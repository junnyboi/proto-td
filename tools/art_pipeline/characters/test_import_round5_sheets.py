from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SPEC = importlib.util.spec_from_file_location('round5_importer', HERE / 'import_round5_sheets.py')
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class Round5ImporterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name)
        source_dir = self.repo / 'art-src/characters/round5'
        source_dir.mkdir(parents=True)
        for source in (REPO / 'art-src/characters/round5').glob('*.png'):
            (source_dir / source.name).symlink_to(source)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def inventory(self) -> dict[str, bytes]:
        return {
            str(path.relative_to(self.repo)): path.read_bytes()
            for path in sorted((self.repo / 'assets').rglob('*.png'))
        }

    def test_build_is_byte_deterministic_and_contract_sized(self) -> None:
        MODULE.run(self.repo, None)
        first = self.inventory()
        self.assertEqual(len(first), 80)
        MODULE.run(self.repo, None)
        self.assertEqual(first, self.inventory())
        expected_sizes = {
            'assets/portraits/vanguard_1.png': (128, 128),
            'assets/sprites/vanguard_1_0.png': (32, 32),
            'assets/sprites/drone_0.png': (24, 24),
            'assets/sprites/mini_boss_0.png': (48, 48),
        }
        for relative_path, expected_size in expected_sizes.items():
            with Image.open(self.repo / relative_path) as image:
                self.assertEqual(image.size, expected_size)

    def test_every_output_has_binary_alpha_and_charm_probe_survives(self) -> None:
        MODULE.run(self.repo, None)
        for path in (self.repo / 'assets').rglob('*.png'):
            with Image.open(path) as opened:
                image = opened.convert('RGBA')
            self.assertTrue(set(image.getchannel('A').tobytes()).issubset({0, 255}), path)
        with Image.open(self.repo / 'assets/sprites/grunt_charmed_0.png') as opened:
            charm = opened.convert('RGBA')
        pixels = charm.tobytes()
        self.assertIn(bytes((65, 166, 246, 255)), [pixels[i:i + 4] for i in range(0, len(pixels), 4)])


if __name__ == '__main__':
    unittest.main()
