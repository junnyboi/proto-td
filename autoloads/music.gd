extends Node

## Sole runtime music owner. Playback is presentation-only: it never enters the
## deterministic BattleModel, state hash, save data, or replay. A single player
## hard-replaces cues because the approved contract forbids layering.

const CATALOG_PATH := "res://assets/music/catalog.tres"
const MUSIC_CATALOG_SCRIPT: GDScript = preload("res://assets/music/music_catalog.gd")
const PLAYER_NAME := "Player"

var _catalog: Resource = null
var _player: AudioStreamPlayer = null
var _current_id: StringName = &""
var _start_count := 0
var _stop_count := 0
var _active_battle_instance_id := 0


func _ready() -> void:
	reload_catalog()
	_ensure_player()


func _process(_delta: float) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var battle := game.get("current_battle") as BattleModel
	var content := game.get("content") as Node
	if battle == null or content == null or not is_instance_valid(content) or not content is Node2D:
		_active_battle_instance_id = 0
		return
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
	var stream := load(String(entry.get("path", ""))) as AudioStream
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
	if _current_id.is_empty():
		return false
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


func _cue_id(act: int, role: StringName) -> StringName:
	if act < 1 or act > 3 or role not in [&"bgm", &"boss"]:
		return &""
	return StringName("act_%d_%s" % [act, role])


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
