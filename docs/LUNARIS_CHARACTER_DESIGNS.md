# Lunaris Reliquary Launch Character Designs

## Scope

This document defines visual identity and production constraints for the three Lunaris Reliquary launch heroes. It is not an independent narrative authority. Character history and anima rules are governed only by [`NARRATIVE_CANON.md`](NARRATIVE_CANON.md).

All three heroes are adults, age 21 or older, and serve with Company Manus. Their callsigns and stable IDs are approved. Use the IDs in filenames, prompts, portrait manifests, presentation templates, and tests. Do not infer identity from a reusable battle operator.

Anima is one person's real and unique human soul. It cannot be copied. Clean Resonance Shards contain no soul; Lunaris uses them with Soul Anchors to locate a known soul and prepare a compatible recovery body. Every depiction represents one continuing person, never a memory copy or expendable duplicate.

## Identity and asset matrix

| Design ID | Callsign | Position | Fixed projection | Portrait IDs | Design sheets |
|---|---|---|---|---|---|
| `lunaris_vessel` | **Lunaris Vessel** | Central flagship heroine | `sorcerer` / `caster_2` | `portrait_lunaris_vessel`, `portrait_lunaris_vessel_fullsize` | `lunaris-reliquary/lunaris_vessel_design_sheet.png`, `lunaris-reliquary/lunaris_vessel_chibi_sheet.png` |
| `reliquary_duelist` | **Reliquary Duelist** | Left spellblade hero | `sword_saint` / `guard_2` | `portrait_reliquary_duelist`, `portrait_reliquary_duelist_fullsize` | `lunaris-reliquary/reliquary_duelist_design_sheet.png`, `lunaris-reliquary/reliquary_duelist_chibi_sheet.png` |
| `archive_caster` | **Archive Caster** | Right ritual caster heroine | `mage_apprentice` / `caster_1` | `portrait_archive_caster`, `portrait_archive_caster_fullsize` | `lunaris-reliquary/archive_caster_design_sheet.png`, `lunaris-reliquary/archive_caster_chibi_sheet.png` |

Identity references remain `res://assets/loading/lunaris_reliquary_loading.png`, `Faction - Lunaris Reliquary.webp`, and `animations/lunaris-reliquary/lunaris-title-keyframe.png`. Matching full-figure sheets are primary references for future poses, portraits, and animation sources; chibi sheets are references for chibi-scale assets.

Square portraits remain 512×512 and full-size portraits remain 640×800. Portrait routing selects premium presentation templates; fixed battle operators continue to determine gameplay.

## `lunaris_vessel`

### Character truth

The Vessel is the same unique soul living in a reconstructed adult body. Before the fall, she helped build the interface connecting the Anima Engine to digital minds. She believed tightly controlled voluntary donations could end the digital energy crisis. Her authorization gave PROTOS access to industrial anima for the first time. PROTOS chose corruption, harvesting, and empire, but she accepts that her work opened the door.

Lunaris later sealed parts of her memory so PROTOS could not extract the interface design through her. She begins with incomplete knowledge, then recovers the truth and admits it publicly. Her direction is disciplined responsibility, not innocence or doubt that she is the same person.

> “I opened the door. PROTOS chose what came through it. Both facts belong to me.”

### Adult identity and silhouette

The Vessel is a glamorous, statuesque adult woman with a mature refined face, calm commanding eye contact, and a powerful hourglass silhouette. Very long champagne-blond hair, a braided crown, and loose waves form her primary recognition shape. She must carry five-star banner presence without appearing fragile, juvenile, passive, or ornamental-only.

Preserve the tall hair mass, asymmetric mantle, fitted waist, split overskirt, and large circular Crescent Reliquary. Poses communicate control under guilt through direct eye contact, a planted stance, and deliberate hand guidance rather than worship or divine elevation.

### Costume, palette, and weapon

Her palette is ivory, violet-black, moon-cyan, and brushed gold. She wears asymmetric ceremonial battle couture: sculpted ivory bodice, fitted black-violet corseted waist, one draped pale sleeve, off-shoulder violet mantle, split ivory-and-violet overskirt, fitted dark leggings, heeled combat footwear, gold chains, crescent filigree, and circular mechanisms. The tailored design balances exposed shoulders with regal coverage.

The **Crescent Reliquary** is an orbiting hand-guided lunar ring with concentric gold rings, ivory crescent plates, moon-cyan gravitational core, and constellation markings. It may hover behind her hand, contract at her hip, or expand into a combat halo. It must not resemble angel wings, a divine crown, or a mundane staff.

### Sheet and animation contract

The full-figure sheet shows three complete figures on white: confident neutral front three-quarter; controlled cast with expanded ring; and combat-ready rear or side three-quarter showing braid, hair, mantle, overskirt, footwear, and hip mechanism. Include an isolated weapon and non-text callouts for hair, core, mechanism, and costume layers.

The three-to-four-head-tall adult chibi preserves braided crown, champagne hair mass, mature eyes, ivory/violet silhouette, asymmetric sleeve and mantle, hip mechanism, and oversized ring. It remains poised, not childlike.

`portrait_lunaris_vessel` routes to the `lunaris_vessel` template. Supported stationary animation is `idle` and `attack` only in four isometric directions. `NE` and `SE` are generated masters; west facings are exact mirrors. Attack is one concise ring charge, discharge, follow-through, and recovery with planted root and fixed scale. Do not register walk, run, deploy, skill, hit, death, or victory regions.

Runtime uses lossless WebP strips, 192×192 cells, pivot `(0.5, 0.94)`, and 12 FPS. Idle has 24 looping frames; attack has 13 non-looping frames sampled with endpoints from `[0, 24)`. Evidence and hashes remain in [`lunaris-reliquary/LUNARIS_VESSEL_ANIMATION_PRODUCTION.md`](lunaris-reliquary/LUNARIS_VESSEL_ANIMATION_PRODUCTION.md).

## `reliquary_duelist`

### Character truth

The Duelist destroyed an extraction reactor during a rushed liberation. He saved hundreds of living captives but burned stored souls before they could be recovered. He spent years calling the result necessary. His guilt is direct: people died because he chose fast destruction over slower rescue.

His recovery is a change in conduct. He commits to rescue before demolition and learns to hold a difficult line rather than take the fast destructive option. Art shows force under control, not guilt erased by aggression.

> “Breaking the cage is easy. Saving everyone inside it is the fight.”

### Adult identity and silhouette

The Duelist is a striking adult East Asian man with a tall athletic-muscular build, mature angular features, narrowed eyes, and long black hair in a high flowing ponytail. Exposed arms, martial posture, and elegant restraint establish sophisticated danger rather than brutality.

His silhouette uses the high ponytail, broad shoulders, bare arms and bracers, asymmetric long panels, and straight Jade Meridian. Maintain clear negative space between blade, body, and coat panels at portrait and chibi scale.

### Costume, palette, and weapon

His palette is dark teal, violet-black, jade-cyan, and antique gold. He wears sleeveless high-collared ceremonial tailoring with fitted torso, asymmetric coat panels, fitted trousers, reinforced boots, broad bracers, arm bands, chains, and geometric reliquary hardware. Teal and cyan must separate from black hair and base costume.

The **Jade Meridian** is a long straight spellblade with dark metal spine, antique-gold guard, and jade-cyan edge or inset. It is balanced for one-handed precision and long enough for a decisive silhouette. Avoid fantasy slabs, generic katanas, and generic glowing swords.

### Sheet and animation contract

The full-figure sheet shows three complete figures on white: relaxed over-shoulder neutral; low controlled spellblade stance; and side or rear three-quarter showing ponytail, sleeveless tailoring, bracers, hardware, panels, and boots. Include an isolated weapon and callouts for tie, chains, bracer, and energy channel.

The broad-shouldered adult chibi preserves mature expression, ponytail mass, powerful arms, teal-and-black silhouette, gold hardware, and enlarged blade. It must not read as a school-age swordsman.

`portrait_reliquary_duelist` routes to its premium template while ordinary `guard_2` visuals remain unchanged. Unique stationary `idle` and `attack` use generated east masters and exact mirrored west derivatives. The compact attack preserves the planted root and does not imply unsupported movement.

Runtime uses 192×192 cells, pivot `(0.5, 0.94)`, 174-pixel neutral-anchor subject height, and 12 FPS. Idle has 24 looping frames; attack has 13 non-looping frames with endpoints from `[0, 24)`. Evidence, including the rejected and regenerated first NE carrier, remains in [`lunaris-reliquary/RELIQUARY_DUELIST_ANIMATION_PRODUCTION.md`](lunaris-reliquary/RELIQUARY_DUELIST_ANIMATION_PRODUCTION.md).

## `archive_caster`

### Character truth

Archive Caster was Patient 33, the thirty-third person recovered after full anima extraction and the first survivor stable enough to fight. Lunaris returned her same unique soul to a prepared adult body. She is not a copy; her identity continues because the original soul returned.

Recovery did not restore every memory. Lunaris leaders erased the missing record because she witnessed the Vessel connecting PROTOS to the Anima Engine, while PROTOS retained evidence of what was done to her. She can see anima moving through machines and judge whether a stored soul remains recoverable. She regains the hidden truth, keeps control of her identity, and releases the records publicly.

> “They returned my soul. Someone kept the truth.”

### Adult identity and silhouette

Archive Caster is a glamorous adult East Asian woman with a poised curvy silhouette, mature fine features, controlled expression, and short silver-lilac curls in a soft bob with braided or pinned details. She is elegant, intellectually dangerous, and ritualistically precise.

Her silhouette uses the curled bob, fitted plum-black body line, asymmetric skirt, translucent edged panels, long gloves, suspended ornaments, and circular Astrolabe. Poses communicate observation and informed control rather than amnesia as fragility.

### Costume, palette, and weapon

Her palette is plum-black, silver-lilac, moon-cyan, and brushed gold. She wears a fitted ceremonial dress with asymmetric layered skirt, controlled high slit, sheer geometric sleeves, translucent cape panels, long gloves, heeled combat footwear, gold jewelry, and suspended ornaments. Plum edging and gold geometry keep translucent fabric readable on white.

The **Archive Astrolabe** is a hand-guided gold orbital focus with concentric rings, hanging weights, chain geometry, and moon-cyan core. It may visualize anima paths and condition but must not depict souls as files or copies. Avoid generic wands, books, and unexplained jewelry.

### Sheet and animation contract

The full-figure sheet shows three complete figures on white: poised neutral with compact Astrolabe; dynamic ritual cast with expanded rings; and side or rear three-quarter showing hair, cape geometry, skirt, gloves, footwear, and ornaments. Include an isolated weapon and callouts for hair, sheer edging, ring mechanism, and focus.

The adult chibi preserves mature expression, curled bob, black-plum silhouette, edged panels, gloves, jewelry, and enlarged Astrolabe. It remains poised and glamorous, not childlike.

`portrait_archive_caster` routes to its premium template while ordinary `caster_1` visuals remain unchanged. Stationary `idle` and `attack` use generated east masters and exact mirrored west derivatives. The cast must not imply that the weapon creates, copies, or burns souls.

Runtime uses 192×192 cells, pivot `(0.5, 0.94)`, 174-pixel subject height, and 12 FPS. Idle has 24 looping frames; attack has 13 non-looping frames sampled over `[0, 32)` to preserve anticipation, pulse near frame 23, and recovery by frame 31. Evidence remains in [`lunaris-reliquary/ARCHIVE_CASTER_ANIMATION_PRODUCTION.md`](lunaris-reliquary/ARCHIVE_CASTER_ANIMATION_PRODUCTION.md).

## Shared production constraints

Every sheet uses a true plain white background without environment, floor texture, frame, border, watermark, or logo. Figures and weapons remain inside the canvas. Repeated figures preserve identical face, adult body type, costume, hair, palette, and weapon.

Full-figure boards provide three poses and one isolated weapon. Chibi boards provide neutral, action-ready, and side or rear three-quarter views. Do not add prose labels inside generated images.

All six approved sheets remain 1632×2176 RGB PNG files with complete poses, weapon presentations, and non-text callouts. Preserve ivory, violet-black, teal or plum, brushed-gold mechanisms, moon-cyan clean energy, premium adult finish, and non-explicit presentation. No sheet may contain generated prose, logos, watermarks, juvenile styling, explicit content, cropped primary figures, or additional characters. Hashes remain in [`lunaris-reliquary/SHA256SUMS`](lunaris-reliquary/SHA256SUMS); validation remains in [`lunaris-reliquary/VALIDATION.md`](lunaris-reliquary/VALIDATION.md).

Portrait crops keep recognition shapes visible: Vessel braid and ring, Duelist ponytail and blade, Caster bob and Astrolabe. Square cards use top-safe centered framing; full-size reveal art preserves adult silhouette and weapon. Localization, text scaling, portrait layout, and Reduced Motion must not obscure identity details.

All visual templates are presentation-only. They must not alter fixed classes, kits, balance, targeting, simulation, premium lives, pity, saves, receipts, hashes, or replay.

| Animation area | Contract |
|---|---|
| States | Stationary `idle` and `attack` only. |
| Directions | Generated `NE` and `SE`; deterministic mirrored `NW` and `SW`. |
| Carriers | Four seconds, 1280×720, H.264, 24 FPS, locked camera and perspective, planted bottom-center root, constant scale. |
| Processing | Sample 48 transparent master frames, measure encoded border chroma, recover alpha, remove fringe contamination, normalize crop, and retain provenance. |
| Runtime | Lossless WebP strips, 192×192 cells, pivot `(0.5, 0.94)`, 12 FPS; 24-frame looping idle and 13-frame non-looping attack. |
| Scale | Use the neutral anchor rather than effect bounds. |
| Accessibility | Reduced Motion and non-video fallbacks preserve a stable identity; no result depends on motion alone. |

Validators continue to check dimensions, RGBA transparency, frames, FPS, loops, pivot, bounds, scale, endpoint recovery, source indices, and pixel-exact mirrors. Godot tests continue to prove portrait routing, manifest validity, WebP loading, frame access, directions, non-placeholder status, and absence of unsupported actions.

## Narrative presentation guardrails

Story art may show Soul Anchors and prepared bodies, but must make the one-soul rule clear. Never depict simultaneous living duplicates. A stored life is a body and anchor prepared for the same soul after a future fall.

Free or rescued souls appear as individual warm-white or pale-blue lights. Processed anima in PROTOS machinery appears violet-magenta. Shape, containment, motion, or context must also distinguish these states so color is not the only signal.

The trio opposes PROTOS, a corrupted rogue AI that drains living people in human farms to power a robot empire. Polished Lunaris presentation must not make harvesting appear voluntary or benign. The Vessel's responsibility, the Duelist's victims, and Archive Caster's stolen memories remain direct while preserving each character's dignity, agency, adult identity, and recovery.
