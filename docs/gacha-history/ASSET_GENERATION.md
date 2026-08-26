# Moon Archive and Reserve-Life Asset Generation

| Field | Value |
|---|---|
| **Phase** | 1 — GPT Image 2 UI assets |
| **Status** | Complete |
| **Generator** | GPT Image 2 |
| **Master size** | 1920×1920 RGBA PNG |
| **Runtime size** | 512×512 RGBA PNG |

## Assets

| Runtime ID | Runtime file | SHA-256 |
|---|---|---|
| `ui_gacha_moon_archive` | `res://assets/ui/gacha/history/moon_archive_glyph.png` | `d3d7289045fb294b614dcf78ddaa0b4c3950caef73a22c8d4aea9e11ceb8db49` |
| `ui_gacha_reserve_life` | `res://assets/ui/gacha/history/reserve_life_sigil.png` | `0808acb89d641f9419bbef5080bdfe253beee531d457043455776cf51e22ecfa` |

The Moon Archive emblem uses a crescent reliquary, three archival nodes, and a cyan moon-glass core. The reserve-life emblem uses a faceted lunar crystal inside a five-point orbital frame. Both are text-free, centered, transparent, and designed for legibility between 48 and 112 pixels.

## Processing

GPT Image 2 produced each master against a temporary green key. A deterministic Pillow pass removed residual key-color pixels, cropped to the alpha bounds, restored a six-percent safe margin, centered the complete silhouette on a square transparent canvas, and downscaled with Lanczos resampling. The 1920-pixel masters and QA notes remain in the Manus project’s `gacha-history-assets` production folder; only optimized runtime derivatives live in the source repository.

## QA

Both runtime assets passed one visual inspection. Their silhouettes are complete, transparency is clean, fine gold/cyan detail survives at the intended UI sizes, and no unintended text, people, coins, hearts, wings, or radial web motifs are present. Godot `4.7.2.stable.official.ed1daf0bf` imported both textures without script, resource, or parser errors.
