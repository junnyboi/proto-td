# Operator Specialization Design Brief 07 — Sniper

## Production summary

| Field | Direction |
|---|---|
| **Class ID** | `sniper` |
| **Class name** | Sniper |
| **Tier** | Advanced, stage 2; promotes from `gunner` |
| **Gameplay role** | Long-Range Marksman |
| **Operator identity** | A recruit-derived professional spotter-archer who eliminates distant priority and airborne targets |
| **Variants** | One matched clearly-adult male design and one matched clearly-adult female design |
| **Faction inspiration** | Vesper Circuit, adapted into a non-premium field-uniform expression |
| **Signature equipment** | Two-handed **Relay Longbow**, with a centered signal-sight and integral bolt synthesis channel |
| **Runtime target** | Four diagonal facings (`ne`, `nw`, `se`, `sw`), 192 × 192 frames, 24-frame looping idle and 13-frame non-looping attack at 12 fps, pivot `(0.5, 0.94)` |

> **Design thesis:** The Sniper is the quiet advanced endpoint of the recruit-to-Gunner line: an adult field professional defined by a tall bow axis, a compact disciplined stance, and one precise cyan release. The design should feel polished and specialized without acquiring the elaborate couture, jewelry, floating mechanisms, or unique spectacle reserved for premium heroes.

## Source alignment and faction choice

The class resource defines `sniper` as a stage-2 promotion from `gunner`, with the role **Long-Range Marksman** and the specific function of eliminating distant priority and airborne targets. The corresponding operator resource reinforces this read with high-ground placement, zero block, aerial-first targeting, a four-tile firing reach, and a quicker 27-tick attack interval. The design must therefore communicate range, target acquisition, and repeated precision rather than siege weight or close-combat survivability.

Of the four approved faction references, **Vesper Circuit is the closest design language**. Its midnight technical couture, wine interference glass, cyan signal filaments, narrow weapon geometry, and information-warfare equipment naturally support target discrimination and long-range fire. The faction concept also includes compact precision bows and hard, angular sighting shapes. Solcrest Accord offers disciplined archery but reads primarily as civic phalanx armor and formation defense; Crimson Aegis is too recoil-heavy and momentum-driven; Lunaris Reliquary is too ceremonial and prestige-caster oriented for this workmanlike operator.

This is an adaptation, not a full faction hero. Premium Vesper signatures are deliberately reduced: no face mask, drone swarm, holographic fan, jewelry chains, dramatic asymmetric train, translucent couture layers, or micro-filigree. The operator retains only the faction's **midnight base, muted wine lens material, thin cyan signal line, narrow gold hardware, and sharply tailored geometry**. The result should sit above the Gunner in refinement but materially below a banner hero in ornament, effects, and silhouette complexity.

## Recruit-derived continuity

Current recruit and operator sprites establish a compact adult chibi on a centered 192 × 192 transparent frame, with four diagonal facings, feet held close to the lower pivot, a subtle 24-frame idle, and a readable 13-frame attack. The existing ranged line is bow-led: the Gunner and Sniper silhouettes use a large bow, visible two-hand draw, planted feet, and a clear release pose. This proposal preserves that weapon grammar so the promotion is instantly legible.

The inherited recruit uniform survives as the Sniper's fitted charcoal underlayer, high boots, close bracers, narrow waist belt, and practical knee-length proportions. Promotion replaces the recruit's short blades with the Relay Longbow, adds a structured midnight shooting vest, a short symmetrical split overskirt/coat, low-profile forearm guards, and a centered throat clasp. The transformation is specialization through equipment and tailoring, not a change into a named hero.

## Visual hierarchy and silhouette

The target body is **approximately 3.5 heads tall**, within the required three-to-four-head adult-chibi range. The enlarged head supports readable mature facial structure, but the torso remains long enough to avoid toddler proportions. Hands and boots are enlarged for clean action poses. The stance is upright and economical, with feet shoulder-width apart, knees unlocked, shoulders level, and the bow held vertically near the body centerline at rest.

The silhouette has four dominant masses:

1. a mature, compact head shape with controlled hair volume;
2. a fitted high-collar torso forming a narrow inverted trapezoid;
3. two short, equal coat panels ending above the knees and opening around both legs; and
4. the tall, slim Relay Longbow, approximately 1.15 times the operator's standing height, creating an unmistakable vertical ranged-weapon axis.

There is no cape, shoulder mantle, hip satchel, exposed quiver, side-mounted scope, or one-sided armor slab. The short coat panels remain equal in length and value. Both shoulders use the same small angular cap; both forearms use the same guard. At gameplay scale, the bow curve and the gap between the weapon and torso must remain visible. Hair must not merge into the bow or obscure the face.

## Restrained palette and material plan

| Swatch | Hex | Use | Approximate area |
|---|---:|---|---:|
| **Midnight navy** | `#101827` | Shooting vest, coat panels, bow limbs | 45% |
| **Charcoal black** | `#22242B` | Recruit-derived underlayer, trousers/leggings, boots | 30% |
| **Muted wine** | `#7A3046` | Inner collar, narrow waist band, sight glass | 10% |
| **Signal cyan** | `#43C9D5` | One thin bow channel, sight pulse, projectile event | 6% |
| **Warm ivory** | `#D8D2C5` | Small collar piping and fletching/energy notch | 5% |
| **Dull gold** | `#A88A52` | Minimal clasp, limb tips, grip hardware | 4% |

The palette is shared across both variants. Midnight cloth should read matte; charcoal underlayers slightly softer; bow limbs lacquered rather than mirror-polished; muted-wine sight glass translucent but not broadly glowing; and gold brushed and subdued. Cyan is an information accent, not an aura. In idle, only the tiny central sight may breathe at low intensity. The attack may briefly brighten the bow channel and projectile, but effects must never hide the body or weapon construction.

## Shared costume construction

Both variants wear the same symmetrical operator kit. A charcoal, long-sleeved recruit compression layer sits under a sleeveless midnight shooting vest with a modest high collar. The vest uses two broad front planes, one muted-wine band around the waist, and a single dull-gold clasp placed exactly on the sternum. Small matching shoulder caps sit close to the body and do not widen into armor pauldrons. Identical forearm guards protect both arms so either diagonal view can be mirrored safely.

Below the belt, two equal midnight coat panels fall to the upper thigh at front and rear, separated at the center so the legs read during the draw. The legs use fitted charcoal trousers for the male variant and equally covered fitted leggings/trousers for the female variant; both terminate in the same low-heeled, reinforced black field boots. Piping is limited to one warm-ivory collar edge and one fine cyan seam on the vest. There are no unit medals, faction crest, rank badges, text, dangling ammunition, earrings, or narrative keepsakes.

The costume should show three levels of shape only: the large dark torso and bow; medium shoulder, forearm, and coat-panel shapes; and a few small sight/clasp accents. Do not add brocade, lace, filigree, chains, multiple belts, exposed wiring, glowing tattoos, or premium-grade jewelry during polish.

## Male variant

The male Sniper is a **clearly adult man, approximately late twenties to thirties**, with a lean athletic build, level shoulders, a defined jaw, straight mature brows, and calm narrowed eyes. His expression is alert and self-possessed rather than fierce or boyish. The chibi body uses a slightly wider shoulder line and straighter waist while retaining the same overall height, weapon scale, foot position, and animation envelope as the female variant.

His hair is cool black with a deep-navy highlight, cut in a short practical crop with a modest swept-back crown. The front edge is balanced rather than a meaningful one-sided fringe; no long ponytail, shaved-side pattern, eyepatch, earpiece, or facial scar is permitted. A subtle shadow at the jaw may support adulthood in portrait-scale art, but it should not become noisy pixel texture in the runtime sprite.

The outfit remains fully matched to the shared kit. The vest is slightly boxier over the ribcage and the coat panels fall nearly straight. His pose emphasizes stable shoulder control: sternum lifted, elbows relaxed, bow hand quiet. He must read as an experienced enlisted marksman, not a named assassin or aristocratic archer.

## Female variant

The female Sniper is a **clearly adult woman, approximately late twenties to thirties**, with an athletic build, mature almond-shaped eyes, defined brows, a composed mouth, and a strong upright posture. Her silhouette may show a subtly shaped waist and hip line, but must preserve practical coverage, stable anatomy, and the same combat footprint as the male design. Avoid oversized eyes, doll-like cheeks, pigeon-toed feet, an exaggerated head-to-body ratio, or a school-age skirt read.

Her hair is ash-brown with a muted-wine undertone, arranged in a compact collar-length blunt bob with both sides tucked evenly back. The outer mass should be almost bilaterally balanced. No side braid, unilateral clip, long loose tail, decorated hairpiece, earring, or monocular visor is permitted. The bob leaves the collar, both hands, and bowstring cleanly readable.

The outfit uses exactly the shared armor and coat construction. The vest can contour the adult torso without cleavage framing, and the paired coat panels may flare slightly more at the hips while staying equal left-to-right and ending at the same height. Her stance is grounded and authoritative, with the same bow size, draw length, projectile origin, and recovery timing as the male variant.

## Signature weapon — Relay Longbow

The **Relay Longbow** is the design's single signature weapon and focus. It is a tall, narrow, two-handed recurve bow built from lacquered midnight limbs, short dull-gold end caps, a charcoal central riser, and one muted-wine interference-glass sight set directly above the grip. A thin cyan channel runs symmetrically along both limbs. The central riser contains a small integral signal-bolt synthesis notch, allowing each projectile to resolve between the draw fingers and string without a physical quiver.

The longbow is intentionally mirror-safe. Its profile, limb decoration, grip, sight, string, and projectile origin are bilaterally symmetric around the weapon's long axis. There is no side-mounted scope, offset magazine, stabilizer, sling buckle, hand-specific guard, hanging charm, or faction emblem. At rest, it is held with both hands close to the centerline; during the attack, one hand supports the grip and the other draws the centered string. Mirroring changes apparent handedness only, which carries no gameplay or narrative meaning.

The weapon must remain readable as a bow rather than an energy staff. Keep a clear curved limb profile, visible string, distinct central grip, and a small projectile/notch shape. Cyan energy is confined to the channels and the released bolt. The bow should be more engineered than the Gunner's field bow but much less ornate than a premium hero's signature equipment.

## Idle motion

The idle is a restrained **24-frame loop at 12 fps**, matching current operator conventions. Feet remain planted and the root/pivot does not translate. The operator holds the bow vertically near the torso centerline, lower limb clear of the ground. Over the loop, the chest rises by approximately one to two pixels, shoulders settle, hands counter-shift by no more than one pixel, and the coat-panel tips and hair ends lag by one pixel before returning. Near the loop midpoint, the central sight gives one low-intensity cyan pulse, no larger than the sight itself.

The loop must begin and end on the same neutral pose. Do not add scanning head turns, weapon flourishes, foot taps, hovering parts, repeated blinking glow bands, or large hair swings. A single natural blink may occur only if it remains unobtrusive and does not make the character cute. The dominant impression is patience under control.

## Attack motion and recovery

The attack is a readable **13-frame, non-looping in-place action at 12 fps**, designed to return cleanly to idle:

| Frames | Beat | Required read |
|---:|---|---|
| **1–2** | Acquire | Chin and eyes align to the firing diagonal; bow rotates from vertical rest toward the aim line; stance remains planted. |
| **3–5** | Raise and draw | Grip arm extends, draw elbow moves back, torso compresses slightly, and a small cyan bolt resolves at the centered notch. The weapon, both hands, face, and string remain readable. |
| **6** | Full anchor | One brief held silhouette: bowstring fully drawn near the cheek, shoulders level, projectile aimed along the gameplay diagonal. This is the strongest anticipation frame. |
| **7** | Release/event | String snaps forward, bolt exits from the centered notch, sight flashes cyan, and the upper torso gives a restrained one-to-two-pixel recoil opposite the shot. This is the damage/projectile event frame. |
| **8–9** | Follow-through | Bow arm remains extended; draw hand opens slightly and settles beside the shoulder. No step, spin, or oversized effect. |
| **10–13** | Recovery | Bow lowers to the vertical centerline, shoulders and coat panels settle, and the final frame matches the neutral idle pose closely enough to avoid a pop. |

The attack must not change the root position, feet, gameplay hitbox, or pivot. The projectile is a narrow cyan-white stroke with minimal wine afterimage; it should clear the silhouette quickly and be authored as an effect/projectile if the combat system supports separation. Recovery is essential: do not end on the release frame or snap directly from full extension to idle. The pose should read equally well in every diagonal facing and under horizontal mirroring.

## Direction, mirroring, and hitbox rules

**Horizontal mirroring is approved.** The complete character and weapon may be flipped to derive opposite facings because no meaningful asymmetric component exists. The following rules are mandatory:

- Keep costume construction bilaterally paired: equal shoulder caps, equal bracers, equal coat panels, centered collar clasp, centered waist closure, and no side-specific color blocking.
- Keep all gameplay-significant weapon parts centered or symmetric: sight above the grip, energy notch on the string center, equal limb channels, equal end caps, and projectile origin at the bow's centerline.
- Do not introduce a physical quiver, side pouch, radio, shoulder antenna, ocular device, rank patch, faction emblem, prosthetic, shield, pet, or drone on one side.
- Hair may have minor strand variation in full art, but no meaningful accessory, braid, shaved side, or color streak may swap sides when mirrored.
- Do not place readable text, numerals, heraldry, or directional chevrons on the body or bow.
- Preserve identical foot contact, normalized subject height, pivot `(0.5, 0.94)`, projectile origin, and collision/hitbox alignment across mirror pairs.
- Mirroring may reverse apparent bow handedness. This is a non-meaningful presentation change and must not alter animation timing, target logic, or hit registration.

If bespoke `ne`, `nw`, `se`, and `sw` sheets continue to be produced rather than generated from two mirrored sources, treat them as mirrored construction equivalents. Do not “improve” one facing by moving equipment to an anatomical side; visual screen-side consistency and equal gameplay envelope take precedence.

## Production constraints and acceptance checks

The current runtime convention uses 192 × 192 sprite-strip frames, 24 idle frames and 13 attack frames at 12 fps, with a pivot of `(0.5, 0.94)`, a display height of 64 px, and a normalized subject height of 158 px. New source art should maintain locked camera, scale, and perspective; keep the full bow, hair, feet, projectile origin, and recoil inside every frame; and retain adequate transparent padding for all four diagonals.

The male and female designs are parallel variants of the same specialization, not separate heroes. Their costume topology, palette placement, bow geometry, animation timing, effect timing, pivot, collision footprint, and total subject envelope must match. Only mature facial structure, body contour, and compact hairstyle differ. Production should review both variants at native gameplay size, in grayscale, in solid-black silhouette, and as horizontally flipped sequences.

Acceptance requires that the unit reads immediately as a long-range archer without effects; remains clearly adult despite chibi abstraction; preserves recruit lineage; looks advanced but non-premium; keeps the bow and face clear at 64 px display height; completes the attack in place with a visible anticipation, release, follow-through, and recovery; loops the idle without root drift; and survives horizontal mirroring without moving any meaningful device, emblem, prosthetic, shield side, projectile origin, or hitbox.

## Explicit exclusions

Do not add a rifle, firearm stock, crossbow crank, giant siege limbs, shoulder cannon, physical arrow quiver, detached drone, floating halo, mask, monocle, one-eye visor, cape, long asymmetric sash, one-sided mantle, exposed mechanical limb, glowing familiar, shield, premium jewelry, cleavage-focused tailoring, bare midriff, high heels, school uniform cues, juvenile expressions, or elaborate faction crest. These elements either break the recruit-derived bow language, undermine adult field practicality, raise the design toward premium rarity, or make horizontal mirroring semantically unsafe.

## Repository references reviewed

This brief is based on [`ART_DIRECTION.md`](../../ART_DIRECTION.md), [`LUNARIS_CHARACTER_DESIGNS.md`](../../LUNARIS_CHARACTER_DESIGNS.md), the four approved faction concepts in `docs/Faction - *.webp`, [`data/classes/sniper.tres`](../../../data/classes/sniper.tres), the promoted operator definitions for `sniper_1` and `sniper_2`, their presentation resources, and the current recruit/Gunner/Sniper animated sprite strips and manifest conventions.
