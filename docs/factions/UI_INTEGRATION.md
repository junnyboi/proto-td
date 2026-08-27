# Faction Heraldry UI Integration

> **Historical technical evidence; not narrative canon.** Current narrative authority: [`../NARRATIVE_CANON.md`](../NARRATIVE_CANON.md). Screenshots and copy observations in this record verify implementation behavior only and do not approve story content.

Faction symbols and banners are part of the runtime presentation layer. This integration is visual only: it does not introduce faction selection, alter campaign authority, change hero ownership, add save fields, or modify battle simulation. Lunaris Reliquary is the active presentation projection for Company Manus; the other three standards do not imply that their rosters are currently playable.

## Runtime identifiers and assets

The faction order and stable IDs are `solcrest_accord`, `vesper_circuit`, `lunaris_reliquary`, and `crimson_aegis`. `FactionHeraldry.ACTIVE_FACTION` remains `lunaris_reliquary`.

Full-resolution source art remains in `docs/factions/symbols/` and `docs/factions/banners/`. Optimized runtime copies remain in `assets/ui/factions/`; their integrity record is `assets/ui/factions/SHA256SUMS`.

| Faction ID | Runtime symbol | Runtime banner |
|---|---|---|
| `solcrest_accord` | `res://assets/ui/factions/solcrest_accord_symbol.webp` | `res://assets/ui/factions/solcrest_accord_banner.webp` |
| `vesper_circuit` | `res://assets/ui/factions/vesper_circuit_symbol.webp` | `res://assets/ui/factions/vesper_circuit_banner.webp` |
| `lunaris_reliquary` | `res://assets/ui/factions/lunaris_reliquary_symbol.png` | `res://assets/ui/factions/lunaris_reliquary_banner.webp` |
| `crimson_aegis` | `res://assets/ui/factions/crimson_aegis_symbol.webp` | `res://assets/ui/factions/crimson_aegis_banner.webp` |

| Asset class | Full-resolution source | Runtime format and nominal size | Intended use |
|---|---|---|---|
| Symbol | `docs/factions/symbols/*_symbol.png` | WebP at 512×512, except the retained Lunaris PNG binding | Header crests, badges, compact cards, and faction filters. |
| Banner | `docs/factions/banners/*_banner.png` | WebP at 384×576 | Faction-standard cards and decorative identity panels. |

Unknown faction lookups continue to fall back to `lunaris_reliquary`. This is presentation fallback behavior, not a persisted faction assignment.

## Screen and navigation behavior

| Screen | Heraldry behavior | Navigation effect |
|---|---|---|
| **Company Command staging** | The Lunaris symbol replaces the procedural placeholder crest. A responsive **Faction Standards** panel shows all four banners and symbols. Lunaris is marked as the active Company Manus faction. | No new route or selection state is introduced. Existing Mission, Training, and Valhalla actions retain their handlers. |
| **Mission selection** | The campaign header shows the Lunaris symbol beside the localized campaign heading. | Existing campaign and stage routing remains unchanged. |
| **Squad selection** | The mission-command header shows the Lunaris symbol beside the mission title. Faction symbols may filter projected roster rows. | Existing squad selection, validation, and deployment routing remains unchanged. |
| **Training** | The training header shows the Lunaris symbol beside the localized title. Faction symbols may filter projected roster rows. | Existing training legality, receipts, persistence, and return routing remains unchanged. |
| **Valhalla** | Visible spelling is **Valhalla**. Faction symbols filter fallen presentation rows. | Internal `vahalla` paths, keys, node names, and `Game.open_vahalla()` remain unchanged for compatibility. Back returns to Company Command. |

The stable localization key `data.company.33.name` remains unchanged, but its rendered English value must be **Company Manus** and its rendered Simplified Chinese value must be **Manus连队**. The numeric key is not player-facing prose and must not be migrated.

## Presentation copy aligned to the Anima War

Identity descriptors are compact interface labels, not canon sources. Their localization must not contradict [`../NARRATIVE_CANON.md`](../NARRATIVE_CANON.md).

| Faction | Identity descriptor | Specialization tooltip |
|---|---|---|
| **Solcrest Accord** | DAWN PHALANX | Formation defense, linked wards, rally commands, interception, and coordinated counterattacks. |
| **Vesper Circuit** | MIDNIGHT RELAY | Stealth deployment, marks, decoys, signal hijacking, rerouting, traps, and precision execution. |
| **Lunaris Reliquary** | SOUL RESCUE | Soul protection and recovery, gravity control, ritual geometry, elite casters, and duelists. |
| **Crimson Aegis** | BREACH CARAVAN | Mobility, displacement, armor fracture, breach chains, and forward deployment. |

Solcrest presentation must leave room for its security-at-any-cost danger. Vesper presentation must not reduce anima to data. Lunaris presentation must state that it rescues unique souls rather than copying or spending them. Crimson presentation must distinguish a controlled rescue breach from demolition that destroys captives.

## Responsive and accessibility contract

The standards panel uses a two-column grid in regular landscape, compact landscape, and portrait layouts. Each card preserves its banner, symbol, faction name, localized identity descriptor, and specialization tooltip. Header symbols shrink rather than disappear at narrow widths. Heraldry ignores pointer input unless an explicit faction-filter control owns the interaction.

Symbols, faction names, labels, tooltips, focus indicators, and accessible names must communicate identity without relying on palette alone. Interactive faction filters maintain at least 44 px touch targets and keyboard/controller focus. Locale switching refreshes tooltips. Text scaling, screen-reader labels, reduced motion, scroll containment, and contrast remain supported.

Processed anima uses violet-magenta, while free or rescued souls appear as separate warm-white or pale-blue lights. Shape, motion, grouping, labels, and luminance must carry the same distinction for players who cannot distinguish those colors.

## Retained verification evidence

The merged staging skin and heraldry system were previously captured under Xvfb at **1280×720** and **720×1280**. Those captures demonstrate that all four banner-and-symbol pairs fit in a readable two-column grid and that the Company Manus active treatment is limited to Lunaris. They also demonstrate preservation of the mission card, controls, resource bar, scroll containment, and frame treatment without overlap or clipping. Campaign, squad-selection, and training captures retain the Lunaris header symbol.

This evidence is historical and should not be read as approval of any old visible story copy. Current reviews must verify Company Manus naming, Anima War language, visible Valhalla spelling, both supported locales, keyboard/controller/pointer/touch access, and non-color-only identity cues.
