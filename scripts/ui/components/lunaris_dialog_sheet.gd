class_name LunarisDialogSheet
extends RefCounted

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")

enum Presentation {
	SHEET,
	FULL_VIEWPORT,
}

const SAFE_MARGIN := 18
const NARROW_SAFE_MARGIN := 12
const LANDSCAPE_WIDTH := 820.0
const BODY_MIN_HEIGHT := 200.0
const BODY_MAX_HEIGHT := 360.0
const FULL_READABLE_WIDTH := 980.0
const TITLE_FONT_SIZE := 44
const BODY_FONT_SIZE := 36
const ACTION_FONT_SIZE := 36
const ACTION_MIN_HEIGHT := 88.0
const ENTRY_SECONDS := 0.16


static func create(
		owner: Control,
		node_name: String,
		title_text: String,
		body_text: String,
		confirm_text: String,
		cancel_text: String,
		destructive := false,
		presentation: int = Presentation.SHEET,
	) -> Dictionary:
	var full_viewport := presentation == Presentation.FULL_VIEWPORT
	var overlay := Control.new()
	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.visible = false
	overlay.clip_contents = true
	overlay.set_meta(&"presentation", presentation)
	overlay.set_meta(&"pending", false)
	owner.add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "StateBackdrop" if full_viewport else "Veil"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Style.INK_DEEP if full_viewport else Color(Style.INK_DEEP, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)
	if full_viewport:
		_add_atmosphere(overlay)

	var safe := MarginContainer.new()
	safe.name = "SafeFrame" if full_viewport else "SafeMargin"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(safe)

	var placement := VBoxContainer.new()
	placement.name = "StateFrame" if full_viewport else "Placement"
	placement.alignment = BoxContainer.ALIGNMENT_CENTER
	placement.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(placement)

	var panel := PanelContainer.new()
	panel.name = "Sheet"
	panel.custom_minimum_size = Vector2.ZERO if full_viewport else Vector2(LANDSCAPE_WIDTH, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if full_viewport else Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if full_viewport else Control.SIZE_SHRINK_CENTER
	Style.apply_panel(panel, &"screen" if full_viewport else &"dialog")
	placement.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "Content"
	stack.add_theme_constant_override(&"separation", 16)
	panel.add_child(stack)

	var header := VBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override(&"separation", 10)
	stack.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_label(title, &"heading")
	title.add_theme_font_size_override(&"font_size", TITLE_FONT_SIZE)
	header.add_child(title)

	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Style.CYAN, 0.66)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(rule)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.custom_minimum_size.y = 0.0 if full_viewport else BODY_MIN_HEIGHT
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.follow_focus = true
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL if full_viewport else Control.SIZE_FILL
	stack.add_child(body_scroll)

	var body_frame: Control = null
	if full_viewport:
		body_frame = CenterContainer.new()
		body_frame.name = "ReadableBody"
		body_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_scroll.add_child(body_frame)

	var body := Label.new()
	body.name = "Body"
	body.text = body_text
	body.custom_minimum_size.x = 0.0 if full_viewport else 420.0
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if full_viewport else Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_CENTER if full_viewport else Control.SIZE_FILL
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.apply_label(body, &"body")
	body.add_theme_font_size_override(&"font_size", BODY_FONT_SIZE)
	if body_frame != null:
		body_frame.add_child(body)
	else:
		body_scroll.add_child(body)

	var action_dock: PanelContainer = null
	var actions := GridContainer.new()
	actions.name = "Actions"
	actions.columns = 2
	actions.add_theme_constant_override(&"h_separation", 14)
	actions.add_theme_constant_override(&"v_separation", 10)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if full_viewport:
		action_dock = PanelContainer.new()
		action_dock.name = "ActionDock"
		action_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Style.apply_panel(action_dock, &"quiet")
		stack.add_child(action_dock)
		action_dock.add_child(actions)
	else:
		stack.add_child(actions)

	var cancel := Button.new()
	cancel.name = "CancelButton"
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(0.0 if full_viewport else 300.0, ACTION_MIN_HEIGHT)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.focus_mode = Control.FOCUS_ALL
	Style.apply_button(cancel, &"quiet")
	cancel.add_theme_font_size_override(&"font_size", ACTION_FONT_SIZE)
	cancel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cancel.clip_text = false
	actions.add_child(cancel)

	var confirm := Button.new()
	confirm.name = "ConfirmButton"
	confirm.text = confirm_text
	confirm.custom_minimum_size = Vector2(0.0 if full_viewport else 300.0, ACTION_MIN_HEIGHT)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.focus_mode = Control.FOCUS_ALL
	Style.apply_button(confirm, &"danger" if destructive else &"primary")
	confirm.add_theme_font_size_override(&"font_size", ACTION_FONT_SIZE)
	confirm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm.clip_text = false
	actions.add_child(confirm)
	confirm.set_meta(&"resting_text", confirm_text)

	_bind_focus_scope(cancel, confirm)
	var dialog := {
		&"presentation": presentation,
		&"overlay": overlay,
		&"backdrop": backdrop,
		&"safe": safe,
		&"placement": placement,
		&"panel": panel,
		&"stack": stack,
		&"header": header,
		&"title": title,
		&"body_scroll": body_scroll,
		&"body_frame": body_frame,
		&"body": body,
		&"action_dock": action_dock,
		&"actions": actions,
		&"confirm": confirm,
		&"cancel": cancel,
	}
	overlay.resized.connect(_relayout_dialog.bind(dialog))
	_relayout_dialog(dialog)
	return dialog


static func show_dialog(dialog: Dictionary, return_focus: Control = null) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	var panel := dialog.get(&"panel") as PanelContainer
	var cancel := dialog.get(&"cancel") as Button
	if overlay == null or panel == null or cancel == null:
		return false
	_stop_transition(overlay)
	if return_focus == null and overlay.get_viewport() != null:
		return_focus = overlay.get_viewport().gui_get_focus_owner()
	overlay.set_meta(&"return_focus", return_focus)
	_relayout_dialog(dialog)
	overlay.visible = true
	cancel.grab_focus.call_deferred()
	var reduced_motion := bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	if reduced_motion:
		overlay.modulate.a = 1.0
		return true
	overlay.modulate.a = 0.0
	var tween := overlay.create_tween()
	overlay.set_meta(&"transition_tween", tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, ENTRY_SECONDS)
	return true


static func hide_dialog(dialog: Dictionary, restore_focus := true) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	if overlay == null:
		return false
	_stop_transition(overlay)
	overlay.visible = false
	overlay.modulate.a = 1.0
	if not restore_focus or not overlay.has_meta(&"return_focus"):
		return true
	var return_candidate: Variant = overlay.get_meta(&"return_focus", null)
	if is_instance_valid(return_candidate) and return_candidate is Control:
		var return_focus := return_candidate as Control
		if return_focus.is_visible_in_tree() and return_focus.focus_mode != Control.FOCUS_NONE:
			return_focus.grab_focus.call_deferred()
	return true


static func _stop_transition(overlay: Control) -> void:
	if not overlay.has_meta(&"transition_tween"):
		return
	var transition: Variant = overlay.get_meta(&"transition_tween")
	if transition is Tween and (transition as Tween).is_valid():
		(transition as Tween).kill()
	overlay.remove_meta(&"transition_tween")


static func set_pending(dialog: Dictionary, pending: bool, pending_text := "PROCESSING…") -> bool:
	var overlay := dialog.get(&"overlay") as Control
	var confirm := dialog.get(&"confirm") as Button
	var cancel := dialog.get(&"cancel") as Button
	if overlay == null or confirm == null or cancel == null:
		return false
	if not confirm.has_meta(&"resting_text"):
		confirm.set_meta(&"resting_text", confirm.text)
	overlay.set_meta(&"pending", pending)
	confirm.disabled = pending
	cancel.disabled = pending
	confirm.text = pending_text if pending else String(confirm.get_meta(&"resting_text"))
	return true


static func is_pending(dialog: Dictionary) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	return overlay != null and bool(overlay.get_meta(&"pending", false))


static func set_copy(
		dialog: Dictionary,
		title_text: String,
		body_text: String,
		confirm_text: String,
		cancel_text: String,
		pending_text := "PROCESSING…",
	) -> bool:
	var title := dialog.get(&"title") as Label
	var body := dialog.get(&"body") as Label
	var confirm := dialog.get(&"confirm") as Button
	var cancel := dialog.get(&"cancel") as Button
	if title == null or body == null or confirm == null or cancel == null:
		return false
	title.text = title_text
	body.text = body_text
	cancel.text = cancel_text
	confirm.set_meta(&"resting_text", confirm_text)
	confirm.text = pending_text if is_pending(dialog) else confirm_text
	_relayout_dialog(dialog)
	return true


static func relayout(dialog: Dictionary) -> void:
	_relayout_dialog(dialog)


static func _add_atmosphere(overlay: Control) -> void:
	var upper_glow := ColorRect.new()
	upper_glow.name = "AtmosphereUpper"
	upper_glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	upper_glow.anchor_bottom = 0.38
	upper_glow.color = Color(Style.VIOLET.r, Style.VIOLET.g, Style.VIOLET.b, 0.18)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(upper_glow)
	var lower_glow := ColorRect.new()
	lower_glow.name = "AtmosphereLower"
	lower_glow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lower_glow.anchor_top = 0.72
	lower_glow.color = Color(Style.CYAN_DIM.r, Style.CYAN_DIM.g, Style.CYAN_DIM.b, 0.08)
	lower_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(lower_glow)


static func _bind_focus_scope(cancel: Button, confirm: Button) -> void:
	var to_confirm := cancel.get_path_to(confirm)
	var to_cancel := confirm.get_path_to(cancel)
	for property: StringName in [
		&"focus_neighbor_left", &"focus_neighbor_right", &"focus_neighbor_top",
		&"focus_neighbor_bottom", &"focus_previous", &"focus_next",
	]:
		cancel.set(property, to_confirm)
		confirm.set(property, to_cancel)


static func _relayout_dialog(dialog: Dictionary) -> void:
	var overlay := dialog.get(&"overlay") as Control
	var safe := dialog.get(&"safe") as MarginContainer
	var placement := dialog.get(&"placement") as VBoxContainer
	var panel := dialog.get(&"panel") as PanelContainer
	var stack := dialog.get(&"stack") as VBoxContainer
	var header := dialog.get(&"header") as VBoxContainer
	var body_scroll := dialog.get(&"body_scroll") as ScrollContainer
	var body_frame := dialog.get(&"body_frame") as Control
	var body := dialog.get(&"body") as Label
	var actions := dialog.get(&"actions") as GridContainer
	var cancel := dialog.get(&"cancel") as Button
	var confirm := dialog.get(&"confirm") as Button
	if (
		overlay == null or safe == null or placement == null or panel == null
		or body_scroll == null or body == null or actions == null
	):
		return
	var viewport_size := overlay.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var portrait := viewport_size.x / viewport_size.y <= 1.2
	var narrow := viewport_size.x <= 720.0
	var short_height := viewport_size.y <= 560.0
	var full_viewport := int(dialog.get(&"presentation", Presentation.SHEET)) == Presentation.FULL_VIEWPORT
	var panel_style := Style.panel_style(&"screen" if full_viewport else &"dialog")
	var panel_content_margin := 4.0 if short_height else 22.0
	panel_style.content_margin_left = panel_content_margin
	panel_style.content_margin_top = panel_content_margin
	panel_style.content_margin_right = panel_content_margin
	panel_style.content_margin_bottom = panel_content_margin
	panel.add_theme_stylebox_override(&"panel", panel_style)
	if full_viewport:
		var horizontal_gutter := int(clampf(roundf(viewport_size.x * 0.033), 12.0, 42.0))
		var vertical_cap := 18.0 if short_height else 32.0
		var vertical_gutter := int(clampf(roundf(viewport_size.y * 0.028), 12.0, vertical_cap))
		safe.add_theme_constant_override(&"margin_left", horizontal_gutter)
		safe.add_theme_constant_override(&"margin_right", horizontal_gutter)
		safe.add_theme_constant_override(&"margin_top", vertical_gutter)
		safe.add_theme_constant_override(&"margin_bottom", vertical_gutter)
		placement.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.custom_minimum_size = Vector2.ZERO
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if stack != null:
			stack.add_theme_constant_override(&"separation", 7 if short_height else 16)
		if header != null:
			header.add_theme_constant_override(&"separation", 4 if short_height else 10)
		body_scroll.custom_minimum_size.y = 0.0
		body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var available_width := maxf(0.0, viewport_size.x - float(horizontal_gutter * 2) - 52.0)
		var readable_width := minf(FULL_READABLE_WIDTH, available_width)
		body.custom_minimum_size.x = readable_width
		if body_frame != null:
			body_frame.custom_minimum_size.x = readable_width
			var stack_actions := narrow or portrait
			actions.columns = 1 if stack_actions else 2
			if cancel != null and confirm != null:
				var action_height := 72.0 if short_height else ACTION_MIN_HEIGHT
				cancel.custom_minimum_size = Vector2(0.0, action_height)
				confirm.custom_minimum_size = Vector2(0.0, action_height)
	else:
		var narrow_sheet := viewport_size.x <= 620.0
		var margin := 4 if short_height else (NARROW_SAFE_MARGIN if narrow_sheet else SAFE_MARGIN)
		for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
			safe.add_theme_constant_override(side, margin)
		placement.alignment = BoxContainer.ALIGNMENT_END if viewport_size.y > viewport_size.x or narrow_sheet else BoxContainer.ALIGNMENT_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_END if viewport_size.y > viewport_size.x or narrow_sheet else Control.SIZE_SHRINK_CENTER
		var available_width := maxf(0.0, viewport_size.x - float(margin * 2))
		panel.custom_minimum_size.x = minf(LANDSCAPE_WIDTH, available_width)
		body.custom_minimum_size.x = maxf(0.0, panel.custom_minimum_size.x - 72.0)
		var body_min_height := 80.0 if short_height else BODY_MIN_HEIGHT
		var body_max_height := 128.0 if short_height else BODY_MAX_HEIGHT
		body_scroll.custom_minimum_size.y = clampf(viewport_size.y * 0.24, body_min_height, body_max_height)
		actions.columns = 1 if narrow_sheet else 2
		if cancel != null and confirm != null:
			var action_width := 0.0 if narrow_sheet else 300.0
			var action_height := 72.0 if short_height else ACTION_MIN_HEIGHT
			cancel.custom_minimum_size = Vector2(action_width, action_height)
			confirm.custom_minimum_size = Vector2(action_width, action_height)
	_bind_focus_scope(cancel, confirm)
