from __future__ import annotations

from collections import Counter, deque
from pathlib import Path

from PIL import Image

ROOT = Path("/home/ubuntu/art-work/agent7-bolt")
RAW = ROOT / "raw"
OUT = ROOT / "normalized"
OUT.mkdir(parents=True, exist_ok=True)

SIZE = 32
SUBJECT_SIZE = 28
MIN_COMPONENT_AREA = 256
MAGENTA_R_MIN = 150
MAGENTA_G_MAX = 120
MAGENTA_B_MIN = 130

PALETTE = [
    (15, 15, 27, 255),     # VOID
    (26, 28, 44, 255),     # INK
    (41, 54, 111, 255),    # NAVY
    (59, 93, 201, 255),    # BLUE
    (115, 239, 247, 255),  # CYAN (SKY deliberately excluded)
    (148, 176, 194, 255),  # STEEL
    (199, 214, 232, 255),  # PALE
    (163, 112, 43, 255),   # BRONZE
    (255, 205, 117, 255),  # GOLD
    (255, 233, 176, 255),  # PALE_GOLD
    (244, 244, 244, 255),  # WHITE, reserved Bolt probe signal
]
TRANSPARENT = (0, 0, 0, 0)
DARK_BG = (17, 19, 31, 255)
LIGHT_BG = (199, 214, 232, 255)


def is_temporary_magenta(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return red >= MAGENTA_R_MIN and green <= MAGENTA_G_MAX and blue >= MAGENTA_B_MIN


def nearest_palette(pixel: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    red, green, blue, _alpha = pixel
    return min(
        PALETTE,
        key=lambda color: (red - color[0]) ** 2 + (green - color[1]) ** 2 + (blue - color[2]) ** 2,
    )


def connected_components(mask: Image.Image) -> list[list[tuple[int, int]]]:
    width, height = mask.size
    data = mask.load()
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            point = (x, y)
            if point in seen or data[x, y] == 0:
                continue
            queue: deque[tuple[int, int]] = deque([point])
            seen.add(point)
            component: list[tuple[int, int]] = []
            while queue:
                current = queue.popleft()
                component.append(current)
                cx, cy = current
                for neighbor in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    nx, ny = neighbor
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if neighbor in seen or data[nx, ny] == 0:
                        continue
                    seen.add(neighbor)
                    queue.append(neighbor)
            components.append(component)
    return components


def clean_source(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    mask = Image.new("L", image.size, 0)
    mask_pixels = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            pixel = pixels[x, y]
            if pixel[3] >= 128 and not is_temporary_magenta(pixel):
                mask_pixels[x, y] = 255
    components = connected_components(mask)
    kept = [component for component in components if len(component) >= MIN_COMPONENT_AREA]
    cleaned = Image.new("RGBA", image.size, TRANSPARENT)
    cleaned_pixels = cleaned.load()
    for component in kept:
        for x, y in component:
            cleaned_pixels[x, y] = (*pixels[x, y][:3], 255)
    return cleaned


def normalize(path: Path) -> Image.Image:
    cleaned = clean_source(path)
    bbox = cleaned.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"{path.name}: no subject survived cleanup")
    cropped = cleaned.crop(bbox)
    side = max(cropped.size)
    pad = max(8, round(side * 0.06))
    square_side = side + 2 * pad
    square = Image.new("RGBA", (square_side, square_side), TRANSPARENT)
    square.alpha_composite(
        cropped,
        ((square_side - cropped.width) // 2, (square_side - cropped.height) // 2),
    )
    sampled = square.resize((SUBJECT_SIZE, SUBJECT_SIZE), Image.Resampling.NEAREST)
    sampled_pixels = sampled.load()
    for y in range(sampled.height):
        for x in range(sampled.width):
            pixel = sampled_pixels[x, y]
            sampled_pixels[x, y] = TRANSPARENT if pixel[3] < 128 else nearest_palette(pixel)
    output = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
    output.alpha_composite(sampled, ((SIZE - SUBJECT_SIZE) // 2, (SIZE - SUBJECT_SIZE) // 2))
    return output


frames: list[Image.Image] = []
for index in range(4):
    source = RAW / f"bolt_impact_{index}.png"
    frame = normalize(source)
    destination = OUT / f"bolt_impact_{index}.png"
    frame.save(destination, optimize=False, compress_level=9)
    frames.append(frame)
    alpha = frame.getchannel("A")
    bbox = alpha.getbbox()
    opaque = sum(value == 255 for value in alpha.getdata())
    partial = sum(0 < value < 255 for value in alpha.getdata())
    white = sum(pixel == (244, 244, 244, 255) for pixel in frame.getdata())
    border = 0
    for coordinate in [(x, y) for x in range(SIZE) for y in (0, SIZE - 1)] + [
        (x, y) for y in range(1, SIZE - 1) for x in (0, SIZE - 1)
    ]:
        if frame.getpixel(coordinate)[3] > 0:
            border += 1
    colors = Counter(pixel for pixel in frame.getdata() if pixel[3] > 0)
    print(
        f"frame={index} bbox={bbox} opaque={opaque} partial={partial} "
        f"white={white} border={border} colors={len(colors)}"
    )

cell = 128
sheet = Image.new("RGBA", (cell * 4, cell * 2), DARK_BG)
for row, background in enumerate((DARK_BG, LIGHT_BG)):
    for index, frame in enumerate(frames):
        panel = Image.new("RGBA", (cell, cell), background)
        enlarged = frame.resize((SIZE * 4, SIZE * 4), Image.Resampling.NEAREST)
        panel.alpha_composite(enlarged, ((cell - enlarged.width) // 2, (cell - enlarged.height) // 2))
        sheet.alpha_composite(panel, (index * cell, row * cell))
sheet.save(OUT / "bolt_impact_contact_sheet.png", optimize=False, compress_level=9)
