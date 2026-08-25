extends SceneTree

const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")
const PREFERENCES_PATH := "user://title_settings_test.cfg"
const EPSILON := 0.02

var _failures: Array[String] = []
var _original_max_fps := 0
var _original_bus_state: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	_original_max_fps = Engine.max_fps
	_capture_bus_state()
	_check(VIEW_PREFERENCES.master_volume(PREFERENCES_PATH) == 1.0, "master volume default is not 100%")
	_check(VIEW_PREFERENCES.music_volume(PREFERENCES_PATH) == 1.0, "music volume default is not 100%")
	_check(VIEW_PREFERENCES.sfx_volume(PREFERENCES_PATH) == 1.0, "SFX volume default is not 100%")
	_check(VIEW_PREFERENCES.frame_limit(PREFERENCES_PATH) == 0, "frame limit default is not unlimited")
	_check(not VIEW_PREFERENCES.reduced_motion(PREFERENCES_PATH), "reduced motion default is not disabled")
	_check(VIEW_PREFERENCES.mark_pan_hint_seen(PREFERENCES_PATH), "unrelated navigation preference is created")

	var game := root.get_node_or_null("Game")
	var music := root.get_node_or_null("Music")
	var sfx := root.get_node_or_null("Sfx")
	_check(game != null, "Game autoload is available")
	_check(music != null, "Music autoload is available")
	_check(sfx != null, "Sfx autoload is available")
	_check(AudioServer.get_bus_index(&"Music") >= 0, "Music bus was not created")
	_check(AudioServer.get_bus_index(&"SFX") >= 0, "SFX bus was not created")
	if music != null:
		var music_player := music.get_node_or_null("Player") as AudioStreamPlayer
		_check(music_player != null and music_player.bus == &"Music", "Music player is not routed to Music bus")
	if sfx != null:
		var first_voice := sfx.get_node_or_null("Voice0") as AudioStreamPlayer
		_check(first_voice != null and first_voice.bus == &"SFX", "SFX voice is not routed to SFX bus")

	if game != null and music != null:
		await _exercise_sessions(game, music)
	await _cleanup(game, music, sfx)
	_remove_preferences()
	call_deferred("_finish")


func _exercise_sessions(game: Node, music: Node) -> void:
	var first := await _create_title()
	first.call("_open_settings")
	await process_frame
	_check(first.find_child("SettingsPanel", true, false) != null, "Settings modal panel missing")
	_check(first.find_child("AudioHeading", true, false) != null, "Audio settings section missing")
	_check(first.find_child("GraphicsHeading", true, false) != null, "Graphics settings section missing")

	var master_slider := first.find_child("MasterVolumeSlider", true, false) as HSlider
	var music_slider := first.find_child("MusicVolumeSlider", true, false) as HSlider
	var sfx_slider := first.find_child("SfxVolumeSlider", true, false) as HSlider
	var frame_option := first.find_child("FrameLimitOption", true, false) as OptionButton
	_check(master_slider != null and music_slider != null and sfx_slider != null, "audio sliders missing")
	_check(frame_option != null and frame_option.item_count == 4, "frame-limit options missing")
	if master_slider != null:
		master_slider.value = 35.0
	if music_slider != null:
		music_slider.value = 45.0
	if sfx_slider != null:
		sfx_slider.value = 55.0
	if frame_option != null:
		frame_option.select(2)
		first.call("_on_frame_limit_selected", 2)
	first.call("_toggle_reduced_motion")
	await process_frame

	_check(_near(VIEW_PREFERENCES.master_volume(PREFERENCES_PATH), 0.35), "master volume was not saved")
	_check(_near(VIEW_PREFERENCES.music_volume(PREFERENCES_PATH), 0.45), "music volume was not saved")
	_check(_near(VIEW_PREFERENCES.sfx_volume(PREFERENCES_PATH), 0.55), "SFX volume was not saved")
	_check(VIEW_PREFERENCES.frame_limit(PREFERENCES_PATH) == 60, "frame limit was not saved")
	_check(VIEW_PREFERENCES.reduced_motion(PREFERENCES_PATH), "reduced motion was not saved")
	_check(VIEW_PREFERENCES.has_seen_pan_hint(PREFERENCES_PATH), "settings save removed unrelated navigation preference")
	_check(Engine.max_fps == 60, "frame limit was not applied")
	_check(_bus_near(&"Master", 0.35), "master volume was not applied")
	_check(_bus_near(&"Music", 0.45), "music volume was not applied")
	_check(_bus_near(&"SFX", 0.55), "SFX volume was not applied")
	var master_label := first.find_child("MasterVolumeLabel", true, false) as Label
	_check(master_label != null and master_label.text.contains("35%"), "live master-volume copy was not refreshed")
	await _release_title(first, game)

	var second := await _create_title()
	_check(_near(float(second.call("master_volume")), 0.35), "master volume was not restored")
	_check(_near(float(second.call("music_volume")), 0.45), "music volume was not restored")
	_check(_near(float(second.call("sfx_volume")), 0.55), "SFX volume was not restored")
	_check(int(second.call("frame_limit")) == 60, "frame limit was not restored")
	var restored_frame := second.find_child("FrameLimitOption", true, false) as OptionButton
	var restored_motion := second.find_child("MotionButton", true, false) as Button
	_check(restored_frame != null and restored_frame.selected == 2, "restored frame-limit option is incorrect")
	_check(restored_motion != null and restored_motion.text.contains("OFF"), "restored reduced-motion copy is incorrect")
	await _release_title(second, game)
	music.call("stop")


func _create_title() -> Control:
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", PREFERENCES_PATH)
	root.add_child(title)
	await process_frame
	await process_frame
	return title


func _release_title(title: Control, game: Node) -> void:
	if game.get("content") == title:
		game.set("content", null)
	title.queue_free()
	for _frame: int in range(6):
		await process_frame


func _capture_bus_state() -> void:
	for bus_name: StringName in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			_original_bus_state[bus_name] = {
				"volume_db": AudioServer.get_bus_volume_db(index),
				"muted": AudioServer.is_bus_mute(index),
			}


func _restore_bus_state() -> void:
	for bus_name: StringName in _original_bus_state:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		var state: Dictionary = _original_bus_state[bus_name]
		AudioServer.set_bus_volume_db(index, float(state["volume_db"]))
		AudioServer.set_bus_mute(index, bool(state["muted"]))


func _bus_near(bus_name: StringName, expected: float) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return expected <= 0.001
	return _near(db_to_linear(AudioServer.get_bus_volume_db(index)), expected)


func _cleanup(game: Node, music: Node, sfx: Node) -> void:
	if game != null:
		game.set("content", null)
	if music != null:
		music.call("stop")
	if sfx != null:
		sfx.call("stop_all")
	Engine.max_fps = _original_max_fps
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	_restore_bus_state()
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= EPSILON


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_SETTINGS_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
