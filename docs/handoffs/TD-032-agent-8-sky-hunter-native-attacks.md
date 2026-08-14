# TD-032 — Native Sky Hunter NE and NW Attack Animations

**Author:** Manus AI / Agent 8

**Repository:** `prototype-td`

**Verified candidate:** `c7f65d04285dedad947be93f1186d4b70ab33096`

**Source package:** `aetheria-chibi-sprites-part-2-completed`

## Outcome

TD-032 replaces the two temporary Sky Hunter attack substitutions with native NE and NW Seedance motion. The game now contains four native and independently generated Sky Hunter attack directions. No directional mirroring remains in this family, and no source, runtime, manifest, resource, or compact-provenance placeholder flag remains anywhere in Aetheria Part 2.

The replacement is presentation-only. The runtime continues to use 192×192 RGBA cells, thirteen attack frames selected from source indices `0,2,4,...,24`, 12 fps playback, pivot `(0.5, 0.94)`, a 158 px normalization denominator, binary alpha, and the existing view projection. Simulation, action, tick, save, replay, economy, operator data, and combat outcomes are unchanged.

## Native assets

| Direction | Accepted source SHA-256 | Runtime PNG SHA-256 | Runtime RGBA SHA-256 | Placeholder |
|---|---|---|---|---|
| NE | `12e0d0a6ac543f66e261d4be5ab6a03e1b39534c776b12383ad4fdc43be86220` | `6ad0f4e47dd6ab80ba1e5b6eddc2c070fd8d0ab2e19177e0381d2a300e4aa201` | `83086fab71a47596d5477dbfa8cd5ef1254fb003ed7faa32e3b6b569416be568` | `false` |
| NW | `6613f6665bd2f1bdc62be1d58919173eda8fec0cd097afd6234188fb1a47c6ee` | `1f8b3d57ce61d9e0598f4ae830ffabf0d4a136acb28fdf7c09fa3dd129d0b69a` | `88ad7d72e031059fc4251e0810eaa2befbb795bd5081692bac89a16a7b6f05f6` | `false` |

The source importer also recompiled the four-direction Sky Hunter attack family under one shared state scale, so the unchanged native SE and SW rows received deterministic runtime-byte updates together with NE and NW. NE and NW source hashes are explicitly unequal to SE and SW, closing the former substitution channel.

## Human visual acceptance and provenance

Poseidon reviewed the linked four-direction contact sheet plus NE and NW gameplay-cadence GIFs and replied to continue if the work was on track. That response is recorded as ACCEPT for the exact native source hashes at `2026-08-14T06:41:55Z` in `docs/media/TD-032-SKY-HUNTER-NATIVE-APPROVAL.json`.

The NE and NW per-atlas provenance sidecars are now `human_final_accepted` and include the approval record in their exact source closure. The other Part 2 atlases retain their existing concept-accepted status while inheriting the refreshed all-native package manifest digest. The compact runtime catalog reports `part2_runtime_integrated_all_native`, and `known_placeholders` is empty.

## Verification

| Gate | Result |
|---|---|
| Package audit | PASS: 40 assets, zero placeholders, 9,358,058 opaque pixels, 4,806 near-magenta edge pixels (0.05136%) |
| Deterministic importer | PASS and byte-stable under `--check` |
| Runtime validator | PASS: all 56 admitted operator atlases |
| Canonical provenance | PASS after regeneration and no-write check |
| Focused Aetheria import test | PASS: 2 tests, 227 assertions |
| Focused operator catalog test | PASS: 6 tests, 260 assertions |
| Focused presentation provenance test | PASS: 9 tests, 3,594 assertions |
| Union enemy-manifest tests | PASS: experimental salvage, Art fallback, and enemy animator suites |
| `operator_animation_catalog` | PASS: 39 checks, 14 rendered shots, zero skips |
| `operator_animation_part2` | PASS: 72 checks, 2 rendered shots, zero skips |
| Live-master affected proof | PASS: bilingual UI 765 checks, experimental salvage 48 checks, and Grunt animation 41 checks, zero skips |
| Stale-class registry | PASS: exact `en-US`/`zh-CN` locale registry plus title, staging, squad, results, S1, S2, and S3 boot from the historical cache |
| Final clean STANDARD | PASS on `c7f65d0`: 105 rungs across full GUT, property oracles, replay/filesystem probes, every headless/rendered scenario, bots, and quality gates |

The live-battle scenario now asserts that Sky Hunter resolves `op_anim_sniper_2_attack_ne` with a false manifest placeholder flag and an empty resource source-direction map. It also retains the existing projection hash-invariance check, so the native visual replacement cannot mutate model state.

## Live-master union

Live master first advanced with Agent 9’s experimental enemy salvage work, producing operator/enemy manifest union `516e6e9`. It advanced again with Agent 11’s atomic `en-US`/`zh-CN` localization, producing combined union `a2f5298`. The first full gate on that combined union exposed a stale-cache probe that still expected the superseded one-locale registry. Commit `c7f65d0` corrected the probe to require exactly `en-US` and `zh-CN`, added a direct regression test, and then passed the complete 105-rung STANDARD gate from zero. No runtime locale behavior, catalog bytes, animation bytes, simulation, or threshold was changed by that correction.

## Delivery

The refreshed all-native package is archived as `aetheria-chibi-sprites-part-2-completed.zip` with SHA-256 `c6b148db0d8091800ed458b4b5d36e8239782863cb9fdcbefc66b2c792e8601c`. Its package manifest SHA-256 is `c57ae5779f320f597e1d3fd34eb6089ca19c81e742437bb4764ee2a50275e2e4`. The package contains forty directional sheets and no placeholder note or placeholder metadata.

TD-032 has no remaining implementation blocker. Any later work on this family is optional art-direction refinement rather than placeholder retirement or runtime correctness work.
