extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const PATH := "user://title_language_toggle_test.cfg"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	_check(PREFS.set_title_music_enabled(false, PATH), "music fixture could not be saved")
	_check(PREFS.set_reduced_motion(true, PATH), "motion fixture could not be saved")
	root.size = Vector2i(1280, 720)
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", PATH)
	root.add_child(title)
	for _frame: int in range(4):
		await process_frame

	var i18n := root.get_node_or_null("I18n")
	var start := title.find_child("StartButton", true, false) as Button
	var language := title.find_child("LanguageToggle", true, false) as Button
	var settings := title.find_child("FooterSettingsButton", true, false) as Button
	var wordmark := title.find_child("Wordmark", true, false) as Label
	_check(i18n != null and language != null, "title language dependencies are missing")
	_check(language != null and language.text == "EN / 中文", "quick language label changed")
	_check(language != null and not language.button_pressed, "English did not open as the initial toggle state")
	_check(
		language != null and language.accessibility_name.contains("Simplified Chinese"),
		"English quick toggle does not announce its Chinese destination",
	)
	_check(
		start != null and language != null
		and start.get_node_or_null(start.focus_neighbor_bottom) == language,
		"keyboard navigation does not move from Start to the language toggle",
	)
	_check(
		language != null and settings != null
		and language.get_node_or_null(language.focus_neighbor_bottom) == settings,
		"keyboard navigation does not move from the language toggle to Settings",
	)

	title.call("_on_language_toggled", true)
	await process_frame
	_check(i18n != null and i18n.call("locale") == &"zh-CN", "quick toggle did not activate Chinese")
	_check(PREFS.locale(PATH) == &"zh-CN", "quick toggle did not persist Chinese")
	_check(language != null and language.button_pressed, "Chinese did not update the selected toggle state")
	_check(wordmark != null and wordmark.text == "PROTOS 防线", "Chinese title copy did not refresh immediately")
	_check(
		language != null and language.accessibility_name.contains("英语"),
		"Chinese quick toggle does not announce its English destination",
	)

	title.call("_on_language_toggled", false)
	await process_frame
	_check(i18n != null and i18n.call("locale") == &"en-US", "quick toggle did not restore English")
	_check(PREFS.locale(PATH) == &"en-US", "quick toggle did not persist English")

	title.call("_on_language_toggled", true)
	await process_frame
	title.call("_open_settings")
	for _frame: int in range(3):
		await process_frame
	var draft := title.call("settings_draft") as Dictionary
	_check(
		StringName(draft.get(&"locale", &"")) == &"zh-CN",
		"Settings did not inherit the quick-toggle locale",
	)
	_check(language != null and language.disabled, "hidden language toggle remained interactive in Settings")

	await _cleanup(title, i18n)
	_remove_preferences()
	_finish()


func _cleanup(title: Control, i18n: Node) -> void:
	if i18n != null:
		i18n.call("set_locale", &"en-US")
	var game := root.get_node_or_null("Game")
	if game != null and game.get("content") == title:
		game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	title.queue_free()
	for _frame: int in range(16):
		await process_frame
	await create_timer(0.5).timeout


func _remove_preferences() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_LANGUAGE_TOGGLE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
