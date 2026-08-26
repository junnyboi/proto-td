# Isometric Map Renderer

The battle map uses the textured multi-pass terrain approach from [`junnyboi/proto-isometric`](https://github.com/junnyboi/proto-isometric) while preserving `proto-td`’s authoritative `StageDef`, `IsoProjection`, `MapNavigator`, and `BattleModel` contracts. The renderer is presentation-only: cell ownership, placement rules, pathing, hit testing, entity projection, and battle simulation remain unchanged.

## Rendering pipeline

`IsoGridBuilder` installs one `ProtoIsometricTerrain` node under `BattleView/GridRoot`. The node renders a procedural outer field, terrain faces, irregular transition bands, edge lines, endpoint accents, and raised walls in deterministic passes. Terrain textures repeat through UV coordinates derived from grid vertices, avoiding the visibly repeated 32×16 sprite stamps used by the previous tile system.

| Stage cycle | Ground | Route | Elevated/blocked surface | Platform-top policy |
|---|---|---|---|---|
| Desert | Desert sand | Salt crust | Iron rock | Clear |
| Wetland | Oasis wetland | Dark mud | Iron rock | Clear |
| Frozen | Tundra snow | Blue ice | Iron rock | Clear |
| Lava | Lava basalt | Volcanic ash | Iron rock | Clear |

`StageDef.Tile.ELEVATED` and `StageDef.Tile.BLOCKED` both retain raised wall geometry, but **every raised face is intentionally empty**. The renderer no longer preloads or draws boulders, trees, stumps, crates, walls, chimneys, obsidian clusters, or procedural rock blobs on any platform. This keeps deployment silhouettes unambiguous and removes visual clutter from blocked architecture across S1–S8.

## Animated endpoints

Every `SPAWN` cell receives a generated photon-energy portal and every `BASE` cell receives a generated holy-crystal pedestal. Both were produced through the project-required **GPT Image 2 → image-conditioned video → `/video-to-sprites`** pipeline and registered in `assets/act1_shared_manifest.tres` as looping `idle` animations. Portal frames retain 589×600 source pixels and display at 64×64; crystal frames retain 401×600 source pixels and display at 64×80. `BattleEndpointLandmark` advances manifest frames, applies mipmapped linear filtering, freezes on frame zero when reduced motion is enabled, ignores pointer input, and remains bottom-centered within a one-tile footprint.

`IsoGridBuilder` enumerates endpoint tiles directly from the authoritative `StageDef`, so multi-path stages receive all portals and pedestals even when they have no authored `StageArtTheme`. `MapNavigator` fits the exact union of terrain and endpoint frames on initial load, preventing tall generated landmarks from clipping at viewport edges without changing simulation geometry.

## Replaced assets

The implementation removes the previous generic `assets/sprites/tile_*` set, obsolete S1 terrain/backdrop tile set, and obsolete Act I ground, route, raised, blocked, and environment-prop images. Their battle-art manifest entries were removed. `assets/world/act1/panorama.png` remains solely as mission-card artwork for the staging UI and is not read by the battle renderer. Source terrain textures remain under `assets/terrain/proto_isometric/`; obsolete obstacle files may remain as source references but are neither preloaded nor rendered.

## Validation

`tests/battle_endpoint_landmark_test.gd` verifies the 600px source-frame ceiling, independent one-tile display size, mipmapped linear filtering, frame count, FPS, terminal-frame availability, frame advance, and reduced-motion freezing. `test/agent4_isometric_renderer_smoke.gd` loads every stage from S1 through S8, verifies the biome cycle and terrain textures, rejects any remaining platform-top prop renderer, and requires one animated landmark for every SPAWN and BASE tile. `test/map_navigator_orientation_smoke.gd` protects endpoint-aware height fitting in portrait and landscape. `test/agent4_isometric_visual_harness.tscn` launches any stage selected by `AGENT4_STAGE` for repeatable visual captures.

## Landscape and portrait maps

Campaign resources are authored in landscape orientation. At battle startup, portrait viewports receive a 90-degree clockwise `StageDef` copy; the simulation, renderer, deployment domains, picking, navigation, and endpoint enumeration consume that same transformed resource. Orientation remains fixed during a battle, while viewport resizing refits the active map against the endpoint-aware visual envelope.

The eight redesigned stage contracts are documented in `docs/LEVEL_DESIGNS.md`. `test/stage_redesign_smoke.gd` validates their tactical topology and wave invariants, while `test/stage_orientation_smoke.gd` validates transform fidelity in portrait mode.
