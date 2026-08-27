# Operator Specialization Design Brief 08 — Sorcerer

## Design mandate

| Field | Specification |
|---|---|
| **Class ID** | `sorcerer` |
| **Display name** | **Sorcerer** |
| **Tier** | **Advanced** (`stage = 2`) |
| **Operator definition** | `caster_2` |
| **Promotion source** | `mage_apprentice` |
| **Gameplay role** | **Area Spellcaster** |
| **Combat read** | A ranged caster who attacks clustered enemies with a 3 × 3 splash footprint; the silhouette and animation must communicate controlled area projection rather than a single-target wand shot. |
| **Product position** | One recruit-derived, non-premium specialization with matched adult male and female variants. It must look polished and promotion-worthy, but remain materially simpler than named premium heroes. |

This brief defines **exactly one operator specialization design**, expressed through matched male and female body variants. The design inherits the recruit/operator production grammar rather than introducing a named hero identity. Both variants are clearly adult professionals, age 21 or older, and use the same costume construction, focus, palette hierarchy, footprint, animation timing, and combat read.

## Source review and design-language selection

The design is grounded in the project’s canonical [`ART_DIRECTION.md`](../../ART_DIRECTION.md), [`LUNARIS_CHARACTER_DESIGNS.md`](../../LUNARIS_CHARACTER_DESIGNS.md), all four faction concepts, the class resource at [`data/classes/sorcerer.tres`](../../../data/classes/sorcerer.tres), the combat definition at [`data/operators/caster_2.tres`](../../../data/operators/caster_2.tres), and current recruit, `caster_1`, and `caster_2` directional sprite sheets. Current operator animation conventions use 192 × 192 cells, a normalized 158-pixel subject height, a bottom-centered pivot at `(0.5, 0.94)`, four diagonal facings, a 24-frame looping idle, a 13-frame non-looping attack, and 12 fps playback.

| Faction language | Fit to Sorcerer | Decision |
|---|---|---|
| **Lunaris Reliquary** | Circular ritual mechanisms, gravity and memory motifs, moon-cyan energy, ceremonial caster silhouettes, and controlled area magic directly reinforce the class role. | **Selected as the closest inspiration.** |
| Solcrest Accord | Strong civic geometry and beacon magic read primarily as formation defense and warding. | Not selected. |
| Vesper Circuit | Signal filaments and interference glass could support technical projection, but the narrow covert silhouette reads as information warfare rather than broad magical impact. | Not selected. |
| Crimson Aegis | Recoil hardware and forward momentum suit breach and impact roles, not a stationary area caster. | Not selected. |

**Lunaris Reliquary is the closest design language**, but this operator occupies its trained rank-and-file tier rather than its prestige reliquary caste. The specialization borrows only the faction’s broad circular geometry, dark ceremonial textile, restrained ivory structure, brushed metal, and moon-cyan magic. It deliberately omits the premium heroes’ orbiting satellites, translucent trains, complex chains, extensive jewelry, asymmetric couture, exposed high-fashion cuts, nested mechanisms, and individualized relic lore. The result should read as a capable field sorcerer issued a standardized ritual implement, not as a reduced copy of the Lunaris Vessel or Archive Caster.

## Visual thesis

> **A disciplined adult field sorcerer braces a compact two-handed orrery at the body center and compresses moon-cyan force into a broad, controlled detonation.**

The dominant recognition shape is a **single bright circle centered against a dark tapered figure**. A short mantle establishes the shoulder line, a fitted long tunic narrows at the waist, and two equal front-and-back coat splits preserve leg readability without becoming a premium gown or cape. The focus is large enough to identify the caster role at gameplay scale, yet mechanically plain enough to remain non-premium.

## Palette and material hierarchy

| Palette role | Color | Use constraint |
|---|---|---|
| **Primary textile** | Violet-black — `#181526` | Approximately 55–60% of the unit; tunic, trousers, boots, mantle shadow. |
| **Secondary textile** | Muted plum — `#493451` | Approximately 15–20%; mantle face, waist band, and broad hem blocks only. |
| **Structural light** | Ash ivory — `#D8D2C5` | Approximately 10–15%; collar, centered chest yoke, cuff blocks, and focus insets. |
| **Hardware** | Brushed brass — `#A88A52` | Approximately 5–8%; broad rims and fasteners, never dense filigree. |
| **Magic accent** | Moon-cyan — `#75D5DF` | Approximately 3–5% at rest and the dominant transient attack light; reserved for the focus core and cast effect. |

Hair uses natural near-black or deep brown values already compatible with the primary textile; skin, eye, and hair variation may support roster diversity but may not introduce a sixth costume accent. Materials separate cleanly as matte woven cloth, low-gloss leather footwear and bracers, brushed—not mirror-polished—brass, chalky ivory insets, and additive cyan energy. Gold coverage must remain markedly below premium Lunaris characters. Purple and cyan should not bloom into one indistinct neon mass.

## Silhouette and proportion contract

The unit is **approximately 3.5 heads tall**, within the required three-to-four-head adult chibi range. The head is enlarged for expression, but the eyes remain moderately sized with defined upper lids, visible brows, mature jaw construction, and a calm, focused mouth. Hands and boots are slightly enlarged for action readability. The torso is long enough to avoid toddler proportions, the pelvis is narrow and stable, and the planted stance communicates practiced adult authority.

At idle, the silhouette forms a compact vertical wedge: a broad but soft mantle shoulder line, a tapered waist, two balanced knee-length coat panels, separated boots, and the circular focus centered between sternum and waist. The focus should occupy roughly 28–32% of the figure’s shoulder width. It must remain visually distinct from the head and must not obscure both hands. Hair stays within the shoulder envelope so that it does not compete with the focus or create different left/right profiles.

The subject remains centered in every 192 × 192 frame with feet registered to the `(0.5, 0.94)` pivot and normalized to the existing 158-pixel subject-height convention. The resting silhouette must survive the 64-pixel gameplay display height. No idle or attack frame may alter the gameplay footprint, suggest a dash, or crop the focus or effect at the cell edge.

## Shared costume construction

Both variants wear the same **field-reliquary uniform**. A low standing ash-ivory collar joins a centered, shallow triangular yoke; beneath it is a fitted violet-black tunic with a broad muted-plum waist wrap closed by one centered rectangular brass clasp. A short symmetrical mantle caps both shoulders and ends above the elbows. Close sleeves terminate in identical dark bracers with one plain brass band each. The lower tunic divides into equal front and rear panels ending near the knee, with matching side openings solely for stride clarity. Straight dark trousers and broad low-heeled boots keep the base solid and deployment-ready.

Decoration is limited to one ivory line following the yoke, two broad brass focus rims, and one centered geometric stitch line down each coat panel. There are no faction badges, heraldic emblems, hip mechanisms, keys, books, masks, earrings, chains, shoulder devices, belt pouches, prosthetics, shields, holsters, one-sided armor plates, or side-specific spell components. The costume uses large readable blocks instead of micro-filigree. It should look carefully tailored and professionally maintained, not luxurious.

## Matched adult variants

| Feature | Adult male variant | Adult female variant |
|---|---|---|
| **Age read** | Clearly 25–35, with a mature angular brow, defined jaw, straight nose, restrained expression, and no boyish roundness. | Clearly 25–35, with defined cheek and jaw structure, controlled eyes and brows, a composed mouth, and no doll-like or adolescent cues. |
| **Build** | Lean-athletic with moderately broader shoulders, a straight torso taper, substantial forearms, and stable separated boots. | Athletic-statuesque with a subtly shaped waist and hips, strong legs, and the same stable stance; anatomy remains functional and non-infantilized. |
| **Hair** | Short, dense deep-brown hair, brushed evenly back from a centered hairline with a compact crown and clean nape; no long forelock or side shave. | A deep-brown, center-parted jaw-length blunt bob tucked evenly behind both ears; the balanced outer contour remains inside the mantle width. |
| **Costume fit** | The shared tunic is straighter through the torso and mantle is fractionally broader; panel lengths, trim, clasp, and bracers are unchanged. | The shared tunic is shaped through an adult bust and waist without cleavage, cutouts, mini-skirt coding, or heels; panel lengths, trim, clasp, and bracers are unchanged. |
| **Expression and posture** | Calm concentration, chin level, shoulders low, elbows heavy, both hands equally authoritative on the focus. | Calm concentration, chin level, shoulders low, elbows heavy, both hands equally authoritative on the focus. |

These are matched production variants rather than separate characters. Neither receives a unique accessory, color, weapon modification, effect language, animation advantage, or rarity signal. Their heads, shoulders, hands, hips, and clothing may be redrawn for adult anatomical fit, but all gameplay-facing landmarks remain equivalent.

## Signature focus — Convergence Orrery

The specialization uses one weapon: the **Convergence Orrery**, a compact, centered, two-handed ritual focus. It consists of a thick brushed-brass outer ring, an ash-ivory inner disk broken into four equal cardinal blocks, and one circular moon-cyan core. A short identical grip projects from the left and right sides. Both hands hold those grips at equal height, keeping the implement centered on the sternum at rest. The silhouette is strictly radial and bilateral: no hanging weights, pointer needle, text, runes with handed reading direction, offset crystal, keyed socket, or upper-versus-side attachment.

The orrery is a simplified descendant of Lunaris circular mechanisms. Unlike a premium astrolabe, it has only two visible mechanical layers and no free-floating components. During casting, the inner disk separates visually into two concentric light rings but remains a single coherent weapon. Its central core is the projectile/effect origin and the visual aiming axis, which prevents either hand from becoming the “casting hand.”

## Idle motion

The idle is a **24-frame, 12 fps, two-second seamless loop**. The feet, pivot, grip positions, and center of mass remain planted. Frames 0–5 show a one-pixel chest and shoulder rise while the orrery lifts no more than one pixel. Frames 6–11 settle to neutral. Frames 12–17 repeat a smaller breath as the cyan core brightens gently and the inner disk rotates approximately six degrees. Frames 18–23 return the disk and glow to the opening state. Coat-panel hems may lag by one pixel, equally on both sides, then settle.

The motion is intentionally subordinate to gameplay: no hovering body, large hair sweep, orbiting particles, hand flourish, blinking emblem, or one-sided cloth flick. A blink may occur once near frames 15–16, with the same timing in both variants. The loop should read as controlled breath and contained pressure, not a premium showcase animation.

## In-place attack and recovery

The attack is a **13-frame, 12 fps, non-looping action** lasting approximately 1.08 seconds. It communicates an area spell through compression, a centered release, a broad radial flash, and visible recovery while keeping the root locked.

| Frames | Beat | Pose and effect requirement |
|---:|---|---|
| 0–2 | **Anticipation** | Knees soften and elbows draw back symmetrically. The orrery lowers one to two pixels toward the solar plexus. The torso does not translate off the pivot. |
| 3–5 | **Compression** | Both hands press the side grips inward; the focus rises to sternum height. The core contracts to a bright cyan point while two faint concentric rings appear within the existing outer rim. |
| 6–7 | **Release** | The operator extends both forearms together, moving the focus a maximum of four to six pixels along the facing axis. A centered cyan-white pulse leaves the core. A broad circular wave and three short equal radial spokes establish splash/area intent; the spokes are effect geometry, not separate projectiles. Frame 7 is the clearest contact keyframe. |
| 8–9 | **Recoil** | Shoulders rock back by no more than two pixels, elbows bend equally, and the focus glow expands once before dimming. Feet and root remain fixed. |
| 10–12 | **Recovery** | The orrery returns to its idle sternum position, knees straighten, coat panels settle symmetrically, and the cyan core returns to its resting value. Frame 12 must match the idle entry pose closely enough to avoid a pop. |

The pulse originates from the exact visual center of the orrery in every direction. Its radial read should suggest the operator is projecting a detonation zone beyond the sprite, while the actual targeting, splash dimensions, and hit timing remain data-owned. The character does not jump, spin, step, lunge, or sweep the focus across the body. Recovery is mandatory and visibly quieter than the release so repeated attacks remain legible.

## Directionality and horizontal-mirroring contract

The design is intentionally **mirror-safe**. All permanent, gameplay-meaningful geometry lies on the centerline or occurs in identical left/right pairs. The Convergence Orrery, chest yoke, waist clasp, coat split, hair mass, cuffs, and boots are bilateral. Both hands share the same grip and motion; neither is designated dominant. There is no meaningful asymmetric device, emblem, prosthetic, shield side, scabbard, pouch, reading-direction rune, one-sided armor, or offset hit origin to swap under horizontal mirroring.

| Rule | Production requirement |
|---|---|
| **Paired facings** | NE/NW and SE/SW may be authored as mirrored pairs or checked against one another by mirroring. Mirroring must not change class meaning, equipment function, or visual targeting. |
| **Centerline lock** | The focus core, release flash, and projectile/effect origin remain on the character’s local centerline. They may project along the facing axis but never originate from a left or right hand. |
| **Identical side components** | Grips, cuffs, mantle corners, panel edges, and boots remain identical in shape, value, and glow response. |
| **Nonsemantic shading** | Lighting and perspective overlap may reverse naturally. No highlight, scratch, fastener, or decorative mark may be treated as identity-critical. |
| **Effects** | Attack rings and spokes are circular or evenly radial. Any perspective squash is centered; no clockwise arrow, letterform, or directional glyph is allowed. |
| **Hair and cloth** | Hair is center-parted or evenly swept back; coat panels have equal length and weight. Motion may lag opposite the cast direction but may not reveal a hidden side-specific object. |
| **Collision and root** | Horizontal mirroring never moves the `(0.5, 0.94)` pivot, collision footprint, target point, core origin, or normalized height. |

## Complexity ceiling and premium separation

| Category | Sorcerer ceiling | Premium Lunaris distinction retained |
|---|---|---|
| **Primary equipment** | One two-layer orrery held in both hands. | Premium heroes may use expanded halos, suspended weights, orbiting assemblies, or named relic transformations. |
| **Costume layers** | Tunic, short mantle, waist wrap, trousers, boots; two balanced lower panels. | Premium heroes retain couture drape, complex sheers, chains, jewelry, asymmetric mantles, and multiple articulated layers. |
| **Metal detail** | Broad rims, clasp, and plain cuff bands only. | Premium heroes retain fine filigree, constellation marks, jewel mechanisms, and extensive gold hierarchy. |
| **Effects** | One core glow, two transient rings, one radial release. | Premium heroes retain gravity fields, orbiting relics, elaborate trails, and character-specific magical choreography. |
| **Motion** | Breathing idle and compact brace-release-recover attack. | Premium heroes retain bespoke secondary motion, fashion movement, and signature flourish. |

Polish should come from excellent shape control, mature faces, material separation, clean key poses, and disciplined timing—not from adding ornaments. If the operator begins to resemble the Archive Caster’s individualized astrolabe, chains, sheer dress, or suspended reliquaries, simplify it.

## Production and review checklist

| Review gate | Acceptance standard |
|---|---|
| **One specialization** | Male and female sheets depict the same Sorcerer specification, not two character concepts. |
| **Adult clarity** | Both variants read as 21+ through mature facial construction, adult anatomy, professional styling, and composed body language. |
| **Role clarity** | Centered circular focus and broad radial release read as Area Spellcaster at 64-pixel display height. |
| **Silhouette** | Approximately 3.5 heads tall; head, shoulders, centered circle, divided coat, and boots remain readable in flat black. |
| **Palette restraint** | Five costume/effect colors follow the stated hierarchy; cyan and brass do not spread into decorative noise. |
| **Non-premium status** | No personalized relic lore, elaborate asymmetry, orbiting accessories, chains, sheer trains, micro-filigree, or hero-grade effect stack. |
| **Matched variants** | Costume landmarks, focus size, frame timing, pivot, subject height, effect origin, and hit read match across male and female variants. |
| **Animation compliance** | Four diagonal facings; 192 × 192 cells; 24-frame idle loop and 13-frame attack at 12 fps; pivot `(0.5, 0.94)`; normalized subject height 158 px. |
| **In-place action** | Feet remain registered; torso and focus motion stay within the stated limits; frame 12 recovers cleanly to idle. |
| **Mirror safety** | A horizontal flip swaps no meaningful device, emblem, prosthetic, shield, hand role, hitbox, or origin. |
| **Frame integrity** | Complete body, weapon, and required release effect remain inside every cell with no cropping or scale drift. |

## Final concept summary

The Sorcerer is a matched adult field-caster pair in a restrained Lunaris-derived uniform, recognized by one central moon-cyan **Convergence Orrery** held equally in both hands. A broad-shouldered, tapered 3.5-head chibi silhouette and compact radial cast communicate advanced area magic immediately. Symmetry is a functional production rule rather than decoration: costume, hair, focus, grip, motion, origin, and collision read remain safe under horizontal mirroring. The specialization looks more accomplished than its Mage Apprentice source through cleaner tailoring, a stronger central focus, and a broader impact pose, while remaining substantially simpler and less ornate than premium heroes.
