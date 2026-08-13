# AUI-11 Visual Review — `attack_hit`

**Verdict: REVISE**

## Atlas
- Both Python and Godot atlases are 768×384 RGBA sheets with a clear 4×2 grid and exactly eight populated cells.
- Frame order is stable between renderers; no cell is blank or clipped, and no adjacent pair is an exact-looking duplicate.
- Row endpoints match cleanly enough to loop (frames 1/4 and 5/8 are matching boundary poses).
- The atlas background is transparent. Aubergine/rose coloring and the compact silhouette remain discernible at final scale.
- **Fatal semantic issue:** the frames read as centered, bilateral four-point/star-flare impacts rather than a directional slash. `attack_hit` explicitly rejects star flares.

## Contact sheet
- Both 1536×256 contact sheets show all eight frames on each of the three intended backgrounds (light, dark, gray), with no visible layout corruption.
- The effect remains visible across the backgrounds, though intentionally very small.
- Python and Godot outputs are visually identical; pixel comparison also finds zero differing pixels in both atlas and contact sheet.

## Required revision
Replace the centered star-flare silhouette with a compact, clearly directional aubergine-and-rose hit slash while preserving the otherwise valid 8-frame atlas/contact layout, transparency, loop boundaries, and renderer parity.
