"""Prepare the lightweight BLD-BD Common Bean pilot dataset.

Source:
  BLD-BD: A Field-Based Image Dataset of Bean Leaf Diseases for Deep Learning
  & Computer Vision Research
  Mendeley Data DOI: 10.17632/3k46s46x3s.1
  CC BY 4.0

Use the ORIGINAL dataset only for the first pilot baseline:
  Original_Bean_Leaf_Disease_Dataset.zip

The original set contains 672 field-derived images, balanced across:
  - Angular Leaf Spot
  - Bean Common Mosaic Virus
  - Healthy

Do not train on the augmented ZIP for the baseline because derivatives of the
same original image can leak across train/validation/test splits.

Example:
  python prepare_common_bean_bldbd.py --zip-path "C:\\Users\\Macdee\\Downloads\\Original_Bean_Leaf_Disease_Dataset.zip"
"""
from __future__ import annotations

import argparse
import re
import shutil
import zipfile
from pathlib import Path

DATASET_PAGE = "https://data.mendeley.com/datasets/3k46s46x3s/1"
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}

CLASS_RULES = {
    "Angular Leaf Spot": {
        "angularleafspot",
        "angularleafspotdisease",
        "als",
    },
    "Bean Common Mosaic Virus": {
        "beancommonmosaicvirus",
        "commonmosaicvirus",
        "mosaicvirus",
        "bcmv",
    },
    "Healthy": {
        "healthy",
        "healthyleaf",
        "healthyleaves",
        "hlt",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare BLD-BD Common Bean pilot data")
    parser.add_argument("--zip-path", type=Path, required=True)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("data_batch1/common_bean"),
    )
    return parser.parse_args()


def _norm(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def _classify(name: str) -> str | None:
    path = Path(name)
    candidates = [_norm(part) for part in path.parts]
    candidates.append(_norm(path.stem))

    for label, tokens in CLASS_RULES.items():
        for candidate in candidates:
            if candidate in tokens:
                return label
        for token in tokens:
            if len(token) >= 3 and any(candidate.startswith(token) for candidate in candidates):
                return label
    return None


def main() -> None:
    args = parse_args()
    zip_path = args.zip_path.expanduser().resolve()
    if not zip_path.exists():
        raise SystemExit(f"ZIP not found: {zip_path}")

    if "augmented" in zip_path.name.lower():
        raise SystemExit(
            "Use Original_Bean_Leaf_Disease_Dataset.zip for the first baseline, "
            "not the augmented archive."
        )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    counts = {label: 0 for label in CLASS_RULES}
    unmatched: list[str] = []

    print(f"Using ZIP: {zip_path}")
    print(f"Source: {DATASET_PAGE}")

    try:
        with zipfile.ZipFile(zip_path) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                suffix = Path(info.filename).suffix.lower()
                if suffix not in IMAGE_SUFFIXES:
                    continue

                label = _classify(info.filename)
                if label is None:
                    if len(unmatched) < 30:
                        unmatched.append(info.filename)
                    continue

                target_dir = args.output_dir / label
                target_dir.mkdir(parents=True, exist_ok=True)
                counts[label] += 1
                target = target_dir / f"{_norm(label)}_{counts[label]:05d}{suffix}"
                with archive.open(info) as src, target.open("wb") as dst:
                    shutil.copyfileobj(src, dst, length=1024 * 1024)
    except zipfile.BadZipFile as exc:
        raise SystemExit(f"Not a readable ZIP: {zip_path}") from exc

    total = sum(counts.values())
    print("Prepared Common Bean pilot dataset:")
    for label, count in counts.items():
        print(f"  {label}: {count}")
    print(f"  TOTAL: {total}")
    print(f"Output: {args.output_dir.resolve()}")

    if total == 0:
        if unmatched:
            print("\nFirst unmatched image paths:")
            for name in unmatched:
                print(f"  {name}")
        raise SystemExit(
            "No classed images were found. Send the unmatched paths so the label "
            "mapping can be adjusted."
        )

    missing = [label for label, count in counts.items() if count == 0]
    if missing:
        raise SystemExit(
            "Preparation was incomplete. Missing classes: " + ", ".join(missing)
        )

    print("Next: python audit_crop_dataset.py --data-dir data_batch1/common_bean --crop-id common_bean")


if __name__ == "__main__":
    main()
