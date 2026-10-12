# CropMedic backend deployment

CropMedic currently performs production diagnosis through the FastAPI backend. A public mobile/web release therefore needs a stable HTTPS backend with the validated model files installed.

## Container build

Build from the backend directory so the validated `model/` folder and any promoted crop-specific `models/<crop>/` folders are included in the image:

```powershell
cd C:\Users\Macdee\Desktop\CropMedic\crop_medic_backend\backend
docker build -t cropmedic-backend .
```

Run locally:

```powershell
docker run --rm -p 8000:8000 `
  -e CROPMEDIC_CORS_ORIGINS="http://localhost:8080" `
  -e CROPMEDIC_TRUSTED_HOSTS="localhost,127.0.0.1" `
  cropmedic-backend
```

Verify:

```text
http://127.0.0.1:8000/api/health
```

The container health check only becomes healthy when `/api/health` reports `status=ready`, which helps prevent deploying a container with no usable diagnosis model.

## Required production environment

Set these on the hosting provider:

- `CROPMEDIC_ENV=production`
- `CROPMEDIC_CORS_ORIGINS=https://<your-app-domain>`
- `CROPMEDIC_TRUSTED_HOSTS=<your-api-domain>`
- `CROPMEDIC_FORCE_HTTPS=false` when the hosting platform terminates HTTPS before forwarding to the container. Set it to `true` only when proxy scheme handling is configured correctly.
- `CROPMEDIC_TRUST_PROXY=true` only behind a trusted reverse proxy that supplies the real client IP.
- `CROPMEDIC_RATE_LIMIT_REQUESTS` and `CROPMEDIC_RATE_LIMIT_WINDOW_SECONDS` may be tuned for the deployment.

Never use `*` for trusted hosts or CORS in the public release just to make an error disappear.

## Model packaging

The repository intentionally ignores trained model binaries. Before building a production image, the build machine must contain:

```text
crop_medic_backend/backend/model/model.keras
crop_medic_backend/backend/model/class_names.json
```

and, for each validated expansion crop that has been explicitly promoted:

```text
crop_medic_backend/backend/models/<crop>/model.keras
crop_medic_backend/backend/models/<crop>/class_names.json
...
```

`models/registry.json` must only mark a crop `enabled: true` after the guarded promotion workflow passes external validation and rejection checks.

## Flutter production URL

Build the Flutter app with the public API URL:

```powershell
flutter build web --release `
  --dart-define=CROP_MEDIC_API_URL=https://api.example.com
```

Use the same `--dart-define` when producing the final Android/iOS release so the app does not point at `localhost`.

## Before public launch

Confirm all of the following:

1. `/api/health` returns `ready` through the public HTTPS URL.
2. `/api/capabilities` lists only crops that are truly validated and enabled.
3. A real phone can take/upload a photo and receive a diagnosis through the public network.
4. Unsupported/non-plant challenge images are rejected at the expected rate.
5. Rollback copies of the previous validated models are retained.
6. Hosting logs, uptime monitoring and a restart/rollback procedure are configured.

Containerization makes the backend deployable, but it does not replace the remaining field-validation and production-operations work recorded in `PRODUCTION_READINESS.md`.
