# Advanced Operator Sprite Implementation Plan

**Repository:** `/home/ubuntu/workspace/proto-td`  
**Source-art archive:** `/home/ubuntu/projects/proto-td-1515240c/advanced-operator-sprites-sources`  
**Prepared against revision:** `662e71c2c85e36e1d902f78b812177cec99dec2b`  
**Inputs:** the eleven briefs in `docs/operator-specializations/design-briefs/`, the four faction concept boards in `docs/Faction - *.webp`, the current recruit animation sets, and the current Godot presentation catalog.

## Execution status

As of the release candidate prepared on 2026-08-27, Phases 0–7 are complete: the immutable archive contains 22 approved GPT Image 2 gender references, 44 NE/SE directional keyframes, and 88 silent four-second carriers; the runtime contains 176 validated atlases and 22 generated visual definitions. Premium portrait precedence, canonical `class_id` routing, deterministic presentation gender, classless legacy fallback, 640px row-major slicing, generated-cache release, serialized manifest schema 3, and registration idempotency are covered by focused regressions. The 11-class Xvfb matrix is visually accepted after a frame-metric sweep found and deterministically repaired three isolated keyed-collapse samples. The reconciled native candidate passed the full 68-gate repository baseline plus a 16-gate focused pass after a second upstream merge. Phase 8 remains open until the exact-revision source push, Web export/HTTP/browser checks, and a new `proto-td-web` checkpoint all pass.

## 1. Objective and non-negotiable scope

This work replaces generic operator-ID presentation reuse with complete, class-specific animation for every **recruit-derived, non-premium specialization**. Each of the eleven classes receives a clearly adult male variant and a clearly adult female variant. Both variants use the same class equipment, gameplay footprint, reach, effect origin, timing, and screen-space authority; gender is an identity presentation attribute, never a combat attribute.

These designs must remain **materially more restrained than premium heroes**. Their quality comes from mature anatomy, decisive silhouettes, readable faction color blocking, coherent issued equipment, and polished motion—not named relic density, couture layering, chains, jewelry, orbiting mechanisms, capes, asymmetric narrative artifacts, micro-filigree, or spectacular multicolor effects. Advanced classes may look promoted and better equipped, but they remain standardized field operators rather than collectible heroes.

The implementation is presentation-only. It must not alter `OperatorDef`, class promotion rules, battle tickets, save formats, premium pity or life rules, model ticks, targeting, hitboxes, attack intervals, damage resolution, simulation hashes, replay semantics, or authoritative `UnitState` mutation. Existing premium portrait mappings remain the highest-priority visual override.

## 2. Complete class and adult-variant roster

The table below is the binding roster. “Male” and “female” identify two separate production variants and therefore enumerate **22 variants in total**.

| # | Class ID / class | Stage and role | Adult male variant | Adult female variant | Restrained class read and current operator fallback |
|---:|---|---|---|---|---|
| 1 | `defender` — **Defender** | Stage 1; Lane Anchor | Mature broad-necked, square-jawed adult with compact brushed-back hair; issued armor and centered two-handed pavise | Mature athletic adult with oval-angular face and centered low braided knot; identical armor coverage, shield authority, reach, and timing | Solcrest ivory/brass/teal ward infantry; one centered Sunbar Ward-Pavise; fallback `defender_1` |
| 2 | `gunner` — **Gunner** | Stage 1; Ranged Marksman | Mature compact-athletic adult with defined jaw and short centered swept-back crest | Mature athletic adult with centered low knot and balanced temple locks; no skirt, heel, jewelry, or reduced weapon scale | Vesper midnight/navy/wine/cyan relay uniform and one symmetric Signal Railbow; fallback `sniper_1` |
| 3 | `mage_apprentice` — **Mage Apprentice** | Stage 1; Arcane Attacker | Mature lean-athletic adult with defined jaw and center-parted hair in a compact symmetric nape tie | Mature poised adult with center-parted jaw-length bob tucked evenly behind both ears | Practical Lunaris academy uniform and one Standard Lunar Conduit Staff; fallback `caster_1` |
| 4 | `shock_trooper` — **Shock Trooper** | Stage 1; Fast Vanguard | Mature compact-athletic adult with broad upper torso and short brushed-back crop | Mature compact-athletic adult with strong legs and centered braided knot or low bun | Simplified Crimson Aegis line kit and one centered service shock pike; fallback `vanguard_1` |
| 5 | `swordmaster` — **Swordmaster** | Stage 1; Melee Striker | Mature compact-athletic adult with squared shoulders and short balanced swept-back hair | Mature athletic-powerful adult with balanced collar-length cut gathered at center | Entry-grade Crimson Aegis armor and one two-handed Breachline Longblade; fallback `guard_1` |
| 6 | `immovable` — **Immovable** | Stage 2; Fortress Defender | Mature broad athletic veteran with firm jaw and short symmetrical practical hair | Mature strongly planted adult with angular-oval face and compact symmetric bob or centered low bun | Promoted Solcrest Dawnwall harness and one Gatebar Ward-Maul; fallback `defender_2` |
| 7 | `sniper` — **Sniper** | Stage 2; Long-Range Marksman | Mature lean-athletic adult with level shoulders and short balanced cool-black hair | Mature poised adult with evenly tucked ash-brown blunt bob | Polished but non-premium Vesper precision kit and one Relay Longbow; fallback `sniper_2` |
| 8 | `sorcerer` — **Sorcerer** | Stage 2; Area Spellcaster | Mature lean-athletic adult with defined jaw and short centered brushed-back hair | Mature athletic-statuesque adult with center-parted blunt bob tucked evenly behind both ears | Standardized Lunaris field-reliquary uniform and one centered Convergence Orrery; fallback `caster_2` |
| 9 | `witch_doctor` — **Witch Doctor** | Stage 2; Combat Medic | Mature compact-athletic adult with square jaw and short near-symmetric hair inside a teal cowl | Mature athletic adult with defined cheekbones and centered jaw-length blunt bob inside the same cowl | Solcrest field medic kit and one Concord Ward Censer; fallback `witch_doctor_1` |
| 10 | `banner_guard` — **Banner Guard** | Stage 2; Support Vanguard | Mature broad line-infantry adult with defined jaw and short swept-back hair | Mature athletic adult with composed command face and symmetric chin-length bob or centered low bun | Issued Solcrest standard-bearer kit and one Oath-Pike Standard; fallback `vanguard_2` |
| 11 | `sword_saint` — **Sword Saint** | Stage 2; Elite Melee Striker | Mature lean-athletic adult with squared jaw, center-parted hair, centered nape knot, and paired locks | Mature powerfully poised adult with center-parted jaw-length bob tucked evenly behind both ears | Simplified Lunaris martial uniform and one Meridian Greatblade; fallback `guard_2` |

Every female variant is fully covered and combat-functional, with practical boots and the same equipment size as the male. No female variant may gain cleavage framing, corsetry, exposed midriff or thigh, skirt coding, heels, jewelry, juvenile proportions, or reduced armor. Every male variant must also read as an adult professional rather than an adolescent or exaggerated brute.

## 3. Exact production matrix

### 3.1 Matrix arithmetic

For each class, production covers two genders, two actions, and four final facings. Only east-facing masters are generated; west-facing sequences are deterministic pixel mirrors.

| Dimension | Values | Count |
|---|---|---:|
| Recruit-derived classes | The eleven rows above | 11 |
| Adult identity variants | `male`, `female` | 2 |
| Generated directions | `ne`, `se` | 2 |
| Mirrored directions | `nw` from `ne`; `sw` from `se` | 2 |
| Actions | `idle`, `attack` | 2 |

> **Exact carrier count:** `11 classes × 2 genders × 2 generated directions × 2 actions = 88` generated Veo carriers.
>
> **Exact final sequence count:** `11 classes × 2 genders × 4 final directions × 2 actions = 176` runtime sequences.

The production also requires `11 × 2 × 2 = 44` approved directional chroma keyframes. One `NE` and one `SE` keyframe are created per class/gender variant and reused as the first and last endpoint image for that variant/direction’s idle and attack carriers.

### 3.2 Per-class accounting

| Class | Adult variants | GPT Image 2 directional keyframes | Generated carriers: NE/SE × idle/attack | Mirrored sequences: NW/SW × idle/attack | Final sequences |
|---|---:|---:|---:|---:|---:|
| Defender | 2 | 4 | 8 | 8 | 16 |
| Gunner | 2 | 4 | 8 | 8 | 16 |
| Mage Apprentice | 2 | 4 | 8 | 8 | 16 |
| Shock Trooper | 2 | 4 | 8 | 8 | 16 |
| Swordmaster | 2 | 4 | 8 | 8 | 16 |
| Immovable | 2 | 4 | 8 | 8 | 16 |
| Sniper | 2 | 4 | 8 | 8 | 16 |
| Sorcerer | 2 | 4 | 8 | 8 | 16 |
| Witch Doctor | 2 | 4 | 8 | 8 | 16 |
| Banner Guard | 2 | 4 | 8 | 8 | 16 |
| Sword Saint | 2 | 4 | 8 | 8 | 16 |
| **Total** | **22** | **44** | **88** | **88** | **176** |

No north-west or south-west video may be generated. `NW` is deterministically derived as the horizontal mirror of `NE`, and `SW` from `SE`, retaining frame order, exact alpha, ground contact, effect timing, reach, and bounds. Quality-92 RGB encoding may introduce only the validator's tightly bounded per-channel compression delta. The briefs are explicitly mirror-safe: permanent features must remain centered or bilaterally paired, and no prompt or paint-over may introduce meaningful handedness, one-sided gear, directional writing, unilateral injuries, or fixed-side lighting.

## 4. Generative media specification

### 4.1 Reference packs and GPT Image 2

Create a paired high-resolution reference pack for every class/gender variant before producing animation. GPT Image 2 is the required image model for the reference boards and directional keyframes.

Each variant’s prompt and input set must include:

1. its exact specialization brief from `docs/operator-specializations/design-briefs/`;
2. the closest faction board from `docs/Faction - Solcrest Accord.webp`, `docs/Faction - Vesper Circuit.webp`, `docs/Faction - Lunaris Reliquary.webp`, or `docs/Faction - Crimson Aegis.webp`;
3. current `recruit_male` or `recruit_female` animation frames as proportion, ground-contact, and issued-uniform lineage references;
4. `docs/ART_DIRECTION.md` as the mature chibi style contract; and
5. the opposite-gender approved board for equipment, coverage, palette, silhouette-envelope, and scale parity—not for face or body duplication.

GPT Image 2 must produce, at its highest available native resolution:

- `design_reference.png`: a clean adult full-figure construction board showing front, rear, and equipment geometry;
- `chibi_reference.png`: a clean adult-chibi construction board showing the same equipment and palette at the intended three-to-four-head proportion; and
- `keyframe_ne.png` and `keyframe_se.png`: isolated, single-character, full-body animation keyframes.

The two directional keyframes use a **16:9 canvas**, a flat chroma field, a locked isometric three-quarter camera, identical elevation and subject scale, generous equipment clearance, no cast shadow, no scenery, no text, and one bottom-center ground contact. Choose neon green `#00FF00` or hot pink `#FF00FF` per variant by measuring separation from skin, hair, costume, and emissive colors; record the choice and reject any keyframe with chroma gradients or contact shadows.

### 4.2 Veo 3.1 carrier contract

All **88 carriers** use **Veo 3.1**. Each carrier must satisfy the following contract:

| Field | Binding value |
|---|---|
| Duration | Exactly **4 seconds** |
| Aspect ratio | Landscape **16:9**, matching its approved keyframe |
| Resolution | Highest native Veo 3.1 output available for the request; preserve that original without transcoding |
| Audio | **Disabled**; reject any carrier containing an audio stream |
| Camera | Locked: no pan, orbit, zoom, shake, dolly, parallax, reframing, cut, or perspective drift |
| Endpoints | The **same approved neutral directional keyframe** supplied as both first and last keyframe for every idle and every attack clip |
| Character count | Exactly one complete character with exactly one approved weapon/focus |
| Background | Uniform recorded chroma; no floor, shadow, particles, props, text, or scenery |
| Root | Bottom-center foot plant fixed; no tile translation or hitbox-significant movement |

An idle carrier performs one restrained, seamless brace/breathe/settle action and returns exactly to neutral. An attack carrier performs anticipation, the brief’s single contact/release event, follow-through, and complete recovery early enough to be sampled into the runtime attack window; it then remains neutral through the matching last keyframe. Prompts must forbid duplicate limbs, weapon transformation, hand detachment, camera motion, new props, extra attacks, large aura fields, and effects that obscure the face or feet.

The identical first/last endpoint requirement applies to **both idle and attack**, not only idle. It enforces a neutral recovery pose while the authoritative simulation continues to determine when an attack occurred.

### 4.3 Timing preservation

The current game contract remains exact:

| Action | Runtime frames | Runtime FPS | Playback duration | Sampling rule |
|---|---:|---:|---:|---|
| Idle | **24** | **12 FPS** | **2.000 s** | Endpoint-exclusive uniform resampling of the complete approved 4-second carrier into a seamless 24-frame loop; verify frame 24→frame 1 continuity |
| Attack | **13** | **12 FPS** | **1.0833 s** | Select the complete authored anticipation-to-recovery window, then endpoint-preserving resample it to 13 frames; do not retime simulation or hit resolution |

Do not add walk, deploy, skill, hit, death, retreat, victory, or portrait animations. The renderer currently consumes idle and attack only. Attack contact frames are visual events and may be aligned for readability, but they may not become a new source of combat truth.

## 5. Archival source layout and reproducibility

The required source root is outside the game package:

```text
/home/ubuntu/projects/proto-td-1515240c/advanced-operator-sprites-sources/
  README.md
  source_manifest.json
  source_manifest.tsv
  references/<class_id>/<gender>/
    design_reference.png
    chibi_reference.png
    prompt.md
    request.json
  keyframes/<class_id>/<gender>/
    keyframe_ne.png
    keyframe_se.png
    keyframe_ne.prompt.md
    keyframe_se.prompt.md
    request_ne.json
    request_se.json
  carriers/<class_id>/<gender>/
    idle_ne.mp4
    attack_ne.mp4
    idle_se.mp4
    attack_se.mp4
    *.request.json
    *.prompt.md
  extracted/<class_id>/<gender>/<action>_<direction>/
    frame_000.webp ...
    extraction.json
  runtime-previews/<class_id>/<gender>/
    idle_ne.webp ... attack_sw.webp
    contact_sheet.webp
    validation.json
  tools/
    build_advanced_operator_sprites.py
    validate_advanced_operator_sprites.py
    requirements.lock
```

Preserve the **highest-resolution original** returned for every GPT Image 2 reference, every GPT Image 2 chroma keyframe, and every Veo 3.1 carrier. Never overwrite an approved source with a resized, keyed, compressed, mirrored, or color-corrected derivative. Corrected generations receive a monotonically numbered sibling such as `keyframe_ne_v02.png` or `attack_se_v03.mp4`; `source_manifest.json` identifies the approved version.

Every source and derivative row records: class ID, gender, action, direction, source or derived status, `mirrored_from`, model and model version, request ID, prompt SHA-256, input-reference SHA-256 values, chroma color, native dimensions, duration, FPS, audio-stream count, generation UTC time, processor commit, processor arguments, temporal window, runtime frame indices, output dimensions, and SHA-256. The TSV is a review-friendly projection of the canonical JSON.

Model output itself is not assumed bit-reproducible. Reproducibility means that the immutable originals, prompts, request metadata, tool lockfile, temporal selections, hashes, and deterministic processing commands are sufficient to regenerate the exact mirrored and runtime derivatives. Mirroring, alpha extraction, resampling, normalization, packing, and hashing must be deterministic and covered by fixtures.

## 6. Runtime image profile

### 6.1 Fixed-cell output

Each of the 176 runtime sequences is a **quality-92 VP8 WebP atlas with lossless alpha** and fixed **640 × 640** cells. Immutable GPT Image 2 references, directional keyframes, and Veo carriers remain at full generated resolution in the external source archive. The neutral body/equipment union is fitted without distortion so its longest non-transparent edge is **560–640 px**; target 600 px where the silhouette allows, reserve visible alpha margin, and reject clipping. The same variant/direction uses one neutral scale transform for idle and attack so transient VFX cannot shrink the character.

All cells use a **bottom-center pivot** at normalized `(0.5, 1.0)`, corresponding to pixel `(320, 640)`. Feet or the planted equipment ferrule register to that ground axis in every frame. If a source pose contains transparent floor clearance, normalize it out rather than compensating with a different manifest pivot. Class-specific display height remains a presentation calibration, approximately the existing 58–64 px tower read, and must not change gameplay collision.

Every atlas uses exactly **8 columns**, in row-major frame order:

| Action | Frames | Columns | Rows | Exact atlas dimensions |
|---|---:|---:|---:|---:|
| Idle | 24 | 8 | 3 | `5120 × 1920` |
| Attack | 13 | 8 | 2 | `5120 × 1280`; row two contains frames 8–12 and three transparent unused cells |

The unused attack cells are transparent padding and are not counted as frames. Quality-92 VP8 encoding preserves lossless alpha and permits only the validator's bounded RGB compression delta; alpha mirrors must remain exact per frame. Color space, premultiplication policy, and alpha threshold are pinned in the processor manifest.

### 6.2 Repository filenames

Runtime art uses stable class and gender identities rather than reusable operator IDs:

```text
assets/sprites/operators/animated/<class_id>/<gender>/
  idle_ne.webp
  idle_nw.webp
  idle_se.webp
  idle_sw.webp
  attack_ne.webp
  attack_nw.webp
  attack_se.webp
  attack_sw.webp
```

For example:

```text
assets/sprites/operators/animated/defender/male/idle_ne.webp
assets/sprites/operators/animated/defender/female/attack_sw.webp
assets/sprites/operators/animated/sword_saint/female/attack_ne.webp
```

Logical IDs use `op_anim_<class_id>_<gender>_<action>_<direction>`, for example `op_anim_banner_guard_female_attack_sw`. Presentation resources use:

```text
data/presentation/operator_visuals/<class_id>_male.tres
data/presentation/operator_visuals/<class_id>_female.tres
```

Their `visual_id` values are `operator_<class_id>_<gender>`. All 22 resources declare idle 24, attack 13, FPS 12, source cell 640 × 640, bottom-center pivot, calibrated display height, and `placeholder = false` with an empty placeholder source map.

## 7. Godot integration

### 7.1 Catalog resolution order

Extend `OperatorVisualCatalog.template_for_unit()` to accept `class_id` while retaining the existing inputs. The resolution order is binding:

1. **Premium portrait override first.** Preserve exactly:
   - `portrait_archive_caster → archive_caster`;
   - `portrait_lunaris_vessel → lunaris_vessel`;
   - `portrait_reliquary_duelist → reliquary_duelist`.
2. If `class_id` is one of the eleven approved specialization IDs, resolve deterministic identity gender and return `<class_id>_male` or `<class_id>_female`.
3. Preserve the existing `recruit_male` / `recruit_female` resolution for unspecialized recruits.
4. Fall back to the incumbent `op_id` definition or alias for legacy/replay/unit fixtures lacking an admitted class ID.

Gender selection remains deterministic and view-only. Use the stable identity string already available to presentation—`hero_id` first, then `portrait_asset_id`; use `unit_id` only when both are empty—and the existing parity/hash rule. Centralize it as `deterministic_identity_gender(hero_id, portrait_asset_id, unit_id)`. Do **not** add or mutate authoritative gender in `UnitState`, save data, battle commands, replay hashes, or campaign receipts. A roster identity must retain its selected gender after promotion and across redeployments because `hero_id`, not the class or deployment instance, is the primary seed.

Update `scripts/view/battle_view.gd::_operator_visual_template_id()` to pass `u.class_id`. `UnitState.class_id`, `hero_id`, `portrait_asset_id`, and `op_id` are read only. Leave `OperatorAnimator.selection()` model-tick behavior intact.

### 7.2 Catalog registrations and placeholder replacement

Register 22 new definitions in `data/presentation/operator_visual_catalog.gd`. The class resources continue to point at their existing operator definitions; only the view resolver changes. The current class-to-operator mapping in Section 2 remains as a fallback and as authoritative combat data.

The new class/gender atlases replace all placeholder, generic, and cross-class presentation currently seen by specialized non-premium recruits. Do not repoint or delete the three premium definitions. Retain old operator-ID visual definitions for one release as rollback/fallback resources, but no admitted specialized class with a valid identity may resolve to them after cutover. The `witch_doctor_1 → caster_1` visual alias remains only for class-less legacy fallback; `witch_doctor` resolves to its own male/female production art.

### 7.3 Animation schema and cell-size removal of hard-coding

`operator_animator.gd` currently hard-codes `SOURCE_CELL_PX := 192.0`. Replace that assumption with the definition/manifest cell size and add an exact 640 × 640 source-cell contract to `OperatorAnimationDef`. Keep `display_height_px` as the calibrated tower-scale result and record the neutral subject body height used by scaling separately from the required 560–640 px longest-edge QA measurement. `body_size()` must produce the same intended in-game read regardless of source resolution.

`OperatorAnimationDef.validate_contract()` must reject anything other than 24 idle frames, 13 attack frames, 12 FPS, four exact directions, finite bottom-center pivot, 640 × 640 cells for these new definitions, positive display calibration, or unknown logical IDs. Existing premium/recruit resources may continue under their existing source profiles during migration; schema validation should be versioned rather than silently changing their meaning.

### 7.4 Asset manifest columns

Promote `AssetManifest` to a new explicit schema version. Add a required integer `columns` field—the field is already consumed opportunistically by `Art.texture()` but is not currently admitted by `AssetManifest.ENTRY_KEYS`—and require `columns = 8` for every new operator atlas. Add a required provenance dictionary so generated and mirrored assets are auditable without consulting filenames.

Each new row in `assets/manifest.tres` contains at least:

| Field | Required value |
|---|---|
| `pattern` | Exact `res://.../<action>_<direction>.webp` path |
| `frames` | 24 idle or 13 attack |
| `size` | `Vector2i(640, 640)` |
| `columns` | `8` |
| `placeholder` | `false` |
| `pivot` | `Vector2(0.5, 1.0)` |
| `animations` | One exact region: idle/24/12/loop or attack/13/12/non-loop |
| `provenance` | Class, gender, action, direction, `generated` or `mirrored`, `mirrored_from`, source-manifest ID, and atlas SHA-256 |

Add exactly **176 logical animation rows** for the new class/gender sequences. `Art.texture()` must correctly address row transitions (frames 7→8 and, for idle, 15→16) and never expose the three padded attack cells. `OperatorVisualCatalog._validate_manifest()` must verify the 640 cell, 8 columns, pivot, frame count, FPS, loop flag, non-placeholder state, provenance direction, and mirror source.

## 8. Processing and validation tooling

Implement `tools/operator_sprites/build_advanced_operator_sprites.py` as a deterministic CLI. It must accept the source root, class, gender, action, generated direction, chroma, temporal window, and output root; remove measured carrier chroma with spill decontamination; preserve soft alpha and costume cyan/teal; sample frames; normalize against a neutral anchor; pack eight columns; derive the west atlas by RGBA pixel mirroring; and write validation JSON. Save the script before execution and pin all Python dependencies in the source archive lockfile.

Implement `tools/operator_sprites/validate_advanced_operator_sprites.py` to fail on wrong carrier count, audio streams, duration drift, non-16:9 media, camera/root drift above tolerance, missing recovery, wrong frame count, wrong atlas dimensions, missing WebP alpha, longest edge outside 560–640 px, clipped alpha, pivot drift, chroma fringe, unequal variant scale, mirror alpha mismatch or excessive RGB compression drift, missing hashes, or unexpected files.

A representative deterministic build command is:

```bash
python3 tools/operator_sprites/build_advanced_operator_sprites.py \
  --sources /home/ubuntu/projects/proto-td-1515240c/advanced-operator-sprites-sources \
  --class defender --gender male --direction ne --action idle \
  --cell 640 --columns 8 --frames 24 --fps 12 \
  --pivot 0.5,1.0 --subject-long-edge-target 600 \
  --runtime-root assets/sprites/operators/animated
```

The canonical batch command and complete argument list go in the archive `README.md`. Batch processing must stop on the first failed sequence and must never overwrite an approved source.

## 9. Phased implementation and completion gates

| Phase | Work | Completion criteria | Safe rollback |
|---|---|---|---|
| 0 — Baseline and archive freeze | Fetch current `master`; record revision; inventory briefs, faction references, current atlases, catalog, manifest, and Web preset; create the source root and manifests | Eleven briefs and 22 variant rows accounted for; baseline import/tests recorded; source root writable and excluded from Web export | Delete only the empty new archive scaffold; no runtime changes |
| 1 — Processor and schema pilot | Add deterministic processor/validator fixtures; version `OperatorAnimationDef` and `AssetManifest`; add mandatory `columns`; remove 192 hard-coding without changing existing resources | Synthetic 24/13-frame, 640-cell, 8-column atlases pass; frames 7/8 and 15/16 address correctly; existing recruit and premium tests still pass | Revert schema/tool commit; existing schema/resources remain valid |
| 2 — Reference approval | Generate 44 highest-resolution GPT Image 2 boards (full/chibi pairs for 22 variants), then 44 NE/SE 16:9 chroma keyframes | Every variant reads adult; male/female equipment parity passes; mirror-safety checklist passes; non-premium restraint and palette pass; hashes and prompts recorded | Mark rejected versions unapproved; never overwrite them; no game assets yet |
| 3 — Defender end-to-end pilot | Generate 8 Defender carriers, derive 16 final sequences, integrate two resources and manifest rows, and render both genders in all facings | Exactly 8 silent 4-second carriers; 16 sequences pass alpha, mirror, root, timing, cell, and native BattleView checks; premium visuals unchanged | Resolver feature gate/fallback returns Defender to `defender_1`; remove only pilot rows/resources in one revert |
| 4 — Remaining stage-1 classes | Produce Gunner, Mage Apprentice, Shock Trooper, and Swordmaster | Adds exactly 32 carriers and 64 final sequences; stage-1 cumulative total is 40 carriers/80 sequences; all eight variant definitions non-placeholder | Revert one class batch at a time; legacy operator visuals remain available |
| 5 — Advanced classes | Produce Immovable, Sniper, Sorcerer, Witch Doctor, Banner Guard, and Sword Saint | Adds exactly 48 carriers and 96 final sequences; grand totals are exactly 88 carriers and 176 sequences; all 22 variants complete | Per-class catalog fallback; do not delete source originals or prior approved classes |
| 6 — Catalog cutover | Register all 22 definitions; route premium first, then class+deterministic gender; update manifest and remove specialized classes from generic presentation paths | Every admitted class identity resolves to its class/gender art; promotions preserve gender; class-less fixtures use fallback; premium portrait table is byte-for-byte equivalent | Revert resolver/catalog commit; old operator-ID definitions and art retained for one release |
| 7 — Native release candidate | Run focused tests, full suite, import, bounded boot, and native visual matrix in landscape and portrait | No script/resource/manifest/render errors; all 176 sequences visibly pass; authoritative model/replay hashes unchanged | Revert candidate commits; restore prior manifest/catalog without touching source archive |
| 8 — Web export and deployment | Export exact preset, stage streams, serve over HTTP, validate browser/network/memory, layer into WebDev host, check/build/preview, checkpoint and deploy | Git revision, export checksums, host revision, PCK hash, preview, and deployed URL all identify the same release; desktop and portrait matrix smoke passes | Restore previous WebDev checkpoint and managed PCK URL; source `master` remains forward-only |

A phase is not complete when files merely exist. It is complete only when its count, hashes, media properties, art review, deterministic tests, native rendering, and rollback record pass.

## 10. Test plan

### 10.1 Focused automated tests

Add `tests/advanced_operator_animation_test.gd` and cover the complete data contract:

| Contract | Required assertion |
|---|---|
| Catalog completeness | Exactly 22 class/gender templates exist, each with unique `visual_id` |
| Resolution priority | Premium portrait override wins even when a premium unit has a recruit-derived `class_id` |
| Class routing | Each of 11 classes resolves to male/female class art, never generic operator art |
| Deterministic identity | Same `hero_id` keeps gender across class promotion and different deployment `unit_id` values |
| Legacy fallback | Empty/unknown class retains incumbent operator-ID behavior |
| Simulation isolation | Resolver does not mutate `UnitState`; representative battle and replay hashes remain unchanged |
| Direction projection | RIGHT→SE, DOWN→SW, LEFT→NW, UP→NE |
| Frame/timing | Idle=24/loop, attack=13/non-loop, FPS=12 |
| Atlas geometry | Cell=640 × 640, columns=8, exact atlas dimensions, padded attack cells inaccessible |
| Pivot/scale | Pivot=(0.5,1.0); calibrated body size remains at approved gameplay scale |
| Production status | All 176 rows exist and have `placeholder=false` |
| Provenance | NE/SE generated; NW mirrors NE; SW mirrors SE; hashes present |
| Exact mirror | Every west frame equals a byte-exact horizontal RGBA mirror of its east source |
| Loading | First, row-boundary, and last frame of every atlas load successfully with and without populated Godot import cache |

Retain and run `tests/lunaris_vessel_animation_test.gd`, `tests/reliquary_duelist_animation_test.gd`, `tests/archive_caster_animation_test.gd`, and `tests/recruit_animation_alignment_test.gd`. Add direct assertions that the three `PREMIUM_VISUAL_BY_PORTRAIT` mappings have not changed.

### 10.2 Native visual matrix

Add `tests/advanced_operator_visual_matrix.gd` as a native Godot/Xvfb harness. It must instantiate each class/gender in real `BattleView`, force all four facings, capture idle neutral, idle seam, attack anticipation, contact/release, and recovery, and run at both **1280 × 720** and **720 × 1280**. The primary acceptance matrix is all **22 variants × 4 directions × 2 actions = 176 sequences**; contact sheets may combine checkpoints but may not omit a sequence.

Save outputs under:

```text
docs/operator-specializations/verification/advanced-operator-sprites/
  landscape/<class_id>_<gender>_<direction>_<action>.png
  portrait/<class_id>_<gender>_<direction>_<action>.png
  contact-sheets/<class_id>_<gender>.png
  inspection-notes.md
  matrix.json
```

The native review checks adult identity, class silhouette, gender parity, premium-distance restraint, exact facing, equipment continuity, planted root, bottom-center alignment, no clipping/chroma fringe, effect readability, idle seam, attack recovery, neighboring-tile occlusion, health/SP overlays, and tower-scale consistency. Log scanning fails on parse, resource, atlas, renderer, texture, assertion, or fatal errors.

### 10.3 Engine and repository gates

On the final candidate, run focused tests once, then the repository regression inventory, followed by the documented engine checks:

```bash
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . --quit-after 120
```

Run the visual harness under Xvfb with the compatibility renderer and dummy audio at both target sizes. Re-fetch `origin/master` before final validation; if reconciliation changes runtime behavior, rerun affected gates. Preserve concurrent compatible work as required by `AGENTS.md`.

## 11. Exact Web export, HTTP validation, and WebDev deployment

Do not alter the existing `Web` preset unless a separately approved platform change is required. The release must use the current Godot 4.7.2 non-threaded preset: all resources, `build/web/index.html`, premium cinematic OGV exclusion, no extension support, no thread support, desktop VRAM compression enabled, mobile VRAM compression disabled, canvas resize policy 2, and PWA disabled.

Export and stage streams exactly as documented by the repository:

```bash
cd /home/ubuntu/workspace/proto-td
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
sha256sum build/web/index.html build/web/index.js build/web/index.wasm build/web/index.pck \
  > build/web/SHA256SUMS
sha256sum -c build/web/SHA256SUMS
```

If Godot emits additional required worklet or icon files, include them in the recorded release inventory; do not rename or omit them. Assert that HTML, JavaScript, WebAssembly, PCK, staged cinematic manifest, and all referenced runtime files exist and return exact sizes/hashes.

Serve the export over HTTP rather than opening `file://`:

```bash
python3 -m http.server 8060 --directory /home/ubuntu/workspace/proto-td/build/web
curl -fI http://127.0.0.1:8060/index.html
curl -fI http://127.0.0.1:8060/index.pck
curl -fI http://127.0.0.1:8060/index.wasm
```

In a real browser, inspect parent and iframe consoles, requests, MIME types, PCK/WASM status, texture imports, atlas row transitions, startup time, peak memory, and all 22 class/gender routes in desktop and portrait. The 5120-pixel atlas width requires a WebGL maximum texture-size gate of at least 8192 on supported targets; block release rather than silently repacking to a different column count.

Then forward-integrate the verified export into `/home/ubuntu/proto-td-web` without overwriting newer compatible host work. Update the managed game loader/PCK references and `README.md`, `PLAN.md`, `STRUCTURE.md`, `MEMORY.md`, `ASSETS.md`, and `VERIFICATION.md` with the exact Godot commit and SHA-256 values. Preserve lazy Premium Resonance stream routing. Run:

```bash
cd /home/ubuntu/proto-td-web
pnpm check
pnpm build
pnpm dev --host 0.0.0.0
```

Verify the borderless `/game/index.html` iframe at desktop and portrait sizes, exact PCK transfer, all four directions, idle-to-attack transitions, and both genders for representative stage-1 and advanced classes. Save a WebDev checkpoint, deploy through the existing WebDev publish route, record the checkpoint/deployment URL and host commit, and confirm the deployed asset hashes match `build/web/SHA256SUMS`. The Godot `master` revision, Web bundle, WebDev host, managed PCK, and deployed preview must all identify the same candidate.

## 12. Risk controls

| Risk | Consequence | Control and rejection condition |
|---|---|---|
| Premium-style drift | Non-premium operators compete with named heroes | Enforce issued equipment, one restrained effect motif, limited trim, no orbitals/chains/couture/asymmetric relics; review at thumbnail and full size |
| Juvenile or sexualized variants | Violates adult brief and parity | Mature face/body checklist; identical coverage and weapon authority; reject childlike head/limbs, exposed body coding, heels, or glamour additions |
| Gender changes class silhouette | Gameplay readability or perceived power differs | Shared silhouette envelope, equipment dimensions, ground line, pivot, timing, and display height; overlay male/female neutral and contact frames |
| Generated asymmetry breaks mirroring | West direction changes identity or function | Prompt centered/bilateral construction; reject one-sided gear, text, runes, lighting, scars, pouches, hand controls, or directional VFX before video |
| Camera/root drift | Jitter and false tile movement | Same first/last keyframe, locked-camera prompt, optical-flow/root validation, bottom-center registration; reject instead of hand-stabilizing severe drift |
| Chroma overlaps cyan/teal effects | Holes or fringe in costume/energy | Per-variant green-versus-pink distance measurement, encoded-carrier chroma sampling, dominance recovery, spill inspection, alpha comparison |
| Attack lacks full recovery | Stuck pose at authoritative timing boundary | Require neutral endpoint, choose complete action window, inspect frame 13→idle frame 1, regenerate if recovery is absent |
| Wide weapon/effect clips at 640 | Lost silhouette or false scale | Target 600 longest edge, neutral-anchor scale, alpha-margin test, brief-conforming compact effect; reject oversized generation |
| 8-column atlas exceeds device limit | 5120-wide textures fail on lower-end WebGL hardware | Require `MAX_TEXTURE_SIZE ≥ 8192` on supported Web targets, test representative desktop/mobile browsers, and block release if target policy cannot support the mandated atlas |
| 640-cell atlases exhaust memory | Browser crash or long load | Preserve the 640px quality-92 WebP sources, but import the 176 class/gender atlases with Godot high-quality lossy mode (`quality = 0.92`) plus mipmaps. `configure_advanced_operator_imports.py` regression-locks the settings. Reject any Web PCK above 600 MiB or any representative browser load that crashes before Title. |
| Manifest schema migration breaks old art | Recruit/premium or legacy textures fail | Version schema, migrate fixtures, retain old resource semantics, test old and new cell profiles together |
| Class/gender resolver affects simulation | Save/replay/hash divergence | Resolver remains in presentation catalog; read stable identity only; mutation guard and paired simulation-hash tests |
| Premium mapping regression | Named heroes receive class art | Premium portrait lookup is first and exact; dedicated tests pin all three mappings |
| Model rerun is non-deterministic | Approved art cannot be recreated exactly | Immutable highest-resolution sources, prompts, request metadata, versions, and hashes; never rely on regeneration as rollback |
| Concurrent `master` or host movement | Stale deployment drops other work | Fetch and forward-reconcile before each integration/release gate; preserve both compatible features; never rewrite shared history |

## 13. Definition of done

The program is complete only when all of the following are true:

- all eleven named recruit-derived classes have separate adult male and adult female production variants;
- the archive contains exactly 44 approved NE/SE directional keyframes and exactly **88** silent, locked-camera, four-second Veo 3.1 carriers with identical first/last keyframes;
- runtime contains exactly **176** idle/attack direction sequences: generated NE/SE and deterministic mirrored NW/SW with exact alpha;
- every idle is 24 frames and every attack is 13 frames at 12 FPS, preserving current presentation timing and authoritative simulation behavior;
- every runtime atlas is quality-92 VP8 WebP with lossless alpha, 640 × 640 per cell, eight columns, bottom-center pivot, with subject longest edge in the 560–640 px range and no clipping;
- all 176 advanced atlas imports retain unlimited 640px dimensions, add mipmaps for tower-scale sampling, and use high-quality compressed storage so the Web PCK remains within the 600 MiB release budget;
- highest-resolution GPT Image 2 references, keyframes, Veo carriers, prompts, request records, processing metadata, and hashes are preserved under `/home/ubuntu/projects/proto-td-1515240c/advanced-operator-sprites-sources`;
- all 22 class/gender resources and 176 manifest rows are non-placeholder and auditable;
- catalog routing is premium portrait first, then class plus deterministic identity gender, then recruit/legacy fallback;
- premium mappings and all authoritative campaign/battle/replay behavior are unchanged;
- automated contracts, exact-alpha and bounded-RGB mirror checks, repository regression, direct import, bounded boot, and the complete native 176-sequence visual matrix pass;
- the exact Godot Web preset exports successfully, the bundle passes HTTP/browser checks and memory/texture-size gates, and the same revision is built, checkpointed, and deployed through the WebDev host; and
- rollback can restore the prior catalog/manifest/WebDev checkpoint without deleting or overwriting any approved source original.

This definition intentionally holds non-premium art to a high execution standard while preserving a visible rarity boundary: specialized recruits are polished, readable field professionals; premium heroes remain the setting’s more ornate, asymmetric, narratively unique visual apex.
