extends Node

## Sole runtime music owner. Playback is presentation-only: it never enters the
## deterministic BattleModel, state hash, save data, or replay. A single player
## hard-replaces cues because the approved contract forbids layering.
##
## The title theme remains in the base PCK. Battle tracks may be supplied by
## act-specific resource packs. Missing or failed packs never block navigation;
## the requested cue starts automatically only after its verified pack mounts.

signal pack_state_changed(act: int, state: StringName)

const CATALOG_PATH := "res://assets/music/catalog.tres"
const MUSIC_CATALOG_SCRIPT: GDScript = preload("res://assets/music/music_catalog.gd")
const PLAYER_NAME := "Player"
const PACK_ARGUMENT_PREFIX := "--music-pack="
const PACK_PRELOAD_ARGUMENT_PREFIX := "--music-pack-preload="
const PACK_CACHE_DIR := "user://music-packs"
const PACK_DOWNLOAD_TIMEOUT_SECONDS := 45.0
const PACK_DOWNLOAD_CHUNK_BYTES := 262_144

const PACK_STATE_UNCONFIGURED := &"unconfigured"
const PACK_STATE_CONFIGURED := &"configured"
const PACK_STATE_LOADING := &"loading"
const PACK_STATE_READY := &"ready"
const PACK_STATE_FAILED := &"failed"
const PACK_STATE_BUNDLED := &"bundled"

var _catalog: Resource = null
var _player: AudioStreamPlayer = null
var _current_id: StringName = &""
var _start_count := 0
var _stop_count := 0
var _active_battle_instance_id := 0
var _pack_specs: Dictionary = {}
var _pack_states: Dictionary = {}
var _pack_requests: Dictionary = {}
var _pending_cues: Dictionary = {}


func _ready() -> void:
	reload_catalog()
	_ensure_player()
	configure_content_packs_from_args()


func _process(_delta: float) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var battle := game.get("current_battle") as BattleModel
	var content_value: Variant = game.get("content")
	if battle == null or content_value == null or not is_instance_valid(content_value):
		_active_battle_instance_id = 0
		return
	if not content_value is Node2D:
		_active_battle_instance_id = 0
		return
	var content := content_value as Node2D
	var battle_instance_id := int(content.get_instance_id())
	if battle_instance_id != _active_battle_instance_id:
		_active_battle_instance_id = battle_instance_id
	var wave := battle.spell_book.wave_index_of(battle.tick)
	sync_stage_wave(battle.stage, wave)


func reload_catalog() -> bool:
	var loaded := load(CATALOG_PATH) as Resource
	if loaded == null or loaded.get_script() != MUSIC_CATALOG_SCRIPT:
		_catalog = null
		return false
	var entries_value: Variant = loaded.get("entries")
	if not entries_value is Dictionary:
		_catalog = null
		return false
	var entries: Dictionary = entries_value
	if entries.is_empty():
		_catalog = null
		return false
	_catalog = loaded
	return true


func configure_content_packs_from_args() -> int:
	var specs: Dictionary = {}
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for argument: String in OS.get_cmdline_args():
		if not arguments.has(argument):
			arguments.append(argument)
	for argument: String in arguments:
		if not argument.begins_with(PACK_ARGUMENT_PREFIX):
			continue
		var payload := argument.trim_prefix(PACK_ARGUMENT_PREFIX)
		var parts := payload.split("|", true, 3)
		if parts.size() != 4:
			continue
		var act := int(parts[0])
		if act < 1 or act > 3:
			continue
		specs[act] = {
			"url": String(parts[1]),
			"sha256": String(parts[2]).to_lower(),
			"bytes": int(parts[3]),
		}
	var configured := configure_content_packs(specs)
	if configured <= 0:
		return configured
	for argument: String in arguments:
		if not argument.begins_with(PACK_PRELOAD_ARGUMENT_PREFIX):
			continue
		var act := int(argument.trim_prefix(PACK_PRELOAD_ARGUMENT_PREFIX))
		if _pack_specs.has(act):
			_ensure_content_pack.call_deferred(act)
	return configured


func configure_content_packs(raw_specs: Dictionary) -> int:
	_cancel_pack_requests()
	_pack_specs.clear()
	_pack_states.clear()
	_pending_cues.clear()
	for key: Variant in raw_specs:
		var act := int(key)
		var value: Variant = raw_specs[key]
		if act < 1 or act > 3 or not value is Dictionary:
			continue
		var raw: Dictionary = value
		var url := String(raw.get("url", ""))
		var sha256 := String(raw.get("sha256", "")).to_lower()
		var expected_bytes := int(raw.get("bytes", 0))
		if url.is_empty() or sha256.length() != 64 or expected_bytes <= 0:
			continue
		_pack_specs[act] = {
			"url": url,
			"sha256": sha256,
			"bytes": expected_bytes,
		}
		_set_pack_state(act, PACK_STATE_CONFIGURED)
	if not _pack_specs.is_empty():
		print("MUSIC_CONTENT_PACKS_CONFIGURED=%d" % _pack_specs.size())
	return _pack_specs.size()


func play_stage_bgm(stage: StageDef) -> bool:
	if stage == null:
		return false
	return play_cue(_cue_id(stage.music_act, &"bgm"))


func play_stage_boss(stage: StageDef) -> bool:
	if stage == null:
		return false
	return play_cue(_cue_id(stage.music_act, &"boss"))


func sync_stage_wave(stage: StageDef, wave_index: int) -> bool:
	if stage == null or wave_index < 0:
		return false
	if stage.music_boss_wave_index >= 0 and wave_index >= stage.music_boss_wave_index:
		return play_stage_boss(stage)
	return play_stage_bgm(stage)


## Valid repeats are successful no-ops: no seek and no restart.
## Invalid requests validate before touching the one player or controller state.
func play_cue(cue_id: StringName) -> bool:
	if cue_id.is_empty():
		return false
	if _catalog == null and not reload_catalog():
		return false
	var entries_value: Variant = _catalog.get("entries")
	if not entries_value is Dictionary or not entries_value.has(cue_id):
		return false
	var entries: Dictionary = entries_value
	var entry: Dictionary = entries[cue_id]
	var stream_path := String(entry.get("path", ""))
	if stream_path.is_empty():
		return false
	if not ResourceLoader.exists(stream_path):
		var act := _act_for_cue(cue_id)
		if act > 0:
			_pending_cues[act] = cue_id
			_ensure_content_pack(act)
		return false
	var act := _act_for_cue(cue_id)
	if act > 0 and pack_state(act) == PACK_STATE_UNCONFIGURED:
		_set_pack_state(act, PACK_STATE_BUNDLED)
	var stream := load(stream_path) as AudioStream
	if stream == null:
		return false
	var player := _ensure_player()
	if _current_id == cue_id and player.stream == stream:
		return true
	if not _current_id.is_empty():
		_stop_active()
	player.stream = stream
	_current_id = cue_id
	player.play()
	_start_count += 1
	return true


func stop() -> bool:
	var had_pending := not _pending_cues.is_empty()
	_pending_cues.clear()
	if _current_id.is_empty():
		return had_pending
	_stop_active()
	return true


func current_id() -> StringName:
	return _current_id


func start_count() -> int:
	return _start_count


func stop_count() -> int:
	return _stop_count


func player_count() -> int:
	var count := 0
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count


func current_stream_path() -> String:
	if _player == null or _player.stream == null:
		return ""
	return _player.stream.resource_path


func pack_state(act: int) -> StringName:
	return _pack_states.get(act, PACK_STATE_UNCONFIGURED) as StringName


func pack_is_ready(act: int) -> bool:
	return pack_state(act) in [PACK_STATE_READY, PACK_STATE_BUNDLED]


func pack_download_progress(act: int) -> float:
	var request := _pack_requests.get(act) as HTTPRequest
	if request == null:
		return 1.0 if pack_is_ready(act) else 0.0
	var total := int(request.get_body_size())
	if total <= 0:
		total = int((_pack_specs.get(act, {}) as Dictionary).get("bytes", 0))
	if total <= 0:
		return 0.0
	return clampf(float(request.get_downloaded_bytes()) / float(total), 0.0, 1.0)


func active_content_pack_act(preferred_act: int = 1) -> int:
	for state: StringName in [PACK_STATE_LOADING, PACK_STATE_FAILED]:
		for act: int in range(1, 4):
			if pack_state(act) == state:
				return act
	if _pack_specs.has(preferred_act) and not pack_is_ready(preferred_act):
		return preferred_act
	return 0


func prefetch_content_pack(act: int) -> bool:
	if not _pack_specs.has(act) or pack_state(act) == PACK_STATE_FAILED:
		return false
	return _ensure_content_pack(act)


func retry_content_pack(act: int) -> bool:
	if not _pack_specs.has(act) or pack_state(act) == PACK_STATE_LOADING:
		return false
	_set_pack_state(act, PACK_STATE_CONFIGURED)
	return _ensure_content_pack(act)


func mount_pack_file(
	act: int,
	pack_path: String,
	expected_sha256: String = "",
	expected_bytes: int = 0,
) -> bool:
	if act < 1 or act > 3:
		return false
	if not _validate_pack_file(pack_path, expected_sha256, expected_bytes):
		_set_pack_state(act, PACK_STATE_FAILED)
		return false
	if not ProjectSettings.load_resource_pack(pack_path, false):
		_set_pack_state(act, PACK_STATE_FAILED)
		return false
	_set_pack_state(act, PACK_STATE_READY)
	return true


func _cue_id(act: int, role: StringName) -> StringName:
	if act < 1 or act > 3 or role not in [&"bgm", &"boss"]:
		return &""
	return StringName("act_%d_%s" % [act, role])


func _act_for_cue(cue_id: StringName) -> int:
	var cue := String(cue_id)
	if not cue.begins_with("act_") or cue.length() < 5:
		return 0
	var act := int(cue.substr(4, 1))
	return act if act >= 1 and act <= 3 else 0


func _ensure_content_pack(act: int) -> bool:
	if not _pack_specs.has(act):
		return false
	var state := pack_state(act)
	if state == PACK_STATE_READY or state == PACK_STATE_LOADING or state == PACK_STATE_FAILED:
		return state == PACK_STATE_READY
	var spec: Dictionary = _pack_specs[act]
	var cached_path := _cache_path(act, String(spec["sha256"]))
	if FileAccess.file_exists(cached_path):
		if mount_pack_file(act, cached_path, String(spec["sha256"]), int(spec["bytes"])):
			_resume_pending_cue(act)
			return true
		_remove_file(cached_path)
		_set_pack_state(act, PACK_STATE_CONFIGURED)
	return _begin_pack_download(act)


func _begin_pack_download(act: int) -> bool:
	var spec: Dictionary = _pack_specs.get(act, {})
	if spec.is_empty():
		return false
	var cache_dir_absolute := ProjectSettings.globalize_path(PACK_CACHE_DIR)
	if DirAccess.make_dir_recursive_absolute(cache_dir_absolute) != OK:
		_set_pack_state(act, PACK_STATE_FAILED)
		return false
	var temp_path := _temp_path(act)
	_remove_file(temp_path)
	var request := HTTPRequest.new()
	request.name = "MusicPackAct%d" % act
	request.accept_gzip = false
	request.body_size_limit = int(spec["bytes"]) + 1024
	request.download_chunk_size = PACK_DOWNLOAD_CHUNK_BYTES
	if not OS.has_feature("web"):
		request.download_file = temp_path
	request.timeout = PACK_DOWNLOAD_TIMEOUT_SECONDS
	request.request_completed.connect(_on_pack_request_completed.bind(act))
	add_child(request)
	_pack_requests[act] = request
	_set_pack_state(act, PACK_STATE_LOADING)
	var request_error := request.request(String(spec["url"]))
	if request_error != OK:
		_pack_requests.erase(act)
		request.queue_free()
		_set_pack_state(act, PACK_STATE_FAILED)
		return false
	return true


func _on_pack_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	act: int,
) -> void:
	var request := _pack_requests.get(act) as HTTPRequest
	_pack_requests.erase(act)
	if request != null:
		request.queue_free()
	var temp_path := _temp_path(act)
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_remove_file(temp_path)
		_set_pack_state(act, PACK_STATE_FAILED)
		print("MUSIC_CONTENT_PACK_DOWNLOAD_FAILED act=%d result=%d status=%d" % [act, result, response_code])
		return
	if not FileAccess.file_exists(temp_path) and not _write_pack_response(temp_path, body):
		_set_pack_state(act, PACK_STATE_FAILED)
		print("MUSIC_CONTENT_PACK_WRITE_FAILED act=%d bytes=%d" % [act, body.size()])
		return
	var spec: Dictionary = _pack_specs.get(act, {})
	if spec.is_empty() or not _validate_pack_file(
		temp_path, String(spec.get("sha256", "")), int(spec.get("bytes", 0)),
	):
		_remove_file(temp_path)
		_set_pack_state(act, PACK_STATE_FAILED)
		print("MUSIC_CONTENT_PACK_VALIDATION_FAILED act=%d" % act)
		return
	var cached_path := _cache_path(act, String(spec["sha256"]))
	_remove_file(cached_path)
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(cached_path),
	)
	if rename_error != OK or not mount_pack_file(
		act, cached_path, String(spec["sha256"]), int(spec["bytes"]),
	):
		_remove_file(temp_path)
		_remove_file(cached_path)
		_set_pack_state(act, PACK_STATE_FAILED)
		print("MUSIC_CONTENT_PACK_MOUNT_FAILED act=%d" % act)
		return
	print("MUSIC_CONTENT_PACK_READY act=%d bytes=%d" % [act, int(spec["bytes"])])
	_resume_pending_cue(act)


func _resume_pending_cue(act: int) -> void:
	if not _pending_cues.has(act):
		return
	var cue_id := _pending_cues[act] as StringName
	_pending_cues.erase(act)
	play_cue.call_deferred(cue_id)


func _cache_path(act: int, sha256: String) -> String:
	return "%s/act-%d-%s.pck" % [PACK_CACHE_DIR, act, sha256.left(16)]


func _temp_path(act: int) -> String:
	return "%s/act-%d.download" % [PACK_CACHE_DIR, act]


func _validate_pack_file(path: String, expected_sha256: String, expected_bytes: int) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	if expected_bytes > 0 and FileAccess.get_size(path) != expected_bytes:
		return false
	if not expected_sha256.is_empty() and FileAccess.get_sha256(path).to_lower() != expected_sha256.to_lower():
		return false
	return true


func _write_pack_response(path: String, body: PackedByteArray) -> bool:
	if path.is_empty() or body.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(body)
	file.flush()
	file.close()
	return FileAccess.file_exists(path) and FileAccess.get_size(path) == body.size()


func _remove_file(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _set_pack_state(act: int, state: StringName) -> void:
	if pack_state(act) == state:
		return
	_pack_states[act] = state
	pack_state_changed.emit(act, state)


func _cancel_pack_requests() -> void:
	for value: Variant in _pack_requests.values():
		var request := value as HTTPRequest
		if request != null:
			request.cancel_request()
			request.queue_free()
	_pack_requests.clear()


func _ensure_player() -> AudioStreamPlayer:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_node_or_null(PLAYER_NAME) as AudioStreamPlayer
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = PLAYER_NAME
		add_child(_player)
	return _player


func _stop_active() -> void:
	var player := _ensure_player()
	player.stop()
	player.stream = null
	_current_id = &""
	_stop_count += 1
