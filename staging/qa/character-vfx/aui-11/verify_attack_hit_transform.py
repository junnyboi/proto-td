#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, __version__ as pillow_version


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_record(path: Path) -> dict[str, object]:
    with Image.open(path) as raw:
        raw.load()
        rgba = raw.convert("RGBA")
    return {"file_sha256": sha(path.read_bytes()), "rgba_sha256": sha(rgba.tobytes()), "bytes": path.stat().st_size}


def parse_hex(value: str) -> tuple[int, int, int]:
    return tuple(bytes.fromhex(value))


def compress(image: Image.Image, contract: dict[str, object]) -> Image.Image:
    alpha_box = image.getchannel("A").getbbox()
    if alpha_box is None:
        raise ValueError("empty pre-transform frame")
    crop = image.crop(alpha_box)
    pin = contract["vertical_compression"]
    target_height = max(1, crop.height * pin["numerator"] // pin["denominator"])
    resized = crop.resize((crop.width, target_height), Image.Resampling.NEAREST)
    output = Image.new("RGBA", tuple(contract["cell_size"]), (0, 0, 0, 0))
    x = (output.width - resized.width) // 2
    y = (output.height - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


def dilate(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    if pin.get("mode") == "preserve_component_gaps":
        return dilate_separated(image, pin)
    result = image.convert("RGBA")
    for _ in range(pin["iterations"]):
        width, height = result.size
        base = list(result.get_flattened_data())
        output = base.copy()
        for y in range(height):
            for x in range(width):
                index = y * width + x
                if base[index][3] != 0:
                    continue
                neighbors = []
                for ny in range(max(0, y - 1), min(height, y + 2)):
                    for nx in range(max(0, x - 1), min(width, x + 2)):
                        if nx == x and ny == y:
                            continue
                        pixel = base[ny * width + nx]
                        if pixel[3] != 0:
                            neighbors.append((ny, nx, pixel))
                if neighbors:
                    neighbors.sort(key=lambda item: (item[0], item[1]))
                    output[index] = neighbors[0][2]
        result = Image.new("RGBA", result.size, (0, 0, 0, 0))
        result.putdata(output)
    return result


def dilate_separated(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    current = image.convert("RGBA")
    width, height = current.size
    pixels = list(current.get_flattened_data())
    labels = [0] * (width * height)
    next_label = 0
    for start, pixel in enumerate(pixels):
        if pixel[3] == 0 or labels[start] != 0:
            continue
        next_label += 1
        labels[start] = next_label
        queue = [start]
        for index in queue:
            x, y = index % width, index // width
            for yy in range(max(0, y - 1), min(height, y + 2)):
                for xx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = yy * width + xx
                    if pixels[neighbor][3] and labels[neighbor] == 0:
                        labels[neighbor] = next_label
                        queue.append(neighbor)
    for _ in range(pin["iterations"]):
        before_pixels = pixels.copy()
        before_labels = labels.copy()
        for y in range(height):
            for x in range(width):
                index = y * width + x
                if before_labels[index] != 0:
                    continue
                candidates = []
                for yy in range(max(0, y - 1), min(height, y + 2)):
                    for xx in range(max(0, x - 1), min(width, x + 2)):
                        neighbor = yy * width + xx
                        if before_labels[neighbor] != 0:
                            candidates.append((before_labels[neighbor], yy, xx, before_pixels[neighbor]))
                if len({entry[0] for entry in candidates}) == 1:
                    candidates.sort(key=lambda entry: (entry[1], entry[2]))
                    labels[index] = candidates[0][0]
                    pixels[index] = candidates[0][3]
    output = Image.new("RGBA", current.size, (0, 0, 0, 0))
    output.putdata(pixels)
    return output


def accent_coordinate(image: Image.Image, closure: dict[str, object]) -> tuple[int, int]:
    if "accent_coordinate" in closure:
        return tuple(closure["accent_coordinate"])
    if closure.get("accent_selector") != "first_opaque_y_then_x":
        raise ValueError("unsupported loop-closure accent selector")
    for y in range(image.height):
        for x in range(image.width):
            if image.getpixel((x, y))[3] != 0:
                return x, y
    raise ValueError("cannot accent empty image")


def clear_open_center(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("cannot clear center of empty image")
    center_x = (box[0] + box[2]) // 2
    center_y = (box[1] + box[3]) // 2
    output = image.copy()
    for y in range(center_y - pin["height"] // 2, center_y + pin["height"] // 2):
        for x in range(center_x - pin["width"] // 2, center_x + pin["width"] // 2):
            if 0 <= x < output.width and 0 <= y < output.height:
                output.putpixel((x, y), (0, 0, 0, 0))
    return output


def densify(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    width, height = image.size
    base = list(image.get_flattened_data())
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty densification frame")
    candidates = []
    inset = pin["candidate_inset"]
    for y in range(box[1] + inset, box[3] - inset):
        for x in range(box[0] + inset, box[2] - inset):
            if base[y * width + x][3] != 0:
                continue
            neighbors = [
                base[ny * width + nx]
                for ny in range(y - 1, y + 2)
                for nx in range(x - 1, x + 2)
                if (nx != x or ny != y) and base[ny * width + nx][3] != 0
            ]
            if len(neighbors) >= pin["minimum_occupied_neighbors"]:
                candidates.append((len(neighbors), y, x, neighbors))
    candidates.sort(key=lambda item: (-item[0], item[1], item[2]))
    if len(candidates) < pin["selected_candidates"]:
        raise ValueError("not enough densification candidates")
    output = base.copy()
    for _, y, x, neighbors in candidates[: pin["selected_candidates"]]:
        output[y * width + x] = (
            sum(pixel[0] for pixel in neighbors) // len(neighbors),
            sum(pixel[1] for pixel in neighbors) // len(neighbors),
            sum(pixel[2] for pixel in neighbors) // len(neighbors),
            pin["output_alpha"],
        )
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.putdata(output)
    return result


def add_detached_chips(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("cannot add chips to empty frame")
    output = image.copy()
    center_y = (box[1] + box[3]) // 2
    positions = {
        "left": box[0] - pin["gap"] - pin["width"],
        "right": box[2] + pin["gap"],
    }
    for side in pin["sides"]:
        x0 = positions[side]
        y0 = center_y - pin["height"] // 2
        for y in range(y0, y0 + pin["height"]):
            for x in range(x0, x0 + pin["width"]):
                output.putpixel((x, y), tuple(pin["color"]))
    return output


def remap(image: Image.Image, mapping: dict[str, str]) -> Image.Image:
    colors = {parse_hex(source): parse_hex(target) for source, target in mapping.items()}
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.putdata([(*colors.get(pixel[:3], pixel[:3]), pixel[3]) for pixel in image.get_flattened_data()])
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, required=True)
    parser.add_argument("--input-root", type=Path, required=True)
    parser.add_argument("--expected-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    if pillow_version != "12.3.0":
        raise RuntimeError(f"Pillow version mismatch: {pillow_version}")
    if args.output_root.exists():
        shutil.rmtree(args.output_root)
    args.output_root.mkdir(parents=True)
    images: list[Image.Image] = []
    input_records = []
    for index in range(contract["expected_final_frames"]):
        path = args.input_root / f"frame_{index:02d}.png"
        input_records.append({"frame": index, **file_record(path)})
        with Image.open(path) as raw:
            raw.load()
            image = raw.convert("RGBA")
            if "pre_dilation" in contract:
                image = dilate(image, contract["pre_dilation"])
            images.append(compress(image, contract))
    for closure in contract["loop_closure"]:
        result = images[closure["source_frame"]].copy()
        result.putpixel(accent_coordinate(result, closure), tuple(closure["accent_after"]))
        images[closure["target_frame"]] = result
    if "open_center_clear" in contract:
        images = [clear_open_center(image, contract["open_center_clear"]) for image in images]
    if "densification" in contract:
        pin = contract["densification"]
        images[pin["frame"]] = densify(images[pin["frame"]], pin)
    if "detached_chips" in contract:
        pin = contract["detached_chips"]
        images[pin["frame"]] = add_detached_chips(images[pin["frame"]], pin)
    images = [remap(image, contract["reserved_color_remap"]) for image in images]
    output_records = []
    for index, image in enumerate(images):
        output = args.output_root / f"frame_{index:02d}.png"
        expected = args.expected_root / output.name
        image.save(output, format="PNG", optimize=False, compress_level=9)
        output_record = file_record(output)
        expected_record = file_record(expected)
        if output_record != expected_record:
            raise AssertionError(f"frame {index} transformation mismatch: {output_record} != {expected_record}")
        output_records.append({"frame": index, "reconstructed": output_record, "expected_final": expected_record})
    report = {
        "schema_version": 1,
        "status": "PASS",
        "contract_sha256": sha(args.contract.read_bytes()),
        "pillow": pillow_version,
        "inputs": input_records,
        "outputs": output_records,
    }
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "frames": len(output_records)}, sort_keys=True))


if __name__ == "__main__":
    main()
