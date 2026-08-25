extends SceneTree

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const EPSILON := 0.05

var _failures: Array[String] = []
var _title: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = LANDSCAPE
	_title = load("res://scenes/title.tscn").instantiate() as Control
	root.add_child(_title)
	await process_frame
	await process_frame
	_verify_landscape()

	root.size = PORTRAIT
	await process_frame
	await process_frame
	_verify_portrait()
	await _verify_settings_typography()
	await _cleanup()
	call_deferred("_finish")


func _verify_landscape() -> void:
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var settings := _title.find_child("SettingsButton", true, false) as Button
	var entry := _title.find_child("EntryControls", true, false) as Control
	var pack_status := _title.find_child("MusicPackStatus", true, false) as Control
	_check(wordmark != null and wordmark.get_theme_font_size(&"font_size") == 76, "landscape wordmark is not scaled by 15%")
	_check(start != null and start.get_theme_font_size(&"font_size") == 28, "Start font is not scaled by 15%")
	_check(settings != null and settings.get_theme_font_size(&"font_size") == 23, "Settings font is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.x, 598.0), "Start width is not scaled by 15%")
	_check(start != null and _near(start.custom_minimum_size.y, 78.2), "Start height is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.x, 494.5), "Settings width is not scaled by 15%")
	_check(settings != null and _near(settings.custom_minimum_size.y, 66.7), "Settings height is not scaled by 15%")
	_check(pack_status != null and _near(pack_status.custom_minimum_size.x, 414.0), "title music status is not scaled by 15%")
	_check(pack_status != null and _near(pack_status.custom_minimum_size.y, 59.8), "title music status height is not scaled by 15%")
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
