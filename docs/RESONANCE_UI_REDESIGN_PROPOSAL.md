# Premium Resonance UI Redesign Proposal

**Status:** Proposed
**Scope:** Premium Resonance browse screen only
**Reference:** User-supplied 2048×1170 capture, reviewed 2026-08-26

## Executive summary

The current Premium Resonance screen communicates the correct game state, but its hierarchy and proportions make the interface feel like a small card cluster floating inside a very large frame. The strongest visual element is the empty background rather than the premium roster or the pull decision. Text is materially undersized, several labels exceed their available containers, the Command Deck control is too small, and its text-based back arrow is unreliable in the display font.

The recommended revision should make the three premium identities the center of the composition, convert the pity and currency information into a deliberate status rail, and enlarge every text-bearing control enough to contain localized copy. The **LUNARIS RELIQUARY** eyebrow should be removed from the top header. The screen should retain the existing Lunaris frame language, but use it to organize information rather than merely outline empty space.

## Observed issues

| Area | Current issue | User impact | Root cause |
|---|---|---|---|
| Overall composition | Most of the screen is unoccupied while the three hero cards occupy a small central island. | Premium characters feel secondary and the interface appears unfinished. | The hero stage expands to fill available space, but the grid children keep small fixed minimum widths and shrink-center alignment. |
| Header hierarchy | **LUNARIS RELIQUARY** competes with **PREMIUM RESONANCE** despite adding no new information. | The title block is noisy while the actual screen title remains too small. | A redundant eyebrow is always rendered above the title. |
| Command Deck control | The button is too small for its label, and the expected back symbol is missing or unreliable. | Navigation looks clipped and affordance is weakened. | The arrow is encoded as text inside a display font instead of rendered as a dedicated icon; the button has no explicit content-driven minimum width. |
| Hero card widths | Four-star cards are too narrow for names, classes, acquisition state, and explanatory copy. | Labels collide with ornamental frames or overflow vertically. | Fixed 250 px side-card width and 350 px height are not sufficient for the current type and localized strings. |
| Hero card hierarchy | The five-star card is larger, but all cards remain too small relative to the viewport. | Portrait art and premium rarity are difficult to read at a glance. | Card sizes do not scale with the available stage width or height. |
| Intro and pity rail | Explanatory copy and pity labels are compressed into a thin strip. | Important economy rules are difficult to scan and appear visually incidental. | The intro panel is treated as a compact single row rather than a structured status rail. |
| Pull action | The bottom call to action is extremely wide, shallow, and visually detached from marks and pity state. | The primary decision lacks emphasis despite spanning almost the entire screen. | The action dock uses a thin full-width button without a nearby cost/balance summary. |
| Text containment | Names, class labels, status, and descriptive copy exceed their ornamental containers. | Content becomes difficult to read and the premium frame artwork appears broken. | Fixed card geometry, undersized padding, and insufficient wrapping/minimum-height rules. |
| Responsive behavior | The desktop composition wastes space; narrower layouts risk stacking the same undersized cards without improving readability. | The screen does not use viewport changes to strengthen hierarchy. | The current responsive function changes column count but not card scale, content density, or information order. |

## Proposed information architecture

### Header

Use one compact header row with three regions:

| Region | Content | Proposed treatment |
|---|---|---|
| Left | Back to Command Deck | Minimum 260×72 px control with a dedicated back icon texture and a 28–32 px label. Do not rely on a Unicode arrow glyph. |
| Center | Premium Resonance | Single title only. Remove **LUNARIS RELIQUARY**. Use a 48–56 px display title on desktop and 40–44 px in portrait. |
| Right | Marks balance | A framed resource chip containing the Marks icon, value, and label. Minimum 220×72 px. |

### Resonance status rail

Replace the current thin introductory strip with a two-row status rail. The first row should contain a concise rule summary: **Every resonance grants one life. Premium identities keep fixed elite kits.** The second row should pair the pity label with ten clearly visible segments and a compact **5% base rate** badge. This area should be approximately 104–128 px tall on desktop, with 24 px body copy and 20–22 px supporting labels.

### Premium hero stage

Use a responsive 12-column composition at desktop widths:

| Card | Grid span | Recommended minimum | Purpose |
|---|---:|---:|---|
| Lunaris Vessel, five-star | 6 columns | 520×500 px | Dominant featured identity with the largest portrait and gold treatment. |
| Archive Caster, four-star | 3 columns | 300×500 px | Equal-height supporting card with full-width readable text. |
| Reliquary Duelist, four-star | 3 columns | 300×500 px | Equal-height supporting card with full-width readable text. |

All cards should share the same vertical structure: rarity, portrait, name, class, acquisition/life state, and detail. The portrait region may grow, but text regions must have explicit minimum heights. Names should wrap to two lines, supporting copy should use smart word wrapping, and no text control should use clipping as a layout strategy.

Recommended desktop card typography is 22 px for rarity, 30–34 px for names, 22–24 px for class and detail, and 26–30 px for acquisition/life state. Ornamental frame content margins should be at least 24 px on the sides and 20 px vertically. The runtime should calculate card width from the available stage width rather than rely on the current fixed 460/250 px split.

### Action dock

Create a persistent 96–112 px action dock with two semantic regions. The left side should show the current result or readiness state in 22–24 px body type. The right side should contain a 360–440 px **RESONATE · 40 MARKS** primary action at 30–34 px. Cost and remaining balance should remain visible together so the action is understandable without scanning the header.

When the player lacks Marks or an operation is pending, preserve the same geometry and change only state styling and explanatory copy. This prevents the layout from shifting when the button is disabled.

## Responsive behavior

At 900–1199 px, retain three cards but move to a 5/3.5/3.5 proportional layout and reduce only portrait height, not text. Below 900 px, use a single-column scroll sequence: featured card, Archive Caster, Reliquary Duelist. Keep the header and action dock persistent, place Marks beside the title when space permits, and move Marks into the status rail on narrow phones.

At 360–720 px, use a compact icon-only Back control with an accessible tooltip/label, a 40 px title, full-width cards, and stacked status-rail content. Buttons should remain at least 72 px tall. Card detail regions should grow with content; long translations must wrap rather than clip.

## Implementation plan

### Phase 1: Header and navigation correction

Remove `_browse_eyebrow` and its **LUNARIS RELIQUARY** copy from `scripts/ui/gacha.gd`. Replace the text arrow in `_back_button.text` with a dedicated icon texture assigned through the button icon API or a composed icon-and-label child. Give the control an explicit responsive minimum size and preserve keyboard focus styling.

**Gate:** At 1280×720, 720×1280, and 360×800, the title, Marks balance, and Back control remain fully inside the header. The back symbol renders independently of locale and font fallback.

### Phase 2: Status rail and primary action hierarchy

Recompose the introductory copy, pity label, ten pity segments, and rate statement into a structured two-row rail. Rebuild the bottom action area as a persistent dock with status copy and a content-sized pull button.

**Gate:** The pity count, 5% rate, pull cost, Marks balance, and disabled reason are readable without hover or tooltip. No text overlaps the rail or ornamental frame.

### Phase 3: Responsive hero-card system

Replace fixed card widths with breakpoint-driven spans. Introduce a shared premium-card layout contract with explicit portrait, name, metadata, state, and detail regions. Set smart wrapping and content-driven minimum heights for every text area. Scale the cards up to consume the available stage rather than centering a small fixed grid.

**Gate:** All three cards fill the intended stage at desktop size; every English and Chinese test string remains inside its card; no card uses `clip_text` to hide overflow; west/east keyboard traversal and pointer targets remain unchanged.

### Phase 4: Polish and validation

Tune gold/cyan emphasis, spacing, focus rings, and disabled states without adding new decorative layers. Extend `tests/premium_gacha_ui_test.gd` with container-bound assertions, title/Back/Marks hierarchy checks, card minimum-width checks, and localized overflow coverage. Add a real visual harness for browse, confirmation, and disabled states.

**Gate:** Run direct import, bounded headless boot, the complete repository regression suite, strict log scans, and Xvfb captures at 1280×720, 720×1280, and 360×800. Re-export through the existing Web preset and verify the bundle over HTTP before updating the mapped WebDev project.

## Acceptance criteria

| Criterion | Required result |
|---|---|
| Dead space | Hero cards and status rail occupy the central working area; the background remains atmospheric rather than dominant. |
| Navigation | Command Deck control contains its full label and a real icon at every breakpoint. |
| Header copy | **LUNARIS RELIQUARY** is absent from the browse header. |
| Card containment | Every name, class, state, and detail label is visible inside its card in English and the longest supported locale fixture. |
| Typography | No critical browse text is below 20 px on the 1280×720 design canvas; the title and primary action have clear dominance. |
| Responsive layout | Desktop uses a 6/3/3 featured composition; portrait and phone use a readable single-column flow. |
| Action clarity | Pull cost, available Marks, pity state, and disabled reason remain visible near the primary action. |
| Input/accessibility | Focus order, keyboard activation, pointer targets, and reduced-motion behavior remain functional. |

## Recommended delivery boundary

Implement the redesign as one dedicated UI phase after the current title/dialog typography change is merged. No simulation, premium economy, pity, hero identity, cinematic, or save-data behavior should change. The work is presentation-only and should preserve the existing `PremiumGacha` state machine and authoritative pull flow.
