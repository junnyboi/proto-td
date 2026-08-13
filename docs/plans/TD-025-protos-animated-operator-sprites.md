# Protos — Animated Operator Sprite Integration Plan

**Author:** Manus AI  
**Owner:** AGENT 5  
**Branch:** `agent-5/td-025-operator-animations`  
**Plan mode:** Active implementation session; Gate H remains human-owned  
**Primary skill:** `godot-2d-planner`  
**Declared seam:** `godot-2d-art-audio`  
**Assurance route:** **RELEASE**  
**Canon authority:** `Protos-World-and-Lore-Bible.md`, version 3.3, 2026-08-13 [1]  
**Repository baseline:** `junnyboi/prototype-td` master `a26969770a5ed57206d0751c1d0f757ac576f733`  
**Baseline result:** fresh detached-clean STANDARD green in 244 seconds: 35 passing rungs, including R3 GUT, replay, filesystem Web, and 28 R4a scenarios [2]

## 1. Mission

Integrate the generated four-direction `idle` and `attacking` animation sheets as player-facing **Company 33 class combat projections**. The work must preserve deterministic simulation, route every production asset through the existing manifest and provenance systems, retain current fallback art until each replacement is honestly admitted, and require human approval before any final-art flag changes.

This is not a simple file-copy operation. The source package is technically complete—40 RGBA sheets, five subjects, two states, four directions, 25 frames per sheet—but only six of ten state families passed agent visual review. One subject is also canon-incompatible with its game class. Technical green is not a diplomatic passport for wrong art. [3] [4]

## 2. Canon reconciliation

The lore bible establishes **Protos**, **Company 33**, a changing roster of adult recruits, and class identities that must not imply a fixed team of generated heroes. Classes describe trained roles; they do not determine culture, morality, gender, or destiny. The prior `Aetheria` label is a retired production term and must not appear on active player-facing surfaces. [1]

The game already exposes the correct class names in `data/operators/*.tres`; no data rename is required. Internal template IDs remain stable because they are implementation identifiers, not player-facing identities. The generated figures are therefore treated as reusable **class projections**, not named heroes and not proof of any recruit's identity.

| Internal template | Retired source label | Canon class projection | Admission now | Required action |
|---|---|---|---|---|
| `vanguard_1` | Vanguard | **Shock Trooper** | Blocked | Regenerate attack NW and SW so all directions preserve the same adult, costume, spear, and thrust family. |
| `vanguard_2` | Bannerguard | **Banner Guard** | Blocked | Remove idle contact shadows without changing the character; regenerate attacks to one pole-thrust family with stable banner cloth and finial. |
| `guard_1` | Swiftblade | **Swordmaster** | Human approval required | Both state families passed technical and agent visual review. Present exact contact sheets to the human art owner; do not auto-approve. |
| `guard_2` | Brandmaster | **Sword Saint** | Reject and regenerate all | The double-ended axe silhouette contradicts Sword Saint. Do not relabel the axe bearer as a sword class. Generate a new sword-bearing four-direction reference, then regenerate idle and attack. |
| `defender_1` | Defender | **Defender** | Blocked | Remove or regenerate attack SE and SW motion-arc residue while preserving hammer, tower shield, identity, and the no-effects capture lock. |

The machine-readable mapping is preserved beside the source production workspace as `PROTOS-IDENTITY-MAP.json`. [5]

## 3. Dependency contract and ownership

AUI-20 was retired before implementation at master `a26969770a5ed57206d0751c1d0f757ac576f733`; every claimed path was released and no AUI-20 runtime or art byte exists to consume. Its representative-fixture authorization is historical input only and grants no runtime binding. [6]

This package therefore extends the landed AUI-34 deterministic 192-pixel normalization seam directly. It does not reactivate AUI-20, use its fixture authorization as acceptance, or modify any future canon-comprehension/tactical-combat successor. The current no-overlap orientation, fresh detached STANDARD baseline, isolated worktree, and narrow TD-025 lease are Phase 0 prerequisites.

**BLOCKED condition:** another active lease claims any TD-025 file; the current base loses its green baseline; or a future master change replaces the AUI-34 192-pixel contract before the exact union freezes.

**CONTINUE condition:** current master is clean and green, the TD-025 lease is conflict-free, and the exact human-approved class packets remain hash-identical.

## 4. Pinned content contract

### 4.1 Source package

| Parameter | Pinned value |
|---|---|
| Subjects | 5 template IDs listed above |
| Source states | `idle`, `attacking` |
| Production aliases | `idle`, `attack` |
| Directions | `se`, `ne`, `nw`, `sw`; no mirrored substitutes |
| Source sheet | 6,400×256 RGBA; 1×25 horizontal frames |
| Source frame | 256×256 maximum |
| Source playback | 12 fps |
| Idle loop frames | source indices 0–23; index 24 is the duplicated loop endpoint and is not replayed |
| Attack runtime window | source indices 12–24, representing impact through recovery after the model attack edge |
| Background | transparent in admitted runtime outputs |
| Source inventory | 40 sheets; all original SHA-256 values must match `MANIFEST.json` [3] |
| Candidate status | technical pass; manual visual approval incomplete [4] |

### 4.2 Canon display-height contract

Relative height is inherited from the approved front-facing reference pack rather than inferred from animated weapon bounds. A 72-pixel tallest-class cap produces the following pinned subject heights:

| Template | Approved reference height | Runtime subject height |
|---|---:|---:|
| `guard_1` / Swordmaster | 208 | 63 px |
| `vanguard_1` / Shock Trooper | 210 | 64 px |
| `defender_1` / Defender | 226 | 69 px |
| `vanguard_2` / Banner Guard | 234 | 71 px |
| `guard_2` / Sword Saint | 236 | 72 px |

All frames for one template use one shared scale. Per-frame or per-direction scaling is forbidden because it would make a recruit breathe like an accordion. The order and values derive from the approved source geometry and preserve the requested height differences. [7]

### 4.3 Runtime normalization

These values extend the landed AUI-34 pipeline through a companion schema. AUI-20 is retired and supplies no runtime contract. [8]

| Parameter | Provisional value |
|---|---|
| Runtime cell | 192×192 RGBA8 |
| Safe subject box | 168×168 within a 12-pixel border |
| Pivot | normalized `(0.5, 0.94)` |
| Foot anchor | row 180 |
| Horizontal anchor | x = 96 |
| Alpha | exactly 0 or 255 after normalization |
| Resize sampler | pinned integer nearest-neighbor |
| Runtime filtering | nearest; no mipmaps; no texture repeat |
| Reserved probe colors | `#F4F4F4`, `#41A6F6` absent from ordinary opaque art |
| Runtime source count | 40 directional state sheets retained; no direction mirroring |
| Decoded upper bound | 140.625 MiB if every 25-frame 192×192 sheet is resident simultaneously |

The importer must preserve every source frame in staging. Runtime loading is lazy by admitted template/state/direction.

Memory is measured on Linux x86_64 with the regular Godot 4.7.1 build by sampling process `VmHWM` from `/proc/<pid>/status`. Every measurement is three fresh OS processes; the median is the verdict. Phase 0 records a frozen boot baseline and `battle_controls` baseline at the exact prerequisite SHA. Candidate boot may add at most **16 MiB** over the frozen boot median. Candidate `battle_controls` may add at most **48 MiB** over its frozen baseline median. The all-assets catalog may peak at no more than **frozen boot median + 192 MiB**. The manifest's decoded animation payload must remain at or below **140.625 MiB**. A timeout or missing sample is red. Exceeding a ceiling requires loading/packing optimization, not hidden frame deletion.

### 4.4 Facing and state semantics

`UnitState.Facing` maps mechanically through the existing isometric axes:

| Model facing | Runtime direction |
|---|---|
| `RIGHT` (0) | `se` |
| `DOWN` (1) | `sw` |
| `LEFT` (2) | `nw` |
| `UP` (3) | `ne` |

No runtime `flip_h` is used for admitted four-direction art. A direction change swaps the logical animation key immediately.

The view does not write model state. Idle age is presentation time and advances in `_process`. `BattleModel.step()` writes `last_attack_tick = T` during combat and increments `model.tick` before the view observes it, so the first real rendered observation is attack age 1. Attack state is derived from that existing authoritative edge:

```text
attack_age_ticks = model.tick - unit.last_attack_tick
attack_active = 1 <= attack_age_ticks < 30
attack_frame = floor((attack_age_ticks - 1) * 13 / 29)
idle_frame = floor(idle_seconds * 12) mod 24
```

`attack_frame` addresses the imported impact/recovery subset corresponding to source frames 12–24. The exhaustive observable mapping is: ages `1–3→0`, `4–5→1`, `6–7→2`, `8–9→3`, `10–12→4`, `13–14→5`, `15–16→6`, `17–18→7`, `19–21→8`, `22–23→9`, `24–25→10`, `26–27→11`, and `28–29→12`; age 30 returns to idle. A pure seam test also requires age 0 to clamp to frame 0, but the real-battle scenario never claims it observed age 0. The fixed 30-tick presentation window is one second at the project's pinned 30 Hz simulation rate. It introduces no mutable model field, does not change hashes/saves/replays, and remains a view projection even if a unit's next attack arrives sooner due to a buff. The source wind-up is not played because the model exposes an impact edge, not a forecastable attack commitment. Inventing a wind-up in the model would convert an art phase into a contract change and trigger a separate RELEASE plan.

## 5. Active TD-025 file ownership

The conflict-free lease is active on `agent-5/td-025-operator-animations`. Paths marked `new` are conflict-isolation seams; every row is bounded by the exact five template IDs in this package.

| Path | Action | Purpose |
|---|---|---|
| `staging/assets/characters/operator-animation-v1/**` | new | Immutable source sheets, candidate/rejected partition, source manifests, and canon identity map. |
| `staging/provenance/characters/operator-animation-v1/**` | new | Tool/model/prompt/reference/source/output hashes, human state, and retired-label metadata. |
| `staging/qa/character-vfx/operator-animation-v1/**` | new | Specs, expected measurements, contact sheets, and non-vacuous admission reports. |
| `tools/art_pipeline/characters/import_operator_animations.py` | new | Fail-closed 25-frame directional importer and runtime packet builder. |
| `tools/art_pipeline/characters/test_import_operator_animations.py` | new | Source hash, geometry, alias, identity, and corruption tests. |
| `assets/sprites/operators/animated/{vanguard_1,vanguard_2,guard_1,guard_2,defender_1}/**` | new | Accepted runtime atlases only. No blocked or rejected family enters this path. |
| `assets/provenance/operators/operator-animation-v1.json` | new | Runtime provenance ledger and per-family human state. |
| `data/presentation/operator_animation_def.gd*` | new | Versioned companion resource containing exact state×direction logical IDs without changing `CharacterVisualDef` schema v1. |
| `data/presentation/operator_visual_catalog.gd*` | new | Exact template-to-`CharacterVisualDef` plus `OperatorAnimationDef` catalog with fail-closed validation. |
| `data/presentation/operator_visuals/{vanguard_1,vanguard_2,guard_1,guard_2,defender_1}.tres` | new | One visual resource pair per accepted template. |
| `scripts/view/operator_animator.gd*` | new | Pure direction/state/frame selection plus presentation-only node refresh. |
| `assets/asset_manifest.gd` | amend | Validate 25-frame directional animation metadata without weakening existing rows. |
| `scripts/view/art.gd` | amend narrowly | Resolve accepted operator animation logical IDs through the existing manifest. |
| `assets/manifest.tres` | amend | Add only accepted logical animation IDs and provenance. |
| `scripts/view/battle_view.gd` | amend narrowly | Delegate operator body presentation to `OperatorAnimator`; preserve HP/SP/shadow/chevron seams. |
| `test/test_operator_animator.gd*` | new | Pure exactness tests for mapping, timing, fallback, and zero-model-mutation behavior. |
| `test/test_operator_animation_def.gd*` | new | Exact eight-key resource/catalog and manifest corruption tests. |
| `selftest/harness.gd` | amend | Expose completion-sentinel booleans in every scenario report; no behavior or threshold weakening. |
| `selftest/scenarios/operator_animation_{smoke,catalog,flow}.gd*` | new | Permanent smoke/watchdog proof, accepted-template catalog, and real-battle four-facing idle/attack proof. |
| `scripts/verify.sh` | amend | Enforce 10/15/45-second shell watchdogs for smoke/catalog/flow, preserve 120 seconds for every other scenario, and fail closed on report freshness/result/check-count/sentinel/windowed-skip fields. |
| `FEATURES.json` | amend at closure | Add one visual feature row only after its declared evidence exists. |
| `docs/plans/TD-025-protos-animated-operator-sprites.md`, `docs/todo.md`, `docs/completed.md`, `docs/handoffs/TD-025-agent-5-operator-animations.md` | amend/new | Plan, lease, closure, and exact evidence identity. |

Do not claim `data/operators/*.tres`: canonical display names are already correct, and animation metadata belongs to the presentation layer.

## 6. Implementation phases

### Phase 0 — Reorient, clear prerequisites, and freeze contracts

**Work.** Record the AUI-20 retirement, restore the pinned Godot/export environment if needed, run STANDARD on a clean detached checkout, record the exact green master SHA, allocate a coordination ID, create an isolated worktree, claim the file set, and copy this plan into the repo under `docs/plans/` without changing its pins. Capture the three-process median boot and `battle_controls` `VmHWM` baselines. Before production assets are touched, add the permanent `operator_animation_smoke` scenario with seed 42, at most 30 model ticks, and `h.max_frames = 180` (`30 ticks × 120 Hz / 30 Hz + 60 slack`). Add `done_expected` and `done_called` to `report.json`. Amend `scenario_cmd` so this exact scenario receives shell timeout 10 while every incumbent scenario remains at 120. Immediately after each engine invocation, `verify.sh` requires a fresh parseable report with matching scenario, `result == "pass"`, `checks|length > 0`, `done_expected == true`, and `done_called == true`; a windowed report additionally requires `pixel_skipped|length == 0`. Execute `scripts/verify.sh --scenario=operator_animation_smoke` and require wall time below 15 seconds.

**Checks.** The source worktree is clean; no verifier is active; no path overlaps an active lease; `godot --headless --version` is 4.7.1; `gdlint --version` is 4.5.0; baseline `verify.sh` is green with evidence outside the worktree.

**Exit gate.** Baseline green, AUI-20 retirement cited, AUI-34 geometry adopted without reinterpretation, memory baselines recorded, trivial scenario green in under 15 seconds, and branch/worktree/lease recorded. Any red stops implementation.

### Phase 1 — Stage sources and enforce canon admission

**Work.** Copy all 40 source sheets and their original manifests into staging. Add the canon identity sidecar and a canonical packet name such as `protos-company33-operator-animation-v1`. Mark `Aetheria`, Vanguard, Bannerguard, Swiftblade, and Brandmaster as retired source labels retained only in provenance. Add a strict admission manifest per state family with `technical`, `agent_visual`, `human_visual`, `canon_fit`, and `runtime_binding` states.

**Checks.** Recompute every source SHA-256; require exactly five templates, two states, four directions, and 25 frames; reject unknown IDs/states/directions, duplicate directions, missing sheets, altered hashes, non-256 cells, and player-facing retired labels. A blocked family must be impossible to copy into `assets/**`.

**Exit gate.** All sources are reproducibly staged, the identity map validates, and exactly one current subject (`guard_1`) is eligible for human review while the four known blockers remain red.

### Phase 2 — Repair/regenerate blocked identities

**Generation packet.** Pre-stage one portable packet containing the exact accepted references, selected keyframes, action-lock files, canonical prompts, prompt/reference/action-lock SHA-256 values, job specs, prior video/source provenance, and a checksum manifest. First inspect the live generation catalog for `autosprite` and verify the active endpoint accepts the required job-set type. If available, run one cost-visible `video_tier=turbo`, `frame_size=256`, `with_sound=false`, smallest-adequate-frame-count canary for a complete state family; an estimation failure requires explicit paid-pilot approval, and `Job set type not supported` records zero jobs and ends that route without an identical retry.

Use manual video only when AutoSprite is unavailable, fails its canary, or lacks the required direction/state. Manual provider resolution follows the updated `/sprites-from-video` policy: Higgsfield MCP when enabled, otherwise the built-in Manus video tool. Preflight live schema, cost, balance, and media roles. The initial Higgsfield lane is `seedance_2_0_mini`, 480p, 16:9, four-second raw clip, first two seconds used, no audio, and one family-wide `CAPTURE_LOCK`: static orthographic/isometric camera, uniform `#D3D3D3` field, flat neutral lighting, no floor, no cast/contact shadow, no effects, and no camera motion. One model and one control set apply to all four directions in a state family. If the cheap family fails, retry the **whole family** once with the unchanged action lock and stricter capture lock; if it remains red, escalate/regenerate the **whole family** on `seedance_2_0` fast. Never mix cheap and premium directions inside one accepted family. Sword Saint reference generation uses GPT Image 2 and requires human reference approval before AutoSprite or video generation. Every stochastic call records provider, model/version, settings, job ID, prompt/reference hashes, output hash, and whether a seed was unavailable. Authentication, workspace, and credit balance are preflight prerequisites. If quota or account access blocks generation, emit a portable cross-account handoff ZIP; do not substitute an unrecorded provider.

**Work.** Correct the four blocked subjects without changing thresholds:

1. regenerate all four `vanguard_1/attacking` directions as one family from the accepted Shock Trooper reference and exact spear-thrust action lock;
2. deterministically remove only confirmed detached contact-shadow components from `vanguard_2/idle`; if silhouette pixels cannot be separated safely, regenerate all four idle directions as one family;
3. regenerate all four `vanguard_2/attacking` directions as one family under one banner-pole thrust contract;
4. create a canon-aligned sword-bearing `guard_2` reference, obtain human reference approval, then regenerate all eight Sword Saint sheets; and
5. remove only confirmed detached motion-arc components from `defender_1/attacking` SE/SW; if any component touches the character, shield, or hammer, regenerate all four attack directions as one family.

**Checks.** Rerun the exact technical gate and produce fresh 10-family contact sheets. Identity, prop persistence, facing, same-action family, stable framing, transparent background, loop boundary, and canon silhouette are independently failable checks. No generated family inherits a pass from an earlier file with a different hash.

**Exit gate.** 40/40 technical pass; 10/10 agent visual pass; 5/5 canon-fit pass; exact candidate contact sheets and their hashes presented to the human art owner. `human_final_art` remains `UNSET_HUMAN_ONLY` until explicit approval.

### Gate H — Human admission before production publication

The human art owner reviews the exact candidate contact sheets and records decisions in `staging/qa/character-vfx/operator-animation-v1/HUMAN-APPROVAL.json`. The canonical record contains the candidate pack SHA-256, all 40 sheet hashes, all 10 contact-sheet hashes, one `approved`/`rejected` decision per state family, the five class-level canon-fit decisions, reviewer identity supplied by the workflow, timestamp, and notes. The file is generated from the candidate inventory and becomes immutable after approval.

Partial approval is allowed only at the class boundary: both `idle` and `attack` families for a class must be hash-identically approved before that class can enter `assets/**`. Rejected or unreviewed classes stay in staging and keep the explicit legacy fallback. A canary may therefore continue with `guard_1` only after its two exact family hashes are human-approved. No Phase 3 runtime packet is published for an unapproved class.

### Phase 3 — Build deterministic runtime packets

**Work.** Extend the AUI-34 normalization seam or add a companion importer that supports 25-frame directional sheets without weakening the existing eight-frame fixture contract. Apply one template-wide scale derived from the pinned height table, then align each frame to x=96 and foot row 180. Produce separate logical atlases for each template/state/direction, canonical metadata, measured QA, contact sheets, and provenance.

The existing AUI-34 contract must remain byte-for-byte valid for its fixture. A new schema version or companion schema is safer than reinterpreting version 1.

**Checks.** Run importer tests and a Python/Godot decoded-RGBA differential for the new schema. Include source/output hash integrity, alpha binaryness, reserved-color exclusion, border clearance, foot-row tolerance, horizontal anchor, fixed frame count, alias normalization, stable height ordering, path containment, rollback/salvage, stale-output, corruption, zero-check, and timeout cases.

**Exit gate.** Every accepted runtime packet reopens and validates; same-backend cross-process bytes match; cross-backend decoded RGBA and semantic metadata match; blocked/rejected candidates still cannot publish.

### Phase 4 — Add presentation catalog and `OperatorAnimator`

**Work.** Keep `CharacterVisualDef` schema v1 unchanged. Add `OperatorAnimationDef` schema v1 with exact fields: `schema_version: int = 1`, `visual_id`, `idle_by_direction`, `attack_by_direction`, `idle_frame_count=24`, `attack_frame_count=13`, `fps=12.0`, `pivot`, `display_height_px`, `provenance_sha256`, and `placeholder`. Each direction dictionary must contain exactly `se`, `ne`, `nw`, and `sw`; every value is a nonempty manifest logical ID named `op_anim_<template>_<state>_<direction>`. Create a fail-closed `operator_visual_catalog` keyed by template ID that pairs the incumbent `CharacterVisualDef` with this companion resource. Unknown or missing schema versions, unknown/missing directions, duplicate logical IDs, missing manifest rows, unapproved hashes, or placeholder/final-state contradictions are red. Implement `OperatorAnimator` as a view-only projection analogous to `EnemyAnimator`, but with no faction palette path. It owns direction resolution, state resolution, frame selection, texture assignment, and source-to-display scaling.

Refactor `BattleView` narrowly:

- `_make_unit_node` asks `OperatorAnimator` to create the visual body;
- `_refresh_unit_sprite` delegates refresh and loses the legacy `flip_h` path for admitted four-direction assets;
- HP bar, SP bar, shadow, feet anchor, chevron, z-index, tracers, skill juice, and model reads remain in their existing seams; and
- templates without an accepted visual continue through the legacy manifest sprites with a truthful placeholder flag.

**Checks.** GUT exactness covers all four facing mappings, 24-frame idle wrap, 13-frame impact/recovery endpoints, `last_attack_tick=-1`, attack-window exit, state/direction logical IDs, display-height order, catalog validation, missing-row fallback, and a hash-equality assertion proving repeated animator refresh does not mutate the model.

**Exit gate.** L1 lint, GUT, manifest tests, catalog tests, and legacy fallback tests are green; no simulation/hash/save/replay files changed.

### Phase 5 — Rendered integration proof

**Work.** Add two bounded scenarios.

`operator_animation_catalog` renders each accepted template in a grid with four directional idle rows and four attack impact/recovery rows. Each cell labels template, state, direction, source frame index, and logical asset ID. The scenario samples frames 0, 6, 12, 18, and 23 for idle and source frames 12, 15, 18, 21, and 24 for attack, then captures fresh exact-candidate images. Seed is 42; maximum model ticks are 60; `h.max_frames = 300` (`60 × 120 / 30 + 60`). `scenario_cmd` assigns this exact scenario shell timeout 15.

`operator_animation_flow` drives a real battle: deploys operators with all four `UnitState.Facing` values, observes idle advancement, then steps one model tick at a time with the existing harness stepping helper until an authoritative `last_attack_tick` edge is observed or the fixed budget expires. It proves the first post-step observation is age 1, attack-frame progression reaches frame 12 by age 28, and age 30 is idle, then verifies HP/SP bars, shadow, chevron, tracer/skill effects, z-order, and fallback operators still render. Seed is 42; maximum model ticks are 600; `h.max_frames = 2,640` (`600 × 120 / 30 + 240`). `scenario_cmd` assigns this exact scenario shell timeout 45. Reaching the budget without the attack edge is an explicit failing check, never a timeout-driven pseudo-verdict.

**Checks.** Each scenario must call its completion sentinel and emit positive checks. The post-scenario verifier assertion reads the fresh report fields described in Phase 0. Headless runs prove only non-render logic; their `[SHOT-SKIPPED]`/`[PIXEL-SKIPPED]` records are expected and never counted as passes. Windowed reports alone must have an empty `pixel_skipped` array. Windowed pixel probes confirm nontransparent body pixels, distinct directional hashes, stable foot contact, no reserved-color collision, and attack/idle frame differences. The fresh windowed screenshots are inspected inline for identity, prop, facing, adult silhouette, relative height, tile readability, crop, and loop boundary.

**Exit gate.** Targeted headless logic and windowed render scenarios pass; windowed reports have zero pixel/render SKIPs; contact sheets and battle frames have fresh mtimes and exact candidate hashes; every admitted class has a human-verifiable screenshot.

### Phase 6 — Union verification and release

**Work.** Merge current master into the feature branch first if master advanced, resolve conflicts there, form the exact union, and run one clean RELEASE gate. Evidence remains physically outside the tested tree. A non-implementer audits the full diff against this plan and the lore bible.

**Required ladder, in canonical order.** L1 per-write parse and gdlint; L2 full headless GUT; L3 import plus boot; L4 seeded scripted scenarios in headless and windowed lanes; L5 agent reads fresh PNGs against falsifiable checklists and pixel probes; L6 standalone-green commit containing the feature and its exact artifacts; L7 human play on the published Web build. Repository replay, filesystem native/Web, bot differentials, memory gates, and provenance checks are additional requirements, not replacements or renumbered rungs.

**Integrity rules (verbatim).**

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

A hang, timeout, missing sentinel, stale artifact, dirty tested tree, zero tests, unexpected SKIP, or any windowed pixel/render SKIP is red. Expected headless shot/pixel SKIPs are recorded and never counted as passes. Lane green does not prove the merged union. The exact union is frozen before evidence is generated.

**Exit gate.** RELEASE green at the exact union hash; 10/10 family human approval; non-implementer diff-vs-pins audit clean; `FEATURES.json` evidence points to exact artifacts; branch pushed normally; master fast-forwarded and pushed without force.

## 7. Verification matrix

| Contract | Falsifiable proof | Failure owner |
|---|---|---|
| Canon identity | Required/retired-term lint plus identity-map validation | Staging/provenance |
| No fixed-hero implication | Resource and copy audit: class projection only; no hero names/callsigns | Presentation data |
| Source integrity | 40 exact SHA-256 checks against source manifest | Importer |
| Direction mapping | Exhaustive four-value GUT table | `OperatorAnimator` |
| Idle timing | Exact frames at 0, 1/12, 23/12, and 24/12 seconds | `OperatorAnimator` |
| Attack timing | Exhaustive ages 1–29 match the pinned 13-frame table; pure seam age 0 clamps to 0; real battle first observes age 1; idle at 30 | `OperatorAnimator` |
| Height order | Exact `[63,64,69,71,72]` table and rendered measurement | Visual catalog/importer |
| Model isolation | State hash before and after repeated refresh is identical | GUT |
| Manifest honesty | Missing/blocked/rejected logical IDs fail closed or use explicit legacy fallback | Manifest/catalog |
| Foot anchor | Opaque foot support intersects rows 179–181 in normalized frames | Importer QA |
| Background/alpha | Binary alpha, zero border contact, no detached residue | Importer QA |
| Runtime integration | Real-battle scenario observes idle → attack → idle on model edge | Harness |
| Render truth | Fresh windowed contact and battle images embedded before verdict | Harness/human |
| Regression | Existing full suite remains green; no scenario removed | `verify.sh` |

## 8. Non-goals

| Explicitly not in this package | Deferred target |
|---|---|
| New combat mechanics, attack wind-up state, or simulation timing | Separate gameplay RELEASE plan |
| Save/hash/replay schema changes | Separate determinism plan if ever required |
| Unique portrait-to-sprite identity for procedural recruits | Personnel/appearance system phase |
| Animations for `defender_2`, both snipers, both casters, or Witch Doctor | Follow-up roster-completion art phase |
| Movement, deploy, skill, hit, death, retreat, or promotion animations | Follow-up animation-state phases |
| Player-facing lore copy changes beyond class labels already present | Canon migration package |
| Approving art by agent verdict | Human art owner only |
| Reactivating AUI-20 or reusing its historical fixture authorization as runtime authority | Forbidden; AUI-20 remains retired and supplies no contract to extend |
| Replacing or weakening the AUI-34 normalization contract | Forbidden; extend only through a versioned or companion AUI-34 seam |

## 9. Trim order and never-cut list

If schedule or memory pressure requires scope reduction, trim in this order:

1. defer nonessential contact-sheet labels and presentation polish;
2. continue one human-approved canary class (`guard_1`) only as a non-release branch experiment while preserving explicit legacy fallback for the other four; this cannot set `FEATURES.json` passing, close TD-025, publish to master, or satisfy the 10/10 RELEASE gate;
3. defer catalog-wide rendered coverage for blocked classes, but keep all admission tests; and
4. defer runtime lazy-loading optimization after measuring memory, never before.

Never cut canon reconciliation, provenance, human approval, all-four-direction coverage, exact attack/idle timing tests, model-isolation proof, fallback truthfulness, fresh windowed evidence, full union verification, or the non-implementer audit.

## 10. Resume protocol

A resumed session reads, in order: the current lore bible, this plan, repository-relative `docs/decisions/AUI-20-RETIREMENT.md`, repository `CLAUDE.md`, `docs/todo.md`, `FEATURES.json`, baseline stdout [2], and baseline report [13]. The AUI-20 fixture-authorization and rebase decisions are historical-only and never runtime authority. A later receipt may supersede [2]/[13] only through one unique machine-readable pointer containing the exact commit, lane, absolute external paths, and SHA-256 values; missing, ambiguous, or hash-mismatched pointers are red. The session then fetches all refs, verifies the worktree and lease, confirms no verifier is active, and checks that source and runtime asset hashes still match the recorded provenance. Any mismatch or ambiguous impact remains on the RELEASE route and blocks continuation until reconciled.

## 11. Decision summary

1. The five generated figures are class combat projections, not a fixed hero roster.
2. Active player-facing names are Shock Trooper, Banner Guard, Swordmaster, Sword Saint, and Defender.
3. Only Swordmaster is presently eligible for human art approval; the other four need correction or regeneration.
4. The axe-bearing `guard_2` is not Sword Saint and must be regenerated, not relabeled.
5. Runtime animation remains view-only and derives attack timing from existing `last_attack_tick`.
6. Implementation records AUI-20 retirement, extends AUI-34 through a versioned contract, and uses RELEASE assurance.
7. The game keeps legacy sprites as explicit placeholders until each class passes technical, visual, canon, and human gates.

## References

[1]: /home/ubuntu/projects/manus-game-studio-c54b05a0/Protos-World-and-Lore-Bible.md "Protos — World and Lore Bible, version 3.3; SHA-256 da442ced518da9d4690e2dcb381120bb17aaf9d822ffc71b016ff74762e3e2aa"
[2]: /home/ubuntu/mgs-state/prototype-td/agent-5/td-025-operator-animations/a26969770a5ed57206d0751c1d0f757ac576f733/standard.log "Protos clean STANDARD baseline at a269697; SHA-256 95ada7176b9d1f5579740f7d92095f897e397af5cdecf2efef943302de673389"
[3]: /home/ubuntu/aetheria-40-sprite-sheets-technical-pass-manual-review/MANIFEST.json "Generated 40-sheet source manifest; SHA-256 b6c430b8079476843df6e3bd7559216b635d25cb42bf463c1f49e6101e674af0"
[4]: /home/ubuntu/aetheria-video-sprites/VISUAL-QA-REPORT.md "Generated sprite visual QA report; SHA-256 c846b791a03b31bdd29618adc18f0a5f3c07d52ba7f59432c1c049c3a61934b1"
[5]: /home/ubuntu/aetheria-video-sprites/PROTOS-IDENTITY-MAP.json "Protos canon identity reconciliation sidecar; SHA-256 82f5ab1b76718e2bfb4ed00148a9a5a659c7ca0ed80f901c17d6e7492c56c025"
[6]: repo `a26969770a5ed57206d0751c1d0f757ac576f733:docs/decisions/AUI-20-RETIREMENT.md` "blob 72a6fee2aeeb07106b9605728e20b13c52cb2475; SHA-256 f7fb6a7d44b159b45f13e793fdf3190d14607da4deec809a04baaf680e5d049e"
[7]: /home/ubuntu/sprite-pack/manifest.json "Approved front-facing reference geometry and height order; SHA-256 7528ebdc34aaac5318be0d4da60a92b8f763f709842d26800efbbf10e065ea20"
[8]: repo `a26969770a5ed57206d0751c1d0f757ac576f733:docs/art/character-vfx/AUI-34-pipeline-contract.md` "blob 1506f4dc47714a05d35e3bdb38b04a859960e0b1; SHA-256 b4958569c4d201f54fe1b1fd7bd25a18ca41d5594705ffb467fc55f493130614"
[9]: repo `a26969770a5ed57206d0751c1d0f757ac576f733:docs/decisions/AUI-ROUND5-RUNTIME-BINDING.md` "blob 96a32e6268f6758660cdd2956f93a846f41a10f3; SHA-256 ea503dba5c14b9b966d18d3dda6e0325b0d1b28aed540401311bf23b89a04f4e"
[10]: repo `a26969770a5ed57206d0751c1d0f757ac576f733:scripts/view/battle_view.gd` "blob 138c660b4054597234e336b00216157108e0e526; SHA-256 d12711cbbbb9fe874dae48ef607687fab7e82759f04ff039fe954dcda0772bb8"
[11]: repo `a26969770a5ed57206d0751c1d0f757ac576f733:data/presentation/character_visual_def.gd` "blob 154fcccb92c51bd4fcd6b4d6b80058558b3378ea; SHA-256 e3f0d8a954c84007688d7e12233847e6b1b313a05ff301c0b3ae8d3087310b80"
[12]: /home/ubuntu/aetheria-video-sprites/FINAL-SHEET-GEOMETRY.json "Measured animated-sheet geometry report; SHA-256 8a0d32b03dc4d235479d385475f9198f3cc4f5df8f29b37a018cb1ecc160fbc1"
[13]: /home/ubuntu/mgs-state/prototype-td/agent-5/td-025-operator-animations/a26969770a5ed57206d0751c1d0f757ac576f733/evidence/verify.json "Protos clean STANDARD baseline report at a269697; SHA-256 36af546e8c8a2331dd23bb401629668ec9fbf377530155db75bbcf3037fb31f3"
