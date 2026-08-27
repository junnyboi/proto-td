# Faction Design Reference

> **Narrative authority:** [`NARRATIVE_CANON.md`](NARRATIVE_CANON.md) is the sole binding narrative authority. This document records faction presentation and gameplay contracts; it does not establish or amend canon.

Company Manus works with four human factions against PROTOS, the corrupted rogue AI whose human farms drain anima—the real human soul—to power a robot empire. The factions share that enemy but disagree about how to rescue people and prevent another harvesting system. Their technical IDs, visual identities, heraldry, and gameplay specialties remain stable.

## Faction contract

| Faction | Stable ID | Purpose in the Anima War | Moral risk | Visual identity | Gameplay specialty |
|---|---|---|---|---|---|
| **Solcrest Accord** | `solcrest_accord` | Build defended human states, protect civilian corridors, and hold territory against PROTOS. | Leaders may trade prisoners, census records, or human-farm access for security. | **Dawn Phalanx**: black under-armor, deep-teal oath-sashes, plum seals, white-gold lamellar, warm sunstone gold, broad shields, standards, arches, and sunrise causeways. | Formation defense, linked wards, rally commands, interception, coordinated counterattacks, and anti-construct hunts. |
| **Vesper Circuit** | `vesper_circuit` | Break PROTOS's information control, expose extraction routes, and free people and souls trapped in its networks. | Operatives may treat a unique human soul as data or retain extraction research because it is useful. | **Midnight Relay**: midnight navy, wine-red interference glass, cyan signal light, ivory masks, restrained micro-gold, narrow asymmetry, drones, and suspended night infrastructure. | Stealth deployment, marks, decoys, signal hijacking, enemy rerouting, traps, debuffs, and precision execution. |
| **Lunaris Reliquary** | `lunaris_reliquary` | Rescue stolen souls and return each recoverable soul to its living body or one prepared replacement body. | Leaders may hide souls, memories, or bodies for safekeeping and begin treating people as protected assets. | Ivory, moon-cyan, violet-black, and brushed gold; crescents, orbital rings, astrolabes, reflective planes, gravity geometry, and ceremonial symmetry. | Soul shields and recovery devices, gravity control, ritual geometry, elite casters and duelists, and Moon Gate operations. |
| **Crimson Aegis** | `crimson_aegis` | Destroy every human farm, refinery, and machine able to imprison or burn a soul. | Assaults may destroy prisons too quickly and kill captives or burn stored souls. | **Breach Caravan**: scarlet shock-sails, blackened impact plate, forest-green field webbing, weapon gold, small cyan targeting lights, forward wedges, fracture lines, and moving siege works. | Mobility, displacement, armor fracture, breach marks, combo chains, temporary forward deployment, and lane-changing bonuses. |

Anima is never a copy, ordinary information, or faction currency. A soul belongs to the person from whom it came. Faction conflict must preserve that rule even when a leader rationalizes control, trade, research, or demolition.

## Visual separation contract

Color is supporting information, not the only differentiator. Each faction owns a distinct silhouette, material family, energy geometry, environment, and battlefield posture.

| Faction | Silhouette and environment | Energy geometry | Heraldic thesis |
|---|---|---|---|
| **Solcrest Accord** | Broad upright shields, standards, disciplined ranks, civic armor, arches, terraced causeways, beacon towers, and sunrise depth. | Straight linked ward planes, hexagons, bridge interlocks, and controlled solar rays. | A crowned sun rising over an interlocking bridge-shield. |
| **Vesper Circuit** | Narrow asymmetric couture, masks, folding weapons, interference glass, drones, rain-dark markets, cable lifts, and layered night bridges. | Triangulation lines, split planes, fine signal routes, eyes, and folded moth wings. | A split circuit-moth whose central negative space forms a watchful eye. |
| **Lunaris Reliquary** | Flowing ivory and violet-black ceremonial layers, sacred machines, reflective planes, monumental pale architecture, and serene symmetry. | Crescents, orbital rings, astrolabes, individual soul lights, and gravity circles. | A crescent reliquary enclosing an orbital soul star. |
| **Crimson Aegis** | Compressed forward wedges, impact plate, shock-sails, field webbing, assault crawlers, moving bridges, and collapsing fortifications. | Spearheads, chevrons, fracture lines, recoil arcs, and acceleration streaks. | A downward spearhead breaking a fortress ring. |

Free or rescued souls appear as individual warm-white or pale-blue lights. Processed anima appears violet-magenta. Shape, labeling, motion, sound, and contrast must communicate the distinction without relying on color alone.

## Lunaris launch presentation

Lunaris Reliquary remains the selected launch and loading faction. Its centered adult heroine, mechanical lunar halo, adult supporting heroes, ivory-machine setting, and dark reflective lower plane retain the approved launch silhouette. The runtime loading asset is `res://assets/loading/lunaris_reliquary_loading.png`; [`animations/lunaris-reliquary/lunaris-title-keyframe.png`](animations/lunaris-reliquary/lunaris-title-keyframe.png) and the production sheets retain the same identities.

The image must be framed as Company Manus and its Lunaris allies preparing to resist PROTOS and recover stolen souls. The setting must not soften or romanticize the machine empire.

## Lunaris launch trio

| Design ID | Role under the Anima War canon | Full-figure production sheet | In-game chibi sheet |
|---|---|---|---|
| `lunaris_vessel` | Flagship heroine, lunar-focus wielder, and former Anima Engine interface designer seeking to undo the harm her work enabled. | [`lunaris_vessel_design_sheet.png`](lunaris-reliquary/lunaris_vessel_design_sheet.png) | [`lunaris_vessel_chibi_sheet.png`](lunaris-reliquary/lunaris_vessel_chibi_sheet.png) |
| `reliquary_duelist` | Jade-cyan spellblade who must learn to hold rescue lines before destroying soul prisons. | [`reliquary_duelist_design_sheet.png`](lunaris-reliquary/reliquary_duelist_design_sheet.png) | [`reliquary_duelist_chibi_sheet.png`](lunaris-reliquary/reliquary_duelist_chibi_sheet.png) |
| `archive_caster` | Orbital-astrolabe caster, Patient 33, and the same unique soul recovered into a prepared body. | [`archive_caster_design_sheet.png`](lunaris-reliquary/archive_caster_design_sheet.png) | [`archive_caster_chibi_sheet.png`](lunaris-reliquary/archive_caster_chibi_sheet.png) |

These IDs, costumes, weapons, proportions, and silhouettes remain unchanged. The sheets support portraits, animation references, UI art, and battlefield readability. Character truth and story usage follow [`NARRATIVE_CANON.md`](NARRATIVE_CANON.md).

## Asset registry

The retained ensemble concepts are [`Faction - Solcrest Accord.webp`](Faction%20-%20Solcrest%20Accord.webp), [`Faction - Vesper Circuit.webp`](Faction%20-%20Vesper%20Circuit.webp), [`Faction - Lunaris Reliquary.webp`](Faction%20-%20Lunaris%20Reliquary.webp), and [`Faction - Crimson Aegis.webp`](Faction%20-%20Crimson%20Aegis.webp). Detailed separation and production constraints are recorded in [`FACTION_REDESIGN_PROPOSAL.md`](FACTION_REDESIGN_PROPOSAL.md).

Each faction has one full-resolution symbol in `docs/factions/symbols/` and one full-resolution in-world banner in `docs/factions/banners/`. Optimized runtime derivatives and UI behavior are documented in [`factions/UI_INTEGRATION.md`](factions/UI_INTEGRATION.md). These assets are presentation references, not narrative authorities.
