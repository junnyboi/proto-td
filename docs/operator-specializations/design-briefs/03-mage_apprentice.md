# Operator Specialization Design Brief 03: Mage Apprentice

## Production identity

| Field | Specification |
|---|---|
| **Class ID** | `mage_apprentice` |
| **Display name** | Mage Apprentice |
| **Tier** | First tier / stage 1 |
| **Promotion origin** | Recruit-derived |
| **Gameplay role** | Arcane Attacker |
| **Runtime operator definition** | `caster_1` |
| **Gameplay read** | Focused magical damage from elevated ground |
| **Variant requirement** | One clearly adult male and one clearly adult female variant, matched as the same rank and training program |
| **Rarity posture** | Polished standard operator; materially simpler than premium named heroes |

This brief defines **exactly one specialization**, Mage Apprentice, expressed through matched male and female recruit-derived variants. It follows the adult chibi contract in the project art direction: both operators must read as at least 21 years old through facial structure, posture, styling, and professional combat dress, even at three-to-four-head proportions.[1] The class data establishes a first-stage Arcane Attacker who deals focused magical damage from elevated ground, so the design emphasizes controlled projection, a compact footprint, and an unmistakable casting action rather than melee armor or support equipment.[2]

## Chosen faction design language

**Closest inspiration: Lunaris Reliquary, interpreted as its practical academy and field-service layer.** Lunaris is the closest fit because its established language already connects ceremonial casters to lunar geometry, restrained cyan energy, circular sacred mechanisms, ivory, violet-black, and brushed gold.[1][3] The concept reference reinforces a caster hierarchy built around dark tailored garments, pale structural panels, circular apparatus, and cool luminous energy.[4] This maps directly to focused arcane damage without borrowing Solcrest's shield-and-formation read, Vesper's information-warfare masks and drones, or Crimson Aegis's impact plate and momentum weapons.[5][6][7]

The specialization must not look like a reduced premium hero or an unnamed fourth member of the launch ensemble. It therefore uses **workmanlike Lunaris training gear**, not prestige ceremonial couture. Remove orbiting chains, translucent capes, exposed fashion cutouts, complex corsetry, multiple floating rings, jewelry constellations, sculpted high heels, and personal relic hardware. Keep only three faction-level signals: one pale tabard shape, a muted violet-black uniform, and a small cyan-lit circular focus. Hardware is brushed brass rather than lustrous display gold. No personal crest, named relic, halo, familiar, or autonomous satellite is permitted.

## Visual thesis and hierarchy

> **A disciplined adult field-caster braces a simple two-handed lunar conduit, gathers one clean cyan charge, and releases a precise bolt.**

At gameplay scale, recognition must resolve in this order:

1. **Large:** compact adult chibi body, broad split tabard, planted boots, and a centered vertical staff.
2. **Medium:** circular staff head, pale shoulder yoke, dark violet torso, and clean hair mass.
3. **Small:** one cyan core, narrow brass edging, belt clasp, and two cuff bands.

There must be no fourth detail tier of filigree. The male and female variants share weapon dimensions, tabard geometry, collar, cuffs, belt, boots, glow placement, animation timing, and overall sprite bounds. Their identity differences live in adult face, physique, hair mass, and subtle tailoring only.

## Restrained palette

| Use | Color | Hex | Application rule |
|---|---|---:|---|
| **Primary uniform** | Violet-black | `#211B2E` | Approximately 50–55%: tunic, trousers/leggings, glove palms, and deepest folds |
| **Structural cloth** | Muted moon-ivory | `#D8D3C7` | Approximately 20–25%: shoulder yoke, narrow center tabard, and staff-head inlay |
| **Secondary cloth** | Dusty lunar plum | `#66506F` | Approximately 10–15%: collar, sleeves, belt, and restrained hem blocks |
| **Hardware** | Brushed training brass | `#A88752` | Approximately 5–8%: staff cage, belt clasp, cuff rims, and minimal edging; never mirror-bright |
| **Arcane energy** | Moon-cyan | `#69D7DE` | Under 5% at rest; reserved for the staff core, attack charge, projectile, and one-frame release flash |

Hair, skin, and eyes use natural character colors and are not additional costume accents. Do not add saturated gold, scarlet, teal, wine glass, green webbing, or secondary magical hues. Energy should be visible but not bloom into the face or erase the staff head.

## Silhouette and proportions

Use a **3.5-head-tall adult chibi**, targeting the current caster's readable presence rather than the smaller recruit placeholder. The silhouette is a stable tapered column: mature head and neck, clear shoulders, fitted torso, a short split tabard ending above the knee, straight legs, and substantial ankle boots. The stance is shoulder-width with knees softly unlocked. It must look like a trained adult holding ground, never a child clutching an oversized prop.

The staff rises from just above the ground to roughly one-quarter head above the hair, giving the class a strong vertical landmark while staying within the 192 × 192 frame. Its circular head sits clear of the face and does not form a halo behind the skull. Keep loose fabric to two short, equal rear panels so motion remains controlled and bilateral. Enlarge hands enough to make the two-handed grip legible. Avoid oversized eyes, tiny feet, rounded toddler limbs, slumped shyness, robes that swallow the body, pointed school hats, graduation motifs, or school-uniform cues.[1]

The default three-quarter view keeps the torso upright and the staff centered along the body's vertical axis. The weapon's head and cyan core are the highest-contrast landmarks. Hair never overlaps the core, hands never disappear into sleeves, and neither tabard half extends beyond the planted boot envelope.

## Shared costume construction

Both variants wear the same standard-issue **Lunaris field-apprentice uniform**:

- A modest, high standing collar in dusty plum, with no brooch or rank gem.
- A fitted violet-black long-sleeve tunic with a simple moon-ivory shoulder yoke. The yoke is an unmarked shallow arc, not a crescent emblem.
- A narrow moon-ivory center tabard split evenly below the belt. It has one brass line at the hem and no text, sigil, chain, or asymmetric seal.
- Dark fitted trousers for both variants. The female cut may taper more closely through the calf; it does not become a skirt, dress, exposed thigh, or heeled silhouette.
- Plain wrist-length gloves with identical brass cuff rims on both arms.
- A centered belt clasp shaped as an undecorated circle. No hip holster, side pouch, potion rack, book, or dangling key.
- Low, broad-soled combat boots with identical left/right construction and no elevated heel.

This construction preserves Lunaris's pale/dark ceremonial rhythm while remaining credible as issued training equipment. Materials should separate cleanly—matte woven cloth, dull leather, brushed brass, and a small emissive core—but texture is broad and economical enough to survive gameplay resolution.

## Adult male variant

The male Mage Apprentice is an **adult man approximately 24–30 in visual read**, lean-athletic rather than bulky. Give him a slightly broader shoulder line, a straight waist, defined jaw, lower-set mature eyes, and a composed, alert expression. His posture is upright with the chest open and elbows controlled; he appears professionally trained, not tentative.

Use a short-to-medium, centrally parted dark ash-brown hairstyle swept back into a compact, symmetrical nape tie. The hair mass may lift subtly during release but has no long side fringe, decorative pin, dyed streak, or faction jewel. Tailor the shared tunic with a straighter torso and squared shoulder yoke. Keep the same tabard width, weapon scale, boots, palette, exposed skin coverage, and animation timing as the female variant. A faint brow angle or restrained under-eye line can reinforce adulthood at sprite scale; do not add facial hair so the face stays clean at 64-pixel display height.

## Adult female variant

The female Mage Apprentice is an **adult woman approximately 24–30 in visual read**, poised and athletic with a mature oval face, defined brows, controlled eyes, and a calm, self-possessed expression. Give her an adult waist-to-hip transition without exaggeration, while retaining the same planted stance and shoulder authority as the male variant. She is a professional combat caster, not an ingenue or magical-girl student.

Use a jaw-to-neck-length dark ash-brown bob with a centered part and both sides tucked evenly behind the ears. The silhouette is clean and balanced; there is no side ornament, ribbon, long ponytail, exposed pin, or one-sided curl. Tailor the shared tunic slightly closer through the waist while preserving full coverage, identical yoke and tabard geometry, flat combat boots, and equal weapon scale. Makeup, if represented at all, is limited to a subtle mature lash line; avoid blush-heavy, wide-eyed, or coy expressions.

## Weapon/focus: Standard Lunar Conduit Staff

The sole equipment silhouette is the **Standard Lunar Conduit Staff**, a bilateral, two-handed training focus. It consists of a straight violet-black shaft, equal brass collars above and below the upper grip, and a closed circular brass cage enclosing one moon-cyan orb. Two small moon-ivory inlays sit at exact top and bottom of the cage. The cage is radially simple and has no crescent cutout, pointer, dangling weight, side vane, readable rune, or directional notch. Front and back construction are identical.

At rest, both hands hold the shaft on the body's centerline: upper hand near sternum level, lower hand near belt level. During casting, the staff may tilt slightly toward the target direction in screen depth, but it must not sweep to a designated left or right side. The conduit is a mass-issued instrument rather than a named relic: no orbiting components, transforming halo, extra blade, book, familiar, or secondary focus.

The circular head gives an immediate arcane read, while the straight shaft and two-handed brace communicate focused ranged output. The design also provides a clean origin point for the projectile and keeps gameplay VFX registration consistent across male, female, and mirrored directions.

## Idle animation

Follow the established operator convention of a **24-frame looping idle at 12 fps** in a 192 × 192 per-frame cell. Preserve a stable foot pivot and keep the subject inside a consistent box. The motion is deliberately subtle:

| Frames | Motion |
|---:|---|
| **1–6** | Neutral brace. Chest rises by approximately 1 pixel at final display scale; shoulders ease upward; cyan core brightens slightly. |
| **7–12** | Weight settles evenly through both boots. Staff head rises no more than 1–2 pixels; elbows flex inward. |
| **13–18** | Core dims to baseline; two equal tabard panels lag downward by 1 pixel. Hair tips make one restrained symmetrical response. |
| **19–24** | Body and staff return exactly to frame-1 pose for a seamless loop. |

No orbiting particles, autonomous staff spin, hand waving, side-to-side sway, eye sparkle, repeated levitation, or large cloth flutter. Boots remain planted and the centered projectile origin does not drift laterally. A blink may occur once near frames 15–16, identically timed for both variants, provided it does not create a cute expression.

## In-place attack and recovery

Follow the current **13-frame non-looping attack at 12 fps**. The attack is a compact gather–brace–release–recover cycle, readable from all four diagonal facings without translation from the deployment tile:

| Frames | Beat | Pose and effect |
|---:|---|---|
| **1–3** | **Gather** | Knees compress slightly and both hands draw the centered staff head down toward the sternum. The cyan core grows from rest size to a crisp contained disc. No lateral wind-up. |
| **4–6** | **Brace** | Torso leans toward the target by a few pixels in screen depth; elbows lock symmetrically around the shaft. The circular cage aligns with the aim vector and a thin cyan ring contracts into the core. |
| **7** | **Release / hit-read frame** | A focused cyan bolt launches from the exact center of the cage. Use one sharp white-cyan core flash and a short tapered trail; the staff and hands remain visible. This is the clearest silhouette frame. |
| **8–9** | **Recoil** | Shoulders and staff return by 1–2 pixels opposite the aim vector; knees absorb the force. Do not step, spin, or cross the feet. |
| **10–13** | **Recovery** | Glow contracts, elbows relax, torso returns upright, and hands settle into the original two-point grip. Frame 13 must connect cleanly to the neutral idle pose. |

The projectile is a small, fast, round-headed bolt rather than a beam, area burst, summoned object, or crescent slash. VFX stays ahead of the body and never obscures the face. The attack conveys precision and recovery, fitting focused magical damage and preventing the first-tier operator from borrowing premium-scale spectacle.

## Horizontal-mirroring safety contract

**Mirror-safe: yes.** The design must remain semantically identical under horizontal reflection.

1. All meaningful construction is centered or bilateral: staff, core, cage, belt clasp, collar, yoke, split tabard, cuffs, boots, and glow origin.
2. There is no faction emblem, readable rune, numeral, text, rank stripe, directional crescent, or hand-specific control surface.
3. There is no prosthetic, eyepatch, monocle, one-sided mask, side pouch, shield, familiar, drone, hip mechanism, holster, shoulder plate, or unequal sleeve.
4. Both hands use equivalent gloves. The two-point grip may visually exchange leading/trailing screen position when mirrored, but neither hand performs a unique function and the staff remains on the centerline.
5. The projectile and gameplay hit origin remain at the exact center of the circular cage in every direction. The body, feet, and staff must not change collision or targeting bounds between mirrored facings.
6. Hair is center-parted and unadorned. Any painted strand variation is cosmetic only and must not resemble an insignia or equipment device.
7. If production elects to derive NW from NE and SW from SE through reflection, inspect the result for equal staff registration, hand contact, foot pivot, tabard spacing, and face readability. Mirroring must not be used if it displaces the projectile socket.

## Sprite-production specifications

Current recruit and caster assets establish 192 × 192 cells, four diagonal directions (`ne`, `nw`, `se`, `sw`), a 24-frame looping idle, a 13-frame non-looping attack, and 12 fps playback.[8][9][10] Mage Apprentice should retain that contract. The current caster visual uses a 64-pixel display height, normalized subject height of 158 pixels, and a bottom-biased pivot of `Vector2(0.5, 0.94)`; use this as the initial implementation target so the specialization reads as a caster and does not inherit the recruit's smaller 58-pixel placeholder presence.[8]

| Item | Production target |
|---|---|
| **Cell size** | 192 × 192 pixels |
| **Directions** | NE, NW, SE, SW |
| **Idle** | 24 frames, looped, 12 fps |
| **Attack** | 13 frames, non-looping, 12 fps |
| **Initial display height** | 64 pixels |
| **Initial normalized subject height** | 158 pixels, including staff silhouette but excluding transient VFX where tooling permits |
| **Initial pivot** | `Vector2(0.5, 0.94)`; feet visually locked across all frames |
| **Framing** | Full body, staff, and effects remain inside cell; no crop or scale change between actions |
| **Directional consistency** | Identical costume, palette, weapon proportions, hand contact, and projectile socket across all views |

The 3.5-head anatomy should be judged at final gameplay scale, not only in the source sheet. Separate dark hair from the violet-black tunic with skin, ivory collar/yoke, or restrained value shifts. Preserve a clean alpha edge; avoid fine cyan sparks that collapse into compression noise.

## Differentiation from premium heroes

| Standard Mage Apprentice | Premium Lunaris hero language intentionally withheld |
|---|---|
| One mass-issued staff with one fixed ring | Named orbiting astrolabe, expanding halo, spellblade, or reliquary system |
| Five controlled costume colors | Character-specific luxury color identity and layered material spectacle |
| Plain fitted tunic, yoke, tabard, trousers, boots | Sculpted corsetry, sheer panels, long couture skirts, exposed fashion cutouts, complex mantle construction |
| Two cuff rims and one belt clasp | Chains, suspended weights, jewelry, constellation markings, multiple mechanisms |
| One contained charge and focused bolt | Gravity fields, ring expansion, elaborate ritual trails, monumental VFX |
| Symmetric issued uniform | Hero-defining asymmetry and personal artifacts |
| Subtle breath-and-core idle | Persistent levitation, orbiting systems, dramatic hair and fabric motion |

The target is **polished restraint**, not generic simplicity. Shape alignment, face quality, material separation, hand contact, and animation recovery must receive premium-level craft, while the number of ideas, moving parts, ornament layers, and VFX channels stays decisively first-tier.

## Review checklist

Approve only if both variants satisfy all of the following:

- They are unmistakably adult at chibi scale through mature face, posture, clothing, and expression.
- They read as the same specialization and rank before they read as different genders.
- Lunaris influence is visible through palette, circular arcane geometry, and ceremonial restraint, without resembling a named premium hero.
- The centered two-handed staff is the only weapon/focus and remains fully gripped in every frame.
- The silhouette resolves as head, shoulders, split tabard, planted boots, and circular-topped staff at gameplay scale.
- Palette usage stays within the five specified costume/energy colors, with cyan reserved for function.
- Idle motion loops without foot sliding, lateral socket drift, or excessive secondary animation.
- Attack has a distinct gather, frame-7 release, recoil, and full recovery while staying in place.
- Horizontal mirroring changes no meaningful device, emblem, side assignment, hand function, projectile origin, or hitbox.
- No school cues, pointed novice hat, juvenile proportions, cute shyness, excessive ornament, floating companion, or premium-scale ritual display appears.

## References

[1]: ../../ART_DIRECTION.md
[2]: ../../../data/classes/mage_apprentice.tres
[3]: ../../LUNARIS_CHARACTER_DESIGNS.md
[4]: ../../Faction%20-%20Lunaris%20Reliquary.webp
[5]: ../../Faction%20-%20Solcrest%20Accord.webp
[6]: ../../Faction%20-%20Vesper%20Circuit.webp
[7]: ../../Faction%20-%20Crimson%20Aegis.webp
[8]: ../../../data/presentation/operator_visuals/caster_1.tres
[9]: ../../../data/presentation/operator_visuals/recruit_male.tres
[10]: ../../../data/presentation/operator_visuals/recruit_female.tres

---

**Canonical brief outcome:** a matched adult male/female Lunaris field-apprentice pair in a restrained violet-black and moon-ivory uniform, each bracing the same centered Standard Lunar Conduit Staff for a precise moon-cyan projectile attack. The result is clearly arcane, readable, mirror-safe, recruit-derived, and deliberately below premium-hero ornament density.
