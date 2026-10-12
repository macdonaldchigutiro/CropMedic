"""Generic pilot trainer for one CropMedic crop.

Expected layout:
  data_batch1/<crop_id>/<class_name>/*.jpg

Example:
  python train_crop_model.py --crop-id soybean --data-dir data_batch1/soybean --output-dir artifacts_batch1/soybean
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

from train import (
    classification_metrics,
    compute_class_weights,
    discover_dataset,
    make_dataset,
    stratified_split,
)
from train_v2 import build_model, freeze_for_fine_tuning, v2_callbacks


def args_parser():
    p = argparse.ArgumentParser()
    p.add_argument("--crop-id", required=True)
    p.add_argument("--data-dir", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--head-epochs", type=int, default=10)
    p.add_argument("--fine-epochs", type=int, default=18)
    p.add_argument("--validation-fraction", type=float, default=0.15)
    p.add_argument("--test-fraction", type=float, default=0.15)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--unfreeze-layers", type=int, default=80)
    return p.parse_args()


def main():
    args = args_parser()
    tf.keras.utils.set_random_seed(args.seed)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    class_names, classes = discover_dataset(args.data_dir)
    if len(class_names) < 2:
        raise SystemExit("At least two class folders are required.")

    splits = stratified_split(
        classes, class_names, args.validation_fraction, args.test_fraction, args.seed
    )
    train_paths, train_labels = splits["train"]
    val_paths, val_labels = splits["validation"]
    test_paths, test_labels = splits["test"]

    train_ds = make_dataset(train_paths, train_labels, args.batch_size, True, args.seed)
    val_ds = make_dataset(val_paths, val_labels, args.batch_size, False, args.seed)
    test_ds = make_dataset(test_paths, test_labels, args.batch_size, False, args.seed)

    weights = compute_class_weights(train_labels, len(class_names))
    model, base = build_model(len(class_names))
    model.compile(
        optimizer=tf.keras.optimizers.Adam(7e-4),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.head_epochs,
        class_weight=weights,
        callbacks=v2_callbacks(args.output_dir, "head"),
    )

    fine_layers = freeze_for_fine_tuning(base, args.unfreeze_layers)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(8e-6),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.fine_epochs,
        class_weight=weights,
        callbacks=v2_callbacks(args.output_dir, "fine"),
    )

    test = model.evaluate(test_ds, verbose=1, return_dict=True)
    probs = model.predict(test_ds, verbose=1)
    pred = np.argmax(probs, axis=1)
    matrix, report = classification_metrics(
        np.asarray(test_labels, dtype=np.int64), pred, class_names
    )
    macro_f1 = float(np.mean([item["f1"] for item in report.values()]))

    model.save(args.output_dir / "model.keras")
    (args.output_dir / "class_names.json").write_text(json.dumps(class_names, indent=2), encoding="utf-8")
    metrics = {
        "crop_id": args.crop_id,
        "test_accuracy": round(float(test["accuracy"]), 6),
        "macro_f1": round(macro_f1, 6),
        "confusion_matrix": matrix,
        "per_class": report,
        "release_status": "pilot_only_external_validation_required"
    }
    (args.output_dir / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    metadata = {
        "crop_id": args.crop_id,
        "classes": class_names,
        "fine_tuned_non_batchnorm_layers": fine_layers,
        "splits": {"train": len(train_paths), "validation": len(val_paths), "test": len(test_paths)},
        "warning": "Do not mark this crop AI-supported until external field validation passes."
    }
    (args.output_dir / "model_metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    (args.output_dir / "model.tflite").write_bytes(converter.convert())

    print(f"{args.crop_id}: accuracy={metrics['test_accuracy']:.4f}, macro_f1={metrics['macro_f1']:.4f}")
    print(f"Artifacts: {args.output_dir.resolve()}")
    print("Pilot only: external field validation is still required.")


if __name__ == "__main__":
    main()
