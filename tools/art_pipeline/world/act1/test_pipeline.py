#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image, ImageStat

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
NORMALIZER = HERE / "normalize.py"
RUNTIME = REPO / "assets/world/act1"
STAGING = REPO / "staging/assets/world/act1"
FRAGMENTS = REPO / "assets/provenance/fragments/act1"
SOURCE = REPO / "art-src/world/act1"
SOURCE_MANIFEST = SOURCE / "source-manifest.json"
MANIFEST = REPO / "assets/act1_shared_manifest.tres"
TOKEN = "ACT-I-S1-S3-OWNER-TILES-V2"
EXPECTED = {
    "ground.png": (64, 32),
    "route.png": (64, 32),
    "raised.png": (64, 48),
    "blocked.png": (64, 32),
    "spawn.png": (64, 32),
    "core.png": (64, 32),
    "panorama.png": (512, 256),
}
SOURCE_HASHES = {
    "ground": "ab43310f885a50fe9a34a6ef32bfd16aa8f15d46e595557a544c6b9b8dbfa7b8",
    "route": "47bd6cebd166aec79f0d90cd852e16d8ab7da9c70908ab8324aea4197fea17e9",
    "raised": "b63816e00bc99487f84def28424897311246c796027eac59a2c0029268490665",
    "spawn_marker": "30f2dbfa61b1ecc494e54f76277ca5c171a08bd22e8575be009536d670c96bdf",
    "core_marker": "f8eac627a503c431f6393ea87711f601554f03b485181d8c0530e4af33228662",
    "panorama": "5da7a563ecef9bebeb8244304cd894cafdbd9205bc5a80c7f42c8236fa358d5b",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot() -> dict[str, str]:
    roots = [RUNTIME, STAGING, FRAGMENTS]
    result = {
        path.relative_to(REPO).as_posix(): digest(path)
        for root in roots
        for path in sorted(root.iterdir())
        if path.is_file() and path.suffix in {".png", ".json"}
    }
    result[MANIFEST.relative_to(REPO).as_posix()] = digest(MANIFEST)
    return result


def alpha_weighted_luma(path: Path) -> float:
    with Image.open(path) as opened:
        rgba = opened.convert("RGBA")
    return float(ImageStat.Stat(rgba.convert("L"), mask=rgba.getchannel("A")).mean[0])


class Act1WorldPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        subprocess.run([sys.executable, str(NORMALIZER)], cwd=REPO, check=True)

    def test_repo_local_owner_source_packet_is_exact(self) -> None:
        manifest = json.loads(SOURCE_MANIFEST.read_text())
        self.assertEqual(manifest["approval_token"], TOKEN)
        self.assertEqual(set(manifest["sources"]), set(SOURCE_HASHES))
        for name, expected_hash in SOURCE_HASHES.items():
            record = manifest["sources"][name]
            path = REPO / record["path"]
            self.assertEqual(digest(path), expected_hash)
            self.assertEqual(record["sha256"], expected_hash)
            with Image.open(path) as image:
                self.assertEqual(list(image.size), record["size"])

    def test_exact_runtime_and_staging_inventory_and_bytes(self) -> None:
        for root in [RUNTIME, STAGING]:
            self.assertEqual({path.name for path in root.glob("*.png")}, set(EXPECTED))
        for filename, size in EXPECTED.items():
            runtime = RUNTIME / filename
            staging = STAGING / filename
            self.assertEqual(runtime.read_bytes(), staging.read_bytes())
            with Image.open(runtime) as image:
                self.assertEqual(image.size, size)

    def test_roles_have_exact_geometry_and_real_alpha(self) -> None:
        for filename in EXPECTED.keys() - {"panorama.png"}:
            with Image.open(RUNTIME / filename) as image:
                rgba = image.convert("RGBA")
                self.assertEqual(image.mode, "RGBA")
                self.assertIsNotNone(rgba.getbbox())
                self.assertLess(rgba.getchannel("A").getextrema()[0], 255)
                self.assertGreater(rgba.getchannel("A").getextrema()[1], 0)
        with Image.open(RUNTIME / "panorama.png") as image:
            self.assertEqual(image.mode, "RGB")

    def test_owner_materials_are_distinct_and_blocked_is_darker(self) -> None:
        self.assertNotEqual(digest(RUNTIME / "ground.png"), digest(RUNTIME / "route.png"))
        self.assertNotEqual(digest(RUNTIME / "ground.png"), digest(RUNTIME / "raised.png"))
        ground_luma = alpha_weighted_luma(RUNTIME / "ground.png")
        route_luma = alpha_weighted_luma(RUNTIME / "route.png")
        blocked_luma = alpha_weighted_luma(RUNTIME / "blocked.png")
        self.assertGreater(ground_luma, 100.0)
        self.assertGreater(route_luma, 80.0)
        self.assertLess(blocked_luma, ground_luma - 20.0)

    def test_no_visible_magenta_canvas_residue_and_markers_are_sparse(self) -> None:
        for filename in ["ground.png", "route.png", "raised.png", "blocked.png"]:
            with Image.open(RUNTIME / filename) as opened:
                pixels = list(opened.convert("RGBA").get_flattened_data())
            residue = [
                pixel
                for pixel in pixels
                if pixel[3] > 0 and pixel[0] - pixel[1] > 25 and pixel[2] - pixel[1] > 25
            ]
            self.assertEqual(residue, [], filename)
            self.assertEqual([pixel for pixel in pixels if 0 < pixel[3] < 16], [], filename)
        for filename in ["spawn.png", "core.png"]:
            with Image.open(RUNTIME / filename) as opened:
                alpha = opened.convert("RGBA").getchannel("A")
            opaque = sum(1 for value in alpha.get_flattened_data() if value > 32)
            self.assertGreater(opaque, 20, filename)
            self.assertLess(opaque, 900, filename)

    def test_provenance_fragments_are_exact_and_truthful(self) -> None:
        paths = sorted(FRAGMENTS.glob("*.json"))
        self.assertEqual(len(paths), 7)
        seen = set()
        for path in paths:
            data = json.loads(path.read_text())
            logical_id = data["logical_id"]
            seen.add(logical_id)
            self.assertEqual(data["approval"]["token"], TOKEN)
            self.assertEqual(data["state"], "OWNER_TILE_DIRECTION_APPROVED_RUNTIME_CAPTURE_PENDING")
            self.assertFalse(data["human_final_art"])
            self.assertNotEqual(data["normalization"]["operation"], "")
            files = data["candidate_files"]
            runtime = REPO / files["runtime"]
            staging = REPO / files["staging"]
            self.assertEqual(runtime.read_bytes(), staging.read_bytes())
            self.assertEqual(digest(runtime), files["sha256"])
            self.assertEqual(digest(REPO / data["source"]["path"]), data["source"]["sha256"])
        self.assertEqual(seen, {f"world.act1.{name.removesuffix('.png')}" for name in EXPECTED})

    def test_regeneration_is_idempotent_and_complete_replacement_safe(self) -> None:
        before = snapshot()
        (RUNTIME / "stale.png").write_bytes(b"stale")
        (STAGING / "stale.png").write_bytes(b"stale")
        (FRAGMENTS / "stale.json").write_text("{}")
        subprocess.run([sys.executable, str(NORMALIZER)], cwd=REPO, check=True)
        self.assertEqual(snapshot(), before)
        self.assertFalse((RUNTIME / "stale.png").exists())
        self.assertFalse((STAGING / "stale.png").exists())
        self.assertFalse((FRAGMENTS / "stale.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
