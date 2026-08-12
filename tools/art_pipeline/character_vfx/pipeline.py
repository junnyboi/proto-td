"""AUI-34 canonical Python packet builder."""

from __future__ import annotations

import base64
import os
import platform
import shutil
import stat
import sys
from itertools import count
from io import BytesIO
from pathlib import Path
from typing import Any

import PIL
from PIL import Image

from __init__ import PIPELINE_VERSION
from canonical_io import canonical_json_bytes, load_json, sha256_bytes, sha256_file, write_canonical_json
from pixel_ops import (
    anchor_in_cell,
    build_contact_sheet,
    composite_atlas,
    key_and_threshold,
    palette_map,
    parse_hex,
    remove_small_components,
    resize_nearest,
)
from qa import QualityError, inspect_atlas, inspect_contact
from spec import SpecError, load_and_validate


class PipelineError(ValueError):
    """A measured pipeline failure."""


_PUBLISH_SEQUENCE = count()
PINNED_PYTHON_VERSION = "3.12.3"
PINNED_PILLOW_VERSION = "12.3.0"


def _require_backend_versions() -> None:
    actual_python = platform.python_version()
    actual_pillow = PIL.__version__
    if actual_python != PINNED_PYTHON_VERSION or actual_pillow != PINNED_PILLOW_VERSION:
        raise PipelineError(
            "backend.version "
            f"expected=python-{PINNED_PYTHON_VERSION},pillow-{PINNED_PILLOW_VERSION} "
            f"actual=python-{actual_python},pillow-{actual_pillow}"
        )


def _backend_info() -> dict[str, str]:
    return {
        "name": "python",
        "python": platform.python_version(),
        "pillow": PIL.__version__,
        "pipeline": PIPELINE_VERSION,
    }


def _run_identity(spec: dict[str, Any], source_hashes: list[dict[str, str]]) -> str:
    payload = {
        "backend": "python",
        "backend_version": f"python-{platform.python_version()}-pillow-{PIL.__version__}",
        "pipeline_version": PIPELINE_VERSION,
        "source_hashes": source_hashes,
        "spec": spec,
    }
    return sha256_bytes(canonical_json_bytes(payload))


def _source_hashes(spec: dict[str, Any], sources: list[Path]) -> list[dict[str, str]]:
    return [
        {"path": frame["path"], "sha256": sha256_file(path)}
        for frame, path in zip(spec["frames"], sources)
    ]


def _normalize_frame(path: Path, spec: dict[str, Any]) -> tuple[Image.Image, dict[str, int]]:
    normalization = spec["normalization"]
    with Image.open(path) as source:
        image = source.convert("RGBA")
    resize = normalization["resize"]
    if resize is not None:
        image = resize_nearest(image, resize[0], resize[1])
    image = key_and_threshold(
        image,
        parse_hex(normalization["background_key"]),
        normalization["alpha_threshold"],
    )
    image = palette_map(image, [parse_hex(value) for value in spec["palette"]])
    image = remove_small_components(image, normalization["minimum_component_size"])
    return anchor_in_cell(
        image,
        (spec["atlas"]["cell_width"], spec["atlas"]["cell_height"]),
        normalization["anchor_x"],
        normalization["anchor_foot_y"],
    )


def _normalized_atlas(spec: dict[str, Any], sources: list[Path]) -> tuple[Image.Image, list[dict[str, int]]]:
    cells: list[tuple[int, int, Image.Image]] = []
    anchors: list[dict[str, int]] = []
    for frame, source in zip(spec["frames"], sources):
        cell, anchor = _normalize_frame(source, spec)
        cells.append((frame["row"], frame["column"], cell))
        anchors.append(anchor)
    return composite_atlas(cells, (768, 384), (192, 192)), anchors


def _png_bytes(image: Image.Image) -> bytes:
    buffer = BytesIO()
    image.convert("RGBA").save(buffer, format="PNG", optimize=False, compress_level=9)
    return buffer.getvalue()


def _save_png(path: Path, image: Image.Image) -> bytes:
    value = _png_bytes(image)
    path.write_bytes(value)
    return value


def _metadata(
    spec: dict[str, Any],
    spec_path: Path,
    source_hashes: list[dict[str, str]],
    atlas: Image.Image,
    atlas_bytes: bytes,
    contact: Image.Image,
    contact_bytes: bytes,
) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "asset_id": spec["asset_id"],
        "asset_class": spec["asset_class"],
        "state": spec["state"],
        "status": "STAGED_RUNTIME_UNBOUND",
        "backend": _backend_info(),
        "run_identity": _run_identity(spec, source_hashes),
        "spec_sha256": sha256_file(spec_path),
        "source_hashes": source_hashes,
        "atlas": {
            **spec["atlas"],
            "file": spec["outputs"]["atlas"],
            "file_sha256": sha256_bytes(atlas_bytes),
            "rgba_sha256": sha256_bytes(atlas.tobytes()),
        },
        "contact": {
            "width": 1536,
            "height": 256,
            "file": spec["outputs"]["contact"],
            "file_sha256": sha256_bytes(contact_bytes),
            "rgba_sha256": sha256_bytes(contact.tobytes()),
        },
        "animations": spec["animations"],
        "palette": spec["palette"],
        "reserved_colors": spec["reserved_colors"],
        "provenance": spec["provenance"],
        "human_final_art": "UNSET_HUMAN_ONLY",
        "runtime_binding": "UNBOUND_AGENT_F_SEAM",
    }


def _report(
    spec: dict[str, Any],
    anchors: list[dict[str, int]],
    atlas_checks: list[dict[str, Any]],
    atlas_measurements: dict[str, Any],
    contact_checks: list[dict[str, Any]],
    contact_measurements: dict[str, Any],
) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "asset_id": spec["asset_id"],
        "status": "PASS",
        "checks_executed": len(atlas_checks) + len(contact_checks),
        "checks": atlas_checks + contact_checks,
        "measurements": {
            "anchors": anchors,
            "atlas": atlas_measurements,
            "contact": contact_measurements,
        },
    }


def _require_canonical(path: Path, value: Any, label: str) -> None:
    expected = canonical_json_bytes(value)
    actual = path.read_bytes()
    if actual != expected:
        raise PipelineError(
            f"packet.{label}.canonical_bytes measured_sha256={sha256_bytes(actual)} expected_sha256={sha256_bytes(expected)}"
        )


def _strictly_equal(recorded: Any, measured: Any) -> bool:
    if type(recorded) is not type(measured):
        return False
    if isinstance(measured, dict):
        return set(recorded) == set(measured) and all(
            _strictly_equal(recorded[key], measured[key]) for key in measured
        )
    if isinstance(measured, list):
        return len(recorded) == len(measured) and all(
            _strictly_equal(left, right) for left, right in zip(recorded, measured)
        )
    return recorded == measured


def _require_exact(label: str, recorded: Any, measured: Any) -> None:
    if not _strictly_equal(recorded, measured):
        raise PipelineError(f"packet.{label} differs-from-recomputed-contract")


def prepare_packet(spec_path: Path, input_root: Path, candidate_dir: Path, backend: str = "python") -> dict[str, Any]:
    _require_backend_versions()
    if backend != "python":
        raise PipelineError(f"backend expected=python actual={backend!r}")
    if candidate_dir.exists():
        raise PipelineError(f"candidate_dir expected=absent actual=exists name={candidate_dir.name!r}")
    spec, sources = load_and_validate(spec_path, input_root)
    candidate_dir.mkdir(parents=True)
    hashes = _source_hashes(spec, sources)
    atlas, anchors = _normalized_atlas(spec, sources)
    contact = build_contact_sheet(atlas)
    atlas_path = candidate_dir / spec["outputs"]["atlas"]
    contact_path = candidate_dir / spec["outputs"]["contact"]
    atlas_bytes = _save_png(atlas_path, atlas)
    contact_bytes = _save_png(contact_path, contact)
    atlas_checks, atlas_measurements = inspect_atlas(atlas, spec)
    contact_checks, contact_measurements = inspect_contact(contact, atlas)
    metadata = _metadata(spec, spec_path, hashes, atlas, atlas_bytes, contact, contact_bytes)
    report = _report(
        spec,
        anchors,
        atlas_checks,
        atlas_measurements,
        contact_checks,
        contact_measurements,
    )
    write_canonical_json(candidate_dir / spec["outputs"]["metadata"], metadata)
    write_canonical_json(candidate_dir / spec["outputs"]["qa"], report)
    validate_packet(candidate_dir, spec_path, input_root)
    return metadata


def validate_packet(packet_dir: Path, spec_path: Path, input_root: Path) -> dict[str, Any]:
    _require_backend_versions()
    spec, sources = load_and_validate(spec_path, input_root)
    expected_names = set(spec["outputs"].values())
    entries = list(packet_dir.iterdir())
    actual_names = {path.name for path in entries}
    if actual_names != expected_names:
        raise PipelineError(f"packet.inventory expected={sorted(expected_names)} actual={sorted(actual_names)}")
    invalid_entries = sorted(path.name for path in entries if path.is_symlink() or not path.is_file())
    if invalid_entries:
        raise PipelineError(f"packet.inventory non-regular-or-symlink={invalid_entries}")
    metadata_path = packet_dir / spec["outputs"]["metadata"]
    report_path = packet_dir / spec["outputs"]["qa"]
    metadata = load_json(metadata_path)
    report = load_json(report_path)
    _require_canonical(metadata_path, metadata, "metadata")
    _require_canonical(report_path, report, "report")
    atlas_path = packet_dir / spec["outputs"]["atlas"]
    contact_path = packet_dir / spec["outputs"]["contact"]
    with Image.open(atlas_path) as source:
        atlas = source.convert("RGBA")
    with Image.open(contact_path) as source:
        contact = source.convert("RGBA")

    atlas_checks, atlas_measurements = inspect_atlas(atlas, spec)
    contact_checks, contact_measurements = inspect_contact(contact, atlas)
    expected_atlas, anchors = _normalized_atlas(spec, sources)
    expected_contact = build_contact_sheet(expected_atlas)
    _require_exact("atlas.rgba", atlas.tobytes(), expected_atlas.tobytes())
    _require_exact("contact.rgba", contact.tobytes(), expected_contact.tobytes())
    expected_atlas_bytes = _png_bytes(expected_atlas)
    expected_contact_bytes = _png_bytes(expected_contact)
    _require_exact("atlas.png_canonical_bytes", atlas_path.read_bytes(), expected_atlas_bytes)
    _require_exact("contact.png_canonical_bytes", contact_path.read_bytes(), expected_contact_bytes)
    hashes = _source_hashes(spec, sources)
    expected_metadata = _metadata(
        spec,
        spec_path,
        hashes,
        expected_atlas,
        expected_atlas_bytes,
        expected_contact,
        expected_contact_bytes,
    )
    expected_report = _report(
        spec,
        anchors,
        atlas_checks,
        atlas_measurements,
        contact_checks,
        contact_measurements,
    )
    _require_exact("metadata", metadata, expected_metadata)
    _require_exact("report", report, expected_report)
    if expected_report["checks_executed"] <= 0:
        raise PipelineError("packet.checks_executed measured=0 expected=>0")
    return {"checks_executed": expected_report["checks_executed"], "metadata": metadata}


def _preflight_removable_tree(path: Path) -> None:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return
    if stat.S_ISLNK(mode) or stat.S_ISREG(mode):
        return
    if not stat.S_ISDIR(mode):
        raise PipelineError(f"cleanup.preflight unsupported-entry name={path.name!r}")
    if not os.access(path, os.R_OK | os.W_OK | os.X_OK):
        raise PermissionError(f"cleanup.preflight inaccessible-directory name={path.name!r}")
    with os.scandir(path) as entries:
        for entry in entries:
            if entry.is_symlink():
                continue
            child = Path(entry.path)
            if entry.is_dir(follow_symlinks=False):
                _preflight_removable_tree(child)
            elif not entry.is_file(follow_symlinks=False):
                raise PipelineError(f"cleanup.preflight unsupported-entry name={entry.name!r}")


def _remove_tree(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def _salvage_payload(root: Path) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []

    def visit(directory: Path) -> None:
        with os.scandir(directory) as children:
            ordered = sorted(children, key=lambda child: child.name)
        for child in ordered:
            path = Path(child.path)
            relative = path.relative_to(root).as_posix()
            if child.is_symlink():
                entries.append({"path": relative, "type": "symlink", "target": os.readlink(path)})
            elif child.is_dir(follow_symlinks=False):
                entries.append({"path": relative, "type": "directory"})
                visit(path)
            elif child.is_file(follow_symlinks=False):
                entries.append(
                    {
                        "path": relative,
                        "type": "file",
                        "data_base64": base64.b64encode(path.read_bytes()).decode("ascii"),
                    }
                )
            else:
                raise PipelineError(f"cleanup.salvage unsupported-entry name={child.name!r}")

    mode = root.lstat().st_mode
    if stat.S_ISLNK(mode):
        entries.append({"path": ".", "type": "symlink", "target": os.readlink(root)})
    elif stat.S_ISREG(mode):
        entries.append(
            {
                "path": ".",
                "type": "file",
                "data_base64": base64.b64encode(root.read_bytes()).decode("ascii"),
            }
        )
    elif stat.S_ISDIR(mode):
        visit(root)
    else:
        raise PipelineError(f"cleanup.salvage unsupported-root name={root.name!r}")
    return {"schema_version": 1, "entries": entries}


def _write_salvage(root: Path, salvage: Path) -> dict[str, Any]:
    expected = _salvage_payload(root)
    temporary = salvage.with_name(f".{salvage.name}.candidate")
    if temporary.exists() or salvage.exists():
        raise PipelineError(f"cleanup.salvage expected=absent actual=exists name={salvage.name!r}")
    try:
        temporary.write_bytes(canonical_json_bytes(expected))
        os.replace(temporary, salvage)
    finally:
        if temporary.exists():
            temporary.unlink()
    measured = load_json(salvage)
    if not _strictly_equal(measured, expected):
        raise PipelineError(f"cleanup.salvage verification-failed name={salvage.name!r}")
    return expected


def _publish(candidate: Path, output_dir: Path, clean: bool) -> None:
    if not output_dir.exists():
        os.replace(candidate, output_dir)
        return
    if not clean:
        raise PipelineError(f"output expected=absent-or-clean actual=exists name={output_dir.name!r}")
    backup = output_dir.with_name(f".{output_dir.name}.rollback.{os.getpid()}.{next(_PUBLISH_SEQUENCE)}")
    while backup.exists():
        backup = output_dir.with_name(f".{output_dir.name}.rollback.{os.getpid()}.{next(_PUBLISH_SEQUENCE)}")
    os.replace(output_dir, backup)
    try:
        os.replace(candidate, output_dir)
    except OSError as cutover_error:
        rollback_error: OSError | None = None
        for _attempt in range(2):
            try:
                os.replace(backup, output_dir)
                rollback_error = None
                break
            except OSError as error:
                rollback_error = error
        if rollback_error is not None:
            raise PipelineError(
                f"publication cutover-and-rollback failed; accepted packet preserved as {backup.name!r}"
            ) from rollback_error
        raise cutover_error
    salvage = backup.with_name(f"{backup.name}.salvage.json")
    try:
        _write_salvage(backup, salvage)
    except (OSError, PipelineError, ValueError) as error:
        raise PipelineError(
            "publication committed but backup salvage failed; "
            f"accepted packet preserved as {backup.name!r}"
        ) from error
    try:
        _preflight_removable_tree(backup)
    except (OSError, PipelineError) as error:
        raise PipelineError(
            "publication committed but backup cleanup failed preflight; "
            f"complete rollback retained as {salvage.name!r}"
        ) from error
    try:
        _remove_tree(backup)
    except OSError as error:
        raise PipelineError(
            "publication committed but backup cleanup failed; "
            f"complete rollback retained as {salvage.name!r}"
        ) from error
    try:
        salvage.unlink()
    except OSError as error:
        raise PipelineError(
            "publication committed but salvage cleanup failed; "
            f"complete rollback retained as {salvage.name!r}"
        ) from error


def build_packet(spec_path: Path, input_root: Path, output_dir: Path, clean: bool) -> dict[str, Any]:
    _require_backend_versions()
    if output_dir.exists() and not clean:
        raise PipelineError(f"output expected=absent-or-clean actual=exists name={output_dir.name!r}")
    candidate = output_dir.with_name(f".{output_dir.name}.candidate.{os.getpid()}")
    if candidate.exists():
        shutil.rmtree(candidate)
    try:
        metadata = prepare_packet(spec_path, input_root, candidate)
        _publish(candidate, output_dir, clean)
        return metadata
    except (OSError, SpecError, QualityError, PipelineError, ValueError):
        if candidate.exists():
            shutil.rmtree(candidate)
        raise


def fail_payload(error: BaseException) -> dict[str, Any]:
    return {
        "status": "FAIL",
        "error_type": type(error).__name__,
        "detail": str(error),
        "python": sys.version.split()[0],
    }
