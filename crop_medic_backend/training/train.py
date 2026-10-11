"""Train and evaluate the CropMedic crop-disease classifier.

Expected dataset layout:

    data/
      Corn_(maize)___Northern_Leaf_Blight/
        image1.jpg
        ...
      Corn_(maize)___healthy/
        ...
      Tomato___Early_blight/
        ...

The script creates deterministic, per-class train/validation/test splits so the
final test set is never used to tune the model. It exports a Keras model,
TFLite model, class names, and per-class evaluation metrics.

Example:
    python train.py --data-dir data --output-dir artifacts
"""

from __future__ import annotations

import argparse
import json
import random
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

IMG_SIZE = 224
DEFAULT_BATCH = 32
DEFAULT_SEED = 42
VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train the CropMedic classifier")
    parser.add_argument("--data-dir", type=Path, default=Path("data"))
    parser.add_argument("--output-dir", type=Path, default=Path("artifacts"))
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH)
    parser.add_argument("--head-epochs", type=int, default=12)
    parser.add_argument("--fine-epochs", type=int, default=12)
    parser.add_argument("--validation-fraction", type=float, default=0.15)
    parser.add_argument("--test-fraction", type=float, default=0.15)
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    return parser.parse_args()


def discover_dataset(data_dir: Path) -> tuple[list[str], dict[str, list[Path]]]:
    if not data_dir.exists():
        raise FileNotFoundError(f"Dataset directory does not exist: {data_dir}")

    classes: dict[str, list[Path]] = {}
    for class_dir in sorted(path for path in data_dir.iterdir() if path.is_dir()):
        files = sorted(
            path
            for path in class_dir.rglob("*")
            if path.is_file() and path.suffix.lower() in VALID_EXTENSIONS
        )
        if files:
            classes[class_dir.name] = files

    if len(classes) < 2:
        raise ValueError("Training requires at least two non-empty class folders.")

    too_small = {name: len(files) for name, files in classes.items() if len(files) < 10}
    if too_small:
        details = ", ".join(f"{name}={count}" for name, count in too_small.items())
        raise ValueError(
            "Each class needs at least 10 images so train/validation/test all contain "
            f"examples. Too small: {details}"
        )

    return list(classes.keys()), classes


def stratified_split(
    classes: dict[str, list[Path]],
    class_names: list[str],
    validation_fraction: float,
    test_fraction: float,
    seed: int,
) -> dict[str, tuple[list[str], list[int]]]:
    if validation_fraction <= 0 or test_fraction <= 0:
        raise ValueError("Validation and test fractions must both be greater than zero.")
    if validation_fraction + test_fraction >= 0.5:
        raise ValueError("Validation + test fraction must be less than 0.5.")

    rng = random.Random(seed)
    splits: dict[str, tuple[list[str], list[int]]] = {
        "train": ([], []),
        "validation": ([], []),
        "test": ([], []),
    }

    for label, class_name in enumerate(class_names):
        files = list(classes[class_name])
        rng.shuffle(files)
        count = len(files)
        test_count = max(1, int(round(count * test_fraction)))
        validation_count = max(1, int(round(count * validation_fraction)))
        train_count = count - validation_count - test_count
        if train_count < 1:
            raise ValueError(f"Not enough images to split class {class_name}.")

        class_parts = {
            "train": files[:train_count],
            "validation": files[train_count : train_count + validation_count],
            "test": files[train_count + validation_count :],
        }
        for split_name, split_files in class_parts.items():
            paths, labels = splits[split_name]
            paths.extend(str(path) for path in split_files)
            labels.extend([label] * len(split_files))

    # Shuffle each split deterministically so classes are interleaved.
    for offset, split_name in enumerate(("train", "validation", "test")):
        paths, labels = splits[split_name]
        paired = list(zip(paths, labels))
        random.Random(seed + offset + 1).shuffle(paired)
        if paired:
            new_paths, new_labels = zip(*paired)
            splits[split_name] = (list(new_paths), list(new_labels))

    return splits


def decode_image(path: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    image = tf.io.read_file(path)
    image = tf.io.decode_image(image, channels=3, expand_animations=False)
    image.set_shape([None, None, 3])
    image = tf.image.resize(image, (IMG_SIZE, IMG_SIZE), antialias=True)
    image = tf.cast(image, tf.float32)
    return image, label


def make_dataset(
    paths: list[str],
    labels: list[int],
    batch_size: int,
    training: bool,
    seed: int,
) -> tf.data.Dataset:
    dataset = tf.data.Dataset.from_tensor_slices((paths, labels))
    if training:
        dataset = dataset.shuffle(
            buffer_size=len(paths), seed=seed, reshuffle_each_iteration=True
        )
    dataset = dataset.map(decode_image, num_parallel_calls=tf.data.AUTOTUNE)
    dataset = dataset.batch(batch_size)
    return dataset.prefetch(tf.data.AUTOTUNE)


def compute_class_weights(labels: list[int], class_count: int) -> dict[int, float]:
    counts = Counter(labels)
    total = len(labels)
    return {
        index: total / (class_count * counts[index])
        for index in range(class_count)
        if counts[index] > 0
    }


def build_model(class_count: int) -> tuple[tf.keras.Model, tf.keras.Model]:
    augment = tf.keras.Sequential(
        [
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.12),
            layers.RandomZoom(0.15),
            layers.RandomContrast(0.2),
            layers.RandomBrightness(0.15),
        ],
        name="augmentation",
    )

    base = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3), include_top=False, weights="imagenet"
    )
    base.trainable = False

    inputs = layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3), name="image")
    x = augment(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.35)(x)
    outputs = layers.Dense(class_count, activation="softmax", name="disease")(x)
    return models.Model(inputs, outputs, name="crop_medic"), base


def callbacks(output_dir: Path, phase: str) -> list[tf.keras.callbacks.Callback]:
    return [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=4, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.3, patience=2, min_lr=1e-7
        ),
        tf.keras.callbacks.CSVLogger(str(output_dir / f"training_{phase}.csv")),
    ]


def classification_metrics(
    y_true: np.ndarray, y_pred: np.ndarray, class_names: list[str]
) -> tuple[list[list[int]], dict[str, dict[str, float | int]]]:
    class_count = len(class_names)
    matrix = np.zeros((class_count, class_count), dtype=np.int64)
    for truth, prediction in zip(y_true, y_pred):
        matrix[int(truth), int(prediction)] += 1

    report: dict[str, dict[str, float | int]] = {}
    for index, class_name in enumerate(class_names):
        tp = int(matrix[index, index])
        fp = int(matrix[:, index].sum() - tp)
        fn = int(matrix[index, :].sum() - tp)
        support = int(matrix[index, :].sum())
        precision = tp / (tp + fp) if tp + fp else 0.0
        recall = tp / (tp + fn) if tp + fn else 0.0
        f1 = (
            2 * precision * recall / (precision + recall)
            if precision + recall
            else 0.0
        )
        report[class_name] = {
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1": round(f1, 4),
            "support": support,
        }

    return matrix.tolist(), report


def main() -> None:
    args = parse_args()
    tf.keras.utils.set_random_seed(args.seed)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    class_names, classes = discover_dataset(args.data_dir)
    splits = stratified_split(
        classes,
        class_names,
        args.validation_fraction,
        args.test_fraction,
        args.seed,
    )

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
    model, base = build_model(len(class_names))

    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.head_epochs,
        class_weight=class_weights,
        callbacks=callbacks(args.output_dir, "head"),
    )

    base.trainable = True
    for layer in base.layers[:-35]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.fine_epochs,
        class_weight=class_weights,
        callbacks=callbacks(args.output_dir, "fine"),
    )

    test_loss, test_accuracy = model.evaluate(test_ds, verbose=1)
    probabilities = model.predict(test_ds, verbose=1)
    predictions = np.argmax(probabilities, axis=1)
    y_true = np.asarray(test_labels, dtype=np.int64)
    matrix, report = classification_metrics(y_true, predictions, class_names)

    keras_path = args.output_dir / "model.keras"
    tflite_path = args.output_dir / "model.tflite"
    classes_path = args.output_dir / "class_names.json"
    metrics_path = args.output_dir / "metrics.json"
    metadata_path = args.output_dir / "model_metadata.json"

    model.save(keras_path)
    classes_path.write_text(json.dumps(class_names, indent=2), encoding="utf-8")

    metrics = {
        "test_loss": round(float(test_loss), 6),
        "test_accuracy": round(float(test_accuracy), 6),
        "confusion_matrix": matrix,
        "per_class": report,
    }
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    metadata = {
        "model": "MobileNetV2",
        "image_size": IMG_SIZE,
        "class_count": len(class_names),
        "seed": args.seed,
        "splits": {
            "train": len(train_paths),
            "validation": len(validation_paths),
            "test": len(test_paths),
        },
        "test_accuracy": round(float(test_accuracy), 6),
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_path.write_bytes(converter.convert())

    macro_f1 = float(np.mean([item["f1"] for item in report.values()]))
    print(f"Held-out test accuracy: {test_accuracy:.4f}")
    print(f"Macro F1: {macro_f1:.4f}")
    print(f"Artifacts written to: {args.output_dir.resolve()}")
    print(
        "Do not promote this model to production based on accuracy alone; review "
        "metrics.json for weak disease classes and validate against real field photos."
    )


if __name__ == "__main__":
    main()
