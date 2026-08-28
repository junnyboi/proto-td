# Advanced Training Layout Stabilization Plan

**Author:** Manus AI  
**Target:** `proto-td` Advanced Training path-selection screen  
**Engine:** Godot 4.7.2  
**Baseline:** started from `f837d99ff9aa91b6d1d292d6e9c5c7dade3a94a3`; reconciled through upstream `94a85b6ad9ae2fb5c55ee108079e190782887776`

## Problem statement

The Advanced Training screen currently builds its promotion choices inside a vertically scrollable `BoxContainer`. The path region has a hard 540–580 px minimum height, each card begins at 492×420 or 540×780, and `fit_to_content()` can increase those dimensions further. The initial screen may therefore receive an oversized stacked layout before the shell's first settled relayout. A later narrow-and-wide resize emits another layout-mode pass, which explains why the same content becomes less distorted only after resizing.

The action dock had a separate cause. Its generic footer routine divided all available horizontal space equally between actions and marked every button `SIZE_EXPAND_FILL`. Consequently, path actions became full-width bars despite being short actions instead of retaining a compact, consistent geometry.

## Annotated redesign update — 2026-08-26

| Phase | Change | Acceptance gate |
|---|---|---|
| 1. Operator-specific title | **Complete.** The heading now renders `CHOOSE A NEW SPECIALIZATION FOR {callsign}` from localized, typed copy. | The current operator callsign appears in the title in English and Chinese without changing campaign semantics. |
| 2. Doubled specialization cards | **Complete.** Landscape cards are 680×450 and portrait cards are 600×450. Portraits and card typography scale with the card; 24-pixel internal padding protects every content edge. | Cards are exactly double the prior footprint and their images, title, role, details, stat strip, and footer remain readable. |
| 3. Color-only interaction states | **Complete.** The selected ornamental background swap was removed. Normal, hover/focus, selected, and selected-hover states now use `StyleBoxFlat` background/border changes with rounded corners and restrained depth. | Selection changes the panel background to Lunaris green with a gold edge; hover/focus uses cyan without loading or swapping a background graphic. |
| 4. Responsive card rail | **Complete.** Five doubled landscape cards occupy one horizontal rail with auto scrolling. Portrait disables horizontal scrolling, stacks one card per row, and exposes all content through the outer Training document scroll. | Every specialization remains reachable at desktop and portrait sizes; a wide→narrow→wide cycle preserves geometry. |
| 5. Screen and action gutters | **Complete.** The specialization page and fixed action dock use 60-pixel left/right gutters in landscape and a safe 24-pixel portrait inset. | Heading, identity strip, cards, warning, and actions clear the ornate screen frame. |
| 6. Action sizing | **Complete.** **Back** is 260×84 and the same geometry is reused by **Retry Promotion** only after a failed durable save. Both use 28-pixel labels and enforce 24-pixel horizontal plus 12-pixel vertical internal padding. | Specialization selection promotes immediately; the normal path screen has no second approval action, while failure recovery remains readable and right-aligned. |
| 7. Regression and visual contract | **Complete.** Tests cover dynamic copy, exact card/image/type scale, flat interaction styles, scrolling behavior, gutters, action padding, localization parity, Chinese rendering, UI foundations, and controller access. Xvfb captures cover 1914×797 initial/selected/scrolled and 720×1280 selected states. After each constructive shared-master reconciliation, direct import, bounded boot, all 45 regressions, and six smoke scripts passed: **53/53 gates**. | Export and the existing WebDev checkpoint are the remaining release steps. |

## Non-goals and preserved behavior

This change does not alter campaign authority, promotion eligibility, permanent-choice semantics, durable retry behavior, localization, controller focus order, audio routing, or character art. The outer Training workspace retains scrolling where content genuinely exceeds the viewport, but the promotion choices no longer introduce a second scroll surface or content-driven geometry.
