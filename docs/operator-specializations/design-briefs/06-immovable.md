# Operator Specialization Design Brief 06 — Immovable

## Production identity

| Field | Specification |
|---|---|
| **Class ID** | `immovable` |
| **Class name** | **Immovable** |
| **Tier** | **Advanced** (`stage = 2`) |
| **Promotion source** | Recruit-derived **Defender** (`promotion_from_class_id = defender`) |
| **Gameplay role** | **Fortress Defender** |
| **Gameplay thesis** | “Endures the heaviest lane pressure without yielding ground.” |
| **Operator visual target** | `defender_2` |
| **Premium status** | **Non-premium operator specialization**; polished and faction-coherent, but materially simpler than named premium heroes |
| **Variant requirement** | Matched, clearly adult male and female variants, both visibly age 21+ |

> **Visual thesis:** A disciplined Solcrest line-holder becomes a human gate: broad white-gold civic armor, a low planted stance, and one centered two-handed ward-maul make “cannot be moved” readable before any effect appears.

This brief defines **exactly one specialization**, expressed through two sex variants of the same issued uniform and equipment. The male and female designs are not separate characters or rarity treatments. They must share the same gameplay silhouette family, palette distribution, weapon dimensions, animation timing, footprint, and hitbox assumptions.

## Source alignment and faction choice

The closest design language is the **Solcrest Accord / Dawn Phalanx**. Among the four faction concepts, Solcrest most directly communicates civic defense through white-gold lamellar, dark underlayers, deep-teal oath cloth, broad stable armor masses, disciplined formation posture, and projected ward planes. Its architectural, upright visual grammar supports a Fortress Defender more naturally than Vesper Circuit’s narrow information-warfare asymmetry, Lunaris Reliquary’s ornate prestige ritualism, or Crimson Aegis’s forward-driving breach momentum.

The design selectively adapts Solcrest rather than copying its premium ensemble. It keeps the faction’s **white civic plate over near-black cloth, restrained gold construction, teal oath accent, and planar ward energy**, but removes hero-grade filigree, jewelry, long ceremonial trains, elaborate sun halos, exposed glamour tailoring, and individualized relic mechanisms. The result should look like a highly trained promoted recruit issued superior line equipment—not a named banner hero.

The four faction concepts were reviewed comparatively. Crimson Aegis offers useful physical weight, but its shock-sails, wedges, ram-lances, and impact posture describe forceful advance rather than unyielding lane control. Lunaris and Vesper depend on delicate mechanisms, floating devices, asymmetry, and prestige detailing that would both overstate rarity and complicate horizontal mirroring. Solcrest therefore provides the clearest mechanical and production fit.

## Design hierarchy and complexity budget

The specialization must read in three passes:

1. **Large shapes:** broad squared shoulders, compact head, flared armored hip line, wide planted boots, and a centered vertical ward-maul.
2. **Medium shapes:** three-segment chest lamellar, paired forearm guards, paired knee plates, short split tabard, and rectangular maul head.
3. **Small accents:** one narrow teal collar/sash band, a plain plum oath seal at the centerline, limited gold edge caps, and one cyan ward slit in the weapon.

Use no more than **three major armor regions** on the torso and no more than **one readable gold trim line per plate group**. Avoid micro-filigree, chains, gemstones, floating ornaments, layered translucent fabric, animated hair ornaments, elaborate cape structures, or multiple energy emitters. The finish should remain clean, deliberate, and premium-compatible through material separation and animation discipline rather than ornament density.

## Restrained palette

| Function | Color | Suggested value | Application rule |
|---|---|---:|---|
| **Understructure** | Charcoal black | `#20242A` | Fitted high-collar gambeson, trousers, gloves, boot joints; largest dark mass |
| **Civic armor** | Warm ivory | `#E2D8C4` | Shoulder shells, chest lamellar faces, bracers, knee plates, maul insets |
| **Structural metal** | Muted brass-gold | `#B28A46` | Plate rims, rivets, belt clasp, weapon corners; never a broad gold surface |
| **Oath cloth** | Deep teal | `#1F5B5B` | Narrow centered collar inset and short split tabard; single faction accent |
| **Seal accent** | Dusty plum | `#713F58` | One small centerline oath seal only; no side-mounted badge |
| **Ward energy** | Pale sun-cyan | `#8DD9D2` | One narrow centered weapon slit and a brief attack plane; glow kept local |

Charcoal and ivory should account for roughly **75–80%** of the sprite. Teal is the dominant faction accent; plum and cyan are small functional punctuation. Gold should outline construction rather than advertise rarity. Hair, skin, and eye colors may vary naturally between recruits, but neither variant receives a unique costume accent color.

## Shared silhouette and chibi translation

Target a **3.4-head-tall adult chibi**. The head is enlarged for runtime clarity but the face remains mature: smaller controlled eyes than a juvenile chibi, firm brow, defined nose shadow, and calm closed mouth. The torso is thick and upright, not toddler-round. Hands and boots are enlarged for weight, while hips and limbs retain adult articulation.

The silhouette is a stable **trapezoid / gatehouse**:

- squared paired shoulder shells form the roof line;
- a compact armored torso tapers slightly into the waist;
- the short split tabard widens over paired thigh guards;
- both boots plant wider than the shoulders with knees softly bent;
- the ward-maul sits on the body centerline, visually dividing the silhouette like a barred gate.

The head and hair remain contained inside the shoulder width in neutral pose. No long ponytail, cape, side skirt, sash tail, or shoulder pennant may create lateral noise. Armor must not engulf the face or turn the operator into a generic full-helmeted knight. The visible mature face and disciplined gaze preserve recruit identity.

At gameplay size, the silhouette must remain recognizably different from the lean recruit: broader shoulder width, lower center of gravity, heavier boots, and the unmistakable centered maul. It must also remain materially simpler than premium Solcrest heroes: no oversized hero shield, radiant standard, elaborate crest, luxury drapery, or ornamental halo.

## Shared costume construction

Both variants wear the same issued **Dawnwall harness**:

- a charcoal high-collar padded underlayer with full sleeves;
- paired ivory shoulder shells with one simple brass rim each;
- three broad overlapping ivory chest lamellae, bilaterally symmetrical;
- a centered teal collar inset that continues into a short, evenly split front-and-back tabard;
- a small plain plum oath seal fixed at the sternum center, shaped as a simple diamond or round wax tab rather than a detailed faction emblem;
- paired ivory forearm guards and gloves designed for a two-handed grip;
- a symmetrical utility belt with identical closed pouches flanking a plain center buckle;
- paired compact thigh guards and paired knee plates;
- broad charcoal-and-ivory boots with flat, enlarged soles.

Every part that affects recognition is paired or centered. Surface wear, scratches, and cloth folds must be generalized or mirrored in density rather than preserved as unique left/right marks. No cape, shield, backpack, side holster, prosthetic, monocle, single pauldron, dangling medal, shoulder emblem, or unilateral mechanism is permitted.

## Male variant

The male Immovable is a **clearly adult man, approximately late twenties to forties**, with a broad neck, mature jaw, straight brows, and a composed, unsmiling expression. His chibi physique is broad-shouldered and thick through the torso, with powerful forearms and legs, but it must remain athletic and human rather than superhuman or brutish.

Use short, practical hair—cropped sides with a compact brushed-back top or close textured crop—kept fully within the shoulder silhouette. Facial hair, if used at all, is limited to subtle even stubble; no unilateral scar, eyepatch, or distinctive face device. His armor follows the shared Dawnwall pattern exactly. Slightly straighter torso tailoring and a marginally broader jaw distinguish him without changing equipment, footprint, weapon scale, or rarity impression.

His posture communicates veteran patience: shoulders level, chin slightly lowered, eyes forward, elbows close around the maul shaft. Avoid a swaggering, roaring, or hypermasculine pose. The appeal is adult competence and dependable physical authority.

## Female variant

The female Immovable is a **clearly adult woman, approximately late twenties to forties**, with a mature oval-to-angular face, controlled eyes, defined brows, and a steady closed-mouth expression. Her chibi physique is athletic and strongly planted, with adult waist and hip structure under practical armor; do not shrink her shoulders, narrow her boots, exaggerate the bust, add heels, or introduce pin-up posing.

Use a compact symmetrical hairstyle: a chin-length blunt bob tucked evenly behind both ears, or a centered low bun fully contained behind the head. No long side fringe, side braid, asymmetric ponytail, ribbon, or jewelry. Her armor uses the identical plate count, tabard length, center seal, paired pouches, and weapon proportions as the male version. Subtly more fitted underlayer tailoring and a slightly narrower jaw may distinguish the body without weakening the gatehouse silhouette.

Her stance must feel equally heavy and authoritative: shoulders square, knees flexed, both feet fully grounded, and both hands controlling the centered maul. She is not a lighter or decorative interpretation of the class.

## Signature equipment — Gatebar Ward-Maul

The specialization carries one signature weapon/focus: the **Gatebar Ward-Maul**, a two-handed pole maul designed as portable Solcrest fortification equipment.

The weapon consists of a straight charcoal shaft, identical brass grip collars above and below the hands, and a broad **bilaterally symmetrical rectangular head**. Both striking faces are identical warm-ivory ward plates with muted gold corner caps. A single narrow sun-cyan slit runs vertically through the exact center of the head. The pommel is a centered blunt shoe suitable for planting on the ground. There is no shield, side blade, banner, key, counterweight, dangling seal, directional text, or distinct front/back face.

In idle, the shaft is held vertically on the character centerline with both hands stacked around chest height and the pommel planted between the feet. This creates the class-defining “barred gate” silhouette without requiring a left- or right-side shield. During attack, the head produces one short-lived rectangular ward plane centered perpendicular to the facing direction. The plane is an effect emitted by the weapon, not a persistent second piece of equipment.

Keep the maul enlarged enough to read at runtime, but no taller than roughly **1.05 character heights** from sole to head top in neutral pose. Its head should span about **55–65% of shoulder width**: substantial, but still clearly a two-handed tool rather than a full tower shield.

## Idle animation

The idle is a subtle **24-frame loop at 12 fps**, matching the current operator convention. The operator never leaves the planted footprint.

- **Frames 1–6 — Settle:** neutral brace; knees compress by approximately 1–2 source pixels, shoulders lower together, hands remain locked to the centered shaft.
- **Frames 7–12 — Hold:** chest rises subtly behind the lamellar; the cyan slit brightens by one restrained value step.
- **Frames 13–18 — Exhale:** shoulders return; the short split tabard shifts inward by no more than 1 pixel per side.
- **Frames 19–24 — Lock:** boots and pommel remain fixed; weapon glow returns to baseline and the pose loops seamlessly.

The head may dip a fraction during the settle, but the gaze remains forward. Do not add weapon spinning, shield flourishes, cloth whipping, large breathing bob, weight transfer from one foot to the other, or side-specific motion. The visual message is stored pressure and unwavering balance.

## In-place attack and recovery

The attack is a readable **13-frame, non-looping action at 12 fps**, compatible with the current operator attack convention. It is a compact ward-bash / ground-lock rather than a traveling swing.

| Frames | Beat | Required action |
|---:|---|---|
| **1–3** | **Anticipation** | Both hands slide apart symmetrically on the centered shaft; the operator sinks 2–3 pixels, elbows widen evenly, and the maul rises slightly without crossing the silhouette laterally. |
| **4–6** | **Drive** | The operator steps neither foot; hips and shoulders press forward along the facing axis while both hands drive the maul head down-and-forward in a short centered arc. |
| **7** | **Impact key** | Maul shoe/head locks to the ground line; knees are deepest; cyan slit flashes and one crisp rectangular ward plane appears centered in front. Keep this as the clearest single silhouette and gameplay contact frame. |
| **8–9** | **Hold / recoil arrest** | The ward plane contracts and fades; arms absorb recoil without torso knockback. Boots, pivot, and class footprint remain fixed. |
| **10–13** | **Recovery** | Weapon returns to vertical center guard, hands return to their idle spacing, torso rises, and the final frame matches idle entry cleanly. |

The attack must not use a broad lateral sweep, shield-side punch, lunging translation, full-body spin, or prolonged bloom. The rectangular effect remains close to the weapon and clear of the face. Its visual footprint may communicate force, but it must not imply a changed gameplay hitbox or projectile unless gameplay later specifies one.

## Direction, mirroring, and hitbox safety

**This design is horizontally mirror-safe.** Directional source art may still be authored for the project’s `ne`, `nw`, `se`, and `sw` presentation slots, but a horizontal flip must not alter class meaning or equipment logic.

The following rules are mandatory:

1. Keep the ward-maul and its cyan slit on the exact body centerline in idle, anticipation, impact, and recovery.
2. Keep all meaningful costume elements either centered or bilaterally paired: sternum seal, collar stripe, split tabard, shoulder shells, bracers, belt pouches, knee plates, and boots.
3. Make both faces and both ends of the maul head mechanically identical. Do not paint directional chevrons, letters, heraldry, keyed sockets, damage marks, or distinct active/inactive faces.
4. Do not add a shield side, prosthetic, single device, side holster, shoulder badge, unilateral plume, asymmetrical hair mass, one-sided cape, or side-specific glow.
5. Center the attack ward plane on the facing vector and weapon axis. Its left and right halves must have identical geometry, brightness distribution, and collision assumption.
6. Keep the feet planted equidistant from the pivot and preserve a consistent centered ground contact. Cosmetic motion must not shift the gameplay origin or suggest a wider temporary body hitbox.
7. General cloth folds and specular highlights may vary naturally per frame, but they must not become persistent identifiers that appear to change sides when mirrored.

## Sprite-production specification

Follow the current recruit/operator delivery conventions:

| Property | Requirement |
|---|---|
| **View set** | `ne`, `nw`, `se`, `sw` idle and attack strips |
| **Cell size** | **192 × 192 px** per frame |
| **Idle strip** | **24 frames**, 4608 × 192 px |
| **Attack strip** | **13 frames**, 2496 × 192 px |
| **Playback** | **12 fps** |
| **Pivot** | Centered horizontally; foot-contact alignment consistent across all frames and views |
| **Target presentation scale** | Advanced defender target: approximately **64 px display height**, normalized subject height approximately **158 px**, subject to final integration validation |
| **Camera** | Locked orthographic/isometric presentation matching current operator sheets |
| **Framing** | Complete operator, weapon, and attack effect remain inside every cell; no clipping or per-frame scale drift |

Although current source strips provide four directional assets, retain mirror safety so future optimization, previews, UI reuse, or fallback flipping cannot corrupt meaning. Male and female strips must share timing keys and contact frames exactly, allowing gameplay feedback to remain sex-neutral.

## Adult-read and non-premium guardrails

The chibi must remain an abstraction of an adult operator. Preserve a firm mature gaze, practical military tailoring, adult posture, and visibly trained stance. Reject oversized sparkling eyes, round toddler cheeks, tiny feet, pigeon-toed stance, school-uniform cues, playful weapon handling, or coy expressions.

The design should be polished but explicitly below named premium heroes in ornament and animation spectacle. Use clean plate separation, confident poses, restrained glow, and coherent faction materials for quality. Do not compensate for lower detail with generic bulk or visual noise. There should be **one weapon, one small center seal, one restrained energy slit, and one brief planar attack effect**—nothing else competing for recognition.

## Acceptance checklist

| Test | Pass condition |
|---|---|
| **Class read** | Silhouette reads as an immovable fortress defender before color or VFX is considered. |
| **Faction read** | Ivory-gold civic armor, teal oath cloth, disciplined geometry, and ward plane identify Solcrest inspiration. |
| **Recruit lineage** | Practical issued uniform, visible adult face, restrained hair, and compact animation preserve recruit-derived identity. |
| **Tier control** | Advanced polish is clear, but complexity remains materially below premium heroes. |
| **Variant parity** | Male and female variants share armor, weapon, stance weight, timing, scale, and authority. |
| **Adult clarity** | Both variants read unambiguously as adults age 21+. |
| **Chibi clarity** | 3.4-head silhouette remains readable at target display height without juvenile cues. |
| **Weapon clarity** | One centered two-handed Gatebar Ward-Maul is readable in idle and impact frames. |
| **Animation clarity** | Idle is subtle; attack has anticipation, a single strong impact key, and complete recovery in place. |
| **Mirror safety** | Flipping changes no meaningful device, emblem, shield side, prosthetic, weapon function, effect geometry, or hitbox assumption. |
| **Production fit** | Four directions, 192 px cells, 24-frame idle, 13-frame attack, and 12 fps match current conventions. |

## Explicit rejection criteria

Reject any concept or sprite that introduces a separate shield, shield-side logic, asymmetric pauldron, one-sided ward projector, premium-grade sun halo, long cape, attack lunge, lateral hammer sweep, juvenile face, decorative high heel, unique sex-specific equipment, excessive gold, broad cyan bloom, unreadable weapon grip, clipped effect, drifting pivot, or meaningful detail that swaps sides under horizontal mirroring.

The final asset succeeds when both variants look like the same dependable promoted Solcrest recruit: **adult, disciplined, broad, centered, and impossible to dislodge.**
