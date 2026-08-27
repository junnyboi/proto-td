extends Node

## Dedicated presentation-only prefetch for the sixteen mission prologues.
## Existing Premium Resonance CinematicPrefetch remains an independent service.

signal stage_ready(stage_id: StringName, playable_path: String)
signal stage_progress(stage_id: StringName, state: StringName, current: int, total: int)
signal stage_error(stage_id: StringName, reason: String)

const CatalogType := preload("res://data/presentation/cinematics/mission_cinematic_catalog.gd")
const STREAM_ARG_PREFIX := "--mission-cinematic-stream="
const CACHE_DIR := "user://mission-cinematic-streams"
const DOWNLOAD_TIMEOUT_SECONDS := 75.0
const DOWNLOAD_CHUNK_BYTES := 256 * 1024
const MAX_DOWNLOAD_BYTES := 256 * 1024 * 1024

var _stream_urls: Dictionary = {}
var _queue: Array[StringName] = []
var _queued: Dictionary = {}
var _ready_paths: Dictionary = {}
var _failed_reasons: Dictionary = {}
var _request: HTTPRequest = null
var _active_stage_id: StringName = &""
var _active_temp_path := ""
var _active_total := 0
var _last_progress_bytes := -1
var _title_entry_count := 0


func _ready() -> void:
	set_process(true)


func prefetch_from_title(arguments: PackedStringArray = OS.get_cmdline_user_args()) -> void:
	_title_entry_count += 1
	configure_streams(arguments)
	for stage_id: StringName in CatalogType.stage_ids():
		if _stream_urls.has(stage_id):
			_enqueue(stage_id, false)
	_pump_queue.call_deferred()


func configure_streams(arguments: PackedStringArray) -> void:
	var parsed := parse_stream_urls(arguments)
	for stage_id: Variant in parsed:
		_stream_urls[StringName(stage_id)] = String(parsed[stage_id])


static func parse_stream_urls(arguments: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	for argument: String in arguments:
		if not argument.begins_with(STREAM_ARG_PREFIX):
			continue
		var payload := argument.substr(STREAM_ARG_PREFIX.length())
		var separator := payload.find("|")
		if separator <= 0 or separator >= payload.length() - 1:
			continue
		var stage_id := StringName(payload.substr(0, separator))
		var url := payload.substr(separator + 1)
		if CatalogType.record_for(stage_id) != null and _valid_remote_url(url):
			parsed[stage_id] = url
	return parsed


func request_stage(stage_id: StringName, prioritize: bool = true) -> bool:
	var record := CatalogType.record_for(stage_id)
	if record == null:
		stage_error.emit.call_deferred(stage_id, "Unknown mission cinematic stage.")
		return false
	if not OS.has_feature("web") and FileAccess.file_exists(record.video.path):
		_ready_paths[stage_id] = record.video.path
		stage_ready.emit.call_deferred(stage_id, record.video.path)
		return true
	var cached := _validated_cache_path(stage_id)
	if not cached.is_empty():
		_ready_paths[stage_id] = cached
		stage_ready.emit.call_deferred(stage_id, cached)
		return true
	if not _stream_urls.has(stage_id):
		_failed_reasons[stage_id] = "Mission cinematic stream is unavailable."
		stage_error.emit.call_deferred(stage_id, String(_failed_reasons[stage_id]))
		return false
	_failed_reasons.erase(stage_id)
	_enqueue(stage_id, prioritize)
	_pump_queue.call_deferred()
	return false


func cached_stage_path(stage_id: StringName) -> String:
	var record := CatalogType.record_for(stage_id)
	if record == null:
		return ""
	if not OS.has_feature("web") and FileAccess.file_exists(record.video.path):
		return record.video.path
	if _ready_paths.has(stage_id):
		var path := String(_ready_paths[stage_id])
		if verify_file(path, record.video.bytes, record.video.sha256):
			return path
	return _validated_cache_path(stage_id)


func configured_stream_count() -> int:
	return _stream_urls.size()


func title_entry_count() -> int:
	return _title_entry_count


func active_stage_id() -> StringName:
	return _active_stage_id


func queued_stage_ids() -> Array[StringName]:
	return _queue.duplicate()


func reset_for_tests() -> void:
	_cancel_active(true)
	_queue.clear()
	_queued.clear()
	_ready_paths.clear()
	_failed_reasons.clear()
	_stream_urls.clear()
	_title_entry_count = 0


static func verify_file(path: String, expected_bytes: int, expected_sha256: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var actual_bytes := file.get_length()
	file.close()
	if expected_bytes > 0 and actual_bytes != expected_bytes:
		return false
	if not expected_sha256.is_empty():
		return FileAccess.get_sha256(path).to_lower() == expected_sha256.to_lower()
	return true


func _process(_delta: float) -> void:
	if _request == null or _active_stage_id.is_empty():
		return
	var downloaded := _request.get_downloaded_bytes()
	var total := _request.get_body_size()
	if total <= 0:
		total = _active_total
	if downloaded == _last_progress_bytes:
		return
	_last_progress_bytes = downloaded
	stage_progress.emit(_active_stage_id, &"downloading", downloaded, total)


func _enqueue(stage_id: StringName, prioritize: bool) -> void:
	if _active_stage_id == stage_id:
		return
	if _queued.has(stage_id):
		if prioritize:
			_queue.erase(stage_id)
			_queue.push_front(stage_id)
		return
	if prioritize:
		_queue.push_front(stage_id)
	else:
		_queue.append(stage_id)
	_queued[stage_id] = true
	var record := CatalogType.record_for(stage_id)
	stage_progress.emit(stage_id, &"queued", 0, record.video.bytes if record != null else 0)


func _pump_queue() -> void:
	if _request != null or not _active_stage_id.is_empty():
		return
	while not _queue.is_empty():
		var stage_id: StringName = _queue.pop_front()
		_queued.erase(stage_id)
		var cached := _validated_cache_path(stage_id)
		if not cached.is_empty():
			_ready_paths[stage_id] = cached
			stage_ready.emit(stage_id, cached)
			continue
		if not _stream_urls.has(stage_id):
			continue
		_start_download(stage_id)
		return


func _start_download(stage_id: StringName) -> void:
	var record := CatalogType.record_for(stage_id)
	var url := String(_stream_urls.get(stage_id, ""))
	if record == null or not _valid_remote_url(url):
		_finish_failed(stage_id, "Mission cinematic source is not configured.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))
	_active_stage_id = stage_id
	_active_total = record.video.bytes
	_active_temp_path = "%s/.%s.part" % [CACHE_DIR, stage_id]
	_cleanup_file(_active_temp_path)
	_request = HTTPRequest.new()
	_request.name = "MissionCinematicDownload"
	_request.accept_gzip = false
	_request.body_size_limit = min(record.video.bytes + DOWNLOAD_CHUNK_BYTES, MAX_DOWNLOAD_BYTES) if record.video.bytes > 0 else MAX_DOWNLOAD_BYTES
	_request.download_chunk_size = DOWNLOAD_CHUNK_BYTES
	if not OS.has_feature("web"):
		_request.download_file = _active_temp_path
	_request.timeout = DOWNLOAD_TIMEOUT_SECONDS
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)
	_last_progress_bytes = 0
	stage_progress.emit(stage_id, &"downloading", 0, _active_total)
	var request_error := _request.request(url)
	if request_error != OK:
		_finish_failed(stage_id, "Mission cinematic request could not start (%s)." % error_string(request_error))


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var stage_id := _active_stage_id
	var temp_path := _active_temp_path
	var record := CatalogType.record_for(stage_id)
	_dispose_request()
	if record == null or result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_cleanup_file(temp_path)
		_finish_failed(stage_id, "Mission cinematic download failed (result %d, HTTP %d)." % [result, response_code])
		return
	if not FileAccess.file_exists(temp_path) and not body.is_empty():
		var output := FileAccess.open(temp_path, FileAccess.WRITE)
		if output != null:
			output.store_buffer(body)
			output.close()
	if not verify_file(temp_path, record.video.bytes, record.video.sha256):
		_cleanup_file(temp_path)
		_finish_failed(stage_id, "Mission cinematic failed size or SHA-256 verification.")
		return
	var digest := FileAccess.get_sha256(temp_path).to_lower()
	var cache_path := "%s/%s.ogv" % [CACHE_DIR, digest]
	var playable := _promote_file(temp_path, cache_path)
	if playable.is_empty():
		_cleanup_file(temp_path)
		_finish_failed(stage_id, "Verified mission cinematic could not be cached.")
		return
	_clear_active()
	_ready_paths[stage_id] = playable
	stage_progress.emit(stage_id, &"ready", record.video.bytes, record.video.bytes)
	stage_ready.emit(stage_id, playable)
	_pump_queue.call_deferred()


func _validated_cache_path(stage_id: StringName) -> String:
	var record := CatalogType.record_for(stage_id)
	if record == null or record.video.sha256.is_empty():
		return ""
	var path := "%s/%s.ogv" % [CACHE_DIR, record.video.sha256.to_lower()]
	if verify_file(path, record.video.bytes, record.video.sha256):
		return path
	_cleanup_file(path)
	return ""


func _finish_failed(stage_id: StringName, reason: String) -> void:
	if stage_id == _active_stage_id:
		_cancel_active(true)
	_failed_reasons[stage_id] = reason
	stage_progress.emit(stage_id, &"failed", 0, 0)
	stage_error.emit(stage_id, reason)
	_pump_queue.call_deferred()


func _promote_file(source_path: String, cache_path: String) -> String:
	if FileAccess.file_exists(cache_path):
		_cleanup_file(source_path)
		return cache_path
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(source_path),
		ProjectSettings.globalize_path(cache_path),
	)
	if rename_error == OK and FileAccess.file_exists(cache_path):
		return cache_path
	var source := FileAccess.open(source_path, FileAccess.READ)
	var destination := FileAccess.open(cache_path, FileAccess.WRITE)
	if source == null or destination == null:
		if source != null:
			source.close()
		if destination != null:
			destination.close()
		return ""
	while source.get_position() < source.get_length():
		destination.store_buffer(source.get_buffer(mini(DOWNLOAD_CHUNK_BYTES, source.get_length() - source.get_position())))
	source.close()
	destination.close()
	_cleanup_file(source_path)
	return cache_path if FileAccess.file_exists(cache_path) else ""


func _cancel_active(remove_partial: bool) -> void:
	if _request != null:
		_request.cancel_request()
		_dispose_request()
	if remove_partial:
		_cleanup_file(_active_temp_path)
	_clear_active()


func _dispose_request() -> void:
	if _request == null:
		return
	if _request.request_completed.is_connected(_on_request_completed):
		_request.request_completed.disconnect(_on_request_completed)
	_request.queue_free()
	_request = null


func _clear_active() -> void:
	_active_stage_id = &""
	_active_temp_path = ""
	_active_total = 0
	_last_progress_bytes = -1


func _cleanup_file(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _valid_remote_url(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://")
