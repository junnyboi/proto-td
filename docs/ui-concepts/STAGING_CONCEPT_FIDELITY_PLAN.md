# Staging Concept-Fidelity Implementation Plan

**Owner:** Agent 3

**Branch:** `agent-3/staging-concept-fidelity`

**Base:** `26e40b815c1287e3288bf35e7f4d049f055eda76`
**Target engine:** Godot `4.7.2.stable.official.ed1daf0bf`

## Objective

The GPT Image 2 desktop and portrait staging concepts are the visual source of truth for this pass. The implementation will reproduce their ceremonial Lunaris identity as closely as a dynamic, localized, interactive Godot interface permits. Runtime text and numbers remain native controls; generated images supply the ornamental symbols, bevels, corner filigree, metallic surface treatment, glows, and borders that flat `StyleBoxFlat` primitives cannot reproduce convincingly.

The pass is intentionally staging-focused. It establishes reusable assets and components that later screens may adopt, but it does not redesign unrelated screens or change campaign authority, stage progression, reward logic, balance, persistence, or purchase behavior.

## Design decomposition

| Concept element | Production approach | Runtime behavior |
|---|---|---|
| Lunaris seal | Standalone GPT Image 2 transparent PNG | Header identity and campaign progress crest |
| Mission sigil | Standalone GPT Image 2 transparent PNG | Mission card and primary action ornament |
| Barracks, Recruit, Armory, Memorial, Training symbols | Five standalone GPT Image 2 transparent PNGs | Operation-tile symbols with disabled tinting |
| Resource symbols | Aether crystal, astral seal, stamina orb; standalone transparent PNGs | Mock-wallet chips in the top navbar |
| Exit symbol | Standalone transparent PNG matching the concept’s angular departing arrow | Native button paired with localized `Exit` text |
| Status diamond | Standalone cyan crystal indicator | Locked/coming-soon tile accent and progress endpoint |
| Primary button | GPT Image 2 gold-metal source frame | Nine-patch native button states, responsive text overlay |
| Secondary operation tile | GPT Image 2 black-glass/brass source frame | Nine-patch buttons, one or two columns by breakpoint |
| Command deck | GPT Image 2 black-glass/brass source frame | Nine-patch panel that expands to measured content |
| Mission card | GPT Image 2 inset beveled source frame | Nine-patch container around live mission art and copy |
| Resource chip | GPT Image 2 compact black-glass source frame | Nine-patch chip around live icon, value, and plus affordance |
| Progress ornament | GPT Image 2 thin brass-and-cyan source strip | Nine-patch campaign progress background with native fill |

Every generated item will be a separate source image. Icons will not be extracted from a contact sheet. The production pass will use a shared prompt vocabulary, palette, material definition, and lighting direction so the set reads as one manufactured interface kit.

## Asset production specification

The canonical palette is moonless navy-black (`#040A12`), black-blue glass (`#0B1827`), antique brass (`#D9B96E`), champagne highlight (`#F0D89A`), moon cyan (`#91EAF1`), pale ivory (`#F5EFE1`), and muted steel (`#AEBFD0`). Ornament must use thin engraved geometry, radial astronomical marks, pointed cut corners, restrained cyan emissive details, subtle surface wear, and warm internal gold bloom. No text, letters, numerals, characters, scenery, mock buttons, checkerboards, drop shadows outside the asset boundary, or baked background may appear in reusable UI assets.

Icon masters will be generated at 1024×1024 or larger, centered with generous transparent padding, then deterministically downsampled to 256×256 source textures with clean alpha. Horizontal frames will be generated at the widest available landscape resolution, then chroma/alpha-cleaned and converted into Godot `NinePatchRect` or `StyleBoxTexture` assets with protected corners. Each final PNG will be inspected at both native and enlarged scale.

The repository layout will be:

| Path | Purpose |
|---|---|
| `assets/ui/staging/icons/` | Final standalone crest, operation, resource, exit, and status symbols |
| `assets/ui/staging/frames/` | Final primary, operation, command-deck, mission-card, chip, and progress textures |
| `assets/fonts/Cinzel-Variable.ttf` | Official Google Fonts Cinzel variable font |
| `assets/fonts/Cinzel-OFL.txt` | Required SIL Open Font License 1.1 notice |
| `docs/ui-concepts/staging-concept-fidelity/` | Generation brief, source prompts, review contact sheets, and checksums |

## Typography plan

The concept’s synthetic display lettering most closely resembles **Cinzel**, an open-source Roman inscriptional serif with six usable weights and a 400–900 variable axis. Google Fonts metadata identifies it as an OFL serif designed by Natanael Gama.[1] The SIL Open Font License permits bundling and embedding the unmodified font with software when its copyright notice and license accompany the distribution.[2]

Cinzel will be used for English-only faction identity, section headings, operation names, resource values, progress metrics, and action labels. The current Protos/Noto Sans face remains the body font for mission descriptions and is the complete fallback for Simplified Chinese. The implementation will never force Cinzel onto CJK text, because the official Cinzel metadata lists Latin and Latin Extended subsets only.[1]

## Mock resource system

A presentation-only `StagingMockWallet` model will return deterministic resource rows. Initial values mirror the concept: **12,450 Aether**, **1,240 Astral Sigils**, and **88/120 Stamina**. The system is deliberately non-persistent and non-spendable. It exposes typed dictionaries with a stable resource ID, localized accessible name, current value, optional capacity, icon texture, and whether a plus affordance is shown.

The top navbar will project those rows into live resource chips. On regular landscape it shows all three resources, message and settings symbols, and Exit. On compact landscape it hides nonfunctional message/settings affordances before collapsing resource chips. On portrait it shows campaign progress, two compact currencies, and Exit as in the concept; stamina moves into an overflow resource row only when horizontal space permits. Plus indicators are decorative and non-interactive until a real economy exists, preventing false purchase behavior.

## Exit behavior

`Back to Title` becomes **Exit** on the staging screen. The button keeps the existing safe navigation behavior by calling `Game.open_title()`; it does not terminate the application. The visible control uses the generated exit symbol, the localized `Exit` label, a minimum 44×44 interaction target, keyboard focus styling, and `ui_cancel` parity. New English and Simplified Chinese localization keys will be added canonically.

## Responsive component architecture

The current shared command-content subtree remains authoritative. Generated frames wrap native controls and never contain baked copy. At 1180 px and wider, the layout matches the desktop concept: full-width resource navbar, hero art on the left, and a framed command deck on the right. Between 800 and 1179 px, the command deck narrows, decorative labels simplify, and low-priority navbar affordances disappear. In portrait, the hero stage occupies the upper region and the command deck becomes a bottom-attached framed sheet. Below 560 px, the mission card stacks vertically and resource chips collapse to compact icon/value presentations.

Containers size from content and viewport clamps rather than fixed coordinates. Nine-patch borders preserve corner ornaments while widths and heights change. Native text handles localization and accessibility. Overflow is allowed only inside the command sheet when real content exceeds available height; no vertically centered dialog or artificial spacer is permitted.

## Implementation sequence

First, generate the master style reference and all standalone icons with GPT Image 2, then review alpha, silhouette consistency, palette, and downsample quality. Second, generate the six frame textures, convert them into scalable nine-patch assets, and determine protected corner margins through visual tests. Third, add Cinzel plus its OFL notice and implement a staging typography helper that selects Cinzel for Latin display roles and the existing Noto-based face for CJK/body roles. Fourth, implement `StagingMockWallet` and the responsive resource-chip component. Fifth, replace the top navbar, Exit control, operation symbols, status indicators, and all flat staging frames. Finally, rerender desktop, compact landscape, target portrait, narrow portrait, and Simplified Chinese states.

## Acceptance criteria

| Gate | Required result |
|---|---|
| Concept fidelity | Beveled cut corners, engraved brass lines, cyan crystal accents, ornamental symbols, resource chips, and Exit control visibly match the GPT Image 2 concepts |
| Asset integrity | Every symbol/frame is a standalone generated source, has clean alpha, is registered/imported, and has recorded prompt/provenance/checksum |
| Dynamic layout | Native labels and values reflow at 1280×720, 1024×768, 720×1280, and 540×960 with no overlap or viewport escape |
| Localization | English uses Cinzel display roles; Chinese uses the existing CJK font with no missing glyphs, clipped labels, or key drift |
| Mock wallet | Values are clearly marked presentation-only in code, deterministic, non-persistent, and non-transactional |
| Interaction | Mission, Training, Exit, keyboard focus, disabled destinations, and `ui_cancel` preserve existing behavior |
| Performance | UI textures are downsampled to appropriate runtime sizes and use nearest practical import dimensions without loading full generation masters at runtime |
| Godot validation | Direct headless import and bounded 120-frame boot pass on Godot 4.7.2; focused staging contracts and windowed renders pass at all breakpoints |

## Risks and mitigations

AI-generated frames may be slightly asymmetric or contain baked shadows; the implementation will use generated art only after lightweight visual review and deterministic alpha cleanup. Nine-patch margins will protect ornamented corners and prevent central bevel distortion. Generated icons may drift stylistically across calls; the full set will share a single master reference and prompt grammar, and one focused correction will be used only when a fatal mismatch is visible. The mock wallet could be mistaken for real economy state; class names, comments, tooltips, and non-interactive plus signs will explicitly mark it as presentation scaffolding.

## References

[1]: https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/METADATA.pb "Google Fonts Cinzel metadata"
[2]: https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/OFL.txt "SIL Open Font License 1.1 for Cinzel"
[3]: https://fonts.google.com/specimen/Cinzel "Cinzel specimen on Google Fonts"
