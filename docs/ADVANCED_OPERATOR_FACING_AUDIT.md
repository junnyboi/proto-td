# Advanced Operator Facing Audit

**Author:** Manus AI  
**Scope:** Eleven recruit-derived specialized classes, two genders, idle and attack, four logical isometric directions  
**Engine:** Godot 4.7.2 stable

## Executive summary

The live battle screenshot indicated that several specialized operators appeared to face away from their selected combat direction. A complete visual audit rendered eleven 1920×1080 class matrices covering all **176 atlas routes**. The review found that the runtime facing conversion itself is coherent: simulation facings map to the four isometric logical directions in one centralized projection function.[1] The defect was instead located in the generated `OperatorAnimationDef` resource maps, where some logical directions selected atlases whose pixels visibly faced another quadrant.[2]

The correction is deliberately presentation-only. No atlas pixels, immutable GPT Image 2 references, animation frames, simulation facings, targeting rules, battle hashes, campaign state, or save data are changed. Eleven affected class/gender identities now select the visually correct source atlas. Four clean classes and all clean gender scopes remain byte-for-byte mapped as before.

## Audit result

| Class | Affected scope | Correction |
|---|---|---|
| Defender | None | Retain authored mapping |
| Gunner | Female and male; idle and attack | 180°: `NE↔SW`, `NW↔SE` |
| Mage Apprentice | Female and male; idle and attack | Vertical: `NE↔SE`, `NW↔SW` |
| Shock Trooper | Female; idle and attack | Source correction: `NE→SE`, `NW→SW`, `SE→NW`, `SW→NE` |
| Shock Trooper | Male; idle and attack | 180°: `NE↔SW`, `NW↔SE` |
| Swordmaster | Female; idle and attack | Vertical: `NE↔SE`, `NW↔SW` |
| Immovable | None | Retain authored mapping |
| Sniper | Male; idle and attack | Horizontal: `NE↔NW`, `SE↔SW` |
| Sorcerer | None | Retain authored mapping |
| Witch Doctor | None | Retain authored mapping |
| Banner Guard | Female; idle and attack | Horizontal: `NE↔NW`, `SE↔SW` |
| Sword Saint | Female and male | Idle vertical; attack 180° |

The resulting change affects **88 of 176 logical mapping rows** across **11 of 22 class/gender identities**. A follow-up live-battle review found that the Shock Trooper's female and male source labels require distinct corrections: the female quadrants use a source-specific permutation, while the male quadrants require a 180° remap. This is why a roster-wide `flip_h`, a global 180-degree rotation, or a change to `OperatorAnimator.direction_for_facing()` would be incorrect: each would regress the clean controls and the unaffected gender/action subsets.

## Implementation

The deterministic registrar owns the reusable identity, horizontal, vertical, and opposite transforms plus one narrowly scoped female Shock Trooper source correction.[3] Resource generation applies the override table when writing each class/gender `idle_by_direction` and `attack_by_direction` map. A new `--resources-only` mode regenerates the presentation resources without requiring or rewriting the external immutable source archive.

The runtime visual harness now resolves frames through `OperatorVisualCatalog` and each generated `OperatorAnimationDef` rather than bypassing the resource mapping with constructed asset IDs.[4] Consequently, its post-fix matrices exercise the same route used by live battles.

## Regression contract

The Python processor suite checks representative affected scopes, clean controls, and the exact total of 88 remapped rows. The Godot animation test validates all 176 logical routes against the audited transform table while retaining existing source-size, frame-count, pivot, provenance, atlas-boundary, and identity-routing checks.[5] Visual acceptance must include all eleven corrected matrices plus representative live battle captures where attack direction can be compared with a target or lane.

## Post-fix acceptance

All eleven runtime-resolved 1920×1080 matrices were regenerated after the mapping repair. Godot route validation passed all 176 rows, and independent visual review accepted the corrected class-, gender-, and action-scoped mappings. Sniper’s subtle front/back bow poses received an additional three-review adjudication: the majority and the practical projectile-origin criterion accepted the female identity map and male horizontal remap. Live battle projection then completed **24 landscape and portrait captures** across the affected classes plus a clean Defender control without a missing texture, fallback sprite, parse error, or runtime error.

The focused gate passed advanced animation/schema/content-pack/compression tests, the battle layout test, and all **14** deterministic Python processor tests. The final native and Web release gates remain responsible for detecting unrelated repository regressions before deployment.

## References

[1]: ../scripts/view/operator_animator.gd "Operator Animator"
[2]: ../data/presentation/operator_visuals/ "Generated Operator Animation Definitions"
[3]: ../tools/operator_sprites/register_advanced_operator_sprites.py "Advanced Operator Sprite Registrar"
[4]: ../test/advanced_operator_visual_harness.gd "Advanced Operator Visual Harness"
[5]: ../tests/advanced_operator_animation_test.gd "Advanced Operator Animation Regression"
