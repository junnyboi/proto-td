#!/usr/bin/env python3
"""Build AUI-11 attack-hit v2 sources from extracted concept-faithful frames."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image


def color(value: str) -> tuple[int, int, int]:
    return tuple(bytes.fromhex(value))


def expand(image: Image.Image, iterations: int) -> Image.Image:
    current = image.convert("RGBA")
    for _ in range(iterations):
        width, height = current.size
        before = list(current.get_flattened_data())
        after = before.copy()
        for y in range(height):
            for x in range(width):
                index = y * width + x
                if before[index][3]:
                    continue
                choices = []
                for yy in range(max(0, y - 1), min(height, y + 2)):
                    for xx in range(max(0, x - 1), min(width, x + 2)):
                        if xx == x and yy == y:
                            continue
                        pixel = before[yy * width + xx]
                        if pixel[3]:
                            choices.append((yy, xx, pixel))
                if choices:
                    choices.sort(key=lambda entry: (entry[0], entry[1]))
                    after[index] = choices[0][2]
        current = Image.new("RGBA", current.size, (0, 0, 0, 0))
        current.putdata(after)
    return current


def expand_separated(image: Image.Image, iterations: int) -> Image.Image:
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
    for _ in range(iterations):
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
                candidate_labels = {entry[0] for entry in candidates}
                if len(candidate_labels) == 1:
                    candidates.sort(key=lambda entry: (entry[1], entry[2]))
                    labels[index] = candidates[0][0]
                    pixels[index] = candidates[0][3]
    output = Image.new("RGBA", current.size, (0, 0, 0, 0))
    output.putdata(pixels)
    return output


def compress(image: Image.Image, contract: dict[str, object]) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty attack-hit input")
    crop = image.crop(box)
    pin = contract["vertical_compression"]
    height = max(1, crop.height * pin["numerator"] // pin["denominator"])
    resized = crop.resize((crop.width, height), Image.Resampling.NEAREST)
    output = Image.new("RGBA", tuple(contract["cell_size"]), (0, 0, 0, 0))
    output.alpha_composite(resized, ((output.width - resized.width) // 2, (output.height - resized.height) // 2))
    return output


def first_opaque(image: Image.Image) -> tuple[int, int]:
    for y in range(image.height):
        for x in range(image.width):
            if image.getpixel((x, y))[3]:
                return x, y
    raise ValueError("empty attack-hit frame")


def clear_open_center(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("cannot clear center of empty frame")
    center_x = (box[0] + box[2]) // 2
    center_y = (box[1] + box[3]) // 2
    half_width = pin["width"] // 2
    half_height = pin["height"] // 2
    output = image.copy()
    for y in range(center_y - half_height, center_y + half_height):
        for x in range(center_x - half_width, center_x + half_width):
            if 0 <= x < output.width and 0 <= y < output.height:
                output.putpixel((x, y), (0, 0, 0, 0))
    return output


def densify(image: Image.Image, pin: dict[str, object]) -> Image.Image:
    width, height = image.size
    base = list(image.get_flattened_data())
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("cannot densify empty frame")
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
    color_value = tuple(pin["color"])
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
                output.putpixel((x, y), color_value)
    return output


def remap(image: Image.Image, mapping: dict[str, str]) -> Image.Image:
    lookup = {color(source): color(target) for source, target in mapping.items()}
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    output.putdata([(*lookup.get(pixel[:3], pixel[:3]), pixel[3]) for pixel in image.get_flattened_data()])
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", required=True)
    parser.add_argument("--input-root", required=True)
    parser.add_argument("--output-root", required=True)
    args = parser.parse_args()
    contract = json.loads(Path(args.contract).read_text(encoding="utf-8"))
    input_root = Path(args.input_root).resolve()
    output_root = Path(args.output_root).resolve()
    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True)
    images = []
    for index in range(contract["expected_final_frames"]):
        with Image.open(input_root / f"frame_{index:02d}.png") as raw:
            raw.load()
            image = raw.convert("RGBA")
        dilation = contract.get("pre_dilation", {"iterations": 0})
        image = expand_separated(image, dilation["iterations"]) if dilation.get("mode") == "preserve_component_gaps" else expand(image, dilation["iterations"])
        images.append(compress(image, contract))
    for closure in contract["loop_closure"]:
        image = images[closure["source_frame"]].copy()
        image.putpixel(first_opaque(image), tuple(closure["accent_after"]))
        images[closure["target_frame"]] = image
    if "open_center_clear" in contract:
        images = [clear_open_center(image, contract["open_center_clear"]) for image in images]
    if "densification" in contract:
        pin = contract["densification"]
        images[pin["frame"]] = densify(images[pin["frame"]], pin)
    if "detached_chips" in contract:
        pin = contract["detached_chips"]
        images[pin["frame"]] = add_detached_chips(images[pin["frame"]], pin)
    for index, image in enumerate(images):
        remap(image, contract["reserved_color_remap"]).save(output_root / f"frame_{index:02d}.png", format="PNG", optimize=False, compress_level=9)
    print(json.dumps({"status": "PASS", "frames": len(images)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
