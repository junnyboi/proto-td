# Banner Guard (`banner_guard`) — Operator Specialization Design Brief

## Design mandate

This brief defines **exactly one recruit-derived, non-premium operator specialization**: **Banner Guard**, an **advanced-tier Support Vanguard** promoted from Shock Trooper. The class fantasy is a disciplined field standard-bearer who preserves deployment tempo and rallies nearby allies. It must look polished enough to belong in Protos while remaining materially simpler than premium heroes: the appeal comes from a decisive standard silhouette, mature bearing, strong color blocking, and clean motion rather than couture layering, floating mechanisms, jewelry, micro-filigree, or unique narrative artifacts.

The male and female presentations are matched variants of the same issued uniform and equipment. Both are clearly adult professionals, age 21 or older. Their faces, stance, proportions, tailoring, and expressions must read as mature even after the three-to-four-head chibi translation.

## Source alignment and faction choice

The class data establishes `banner_guard` as stage 2, promoted from `shock_trooper`, with operator definition `vanguard_2`, role **Support Vanguard**, and the description “Rallies nearby allies while maintaining deployment tempo.” The associated **War Banner** skill reinforces a brief, local rally effect. Existing recruit presentation establishes four diagonal directions, 24-frame idle and 13-frame attack strips at 12 fps, a centered pivot at `(0.5, 0.770833)`, 58 px display height, and a normalized subject height of 106 px within 192 px frames. The new art should retain that production envelope and grounded isometric footprint.

**Closest faction language: Solcrest Accord — the Dawn Phalanx.** Of the four concept references, Solcrest is the direct functional and visual match because its identity is built around disciplined formation silhouettes, upright standards, white-gold civic armor, deep-teal oath cloth, and linked ward planes. Vesper Circuit’s covert masks and signal equipment conflict with a public rally role; Lunaris Reliquary’s orbital ritual luxury is too prestigious and caster-coded; Crimson Aegis’s shock-sails and momentum-heavy breach equipment overstate aggression and recoil. Banner Guard therefore uses a **simplified line-infantry reading of Solcrest**, not the monumental, jewelry-rich treatment of a premium Solcrest hero.

The unit should suggest that ordinary recruits have earned better civic equipment and responsibility. Retain recruit-derived practicality through fitted dark underlayers, stout boots, compact armor zones, uncomplicated belts, and a direct ready stance. Upgrade the lineage through the upright standard, an ivory chest lamella, deep-teal oath panel, and a small amber ward core.

## Visual thesis and hierarchy

> **A steady adult line officer framed by one tall, centered standard: dark practical body, ivory civic chest, teal oath cloth, and one amber rally signal.**

At gameplay scale, the reading order is: **(1) tall crossbar-and-banner crown, (2) broad ivory chest block and adult head, (3) centered two-handed dark shaft, (4) teal lower coat block, (5) small amber core flash**. The banner should contribute more to recognition than hair, armor ornament, or VFX.

The design uses approximately **3.5 heads of total body height**, excluding the standard’s finial. The head is enlarged for expression without becoming round or juvenile; the torso is compact but adult, the shoulders are structured, the hips and legs remain long enough to imply a grown body, and the hands and boots are slightly enlarged for readable grip and grounding. The standard rises roughly half a head above the operator and creates a vertical central spine. A short, symmetrical crossbar and two equal cloth tails form a clear T/arrow silhouette. The tails end above the knees so they do not merge with the legs or enlarge the ground footprint.

The silhouette must remain clean in all four diagonal views. Avoid capes, side shields, oversized pauldrons, one-sided pouches, hip reliquaries, trailing ponytails past the shoulder blades, or cloth wider than the shoulders. From a distance, both variants should appear as the same class before gender or face details are noticed.

## Restrained palette and material allocation

| Palette element | Suggested color | Approximate use | Material and purpose |
|---|---:|---:|---|
| **Charcoal black** | `#20242B` | 40% | Matte under-suit, trousers, gloves, boots, and standard shaft; preserves recruit practicality. |
| **Civic ivory** | `#D8D2C2` | 24% | Satin-painted lamellar chest, compact shoulder shells, and banner field; primary class-value block. |
| **Oath teal** | `#17666A` | 22% | Twill collar, waist tabard, piping, and equal banner tails; carries Solcrest identity without premium saturation. |
| **Brushed antique gold** | `#A98245` | 10% | Crossbar, finial edge, buckles, lamella rims, and core housing; broad simple edges only, no filigree. |
| **Sunrise amber** | `#F2B84B` | 4% | Ward-core lens and brief rally VFX; the only emissive color. |

Skin and hair are identity variables rather than class palette slots, but hair values should remain natural and separated from both charcoal and ivory. Gold is a structural accent, not decoration. Cyan, violet, scarlet, chrome-white bloom, gemstones, and secondary glow colors are excluded. Use clear matte cloth, satin-painted plate, brushed metal, dark leather, and restrained translucent amber energy as the complete material set.

## Shared uniform construction

Both variants wear the same issued construction: a charcoal high-neck under-suit; a compact sleeveless ivory lamellar cuirass with four or five large readable bands; shallow symmetrical shoulder shells; fitted charcoal gloves and forearm guards; a deep-teal collar and centered split waist tabard; dark straight trousers; and low-ornament, square-toed field boots. A narrow belt has one centered rectangular buckle. The only insignia is a simple **bilaterally symmetric eight-ray civic mark** embossed on the centered chest clasp and repeated as a large flat shape on the banner. It is not tied to left or right and does not contain text.

The outfit must not use luxury chains, translucent overskirts, exposed corsetry, high heels, elaborate hair jewelry, orbiting parts, or hero-specific relics. Seam lines are limited to those needed to explain construction. The front and back may be distinguished by collar and tabard geometry, but left and right halves remain functionally equivalent.

## Male variant

The male Banner Guard is an unmistakably adult man with a broad, athletic line-infantry build, a defined jaw, straight mature brows, and a calm, watchful expression rather than a boyish grin. His stance is square and weighty, with shoulders relaxed behind the centered standard and knees softly braced. Use short, swept-back dark brown or ash-brown hair with a modest angular forelock; it must not cover the eyes or create a one-sided tail. Light temple texture or subtle under-eye definition can reinforce adulthood at portrait scale, but avoid a unique scar because it would become a meaningful mirrored asymmetry.

His cuirass is cut slightly wider across the upper torso, his forearm guards are marginally thicker, and his waist tabard falls straight. These are fit adjustments, not additional armor tiers. His gloves, emblem, standard, palette, trim count, and animation timing exactly match the female variant.

## Female variant

The female Banner Guard is an unmistakably adult woman with an athletic, powerfully poised build, mature almond-shaped eyes, defined cheek and jaw structure, and a composed command expression. Her body is not miniaturized relative to the male: preserve equivalent head-to-body ratio, hand scale, boot scale, standard size, grounded stance, and screen-space authority. The cuirass is shaped cleanly over an adult torso without cleavage framing or corset exaggeration; the waist is fitted but the uniform remains practical and fully combat-functional.

Use a chin-length dark chestnut blunt bob with both sides tucked back equally, or a compact centered low bun fully contained behind the head silhouette. No side braid, ribbon, long ponytail, asymmetric fringe, or ornamental pin is permitted. The waist tabard may flare slightly over the hips but keeps the same centered split and knee-above endpoint as the male version. She receives no extra skirt, jewelry, exposed thigh, heel, or decorative trim. Her authority comes from mature facial design, upright posture, and precise grip rather than glamour additions.

## Signature weapon/focus: Oath-Pike Standard

The class carries one device only: the **Oath-Pike Standard**, a two-handed polearm and rally focus. It consists of a straight charcoal shaft; a compact, bilaterally symmetric spearhead/solar finial; a short gold crossbar; two equal rectangular-swallowtail cloth panels; and one centered amber sunstone where crossbar and shaft meet. The ivory banner field carries the centered eight-ray civic mark with equal teal tails. Its broad shapes survive downsampling, while its restrained hardware keeps it visibly below premium-hero ornament density.

The standard is held **on the operator’s sagittal centerline with both hands**, upper hand near the sternum and lower hand near the belt. It stays within a narrow vertical corridor in idle and recovery. There is no shield, sidearm, back weapon, off-hand beacon, separate familiar, or detachable device. The standard is a weapon, skill focus, and silhouette anchor in one, reducing both asset complexity and mirroring risk.

## Animation direction

### Idle loop

Use the established **24 frames at 12 fps** for a two-second loop. Boots and the base of the standard remain locked to the same ground point. The torso rises and settles by only one to two source pixels through a controlled breath; elbows open by a similarly small amount while both hands maintain contact and do not slide through the shaft. The head makes one restrained scan toward the lane and returns to neutral. The two equal banner tails lag the body by one to two frames, each moving with the same amplitude in opposite contour, and the amber core performs one low-intensity pulse near the breathing apex. No marching, weapon twirl, salute, cloth whip, floating particle orbit, or full-body sway is allowed. The loop should communicate alert steadiness and remain visually quiet beside active combat.

### In-place attack and recovery

Use the established **13 frames at 12 fps**, with a readable anticipation, centered impact, and complete recovery. Frames 1–3 lower the center of gravity and slide both hands a short distance down the shaft. Frames 4–6 raise the standard by approximately one hand-width and drive its ferrule straight back into the same planted center point; the body compresses vertically rather than translating. Frame 6 is the impact pose: the amber core flashes and emits one low, thin, symmetrical diamond/ward ring hugging the ground plane. Frames 7–9 hold the brace briefly while the equal banner tails kick upward together. Frames 10–13 dissipate the ward plane, return the hands to their original marks, restore the torso height, and settle the cloth into the exact idle entry pose.

The action reads as a forceful rally strike rather than a spellcasting flourish. Keep the operator inside the idle footprint throughout; the standard may extend vertically but cannot sweep into adjacent tiles. The effect center, damage/support origin, contact shadow, and gameplay hitbox remain unchanged. The amber ward ring is brief and low-opacity, never obscuring the feet or neighboring units.

## Mirroring and directional production rules

Horizontal mirroring is explicitly safe because every gameplay-significant feature is centered or bilaterally symmetric. The same rules apply to male and female variants.

| Constraint | Production rule |
|---|---|
| **Equipment** | Standard remains centered and two-handed. No shield, sidearm, side beacon, shoulder device, prosthetic, or one-sided sheath may be added. |
| **Insignia** | Chest and banner use only the centered eight-ray emblem. Do not use letters, numerals, directional arrows, heraldic animals facing one way, rank stripes, or left/right unit patches. |
| **Costume** | Shoulder shells, gloves, belt fittings, pouches, tabard halves, boot guards, and gold trim must be paired and equal. Any necessary fastener is visually neutral at sprite scale. |
| **Hair and face** | Hair masses must be broadly bilateral; no meaningful side braid, eyepatch, monocle, scar, earring, pin, or unilateral makeup mark. |
| **Cloth and core** | Banner tails are equal and the sunstone sits on the shaft center. Mirrored cloth motion must not imply a fixed prevailing wind or alter effect timing. |
| **Motion and gameplay** | Foot plant, pivot, standard contact point, ward origin, and hitbox remain centered. Mirroring changes facing only; it must not change reach, occupied pixels used for collision, attack timing, or support radius. |

Produce canonical southeast and northeast sequences and derive west-facing counterparts by horizontal mirror only if the engine pipeline permits; otherwise, hand-authored west frames must obey the same symmetric construction and registration. In every direction, keep the established centered pivot at `(0.5, 0.770833)`, normalize the adult subject to approximately 106 px inside each 192 px frame, and target the existing 58 px gameplay display height. The finial may use upper transparent margin, but neither cloth nor VFX may clip.

## Premium-distance and acceptance criteria

The Banner Guard should feel like a high-quality earned promotion, not a collectible premium hero. Limit the costume to one cuirass, one under-suit, one centered tabard, paired guards, boots, and the single Oath-Pike Standard. Use no more than one emblem, one emissive core, and one short-lived VFX motif. Large shape discipline, clean material separation, mature faces, and animation polish are mandatory; ornament density is intentionally low.

Final approval requires that both variants read as the same Support Vanguard class at thumbnail size; both read clearly as adults; the standard remains the dominant silhouette; ivory, teal, and amber separate cleanly from charcoal; the idle is subtle and perfectly looping; the attack lands in place and visibly recovers; all equipment and insignia remain mirror-safe; and no premium-coded chains, orbiting relics, excessive gold, couture asymmetry, or multi-color bloom has entered the design.

## Repository references consulted

This specification is grounded in `docs/ART_DIRECTION.md`, `docs/LUNARIS_CHARACTER_DESIGNS.md`, all four `docs/Faction - *.webp` concept references, `data/classes/banner_guard.tres`, `data/classes/shock_trooper.tres`, `data/skills/war_banner.tres`, the recruit operator definition, the male and female recruit presentation resources, and the current recruit/vanguard animated sprite sheets.
