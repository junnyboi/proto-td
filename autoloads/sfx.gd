extends Node

## SFX resolution + playback (Phase 9, td-phase-9.md §3.3). Wiring is the
## gate: play(id) emits the sfx_played Telemetry event UNCONDITIONALLY and
## first — the audio behind it is the payload (§1.4 C1: the per-frame
## throttle applies to audio playback only, never the event, so event
## counts equal call counts exactly). Resolution: ALIASES maps spell ids to
## their sounds; every skill id (scanned from data/skills) maps to the one
## sting; anything else resolves to its own file name. A missing file warns
## once per id and never crashes (the headless dummy audio driver plays
## nothing anyway). Manifest indirection is deferred to Lane A (§2.1.5).

const SFX_DIR := "res://assets/sfx"
const POOL_SIZE := 8
const ALIASES := {"bolt": "bolt_zap", "charm": "charm_chime"}

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _streams: Dictionary = {}
var _skill_ids: Dictionary = {}
var _warned: Dictionary = {}
var _last_audio_frame: Dictionary = {}


func _ready() -> void:
	for _i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	var dir := DirAccess.open("res://data/skills")
	if dir != null:
		for file: String in dir.get_files():
			if file.ends_with(".tres"):
				_skill_ids[file.trim_suffix(".tres")] = true


func play(id: String) -> void:
	Telemetry.event("sfx_played", {"id": id})
	var resolved: String = ALIASES.get(id, "sting" if _skill_ids.has(id) else id)
	var frame := Engine.get_process_frames()
	if int(_last_audio_frame.get(resolved, -1)) == frame:
		return
	_last_audio_frame[resolved] = frame
	var stream := _stream_for(resolved)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = stream
	player.play()


func _stream_for(resolved: String) -> AudioStream:
	if _streams.has(resolved):
		return _streams[resolved]
	var path := "%s/%s.wav" % [SFX_DIR, resolved]
	if not ResourceLoader.exists(path):
		if not _warned.has(resolved):
			_warned[resolved] = true
			push_warning("sfx: no wav for '%s' (%s)" % [resolved, path])
		_streams[resolved] = null
		return null
	_streams[resolved] = load(path)
	return _streams[resolved]
