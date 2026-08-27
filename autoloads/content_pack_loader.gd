extends Node

## Downloads presentation-only atlas packs after the cold-start core is playable.
## Packs may add absent resources but never replace core files. Missing content
## always falls back to incumbent art while a verified pack is in flight.

signal pack_state_changed(pack_id: StringName, state: StringName, current: int, total: int)
signal pack_ready(pack_id: StringName)
signal pack_failed(pack_id: StringName, reason: String)

const ARG_PREFIX := "--content-pack="
const CACHE_DIR := "user://content-packs"
const COPY_CHUNK_BYTES := 256 * 1024
const DOWNLOAD_TIMEOUT_SECONDS := 180.0
const MAX_PACK_BYTES := 64 * 1024 * 1024
const ADVANCED_CLASSES := [
	"banner_guard",
	"defender",
	"gunner",
	"immovable",
	"mage_apprentice",
	"shock_trooper",
	"sniper",
	"sorcerer",
	"sword_saint",
	"swordmaster",
	"witch_doctor",
]

var _specs: Dictionary = {}
var _queue: Array[String] = []
var _queued: Dictionary = {}
var _loaded: Dictionary = {}
var _failed: Dictionary = {}
var _request: HTTPRequest = null
var _active_id := ""
var _active_total := 0
var _last_progress := 0


func _ready() -> void:
	set_process(false)


func configure(arguments: PackedStringArray = OS.get_cmdline_user_args()) -> void:
	for argument: String in arguments:
		if not argument.begins_with(ARG_PREFIX):
			continue
		var spec := parse_argument(argument)
		if spec.is_empty():
			continue
		_specs[String(spec[&"id"])] = spec


func prefetch_from_title(arguments: PackedStringArray = OS.get_cmdline_user_args()) -> void:
	configure(arguments)


func request_resource(path: String) -> bool:
	if path.is_empty() or FileAccess.file_exists(path):
		return true
	var pack_id := pack_id_for_resource(path)
	if pack_id.is_empty():
		return false
	request_pack(pack_id, true)
	return FileAccess.file_exists(path)


func request_pack(pack_id: String, prioritize := true) -> bool:
	if _loaded.has(pack_id):
		return true
	if not _specs.has(pack_id):
		return false
	if _mount_cached(pack_id):
		return true
	if _failed.has(pack_id):
		return false
	if _active_id == pack_id:
		return false
	if _queued.has(pack_id):
		if prioritize:
			_queue.erase(pack_id)
			_queue.push_front(pack_id)
		return false
	if prioritize:
		_queue.push_front(pack_id)
	else:
		_queue.append(pack_id)
	_queued[pack_id] = true
	var spec: Dictionary = _specs[pack_id]
	pack_state_changed.emit(StringName(pack_id), &"queued", 0, int(spec[&"bytes"]))
	_pump_queue.call_deferred()
	return false


func configured_pack_count() -> int:
	return _specs.size()


func is_pack_ready(pack_id: String) -> bool:
	return _loaded.has(pack_id)


func active_pack_id() -> String:
	return _active_id


func queued_pack_ids() -> Array[String]:
	return _queue.duplicate()


func reset_for_tests() -> void:
	_cancel_active()
	_specs.clear()
	_queue.clear()
	_queued.clear()
	_loaded.clear()
	_failed.clear()


func _process(_delta: float) -> void:
	if _request == null or _active_id.is_empty():
		return
	var downloaded := _request.get_downloaded_bytes()
	var total := _request.get_body_size()
	if total <= 0:
		total = _active_total
	if downloaded == _last_progress:
		return
	_last_progress = downloaded
	pack_state_changed.emit(StringName(_active_id), &"downloading", downloaded, total)


func _pump_queue() -> void:
	if _request != null or not _active_id.is_empty():
		return
	while not _queue.is_empty():
		var pack_id: String = _queue.pop_front()
		_queued.erase(pack_id)
		if _loaded.has(pack_id):
			continue
		if _mount_cached(pack_id):
			continue
		_start_download(pack_id)
		return


func _start_download(pack_id: String) -> void:
	var spec: Dictionary = _specs.get(pack_id, {})
	if spec.is_empty():
		_finish_failed(pack_id, "Content pack is not configured.")
		return
	_active_id = pack_id
	_active_total = int(spec[&"bytes"])
	_last_progress = 0
	_request = HTTPRequest.new()
	_request.name = "ContentPackDownload"
	_request.accept_gzip = false
	_request.body_size_limit = _active_total + COPY_CHUNK_BYTES
	_request.download_chunk_size = COPY_CHUNK_BYTES
	_request.timeout = DOWNLOAD_TIMEOUT_SECONDS
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)
	set_process(true)
	pack_state_changed.emit(StringName(pack_id), &"downloading", 0, _active_total)
	var error := _request.request(String(spec[&"url"]))
	if error != OK:
		_finish_failed(pack_id, "Request could not start (%s)." % error_string(error))


func _on_request_completed(
		result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray,
) -> void:
	var pack_id := _active_id
	var spec: Dictionary = _specs.get(pack_id, {})
	_dispose_request()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_finish_failed(pack_id, "Download failed (result %d, HTTP %d)." % [result, response_code])
		return
	if body.size() != int(spec.get(&"bytes", 0)):
		_finish_failed(pack_id, "Downloaded content pack failed its byte-length check.")
		return
	_ensure_cache_dir()
	var path := _cache_path(pack_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_finish_failed(pack_id, "Downloaded content pack could not be cached.")
		return
	file.store_buffer(body)
	file.close()
	if not _verify_file(path, spec):
		_cleanup_file(path)
		_finish_failed(pack_id, "Downloaded content pack failed SHA-256 verification.")
		return
	_clear_active()
	if not _mount_pack(pack_id, path):
		_cleanup_file(path)
		_finish_failed(pack_id, "Verified content pack could not be mounted.")
		return
	_pump_queue.call_deferred()


func _mount_cached(pack_id: String) -> bool:
	var spec: Dictionary = _specs.get(pack_id, {})
	if spec.is_empty():
		return false
	var path := _cache_path(pack_id)
	if not _verify_file(path, spec):
		_cleanup_file(path)
		return false
	return _mount_pack(pack_id, path)


func _mount_pack(pack_id: String, path: String) -> bool:
	# `replace_files = false` is the security boundary: downloaded packs may only
	# provide resources intentionally omitted from the signed core export.
	if not ProjectSettings.load_resource_pack(path, false):
		return false
	_loaded[pack_id] = true
	_failed.erase(pack_id)
	pack_state_changed.emit(StringName(pack_id), &"ready", int(_specs[pack_id][&"bytes"]), int(_specs[pack_id][&"bytes"]))
	pack_ready.emit(StringName(pack_id))
	return true


func _finish_failed(pack_id: String, reason: String) -> void:
	_dispose_request()
	_clear_active()
	_failed[pack_id] = reason
	push_warning("Content pack '%s' failed: %s" % [pack_id, reason])
	pack_state_changed.emit(StringName(pack_id), &"failed", 0, 0)
	pack_failed.emit(StringName(pack_id), reason)
	_pump_queue.call_deferred()


func _dispose_request() -> void:
	if _request == null:
		return
	if _request.request_completed.is_connected(_on_request_completed):
		_request.request_completed.disconnect(_on_request_completed)
	_request.queue_free()
	_request = null


func _cancel_active() -> void:
	if _request != null:
		_request.cancel_request()
	_dispose_request()
	_clear_active()


func _clear_active() -> void:
	_active_id = ""
	_active_total = 0
	_last_progress = 0
	set_process(false)


func _cache_path(pack_id: String) -> String:
	var digest := String((_specs.get(pack_id, {}) as Dictionary).get(&"sha256", ""))
	return "%s/%s-%s.pck" % [CACHE_DIR, pack_id, digest.left(16)]


func _verify_file(path: String, spec: Dictionary) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var actual_bytes := file.get_length()
	file.close()
	if actual_bytes != int(spec.get(&"bytes", 0)):
		return false
	return FileAccess.get_sha256(path).to_lower() == String(spec.get(&"sha256", "")).to_lower()


func _ensure_cache_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))


func _cleanup_file(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func parse_argument(argument: String) -> Dictionary:
	if not argument.begins_with(ARG_PREFIX):
		return {}
	var fields := argument.substr(ARG_PREFIX.length()).split("|", false)
	if fields.size() != 4:
		return {}
	var pack_id := String(fields[0])
	var url := String(fields[1])
	var byte_text := String(fields[2])
	var digest := String(fields[3]).to_lower()
	if not valid_pack_ids().has(pack_id):
		return {}
	if not (url.begins_with("https://") or url.begins_with("http://")):
		return {}
	if not byte_text.is_valid_int():
		return {}
	var bytes := byte_text.to_int()
	if bytes <= 0 or bytes > MAX_PACK_BYTES:
		return {}
	if digest.length() != 64 or not digest.is_valid_hex_number(false):
		return {}
	return {&"id": pack_id, &"url": url, &"bytes": bytes, &"sha256": digest}


static func pack_id_for_resource(path: String) -> String:
	const prefix := "res://assets/sprites/operators/animated/"
	if not path.begins_with(prefix):
		return ""
	var relative := path.substr(prefix.length())
	var class_id := relative.get_slice("/", 0)
	if not ADVANCED_CLASSES.has(class_id):
		return ""
	return "operator-%s" % class_id.replace("_", "-")


static func valid_pack_ids() -> Array[String]:
	var result: Array[String] = []
	for class_id: String in ADVANCED_CLASSES:
		result.append("operator-%s" % class_id.replace("_", "-"))
	return result
