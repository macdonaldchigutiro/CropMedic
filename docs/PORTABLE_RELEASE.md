# CropMedic portable Windows release

CropMedic can be distributed to another Windows machine without linking that machine to GitHub and without retraining any model.

## Build machine

The build machine needs the canonical `crop_medic/` Flutter app, backend dependencies, Flutter in `PATH`, and the validated model files installed under the backend. Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\package_portable.ps1
```

The builder:

1. builds the Flutter web app in release mode;
2. copies the backend and currently installed validated model artifacts into a staging folder;
3. replaces the staging backend static site with the Flutter web build;
4. writes `START_CROPMEDIC.ps1` for the destination machine;
5. creates `release/CropMedic_Portable.release.zip`.

Training datasets are deliberately excluded.

## Destination machine

The destination machine does **not** need Git or access to the CropMedic repository. It currently needs Windows 10/11 and 64-bit Python 3. Extract the ZIP and run `START_CROPMEDIC.ps1`.

On first launch the start script creates a local virtual environment and installs the backend Python dependencies. Later launches reuse that environment and the already-trained model files.

## Future installer

A later production packaging step can remove the Python prerequisite by bundling the backend/runtime into a signed Windows installer. Do this only after the model set, backend architecture and release configuration have stabilised; TensorFlow makes early executable bundling unnecessarily large and slow to iterate.

## Release safety

Only validated models should be present in a public release bundle. Crop-specific models remain disabled in `backend/models/registry.json` until they pass independent field validation, rejection testing, guidance/translation review and explicit promotion.
