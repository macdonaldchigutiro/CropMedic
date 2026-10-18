# CropMedic V1

CropMedic V1 is the focused four-crop release of the CropMedic plant-health assistant.

## Supported AI crops

- Maize
- Tomato
- Potato
- Bell pepper

The V1 product deliberately hides the wider research roadmap from normal farmer workflows. New crops remain an ML/research pipeline and are not exposed as diagnosable until they pass the required validation gates.

## Farmer-facing features

- Camera or gallery crop-image input
- Farmer confirmation of the crop before disease diagnosis
- Confidence-aware diagnosis and unsupported-image handling
- Practical next-step guidance
- Offline disease reference library for the four V1 crops
- Saved diagnosis history stored on the device
- PDF and Word report export
- Weather and crop-risk guidance
- Verified agricultural support contacts where available
- English, Shona, Ndebele and Tonga UI/guidance support

## Runtime architecture

The Flutter app calls the CropMedic backend API. AI diagnosis requires a reachable backend in V1. The disease library and saved diagnosis history remain usable on-device when the API is unavailable.

For local development, run the helper from the repository root:

```powershell
.\tools\start_local.ps1
```

For a no-Git Windows runtime package, use:

```powershell
.\tools\package_portable.ps1
```

The build machine must have the validated model artifacts installed in the backend model location expected by the packaging script.

## Release safety note

CropMedic is decision support, not a substitute for a qualified agronomist, plant pathologist or extension officer. The current four-crop classifier is a bootstrap model and must not be marketed as Zimbabwe field-validated until independent field testing has been completed.

See `RELEASE_V1.md` for the release checklist and deployment gates.
