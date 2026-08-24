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

`StageDef.Tile.ELEVATED` and `StageDef.Tile.BLOCKED` both receive source-style raised wall geometry. Deployable elevated cells use smaller obstacle silhouettes so operator sprites and their cell footprint remain readable. Blocked cells use the full obstacle scale. Spawn and base cells retain explicit cyan and amber edge accents, and existing endpoint landmarks remain manifest-backed.

## Replaced assets

The implementation removes the previous generic `assets/sprites/tile_*` set, obsolete S1 terrain/backdrop tile set, and obsolete Act I ground, route, raised, blocked, panorama, and environment-prop images. Their manifest entries were removed. The full source terrain texture and elevated obstacle set now lives in `assets/terrain/proto_isometric/`; its `README.md` records the exact source revision and SHA-256 checksums.

## Validation

The deterministic `test/agent4_isometric_renderer_smoke.gd` check loads every stage from S1 through S8, builds the new renderer, verifies the expected biome cycle, confirms all source textures exist, and confirms selected legacy tile files are absent. `test/agent4_isometric_visual_harness.tscn` launches any stage selected by the `AGENT4_STAGE` environment variable for repeatable 1280×720 visual captures.
