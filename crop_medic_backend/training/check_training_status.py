"""Report whether a CropMedic training run is complete, resumable, or missing.

Designed for local use and Google Colab. The script never deletes or changes
training state.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--crop-id", required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    p.add_argument("--checkpoint-dir", type=Path, required=True)
    return p.parse_args()


def _exists(path: Path) -> str:
    return "yes" if path.exists() else "no"


def main():
    args = parse_args()
    output = args.output_dir
    checkpoints = args.checkpoint_dir

    metrics_path = output / "metrics.json"
    model_path = output / "model.keras"
    tflite_path = output / "model.tflite"
    classes_path = output / "class_names.json"
    metadata_path = output / "model_metadata.json"
    run_complete = checkpoints / "run_complete.json"
    head_complete = checkpoints / "head_complete.json"
    fine_complete = checkpoints / "fine_complete.json"
    head_best = checkpoints / "head_best.keras"
    fine_best = checkpoints / "fine_best.keras"
    head_backup = checkpoints / "head_backup"
    fine_backup = checkpoints / "fine_backup"

    print(f"Crop: {args.crop_id}")
    print(f"Output dir: {output}")
    print(f"Checkpoint dir: {checkpoints}")
    print()

    if metrics_path.exists() and model_path.exists() and classes_path.exists():
        print("STATUS: COMPLETE")
        metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
        print(f"TEST ACCURACY: {metrics.get('test_accuracy')}")
        print(f"MACRO F1: {metrics.get('macro_f1')}")
        print(f"model.keras: {_exists(model_path)}")
        print(f"model.tflite: {_exists(tflite_path)}")
        print(f"class_names.json: {_exists(classes_path)}")
        print(f"model_metadata.json: {_exists(metadata_path)}")
        if not tflite_path.exists():
            print("NOTE: Core Keras training completed, but TFLite export is missing.")
        return

    resumable = any(
        p.exists()
        for p in [
            run_complete,
            head_complete,
            fine_complete,
            head_best,
            fine_best,
            head_backup,
            fine_backup,
        ]
    )

    if resumable:
        print("STATUS: INCOMPLETE BUT RESUMABLE")
        print(f"head_complete: {_exists(head_complete)}")
        print(f"fine_complete: {_exists(fine_complete)}")
        print(f"head_best.keras: {_exists(head_best)}")
        print(f"fine_best.keras: {_exists(fine_best)}")
        print(f"head_backup: {_exists(head_backup)}")
        print(f"fine_backup: {_exists(fine_backup)}")
        print("Re-run train_crop_model.py with the SAME output and checkpoint directories.")
        print("Do not use --restart.")
        return

    print("STATUS: NO PERSISTED TRAINING STATE FOUND")
    print("No final metrics/model and no resumable checkpoints were found at these paths.")
    print("Check that Google Drive is mounted and that the paths point to the correct account/folders.")


if __name__ == "__main__":
    main()
