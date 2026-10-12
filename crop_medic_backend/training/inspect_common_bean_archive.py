"""Inspect a downloaded Common Bean Mendeley archive without extracting images.

This helper is diagnostic only. It streams nested ZIP files to disk, prints
representative image paths, and counts image-containing folder names so we can
map the dataset's real archive structure safely before staging training data.
"""
from __future__ import annotations

import argparse
import collections
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def parse_args():
    p = argparse.ArgumentParser(description="Inspect Common Bean archive structure")
    p.add_argument("--zip-path", type=Path, required=True)
    return p.parse_args()


def inspect_zip(path: Path, label: str) -> None:
    with zipfile.ZipFile(path) as zf:
        infos = [i for i in zf.infolist() if not i.is_dir()]
        image_infos = [i for i in infos if PurePosixPath(i.filename.replace('\\', '/')).suffix.lower() in IMAGE_SUFFIXES]

        print(f"\n=== {label} ===")
        print(f"Files: {len(infos)}")
        print(f"Images: {len(image_infos)}")

        if image_infos:
            print("\nFirst image paths:")
            for info in image_infos[:40]:
                print(f"  {info.filename}")

            folder_counts: collections.Counter[str] = collections.Counter()
            for info in image_infos:
                p = PurePosixPath(info.filename.replace('\\', '/'))
                parts = p.parts[:-1]
                if parts:
                    # Count each directory component; class labels often appear at
                    # the last or second-last component.
                    for part in parts:
                        folder_counts[part] += 1

            print("\nMost common image-folder components:")
            for folder, count in folder_counts.most_common(40):
                print(f"  {count:5d}  {folder}")
        else:
            print("\nNo direct images in this archive. First file entries:")
            for info in infos[:40]:
                print(f"  {info.filename}")


def main():
    args = parse_args()
    outer = args.zip_path.expanduser().resolve()
    if not outer.exists():
        raise SystemExit(f"ZIP not found: {outer}")

    print(f"Inspecting: {outer}")
    inspect_zip(outer, "OUTER ZIP")

    with zipfile.ZipFile(outer) as zf, tempfile.TemporaryDirectory(prefix="cropmedic_bean_inspect_") as tmp:
        nested = [i for i in zf.infolist() if not i.is_dir() and i.filename.lower().endswith('.zip')]
        if not nested:
            print("\nNo nested ZIP files found.")
            return

        for index, info in enumerate(nested, start=1):
            target = Path(tmp) / f"nested_{index}.zip"
            print(f"\nStreaming nested ZIP to temporary file: {info.filename}")
            print(f"Nested ZIP size: {info.file_size / (1024**3):.2f} GiB")
            with zf.open(info) as src, target.open('wb') as dst:
                shutil.copyfileobj(src, dst, length=4 * 1024 * 1024)
            try:
                inspect_zip(target, f"NESTED ZIP: {info.filename}")
            except zipfile.BadZipFile as exc:
                print(f"Could not open nested ZIP {info.filename}: {exc}")


if __name__ == "__main__":
    main()
