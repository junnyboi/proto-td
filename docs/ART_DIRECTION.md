# Protos Visual Art Direction

> **Canonical visual promise:** Protos presents premium adult gacha heroes with exceptional beauty, glamour, confident sensuality, striking physiques, fashion-editorial combat couture, memorable hair and color identities, and immediate high-rarity “must-pull” presence.

This document is the visual source of truth for character concepts, portraits, promotional ensembles, loading and title imagery, UI illustrations, chibi units, animated sprites, and future generated assets. The approved faction concepts in [`docs/`](./) define the reference quality bar; the locked **Lunaris Reliquary** runtime loading art, title keyframe, and production character sheets remain the launch benchmark.

## Non-negotiable character contract

Every depicted hero is **clearly adult, age 21 or older**. Faces, anatomy, posture, styling, and context must communicate mature adulthood. Do not use school uniforms, school-age contexts, juvenile proportions, childlike faces, infantilizing poses, or ambiguous age cues.

Sex appeal is intentional but **non-explicit**. Use mature confidence, athletic or statuesque physiques, elegant body-conscious tailoring, controlled cutouts, exposed shoulders or legs, commanding posture, and fashion photography sensibility. Do not depict nudity, explicit sexual activity, fetish framing, accidental exposure, pornographic posing, or anatomy that prevents the asset from functioning as polished game UI.

## Core visual pillars

| Pillar | Direction |
|---|---|
| **Premium anime realism** | Use high-end painterly anime rendering with mature faces, believable adult anatomy, refined hands, sophisticated lighting, controlled texture, and clean material separation. Avoid flat generic anime, plastic 3D rendering, or photorealistic faces disconnected from the established concepts. |
| **Must-pull charisma** | Give every hero a readable visual thesis: a memorable silhouette, one dominant color identity, distinctive hair, a signature weapon or focus, and confident expression. A unit should remain recognizable from a small portrait or chibi silhouette. |
| **Fashion-editorial combat couture** | Treat costumes as luxury fashion engineered for combat. Use asymmetric tailoring, long panels, fitted structure, deliberate skin balance, gloves or bracers, jewelry, chains, high collars, layered sheers, and faction-specific metalwork. Construction must remain understandable enough for animation. |
| **Powerful adult physiques** | Men may be athletic, broad, lean-muscular, or statuesque; women may be athletic, curvy, statuesque, or elegantly powerful. Use strong posture and mature proportions rather than exaggerated anatomy that breaks pose, costume, or UI readability. |
| **Hair and color identity** | Give each hero a memorable hairstyle and controlled palette that separates them from their faction ensemble. Hair should carry silhouette and motion without hiding the face or weapon. |
| **Weapon authority** | Pair each hero with one signature weapon, tool, shield, or ritual focus. Its shape language, materials, and energy color must reinforce faction identity and remain readable in full figure, portrait crop, and chibi form. |
| **Science-fantasy monumentality** | Combine sacred geometry, floating architecture, ruined causeways, reliquary mechanisms, luminous energy, and luxurious dark fantasy. Technology should feel ceremonial rather than industrially generic. |

## Shared material and rendering language

Characters use deep near-black textiles, saturated faction accents, polished or brushed gold hardware, selective luminous cyan energy, translucent ritual layers, leather or lacquered armor, and small jewel-like mechanisms. Render metal, cloth, skin, hair, and energy as distinct materials. Reserve the strongest glow for signature weapons, magical focuses, eyes only when narratively justified, and monumental environmental devices.

Faces and hands receive priority over incidental scenery. Eyes must be aligned, expressions intentional, fingers complete, joints plausible, and weapons gripped or levitated coherently. Effects must support silhouettes rather than obscure anatomy or costume construction.

## Composition standards

| Asset | Composition standard |
|---|---|
| **Faction ensemble** | Use cinematic 16:9 framing, a clear lead hero, readable supporting adults, monumental faction architecture, and reserved negative space for UI when required. |
| **Full-figure character sheet** | Use a true plain white studio background. Show one hero in multiple complete full-body poses, include a clear primary-weapon presentation, and add a small number of focused visual callouts. Keep every figure, limb, costume panel, and weapon inside frame. |
| **Chibi design sheet** | Translate the approved adult hero into a production-friendly chibi while preserving mature identity markers, hair silhouette, palette, costume construction, and signature weapon. Use a plain white background and show complete full-body views or poses. |
| **Portrait/UI art** | Prioritize face, hair, upper costume, signature accessory, and faction color. Preserve mature expression and avoid crops that create accidental sexualization. |
| **Animated sprite source** | Lock camera and perspective, keep the complete centered character visible, preserve one consistent scale, and simplify only details that cannot survive the target resolution. |

## Chibi translation standard

Chibi assets are stylized in-game abstractions of **adult heroes**, not younger versions. Preserve mature expressions, adult costume cues, signature makeup or facial structure, faction jewelry, weapon proportions, hair mass, and body-language confidence. Use approximately three to four heads of total height unless a specific gameplay silhouette requires another ratio. Enlarge the head, hands, feet, weapon, and signature mechanisms for readability while keeping costume coverage and adult identity consistent.

Simplify micro-filigree into a hierarchy of large, medium, and small shapes. Preserve the dominant palette and gold/cyan accent placement. Avoid baby proportions, toddler bodies, school styling, childlike expressions, or oversized eyes that erase the hero's mature identity.

## Faction adaptation

| Faction | Visual identity |
|---|---|
| **Solcrest Accord** | The Dawn Phalanx: white-gold civic lamellar over black, deep-teal oath-sashes, plum seals, broad shields, upright standards, sunstone beacons, linked ward planes, and disciplined formation silhouettes. |
| **Vesper Circuit** | The Midnight Relay: midnight technical couture, wine-red interference glass, cyan signal filaments, ivory masks, micro-gold mechanisms, narrow asymmetry, drones, and information-warfare equipment. |
| **Lunaris Reliquary** | Locked: ivory, moon-cyan, violet-black, and brushed gold; ceremonial elegance; lunar rings, sacred mechanisms, gravity and memory motifs; prestige flagship casters and duelists. |
| **Crimson Aegis** | The Breach Caravan: scarlet shock-sails, blackened impact plate, forest-green field webbing, weapon-gold breach edges, forward wedges, ram-lances, recoil shields, and momentum-driven effects. |

Faction palettes differentiate heroes but never replace individual identity. Within every faction, separate characters by hair color, silhouette, weapon, accent placement, and costume rhythm.

## Generation and review guardrails

Use approved character references for every subsequent image or animation. Preserve identity, age, face, hair, outfit construction, equipment, palette, and body type unless a redesign is explicitly approved. When generating additional poses or chibi variants, treat the full-figure sheet as the canonical reference and describe only the requested change.

Reject assets with ambiguous age, juvenile styling, generic costume design, duplicated or missing anatomy, face drift, mismatched weapons, unreadable silhouettes, random accessories, inconsistent gold/cyan mechanisms, cropped equipment, unexplained wardrobe changes, excessive bloom, sexually explicit framing, or visual detail that cannot survive the intended UI size.

## Canonical references

| Priority | Repository reference |
|---:|---|
| 1 | `assets/loading/lunaris_reliquary_loading.png` |
| 2 | `docs/animations/lunaris-reliquary/lunaris-title-keyframe.png` |
| 3 | `docs/LUNARIS_CHARACTER_DESIGNS.md` and its production sheets |
| 4 | `docs/Faction - Lunaris Reliquary.webp` |
| 5 | `docs/Faction - Solcrest Accord.webp` |
| 6 | `docs/Faction - Vesper Circuit.webp` |
| 7 | `docs/Faction - Crimson Aegis.webp` |
| 8 | `docs/factions/symbols/` and `docs/factions/banners/` |
| 9 | `docs/FACTION_REDESIGN_PROPOSAL.md` |

Future art guidance may add faction-specific details, but it must not weaken the adult-age rule, non-explicit presentation, premium finish, or must-pull character promise defined here.
