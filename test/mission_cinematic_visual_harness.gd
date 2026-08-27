extends Node

const PlayerType := preload("res://scripts/ui/components/mission_cinematic_player.gd")

var _mode := "player"
var _output_path := "/tmp/proto-td-mission-cinematic.png"
var _locale := "en-US"
var _stage_id := "s1"
var _text_scale := 1.5
var _capture_root: Node = null


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
		elif argument.begins_with("--locale="):
			_locale = argument.trim_prefix("--locale=")
		elif argument.begins_with("--stage="):
			_stage_id = argument.trim_prefix("--stage=")
		elif argument.begins_with("--text-scale="):
			_text_scale = clampf(argument.trim_prefix("--text-scale=").to_float(), 0.8, 1.5)
	call_deferred("_run")


func _run() -> void:
	var i18n := get_tree().root.get_node_or_null("I18n")
	if i18n != null:
		i18n.call("set_locale", StringName(_locale))
	var text_scale := get_tree().root.get_node_or_null("TextScale")
	if text_scale != null:
		text_scale.call("set_scale", _text_scale)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	if _mode == "player":
		await _show_direct_player()
	elif _mode == "gate" or _mode == "skip":
		await _show_stage_gate(_mode == "skip")
	else:
		_fail("Unknown mission cinematic visual mode: %s" % _mode)
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_output_path)
	if error != OK:
		_fail("Could not save mission cinematic capture: %s" % error)
		return
	await _cleanup()
	print(
		"MISSION_CINEMATIC_VISUAL_OK mode=%s path=%s locale=%s stage=%s text_scale=%.2f" % [
			_mode, _output_path, _locale, _stage_id, _text_scale,
		],
	)
	get_tree().quit(0)


func _show_direct_player() -> void:
	var player := PlayerType.new()
	player.name = "MissionCinematicVisualPlayer"
	get_tree().root.add_child(player)
	_capture_root = player
	await get_tree().process_frame
	player.present(StringName(_stage_id))
	await get_tree().create_timer(1.25).timeout
	for _frame: int in range(4):
		await get_tree().process_frame
	_verify_playing_overlay(player)


func _show_stage_gate(skip_after_start: bool) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		_fail("Game autoload is unavailable")
		return
	game.call("set_run_seed", 73421)
	if not bool(game.call("start_campaign", false, true)):
		_fail("Could not create mission cinematic visual campaign")
		return
	var campaign := load("res://scenes/stage_select.tscn").instantiate() as Control
	get_tree().root.add_child(campaign)
	_capture_root = campaign
	for _frame: int in range(4):
		await get_tree().process_frame
	var row := campaign.find_child("Stage_s1", true, false) as Button
	if row == null:
		_fail("Stage Select is missing the S1 route")
		return
	row.pressed.emit()
	await get_tree().create_timer(1.25).timeout
	for _frame: int in range(4):
		await get_tree().process_frame
	var overlay := campaign.find_child("MissionCinematicOverlay", true, false) as Control
	if overlay == null:
		_fail("Stage Select did not open the mission cinematic overlay")
		return
	_verify_playing_overlay(overlay)
	if not skip_after_start:
		return
	var action := overlay.call("action_button") as Button
	if action == null:
		_fail("Mission cinematic Skip action is unavailable")
		return
	action.pressed.emit()
	for _frame: int in range(10):
		await get_tree().process_frame
	var content := game.get("content") as Node
	if content == null or content.name != "SquadSelect":
		_fail("Skip did not route to Field Team")
		return
	_capture_root = content


func _verify_playing_overlay(player: Control) -> void:
	var video := player.call("video_player") as VideoStreamPlayer
	var action := player.call("action_button") as Button
	if video == null or not video.visible or not video.is_playing():
		_fail("Mission OGV is not visibly playing")
		return
	if action == null or not action.visible or not action.has_focus():
		_fail("Mission cinematic Skip is not visible and focused")
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var rect := action.get_global_rect()
	if rect.position.x < viewport_size.x * 0.55 or rect.position.y > viewport_size.y * 0.2:
		_fail("Mission cinematic Skip is not in the upper-right safe area")
		return
	if rect.end.x > viewport_size.x + 0.5 or rect.end.y > viewport_size.y + 0.5:
		_fail("Mission cinematic Skip overflows the viewport")


func _cleanup() -> void:
	if _capture_root != null and is_instance_valid(_capture_root):
		if _capture_root.get_parent() != null:
			_capture_root.get_parent().remove_child(_capture_root)
		_capture_root.free()
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		game.set("content", null)
		game.set("campaign_active", false)
		game.set("campaign", null)
		game.set("campaign_store", null)
	var music := get_tree().root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
		for child: Node in music.get_children():
			if child is AudioStreamPlayer:
				var player := child as AudioStreamPlayer
				player.stop()
				player.stream = null
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	for _frame: int in range(12):
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
