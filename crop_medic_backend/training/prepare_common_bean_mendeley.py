"""Prepare the current Common Bean Batch-1 dataset from Mendeley Data.

Primary source:
  High-Resolution Dataset of Common Bean Leaf Diseases in Bangladesh
  DOI: 10.17632/89c9r5m2gx.1
  CC BY 4.0

The script first tries Mendeley's public dataset API. If automated download is
blocked, pass a locally downloaded ZIP with --zip-path.

The Mendeley browser download may itself contain another ZIP archive. This
preparer therefore walks nested ZIP files as well as ordinary folders. Large
nested archives are streamed to a temporary file instead of being loaded into
RAM.

Output layout:
  data_batch1/common_bean/
    Angular Leaf Spot/
    Anthracnose/
    Mosaic Virus/
    Rust/
    Healthy/

Examples:
  python prepare_common_bean_mendeley.py
  python prepare_common_bean_mendeley.py --zip-path C:\\Users\\Macdee\\Downloads\\bean_dataset.zip
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import tempfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

DATASET_ID = "89c9r5m2gx"
VERSION = 1
DATASET_PAGE = f"https://data.mendeley.com/datasets/{DATASET_ID}/{VERSION}"
API_URL = f"https://api.data.mendeley.com/datasets/{DATASET_ID}?version={VERSION}"
DOWNLOAD_EVENT = (
    f"https://api.data.mendeley.com/datasets/{DATASET_ID}/files/{{file_id}}/"
    f"file_downloaded?version={VERSION}"
)

CLASS_RULES = {
    "Angular Leaf Spot": {"angularleafspot", "als", "angular", "angularleafspotdisease"},
    "Anthracnose": {"anthracnose", "anthra", "ant"},
    "Mosaic Virus": {"mosaicvirus", "mosaic", "mv", "beancommonmosaicvirus"},
    "Rust": {"rust", "beanrust"},
    "Healthy": {"healthyleaves", "healthy", "hlt", "healthyleaf"},
}
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}
# This is a guard against accidental archive bombs, not a RAM limit: nested
# archives are streamed to disk. The high-resolution source can legitimately be
# several GB, so keep the ceiling generous.
MAX_NESTED_ZIP_BYTES = 15 * 1024 * 1024 * 1024


def parse_args():
    p = argparse.ArgumentParser(description="Prepare Common Bean Batch-1 data")
    p.add_argument("--output-dir", type=Path, default=Path("data_batch1/common_bean"))
    p.add_argument("--zip-path", type=Path, default=None)
    p.add_argument("--keep-download", action="store_true")
    return p.parse_args()


def _norm(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def _classify(member_name: str) -> str | None:
    parts = [p for p in Path(member_name).parts if p not in {"", "."}]
    candidates = [_norm(p) for p in parts]
    stem = _norm(Path(member_name).stem)
    candidates.append(stem)

    for label, tokens in CLASS_RULES.items():
        for candidate in candidates:
            if candidate in tokens:
                return label
        for token in tokens:
            if len(token) >= 4 and any(token in candidate for candidate in candidates):
                return label
    return None


def _download_public_zip(target: Path) -> Path:
    headers = {
        "Accept": "application/vnd.mendeley-public-dataset.1+json",
        "User-Agent": "CropMedic/1.0 dataset-preparer",
    }
    req = urllib.request.Request(API_URL, headers=headers)
    with urllib.request.urlopen(req, timeout=45) as response:
        payload = json.loads(response.read().decode("utf-8"))

    files = payload.get("files") or []
    if not files:
        raise RuntimeError("Mendeley API returned no public files for the dataset.")

    zip_files = [
        item for item in files
        if str(item.get("filename", "")).lower().endswith(".zip")
    ]
    if not zip_files:
        raise RuntimeError("No ZIP archive was listed by the Mendeley dataset API.")

    zip_files.sort(
        key=lambda item: (
            "original" not in str(item.get("filename", "")).lower(),
            -int(item.get("size") or 0),
        )
    )
    chosen = zip_files[0]
    file_id = chosen.get("id")
    if not file_id:
        raise RuntimeError("Mendeley dataset file did not include an id.")

    download_url = DOWNLOAD_EVENT.format(file_id=file_id)
    print(f"Downloading: {chosen.get('filename', 'dataset.zip')}")
    print(f"Source: {DATASET_PAGE}")

    req = urllib.request.Request(
        download_url,
        headers={"User-Agent": "CropMedic/1.0 dataset-preparer"},
    )
    with urllib.request.urlopen(req, timeout=120) as response, target.open("wb") as out:
        shutil.copyfileobj(response, out, length=1024 * 1024)
    return target


def _write_image(
    archive: zipfile.ZipFile,
    info: zipfile.ZipInfo,
    logical_name: str,
    output_dir: Path,
    counts: dict[str, int],
) -> bool:
    suffix = Path(logical_name).suffix.lower()
    if suffix not in IMAGE_SUFFIXES:
        return False

    label = _classify(logical_name)
    if label is None:
        return False

    target_dir = output_dir / label
    target_dir.mkdir(parents=True, exist_ok=True)
    index = counts[label] + 1
    target = target_dir / f"{_norm(label)}_{index:05d}{suffix}"
    while target.exists():
        index += 1
        target = target_dir / f"{_norm(label)}_{index:05d}{suffix}"

    with archive.open(info) as src, target.open("wb") as dst:
        shutil.copyfileobj(src, dst, length=1024 * 1024)
    counts[label] += 1
    return True


def _walk_archive(
    archive: zipfile.ZipFile,
    output_dir: Path,
    counts: dict[str, int],
    seen_names: list[str],
    temp_root: Path,
    prefix: str = "",
    depth: int = 0,
) -> None:
    if depth > 4:
        return

    for info in archive.infolist():
        if info.is_dir():
            continue

        logical_name = f"{prefix}{info.filename}"
        if len(seen_names) < 100:
            seen_names.append(logical_name)

        if _write_image(archive, info, logical_name, output_dir, counts):
            continue

        if Path(info.filename).suffix.lower() != ".zip":
            continue
        if info.file_size <= 0:
            print(f"Skipping empty nested ZIP: {logical_name}")
            continue
        if info.file_size > MAX_NESTED_ZIP_BYTES:
            print(
                f"Skipping nested ZIP larger than safety limit: {logical_name} "
                f"({info.file_size / (1024**3):.2f} GiB)"
            )
            continue

        nested_path = temp_root / f"nested_{depth}_{abs(hash(logical_name))}.zip"
        try:
            print(
                f"Extracting nested ZIP: {logical_name} "
                f"({info.file_size / (1024**3):.2f} GiB uncompressed)"
            )
            with archive.open(info) as src, nested_path.open("wb") as dst:
                shutil.copyfileobj(src, dst, length=4 * 1024 * 1024)
            with zipfile.ZipFile(nested_path) as nested:
                print(f"Opening nested ZIP: {logical_name}")
                _walk_archive(
                    nested,
                    output_dir,
                    counts,
                    seen_names,
                    temp_root=temp_root,
                    prefix=f"{logical_name}::",
                    depth=depth + 1,
                )
        except (zipfile.BadZipFile, RuntimeError, OSError) as exc:
            print(f"Skipping unreadable nested ZIP {logical_name}: {exc}")
        finally:
            try:
                nested_path.unlink(missing_ok=True)
            except OSError:
                pass


def _stage(zip_path: Path, output_dir: Path) -> tuple[dict[str, int], list[str]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    counts = {name: 0 for name in CLASS_RULES}
    seen_names: list[str] = []

    with tempfile.TemporaryDirectory(prefix="cropmedic_nested_zips_") as tmp:
        temp_root = Path(tmp)
        with zipfile.ZipFile(zip_path) as archive:
            _walk_archive(
                archive,
                output_dir,
                counts,
                seen_names,
                temp_root=temp_root,
            )

    return counts, seen_names


def main():
    args = parse_args()
    temp_dir = None
    zip_path = args.zip_path

    if zip_path is not None:
        zip_path = zip_path.expanduser().resolve()
        if not zip_path.exists():
            raise SystemExit(f"ZIP not found: {zip_path}")
        print(f"Using ZIP: {zip_path}")
    else:
        temp_dir = tempfile.TemporaryDirectory(prefix="cropmedic_common_bean_")
        zip_path = Path(temp_dir.name) / "common_bean_mendeley.zip"
        try:
            _download_public_zip(zip_path)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, RuntimeError) as exc:
            if temp_dir is not None:
                temp_dir.cleanup()
            raise SystemExit(
                "Automatic Mendeley download did not work.\n"
                f"Open {DATASET_PAGE} in your browser, download the dataset ZIP, then run:\n"
                "  python prepare_common_bean_mendeley.py --zip-path \"C:\\\\path\\\\to\\\\downloaded.zip\"\n"
                f"Reason: {exc}"
            ) from exc

    try:
        counts, seen_names = _stage(zip_path, args.output_dir)
    except zipfile.BadZipFile as exc:
        raise SystemExit(f"The selected file is not a readable ZIP archive: {zip_path}") from exc
    finally:
        if temp_dir is not None and not args.keep_download:
            temp_dir.cleanup()

    total = sum(counts.values())
    print("Prepared Common Bean dataset:")
    for name, count in counts.items():
        print(f"  {name}: {count}")
    print(f"  TOTAL: {total}")
    print(f"Output: {args.output_dir.resolve()}")

    missing = [name for name, count in counts.items() if count == 0]
    if total == 0:
        print("\nNo classed images were found. First archive entries were:")
        for name in seen_names[:60]:
            print(f"  {name}")
        raise SystemExit(
            "No usable bean images were found in the selected ZIP. "
            "The archive was read successfully, but its folder labels did not match the expected classes."
        )
    if missing:
        raise SystemExit(
            "Dataset preparation was incomplete. No images were found for: "
            + ", ".join(missing)
            + ". Check the archive structure before training."
        )

    print("Next: python audit_crop_dataset.py --data-dir data_batch1/common_bean --crop-id common_bean")


if __name__ == "__main__":
    main()
