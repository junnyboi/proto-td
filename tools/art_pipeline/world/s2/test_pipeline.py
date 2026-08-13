#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHARED = HERE.parent / "act2_shared" / "normalize.py"
SPEC = importlib.util.spec_from_file_location("act2_shared_normalize_s2_tests", SHARED)
assert SPEC and SPEC.loader
normalize = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(normalize)


class S2PipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.images = normalize.build_assets(normalize.palette())

    def test_exact_s2_inventory(self) -> None:
        ids = {logical for logical, data in normalize.ASSETS.items() if data[0] == "s2"}
        self.assertEqual(ids, {
            "world.s2.elevated_manometer", "world.s2.elevated_relief",
            "world.s2.spawn_louver", "world.s2.core_receiver",
            "world.s2.backdrop_panorama",
        })

    def test_bottom_center_contacts_and_approaches(self) -> None:
        for logical in ("world.s2.spawn_louver", "world.s2.core_receiver"):
            image = self.images[logical]
            self.assertEqual(image.getpixel((16, 30))[3], 255)
            open_pixels = sum(
                image.getpixel((x, y))[3] == 0
                for y in range(14, 27) for x in range(12, 20)
            )
            self.assertGreaterEqual(open_pixels, 45)

    def test_panorama_native_size_and_no_route_bronze(self) -> None:
        image = self.images["world.s2.backdrop_panorama"]
        self.assertEqual(image.size, (240, 120))
        colors = {(r, g, b) for r, g, b, a in image.get_flattened_data() if a == 255}
        self.assertNotIn(normalize.palette()["bronze"], colors)


if __name__ == "__main__":
    unittest.main()
