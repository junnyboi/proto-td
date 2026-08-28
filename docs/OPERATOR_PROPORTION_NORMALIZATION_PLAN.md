# Advanced Operator Proportion Normalization — Audit and Implementation Plan

**Author:** Manus AI
**Canonical repository:** `https://github.com/junnyboi/proto-td`
**Planning baseline:** `b608116677fba89088bfdf664579c93b533d26b6`
**Engine and templates:** Godot `4.7.2.stable.official.ed1daf0bf`, non-threaded Web
**Image model:** GPT Image 2
**Animation workflow:** locked-camera image-conditioned video carriers processed through the repository video-to-sprites pipeline

## 1. Objective

The V2 advanced-operator set satisfies animation, source-resolution, compression, and runtime-routing contracts, but it does not present one coherent adult-chibi proportion language. The visible body heights vary because the original processor normalized each frame by its **longest subject edge**, which can be a banner, shield, staff, bow, or attack effect rather than the character’s crown-to-ground body height. Several identities also have head-to-body ratios outside the approved three-to-four-head range.

This work standardizes the **apparent crown-to-ground height** and **head-to-body ratio** of all twenty-two advanced operator identities while preserving class equipment, gender identity, adult age, palette, animation timing, root position, deferred content-pack architecture, and presentation-only runtime behavior.[1] [2]

> **Minimal-change rule:** correct absolute height with metadata whenever the underlying anatomy is salvageable; regenerate only identities whose head-to-body ratio cannot be changed by uniform runtime scaling.

## 2. Audit method

The audit combines three independent evidence sources. First, a deterministic Pillow scanner measured a 144-pixel-wide central alpha silhouette across ten neutral idle samples per identity; this isolates body height more reliably than the full alpha box, which includes equipment. Second, eleven independent visual reviewers estimated crown-to-ground head counts from the current close-up matrices. Third, the existing live BattleView captures were used to confirm that the discrepancy is visible at production scale rather than only in source atlases.

The approved adult-chibi target is **3.25–3.75 heads tall**. A 3.0–4.0 range is tolerated only when the deviation is minor at live size and both genders remain visually coherent. Male/female variants of one class must land within **8% apparent body height** and **0.25 head** after normalization.[3]

## 3. Findings and disposition

| Class | Female head count | Male head count | Current central silhouette, F/M | Disposition | Minimal correction |
|---|---:|---:|---:|---|---|
| Banner Guard | 2.80 | 3.25 | 598 / 586.5 px | Selective regeneration | Regenerate female; preserve male; calibrate both by measured crown-to-ground height. |
| Defender | 2.85 | 2.65 | 576 / 585 px | Full pair regeneration | Regenerate female and male with one shared 3.5-head construction. |
| Gunner | 6.10 | 6.00 | 555 / 595.5 px | Full pair regeneration | Regenerate female and male; preserve Signal Railbow identity and slim ranged silhouette without six-head realism. |
| Immovable | 3.55 | 3.25 | 578.5 / 573.5 px | Metadata only | Preserve art; calibrate both variants to one 64px crown-to-ground runtime height. |
| Mage Apprentice | 2.45 | 2.75 | 597.5 / 588 px | Full pair regeneration | Regenerate female and male with longer adult-chibi bodies and matched heads. |
| Shock Trooper | 3.40 | 3.95 | 534 / 527.5 px | Selective regeneration | Preserve female; regenerate male; calibrate both independently of the pike’s extent. |
| Sniper | 3.40 | 3.35 | 569 / 532.5 px | Metadata only | Preserve art; correct the 11% apparent-height gap through per-identity calibration. |
| Sorcerer | 2.10 | 2.65 | 600 / 600 px | Full pair regeneration | Regenerate both; remove doll-like oversized-head treatment while preserving orrery identity. |
| Sword Saint | 3.48 | 3.56 | 600 / 600 px | Metadata only | Preserve art; retain near-identical calibration. |
| Swordmaster | 3.90 | 3.25 | 600 / 597.5 px | Selective regeneration | Regenerate female; preserve male; match both to a 3.5-head class silhouette. |
| Witch Doctor | 2.70 | 2.75 | 593.5 / 597.5 px | Full pair regeneration | Regenerate both with smaller heads and longer adult-chibi bodies; preserve censer and ward identity. |

The selective scope is therefore **13 regenerated identities** and **9 metadata-only identities**. The regenerated matrix contains eight class reference boards, twenty-six generated `NE`/`SE` neutral keyframes, fifty-two four-second carriers, and 104 replacement atlases after deterministic west mirroring. The remaining seventy-two V2 atlases remain byte-identical.

## 4. Canonical proportion and runtime contracts

Every regenerated identity must be clearly adult, age twenty-one or older, and read as **3.5 heads tall**, with an acceptance window of 3.25–3.75. Male and female variants share the same visual head height within 8%, while body construction may remain appropriately gendered. The class’s existing face, hair, palette, costume, equipment, and attack thesis remain identity anchors.

Runtime cells remain 640×640 with transparent alpha and a 560–640px longest source edge. Apparent in-game crown-to-ground height becomes authoritative: each `OperatorAnimationDef.normalized_subject_height_px` records the measured median central body silhouette for that identity, and `display_height_px = 64` maps it to a common tactical footprint. Raised weapons, shields, standards, spell orbs, and attack effects no longer determine character height.

No gameplay state, class statistics, promotion legality, battle determinism, campaign receipt, save format, identity routing, or premium hero is modified.

## 5. Regeneration briefs

Each affected class receives one paired GPT Image 2 board with male and female operators shown at the same scale. The board uses a plain white studio background, complete full-body framing, neutral isometric production stance, no text, no scenery, and no cropped equipment. Each identity is then rendered into `NE` and `SE` neutral keyframes on the selected flat chroma background.

Idle carriers use Veo 3.1 with the same approved neutral image as first and last frame. Attack carriers use Gemini Omni Flash Preview unless Veo is required for identity stability. Every carrier is four seconds, 720p, 16:9, silent, single-subject, constant-scale, in-place, and locked-camera. West directions remain deterministic horizontal mirrors.

The affected classes retain these class anchors:

| Class | Required identity anchors |
|---|---|
| Banner Guard | Oath-Pike Standard, disciplined Solcrest support silhouette, matching female equipment to the preserved male. |
| Defender | Sunbar Ward-Pavise, white-gold Solcrest armor, broad but compact lane-anchor stance. |
| Gunner | Vesper Signal Railbow, midnight technical coat, cyan signal accents, restrained ranged silhouette. |
| Mage Apprentice | Lunaris conduit staff, violet-black practical robes, green-cyan controlled bolt energy. |
| Shock Trooper | Crimson service shock pike, impact plate, forward-ready vanguard posture. |
| Sorcerer | Lunaris convergence orrery, broad radial spell release, mature adult facial structure. |
| Swordmaster | Crimson breachline longblade, athletic melee stance, female identity matched to preserved male scale. |
| Witch Doctor | Solcrest Concord ward censer, teal-gold medic layers, restorative ward pulse. |

## 6. Implementation phases

| Phase | Work package | Required gate | Push rule |
|---|---|---|---|
| **0 — Audit and contract** | Commit deterministic body metrics, eleven-class review, this plan, and exact 13/9 disposition. | JSON validity, 22 identities, 11 classes, classification totals, document review. | Commit and push to `master` before asset changes. |
| **1 — Metadata normalization** | Add measured body-height calibration support and apply it to the nine byte-identical salvageable identities. | Animation schema, body-size regression, live mixed-class height capture, no atlas hash changes. | Commit and push after focused regressions. |
| **2 — Selective reference regeneration** | Generate and approve eight GPT Image 2 paired boards and twenty-six directional neutral keyframes; preserve all high-resolution sources outside Git in the project asset archive. | Adult read, 3.25–3.75 heads, paired height/head parity, identity/equipment continuity, full-body containment, fixed isometric perspective. | Commit/push manifests, prompts, and approved preview records; source PNGs stay in project files. |
| **3 — Video-to-sprites regeneration** | Generate fifty-two carriers and process them into 104 replacement atlases; preserve seventy-two existing atlases. | `ffprobe`, carrier count, camera/chroma/subject integrity, alpha/root/frame/mirror validation, 560–640px source edge, final proportion measurement. | Commit/push each complete class family after focused tests. |
| **4 — Runtime integration** | Register replacement hashes/provenance, update all twenty-two body calibrations, restage only affected deferred class packs, and preserve loader topology. | Schema/manifest/content-pack/import-policy tests, byte-identical untouched assets, exact changed-file allowlist. | Commit and push integrated runtime. |
| **5 — Native and visual acceptance** | Capture all twenty-two identities together and per class in close-up and live combat, idle and attack, landscape and portrait. | Direct import, bounded boot, full suite, strict log scan, 64px ±2px apparent height, head-count range, pair parity, no clipping/jitter/chroma. | Commit/push validated corrections and evidence. |
| **6 — Forward-only release** | Re-fetch `master`, preserve all compatible concurrent work, export exact pushed source, rebuild affected content packs, and layer the release onto the newest WebDev host. | HTML/JS/WASM/PCK, pack manifest/hash/range/MIME checks, `pnpm check`, `pnpm build`, managed browser/network/console/desktop/portrait verification, checkpoint. | Push source `master`; save the newest merged WebDev checkpoint. |

## 7. Automated acceptance criteria

1. The audit and runtime contain exactly eleven classes and twenty-two advanced identities.
2. Exactly thirteen identities are regenerated; the other nine retain byte-identical V2 atlases.
3. Each identity’s measured neutral crown-to-ground runtime height is 64px ±2px across generated east directions and mirrors.
4. Every regenerated identity measures 3.25–3.75 heads tall; no male/female class pair differs by more than 0.25 head.
5. Male/female body-height mismatch is at most 8% before metadata correction and at most 3% after runtime calibration.
6. Regenerated source frames retain 640×640 cells, 560–640px longest source edge, transparent padding, bottom-center roots, 24 idle frames, 13 attack frames, and 12fps playback.
7. `NW` remains an exact alpha mirror of `NE`; `SW` remains an exact alpha mirror of `SE`.
8. Existing V2 art outside the thirteen-identity allowlist remains byte-identical.
9. Deferred content packs remain class-scoped and lazy-loaded; a failed pack retains the incumbent fallback instead of a blank unit.
10. Full native, Web export, local HTTP, managed browser, network, console, and responsive visual gates pass on the exact released source.

## 8. Evidence and source custody

The deterministic audit JSON files live under `docs/operator-proportions/`. Generated reference boards, keyframes, carriers, raw extracted frames, and processor validation records are stored under `/home/ubuntu/projects/proto-td-5e1ec8e7/advanced-operator-proportion-normalization/`. Git receives the plan, metrics, prompt/provenance manifest, optimized runtime atlases, tests, tools, and final visual evidence—not the high-resolution generation archive.

## References

[1]: https://github.com/junnyboi/proto-td/blob/master/docs/ADVANCED_OPERATOR_SPRITE_REGENERATION_V2_PLAN.md "Advanced Specialization Animated Sprite Regeneration V2 — Implementation Plan"
[2]: https://github.com/junnyboi/proto-td/blob/master/docs/ADVANCED_OPERATOR_SPRITE_V2_RELEASE.md "Advanced Operator Sprite V2 Release Record"
[3]: https://github.com/junnyboi/proto-td/blob/master/docs/ART_DIRECTION.md "Protos Visual Art Direction"
