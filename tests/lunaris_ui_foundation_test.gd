extends SceneTree

const ThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")
const ShellScene := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const DialogType := preload("res://scripts/ui/components/lunaris_dialog_sheet.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var theme := ThemeType.new()
	_check(theme.get_stylebox(&"normal", &"AuiPrimaryButton") is StyleBoxTexture, "primary action does not use the Lunaris frame")
	_check(theme.get_stylebox(&"panel", &"AuiReadingPanel") is StyleBoxTexture, "reading panel does not use the command-deck frame")
	_check(theme.get_font(&"font", &"AuiTitleLabel") != null, "display typography is missing")

	var shell := ShellScene.instantiate()
	shell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.add_child(shell)
	shell.size = Vector2(1280, 720)
	await process_frame
	shell.set_full_safe_area(true)
	shell.relayout(Vector2i(1280, 720))
	await process_frame
	var plate := shell.reading_plate() as Control
	_check(shell.layout_mode() == &"regular_landscape", "landscape mode was not selected")
	_check(plate.custom_minimum_size.x >= 1200.0, "full-safe-area landscape did not occupy the viewport")
	_check(plate.custom_minimum_size.y >= 640.0, "full-safe-area landscape height is too small")

	shell.size = Vector2(720, 1280)
	shell.relayout(Vector2i(720, 1280))
	await process_frame
	_check(shell.layout_mode() == &"portrait", "portrait mode was not selected")
	_check(plate.custom_minimum_size.x >= 680.0, "full-safe-area portrait width is too small")
	_check(plate.custom_minimum_size.y >= 1230.0, "full-safe-area portrait height is too small")

	var owner := Control.new()
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(owner)
	root.size = Vector2i(540, 960)
	await process_frame
	var return_focus := Button.new()
	return_focus.focus_mode = Control.FOCUS_ALL
	owner.add_child(return_focus)
	var dialog := DialogType.create(owner, "TestDialog", "Confirm operation", "No authoritative state changes until Confirm.", "Confirm", "Cancel")
	var overlay := dialog[&"overlay"] as Control
	var confirm := dialog[&"confirm"] as Button
	var cancel := dialog[&"cancel"] as Button
	var panel := dialog[&"panel"] as PanelContainer
	var placement := dialog[&"placement"] as VBoxContainer
	var actions := dialog[&"actions"] as GridContainer
	_check(overlay != null and not overlay.visible, "dialog should start hidden")
	_check(confirm.custom_minimum_size.y >= 44.0 and cancel.custom_minimum_size.y >= 44.0, "dialog actions are not touch safe")
	_check(panel.custom_minimum_size.x <= 516.0, "narrow dialog exceeds the 540px safe width")
	_check(placement.alignment == BoxContainer.ALIGNMENT_END, "narrow dialog is not bottom attached")
	_check(actions.columns == 1, "narrow dialog actions do not stack")
	_check(cancel.focus_neighbor_top == cancel.get_path_to(confirm), "dialog top focus escapes its scope")
	_check(confirm.focus_neighbor_bottom == confirm.get_path_to(cancel), "dialog bottom focus escapes its scope")
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	_check(DialogType.show_dialog(dialog, return_focus), "dialog did not open")
	await process_frame
	_check(overlay.visible, "dialog overlay remained hidden")
	_check(cancel.has_focus(), "Cancel is not the safe default focus")
	_check(DialogType.set_pending(dialog, true), "dialog pending state failed")
	_check(confirm.disabled and cancel.disabled, "pending state did not lock both actions")
	DialogType.set_pending(dialog, false)
	DialogType.hide_dialog(dialog)
	await process_frame
	_check(not overlay.visible, "dialog did not close")
	_check(return_focus.has_focus(), "dialog did not restore focus")
	var invalid_return := Button.new()
	owner.add_child(invalid_return)
	_check(DialogType.show_dialog(dialog, invalid_return), "dialog did not reopen for invalid return-focus coverage")
	await process_frame
	invalid_return.queue_free()
	await process_frame
	_check(DialogType.hide_dialog(dialog), "dialog failed to close after return focus was invalidated")
	ProjectSettings.set_setting("accessibility/reduced_motion", false)

	owner.queue_free()
	shell.queue_free()
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("LUNARIS_UI_FOUNDATION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
