# Crop-specific backend models

This directory is the guarded registry for crop-specific diagnosis models that extend the legacy four-crop model.

`registry.json` is tracked in Git. Generated binary model folders are ignored by Git and installed locally only after validation.

Expected installed layout for an enabled crop:

```text
models/
  registry.json
  common_bean/
    model.keras
    model.tflite
    class_names.json
    metrics.json
    model_metadata.json
    external_validation.json
```

A crop must stay `enabled: false` until it passes independent external/field validation, unknown/rejection testing, field review and guidance/translation review. Use `training/promote_crop_model.py` for guarded promotion rather than manually switching the flag.

The backend exposes current readiness at `/api/health` and `/api/capabilities`. Crop identification remains separate: adding a crop-specific disease model does not automatically make the crop identifiable from an arbitrary image.
