extends SceneTree

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const ULTRAWIDE := Vector2i(2560, 1080)
const SHORT_LANDSCAPE := Vector2i(1024, 576)
const EPSILON := 0.05
const PREFERENCES_PATH := "user://title_ui_scale_test.cfg"

var _failures: Array[String] = []
var _title: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	root.size = LANDSCAPE
	_title = load("res://scenes/title.tscn").instantiate() as Control
	_title.call("set_preferences_path", PREFERENCES_PATH)
	root.add_child(_title)
	await process_frame
	await process_frame
	_verify_landscape()

	root.size = PORTRAIT
	await process_frame
	await process_frame
	_verify_portrait()
	await _verify_settings_typography()
	_title.call("_close_settings")
	await process_frame

	root.size = ULTRAWIDE
	await process_frame
	await process_frame
	await _verify_responsive_settings(ULTRAWIDE, "ultrawide", false)

	root.size = SHORT_LANDSCAPE
	await process_frame
	await process_frame
	await _verify_responsive_settings(SHORT_LANDSCAPE, "short landscape", true)
	await _cleanup()
	_remove_preferences()
	call_deferred("_finish")


func _verify_landscape() -> void:
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var settings := _title.find_child("SettingsButton", true, false) as Button
	var entry := _title.find_child("EntryControls", true, false) as Control
	_check(wordmark != null and wordmark.get_theme_font_size(&"font_size") == 76, "landscape wordmark is not scaled by 15%")
	_check(start != null and start.get_theme_font_size(&"font_size") == 28, "Start font is not scaled by 15%")
	_check(settings != null and settings.get_theme_font_size(&"font_size") == 23, "Settings font is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.x, 598.0), "Start width is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.y, 78.2), "Start height is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.x, 494.5), "Settings width is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.y, 66.7), "Settings height is not scaled by 15%")
	_check(_inside_viewport(entry, LANDSCAPE), "scaled landscape title controls leave the viewport")


func _verify_portrait() -> void:
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var settings := _title.find_child("SettingsButton", true, false) as Button
	var entry := _title.find_child("EntryControls", true, false) as Control
	_check(wordmark != null and wordmark.get_theme_font_size(&"font_size") == 53, "portrait wordmark is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.x, 598.0), "portrait Start width is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.y, 69.0), "portrait Start height is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.x, 490.36), "portrait Settings width is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.y, 62.1), "portrait Settings height is not scaled by 15%")
	_check(_inside_viewport(entry, PORTRAIT), "scaled portrait title controls leave the viewport")


func _verify_settings_typography() -> void:
	_title.call("_open_settings")
	await process_frame
	var heading := _title.find_child("SettingsTitle", true, false) as Label
	var locale_label := _title.find_child("LocaleLabel", true, false) as Label
	var locale_list := _title.find_child("LocaleList", true, false) as ItemList
	var music := _title.find_child("MusicButton", true, false) as Button
	var motion := _title.find_child("MotionButton", true, false) as Button
	var back := _title.find_child("SettingsBackButton", true, false) as Button
	_check(heading != null and heading.get_theme_font_size(&"font_size") == 35, "portrait Settings heading is not scaled by 15%")
	_check(locale_label != null and locale_label.get_theme_font_size(&"font_size") == 20, "Language label is not scaled by 15%")
	_check(locale_list != null and locale_list.get_theme_font_size(&"font_size") == 23, "language options are not scaled by 15%")
	for button: Button in [music, motion, back]:
		_check(button != null and button.get_theme_font_size(&"font_size") == 20, "settings action font is not scaled by 15%")
		_check(button != null and _near(button.custom_minimum_size.y, 62.1), "settings action height is not scaled by 15%")
	var audio_heading := _title.find_child("AudioHeading", true, false) as Label
	var graphics_heading := _title.find_child("GraphicsHeading", true, false) as Label
	var frame_option := _title.find_child("FrameLimitOption", true, false) as OptionButton
	_check(audio_heading != null and audio_heading.get_theme_font_size(&"font_size") == 21, "Audio heading is not scaled by 15%")
	_check(graphics_heading != null and graphics_heading.get_theme_font_size(&"font_size") == 21, "Graphics heading is not scaled by 15%")
	_check(frame_option != null and frame_option.item_count == 4, "frame-limit choices are missing")


func _verify_responsive_settings(viewport_size: Vector2i, label: String, expect_scroll: bool) -> void:
	var entry := _title.find_child("EntryControls", true, false) as Control
	_check(_inside_viewport(entry, viewport_size), "%s title controls leave the viewport" % label)
	_title.call("_open_settings")
	await process_frame
	var panel := _title.find_child("SettingsPanel", true, false) as Control
	var scroll := _title.find_child("SettingsScroll", true, false) as ScrollContainer
	var stack := _title.find_child("SettingsStack", true, false) as VBoxContainer
	_check(_inside_viewport(panel, viewport_size), "%s settings panel leaves the viewport" % label)
	_check(scroll != null and scroll.size.x > 0.0 and scroll.size.y > 0.0, "%s settings scroll host is invalid" % label)
	if expect_scroll and scroll != null and stack != null:
		_check(stack.size.y > scroll.size.y, "%s modal does not expose scroll overflow" % label)
	_title.call("_close_settings")
	await process_frame


func _inside_viewport(control: Control, viewport_size: Vector2i) -> bool:
	if control == null:
		return false
	var rect := control.get_rect()
	return (
		rect.position.x >= -EPSILON
		and rect.position.y >= -EPSILON
		and rect.end.x <= float(viewport_size.x) + EPSILON
		and rect.end.y <= float(viewport_size.y) + EPSILON
	)


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= EPSILON


func _cleanup() -> void:
	var game := root.get_node_or_null("Game")
	if game != null and game.get("content") == _title:
		game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	if _title != null:
		_title.queue_free()
	_title = null
	for _frame: int in range(12):
		await process_frame
	# Opening Settings plays a short confirmation sample. Let the audio server
	# retire that one-shot playback before the standalone SceneTree runs its
	# ObjectDB and resource-lifetime checks.
	await create_timer(0.5).timeout


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_UI_SCALE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
