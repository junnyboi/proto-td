# AUI-10 Prep — GPT Image 2 Source Prompt Contract

**Status:** generated source contract; Agent D staging is active and Agent F remains the later runtime integration seam.
**Model:** GPT Image 2
**Reference set:** Agent D's approved `d-world-style-board.png`, `d-act-i-material-prop-sheet.png`, and canonical `d-s1-guild-threshold-keyframe.png` only.

## Frozen style block

Original compact civic-weatherworks game asset, practical public infrastructure rather than temple or magic shrine. Bright Act I coastal daylight. Matte shell-lime aggregate, chalk, bleached timber, plain canvas, rain glass, weathered ceramic, and dark service metal. Simple calibration ticks, drainage joints, louvers, braces, gauge housings, and pressure hardware. Orthographic pure 2:1 dimetric game-art view. Clear low-frequency value groups, dark separators, restrained surface detail, no anti-aliasing-dependent semantics. Designed to survive deterministic reduction to tiny native pixel art.

**Exclude:** recognizable Aetheria/vault-site assets, gothic arches, monumental vault doors, crystals, runes, magic circles, religious symbols, ornate filigree, copied layouts, copied swatches, characters, weapons, text, UI, logos, perspective convergence, square/top-down tiles, photorealism, broad bloom, fog carpets, or reserved probe-color intent.

## Asset prompts

### Ground
A single centered 2:1 isometric diamond top face representing quiet shell-lime civic-court paving. Broad pale aggregate with a few sparse diagonal drainage joints aligned to isometric axes. Center must remain visually quiet and clear for a unit. No vertical walls, props, glyphs, route markings, labels, shadow outside the face, or repeated micro-noise.

### Route
A single centered 2:1 isometric diamond top face representing the Windward Muster Line. Warm compacted aggregate and bleached timber service strips, firmer edge rhythm than ground, subtle west-to-east wear and one neutral mechanical notch cadence. Center remains open for units/traps. No arrows, text, colored magic, props, walls, or false branches.

### Elevated
A single centered 2:1 isometric shell-lime top face with exactly one shallow visible left wall and one darker right wall, suitable for reduction to a 32×16 top plus 8 native wall rows. Open deployable center. Material continuity with ground, dark service-metal braces only on visible wall faces. No railings, stairs, ramps, tall props, second height tier, or overhang.

### Spawn landmark
One compact low signal awning/intake for the left endpoint of a civic weather court, isolated object in 2:1 dimetric view. Bleached timber posts, plain canvas roof, one small wind tab, ceramic intake box, dark service-metal feet. Bottom-center ground contact, wider than tall, open center/underside so emergence remains readable. No gate wall, portal, crystal, rune, text, character, floor tile, or large cast shadow.

### Core landmark
One compact storm-pressure regulator/receiver for the right endpoint, isolated object in 2:1 dimetric view. Squat ceramic pressure drum, small analog gauge housing, two stabilizer feet, dark service-metal braces, pale shell-lime base lip. Bottom-center ground contact, wider than tall, asymmetric from Spawn, with clear open approach and no monumental-door silhouette. No magic glow, crystal, rune, text, character, floor tile, or large cast shadow.

### Backdrop
One low-contrast noninteractive civic-court edge motif: broken shell-lime edge fragments, shallow drainage lip, and dark open air/water recess. It must not complete a clean 2:1 playable diamond, must not resemble route material, and must not have a selectable center.

### Rain measure
One tiny low rain-measure instrument, isolated: squat ceramic basin and short dark service-metal tick post. Bottom-center contact, no overhang beyond a small footprint, no flags, glow, text, floor tile, or tall silhouette.

### Route notch
A restrained transparent overlay for a west-to-east route cadence on a 2:1 diamond: three short neutral mechanical edge notches/chevrons, dark separator plus pale warm accent, sparse enough that units and traps remain dominant. No text, colored magic, broad fill, or reserved white/cyan.

## Generation layout

Generate one standalone source per asset. Tile sources are centered on a solid `#FF00FF` key background and show only the requested diamond/object. Landmark and overlay sources use the same key background. No labels or contact-sheet framing. Deterministic tooling owns crop, alpha, native geometry, palette, and pivots after generation.
