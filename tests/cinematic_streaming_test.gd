extends SceneTree

const PlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stream_argument := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(PlayerType.STREAM_ARG_PREFIX):
			stream_argument = argument
			break
	if stream_argument.is_empty():
		await _run_source_contract()
	else:
		await _run_remote_contract(stream_argument)
	_finish()


func _run_source_contract() -> void:
	var player := PlayerType.new()
	root.add_child(player)
	await process_frame
	await process_frame
	player.configure_streams(PackedStringArray([
		"--cinematic-stream=unknown|https://example.invalid/unknown.ogv",
		"--cinematic-stream=lunaris-vessel-landscape|ftp://example.invalid/video.ogv",
		"--cinematic-stream=lunaris-vessel-landscape|https://example.invalid/video.ogv",
	]))
	_check(player.configured_stream_count() == 1, "stream argument validation accepted invalid entries")
	_check(
		player.stream_url("lunaris-vessel-landscape") == "https://example.invalid/video.ogv",
		"valid stream URL did not register",
	)
	player.configure_streams(PackedStringArray())
	var reduced_started := player.play_cinematic("lunaris_vessel", true)
	_check(not reduced_started, "reduced motion started cinematic video")
	_check(player.final_plate() != null and player.final_plate().visible, "reduced motion did not preserve final plate")
	var finished_count := [0]
	player.cinematic_finished.connect(func() -> void: finished_count[0] += 1)
	var native_started := player.play_cinematic("lunaris_vessel", false)
	_check(native_started, "native bundled cinematic fallback did not start")
	_check(player.video_player().stream != null, "native fallback did not assign a video stream")
	_check(player.video_player().is_playing(), "native fallback did not enter playback")
	_check(player.video_player().loop, "native cinematic is not configured to loop")
	_check(not player.final_plate().visible, "final plate covered active cinematic playback")
	player.video_player().finished.emit()
	_check(finished_count[0] == 1, "first completed cycle did not emit cinematic_finished")
	_check(player.video_player().is_playing(), "first completed cycle stopped loop playback")
	_check(player.video_player().visible, "first completed cycle hid the looping video")
	_check(not player.final_plate().visible, "first completed cycle froze onto the final plate")
	player.video_player().finished.emit()
	_check(finished_count[0] == 1, "cinematic_finished emitted more than once")
	player.stop()
	_check(player.video_player().stream == null, "stop did not release native video stream")
	root.remove_child(player)
	player.free()
	await process_frame


func _run_remote_contract(stream_argument: String) -> void:
	var payload := stream_argument.substr(PlayerType.STREAM_ARG_PREFIX.length())
	var separator := payload.find("|")
	_check(separator > 0, "remote test stream argument is malformed")
	if separator <= 0:
		return
	var stream_key := payload.substr(0, separator)
	var profile_id := _profile_for_stream(stream_key)
	_check(not profile_id.is_empty(), "remote test stream has no premium profile")
	if profile_id.is_empty():
		return
	root.size = Vector2i(1280, 720)
	_remove_cached_stream(stream_key)
	var player := PlayerType.new()
	root.add_child(player)
	await process_frame
	await process_frame
	player.configure_streams(PackedStringArray([stream_argument]))
	_check(player.configured_stream_count() == 1, "remote stream configuration was not loaded")
	_check(player.stream_url(stream_key).begins_with("http"), "remote stream URL is missing")
	var started := [false]
	var failed := [""]
	player.cinematic_started.connect(func(_music_id: StringName) -> void: started[0] = true)
	player.cinematic_failed.connect(func(_key: StringName, reason: String) -> void: failed[0] = reason)
	var immediate := player.play_cinematic(profile_id, false)
	_check(not immediate, "cold remote stream started before download")
	_check(player.download_key() == stream_key, "cold remote stream did not begin downloading")
	var deadline := Time.get_ticks_msec() + 45000
	while not started[0] and failed[0].is_empty() and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	_check(failed[0].is_empty(), "remote stream failed: %s" % failed[0])
	_check(started[0], "remote stream did not start before timeout")
	var cached_path := player.cached_stream_path(stream_key)
	_check(not cached_path.is_empty(), "verified remote stream was not cached")
	_check(player.video_player().stream is VideoStreamTheora, "cached file did not create VideoStreamTheora")
	_check(player.video_player().is_playing(), "cached Theora stream is not playing")
	var spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
	_check(FileAccess.get_sha256(cached_path) == String(spec.get("sha256", "")), "cached stream SHA-256 mismatch")
	player.stop()
	root.remove_child(player)
	player.free()
	await process_frame


func _profile_for_stream(stream_key: String) -> String:
	for premium_id: String in PlayerType.PROFILES:
		var profile: Dictionary = PlayerType.PROFILES[premium_id]
		if String(profile.get("landscape_stream", "")) == stream_key:
			return premium_id
		if String(profile.get("portrait_stream", "")) == stream_key:
			return premium_id
	return ""


func _remove_cached_stream(stream_key: String) -> void:
	var spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
	if spec.is_empty():
		return
	var digest := String(spec.get("sha256", ""))
	var path := "%s/%s-%s.ogv" % [PlayerType.CACHE_DIR, stream_key, digest.left(16)]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CINEMATIC_STREAMING_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
