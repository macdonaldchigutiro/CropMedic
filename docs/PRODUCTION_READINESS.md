# CropMedic production readiness tracker

This file separates **implemented platform capability** from **evidence still required before public release**.

## Implemented

- Canonical Flutter app: `crop_medic/`.
- Real backend inference; no fake diagnosis fallback.
- Current four-crop bootstrap diagnosis model for Maize, Tomato, Potato and Bell pepper.
- Farmer-confirmed crop selection before diagnosis.
- Confidence and prediction-margin rejection.
- JPEG/PNG/WebP validation, upload limits, pixel limits, CORS/trusted-host controls, rate limiting and production HTTPS support.
- English, Shona, Ndebele and Tonga UI/guidance framework.
- Disease library, result flow and printable report flow.
- Guarded crop-specific model registry for expansion crops.
- `/api/health` and `/api/capabilities` model/crop readiness reporting.
- Flutter crop confirmation can discover newly enabled diagnosis crops from the backend while keeping crop identification separate.
- Resumable Colab training with Google Drive persistence.
- Independent external-validation/rejection evaluator.
- Guarded model-promotion workflow.
- Reusable Batch-1 dataset preparer and Colab trainer.
- No-Git Windows portable release builder.
- `production-v1` CI for Python syntax/config and Flutter analysis.

## Common bean

- BLD-BD original-image pilot prepared: 672 images, 3 balanced classes.
- Local audit passed: 0 corrupt images, 0 exact duplicates, 0 cross-label duplicate groups.
- Training is pilot-only until metrics are frozen and independent field/rejection validation passes.
- Backend registry entry exists but is intentionally disabled.

## Batch 1 still required

- Finish and freeze Common Bean pilot training metrics.
- Obtain independent Common Bean field images for the known classes plus unsupported-disease/non-crop challenge images.
- Prepare/audit/train Soybean.
- Prepare/audit/train Wheat.
- Prepare/audit/train Sorghum, preserving affected-part semantics for head/grain diseases.
- Keep Tobacco disease diagnosis blocked until dataset licence/classes are verified.
- Train and independently validate a dedicated crop identifier rather than relying indefinitely on the four-crop disease-model bootstrap.

## Public-release blockers

- Zimbabwe-style field validation for every crop claimed as supported.
- OOD/non-plant rejection validation. Confidence thresholds alone are not proof of OOD safety.
- Native/agronomic review of Shona, Ndebele and especially Tonga disease guidance.
- Public HTTPS backend deployment, monitoring and rollback plan if server inference remains the production architecture.
- Decide whether the final mobile product requires offline TFLite inference; current production inference is backend-based.
- Final privacy/terms/support content and store-release configuration.
- Final Windows/mobile packaging and signed release artifacts.

## Promotion rule

A crop is not AI-supported merely because a model trained successfully. Promotion requires dataset audit, frozen internal metrics, independent external validation, rejection testing, Zimbabwe-style field review, reviewed guidance/translations and explicit backend registry promotion.
