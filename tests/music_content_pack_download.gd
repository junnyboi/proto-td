extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_user_args()
	var url := String(args.get("url", ""))
	var expected_sha256 := String(args.get("sha256", ""))
	var expected_bytes := int(args.get("bytes", "0"))
	_check(not url.is_empty(), "download URL missing")
	_check(expected_sha256.length() == 64, "download SHA-256 missing")
	_check(expected_bytes > 0, "download byte count missing")
	var music := root.get_node_or_null("Music")
	_check(music != null, "Music autoload missing")
	if not _failures.is_empty() or music == null:
		_finish()
		return

	var stream_path := "res://assets/music/act_1_guild_threshold_bgm.ogg"
	_check(not ResourceLoader.exists(stream_path), "base PCK still contains Act I music")
	var cache_root := "user://music-packs"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(cache_root)):
		var directory := DirAccess.open(cache_root)
		if directory != null:
			for file_name: String in directory.get_files():
				directory.remove(file_name)
	music.call("configure_content_packs", {
		1: {"url": url, "sha256": expected_sha256, "bytes": expected_bytes},
	})
	_check(not bool(music.call("play_cue", &"act_1_bgm")), "downloaded cue played before transfer")
	var deadline := Time.get_ticks_msec() + 30_000
	while Time.get_ticks_msec() < deadline:
		var state := music.call("pack_state", 1) as StringName
		if state in [&"ready", &"failed"]:
			break
		await create_timer(0.05).timeout
	_check(music.call("pack_state", 1) == &"ready", "downloaded pack did not reach ready state")
	_check(ResourceLoader.exists(stream_path), "downloaded pack did not expose Act I music")
	for _frame in range(4):
		await process_frame
	_check(music.call("current_id") == &"act_1_bgm", "deferred cue did not start after download")
	_check(
		String(music.call("current_stream_path")) == stream_path,
		"downloaded cue resolved the wrong stream",
	)
	music.call("stop")
	for _frame: int in range(8):
		await process_frame
	await create_timer(0.25).timeout
	_finish()


func _parse_user_args() -> Dictionary:
	var parsed: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		parsed[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return parsed


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MUSIC_CONTENT_PACK_DOWNLOAD_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
