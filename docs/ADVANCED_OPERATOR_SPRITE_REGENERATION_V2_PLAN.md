# Advanced Specialization Animated Sprite Regeneration V2 — Implementation Plan

**Author:** Manus AI (Agent 8)

**Canonical repository:** `https://github.com/junnyboi/proto-td`

**Planning baseline:** `b860f111f32fc1b1b3f1329875162906acbf58aa`

**Working branch:** `agent8/advanced-specialization-sprites-v2`

**Engine and templates:** Godot `4.7.2.stable`, non-threaded Web export

**Image model:** GPT Image 2

**Video workflow:** Image-conditioned, locked-camera video carriers processed by the repository’s deterministic video-to-sprite tooling

## 1. Objective

Regenerate every animated, non-premium specialization that follows Recruit in the authored class tree. The release covers all eleven specialization classes, both adult male and adult female variants, four logical isometric facings, and the two stationary-tower action states required by runtime: `idle` and `attack`.

The new collection will preserve each specialization’s existing gameplay identity and portrait-defined character language while improving visual cohesion with the Recruit and premium-hero sprite families. The operators must remain deliberately less ornate and less effect-heavy than Premium Resonance heroes. This is a presentation-only replacement: campaign authority, simulation data, operator stats, promotion legality, saves, receipts, and deterministic hashes remain unchanged.

> **Locked production matrix:** 11 classes × 2 variants × 2 generated east-facing diagonals × 2 actions = **88 generated four-second carriers**. Horizontal mirroring derives the remaining 88 west-facing runtime sequences, producing **176 final directional atlases**.

## 2. Frozen class matrix

| Class | Tier | Role | Primary visual language | Signature equipment | Attack read |
|---|---:|---|---|---|---|
| Defender | 1 | Lane Anchor | Restrained Solcrest | Sunbar Ward-Pavise | Centerline ward-check |
| Gunner | 1 | Ranged Marksman | Restrained Vesper | Signal Railbow | Acquire, release, recover |
| Mage Apprentice | 1 | Arcane Attacker | Practical Lunaris | Lunar Conduit Staff | Gather, bolt, recover |
| Shock Trooper | 1 | Fast Vanguard | Restrained Crimson | Service Shock Pike | Brace-thrust-discharge |
| Swordmaster | 1 | Melee Striker | Restrained Crimson | Breachline Longblade | Descending breach cut |
| Immovable | 2 | Fortress Defender | Restrained Solcrest | Gatebar Ward-Maul | Ground-lock ward bash |
| Sniper | 2 | Long-Range Marksman | Restrained Vesper | Relay Longbow | Draw, precise release |
| Sorcerer | 2 | Area Spellcaster | Restrained Lunaris | Convergence Orrery | Broad radial release |
| Witch Doctor | 2 | Combat Medic | Restrained Solcrest | Concord Ward Censer | Restorative ward pulse |
| Banner Guard | 2 | Support Vanguard | Restrained Solcrest | Oath-Pike Standard | Rally ground strike |
| Sword Saint | 2 | Elite Melee Striker | Restrained Lunaris | Meridian Greatblade | Decisive rising cut |

Every class receives one matched male/female reference board. Both variants represent clearly adult operators aged 21 or older, share the same issued equipment and animation timing, and differ only through mature facial structure, body construction, and practical hair design.

## 3. Art and identity contract

### 3.1 Reference hierarchy

Generation uses this priority order:

1. Existing specialization portraits in `docs/portraits/nonpremium/sources/` for face, hair, palette, costume, and equipment identity.
2. The class-specific briefs in `docs/operator-specializations/design-briefs/` for silhouettes, materials, mirrored construction, and exact motion beats.
3. Current Recruit sprite frames for compact adult-chibi proportion, outline density, readability, and non-premium restraint.
4. Existing premium hero sprite frames as the rendering-quality ceiling, not the ornament or VFX target.
5. `docs/ART_DIRECTION.md` and the four faction concepts for shared material and faction language.

### 3.2 Reference sheets

GPT Image 2 will create eleven new high-resolution 16:9 paired character reference boards. Each board shows one male and one female variant as full-body adult chibi operators in matching issue kit, with clear weapon construction, unambiguous silhouette, stable isometric production poses, plain studio presentation, and no scenery or text. The generated boards are immutable source assets and live outside the source repository in the Manus project’s shared asset archive.

A board is rejected if it contains juvenile proportions, ambiguous age, malformed anatomy, mismatched male/female equipment, premium-grade ornament, cropped weapons, extra characters, text, watermarks, environmental scenery, meaningful left/right asymmetry, or material deviations from the class portrait and brief.

### 3.3 Direction and mirroring

The requested isometric topology is `NE`, `NW`, `SE`, and `SW`. Only `NE` and `SE` are generated. `NW` is derived from `NE`, and `SW` from `SE`, by deterministic per-cell horizontal mirroring. All eleven designs are already specified as mirror-safe: weapons are centered or bilateral; permanent equipment is paired; no side-specific emblem, prosthetic, shield-side logic, readable text, or asymmetric gameplay origin is permitted.

### 3.4 Runtime scale

High-resolution source boards, keyframes, and carriers remain in the shared archive. Runtime frames preserve the current repository contract: each frame is normalized into a 640 × 640 transparent cell, the visible operator’s longest edge targets approximately 600 px and must stay within 560–640 px, and the in-game footprint is controlled through Godot display size and pivots rather than destructive image reduction.

## 4. Video carrier contract

Each carrier is a four-second, 720p, 16:9, audio-disabled, image-conditioned clip containing exactly one full-body character. The first frame is a GPT Image 2 production keyframe matching the character board, direction, chroma choice, and neutral pose.

| Property | Requirement |
|---|---|
| Camera | Absolutely locked; no pan, tilt, zoom, dolly, orbit, shake, cut, reframing, parallax, perspective, or focal-length change |
| Projection | Fixed orthographic-style isometric view |
| Subject | One complete character and weapon at constant scale; feet/root anchored to one ground point |
| Background | Perfectly uniform hot pink `#FF00FF` or neon green `#00FF00`, selected per character for maximum separation |
| Audio | Disabled |
| Idle | Subtle two-second-ready-loop material distributed across the four-second carrier; breathing and minimal cloth/hair/equipment settling only |
| Attack | In-place anticipation, class-specific contact/release, follow-through, and complete neutral recovery |
| Prohibited | Scenery, floor, shadow, gradients, particles detached from the action, text, watermark, duplicate characters, extra props, locomotion, or camera motion |

Idle carriers use Veo 3.1 with the same approved neutral keyframe supplied as first and last frames for loop closure. Attack carriers use the highest-quality available image-conditioned model suitable for a non-looping four-second action and must still recover to neutral by clip end.

## 5. Deterministic processing and source custody

The immutable source archive will live at:

`/home/ubuntu/projects/proto-td-b7465cb9/advanced-operator-sprites-v2/`

The archive contains:

- `references/<class>/paired/design_reference.png`
- `references/<class>/<gender>/design_reference.png`
- `references/<class>/<gender>/chibi_reference.png`
- `keyframes/<class>/<gender>/neutral_<direction>.png`, with each neutral anchor reused as the idle first/last frame and the attack first frame
- `carriers/<class>/<gender>/<action>_<direction>.mp4`
- `runtime-previews/<class>/<gender>/*.validation.json`
- `source_manifest.json` with model, prompt, source, SHA-256, media, mirror, and runtime-output provenance

The repository receives only optimized runtime atlases, `.import` policy, manifests/metadata, deterministic processing tools, tests, and release documentation. Source generation files and carriers do not enter Git or the WebDev project.

The existing processor will extract native carrier frames, sample 24 idle frames or 13 attack frames, key the measured chroma, decontaminate color spill, retain the primary subject, compensate bounded scale drift, normalize every frame to the bottom-center root, pack eight-column WebP atlases, derive west facings by exact per-cell mirroring, and emit validation records.

## 6. Runtime integration

The existing presentation architecture remains authoritative:

- `OperatorVisualDef` continues to own class/gender atlas paths, frame counts, 12 fps playback, display height, normalized source height, and pivots.
- `OperatorVisualCatalog` continues to select specialization visuals using the current class and presentation variant without writing new campaign state.
- `assets/manifest.tres` retains stable IDs and receives updated atlas hashes/bytes and V2 provenance identifiers.
- The deferred Web content-pack topology remains intact: the base PCK stays compact and the eleven advanced class packs are restaged independently.
- Missing or failed deferred packs retain the current static fallback path.

No gameplay code, operator data, battle simulation rule, class promotion, save schema, identity mapping, or premium-hero asset is changed.

## 7. Implementation phases and gates

| Phase | Work | Required gate | Push rule |
|---|---|---|---|
| **0 — Contract** | Freeze matrix, naming, source custody, model choices, prompts, and acceptance criteria in this plan. | Diff review and exact 11/22/44/88/176 count audit. | Commit and push plan to `master`. |
| **1 — References** | Generate and review eleven GPT Image 2 paired reference boards; crop immutable per-gender derivatives; choose chroma; generate 44 directional neutral keyframes. | Dimensions, uniqueness, full-body/weapon containment, adult read, class silhouette, paired-equipment parity, contact sheet inspection. | Commit/push tooling and reviewed reference metadata; source images remain project files. |
| **2 — Carriers and atlases** | Generate 88 four-second carriers; verify technical media integrity; process into 176 atlases and validation records. | `ffprobe`, expected counts, alpha/bounds/root/frame/mirror validation, atlas contact sheets, runtime longest-edge contract. | Commit/push each fully completed class family after focused tests. |
| **3 — Runtime integration** | Update stable asset metadata, provenance, import policy, registration, and deferred content packs without altering gameplay state. | Godot direct import, parser gate, advanced schema/animation/content-pack tests, static fallback checks. | Commit/push integrated runtime phase. |
| **4 — Native and visual acceptance** | Run complete repository suite; Xvfb battle/training captures in landscape and portrait; exercise idle and attack for all 22 variants. | Bounded boot, repository tests, strict diagnostic scans, matrix visual review, no clipping/jitter/identity or background failures. | Commit/push any validated corrections. |
| **5 — Reconciliation and release** | Fetch newest `master`, preserve compatible concurrent work, rerun touched gates, export exact pushed source, restage base and eleven packs, then update the newest `proto-td-web` host forward-only. | Required HTML/JS/WASM/PCK artifacts; HTTP MIME/range/hash checks; `pnpm check`; `pnpm build`; managed runtime/network/console/desktop/portrait verification; final checkpoint/publish. | Push source `master`; checkpoint the newest merged WebDev host. |

## 8. Automated acceptance criteria

The release is acceptable only when all of the following are true:

1. Exactly eleven specialization classes and twenty-two male/female variants are represented.
2. Exactly eighty-eight generated source carriers exist: two actions × two canonical directions per variant.
3. Exactly 176 runtime atlases exist: two actions × four logical directions per variant.
4. Every idle atlas has 24 frames; every attack atlas has 13 frames; playback remains 12 fps.
5. Every visible frame has a longest subject edge between 560 and 640 px inside a 640 px square cell, transparent padding, bottom-center anchoring, and no non-root edge clipping.
6. `NW` is an exact mirrored derivative of `NE`, and `SW` of `SE`, within the repository’s alpha and compression tolerances.
7. Male and female variants retain matched class equipment, palette, attack timing, footprint, effect origin, and rarity treatment.
8. Every character is clearly adult and reads as the intended class at native gameplay size.
9. Camera and perspective are locked; no background, shadow, duplicate subject, or chroma fringe survives the runtime atlas.
10. Idle cycles are subtle and seamless; attack cycles are in place, class-specific, readable, and fully recovered.
11. Runtime selection remains presentation-only and all existing campaign/save/simulation tests remain byte-compatible.
12. Base Web export and all eleven deferred packs pass manifest, hash, MIME, byte-range, browser-load, and fallback validation.
13. The existing fullscreen, borderless, zero-margin WebDev host and all concurrent compatible loader/cinematic work are preserved.

## 9. Regeneration policy

Inspect final atlases rather than performing forensic frame-by-frame criticism of model videos. Regenerate only for a material failure: camera or perspective movement, character/weapon crop, identity loss, duplicate subject, malformed mask, persistent chroma contamination, obvious class mismatch, non-adult read, missing action beat, or unusable root/scale drift. Minor generative imperfections that remain visually acceptable at runtime size do not justify an unbounded generation loop.

## 10. Completion record

| Phase | Status | Evidence |
|---|---|---|
| 0 — Contract | **Complete** | Matrix, source custody, mirroring topology, quality ceiling, runtime scale, validation contract, and phased release gates were frozen and pushed as `1eae2965`. |
| 1 — References | **Complete** | Eleven reviewed 2560 × 1440 paired GPT Image 2 boards, twenty-two per-gender derivatives, forty-four approved `NE`/`SE` production keyframes, preserved raw sources, exact-chroma copies, SHA-256 provenance, and male/female contact-sheet review. Sorcerer female identity continuity and Banner Guard female equipment clearance were corrected before acceptance. |
| 2 — Carriers and atlases | **Complete** | Eighty-eight four-second, 1280 × 720, 24 fps, audio-free carriers were generated from the approved keyframes, audited with `ffprobe`, and processed into 176 lossless-alpha VP8 WebP atlases. All 24-frame idles and 13-frame attacks satisfy the 560–640 px runtime edge contract; all west directions are deterministic east mirrors. Independent class review and parent review accepted all classes after targeted correction of fifteen attack carriers and two exact-neutral recovery endpoints. |
| 3 — Runtime integration | **Complete** | Runtime resources, `assets/manifest.tres`, V2 source provenance, Q92/mipmap Web import policy, registrar tooling, and eleven deferred content-pack inputs now reference `advanced_operator_sprites_v2`. The immutable source manifest records 22 references, 44 keyframes, 88 carriers, and 176 runtime sequences with 21 Gemini Omni Flash Preview, 32 Veo 3.1, and 35 Veo 3.1 Fast carriers. |
| 4 — Native and visual acceptance | **Complete** | Exact Godot 4.7.2 import, bounded boot, schema, animation, content-pack, processor, import-policy, 88-carrier batch validation, and strict diagnostic scans pass. Eleven close-up matrices plus 66 live landscape/portrait gameplay captures cover all classes and both genders. Full 176-asset compression analysis passed at minimum 36.466 dB PSNR, maximum 0.008134 RGB MAE, zero alpha MAE, and worst 0.9811 edge ratio. All 82 aggregate Godot/import/smoke gates passed with zero diagnostics; the 12-test Python processor suite passed independently in 126 seconds after the aggregate runner’s isolated duration timeout. |
| 5 — Reconciliation and release | Pending | — |
