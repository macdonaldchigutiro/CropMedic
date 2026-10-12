"""Evaluate a frozen CropMedic crop model on independent external images.

Known-class layout:
  external/<class name>/*.jpg

Optional unknown/challenge layout:
  unknown/**/*.jpg

The external set must not be used for training or threshold tuning. This script
reports known-class classification metrics plus rejection behaviour for both
known and unknown images.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

from train import classification_metrics, make_dataset

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--crop-id", required=True)
    p.add_argument("--model-dir", type=Path, required=True)
    p.add_argument("--data-dir", type=Path, required=True)
    p.add_argument("--unknown-dir", type=Path, default=None)
    p.add_argument("--output", type=Path, default=None)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--confidence-threshold", type=float, default=0.70)
    p.add_argument("--margin-threshold", type=float, default=0.15)
    return p.parse_args()


def image_files(root: Path) -> list[Path]:
    return sorted(
        p for p in root.rglob("*")
        if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES
    )


def load_known(data_dir: Path, class_names: list[str]):
    paths: list[str] = []
    labels: list[int] = []
    present: list[str] = []

    if not data_dir.exists():
        raise SystemExit(f"External data directory not found: {data_dir}")

    class_to_index = {name: idx for idx, name in enumerate(class_names)}
    folders = sorted(p for p in data_dir.iterdir() if p.is_dir())
    if not folders:
        raise SystemExit("External validation directory has no class folders.")

    unknown_folders = [p.name for p in folders if p.name not in class_to_index]
    if unknown_folders:
        raise SystemExit(
            "External validation contains class folders the model does not know: "
            + ", ".join(unknown_folders)
            + ". Put unsupported diseases in --unknown-dir instead."
        )

    for folder in folders:
        files = image_files(folder)
        if not files:
            continue
        present.append(folder.name)
        label = class_to_index[folder.name]
        paths.extend(str(p) for p in files)
        labels.extend([label] * len(files))

    if not paths:
        raise SystemExit("No external validation images were found.")
    return paths, labels, present


def rejection_stats(probs: np.ndarray, confidence_threshold: float, margin_threshold: float):
    if len(probs) == 0:
        return {
            "images": 0,
            "accepted": 0,
            "rejected": 0,
            "rejection_rate": None,
        }, np.zeros((0,), dtype=bool)

    order = np.sort(probs, axis=1)[:, ::-1]
    top1 = order[:, 0]
    top2 = order[:, 1] if probs.shape[1] > 1 else np.zeros_like(top1)
    accepted = (top1 >= confidence_threshold) & ((top1 - top2) >= margin_threshold)
    count = len(accepted)
    stats = {
        "images": int(count),
        "accepted": int(np.sum(accepted)),
        "rejected": int(np.sum(~accepted)),
        "rejection_rate": round(float(np.mean(~accepted)), 6),
        "mean_top1_confidence": round(float(np.mean(top1)), 6),
        "mean_margin": round(float(np.mean(top1 - top2)), 6),
    }
    return stats, accepted


def main():
    args = parse_args()
    model_path = args.model_dir / "model.keras"
    classes_path = args.model_dir / "class_names.json"
    if not model_path.exists() or not classes_path.exists():
        raise SystemExit("model.keras and class_names.json are required in --model-dir.")

    class_names = json.loads(classes_path.read_text(encoding="utf-8"))
    if not isinstance(class_names, list) or len(class_names) < 2:
        raise SystemExit("class_names.json is invalid.")

    model = tf.keras.models.load_model(model_path)
    if int(model.output_shape[-1]) != len(class_names):
        raise SystemExit("Model output count does not match class_names.json.")

    known_paths, known_labels, present_classes = load_known(args.data_dir, class_names)
    missing_classes = [name for name in class_names if name not in present_classes]
    known_ds = make_dataset(known_paths, known_labels, args.batch_size, False, 42)
    known_probs = np.asarray(model.predict(known_ds, verbose=1), dtype=np.float32)
    known_pred = np.argmax(known_probs, axis=1)

    matrix, report = classification_metrics(
        np.asarray(known_labels, dtype=np.int64), known_pred, class_names
    )
    present_report = {name: report[name] for name in present_classes}
    present_f1 = [float(item["f1"]) for item in present_report.values()]
    external_accuracy = float(np.mean(known_pred == np.asarray(known_labels)))
    known_rejection, known_accepted = rejection_stats(
        known_probs, args.confidence_threshold, args.margin_threshold
    )

    accepted_correct = 0
    if np.any(known_accepted):
        accepted_correct = int(
            np.sum(
                known_pred[known_accepted]
                == np.asarray(known_labels, dtype=np.int64)[known_accepted]
            )
        )
    accepted_accuracy = (
        accepted_correct / int(np.sum(known_accepted))
        if np.any(known_accepted)
        else None
    )
    known_rejection["accepted_accuracy"] = (
        round(float(accepted_accuracy), 6) if accepted_accuracy is not None else None
    )

    unknown_stats = None
    if args.unknown_dir is not None:
        unknown_paths = [str(p) for p in image_files(args.unknown_dir)]
        if unknown_paths:
            unknown_ds = make_dataset(
                unknown_paths, [0] * len(unknown_paths), args.batch_size, False, 42
            )
            unknown_probs = np.asarray(model.predict(unknown_ds, verbose=1), dtype=np.float32)
            unknown_stats, _ = rejection_stats(
                unknown_probs, args.confidence_threshold, args.margin_threshold
            )
            unknown_stats["desired_behaviour"] = "high_rejection_rate"
        else:
            unknown_stats = {
                "images": 0,
                "warning": "Unknown directory was supplied but contained no supported image files.",
            }

    payload = {
        "crop_id": args.crop_id,
        "evaluation_type": "external_validation_no_tuning",
        "model_dir": str(args.model_dir.resolve()),
        "external_data_dir": str(args.data_dir.resolve()),
        "model_classes": class_names,
        "classes_present": present_classes,
        "missing_model_classes": missing_classes,
        "all_model_classes_present": not missing_classes,
        "images": len(known_paths),
        "accuracy": round(external_accuracy, 6),
        "macro_f1_present_classes": round(float(np.mean(present_f1)), 6),
        "confusion_matrix_all_model_classes": matrix,
        "per_class": present_report,
        "rejection_thresholds": {
            "confidence": args.confidence_threshold,
            "margin": args.margin_threshold,
        },
        "known_image_rejection": known_rejection,
        "unknown_challenge_rejection": unknown_stats,
        "release_warning": (
            "This report is evidence only for the supplied independent images. "
            "Do not claim Zimbabwe field readiness unless the validation set actually "
            "contains representative Zimbabwe-style field photos and was not used for tuning."
        ),
    }

    output = args.output or (args.model_dir / "external_validation.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    print(f"External images: {payload['images']}")
    print(f"Classes present: {len(present_classes)}/{len(class_names)}")
    if missing_classes:
        print("WARNING: Missing model classes from external validation: " + ", ".join(missing_classes))
    print(f"Accuracy: {payload['accuracy']:.4f}")
    print(f"Macro F1 (present classes): {payload['macro_f1_present_classes']:.4f}")
    print(f"Known rejection rate: {known_rejection['rejection_rate']:.4f}")
    if unknown_stats and unknown_stats.get("rejection_rate") is not None:
        print(f"Unknown challenge rejection rate: {unknown_stats['rejection_rate']:.4f}")
    print(f"Report: {output.resolve()}")
    print("Do not tune the model on this external validation set.")


if __name__ == "__main__":
    main()
