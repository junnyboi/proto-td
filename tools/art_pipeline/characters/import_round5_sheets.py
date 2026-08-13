#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Iterable

from PIL import Image

OPERATOR_IDS = [
    'vanguard_1', 'vanguard_2', 'guard_1', 'guard_2', 'defender_1',
    'defender_2', 'sniper_1', 'sniper_2', 'caster_1', 'caster_2',
]
PORTRAIT_CROPS = {
    **{
        op_id: (index * 435 + 20, 92, min((index + 1) * 435 - 20, 2156), 765)
        for index, op_id in enumerate(OPERATOR_IDS[:5])
    },
    **{
        op_id: (index * 435 + 20, 850, min((index + 1) * 435 - 20, 2156), 1468)
        for index, op_id in enumerate(OPERATOR_IDS[5:])
    },
}
ROSTER_CROPS = {
    op_id: (index * 256 + 4, 92, min((index + 1) * 256 - 4, 2556), 970)
    for index, op_id in enumerate(OPERATOR_IDS)
}
ENEMY_CROPS = {
    'grunt': (380, 72, 780, 475),
    'heavy': (760, 72, 1220, 475),
    'drone': (1210, 82, 1584, 452),
    'mini_boss': (1610, 82, 1968, 468),
    'runner': (2025, 82, 2268, 410),
    'spellcaster': (2025, 430, 2268, 825),
}
ENEMY_SIZES = {
    'grunt': (32, 32),
    'heavy': (32, 32),
    'drone': (24, 24),
    'mini_boss': (48, 48),
    'runner': (32, 32),
    'spellcaster': (32, 32),
}
CHARMABLE = {'grunt', 'heavy', 'runner', 'spellcaster'}

PALETTE = [
    '#1a1c2c', '#5d275d', '#b13e53', '#ef7d57', '#ffcd75', '#a7f070',
    '#38b764', '#257179', '#29366f', '#3b5dc9', '#73eff7', '#94b0c2',
    '#566c86', '#333c57', '#0f0f1b', '#c7d6e8', '#6e7a94', '#1a5f43',
    '#7a2436', '#ffe9b0', '#a3702b', '#6b4a34', '#3a2a24', '#8a4836',
    '#c77b58', '#e8b796', '#f6dcbf', '#c964cf', '#94216a', '#e39aac',
]
PALETTE_RGB = [tuple(bytes.fromhex(color[1:])) for color in PALETTE]
VOID = tuple(bytes.fromhex('0f0f1b'))
CHARM_RAMP = [
    tuple(bytes.fromhex('29366f')),
    tuple(bytes.fromhex('3b5dc9')),
    tuple(bytes.fromhex('41a6f6')),
    tuple(bytes.fromhex('73eff7')),
]
CHARM_HEART = tuple(bytes.fromhex('e39aac'))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument('--review-dir', type=Path)
    return parser.parse_args()


def distance_sq(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return sum((a[index] - b[index]) ** 2 for index in range(3))


def border_background(image: Image.Image, tolerance: int = 72) -> Image.Image:
    rgba = image.convert('RGBA')
    width, height = rgba.size
    corners = [
        rgba.getpixel((0, 0))[:3], rgba.getpixel((width - 1, 0))[:3],
        rgba.getpixel((0, height - 1))[:3], rgba.getpixel((width - 1, height - 1))[:3],
    ]
    background = tuple(sorted(channel)[len(channel) // 2] for channel in zip(*corners))
    pixels = rgba.load()
    queue: deque[tuple[int, int]] = deque()
    seen = bytearray(width * height)

    def eligible(x: int, y: int) -> bool:
        return distance_sq(pixels[x, y][:3], background) <= tolerance * tolerance

    for x in range(width):
        for y in (0, height - 1):
            if eligible(x, y):
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if eligible(x, y):
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        key = y * width + x
        if seen[key] or not eligible(x, y):
            continue
        seen[key] = 1
        pixels[x, y] = (0, 0, 0, 0)
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))
    return rgba


def largest_component(image: Image.Image, min_alpha: int = 32) -> Image.Image:
    rgba = image.convert('RGBA')
    width, height = rgba.size
    alpha = rgba.getchannel('A')
    opaque = bytearray(1 if value >= min_alpha else 0 for value in alpha.tobytes())
    seen = bytearray(width * height)
    components: list[list[int]] = []
    for key, value in enumerate(opaque):
        if not value or seen[key]:
            continue
        stack = [key]
        seen[key] = 1
        component: list[int] = []
        while stack:
            current = stack.pop()
            component.append(current)
            x = current % width
            y = current // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < 0 or nx >= width or ny < 0 or ny >= height:
                    continue
                neighbor = ny * width + nx
                if opaque[neighbor] and not seen[neighbor]:
                    seen[neighbor] = 1
                    stack.append(neighbor)
        components.append(component)
    if not components:
        raise ValueError('source crop contains no foreground component')
    components.sort(key=len, reverse=True)
    keep = bytearray(width * height)
    primary_size = len(components[0])
    for component in components:
        if len(component) >= max(48, primary_size // 90):
            for key in component:
                keep[key] = 1
    output = Image.new('RGBA', rgba.size, (0, 0, 0, 0))
    source = rgba.load()
    target = output.load()
    for key, value in enumerate(keep):
        if value:
            x = key % width
            y = key // width
            target[x, y] = source[x, y]
    return output


def normalize_subject(source: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    subject = largest_component(border_background(source))
    bbox = subject.getchannel('A').getbbox()
    if bbox is None:
        raise ValueError('source crop became empty after background removal')
    subject = subject.crop(bbox)
    target_width = max(1, size[0] - 2 * margin)
    target_height = max(1, size[1] - 2 * margin)
    scale = min(target_width / subject.width, target_height / subject.height)
    resized = subject.resize(
        (max(1, round(subject.width * scale)), max(1, round(subject.height * scale))),
        Image.Resampling.LANCZOS,
    )
    output = Image.new('RGBA', size, (0, 0, 0, 0))
    x = (size[0] - resized.width) // 2
    y = size[1] - margin - resized.height
    output.alpha_composite(resized, (x, y))
    return hard_alpha_and_palette(output)


def hard_alpha_and_palette(image: Image.Image) -> Image.Image:
    source = image.convert('RGBA')
    output = Image.new('RGBA', source.size, (0, 0, 0, 0))
    source_pixels = source.load()
    target_pixels = output.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = source_pixels[x, y]
            if alpha < 40:
                continue
            color = min(PALETTE_RGB, key=lambda candidate: distance_sq((red, green, blue), candidate))
            target_pixels[x, y] = (*color, 255)
    return output


def add_outline(image: Image.Image) -> Image.Image:
    source = image.convert('RGBA')
    output = source.copy()
    source_pixels = source.load()
    target_pixels = output.load()
    width, height = source.size
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            if source_pixels[x, y][3] != 0:
                continue
            if any(source_pixels[nx, ny][3] != 0 for nx, ny in ((x-1, y), (x+1, y), (x, y-1), (x, y+1))):
                target_pixels[x, y] = (*VOID, 255)
    return output


def shifted(image: Image.Image, x_offset: int, y_offset: int) -> Image.Image:
    output = Image.new('RGBA', image.size, (0, 0, 0, 0))
    output.alpha_composite(image, (x_offset, y_offset))
    return output


def upper_shift(image: Image.Image, x_offset: int, y_offset: int = 0) -> Image.Image:
    output = Image.new('RGBA', image.size, (0, 0, 0, 0))
    split = max(1, image.height * 2 // 3)
    upper = image.crop((0, 0, image.width, split))
    lower = image.crop((0, split, image.width, image.height))
    output.alpha_composite(upper, (x_offset, y_offset))
    output.alpha_composite(lower, (0, split))
    return output


def crouched(image: Image.Image) -> Image.Image:
    target_height = max(1, image.height - max(2, image.height // 8))
    resized = image.resize((image.width, target_height), Image.Resampling.NEAREST)
    output = Image.new('RGBA', image.size, (0, 0, 0, 0))
    output.alpha_composite(resized, (0, image.height - target_height))
    return output


def charmed(image: Image.Image) -> Image.Image:
    source = image.convert('RGBA')
    output = Image.new('RGBA', source.size, (0, 0, 0, 0))
    source_pixels = source.load()
    target_pixels = output.load()
    points: list[tuple[int, int]] = []
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = source_pixels[x, y]
            if alpha == 0:
                continue
            points.append((x, y))
            luminance = (77 * red + 150 * green + 29 * blue + 128) // 256
            if (red, green, blue) == VOID:
                color = CHARM_RAMP[3]
            elif luminance < 46:
                color = CHARM_RAMP[0]
            elif luminance < 97:
                color = CHARM_RAMP[1]
            elif luminance < 158:
                color = CHARM_RAMP[2]
            else:
                color = CHARM_RAMP[3]
            target_pixels[x, y] = (*color, 255)
    if points:
        left = min(x for x, _ in points)
        right = max(x for x, _ in points)
        top = min(y for _, y in points)
        center = (left + right) // 2
        for origin_x, origin_y in ((center - 4, max(1, top - 2)), (center + 3, max(1, top - 3))):
            for dx, dy in ((0,0), (2,0), (0,1), (1,1), (2,1), (1,2)):
                x = origin_x + dx
                y = origin_y + dy
                if 0 < x < source.width - 1 and 0 < y < source.height - 1:
                    target_pixels[x, y] = (*CHARM_HEART, 255)
    return output


def save_atomic(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp.png')
    image.save(temporary, format='PNG', optimize=False, compress_level=9)
    with Image.open(temporary) as reopened:
        reopened.load()
        if reopened.size != image.size or reopened.mode != 'RGBA':
            raise ValueError(f'PNG roundtrip mismatch: {path}')
        alpha_values = set(reopened.getchannel('A').tobytes())
        if not alpha_values.issubset({0, 255}):
            raise ValueError(f'soft alpha emitted: {path}')
    temporary.replace(path)


def build_review(images: Iterable[tuple[str, Image.Image]], output_path: Path, cell: int = 160) -> None:
    rows = list(images)
    columns = 5
    row_count = (len(rows) + columns - 1) // columns
    canvas = Image.new('RGBA', (columns * cell, row_count * cell), (30, 34, 45, 255))
    for index, (_, image) in enumerate(rows):
        preview = image.resize((cell - 16, cell - 16), Image.Resampling.NEAREST)
        x = (index % columns) * cell + 8
        y = (index // columns) * cell + 8
        canvas.alpha_composite(preview, (x, y))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, optimize=False, compress_level=9)


def run(repo: Path, review_dir: Path | None) -> None:
    source_root = repo / 'art-src/characters/round5'
    portrait_sheet = Image.open(source_root / 'portrait-treatment-sheet.png').convert('RGBA')
    roster_sheet = Image.open(source_root / 'roster-style-board.png').convert('RGBA')
    enemy_sheet = Image.open(source_root / 'enemy-character-sheet.png').convert('RGBA')
    if portrait_sheet.size != (2176, 1632):
        raise ValueError(f'unexpected portrait sheet size: {portrait_sheet.size}')
    if roster_sheet.size != (2560, 1440):
        raise ValueError(f'unexpected roster sheet size: {roster_sheet.size}')
    if enemy_sheet.size != (2304, 1536):
        raise ValueError(f'unexpected enemy sheet size: {enemy_sheet.size}')

    portrait_reviews: list[tuple[str, Image.Image]] = []
    sprite_reviews: list[tuple[str, Image.Image]] = []
    for op_id in OPERATOR_IDS:
        portrait = normalize_subject(portrait_sheet.crop(PORTRAIT_CROPS[op_id]), (128, 128), 3)
        save_atomic(portrait, repo / f'assets/portraits/{op_id}.png')
        portrait_reviews.append((op_id, portrait))

        base = add_outline(normalize_subject(roster_sheet.crop(ROSTER_CROPS[op_id]), (32, 32), 2))
        frames = [base, shifted(base, 0, 1), upper_shift(base, 1), upper_shift(base, -1, 1), crouched(base)]
        for frame_index, frame in enumerate(frames):
            save_atomic(frame, repo / f'assets/sprites/{op_id}_{frame_index}.png')
        sprite_reviews.append((op_id, base))

    enemy_reviews: list[tuple[str, Image.Image]] = []
    for enemy_id, crop in ENEMY_CROPS.items():
        size = ENEMY_SIZES[enemy_id]
        base = add_outline(normalize_subject(enemy_sheet.crop(crop), size, 2))
        save_atomic(base, repo / f'assets/sprites/{enemy_id}_0.png')
        save_atomic(shifted(base, 0, 1), repo / f'assets/sprites/{enemy_id}_1.png')
        enemy_reviews.append((enemy_id, base))
        if enemy_id in CHARMABLE:
            charm = charmed(base)
            save_atomic(charm, repo / f'assets/sprites/{enemy_id}_charmed_0.png')
            save_atomic(shifted(charm, 0, 1), repo / f'assets/sprites/{enemy_id}_charmed_1.png')

    if review_dir is not None:
        build_review(portrait_reviews, review_dir / 'round5-portraits.png')
        build_review(sprite_reviews + enemy_reviews, review_dir / 'round5-battle-sprites.png')
        inventory = {
            'schema_version': 1,
            'operators': OPERATOR_IDS,
            'enemies': list(ENEMY_CROPS),
            'portrait_size': [128, 128],
            'operator_sprite_size': [32, 32],
            'enemy_sizes': {key: list(value) for key, value in ENEMY_SIZES.items()},
            'alpha': 'binary',
            'palette': PALETTE,
        }
        (review_dir / 'round5-import-report.json').write_text(
            json.dumps(inventory, indent=2) + '\n', encoding='utf-8'
        )


if __name__ == '__main__':
    arguments = parse_args()
    run(arguments.repo.resolve(), arguments.review_dir.resolve() if arguments.review_dir else None)
