#!/usr/bin/env python3
"""Register generated premium identity and Resonance portraits in assets/manifest.tres."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/manifest.tres"

ASSETS = {
    "portrait_archive_caster": (
        "res://assets/portraits/premium/archive_caster.png", (512, 512)
    ),
    "portrait_lunaris_vessel": (
        "res://assets/portraits/premium/lunaris_vessel.png", (512, 512)
    ),
    "portrait_reliquary_duelist": (
        "res://assets/portraits/premium/reliquary_duelist.png", (512, 512)
    ),
    "portrait_archive_caster_fullsize": (
        "res://assets/portraits/fullsize/archive_caster_fullsize.webp", (640, 800)
    ),
    "portrait_lunaris_vessel_fullsize": (
        "res://assets/portraits/fullsize/lunaris_vessel_fullsize.webp", (640, 800)
    ),
    "portrait_reliquary_duelist_fullsize": (
        "res://assets/portraits/fullsize/reliquary_duelist_fullsize.webp", (640, 800)
    ),
}


def entry_block(asset_id: str, path: str, size: tuple[int, int]) -> str:
    return f'''&"{asset_id}": {{
"animations": {{
&"default": {{
&"fps": 1.0,
&"length": 1,
&"loop": true,
&"start": 0
}}
}},
"frames": 1,
"pattern": "{path}",
"pivot": Vector2(0.5, 0.5),
"placeholder": false,
"size": Vector2i({size[0]}, {size[1]})
}}'''


def entry_span(text: str, asset_id: str) -> tuple[int, int]:
    marker = f'&"{asset_id}": {{'
    start = text.find(marker)
    if start < 0:
        raise RuntimeError(f"premium portrait manifest entry is missing: {asset_id}")
    brace = text.find("{", start)
    depth = 0
    in_string = False
    escaped = False
    for index in range(brace, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return start, index + 1
    raise RuntimeError(f"unterminated premium portrait manifest entry: {asset_id}")


def main() -> None:
    text = MANIFEST.read_text(encoding="utf-8")
    for asset_id, (path, size) in ASSETS.items():
        start, end = entry_span(text, asset_id)
        text = text[:start] + entry_block(asset_id, path, size) + text[end:]
    MANIFEST.write_text(text, encoding="utf-8")
    print(f"registered {len(ASSETS)} generated premium portrait assets")


if __name__ == "__main__":
    main()
