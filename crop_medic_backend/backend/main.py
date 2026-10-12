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

from model_registry import CropModelRegistry

BASE = Path(__file__).parent
MODEL_PATH = BASE / "model" / "model.keras"
CLASSES_PATH = BASE / "model" / "class_names.json"
OPTIONAL_MODELS_ROOT = BASE / "models"
ADVICE = json.loads((BASE / "advice.json").read_text(encoding="utf-8"))

IMG_SIZE = 224
LOW_CONFIDENCE = 0.70
MIN_PREDICTION_MARGIN = 0.15
CROP_MIN_RAW_SCORE = 0.60
CROP_MIN_MARGIN = 0.10
TOP_K = 3
SUPPORTED_LANGS = {"en", "sn", "nd", "toi"}
ALLOWED_IMAGE_FORMATS = {"JPEG", "PNG", "WEBP"}
LEGACY_SUPPORTED_CROPS = ("Maize", "Tomato", "Potato", "Bell pepper")

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
LOCAL_DEV_ORIGIN_REGEX = None if IS_PRODUCTION else r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"
TRUSTED_HOSTS = [
    item.strip()
    for item in os.getenv("CROPMEDIC_TRUSTED_HOSTS", "localhost,127.0.0.1").split(",")
    if item.strip()
]

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
    allow_origin_regex=LOCAL_DEV_ORIGIN_REGEX,
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
    if request.method == "POST" and request.url.path in {"/api/predict", "/api/identify-crop"}:
        exceeded, retry_after = _rate_limit_exceeded(request)
        if exceeded:
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many analysis requests. Please try again shortly."},
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
class_names: list[str] = []
model_error = None
crop_registry = CropModelRegistry(OPTIONAL_MODELS_ROOT)


def load_model():
    """Load and validate the legacy four-crop diagnosis model."""
    global model, class_names, model_error

    model = None
    class_names = []
    model_error = None

    if not MODEL_PATH.exists() or not CLASSES_PATH.exists():
        model_error = "Trained legacy model files are not installed."
        print(f"Crop Medic legacy model unavailable: {model_error}")
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
        print(f"Crop Medic legacy model loaded with {len(class_names)} classes")
    except Exception as exc:
        model = None
        class_names = []
        model_error = f"Model failed validation: {exc}"
        print(f"Crop Medic legacy model unavailable: {model_error}")


def load_optional_models():
    try:
        crop_registry.load()
        ready = crop_registry.ready_crops()
        if ready:
            print("Crop-specific diagnosis models loaded: " + ", ".join(ready))
    except Exception as exc:
        print(f"Crop-specific model registry unavailable: {exc}")


load_model()
load_optional_models()


def split_label(raw: str):
    crop, separator, disease = raw.partition("___")
    if not separator:
        return crop.replace("_", " ").strip(), "Unknown"
    return crop.replace("_", " ").strip(), disease.replace("_", " ").strip()


def normalize_crop_name(raw: str) -> str:
    value = raw.replace("_", " ").strip().lower()
    aliases = {
        "corn (maize)": "Maize",
        "corn": "Maize",
        "maize": "Maize",
        "tomato": "Tomato",
        "potato": "Potato",
        "pepper, bell": "Bell pepper",
        "bell pepper": "Bell pepper",
        "pepper": "Bell pepper",
        "beans": "Common bean",
        "bean": "Common bean",
        "common bean": "Common bean",
        "soybean": "Soybean",
        "soya bean": "Soybean",
        "wheat": "Wheat",
        "sorghum": "Sorghum",
        "tobacco": "Tobacco",
    }
    return aliases.get(value, raw.replace("_", " ").strip())


def _diagnosis_supported_crops() -> list[str]:
    return list(dict.fromkeys([*LEGACY_SUPPORTED_CROPS, *crop_registry.ready_crops()]))


def _disease_display(raw: str) -> str:
    if "___" in raw:
        return split_label(raw)[1]
    return raw.replace("_", " ").strip()


def get_advice(raw: str, lang: str):
    if raw.lower().endswith("healthy"):
        entry = ADVICE["_healthy"]
    else:
        entry = ADVICE.get(raw, ADVICE["_default"])
    return entry.get(lang) or entry["en"]


def ensure_legacy_model_ready():
    if model is None or not class_names:
        raise HTTPException(
            status_code=503,
            detail=(
                "Crop Medic crop identification is temporarily unavailable because "
                "the legacy diagnosis model is not loaded."
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


async def _read_upload(file: UploadFile) -> bytes:
    if not file.content_type or not file.content_type.lower().startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file.")
    image_bytes = await file.read(MAX_IMAGE_BYTES + 1)
    await file.close()
    _decode_and_validate_image(image_bytes)
    return image_bytes


def _model_probabilities(image_bytes: bytes, model_obj, model_classes: list[str]) -> np.ndarray:
    img = _decode_and_validate_image(image_bytes).resize((IMG_SIZE, IMG_SIZE))
    arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0)

    try:
        probs = np.asarray(model_obj.predict(arr, verbose=0)[0], dtype=np.float32)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail="The diagnosis model could not analyse this image. Try again shortly.",
        ) from exc

    if probs.ndim != 1 or len(probs) != len(model_classes) or not np.all(np.isfinite(probs)):
        raise HTTPException(
            status_code=503,
            detail="The diagnosis model returned an invalid result. No diagnosis was generated.",
        )
    return probs


def _indices_for_crop(crop: str) -> list[int]:
    canonical = normalize_crop_name(crop)
    return [
        idx
        for idx, raw in enumerate(class_names)
        if normalize_crop_name(split_label(raw)[0]) == canonical
    ]


@app.get("/api/health")
def health():
    legacy_ready = model is not None and bool(class_names)
    optional_ready = crop_registry.ready_crops()
    any_ready = legacy_ready or bool(optional_ready)
    payload = {
        "status": "ready" if any_ready else "unavailable",
        "model_loaded": legacy_ready,
        "legacy_model_loaded": legacy_ready,
        "class_count": len(class_names),
        "supported_crops": _diagnosis_supported_crops(),
        "crop_identification_supported_crops": list(LEGACY_SUPPORTED_CROPS),
        "crop_specific_models": crop_registry.status(),
    }
    if not IS_PRODUCTION:
        payload["model_error"] = model_error
    return payload


@app.get("/api/capabilities")
def capabilities():
    return {
        "diagnosis_supported_crops": _diagnosis_supported_crops(),
        "crop_identification_supported_crops": list(LEGACY_SUPPORTED_CROPS),
        "crop_identification_mode": "bootstrap_legacy_model_requires_farmer_confirmation",
        "crop_specific_models": crop_registry.status(),
        "languages": sorted(SUPPORTED_LANGS),
    }


@app.post("/api/identify-crop")
async def identify_crop(file: UploadFile = File(...)):
    """
    Bootstrap crop identification using the current four-crop disease model.

    This remains a suggestion that the farmer must confirm. Crop-specific
    disease models do not automatically become crop-identification models.
    """
    ensure_legacy_model_ready()
    image_bytes = await _read_upload(file)
    probs = _model_probabilities(image_bytes, model, class_names)

    raw_scores = {crop: 0.0 for crop in LEGACY_SUPPORTED_CROPS}
    for idx, raw in enumerate(class_names):
        crop = normalize_crop_name(split_label(raw)[0])
        if crop in raw_scores:
            raw_scores[crop] = max(raw_scores[crop], float(probs[idx]))

    total = sum(raw_scores.values()) or 1.0
    ranked = sorted(raw_scores.items(), key=lambda item: item[1], reverse=True)
    top_crop, top_raw = ranked[0]
    second_raw = ranked[1][1] if len(ranked) > 1 else 0.0
    candidates = [
        {
            "crop": crop,
            "confidence": round(score / total, 3),
            "raw_score": round(score, 3),
        }
        for crop, score in ranked
    ]

    accepted = top_raw >= CROP_MIN_RAW_SCORE and (top_raw - second_raw) >= CROP_MIN_MARGIN
    return {
        "accepted": accepted,
        "crop": top_crop if accepted else "",
        "confidence": round(top_raw / total, 3),
        "message": None
        if accepted
        else "CropMedic is not confident which supported crop this is. Please choose the crop before diagnosis.",
        "candidates": candidates,
        "supported_crops": list(LEGACY_SUPPORTED_CROPS),
        "bootstrap": True,
    }


def _optional_crop_prediction(image_bytes: bytes, crop: str, lang: str, entry):
    probs = _model_probabilities(image_bytes, entry.model, entry.class_names or [])
    order = [int(i) for i in np.argsort(probs)[::-1]]
    top = order[: min(TOP_K, len(order))]
    confidences = [float(probs[i]) for i in top]

    predictions = [
        {
            "crop": crop,
            "disease": _disease_display((entry.class_names or [])[idx]),
            "confidence": round(confidence, 3),
        }
        for idx, confidence in zip(top, confidences)
    ]

    confidence = confidences[0]
    second = confidences[1] if len(confidences) > 1 else 0.0
    margin = confidence - second
    accepted = (
        confidence >= entry.confidence_threshold
        and margin >= entry.margin_threshold
    )

    if not accepted:
        return {
            "accepted": False,
            "crop": crop,
            "disease": "",
            "confidence": round(confidence, 3),
            "low_confidence": True,
            "message": (
                f"CropMedic could not make a reliable diagnosis from this {crop} image. "
                "Use a clear photo of the affected plant part in good light and try again."
            ),
            "advice": [],
            "top_predictions": predictions,
            "demo": False,
        }

    raw = (entry.class_names or [])[top[0]]
    return {
        "accepted": True,
        "crop": crop,
        "disease": _disease_display(raw),
        "confidence": round(confidence, 3),
        "low_confidence": False,
        "message": None,
        "advice": get_advice(raw, lang),
        "top_predictions": predictions,
        "demo": False,
    }


@app.post("/api/predict")
async def predict(file: UploadFile = File(...), lang: str = "en", crop: str | None = None):
    lang = lang.lower().strip()
    if lang not in SUPPORTED_LANGS:
        lang = "en"

    image_bytes = await _read_upload(file)

    if crop:
        canonical_crop = normalize_crop_name(crop)
        optional_entry = crop_registry.get(canonical_crop)
        if optional_entry is not None:
            return _optional_crop_prediction(image_bytes, canonical_crop, lang, optional_entry)

        if canonical_crop not in LEGACY_SUPPORTED_CROPS:
            raise HTTPException(status_code=400, detail="That crop is not yet supported for AI diagnosis.")

        ensure_legacy_model_ready()
        probs = _model_probabilities(image_bytes, model, class_names)
        selected_indices = _indices_for_crop(canonical_crop)
        if not selected_indices:
            raise HTTPException(status_code=503, detail="The installed model has no classes for that crop.")

        selected_probs = np.asarray([float(probs[idx]) for idx in selected_indices], dtype=np.float32)
        crop_mass = float(np.sum(selected_probs))
        if crop_mass <= 0 or not np.isfinite(crop_mass):
            raise HTTPException(status_code=503, detail="The model could not score that crop reliably.")

        conditional = selected_probs / crop_mass
        local_order = np.argsort(conditional)[::-1]
        ordered_indices = [selected_indices[int(i)] for i in local_order]
        confidence_values = [float(conditional[int(i)]) for i in local_order]
        crop_match_score = float(np.max(selected_probs))
    else:
        ensure_legacy_model_ready()
        probs = _model_probabilities(image_bytes, model, class_names)
        ordered_indices = [int(i) for i in np.argsort(probs)[::-1]]
        confidence_values = [float(probs[i]) for i in ordered_indices]
        crop_match_score = confidence_values[0]
        canonical_crop = normalize_crop_name(split_label(class_names[ordered_indices[0]])[0])

    top_indices = ordered_indices[: min(TOP_K, len(ordered_indices))]
    top_confidences = confidence_values[: min(TOP_K, len(confidence_values))]
    predictions = []
    for idx, candidate_confidence in zip(top_indices, top_confidences):
        raw_label = class_names[idx]
        raw_crop, disease = split_label(raw_label)
        predictions.append(
            {
                "crop": normalize_crop_name(raw_crop),
                "disease": disease,
                "confidence": round(candidate_confidence, 3),
            }
        )

    primary_idx = int(top_indices[0])
    confidence = float(top_confidences[0])
    second_confidence = float(top_confidences[1]) if len(top_confidences) > 1 else 0.0
    prediction_margin = confidence - second_confidence

    accepted = confidence >= LOW_CONFIDENCE and prediction_margin >= MIN_PREDICTION_MARGIN
    if crop and crop_match_score < 0.12:
        accepted = False

    if not accepted:
        crop_text = f" {canonical_crop}" if crop else " supported crop"
        return {
            "accepted": False,
            "crop": canonical_crop if crop else "",
            "disease": "",
            "confidence": round(confidence, 3),
            "low_confidence": True,
            "message": (
                f"CropMedic could not make a reliable diagnosis from this{crop_text} image. "
                "Use a clear photo of the affected plant part in good light and try again."
            ),
            "advice": [],
            "top_predictions": predictions,
            "demo": False,
        }

    raw = class_names[primary_idx]
    raw_crop, disease = split_label(raw)
    result_crop = normalize_crop_name(raw_crop)

    return {
        "accepted": True,
        "crop": result_crop,
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
