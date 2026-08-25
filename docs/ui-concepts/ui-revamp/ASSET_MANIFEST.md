# UI Revamp Concept Asset Manifest

All concept images were generated with **GPT Image 2** on 2026-08-25. They are visual design targets, not runtime screenshots and not sources of authoritative game data. Character identity, age, costume, and faction references came from `docs/ART_DIRECTION.md`, `docs/LUNARIS_CHARACTER_DESIGNS.md`, `assets/loading/lunaris_reliquary_loading.png`, and `docs/animations/lunaris-reliquary/lunaris-title-keyframe.png`. Mission and Training composition references came from the previously accepted GPT Image 2 concepts in `docs/ui-concepts/assets/`.

| Asset | Target | Orientation | Production use |
|---|---|---:|---|
| `concepts/01-company-command.webp` | Global staging hub | 16:9 | Hero-stage/command-deck hierarchy, destination rail, resource chips |
| `concepts/02-campaign-map.webp` | Campaign and mission selection | 16:9 | Map priority, node states, mission dossier, chapter progress |
| `concepts/03-premium-gacha.webp` | Premium Recruit | 16:9 | Adult banner composition, pity/economy hierarchy, confirmation sheet |
| `concepts/04-vahalla-memorial.webp` | Memorial archive | 16:9 | Fallen roster, selected identity, service ledger, solemn tone |
| `concepts/05-battle-hud.webp` | Battle HUD | 16:9 | Battlefield-safe metrics, operator rail, spell dock, contextual overlays |
| `concepts/06-portrait-command-dialogs.webp` | Command and shared dialogs | 9:16 | Bottom command sheet, touch targets, modal/scrim grammar |
| `concepts/07-portrait-gacha.webp` | Premium Recruit | 9:16 | Banner crop, first-view pity/actions, bottom confirmation |
| `concepts/08-portrait-battle-results.webp` | Battle and results | 9:16 | Horizontal operator strip, fixed spells, responsive result sheet |

The images deliberately contain illustrative names, values, and environments. Runtime implementation must replace every placeholder with the existing Godot model/presenter output. No generated concept is shipped as a static full-screen UI. Full-resolution optimized WebP files and their SHA-256 checksums are stored in this directory.

## Company Command runtime frame assets

The Company Command sizing reimplementation added two **GPT Image 2** runtime frame assets on 2026-08-25. Both were generated from the approved Lunaris command-deck and resource-frame references, with explicit empty content fields and no rasterized labels, icons, or authoritative state. The generated masters were chroma-cleaned, cropped to their visible alpha bounds, and downscaled with aspect-preserving Lanczos resampling for runtime use.

| Runtime asset | Size | Role | Native-authority constraint |
|---|---:|---|---|
| `assets/ui/staging/frames/company_hud_plate.png` | 1344×305 | Divider-free segmented top-HUD plate | Identity, currencies, campaign status, utility controls, and Exit remain native Godot controls. |
| `assets/ui/staging/frames/company_navigation_rail.png` | 476×1152 | Dedicated landscape destination rail | Operation labels, disabled states, focus, localization, and navigation remain native Godot controls. |

Both assets confine ornament to their outer border and corners. `staging_skin.gd` defines independent texture stretch margins and content-safe insets; content margins must never be reset to zero or inferred from one shared constant.
