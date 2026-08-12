"""Integer-only RGBA operations shared by the AUI-34 contract."""

from __future__ import annotations

from collections import deque
from typing import Iterable

from PIL import Image

RGBA = tuple[int, int, int, int]
RGB = tuple[int, int, int]


def parse_hex(value: str) -> RGB:
    return tuple(int(value[index:index + 2], 16) for index in (1, 3, 5))  # type: ignore[return-value]


def rgba_sha256_bytes(image: Image.Image) -> bytes:
    return image.convert("RGBA").tobytes()


def nearest_source_index(destination_index: int, source_size: int, destination_size: int) -> int:
    if source_size <= 0 or destination_size <= 0 or destination_index not in range(destination_size):
        raise ValueError(
            f"nearest-index invalid d={destination_index} src={source_size} dst={destination_size}"
        )
    return min(source_size - 1, (destination_index * source_size) // destination_size)


def resize_nearest(image: Image.Image, width: int, height: int) -> Image.Image:
    source = image.convert("RGBA")
    result = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    src_pixels = source.load()
    dst_pixels = result.load()
    for y in range(height):
        source_y = nearest_source_index(y, source.height, height)
        for x in range(width):
            source_x = nearest_source_index(x, source.width, width)
            dst_pixels[x, y] = src_pixels[source_x, source_y]
    return result


def key_and_threshold(image: Image.Image, background: RGB, alpha_threshold: int) -> Image.Image:
    result = image.convert("RGBA")
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if (red, green, blue) == background or alpha < alpha_threshold:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (red, green, blue, 255)
    return result


def palette_map(image: Image.Image, palette: list[RGB]) -> Image.Image:
    result = image.convert("RGBA")
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            best = palette[0]
            best_distance = 1 << 62
            for candidate in palette:
                distance = sum((actual - target) ** 2 for actual, target in zip((red, green, blue), candidate))
                if distance < best_distance:
                    best = candidate
                    best_distance = distance
            pixels[x, y] = (*best, 255)
    return result


def _opaque_neighbors(x: int, y: int, width: int, height: int) -> Iterable[tuple[int, int]]:
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < width and 0 <= ny < height:
            yield nx, ny


def remove_small_components(image: Image.Image, minimum_size: int) -> Image.Image:
    result = image.convert("RGBA")
    if minimum_size <= 1:
        return result
    pixels = result.load()
    visited: set[tuple[int, int]] = set()
    for y in range(result.height):
        for x in range(result.width):
            if (x, y) in visited or pixels[x, y][3] == 0:
                continue
            component: list[tuple[int, int]] = []
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            while queue:
                current = queue.popleft()
                component.append(current)
                for neighbor in _opaque_neighbors(*current, result.width, result.height):
                    if neighbor not in visited and pixels[neighbor[0], neighbor[1]][3] == 255:
                        visited.add(neighbor)
                        queue.append(neighbor)
            if len(component) < minimum_size:
                for px, py in component:
                    pixels[px, py] = (0, 0, 0, 0)
    return result


def opaque_bounds(image: Image.Image) -> tuple[int, int, int, int] | None:
    pixels = image.convert("RGBA").load()
    coordinates = [
        (x, y)
        for y in range(image.height)
        for x in range(image.width)
        if pixels[x, y][3] == 255
    ]
    if not coordinates:
        return None
    xs = [point[0] for point in coordinates]
    ys = [point[1] for point in coordinates]
    return min(xs), min(ys), max(xs), max(ys)


def anchor_in_cell(image: Image.Image, cell_size: tuple[int, int], anchor_x: int, foot_y: int) -> tuple[Image.Image, dict[str, int]]:
    source = image.convert("RGBA")
    bounds = opaque_bounds(source)
    if bounds is None:
        raise ValueError("frame opaque_pixels expected=>0 actual=0")
    left, top, right, bottom = bounds
    center_x = (left + right) // 2
    dx, dy = anchor_x - center_x, foot_y - bottom
    result = Image.new("RGBA", cell_size, (0, 0, 0, 0))
    src_pixels = source.load()
    dst_pixels = result.load()
    for y in range(source.height):
        for x in range(source.width):
            pixel = src_pixels[x, y]
            if pixel[3] == 0:
                continue
            destination_x, destination_y = x + dx, y + dy
            if destination_x <= 0 or destination_y <= 0 or destination_x >= cell_size[0] - 1 or destination_y >= cell_size[1] - 1:
                raise ValueError(
                    "frame border-contact "
                    f"source={x},{y} destination={destination_x},{destination_y} cell={cell_size[0]}x{cell_size[1]}"
                )
            dst_pixels[destination_x, destination_y] = pixel
    anchored = opaque_bounds(result)
    assert anchored is not None
    return result, {
        "source_left": left, "source_top": top, "source_right": right, "source_bottom": bottom,
        "source_center_x": center_x, "dx": dx, "dy": dy,
        "anchored_left": anchored[0], "anchored_top": anchored[1],
        "anchored_right": anchored[2], "anchored_bottom": anchored[3],
        "anchored_center_x": (anchored[0] + anchored[2]) // 2,
    }


def composite_atlas(cells: list[tuple[int, int, Image.Image]], size: tuple[int, int], cell_size: tuple[int, int]) -> Image.Image:
    atlas = Image.new("RGBA", size, (0, 0, 0, 0))
    for row, column, cell in cells:
        atlas.alpha_composite(cell.convert("RGBA"), (column * cell_size[0], row * cell_size[1]))
    return atlas


def grayscale_rgb(rgb: RGB) -> RGB:
    value = (77 * rgb[0] + 150 * rgb[1] + 29 * rgb[2] + 128) // 256
    return value, value, value


def build_contact_sheet(atlas: Image.Image) -> Image.Image:
    source = atlas.convert("RGBA")
    result = Image.new("RGBA", (1536, 256), (0, 0, 0, 255))
    backgrounds: list[RGB] = [parse_hex("#E8DFCF"), parse_hex("#1B2230"), parse_hex("#808080")]
    for panel, background in enumerate(backgrounds):
        panel_left = panel * 512
        for background_y in range(256):
            for background_x in range(panel_left, panel_left + 512):
                result.putpixel((background_x, background_y), (*background, 255))
        for row in range(2):
            for column in range(4):
                crop = source.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
                sampled = resize_nearest(crop, 72, 72)
                src_pixels = sampled.load()
                panel_x = panel * 512 + column * 128 + 28
                panel_y = row * 128 + 28
                for y in range(72):
                    for x in range(72):
                        red, green, blue, alpha = src_pixels[x, y]
                        if alpha == 0:
                            color = background
                        elif panel == 2:
                            color = grayscale_rgb((red, green, blue))
                        else:
                            color = (red, green, blue)
                        result.putpixel((panel_x + x, panel_y + y), (*color, 255))
    return result
