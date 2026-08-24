# Isometric Map Renderer

The battle map now uses the textured multi-pass terrain approach from [`junnyboi/proto-isometric`](https://github.com/junnyboi/proto-isometric) while preserving `proto-td`’s authoritative `StageDef`, `IsoProjection`, `MapNavigator`, and `BattleModel` contracts. The renderer change is presentation-only: cell ownership, placement rules, pathing, hit testing, entity projection, and battle simulation remain unchanged.

## Rendering pipeline

`IsoGridBuilder` installs one `ProtoIsometricTerrain` node under `BattleView/GridRoot`. The node renders a procedural outer field, terrain faces, irregular transition bands, edge lines, endpoint accents, raised walls, and elevated obstacle silhouettes in deterministic passes. Terrain textures repeat through UV coordinates derived from grid vertices, avoiding the visibly repeated 32×16 sprite stamps used by the previous tile system.

| Stage cycle | Ground | Route | Elevated surface | Elevated obstacle family |
|---|---|---|---|---|
| Desert | Desert sand | Salt crust | Iron rock | Source-style rounded rock |
| Wetland | Oasis wetland | Dark mud | Iron rock | Mangrove and stump |
| Frozen | Tundra snow | Blue ice | Iron rock | Snow rock and frozen pine |
| Lava | Lava basalt | Volcanic ash | Iron rock | Basalt chimney and obsidian cluster |

`StageDef.Tile.ELEVATED` and `StageDef.Tile.BLOCKED` both receive source-style raised wall geometry. Deployable elevated cells remain completely clear because they are reserved for ranged and special tower placement. Only blocked cells receive full-scale obstacle sprites. Spawn and base cells retain explicit cyan and amber edge accents, and existing endpoint landmarks remain manifest-backed.

## Replaced assets

The implementation removes the previous generic `assets/sprites/tile_*` set, obsolete S1 terrain/backdrop tile set, and obsolete Act I ground, route, raised, blocked, and environment-prop images. Their battle-art manifest entries were removed. `assets/world/act1/panorama.png` remains solely as mission-card artwork for the staging UI and is not read by the battle renderer. The full source terrain texture and elevated obstacle set now lives in `assets/terrain/proto_isometric/`; its `README.md` records the exact source revision and SHA-256 checksums.

## Validation

The deterministic `test/agent4_isometric_renderer_smoke.gd` check loads every stage from S1 through S8, builds the new renderer, verifies the expected biome cycle, confirms all source textures exist, confirms selected legacy tile files are absent, and enforces that obstacle sprites appear only on blocked cells—not deployable elevated cells. `test/agent4_isometric_visual_harness.tscn` launches any stage selected by the `AGENT4_STAGE` environment variable for repeatable 1280×720 visual captures.

## Elevated placement visual check

The corrected S1 and S4 gameplay captures verify the rule at both compact and large map sizes: every `ELEVATED` platform is a clean, textured raised face with no decorative object occupying its placement footprint. Source obstacle sprites remain restricted to `BLOCKED` cells, so ranged and special towers can be placed without visual overlap.

## Landscape and portrait maps

Campaign resources are authored in landscape orientation. At battle startup, portrait viewports receive a 90-degree clockwise `StageDef` copy; the simulation, renderer, deployment domains, picking, and navigation all consume that same transformed resource. S1–S3 landmark themes rotate their cell-indexed metadata with the stage after the landscape resource passes normal preflight. Orientation remains fixed during a battle, while viewport resizing continues to refit the active map.

The eight redesigned stage contracts are documented in `docs/LEVEL_DESIGNS.md`. `test/stage_redesign_smoke.gd` validates their tactical topology and wave invariants, while `test/stage_orientation_smoke.gd` validates transform fidelity in portrait mode.
