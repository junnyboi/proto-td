extends SceneTree

const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")
const PREFERENCES_PATH := "user://title_music_preference_test.cfg"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	var music := root.get_node_or_null("Music")
	var game := root.get_node_or_null("Game")
	_check(music != null, "Music autoload is available")
	_check(game != null, "Game autoload is available")
	_check(
		bool(VIEW_PREFERENCES.title_music_enabled(PREFERENCES_PATH)),
		"missing preference defaults title music to enabled",
	)
	_check(
		bool(VIEW_PREFERENCES.mark_pan_hint_seen(PREFERENCES_PATH)),
		"unrelated navigation preference is created",
	)
	if music != null and game != null:
		await _exercise_sessions(music, game)
		await _clean_up(music, game)
	_remove_preferences()
	call_deferred("_finish")


func _exercise_sessions(music: Node, game: Node) -> void:
	var first: Node = await _create_title()
	_check(bool(first.call("title_music_enabled")), "first session starts enabled")
	_check(music.call("current_id") == &"title_lunaris", "first session starts the title cue")
	first.call("_toggle_music")
	await process_frame
	_check(not bool(first.call("title_music_enabled")), "toggle disables title music")
	_check(not bool(VIEW_PREFERENCES.title_music_enabled(PREFERENCES_PATH)), "disabled state is saved")
	_check(
		bool(VIEW_PREFERENCES.has_seen_pan_hint(PREFERENCES_PATH)),
		"saving music preserves unrelated preferences",
	)
	_check(StringName(music.call("current_id")).is_empty(), "disabled toggle stops the title cue")
	await _release_title(first, game)

	var second: Node = await _create_title()
	_check(not bool(second.call("title_music_enabled")), "second session restores disabled state")
	_check(StringName(music.call("current_id")).is_empty(), "restored disabled state stays silent")
	var music_button := second.find_child("MusicButton", true, false) as Button
	_check(music_button != null and music_button.text.contains("OFF"), "settings copy restores OFF")
	second.call("_toggle_music")
	await process_frame
	_check(bool(VIEW_PREFERENCES.title_music_enabled(PREFERENCES_PATH)), "enabled state is saved")
	_check(music.call("current_id") == &"title_lunaris", "re-enabling starts the title cue")
	await _release_title(second, game)

	var third: Node = await _create_title()
	_check(bool(third.call("title_music_enabled")), "third session restores enabled state")
	_check(music.call("current_id") == &"title_lunaris", "restored enabled state starts the title cue")
	await _release_title(third, game)


func _create_title() -> Node:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	title.call("set_preferences_path", PREFERENCES_PATH)
	root.add_child(title)
	await process_frame
	await process_frame
	return title


func _release_title(title: Node, game: Node) -> void:
	if game.get("content") == title:
		game.set("content", null)
	title.queue_free()
	for _frame: int in range(4):
		await process_frame


func _clean_up(music: Node, game: Node) -> void:
	game.set("content", null)
	music.call("stop")
	for _frame: int in range(4):
		await process_frame


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))


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
