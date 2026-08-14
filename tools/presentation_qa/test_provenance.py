from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SPEC = importlib.util.spec_from_file_location("aui00_provenance", HERE / "provenance.py")
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ProvenanceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = json.loads((HERE / "provenance_schema_v1.json").read_text(encoding="utf-8"))
        cls.document = json.loads(
            (REPO / "assets/provenance/tile_backdrop.provenance.json").read_text(encoding="utf-8")
        )

    def assert_invalid(self, document: dict[str, object]) -> None:
        with self.assertRaises(ValueError):
            MODULE.validate_schema(document, self.schema, self.schema)

    def test_known_document_and_canonical_bytes(self) -> None:
        MODULE.validate_schema(self.document, self.schema, self.schema)
        raw = (REPO / "assets/provenance/tile_backdrop.provenance.json").read_bytes()
        self.assertEqual(raw, MODULE.canonical_bytes(self.document))
        self.assertEqual(self.document["acceptance"]["state"], "unknown_per_current_byte")
        self.assertIsNone(self.document["acceptance"]["accepting_commit"])

    def test_missing_extra_version_and_wrong_type_reject(self) -> None:
        missing = copy.deepcopy(self.document)
        del missing["migration"]
        self.assert_invalid(missing)
        extra = copy.deepcopy(self.document)
        extra["invented"] = True
        self.assert_invalid(extra)
        version = copy.deepcopy(self.document)
        version["schema_version"] = 2
        self.assert_invalid(version)
        wrong_type = copy.deepcopy(self.document)
        wrong_type["final_files"][0]["bytes"] = "1"
        self.assert_invalid(wrong_type)

    def test_hash_null_enum_path_and_nested_unknown_reject(self) -> None:
        wrong_hash = copy.deepcopy(self.document)
        wrong_hash["final_files"][0]["sha256"] = "A" * 64
        self.assert_invalid(wrong_hash)
        wrong_null = copy.deepcopy(self.document)
        wrong_null["acceptance"]["accepting_commit"] = "218aaea"
        self.assert_invalid(wrong_null)
        wrong_enum = copy.deepcopy(self.document)
        wrong_enum["acceptance"]["state"] = "accepted"
        self.assert_invalid(wrong_enum)
        wrong_path = copy.deepcopy(self.document)
        wrong_path["source_files"][0]["path"] = "/tmp/not-project"
        self.assert_invalid(wrong_path)
        nested_extra = copy.deepcopy(self.document)
        nested_extra["license"]["owner"] = "invented"
        self.assert_invalid(nested_extra)

    def test_exact_source_closure_rejects_omission_extra_and_mutation(self) -> None:
        entry = {"pattern": "res://assets/sprites/tile_backdrop.png", "frames": 1}
        MODULE.validate_document(REPO, self.document, "tile_backdrop", entry)
        omitted = copy.deepcopy(self.document)
        omitted["source_files"].pop()
        with self.assertRaises(ValueError):
            MODULE.validate_document(REPO, omitted, "tile_backdrop", entry)
        extra = copy.deepcopy(self.document)
        extra["source_files"].append(extra["source_files"][0])
        with self.assertRaises(ValueError):
            MODULE.validate_document(REPO, extra, "tile_backdrop", entry)
        mutated = copy.deepcopy(self.document)
        mutated["source_files"][0]["sha256"] = "0" * 64
        with self.assertRaises(ValueError):
            MODULE.validate_document(REPO, mutated, "tile_backdrop", entry)

    def test_s1_ai_assisted_document_is_exact_and_human_final(self) -> None:
        path = REPO / "assets/provenance/world.s1.core_landmark.provenance.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        entry = {"pattern": "res://assets/world/s1/s1-core-landmark.png", "frames": 1}
        MODULE.validate_schema(document, self.schema, self.schema)
        MODULE.validate_document(REPO, document, "world.s1.core_landmark", entry)
        self.assertEqual(document["source_type"], "ai_assisted_deterministic_normalization")
        self.assertEqual(document["generation"]["model"], "gpt-image-2")
        self.assertEqual(document["acceptance"]["state"], "human_final_accepted")
        self.assertEqual(document["acceptance"]["human_accepter"], "Poseidon")
        self.assertEqual(document["acceptance"]["accepting_commit"], MODULE.S1_APPROVED_CANDIDATE)

    def test_round5_character_is_human_final_accepted(self) -> None:
        path = REPO / "assets/provenance/portrait_vanguard_1.provenance.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        entry = {"pattern": "res://assets/portraits/vanguard_1.png", "frames": 1}
        MODULE.validate_schema(document, self.schema, self.schema)
        MODULE.validate_document(REPO, document, "portrait_vanguard_1", entry)
        self.assertEqual(document["source_type"], "ai_assisted_deterministic_normalization")
        self.assertEqual(document["generation"]["model"], "gpt-image-2")
        self.assertEqual(document["acceptance"]["state"], "human_final_accepted")
        self.assertEqual(document["acceptance"]["human_accepter"], "Poseidon")
        self.assertEqual(
            document["acceptance"]["accepting_commit"],
            MODULE.ROUND5_APPROVED_CANDIDATE,
        )

    def test_recruit_placeholder_is_canonical_and_review_pending(self) -> None:
        logical_id = "portrait_recruit_00"
        path = REPO / f"assets/provenance/{logical_id}.provenance.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        entry = {"pattern": "res://assets/portraits/vanguard_1.png", "frames": 1}
        MODULE.validate_schema(document, self.schema, self.schema)
        MODULE.validate_document(REPO, document, logical_id, entry)
        self.assertEqual(document["source_type"], "ai_assisted_deterministic_normalization")
        self.assertEqual(document["generation"]["model"], "gpt-image-2")
        self.assertEqual(document["acceptance"]["state"], "unknown_per_current_byte")
        self.assertIsNone(document["acceptance"]["accepting_commit"])

    def test_single_file_atlas_path_is_not_expanded_as_printf_pattern(self) -> None:
        entry = {"pattern": "res://assets/sprites/grunt_anim_walk_se.png", "frames": 25}
        self.assertEqual(MODULE.final_paths(entry), [entry["pattern"]])

    def test_grunt_animation_atlas_is_ai_assisted_and_review_pending(self) -> None:
        logical_id = "grunt_anim_walk_se"
        path = REPO / f"assets/provenance/{logical_id}.provenance.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        entry = {"pattern": f"res://assets/sprites/{logical_id}.png", "frames": 25}
        MODULE.validate_schema(document, self.schema, self.schema)
        MODULE.validate_document(REPO, document, logical_id, entry)
        self.assertEqual(document["source_type"], "ai_assisted_deterministic_normalization")
        self.assertEqual(document["generation"]["model"], "gpt-image-2")
        self.assertEqual(document["acceptance"]["state"], "human_concept_accepted_runtime_review_pending")
        self.assertEqual(document["acceptance"]["human_accepter"], "Poseidon")
        self.assertIsNone(document["acceptance"]["accepting_commit"])

    def test_operator_animation_atlas_is_higgsfield_backed_and_review_pending(self) -> None:
        logical_id = "op_anim_defender_1_idle_se"
        path = REPO / f"assets/provenance/{logical_id}.provenance.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        entry = {
            "pattern": "res://assets/sprites/operators/animated/defender_1/idle_se.png",
            "frames": 24,
        }
        MODULE.validate_schema(document, self.schema, self.schema)
        MODULE.validate_document(REPO, document, logical_id, entry)
        self.assertEqual(document["source_type"], "ai_assisted_deterministic_normalization")
        self.assertEqual(document["generation"]["provider"], "Higgsfield")
        self.assertEqual(document["generation"]["model"], "Seedance 2.0 family")
        self.assertEqual(
            document["acceptance"]["state"],
            "human_concept_accepted_runtime_review_pending",
        )
        self.assertIsNone(document["acceptance"]["accepting_commit"])


if __name__ == "__main__":
    unittest.main()
