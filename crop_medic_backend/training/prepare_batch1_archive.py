"""Safely stage vetted Batch-1 crop archives into class folders.

This helper intentionally does not guess unknown labels. It supports the crops
whose source classes are already recorded in zimbabwe-v3-batch1-sources.json.
If an archive uses unexpected folder names, the script stops and prints sample
paths rather than silently mislabelling images.

Examples:
  python prepare_batch1_archive.py --crop-id soybean --zip-path C:\\Downloads\\soybean.zip
  python prepare_batch1_archive.py --crop-id wheat --zip-path C:\\Downloads\\wheat.zip
  python prepare_batch1_archive.py --crop-id sorghum --zip-path C:\\Downloads\\sorghum.zip
"""
from __future__ import annotations

import argparse
import re
import shutil
import zipfile
from collections import Counter
from pathlib import Path

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}

PROFILES = {
    "soybean": {
        "Healthy": {"healthy", "healthyleaf", "healthyleaves"},
        "Bacterial Blight": {"bacterialblight", "bacterialblightdisease"},
        "Cercospora Leaf Blight": {"cercosporaleafblight", "cercospora"},
        "Sudden Death Syndrome": {"suddendeathsyndrome", "sds"},
        "Soybean Rust": {"soybeanrust", "rust"},
    },
    "wheat": {
        "Healthy": {"healthy", "healthyleaf", "healthyleaves"},
        "Stripe Rust": {"striperust", "yellowrust"},
        "Septoria": {"septoria", "septorialeafblotch"},
    },
    "sorghum": {
        "Anthracnose and Red Rot": {"anthracnoseandredrot", "anthracnoseredrot"},
        "Cereal Grain Molds": {"cerealgrainmolds", "grainmolds", "grainmold"},
        "Covered Kernel Smut": {"coveredkernelsmut"},
        "Head Smut": {"headsmut"},
        "Loose Smut": {"loosesmut"},
        "Rust": {"rust", "sorghumrust"},
    },
}


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--crop-id", choices=sorted(PROFILES), required=True)
    p.add_argument("--zip-path", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, default=None)
    p.add_argument("--replace", action="store_true")
    return p.parse_args()


def norm(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def classify(member_name: str, rules: dict[str, set[str]]) -> str | None:
    path = Path(member_name)
    candidates = [norm(part) for part in path.parts if part not in {"", "."}]
    candidates.append(norm(path.stem))

    exact_hits: list[str] = []
    substring_hits: list[str] = []
    for label, aliases in rules.items():
        if any(candidate in aliases for candidate in candidates):
            exact_hits.append(label)
            continue
        for alias in aliases:
            if len(alias) >= 5 and any(alias in candidate for candidate in candidates):
                substring_hits.append(label)
                break

    hits = list(dict.fromkeys(exact_hits or substring_hits))
    return hits[0] if len(hits) == 1 else None


def main():
    args = parse_args()
    zip_path = args.zip_path.expanduser().resolve()
    if not zip_path.exists():
        raise SystemExit(f"ZIP not found: {zip_path}")

    output_dir = args.output_dir or Path("data_batch1") / args.crop_id
    if output_dir.exists() and any(output_dir.iterdir()):
        if not args.replace:
            raise SystemExit(
                f"Output is not empty: {output_dir}. Use --replace only after checking the path."
            )
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    rules = PROFILES[args.crop_id]
    counts = {name: 0 for name in rules}
    unmapped_images: list[str] = []
    folder_samples: Counter[str] = Counter()
    nested_zips: list[str] = []

    try:
        archive = zipfile.ZipFile(zip_path)
    except zipfile.BadZipFile as exc:
        raise SystemExit(f"Not a readable ZIP: {zip_path}") from exc

    with archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            suffix = Path(info.filename).suffix.lower()
            if suffix == ".zip":
                nested_zips.append(info.filename)
                continue
            if suffix not in IMAGE_SUFFIXES:
                continue

            for part in Path(info.filename).parts[:-1]:
                if part not in {"", "."}:
                    folder_samples[part] += 1

            label = classify(info.filename, rules)
            if label is None:
                if len(unmapped_images) < 40:
                    unmapped_images.append(info.filename)
                continue

            target_dir = output_dir / label
            target_dir.mkdir(parents=True, exist_ok=True)
            index = counts[label] + 1
            target = target_dir / f"{args.crop_id}_{norm(label)}_{index:06d}{suffix}"
            while target.exists():
                index += 1
                target = target_dir / f"{args.crop_id}_{norm(label)}_{index:06d}{suffix}"
            with archive.open(info) as src, target.open("wb") as dst:
                shutil.copyfileobj(src, dst, length=1024 * 1024)
            counts[label] += 1

    total = sum(counts.values())
    print(f"Crop: {args.crop_id}")
    print(f"ZIP: {zip_path}")
    print("Prepared classes:")
    for label, count in counts.items():
        print(f"  {label}: {count}")
    print(f"  TOTAL: {total}")
    print(f"Output: {output_dir.resolve()}")

    missing = [label for label, count in counts.items() if count == 0]
    if nested_zips:
        print("Nested ZIP files detected (not automatically expanded):")
        for name in nested_zips[:10]:
            print(f"  {name}")
    if unmapped_images:
        print("Sample image paths that were deliberately NOT mapped:")
        for name in unmapped_images[:20]:
            print(f"  {name}")
    if missing or total == 0 or unmapped_images:
        print("Most common archive folders:")
        for name, count in folder_samples.most_common(20):
            print(f"  {name}: {count}")
        raise SystemExit(
            "Dataset staging needs review before training. No uncertain labels were guessed."
        )

    print(
        f"Next: python audit_crop_dataset.py --data-dir {output_dir} --crop-id {args.crop_id}"
    )


if __name__ == "__main__":
    main()
