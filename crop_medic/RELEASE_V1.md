# CropMedic V1 release scope

This document defines what counts as the finished four-crop CropMedic V1 product.

## Locked V1 crop scope

AI diagnosis is exposed only for:

1. Maize
2. Tomato
3. Potato
4. Bell pepper

The research roadmap for Common bean, Soybean, Wheat, Sorghum, Tobacco and other crops remains outside the V1 farmer-facing release.

## V1 product features

- Guided camera/gallery scan workflow
- Crop confirmation before disease diagnosis
- Top diagnosis, confidence and practical advice
- Low-confidence / unsupported-image rejection
- Four-crop disease library
- Saved diagnosis history on the device
- PDF and Word report export on web and native platforms
- Weather and crop-risk screen
- Agricultural support directory with verification dates for confirmed public contacts
- English, Shona, Ndebele and Tonga user experience
- Backend health/capabilities endpoints
- Security controls for CORS, hosts, image validation, request limits and production headers
- One-command local launcher
- Docker-ready backend
- No-Git Windows portable packaging flow
- CI checks for Python syntax/config, Flutter analysis, tests and release web build

## Release gates before public deployment

The software can be treated as the completed V1 codebase when CI is green and the four-crop scan journey passes end-to-end against the intended backend model.

A public deployment still requires all of the following operational steps:

- install the validated four-crop model artifacts on the production backend;
- deploy the backend to a stable HTTPS endpoint;
- build the Flutter release with that production API URL;
- test camera, gallery, diagnosis, rejection, history and report export on real Android/iPhone devices;
- verify current extension contacts before publication;
- perform a final language/content review for Shona, Ndebele and Tonga;
- preserve the existing caution that the current public-data model is not yet Zimbabwe field-validated.

## AI claims

Do not describe CropMedic V1 as a replacement for agronomic or plant-pathology diagnosis. Public benchmark performance is useful for bootstrap engineering but is not the same as independent Zimbabwe field validation.

A farmer should be encouraged to seek extension/agronomic help when symptoms are severe, spreading, treatment-sensitive or inconsistent with the app result.

## New crop policy

No fifth crop should appear in the V1 diagnosis UI simply because a model exists. New crops must go through dataset audit, pilot training, held-out metrics, independent external validation, uncertainty/rejection checks, field-style testing and guidance review before a future product release exposes them.
