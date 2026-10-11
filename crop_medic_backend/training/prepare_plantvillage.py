"""Download and prepare PlantVillage for a CropMedic training profile.

This downloader deliberately bypasses the Hugging Face Datasets config loader.
The PlantVillage repository currently exposes the archive and official split
files directly, which is more stable than relying on dataset config discovery.

Example:
    python prepare_plantvillage.py --profile zimbabwe-v1 --output-dir data

The script downloads the PlantVillage archive from Hugging Face, reads the
official color_train/color_test split files, exports only classes included by
the selected CropMedic profile, and writes a manifest that preserves the
official test split for train.py.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import time
import zipfile
from collections import Counter
from pathlib import Path, PurePosixPath

# Hugging Face's default timeout is too short for a multi-GB archive on a
# variable connection. Set this before importing huggingface_hub so its client
# uses the longer timeout. Existing partial downloads in the HF cache are reused.
os.environ.setdefault("HF_HUB_DOWNLOAD_TIMEOUT", "120")
os.environ.setdefault("HF_HUB_ETAG_TIMEOUT", "30")

from huggingface_hub import hf_hub_download
from PIL import Image

BASE = Path(__file__).parent
PROFILES_DIR = BASE / "profiles"
DATASET_ID = "mohanty/PlantVillage"
ARCHIVE_FILE = "data.zip"
TRAIN_SPLIT_FILE = "splits/color_train.txt"
TEST_SPLIT_FILE = "splits/color_test.txt"
MANIFEST_NAME = "plantvillage_manifest.json"
DOWNLOAD_ATTEMPTS = 8
RETRY_WAIT_SECONDS = 15


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


def download_repo_file(filename: str) -> Path:
    """Download one dataset file, resuming cached partial downloads after drops."""
    last_error: Exception | None = None

    for attempt in range(1, DOWNLOAD_ATTEMPTS + 1):
        try:
            path = hf_hub_download(
                repo_id=DATASET_ID,
                filename=filename,
                repo_type="dataset",
            )
            return Path(path)
        except Exception as exc:
            last_error = exc
            if attempt == DOWNLOAD_ATTEMPTS:
                break

            print(
                f"\nDownload interrupted for {filename} "
                f"(attempt {attempt}/{DOWNLOAD_ATTEMPTS})."
            )
            print(
                "The partial Hugging Face cache is kept; the next attempt will "
                "resume it when possible."
            )
            print(f"Retrying in {RETRY_WAIT_SECONDS} seconds...\n")
            time.sleep(RETRY_WAIT_SECONDS)

    raise RuntimeError(
        f"Could not finish downloading {filename} after {DOWNLOAD_ATTEMPTS} attempts. "
        "Your partial download remains cached, so rerunning this script later should "
        "resume rather than restart."
    ) from last_error


def read_split_file(path: Path) -> list[str]:
    return [
        line.strip().replace("\\", "/")
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def class_name_from_source_path(source_path: str) -> str:
    parts = PurePosixPath(source_path).parts
    if len(parts) < 4 or parts[0] != "raw" or parts[1] != "color":
        raise ValueError(f"Unexpected PlantVillage color path: {source_path}")
    return parts[2]


def selected_records(
    source_paths: list[str], source_split: str, prefixes: tuple[str, ...]
) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for source_path in source_paths:
        class_name = class_name_from_source_path(source_path)
        if class_name.startswith(prefixes):
            records.append(
                {
                    "source_split": source_split,
                    "source_path": source_path,
                    "class_name": class_name,
                }
            )
    return records


def main() -> None:
    args = parse_args()
    profile = load_profile(args.profile)
    prefixes = tuple(profile["crop_prefixes"])
    args.output_dir.mkdir(parents=True, exist_ok=True)

    print("Downloading PlantVillage color archive and official splits from Hugging Face...")
    print("The archive is about 2.2 GB on first download; cached downloads are reused.")
    print("Interrupted downloads are retried and resumed from the Hugging Face cache.")

    train_split_path = download_repo_file(TRAIN_SPLIT_FILE)
    test_split_path = download_repo_file(TEST_SPLIT_FILE)
    archive_path = download_repo_file(ARCHIVE_FILE)

    records = selected_records(read_split_file(train_split_path), "train", prefixes)
    records.extend(selected_records(read_split_file(test_split_path), "test", prefixes))

    selected_names = sorted({record["class_name"] for record in records})
    expected_count = profile.get("expected_class_count")
    if expected_count is not None and len(selected_names) != int(expected_count):
        raise RuntimeError(
            f"Profile expected {expected_count} classes but the official color splits "
            f"contained {len(selected_names)} selected classes. Selected: {selected_names}"
        )

    if not records:
        raise RuntimeError("No PlantVillage images matched the selected profile.")

    counters: Counter[tuple[str, str]] = Counter()
    class_totals: Counter[str] = Counter()
    split_totals: Counter[str] = Counter()
    manifest_records: list[dict[str, str]] = []

    print(f"Exporting {len(selected_names)} classes for {profile['id']}...")

    with zipfile.ZipFile(archive_path, "r") as archive:
        archive_names = set(archive.namelist())
        missing_sources = [
            record["source_path"]
            for record in records
            if record["source_path"] not in archive_names
        ]
        if missing_sources:
            preview = ", ".join(missing_sources[:5])
            raise RuntimeError(
                f"{len(missing_sources)} official split paths were not found in data.zip. "
                f"Examples: {preview}"
            )

        for record in records:
            class_name = record["class_name"]
            source_split = record["source_split"]
            source_path = record["source_path"]

            class_dir = args.output_dir / class_name
            class_dir.mkdir(parents=True, exist_ok=True)

            index = counters[(class_name, source_split)]
            output_name = f"plantvillage_{source_split}_{index:05d}.jpg"
            output_path = class_dir / output_name

            with archive.open(source_path) as source:
                image_bytes = source.read()
            with Image.open(io.BytesIO(image_bytes)) as image:
                image.convert("RGB").save(output_path, format="JPEG", quality=95)

            relative_output = output_path.relative_to(args.output_dir).as_posix()
            manifest_records.append(
                {
                    "path": relative_output,
                    "class_name": class_name,
                    "source_split": source_split,
                    "source_path": source_path,
                }
            )
            counters[(class_name, source_split)] += 1
            class_totals[class_name] += 1
            split_totals[source_split] += 1

    manifest = {
        "dataset": DATASET_ID,
        "variant": "color",
        "profile": profile["id"],
        "official_split_preserved": True,
        "classes": selected_names,
        "counts": {
            "train": split_totals["train"],
            "test": split_totals["test"],
            "total": len(manifest_records),
        },
        "records": manifest_records,
    }
    manifest_path = args.output_dir / MANIFEST_NAME
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print("\nPrepared dataset:")
    for name in selected_names:
        train_count = counters[(name, "train")]
        test_count = counters[(name, "test")]
        print(
            f"  {name}: train={train_count}, test={test_count}, "
            f"total={class_totals[name]}"
        )

    print(
        f"\nTotals: train={split_totals['train']}, test={split_totals['test']}, "
        f"total={len(manifest_records)}"
    )
    print(f"Output: {args.output_dir.resolve()}")
    print(f"Manifest: {manifest_path.resolve()}")
    print(
        "PlantVillage is a bootstrap dataset. Before public release, validate the "
        "model on ordinary Zimbabwe field photos from real phones and backgrounds."
    )


if __name__ == "__main__":
    main()
