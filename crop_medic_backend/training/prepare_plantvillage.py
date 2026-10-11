"""Download and prepare PlantVillage for a CropMedic training profile.

Example:
    python -m pip install -r requirements-training.txt
    python prepare_plantvillage.py --profile zimbabwe-v1 --output-dir data

The script uses the maintained Hugging Face PlantVillage dataset rather than
TensorFlow Datasets' legacy Mendeley download URL. It exports only classes in
the selected CropMedic profile into class folders expected by train.py.

A manifest is also written with the original Hugging Face split and leaf_id so
we can preserve leaf-grouped evaluation as the training pipeline evolves.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path

from datasets import load_dataset

BASE = Path(__file__).parent
PROFILES_DIR = BASE / "profiles"
DATASET_ID = "mohanty/PlantVillage"
DATASET_CONFIG = "color"


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


def label_name(example: dict, label_names: list[str] | None) -> str:
    label = example["label"]
    if isinstance(label, str):
        return label
    if label_names is None:
        raise RuntimeError("PlantVillage label metadata is unavailable.")
    return label_names[int(label)]


def main() -> None:
    args = parse_args()
    profile = load_profile(args.profile)
    prefixes = tuple(profile["crop_prefixes"])
    args.output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Downloading/loading {DATASET_ID} ({DATASET_CONFIG}) via Hugging Face...")
    dataset = load_dataset(DATASET_ID, DATASET_CONFIG)

    if "train" not in dataset:
        raise RuntimeError("PlantVillage did not expose the expected train split.")

    label_feature = dataset["train"].features.get("label")
    label_names = getattr(label_feature, "names", None)

    if label_names:
        selected_names = sorted(name for name in label_names if name.startswith(prefixes))
    else:
        discovered = set()
        for split in dataset.values():
            for example in split:
                name = label_name(example, None)
                if name.startswith(prefixes):
                    discovered.add(name)
        selected_names = sorted(discovered)

    expected_count = profile.get("expected_class_count")
    if expected_count is not None and len(selected_names) != int(expected_count):
        raise RuntimeError(
            f"Profile expected {expected_count} classes but PlantVillage exposed "
            f"{len(selected_names)} selected classes. Selected: {selected_names}"
        )

    counters: Counter[str] = Counter()
    manifest_rows: list[dict[str, str]] = []
    print(f"Preparing {len(selected_names)} selected classes for {profile['id']}...")

    for split_name, split in dataset.items():
        print(f"Processing source split: {split_name} ({len(split)} rows)")
        for example in split:
            class_name = label_name(example, label_names)
            if not class_name.startswith(prefixes):
                continue

            class_dir = args.output_dir / class_name
            class_dir.mkdir(parents=True, exist_ok=True)
            index = counters[class_name]
            output_path = class_dir / f"plantvillage_{index:05d}.jpg"

            image = example["image"].convert("RGB")
            image.save(output_path, format="JPEG", quality=95)
            counters[class_name] += 1

            manifest_rows.append(
                {
                    "path": str(output_path.relative_to(args.output_dir)),
                    "class_name": class_name,
                    "source_split": split_name,
                    "leaf_id": str(example.get("leaf_id", "")),
                }
            )

    missing = [name for name in selected_names if counters[name] == 0]
    if missing:
        raise RuntimeError(f"No images exported for selected classes: {missing}")

    manifest_path = args.output_dir / "plantvillage_manifest.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["path", "class_name", "source_split", "leaf_id"],
        )
        writer.writeheader()
        writer.writerows(manifest_rows)

    print("\nPrepared dataset:")
    for name in selected_names:
        print(f"  {name}: {counters[name]} images")
    print(f"\nOutput: {args.output_dir.resolve()}")
    print(f"Manifest: {manifest_path.resolve()}")
    print(
        "PlantVillage is a bootstrap dataset. Before public release, validate the "
        "model on ordinary Zimbabwe field photos from real phones and backgrounds."
    )


if __name__ == "__main__":
    main()
