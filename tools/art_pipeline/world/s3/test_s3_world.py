#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path); module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader; spec.loader.exec_module(module); return module


normalizer = load("s3_normalizer", HERE / "normalize_s3_world.py")
validator = load("s3_validator", HERE / "validate_s3_world.py")
MANAGED = [
    Path("assets/world/s3"), Path("staging/assets/world/s3"),
    Path("assets/provenance/fragments/s3"), Path("staging/provenance/world/s3"),
    Path("staging/qa/world/s3"),
]
GENERATED_ART = [
    Path("art-src/world/s3/gpt-image-2-source-ledger.json"),
    Path("art-src/world/s3/s3-world-asset-contract.json"),
    Path("art-src/world/s3/s3-derived-palette.json"),
]


def digest_tree(root: Path) -> dict[str, str]:
    result = {}
    for rel in MANAGED + GENERATED_ART:
        path = root / rel
        if path.is_file(): result[rel.as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        elif path.is_dir():
            for item in sorted(p for p in path.rglob("*") if p.is_file()):
                result[item.relative_to(root).as_posix()] = hashlib.sha256(item.read_bytes()).hexdigest()
    return result


class TestS3World(unittest.TestCase):
    def trial(self, name: str, contaminate: bool = False) -> Path:
        root = Path(tempfile.mkdtemp(prefix=f"s3-{name}-"))
        source = root / "art-src/world/s3/s3-production-source.png"; source.parent.mkdir(parents=True)
        shutil.copyfile(REPO / "art-src/world/s3/s3-production-source.png", source)
        for relative in (
            "art-src/world/s3/production-prompt-contract.md",
            "art-src/world/s3/production-source-selection.json",
            "art-src/world/s3/candidates/s3-production-candidate-a.png",
            "art-src/world/s3/candidates/s3-production-candidate-b.png",
            "art-src/world/s3/rejected/s3-pre-lineage-source.png",
            "art-src/world/act2-shared/production-prompt-contract.md",
            "art-src/world/act2-shared/production-source-selection.json",
            "art-src/world/act2-shared/source-ledger.json",
            "art-src/world/act2-shared/act2-shared-production-source.png",
            "art-src/world/s2/production-prompt-contract.md",
            "art-src/world/s2/production-source-selection.json",
            "art-src/world/s2/source-ledger.json",
            "art-src/world/s2/s2-production-source.png",
        ):
            destination = root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / relative, destination)
        references = root / "art-src/world/act2-references"; references.mkdir(parents=True)
        for reference in (REPO / "art-src/world/act2-references").iterdir():
            shutil.copyfile(reference, references / reference.name)
        tool_dir = root / "tools/art_pipeline/world/s3"; tool_dir.mkdir(parents=True)
        shutil.copyfile(HERE / "normalize_s3_world.py", tool_dir / "normalize_s3_world.py")
        lineage_tool = root / "tools/art_pipeline/world/validate_act2_lineage.py"
        lineage_tool.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REPO / "tools/art_pipeline/world/validate_act2_lineage.py", lineage_tool)
        if contaminate:
            for rel in MANAGED:
                directory = root / rel; directory.mkdir(parents=True, exist_ok=True)
                (directory / "stale-junk.txt").write_text("must be removed", encoding="utf-8")
        normalizer.generate(root, source)
        return root

    def test_clean_a_b_and_contaminated_c(self):
        roots = [self.trial("clean-a"), self.trial("clean-b"), self.trial("contaminated-c", True)]
        try:
            snapshots = [digest_tree(root) for root in roots]
            self.assertEqual(snapshots[0], snapshots[1])
            self.assertEqual(snapshots[0], snapshots[2])
            for root in roots:
                self.assertFalse(any(p.name == "stale-junk.txt" for rel in MANAGED for p in (root / rel).rglob("*")))
                self.assertGreaterEqual(len(validator.validate(root)), 6)
        finally:
            for root in roots: shutil.rmtree(root)

    def test_repository_second_run_is_byte_noop(self):
        normalizer.generate(REPO)
        before = digest_tree(REPO)
        normalizer.generate(REPO)
        self.assertEqual(before, digest_tree(REPO))

    def test_runtime_import_sidecars_survive_complete_replacement(self):
        root = self.trial("import-sidecars")
        try:
            runtime = root / "assets/world/s3"
            sidecars = {}
            for filename, _, _ in normalizer.ASSETS.values():
                path = runtime / f"{filename}.import"
                data = f"engine-owned:{filename}\n".encode()
                path.write_bytes(data)
                sidecars[path] = data
            (runtime / "stale-junk.txt").write_text("must be removed", encoding="utf-8")
            normalizer.generate(root)
            self.assertFalse((runtime / "stale-junk.txt").exists())
            for path, data in sidecars.items():
                self.assertEqual(path.read_bytes(), data)
        finally:
            shutil.rmtree(root)

    def test_source_is_not_a_runtime_candidate(self):
        source_hash = hashlib.sha256((REPO / "art-src/world/s3/s3-production-source.png").read_bytes()).hexdigest()
        for path in (REPO / "assets/world/s3").glob("*.png"):
            self.assertNotEqual(source_hash, hashlib.sha256(path.read_bytes()).hexdigest())


if __name__ == "__main__": unittest.main(verbosity=2)
