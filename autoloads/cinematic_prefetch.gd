extends Node

## Persistent, presentation-only prefetch for Premium Resonance cinematics.
## Title starts the queue without blocking navigation. GachaCinematicPlayer can
## join or prioritize the same verified transfer instead of downloading twice.

signal stream_state_changed(stream_key: StringName, state: StringName, current: int, total: int)
signal stream_ready(stream_key: StringName, cache_path: String)
signal stream_failed(stream_key: StringName, reason: String)

const PlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")
const BackgroundDownloadStatusType := preload("res://scripts/view/background_download_status.gd")
const CACHE_DIR := PlayerType.CACHE_DIR
const COPY_CHUNK_BYTES := PlayerType.COPY_CHUNK_BYTES
const DOWNLOAD_TIMEOUT_SECONDS := PlayerType.DOWNLOAD_TIMEOUT_SECONDS
const PROFILE_ORDER := ["lunaris_vessel", "reliquary_duelist", "archive_caster"]

var _stream_urls: Dictionary = {}
var _queue: Array[String] = []
var _queued: Dictionary = {}
var _background_queued: Dictionary = {}
var _ready_paths: Dictionary = {}
var _failed_reasons: Dictionary = {}
var _request: HTTPRequest = null
var _active_key := ""
var _active_temp_path := ""
var _active_total := 0
var _last_progress_bytes := 0
var _title_entry_count := 0
var _background_downloads_enabled := true
var _background_limit := 6
var _active_background := false


func _ready() -> void:
	set_process(true)
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.background_policy_changed.connect(_on_content_background_policy_changed)
		_on_content_background_policy_changed(
			bool(content_packs.call("background_downloads_enabled")),
			StringName(content_packs.call("network_profile")),
			int(content_packs.call("background_class_limit")),
		)


func prefetch_from_title(
		viewport_size: Vector2 = Vector2.ZERO,
		arguments: PackedStringArray = OS.get_cmdline_user_args(),
) -> void:
	_title_entry_count += 1
	configure_streams(arguments)
	if _stream_urls.is_empty():
		return
	if not _background_downloads_enabled or _background_limit <= 0:
		return
	var effective_viewport := viewport_size
	if effective_viewport.x <= 0.0 or effective_viewport.y <= 0.0:
		effective_viewport = get_viewport().get_visible_rect().size
	var available := maxi(_background_limit - _background_pending_count(), 0)
	if available <= 0:
		return
	var queued_count := 0
	for stream_key: String in preferred_stream_order(effective_viewport):
		if queued_count >= available:
			break
		if _enqueue_stream(stream_key, false, true):
			queued_count += 1
	_pump_queue.call_deferred()


func configure_streams(arguments: PackedStringArray) -> void:
	var parsed := PlayerType.parse_stream_urls(arguments)
	for stream_key: Variant in parsed:
		_stream_urls[String(stream_key)] = String(parsed[stream_key])


func request_stream(stream_key: String, url: String = "") -> bool:
	if not PlayerType.STREAMS.has(stream_key):
		return false
	if not url.is_empty() and _valid_remote_url(url):
		_stream_urls[stream_key] = url
	var cache_path := _validated_cache_path(stream_key)
	if not cache_path.is_empty():
		_mark_ready(stream_key, cache_path)
		stream_ready.emit.call_deferred(StringName(stream_key), cache_path)
		return true
	_ready_paths.erase(stream_key)
	_failed_reasons.erase(stream_key)
	if _active_key == stream_key and _request != null:
		_active_background = false
		BackgroundDownloadStatusType.publish(&"resonance", StringName(stream_key), &"foreground")
		stream_state_changed.emit.call_deferred(
			StringName(stream_key), &"downloading", _last_progress_bytes, _active_total,
		)
		return false
	_enqueue_stream(stream_key, true, false)
	_pump_queue.call_deferred()
	return false


func preferred_stream_order(viewport_size: Vector2) -> Array[String]:
	var portrait_first := viewport_size.x < 900.0
	var first_orientation := "portrait" if portrait_first else "landscape"
	var second_orientation := "landscape" if portrait_first else "portrait"
	var ordered: Array[String] = []
	for orientation: String in [first_orientation, second_orientation]:
		for premium_id: String in PROFILE_ORDER:
			var profile: Dictionary = PlayerType.PROFILES.get(premium_id, {})
			var stream_key := String(profile.get("%s_stream" % orientation, ""))
			if not stream_key.is_empty():
				ordered.append(stream_key)
	return ordered


func configured_stream_count() -> int:
	return _stream_urls.size()


func title_entry_count() -> int:
	return _title_entry_count


func active_stream_key() -> String:
	return _active_key


func queued_stream_keys() -> Array[String]:
	return _queue.duplicate()


func completed_stream_count() -> int:
	return _ready_paths.size()


func set_background_download_policy(enabled: bool, limit: int) -> void:
	_background_downloads_enabled = enabled
	_background_limit = clampi(limit, 0, PlayerType.STREAMS.size())
	if not enabled or _background_limit <= 0:
		if _active_background:
			_cancel_active_download(true)
		_remove_background_queue()
		BackgroundDownloadStatusType.publish(&"resonance", &"", &"disabled")
		if _request == null and _active_key.is_empty() and not _queue.is_empty():
			_pump_queue.call_deferred()
		return
	_trim_background_queue()


func background_downloads_enabled() -> bool:
	return _background_downloads_enabled


func background_prefetch_limit() -> int:
	return _background_limit


func _on_content_background_policy_changed(
		enabled: bool,
		_network_profile: StringName,
		_class_limit: int,
	) -> void:
	var content_packs := get_node_or_null("/root/ContentPacks")
	var limit := 0
	if content_packs != null:
		limit = int((content_packs.call("adaptive_prefetch_limits") as Dictionary).get(&"resonance", 0))
	set_background_download_policy(enabled, limit)


func cached_stream_path(stream_key: String) -> String:
	return _validated_cache_path(stream_key)


func reset_for_tests() -> void:
	_cancel_active_download(true)
	_queue.clear()
	_queued.clear()
	_background_queued.clear()
	_ready_paths.clear()
	_failed_reasons.clear()
	_stream_urls.clear()
	_title_entry_count = 0
	_background_downloads_enabled = true
	_background_limit = 6
	_active_background = false


func _process(_delta: float) -> void:
	if _request == null or _active_key.is_empty():
		return
	var downloaded := _request.get_downloaded_bytes()
	var total := _request.get_body_size()
	if total <= 0:
		total = _active_total
	if downloaded == _last_progress_bytes:
		return
	_last_progress_bytes = downloaded
	stream_state_changed.emit(StringName(_active_key), &"downloading", downloaded, total)
	if _active_background:
		BackgroundDownloadStatusType.publish(
			&"resonance", StringName(_active_key), &"downloading", downloaded, total,
		)


func _enqueue_stream(stream_key: String, prioritize: bool, background: bool) -> bool:
	if not PlayerType.STREAMS.has(stream_key) or not _stream_urls.has(stream_key):
		return false
	if _active_key == stream_key:
		return false
	if _queued.has(stream_key):
		if not background:
			_background_queued[stream_key] = false
			BackgroundDownloadStatusType.publish(&"resonance", StringName(stream_key), &"foreground")
		if prioritize:
			_queue.erase(stream_key)
			_queue.push_front(stream_key)
		return false
	if prioritize:
		_queue.push_front(stream_key)
	else:
		_queue.append(stream_key)
	_queued[stream_key] = true
	_background_queued[stream_key] = background
	var spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
	stream_state_changed.emit(
		StringName(stream_key), &"queued", 0, int(spec.get("bytes", 0)),
	)
	if background:
		BackgroundDownloadStatusType.publish(
			&"resonance", StringName(stream_key), &"queued", 0, int(spec.get("bytes", 0)),
		)
	return true


func _pump_queue() -> void:
	if _request != null or not _active_key.is_empty():
		return
	while not _queue.is_empty():
		var stream_key: String = _queue.pop_front()
		_queued.erase(stream_key)
		_active_background = bool(_background_queued.get(stream_key, false))
		_background_queued.erase(stream_key)
		var cached_path := _existing_cache_path(stream_key)
		if not cached_path.is_empty():
			_mark_ready(stream_key, cached_path)
			stream_ready.emit(StringName(stream_key), cached_path)
			continue
		if not _stream_urls.has(stream_key):
			continue
		_start_download(stream_key)
		return


func _start_download(stream_key: String) -> void:
	var spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
	var url := String(_stream_urls.get(stream_key, ""))
	if spec.is_empty() or not _valid_remote_url(url):
		_fail_active("Cinematic source is not configured.")
		return
	_ensure_cache_dir()
	_active_key = stream_key
	_active_total = int(spec.get("bytes", 0))
	_active_temp_path = "%s/.prefetch-%s.part" % [CACHE_DIR, stream_key]
	if FileAccess.file_exists(_active_temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_active_temp_path))
	_request = HTTPRequest.new()
	_request.name = "CinematicPrefetchDownload"
	_request.accept_gzip = false
	_request.body_size_limit = _active_total + COPY_CHUNK_BYTES
	_request.download_chunk_size = 256 * 1024
	if not OS.has_feature("web"):
		_request.download_file = _active_temp_path
	_request.timeout = DOWNLOAD_TIMEOUT_SECONDS
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)
	_last_progress_bytes = 0
	stream_state_changed.emit(StringName(stream_key), &"downloading", 0, _active_total)
	if _active_background:
		BackgroundDownloadStatusType.publish(
			&"resonance", StringName(stream_key), &"downloading", 0, _active_total,
		)
	var error := _request.request(url)
	if error != OK:
		_fail_active("Request could not start (%s)." % error_string(error))


func _on_request_completed(
		result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray,
) -> void:
	var completed_key := _active_key
	var completed_background := _active_background
	var temp_path := _active_temp_path
	var spec: Dictionary = PlayerType.STREAMS.get(completed_key, {})
	var expected_bytes := int(spec.get("bytes", 0))
	var expected_sha := String(spec.get("sha256", ""))
	_dispose_request()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_cleanup_file(temp_path)
		_finish_failed(completed_key, "Download failed (result %d, HTTP %d)." % [result, response_code])
		return
	if not FileAccess.file_exists(temp_path) and not body.is_empty():
		var fallback_file := FileAccess.open(temp_path, FileAccess.WRITE)
		if fallback_file != null:
			fallback_file.store_buffer(body)
			fallback_file.close()
	if not _verify_file(temp_path, expected_bytes, expected_sha):
		_cleanup_file(temp_path)
		_finish_failed(completed_key, "Downloaded cinematic failed size or SHA-256 verification.")
		return
	var cache_path := _cache_path(completed_key)
	var promoted_path := _promote_verified_file(temp_path, cache_path)
	if promoted_path.is_empty():
		_cleanup_file(temp_path)
		_finish_failed(completed_key, "Verified cinematic could not be cached.")
		return
	_clear_active_state()
	_mark_ready(completed_key, promoted_path)
	stream_state_changed.emit(StringName(completed_key), &"ready", expected_bytes, expected_bytes)
	stream_ready.emit(StringName(completed_key), promoted_path)
	if completed_background:
		BackgroundDownloadStatusType.publish(
			&"resonance", StringName(completed_key), &"ready", expected_bytes, expected_bytes,
		)
	_pump_queue.call_deferred()


func _finish_failed(stream_key: String, reason: String) -> void:
	var failed_background := _active_background
	_clear_active_state()
	_failed_reasons[stream_key] = reason
	push_warning("Cinematic prefetch '%s' failed: %s" % [stream_key, reason])
	stream_state_changed.emit(StringName(stream_key), &"failed", 0, 0)
	stream_failed.emit(StringName(stream_key), reason)
	if failed_background:
		BackgroundDownloadStatusType.publish(&"resonance", StringName(stream_key), &"failed")
	_pump_queue.call_deferred()


func _fail_active(reason: String) -> void:
	var failed_key := _active_key
	var failed_background := _active_background
	_cancel_active_download(true)
	if failed_key.is_empty():
		return
	_failed_reasons[failed_key] = reason
	push_warning("Cinematic prefetch '%s' failed: %s" % [failed_key, reason])
	stream_state_changed.emit(StringName(failed_key), &"failed", 0, 0)
	stream_failed.emit(StringName(failed_key), reason)
	if failed_background:
		BackgroundDownloadStatusType.publish(&"resonance", StringName(failed_key), &"failed")
	_pump_queue.call_deferred()


func _mark_ready(stream_key: String, cache_path: String) -> void:
	_ready_paths[stream_key] = cache_path
	_failed_reasons.erase(stream_key)


func _validated_cache_path(stream_key: String) -> String:
	if not PlayerType.STREAMS.has(stream_key):
		return ""
	var path := _cache_path(stream_key)
	var spec: Dictionary = PlayerType.STREAMS[stream_key]
	if _verify_file(path, int(spec.get("bytes", 0)), String(spec.get("sha256", ""))):
		return path
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return ""


func _existing_cache_path(stream_key: String) -> String:
	if not PlayerType.STREAMS.has(stream_key):
		return ""
	var path := _cache_path(stream_key)
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var actual_bytes := file.get_length()
	file.close()
	var spec: Dictionary = PlayerType.STREAMS[stream_key]
	return path if actual_bytes == int(spec.get("bytes", 0)) else ""


func _cache_path(stream_key: String) -> String:
	var spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
	var digest := String(spec.get("sha256", ""))
	return "%s/%s-%s.ogv" % [CACHE_DIR, stream_key, digest.left(16)]


func _verify_file(path: String, expected_bytes: int, expected_sha: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var actual_bytes := file.get_length()
	file.close()
	if actual_bytes != expected_bytes:
		return false
	return FileAccess.get_sha256(path).to_lower() == expected_sha.to_lower()


func _promote_verified_file(temp_path: String, cache_path: String) -> String:
	if FileAccess.file_exists(cache_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_path))
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(cache_path),
	)
	if rename_error == OK and FileAccess.file_exists(cache_path):
		return cache_path
	if _copy_file(temp_path, cache_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return cache_path
	return temp_path if FileAccess.file_exists(temp_path) else ""


func _copy_file(source_path: String, destination_path: String) -> bool:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return false
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		source.close()
		return false
	while source.get_position() < source.get_length():
		var remaining := source.get_length() - source.get_position()
		destination.store_buffer(source.get_buffer(mini(COPY_CHUNK_BYTES, remaining)))
	destination.close()
	source.close()
	return FileAccess.file_exists(destination_path)


func _ensure_cache_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))


func _cancel_active_download(remove_partial: bool) -> void:
	if _request != null:
		_request.cancel_request()
		_dispose_request()
	if remove_partial:
		_cleanup_file(_active_temp_path)
	_clear_active_state()


func _dispose_request() -> void:
	if _request == null:
		return
	if _request.request_completed.is_connected(_on_request_completed):
		_request.request_completed.disconnect(_on_request_completed)
	_request.queue_free()
	_request = null


func _clear_active_state() -> void:
	_active_key = ""
	_active_temp_path = ""
	_active_total = 0
	_last_progress_bytes = 0
	_active_background = false


func _remove_background_queue() -> void:
	for index: int in range(_queue.size() - 1, -1, -1):
		var stream_key := _queue[index]
		if bool(_background_queued.get(stream_key, false)):
			_queue.remove_at(index)
			_queued.erase(stream_key)
			_background_queued.erase(stream_key)


func _trim_background_queue() -> void:
	var allowance := maxi(_background_limit - (1 if _active_background else 0), 0)
	var background_total := 0
	for stream_key: String in _queue:
		if bool(_background_queued.get(stream_key, false)):
			background_total += 1
	for index: int in range(_queue.size() - 1, -1, -1):
		if background_total <= allowance:
			break
		var stream_key := _queue[index]
		if not bool(_background_queued.get(stream_key, false)):
			continue
		_queue.remove_at(index)
		_queued.erase(stream_key)
		_background_queued.erase(stream_key)
		background_total -= 1


func _background_pending_count() -> int:
	var count := 1 if _active_background else 0
	for stream_key: String in _queue:
		if bool(_background_queued.get(stream_key, false)):
			count += 1
	return count


func _cleanup_file(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _valid_remote_url(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://")
