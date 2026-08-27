#!/usr/bin/env python3
"""Configure 600px enemy-variant atlases for browser-safe 2D import.

The quality-92 WebP sources remain untouched. Godot uses high-quality compressed
runtime storage plus mipmaps, reducing PCK and decoded startup pressure while
retaining the authored 560-640px per-frame detail.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IMPORT_ROOT = ROOT / "assets" / "enemy-variants"
EXPECTED_IMPORTS = 24
REPLACEMENTS = {
    "compress/mode=0": "compress/mode=1",
    "compress/lossy_quality=0.7": "compress/lossy_quality=0.92",
    "mipmaps/generate=false": "mipmaps/generate=true",
}


def main() -> None:
    paths = sorted(IMPORT_ROOT.glob("*.webp.import"))
    if len(paths) != EXPECTED_IMPORTS:
        raise SystemExit(f"expected {EXPECTED_IMPORTS} enemy variant imports, found {len(paths)}")

    changed = 0
    for path in paths:
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in REPLACEMENTS.items():
            if old not in text and new not in text:
                raise SystemExit(f"{path}: missing import setting {old!r}")
            text = text.replace(old, new)
        if text != original:
            path.write_text(text, encoding="utf-8")
            changed += 1

    print(f"configured={len(paths)} changed={changed} mode=lossy quality=0.92 mipmaps=true")


if __name__ == "__main__":
    main()
