#!/usr/bin/env python3
"""Extract the concept-faithful attack-hit master with pinned rembg and all material components."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from collections import deque
from pathlib import Path

from PIL import Image
from rembg import new_session, remove

MODEL_ROOT = Path(os.environ.get("U2NET_HOME", str(Path.home() / ".cache/aui11-rembg-models")))
MODEL = "isnet-general-use"
MODEL_SHA256 = "60920e99c45464f2ba57bee2ad08c919a52bbf852739e96947fbb4358c0d964a"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def components(alpha: Image.Image, threshold: int = 16) -> list[list[int]]:
    width, height = alpha.size
    values = list(alpha.getdata())
    remaining = {index for index, value in enumerate(values) if value > threshold}
    result: list[list[int]] = []
    while remaining:
        start = remaining.pop()
        group = [start]
        queue: deque[int] = deque([start])
        while queue:
            index = queue.popleft()
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1), (x + 1, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = ny * width + nx
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        queue.append(neighbor)
                        group.append(neighbor)
        result.append(group)
    return sorted(result, key=len, reverse=True)


def keep_material(image: Image.Image, minimum: int = 96) -> tuple[Image.Image, dict[str, object]]:
    output = image.convert("RGBA")
    found = components(output.getchannel("A"))
    kept = [group for group in found if len(group) >= minimum]
    if not kept:
        raise ValueError("foreground segmentation returned no material components")
    keep = bytearray(output.width * output.height)
    for group in kept:
        for index in group:
            keep[index] = 1
    data = list(output.getdata())
    for index, selected in enumerate(keep):
        if not selected:
            data[index] = (0, 0, 0, 0)
    output.putdata(data)
    box = output.getchannel("A").getbbox()
    if box is None:
        raise ValueError("component filtering produced an empty frame")
    return output, {
        "components_before": len(found),
        "components_kept": len(kept),
        "material_pixels": sum(len(group) for group in kept),
        "visible_bbox": list(box),
    }


def fit(subject: Image.Image, size: int, margin: int) -> tuple[Image.Image, dict[str, object]]:
    box = subject.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty segmented cell")
    cropped = subject.crop(box)
    scale_ppm = min((size - 2 * margin) * 1_000_000 // cropped.width, (size - 2 * margin) * 1_000_000 // cropped.height)
    width = max(1, cropped.width * scale_ppm // 1_000_000)
    height = max(1, cropped.height * scale_ppm // 1_000_000)
    resized = cropped.resize((width, height), resample=Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x, y = (size - width) // 2, size - margin - height
    canvas.alpha_composite(resized, (x, y))
    return canvas, {
        "source_bbox": list(box),
        "cropped_size": [cropped.width, cropped.height],
        "output_bbox": list(canvas.getchannel("A").getbbox() or (0, 0, 0, 0)),
        "output_size": [size, size],
    }


def record(path: Path) -> dict[str, object]:
    return {"bytes": path.stat().st_size, "path": str(path), "sha256": sha256(path)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", required=True)
    parser.add_argument("--source-root", required=True)
    parser.add_argument("--clean-master", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--asset-id", default="attack_hit")
    parser.add_argument("--native-size", type=int, default=128)
    parser.add_argument("--margin", type=int, default=9)
    args = parser.parse_args()
    candidate = Path(args.master).resolve()
    source_root = Path(args.source_root).resolve()
    clean_master_path = Path(args.clean_master).resolve()
    report_path = Path(args.report).resolve()
    model_path = MODEL_ROOT / f"{MODEL}.onnx"
    if not model_path.is_file() or sha256(model_path) != MODEL_SHA256:
        raise ValueError("pinned rembg model missing or hash mismatch")
    with Image.open(candidate) as raw:
        raw.load()
        master = raw.convert("RGB")
    if master.size != (2560, 1440):
        raise ValueError(f"unexpected master size: {master.size}")
    session = new_session(MODEL)
    source_root.mkdir(parents=True, exist_ok=True)
    clean_master = Image.new("RGBA", master.size, (0, 0, 0, 0))
    frames = []
    for index in range(8):
        row, column = divmod(index, 4)
        box = (column * 640, row * 720, (column + 1) * 640, (row + 1) * 720)
        segmented = remove(master.crop(box), session=session, alpha_matting=False)
        cleaned, component_report = keep_material(segmented)
        clean_cell, _ = fit(cleaned, 640, 12)
        clean_master.alpha_composite(clean_cell, (column * 640, row * 720))
        frame, measures = fit(cleaned, args.native_size, args.margin)
        path = source_root / f"frame_{index:02d}.png"
        frame.save(path, format="PNG", optimize=False, compress_level=9)
        frames.append({"index": index, **record(path), **component_report, **measures})
    clean_master_path.parent.mkdir(parents=True, exist_ok=True)
    clean_master.save(clean_master_path, format="PNG", optimize=False, compress_level=9)
    report = {
        "schema_version": f"mgs.aui11.{args.asset_id.replace('_', '-')}-source-extraction.v1",
        "candidate_master": record(candidate),
        "model": {"name": MODEL, "path": str(model_path), "sha256": sha256(model_path)},
        "clean_master": record(clean_master_path),
        "frames": frames,
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
