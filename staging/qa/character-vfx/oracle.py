"""Independent AUI-34 packet oracle; it never generates expected output."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image


@dataclass
class Counter:
    checks: int = 0

    def equal(self, name: str, actual: Any, expected: Any) -> None:
        self.checks += 1
        if actual != expected:
            raise AssertionError(f"{name} measured={actual!r} expected={expected!r}")

    def true(self, name: str, condition: bool, detail: str) -> None:
        self.checks += 1
        if not condition:
            raise AssertionError(f"{name} {detail}")


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def rgba_sha256(path: Path) -> tuple[str, tuple[int, int]]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    return hashlib.sha256(image.tobytes()).hexdigest(), image.size


def compare_directories(first: Path, second: Path, counter: Counter, label: str) -> None:
    first_names = sorted(path.name for path in first.iterdir() if path.is_file())
    second_names = sorted(path.name for path in second.iterdir() if path.is_file())
    counter.equal(f"{label}.inventory", second_names, first_names)
    for name in first_names:
        counter.equal(f"{label}.bytes.{name}", (second / name).read_bytes(), (first / name).read_bytes())


def verify_sources(input_root: Path, expected: dict[str, Any], counter: Counter) -> None:
    actual = [
        {"path": entry["path"], "sha256": sha256_file(input_root / entry["path"])}
        for entry in expected["source_sha256"]
    ]
    counter.equal("sources.hashes", actual, expected["source_sha256"])


def _verify_samples(image: Image.Image, samples: list[dict[str, Any]], counter: Counter, label: str) -> None:
    rgba = image.convert("RGBA")
    for index, sample in enumerate(samples):
        coordinate = tuple(sample["xy"])
        counter.equal(f"{label}.sample.{index}.{sample['meaning']}", list(rgba.getpixel(coordinate)), sample["rgba"])


def verify_packet(packet: Path, expected: dict[str, Any], counter: Counter, canonical_png: bool) -> dict[str, Any]:
    names = sorted(path.name for path in packet.iterdir() if path.is_file())
    counter.equal(
        "packet.inventory",
        names,
        ["fixture-aui34.asset.json", "fixture-aui34.contact.png", "fixture-aui34.png", "fixture-aui34.qa.json"],
    )
    metadata = load(packet / "fixture-aui34.asset.json")
    report = load(packet / "fixture-aui34.qa.json")
    atlas_path = packet / "fixture-aui34.png"
    contact_path = packet / "fixture-aui34.contact.png"
    atlas_rgba, atlas_size = rgba_sha256(atlas_path)
    contact_rgba, contact_size = rgba_sha256(contact_path)
    counter.equal("atlas.dimensions", list(atlas_size), expected["atlas"]["dimensions"])
    counter.equal("atlas.rgba_sha256", atlas_rgba, expected["atlas"]["rgba_sha256"])
    counter.equal("contact.dimensions", list(contact_size), expected["contact"]["dimensions"])
    counter.equal("contact.rgba_sha256", contact_rgba, expected["contact"]["rgba_sha256"])
    if canonical_png:
        counter.equal("atlas.file_sha256", sha256_file(atlas_path), expected["atlas"]["file_sha256"])
        counter.equal("contact.file_sha256", sha256_file(contact_path), expected["contact"]["file_sha256"])
    counter.equal("qa.status", report["status"], "PASS")
    counter.equal("qa.checks_executed", report["checks_executed"], expected["checks_executed"])
    counter.true("qa.nonzero_checks", report["checks_executed"] > 0, f"measured={report['checks_executed']}")
    counter.equal("qa.anchors", report["measurements"]["anchors"], expected["anchors"])
    counter.equal("qa.anchor_inventory", len(report["measurements"]["anchors"]), 8)
    counter.equal("qa.cells", report["measurements"]["atlas"]["cells"], expected["atlas"]["cells"])
    counter.equal(
        "qa.opaque_palette",
        report["measurements"]["atlas"]["opaque_palette"],
        expected["atlas"]["opaque_palette"],
    )
    counter.equal("metadata.source_hashes", metadata["source_hashes"], expected["source_sha256"])
    counter.equal("metadata.human_final_art", metadata["human_final_art"], "UNSET_HUMAN_ONLY")
    counter.equal("metadata.runtime_binding", metadata["runtime_binding"], "UNBOUND_AGENT_F_SEAM")
    with Image.open(atlas_path) as source:
        _verify_samples(source, expected["atlas"]["samples"], counter, "atlas")
    with Image.open(contact_path) as source:
        _verify_samples(source, expected["contact"]["samples"], counter, "contact")
    return metadata


def compare_backend_content(python_packet: Path, godot_packet: Path, counter: Counter) -> None:
    for name in ("fixture-aui34.png", "fixture-aui34.contact.png"):
        with Image.open(python_packet / name) as source:
            python_rgba = source.convert("RGBA")
        with Image.open(godot_packet / name) as source:
            godot_rgba = source.convert("RGBA")
        counter.equal(f"differential.{name}.dimensions", godot_rgba.size, python_rgba.size)
        counter.equal(f"differential.{name}.rgba", godot_rgba.tobytes(), python_rgba.tobytes())
    python_meta = load(python_packet / "fixture-aui34.asset.json")
    godot_meta = load(godot_packet / "fixture-aui34.asset.json")
    for key in (
        "schema_version", "asset_id", "asset_class", "state", "status", "spec_sha256",
        "source_hashes", "animations", "palette", "reserved_colors", "provenance",
        "human_final_art", "runtime_binding",
    ):
        counter.equal(f"differential.metadata.{key}", godot_meta[key], python_meta[key])
    python_qa = load(python_packet / "fixture-aui34.qa.json")
    godot_qa = load(godot_packet / "fixture-aui34.qa.json")
    counter.equal("differential.qa.checks_executed", godot_qa["checks_executed"], python_qa["checks_executed"])
    counter.equal("differential.qa.measurements", godot_qa["measurements"], python_qa["measurements"])
