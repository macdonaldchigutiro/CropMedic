"""Audit a folder-based crop disease dataset before training.

Expected layout:
    data_batch1/<crop_id>/<class_name>/*.{jpg,jpeg,png,webp}

The audit is intentionally non-destructive. It checks image readability, class
counts, dimensions, formats, exact duplicates, and cross-label duplicate files.

Example:
    python audit_crop_dataset.py --data-dir data_batch1/soybean --crop-id soybean
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit a CropMedic crop dataset")
    parser.add_argument("--data-dir", type=Path, required=True)
    parser.add_argument("--crop-id", required=True)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--min-images-per-class", type=int, default=100)
    return parser.parse_args()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    args = parse_args()
    data_dir = args.data_dir.resolve()
    if not data_dir.exists():
        raise SystemExit(f"Dataset folder not found: {data_dir}")

    class_dirs = sorted(path for path in data_dir.iterdir() if path.is_dir())
    if len(class_dirs) < 2:
        raise SystemExit(
            "Expected at least two class folders directly under the crop dataset directory."
        )

    class_counts: dict[str, int] = {}
    corrupt: list[str] = []
    formats: Counter[str] = Counter()
    widths: list[int] = []
    heights: list[int] = []
    hashes: dict[str, list[tuple[str, str]]] = defaultdict(list)
    total = 0

    for class_dir in class_dirs:
        count = 0
        for path in sorted(class_dir.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            relative = str(path.relative_to(data_dir))
            try:
                with Image.open(path) as image:
                    image.verify()
                with Image.open(path) as image:
                    width, height = image.size
                    image_format = (image.format or path.suffix.lstrip(".")).upper()
                widths.append(width)
                heights.append(height)
                formats[image_format] += 1
                digest = sha256_file(path)
                hashes[digest].append((class_dir.name, relative))
                count += 1
                total += 1
            except Exception as exc:  # report rather than mutating source data
                corrupt.append(f"{relative}: {type(exc).__name__}: {exc}")
        class_counts[class_dir.name] = count

    duplicate_groups = [items for items in hashes.values() if len(items) > 1]
    cross_label_duplicates = [
        items for items in duplicate_groups if len({class_name for class_name, _ in items}) > 1
    ]

    low_count_classes = {
        name: count
        for name, count in class_counts.items()
        if count < args.min_images_per_class
    }

    report = {
        "crop_id": args.crop_id,
        "data_dir": str(data_dir),
        "class_count": len(class_counts),
        "image_count": total,
        "class_counts": class_counts,
        "formats": dict(formats),
        "image_dimensions": {
            "min_width": min(widths) if widths else None,
            "max_width": max(widths) if widths else None,
            "min_height": min(heights) if heights else None,
            "max_height": max(heights) if heights else None,
        },
        "corrupt_image_count": len(corrupt),
        "corrupt_images": corrupt[:100],
        "exact_duplicate_group_count": len(duplicate_groups),
        "cross_label_duplicate_group_count": len(cross_label_duplicates),
        "cross_label_duplicates": cross_label_duplicates[:100],
        "low_count_classes": low_count_classes,
        "ready_for_pilot_training": (
            total > 0
            and not corrupt
            and not cross_label_duplicates
            and not low_count_classes
        ),
        "notes": [
            "Exact duplicate detection does not catch near-duplicate crops or augmented copies.",
            "Keep geographic/external validation data outside this training directory.",
            "A passing audit does not prove field readiness or label correctness.",
        ],
    }

    output = args.output or (data_dir.parent / f"{args.crop_id}_audit.json")
    output.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"Crop: {args.crop_id}")
    print(f"Images: {total}")
    print(f"Classes: {len(class_counts)}")
    for name, count in class_counts.items():
        print(f"  {name}: {count}")
    print(f"Corrupt images: {len(corrupt)}")
    print(f"Exact duplicate groups: {len(duplicate_groups)}")
    print(f"Cross-label duplicate groups: {len(cross_label_duplicates)}")
    print(f"Low-count classes: {low_count_classes or 'none'}")
    print(f"Pilot audit ready: {report['ready_for_pilot_training']}")
    print(f"Report: {output.resolve()}")


if __name__ == "__main__":
    main()
