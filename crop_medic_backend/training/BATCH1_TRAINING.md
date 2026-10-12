# CropMedic Zimbabwe v3 — Batch 1 training

Batch 1: **Soybean, Common bean, Wheat, Sorghum, Tobacco** plus the first dedicated crop-identifier model.

## Release rule

A crop stays **Coming soon** until all of these are true:

1. dataset licence and labels are reviewed;
2. source data passes `audit_crop_dataset.py`;
3. a pilot model is trained;
4. internal held-out metrics are acceptable;
5. a separate external/field dataset is tested without being used for tuning;
6. rejection/uncertainty behaviour is checked;
7. Zimbabwe-style field photos are tested before public release.

Do not mix external validation images into training before the baseline is frozen.

## Vetted starting sources

The machine-readable registry is `profiles/zimbabwe-v3-batch1-sources.json`.

- **Soybean** — Mendeley `10.17632/6fhphxg297.2`, CC BY 4.0, five field-image classes. Auburn ASDID is reserved for external validation initially.
- **Common bean pilot** — BLD-BD Mendeley `10.17632/3k46s46x3s.1`, CC BY 4.0, 672 original field-derived images covering Healthy, Angular Leaf Spot and Bean Common Mosaic Virus. Use `Original_Bean_Leaf_Disease_Dataset.zip` only for the first baseline.
- **Common bean later expansion** — Mendeley `10.17632/89c9r5m2gx.1`, CC BY 4.0, 3,180 high-resolution images and five classes. The browser download contains a nested archive that expands to roughly 8.6 GiB, so prepare it later in cloud storage or on a machine with sufficient free disk rather than blocking the first pilot.
- **Wheat** — Mendeley `10.17632/wgd66f8n6h.1`, CC BY 4.0, real Ethiopian wheat-field images with Healthy, Stripe Rust and Septoria.
- **Sorghum** — Mendeley `10.17632/fgb3cmfrg2.1`, CC BY 4.0. It contains leaf and head/grain diseases, so CropMedic must support affected-part photos rather than a leaf-only assumption.
- **Tobacco** — disease dataset is not approved yet. Keep tobacco disabled for disease diagnosis until the candidate source licence and class definitions are verified.

## Common bean preparation

For the first pilot, download only this file from the BLD-BD dataset page:

```text
Original_Bean_Leaf_Disease_Dataset.zip
```

Do **not** use the augmented ZIP for the baseline because derived versions of the same image can leak across train/validation/test splits.

Prepare it with:

```powershell
python prepare_common_bean_bldbd.py --zip-path "C:\path\to\Original_Bean_Leaf_Disease_Dataset.zip"
```

Expected output layout:

```text
data_batch1/
  common_bean/
    Healthy/
    Angular Leaf Spot/
    Bean Common Mosaic Virus/
```

Then audit:

```powershell
python audit_crop_dataset.py --data-dir data_batch1/common_bean --crop-id common_bean
```

The old `prepare_common_bean_tfds.py` command remains only as a compatibility entry point and now delegates to the BLD-BD preparer when `--zip-path` is supplied.

## Local folder layout

Do not commit datasets to Git.

```text
data_batch1/
  soybean/
    Healthy/
    Bacterial Blight/
    Cercospora Leaf Blight/
    Sudden Death Syndrome/
    Soybean Rust/
  common_bean/
    Healthy/
    Angular Leaf Spot/
    Bean Common Mosaic Virus/
  wheat/
    Healthy/
    Stripe Rust/
    Septoria/
  sorghum/
    ...class folders...
```

The trainer treats each immediate subfolder as one class.

## Step 1 — audit each dataset

From `crop_medic_backend/training`:

```powershell
python audit_crop_dataset.py --data-dir data_batch1/soybean --crop-id soybean
python audit_crop_dataset.py --data-dir data_batch1/common_bean --crop-id common_bean
python audit_crop_dataset.py --data-dir data_batch1/wheat --crop-id wheat
python audit_crop_dataset.py --data-dir data_batch1/sorghum --crop-id sorghum
```

Fix corrupt files, cross-label duplicates and suspicious class imbalance before training.

## Step 2 — train a pilot crop-specific model

GPU/Colab is recommended.

```bash
python train_crop_model.py \
  --crop-id common_bean \
  --data-dir data_batch1/common_bean \
  --output-dir artifacts_batch1/common_bean
```

Repeat for soybean, wheat and sorghum. Artifacts include `model.keras`, `model.tflite`, `class_names.json`, `metrics.json`, training logs and metadata.

## Step 3 — build the crop identifier

Create a separate folder where the *class is the crop*, not the disease:

```text
crop_identifier_data/
  maize/
  tomato/
  potato/
  bell_pepper/
  soybean/
  common_bean/
  wheat/
  sorghum/
  tobacco/
```

Use a balanced sample of varied healthy and diseased field images for each crop. Do not use only clean-background images. Keep an **unknown/non-crop challenge set** outside training (faces, vehicles, soil, weeds, unrelated plants, tools, food photos, etc.).

The same generic trainer can train the first identifier:

```bash
python train_crop_model.py \
  --crop-id crop_identifier_v1 \
  --data-dir crop_identifier_data \
  --output-dir artifacts_batch1/crop_identifier_v1
```

## Step 4 — external validation

After a baseline is frozen, evaluate it on a source that was not used for training. Report at least accuracy, macro F1, per-class precision/recall, confusion matrix, rejection rate, and top-2 confusion patterns.

CropMedic should prefer **uncertain / unsupported** over a confident wrong diagnosis.

## Step 5 — promote only when ready

Promotion means:

- copy the validated model into the backend model registry;
- add the crop to `AI-supported crops` in the Flutter catalog;
- add reviewed disease guidance and translations;
- add crop-specific confidence/rejection thresholds;
- preserve the previous model for rollback.

Public datasets remain bootstrap sources. Public release claims require real field-photo validation, preferably including Zimbabwean crops, varieties, lighting, phones and disease stages.
