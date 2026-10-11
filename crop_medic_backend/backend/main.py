import io
import json
from pathlib import Path

import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image

BASE = Path(__file__).parent
MODEL_PATH = BASE / "model" / "model.keras"
CLASSES_PATH = BASE / "model" / "class_names.json"
ADVICE = json.loads((BASE / "advice.json").read_text(encoding="utf-8"))

IMG_SIZE = 224
LOW_CONFIDENCE = 0.70
TOP_K = 3

app = FastAPI(title="Crop Medic API")

# Development-only CORS policy. Restrict this to trusted origins before deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    # PlantVillage format: "Crop___Disease_name"
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


@app.get("/api/health")
def health():
    ready = model is not None and bool(class_names)
    return {
        "status": "ready" if ready else "unavailable",
        "model_loaded": ready,
        "class_count": len(class_names),
        "model_error": model_error,
    }


@app.post("/api/predict")
async def predict(file: UploadFile = File(...), lang: str = "en"):
    ensure_model_ready()

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file.")

    try:
        image_bytes = await file.read()
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Couldn't read that image.") from exc

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
    raw = class_names[primary_idx]
    confidence = float(probs[primary_idx])
    crop, disease = split_label(raw)

    return {
        "crop": crop,
        "disease": disease,
        "confidence": round(confidence, 3),
        "low_confidence": confidence < LOW_CONFIDENCE,
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
