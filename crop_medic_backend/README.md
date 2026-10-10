# Crop Medic - backend

AI crop disease detection: take a leaf photo, get a diagnosis and advice.

## Structure
- backend/   FastAPI server + web app (PWA) the farmer uses
- training/  train.py to build the model

## Step 1: run it right now (demo mode, no model needed)
    cd backend
    python -m venv venv
    venv\Scripts\activate          (Windows)   or   source venv/bin/activate   (Mac/Linux)
    pip install -r requirements.txt
    uvicorn main:app --reload

Open http://127.0.0.1:8000 and upload any image. It returns a fake
"Northern leaf blight" result so you can see the full flow working.

To try it on your phone, run with --host 0.0.0.0 and open
http://YOUR-PC-IP:8000 on the same Wi-Fi.

## Step 2: train a real model
1. Download PlantVillage from Kaggle. Keep 2 or 3 crops to start (e.g. maize, tomato).
2. Put the class folders inside training/data/
3. Open Google Colab, upload train.py and the data, enable a GPU, run it.
4. Copy model.keras and class_names.json into backend/model/
5. Restart the server. Demo mode switches off automatically.

## Step 3: improve it
- Add advice for each class in backend/advice.json
- Have a native speaker write the Shona (sn) and Ndebele (nd) advice
- Collect real local leaf photos and retest. Accuracy usually drops on farm photos.
- Later: scan history (SQLite), a Flutter app, TFLite on-device for offline use.

## Important
Treat results as guidance, not a final diagnosis. Low-confidence results
show a warning to confirm with an extension officer.
