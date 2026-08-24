extends Node

## Sole runtime SFX owner. Playback is alias-resolved, deduplicated per render
## frame, and remains presentation-only.

const CATALOG_PATH := "res://assets/sfx/catalog.tres"
const SFX_CATALOG_SCRIPT: GDScript = preload("res://assets/sfx/sfx_catalog.gd")
const VOICE_COUNT := 8
const PLAYER_PREFIX := "Voice"

var _catalog: Resource = null
var _players: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _audible_start_count := 0
var _dedupe_count := 0
var _last_raw_id := &""
var _last_resolved_id := &""
var _last_stream_path := ""
var _last_started_frame_by_id: Dictionary = {}


func _ready() -> void:
	reload_catalog()
	_ensure_players()


func reload_catalog() -> bool:
	var loaded := load(CATALOG_PATH) as Resource
	if not _catalog_contract_valid(loaded):
		_catalog = null
		return false
	_catalog = loaded
	return true


func _catalog_contract_valid(loaded: Resource) -> bool:
	if loaded == null or loaded.get_script() != SFX_CATALOG_SCRIPT:
		return false
	var entries_value: Variant = loaded.get("entries")
	var aliases_value: Variant = loaded.get("aliases")
	if not entries_value is Dictionary or not aliases_value is Dictionary:
		return false
	var entries: Dictionary = entries_value
	var aliases: Dictionary = aliases_value
	if entries.is_empty():
		return false
	return _entries_contract_valid(entries) and _aliases_contract_valid(entries, aliases)


func _entries_contract_valid(entries: Dictionary) -> bool:
	for raw_id: Variant in entries:
		if typeof(raw_id) != TYPE_STRING_NAME or StringName(raw_id).is_empty():
			return false
		if not entries[raw_id] is Dictionary:
			return false
	return true


func _aliases_contract_valid(entries: Dictionary, aliases: Dictionary) -> bool:
	for raw_id: Variant in aliases:
		var target: Variant = aliases[raw_id]
		if (
			typeof(raw_id) != TYPE_STRING_NAME
			or typeof(target) != TYPE_STRING_NAME
			or not entries.has(target)
		):
			return false
	return true


## A true return means one AudioStreamPlayer started.
func play(id: String) -> bool:
	var raw_id := StringName(id)
	if raw_id.is_empty():
		return false
	var resolved_id := resolved_id_for(raw_id)
	if resolved_id.is_empty():
		return false
	var frame := Engine.get_process_frames()
	if int(_last_started_frame_by_id.get(resolved_id, -1)) == frame:
		_dedupe_count += 1
		return false
	var stream := _stream_for(resolved_id)
	if stream == null:
		return false
	var players := _ensure_players()
	var player := players[_voice_cursor]
	player.stop()
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()
	_voice_cursor = (_voice_cursor + 1) % VOICE_COUNT
	_audible_start_count += 1
	_last_raw_id = raw_id
	_last_resolved_id = resolved_id
	_last_stream_path = stream.resource_path
	_last_started_frame_by_id[resolved_id] = frame
	return true


func _stream_for(resolved_id: StringName) -> AudioStream:
	var entries_value: Variant = _catalog.get("entries") if _catalog != null else null
	if not entries_value is Dictionary or not entries_value.has(resolved_id):
		return null
	var entries: Dictionary = entries_value
	var entry: Dictionary = entries[resolved_id]
	return load(String(entry.get("path", ""))) as AudioStream


func resolved_id_for(raw_id: StringName) -> StringName:
	if _catalog == null and not reload_catalog():
		return &""
	var entries_value: Variant = _catalog.get("entries")
	var aliases_value: Variant = _catalog.get("aliases")
	if not entries_value is Dictionary or not aliases_value is Dictionary:
		return &""
	var entries: Dictionary = entries_value
	var aliases: Dictionary = aliases_value
	if entries.has(raw_id):
		return raw_id
	var target: Variant = aliases.get(raw_id, &"")
	if typeof(target) == TYPE_STRING_NAME and entries.has(target):
		return target
	return &""


func stop_all() -> bool:
	var stopped := false
	for player: AudioStreamPlayer in _ensure_players():
		if player.stream != null:
			stopped = true
		player.stop()
		player.stream = null
	return stopped


func catalog_entry_count() -> int:
	if _catalog == null and not reload_catalog():
		return 0
	var entries_value: Variant = _catalog.get("entries")
	return entries_value.size() if entries_value is Dictionary else 0


func player_count() -> int:
	var count := 0
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count


func assigned_voice_count() -> int:
	var count := 0
	for player: AudioStreamPlayer in _ensure_players():
		if player.stream != null:
			count += 1
	return count


func audible_start_count() -> int:
	return _audible_start_count


func dedupe_count() -> int:
	return _dedupe_count


func last_raw_id() -> StringName:
	return _last_raw_id


func last_resolved_id() -> StringName:
	return _last_resolved_id


func last_stream_path() -> String:
	return _last_stream_path


func _ensure_players() -> Array[AudioStreamPlayer]:
	if _players.size() == VOICE_COUNT:
		var all_valid := true
		for player: AudioStreamPlayer in _players:
			if not is_instance_valid(player):
				all_valid = false
				break
		if all_valid:
			return _players
	_players.clear()
	for index: int in VOICE_COUNT:
		var player := get_node_or_null("%s%d" % [PLAYER_PREFIX, index]) as AudioStreamPlayer
		if player == null:
			player = AudioStreamPlayer.new()
			player.name = "%s%d" % [PLAYER_PREFIX, index]
			add_child(player)
		_players.append(player)
	return _players
