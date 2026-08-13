#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("act2_shared_normalize", HERE / "normalize.py")
assert SPEC and SPEC.loader
normalize = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(normalize)


class Act2SharedS2PipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.palette = normalize.palette()
        cls.images = normalize.build_assets(cls.palette)

    def test_exact_inventory_and_sizes(self) -> None:
        self.assertEqual(set(self.images), set(normalize.ASSETS))
        self.assertEqual(len(self.images), 12)
        for logical_id, image in self.images.items():
            self.assertEqual(image.size, normalize.ASSETS[logical_id][2])

    def test_palette_is_deterministic_and_source_derived(self) -> None:
        self.assertEqual(self.palette, normalize.palette())
        self.assertTrue(all(color not in normalize.RESERVED for color in self.palette.values()))
        self.assertGreaterEqual(len(set(self.palette.values())), 8)

    def test_hard_alpha_and_reserved_colors(self) -> None:
        for logical_id, image in self.images.items():
            alpha_values = set(image.getchannel("A").get_flattened_data())
            self.assertLessEqual(alpha_values, {0, 255}, logical_id)
            self.assertIn(255, alpha_values, logical_id)
            opaque_colors = {
                (r, g, b) for r, g, b, a in image.get_flattened_data() if a == 255
            }
            self.assertFalse(opaque_colors & normalize.RESERVED, logical_id)

    def test_panorama_avoids_route_palette_and_diamond_builder(self) -> None:
        panorama = self.images["world.s2.backdrop_panorama"]
        route = self.images["world.pressure.route_plate"]
        route_colors = {
            (r, g, b) for r, g, b, a in route.get_flattened_data() if a == 255
        }
        panorama_colors = {
            (r, g, b) for r, g, b, a in panorama.get_flattened_data() if a == 255
        }
        # Route's distinctive mid-bronze never continues into the backdrop.
        self.assertNotIn(self.palette["bronze"], panorama_colors)
        self.assertIn(self.palette["bronze"], route_colors)
        # Every 32x16 window has less opacity than a complete native playable face.
        full_face_pixels = sum(normalize.mask32())
        for y in range(0, panorama.height - 15, 8):
            for x in range(0, panorama.width - 31, 16):
                opaque = sum(
                    panorama.getpixel((xx, yy))[3] == 255
                    for yy in range(y, y + 16)
                    for xx in range(x, x + 32)
                )
                self.assertNotEqual(opaque, full_face_pixels)

    def test_endpoint_contact_and_negative_space(self) -> None:
        for logical_id in ("world.s2.spawn_louver", "world.s2.core_receiver"):
            image = self.images[logical_id]
            self.assertEqual(image.getpixel((16, 30))[3], 255)
            transparent = sum(
                image.getpixel((x, y))[3] == 0
                for y in range(14, 27)
                for x in range(12, 20)
            )
            self.assertGreaterEqual(transparent, 45)
            left, top, right, bottom = image.getbbox()
            self.assertGreaterEqual(left, 3)
            self.assertLessEqual(right, 30)
            self.assertLessEqual(bottom, 31)


if __name__ == "__main__":
    unittest.main()
