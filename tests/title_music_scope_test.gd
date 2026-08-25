extends SceneTree

const PREFERENCES_PATH := "user://title_music_scope_test.cfg"
const REMOVED_CUES := [
	&"act_1_bgm",
	&"act_1_boss",
	&"act_2_bgm",
	&"act_2_boss",
	&"act_3_bgm",
	&"act_3_boss",
]
const REMOVED_STREAMS := [
	"res://assets/music/act_1_guild_threshold_bgm.ogg",
	"res://assets/music/act_1_guild_threshold_boss.ogg",
	"res://assets/music/act_2_twilight_grotto_bgm.ogg",
	"res://assets/music/act_2_twilight_grotto_boss.ogg",
	"res://assets/music/act_3_abyssal_vault_bgm.ogg",
	"res://assets/music/act_3_abyssal_vault_boss.ogg",
]

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
		await _exercise_scope(music, game)
		await _clean_up(music, game)
	_remove_preferences()
	call_deferred("_finish")


func _exercise_scope(music: Node, game: Node) -> void:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	title.call("set_preferences_path", PREFERENCES_PATH)
	root.add_child(title)
	await process_frame
	await process_frame

	_check(music.call("current_id") == &"title_lunaris", "approved title cue starts on player entry")
	var player := music.get_node_or_null("Player") as AudioStreamPlayer
	_check(player != null and player.playing, "approved title cue is actively playing")
	var stops_before := int(music.call("stop_count"))
	for cue_id: StringName in REMOVED_CUES:
		_check(not bool(music.call("play_cue", cue_id)), "removed cue remains playable: %s" % cue_id)
	for stream_path: String in REMOVED_STREAMS:
		_check(not ResourceLoader.exists(stream_path), "removed stream still exists: %s" % stream_path)

	title.call("_on_start_pressed")
	for _frame: int in range(8):
		await process_frame

	var content := game.get("content") as Node
	_check(content != null, "campaign home is installed")
	_check(
		content != null and content.get_script().resource_path == "res://scripts/ui/staging.gd",
		"Start transitions to staging",
	)
	_check(
		music.call("current_id") == &"lunaris_staging_archive_command",
		"approved Company Command cue starts after title",
	)
	_check(player != null and not player.playing, "title playback stops before staging")
	_check(player != null and player.stream == null, "staging retains no title stream")
	_check(
		music.call("current_stream_path")
		== "res://assets/music/lunaris/lunaris_staging_archive_command.ogg",
		"staging resolves the faction-authored command loop",
	)
	_check(int(music.call("stop_count")) == stops_before + 1, "title cue stops exactly once")


func _clean_up(music: Node, game: Node) -> void:
	var content := game.get("content") as Node
	game.set("content", null)
	if content != null and is_instance_valid(content):
		content.queue_free()
	music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(16):
		await process_frame


func _remove_preferences() -> void:
	if FileAccess.file_exists(PREFERENCES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFERENCES_PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_MUSIC_SCOPE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
