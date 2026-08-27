# Operator Specialization Design Brief 05: Swordmaster

## Production identity

| Field | Specification |
|---|---|
| **Class ID** | `swordmaster` |
| **Class name** | **Swordmaster** |
| **Tier** | **First tier / Standard** (`stage = 1`) |
| **Promotion source** | `recruit` |
| **Gameplay role** | **Melee Striker** |
| **Runtime kit projection** | `guard_1` |
| **Combat read** | Fast, close-range cuts against grounded threats |
| **Rarity treatment** | Recruit-derived, non-premium operator specialization |

This brief defines **exactly one specialization**, Swordmaster, with matched clearly-adult male and female presentation variants. It does not introduce a named hero, premium identity, alternate weapon, shield, companion, prosthetic, faction device, or second costume. The class data establishes Swordmaster as the Standard-stage promotion from Recruit, projected through `guard_1`, and describes it as a fast close-range ground attacker.[1] The design must therefore communicate **trained precision and speed**, not elite ceremonial rank, defensive mass, magical casting, or premium-banner spectacle.

## Design thesis

> **A field recruit refined into a disciplined breach duelist: compact blackened armor, one scarlet motion cue, and a centered two-handed longblade that turns a planted stance into a fast, readable cut.**

Swordmaster should look like a credible step above the existing Recruit rather than an unrelated hero. Preserve the recruit sprites' practical dark fitted uniform, red-brown accents, sturdy boots, compact adult chibi body, centered ground contact, and uncomplicated melee construction. Upgrade those ingredients with a clean chest plate, reinforced forearms and shins, a short split waist guard, and a more authoritative longblade. The promotion increases **clarity, training, and material quality**, not ornament count.

The finish should be polished through controlled material separation and confident posing, while remaining materially simpler than the premium Lunaris characters. Use approximately four major costume masses, one small centered insignia, no jewelry, no chains, no translucent layers, no orbiting mechanisms, no luminous body hardware, no cape, and no filigree. Premium characters are defined by elaborate couture, signature mechanisms, dramatic hair, layered asymmetry, and multiple prestige accents; Swordmaster deliberately avoids those signals.[2][3]

## Closest faction language: Crimson Aegis

**Crimson Aegis** is the closest faction design language. Its blackened impact plate, scarlet motion shapes, weapon-gold breach edges, forward wedges, and momentum-driven combat effects directly support an in-place Melee Striker whose gameplay promise is a rapid close-range cut.[2] The faction concept also demonstrates powerful adult combatants in practical segmented armor, strong forward posture, and weapons designed around force delivery.[4]

This is an **entry-grade Crimson interpretation**, not a full Breach Caravan hero. Retain the faction's blackened plate, controlled scarlet accent, shallow wedge geometry, and warm blade hardware, but omit shock-sails, massive recoil equipment, heavy ram architecture, green webbing clutter, explosive effects, and heroic-scale trailing cloth. Solcrest reads too formation-defensive and shield-led for this striker; Vesper reads technical, masked, and information-war oriented; Lunaris supplies a premium spellblade precedent but its ivory/violet ceremonial mechanisms and prestige duelist styling would overstate this unit's rarity.[2][3][5][6][7]

## Restrained palette and materials

| Palette role | Color | Hex | Placement and limit |
|---|---|---:|---|
| **Blackened graphite** | Near-black charcoal | `#202429` | Primary fitted uniform, trousers, boot body, glove palms; approximately 45% of visible area |
| **Breach scarlet** | Deep muted red | `#8F3034` | High collar inset, centered belt tab, and the two short waist-panel linings; approximately 18%; never a cape or full coat |
| **Field green** | Desaturated forest green | `#31483B` | Narrow under-armor piping and one centered grip wrap; approximately 8%; must not compete with scarlet |
| **Warm steel** | Low-glare blade and plate gray | `#B8B3A7` | Blade, chest/forearm/shin plate faces; approximately 24%; broad readable planes rather than polished white chrome |
| **Breach gold** | Aged brass-gold | `#B9863F` | Guard, pommel, rivet bars, and one centered chest chevron; approximately 5%; no filigree or luminous bloom |

Skin and hair remain natural identity colors and are not counted as faction accents. Materials must separate at gameplay scale: matte charcoal cloth, satin scarlet cloth, brushed darkened steel, and restrained aged brass. The blade may receive a one-pixel pale edge highlight at final sprite resolution, but it has **no energy core, rune text, persistent glow, or particle trail**. Reserve bright value for the face, blade edge, and small contact slash only.

## Adult chibi silhouette and proportion contract

Use a **3.4-to-3.6-head-tall adult chibi**, consistent with the project's three-to-four-head standard.[2] The silhouette is an upright tapered diamond: a mature head, broad armored shoulder line, fitted waist, paired short thigh panels, planted boots, and one long diagonal/vertical sword axis. The weapon is the most recognizable secondary mass, but the body remains readable independently of it.

| Zone | Silhouette requirement |
|---|---|
| **Head and face** | Approximately 28% of body height; modest adult eye size, defined brows, visible nose bridge, firm jaw/chin, and a composed unsmiling focus. Avoid round cheeks, huge sparkling eyes, or oversized childlike cranium treatment. |
| **Upper body** | Shoulder width is the dominant body width. A low-profile, bilaterally matched chest plate forms one clear wedge over a fitted recruit-derived jacket. No oversized pauldrons. |
| **Waist and legs** | Narrow utility belt with a centered buckle; two equal short split panels stop above the knees; trouser legs and armored boots remain distinct. Feet are separated enough to show a stable fighter's base. |
| **Weapon axis** | In idle, the two-handed blade sits close to the body centerline with its point down-forward or up-forward according to directional view. It must not create a shield-like side mass. |
| **Hair mass** | Compact and controlled, clearing the eyes, shoulders, and sword. No long ponytail, side braid, giant ribbon, or premium flowing hair curtain. |

At neutral gameplay scale, target the current recruit family's compact **58–60 pixel displayed body height**, normalized from the character rather than the attack-effect union. Author in 192×192 cells with bottom-center alignment, a centered horizontal pivot, and grounded foot contact at the recruit convention near source `y = 148` (`pivot ≈ Vector2(0.5, 0.770833)`).[8][9][10] Keep raised blade and hair inside safe bounds. The attack may crouch by no more than six source pixels and must return to the identical neutral anchor.[9]

The silhouette must remain distinct from premium heroes: no halo, no orbiting focus, no broad shield, no giant slab weapon, no floor-length coat, and no dramatic back ornament. Recognition should come from the **tapered armored torso plus centered longblade**, not detail density.

## Shared costume construction

Both variants wear the same specialization uniform and must read as members of the same operational class:

1. A charcoal, high-collared fitted recruit jacket with a narrow scarlet center inset.
2. A shallow V-shaped warm-steel chest plate made from one main plate and two small lower facets. All facets are bilateral.
3. Equal low-profile shoulder caps, equal forearm guards, and equal shin plates.
4. A centered belt buckle and two equal short waist panels, charcoal outside with scarlet lining visible only during motion.
5. Fitted dark trousers, practical flat-soled combat boots, and equal gloves.
6. One small, bilaterally symmetric downward chevron on the center chest in aged gold. It is an abstract rank marker, not a directional faction emblem.

Do not add side pouches, a hip sheath, a shoulder sash, one-sided armor, single-ear jewelry, exposed mechanical parts, writing, heraldic animals, or a meaningful left/right color code. The sword remains in both hands at all times, so a scabbard is unnecessary and would introduce avoidable directional clutter.

## Male variant

The male Swordmaster is a **clearly adult man, approximately late twenties to mid-thirties**, with a compact athletic build, squared shoulders, a mature angular face, defined brows, a straight nose, and calm narrowed eyes. His stance is grounded and economical rather than swaggering. Use short, dense dark-brown or near-black hair with a modest swept-back crown; keep both temple shapes visually balanced and avoid a directional shaved pattern. A light, symmetrical jaw shadow is acceptable only if it survives at sprite scale without reading as dirt.

His jacket and armor use the exact shared construction. The chest block may be slightly broader and the waist slightly straighter than the female variant, but armor scale, panel lengths, palette ratios, sword dimensions, ground line, action timing, and gameplay footprint remain matched. The silhouette communicates adult strength through shoulder breadth, forearm thickness, boot weight, and posture—not an oversized torso or exaggerated muscular exposure. Keep the neck visible enough to prevent the head from reading as a child's head attached directly to armor.

## Female variant

The female Swordmaster is a **clearly adult woman, approximately late twenties to mid-thirties**, with an athletic, powerful build, mature almond-shaped eyes, defined brows, a visible nose bridge, firm jawline, and controlled expression. Her hair is dark auburn-brown in a compact collar-length cut gathered into a low, centered knot or short central tie; the mass must be balanced on both sides and must not resemble a school-age bob, side ponytail, or decorative idol hairstyle.

She wears the same full-coverage fitted jacket, chest plate, paired guards, trousers, waist panels, gloves, and practical boots as the male variant. Shape the armor to an adult female torso without cleavage framing, corsetry, exposed thighs, a skirt substitution, high heels, or reduced protection. Her silhouette may use a slightly narrower shoulder line and a clearer waist-to-hip transition, but she must retain the same planted power, weapon reach, action arc, total sprite height, pivot, and hitbox read as the male variant. Adult identity comes from facial structure, posture, proportion, and competent body language rather than glamour exaggeration.

## Signature weapon: Breachline Longblade

The only weapon is the **Breachline Longblade**, a straight hand-and-a-half sword used with **both hands**. Its design is simple enough for non-premium production and forceful enough to identify the class:

- A long, moderately broad warm-steel blade, approximately 2.0–2.2 chibi heads from guard to point.
- A centered shallow ridge/fuller and a bilateral tapered point.
- A short, perfectly symmetric wedge guard in aged brass-gold.
- A centered forest-green grip wrap long enough for two clearly separated hands.
- A round or shallow diamond pommel centered on the blade axis.
- One restrained gold edge inset near the forte; no letters, runes, faction logo, animated mechanism, jewel, tassel, or glow.

The sword is neither a katana nor an oversized fantasy slab. Its straight bilateral construction and two-handed use create weapon authority without assigning canonical handedness. In every key pose, the midpoint between both hands stays close to the torso centerline. The blade may travel to the front side during the cut, but neither hand releases, and the weapon never becomes a one-sided persistent device.

## Direction and mirror-safety contract

The production set uses `NE`, `SE`, `NW`, and `SW` for stationary tower presentation; east-facing `NE` and `SE` may serve as masters, with `NW` and `SW` derived as exact horizontal mirrors.[10] Swordmaster is intentionally designed so mirroring changes only apparent facing, not meaning.

**Mandatory mirror rules:**

- Costume geometry, shoulder caps, bracers, shin guards, waist panels, glove cuffs, boots, and color blocking are bilateral.
- The chest chevron, belt buckle, collar inset, hair tie, blade ridge, guard, grip, and pommel are centered and bilaterally symmetric.
- The sword is always held with two hands around the centerline; there is no canonical dominant hand.
- There is no shield, scabbard, hip device, side pouch, prosthetic, side-specific emblem, writing, eyepatch, single earring, unilateral scar, directional rune, or off-center hitbox-significant equipment.
- Hair may deform with motion but cannot have a meaningful left/right construction.
- Weapon reach, root location, contact point, alpha bounds, frame order, timing, pivot, and gameplay footprint must remain exactly equivalent across mirrored pairs.
- Generate/authenticate `NE` and `SE`; derive `NW = mirror(NE)` and `SW = mirror(SE)`. Do not independently redraw west facings in a way that alters proportions or attack reach.

**Mirror-safe status: true.**

## Idle animation

The idle is a subtle **ready-breath loop**, authored as **24 frames at 12 FPS** for a seamless two-second cycle, matching current operator presentation.[8][10] Feet and root remain locked. Both hands hold the Breachline Longblade near the centerline in a low middle guard. Motion is intentionally restrained:

- Frames 0–5: neutral guard; shoulders settle by roughly one source pixel.
- Frames 6–11: quiet inhale raises the sternum and sword hilt by one to two source pixels; elbows open minimally.
- Frames 12–17: controlled exhale lowers the hilt and torso to neutral; the two short waist panels lag by no more than one frame.
- Frames 18–23: final stabilization into frame 0 with no visible seam.

Allow a slight blink once per loop and a one-pixel hair-tip response. Do not shift either foot, bounce the whole body, rotate the camera, flash the blade, emit particles, or sweep the sword through an attack-like arc. The pose should suggest an adult professional conserving energy.

## Attack animation

The attack is a readable **in-place two-handed descending breach cut** with complete recovery, authored as **13 non-looping frames at 12 FPS**, matching the existing runtime attack window.[8][10]

| Frames | Beat | Pose and readability |
|---:|---|---|
| **0–2** | **Anticipation** | From middle guard, sink the hips by up to three source pixels, tighten elbows, and draw the centered hilt toward the sternum. The point rises behind/above the forward shoulder without changing root position. |
| **3–4** | **Commit** | Rotate shoulders and hips within the planted stance; both hands remain on the grip. Keep the face and chest readable in three-quarter view. |
| **5–6** | **Primary cut / contact** | Drive one fast diagonal cut down and forward across the target-facing space. Use a short, broad pale-steel slash accent tied to the blade edge, peaking for one frame. The effect must not exceed the weapon's plausible reach or obscure the body. |
| **7–8** | **Follow-through** | Blade finishes low-forward, knees compressed, back heel still planted. Hold the impact shape briefly enough to register at gameplay scale. |
| **9–12** | **Recovery** | Retract along the shortest path, unwind the torso, raise to middle guard, and restore the exact idle root, hilt height, panel rest, and silhouette by frame 12. |

The animation may use **pose displacement but not translation**: no dash, forward step, leap, spin, multi-hit flourish, screen shake, persistent trail, or delayed magical burst. Keep the blade fully inside the 192×192 cell. Ground contact may compress by at most six source pixels but must never float below or above the authored ground tolerance.[9] The visible contact should occur around frames 5–6, while authoritative combat timing remains controlled by simulation rather than art.

## Production and review requirements

The runtime scope is **idle and attack only** because deployed operators are stationary towers.[10] Produce a single matched male/female Swordmaster family, each with four directional idle strips and four directional attack strips. Use transparent fixed 192×192 cells, 24-frame looping idles, 13-frame non-looping attacks, 12 FPS playback, stable bottom-center placement, consistent scale, and no camera movement.[8][10] Normalize body scale from the neutral figure, not slash-effect or raised-blade union bounds.

Review at actual gameplay display size, not only enlarged concept scale. The design passes when:

| Acceptance area | Required result |
|---|---|
| **Class read** | First glance communicates fast sword striker, not defender, caster, samurai, knight commander, or premium named hero. |
| **Recruit continuity** | Dark fitted uniform, red-brown lineage, practical boots, compact proportions, and direct melee posture remain recognizable as a trained recruit promotion. |
| **Adult identity** | Both variants read unequivocally 21+ through mature faces, posture, physiques, costume, and expression; no juvenile or school-coded traits. |
| **Variant match** | Male and female share costume construction, weapon, palette, scale, timing, reach, pivot, and gameplay footprint; only adult anatomy, face, and controlled hair identity differ. |
| **Rarity discipline** | No prestige mechanisms, couture layering, filigree, jewelry, asymmetrical hero device, excessive exposed skin, dramatic cape, or multi-color glow. |
| **Silhouette** | Broad shoulder wedge, short split panels, planted boots, and centered longblade remain recognizable at 58–60 pixels. |
| **Motion** | Idle loops quietly; attack shows anticipation, contact, follow-through, and full recovery without root drift. |
| **Mirror safety** | Exact east-to-west mirrors preserve all semantic details and identical attack bounds; no meaningful asymmetric element changes sides. |
| **Technical bounds** | No clipping of blade, hair, armor, hands, boots, or slash accent; transparent fixed cells and stable ground line are maintained. |

## Explicit exclusions

Do not reinterpret Swordmaster as a premium Lunaris duelist, katana specialist, dual wielder, shield user, elemental swordsman, masked Vesper agent, mounted fighter, or Crimson shock-sail captain. Do not add a second blade, off-hand dagger, buckler, floating focus, elemental familiar, prosthetic, long asymmetric coat, one-sided shoulder armor, written emblem, or persistent VFX. Those additions would weaken mirror safety, blur the Melee Striker read, or exceed the intended first-tier non-premium complexity.

## References

[1]: ../../../data/classes/swordmaster.tres "Swordmaster class resource"
[2]: ../../ART_DIRECTION.md "Protos Visual Art Direction"
[3]: ../../LUNARIS_CHARACTER_DESIGNS.md "Lunaris Reliquary Launch Character Designs"
[4]: ../../Faction%20-%20Crimson%20Aegis.webp "Crimson Aegis faction concept"
[5]: ../../Faction%20-%20Solcrest%20Accord.webp "Solcrest Accord faction concept"
[6]: ../../Faction%20-%20Vesper%20Circuit.webp "Vesper Circuit faction concept"
[7]: ../../Faction%20-%20Lunaris%20Reliquary.webp "Lunaris Reliquary faction concept"
[8]: ../../../data/presentation/operator_visuals/recruit_male.tres "Recruit male animation definition"
[9]: ../../../tests/recruit_animation_alignment_test.gd "Recruit sprite alignment contract"
[10]: ../../lunaris-reliquary/VIDEO_TO_SPRITES_IMPLEMENTATION_PLAN.md "Operator sprite production and runtime conventions"
