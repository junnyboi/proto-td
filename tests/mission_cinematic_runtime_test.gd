extends SceneTree

const CatalogType := preload("res://data/presentation/cinematics/mission_cinematic_catalog.gd")
const PlayerType := preload("res://scripts/ui/components/mission_cinematic_player.gd")
const PrefetchType := preload("res://autoloads/mission_cinematic_prefetch.gd")
const TEST_FILE := "user://mission_cinematic_verify_fixture.bin"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_catalog_and_prefetch()
	await _verify_player_contract()
	_finish()


func _verify_catalog_and_prefetch() -> void:
	var records := CatalogType.all()
	_check(records.size() == 16, "mission cinematic catalog does not contain exactly sixteen records")
	for index: int in range(16):
		var expected := StringName("s%d" % (index + 1))
		var record: MissionCinematicRecord = records[index]
		_check(record.stage_id == expected and record.is_valid(), "%s typed catalog record is invalid" % expected)
		_check(record.poster_path == "res://assets/cinematics/missions/posters/%s.webp" % expected, "%s poster path drifted" % expected)
		_check(record.video.path.ends_with("/%s.ogv" % expected), "%s final OGV path drifted" % expected)
		_check(record.ambience.path.ends_with("/%s.ogg" % expected), "%s final OGG path drifted" % expected)
		_check(record.video.duration_seconds <= 8.0, "%s catalog duration exceeds eight seconds" % expected)
		_check(record.video.bytes > 0 and record.video.sha256.length() == 64, "%s final OGV metadata is not pinned" % expected)
		_check(record.ambience.bytes > 0 and record.ambience.sha256.length() == 64, "%s final OGG metadata is not pinned" % expected)
		_check(PrefetchType.verify_file(record.video.path, record.video.bytes, record.video.sha256), "%s bundled OGV failed pinned metadata verification" % expected)
		_check(PrefetchType.verify_file(record.ambience.path, record.ambience.bytes, record.ambience.sha256), "%s bundled OGG failed pinned metadata verification" % expected)
	var parsed := PrefetchType.parse_stream_urls(PackedStringArray([
		"--mission-cinematic-stream=s1|https://example.invalid/s1.ogv",
		"--mission-cinematic-stream=s17|https://example.invalid/s17.ogv",
		"--mission-cinematic-stream=s2|ftp://example.invalid/s2.ogv",
		"--mission-cinematic-stream=s3|http://example.invalid/s3.ogv",
		"--mission-cinematic-stream=broken",
	]))
	_check(parsed.size() == 2 and parsed.has(&"s1") and parsed.has(&"s3"), "mission stream argument parsing accepted invalid mappings")
	var file := FileAccess.open(TEST_FILE, FileAccess.WRITE)
	file.store_string("mission-cinematic-verification")
	file.close()
	var bytes := FileAccess.get_file_as_bytes(TEST_FILE).size()
	var digest := FileAccess.get_sha256(TEST_FILE)
	_check(PrefetchType.verify_file(TEST_FILE, bytes, digest), "exact mission stream metadata verification failed")
	_check(not PrefetchType.verify_file(TEST_FILE, bytes + 1, digest), "mission stream byte mismatch was accepted")
	_check(not PrefetchType.verify_file(TEST_FILE, bytes, "0".repeat(64)), "mission stream SHA-256 mismatch was accepted")
	_check(PrefetchType.verify_file(TEST_FILE, 0, ""), "zero/empty conversion placeholders did not allow existence-only verification")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_FILE))
	var service := root.get_node_or_null("MissionCinematicPrefetch")
	_check(service != null, "MissionCinematicPrefetch autoload is missing")
	if service != null:
		service.call("reset_for_tests")
		service.call("configure_streams", PackedStringArray([
			"--mission-cinematic-stream=s2|https://example.invalid/s2.ogv",
			"--mission-cinematic-stream=s1|https://example.invalid/s1.ogv",
		]))
		_check(int(service.call("configured_stream_count")) == 2, "mission prefetch did not retain two valid mappings")
		service.call("set_background_download_policy", true, 1)
		service.call("prefetch_from_title", PackedStringArray())
		_check(int(service.call("title_entry_count")) == 1, "mission title startup telemetry did not increment")
		_check(service.call("queued_stage_ids").size() <= 1, "slow-network policy queued more than one mission prologue")
		service.call("set_background_download_policy", false, 0)
		_check(service.call("queued_stage_ids").is_empty(), "metered preference did not clear mission background work")
		_check(not bool(service.call("background_downloads_enabled")), "mission prefetch did not retain the disabled policy")
		var selected_ready := bool(service.call("request_stage", &"s2", true))
		var queue: Array = service.call("queued_stage_ids")
		var selected_local := String(service.call("cached_stage_path", &"s2")).ends_with("/s2.ogv")
		_check(
			(selected_ready and selected_local)
			or queue.is_empty()
			or queue[0] == &"s2"
			or service.call("active_stage_id") == &"s2",
			"selected stage was neither immediately ready nor prioritized in the bounded queue",
		)
		_check(service.find_children("MissionCinematicDownload", "HTTPRequest", false, false).size() <= 1, "mission prefetch owns more than one download")
		service.call("reset_for_tests")


func _verify_player_contract() -> void:
	var i18n := root.get_node_or_null("I18n")
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	var player := PlayerType.new()
	root.add_child(player)
	await process_frame
	var terminals: Array[StringName] = []
	player.terminal.connect(func(_stage_id: StringName, reason: StringName) -> void: terminals.append(reason))
	player.present(&"s1")
	await process_frame
	await process_frame
	var action := player.action_button()
	_check(action != null and action.custom_minimum_size.x >= 160.0 and action.custom_minimum_size.y >= 64.0, "Skip/Continue action is below 160x64")
	_check(action != null and action.has_focus(), "mission cinematic action did not receive initial focus")
	_check(action != null and action.text == "Continue", "Reduced Motion did not expose Continue")
	_check(player.poster() != null and player.poster().visible and player.video_player() != null and not player.video_player().is_playing(), "Reduced Motion did not preserve poster-only fallback")
	_check(terminals.size() == 1 and terminals[0] == &"reduced_motion", "Reduced Motion did not resolve terminal exactly once")
	player.finish_for_test(&"skip")
	_check(terminals.size() == 1, "mission player terminal emitted more than once")
	_check(i18n != null and i18n.call("set_locale", &"zh-CN"), "mission player could not switch to Chinese")
	await process_frame
	_check(action.text == "继续", "Continue did not localize to Chinese")
	_check(not action.accessibility_name.is_empty() and not player.status_label().text.is_empty(), "mission player accessibility copy is empty")
	if i18n != null:
		i18n.call("set_locale", &"en-US")
	player.queue_free()
	await process_frame
	ProjectSettings.set_setting("accessibility/reduced_motion", false)

	var exit_player := PlayerType.new()
	root.add_child(exit_player)
	await process_frame
	var exit_count := [0]
	exit_player.terminal.connect(func(_stage_id: StringName, _reason: StringName) -> void: exit_count[0] += 1)
	exit_player.queue_free()
	await process_frame
	_check(exit_count[0] == 1, "scene exit did not resolve mission player terminal exactly once")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MISSION_CINEMATIC_RUNTIME_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
