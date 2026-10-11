"""Train and evaluate the CropMedic crop-disease classifier.

Expected dataset layout:

    data/
      Corn_(maize)___Northern_Leaf_Blight/
        image1.jpg
        ...
      Tomato___Early_blight/
        ...

When data/plantvillage_manifest.json is present, the script preserves the
official PlantVillage test split and creates validation data only from the
official training split. For other datasets it falls back to deterministic,
per-class train/validation/test splits.

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
MANIFEST_NAME = "plantvillage_manifest.json"


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


def shuffle_split(
    paths: list[str], labels: list[int], seed: int
) -> tuple[list[str], list[int]]:
    paired = list(zip(paths, labels))
    random.Random(seed).shuffle(paired)
    if not paired:
        return [], []
    shuffled_paths, shuffled_labels = zip(*paired)
    return list(shuffled_paths), list(shuffled_labels)


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

    for offset, split_name in enumerate(("train", "validation", "test")):
        paths, labels = splits[split_name]
        splits[split_name] = shuffle_split(paths, labels, seed + offset + 1)

    return splits


def split_from_plantvillage_manifest(
    data_dir: Path,
    class_names: list[str],
    validation_fraction: float,
    seed: int,
) -> dict[str, tuple[list[str], list[int]]]:
    if validation_fraction <= 0 or validation_fraction >= 0.5:
        raise ValueError("Validation fraction must be greater than 0 and less than 0.5.")

    manifest_path = data_dir / MANIFEST_NAME
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    records = payload.get("records") or []
    if not records:
        raise ValueError(f"{manifest_path} contains no records.")

    class_to_label = {name: index for index, name in enumerate(class_names)}
    official_train: dict[str, list[Path]] = {name: [] for name in class_names}
    official_test: dict[str, list[Path]] = {name: [] for name in class_names}

    for record in records:
        class_name = record.get("class_name")
        source_split = record.get("source_split")
        relative_path = record.get("path")
        if class_name not in class_to_label:
            raise ValueError(f"Manifest contains unknown class: {class_name}")
        if source_split not in {"train", "test"}:
            raise ValueError(f"Manifest contains invalid source split: {source_split}")
        if not relative_path:
            raise ValueError("Manifest contains a record without a path.")

        image_path = data_dir / Path(relative_path)
        if not image_path.exists():
            raise FileNotFoundError(f"Manifest image is missing: {image_path}")

        target = official_train if source_split == "train" else official_test
        target[class_name].append(image_path)

    splits: dict[str, tuple[list[str], list[int]]] = {
        "train": ([], []),
        "validation": ([], []),
        "test": ([], []),
    }

    for label, class_name in enumerate(class_names):
        train_candidates = list(official_train[class_name])
        test_files = list(official_test[class_name])
        if len(train_candidates) < 2:
            raise ValueError(
                f"Official PlantVillage train split has too few images for {class_name}."
            )
        if not test_files:
            raise ValueError(
                f"Official PlantVillage test split has no images for {class_name}."
            )

        random.Random(seed + label).shuffle(train_candidates)
        validation_count = max(1, int(round(len(train_candidates) * validation_fraction)))
        if validation_count >= len(train_candidates):
            validation_count = len(train_candidates) - 1

        validation_files = train_candidates[:validation_count]
        train_files = train_candidates[validation_count:]

        for split_name, split_files in (
            ("train", train_files),
            ("validation", validation_files),
            ("test", test_files),
        ):
            paths, labels = splits[split_name]
            paths.extend(str(path) for path in split_files)
            labels.extend([label] * len(split_files))

    for offset, split_name in enumerate(("train", "validation", "test")):
        paths, labels = splits[split_name]
        splits[split_name] = shuffle_split(paths, labels, seed + 100 + offset)

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
    if split_strategy == "plantvillage_official_test":
        print("Held-out test set: official PlantVillage color test split")

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

    macro_f1 = float(np.mean([item["f1"] for item in report.values()]))
    metrics = {
        "test_loss": round(float(test_loss), 6),
        "test_accuracy": round(float(test_accuracy), 6),
        "macro_f1": round(macro_f1, 6),
        "split_strategy": split_strategy,
        "confusion_matrix": matrix,
        "per_class": report,
    }
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    metadata = {
        "model": "MobileNetV2",
        "image_size": IMG_SIZE,
        "class_count": len(class_names),
        "seed": args.seed,
        "split_strategy": split_strategy,
        "splits": {
            "train": len(train_paths),
            "validation": len(validation_paths),
            "test": len(test_paths),
        },
        "test_accuracy": round(float(test_accuracy), 6),
        "macro_f1": round(macro_f1, 6),
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_path.write_bytes(converter.convert())

    print(f"Held-out test accuracy: {test_accuracy:.4f}")
    print(f"Macro F1: {macro_f1:.4f}")
    print(f"Artifacts written to: {args.output_dir.resolve()}")
    print(
        "Do not promote this model to production based on accuracy alone; review "
        "metrics.json for weak disease classes and validate against real field photos."
    )


if __name__ == "__main__":
    main()
