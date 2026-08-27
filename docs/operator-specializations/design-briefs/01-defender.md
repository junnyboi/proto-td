# Operator Specialization Design Brief 01 — Defender

## Design mandate

This brief defines **exactly one** recruit-derived, non-premium first-tier specialization for Protos: **Defender** (`defender`, operator definition `defender_1`), whose gameplay role is **Lane Anchor**. The specialization promotes the Recruit’s practical dark field uniform into a more protective, faction-coded issue kit without acquiring the unique face treatment, elaborate hair, jewelry, asymmetrical couture, floating mechanisms, layered filigree, or spectacular effects reserved for premium heroes.

The matched presentation consists of one clearly adult male variant and one clearly adult female variant of the **same issued specialization**. They share the same silhouette logic, equipment, palette distribution, animation timing, footprint, and gameplay read. Sex-specific differences are limited to adult face, build, and hair construction; neither variant is a separate character concept or alternate specialization.

## Source basis and gameplay read

The design follows the project’s [art direction](../../ART_DIRECTION.md), including the requirement that chibi units remain recognizable abstractions of adults, stand approximately three to four heads tall, prioritize large and medium shapes over micro-detail, and keep weapons legible at runtime scale. The premium [Lunaris designs](../../LUNARIS_CHARACTER_DESIGNS.md) establish the upper quality bar but are intentionally not copied: the Defender has no signature jewelry, ritual orbitals, translucent couture, extensive gold chainwork, elaborate hair mass, or rarity-defining asymmetry.

The four approved faction concepts were compared directly. Lunaris is too ceremonial and prestige-caster-oriented for an issued first promotion; Vesper’s narrow technical asymmetry, masks, drones, and interference glass oppose the desired broad stable read; Crimson Aegis communicates aggressive forward momentum and breaching rather than patient containment. **Solcrest Accord is the closest design language** because its civic lamellar, upright formation posture, broad ward planes, white-gold structure over black, and deep-teal oath textiles directly communicate blocking several enemies and surviving sustained pressure. This Defender uses the inexpensive line-infantry end of Solcrest language, not the ornate command-hero end shown in the concept.

The class data establishes a first-stage promotion from Recruit, **block 3**, melee placement, same-tile attack range, high survivability emphasis, and a 30-tick attack interval. The visual thesis is therefore **“the brace at the center of the lane”**: a low, wide operator whose centered bulwark makes the occupied tile feel closed even before an enemy reaches it.

## Specialization concept: Dawn Brace

**Dawn Brace** is the production-facing concept name for this one Defender specialization. It describes a rank-and-file Solcrest auxiliary issued a compact ward-pavise and simplified civic lamellar. The operator is polished enough to read as a meaningful promotion from Recruit, but materially below premium heroes: five principal armor masses, one textile accent, one simple metal trim system, no personal crest, and one weapon with a single restrained energy response.

| Attribute | Locked direction |
|---|---|
| Class ID | `defender` |
| Class name | Defender |
| Tier | First tier / stage 1 |
| Gameplay role | Lane Anchor |
| Operator definition | `defender_1` |
| Promotion source | Recruit |
| Faction inspiration | Solcrest Accord, rank-and-file Dawn Phalanx issue kit |
| Variant set | Matched clearly adult male and female |
| Rarity posture | Polished non-premium; functional rather than personalized |

## Restrained palette and materials

| Color | Value | Application |
|---|---:|---|
| **Charcoal black** | `#181D22` | Recruit-derived fitted underlayer, trousers, gloves, boots, weapon recesses |
| **Civic ivory** | `#D8D1BE` | Three broad torso lamellae, shoulder caps, primary bulwark face |
| **Deep oath teal** | `#245B5A` | Short centered waist tab, collar inset, narrow shield channel |
| **Brushed brass** | `#A9823E` | Sparse armor rims, rivets, shield perimeter and central spine |
| **Sunstone amber** | `#E6B557` | Small central ward lens and brief attack pulse only |

The value hierarchy must survive the approximate 60-pixel runtime display: charcoal separates the body; ivory defines protection; teal gives Solcrest identity; brass is a thin structural separator; amber is reserved for state feedback. Metals are brushed rather than mirror-polished. Cloth is matte and armor is lightly worn but clean. Do not introduce cyan, violet, red, white bloom, leather-brown belts, extra gems, heraldic multicolor, or extensive gold filigree.

## Silhouette and costume construction

Use a **3.4–3.6-head-tall adult chibi**. The head is enlarged for expression but not infantile; eyes are controlled and proportionally smaller than a cute mascot’s. Broad shoulder caps, a compact armored torso, planted boots, and the large centered pavise create a squat trapezoid that reads immediately as a blocker. The body’s widest point is the shoulders and upper shield; the feet remain visible on either side of the lower weapon so grounding and recovery can be read.

The armor is an issued half-lamellar worn over the Recruit’s charcoal field layer: three large overlapping ivory torso plates, two simple shoulder caps, dark bracers, one-piece shin guards, and sturdy flat-soled boots. A short deep-teal waist tab hangs on the exact centerline and ends above the knees; it is not a long cape or side sash. Brass appears only as narrow plate edges and large readable rivets. There is no helmet, cape, skirt train, standard, jewelry, chain, personal emblem, unit number, reliquary, prosthetic, pouch cluster, or side-mounted device.

Hair remains compact and clear of the weapon and shoulders. The silhouette must fit consistently in a locked 192 × 192 frame without cropping, with the current Defender presentation target of approximately **60 pixels display height** and a grounded lower pivot close to the existing `Vector2(0.5, 0.94)` convention. Preserve consistent scale in all four diagonal views.

## Matched adult variants

### Male variant

The male Defender is unmistakably an adult in his late twenties or thirties, with a broad neck, square mature jaw, straight brows, and a calm, watchful expression. His build is broad-shouldered and sturdy rather than bodybuilder-large. Short dark umber hair is brushed back in one compact mass with a modest front break; no spikes extend beyond the shoulder line. Light stubble may appear in portrait art but should reduce to a subtle jaw shadow, not noisy pixels, in the sprite.

His armor, shield dimensions, hand placement, waist tab, boots, and animation arcs are identical to the female issue pattern. The torso plates may sit slightly broader over the ribcage, but the overall subject height and combat footprint must match the female variant. His stance communicates trained restraint: chin level, knees softly bent, feet planted just wider than the hips.

### Female variant

The female Defender is unmistakably an adult in her late twenties or thirties, with a mature oval-to-angular face, defined brows, steady narrowed eyes, and an athletic, powerful build. Her dark umber hair is arranged in a compact low braided knot centered at the back of the head, with two short temple locks kept close to the cheeks. The knot must stay within the head silhouette and must not become a youthful high ponytail, oversized bow, or flowing premium hair feature.

Her armor uses the same coverage and components as the male kit. The three torso lamellae are fitted cleanly over adult anatomy without cleavage framing, exposed midriff, high heels, skirt coding, or decorative corsetry. Slightly tapered shoulder-to-waist shaping and the mature face distinguish her without weakening the blocker silhouette. Shield size, grip spacing, planted stance, total subject height, attack reach, and recovery timing remain matched to the male variant.

## Signature equipment: Sunbar Ward-Pavise

The specialization has **one weapon only**: the **Sunbar Ward-Pavise**, a vertically oriented, bilaterally symmetrical two-handed shield-weapon held on the operator’s facing centerline. Its outline is a compact clipped-arch rectangle: broad shoulders, nearly straight sides, clipped lower corners, and a shallow central foot. It is tall enough to cover from upper chest to shin in neutral stance but not so tall that it hides the face or feet.

The shield face uses two large ivory planes divided by a straight brass central spine. A small round amber ward lens sits exactly on both the shield’s vertical axis and the operator’s sagittal axis. The rear uses one centered horizontal grip bar; both hands grasp it at equal distances from center. There are no left/right straps, side scabbards, offset generators, heraldic animals, directional runes, written text, or shield-side tactics. The perimeter is blunt. It attacks through a short body-driven shield check, not a blade edge, projectile, or detached ward.

At chibi scale the shield should occupy roughly one third of the full character width in ready stance and become the dominant central mass during contact. Ivory and brass remain broad and graphic. The amber lens may brighten by one value step during impact but must not produce a large magical barrier, orbiting parts, or premium-grade spectacle.

## Animation direction

Current Recruit and operator resources establish four diagonal direction assets (`ne`, `nw`, `se`, `sw`), **24-frame idle and 13-frame attack strips at 12 fps**, centered locked framing, and an in-place melee presentation. Dawn Brace should use this same production convention for both adult variants.

### Idle loop

The 24-frame, two-second idle is a restrained **brace-and-breathe** loop. Frames 1–6 settle the weight evenly with the shield centered and its foot hovering just above the ground. Frames 7–12 lower the shoulders and shield by approximately one to two sprite pixels with a small exhale; the elbows compress symmetrically. Frames 13–18 return to neutral as the amber lens rises no more than one restrained value step. Frames 19–24 hold and ease seamlessly into frame 1. Hair, waist tab, and armor move only enough to avoid a frozen cutout. The feet do not slide, the weapon does not sway side to side, and the shield never leaves the body centerline.

### In-place attack and recovery

The 13-frame attack is a readable **centerline ward-check** with a complete recovery. Frames 1–3 are anticipation: knees compress, hips move back one to two pixels, and the shield draws close to the sternum while remaining vertical. Frames 4–6 drive forward in place with both hands, shoulders square, and the shield translating along the facing axis; the feet remain planted within the tile. Frame 7 is contact: the shield reaches maximum extension, the amber lens gives a compact pulse, and the torso is at its lowest stable brace. Frames 8–10 recoil a few pixels without an overshoot or side twist. Frames 11–13 restore the neutral guard and must visually hand off cleanly to the idle loop.

The action is defensive force, not a running bash. There is no leap, spin, lateral sweep, shield throw, weapon swap, ground fissure, displaced barrier, or prolonged glow. The impact frame must remain legible when seen once at runtime speed, while the recovery clearly returns the operator to lane-blocking readiness.

## Horizontal-mirroring contract

This design is **fully horizontal-mirror-safe**. Meaningful information sits on the centerline or is bilaterally paired. The ward lens, shield spine, teal tab, collar inset, grip bar, and attack contact point are centered. Shoulder caps, bracers, boots, rivets, and plate divisions are matched left-to-right. Neither variant carries an emblem, prosthetic, monocle, eyepatch, side pouch, rank cord, one-sided hair ornament, off-hand shield, side-mounted generator, or asymmetric injury.

Hair asymmetry must also be cosmetic-neutral: the male front break is centered or visually even, and the female braided knot is centered; loose locks must be paired. Lighting painted into the sprite must describe form rather than imply a fixed world-side light or a faction-coded side. The weapon collision and visual contact point remain centered on the facing axis. If directional production renders only one east/west member of each diagonal pair and mirrors it, the mirrored result preserves identity, function, silhouette, and hit-read exactly.

## Simplification and rejection criteria

Dawn Brace must remain visibly below premium rarity while still polished. The correct detail budget is three torso plates, two shoulder caps, two bracers, two shin guards, one short central tab, and one shield with a single spine and lens. Large, clean separations take priority over ornament.

Reject any iteration that introduces a one-handed or side-carried shield; an offset weapon, device, crest, seal, or glow; a cape or long side sash; Solcrest command-standard ornament; Lunaris rings or chains; Vesper masks or drones; Crimson shock-sails or ram-lances; juvenile facial proportions; high heels; exposed midriff; excessive hair motion; shield coverage that hides both feet; lateral displacement during attack; mismatched variant scale; or effects that enlarge the perceived hitbox. Also reject a palette drift that lets brass dominate ivory or lets amber read continuously as a premium magical aura.

## Production acceptance checklist

| Review gate | Acceptance condition |
|---|---|
| Adult read | Both faces, posture, builds, and styling clearly communicate age 21+ |
| Class read | Broad low trapezoid, planted feet, and centered pavise read as Defender at thumbnail size |
| Role read | Neutral pose visibly closes the lane; attack preserves position and returns to guard |
| Recruit lineage | Charcoal field underlayer and practical construction remain visible beneath promoted armor |
| Faction read | Ivory/brass civic lamellar and teal oath textile identify restrained Solcrest influence |
| Non-premium tier | No bespoke emblem, jewelry, couture asymmetry, elaborate hair, orbitals, cape, or spectacular effects |
| Variant match | Same kit, weapon, scale, footprint, timing, palette placement, and contact point for male and female |
| Mirror safety | No meaningful left/right information; all functional devices and hit-read remain centered or paired |
| Runtime fit | Four diagonal directions; 24-frame idle and 13-frame attack at 12 fps; locked 192 × 192 framing; approximately 60-pixel display height |
| Animation clarity | Subtle looping idle; one readable centerline impact; no tile travel; complete 3-frame visual recovery |

This specification is the canonical design and motion brief for the single first-tier Defender specialization and its matched recruit-derived adult variants.
