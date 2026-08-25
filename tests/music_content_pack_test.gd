extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_user_args()
	var pack_path := String(args.get("act1-pack", ""))
	var expected_sha256 := String(args.get("sha256", ""))
	var expected_bytes := int(args.get("bytes", "0"))
	var music := root.get_node_or_null("Music")
	_check(music != null, "Music autoload missing")
	if music == null:
		_finish()
		return
	var response_fixture := PackedByteArray([0, 1, 2, 127, 255])
	var response_path := "user://music-pack-response-fixture.bin"
	if FileAccess.file_exists(response_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(response_path))
	_check(
		bool(music.call("_write_pack_response", response_path, response_fixture)),
		"HTTP response body did not persist for validation",
	)
	_check(
		FileAccess.get_file_as_bytes(response_path) == response_fixture,
		"persisted HTTP response body changed bytes",
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(response_path))
	if pack_path.is_empty():
		_check(
			bool(music.call("play_cue", &"act_1_bgm")),
			"source-tree battle music did not remain playable",
		)
		_check(
			music.call("pack_state", 1) == &"bundled",
			"source-tree battle music did not report bundled state",
		)
		music.call("stop")
		for _frame: int in range(8):
			await process_frame
		await create_timer(0.25).timeout
		_finish()
		return
	_check(expected_sha256.length() == 64, "act 1 pack SHA-256 missing")
	_check(expected_bytes > 0, "act 1 pack byte count missing")
	if not _failures.is_empty():
		_finish()
		return

	var title_path := "res://assets/music/lunaris_astra_memoriam_title.ogg"
	var act_1_bgm_path := "res://assets/music/act_1_guild_threshold_bgm.ogg"
	var act_1_boss_path := "res://assets/music/act_1_guild_threshold_boss.ogg"
	var act_2_bgm_path := "res://assets/music/act_2_twilight_grotto_bgm.ogg"
	_check(ResourceLoader.exists(title_path), "base PCK lost title music")
	_check(not ResourceLoader.exists(act_1_bgm_path), "base PCK still contains act 1 BGM")
	_check(not ResourceLoader.exists(act_1_boss_path), "base PCK still contains act 1 boss music")
	_check(not ResourceLoader.exists(act_2_bgm_path), "base PCK still contains act 2 BGM")
	_check(not bool(music.call("play_cue", &"act_1_bgm")), "missing pack cue played unexpectedly")
	_check(StringName(music.call("current_id")).is_empty(), "missing pack changed current cue")

	var wrong_hash := "0".repeat(64)
	_check(
		not bool(music.call("mount_pack_file", 1, pack_path, wrong_hash, expected_bytes)),
		"pack mounted with an invalid hash",
	)
	var copied_pack_path := "user://music-content-pack-copy-test.pck"
	if FileAccess.file_exists(copied_pack_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(copied_pack_path))
	_check(
		bool(music.call(
			"_copy_verified_pack",
			pack_path,
			copied_pack_path,
			expected_sha256,
			expected_bytes,
		)),
		"verified pack copy fallback failed",
	)
	_check(
		bool(music.call("mount_pack_file", 1, copied_pack_path, expected_sha256, expected_bytes)),
		"copied act 1 pack failed to mount",
	)
	_check(ResourceLoader.exists(act_1_bgm_path), "mounted pack did not expose act 1 BGM")
	_check(ResourceLoader.exists(act_1_boss_path), "mounted pack did not expose act 1 boss music")
	_check(not ResourceLoader.exists(act_2_bgm_path), "act 1 pack leaked act 2 music")
	_check(bool(music.call("play_cue", &"act_1_bgm")), "mounted act 1 BGM did not play")
	_check(music.call("current_id") == &"act_1_bgm", "mounted cue did not become current")
	_check(
		String(music.call("current_stream_path")) == act_1_bgm_path,
		"mounted cue resolved the wrong stream",
	)
	music.call("stop")
	if FileAccess.file_exists(copied_pack_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(copied_pack_path))
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
		print("MUSIC_CONTENT_PACK_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
