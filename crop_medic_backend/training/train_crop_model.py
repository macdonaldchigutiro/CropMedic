"""Generic resumable pilot trainer for one CropMedic crop.

Expected layout:
  data_batch1/<crop_id>/<class_name>/*.jpg

The trainer supports persistent checkpoints so Colab/VM disconnects do not
force a full restart. For Colab, point --checkpoint-dir and preferably
--output-dir at Google Drive.
"""
from __future__ import annotations

import argparse
import json
import shutil
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
from train_v2 import build_model, freeze_for_fine_tuning


def args_parser():
    p = argparse.ArgumentParser()
    p.add_argument("--crop-id", required=True)
    p.add_argument("--data-dir", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    p.add_argument("--checkpoint-dir", type=Path, default=None)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--head-epochs", type=int, default=10)
    p.add_argument("--fine-epochs", type=int, default=18)
    p.add_argument("--validation-fraction", type=float, default=0.15)
    p.add_argument("--test-fraction", type=float, default=0.15)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--unfreeze-layers", type=int, default=80)
    p.add_argument(
        "--restart",
        action="store_true",
        help="Delete this run's checkpoints and start training from scratch.",
    )
    return p.parse_args()


def _json_write(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _find_backbone(model: tf.keras.Model) -> tf.keras.Model:
    for layer in model.layers:
        if isinstance(layer, tf.keras.Model) and "efficientnet" in layer.name.lower():
            return layer
    raise RuntimeError("Could not find the EfficientNet backbone in a resumed model.")


def _callbacks(output_dir: Path, checkpoint_dir: Path, phase: str):
    backup_dir = checkpoint_dir / f"{phase}_backup"
    best_model = checkpoint_dir / f"{phase}_best.keras"
    return [
        tf.keras.callbacks.BackupAndRestore(backup_dir=str(backup_dir)),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(best_model),
            monitor="val_loss",
            save_best_only=True,
            save_weights_only=False,
            verbose=1,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=5,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.3,
            patience=2,
            min_lr=1e-7,
            verbose=1,
        ),
        tf.keras.callbacks.CSVLogger(
            str(output_dir / f"training_{phase}.csv"),
            append=True,
        ),
    ]


def _load_best(path: Path) -> tf.keras.Model:
    if not path.exists():
        raise RuntimeError(f"Expected checkpoint was not written: {path}")
    return tf.keras.models.load_model(path)


def main():
    args = args_parser()
    tf.keras.utils.set_random_seed(args.seed)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_dir = args.checkpoint_dir or (args.output_dir / "_checkpoints")

    if args.restart and checkpoint_dir.exists():
        print(f"Restart requested; deleting checkpoints: {checkpoint_dir}")
        shutil.rmtree(checkpoint_dir)

    checkpoint_dir.mkdir(parents=True, exist_ok=True)

    class_names, classes = discover_dataset(args.data_dir)
    if len(class_names) < 2:
        raise SystemExit("At least two class folders are required.")

    splits = stratified_split(
        classes, class_names, args.validation_fraction, args.test_fraction, args.seed
    )
    train_paths, train_labels = splits["train"]
    val_paths, val_labels = splits["validation"]
    test_paths, test_labels = splits["test"]

    print(f"Crop: {args.crop_id}")
    print(f"Classes ({len(class_names)}): {class_names}")
    print(
        f"Split: train={len(train_paths)}, validation={len(val_paths)}, "
        f"test={len(test_paths)}"
    )
    print(f"Persistent checkpoints: {checkpoint_dir.resolve()}")

    train_ds = make_dataset(train_paths, train_labels, args.batch_size, True, args.seed)
    val_ds = make_dataset(val_paths, val_labels, args.batch_size, False, args.seed)
    test_ds = make_dataset(test_paths, test_labels, args.batch_size, False, args.seed)

    weights = compute_class_weights(train_labels, len(class_names))

    head_best = checkpoint_dir / "head_best.keras"
    head_complete = checkpoint_dir / "head_complete.json"

    if head_complete.exists() and head_best.exists():
        print("Head phase already completed. Loading saved best head model.")
        model = _load_best(head_best)
        base = _find_backbone(model)
    else:
        print("Starting/resuming head training.")
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
            callbacks=_callbacks(args.output_dir, checkpoint_dir, "head"),
        )
        model = _load_best(head_best)
        base = _find_backbone(model)
        _json_write(
            head_complete,
            {
                "phase": "head",
                "complete": True,
                "best_model": str(head_best),
                "requested_epochs": args.head_epochs,
            },
        )
        print("Head phase complete and preserved.")

    fine_best = checkpoint_dir / "fine_best.keras"
    fine_complete = checkpoint_dir / "fine_complete.json"

    if fine_complete.exists() and fine_best.exists():
        print("Fine-tuning phase already completed. Loading saved best fine-tuned model.")
        model = _load_best(fine_best)
        base = _find_backbone(model)
        state = json.loads(fine_complete.read_text(encoding="utf-8"))
        fine_layers = int(state.get("fine_tuned_non_batchnorm_layers", 0))
    else:
        print("Starting/resuming fine-tuning.")
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
            callbacks=_callbacks(args.output_dir, checkpoint_dir, "fine"),
        )
        model = _load_best(fine_best)
        base = _find_backbone(model)
        _json_write(
            fine_complete,
            {
                "phase": "fine",
                "complete": True,
                "best_model": str(fine_best),
                "requested_epochs": args.fine_epochs,
                "fine_tuned_non_batchnorm_layers": fine_layers,
            },
        )
        print("Fine-tuning complete and preserved.")

    test = model.evaluate(test_ds, verbose=1, return_dict=True)
    probs = model.predict(test_ds, verbose=1)
    pred = np.argmax(probs, axis=1)
    matrix, report = classification_metrics(
        np.asarray(test_labels, dtype=np.int64), pred, class_names
    )
    macro_f1 = float(np.mean([item["f1"] for item in report.values()]))

    model.save(args.output_dir / "model.keras")
    (args.output_dir / "class_names.json").write_text(
        json.dumps(class_names, indent=2), encoding="utf-8"
    )

    metrics = {
        "crop_id": args.crop_id,
        "test_accuracy": round(float(test["accuracy"]), 6),
        "macro_f1": round(macro_f1, 6),
        "confusion_matrix": matrix,
        "per_class": report,
        "release_status": "pilot_only_external_validation_required",
    }
    _json_write(args.output_dir / "metrics.json", metrics)

    metadata = {
        "crop_id": args.crop_id,
        "classes": class_names,
        "fine_tuned_non_batchnorm_layers": fine_layers,
        "splits": {
            "train": len(train_paths),
            "validation": len(val_paths),
            "test": len(test_paths),
        },
        "checkpoint_dir": str(checkpoint_dir.resolve()),
        "resumable_training": True,
        "warning": (
            "Do not mark this crop AI-supported until independent external "
            "field validation and rejection testing pass."
        ),
    }
    _json_write(args.output_dir / "model_metadata.json", metadata)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    (args.output_dir / "model.tflite").write_bytes(converter.convert())

    _json_write(
        checkpoint_dir / "run_complete.json",
        {
            "crop_id": args.crop_id,
            "complete": True,
            "test_accuracy": metrics["test_accuracy"],
            "macro_f1": metrics["macro_f1"],
            "artifacts": str(args.output_dir.resolve()),
        },
    )

    print(
        f"{args.crop_id}: accuracy={metrics['test_accuracy']:.4f}, "
        f"macro_f1={metrics['macro_f1']:.4f}"
    )
    print(f"Artifacts: {args.output_dir.resolve()}")
    print("Training state is resumable from the checkpoint directory.")
    print("Pilot only: external field validation is still required.")


if __name__ == "__main__":
    main()
