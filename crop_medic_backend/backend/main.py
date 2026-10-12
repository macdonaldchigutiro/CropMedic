import io
import json
import os
import warnings
from collections import defaultdict, deque
from pathlib import Path
from threading import Lock
from time import monotonic

import numpy as np
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image

BASE = Path(__file__).parent
MODEL_PATH = BASE / "model" / "model.keras"
CLASSES_PATH = BASE / "model" / "class_names.json"
ADVICE = json.loads((BASE / "advice.json").read_text(encoding="utf-8"))

IMG_SIZE = 224
LOW_CONFIDENCE = 0.70
MIN_PREDICTION_MARGIN = 0.15
TOP_K = 3
SUPPORTED_LANGS = {"en", "sn", "nd", "toi"}
ALLOWED_IMAGE_FORMATS = {"JPEG", "PNG", "WEBP"}

APP_ENV = os.getenv("CROPMEDIC_ENV", "development").strip().lower()
IS_PRODUCTION = APP_ENV == "production"
MAX_IMAGE_BYTES = int(os.getenv("CROPMEDIC_MAX_IMAGE_BYTES", str(8 * 1024 * 1024)))
MAX_IMAGE_PIXELS = int(os.getenv("CROPMEDIC_MAX_IMAGE_PIXELS", str(20_000_000)))
RATE_LIMIT_REQUESTS = int(os.getenv("CROPMEDIC_RATE_LIMIT_REQUESTS", "30"))
RATE_LIMIT_WINDOW_SECONDS = int(os.getenv("CROPMEDIC_RATE_LIMIT_WINDOW_SECONDS", "60"))
TRUST_PROXY = os.getenv("CROPMEDIC_TRUST_PROXY", "false").lower() == "true"
FORCE_HTTPS = os.getenv("CROPMEDIC_FORCE_HTTPS", "true").lower() == "true"

DEFAULT_CORS = (
    "http://localhost:3000,http://127.0.0.1:3000,"
    "http://localhost:8080,http://127.0.0.1:8080,"
    "http://localhost:5000,http://127.0.0.1:5000"
)
CORS_ORIGINS = [
    item.strip()
    for item in os.getenv("CROPMEDIC_CORS_ORIGINS", DEFAULT_CORS).split(",")
    if item.strip()
]
TRUSTED_HOSTS = [
    item.strip()
    for item in os.getenv("CROPMEDIC_TRUSTED_HOSTS", "localhost,127.0.0.1").split(",")
    if item.strip()
]

# Pillow can otherwise only warn about decompression-bomb-sized images.
Image.MAX_IMAGE_PIXELS = MAX_IMAGE_PIXELS

app = FastAPI(
    title="Crop Medic API",
    docs_url=None if IS_PRODUCTION else "/docs",
    redoc_url=None if IS_PRODUCTION else "/redoc",
    openapi_url=None if IS_PRODUCTION else "/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
    allow_credentials=False,
)

if TRUSTED_HOSTS:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=TRUSTED_HOSTS)

if IS_PRODUCTION and FORCE_HTTPS:
    app.add_middleware(HTTPSRedirectMiddleware)

_rate_buckets = defaultdict(deque)
_rate_lock = Lock()


def _client_key(request: Request) -> str:
    if TRUST_PROXY:
        forwarded = request.headers.get("x-forwarded-for", "")
        if forwarded:
            return forwarded.split(",", 1)[0].strip()
    return request.client.host if request.client else "unknown"


def _rate_limit_exceeded(request: Request) -> tuple[bool, int]:
    now = monotonic()
    cutoff = now - RATE_LIMIT_WINDOW_SECONDS
    key = _client_key(request)

    with _rate_lock:
        bucket = _rate_buckets[key]
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()
        if len(bucket) >= RATE_LIMIT_REQUESTS:
            retry_after = max(1, int(RATE_LIMIT_WINDOW_SECONDS - (now - bucket[0])))
            return True, retry_after
        bucket.append(now)
    return False, 0


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    if request.method == "POST" and request.url.path == "/api/predict":
        exceeded, retry_after = _rate_limit_exceeded(request)
        if exceeded:
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many diagnosis requests. Please try again shortly."},
                headers={"Retry-After": str(retry_after)},
            )

    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "camera=(self), microphone=(), geolocation=()"
    if request.url.path.startswith("/api/"):
        response.headers["Cache-Control"] = "no-store"
    if IS_PRODUCTION:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response


model = None
class_names = []
model_error = None


def load_model():
    """Load and validate the diagnosis model without ever enabling fake predictions."""
    global model, class_names, model_error

    model = None
    class_names = []
    model_error = None

    if not MODEL_PATH.exists() or not CLASSES_PATH.exists():
        model_error = "Trained model files are not installed."
        print(f"Crop Medic model unavailable: {model_error}")
        return

    try:
        import tensorflow as tf

        loaded_classes = json.loads(CLASSES_PATH.read_text(encoding="utf-8"))
        if not isinstance(loaded_classes, list) or not loaded_classes:
            raise ValueError("class_names.json must contain a non-empty list")
        if not all(isinstance(name, str) and name.strip() for name in loaded_classes):
            raise ValueError("class_names.json contains an invalid class name")

        loaded_model = tf.keras.models.load_model(MODEL_PATH)
        output_size = int(loaded_model.output_shape[-1])
        if output_size != len(loaded_classes):
            raise ValueError(
                f"Model outputs {output_size} classes but class_names.json contains "
                f"{len(loaded_classes)}"
            )

        model = loaded_model
        class_names = loaded_classes
        print(f"Crop Medic model loaded with {len(class_names)} classes")
    except Exception as exc:
        model = None
        class_names = []
        model_error = f"Model failed validation: {exc}"
        print(f"Crop Medic model unavailable: {model_error}")


load_model()


def split_label(raw: str):
    crop, separator, disease = raw.partition("___")
    if not separator:
        return crop.replace("_", " ").strip(), "Unknown"
    return crop.replace("_", " ").strip(), disease.replace("_", " ").strip()


def get_advice(raw: str, lang: str):
    if raw.lower().endswith("healthy"):
        entry = ADVICE["_healthy"]
    else:
        entry = ADVICE.get(raw, ADVICE["_default"])
    return entry.get(lang) or entry["en"]


def ensure_model_ready():
    if model is None or not class_names:
        raise HTTPException(
            status_code=503,
            detail=(
                "Crop Medic diagnosis is temporarily unavailable because a trained "
                "model is not loaded. No diagnosis has been generated."
            ),
        )


def _decode_and_validate_image(image_bytes: bytes) -> Image.Image:
    if not image_bytes:
        raise HTTPException(status_code=400, detail="The uploaded image is empty.")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"Image is too large. Maximum upload size is {MAX_IMAGE_BYTES // (1024 * 1024)} MB.",
        )

    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            probe = Image.open(io.BytesIO(image_bytes))
            image_format = (probe.format or "").upper()
            width, height = probe.size

            if image_format not in ALLOWED_IMAGE_FORMATS:
                raise HTTPException(
                    status_code=400,
                    detail="Unsupported image format. Use JPEG, PNG or WebP.",
                )
            if width < 64 or height < 64:
                raise HTTPException(status_code=400, detail="Image is too small to analyse reliably.")
            if width * height > MAX_IMAGE_PIXELS:
                raise HTTPException(status_code=413, detail="Image dimensions are too large.")
            if getattr(probe, "is_animated", False):
                raise HTTPException(status_code=400, detail="Animated images are not supported.")

            probe.verify()
            return Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except HTTPException:
        raise
    except (Image.DecompressionBombError, Image.DecompressionBombWarning) as exc:
        raise HTTPException(status_code=413, detail="Image dimensions are too large.") from exc
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Couldn't read that image.") from exc


@app.get("/api/health")
def health():
    ready = model is not None and bool(class_names)
    payload = {
        "status": "ready" if ready else "unavailable",
        "model_loaded": ready,
        "class_count": len(class_names),
    }
    if not IS_PRODUCTION:
        payload["model_error"] = model_error
    return payload


@app.post("/api/predict")
async def predict(file: UploadFile = File(...), lang: str = "en"):
    ensure_model_ready()

    if not file.content_type or not file.content_type.lower().startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file.")

    lang = lang.lower().strip()
    if lang not in SUPPORTED_LANGS:
        lang = "en"

    image_bytes = await file.read(MAX_IMAGE_BYTES + 1)
    await file.close()
    img = _decode_and_validate_image(image_bytes)

    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0)

    try:
        probs = np.asarray(model.predict(arr, verbose=0)[0], dtype=np.float32)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail="The diagnosis model could not analyse this image. Try again shortly.",
        ) from exc

    if probs.ndim != 1 or len(probs) != len(class_names) or not np.all(np.isfinite(probs)):
        raise HTTPException(
            status_code=503,
            detail="The diagnosis model returned an invalid result. No diagnosis was generated.",
        )

    top_indices = np.argsort(probs)[::-1][: min(TOP_K, len(class_names))]
    predictions = []
    for idx in top_indices:
        raw_label = class_names[int(idx)]
        crop, disease = split_label(raw_label)
        predictions.append(
            {
                "crop": crop,
                "disease": disease,
                "confidence": round(float(probs[int(idx)]), 3),
            }
        )

    primary_idx = int(top_indices[0])
    confidence = float(probs[primary_idx])
    second_confidence = float(probs[int(top_indices[1])]) if len(top_indices) > 1 else 0.0
    prediction_margin = confidence - second_confidence

    accepted = confidence >= LOW_CONFIDENCE and prediction_margin >= MIN_PREDICTION_MARGIN
    if not accepted:
        return {
            "accepted": False,
            "crop": "",
            "disease": "",
            "confidence": round(confidence, 3),
            "low_confidence": True,
            "message": (
                "Crop Medic could not verify this as a clear supported crop-leaf image. "
                "Use one maize, tomato, potato or bell-pepper leaf in good light and try again."
            ),
            "advice": [],
            "top_predictions": predictions,
            "demo": False,
        }

    raw = class_names[primary_idx]
    crop, disease = split_label(raw)

    return {
        "accepted": True,
        "crop": crop,
        "disease": disease,
        "confidence": round(confidence, 3),
        "low_confidence": False,
        "message": None,
        "advice": get_advice(raw, lang),
        "top_predictions": predictions,
        "demo": False,
    }


app.mount("/static", StaticFiles(directory=BASE / "static"), name="static")


@app.get("/")
def index():
    return FileResponse(BASE / "static" / "index.html")


@app.get("/manifest.json")
def manifest():
    return FileResponse(BASE / "static" / "manifest.json")


@app.get("/sw.js")
def service_worker():
    return FileResponse(BASE / "static" / "sw.js", media_type="application/javascript")
