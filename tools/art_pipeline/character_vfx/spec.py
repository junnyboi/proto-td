"""Strict AUI-34 input contract and trusted-root containment."""

from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from typing import Any

from canonical_io import load_json

HEX_RE = re.compile(r"^#[0-9A-F]{6}$")
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
CONCEPT_HASHES = (
    "f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
    "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
    "f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
    "d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
    "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
    "0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
)
TOP_KEYS = {
    "schema_version", "asset_id", "asset_class", "state", "frames", "atlas",
    "animations", "palette", "normalization", "reserved_colors", "outputs", "provenance",
}
FRAME_KEYS = {"path", "row", "column"}
ATLAS_KEYS = {
    "width", "height", "columns", "rows", "cell_width", "cell_height", "pivot", "foot_row",
}
ANIMATION_KEYS = {"name", "row", "frames", "fps", "loop"}
NORMALIZATION_KEYS = {
    "background_key", "alpha_threshold", "minimum_component_size", "anchor_x", "anchor_foot_y", "resize",
}
OUTPUT_KEYS = {"atlas", "metadata", "qa", "contact"}
PROVENANCE_KEYS = {
    "tool", "model", "prompt_sha256", "reference_sha256", "seed", "approved_concept_sha256",
    "human_approval",
}


class SpecError(ValueError):
    """A measured fail-closed contract violation."""


def _exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    actual = set(value)
    if actual != expected:
        raise SpecError(f"{label}.keys expected={sorted(expected)} actual={sorted(actual)}")


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _strictly_equal(recorded: Any, expected: Any) -> bool:
    if type(recorded) is not type(expected):
        return False
    if isinstance(expected, dict):
        return set(recorded) == set(expected) and all(
            _strictly_equal(recorded[key], expected[key]) for key in expected
        )
    if isinstance(expected, list):
        return len(recorded) == len(expected) and all(
            _strictly_equal(left, right) for left, right in zip(recorded, expected)
        )
    return recorded == expected


def _hex(value: Any, label: str) -> str:
    if not isinstance(value, str) or not HEX_RE.fullmatch(value):
        raise SpecError(f"{label} expected=#RRGGBB-uppercase actual={value!r}")
    return value


def _optional_sha(value: Any, label: str) -> None:
    if value is not None and (not isinstance(value, str) or not SHA_RE.fullmatch(value)):
        raise SpecError(f"{label} expected=null-or-sha256 actual={value!r}")


def validate_relative_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value or "\x00" in value:
        raise SpecError(f"{label} expected=non-empty-posix-relative-path")
    if "\\" in value or ":" in value:
        raise SpecError(f"{label} forbidden-separator-or-colon value={value!r}")
    segments = value.split("/")
    if any(segment in {"", ".", ".."} for segment in segments):
        raise SpecError(f"{label} path-escape value={value!r}")
    pure = PurePosixPath(value)
    if pure.is_absolute():
        raise SpecError(f"{label} path-escape value={value!r}")
    return value


def resolve_inside(root: Path, relative: str, label: str) -> Path:
    trusted = root.resolve(strict=True)
    if not trusted.is_dir():
        raise SpecError("input_root expected=directory")
    candidate = (trusted / relative).resolve(strict=True)
    if candidate == trusted or not candidate.is_relative_to(trusted):
        raise SpecError(f"{label} realpath-escape value={relative!r}")
    if not candidate.is_file():
        raise SpecError(f"{label} expected=file value={relative!r}")
    return candidate


def load_and_validate(spec_path: Path, input_root: Path) -> tuple[dict[str, Any], list[Path]]:
    raw = load_json(spec_path)
    if not isinstance(raw, dict):
        raise SpecError("spec expected=object")
    _exact_keys(raw, TOP_KEYS, "spec")
    if type(raw["schema_version"]) is not int or raw["schema_version"] != 1:
        raise SpecError(f"schema_version expected=1 actual={raw['schema_version']!r}")
    for key in ("asset_id", "asset_class", "state"):
        if not isinstance(raw[key], str) or not raw[key]:
            raise SpecError(f"{key} expected=non-empty-string")
    if raw["asset_class"] != "character_vfx":
        raise SpecError(f"asset_class expected=character_vfx actual={raw['asset_class']!r}")

    atlas = raw["atlas"]
    if not isinstance(atlas, dict):
        raise SpecError("atlas expected=object")
    _exact_keys(atlas, ATLAS_KEYS, "atlas")
    pinned_atlas = {
        "width": 768, "height": 384, "columns": 4, "rows": 2,
        "cell_width": 192, "cell_height": 192, "pivot": [0.5, 0.94], "foot_row": 180,
    }
    if not _strictly_equal(atlas, pinned_atlas):
        raise SpecError(f"atlas expected={pinned_atlas!r} actual={atlas!r}")

    frames = raw["frames"]
    if not isinstance(frames, list) or len(frames) != 8:
        raise SpecError(f"frames.count expected=8 actual={len(frames) if isinstance(frames, list) else 'non-list'}")
    resolved: list[Path] = []
    cells: set[tuple[int, int]] = set()
    for index, frame in enumerate(frames):
        if not isinstance(frame, dict):
            raise SpecError(f"frames[{index}] expected=object")
        _exact_keys(frame, FRAME_KEYS, f"frames[{index}]")
        row, column = frame["row"], frame["column"]
        if not _is_int(row) or not _is_int(column) or row not in range(2) or column not in range(4):
            raise SpecError(f"frames[{index}].cell expected=row0..1,col0..3 actual={row!r},{column!r}")
        if (row, column) in cells:
            raise SpecError(f"frames[{index}].cell duplicate={row},{column}")
        cells.add((row, column))
        relative = validate_relative_path(frame["path"], f"frames[{index}].path")
        resolved.append(resolve_inside(input_root, relative, f"frames[{index}].path"))
    if cells != {(row, column) for row in range(2) for column in range(4)}:
        raise SpecError(f"frames.cells incomplete={sorted(cells)}")

    animations = raw["animations"]
    if not isinstance(animations, list) or len(animations) != 2:
        raise SpecError("animations expected=two-rows")
    expected_animations = [
        {"name": "rest_movement", "row": 0, "frames": 4, "fps": 5.5, "loop": True},
        {"name": "attack_skill", "row": 1, "frames": 4, "fps": 8, "loop": True},
    ]
    for index, animation in enumerate(animations):
        if not isinstance(animation, dict):
            raise SpecError(f"animations[{index}] expected=object")
        _exact_keys(animation, ANIMATION_KEYS, f"animations[{index}]")
    if not _strictly_equal(animations, expected_animations):
        raise SpecError(f"animations expected={expected_animations!r} actual={animations!r}")

    palette = raw["palette"]
    if not isinstance(palette, list) or not palette or len(set(palette)) != len(palette):
        raise SpecError("palette expected=non-empty-unique-array")
    for index, color in enumerate(palette):
        _hex(color, f"palette[{index}]")
    reserved = raw["reserved_colors"]
    if reserved != ["#F4F4F4", "#41A6F6"]:
        raise SpecError(f"reserved_colors expected=['#F4F4F4','#41A6F6'] actual={reserved!r}")
    if set(palette) & set(reserved):
        raise SpecError(f"palette reserved-collision={sorted(set(palette) & set(reserved))}")

    normalization = raw["normalization"]
    if not isinstance(normalization, dict):
        raise SpecError("normalization expected=object")
    _exact_keys(normalization, NORMALIZATION_KEYS, "normalization")
    _hex(normalization["background_key"], "normalization.background_key")
    expected_numbers = {"alpha_threshold": 26, "anchor_x": 96, "anchor_foot_y": 180}
    for key, expected in expected_numbers.items():
        if not _is_int(normalization[key]) or normalization[key] != expected:
            raise SpecError(f"normalization.{key} expected={expected} actual={normalization[key]!r}")
    minimum = normalization["minimum_component_size"]
    if not _is_int(minimum) or minimum < 0:
        raise SpecError("normalization.minimum_component_size expected=integer>=0")
    resize = normalization["resize"]
    if resize is not None and (
        not isinstance(resize, list) or len(resize) != 2 or not all(_is_int(v) and v > 0 for v in resize)
    ):
        raise SpecError("normalization.resize expected=null-or-[positive-int,positive-int]")

    outputs = raw["outputs"]
    if not isinstance(outputs, dict):
        raise SpecError("outputs expected=object")
    _exact_keys(outputs, OUTPUT_KEYS, "outputs")
    suffixes = {"atlas": ".png", "metadata": ".asset.json", "qa": ".qa.json", "contact": ".contact.png"}
    output_values: list[str] = []
    for key, suffix in suffixes.items():
        value = validate_relative_path(outputs[key], f"outputs.{key}")
        if "/" in value or not value.endswith(suffix):
            raise SpecError(f"outputs.{key} expected=basename-ending-{suffix} actual={value!r}")
        output_values.append(value)
    if len(set(output_values)) != 4:
        raise SpecError("outputs filenames must be unique")

    provenance = raw["provenance"]
    if not isinstance(provenance, dict):
        raise SpecError("provenance expected=object")
    _exact_keys(provenance, PROVENANCE_KEYS, "provenance")
    for key in ("tool", "model", "human_approval"):
        if not isinstance(provenance[key], str) or not provenance[key]:
            raise SpecError(f"provenance.{key} expected=non-empty-string")
    _optional_sha(provenance["prompt_sha256"], "provenance.prompt_sha256")
    _optional_sha(provenance["reference_sha256"], "provenance.reference_sha256")
    if provenance["seed"] is not None and not _is_int(provenance["seed"]):
        raise SpecError("provenance.seed expected=null-or-integer")
    if tuple(provenance["approved_concept_sha256"]) != CONCEPT_HASHES:
        raise SpecError("provenance.approved_concept_sha256 differs from exact Round 5 approval")
    if provenance["human_approval"] != "CONCEPT_APPROVED_RUNTIME_UNBOUND":
        raise SpecError("provenance.human_approval must remain concept-approved/runtime-unbound")
    return raw, resolved
