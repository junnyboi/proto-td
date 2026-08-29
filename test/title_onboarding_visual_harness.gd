extends Node

const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")
const PREFERENCES_PATH := "user://title_onboarding_visual_harness.cfg"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_user_args()
	var output_path := String(args.get("output", ""))
	var mode := StringName(args.get("mode", "mission"))
	var locale_id := StringName(args.get("locale", "en-US"))
	if output_path.is_empty() or mode not in [
		&"mission", &"resonance", &"operation_focus", &"mission_control",
		&"command_settings_button", &"command_settings_modal",
		&"field_squad", &"field_hire", &"field_deploy",
		&"post_training", &"post_valhalla",
	]:
		push_error("valid visual output path and mode are required")
		get_tree().quit(1)
		return
	_remove_preferences()
	VIEW_PREFERENCES.set_locale(locale_id, PREFERENCES_PATH)
	VIEW_PREFERENCES.set_title_music_enabled(false, PREFERENCES_PATH)
	VIEW_PREFERENCES.set_reduced_motion(true, PREFERENCES_PATH)
	if mode not in [&"mission", &"resonance"]:
		VIEW_PREFERENCES.mark_command_tutorial_seen(PREFERENCES_PATH)
	I18n.set_locale(locale_id)
	Game.set_view_preferences_path(PREFERENCES_PATH)
	Game.set_run_seed(82417)
	if not Game.start_campaign(false, true):
		push_error("visual campaign fixture failed")
		get_tree().quit(1)
		return
	if mode in [&"mission", &"resonance"]:
		Game.request_command_tutorial()
	elif mode in [&"field_squad", &"field_hire", &"field_deploy"]:
		Game.selected_stage_id = &"s1"
		Game.request_field_team_tutorial()
	elif mode in [&"post_training", &"post_valhalla"]:
		Game.request_post_mission_tutorial()
	var screen_path := (
		"res://scenes/squad_select.tscn"
		if mode in [&"field_squad", &"field_hire", &"field_deploy"]
		else "res://scenes/staging.tscn"
	)
	var staging := load(screen_path).instantiate() as Control
	if staging.has_method("set_preferences_path"):
		staging.call("set_preferences_path", PREFERENCES_PATH)
	add_child(staging)
	for _frame: int in range(12):
		await get_tree().process_frame
	if mode == &"resonance":
		var tutorial := staging.find_child("CommandCenterTutorial", true, false) as Control
		if tutorial != null:
			tutorial.call("advance")
		for _frame: int in range(6):
			await get_tree().process_frame
	elif mode in [&"field_hire", &"field_deploy"]:
		var field_tutorial := staging.find_child("FieldTeamTutorial", true, false) as Control
		if field_tutorial != null:
			field_tutorial.call("advance")
			if mode == &"field_deploy":
				field_tutorial.call("advance")
		for _frame: int in range(8):
			await get_tree().process_frame
	elif mode == &"post_valhalla":
		var post_tutorial := staging.find_child("PostMissionTutorial", true, false) as Control
		if post_tutorial != null:
			post_tutorial.call("advance")
		for _frame: int in range(8):
			await get_tree().process_frame
	elif mode == &"operation_focus":
		(staging.find_child("NextOperationAction", true, false) as Button).grab_focus()
		await get_tree().process_frame
	elif mode == &"command_settings_button":
		(staging.find_child("CommandSettingsButton", true, false) as Button).grab_focus()
		await get_tree().process_frame
	elif mode == &"command_settings_modal":
		(staging.find_child("CommandSettingsButton", true, false) as Button).pressed.emit()
		for _frame: int in range(6):
			await get_tree().process_frame
	elif mode == &"mission_control":
		(staging.find_child("NextOperationAction", true, false) as Button).pressed.emit()
		for _frame: int in range(12):
			await get_tree().process_frame
		if Game.content == null or Game.content.name != "StageSelect":
			push_error("visual next-operation route did not open Mission Control")
			get_tree().quit(1)
			return
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("visual capture failed: %s" % error_string(save_error))
		get_tree().quit(1)
		return
	print(
		"TITLE_ONBOARDING_VISUAL_OK|%s|%dx%d|mode=%s|locale=%s"
		% [output_path, image.get_width(), image.get_height(), mode, locale_id]
	)
	await _cleanup()
	_remove_preferences()
	get_tree().quit(0)


func _cleanup() -> void:
	var active := Game.content
	Game.content = null
	if active != null and is_instance_valid(active):
		active.queue_free()
	var music := get_tree().root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(16):
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout


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
