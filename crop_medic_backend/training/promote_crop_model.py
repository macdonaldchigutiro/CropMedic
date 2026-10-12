"""Promote a validated crop-specific model into the CropMedic backend registry.

Promotion is intentionally guarded. It refuses to enable a crop unless the
external validation report meets declared thresholds, covers every model class,
contains a meaningful unknown/non-crop challenge set, and the caller explicitly
confirms field and guidance review are complete.
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

REQUIRED_ARTIFACTS = [
    "model.keras",
    "model.tflite",
    "class_names.json",
    "metrics.json",
    "model_metadata.json",
]


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--crop", required=True, help="Registry crop name, e.g. 'Common bean'")
    p.add_argument("--artifact-dir", type=Path, required=True)
    p.add_argument("--validation-report", type=Path, required=True)
    p.add_argument(
        "--backend-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "backend",
    )
    p.add_argument("--min-accuracy", type=float, default=0.80)
    p.add_argument("--min-macro-f1", type=float, default=0.80)
    p.add_argument("--min-unknown-rejection", type=float, default=0.80)
    p.add_argument("--min-unknown-images", type=int, default=30)
    p.add_argument("--confirm-field-review", action="store_true")
    p.add_argument("--confirm-guidance-reviewed", action="store_true")
    return p.parse_args()


def _load_json(path: Path, label: str):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"Could not read {label}: {path}: {exc}") from exc


def main():
    args = parse_args()
    if not args.confirm_field_review or not args.confirm_guidance_reviewed:
        raise SystemExit(
            "Promotion blocked. Re-run only after field/rejection review and guidance/translation "
            "review, with --confirm-field-review --confirm-guidance-reviewed."
        )

    missing = [name for name in REQUIRED_ARTIFACTS if not (args.artifact_dir / name).exists()]
    if missing:
        raise SystemExit("Missing model artifacts: " + ", ".join(missing))
    if not args.validation_report.exists():
        raise SystemExit(f"Validation report not found: {args.validation_report}")

    validation = _load_json(args.validation_report, "validation report")
    if validation.get("evaluation_type") != "external_validation_no_tuning":
        raise SystemExit("Validation report is not marked external_validation_no_tuning.")

    artifact_classes = _load_json(args.artifact_dir / "class_names.json", "class names")
    if not isinstance(artifact_classes, list) or len(artifact_classes) < 2:
        raise SystemExit("Artifact class_names.json is invalid.")

    validation_classes = validation.get("model_classes")
    if validation_classes != artifact_classes:
        raise SystemExit(
            "Promotion blocked: validation report class list does not exactly match the model artifact."
        )

    if validation.get("all_model_classes_present") is not True:
        missing_classes = validation.get("missing_model_classes") or []
        detail = ", ".join(str(x) for x in missing_classes) or "unknown"
        raise SystemExit(
            "Promotion blocked: external validation did not cover every model class. Missing: "
            + detail
        )

    metrics = _load_json(args.artifact_dir / "metrics.json", "training metrics")
    if str(metrics.get("crop_id", "")).strip() != str(validation.get("crop_id", "")).strip():
        raise SystemExit(
            "Promotion blocked: training metrics crop_id and validation report crop_id do not match."
        )

    accuracy = float(validation.get("accuracy", 0.0))
    macro_f1 = float(validation.get("macro_f1_present_classes", 0.0))
    unknown = validation.get("unknown_challenge_rejection") or {}
    unknown_rejection = unknown.get("rejection_rate")
    unknown_images = int(unknown.get("images") or 0)

    failures = []
    if accuracy < args.min_accuracy:
        failures.append(f"accuracy {accuracy:.3f} < {args.min_accuracy:.3f}")
    if macro_f1 < args.min_macro_f1:
        failures.append(f"macro F1 {macro_f1:.3f} < {args.min_macro_f1:.3f}")
    if unknown_images < args.min_unknown_images:
        failures.append(
            f"unknown challenge images {unknown_images} < {args.min_unknown_images}"
        )
    if unknown_rejection is None:
        failures.append("unknown/non-crop rejection challenge was not evaluated")
    elif float(unknown_rejection) < args.min_unknown_rejection:
        failures.append(
            f"unknown rejection {float(unknown_rejection):.3f} < {args.min_unknown_rejection:.3f}"
        )
    if failures:
        raise SystemExit("Promotion blocked: " + "; ".join(failures))

    registry_path = args.backend_dir / "models" / "registry.json"
    if not registry_path.exists():
        raise SystemExit(f"Backend registry not found: {registry_path}")
    registry = _load_json(registry_path, "backend model registry")

    match = None
    for entry in registry.get("crops", []):
        if str(entry.get("crop", "")).lower() == args.crop.strip().lower():
            match = entry
            break
    if match is None:
        raise SystemExit(f"Crop is not declared in backend model registry: {args.crop}")

    destination = args.backend_dir / "models" / str(match["directory"])
    destination.mkdir(parents=True, exist_ok=True)
    for name in REQUIRED_ARTIFACTS:
        shutil.copy2(args.artifact_dir / name, destination / name)
    shutil.copy2(args.validation_report, destination / "external_validation.json")

    match["enabled"] = True
    match["release_status"] = "validated_enabled"
    match["validation_summary"] = {
        "accuracy": accuracy,
        "macro_f1": macro_f1,
        "unknown_rejection_rate": float(unknown_rejection),
        "unknown_challenge_images": unknown_images,
        "all_model_classes_present": True,
    }
    registry_path.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")

    print(f"Promoted: {args.crop}")
    print(f"Installed model: {destination.resolve()}")
    print(f"Registry updated: {registry_path.resolve()}")
    print("Restart the backend and verify /api/health before updating the Flutter AI-supported catalog.")


if __name__ == "__main__":
    main()
