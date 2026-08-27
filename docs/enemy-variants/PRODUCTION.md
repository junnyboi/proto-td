# Early Enemy Variety Production Record

## Scope

The early campaign now introduces one mechanically legible enemy lesson per stage without changing spawn totals or wave boundaries. **S2** replaces one Grunt with an armored Shieldbearer, **S3** replaces two Grunts with two-block Breachers, and **S4** replaces two Drones with durable Interceptors. Mage Apprentice and Sorcerer basic attacks now deal Arts damage, giving the S2 Caster lesson a real mechanical counter instead of decorative copy.

| Stage | New enemy | Authored substitutions | Tactical lesson |
|---|---|---:|---|
| S2 | Shieldbearer | 1 Grunt → 1 Shieldbearer | Armor suppresses Physical damage; Caster Arts attacks ignore that armor. |
| S3 | Breacher | 2 Grunts → 2 Breachers | Each Breacher consumes two block capacity, punishing a single weak choke. |
| S4 | Interceptor | 2 Drones → 2 Interceptors | Durable aerial pressure rewards sustained anti-air rather than one burst hit. |

## Balance definitions

| Enemy | HP | ATK | DEF | RES | Speed | Block weight | Aerial | Special rule |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Shieldbearer | 60 | 6 | 7 | 0 | 0.75 | 1 | No | Deliberately vulnerable to Arts; Caster hits for 9 versus Swordmaster's 3. |
| Breacher | 90 | 10 | 2 | 0 | 0.65 | 2 | No | Occupies two block capacity while engaged. |
| Interceptor | 50 | 5 | 1 | 0 | 0.90 | 0 | Yes | Bypasses blocking, attacks nearby deployed operators within two cells, and remains Charm-immune like Drone. |

The stage schedules preserve the original **10 / 9 / 11** total spawns and `[0, 390]` wave boundaries for S2/S3/S4. Intro hints explicitly teach the intended response before each new enemy arrives.

## Visual production

GPT Image 2 generated eight approved first-frame references under `docs/enemy-variants/source/*/references/`. Sixteen image-conditioned, locked-camera four-second video carriers were produced under `docs/enemy-variants/source/*/carriers/`, with audio disabled and a flat hot-pink or neon-green background. Shieldbearer uses independently authored NE/NW/SE/SW sequences because mirroring would swap its meaningful shield hand. Breacher and Interceptor are bilaterally safe, so NE/SE carriers deterministically derive NW/SW.

Each enemy has `walk` (or hover) and `attack` in four isometric directions. The Breacher's final NE/SE walk carriers were regenerated as locomotion-only cycles after visual review rejected effect-heavy first passes. The video-to-sprites processor sampled eight frames at 8 FPS and emitted lossless WebP masters plus JSON manifests under `docs/enemy-variants/processed/`. `scripts/tools/build_enemy_variant_sheets.py` then performs deterministic alpha cleanup, non-border connected-component filtering, one union crop per sequence, portable repository-relative provenance normalization, and lossless runtime-sheet normalization.

The final runtime package under `assets/enemy-variants/` contains **24 WebP sheets and 24 JSON manifests**. Every sheet exposes eight frames in a **4×2 atlas**, keeps its longest cell edge at exactly 620px, and stays at or below 2,480px on its longest texture dimension—comfortably beneath the 4,096px WebGL2 compatibility ceiling. Godot preserves each variable-size cell's aspect ratio while independently constraining the on-screen footprint to **64px for Shieldbearer/Breacher** and **56px for Interceptor**.

`docs/enemy-variants/SHA256SUMS.txt` records the canonical references, video carriers, processed masters, runtime atlases, JSON metadata, and production manifest. All generated-file provenance paths are repository-relative, so checksum verification and deterministic rebuilds remain portable across clones.

## Runtime integration

`assets/enemy_variant_manifest.tres` is a fourth non-overlapping `Art` manifest layer. IDs follow `enemy_variant_<enemy>_<state>_<direction>`. `EnemyAnimator` routes the three new enemy IDs to this production prefix, preserves ordinary experimental assets for existing enemies, uses each sheet's 8 FPS metadata for both looping walk and non-looping attack frames, and retains damage flash, health bars, and directional transitions. Charmed Shieldbearers and Breachers keep their recognizable production silhouette, reverse direction with faction authority, and receive a distinct blue faction tint instead of degrading to generic Grunt art. Interceptors use `enemy_blocker_then_nearest` with a two-cell range, so their attack sheets are reachable through authoritative target acquisition and cooldown state.

Because the approved S2–S4 schedules and Caster damage kind are combat-authoritative content, the canonical CampaignSave v3 environment hash is reconciled with the concurrent Act II campaign at `94368da5ab8df24620f9987229a3448385226755d36dc9950faebd66ccab8e1e`. Runtime-context construction, fresh campaign startup, and the existing historical-save compatibility suite all pass under the combined binding.

## Deterministic balance telemetry

`tests/early_enemy_variety_balance_telemetry_test.gd` compares the candidate against a generated baseline that restores the substituted Grunts/Drones and Physical Caster attacks. Both runs deploy the same recovery roster immediately at authored cells, auto-trigger ready skills, and raise HP/leak limits only so every spawn resolves. The full raw payload is stored in `BALANCE_TELEMETRY.json`.

| Stage | Metric | Baseline | Candidate | Interpretation |
|---|---|---:|---:|---|
| S2 | Peak pressure | 480 | 480 | No burst-pressure increase. |
| S2 | Terminal tick | 917 | 917 | No encounter-length increase. |
| S2 | Pressure AUC | 207,520 | 227,840 | +9.7%; armor creates a modest sustained-damage lesson. |
| S3 | Peak pressure | 800 | 740 | −7.5%; no burst spike. |
| S3 | Terminal tick | 902 | 1,035 | +14.7%; Breachers create a longer choke interaction. |
| S3 | Pressure AUC | 260,640 | 372,680 | +42.9%; pressure persists longer, but peak alive enemies fall from 5 to 4 and no leaks occur. |
| S4 | Peak pressure | 850 | 850 | No peak-pressure increase. |
| S4 | Terminal tick | 1,100 | 956 | −13.0%; sustained anti-air resolves the mixed wave faster in this fixture. |
| S4 | Pressure AUC | 346,975 | 331,435 | −4.4%; candidate clears all 11 enemies versus one baseline leak. |

All candidate scenarios clear deterministically. The accepted tuning preserves S2 parity, makes S3 a longer but less bursty block-capacity lesson, and keeps S4 within baseline pressure while visibly differentiating its air wave.

## Verification

The implementation is protected by `tests/early_enemy_variety_test.gd`, `tests/early_enemy_variant_art_test.gd`, `tests/early_enemy_variety_balance_telemetry_test.gd`, and the existing stage redesign smoke. These gates cover authoritative Interceptor attacks, Caster counterplay, wave substitutions, 4×2 atlas coordinates, the 4,096px texture ceiling, fixed display footprints, aspect preservation, charmed identity, portable carrier paths, mirror contracts, and manifest-FPS attack progression. Native `BattleView` captures render S2/S3/S4 at 1280×720 and S4 at 720×1280 with Dummy audio; the reusable harness includes a 20-second watchdog, and all target sprites load through the production manifest, preserve transparency, and pass script/runtime/resource scans. Direct import, bounded boot, focused cross-feature regressions, and the expanded repository-wide strict suite all pass on the reconciled native candidate; Web export and forward-only WebDev verification are the remaining release gates.

**Mechanics base revision:** `ece102e` (merged to synchronized master by `b84124e`).
