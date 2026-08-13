# TD-029 — Aetheria Part 2 Directional Operator Animations

**Author:** Manus AI / Agent 8
**Repository:** `prototype-td`
**Union candidate:** `d2c5b33` on `agent-8/td-029-aetheria-part2-integration`
**Source package:** `aetheria-chibi-sprites-part-2-completed`

## Outcome

TD-029 integrates five additional operator templates into the existing OPANIM-1 view-only runtime: Caster I (`caster_1`), Caster II (`caster_2`), Protector (`defender_2`), Ranger (`sniper_1`), and Sky Hunter (`sniper_2`). Each template resolves independently generated SE, NE, NW, and SW idle and attack atlases. No simulation, action, save, replay, economy, or gameplay data was changed.

The admitted catalog now contains seven animated templates and 56 runtime atlases. The five Part 2 templates contribute 40 atlases. All unrelated operator templates continue through the incumbent legacy sprite fallback.

## Runtime contract

| Contract | Integrated value |
|---|---:|
| Runtime cell | 192×192 RGBA |
| Idle frames | 24 |
| Attack frames | 13 |
| Playback rate | 12 fps |
| Part 2 normalized subject height | 158 px |
| Part 1 canary normalized subject height | 168 px |
| Runtime pivot | `(0.5, 0.94)` |
| Alpha | Binary |
| Mirroring | Disabled |

The deterministic importer reads the authenticated 256×256, 25-frame delivery sheets, preserves source hashes, selects source frames `0..23` for idle and `0,2,4,...,24` for attack, and emits hard-alpha 192×192 runtime atlases. The importer is idempotent and validates source-manifest hashes before writing.

Attack playback is now derived from each resource's declared frame count and fps at the model's 30 Hz observation rate. Thirteen frames at 12 fps remain active for ages 1–33 and retire at age 34, eliminating the earlier self-consistent but incorrect 13.45 fps mapping. Runtime body scale is also data-driven: Part 2 uses its authenticated 158 px normalization denominator rather than the 168 px canary value.

## Declared placeholders

Exactly two assets remain placeholders, both explicitly requested as temporary substitutions when the paid generation batch exhausted credits.

| Runtime asset | Requested direction | Source direction | Status |
|---|---|---|---|
| `op_anim_sniper_2_attack_ne` | NE | SE | Declared placeholder |
| `op_anim_sniper_2_attack_nw` | NW | SW | Declared placeholder |

The mapping is preserved in the source manifest, compact runtime manifest, per-resource contract, provenance graph, catalog checks, and live-battle scenario. No other Part 2 atlas is placeholder-marked.

## Verification

| Gate | Result |
|---|---|
| Deterministic importer `--check` | PASS |
| Runtime atlas validator | PASS, 56 atlases |
| Provenance regeneration/check | PASS |
| Focused GUT | PASS: resource, animator, source-import, and provenance contracts |
| Stale class registry | PASS on union candidate |
| Full union FAST | PASS: import, 316-test GUT suite, replay, native/Web filesystem probes, and every headless scenario |
| `operator_animation_catalog` rendered | PASS: 39 checks, 14 fresh shots, zero skips |
| `operator_animation_part2` rendered | PASS: 72 checks, 2 fresh shots, zero skips |
| `map_navigation` rendered | PASS: 52 checks, 3 fresh shots, zero skips |
| `act1_shared_world_art` rendered | PASS: 37 checks, 3 fresh shots, zero skips |

The live-battle scenario deploys all five Part 2 heroes, checks exact direction and admitted atlas metadata, advances every attack beyond frame zero, validates the Sky Hunter NE-from-SE placeholder at runtime, proves view projection leaves the model hash unchanged, and captures distinct idle/attack frames.

## Audit corrections

An independent adversarial review found three high-confidence contract mismatches before closure. The final union corrects all three: attack timing now respects 12 fps, Part 2 scale uses 158 px rather than 168 px, and the compact provenance pivot now equals the runtime/resource pivot of `(0.5, 0.94)`.

The live-master fan-in also exposed a pre-existing null-theme terrain dictionary gap in `IsoGridBuilder`. The union fixes the fallback to provide both `tile_id` and `cadence_id`; the exact failing `map_navigation` scenario and the subsequent full FAST gate are green.

## Visual assessment and remaining work

Rendered battle evidence shows cell-compatible scale, stable bottom anchors, distinct idle and attack poses, and readable combat tracers. Directional silhouette-size variation inherited from the source package is preserved rather than hidden by per-direction rescaling. It is acceptable for integration but remains a candidate for a later art-fidelity pass.

The only required follow-up is to replace the two Sky Hunter placeholder attacks with native NE and NW Seedance clips when credits are available. Replacement should preserve the same logical IDs, frame counts, pivot, normalization, provenance, and verification gates so no runtime code change is required.
