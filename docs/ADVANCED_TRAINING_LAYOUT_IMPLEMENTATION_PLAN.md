# Advanced Training Layout Stabilization Plan

**Author:** Manus AI  
**Target:** `proto-td` Advanced Training path-selection screen  
**Engine:** Godot 4.7.2  
**Baseline:** started from `f837d99ff9aa91b6d1d292d6e9c5c7dade3a94a3`; reconciled through upstream `94a85b6ad9ae2fb5c55ee108079e190782887776`

## Problem statement

The Advanced Training screen currently builds its promotion choices inside a vertically scrollable `BoxContainer`. The path region has a hard 540–580 px minimum height, each card begins at 492×420 or 540×780, and `fit_to_content()` can increase those dimensions further. The initial screen may therefore receive an oversized stacked layout before the shell's first settled relayout. A later narrow-and-wide resize emits another layout-mode pass, which explains why the same content becomes less distorted only after resizing.

The action dock has a separate cause. Its generic footer routine divides all available horizontal space equally between actions and marks every button `SIZE_EXPAND_FILL`. Consequently, **Back** and **Add to Plan** become full-width bars despite being short actions, and their role treatments do not share a consistent neutral geometry.

## Implementation design

| Phase | Change | Acceptance gate |
|---|---|---|
| 1. Stable choice composition | **Complete.** Replaced the nested vertical card scroll with a centered `GridContainer`. Columns are computed directly from the current viewport width, fixed card width, and gap, rather than relying only on the shell's asynchronous layout mode. | First entry at 2048×826 shows all five recruit paths in one compact row; resizing narrow and wide does not alter card dimensions or introduce oversized gaps. |
| 2. Fixed promotion cards | **Complete.** Each path uses an explicit 340×225 landscape footprint or 300×225 portrait footprint. The compact hierarchy preserves portrait, class, role, description, skill, combat badge, and field-kit status; decorative temporary-art copy was removed. Content-driven card growth is disabled. | Every card has identical width and height; no card expands because of text or initial layout timing; labels remain contained and readable. |
| 3. Responsive grid behavior | **Complete.** The grid chooses 1–5 columns from actual usable viewport width. The outer Training document scroll is the only overflow surface when multiple fixed rows are required. | Wide desktop uses available horizontal space; 1280-wide layouts use multiple columns; narrow portrait uses one centered column without horizontal overflow. |
| 4. Action dock consistency | **Complete.** `PathActions` uses the same 180×64 secondary frame for **Back** and **Add to Plan**, including the disabled state. The permanent warning and controls share one action bar, aligned bottom-right; actions remain horizontal on landscape and stack right-aligned only in portrait. | Buttons are equal, compact, and right-aligned; the generic footer expander no longer stretches them across the screen. |
| 5. Regression contract | **Complete.** The training layout test now covers initial entry, fixed size, no nested scroll, wide→narrow→wide stability, column count, containment, and action geometry. A deterministic visual harness captures first-entry, selected landscape, and portrait states. | Focused test passes without requiring a resize to establish correct geometry. |
| 6. Visual and release verification | **Native gates complete; deployment in progress.** Exact 2048×826 initial-entry, 1280×720 selected, and 720×1280 path-selection states passed Xvfb review. Direct import, bounded boot, and all 45 repository regressions passed both before and after upstream reconciliation with clean error scans. Web export, browser checks, and existing WebDev checkpointing follow the source push. | Source is pushed only after post-reconciliation tests pass; final Web checkpoint matches the verified GitHub revision. |

## Non-goals and preserved behavior

This change does not alter campaign authority, promotion eligibility, permanent-choice semantics, draft behavior, localization, controller focus order, selection logic, audio routing, or character art. The outer Training workspace retains scrolling where content genuinely exceeds the viewport, but the promotion choices no longer introduce a second scroll surface or content-driven geometry.
