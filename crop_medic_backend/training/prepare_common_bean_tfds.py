"""Download and stage the Makerere/NaCRRI Beans dataset for CropMedic Batch 1.

The TensorFlow Datasets `beans` dataset contains Ugandan field images with
three labels: angular_leaf_spot, bean_rust and healthy.

Output layout:
  data_batch1/common_bean/
    Angular Leaf Spot/
    Bean Rust/
    Healthy/

Example:
  python prepare_common_bean_tfds.py
"""
from __future__ import annotations

import argparse
from pathlib import Path

import tensorflow_datasets as tfds
from PIL import Image

LABEL_MAP = {
    "angular_leaf_spot": "Angular Leaf Spot",
    "bean_rust": "Bean Rust",
    "healthy": "Healthy",
}


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--output-dir", type=Path, default=Path("data_batch1/common_bean"))
    return p.parse_args()


def main():
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    builder = tfds.builder("beans")
    builder.download_and_prepare()
    label_feature = builder.info.features["label"]

    counts = {folder: 0 for folder in LABEL_MAP.values()}
    for split_name in ("train", "validation", "test"):
        dataset = builder.as_dataset(split=split_name, as_supervised=True)
        for index, (image, label) in enumerate(tfds.as_numpy(dataset)):
            source_label = label_feature.int2str(int(label))
            target_label = LABEL_MAP[source_label]
            target_dir = args.output_dir / target_label
            target_dir.mkdir(parents=True, exist_ok=True)
            filename = target_dir / f"{split_name}_{index:05d}.jpg"
            Image.fromarray(image).convert("RGB").save(filename, "JPEG", quality=95)
            counts[target_label] += 1

    print("Prepared common bean dataset:")
    for name, count in counts.items():
        print(f"  {name}: {count}")
    print(f"Output: {args.output_dir.resolve()}")
    print("Next: run audit_crop_dataset.py before training.")


if __name__ == "__main__":
    main()
