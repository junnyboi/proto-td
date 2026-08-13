#!/usr/bin/env python3
"""Build deterministic, unlabeled AUI-11 blind-review inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


PACKETS = Path("staging/character-vfx/aui-11/packets")
OUTPUTS = {
    "vanguard_silhouette": "blind-vanguard-silhouette.png",
    "grunt_silhouette": "blind-grunt-silhouette.png",
    "state_pair": "blind-grunt-state-pair.png",
}
ATLAS_INPUTS = {
    "vanguard": PACKETS / "vanguard_1/aui11-vanguard_1.png",
    "grunt": PACKETS / "grunt/aui11-grunt.png",
    "grunt_charmed": PACKETS / "grunt_charmed/aui11-grunt_charmed.png",
}
SOURCE_CELL = 192
REVIEW_CELL = 72
COLUMNS = 4
ROWS = 2
BACKGROUND = (230, 230, 230, 255)
SILHOUETTE = (17, 17, 17, 255)
PAIR_GAP = 8


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(path: Path, root: Path) -> dict[str, object]:
    return {
        "bytes": path.stat().st_size,
        "path": "res://" + path.relative_to(root).as_posix(),
        "sha256": sha256(path),
    }


def resize_cell(cell: Image.Image) -> Image.Image:
    return cell.resize((REVIEW_CELL, REVIEW_CELL), Image.Resampling.NEAREST)


def build_strip(atlas: Image.Image, *, silhouette: bool) -> Image.Image:
    strip = Image.new("RGBA", (COLUMNS * REVIEW_CELL, ROWS * REVIEW_CELL), BACKGROUND)
    for row in range(ROWS):
        for column in range(COLUMNS):
            box = (
                column * SOURCE_CELL,
                row * SOURCE_CELL,
                (column + 1) * SOURCE_CELL,
                (row + 1) * SOURCE_CELL,
            )
            cell = resize_cell(atlas.crop(box).convert("RGBA"))
            alpha = cell.getchannel("A")
            if silhouette:
                foreground = Image.new("RGBA", cell.size, SILHOUETTE)
                foreground.putalpha(alpha)
            else:
                grayscale = cell.convert("L")
                foreground = Image.merge("RGBA", (grayscale, grayscale, grayscale, alpha))
            background = Image.new("RGBA", cell.size, BACKGROUND)
            background.alpha_composite(foreground)
            strip.alpha_composite(background, (column * REVIEW_CELL, row * REVIEW_CELL))
    return strip


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()

    project = Path(args.project).resolve()
    output_dir = Path(args.output_dir).resolve()
    manifest_path = Path(args.manifest).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    atlases: dict[str, Image.Image] = {}
    for name, relative in ATLAS_INPUTS.items():
        path = project / relative
        with Image.open(path) as image:
            atlas = image.convert("RGBA")
        if atlas.size != (SOURCE_CELL * COLUMNS, SOURCE_CELL * ROWS):
            raise ValueError(f"{name}: unexpected atlas size {atlas.size}")
        atlases[name] = atlas

    vanguard_path = output_dir / OUTPUTS["vanguard_silhouette"]
    grunt_path = output_dir / OUTPUTS["grunt_silhouette"]
    state_path = output_dir / OUTPUTS["state_pair"]

    build_strip(atlases["vanguard"], silhouette=True).save(vanguard_path, optimize=False)
    build_strip(atlases["grunt"], silhouette=True).save(grunt_path, optimize=False)

    left = build_strip(atlases["grunt_charmed"], silhouette=False)
    right = build_strip(atlases["grunt"], silhouette=False)
    pair = Image.new(
        "RGBA",
        (left.width + PAIR_GAP + right.width, left.height),
        BACKGROUND,
    )
    pair.alpha_composite(left, (0, 0))
    pair.alpha_composite(right, (left.width + PAIR_GAP, 0))
    pair.save(state_path, optimize=False)

    manifest = {
        "schema_version": "mgs.aui11.blind-review-inputs.v1",
        "batch_id": "AUI-11",
        "background_rgba": list(BACKGROUND),
        "columns": COLUMNS,
        "generator": record(Path(__file__).resolve(), project),
        "inputs": {
            name: record(project / relative, project)
            for name, relative in sorted(ATLAS_INPUTS.items())
        },
        "outputs": {
            name: record(output_dir / filename, project)
            for name, filename in sorted(OUTPUTS.items())
        },
        "review_cell_px": REVIEW_CELL,
        "rows": ROWS,
        "silhouette_rgba": list(SILHOUETTE),
        "source_cell_px": SOURCE_CELL,
        "state_pair_order": {
            "left": "grunt_charmed",
            "right": "grunt",
        },
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps({"outputs": OUTPUTS, "status": "PASS"}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
