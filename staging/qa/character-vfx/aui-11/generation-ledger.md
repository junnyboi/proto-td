# AUI-11 Round 5 Production Generation Ledger

## Authority

The production slice is derived from the six human-approved Round 5 concept hashes recorded in `docs/decisions/AUI-DESIGN-APPROVALS.md` and the external checksum manifest whose SHA-256 is `0389dd44621684d65636c5d4d549311ab39e090d77ca9560b7522f107162c1d6`. The approval-token set identity is `5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b`.

## Generation route

Six 4×2 masters were generated with GPT Image 2 from the frozen Vanguard/portrait, grunt/Charm, and VFX reducers. They cover `vanguard_1`, `portrait_vanguard_1`, `grunt`, `deploy`, `attack_hit`, and `Charm`. Generated guide bars and checkerboard presentation pixels were treated as source-preparation defects rather than game content.

Focused GPT Image 2 variation passes removed panel labels and reduced guide artifacts. Those edits baked an opaque checkerboard into the returned PNGs. The pre-clean and rejected variants are retained under the external `research/rejected/` hierarchy with hash manifests.

The first named blind-review wave exposed a real canonical-facing defect: Vanguard scored 0/10 and grunt 6/10 for screen-right facing. Rejected correction rounds and their exact reviewer outputs remain preserved in the external reviewer-gate evidence. The final bounded GPT Image 2 corrections retain the approved identities and phase order while moving Vanguard's face/spear action and the grunt's front wedge/lens/hammer action to screen-right. The final 72 px one-color gate scored 10/10 for both roles and both screen-right facings.

The strengthened staged verifier later rejected Vanguard's row-1 recovery because its occupied-shape IoU against row-1 anticipation was `0.467288`, below the unchanged `0.92` loop floor. That failed result and its predecessor bytes remain preserved as external red evidence. `close_vanguard_attack_loop.py` copies the accepted anticipation source/master cell into the recovery slot byte-for-byte. The attack contact remains in frame 5 and the Rally cue remains in frame 6; only frame 7 now closes the loop exactly. Fresh blind and Vanguard originality reviews are required for this loop-closed candidate rather than inherited from its predecessor.

The expanded final staged gate then rejected both grunt rows: row 0 measured `0.893516` and row 1 measured `0.362651` against the same unchanged `0.92` floor. Those exact packets and the traceback remain external red evidence. `close_grunt_loops.py` copies each row start into its recovery slot in the master and base sources. The frozen Charm cue-support transform then adds only the phase-specific connected support needed by the unchanged semantic oracle; no region, color, topology, threshold, or loop floor changes. Final grunt loop IoUs are `0.998405` and `1.0`, and the Charmed derivative is regenerated from that accepted base atlas. Because the reviewed grunt images changed, fresh ten-reader blind and seven-packet originality gates are required rather than inherited.

The first normalized `attack_hit` packet was rejected during final-size visual review because its centered bilateral silhouette read as a four-point star flare. A directional slash/comet replacement passed its initial local review but was later rejected by the definitive packet-specific reviewer because it did not preserve the sealed target-lozenge concept. The first target-lozenge correction passed every numeric pin but failed visible chevron/notch separation; its first r3 normalization also failed because three dilation iterations merged the punctuation. All three failures remain external red evidence.

The accepted r3 master was generated with GPT Image 2 from the rejected target-lozenge candidate and the sealed VFX sheet. Its exact prompt is tracked in `attack-hit-v2-generation-prompt.md`. Pinned `isnet-general-use` extraction preserves all material components on the frozen 128×128 native VFX canvas. `build_attack_hit_sources.py` then applies one eight-connected source-pixel dilation, the proven deterministic 3/4 vertical fit, and exact row-boundary closure with one palette-valid accent pixel so rows are visually distinct while alpha IoU is `1.0`. The independent transform oracle reproduces all eight sources byte-for-byte. The final packet measures `55..56 px` wide, `36..38 px` high, `424..486` opaque pixels, center `96`, foot `180`, open-center alpha `0`, and exactly `7` detached components in every cell. An independent final audit passes the open target lozenge, two unequal detached bearing chevrons, exactly three detached unequal notch blocks, smallest-family read, and all forbidden-shape exclusions.

The original `charm_vfx` packet passed its local size/open-center gates but was rejected by the definitive packet-specific reviewer because eight near-static single-lozenge forms did not preserve the sealed four-facet-to-open-clasp progression. The first concept correction passed every numeric pin but failed because deterministic thickening fused its arrival facets and swallowed the under-mark; the next separated correction passed the progression but frame 6 retained only one chip. Those failures remain preserved as external red evidence.

The accepted r4 Charm master was generated with GPT Image 2 from the rejected chunky correction and both sealed Charm authorities. Its exact prompt is tracked in `charm-vfx-r4-generation-prompt.md`. Pinned extraction preserves the 128×128 native component layout. The contract-bound transform applies one component-gap-preserving thickness step, a deterministic 5/8 vertical fit, protected-center clearing, frame-6 interior densification, two explicit detached side chips, and exact row-boundary closure. The independent oracle reproduces all eight final sources byte-for-byte. The packet measures `60..67 px` wide, `40 px` high, `922..1090` opaque pixels, center `96`, foot `180`, open-center alpha `0`, and loop IoU `1.0`. Frame 6 has exactly six components: two open clasps, three chips, and one under-mark. An independent final audit passes the full sealed Charm progression and all forbidden-shape exclusions.

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

The corrected grunt silhouette initially underfilled frozen right-tab and shoulder-light regions. `repair_charm_cue_support.py` adds only connected base-art support inside those already frozen regions; the semantic minimum remains `128`, while the final authored signal target is `200` light/dark samples per binding region. `flatten_grunt_state_regions.py` recolors only occupied base samples in the same regions to remove misleading seam noise. After loop closure, three fresh state-review candidates failed at `6/10`, `2/10`, and `1/10`; all results remain external red evidence. `reduce_grunt_base_highlights.py` then recolored only occupied samples mapping to the three brightest ordinary ceramic palette values, removing the global pale wash that reviewers mistook for status. Alpha, occupied coordinates, anchors, phase order, the Charm contract, semantic minimum, and review threshold remained unchanged. Final loop IoUs are `0.980726` and `0.995726`; the unchanged semantic verifier passes; fresh blind scores are Vanguard role/facing `10/10`, grunt role/facing `9/10`, and Charmed side `8/10`—the exact frozen minimum.

`blind-review-inputs.json`, the three generated 72 px inputs, `blind-review-results.json`, and `verify_named_review_gates.py` bind those human judgments to the exact promoted atlases. Review results below threshold from earlier rounds remain external red evidence; they are not overwritten or reclassified.

## Runtime status

All seven packets remain `PRODUCTION_PACKET_STAGED_RUNTIME_UNBOUND`. Their exact integration barrier is `runtime_binding: UNBOUND_AGENT_F_SEAM`; Agent F owns runtime ingestion. Their exact art-acceptance barrier is `human_final_art: UNSET_HUMAN_ONLY`; packet review cannot clear the required later exact-candidate in-game human review. No runtime manifest, scene, gameplay, save/replay, probe registry, threshold, runtime binding, or human final-art state is changed by AUI-11.
