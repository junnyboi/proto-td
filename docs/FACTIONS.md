# Protos Faction Concepts

The four factions are designed as distinct character pools, gameplay promises, and heraldic identities for future recruitment banners. All faction and character work follows the canonical premium adult gacha visual contract in [`ART_DIRECTION.md`](ART_DIRECTION.md). **Lunaris Reliquary is locked** through the approved launch ensemble and production sheets in [`LUNARIS_CHARACTER_DESIGNS.md`](LUNARIS_CHARACTER_DESIGNS.md); the other three factions use the redesign directions documented in [`FACTION_REDESIGN_PROPOSAL.md`](FACTION_REDESIGN_PROPOSAL.md). Runtime presentation rules for these canonical symbols and banners are defined in [`factions/UI_INTEGRATION.md`](factions/UI_INTEGRATION.md).

## Canonical faction directions

| Faction | Identity and palette | Character-pool and specialization promise | Canonical concept | Symbol | Banner |
|---|---|---|---|---|---|
| **Solcrest Accord** | **The Dawn Phalanx**: a radiant coalition holding the last sunlit causeways. Black under-armor, deep teal oath-sashes, plum seals, white-gold lamellar, and warm sunstone gold. | Broad heroic appeal with oath-marshals, spellblade adjudicators, reliquary hunters, and ward engineers. Gameplay emphasizes formation defense, linked wards, rally commands, interception, coordinated counterattacks, and anti-reliquary hunts. | [`Faction - Solcrest Accord.webp`](Faction%20-%20Solcrest%20Accord.webp) | [`solcrest_accord_symbol.png`](factions/symbols/solcrest_accord_symbol.png) | [`solcrest_accord_banner.png`](factions/banners/solcrest_accord_banner.png) |
| **Vesper Circuit** | **The Midnight Relay**: a nocturnal intelligence network operating through suspended urban infrastructure. Midnight navy, wine red, cyan signal light, ivory masks, and restrained micro-gold. | Fashion-forward operatives including relay directors, decoy artists, shield hackers, and signal runners. Gameplay emphasizes stealth deployment, marks, decoys, signal hijacking, enemy rerouting, traps, debuffs, and precision execution. | [`Faction - Vesper Circuit.webp`](Faction%20-%20Vesper%20Circuit.webp) | [`vesper_circuit_symbol.png`](factions/symbols/vesper_circuit_symbol.png) | [`vesper_circuit_banner.png`](factions/banners/vesper_circuit_banner.png) |
| **Lunaris Reliquary** | Locked custodians of a moon-powered sacred machine. Ivory, moon-cyan, violet-black, and brushed gold; crescents, orbital rings, gravity geometry, and ceremonial symmetry. | Prestige flagship heroes, elegant ceremonial combat, high-rarity casters and duelists, memory manipulation, gravity effects, and ritual geometry. Existing characters and costume construction do not change. | [`Faction - Lunaris Reliquary.webp`](Faction%20-%20Lunaris%20Reliquary.webp) | [`lunaris_reliquary_symbol.png`](factions/symbols/lunaris_reliquary_symbol.png) | [`lunaris_reliquary_banner.png`](factions/banners/lunaris_reliquary_banner.png) |
| **Crimson Aegis** | **The Breach Caravan**: a mobile strike order that converts forward momentum into siege-breaking impact. Scarlet shock-sails, blackened impact plate, forest-green field webbing, weapon gold, and small cyan targeting lights. | Action-led fighters including breach captains, recoil-shield bruisers, grapnel outriders, demolition medics, and shock-sail lancers. Gameplay emphasizes movement, displacement, armor fracture, breach marks, combo chains, temporary forward deployment, and lane-changing bonuses. | [`Faction - Crimson Aegis.webp`](Faction%20-%20Crimson%20Aegis.webp) | [`crimson_aegis_symbol.png`](factions/symbols/crimson_aegis_symbol.png) | [`crimson_aegis_banner.png`](factions/banners/crimson_aegis_banner.png) |

## Visual separation contract

The factions must not rely on palette alone. Each faction owns a protected combination of silhouette, material family, energy geometry, environment, and battlefield posture.

| Faction | Silhouette and environment | Energy geometry | Heraldic thesis |
|---|---|---|---|
| **Solcrest Accord** | Broad upright shields, standards, disciplined ranks, sunstone civic armor, arches, terraced causeways, beacon towers, and sunrise depth. | Straight linked ward planes, hexagons, bridge interlocks, and controlled solar rays. | A crowned sun rising over an interlocking bridge-shield. |
| **Vesper Circuit** | Narrow asymmetric couture, masks, folding weapons, interference glass, drones, rain-dark markets, cable lifts, and layered night bridges. | Triangulation lines, split planes, fine signal routes, eyes, and folded moth wings. | A split circuit-moth whose central negative space forms a watchful eye. |
| **Lunaris Reliquary** | Flowing ivory and violet-black ceremonial layers, sacred machines, reflective planes, monumental pale architecture, and serene symmetry. | Crescents, orbital rings, astrolabes, memory stars, and gravity circles. | A crescent reliquary enclosing an orbital memory star. |
| **Crimson Aegis** | Compressed forward wedges, impact plate, shock-sails, field webbing, assault crawlers, moving bridges, and collapsing fortifications. | Spearheads, chevrons, fracture lines, recoil arcs, and acceleration streaks. | A downward spearhead breaking a fortress ring. |

## Locked Lunaris launch direction

**Lunaris Reliquary** remains the selected launch and loading faction. Its centered flagship heroine, mechanical lunar halo, adult supporting heroes, ivory-machine world, and dark reflective lower plane provide the permanent launch silhouette. The repository’s runtime loading copy remains `res://assets/loading/lunaris_reliquary_loading.png`, while [`animations/lunaris-reliquary/lunaris-title-keyframe.png`](animations/lunaris-reliquary/lunaris-title-keyframe.png) and the production character sheets preserve the approved identities.

The obsolete documentation-only refinement has been removed. This deletion does **not** alter the locked runtime loading art, title keyframe, launch trio, costumes, weapons, or faction specialization.

## Canonical Lunaris launch trio

| Design ID | Role | Full-figure production sheet | In-game chibi sheet |
|---|---|---|---|
| `lunaris_vessel` | Central flagship heroine and lunar-focus wielder | [`lunaris_vessel_design_sheet.png`](lunaris-reliquary/lunaris_vessel_design_sheet.png) | [`lunaris_vessel_chibi_sheet.png`](lunaris-reliquary/lunaris_vessel_chibi_sheet.png) |
| `reliquary_duelist` | Jade-cyan spellblade duelist | [`reliquary_duelist_design_sheet.png`](lunaris-reliquary/reliquary_duelist_design_sheet.png) | [`reliquary_duelist_chibi_sheet.png`](lunaris-reliquary/reliquary_duelist_chibi_sheet.png) |
| `archive_caster` | Orbital-astrolabe ritual caster | [`archive_caster_design_sheet.png`](lunaris-reliquary/archive_caster_design_sheet.png) | [`archive_caster_chibi_sheet.png`](lunaris-reliquary/archive_caster_chibi_sheet.png) |

The sheets preserve the approved loading and title identities while expanding hidden costume and weapon construction for future portraits, animated sprite references, UI art, and gameplay readability. Personal names remain intentionally unassigned until narrative naming is approved.

## Canonical asset registry

The four canonical faction concepts are `Faction - Solcrest Accord.webp`, `Faction - Vesper Circuit.webp`, `Faction - Lunaris Reliquary.webp`, and `Faction - Crimson Aegis.webp`. The approved Solcrest, Vesper, and Crimson redesigns now occupy those canonical paths; the superseded concept files and temporary `- Redesign` copies have been removed. Lunaris remains locked and unchanged.

Every faction also has one canonical standalone symbol in `docs/factions/symbols/` and one canonical in-world banner in `docs/factions/banners/`. These eight heraldic assets are the source of truth for faction badges, recruitment presentation, banners, flags, environmental dressing, and future UI identity work.
