# Title and Command Center Onboarding Implementation Plan

## Objective

Deliver four compatible presentation and navigation improvements without modifying campaign simulation authority:

1. Keep the existing title Settings action and add a second, fixed Settings button at the bottom of the title viewport.
2. Show a skippable, first-run Command Center tutorial that teaches the two principal routes: **Mission Control** for mission selection and **Premium Resonance** for special-hero summoning.
3. Remove the broad cyan/blue fill from keyboard-focused buttons across the shared UI while preserving a clear, accessible warm-gold outline.
4. Make the Command Center's highlighted next-operation card directly open **Field Team** for that operation.

## Product Interpretation

The two controls named in the request live in the Command Center reached after Start, not on the initial logo/title surface. Therefore the title Start action arms the first-run tutorial, and the coachmarks appear on the first Command Center entry where they can point to the real Mission Control and Resonance controls. Completion or Skip is stored in presentation-only `user://` preferences and never enters campaign state, receipts, saves, hashes, or replay data.

The new operation-card shortcut is presentation routing only. It validates the requested stage through the Game facade, assigns the existing `selected_stage_id`, and opens the existing Field Team scene. It does not launch a battle or commit an attempt.

## Architecture

### Title footer Settings

The title controller will create a bottom-wide safe-area dock containing `FooterSettingsButton`. The existing `SettingsButton` remains in the title action stack. Both actions open the same exclusive `TitleSettings` state, share localized copy and input feedback, and return focus to the exact button that opened Settings. The scroll document reserves bottom clearance so enlarged title content never hides beneath the fixed dock.

### First-run Command Center tutorial

A new `CommandCenterTutorial` presentation component will own:

- two steps: Mission Control, then Premium Resonance;
- a viewport-level input shield, centered padded callout card, and directional connector with a clear arrowhead;
- Skip, Next, and Done actions;
- keyboard focus containment and `ui_cancel` Skip behavior;
- reduced-motion-safe entry and step transitions;
- localized English and Simplified Chinese copy;
- stable introspection methods for tests and visual harnesses.

`ViewPreferences` will add an unrelated presentation key for tutorial completion. The title arms a pending tutorial request through `Game`; Command Center consumes that request only when the preference has not been completed. This prevents direct test fixtures and non-title routes from unexpectedly mounting onboarding.

### Direct mission-card routing

The next-operation panel retains its existing framed visual structure. A transparent, accessible full-card `Button` overlay receives pointer and keyboard input. A new `Game.open_field_team_for_stage(stage_id)` method validates campaign activity, membership in the campaign route, unlock state, and stage resource existence before publishing `selected_stage_id` and opening Field Team. Stage Select will use the same facade so both routes obey one navigation contract.

### Focus presentation

Shared buttons outside the tutorial retain accessible keyboard focus styles. The tutorial itself removes the decorative gold target border around Mission Control and Resonance; its connector arrowhead now communicates the active destination without visually impersonating keyboard focus.

Shared button focus styles outside the tutorial will use:

- transparent fill;
- warm-gold 2 px outline;
- restrained 2–3 px expansion;
- no cyan/blue flood behind the button.

Hover, pressed, selected, and disabled states remain unchanged. Specialized buttons that currently reuse a cyan hover box as focus will receive a dedicated transparent gold outline. Text fields and selection state are outside this button-only change.

## Localization

New keys will be added with strict `en-US` / `zh-CN` parity for the two tutorial steps, Skip/Next/Done actions, accessibility name, and direct-operation-card description. `UiCopy` fallbacks and placeholder schemas will remain consistent with the locale catalogs.

## Verification Matrix

| Gate | Acceptance |
|---|---|
| Preference regression | default unseen; completion persists; Settings batch preserves tutorial state |
| Title regression | both Settings actions exist, are reachable, open the same state, restore exact focus, and remain inside all target viewports |
| Tutorial regression | first requested Command Center entry shows two centered padded steps; target geometry and arrowhead move correctly without a visible target border; Skip/Done persists; primary copy is white; second entry stays silent; locale and Reduced Motion pass |
| Routing regression | clicking or activating next-operation card selects the exact next unlocked stage and opens Field Team; invalid/locked stages fail without mutation |
| Focus regression | all shared Button focus boxes have effectively transparent fill and a warm-gold visible border; specialist button components obey the same contract |
| Responsive layout | 4K, ultrawide, 1280×720, short landscape, 720×1280, and narrow portrait remain contained |
| Visual evidence | title footer plus both tutorial steps captured in landscape and portrait; focused Return/action buttons show outline without blue fill; direct card opens Field Team |
| Native release | Godot 4.7.2 import, bounded boot, focused tests, full repository gate, and clean error scan pass |
| Web release | exact Web preset export includes HTML/JS/WASM/PCK, serves over HTTP with correct MIME/ranges, managed fullscreen host builds, loads, navigates, and remains console-clean |

## Release Procedure

1. Implement on an isolated feature branch based on synchronized `master`.
2. Run focused functional, localization, geometry, focus-style, and visual checks.
3. Re-fetch and constructively merge current `origin/master`.
4. Run the complete Godot gate on the reconciled candidate.
5. Fast-forward local `master`, push without rewriting history, and verify remote identity.
6. Export the exact pushed source with Godot 4.7.2 and the matching non-threaded Web templates.
7. Reuse `proto-td-web`, preserving the newest host and cinematic mappings while replacing only the authoritative PCK mapping.
8. Run WebDev type/build and managed browser checks, then save a final checkpoint.

## Progress

| Phase | Status |
|---|---|
| Audit and design | Complete |
| Runtime implementation | Complete |
| Focused and visual verification | Complete |
| Reconciliation and full native gate | Complete |
| Web export and managed deployment | Pending |
| Final checkpoint | Pending |
