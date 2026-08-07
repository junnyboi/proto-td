extends RefCounted

## Boot scenario (Phase 0 scope): title scene boots with visible, non-empty
## UI. Phase 1 extends this file with the battle-start flow.


func run(h: SelfTestHarness) -> void:
	await h.frames(10)
	var title := h.scene as Control
	h.check("title scene is a Control", title != null)
	var label := h.scene.find_child("TitleLabel", true, false) as Label
	h.check(
		"title label present + non-empty",
		label != null and not label.text.is_empty(),
		"text=%s" % (label.text if label != null else "<missing>"),
	)
	var button := h.scene.find_child("StartButton", true, false) as Button
	var rect := button.get_global_rect() if button != null else Rect2()
	h.check(
		"start button has a visible rect",
		button != null and rect.size.x > 0.0 and rect.size.y > 0.0,
		"rect=%s" % rect,
	)
	await h.shot("boot")
