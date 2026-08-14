# Protos UI Component Style Guide

**Status:** Active  
**Runtime owner:** `scripts/ui/components/`  
**Machine contract:** `test/test_ui_components.gd.component-contract.json`

This guide documents the reusable Protos presentation rules implemented by the Aetheria UI components. Runtime behavior and the machine contract remain authoritative when prose and code disagree.

## Button hierarchy

The default `AetheriaButton` remains the general-purpose navigation and selection control. Its minimum target is 44×52 logical pixels and its theme typography remains 44px. Compact action controls are an explicit variant for bounded action rows beneath screen content; they do not replace operator cards, stage metadata, locale controls, battle HUD controls, or large primary navigation.

| Specification | Default button | Compact action button |
|---|---:|---:|
| Minimum width | 44px | 44px |
| Minimum height | 52px | 80px |
| Visible label size | 44px | 34px |
| Row top padding | Screen-owned | 20px |
| Width behavior | Content or container-owned | Container-owned; fixed or expanding widths are allowed |
| 200% text mode | 88px theme text | 68px visible label and 160px minimum height |
| 135% expansion mode | Container-dependent | 34px label and 108px minimum height |

A compact action must first call `set_presentation_text()` and then `apply_compact_action_layout()`. The compact method fails closed when the semantic presentation label is absent. It preserves a minimum 44px width, pins the logical minimum to 80px with vertical-shrink sizing, and sizes the visible presentation label to 34px. Godot GridContainer allocation may contribute one rounding pixel, so the measured rendered height is constrained to 80–81px in standard mode rather than being allowed to stretch with sibling content. The logical `Button.text`, role, focus behavior, tooltip, disabled state, and localization key remain unchanged.

Compact visible labels are single-line action or destination words that fit their rendered width, such as `Mission`, `Back`, `Start`, `Retry`, or `Staging`. The complete localized command remains in `Button.text` and `tooltip_text`; shortening the visible label must never discard semantic or localization identity. Explicit newlines and clipped labels are prohibited in compact action rows.

## Action-row spacing

Every compact action row is separated from the preceding content by a `MarginContainer` with exactly 20 logical pixels of top padding. Horizontal and vertical gaps inside a row remain screen-owned because column count and available width vary by viewport.

| Screen | Padded container | Compact controls |
|---|---|---|
| Staging | `OperationGridMargin` | Mission Control, Back to Title, and unavailable operation controls |
| Campaign | `StageRowsMargin` | Eight stage controls and Back to Staging |
| Squad | `ActionRowMargin` | Back and Start Battle |
| Results | `ActionRowMargin` | Retry, Return to Staging, and Back to Title |

The 20px inset must remain outside the action container rather than being simulated with blank text, empty controls, or button content margins. This keeps focus geometry and interaction targets truthful.

## Responsive and accessibility behavior

Compact action typography participates in true 200% text scaling. Any local `font_size` override is doubled by the UI stress path, and button minimum height scales with the same mode. Portrait layouts may reduce the number of columns, but they must not change the 20px top inset or the compact action identity. At every supported viewport, controls remain at least 44×44, presentation labels remain enclosed by their buttons, and scrollbars remain outside the text gutter.

## Implementation pattern

```gdscript
var button := AetheriaButton.new()
button.text = localized_text
button.set_presentation_text(localized_text, rendered_text)
button.apply_compact_action_layout()

var margin := MarginContainer.new()
margin.add_theme_constant_override(
    &"margin_top", AetheriaButton.COMPACT_ACTION_ROW_TOP_PADDING,
)
margin.add_child(action_row)
```

The reusable constants are `COMPACT_ACTION_MINIMUM_WIDTH`, `COMPACT_ACTION_MINIMUM_HEIGHT`, `COMPACT_ACTION_FONT_SIZE`, and `COMPACT_ACTION_ROW_TOP_PADDING` on `AetheriaButton`.

## Verification

The focused component suite proves exact constants and fail-closed behavior. `ui_shell_floor` verifies Staging, Campaign, Squad, and Results across 1920×1080, 1280×720, 960×720, and 720×1280 in standard, 200% text, and 135% expansion modes. Each run checks the 20px margin, expected compact-action count, scaled minimum height, visible label size, text enclosure, responsive reflow, and fresh rendered output.
