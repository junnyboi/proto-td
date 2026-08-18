#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import mock

from PIL import Image, ImageDraw

import import_recruit_sheets as importer

REPO = Path(__file__).resolve().parents[3]


class RecruitImporterTests(unittest.TestCase):
    def field_source(self, size: tuple[int, int] = (200, 200)) -> Image.Image:
        return Image.new("RGBA", size, (*importer.FIELD_BACKGROUND, 255))

    def portrait_source(self, size: tuple[int, int] = (200, 200)) -> Image.Image:
        return Image.new("RGBA", size, (244, 12, 232, 255))

    def test_accepted_sources_satisfy_fail_closed_contract(self) -> None:
        field = Image.open(
            REPO / "art-src/characters/recruit/recruit-field-master.png"
        ).convert("RGBA")
        portraits = Image.open(
            REPO / "art-src/characters/recruit/recruit-portrait-treatment-sheet.png"
        ).convert("RGBA")
        importer.validate_source_subject(field, "accepted field", True)
        for index in range(8):
            importer.validate_source_subject(
                portraits.crop(importer.portrait_crop(index)),
                f"accepted portrait {index}",
                False,
            )

    def test_empty_wrong_background_and_top_clipped_sources_reject(self) -> None:
        with self.assertRaises(ValueError):
            importer.validate_source_subject(self.field_source(), "empty", True)
        wrong = Image.new("RGBA", (200, 200), (20, 200, 20, 255))
        ImageDraw.Draw(wrong).rectangle((60, 20, 140, 190), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(wrong, "wrong background", True)
        clipped = self.field_source()
        ImageDraw.Draw(clipped).rectangle((60, 0, 140, 190), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(clipped, "clipped", True)

    def test_two_subject_detached_large_part_and_incomplete_sources_reject(self) -> None:
        two_subjects = self.field_source()
        draw = ImageDraw.Draw(two_subjects)
        draw.rectangle((25, 30, 80, 185), fill=(20, 40, 60, 255))
        draw.rectangle((120, 30, 175, 185), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(two_subjects, "two subjects", True)

        detached = self.field_source()
        draw = ImageDraw.Draw(detached)
        draw.rectangle((45, 25, 125, 190), fill=(20, 40, 60, 255))
        draw.rectangle((145, 80, 180, 180), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(detached, "detached large part", True)

        incomplete = self.field_source()
        ImageDraw.Draw(incomplete).rectangle((85, 100, 115, 170), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(incomplete, "incomplete", True)

    def test_cross_cell_portrait_input_rejects(self) -> None:
        cross_cell = self.portrait_source()
        draw = ImageDraw.Draw(cross_cell)
        draw.rectangle((10, 30, 85, 190), fill=(20, 40, 60, 255))
        draw.rectangle((115, 30, 190, 190), fill=(20, 40, 60, 255))
        with self.assertRaises(ValueError):
            importer.validate_source_subject(cross_cell, "cross-cell portrait", False)

    def test_connected_portrait_subject_clipped_at_each_edge_rejects(self) -> None:
        boxes = {
            "left": (0, 35, 145, 180),
            "right": (55, 35, 199, 180),
            "top": (25, 0, 175, 180),
            "bottom": (25, 20, 175, 199),
        }
        for edge, box in boxes.items():
            with self.subTest(edge=edge):
                clipped = self.portrait_source()
                ImageDraw.Draw(clipped).rectangle(box, fill=(20, 40, 60, 255))
                with self.assertRaises(ValueError):
                    importer.validate_source_subject(clipped, f"portrait {edge}", False)

    def test_full_run_writes_nothing_for_each_clipped_portrait_edge(self) -> None:
        boxes = {
            "left": (0, 35, 145, 180),
            "right": (55, 35, 199, 180),
            "top": (25, 0, 175, 180),
            "bottom": (25, 20, 175, 199),
        }
        valid_field = self.field_source()
        ImageDraw.Draw(valid_field).rectangle((60, 20, 140, 180), fill=(20, 40, 60, 255))
        for edge, box in boxes.items():
            with self.subTest(edge=edge), TemporaryDirectory() as temp:
                portrait_sheet = Image.new("RGBA", (800, 400), (244, 12, 232, 255))
                ImageDraw.Draw(portrait_sheet).rectangle(box, fill=(20, 40, 60, 255))

                def source_open(path: Path) -> Image.Image:
                    return (
                        portrait_sheet.copy()
                        if "portrait-treatment" in str(path)
                        else valid_field.copy()
                    )

                review_dir = Path(temp) / "review"
                with (
                    mock.patch.object(importer, "PORTRAIT_SOURCE_SIZE", (800, 400)),
                    mock.patch.object(importer, "FIELD_SOURCE_SIZE", (200, 200)),
                    mock.patch.object(importer, "PORTRAIT_CELL_SIZE", (200, 200)),
                    mock.patch.object(importer.Image, "open", side_effect=source_open),
                    mock.patch.object(importer, "save_atomic") as save,
                    mock.patch.object(importer, "authenticate_recruit_approval") as authenticate,
                ):
                    with self.assertRaises(ValueError):
                        importer.run(REPO, review_dir)
                    save.assert_not_called()
                    authenticate.assert_not_called()
                    self.assertFalse(review_dir.exists())

    def test_approval_failure_occurs_before_any_output_write(self) -> None:
        image = Image.new("RGBA", (2, 2), (0, 0, 0, 0))
        with (
            mock.patch.object(
                importer,
                "authenticate_recruit_approval",
                side_effect=ValueError("tampered approval"),
            ),
            mock.patch.object(importer, "save_atomic") as save,
        ):
            with self.assertRaises(ValueError):
                importer.publish_approved_outputs(
                    REPO,
                    [(REPO / "assets/never-written.png", image)],
                    {},
                    image,
                    REPO / "artifacts/never-written.png",
                )
            save.assert_not_called()


if __name__ == "__main__":
    unittest.main(verbosity=2)
