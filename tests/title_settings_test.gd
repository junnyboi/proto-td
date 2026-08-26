extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const PATH := "user://title_settings_test.cfg"
const FAIL_PATH := "user://missing/title_settings_test.cfg"
const EPSILON := 0.02

var _failures: Array[String] = []
var _original_max_fps := 0
var _original_bus_state: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove(PATH)
	_original_max_fps = Engine.max_fps
	_capture_buses()
	_check(PREFS.locale(PATH) == &"en-US", "locale default is not English")
	_check(PREFS.mark_pan_hint_seen(PATH), "unrelated navigation preference was not created")
	_check(not PREFS.save_batch({&"locale": &"en-US"}, PATH), "invalid batch was accepted")
	var game := root.get_node_or_null("Game")
	var music := root.get_node_or_null("Music")
	var sfx := root.get_node_or_null("Sfx")
	_check(game != null and music != null and sfx != null, "required autoloads are unavailable")
	if game != null and music != null:
		await _verify_cancel(game, music)
		await _verify_apply(game, music)
		await _verify_failure(game)
	await _cleanup(game, music, sfx)
	_remove(PATH)
	call_deferred("_finish")


func _verify_cancel(game: Node, music: Node) -> void:
	var title := await _create_title(PATH)
	var settings_button := title.find_child("SettingsButton", true, false) as Button
	settings_button.grab_focus()
	title.call("_open_settings")
	await process_frame
	var state_root := title.get_node("TitleSettings") as Control
	_check(StringName(title.call("screen_state")) == &"SETTINGS", "explicit SETTINGS state was not entered")
	_check(state_root.visible and state_root.mouse_filter == Control.MOUSE_FILTER_STOP, "full-rect STOP state is not active")
	_check(title.find_child("SettingsPanel", true, false) == null, "legacy centered panel remains")
	_check(not settings_button.is_visible_in_tree() and settings_button.disabled, "underlying title input remains active")
	var content_before: Node = game.get("content") as Node
	title.call("_on_start_pressed")
	await process_frame
	_check(game.get("content") == content_before, "Start dispatched while Settings was active")
	_edit_draft(title)
	await process_frame
	_check(root.get_node("I18n").call("locale") == &"zh-CN", "locale edit did not preview")
	_check(Engine.max_fps == 60, "frame-limit edit did not preview")
	_check(_bus_near(&"Master", 0.35), "master-volume edit did not preview")
	_check(not bool(title.call("title_music_enabled")), "music edit did not preview")
	_check(bool(title.call("reduced_motion")) and bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)), "reduced-motion edit did not preview")
	_check(PREFS.frame_limit(PATH) == 0, "draft frame limit persisted before Apply")
	_check(_near(PREFS.master_volume(PATH), 1.0), "draft volume persisted before Apply")
	_check(PREFS.locale(PATH) == &"en-US", "draft locale persisted before Apply")
	title.call("_close_settings")
	await process_frame
	_check(StringName(title.call("screen_state")) == &"TITLE", "Cancel did not restore TITLE state")
	_check(root.get_node("I18n").call("locale") == &"en-US" and Engine.max_fps == 0, "Cancel did not restore locale/frame limit")
	_check(_bus_near(&"Master", 1.0), "Cancel did not restore master volume")
	_check(bool(title.call("title_music_enabled")), "Cancel did not restore music preference")
	_check(not bool(title.call("reduced_motion")) and not bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)), "Cancel did not restore reduced motion")
	_check(music.call("current_id") == &"title_lunaris", "Cancel did not restore title cue")
	_check(settings_button.has_focus(), "Cancel did not restore deterministic focus")
	_check(PREFS.has_seen_pan_hint(PATH), "Cancel changed unrelated preference")
	await _release(title, game)


func _verify_apply(game: Node, music: Node) -> void:
	var first := await _create_title(PATH)
	first.call("_open_settings")
	await process_frame
	_edit_draft(first)
	await process_frame
	(first.find_child("SettingsApplyButton", true, false) as Button).pressed.emit()
	await process_frame
	_check(StringName(first.call("screen_state")) == &"TITLE", "Apply did not restore TITLE state")
	_check(_near(PREFS.master_volume(PATH), 0.35), "master volume batch was not saved")
	_check(_near(PREFS.music_volume(PATH), 0.45), "music volume batch was not saved")
	_check(_near(PREFS.sfx_volume(PATH), 0.55), "SFX volume batch was not saved")
	_check(PREFS.frame_limit(PATH) == 60 and PREFS.reduced_motion(PATH), "graphics batch was not saved")
	_check(PREFS.locale(PATH) == &"zh-CN", "locale batch was not saved")
	_check(not PREFS.title_music_enabled(PATH), "music preference batch was not saved")
	_check(PREFS.has_seen_pan_hint(PATH), "batch save removed unrelated navigation preference")
	await _release(first, game)
	var second := await _create_title(PATH)
	_check(root.get_node("I18n").call("locale") == &"zh-CN", "committed locale was not restored")
	_check(_near(float(second.call("master_volume")), 0.35), "committed master volume was not restored")
	_check(int(second.call("frame_limit")) == 60 and bool(second.call("reduced_motion")), "committed graphics were not restored")
	_check(StringName(music.call("current_id")).is_empty(), "disabled committed title music did not stay silent")
	await _release(second, game)


func _verify_failure(game: Node) -> void:
	var title := await _create_title(FAIL_PATH)
	title.call("_open_settings")
	await process_frame
	(title.find_child("SettingsApplyButton", true, false) as Button).pressed.emit()
	await process_frame
	var error := title.find_child("SettingsError", true, false) as Label
	_check(StringName(title.call("screen_state")) == &"SETTINGS", "failed save closed Settings")
	_check(error != null and error.visible and not error.text.is_empty(), "failed save did not show localized error")
	_check(not (title.find_child("SettingsApplyButton", true, false) as Button).disabled, "failed save did not restore editable state")
	title.call("_close_settings")
	await process_frame
	await _release(title, game)


func _edit_draft(title: Control) -> void:
	(title.find_child("MasterVolumeSlider", true, false) as HSlider).value = 35.0
	(title.find_child("MusicVolumeSlider", true, false) as HSlider).value = 45.0
	(title.find_child("SfxVolumeSlider", true, false) as HSlider).value = 55.0
	var frame := title.find_child("FrameLimitOption", true, false) as OptionButton
	frame.select(2)
	frame.item_selected.emit(2)
	(title.find_child("LocaleSelector", true, false) as Node).call("select_locale", &"zh-CN")
	(title.find_child("MusicButton", true, false) as Button).pressed.emit()
	(title.find_child("MotionButton", true, false) as Button).pressed.emit()


func _create_title(path: String) -> Control:
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", path)
	root.add_child(title)
	await process_frame
	await process_frame
	return title


func _release(title: Control, game: Node) -> void:
	if game.get("content") == title:
		game.set("content", null)
	title.queue_free()
	for _frame: int in range(6):
		await process_frame


func _capture_buses() -> void:
	for bus_name: StringName in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			_original_bus_state[bus_name] = {"volume_db": AudioServer.get_bus_volume_db(index), "muted": AudioServer.is_bus_mute(index)}


func _restore_buses() -> void:
	for bus_name: StringName in _original_bus_state:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
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
	root.get_node("I18n").call("set_locale", &"en-US")
	Engine.max_fps = _original_max_fps
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	_restore_buses()
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= EPSILON


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
