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

app = FastAPI(title="Crop Medic API")

# Allows the Flutter web app to call this API during development.
# Replace "*" with your real domain before going live.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

model = None
class_names = []


def load_model():
    global model, class_names
    if MODEL_PATH.exists() and CLASSES_PATH.exists():
        import tensorflow as tf

        model = tf.keras.models.load_model(MODEL_PATH)
        class_names = json.loads(CLASSES_PATH.read_text(encoding="utf-8"))
        print(f"Model loaded with {len(class_names)} classes")
    else:
        print("No model found. Running in DEMO mode (fake predictions).")


load_model()


def split_label(raw: str):
    # PlantVillage format: "Crop___Disease_name"
    crop, _, disease = raw.partition("___")
    return crop.replace("_", " ").strip(), disease.replace("_", " ").strip()


def get_advice(raw: str, lang: str):
    if raw.endswith("healthy"):
        entry = ADVICE["_healthy"]
    else:
        entry = ADVICE.get(raw, ADVICE["_default"])
    steps = entry.get(lang) or entry["en"]
    return steps


@app.get("/api/health")
def health():
    return {"status": "ok", "demo_mode": model is None}


@app.post("/api/predict")
async def predict(file: UploadFile = File(...), lang: str = "en"):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file.")

    try:
        img = Image.open(io.BytesIO(await file.read())).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Couldn't read that image.")

    if model is None:
        raw, confidence = "Corn_(maize)___Northern_Leaf_Blight", 0.94
    else:
        img = img.resize((IMG_SIZE, IMG_SIZE))
        arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0)
        probs = model.predict(arr, verbose=0)[0]
        idx = int(np.argmax(probs))
        raw, confidence = class_names[idx], float(probs[idx])

    crop, disease = split_label(raw)
    return {
        "crop": crop,
        "disease": disease,
        "confidence": round(confidence, 3),
        "low_confidence": confidence < LOW_CONFIDENCE,
        "advice": get_advice(raw, lang),
        "demo": model is None,
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
