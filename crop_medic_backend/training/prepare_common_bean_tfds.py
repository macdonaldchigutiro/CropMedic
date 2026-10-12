"""Compatibility entry point for Common Bean Batch-1 preparation.

The original TensorFlow Datasets Beans host now returns HTTP 403, and the
previous high-resolution Mendeley fallback expands to about 8.6 GiB, which is
unnecessarily heavy for the first pilot on a local Windows machine.

CropMedic now uses the lightweight BLD-BD original field dataset for the pilot.
Download only:
    Original_Bean_Leaf_Disease_Dataset.zip
from:
    https://data.mendeley.com/datasets/3k46s46x3s/1

Then run either:
    python prepare_common_bean_bldbd.py --zip-path "C:\\path\\to\\Original_Bean_Leaf_Disease_Dataset.zip"

or this compatibility command with the same --zip-path argument.
"""
from prepare_common_bean_bldbd import main


if __name__ == "__main__":
    print(
        "Using the lightweight BLD-BD Common Bean pilot dataset. "
        "Pass --zip-path pointing to Original_Bean_Leaf_Disease_Dataset.zip."
    )
    main()
