class_name ArchiveAudioLogPlayer
extends PanelContainer

## Interactive, localized lore narration. Playback is presentation-only and uses
## the existing SFX bus so the player's audio preferences remain authoritative.

const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")

const STREAMS := {
	&"en-US": {
		&"stewardship": preload("res://assets/audio/narrative/mercy-archive/en-US/stewardship.ogg"),
		&"choir": preload("res://assets/audio/narrative/mercy-archive/en-US/choir.ogg"),
		&"equation": preload("res://assets/audio/narrative/mercy-archive/en-US/equation.ogg"),
		&"garden": preload("res://assets/audio/narrative/mercy-archive/en-US/garden.ogg"),
	},
	&"zh-CN": {
		&"stewardship": preload("res://assets/audio/narrative/mercy-archive/zh-CN/stewardship.ogg"),
		&"choir": preload("res://assets/audio/narrative/mercy-archive/zh-CN/choir.ogg"),
		&"equation": preload("res://assets/audio/narrative/mercy-archive/zh-CN/equation.ogg"),
		&"garden": preload("res://assets/audio/narrative/mercy-archive/zh-CN/garden.ogg"),
	},
}

var _entry_id := &""
var _player: AudioStreamPlayer = null
var _play_pause: AetheriaButtonType = null
var _restart: AetheriaButtonType = null
var _seek: HSlider = null
var _status: AetheriaLabelType = null
var _time: AetheriaLabelType = null
var _syncing_seek := false
var _completed := false
var _i18n: Node = null


func _ready() -> void:
	name = "ArchiveAudioLog"
	custom_minimum_size.y = 128.0
	Style.apply_panel(self, &"quiet")
	_build_ui()
	set_process(true)
	_i18n = get_node_or_null("/root/I18n")
	if _i18n != null and not _i18n.is_connected(&"locale_changed", _on_locale_changed):
		_i18n.connect(&"locale_changed", _on_locale_changed)


func _build_ui() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "ArchiveNarrationPlayer"
	_player.bus = &"SFX"
	_player.finished.connect(_on_finished)
	add_child(_player)

	var column := VBoxContainer.new()
	column.name = "AudioLogContent"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)

	var header := HBoxContainer.new()
	header.name = "AudioLogHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override(&"separation", 12)
	column.add_child(header)
	var title := _label("AudioLogTitle", UiCopyType.text(&"ui.archive.audio.title", "INTERACTIVE AUDIO LOG"), &"dense_heading")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_status = _label("AudioLogStatus", "", &"dense_detail")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_status)

	_seek = HSlider.new()
	_seek.name = "AudioLogSeek"
	_seek.min_value = 0.0
	_seek.max_value = 1.0
	_seek.step = 0.05
	_seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seek.focus_mode = Control.FOCUS_ALL
	_seek.tooltip_text = UiCopyType.text(&"ui.archive.audio.seek", "Audio log position")
	_seek.accessibility_name = _seek.tooltip_text
	_seek.value_changed.connect(_on_seek_changed)
	column.add_child(_seek)

	var controls := HBoxContainer.new()
	controls.name = "AudioLogControls"
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override(&"separation", 10)
	column.add_child(controls)

	_play_pause = AetheriaButtonType.new()
	_play_pause.name = "AudioLogPlayPause"
	_play_pause.custom_minimum_size = Vector2(190.0, 52.0)
	_play_pause.apply_role(&"primary")
	_play_pause.pressed.connect(_on_play_pause)
	controls.add_child(_play_pause)

	_restart = AetheriaButtonType.new()
	_restart.name = "AudioLogRestart"
	_restart.custom_minimum_size = Vector2(170.0, 52.0)
	_restart.apply_role(&"secondary")
	_restart.pressed.connect(_on_restart)
	controls.add_child(_restart)

	_time = _label("AudioLogTime", "0:00 / 0:00", &"dense_detail")
	_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(_time)
	_refresh_copy()


func _label(node_name: String, text_value: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = node_name
	label.text = text_value
	label.apply_role(role)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func set_entry(entry_id: StringName) -> bool:
	if not STREAMS[&"en-US"].has(entry_id):
		return false
	_entry_id = entry_id
	_completed = false
	_player.stop()
	_player.stream_paused = false
	var locale_id := StringName(_i18n.call("locale")) if _i18n != null else &"en-US"
	_player.stream = _stream_for_locale(locale_id, entry_id)
	var length := _stream_length()
	_syncing_seek = true
	_seek.max_value = maxf(length, 1.0)
	_seek.value = 0.0
	_syncing_seek = false
	_refresh_copy()
	_refresh_time(0.0)
	return _player.stream != null


func _stream_for_locale(locale_id: StringName, entry_id: StringName) -> AudioStream:
	var locale_streams: Dictionary = STREAMS.get(locale_id, STREAMS[&"en-US"])
	return locale_streams.get(entry_id) as AudioStream


func _on_play_pause() -> void:
	if _player.stream == null:
		return
	_play_sfx(&"ui_confirm")
	if _player.playing and not _player.stream_paused:
		_player.stream_paused = true
	elif _player.stream_paused:
		_player.stream_paused = false
	else:
		_completed = false
		_player.play(0.0)
	_refresh_copy()


func _on_restart() -> void:
	if _player.stream == null:
		return
	_play_sfx(&"ui_click")
	_completed = false
	_player.stream_paused = false
	_player.play(0.0)
	_refresh_copy()


func _on_seek_changed(value: float) -> void:
	if _syncing_seek or _player.stream == null:
		return
	_completed = false
	_player.seek(clampf(value, 0.0, _stream_length()))
	_refresh_time(value)


func _process(_delta: float) -> void:
	if _player == null or _player.stream == null:
		return
	var position := _player.get_playback_position() if _player.playing else (0.0 if not _completed else _stream_length())
	_syncing_seek = true
	_seek.value = clampf(position, 0.0, _stream_length())
	_syncing_seek = false
	_refresh_time(position)
	_refresh_copy()


func _on_finished() -> void:
	_completed = true
	_player.stream_paused = false
	_syncing_seek = true
	_seek.value = _stream_length()
	_syncing_seek = false
	_refresh_time(_stream_length())
	_refresh_copy()


func _refresh_copy() -> void:
	if _play_pause == null:
		return
	var can_play := _player != null and _player.stream != null
	_play_pause.disabled = not can_play
	_restart.disabled = not can_play
	_seek.editable = can_play
	var paused := can_play and _player.stream_paused
	var playing := can_play and _player.playing and not paused
	var play_text := UiCopyType.text(
		&"ui.archive.audio.pause" if playing else &"ui.archive.audio.play",
		"Pause narration" if playing else "Play audio log",
	)
	_play_pause.text = play_text
	_play_pause.set_presentation_text(play_text, play_text.to_upper())
	_play_pause.tooltip_text = play_text
	_play_pause.accessibility_name = play_text
	var restart_text := UiCopyType.text(&"ui.archive.audio.restart", "Restart")
	_restart.text = restart_text
	_restart.set_presentation_text(restart_text, restart_text.to_upper())
	_restart.tooltip_text = restart_text
	_restart.accessibility_name = restart_text
	if not can_play:
		_status.text = UiCopyType.text(&"ui.archive.audio.unavailable", "VOICE RECORD UNAVAILABLE")
	elif playing:
		_status.text = UiCopyType.text(&"ui.archive.audio.playing", "ARCHIVE CASTER // NARRATING")
	elif paused:
		_status.text = UiCopyType.text(&"ui.archive.audio.paused", "NARRATION PAUSED")
	elif _completed:
		_status.text = UiCopyType.text(&"ui.archive.audio.complete", "LOG COMPLETE")
	else:
		_status.text = UiCopyType.text(&"ui.archive.audio.ready", "VOICE RECORD READY")


func _refresh_time(position: float) -> void:
	if _time == null:
		return
	_time.text = UiCopyType.format_text(
		&"ui.archive.audio.time",
		"{current} / {total}",
		{&"current": _clock(position), &"total": _clock(_stream_length())},
	)


func _clock(seconds: float) -> String:
	var rounded := maxi(floori(maxf(seconds, 0.0)), 0)
	return "%d:%02d" % [floori(float(rounded) / 60.0), rounded % 60]


func _stream_length() -> float:
	return _player.stream.get_length() if _player != null and _player.stream != null else 0.0


func _play_sfx(cue_id: StringName) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", cue_id)


func _on_locale_changed(locale_id: StringName) -> void:
	if _entry_id.is_empty():
		_refresh_copy()
		return
	var was_playing := _player.playing and not _player.stream_paused
	set_entry(_entry_id)
	if was_playing:
		_player.play(0.0)
	_refresh_copy()


func entry_id() -> StringName:
	return _entry_id


func stream_path() -> String:
	return _player.stream.resource_path if _player != null and _player.stream != null else ""


func duration_seconds() -> float:
	return _stream_length()


func playback_position() -> float:
	return _player.get_playback_position() if _player != null and _player.playing else 0.0


func narration_playing() -> bool:
	return _player != null and _player.playing and not _player.stream_paused


func focus_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for control: Control in [_play_pause, _restart, _seek]:
		if control != null:
			controls.append(control)
	return controls


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
	if _i18n != null and _i18n.is_connected(&"locale_changed", _on_locale_changed):
		_i18n.disconnect(&"locale_changed", _on_locale_changed)
