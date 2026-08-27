# Operator Specialization Design Brief 02 — Gunner

## Design mandate

This brief defines **exactly one** recruit-derived, non-premium operator specialization: **Gunner** (`gunner`), first tier (class stage 1), with the gameplay role **Ranged Marksman**. It supplies matched clearly-adult male and female sprite variants of the same operator design; they are identity variants, not separate classes or alternate costumes.

The design follows the adult chibi, material-separation, weapon-readability, and locked-camera requirements in [ART_DIRECTION.md](../../ART_DIRECTION.md), while deliberately remaining materially simpler than the premium heroes documented in [LUNARIS_CHARACTER_DESIGNS.md](../../LUNARIS_CHARACTER_DESIGNS.md). It also reflects the class contract in [`data/classes/gunner.tres`](../../../data/classes/gunner.tres): promotion from Recruit, engagement of distant and airborne threats, elevated-ground placement, and promotion onward to Sniper. Runtime reference data in `data/operators/sniper_1.tres` further establishes a ranged, aerial-first operator with a 30-tick attack interval.

## Faction inspiration: Vesper Circuit

The closest faction language is **Vesper Circuit — the Midnight Relay**. Of the four approved faction concepts, Vesper most directly communicates precision target acquisition, ranged control, signal routing, and compact technical equipment. Its midnight tailoring, restrained wine interference color, cyan signal filaments, and fine gold mechanisms naturally support an elevated marksman. Solcrest reads primarily as formation defense, Lunaris as prestige ritual casting, and Crimson Aegis as heavy momentum and breach impact; those are less aligned with a light first-tier ranged specialist.

This is a **recruit-grade Vesper adaptation**, not a premium Vesper hero. Retain the faction's clean dark technical silhouette and one readable cyan signal path, but omit ivory masks, drones, projection fans, long capes, jewelry, micro-filigree, ornate glass arrays, and fashion-editorial asymmetry. The result should look issued, well-fitted, and polished rather than unique or collectible. A single centerline collar insert and the weapon core carry the design language. No faction crest, personal badge, or side-specific device appears on the costume.

## Production thesis

> **A disciplined adult rooftop marksman in a compact midnight field coat, anchoring a centered two-handed signal railbow whose clean forked profile immediately communicates long range.**

At gameplay size, recognition must resolve in this order: **tall vertical railbow**, **large adult head and controlled hair mass**, **square shoulder yoke**, **short symmetrical coat tails**, then **one cyan weapon core**. The character must not be mistaken for a premium hero, caster, child archer, or heavily armored breach unit.

## Palette and material hierarchy

The restrained shared palette contains five authored colors. Skin, hair, and eye colors may vary naturally between identities but must remain subdued enough that the uniform and weapon read consistently.

| Priority | Color | Hex | Application |
|---:|---|---:|---|
| 1 | **Midnight near-black** | `#151923` | Main fitted coat, trousers, railbow body, and deepest shadows; approximately 50–55% of the costume. |
| 2 | **Relay navy** | `#263248` | Shoulder yoke, forearm guards, boot uppers, and broad cloth planes; approximately 25–30%. |
| 3 | **Muted wine** | `#743247` | Thin centered collar insert and small inner-coat glimpses only; approximately 8–10%. |
| 4 | **Signal cyan** | `#63C7D4` | Weapon core, one continuous centerline energy channel, and the attack flash only; approximately 5%. |
| 5 | **Brushed brass** | `#A88952` | Minimal fasteners and reinforced bow edges; no polished gold filigree; approximately 3–5%. |

Use only three dominant material reads: matte technical cloth, dark lacquered composite, and brushed brass. Cyan is emissive but controlled. There are no translucent costume panels, dangling chains, gemstones, patterned tights, decorative seals, or secondary glow colors. This places the Gunner clearly below premium Lunaris and faction-banner characters in ornament density while retaining professional finish.

## Shared silhouette and costume construction

The sprite is **approximately 3.5 heads tall**, within the required three-to-four-head adult-chibi range. The head is enlarged for readability but the face uses mature, narrowed eyes, a defined nose bridge, a restrained mouth, and a focused neutral expression rather than oversized childlike eyes or a cheerful juvenile affect. Both variants stand with an erect sternum, planted feet, and practiced weapon control.

The silhouette is an upright narrow wedge: a large head and hair mass above a squared, compact shoulder yoke; a fitted torso tapering to a clean waist; two short **equal-length** center-split coat tabs ending above the knee; straight fitted trousers; and sturdy calf-high boots. The centered railbow creates a tall vertical counter-shape in idle and a long, unmistakable aiming line in attack. Hands and boots are slightly enlarged for chibi clarity. The costume avoids long capes, skirts, exposed trailing straps, oversized pauldrons, and wide lateral accessories that would muddy tile occupancy or create variant-specific bounds.

The uniform evolves visibly from the current Recruit convention: retain a dark practical fitted base, compact gloves, close trousers, boots, and an unencumbered stance, then add the navy marksman yoke, short split field-coat layer, forearm protection, and dedicated two-handed ranged weapon. The progression should read as training and equipment specialization rather than a wholly unrelated hero replacement.

All construction is bilateral or centered. The shoulder yoke has equal panels; both forearms use the same guard; both gloves and boots match; the collar insert, belt clasp, coat split, and weapon core sit on the centerline. Do not add a quiver, side pouch, shoulder radio, monocle, eyepatch, one-sided mask, rank patch, holster, ammunition belt, or side-mounted optic.

## Male variant

The male Gunner is an unmistakably adult man, approximately late twenties to thirties in presentation, with a compact athletic build, broad but not heroic-scale shoulders, a defined jaw, straight mature brows, and a calm narrowed gaze. His stance is economical rather than swaggering. Hair is short, dense, and swept back into a modest centered crest with close sides; it must not form a schoolboy fringe or extreme premium-hero ponytail. Light stubble may appear in portrait-scale art but should not be encoded as noisy sprite pixels.

His jacket is cut slightly straighter through the torso, with the same yoke width, coat-tab length, forearm guards, boots, weapon scale, and centerline accents as the female variant. Avoid exaggerated muscular bulk, exposed chest, ornate belts, or a commander silhouette. He is a trained operator one promotion removed from Recruit, not a named elite.

## Female variant

The female Gunner is an unmistakably adult woman, approximately late twenties to thirties in presentation, with an athletic build, mature cheek and jaw definition, focused almond-shaped eyes, and a poised, confident expression. Her posture remains upright and operational, without pin-toed, coquettish, or childlike posing. Hair is gathered into a compact **centered low knot** with a clean crown and two short, balanced temple locks; it remains inside the shoulder width and does not trail across the weapon.

Her jacket follows the same armor and seam map as the male version, with only a subtly shaped adult torso and slightly tapered waist. Coverage, hem length, boots, gloves, shoulder yoke, forearm guards, weapon scale, and color placement remain identical. Do not use a skirt, high heels, exposed midriff, thigh-high styling, bows, jewelry, or other gender-coded ornament that would separate her from the issued operator uniform or alter the hitbox read.

## Signature weapon — Signal Railbow

The Gunner has **one weapon only**: the **Signal Railbow**, a two-handed, vertically oriented precision launcher derived from Vesper's angular ranged equipment. It combines a shallow symmetrical recurve frame with a rigid central firing rail. The upper and lower limbs are equal, the grip is centered, and the small cyan induction core is centered directly above the grip. Brass reinforcement appears in equal amounts on both limbs. The silhouette should read as a bow at first glance and as science-fantasy technical equipment on inspection.

The weapon is fully ambidextrous and mirror-safe. It has no quiver, loose arrows, side magazine, ejection port, trigger-side housing, offset sight, hanging cable, or unilateral ornament. During the draw, a short cyan energy quarrel forms **on the central rail**, eliminating ammunition-side continuity. Both hands remain visibly involved: the forward hand stabilizes the center grip while the rear hand draws a compact energy latch along the rail. Grip choreography may reverse under horizontal mirroring because the weapon, gloves, sleeves, and action are functionally bilateral.

At idle, the railbow rests nearly vertical in front of and slightly beside the torso but overlaps the body's center band enough to read as one centered equipment unit. Keep its lower tip above the ground line and its upper tip clear of the hair silhouette. At full aim it rotates into the facing direction without extending beyond the admitted attack canvas or changing collision/hitbox assumptions.

## Animation contract

Animation follows the current operator convention: four isometric direction families (`ne`, `nw`, `se`, `sw`), a locked 192 × 192 source cell, centered horizontal pivot, 24-frame idle, 13-frame attack, and 12 fps playback. The Gunner's existing presentation target is 64 px display height with a normalized subject height of 158 px and a pivot of approximately `(0.5, 0.94)`. Production may remeasure transparent bounds after final cleanup, but male and female variants must share the same source canvas, ground line, display height, and effective combat footprint. Feet should remain planted throughout both actions.

### Idle loop — measured overwatch

The **24-frame, two-second** idle is intentionally subtle. Frames 0–5 hold the ready pose; frames 6–11 show a one-pixel chest rise and a one-pixel lift of the centered weapon; frames 12–17 return through neutral; frames 18–23 add a very faint cyan core pulse and settle exactly into frame 0. The head performs only a one-to-two-degree target-check tilt, then returns. The weapon may rock by no more than one degree; coat tabs move together by one pixel. Feet, hips, ground contact, and overall height do not drift. Hair motion is limited to a one-pixel settle and must not create a premium flowing-hair loop.

### Attack — acquire, release, recover

The **13-frame, in-place** attack has a clear silhouette and full recovery:

| Frames | Beat | Required read |
|---:|---|---|
| 0–2 | **Acquire** | Knees compress by at most two source pixels; the railbow rotates from vertical to the facing line while both hands remain attached. |
| 3–4 | **Draw** | Rear elbow opens, centered cyan quarrel forms on the rail, and the torso counter-rotates slightly without moving the feet. |
| 5 | **Release / gameplay read** | One crisp cyan muzzle-line flash at the centered rail tip; bow limbs flex symmetrically. This is the preferred visual hit/projectile timing frame. |
| 6–7 | **Recoil settle** | Arms absorb a small backward impulse; cyan drops immediately to idle intensity. No screen-obscuring bloom or lateral shell/ejection effect. |
| 8–10 | **Lower** | Weapon returns toward vertical, shoulders square, and the operator regains full height. |
| 11–12 | **Recovery** | Exact idle-ready silhouette is restored, allowing a clean transition to the 24-frame loop. |

The action must not lunge off the tile, jump, spin, kneel, or use a separate side effect that implies a changing hitbox. Any projectile is a separate centered gameplay effect traveling along the target line; the sprite itself contains only the brief release flash. The pose should remain readable when viewed at 64 px display height and when several operators occupy neighboring elevated tiles.

## Horizontal mirroring and directional safety

This design is approved as **mirror-safe**. Horizontal mirroring may reverse a decorative hair sweep or which hand appears forward in perspective, but it must never change gameplay meaning, identity, equipment function, faction rank, or collision read.

| Mirror-safety rule | Production requirement |
|---|---|
| **Centered equipment** | Keep the rail, induction core, grip, collar insert, belt clasp, and coat split on the character/weapon centerline. |
| **Bilateral body gear** | Duplicate shoulder panels, forearm guards, gloves, boots, and coat tabs exactly across the body. |
| **No meaningful side assignment** | Prohibit emblems, prosthetics, shields, masks, radios, holsters, pouches, magazines, quivers, side optics, and rank devices. |
| **Stable bounds** | Use identical pivots, ground lines, weapon reach, transparent padding, and nominal hitbox for mirrored directions and for both sex variants. |
| **Symmetrical effects** | Spawn the quarrel and flash from the weapon's central rail; do not use left/right ejection, trailing cables, or side-offset glow. |
| **Ambidextrous posing** | Both hands operate an axially symmetrical weapon with identical gloves; mirrored hand roles carry no narrative or mechanical meaning. |

Although the runtime currently provides four authored directional strips and sets `flip_h = false`, every directional composition should still pass a horizontal-flip review. This protects future atlas reuse, preview mirroring, and generated-frame cleanup from introducing side-dependent continuity errors.

## Detail budget and exclusions

The Gunner should look cleaner than the current placeholder-style Recruit and more specialized in weapon authority, but materially less ornate than any premium faction hero. Limit each sprite view to the five costume colors, one cyan glow source, three material families, one centerline accent, and one weapon. Large and medium shape clarity takes precedence over micro-detail. Brass should appear as small edge breaks rather than jewelry.

Do not introduce alternate guns, backup blades, arrows, drones, masks, familiars, capes, banners, shields, asymmetrical armor, exposed mechanical limbs, luminous eyes, personal heraldry, or named-hero accessories. Do not increase the railbow into a Sniper-tier siege weapon; the next promotion must retain room for a longer silhouette, more advanced sighting mechanism, and stronger signal effect.

## Acceptance checklist

The asset is ready for production approval only when both variants: read as adults at native gameplay size; share one Gunner costume and Signal Railbow; preserve a 3–4-head chibi proportion; read as ranged marksmen in silhouette; remain visibly descended from Recruit; contain no premium-level ornament density; hold stable ground contact; deliver the attack release clearly within the 13-frame strip; return exactly to idle; and remain semantically, visually, and mechanically safe under horizontal mirroring.
