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
7. Zimbabwe-style field photos are tested before public release;
8. disease guidance/translations are reviewed;
9. the model is explicitly promoted into the guarded backend registry.

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

## Soybean, wheat and sorghum archive preparation

`prepare_batch1_archive.py` stages only labels it can map unambiguously. If archive labels do not match the vetted classes, it stops and prints sample paths rather than guessing.

```powershell
python prepare_batch1_archive.py --crop-id soybean --zip-path "C:\path\to\soybean.zip"
python prepare_batch1_archive.py --crop-id wheat --zip-path "C:\path\to\wheat.zip"
python prepare_batch1_archive.py --crop-id sorghum --zip-path "C:\path\to\sorghum.zip"
```

If it reports unmapped images, review the archive structure before changing aliases. Never train from uncertain labels.

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

## Step 2 — resumable pilot training

`train_crop_model.py` now supports persistent phase checkpoints. On Colab, place both the output and checkpoint directories in Google Drive so a runtime disconnect does not force a full restart.

```bash
python train_crop_model.py \
  --crop-id common_bean \
  --data-dir data_batch1/common_bean \
  --output-dir /content/drive/MyDrive/CropMedic/batch1/common_bean \
  --checkpoint-dir /content/drive/MyDrive/CropMedic/checkpoints/common_bean
```

The Common Bean notebook `CropMedic_Batch1_CommonBean_Colab.ipynb` mounts Drive before training, stores the dataset ZIP there after the first upload, and resumes interrupted training from Drive checkpoints.

Artifacts include `model.keras`, `model.tflite`, `class_names.json`, `metrics.json`, training logs and metadata.

## Step 3 — external validation and rejection testing

After a baseline is frozen, evaluate it on a source that was **not** used for training. Unsupported diseases/non-crop images should go in a separate challenge directory rather than being mislabeled as a known class.

```bash
python evaluate_external_dataset.py \
  --crop-id common_bean \
  --model-dir /content/drive/MyDrive/CropMedic/batch1/common_bean \
  --data-dir external_common_bean/known \
  --unknown-dir external_common_bean/unknown
```

The report includes accuracy, macro F1 for classes actually present, per-class precision/recall/F1, confusion matrix, known-image rejection and unknown-challenge rejection.

Do **not** tune on the external validation set. CropMedic should prefer **uncertain / unsupported** over a confident wrong diagnosis.

## Step 4 — build the crop identifier

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
  --output-dir artifacts_batch1/crop_identifier_v1 \
  --checkpoint-dir checkpoints/crop_identifier_v1
```

Crop identification remains a farmer-confirmed bootstrap flow until this dedicated identifier has its own external validation.

## Step 5 — guarded backend promotion

The backend now supports optional crop-specific models under `backend/models/<crop>/`, controlled by `backend/models/registry.json`. Registry entries default to disabled.

Use `promote_crop_model.py` only after external validation, rejection testing, field review and guidance/translation review are complete. The promotion script validates required artifacts and thresholds before enabling the registry entry.

```powershell
python promote_crop_model.py `
  --crop "Common bean" `
  --artifact-dir "C:\path\to\common_bean_artifacts" `
  --validation-report "C:\path\to\external_validation.json" `
  --confirm-field-review `
  --confirm-guidance-reviewed
```

After promotion:

- restart the backend;
- verify `/api/health` and `/api/capabilities`;
- update the Flutter catalog only when the backend reports the crop ready;
- preserve the previous model for rollback.

Public datasets remain bootstrap sources. Public release claims require real field-photo validation, preferably including Zimbabwean crops, varieties, lighting, phones and disease stages.
