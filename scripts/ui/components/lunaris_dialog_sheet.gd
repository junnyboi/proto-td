class_name LunarisDialogSheet
extends RefCounted

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")

const SAFE_MARGIN := 18
const NARROW_SAFE_MARGIN := 12
const LANDSCAPE_WIDTH := 520.0
const BODY_MIN_HEIGHT := 112.0
const BODY_MAX_HEIGHT := 180.0
const ENTRY_SECONDS := 0.16


static func create(
		owner: Control,
		node_name: String,
		title_text: String,
		body_text: String,
		confirm_text: String,
		cancel_text: String,
		destructive := false,
	) -> Dictionary:
	var overlay := Control.new()
	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.visible = false
	owner.add_child(overlay)

	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(Style.INK_DEEP, 0.82)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var safe := MarginContainer.new()
	safe.name = "SafeMargin"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(safe)

	var placement := VBoxContainer.new()
	placement.name = "Placement"
	placement.alignment = BoxContainer.ALIGNMENT_CENTER
	placement.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(placement)

	var panel := PanelContainer.new()
	panel.name = "Sheet"
	panel.custom_minimum_size = Vector2(LANDSCAPE_WIDTH, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Style.apply_panel(panel, &"dialog")
	placement.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "Content"
	stack.add_theme_constant_override(&"separation", 16)
	panel.add_child(stack)

	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.apply_label(title, &"heading")
	stack.add_child(title)

	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Style.CYAN, 0.66)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(rule)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.custom_minimum_size.y = BODY_MIN_HEIGHT
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(body_scroll)

	var body := Label.new()
	body.name = "Body"
	body.text = body_text
	body.custom_minimum_size.x = 420.0
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.apply_label(body, &"body")
	body_scroll.add_child(body)

	var actions := GridContainer.new()
	actions.name = "Actions"
	actions.columns = 2
	actions.add_theme_constant_override(&"h_separation", 14)
	actions.add_theme_constant_override(&"v_separation", 10)
	stack.add_child(actions)

	var cancel := Button.new()
	cancel.name = "CancelButton"
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(190, 54)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.focus_mode = Control.FOCUS_ALL
	Style.apply_button(cancel, &"quiet")
	actions.add_child(cancel)

	var confirm := Button.new()
	confirm.name = "ConfirmButton"
	confirm.text = confirm_text
	confirm.custom_minimum_size = Vector2(190, 54)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.focus_mode = Control.FOCUS_ALL
	Style.apply_button(confirm, &"danger" if destructive else &"primary")
	actions.add_child(confirm)

	_bind_focus_scope(cancel, confirm)
	var dialog := {
		&"overlay": overlay,
		&"safe": safe,
		&"placement": placement,
		&"panel": panel,
		&"title": title,
		&"body_scroll": body_scroll,
		&"body": body,
		&"actions": actions,
		&"confirm": confirm,
		&"cancel": cancel,
	}
	owner.resized.connect(_relayout_dialog.bind(dialog))
	_relayout_dialog(dialog)
	return dialog


static func show_dialog(dialog: Dictionary, return_focus: Control = null) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	var panel := dialog.get(&"panel") as PanelContainer
	var cancel := dialog.get(&"cancel") as Button
	if overlay == null or panel == null or cancel == null:
		return false
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
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, ENTRY_SECONDS)
	return true


static func hide_dialog(dialog: Dictionary) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	if overlay == null:
		return false
	overlay.visible = false
	overlay.modulate.a = 1.0
	if not overlay.has_meta(&"return_focus"):
		return true
	var return_candidate: Variant = overlay.get_meta(&"return_focus", null)
	if is_instance_valid(return_candidate) and return_candidate is Control:
		var return_focus := return_candidate as Control
		if return_focus.is_visible_in_tree() and return_focus.focus_mode != Control.FOCUS_NONE:
			return_focus.grab_focus.call_deferred()
	return true


static func set_pending(dialog: Dictionary, pending: bool, pending_text := "PROCESSING…") -> bool:
	var confirm := dialog.get(&"confirm") as Button
	var cancel := dialog.get(&"cancel") as Button
	if confirm == null or cancel == null:
		return false
	if not confirm.has_meta(&"resting_text"):
		confirm.set_meta(&"resting_text", confirm.text)
	confirm.disabled = pending
	cancel.disabled = pending
	confirm.text = pending_text if pending else String(confirm.get_meta(&"resting_text"))
	return true


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
	var body_scroll := dialog.get(&"body_scroll") as ScrollContainer
	var body := dialog.get(&"body") as Label
	var actions := dialog.get(&"actions") as GridContainer
	var cancel := dialog.get(&"cancel") as Button
	var confirm := dialog.get(&"confirm") as Button
	if overlay == null or safe == null or placement == null or panel == null or body_scroll == null or body == null or actions == null:
		return
	var viewport_size := overlay.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var portrait := viewport_size.y > viewport_size.x
	var narrow := viewport_size.x <= 620.0
	var margin := NARROW_SAFE_MARGIN if narrow else SAFE_MARGIN
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		safe.add_theme_constant_override(side, margin)
	placement.alignment = BoxContainer.ALIGNMENT_END if portrait or narrow else BoxContainer.ALIGNMENT_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_END if portrait or narrow else Control.SIZE_SHRINK_CENTER
	var available_width := maxf(0.0, viewport_size.x - float(margin * 2))
	panel.custom_minimum_size.x = minf(LANDSCAPE_WIDTH, available_width)
	body.custom_minimum_size.x = maxf(0.0, panel.custom_minimum_size.x - 72.0)
	body_scroll.custom_minimum_size.y = clampf(viewport_size.y * 0.18, BODY_MIN_HEIGHT, BODY_MAX_HEIGHT)
	var stack_actions := narrow
	actions.columns = 1 if stack_actions else 2
	if cancel != null and confirm != null:
		var action_width := 0.0 if stack_actions else 190.0
		cancel.custom_minimum_size.x = action_width
		confirm.custom_minimum_size.x = action_width
