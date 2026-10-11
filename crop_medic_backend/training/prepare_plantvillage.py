"""Download and prepare PlantVillage for a CropMedic training profile.

Example:
    pip install -r requirements-training.txt
    python prepare_plantvillage.py --profile zimbabwe-v1 --output-dir data

The script uses TensorFlow Datasets, exports only classes included by the
selected profile, and writes them into class folders expected by train.py.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import tensorflow_datasets as tfds
from PIL import Image

BASE = Path(__file__).parent
PROFILES_DIR = BASE / "profiles"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare PlantVillage for CropMedic")
    parser.add_argument("--profile", default="zimbabwe-v1")
    parser.add_argument("--output-dir", type=Path, default=Path("data"))
    return parser.parse_args()


def load_profile(name: str) -> dict:
    path = PROFILES_DIR / f"{name}.json"
    if not path.exists():
        raise FileNotFoundError(f"Unknown training profile: {name} ({path})")
    profile = json.loads(path.read_text(encoding="utf-8"))
    prefixes = profile.get("crop_prefixes") or []
    if not prefixes:
        raise ValueError(f"Profile {name} has no crop_prefixes.")
    return profile


def main() -> None:
    args = parse_args()
    profile = load_profile(args.profile)
    prefixes = tuple(profile["crop_prefixes"])
    args.output_dir.mkdir(parents=True, exist_ok=True)

    print("Downloading/loading PlantVillage via TensorFlow Datasets...")
    builder = tfds.builder("plant_village")
    builder.download_and_prepare()
    dataset = builder.as_dataset(split="train", as_supervised=True)
    label_names = builder.info.features["label"].names

    selected_names = [name for name in label_names if name.startswith(prefixes)]
    expected_count = profile.get("expected_class_count")
    if expected_count is not None and len(selected_names) != int(expected_count):
        raise RuntimeError(
            f"Profile expected {expected_count} classes but PlantVillage exposed "
            f"{len(selected_names)} selected classes. Selected: {selected_names}"
        )

    counters: Counter[str] = Counter()
    print(f"Preparing {len(selected_names)} selected classes for {profile['id']}...")

    for image, label in tfds.as_numpy(dataset):
        class_name = label_names[int(label)]
        if not class_name.startswith(prefixes):
            continue

        class_dir = args.output_dir / class_name
        class_dir.mkdir(parents=True, exist_ok=True)
        index = counters[class_name]
        output_path = class_dir / f"plantvillage_{index:05d}.jpg"
        Image.fromarray(image).convert("RGB").save(output_path, quality=95)
        counters[class_name] += 1

    missing = [name for name in selected_names if counters[name] == 0]
    if missing:
        raise RuntimeError(f"No images exported for selected classes: {missing}")

    print("\nPrepared dataset:")
    for name in selected_names:
        print(f"  {name}: {counters[name]} images")
    print(f"\nOutput: {args.output_dir.resolve()}")
    print(
        "PlantVillage is a bootstrap dataset. Before public release, validate the "
        "model on ordinary Zimbabwe field photos from real phones and backgrounds."
    )


if __name__ == "__main__":
    main()
