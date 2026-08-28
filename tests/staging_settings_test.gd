extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const PATH := "user://staging_settings_test.cfg"
const WAIT_TIMEOUT := 1.0
const EPSILON := 0.02

var _failures: Array[String] = []
var _original_max_fps := 0
var _original_reduced_motion := false
var _original_text_scale := 1.0
var _original_locale := &"en-US"
var _original_music_enabled := true
var _original_bus_state: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	_capture_runtime()
	_prepare_runtime()
	_check(PREFS.mark_command_tutorial_seen(PATH), "tutorial preference fixture was not created")
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 8173)
	_check(bool(game.call("start_campaign", false, true)), "Company Command fixture failed")
	var staging := load("res://scenes/staging.tscn").instantiate() as Control
	staging.call("set_preferences_path", PATH)
	root.add_child(staging)
	for _frame: int in range(4):
		await process_frame
	root.get_node("Music").call("play_staging", &"lunaris")
	await _verify_placement_and_focus(staging)
	await _verify_cancel(staging, game)
	await _verify_apply(staging, game)
	await _release(staging, game)
	_prepare_runtime()
	game.call("set_run_seed", 8174)
	_check(bool(game.call("start_campaign", false, true)), "restored Company Command fixture failed")
	var restored := load("res://scenes/staging.tscn").instantiate() as Control
	restored.call("set_preferences_path", PATH)
	root.add_child(restored)
	for _frame: int in range(4):
		await process_frame
	_verify_restored_runtime(restored)
	await _release(restored, game)
	_restore_runtime()
	_remove_preferences()
	call_deferred("_finish")


func _verify_placement_and_focus(staging: Control) -> void:
	var settings_plate := staging.find_child("SettingsUtilityPlate", true, false) as PanelContainer
	var settings_button := staging.find_child("CommandSettingsButton", true, false) as Button
	var exit_plate := staging.find_child("UtilityPlate", true, false) as PanelContainer
	var exit_button := staging.find_child("ExitButton", true, false) as Button
	_check(settings_plate != null and settings_button != null, "Company Command Settings utility is missing")
	_check(exit_plate != null and exit_button != null, "Company Command Exit utility is missing")
	_check(settings_plate.get_parent() == exit_plate.get_parent(), "Settings and Exit do not share the utility row")
	_check(settings_plate.get_index() + 1 == exit_plate.get_index(), "Settings is not immediately left of Exit")
	_check(settings_button.focus_mode == Control.FOCUS_ALL, "Settings is not keyboard focusable")
	_check(not settings_button.accessibility_name.is_empty(), "Settings lacks an accessibility name")
	_check(settings_button.get_node_or_null(settings_button.focus_next) == exit_button, "Settings does not advance directly to Exit")
	_check(exit_button.get_node_or_null(exit_button.focus_previous) == settings_button, "Exit does not reverse directly to Settings")
	var focus_style := settings_button.get_theme_stylebox(&"focus") as StyleBoxFlat
	_check(focus_style != null and focus_style.bg_color.a <= 0.01, "Settings focus state reintroduced a filled highlight")
	_check(focus_style != null and focus_style.border_color.r > focus_style.border_color.b, "Settings focus outline is not warm gold")
	settings_button.grab_focus()
	await process_frame
	_check(settings_button.has_focus(), "Settings could not receive keyboard focus")


func _verify_cancel(staging: Control, game: Node) -> void:
	var settings_button := staging.find_child("CommandSettingsButton", true, false) as Button
	settings_button.pressed.emit()
	var state := staging.get_node("TitleSettings") as Control
	await _wait_for_transition(state, &"ACTIVE")
	_check(StringName(staging.call("settings_screen_state")) == &"SETTINGS", "Settings state did not activate")
	_check(settings_button.focus_mode == Control.FOCUS_NONE, "underlying Settings action remained focusable")
	var focus_owner := root.gui_get_focus_owner()
	_check(focus_owner != null and state.is_ancestor_of(focus_owner), "Settings focus escaped the modal")
	_edit_draft(staging)
	await process_frame
	_check(StringName(root.get_node("I18n").call("locale")) == &"zh-CN", "locale edit did not preview in Company Command")
	_check(Engine.max_fps == 60, "frame-limit edit did not preview in Company Command")
	_check(bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)), "reduced motion did not preview in Company Command")
	_check(_near(float(root.get_node("TextScale").call("value")), 1.35), "text scale did not preview in Company Command")
	_check(_bus_volume_near(&"Master", 0.35) and _bus_muted(&"Master"), "Master volume/mute did not preview in Company Command")
	_check(_bus_volume_near(&"Music", 0.45) and _bus_volume_near(&"SFX", 0.55), "Music/SFX volumes did not preview in Company Command")
	_check(not bool(root.get_node("Music").call("is_enabled")), "music-off did not preview in Company Command")
	_check(bool(root.get_node("ContentPacks").call("background_downloads_enabled")), "background-download policy should wait for Apply")
	_check(game.get("content") == staging, "Settings preview routed away from Company Command")
	staging.call("_cancel_settings")
	await _wait_for_transition(state, &"CLOSED")
	_check(StringName(staging.call("settings_screen_state")) == &"COMMAND", "Cancel did not restore Company Command")
	_check(settings_button.has_focus(), "Cancel did not restore exact Settings focus")
	_check(StringName(root.get_node("I18n").call("locale")) == &"en-US" and Engine.max_fps == 0, "Cancel did not restore locale/frame limit")
	_check(not bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)), "Cancel did not restore reduced motion")
	_check(_near(float(root.get_node("TextScale").call("value")), 1.0), "Cancel did not restore text scale")
	_check(_bus_near(&"Master", 1.0), "Cancel did not restore Master volume")
	_check(_bus_near(&"Music", 1.0) and _bus_near(&"SFX", 1.0), "Cancel did not restore Music/SFX volumes")
	_check(bool(root.get_node("Music").call("is_enabled")), "Cancel did not restore music enablement")
	_check(StringName(root.get_node("Music").call("current_state_id")) == &"staging", "Cancel did not resume the Company Command music state")
	_check(bool(root.get_node("ContentPacks").call("background_downloads_enabled")), "Cancel changed the background-download policy")
	_check(PREFS.locale(PATH) == &"en-US" and PREFS.frame_limit(PATH) == 0, "Cancel persisted draft values")
	_check(PREFS.has_seen_command_tutorial(PATH), "Cancel changed unrelated tutorial completion")


func _verify_apply(staging: Control, game: Node) -> void:
	var settings_button := staging.find_child("CommandSettingsButton", true, false) as Button
	settings_button.pressed.emit()
	var state := staging.get_node("TitleSettings") as Control
	await _wait_for_transition(state, &"ACTIVE")
	_edit_draft(staging)
	await process_frame
	(staging.find_child("SettingsApplyButton", true, false) as Button).pressed.emit()
	await _wait_for_transition(state, &"CLOSED")
	_check(StringName(staging.call("settings_screen_state")) == &"COMMAND", "Apply did not restore Company Command")
	_check(settings_button.has_focus(), "Apply did not restore exact Settings focus")
	_check(PREFS.locale(PATH) == &"zh-CN", "Company Command locale was not persisted")
	_check(PREFS.frame_limit(PATH) == 60 and PREFS.reduced_motion(PATH), "Company Command graphics settings were not persisted")
	_check(_near(PREFS.master_volume(PATH), 0.35), "Company Command Master volume was not persisted")
	_check(PREFS.master_muted(PATH), "Company Command Master mute was not persisted")
	_check(_near(PREFS.music_volume(PATH), 0.45) and _near(PREFS.sfx_volume(PATH), 0.55), "Company Command Music/SFX volumes were not persisted")
	_check(not PREFS.title_music_enabled(PATH), "Company Command music enablement was not persisted")
	_check(not PREFS.background_downloads_enabled(PATH), "Company Command background-download policy was not persisted")
	_check(not bool(root.get_node("ContentPacks").call("background_downloads_enabled")), "Apply did not update the background-download policy")
	_check(_near(PREFS.text_scale(PATH), 1.35), "Company Command text scale was not persisted")
	_check(PREFS.has_seen_command_tutorial(PATH), "Settings batch removed tutorial completion")
	_check(game.get("content") == staging, "Apply routed away from Company Command")


func _edit_draft(staging: Control) -> void:
	(staging.find_child("MasterVolumeSlider", true, false) as HSlider).value = 35.0
	(staging.find_child("MasterMuteButton", true, false) as Button).pressed.emit()
	(staging.find_child("MusicVolumeSlider", true, false) as HSlider).value = 45.0
	(staging.find_child("SfxVolumeSlider", true, false) as HSlider).value = 55.0
	(staging.find_child("MusicButton", true, false) as Button).pressed.emit()
	var frame := staging.find_child("FrameLimitOption", true, false) as OptionButton
	frame.select(2)
	frame.item_selected.emit(2)
	(staging.find_child("LocaleSelector", true, false) as Node).call("select_locale", &"zh-CN")
	(staging.find_child("MotionButton", true, false) as Button).pressed.emit()
	(staging.find_child("BackgroundDownloadsButton", true, false) as Button).pressed.emit()
	(staging.find_child("TextScaleSlider", true, false) as HSlider).value = 135.0


func _verify_restored_runtime(staging: Control) -> void:
	_check(StringName(root.get_node("I18n").call("locale")) == &"zh-CN", "recreated Company Command did not restore locale")
	_check(Engine.max_fps == 60, "recreated Company Command did not restore frame limit")
	_check(bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)), "recreated Company Command did not restore reduced motion")
	_check(_near(float(root.get_node("TextScale").call("value")), 1.35), "recreated Company Command did not restore text scale")
	_check(not bool(root.get_node("Music").call("is_enabled")), "recreated Company Command did not restore music enablement")
	_check(not bool(root.get_node("ContentPacks").call("background_downloads_enabled")), "recreated Company Command did not restore background-download policy")
	_check(_bus_volume_near(&"Master", 0.35) and _bus_muted(&"Master"), "recreated Company Command did not restore Master volume/mute")
	_check(_bus_volume_near(&"Music", 0.45) and _bus_volume_near(&"SFX", 0.55), "recreated Company Command did not restore Music/SFX volumes")
	_check(staging.find_child("CommandSettingsButton", true, false) != null, "recreated Company Command lost Settings")


func _wait_for_transition(state: Control, expected: StringName) -> bool:
	var elapsed := 0.0
	while StringName(state.call("transition_state_name")) != expected and elapsed < WAIT_TIMEOUT:
		await create_timer(0.01).timeout
		elapsed += 0.01
	var matched := StringName(state.call("transition_state_name")) == expected
	_check(matched, "transition timed out waiting for %s" % expected)
	return matched


func _prepare_runtime() -> void:
	root.get_node("I18n").call("set_locale", &"en-US")
	Engine.max_fps = 0
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	root.get_node("TextScale").call("set_scale", 1.0)
	root.get_node("Music").call("set_enabled", true)
	root.get_node("ContentPacks").call("set_background_downloads_enabled", true)
	for bus_name: StringName in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			AudioServer.set_bus_mute(index, false)
			AudioServer.set_bus_volume_db(index, 0.0)


func _capture_runtime() -> void:
	_original_max_fps = Engine.max_fps
	_original_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	_original_text_scale = float(root.get_node("TextScale").call("value"))
	_original_locale = StringName(root.get_node("I18n").call("locale"))
	_original_music_enabled = bool(root.get_node("Music").call("is_enabled"))
	for bus_name: StringName in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			_original_bus_state[bus_name] = {
				&"volume_db": AudioServer.get_bus_volume_db(index),
				&"muted": AudioServer.is_bus_mute(index),
			}


func _restore_runtime() -> void:
	root.get_node("I18n").call("set_locale", _original_locale)
	Engine.max_fps = _original_max_fps
	ProjectSettings.set_setting("accessibility/reduced_motion", _original_reduced_motion)
	root.get_node("TextScale").call("set_scale", _original_text_scale)
	root.get_node("Music").call("set_enabled", _original_music_enabled)
	for bus_name: StringName in _original_bus_state:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var state: Dictionary = _original_bus_state[bus_name]
			AudioServer.set_bus_volume_db(index, float(state[&"volume_db"]))
			AudioServer.set_bus_mute(index, bool(state[&"muted"]))


func _release(staging: Control, game: Node) -> void:
	if game.get("content") == staging:
		game.set("content", null)
	staging.queue_free()
	root.get_node("Music").call("stop")
	root.get_node("Sfx").call("stop_all")
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _bus_near(bus_name: StringName, expected: float) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return expected <= 0.001
	return _near(db_to_linear(AudioServer.get_bus_volume_db(index)), expected)


func _bus_volume_near(bus_name: StringName, expected: float) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	return index >= 0 and _near(db_to_linear(AudioServer.get_bus_volume_db(index)), expected)


func _bus_muted(bus_name: StringName) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	return index >= 0 and AudioServer.is_bus_mute(index)


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= EPSILON


func _remove_preferences() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("STAGING_SETTINGS_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
