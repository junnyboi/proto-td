# Premium Resonance History and Duplicate Conversion Design

| Field | Value |
|---|---|
| **Status** | Execution in progress; Phases 0–3 complete |
| **Source candidate** | `cd69b07607cdc5b4bdfea2bd36c43014ffc93e53` |
| **Runtime** | Godot `4.7.2.stable.official.ed1daf0bf` |
| **Scope** | Compact pull-history drawer and duplicate-character conversion feedback |

## Product decision

Premium Resonance will gain a **right-edge Moon Archive drawer** that presents the latest ten committed pull receipts and a **Resonance Conversion** beat inside the settled character reveal. Both surfaces are projections of already committed command receipts. They never roll, award, or mutate gameplay state.

The existing economy remains authoritative: every repeat premium pull adds one stored life to that hero, and a repeat pull of a dead hero revives them with one life. “Conversion” is the presentation language for transforming a duplicate signal into that stored life; it does **not** introduce a second currency, dismantling system, or exchange shop.

> **Creative thesis:** the Reliquary does not discard duplicate identities. It compresses the repeated signal into a luminous reserve-life sigil and archives the transaction as a verified memory.

## Visual concept

### Moon Archive drawer

The drawer is a compact command-ledger surface rather than a generic mobile sidebar. It slides from the right over the browse screen, occupying approximately **430 px** on landscape and the full safe width on narrow portrait viewports. A deep ink-glass panel, antique-gold hairline border, and restrained cyan telemetry separate it from the hero cards while preserving the Lunaris palette.

The header contains a generated **crescent archive glyph**, `MOON ARCHIVE`, the localized total pull count, and a quiet close action. The body uses a vertically scrolling stack of compact receipt rows. Each row contains the hero’s full-size identity portrait, rarity stars, callsign, acquisition state, pull ordinal, and guarantee status. Rows are newest-first and limited to ten; an empty-state plate explains that committed resonances will be archived here.

| Receipt state | Badge | Detail line |
|---|---|---|
| First acquisition | `NEW SIGNAL` | `LIFE 1 • GUARANTEE IN N` |
| Duplicate | `LIFE CONVERTED` | `LIVES X → Y • GUARANTEE IN N` |
| Revival | `REVIVAL` | `RESERVE RESTORED • GUARANTEE IN N` |
| Forced five-star | Additional `GUARANTEE` chip | Gold emphasis without replacing the acquisition badge |

### Resonance Conversion feedback

After the character name and rarity stars settle, a duplicate pull reveals one additional compact plate above `Pull Again`. A generated **reserve-life sigil** blooms in, followed by:

- `DUPLICATE RESONANCE CONVERTED`
- `RESERVE LIFE +1`, or `REVIVAL PROTOCOL • LIFE +1`
- `LIVES X → Y`

The sigil scales from 88% to 100% with a short gold/cyan luminance bloom. The fully grown sigil settles into a low-amplitude pulse synchronized with the existing astral-star rhythm. Reduced-motion mode uses opacity only and does not pulse. First acquisitions do not show the conversion plate.

## Generated asset direction

All new authored visual assets use **GPT Image 2** and match the Lunaris title keyframe and existing astral-star material language.

| Asset | Runtime use | Art direction |
|---|---|---|
| `moon_archive_glyph.png` | Drawer header and History action | Symmetrical crescent reliquary enclosing three tiny archival nodes; moon-glass cyan core, antique-gold filigree, ivory edge light |
| `reserve_life_sigil.png` | Duplicate conversion plate and history badges | Faceted lunar crystal nested in a five-point orbital frame; gold-white core, cyan refraction, restrained indigo shadow |

Both assets are transparent, text-free, centered, readable at 48–96 px, and free of drop shadows that assume a particular background.

## Interaction and accessibility

- The History action is available only in browse state and opens without changing campaign state.
- Drawer opening stores the previous focus; closing restores it exactly.
- `ui_cancel`, the close button, and clicking the dimmed scrim close the drawer.
- Controller focus is trapped inside the drawer while open.
- The drawer exposes localized accessibility names and a polite live summary.
- The history list is readable without relying on color; rarity uses star count and text.
- Reduced motion shortens drawer movement to an opacity transition and suppresses conversion pulse/parallax.
- Pull, Back, and hero-card navigation remain locked only by existing authoritative flow states.

## Data architecture

No new save field is required. `CampaignStateV3.runtime_projection()` derives `premium_pull_history` from canonical `command_receipts` where `verb == "pull_premium_hero"`. Each projected row is a defensive copy of `receipt.premium_pull`, newest-first. The projection returns at most ten rows while exposing `premium_pull_history_total` for the header.

This approach preserves replay compatibility, save hashes, migration behavior, command idempotency, and the current life economy. The final reveal reads the current committed receipt’s existing `new_hero`, `revived`, `lives_before`, and `lives_after` fields.

## Responsive layout

| Viewport | Drawer | Receipt row | Conversion plate |
|---|---|---|---|
| ≥ 1100 px | 430 px right drawer | Portrait 76 px; two-line copy; badges right-aligned | 620 px max width above Pull Again |
| 720–1099 px | 390 px right drawer | Portrait 68 px; badges wrap below | 560 px max width |
| < 720 px | Full safe width | Portrait 64 px; one-column metadata | Full safe width with compact 44–56 px sigil |

## Implementation plan

| Phase | Work | Gate | Status |
|---|---|---|---|
| 0 | Canon inspection and binding concept | Design references command receipts and preserves life authority | Complete |
| 1 | Generate GPT Image 2 archive and reserve-life glyphs; clean alpha; register in art manifest | Both assets pass one visual QA check and remain readable at runtime sizes | Complete |
| 2 | Add receipt-derived history projection and lifecycle regressions | No save-schema change; replay and history rows match committed receipts | Complete |
| 3 | Implement drawer, focus trap, localization, responsive layout, and conversion choreography | Focus restoration, controller cancel, reduced motion, and duplicate/revival copy pass | Complete |
| 4 | Reconcile master and run import, boot, focused tests, full regression suite, and Xvfb desktop/portrait captures | No error diagnostics; all success sentinels pass | Pending |
| 5 | Export Web, stage streams, update existing `proto-td-web`, checkpoint, and publish when available | Required artifacts, HTTP runtime, WebDev type/build, fullscreen host | Pending |

## Acceptance criteria

1. The drawer shows at most ten newest committed premium pulls and the correct total count.
2. History is reconstructed entirely from canonical receipts and survives save encode/restore.
3. First, duplicate, revival, four-star, five-star, and forced-guarantee rows are distinguishable without color-only meaning.
4. Duplicate final reveals show the exact `lives_before → lives_after` conversion; first acquisitions do not.
5. Drawer focus is contained and restored; `ui_cancel` closes it; reduced motion suppresses transform-heavy effects.
6. The two generated GPT Image 2 assets are used at runtime and tracked through the art manifest.
7. Existing one-click pull, Pull Again, click-anywhere dismissal, cinematic looping, audio transitions, pity, and Marks authority remain unchanged.
