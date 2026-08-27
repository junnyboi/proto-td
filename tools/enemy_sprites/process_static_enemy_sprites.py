#!/usr/bin/env python3
"""Create core-resident 640px static enemy sprites from preserved GPT Image 2 sources."""

from __future__ import annotations

import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "docs/enemy-redesign/source/concepts"
RUNTIME_DIR = ROOT / "assets/sprites/enemies/static"
REPORT_PATH = ROOT / "docs/enemy-redesign/static-sprite-processing.json"
CHECKSUM_PATH = ROOT / "docs/enemy-redesign/SHA256SUMS.txt"

ENEMIES = {
    "runner": "ground",
    "shieldbearer": "ground",
    "breacher": "ground",
    "heavy": "ground",
    "drone": "aerial",
    "interceptor": "aerial",
    "spellcaster": "ground",
    "mini_boss": "ground",
}
CANVAS = 640
SUBJECT_MAX = 600
GROUND_BOTTOM = 624
ALPHA_THRESHOLD = 8
MIN_COMPONENT_PIXELS = 16


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def chroma_alpha(red: int, green: int, blue: int, alpha: int) -> int:
    if alpha == 0:
        return 0
    maximum_other = max(red, blue)
    dominance = green - maximum_other
    saturation = (max(red, green, blue) - min(red, green, blue)) / max(1, max(red, green, blue))
    # GPT Image 2 uses the requested #00FF00 field plus darker textured and
    # antialiased derivatives. Cyan machine light survives because blue tracks green.
    if green >= 45 and dominance >= 18 and saturation >= 0.22 and green >= int(red * 1.18) and green >= int(blue * 1.14):
        return 0
    if green >= 70 and dominance >= 10 and saturation >= 0.16:
        return max(0, int(alpha * (1.0 - min(1.0, (dominance - 9) / 28.0))))
    # The image model may texture the requested field into dark olive/green
    # speckles. Cyan details survive because blue remains equal to or above green.
    if green >= 28 and dominance >= 5 and green >= int(red * 1.15) and green >= int(blue * 1.08):
        return 0
    return alpha


def robust_subject_bbox(alpha: Image.Image) -> tuple[int, int, int, int] | None:
    """Discard sparse detached chroma flecks when locating the centered subject."""
    width, height = alpha.size
    values = list(alpha.getdata())
    row_threshold = max(6, width // 300)
    column_threshold = max(6, height // 300)
    rows = [
        sum(1 for value in values[y * width:(y + 1) * width] if value > ALPHA_THRESHOLD)
        for y in range(height)
    ]
    columns = [
        sum(1 for y in range(height) if values[y * width + x] > ALPHA_THRESHOLD)
        for x in range(width)
    ]
    active_rows = [index for index, count in enumerate(rows) if count >= row_threshold]
    active_columns = [index for index, count in enumerate(columns) if count >= column_threshold]
    if not active_rows or not active_columns:
        return None
    return (
        active_columns[0],
        active_rows[0],
        active_columns[-1] + 1,
        active_rows[-1] + 1,
    )


def remove_small_components(image: Image.Image) -> Image.Image:
    width, height = image.size
    alpha = list(image.getchannel("A").getdata())
    visited = bytearray(width * height)
    erase: list[int] = []
    for start, value in enumerate(alpha):
        if value <= ALPHA_THRESHOLD or visited[start]:
            continue
        component: list[int] = []
        queue: deque[int] = deque([start])
        visited[start] = 1
        while queue:
            index = queue.popleft()
            component.append(index)
            x = index % width
            y = index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < 0 or nx >= width or ny < 0 or ny >= height:
                    continue
                neighbor = ny * width + nx
                if visited[neighbor] or alpha[neighbor] <= ALPHA_THRESHOLD:
                    continue
                visited[neighbor] = 1
                queue.append(neighbor)
        if len(component) < MIN_COMPONENT_PIXELS:
            erase.extend(component)
    if not erase:
        return image
    pixels = list(image.getdata())
    for index in erase:
        red, green, blue, _alpha = pixels[index]
        pixels[index] = (red, green, blue, 0)
    cleaned = Image.new("RGBA", image.size)
    cleaned.putdata(pixels)
    return cleaned


def normalize_canvas(image: Image.Image, kind: str) -> Image.Image:
    bbox = image.getchannel("A").point(
        lambda value: 255 if value > ALPHA_THRESHOLD else 0
    ).getbbox()
    if bbox is None:
        raise RuntimeError("component cleanup removed the entire subject")
    subject = image.crop(bbox)
    scale = min(SUBJECT_MAX / subject.width, SUBJECT_MAX / subject.height)
    size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    x = (CANVAS - size[0]) // 2
    y = GROUND_BOTTOM - size[1] if kind == "ground" else (CANVAS - size[1]) // 2
    y = max(0, min(CANVAS - size[1], y))
    canvas.alpha_composite(subject, (x, y))
    return canvas


def process(enemy_id: str, kind: str) -> dict[str, object]:
    source = SOURCE_DIR / f"{enemy_id}.png"
    target = RUNTIME_DIR / f"{enemy_id}.png"
    image = Image.open(source).convert("RGBA")
    source_size = image.size
    pixels = list(image.getdata())
    cleaned = Image.new("RGBA", image.size)
    cleaned.putdata([(r, g, b, chroma_alpha(r, g, b, a)) for r, g, b, a in pixels])

    alpha = cleaned.getchannel("A")
    bbox = robust_subject_bbox(alpha)
    if bbox is None:
        raise RuntimeError(f"{enemy_id}: chroma cleanup removed the entire subject")
    subject = cleaned.crop(bbox)
    scale = min(SUBJECT_MAX / subject.width, SUBJECT_MAX / subject.height, 1.0)
    runtime_size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(runtime_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    x = (CANVAS - runtime_size[0]) // 2
    if kind == "ground":
        y = GROUND_BOTTOM - runtime_size[1]
    else:
        y = (CANVAS - runtime_size[1]) // 2
    y = max(0, min(CANVAS - runtime_size[1], y))
    canvas.alpha_composite(subject, (x, y))
    canvas = remove_small_components(canvas)
    canvas = normalize_canvas(canvas, kind)
    target.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(target, format="PNG", optimize=True)

    final_alpha = canvas.getchannel("A")
    final_bbox = final_alpha.point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox()
    assert final_bbox is not None
    visible_size = (final_bbox[2] - final_bbox[0], final_bbox[3] - final_bbox[1])
    if max(visible_size) < 560 or max(visible_size) > 600:
        raise RuntimeError(f"{enemy_id}: visible extent {visible_size} is outside 560–600 px")
    return {
        "id": enemy_id,
        "kind": kind,
        "source": str(source.relative_to(ROOT)),
        "source_size": list(source_size),
        "source_sha256": sha256(source),
        "runtime": str(target.relative_to(ROOT)),
        "runtime_canvas": [CANVAS, CANVAS],
        "visible_bbox": list(final_bbox),
        "visible_size": list(visible_size),
        "runtime_sha256": sha256(target),
        "runtime_bytes": target.stat().st_size,
    }


def configure_imports() -> None:
    for enemy_id in ENEMIES:
        import_path = RUNTIME_DIR / f"{enemy_id}.png.import"
        if not import_path.exists():
            continue
        source = import_path.read_text()
        source = source.replace("compress/mode=1", "compress/mode=0")
        source = source.replace("mipmaps/generate=false", "mipmaps/generate=true")
        source = source.replace("process/size_limit=2048", "process/size_limit=0")
        import_path.write_text(source)


def main() -> None:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    records = [process(enemy_id, kind) for enemy_id, kind in ENEMIES.items()]
    REPORT_PATH.write_text(json.dumps({"schema": 1, "sprites": records}, indent=2) + "\n")
    lines: list[str] = []
    for record in records:
        lines.append(f"{record['source_sha256']}  {record['source']}")
        lines.append(f"{record['runtime_sha256']}  {record['runtime']}")
    CHECKSUM_PATH.write_text("\n".join(lines) + "\n")
    configure_imports()
    print(f"STATIC_ENEMY_SPRITES_OK|count={len(records)}|report={REPORT_PATH}")


if __name__ == "__main__":
    main()
