#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
sys.path.insert(0, str(TOOLS))

import recruit_approval as approval


class RecruitApprovalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.approval_path = REPO / approval.APPROVAL_PATH.removeprefix("res://")
        cls.raw = cls.approval_path.read_bytes()
        cls.document = json.loads(cls.raw)
        cls.manifest = (
            __import__("subprocess")
            .check_output(
                [
                    "git",
                    "-C",
                    str(REPO),
                    "show",
                    f"{approval.APPROVED_CANDIDATE}:assets/manifest.tres",
                ]
            )
        )

    def validate(
        self,
        document: dict | None = None,
        *,
        raw: bytes | None = None,
        generated_assets: dict[str, bytes] | None = None,
        generated_contact_sheet: bytes | None = None,
        candidate_manifest: bytes | None = None,
        file_overrides: dict[str, bytes] | None = None,
    ) -> None:
        chosen = copy.deepcopy(self.document if document is None else document)
        approval.validate_recruit_approval(
            REPO,
            chosen,
            approval._canonical_bytes(chosen) if raw is None else raw,
            generated_assets=generated_assets,
            generated_contact_sheet=generated_contact_sheet,
            candidate_manifest=self.manifest if candidate_manifest is None else candidate_manifest,
            file_overrides=file_overrides,
        )

    def test_current_exact_candidate_is_authenticated(self) -> None:
        self.validate(raw=self.raw)
        approval.authenticate_recruit_approval(REPO)

    def test_every_exact_approval_identity_field_rejects_mutation(self) -> None:
        mutations = {
            "schema_version": 2,
            "phase": 7,
            "feature": "different",
            "verdict": "REJECT",
            "human_accepter": "nobody",
            "accepted_at_utc": "1970-01-01T00:00:00Z",
            "accepted_candidate_commit": "0" * 40,
            "approved_manifest_sha256": "0" * 64,
            "ordered_asset_set_sha256": "0" * 64,
            "approval_text": "different",
        }
        for key, value in mutations.items():
            with self.subTest(key=key):
                changed = copy.deepcopy(self.document)
                changed[key] = value
                with self.assertRaises(ValueError):
                    self.validate(changed)

    def test_noncanonical_missing_extra_and_closure_mutations_reject(self) -> None:
        with self.assertRaises(ValueError):
            self.validate(raw=self.raw + b"\n")
        for mutation in ("missing", "extra"):
            with self.subTest(mutation=mutation):
                changed = copy.deepcopy(self.document)
                if mutation == "missing":
                    del changed["verdict"]
                else:
                    changed["invented"] = True
                with self.assertRaises(ValueError):
                    self.validate(changed)
        for key, value in {
            "approved_logical_ids": list(reversed(approval.APPROVED_LOGICAL_IDS)),
            "authorized_mutation": "broader mutation",
        }.items():
            with self.subTest(closure=key):
                changed = copy.deepcopy(self.document)
                changed["closure_authority"][key] = value
                with self.assertRaises(ValueError):
                    self.validate(changed)

    def test_asset_missing_duplicate_reordered_and_byte_mutations_reject(self) -> None:
        cases = []
        missing = copy.deepcopy(self.document)
        missing["ordered_assets"].pop()
        cases.append(missing)
        duplicate = copy.deepcopy(self.document)
        duplicate["ordered_assets"][-1] = copy.deepcopy(duplicate["ordered_assets"][0])
        cases.append(duplicate)
        reordered = copy.deepcopy(self.document)
        reordered["ordered_assets"][0], reordered["ordered_assets"][1] = (
            reordered["ordered_assets"][1],
            reordered["ordered_assets"][0],
        )
        cases.append(reordered)
        for index, changed in enumerate(cases):
            with self.subTest(shape=index), self.assertRaises(ValueError):
                self.validate(changed)
        generated = {
            path: (REPO / path.removeprefix("res://")).read_bytes()
            for path in approval.APPROVED_ASSET_PATHS
        }
        self.validate(generated_assets=generated)
        for path in approval.APPROVED_ASSET_PATHS:
            with self.subTest(asset=path):
                changed = generated.copy()
                changed[path] = changed[path] + b"tamper"
                with self.assertRaises(ValueError):
                    self.validate(generated_assets=changed)

    def test_source_contact_and_candidate_manifest_mutations_reject(self) -> None:
        for path in approval.APPROVED_SOURCE_PATHS + approval.APPROVED_CONTACT_PATHS:
            with self.subTest(file=path), self.assertRaises(ValueError):
                self.validate(file_overrides={path: b"tamper"})
        approved_contact = (
            REPO / approval.APPROVED_CONTACT_PATHS[0].removeprefix("res://")
        ).read_bytes()
        self.validate(generated_contact_sheet=approved_contact)
        with self.assertRaises(ValueError):
            self.validate(generated_contact_sheet=approved_contact + b"tamper")
        with self.assertRaises(ValueError):
            self.validate(candidate_manifest=self.manifest + b"tamper")


if __name__ == "__main__":
    unittest.main(verbosity=2)
