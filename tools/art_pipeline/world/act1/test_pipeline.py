#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
NORMALIZER = HERE / "normalize.py"
RUNTIME = REPO / "assets/world/act1"
STAGING = REPO / "staging/assets/world/act1"
FRAGMENTS = REPO / "assets/provenance/fragments/act1"
SOURCE = REPO / "art-src/world/act1"
MANIFEST = REPO / "assets/act1_shared_manifest.tres"
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
    "ground": "a1bc8c3c969ee921051490c716ce09d94ce001c8df520ad07782b1f9c81affd4",
    "route": "3894361e2b3f79dfab379ef0745f52ea3bac5ecf7bbbd649e44aa247bd5b94c8",
    "raised": "faaee6a67f3066f244d72fffaed173b7b9ea1a7cbd247468b6e2e278966144e3",
    "blocked": "db421085e6205a1e8b7b789b5426e7af7471c8b32a5c1cd4270a5d9193f15a51",
    "spawn": "30f2dbfa61b1ecc494e54f76277ca5c171a08bd22e8575be009536d670c96bdf",
    "core": "f8eac627a503c431f6393ea87711f601554f03b485181d8c0530e4af33228662",
    "panorama": "eb7e0ebd9a7c5017c2686236140b7f53fb645d6879d6bf6d71586e374e393f01",
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


class Act1WorldPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        subprocess.run([sys.executable, str(NORMALIZER)], cwd=REPO, check=True)

    def test_repo_local_source_packet_is_exact(self) -> None:
        manifest = json.loads((SOURCE / "synthesis-manifest.json").read_text())
        for role in EXPECTED.keys() - {"panorama.png"}:
            name = role.removesuffix(".png")
            path = SOURCE / "synthesized-roles" / f"act1-{name}.png"
            self.assertEqual(digest(path), SOURCE_HASHES[name])
            self.assertEqual(manifest["roles"][name]["sha256"], SOURCE_HASHES[name])
        self.assertEqual(digest(SOURCE / "act1-alpine-panorama-flux-a.jpg"), SOURCE_HASHES["panorama"])

    def test_exact_runtime_and_staging_inventory_and_bytes(self) -> None:
        for root in [RUNTIME, STAGING]:
            self.assertEqual({p.name for p in root.glob("*.png")}, set(EXPECTED))
        for filename, size in EXPECTED.items():
            runtime = RUNTIME / filename
            staging = STAGING / filename
            self.assertEqual(runtime.read_bytes(), staging.read_bytes())
            with Image.open(runtime) as image:
                self.assertEqual(image.size, size)

    def test_roles_preserve_real_alpha_and_panorama_is_rgb(self) -> None:
        for filename in EXPECTED.keys() - {"panorama.png"}:
            with Image.open(RUNTIME / filename) as image:
                self.assertEqual(image.mode, "RGBA")
                extrema = image.getchannel("A").getextrema()
                self.assertLess(extrema[0], extrema[1])
                self.assertGreater(extrema[1], 0)
        with Image.open(RUNTIME / "panorama.png") as image:
            self.assertEqual(image.mode, "RGB")

    def test_provenance_fragments_are_exact_and_truthful(self) -> None:
        paths = sorted(FRAGMENTS.glob("*.json"))
        self.assertEqual(len(paths), 7)
        seen = set()
        for path in paths:
            data = json.loads(path.read_text())
            logical_id = data["logical_id"]
            seen.add(logical_id)
            self.assertEqual(data["approval"]["token"], "ACT-I-S1-S3-SYNTHESIS-V1")
            self.assertFalse(data["human_final_art"])
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
