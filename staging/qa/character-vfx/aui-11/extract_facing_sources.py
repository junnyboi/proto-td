#!/usr/bin/env python3
"""Extract the bounded AUI-11 facing-correction candidates with pinned rembg models."""

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
ASSETS = ("vanguard_1", "grunt")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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
            x = index % width
            y = index // width
            for nx, ny in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
                (x - 1, y - 1),
                (x + 1, y - 1),
                (x - 1, y + 1),
                (x + 1, y + 1),
            ):
                if not (0 <= nx < width and 0 <= ny < height):
                    continue
                neighbor = ny * width + nx
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    queue.append(neighbor)
                    group.append(neighbor)
        result.append(group)
    return sorted(result, key=len, reverse=True)


def keep_largest(image: Image.Image) -> tuple[Image.Image, dict[str, object]]:
    output = image.convert("RGBA")
    found = components(output.getchannel("A"))
    if not found:
        raise ValueError("foreground segmentation returned no component")
    keep = bytearray(output.width * output.height)
    for index in found[0]:
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
        "components_kept": 1,
        "largest_component_pixels": len(found[0]),
        "visible_bbox": list(box),
    }


def fit_subject(subject: Image.Image, size: int = 192) -> tuple[Image.Image, dict[str, object]]:
    box = subject.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty segmented source cell")
    cropped = subject.crop(box)
    margin = 8
    scale_ppm = min(
        (size - margin * 2) * 1_000_000 // cropped.width,
        (size - margin * 2) * 1_000_000 // cropped.height,
    )
    width = max(1, cropped.width * scale_ppm // 1_000_000)
    height = max(1, cropped.height * scale_ppm // 1_000_000)
    resized = cropped.resize((width, height), resample=Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - width) // 2
    y = size - margin - height
    canvas.alpha_composite(resized, (x, y))
    return canvas, {
        "source_bbox": list(box),
        "cropped_size": [cropped.width, cropped.height],
        "output_bbox": list(canvas.getchannel("A").getbbox() or (0, 0, 0, 0)),
        "output_size": [size, size],
    }


def fit_master_cell(subject: Image.Image) -> Image.Image:
    box = subject.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty segmented master cell")
    cropped = subject.crop(box)
    margin = 12
    scale_ppm = min(
        (640 - margin * 2) * 1_000_000 // cropped.width,
        (720 - margin * 2) * 1_000_000 // cropped.height,
    )
    width = max(1, cropped.width * scale_ppm // 1_000_000)
    height = max(1, cropped.height * scale_ppm // 1_000_000)
    resized = cropped.resize((width, height), resample=Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (640, 720), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((640 - width) // 2, 720 - margin - height))
    return canvas


def record(path: Path) -> dict[str, object]:
    return {"bytes": path.stat().st_size, "path": str(path), "sha256": sha256(path)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--vanguard-master", required=True)
    parser.add_argument("--grunt-master", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--clean-master-root", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    masters = {
        "vanguard_1": Path(args.vanguard_master).resolve(),
        "grunt": Path(args.grunt_master).resolve(),
    }
    output_root = Path(args.output_root).resolve()
    clean_master_root = Path(args.clean_master_root).resolve()
    report_path = Path(args.report).resolve()
    model_path = MODEL_ROOT / f"{MODEL}.onnx"
    if not model_path.is_file() or sha256(model_path) != MODEL_SHA256:
        raise ValueError("pinned rembg model missing or hash mismatch")
    session = new_session(MODEL)
    report: dict[str, object] = {
        "schema_version": "mgs.aui11.facing-source-extraction.v1",
        "model": {"name": MODEL, **record(model_path)},
        "assets": {},
    }

    for asset_id in ASSETS:
        source_path = masters[asset_id]
        with Image.open(source_path) as raw:
            raw.load()
            master = raw.convert("RGB")
        if master.size != (2560, 1440):
            raise ValueError(f"{asset_id}: unexpected master size {master.size}")
        destination = output_root / asset_id
        destination.mkdir(parents=True, exist_ok=True)
        clean_master = Image.new("RGBA", master.size, (0, 0, 0, 0))
        frames: list[dict[str, object]] = []
        for index in range(8):
            row, column = divmod(index, 4)
            box = (column * 640, row * 720, (column + 1) * 640, (row + 1) * 720)
            segmented = remove(master.crop(box), session=session, alpha_matting=False)
            cleaned, component_report = keep_largest(segmented)
            clean_master.alpha_composite(fit_master_cell(cleaned), (column * 640, row * 720))
            frame, measures = fit_subject(cleaned)
            frame_path = destination / f"frame_{index:02d}.png"
            frame.save(frame_path, format="PNG", optimize=False, compress_level=9)
            frames.append({"index": index, **record(frame_path), **component_report, **measures})
        clean_master_root.mkdir(parents=True, exist_ok=True)
        clean_master_path = clean_master_root / f"{asset_id}-master.png"
        clean_master.save(clean_master_path, format="PNG", optimize=False, compress_level=9)
        report["assets"][asset_id] = {
            "candidate_master": record(source_path),
            "clean_master": record(clean_master_path),
            "frames": frames,
        }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
