class_name LunarisDialogSheet
extends RefCounted

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")


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
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		safe.add_theme_constant_override(side, 18)
	overlay.add_child(safe)

	var center := CenterContainer.new()
	center.name = "Center"
	safe.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Sheet"
	panel.custom_minimum_size = Vector2(520, 0)
	Style.apply_panel(panel, &"dialog")
	center.add_child(panel)

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

	var body := Label.new()
	body.name = "Body"
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.apply_label(body, &"body")
	stack.add_child(body)

	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", 14)
	stack.add_child(actions)

	var cancel := Button.new()
	cancel.name = "CancelButton"
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(190, 54)
	cancel.focus_mode = Control.FOCUS_ALL
	Style.apply_button(cancel, &"quiet")
	actions.add_child(cancel)

	var confirm := Button.new()
	confirm.name = "ConfirmButton"
	confirm.text = confirm_text
	confirm.custom_minimum_size = Vector2(190, 54)
	confirm.focus_mode = Control.FOCUS_ALL
	Style.apply_button(confirm, &"danger" if destructive else &"primary")
	actions.add_child(confirm)

	cancel.focus_neighbor_left = cancel.get_path_to(confirm)
	cancel.focus_neighbor_right = cancel.get_path_to(confirm)
	cancel.focus_previous = cancel.get_path_to(confirm)
	cancel.focus_next = cancel.get_path_to(confirm)
	confirm.focus_neighbor_left = confirm.get_path_to(cancel)
	confirm.focus_neighbor_right = confirm.get_path_to(cancel)
	confirm.focus_previous = confirm.get_path_to(cancel)
	confirm.focus_next = confirm.get_path_to(cancel)

	return {
		&"overlay": overlay,
		&"panel": panel,
		&"title": title,
		&"body": body,
		&"confirm": confirm,
		&"cancel": cancel,
	}


static func show_dialog(dialog: Dictionary, return_focus: Control = null) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	var cancel := dialog.get(&"cancel") as Button
	if overlay == null or cancel == null:
		return false
	overlay.set_meta(&"return_focus", return_focus)
	overlay.visible = true
	cancel.grab_focus.call_deferred()
	return true


static func hide_dialog(dialog: Dictionary) -> bool:
	var overlay := dialog.get(&"overlay") as Control
	if overlay == null:
		return false
	overlay.visible = false
	var return_focus := overlay.get_meta(&"return_focus", null) as Control
	if is_instance_valid(return_focus) and return_focus.is_visible_in_tree() and return_focus.focus_mode != Control.FOCUS_NONE:
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
