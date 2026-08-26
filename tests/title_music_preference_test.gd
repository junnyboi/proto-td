extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const PATH := "user://title_music_preference_test.cfg"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove()
	var music := root.get_node_or_null("Music")
	var game := root.get_node_or_null("Game")
	_check(music != null and game != null, "required autoloads are available")
	_check(PREFS.title_music_enabled(PATH), "missing preference does not default enabled")
	_check(PREFS.mark_pan_hint_seen(PATH), "unrelated preference was not created")
	if music != null and game != null:
		await _exercise(music, game)
		await _cleanup(music, game)
	_remove()
	call_deferred("_finish")


func _exercise(music: Node, game: Node) -> void:
	var first := await _create_title()
	_check(bool(first.call("title_music_enabled")), "first session starts enabled")
	_check(music.call("current_id") == &"title_lunaris", "first session starts title cue")
	first.call("_open_settings")
	await process_frame
	(first.find_child("MusicButton", true, false) as Button).pressed.emit()
	await process_frame
	_check(not bool(first.call("title_music_enabled")), "draft toggle did not preview disabled")
	_check(PREFS.title_music_enabled(PATH), "draft toggle persisted before Apply")
	_check(StringName(music.call("current_id")).is_empty(), "draft disable did not stop title cue")
	first.call("_close_settings")
	await process_frame
	_check(bool(first.call("title_music_enabled")), "Cancel did not restore enabled preference")
	_check(music.call("current_id") == &"title_lunaris", "Cancel did not restore title cue")
	_check(PREFS.title_music_enabled(PATH), "Cancel persisted music preference")

	first.call("_open_settings")
	await process_frame
	(first.find_child("MusicButton", true, false) as Button).pressed.emit()
	await process_frame
	(first.find_child("SettingsApplyButton", true, false) as Button).pressed.emit()
	await process_frame
	_check(not PREFS.title_music_enabled(PATH), "Apply did not persist disabled preference")
	_check(PREFS.has_seen_pan_hint(PATH), "Apply removed unrelated preferences")
	await _release(first, game)

	var second := await _create_title()
	_check(not bool(second.call("title_music_enabled")), "second session did not restore disabled preference")
	_check(StringName(music.call("current_id")).is_empty(), "restored disabled preference did not stay silent")
	second.call("_open_settings")
	await process_frame
	(second.find_child("MusicButton", true, false) as Button).pressed.emit()
	await process_frame
	(second.find_child("SettingsApplyButton", true, false) as Button).pressed.emit()
	await process_frame
	_check(PREFS.title_music_enabled(PATH), "Apply did not persist enabled preference")
	_check(music.call("current_id") == &"title_lunaris", "preview enable did not restore title cue")
	await _release(second, game)

	var third := await _create_title()
	_check(bool(third.call("title_music_enabled")), "third session did not restore enabled preference")
	_check(music.call("current_id") == &"title_lunaris", "restored enabled preference did not start title cue")
	await _release(third, game)


func _create_title() -> Control:
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", PATH)
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


func _cleanup(music: Node, game: Node) -> void:
	game.set("content", null)
	music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(16):
		await process_frame


func _remove() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_MUSIC_PREFERENCE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
