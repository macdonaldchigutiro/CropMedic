"""Train CropMedic Zimbabwe v2 against the same PlantVillage benchmark.

V2 is a controlled experiment based on the v1 failure pattern:
- stronger EfficientNetB0 ImageNet backbone
- deeper fine-tuning with BatchNorm kept frozen
- modest class-weight boost for Tomato Early Blight
- same official PlantVillage split/validation strategy as train.py

Example (Colab/T4 recommended):
    python train_v2.py \
        --data-dir data \
        --output-dir artifacts_v2 \
        --baseline-metrics artifacts/metrics.json

PlantVillage remains a bootstrap benchmark. Do not treat these metrics as proof
of Zimbabwe field performance.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

from train import (
    IMG_SIZE,
    MANIFEST_NAME,
    classification_metrics,
    compute_class_weights,
    discover_dataset,
    make_dataset,
    split_from_plantvillage_manifest,
    stratified_split,
)

EARLY_BLIGHT_CLASS = "Tomato___Early_blight"
TARGET_SPOT_CLASS = "Tomato___Target_Spot"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train CropMedic Zimbabwe v2")
    parser.add_argument("--data-dir", type=Path, default=Path("data"))
    parser.add_argument("--output-dir", type=Path, default=Path("artifacts_v2"))
    parser.add_argument("--baseline-metrics", type=Path, default=None)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--head-epochs", type=int, default=10)
    parser.add_argument("--fine-epochs", type=int, default=18)
    parser.add_argument("--validation-fraction", type=float, default=0.15)
    parser.add_argument("--test-fraction", type=float, default=0.15)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--unfreeze-layers", type=int, default=80)
    parser.add_argument("--early-blight-boost", type=float, default=1.6)
    return parser.parse_args()


def v2_callbacks(output_dir: Path, phase: str) -> list[tf.keras.callbacks.Callback]:
    return [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=5, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.3, patience=2, min_lr=1e-7
        ),
        tf.keras.callbacks.CSVLogger(str(output_dir / f"training_{phase}.csv")),
    ]


def build_model(class_count: int) -> tuple[tf.keras.Model, tf.keras.Model]:
    augment = tf.keras.Sequential(
        [
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.10),
            layers.RandomZoom(0.12),
            layers.RandomContrast(0.18),
            layers.RandomBrightness(0.12),
        ],
        name="augmentation",
    )

    # EfficientNetB0 includes its own input rescaling and expects float pixels in
    # the ordinary 0-255 range produced by train.decode_image().
    base = tf.keras.applications.EfficientNetB0(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base.trainable = False

    inputs = layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3), name="image")
    x = augment(inputs)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.35)(x)
    x = layers.Dense(256, activation="swish", name="feature_head")(x)
    x = layers.Dropout(0.25)(x)
    outputs = layers.Dense(class_count, activation="softmax", name="disease")(x)
    return models.Model(inputs, outputs, name="crop_medic_zimbabwe_v2"), base


def apply_targeted_weight_boost(
    class_weights: dict[int, float],
    class_names: list[str],
    early_blight_boost: float,
) -> dict[int, float]:
    if early_blight_boost <= 0:
        raise ValueError("--early-blight-boost must be greater than zero")
    if EARLY_BLIGHT_CLASS not in class_names:
        raise ValueError(f"Required class missing: {EARLY_BLIGHT_CLASS}")

    boosted = dict(class_weights)
    index = class_names.index(EARLY_BLIGHT_CLASS)
    boosted[index] *= early_blight_boost
    print(
        f"Early Blight weight boost: {early_blight_boost:.2f}x "
        f"(final class weight={boosted[index]:.4f})"
    )
    return boosted


def freeze_for_fine_tuning(base: tf.keras.Model, unfreeze_layers: int) -> int:
    if unfreeze_layers < 1:
        raise ValueError("--unfreeze-layers must be at least 1")

    base.trainable = True
    cutoff = max(0, len(base.layers) - unfreeze_layers)
    trainable_count = 0

    for index, layer in enumerate(base.layers):
        if index < cutoff or isinstance(layer, layers.BatchNormalization):
            layer.trainable = False
        else:
            layer.trainable = True
            trainable_count += 1

    print(
        f"Fine-tuning {trainable_count} non-BatchNorm backbone layers "
        f"from the last {unfreeze_layers} EfficientNet layers."
    )
    return trainable_count


def load_baseline(path: Path | None) -> dict | None:
    if path is None:
        return None
    if not path.exists():
        print(f"Baseline metrics not found at {path}; comparison will be skipped.")
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    args = parse_args()
    tf.keras.utils.set_random_seed(args.seed)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    class_names, classes = discover_dataset(args.data_dir)
    manifest_path = args.data_dir / MANIFEST_NAME
    if manifest_path.exists():
        print(f"Using official PlantVillage split manifest: {manifest_path}")
        splits = split_from_plantvillage_manifest(
            args.data_dir,
            class_names,
            args.validation_fraction,
            args.seed,
        )
        split_strategy = "plantvillage_official_test"
    else:
        splits = stratified_split(
            classes,
            class_names,
            args.validation_fraction,
            args.test_fraction,
            args.seed,
        )
        split_strategy = "deterministic_per_class"

    train_paths, train_labels = splits["train"]
    validation_paths, validation_labels = splits["validation"]
    test_paths, test_labels = splits["test"]

    print(f"Classes: {len(class_names)}")
    print(
        f"Split: train={len(train_paths)}, validation={len(validation_paths)}, "
        f"test={len(test_paths)}"
    )

    train_ds = make_dataset(
        train_paths, train_labels, args.batch_size, training=True, seed=args.seed
    )
    validation_ds = make_dataset(
        validation_paths,
        validation_labels,
        args.batch_size,
        training=False,
        seed=args.seed,
    )
    test_ds = make_dataset(
        test_paths, test_labels, args.batch_size, training=False, seed=args.seed
    )

    class_weights = compute_class_weights(train_labels, len(class_names))
    class_weights = apply_targeted_weight_boost(
        class_weights, class_names, args.early_blight_boost
    )

    model, base = build_model(len(class_names))
    model.compile(
        optimizer=tf.keras.optimizers.Adam(7e-4),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            tf.keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_accuracy"),
        ],
    )
    model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.head_epochs,
        class_weight=class_weights,
        callbacks=v2_callbacks(args.output_dir, "head"),
    )

    fine_tuned_layers = freeze_for_fine_tuning(base, args.unfreeze_layers)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(8e-6),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            tf.keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_accuracy"),
        ],
    )
    model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.fine_epochs,
        class_weight=class_weights,
        callbacks=v2_callbacks(args.output_dir, "fine"),
    )

    test_values = model.evaluate(test_ds, verbose=1, return_dict=True)
    probabilities = model.predict(test_ds, verbose=1)
    predictions = np.argmax(probabilities, axis=1)
    y_true = np.asarray(test_labels, dtype=np.int64)
    matrix, report = classification_metrics(y_true, predictions, class_names)

    macro_f1 = float(np.mean([item["f1"] for item in report.values()]))
    early = report[EARLY_BLIGHT_CLASS]
    target = report[TARGET_SPOT_CLASS]

    keras_path = args.output_dir / "model.keras"
    tflite_path = args.output_dir / "model.tflite"
    classes_path = args.output_dir / "class_names.json"
    metrics_path = args.output_dir / "metrics.json"
    metadata_path = args.output_dir / "model_metadata.json"
    comparison_path = args.output_dir / "baseline_comparison.json"

    model.save(keras_path)
    classes_path.write_text(json.dumps(class_names, indent=2), encoding="utf-8")

    metrics = {
        "test_loss": round(float(test_values["loss"]), 6),
        "test_accuracy": round(float(test_values["accuracy"]), 6),
        "test_top3_accuracy": round(float(test_values["top3_accuracy"]), 6),
        "macro_f1": round(macro_f1, 6),
        "split_strategy": split_strategy,
        "confusion_matrix": matrix,
        "per_class": report,
    }
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    metadata = {
        "model": "EfficientNetB0",
        "experiment": "zimbabwe-v2-targeted-early-blight",
        "image_size": IMG_SIZE,
        "class_count": len(class_names),
        "seed": args.seed,
        "split_strategy": split_strategy,
        "early_blight_weight_boost": args.early_blight_boost,
        "requested_unfreeze_layers": args.unfreeze_layers,
        "fine_tuned_non_batchnorm_layers": fine_tuned_layers,
        "splits": {
            "train": len(train_paths),
            "validation": len(validation_paths),
            "test": len(test_paths),
        },
        "test_accuracy": metrics["test_accuracy"],
        "macro_f1": metrics["macro_f1"],
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    baseline = load_baseline(args.baseline_metrics)
    if baseline is not None:
        baseline_early = (baseline.get("per_class") or {}).get(EARLY_BLIGHT_CLASS, {})
        baseline_target = (baseline.get("per_class") or {}).get(TARGET_SPOT_CLASS, {})
        comparison = {
            "baseline": {
                "test_accuracy": baseline.get("test_accuracy"),
                "macro_f1": baseline.get("macro_f1"),
                "early_blight_recall": baseline_early.get("recall"),
                "early_blight_f1": baseline_early.get("f1"),
                "target_spot_precision": baseline_target.get("precision"),
            },
            "v2": {
                "test_accuracy": metrics["test_accuracy"],
                "macro_f1": metrics["macro_f1"],
                "early_blight_recall": early["recall"],
                "early_blight_f1": early["f1"],
                "target_spot_precision": target["precision"],
            },
            "predeclared_acceptance_targets": {
                "early_blight_recall_min": 0.80,
                "weakest_class_f1_min": 0.80,
                "overall_accuracy_floor": 0.92,
            },
        }
        comparison_path.write_text(json.dumps(comparison, indent=2), encoding="utf-8")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_path.write_bytes(converter.convert())

    weakest = sorted(report.items(), key=lambda item: item[1]["f1"])[0]
    print("\n=== CropMedic Zimbabwe v2 benchmark ===")
    print(f"Held-out benchmark accuracy: {metrics['test_accuracy']:.4f}")
    print(f"Top-3 accuracy: {metrics['test_top3_accuracy']:.4f}")
    print(f"Macro F1: {metrics['macro_f1']:.4f}")
    print(
        f"Early Blight: precision={early['precision']:.4f}, "
        f"recall={early['recall']:.4f}, f1={early['f1']:.4f}"
    )
    print(
        f"Target Spot: precision={target['precision']:.4f}, "
        f"recall={target['recall']:.4f}, f1={target['f1']:.4f}"
    )
    print(
        f"Weakest class: {weakest[0]} (f1={weakest[1]['f1']:.4f}, "
        f"recall={weakest[1]['recall']:.4f})"
    )
    print(f"Artifacts written to: {args.output_dir.resolve()}")
    print(
        "This remains a PlantVillage bootstrap benchmark. Zimbabwe field-photo "
        "validation is still required before release claims."
    )


if __name__ == "__main__":
    main()
