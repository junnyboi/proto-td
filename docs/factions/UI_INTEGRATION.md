# Faction Heraldry UI Integration

The canonical faction symbols and banners are now part of the **runtime presentation layer**. This integration is visual only: it does not introduce faction selection, alter campaign authority, change hero ownership, or modify battle simulation.

## Runtime asset contract

The full-resolution canonical sources remain in `docs/factions/symbols/` and `docs/factions/banners/`. Optimized runtime copies live in `assets/ui/factions/` so desktop and Web exports do not carry unnecessary source resolution. Their reproducible integrity record is `assets/ui/factions/SHA256SUMS`.

| Asset class | Canonical source | Runtime format and size | Intended use |
|---|---|---|---|
| Symbol | `docs/factions/symbols/*_symbol.png` | WebP, 512×512 | Header crests, badges, compact cards, and future faction filters |
| Banner | `docs/factions/banners/*_banner.png` | WebP, 384×576 | Faction-standard cards and decorative identity panels |

## Screen behavior

| Screen | Heraldry behavior |
|---|---|
| **Staging** | The procedural placeholder crest is replaced by the canonical Lunaris symbol. A responsive **Faction Standards** panel displays all four canonical banners and symbols with their approved identity subtitles. Lunaris is marked as the active Company 33 faction without implying that the other factions are currently playable. |
| **Mission selection** | The campaign header uses the canonical Lunaris symbol beside the localized campaign heading. |
| **Squad selection** | The mission-command header uses the canonical Lunaris symbol beside the mission title. |
| **Training** | The Reliquary Atelier header uses the canonical Lunaris symbol beside the training title. |

## Post-merge visual verification

The fully merged premium staging skin and faction-heraldry system were captured at **1280×720** and **720×1280** under Xvfb. Both layouts display all four banner-and-symbol pairs in a readable two-column grid, retain the Company 33 active treatment only on Lunaris, and preserve the command deck’s mission card, controls, resource bar, scroll containment, and concept-fidelity frame treatment without overlap or clipping. Campaign, squad-selection, and training captures also retain the canonical Lunaris header symbol.

## Responsive rules

The standards panel uses a readable two-column grid in regular landscape, compact landscape, and portrait. Each card preserves its banner, symbol, faction name, approved identity subtitle, and specialization tooltip. Header symbols shrink rather than disappear at narrow widths. All heraldry is presentation-only and ignores pointer input unless a future faction-selection feature explicitly adds interaction.

## Canonical identity copy

| Faction | Identity subtitle | Specialization tooltip |
|---|---|---|
| **Solcrest Accord** | DAWN PHALANX | Formation defense, linked wards, rally commands, interception, and coordinated counterattacks. |
| **Vesper Circuit** | MIDNIGHT RELAY | Stealth deployment, marks, decoys, signal hijacking, rerouting, traps, and precision execution. |
| **Lunaris Reliquary** | SACRED ARCHIVE | Memory, gravity, ritual geometry, prestige casters, and duelists. |
| **Crimson Aegis** | BREACH CARAVAN | Mobility, displacement, armor fracture, breach chains, and forward deployment. |
