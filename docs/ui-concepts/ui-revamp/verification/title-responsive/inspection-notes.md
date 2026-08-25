# Title Responsive Screenshot Regressions

These reference captures verify the title page and its settings modal at two display extremes that are not covered by the standard landscape and portrait checks. The harness forces reduced motion so the static Lunaris background is deterministic, disables title music, pins modal scroll after deferred focus, releases audio one-shots before exit, captures the Godot viewport directly, validates exact dimensions, and scans runtime logs for script, resource, renderer, or fatal errors.

| Baseline | Viewport | Acceptance result |
|---|---:|---|
| `ultrawide-title.webp` | 2560×1080 | Wordmark, Start, and Settings remain centered and fully visible without excessive stretching or clipping. |
| `ultrawide-settings.webp` | 2560×1080 | Language, all audio controls, frame limit, animated background, and Back are visible without scrolling. |
| `short-landscape-title.webp` | 1024×576 | The complete title action stack remains inside the viewport with readable type and touch-sized controls. |
| `short-landscape-settings.webp` | 1024×576 | The modal remains inside the viewport; its visible scrollbar provides access to lower graphics controls and Back. |

Regenerate the source PNGs with:

```bash
GODOT_BIN=godot tools/capture_title_responsive_regressions.sh
```

The corresponding structural regression in `tests/title_ui_scale_test.gd` independently verifies that the title stack and modal remain within bounds at both sizes, and that short-landscape content exceeds the scroll viewport rather than being clipped or pushed off-screen.

The Settings references were refreshed on 2026-08-25 after the canonical title-music action copy changed from `TITLE MUSIC` to `MUSIC`; title-only references remained byte-identical.
