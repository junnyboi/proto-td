extends SceneTree

const PREFERENCES_PATH := "user://title_music_continuity_test.cfg"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences()
	var music := root.get_node_or_null("Music")
	var game := root.get_node_or_null("Game")
	_check(music != null, "Music autoload is available")
	_check(game != null, "Game autoload is available")
	if music != null and game != null:
		await _exercise_transition(music, game)
		await _clean_up(music, game)
	_remove_preferences()
	call_deferred("_finish")


func _exercise_transition(music: Node, game: Node) -> void:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	title.call("set_preferences_path", PREFERENCES_PATH)
	root.add_child(title)
	await process_frame
	await process_frame

	_check(music.call("current_id") == &"title_lunaris", "title cue starts on player entry")
	var player := music.get_node_or_null("Player") as AudioStreamPlayer
	_check(player != null and player.playing, "title cue is actively playing")
	var stream_before: AudioStream = player.stream if player != null else null
	var starts_before := int(music.call("start_count"))
	var stops_before := int(music.call("stop_count"))

	title.call("_on_start_pressed")
	for _frame: int in range(8):
		await process_frame

	var content := game.get("content") as Node
	_check(content != null, "campaign home is installed")
	_check(
		content != null and content.get_script().resource_path == "res://scripts/ui/staging.gd",
		"Start transitions to staging",
	)
	_check(music.call("current_id") == &"title_lunaris", "title cue continues in staging")
	_check(player != null and player.playing, "title cue remains actively playing in staging")
	_check(player != null and player.stream == stream_before, "continuity keeps the same stream")
	_check(int(music.call("start_count")) == starts_before, "continuity does not restart the cue")
	_check(int(music.call("stop_count")) == stops_before, "continuity does not stop the cue")
	# Coroutine locals remain alive until the test tree exits. Release the explicit
	# stream reference before cleanup so the resource-leak scan reflects runtime ownership.
	stream_before = null


func _clean_up(music: Node, game: Node) -> void:
	var content := game.get("content") as Node
	game.set("content", null)
	if content != null and is_instance_valid(content):
		content.queue_free()
	music.call("stop")
	for _frame: int in range(8):
		await process_frame


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_MUSIC_CONTINUITY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
