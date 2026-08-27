extends SceneTree

const PlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stream_arguments := PackedStringArray()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(PlayerType.STREAM_ARG_PREFIX):
			stream_arguments.append(argument)
	if stream_arguments.is_empty():
		await _run_source_contract()
	elif stream_arguments.size() == PlayerType.STREAMS.size():
		await _run_title_prefetch_remote_contract(stream_arguments)
	else:
		await _run_remote_contract(stream_arguments[0])
	_finish()


func _run_source_contract() -> void:
	var prefetch := root.get_node_or_null("CinematicPrefetch")
	_check(prefetch != null, "CinematicPrefetch autoload is missing")
	if prefetch != null:
		prefetch.call("reset_for_tests")
		var all_arguments := PackedStringArray()
		for stream_key: String in PlayerType.STREAMS:
			all_arguments.append("%s%s|https://example.invalid/%s.ogv" % [
				PlayerType.STREAM_ARG_PREFIX, stream_key, stream_key,
			])
		prefetch.call("configure_streams", all_arguments)
		_check(int(prefetch.call("configured_stream_count")) == 6, "prefetch did not accept all six configured streams")
		var landscape_order: Array = prefetch.call("preferred_stream_order", Vector2(1280, 720))
		var portrait_order: Array = prefetch.call("preferred_stream_order", Vector2(720, 1280))
		_check(landscape_order.size() == 6 and landscape_order[0].ends_with("landscape"), "landscape prefetch order did not prioritize visible orientation")
		_check(portrait_order.size() == 6 and portrait_order[0].ends_with("portrait"), "portrait prefetch order did not prioritize visible orientation")
		_check(landscape_order.slice(0, 3).all(func(key: String) -> bool: return key.ends_with("landscape")), "landscape streams are not the first prefetch group")
		_check(portrait_order.slice(0, 3).all(func(key: String) -> bool: return key.ends_with("portrait")), "portrait streams are not the first prefetch group")
		prefetch.call("reset_for_tests")
	var player := PlayerType.new()
	root.add_child(player)
	await process_frame
	await process_frame
	var i18n := root.get_node_or_null("I18n")
	var status_label := player.find_child("CinematicStreamLabel", true, false) as Label
	player.call("_update_download_status", 25, 100)
	_check(status_label.text == "RECEIVING CINEMATIC // 25%", "English cinematic progress did not use localized template")
	_check(i18n != null and i18n.call("set_locale", &"zh-CN"), "zh-CN locale could not activate for cinematic")
	await process_frame
	_check(status_label.text == "正在接收影像 // 25%", "cinematic progress did not refresh on locale change")
	player.call("_set_failure_status", "fixture")
	_check(status_label.text == "影像离线 // 已显示最终画面", "cinematic offline status did not localize")
	_check(i18n.call("set_locale", &"en-US"), "en-US locale could not restore for cinematic")
	await process_frame
	_check(status_label.text == "CINEMATIC OFFLINE // FINAL PLATE ACTIVE", "cinematic offline status did not refresh")
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
	var prefetch := root.get_node_or_null("CinematicPrefetch")
	_check(prefetch != null, "remote fixture is missing CinematicPrefetch")
	if prefetch != null:
		prefetch.call("reset_for_tests")
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
	var prefetch_queue: Array = prefetch.call("queued_stream_keys") if prefetch != null else []
	_check(
		prefetch != null and (
			String(prefetch.call("active_stream_key")) == stream_key
			or prefetch_queue.has(stream_key)
		),
		"cold remote stream was not owned by the shared prefetch service",
	)
	_check(player.find_child("CinematicDownload", false, false) == null, "player started a duplicate cinematic request")
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
	if prefetch != null:
		prefetch.call("reset_for_tests")
	await process_frame


func _run_title_prefetch_remote_contract(stream_arguments: PackedStringArray) -> void:
	var prefetch := root.get_node_or_null("CinematicPrefetch")
	_check(prefetch != null, "title prefetch fixture is missing CinematicPrefetch")
	if prefetch == null:
		return
	prefetch.call("reset_for_tests")
	for stream_key: String in PlayerType.STREAMS:
		_remove_cached_stream(stream_key)
	var ready_order: Array[String] = []
	var failures: Array[String] = []
	prefetch.stream_ready.connect(func(stream_key: StringName, _path: String) -> void:
		ready_order.append(String(stream_key))
	)
	prefetch.stream_failed.connect(func(stream_key: StringName, reason: String) -> void:
		failures.append("%s: %s" % [stream_key, reason])
	)
	prefetch.call("prefetch_from_title", Vector2(1280, 720), stream_arguments)
	var initial_queue: Array = prefetch.call("queued_stream_keys")
	_check(initial_queue.size() == 6, "title prefetch did not queue all six streams")
	_check(
		initial_queue.slice(0, 3).all(func(key: String) -> bool: return key.ends_with("landscape")),
		"title prefetch did not queue current orientation first",
	)
	var deadline := Time.get_ticks_msec() + 180000
	while ready_order.size() < 6 and failures.is_empty() and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	_check(failures.is_empty(), "title prefetch failed: %s" % "; ".join(failures))
	_check(ready_order.size() == 6, "title prefetch did not finish all six streams before timeout")
	_check(
		ready_order.slice(0, 3).all(func(key: String) -> bool: return key.ends_with("landscape")),
		"title prefetch completion order did not preserve orientation priority",
	)
	for stream_key: String in PlayerType.STREAMS:
		var cached_path := String(prefetch.call("cached_stream_path", stream_key))
		var spec: Dictionary = PlayerType.STREAMS[stream_key]
		_check(not cached_path.is_empty(), "title prefetch did not cache %s" % stream_key)
		_check(
			FileAccess.get_sha256(cached_path) == String(spec.get("sha256", "")),
			"title prefetch digest mismatch for %s" % stream_key,
		)
	prefetch.call("reset_for_tests")


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
