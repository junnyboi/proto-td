# Operator Specialization Design Brief 09 — Witch Doctor

## Design mandate

**Class ID:** `witch_doctor`  
**Class name:** Witch Doctor  
**Tier:** Advanced (`stage = 2`)  
**Gameplay role:** Combat Medic  
**Recruit lineage:** Mage Apprentice promotion  
**Runtime operator:** `witch_doctor_1`

This brief defines **exactly one non-premium, recruit-derived Witch Doctor specialization**, presented as matched adult male and female variants. The unit restores wounded allies and stabilizes a pressured formation rather than dealing conventional damage: the class data assigns a zero attack value, no automatic target policy, a broad forward support range, and the `mend` skill.[1][2] The visual read must therefore be “field ritualist delivering a controlled restorative ward,” not poisoner, necromancer, plague carrier, or premium hero.

Both variants are visibly **age 25–35**, with mature facial planes, proportionate adult hands and feet, confident posture, and practical professional styling. Neither variant uses a childlike face, oversized juvenile eyes, school cues, mascot anatomy, or a coy/cutesy performance. The chibi translation remains an abstraction of an adult, following the project requirement for approximately three to four heads of total height.[3]

## Faction inspiration and rationale

The closest design language is the **Solcrest Accord — Dawn Phalanx**. Solcrest is the best functional and visual match because its civic armor, oath-sashes, beacon mechanisms, linked ward planes, and disciplined formation silhouettes directly support a Combat Medic whose stated purpose is to stabilize formations.[3] The concept reference reinforces upright, organized silhouettes; white and gold ward hardware; dark underlayers; teal cloth; and luminous barrier geometry.[4] This gives the Witch Doctor a legible magical-medical vocabulary without borrowing the more rarefied glamour, orbiting reliquaries, gravity motifs, extensive translucent layers, or ceremonial ornament reserved for premium Lunaris heroes.[3][5]

The specialization adapts Solcrest at **field-operator grade**. Ivory becomes two simple ceramic armor pieces rather than a full civic harness; gold becomes sparse brushed-brass edging rather than filigree; and the oath-sash becomes a short, centered tabard instead of a long dramatic mantle. It deliberately avoids Solcrest’s broad shield silhouette, because a shield side would create a meaningful handed asymmetry under horizontal mirroring. It also avoids Vesper masks and drones, Lunaris orbital rings, and Crimson recoil hardware, all of which would either imply the wrong role or raise the design above its non-premium complexity budget.

## Visual thesis

> A disciplined battlefield healer in a compact cowl-coat, bracing a centered two-handed ward censer whose teal core compresses and releases restorative force.

The old placeholder’s bright green hooded read may survive only as the **deep medicinal teal cowl and glow identity**; the lime color, blank face, and generic wand-like implication are replaced by an adult, faction-coherent operator design. At small scale the recognition order is:

1. compact teal cowl framing an unobscured mature face;
2. ivory shoulder shelf over a charcoal fitted coat;
3. centered vertical brass-and-ivory Ward Censer held in both hands;
4. short split teal tabard and planted dark boots;
5. one mint-cyan activation pulse.

## Restrained palette

| Use | Color | Hex | Production rule |
|---|---|---:|---|
| Dominant textile and outline mass | **Charcoal black** | `#171C20` | Coat, trousers, gloves, boots; approximately 45% of the figure. |
| Faction cloth identity | **Medicinal deep teal** | `#176B68` | Cowl, short centered tabard, narrow sleeve bands; approximately 25%. |
| Readable armor/light value | **Bone ivory** | `#D8D2BE` | Two shoulder caps, sternum guard, censer ceramic faces; approximately 18%. |
| Mechanism trim | **Brushed brass** | `#B38A49` | Only major borders, grip collars, and core cage; approximately 8%. |
| Restorative energy | **Mint-cyan** | `#65D8C7` | Core and attack effect only; approximately 4%, never a constant bloom. |

Hair, skin, and eye colors remain natural and should not introduce another saturated accent. Use one dark outline family and no more than two shade steps per material at gameplay scale. Do not add crimson blood marks, neon green toxins, purple occult smoke, multicolor vials, gold filigree, chains, floating charms, feathers, skulls, horns, animal masks, or bone trophies. The unit should look polished through clean shape separation and material control, not ornament count.

## Shared silhouette and costume construction

Both variants use a **3.5-head-tall adult chibi silhouette** inside the same normalized subject envelope. The silhouette is an upright, stable column: a head-width cowl; a modest horizontal shelf from paired shoulder caps; a fitted torso narrowing into a short split tabard; straight planted legs; and the Ward Censer centered vertically in front of the body. The head occupies about 28% of total body height. Hands and boots are enlarged for sprite readability, but the torso remains long enough and the shoulders structured enough to preserve adult identity.

The shared outfit is a recruit uniform upgraded rather than replaced. Retain a practical charcoal undersuit, simple high boots, gloves, and a broad service belt. Add only four specialization-defining construction groups:

1. a deep-teal shoulder cowl with a short, symmetrical back fall;
2. paired ivory half-caps over both shoulders, identical in shape and value;
3. a centered ivory sternum plate above a short, evenly split teal tabard;
4. the two-handed Ward Censer.

Seams form broad vertical and chevron shapes that survive downsampling. The coat hem ends above the knee and splits evenly at center front and back. The belt has a centered plain brass clasp. If supplies must be indicated, use **two identical flat pouches**, one on each rear quarter, with no colored label or unique contents. Nothing projects from only one hip, shoulder, forearm, or side of the head.

The face remains fully visible inside a shallow cowl: no plague mask, blindfold, face paint, skull motif, or glowing eyes. The expression is focused and reassuring, with a low brow, small controlled mouth, and direct professional bearing. This communicates medical authority without premium-hero glamour.

## Male variant

The male variant is a clearly adult man, approximately 30, with a compact athletic build, a squared jaw, a straight mature nose, and calm heavy-lidded eyes. His shoulders are slightly broader and waist straighter than the female variant, but he fits the same overall gameplay height, ground contact, weapon envelope, and animation timing. Hair is a short, near-symmetrical dark crop with a centered widow’s peak and small even temple locks; it does not protrude beyond the cowl or generate directional secondary motion.

His cowl opening is slightly squarer, the paired shoulder caps are a little wider, and the coat uses a straight lower taper. These are silhouette-level gender distinctions, not equipment differences. He wears the same centered sternum guard, belt clasp, split tabard, gloves, boots, mirrored pouch pair, and Ward Censer as the female variant. His neutral stance uses a modest broad-legged brace and level shoulders, reading as an experienced field practitioner rather than a heroic bodybuilder.

## Female variant

The female variant is a clearly adult woman, approximately 28, with an athletic build, mature almond-shaped eyes, defined cheekbones, and a composed expression. Her adult identity comes from facial structure, posture, fitted professional tailoring, and proportionate torso and limbs—not sexualized posing or childlike softness. Hair is a centered jaw-length dark blunt bob tucked evenly behind both ears; both sides have the same outer contour and remain contained within the cowl.

Her cowl opening is a shallow oval, the waist has a modest tailored taper, and the paired shoulder caps are fractionally narrower. The coat remains fully practical and uses the same coverage, center split, length, materials, and construction groups as the male outfit. She carries no jewelry, hair ornament, exposed thigh, heel, unilateral stocking, or decorative side panel. The centered sternum guard, belt clasp, tabard, gloves, boots, mirrored pouch pair, and Ward Censer are identical to the male equipment. Her stance is equally planted and authoritative, with no hip cock or fashion pose.

## Signature focus — Concord Ward Censer

The sole weapon/focus is the **Concord Ward Censer**, a short two-handed field implement held vertically on the body centerline. Its total length runs from just above the boots to roughly chin height, large enough to read but short enough to stay inside the standard cell. The focus consists of:

- a dark straight shaft with two centered grip bands;
- a bilateral, vertically aligned ivory capsule at the top;
- an open brushed-brass cage with matching left and right arcs;
- one mint-cyan cylindrical core on the central axis;
- a small symmetric butt cap that can meet the ground during activation.

The silhouette is identical when mirrored. The core has no writing, directional arrow, faction crest, numbered gauge, dangling chain, side valve, hose, vial, needle, blade, or orbiting component. Both hands remain attached to the shaft during idle and attack. The Censer is not a staff of office and should not acquire a premium halo or ornate headpiece; its construction uses about six large readable pieces.

At rest, the upper hand sits just below the capsule and the lower hand near the waist, both straddling the body centerline. In three-quarter views the shaft may shift only a few pixels toward the camera so that both hands remain readable; it must not become a left- or right-side prop. Any restorative projectile or ward wave originates from the core’s center, preserving a stable muzzle/effect origin and hitbox under mirroring.

## Animation contract

The current animated operator convention uses four directions (`se`, `ne`, `nw`, `sw`), **24 idle frames**, **13 attack frames**, and **12 fps**, with each logical animation stored in 192 × 192 cells.[6][7] The existing Witch Doctor runtime currently aliases the non-premium `caster_1` presentation, whose production scale is a useful baseline: pivot `(0.5, 0.94)`, display height `64 px`, and normalized subject height `158 px`.[8][9] A dedicated male/female Witch Doctor implementation should preserve those timing and cell conventions and target the same displayed footprint unless an integration test requires a minor normalization adjustment.

### Idle loop — contained triage cadence

The **24-frame loop** is subtle and seamless. Both feet stay locked, the body center remains over the pivot, and the hands remain on the Censer.

| Frames | Motion |
|---:|---|
| 1–6 | Neutral brace; chest and cowl rise by at most 1 px while the Censer remains nearly fixed. |
| 7–12 | Upper body settles; mint core brightens one value step without enlarging. |
| 13–18 | One restrained 1 px weight return; the short tabard tips outward by 1–2 px symmetrically. |
| 19–24 | Core dims and cloth returns exactly to frame 1. |

The head may make a barely perceptible 1 px professional scan toward the combat direction, but there is no wink, bounce, wave, floating particle, rotating halo, unilateral charm swing, or dramatic hair motion. The core pulse is centered and should not alter the silhouette.

### Attack/skill motion — brace, compress, release, recover

The **13-frame in-place attack** reads as a support activation with a clear anticipation, impact, and recovery. It must remain readable even if the mint effect is disabled.

| Frames | Beat | Motion and effect |
|---:|---|---|
| 1–2 | **Set** | Knees compress 1–2 px; both hands draw the centered Censer closer to the sternum. |
| 3–4 | **Prime** | Censer rises vertically by roughly 4 px; ivory cage closes visually around the brightening core. Elbows spread evenly. |
| 5–6 | **Brace** | Butt cap plants on the ground centerline; torso leans forward slightly while feet remain fixed. |
| 7 | **Release/key pose** | Core flashes mint-cyan and emits one clean, shallow bilateral ward arc/diamond pulse forward from the center. The pulse may exceed the body by a modest amount but stays centered on the attack axis. |
| 8 | **Confirm** | Hold the readable activation pose for one frame; no camera-facing flare covers the hands or face. |
| 9–10 | **Recoil** | Shoulders and Censer settle backward/up by 1–2 px; effect contracts and vanishes. |
| 11–13 | **Recovery** | Hands slide back to their exact idle grips, knees straighten, tabard settles, and frame 13 aligns cleanly with idle. |

The action does not step, spin, kneel, jump, sweep sideways, or change facing. The feet, pivot, and gameplay hitbox never move. The effect is a controlled treatment pulse, not an explosive blast; use no skull cloud, potion splash, lightning storm, blood, target silhouette, or persistent ground decal. For the zero-attack support implementation, this sequence accompanies `mend`/skill activation rather than implying weapon damage.[2]

## Horizontal mirroring and direction rules

This design is **mirror-safe by construction**.

- The Censer is bilateral and stays on the body centerline with a centered core and effect origin.
- Both hands always hold the same centered shaft; no weapon hand, casting hand, shield side, or medically significant tool side exists.
- Shoulder caps, sleeve bands, gloves, boots, rear pouches, cowl tails, and tabard halves are matched pairs.
- The sternum guard and belt clasp are centered. If a Solcrest sun/ward mark is used at all, it is a simple radially symmetric mark placed only on the center of the sternum guard; omitting it at small scale is preferred.
- There is no prosthetic, eyepatch, tattoo, rank badge, text, directional gauge, unique vial, side satchel, shield, holster, mask half, side valve, or one-sided hair ornament.
- Hair contours are near-bilateral. Minor strand variation may mirror because it carries no identity, rank, function, or gameplay information.
- NW may be produced by horizontally mirroring NE, and SW by mirroring SE, provided feet and Censer remain centered to the same normalized pivot. Do not redraw an apparent hand swap into new functionality.
- Attack pulses must be centered on the facing vector. Mirroring changes only travel direction; it does not change effect width, source point, timing, or collision/hitbox interpretation.

## Non-premium complexity ceiling

The Witch Doctor should look authored and finished beside current operators but **materially simpler than premium heroes**. Limit the costume to one cowl/coat silhouette, two armor pairs, one centered tabard, one belt, and one focus. Use no long cape, orbiting mechanism, independent familiar, translucent overskirt, elaborate braids, jewelry cascade, filigree field, asymmetrical couture, exposed glamour panel, animated chain, or secondary weapon. The outfit should be explainable in one front view and should not require hidden mechanism callouts.

A successful sprite reads first as “teal-and-ivory support caster,” second as “Solcrest field medic,” and third as a gender-matched recruit promotion. It must never compete with the Lunaris flagship cast’s rings, hair mass, luxurious tailoring, or ceremonial spectacle.[5] Polish comes from adult characterization, disciplined silhouette, stable animation, and clean restorative timing.

## Production checklist

| Requirement | Acceptance criterion |
|---|---|
| Scope | Exactly one specialization concept, `witch_doctor`, with matched male and female variants. |
| Adult read | Both variants unmistakably 21+; target read 25–35, mature faces and posture. |
| Tier/role | Advanced Combat Medic; support activation does not imply direct-damage DPS. |
| Faction | Solcrest language is visible through teal/ivory/brass field ward equipment and disciplined stance. |
| Chibi scale | Approximately 3.5 heads tall, strong cowl–shoulder–centered-focus silhouette. |
| Variant parity | Same equipment, palette, timing, footprint, effect origin, and gameplay read for both genders. |
| Focus | One centered two-handed Concord Ward Censer; no off-hand item or secondary prop. |
| Idle | 24 frames at 12 fps; subtle breathing/core cadence; planted feet and seamless loop. |
| Attack | 13 frames at 12 fps; readable set, prime, centered release, recoil, and full recovery. |
| Mirroring | No meaningful asymmetry, side-specific device, emblem, prosthetic, shield, or hitbox. |
| Complexity | Clearly cleaner and less ornate than premium heroes; no orbiting or independently animated accessories. |
| Small-scale test | At gameplay height, cowl, ivory shoulders, center focus, planted stance, and mint release remain distinct. |

## References

[1]: ../../../data/classes/witch_doctor.tres "Witch Doctor class definition"
[2]: ../../../data/operators/witch_doctor_1.tres "Witch Doctor runtime operator definition"
[3]: ../../ART_DIRECTION.md "Protos visual art direction"
[4]: ../../Faction%20-%20Solcrest%20Accord.webp "Solcrest Accord faction concept"
[5]: ../../LUNARIS_CHARACTER_DESIGNS.md "Lunaris premium character benchmark"
[6]: ../../../data/presentation/operator_animation_def.gd "Operator animation schema"
[7]: ../../../data/presentation/operator_visuals/recruit_male.tres "Recruit male animation convention"
[8]: ../../../data/presentation/operator_visuals/caster_1.tres "Current caster animation convention"
[9]: ../../../data/presentation/operator_visual_catalog.gd "Current Witch Doctor visual alias"
