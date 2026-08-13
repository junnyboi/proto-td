# AUI-11 Round 5 Production Generation Ledger

## Authority

The production slice is derived from the six human-approved Round 5 concept hashes recorded in `docs/decisions/AUI-DESIGN-APPROVALS.md` and the external checksum manifest whose SHA-256 is `0389dd44621684d65636c5d4d549311ab39e090d77ca9560b7522f107162c1d6`. The approval-token set identity is `5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b`.

## Generation route

Six 4×2 masters were generated with GPT Image 2 from the frozen Vanguard/portrait, grunt/Charm, and VFX reducers. They cover `vanguard_1`, `portrait_vanguard_1`, `grunt`, `deploy`, `attack_hit`, and `Charm`. Generated guide bars and checkerboard presentation pixels were treated as source-preparation defects rather than game content.

Focused GPT Image 2 variation passes removed panel labels and reduced guide artifacts. Those edits baked an opaque checkerboard into the returned PNGs. The pre-clean and rejected variants are retained under the external `research/rejected/` hierarchy with hash manifests.

The first normalized `attack_hit` packet was rejected during final-size visual review because its centered bilateral silhouette read as a four-point star flare. A focused GPT Image 2 variation replaced that language with eight asymmetric lower-left-to-upper-right slash/comet-shard frames. The replacement was re-segmented, vertically compressed by a deterministic 3/4 transform to satisfy the frozen height range, and received one bounded interior densification on frame 6 to satisfy the minimum occupied-area gate without changing its bounds. The prior master, sources, and visual verdict remain retained as red evidence.

## Deterministic foreground extraction

Final production sources are extracted cell-by-cell from the preserved corrected RGB masters. The extractor is `research/build_source_frames_rembg.py` in this external production workspace. It uses pinned `rembg==2.0.67` with the following model split:

| Domain | Model | Policy |
|---|---|---|
| Vanguard | `isnet-general-use` | largest material component |
| Vanguard portrait | `u2net_human_seg` | largest material component |
| grunt | `isnet-general-use` | largest material component |
| deploy / attack_hit / Charm | `isnet-general-use` | all material components of at least 32 pixels |

Model bytes are independently hashed in `research/source-frame-rembg-report.json`. Every extracted source is fitted without crop onto a transparent native canvas (`192×192` for characters/portrait and `128×128` for VFX), with at least eight pixels of transparent clearance. Exact ordinary probe-color tokens are remapped by one channel only and recorded in `research/reserved-remap-report.json`.

## Rejected deterministic cleanup attempts

Three deterministic alternatives were rejected before packet construction: long exact-color row deletion was ineffective; colored-anchor neutral flood destroyed legitimate neutral character materials; and color-only checkerboard keying left anti-aliased guide fragments. Their outputs and reasons are retained under `research/rejected/` and `research/master-visual-findings.md`. They are not production sources.

## Charm state

`grunt_charmed` is not generated independently. Its final packet sources are derived from the normalized `grunt` atlas after the base packet is accepted. The transform preserves every alpha byte and occupied coordinate, applies the frozen `charm-grunt-v1` palette/binding/tab/knot rules, and is checked by a separate oracle before its packet is built.

## Runtime status

All seven packets remain `PRODUCTION_PACKET_STAGED_RUNTIME_UNBOUND`. No runtime manifest, scene, gameplay, save/replay, probe registry, threshold, or human final-art state is changed by AUI-11.
