"""Optional crop-specific model registry for CropMedic.

The legacy combined four-crop model remains supported by main.py. This module
adds guarded loading of crop-specific models placed under backend/models/<dir>.
A crop is only loadable when registry.json explicitly marks it enabled.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class CropModelEntry:
    crop: str
    directory: str
    enabled: bool
    release_status: str
    confidence_threshold: float
    margin_threshold: float
    model: Any = None
    class_names: list[str] | None = None
    error: str | None = None

    @property
    def ready(self) -> bool:
        return self.enabled and self.model is not None and bool(self.class_names)


class CropModelRegistry:
    def __init__(self, root: Path):
        self.root = root
        self.config_path = root / "registry.json"
        self.entries: dict[str, CropModelEntry] = {}

    def load(self) -> None:
        self.entries = {}
        if not self.config_path.exists():
            return

        payload = json.loads(self.config_path.read_text(encoding="utf-8"))
        for raw in payload.get("crops", []):
            entry = CropModelEntry(
                crop=str(raw.get("crop", "")).strip(),
                directory=str(raw.get("directory", "")).strip(),
                enabled=bool(raw.get("enabled", False)),
                release_status=str(raw.get("release_status", "unknown")),
                confidence_threshold=float(raw.get("confidence_threshold", 0.75)),
                margin_threshold=float(raw.get("margin_threshold", 0.15)),
            )
            if not entry.crop or not entry.directory:
                continue
            self.entries[entry.crop] = entry

        enabled = [entry for entry in self.entries.values() if entry.enabled]
        if not enabled:
            return

        import tensorflow as tf

        for entry in enabled:
            model_dir = self.root / entry.directory
            model_path = model_dir / "model.keras"
            classes_path = model_dir / "class_names.json"
            if not model_path.exists() or not classes_path.exists():
                entry.error = "Enabled crop model artifacts are missing."
                continue
            try:
                classes = json.loads(classes_path.read_text(encoding="utf-8"))
                if not isinstance(classes, list) or len(classes) < 2:
                    raise ValueError("class_names.json must contain at least two classes")
                if not all(isinstance(name, str) and name.strip() for name in classes):
                    raise ValueError("class_names.json contains an invalid class name")
                loaded = tf.keras.models.load_model(model_path)
                if int(loaded.output_shape[-1]) != len(classes):
                    raise ValueError(
                        "Model output count does not match class_names.json"
                    )
                entry.model = loaded
                entry.class_names = [str(name) for name in classes]
            except Exception as exc:
                entry.error = f"Model failed validation: {exc}"
                entry.model = None
                entry.class_names = None

    def get(self, crop: str) -> CropModelEntry | None:
        entry = self.entries.get(crop)
        return entry if entry and entry.ready else None

    def ready_crops(self) -> list[str]:
        return [entry.crop for entry in self.entries.values() if entry.ready]

    def status(self) -> list[dict[str, object]]:
        return [
            {
                "crop": entry.crop,
                "enabled": entry.enabled,
                "ready": entry.ready,
                "release_status": entry.release_status,
                "error": entry.error,
            }
            for entry in self.entries.values()
        ]
