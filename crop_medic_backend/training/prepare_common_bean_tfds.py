"""Compatibility entry point for Common Bean Batch-1 preparation.

The original TensorFlow Datasets Beans download now returns HTTP 403 from
https://storage.googleapis.com/ibeans/*.zip. CropMedic therefore uses the
current CC BY 4.0 Mendeley common-bean field dataset instead.

You can keep using the old command:
    python prepare_common_bean_tfds.py

It now delegates to prepare_common_bean_mendeley.py.
"""
from prepare_common_bean_mendeley import main


if __name__ == "__main__":
    print(
        "The old TFDS Beans host is unavailable (HTTP 403). "
        "Using the Mendeley Common Bean fallback instead."
    )
    main()
