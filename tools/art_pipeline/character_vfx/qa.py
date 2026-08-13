"""Measured fail-closed QA for AUI-34 packet images."""

from __future__ import annotations

from typing import Any

from PIL import Image

from pixel_ops import build_contact_sheet, opaque_bounds, parse_hex


class QualityError(ValueError):
    """A packet failed a mandatory measurable gate."""


def _check(checks: list[dict[str, Any]], name: str, ok: bool, detail: str) -> None:
    checks.append({"name": name, "ok": ok, "detail": detail})
    if not ok:
        raise QualityError(f"{name}: {detail}")


def inspect_atlas(atlas: Image.Image, spec: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    image = atlas.convert("RGBA")
    checks: list[dict[str, Any]] = []
    _check(checks, "atlas_dimensions", image.size == (768, 384), f"measured={image.width}x{image.height} expected=768x384")
    palette = {parse_hex(value) for value in spec["palette"]}
    reserved = {parse_hex(value) for value in spec["reserved_colors"]}
    soft_alpha: list[tuple[int, int, int]] = []
    palette_violations: list[tuple[int, int, tuple[int, int, int]]] = []
    reserved_violations: list[tuple[int, int, tuple[int, int, int]]] = []
    pixels = image.load()
    opaque_palette: set[tuple[int, int, int]] = set()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha not in (0, 255) and len(soft_alpha) < 5:
                soft_alpha.append((x, y, alpha))
            if alpha == 255:
                rgb = (red, green, blue)
                opaque_palette.add(rgb)
                if rgb not in palette and len(palette_violations) < 5:
                    palette_violations.append((x, y, rgb))
                if rgb in reserved and len(reserved_violations) < 5:
                    reserved_violations.append((x, y, rgb))
    _check(checks, "binary_alpha", not soft_alpha, f"invalid_samples={soft_alpha}")
    _check(checks, "palette_membership", not palette_violations, f"invalid_samples={palette_violations}")
    _check(checks, "reserved_colors", not reserved_violations, f"invalid_samples={reserved_violations}")

    cells: list[dict[str, Any]] = []
    for row in range(2):
        for column in range(4):
            cell = image.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
            bounds = opaque_bounds(cell)
            label = f"cell_{row}_{column}"
            _check(checks, f"{label}_non_empty", bounds is not None, f"bounds={bounds}")
            assert bounds is not None
            left, top, right, bottom = bounds
            center_x = (left + right) // 2
            border_count = 0
            cell_pixels = cell.load()
            opaque_count = 0
            for y in range(192):
                for x in range(192):
                    if cell_pixels[x, y][3] == 255:
                        opaque_count += 1
                        if x in (0, 191) or y in (0, 191):
                            border_count += 1
            _check(checks, f"{label}_border", border_count == 0, f"opaque_border_pixels={border_count}")
            _check(checks, f"{label}_foot", 179 <= bottom <= 181, f"measured={bottom} expected=179..181")
            _check(checks, f"{label}_center", center_x == 96, f"measured={center_x} expected=96")
            cells.append({
                "row": row, "column": column, "opaque_pixels": opaque_count,
                "bounds": [left, top, right, bottom], "center_x": center_x, "foot_row": bottom,
            })
    _check(checks, "cell_inventory", len(cells) == 8, f"measured={len(cells)} expected=8")
    return checks, {
        "cells": cells,
        "opaque_palette": ["#%02X%02X%02X" % rgb for rgb in sorted(opaque_palette)],
    }


def inspect_contact(contact: Image.Image, atlas: Image.Image) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    image = contact.convert("RGBA")
    checks: list[dict[str, Any]] = []
    _check(checks, "contact_dimensions", image.size == (1536, 256), f"measured={image.width}x{image.height} expected=1536x256")
    expected = build_contact_sheet(atlas)
    mismatch = None
    actual_pixels = image.load()
    expected_pixels = expected.load()
    for y in range(256):
        for x in range(1536):
            if actual_pixels[x, y] != expected_pixels[x, y]:
                mismatch = {"x": x, "y": y, "actual": list(actual_pixels[x, y]), "expected": list(expected_pixels[x, y])}
                break
        if mismatch is not None:
            break
    _check(checks, "contact_exact_raster", mismatch is None, f"first_mismatch={mismatch}")
    backgrounds = {
        "light": list(actual_pixels[0, 0]),
        "dark": list(actual_pixels[512, 0]),
        "grayscale": list(actual_pixels[1024, 0]),
    }
    _check(checks, "contact_light_background", backgrounds["light"] == [232, 223, 207, 255], f"measured={backgrounds['light']}")
    _check(checks, "contact_dark_background", backgrounds["dark"] == [27, 34, 48, 255], f"measured={backgrounds['dark']}")
    _check(checks, "contact_grayscale_background", backgrounds["grayscale"] == [128, 128, 128, 255], f"measured={backgrounds['grayscale']}")
    return checks, {"backgrounds": backgrounds}
