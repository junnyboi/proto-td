# TD-019 — Remove Music autoload's cache-order compile dependency

## Report and reproduction

Poseidon launched current `master` with Godot 4.7.1 on Apple M4 Pro and received a parse error because `autoloads/music.gd` typed `_catalog` and an `as` cast as global `MusicCatalog` before that class was available in the machine's `.godot` global-class registry.

The first reported error is reproduced at base `6a578856d1893030011c557716bbb930559fa681` by deleting `.godot` and running:

```text
godot --headless --path . --quit-after 2
```

Godot prints both `Could not find type "MusicCatalog" in the current scope` and `Failed to instantiate an autoload`, but exits **0**. A fully empty cache also exposes older cache-backed dependencies in other autoloads, so that broad condition remains governed by the existing import-first bootstrap contract and is not reinterpreted as this ticket's scope.

The exact non-vacuous regression starts from a successful import, copies that cache, deletes **only** the `MusicCatalog` entry while retaining `BattleModel` and every other registration, and launches the game. Base fails with Poseidon's Music parse/autoload errors; the fixed tree must load Music and the title scene with no fatal parser/autoload text. The defect is specifically Music's dependence on one cache registration, not catalog data or playback behavior.

## Route

- Primary owner: `godot-2d-environment`.
- Declared seam: `godot-2d-verification`, because the engine fact changes compile-gate execution.
- Effective lane: RELEASE (`engine_export`, public autoload seam, tests/checks, player-facing startup).
- Deterministic impact: none; no BattleModel/hash/save/replay/tick or balance data changes.

## Fix contract

1. `autoloads/music.gd` explicitly preloads `res://assets/music/music_catalog.gd` as a `GDScript` dependency.
2. The autoload stores the catalog as built-in `Resource`, validates that its script exactly equals the explicit preload, and reads `entries` through a fail-closed dictionary helper.
3. No source reference may remain to the global `MusicCatalog` identifier. The catalog resource keeps its `class_name`; editor and resource consumers remain compatible.
4. All TD-017 behavior is unchanged: one player, duplicate same-ID no-op, hard replacement, invalid zero-state rejection, stage/boss routing, and non-battle stop.
5. Add a source regression test that requires the explicit preload and forbids `MusicCatalog` type/cast syntax in the autoload.
6. Add the earned repository rule: a player-launch autoload must explicitly preload a newly introduced cache-sensitive dependency and tolerate a stale/partially populated class registry; import-first remains the fresh-clone bootstrap contract.

## Evidence

- Red base log preserving the exact cache-cold parse failure despite exit 0.
- Stale-cache direct boot with only `MusicCatalog` absent, no `SCRIPT ERROR`, parse error, failed script load, or failed autoload instantiation, and positive Music/title load proof.
- Import, targeted lint, focused Music GUT, music integrity, mandatory headless gate.
- Frozen fresh cache-bypassed RELEASE on the implementation commit with positive test/scenario/bot counts and zero render skips.
- Independent non-implementer diff-vs-pins/evidence audit.
- Current-master reconciliation followed by exact-union verification and normal non-force branch/master pushes.

## Rollback

Revert TD-019. No resource, save, replay, catalog schema, or audio asset migration is required.

## Implementation outcome

- `Music` now preloads the catalog script by path, stores it as built-in `Resource`, validates exact script identity, and validates `entries` as a non-empty `Dictionary` before mutating controller state.
- Existing BattleModel and StageDef routing annotations and behavior remain unchanged; the fix removes only the newly introduced `MusicCatalog` global-class dependency.
- `scripts/cold_boot_check.sh` copies a valid imported cache, removes only `MusicCatalog`, runs the real project with a bounded watchdog, and rejects fatal text even when Godot exits 0.
- `test_autoload_cold_cache.gd` pins the source contract and executes that shell gate inside GUT. Focused result: 4/4 new regression tests pass; existing Music player tests remain 7/7; the mandatory headless repository gate is green.
- A fully empty `.godot` cache still requires the established `--import` bootstrap because pre-existing non-Music autoloads depend on their registered classes. TD-019 neither hides nor broadens into those unrelated boundaries.
