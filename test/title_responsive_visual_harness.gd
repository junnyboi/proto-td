extends Node

const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")
const PREFERENCES_PATH := "user://title_responsive_visual_harness.cfg"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_user_args()
	var output_path := String(args.get("output", ""))
	var show_settings := String(args.get("settings", "false")).to_lower() == "true"
	if output_path.is_empty():
		push_error("visual output path missing")
		get_tree().quit(1)
		return
	_remove_preferences()
	VIEW_PREFERENCES.set_title_music_enabled(false, PREFERENCES_PATH)
	VIEW_PREFERENCES.set_reduced_motion(true, PREFERENCES_PATH)
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", PREFERENCES_PATH)
	add_child(title)
	for _frame: int in range(5):
		await get_tree().process_frame
	if show_settings:
		title.call("_open_settings")
		for _frame: int in range(3):
			await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("visual capture failed: %s" % error_string(save_error))
		get_tree().quit(1)
		return
	print(
		"TITLE_RESPONSIVE_VISUAL_OK|%s|%dx%d|settings=%s"
		% [output_path, image.get_width(), image.get_height(), show_settings]
	)
	if get_tree().root.get_node_or_null("Game") != null:
		get_tree().root.get_node("Game").set("content", null)
	title.queue_free()
	for _frame: int in range(4):
		await get_tree().process_frame
	_remove_preferences()
	get_tree().quit(0)


func _parse_user_args() -> Dictionary:
	var parsed: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		parsed[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return parsed


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))
