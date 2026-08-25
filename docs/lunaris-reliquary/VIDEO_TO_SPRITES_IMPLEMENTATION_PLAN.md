# Lunaris Video-to-Sprites Production Assessment and Implementation Plan

**Author:** Manus AI
**Repository:** `https://github.com/junnyboi/proto-td`
**Assessed revision:** `653f51b65ecb311f147d0ca22dec0f1301e7a2ba`

## Executive summary

The repository contains a complete, production-grade reference package for the three **Lunaris Reliquary** premium heroes under `docs/lunaris-reliquary/`. Each character has a 1632×2176 full-figure PNG and a matching 1632×2176 chibi PNG on a plain white background. Every pair includes the complete signature weapon or focus, multiple full-body views, and construction callouts. The files match the repository’s recorded SHA-256 checksums.

All six boards are strong **reference images**, but none is suitable as a direct video keyframe because each board contains multiple figures and detail callouts. The correct `/video-to-sprites` workflow is to supply the matching full-size and chibi boards to **GPT Image 2**, generate one clean single-character chroma keyframe for each required isometric direction, and then use that keyframe to condition a locked-camera video carrier.

The game already has a directional operator-animation architecture. Runtime towers use four isometric directions—`NE`, `NW`, `SE`, and `SW`—with 24-frame looping idle strips and 13-frame non-looping attack strips at 12 FPS, using 192×192 cells and a bottom-center pivot near `(0.5, 0.94)`. Premium heroes currently reuse `caster_2`, `guard_2`, and `caster_1` visuals; the implementation should override presentation by the premium hero’s unique portrait identity while leaving deterministic combat behavior unchanged.[1] [2] [3]

> **Approved production scope:** generate `NE` and `SE` for `idle` and `attack`, then horizontally mirror them into `NW` and `SW`. This produces **12 video carriers and 24 runtime sprite strips** across the three heroes. The user explicitly approved the left/right costume and equipment inversion on 2026-08-25 to reduce generation count.

## Repository findings

### Canonical character package

The faction-specific folder contains exactly three full-size/chibi pairs documented as the launch premium ensemble.[4]

| Premium ID | Full-size reference | Chibi reference | Signature equipment | Production finding |
|---|---|---|---|---|
| `lunaris_vessel` | `lunaris_vessel_design_sheet.png` | `lunaris_vessel_chibi_sheet.png` | **Crescent Reliquary** orbital lunar-ring focus | Complete weapon, front/casting/rear views, braided-crown and mechanism callouts |
| `reliquary_duelist` | `reliquary_duelist_design_sheet.png` | `reliquary_duelist_chibi_sheet.png` | **Jade Meridian** straight spellblade | Complete sword, neutral/combat/rear views, ponytail, bracer, harness, and blade callouts |
| `archive_caster` | `archive_caster_design_sheet.png` | `archive_caster_chibi_sheet.png` | **Archive Astrolabe** orbital ritual focus | Complete focus, neutral/casting/rear views, curled-bob, translucent panel, mechanism, and footwear callouts |

Each image is an RGB PNG measuring **1632×2176**. The sheets follow the project’s adult-chibi standard: approximately three to four heads tall, mature facial and costume cues, enlarged hands/feet/equipment, and preserved high-rarity silhouettes.[5] The repository’s original generation record confirms that GPT Image 2 created the boards and establishes the matching full-size sheet as the primary identity reference and the chibi sheet as the chibi-scale reference.[6]

### Character-specific animation assessment

| Character | Stable animation anchors | Proposed idle | Proposed attack | Mirroring assessment |
|---|---|---|---|---|
| **Lunaris Vessel** | Champagne braided-crown hair, long hair mass, asymmetric ivory/violet mantle and sleeve, gold/cyan hip mechanism, large circular Crescent Reliquary | Restrained breathing, gentle hair and mantle settle, slow controlled ring orbit, stable feet | One deliberate Crescent Reliquary expansion and moon-cyan discharge gesture, followed by controlled recovery | **Unsafe by default.** Mirroring swaps the asymmetric sleeve/mantle, hip mechanism, and focus-control side |
| **Reliquary Duelist** | Mature angular face, high black ponytail, exposed arms, dark-teal long panels, gold harness/bracers, long cyan-edged Jade Meridian | Guarded breathing, slight ponytail and coat-panel settle, blade held under control | One concise diagonal spellblade cut with readable anticipation, contact pose, follow-through, and recovery | **Unsafe by default.** Mirroring swaps canonical sword handedness and asymmetric harness/panel details |
| **Archive Caster** | Silver-lilac curled bob, black-plum fitted silhouette, translucent gold-edged panels, hip ornaments, circular Archive Astrolabe | Subtle breathing, panel drift, restrained Astrolabe rotation, stable operating hand | One precise Astrolabe expansion/rotation and focused moon-cyan casting pulse, followed by recovery | **Unsafe by default.** Mirroring swaps the operating hand, asymmetric dress/cape geometry, ornaments, and focus relationship |

All three sheets visibly include weapons and accessories, so no additional equipment design is required before animation. The full-size and chibi boards should always be used together for GPT Image 2 keyframes: the full-size image protects adult identity, anatomy, costume construction, and equipment geometry; the chibi image protects proportions, simplification, and game-scale silhouette.

## `/video-to-sprites` test result so far

The new skill’s deterministic preprocessing stage was run directly against the production sheets. It successfully read all six images and selected chroma backgrounds using the maximum 10th-percentile RGB distance from visible character pixels.

| Character | References tested | Selected chroma | Pink distance score | Green distance score | Result |
|---|---|---:|---:|---:|---|
| Lunaris Vessel | Full-size + chibi | Neon green `#00FF00` | 203.155 | **216.603** | Use neon green |
| Reliquary Duelist | Full-size + chibi | Hot pink `#FF00FF` | **217.702** | 211.722 | Use hot pink |
| Archive Caster | Full-size + chibi | Neon green `#00FF00` | 200.402 | **216.631** | Use neon green |

This validates the skill’s **reference inspection and automatic chroma-selection path** on real production art. The video-generation portion was approved as a Lunaris Vessel `NE idle` pilot, with `NW` derived by mirroring. The approved payload appears below.

## Recommended pilot test

Use **Lunaris Vessel, NE-facing idle** as the first production test. It is the five-star flagship, has the most demanding long-hair and circular-weapon silhouette, and therefore exercises identity preservation, alpha extraction, fixed framing, and oversized-equipment bounds more aggressively than a simpler character would.

| Field | Pilot value |
|---|---|
| References | `lunaris_vessel_design_sheet.png` + `lunaris_vessel_chibi_sheet.png` |
| Character | `lunaris_vessel` |
| Equipment | Crescent Reliquary retained and fully visible |
| Facing | `NE`, matching the runtime isometric direction contract |
| Action | `idle` |
| Keyframe model | GPT Image 2 |
| Chroma | Neon green `#00FF00` |
| Video model | Veo 3.1, because the idle needs identical first/last keyframes |
| Carrier | 4 seconds, 720p, landscape, audio disabled |
| Camera | Locked; no movement, shake, zoom, reframing, or perspective change |
| Master extraction | 48 transparent lossless WebP frames under the 854×480 processing ceiling |
| Runtime derivative | 24 frames at 12 FPS, packed into 192×192 WebP cells |
| Mirrored derivative | `NW idle`, horizontally mirrored from the generated `NE idle` sequence |
| Output location during pilot | Outside the repository until the asset passes review |

The pilot should stop after delivering the chroma keyframe, MP4 carrier, 48-frame transparent master, runtime 24-frame strip, JSON manifests, and atlas preview. No repository integration should occur until the final sheet is visually approved.

### Completed pilot outcome

The approved Vessel `NE idle` pilot completed outside the repository. GPT Image 2 produced a 2560×1440 chroma keyframe; Veo 3.1 produced a valid four-second 1280×720, 24 FPS, silent carrier; and the corrected processor produced 48 NE master frames plus 48 pixel-exact mirrored NW frames. A pilot-only runtime conversion proved 24-frame, 12 FPS, 192×192 strips with zero clipped alpha bounds and zero mirror mismatches.

The first production extraction revealed that Euclidean RGB chroma distance retained model/compression-blended green and magenta edge pixels. The global `/video-to-sprites` processor was hardened through the skill-creator workflow to measure the actual encoded carrier chroma and combine distance alpha with channel-dominance recovery. Its complete synthetic-video regression suite and official skill validation pass after the correction. The remaining skill work is the reusable fixed-cell Godot output profile described in Phase 1.

## Production generation matrix

### Directions

The battle renderer maps authoritative cardinal facings into four isometric visual directions: right→`SE`, down→`SW`, left→`NW`, and up→`NE`.[2] The production set therefore requires `NE`, `NW`, `SE`, and `SW` for every action.

The approved package follows `/video-to-sprites` direction optimization: generate `NE` and `SE`, then derive `NW` and `SW` by horizontal mirroring. All three heroes have handed equipment and visibly asymmetric garments, mechanisms, ornaments, or hair construction, so mirrored west-facing assets intentionally invert those details. The user explicitly accepted this visual tradeoff to reduce video generation from 24 carriers to 12. Simulation geometry, target selection, hitboxes, and combat outcomes remain unaffected because the change is presentation-only.

### Actions — stationary tower contract

The complete animation scope for this game is **idle and attack only**. Deployed characters are stationary towers: they never walk or run, and the current renderer has no separate deploy or skill-animation consumer. Do not generate locomotion, deploy, skill, hit, death, or victory carriers unless a future approved renderer contract adds those states.[3]

| Character | Generated directions | Mirrored directions | Actions | Video carriers | Runtime strips |
|---|---|---|---:|---:|
| Lunaris Vessel | NE, SE | NW from NE; SW from SE | idle, attack | 4 | 8 |
| Reliquary Duelist | NE, SE | NW from NE; SW from SE | idle, attack | 4 | 8 |
| Archive Caster | NE, SE | NW from NE; SW from SE | idle, attack | 4 | 8 |
| **Total** | 6 generated directional sets | 6 mirrored directional sets | 6 action families | **12** | **24** |

Six direction-specific GPT Image 2 keyframes are sufficient: one neutral `NE` and one neutral `SE` pose for each character. Each can serve as the idle first/last frame and attack first frame; the processed `NW` and `SW` sequences are deterministic mirrors. Generate the six keyframes in three character batches while preserving the matching full-size and chibi reference pair.

## Media-production specification

### Keyframe generation

Generate one isolated, full-body, single-character keyframe for `NE` and one for `SE` per character. Use a landscape 16:9 canvas with generous weapon clearance, a perfectly flat approved chroma background, a constant isometric three-quarter view, bottom-center ground contact, and no floor shadow. Preserve the exact chibi style, mature identity, costume asymmetry, signature weapon, and equipment handedness in generated east-facing masters.

The generated `NE` view should reveal more rear/upper construction while remaining readable as a tower sprite; its mirror becomes `NW`. The generated `SE` view should expose the front and weapon action; its mirror becomes `SW`. Camera elevation and character scale must be identical across both generated directions, and mirrored derivatives must preserve the same dimensions, pivot, alpha, timing, and frame order.

### Video routing

| Action | Model | Keyframe policy | Motion policy |
|---|---|---|---|
| Idle | Veo 3.1 | Same approved image as first and last keyframe | One seamless four-second cycle; feet and root locked; restrained secondary motion only |
| Attack | Gemini Omni Flash Preview | Approved directional image as first keyframe | Complete anticipation, strike/cast, contact, follow-through, and recovery during the first runtime window; remain neutral afterward |

Every clip must be 720p with audio disabled. The prompt must explicitly forbid camera movement, shake, parallax, perspective drift, cuts, reframing, duplicate characters, extra props, scenery, shadows, particles, text, and weapon clipping.

### Master and runtime frame profiles

The `/video-to-sprites` default remains the archival master: 48 transparent WebP frames sampled from a four-second carrier at the 480p processing ceiling. The repository runtime uses a stricter profile and should consume derived strips rather than the raw master.

| Family | Archival master | Runtime derivative | Rationale |
|---|---|---|---|
| Idle | 48 lossless WebP frames | 24 frames at 12 FPS | Matches the existing two-second looping idle contract exactly |
| Attack | 48 lossless WebP frames | 13 frames at 12 FPS, selected from the authored attack window | Matches the current non-looping attack window and avoids changing combat-presentation timing |

Extend the global processor with an optional **Godot operator profile** before mass production. The profile should support a temporal window, explicit runtime frame count, fixed 192×192 cells, bottom-center alignment, normalized subject-height fitting, lossless WebP strip output, and manifest metadata. The tight union crop remains useful for masters, but runtime frames must be placed into identical fixed cells to prevent visual jitter and satisfy the art-manifest contract.

## Godot integration design

### Asset layout

Store production strips under stable premium identities rather than the reusable combat operators:

```text
assets/sprites/operators/animated/lunaris_vessel/
  idle_ne.webp  idle_nw.webp  idle_se.webp  idle_sw.webp
  attack_ne.webp attack_nw.webp attack_se.webp attack_sw.webp
assets/sprites/operators/animated/reliquary_duelist/
  ...
assets/sprites/operators/animated/archive_caster/
  ...
```

Keep carrier MP4s, 48-frame masters, per-frame WebPs, source keyframes, and processing manifests under a documented source-art directory rather than packaging all intermediates into the runtime export. The game repository should include only the approved runtime strips, integration metadata, and concise generation records unless long-term source retention is explicitly desired.

### Presentation-only identity override

Premium heroes currently preserve unique `portrait_asset_id` values in `UnitState`, while the combat operator remains `caster_2`, `guard_2`, or `caster_1`.[1] Update the view-only template resolver so these portrait identities select the premium visual template before falling back to `u.op_id`:

| Portrait identity | Premium visual template | Existing combat operator |
|---|---|---|
| `portrait_lunaris_vessel` | `lunaris_vessel` | `caster_2` |
| `portrait_reliquary_duelist` | `reliquary_duelist` | `guard_2` |
| `portrait_archive_caster` | `archive_caster` | `caster_1` |

This avoids modifying battle tickets, save schemas, simulation hashes, premium lifecycle rules, or deterministic combat. The change remains a pure presentation projection, consistent with the existing architecture.[1] [2]

### Catalog and manifest changes

For each premium identity:

1. Add an `OperatorAnimationDef` resource with four idle IDs, four attack IDs, 24 idle frames, 13 attack frames, 12 FPS, `(0.5, 0.94)` pivot, calibrated display height, and `placeholder=false`.
2. Register the definition in `OperatorVisualCatalog.DEFINITIONS`.
3. Add eight logical rows to `assets/manifest.tres`, each using a 192×192 cell, lossless WebP strip path, correct loop flag, and exact frame count.
4. Confirm `Art.texture()` loads imported WebP strips. Generalize the source-file fallback from PNG-only to PNG/WebP so focused tests also work when the Godot import cache is absent.[7]
5. Add a generation manifest containing source-sheet hashes, keyframe hashes, carrier hashes, selected chroma, model, prompt, runtime profile, and strip hashes.

## Phased implementation plan

### Phase 0 — Confirm and execute the pilot — complete and approved

Generate the Lunaris Vessel `NE idle` keyframe and carrier outside the repository. Process the result into a 48-frame transparent master and a 24-frame, 192×192 runtime strip. Inspect identity, weapon bounds, root lock, camera lock, loop seam, alpha edge, chroma spill, and small-scale readability. Tune the Godot output profile only from observed pilot requirements.

**Gate result:** Passed technical extraction, alpha, frame, mirror, and runtime-cell checks. The pilot preserves the approved character and Crescent Reliquary, remains planted and readable at tower scale, and contains no clipped alpha bounds. The user approved the pilot preview and NE→NW mirror on 2026-08-25 for repository integration.

### Phase 1 — Harden the reusable processor

Using the `skill-creator` update workflow, add temporal-window resampling and a fixed-cell Godot operator output profile to the global `/video-to-sprites` skill. Add synthetic regression fixtures for 48→24 idle conversion, attack-window→13 conversion, 192×192 placement, bottom-center pivot stability, lossless WebP alpha, multi-page atlas behavior, and JSON schema validity.

**Gate:** Official skill validation and end-to-end synthetic video tests pass. This phase changes the Manus-level skill, not the game repository.

### Phase 2 — Produce and integrate Lunaris Vessel

Reuse the approved Vessel `NE idle` keyframe, carrier, master, and `NE`/`NW` runtime strips. Generate one clearly front-biased `SE` keyframe, then generate only the three missing carriers: `SE idle`, `NE attack`, and `SE attack`. Derive `NW attack`, `SW idle`, and `SW attack` by deterministic horizontal mirroring. The completed Vessel set contains exactly four idle strips and four attack strips—no locomotion or auxiliary state. Add the Vessel visual resource, catalog entry, manifest rows, presentation-only premium resolver, generation record, and focused tests before changing any other character.

**Regression and delivery gate:** Run the premium animation tests, art-manifest validation, direct Godot import, bounded headless boot, relevant premium hero/UI tests, and Xvfb battle verification in landscape and portrait. Re-fetch `origin/master`, rerun affected gates if the revision moved, commit, and push to `master` without rewriting history.

### Phase 3 — Produce and integrate Reliquary Duelist

Generate the Duelist `NE` and `SE` keyframes and four carriers with explicit sword-handedness and Jade Meridian bounds. Tune attack timing around the melee strike while leaving authoritative hit timing unchanged, derive `NW` and `SW` by mirroring, and record the approved handedness inversion in the asset manifest. Add the Duelist visual resource and manifest rows.

**Regression and delivery gate:** Verify all four facings, sword clearance, attack synchronization, existing Vessel visuals, premium lifecycle tests, import, bounded boot, Xvfb battle screenshots, error scans, then fetch, commit, and push to `master`.

### Phase 4 — Produce and integrate Archive Caster

Generate the Caster `NE` and `SE` keyframes and four carriers with stable Astrolabe geometry, controlled ring motion, readable translucent panels, and no chroma erosion. Derive `NW` and `SW` by mirroring and add the Caster visual resource and manifest rows.

**Regression and delivery gate:** Verify all four facings, Astrolabe clearance, alpha quality around translucent panels, existing Vessel/Duelist visuals, premium tests, import, bounded boot, Xvfb battle screenshots, error scans, then fetch, commit, and push to `master`.

### Phase 5 — Full release validation and Web deployment

Run the complete repository test suite, direct import, bounded boot, and final Xvfb scenarios showing all three premium towers attacking in each available facing at landscape and portrait resolutions. Scan logs for script, resource, renderer, manifest, and fatal errors. Re-fetch and integrate concurrent `master` work before the final run.

Export the existing non-threaded Godot 4.7.2 Web preset and require HTML, JavaScript, WebAssembly, and PCK artifacts. Record checksums, serve the bundle over HTTP, inspect network and browser console output, update the existing `proto-td-web` fullscreen host, run TypeScript and production builds, verify desktop and mobile viewports, save a WebDev checkpoint, and publish through the available deployment route.

**Gate:** GitHub `master`, the verified Web bundle, and the WebDev preview all represent the same revision and contain all three premium animation sets without regression.

## Test plan

### Focused deterministic tests

Add a dedicated `premium_operator_animation_test.gd` covering the following contracts:

| Contract | Assertion |
|---|---|
| Identity mapping | Each premium portrait resolves to its unique premium visual template |
| Simulation isolation | Nonpremium users of `caster_1`, `caster_2`, and `guard_2` retain their existing visuals |
| Direction mapping | RIGHT/DOWN/LEFT/UP resolve to SE/SW/NW/NE |
| Catalog completeness | Three premium definitions validate with unique visual IDs |
| Frame contract | Idle=24, attack=13, FPS=12, cell=192×192, four exact directions |
| Production status | Every premium row has `placeholder=false` and valid logical IDs |
| WebP loading | Every frame resolves to a non-null texture after direct import |
| Pivot consistency | Every strip uses the same intended normalized pivot |

### Visual acceptance matrix

Capture representative frames for all three heroes in landscape and portrait. Force or script each facing direction and trigger an attack. Inspect at least the neutral idle, anticipation, impact/cast, recovery, and loop boundary.

| Acceptance area | Required result |
|---|---|
| Identity | Face, hair, costume, palette, and mature chibi characterization remain canonical |
| Equipment | Crescent Reliquary, Jade Meridian, and Archive Astrolabe remain complete and coherent |
| Camera | No pan, zoom, shake, orbit, reframing, or perspective drift |
| Root stability | Feet/tower origin stay locked; no unintended translation |
| Bounds | No hair, garment, limb, blade, ring, chain, or hanging weight is clipped |
| Alpha | Background is fully transparent with no destructive holes or prominent chroma fringe |
| Direction | View and equipment handedness match the requested NE/NW/SE/SW asset |
| Timing | Idle loops cleanly; attack is readable and returns to idle without a stuck pose |
| Scale | All three heroes occupy comparable gameplay height without oversized weapon collisions |
| Performance | No repeated texture-load errors, atlas dimension failures, or Web export regressions |

## Risks and mitigations

| Risk | Consequence | Mitigation |
|---|---|---|
| Multi-pose boards confuse the video model | Duplicate characters or blended poses | Generate one isolated GPT Image 2 keyframe first; never pass the raw board directly as the video first frame |
| Long hair and large weapons exceed the cell | Clipping or tiny body scale | Use generous keyframe margins, fixed union bounds per sequence, and calibrated subject height within 192×192 |
| Direction mirroring reverses design canon | West-facing weapon hand and costume layout are inverted | The user explicitly approved this presentation tradeoff; record `mirrored_from` metadata and verify exact deterministic NE→NW and SE→SW correspondence |
| Cyan glow approaches green chroma | Alpha erosion on energy components | Use automatic per-character chroma; Vessel/Caster use neon green only after inspection, and tune tolerance against cyan cores before batch processing |
| Transparent ritual panels key poorly | Ragged alpha or holes | Test Archive Caster separately, lower tolerance if necessary, and preserve a soft feather with spill decontamination |
| Four-second default conflicts with runtime timing | Idle/attack animation runs at the wrong duration | Retain 48-frame masters but derive 24-frame idle and 13-frame attack strips at the current 12 FPS runtime contract |
| Premium identity is not an operator ID | Existing operators receive the wrong art | Resolve the premium visual from the unique portrait identity in the view layer; keep the authoritative operator ID unchanged |
| Concurrent agents move `master` | Assets or manifests deploy from stale code | Fetch before every phase and immediately before final validation; only fast-forward shared history |

## Acceptance criteria

The feature is complete when all three premium heroes use unique production chibi tower art rather than the reused `caster_1`, `caster_2`, and `guard_2` presentation; every hero has generated `NE`/`SE` and mirrored `NW`/`SW` **idle and attack only** strips; no locomotion or unsupported auxiliary animations are generated or registered; every runtime strip is lossless WebP with 192×192 cells, exact frame counts, stable pivot, transparent background, correct `mirrored_from` provenance, and no placeholder flag; premium combat behavior, saves, hashes, lives, pity, classes, and operators remain unchanged; all focused and repository-wide tests pass; Xvfb and browser verification show correct animations in landscape and portrait; and GitHub, Web export, and WebDev deployment use the same final revision.

## References

[1]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/docs/PREMIUM_HERO_SYSTEM.md "Premium Hero and Gacha System"
[2]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/scripts/view/operator_animator.gd "OperatorAnimator directional and frame contract"
[3]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/data/presentation/operator_animation_def.gd "OperatorAnimationDef schema"
[4]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/docs/LUNARIS_CHARACTER_DESIGNS.md "Lunaris Reliquary launch character designs"
[5]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/docs/ART_DIRECTION.md "Protos visual art direction"
[6]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/docs/lunaris-reliquary/GENERATION_PROMPTS.md "Lunaris character-sheet generation record"
[7]: https://github.com/junnyboi/proto-td/blob/8cecde1bb4fcee44bd25cd47997f64c0cbcb9f37/scripts/view/art.gd "Runtime art loader"
