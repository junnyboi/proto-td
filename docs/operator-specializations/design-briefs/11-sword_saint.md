# Operator Specialization Design Brief 11 — Sword Saint

## Design mandate

| Field | Specification |
|---|---|
| **Class ID** | `sword_saint` |
| **Class name** | Sword Saint |
| **Tier** | Advanced (stage 2) |
| **Recruit lineage** | Recruit → Swordmaster → Sword Saint |
| **Gameplay role** | Elite Melee Striker |
| **Gameplay thesis** | A disciplined close-combat operator who overwhelms the assigned priority target with one decisive, readable sword action. |
| **Variant requirement** | One matched clearly-adult male design and one matched clearly-adult female design; both read as experienced operators aged 25–35 rather than premium named heroes. |
| **Rarity posture** | Polished advanced troop specialization, **not** a premium hero: one weapon, one costume construction, no orbiting devices, no jewelry chains, no floating mechanisms, no elaborate mantle, and no unique narrative relic. |

This brief defines exactly one specialization. Its visual hierarchy follows the adult chibi and animated-sprite standards in [ART_DIRECTION.md](../../ART_DIRECTION.md), while its gameplay premise comes directly from [`sword_saint.tres`](../../../data/classes/sword_saint.tres): an advanced `guard_2` operator promoted from Swordmaster whose role is **Elite Melee Striker** and whose description promises decisive close combat. The class's `Overpower` skill doubles its attack output, so the design and motion emphasize timing, control, and a forceful single hit rather than berserker excess.

## Faction inspiration: Lunaris Reliquary, reduced to field-uniform language

**Lunaris Reliquary is the closest faction design language.** Among the four approved faction concepts, it alone contains a canonical ceremonial duelist whose long straight spellblade, dark fitted martial tailoring, teal/cyan separation, and precise posture already express mastery through restraint. This makes it a closer fit than Solcrest's shield-and-formation language, Vesper's information-warfare equipment, or Crimson Aegis's recoil, ram, and forward-impact mass. The Sword Saint borrows only the Reliquary duelist's broad grammar—**violet-black tailoring, ivory structure, brushed-gold hardware, moon-cyan blade energy, and measured martial authority**—not his prestige-specific long ponytail, chains, exposed-arm glamour, ornate mechanisms, asymmetrical coat, or named relic construction. The result should look like a recruit who earned an elite standardized kit, not a lesser copy of a banner hero.

This adaptation is intentionally simpler than the premium designs in [LUNARIS_CHARACTER_DESIGNS.md](../../LUNARIS_CHARACTER_DESIGNS.md). Large flat shapes replace filigree; one centered collar clasp replaces jewelry; a shallow luminous blade channel replaces a complex reliquary mechanism; and a short, symmetrical split tabard replaces sweeping asymmetric panels. At gameplay scale, the operator reads first as **adult swordsman**, second as **advanced class**, and only third as **Lunaris-adjacent**.

## Restrained palette and materials

| Use | Color | Hex | Material/readability rule |
|---|---|---:|---|
| **Dominant textile** | Violet-black | `#211D2B` | Matte fitted coat, trousers, gloves, and boot shadow mass; approximately 50% of visible area. |
| **Structural secondary** | Warm ivory | `#D8D2C3` | Collar, paired shoulder plates, bracer faces, and the two matching front tabard planes; approximately 22%. |
| **Class accent** | Muted deep teal | `#245B5A` | Center placket, belt band, and restrained seam blocks; approximately 15%. |
| **Hardware/edge** | Brushed antique gold | `#A8894F` | Guard, pommel, collar clasp, buckles, and two or three broad armor borders only; approximately 8%. |
| **Energy/read cue** | Moon cyan | `#69D3D0` | Thin blade fuller and a brief attack flare only; approximately 5%, never used as a full-body glow. |

Skin and hair are natural identity colors outside the kit palette. Keep hair in near-black, dark brown, charcoal, or muted ash-brown values so it does not compete with the cyan blade. Material separation must survive the 64-pixel display target: violet-black remains matte, ivory reads as satin-lacquered armor, gold is brushed rather than mirror-bright, and cyan is the sole emissive. Do not add plum seals, faction banners, gemstones, patterned brocade, constellations, dangling ornaments, or secondary accent colors.

## Shared silhouette and construction

The sprite is **approximately 3.5 heads tall**, clearly within the project's three-to-four-head adult chibi standard. Use a mature head at roughly 28% of total height, a compact but developed torso, strong shoulders, a defined waist, long-enough thighs to avoid toddler proportions, enlarged gloved hands, and planted reinforced boots. The neutral silhouette forms a stable **narrow diamond**: shoulder armor supplies the upper width, the centered two-handed sword creates a strong vertical, matching split tabard points narrow toward the knees, and the feet separate into a grounded base.

The defining read is a straight sword centered before the torso, gripped with both hands, with its tip angled slightly down between the feet in idle. The blade should be about 1.05–1.15 times the operator's body height, narrow enough to communicate precision and broad enough to remain legible after downscaling. The blade, paired shoulders, paired bracers, central clasp, belt, two equal tabard panels, and boots form a bilaterally balanced silhouette. No cape, shield, scabbard, hip pouch, shoulder badge, one-sided braid, single pauldron, or side-mounted device may interrupt that balance.

The costume is a standardized high-collared sleeveless-over-undersuit martial coat with a fitted violet-black torso, deep-teal center placket, equal ivory shoulder caps, equal forearm bracers, a centered gold collar lozenge, a plain dark belt with centered gold buckle, and two equal knee-length front-and-back split tabard panels. Fitted trousers and low-heeled armored boots keep the stance agile. Limit every region to one large shape and, at most, one edge accent. The only class mark is a **centered, non-directional four-point lozenge** at the collar; it carries no faction-specific heraldry and remains semantically unchanged under reflection.

### Silhouette checkpoints

At thumbnail scale, reviewers must be able to identify: **(1)** a mature, stern head rather than oversized cute eyes; **(2)** paired shoulder blocks; **(3)** a centered long straight blade; **(4)** two hands visibly controlling the hilt; **(5)** a symmetrical split coat over planted legs. In pure black silhouette, male and female variants should read as the same class family while differing through adult torso geometry and hair mass—not through different armor, exposed skin, weapon size, or animation footprint.

## Matched adult variants

### Male variant

The male Sword Saint is an adult operator aged approximately 28–35 with a lean-athletic build, broad but not heroic-exaggerated shoulders, a developed chest, squared jaw, straight nose, low-set brows, and calm narrowed eyes. His expression is focused and unsmiling rather than angry. Hair is charcoal-black, center-parted, and tied into a **short centered nape knot**; two equal temple locks frame the face without extending past the jaw. No long ponytail, facial tattoo, earring, or prestige ornament is permitted.

His version uses the shared costume without structural changes. The coat sits straighter through the torso, the shoulder caps are fractionally broader, and the belt line is slightly lower. The forearms and hands are robust enough to sell two-handed control. Keep the collar closed and skin exposure limited to face and a small throat wedge. His mature identity comes from the jaw, brow, shoulder-to-waist ratio, and contained posture—not facial hair or extra equipment.

### Female variant

The female Sword Saint is an adult operator aged approximately 26–34 with an athletic, powerfully poised build, mature oval-angular face, defined cheekbones, level brows, and focused eyes with restrained liner. Her silhouette has a clearly adult bust and hip structure but no exaggerated cleavage, pin-up arch, or juvenile softness. Hair is dark ash-brown or near-black in a **center-parted jaw-length blunt bob**, tucked equally behind both ears; both sides have the same length and volume, and no clip or side braid is used.

She wears the **same coverage, armor map, palette, blade dimensions, boots, gloves, and centered class mark** as the male. The coat is shaped to an adult waist and hip line without corsetry; shoulder caps are slightly narrower and the tabard panels flare subtly to clear the hips. Hands remain large enough to read around the shared two-handed hilt. Do not feminize the variant with a skirt, heels, exposed thighs, jewelry, ribbons, a reduced weapon, or a different attack. Her adult identity comes from facial structure, torso proportion, confident stance, and tailored fit.

### Variant matching rule

Both variants use identical weapon geometry, palette placement, armor segmentation, hem length, effect color, frame timing, contact point, pivot, and silhouette envelope. Variant differences are limited to mature face, hair construction, shoulder width, torso shaping, and modest fit adjustments. In side-by-side review they must read as two adults issued the same advanced-class uniform.

## Signature weapon — Meridian Greatblade

The sole weapon is the **Meridian Greatblade**, a centered two-handed straight sword. It has a dark desaturated-steel spine, a warm-ivory inset on each face, a single shallow moon-cyan fuller running precisely along the centerline, a short symmetrical antique-gold crossguard, a dark two-hand grip, and a centered faceted gold pommel. The tip is a simple clipped diamond; the guard has no hooked left/right distinction. Both faces of the weapon are visually equivalent. There is no scabbard, off-hand focus, tassel, charm, key, inscription, floating ring, or detached effect.

The sword reads as advanced through clean proportion, material control, and the cyan channel—not ornament density. In idle, both hands stack close to the body's centerline and the blade occupies the central silhouette. During attack, it remains in both hands. The energy channel may brighten from muted cyan to pale cyan for two impact frames, but it never projects a persistent ranged blade or changes the melee hitbox.

## Animation brief

Production should preserve the current operator contract: four logical directions (`se`, `ne`, `nw`, `sw`), **24 idle frames and 13 attack frames at 12 fps**, each on a 192 × 192 cell. Match the current `guard_2` presentation scale as the starting target—approximately 64-pixel display height, 140-pixel normalized source subject height, and a bottom-weighted pivot near `(0.5, 0.94)`—then verify the planted boot contact against existing recruit and operator sheets. Keep the character centered and fully in frame throughout; motion is in-place and must not imply displacement, knockback, or a moving gameplay footprint.

### Idle loop — measured center guard

The 24-frame loop is a subtle **measured center guard**. Frames 1–6 settle the shoulders down by roughly one source pixel while the sword tip lowers by one to two pixels; frames 7–12 add a restrained inhale, raising the sternum and hands by one pixel; frames 13–18 return through neutral; frames 19–24 complete the exhale and close seamlessly into frame 1. Elbows flex equally, the two tabard panels separate and reunite by no more than one pixel each, and the cyan fuller makes one very soft value pulse at the inhale apex. Feet, pivot, blade centerline, and head facing remain locked. Hair motion is tiny and bilateral: the male nape knot compresses and releases; the female bob tips move equally. No weapon flourish, orbit, foot shuffle, wink, cape wave, or full-body bounce.

### Attack — centered rising cut, impact, disciplined recovery

The 13-frame attack is a readable in-place **centered rising cut** designed around the class's priority-target burst:

| Frames | Phase | Action and readability requirement |
|---:|---|---|
| **1–2** | Anticipation | Knees compress and the sword draws straight down to a centered low guard. Both hands remain on the grip; torso rotation is slight and contains no lateral step. |
| **3–5** | Acceleration | The operator drives upward through the hips and shoulders, cutting from the centered low line toward the target-facing upper diagonal. A narrow cyan edge trail follows the blade only. |
| **6** | Contact | Clearest key pose: arms extended but not locked, sword fully visible past the silhouette, eyes on target. Add a compact cyan-white contact crescent at the blade's forward third; keep it within the melee reach and away from the face. |
| **7** | Follow-through | Carry the blade just beyond contact while the rear heel stays planted; the body does not translate from the pivot. |
| **8–10** | Brake | Elbows fold, shoulders settle, trail vanishes completely, and the blade returns toward the centerline. |
| **11–13** | Recovery | Re-establish the exact idle guard, foot placement, tabard spacing, and weapon angle by frame 13. The final frame may hand off directly to idle without a pop. |

The body should communicate exceptional technique through **fast acceleration and an unmistakable brake**, not multiple slashes. Use one contact flash, one trail, and no camera shake baked into the sprite. For `Overpower`, reuse the same geometry and timing; intensify the fuller to pale cyan for frames 5–7 and widen the contact crescent slightly, preserving the same origin, reach, and gameplay hitbox.

## Horizontal-mirroring safety contract

The design is intentionally **mirror-safe**. Horizontal reflection may change apparent handedness, but it must not change class meaning, equipment logic, hitbox, or identity. Enforce all of the following:

1. The sword is a two-handed, double-faced, geometrically symmetrical weapon; the crossguard, fuller, inset, pommel, and effect are centered.
2. The costume is bilaterally matched: equal shoulder caps, equal bracers, equal tabard panels, equal boot construction, and a centered belt buckle and collar lozenge.
3. Hair is center-parted and balanced. The male knot is on the rear centerline; the female bob has equal side length. No one-sided clip, braid, shaved panel, streak, earring, or eye covering is allowed.
4. No shield, scabbard, holster, pouch, prosthetic, asymmetrical device, readable text, directional rune, faction seal, or side-specific injury may appear.
5. The class lozenge is non-directional. Do not use crescents, letters, arrows, heraldic animals, or any emblem whose facing matters.
6. The idle and attack remain centered on the same planted pivot. Trails are generated from the blade path and mirror with it; the contact flash cannot extend the authored melee reach.
7. If left-facing directions are produced by flipping right-facing art, review the complete sheet after reflection for grip continuity, tabard balance, eye alignment, and identical pixel bounds. If all four directions are authored separately, they must still obey the same mirrored geometry and footprint.

> **Acceptance test:** Cover all color and interior detail and mirror the sprite. A reviewer should see the same class, same equipment loadout, same strike reach, and same tactical information in both orientations; only facing may change.

## Production simplification and exclusions

This specialization must remain materially below premium hero ornament density. Allocate detail in this order: face and adult expression; weapon silhouette and grip; paired shoulders and split tabard; palette blocks; then a maximum of three broad gold edges. At 64-pixel display height, delete any seam, trim, or highlight that becomes a one-pixel sparkle unrelated to material readability. Gold should occupy less area than ivory, and cyan should occupy less area than gold outside the two-frame impact accent.

Do **not** add: a long mantle or cape; lunar halo; suspended ring; hip reliquary; orbiting focus; chain drapery; gemstone array; exposed asymmetrical sleeve; one-sided armor; high slit; detached sleeves; decorative scabbard; secondary knife; shield; pet; drone; banner; elaborate hair ornament; or faction-leader insignia. Avoid the premium Reliquary duelist's long high ponytail and asymmetric coat-panel silhouette. Avoid Solcrest shield geometry, Vesper masks and interference glass, and Crimson recoil armor or shock-sails. The Sword Saint earns distinction through disciplined silhouette and animation quality, not collectible-hero spectacle.

## Review checklist

| Gate | Pass condition |
|---|---|
| **Exactly one specialization** | All art is labeled `sword_saint`; no alternate faction skin, weapon option, or second concept is introduced. |
| **Adult read** | Both variants look 25–35 through mature faces, athletic adult anatomy, tailored combat uniform, and controlled expressions; neither reads as a child or student. |
| **Recruit-derived parity** | Male and female share the same kit, weapon, coverage, scale, animation, and role read. |
| **Role read** | Centered two-handed blade and decisive single cut communicate elite melee striker before faction cues. |
| **Non-premium restraint** | No prestige relic, complex filigree, floating device, ornate jewelry, or sweeping unique costume element. |
| **Chibi readability** | Approximately 3.5 heads tall; adult head/torso cues, paired shoulders, blade, hands, tabards, and boots survive gameplay scale. |
| **Palette control** | Five kit colors only; cyan is the sole emissive and gold remains subordinate. |
| **Idle quality** | Subtle seamless 24-frame breathing loop; fixed feet, pivot, and blade centerline. |
| **Attack quality** | One readable 13-frame in-place rising cut with anticipation, contact, follow-through, brake, and exact recovery. |
| **Mirror safety** | No meaningful left/right asymmetry, directional emblem, side-mounted equipment, prosthetic, shield side, or reflected hitbox change. |
| **Sprite contract** | Four directions, 192 × 192 cells, 12 fps, full subject and weapon inside frame, consistent scale and ground contact. |

## Source references reviewed

- [Protos Visual Art Direction](../../ART_DIRECTION.md), especially the adult character contract, faction identities, chibi translation standard, and animated-sprite source requirements.
- [Lunaris Reliquary Launch Character Designs](../../LUNARIS_CHARACTER_DESIGNS.md), especially the `reliquary_duelist` language and the distinction between canonical premium detail and this standardized operator kit.
- The four approved concept references: [`Faction - Solcrest Accord.webp`](../../Faction%20-%20Solcrest%20Accord.webp), [`Faction - Vesper Circuit.webp`](../../Faction%20-%20Vesper%20Circuit.webp), [`Faction - Lunaris Reliquary.webp`](../../Faction%20-%20Lunaris%20Reliquary.webp), and [`Faction - Crimson Aegis.webp`](../../Faction%20-%20Crimson%20Aegis.webp).
- Class lineage and role data in [`recruit.tres`](../../../data/classes/recruit.tres), [`swordmaster.tres`](../../../data/classes/swordmaster.tres), and [`sword_saint.tres`](../../../data/classes/sword_saint.tres), plus the `guard_2` operator and `Overpower` skill resources.
- Current recruit/operator sprite conventions in the male and female recruit visual resources and sheets, the `guard_2` visual resource and sheets, and the shared [`OperatorAnimationDef`](../../../data/presentation/operator_animation_def.gd) contract.
