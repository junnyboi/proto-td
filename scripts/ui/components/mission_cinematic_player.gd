class_name MissionCinematicPlayer
extends Control

## Full-screen presentation-only mission prologue. It owns no campaign data and
## always resolves terminal exactly once so media can never block Field Team.

signal terminal(stage_id: StringName, reason: StringName)

const CatalogType := preload("res://data/presentation/cinematics/mission_cinematic_catalog.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const COMPLETION_GRACE_SECONDS := 0.15

var _stage_id: StringName = &""
var _record: MissionCinematicRecord = null
var _poster: TextureRect = null
var _video: VideoStreamPlayer = null
var _ambience: AudioStreamPlayer = null
var _action: Button = null
var _status: Label = null
var _progress: ProgressBar = null
var _watchdog: Timer = null
var _prefetch: Node = null
var _i18n: Node = null
var _terminal_emitted := false
var _completed := false
var _playback_started := false
var _music_was_enabled := false
var _music_cue_before: StringName = &""
var _music_suspended := false
var _status_mode: StringName = &"loading"
var _status_percent := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	z_index = 1000
	_build_ui()
	_prefetch = get_node_or_null("/root/MissionCinematicPrefetch")
	_i18n = get_node_or_null("/root/I18n")
	if _prefetch != null:
		_prefetch.stage_ready.connect(_on_stage_ready)
		_prefetch.stage_progress.connect(_on_stage_progress)
		_prefetch.stage_error.connect(_on_stage_error)
	if _i18n != null and not _i18n.locale_changed.is_connected(_on_locale_changed):
		_i18n.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_fit_media)
	_refresh_copy()


func _exit_tree() -> void:
	_stop_media()
	_restore_music()
	if not _terminal_emitted:
		_emit_terminal(&"scene_exit")


func present(stage_id: StringName) -> void:
	_stage_id = stage_id
	_record = CatalogType.record_for(stage_id)
	_terminal_emitted = false
	_completed = false
	_playback_started = false
	if _record == null or not ResourceLoader.exists(_record.poster_path):
		_emit_terminal(&"failure")
		return
	_poster.texture = load(_record.poster_path) as Texture2D
	_poster.visible = true
	_fit_media()
	_set_action_mode(false)
	_action.grab_focus.call_deferred()
	if bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)):
		_status_mode = &"reduced"
		_set_action_mode(true)
		_refresh_copy()
		_emit_terminal.call_deferred(&"reduced_motion")
		return
	_status_mode = &"loading"
	_refresh_copy()
	if _prefetch == null:
		_set_fallback_and_finish(&"failure")
		return
	var ready_now := bool(_prefetch.call("request_stage", stage_id, true))
	if ready_now:
		_start_video(String(_prefetch.call("cached_stage_path", stage_id)))


func finish_for_test(reason: StringName = &"completion") -> void:
	_emit_terminal(reason)


func terminal_emitted() -> bool:
	return _terminal_emitted


func stage_id() -> StringName:
	return _stage_id


func action_button() -> Button:
	return _action


func status_label() -> Label:
	return _status


func video_player() -> VideoStreamPlayer:
	return _video


func poster() -> TextureRect:
	return _poster


func ambience_player() -> AudioStreamPlayer:
	return _ambience


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_action_pressed()


func _build_ui() -> void:
	var blackout := ColorRect.new()
	blackout.name = "MissionCinematicBlackout"
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("03070c")
	blackout.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blackout)

	_poster = TextureRect.new()
	_poster.name = "MissionCinematicPoster"
	_poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_poster.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_poster)

	_video = VideoStreamPlayer.new()
	_video.name = "MissionCinematicVideo"
	_video.autoplay = false
	_video.loop = false
	_video.expand = true
	_video.volume_db = -80.0
	_video.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_video.finished.connect(_on_video_finished)
	add_child(_video)

	_ambience = AudioStreamPlayer.new()
	_ambience.name = "MissionCinematicAmbience"
	_ambience.bus = &"Master"
	_ambience.finished.connect(_on_ambience_finished)
	add_child(_ambience)

	var controls := MarginContainer.new()
	controls.name = "MissionCinematicControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		controls.add_theme_constant_override(side, 24)
	add_child(controls)

	var layout := VBoxContainer.new()
	layout.name = "MissionCinematicControlLayout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_child(layout)

	var action_row := HBoxContainer.new()
	action_row.name = "MissionCinematicActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(action_row)

	_action = Button.new()
	_action.name = "MissionCinematicAction"
	_action.custom_minimum_size = Vector2(160.0, 64.0)
	_action.focus_mode = Control.FOCUS_ALL
	_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Style.apply_compact_rounded_button(_action, &"primary")
	_action.pressed.connect(_on_action_pressed)
	action_row.add_child(_action)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var status_center := CenterContainer.new()
	status_center.name = "MissionCinematicStatusCenter"
	status_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(status_center)
	var status_panel := PanelContainer.new()
	status_panel.name = "MissionCinematicStatusPanel"
	status_panel.custom_minimum_size = Vector2(360.0, 72.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.008, 0.025, 0.042, 0.88)
	panel_style.border_color = Color(Style.GOLD, 0.58)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 24
	status_panel.add_theme_stylebox_override(&"panel", panel_style)
	status_center.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override(&"separation", 6)
	status_panel.add_child(status_box)
	_status = Label.new()
	_status.name = "MissionCinematicStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.accessibility_live = AccessibilityServer.LIVE_POLITE
	Style.apply_label(_status, &"detail")
	status_box.add_child(_status)
	_progress = ProgressBar.new()
	_progress.name = "MissionCinematicProgress"
	_progress.custom_minimum_size.y = 6.0
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.show_percentage = false
	_progress.indeterminate = true
	status_box.add_child(_progress)

	_watchdog = Timer.new()
	_watchdog.name = "MissionCinematicWatchdog"
	_watchdog.one_shot = true
	_watchdog.timeout.connect(_on_watchdog_timeout)
	add_child(_watchdog)
	_fit_media()


func _fit_media() -> void:
	if _poster == null or _video == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var source_aspect := 16.0 / 9.0
	var viewport_aspect := viewport_size.x / viewport_size.y
	var fitted := Vector2(viewport_size.x, viewport_size.x / source_aspect) if viewport_aspect > source_aspect else Vector2(viewport_size.y * source_aspect, viewport_size.y)
	var position := (viewport_size - fitted) * 0.5
	_poster.position = position
	_poster.size = fitted
	_video.position = position
	_video.size = fitted


func _start_video(path: String) -> void:
	if _terminal_emitted or _record == null or path.is_empty():
		return
	var stream: VideoStream = null
	if path.begins_with("res://"):
		stream = load(path) as VideoStream
	elif FileAccess.file_exists(path):
		var theora := VideoStreamTheora.new()
		theora.file = path
		stream = theora
	if stream == null:
		_set_fallback_and_finish(&"failure")
		return
	_suspend_music()
	_video.stream = stream
	_video.visible = true
	_video.play()
	_poster.visible = false
	_playback_started = true
	_status_mode = &"playing"
	_progress.indeterminate = false
	_progress.value = 100.0
	if ResourceLoader.exists(_record.ambience.path):
		_ambience.stream = load(_record.ambience.path) as AudioStream
		if _ambience.stream != null:
			_ambience.play()
	_watchdog.start(minf(_record.video.duration_seconds, 8.0) + COMPLETION_GRACE_SECONDS)
	_refresh_copy()


func _on_stage_ready(stage_id: StringName, playable_path: String) -> void:
	if stage_id == _stage_id and not _terminal_emitted:
		_start_video(playable_path)


func _on_stage_progress(stage_id: StringName, state: StringName, current: int, total: int) -> void:
	if stage_id != _stage_id or _terminal_emitted:
		return
	if state == &"queued" or state == &"downloading":
		_status_mode = &"loading"
		_status_percent = int(clampf(float(current) / float(total), 0.0, 1.0) * 100.0) if total > 0 else 0
		_progress.indeterminate = total <= 0
		_progress.value = _status_percent
		_refresh_copy()


func _on_stage_error(stage_id: StringName, _reason: String) -> void:
	if stage_id == _stage_id and not _terminal_emitted:
		_set_fallback_and_finish(&"failure")


func _set_fallback_and_finish(reason: StringName) -> void:
	_stop_media()
	_poster.visible = true
	_status_mode = &"offline"
	_progress.indeterminate = false
	_progress.value = 0.0
	_set_action_mode(true)
	_refresh_copy()
	_emit_terminal.call_deferred(reason)


func _on_video_finished() -> void:
	if _playback_started:
		_complete()


func _on_ambience_finished() -> void:
	# Video timing remains authoritative; ambience is allowed to be slightly short.
	pass


func _on_watchdog_timeout() -> void:
	if _playback_started:
		_complete()


func _complete() -> void:
	if _completed or _terminal_emitted:
		return
	_completed = true
	_stop_media()
	_poster.visible = true
	_status_mode = &"complete"
	_set_action_mode(true)
	_refresh_copy()
	_emit_terminal(&"completion")


func _on_action_pressed() -> void:
	_emit_terminal(&"completion" if _completed else &"skip")


func _emit_terminal(reason: StringName) -> void:
	if _terminal_emitted:
		return
	_terminal_emitted = true
	_stop_media()
	_restore_music()
	terminal.emit(_stage_id, reason)


func _stop_media() -> void:
	_playback_started = false
	if _watchdog != null:
		_watchdog.stop()
	if _video != null:
		_video.stop()
		_video.stream = null
		_video.visible = false
	if _ambience != null:
		_ambience.stop()
		_ambience.stream = null


func _suspend_music() -> void:
	if _music_suspended:
		return
	var music := get_node_or_null("/root/Music")
	if music == null:
		return
	_music_was_enabled = bool(music.call("is_enabled"))
	_music_cue_before = StringName(music.call("current_id"))
	if not _music_cue_before.is_empty():
		music.call("stop")
	_music_suspended = true


func _restore_music() -> void:
	if not _music_suspended:
		return
	var music := get_node_or_null("/root/Music")
	if music != null and _music_was_enabled and not _music_cue_before.is_empty():
		music.call("play_cue", _music_cue_before)
	_music_suspended = false
	_music_cue_before = &""


func _set_action_mode(continue_mode: bool) -> void:
	if _action == null:
		return
	_action.set_meta(&"continue_mode", continue_mode)
	_refresh_copy()


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_copy()


func _refresh_copy() -> void:
	if _action == null or _status == null:
		return
	var continue_mode := bool(_action.get_meta(&"continue_mode", false))
	_action.text = UiCopyType.text(
		&"ui.mission_cinematic.continue" if continue_mode else &"ui.mission_cinematic.skip",
		"Continue" if continue_mode else "Skip",
	)
	_action.accessibility_name = UiCopyType.text(
		&"ui.mission_cinematic.continue_accessibility" if continue_mode else &"ui.mission_cinematic.skip_accessibility",
		"Continue to Field Team" if continue_mode else "Skip mission cinematic",
	)
	if _status_mode == &"offline":
		_status.text = UiCopyType.text(&"ui.mission_cinematic.offline", "Cinematic unavailable · poster fallback active")
	elif _status_mode == &"reduced":
		_status.text = UiCopyType.text(&"ui.mission_cinematic.reduced_motion", "Reduced Motion · poster fallback active")
	elif _status_mode == &"playing":
		_status.text = UiCopyType.text(&"ui.mission_cinematic.playing", "Mission cinematic playing")
	elif _status_mode == &"complete":
		_status.text = UiCopyType.text(&"ui.mission_cinematic.complete", "Mission cinematic complete")
	else:
		_status.text = UiCopyType.format_text(
			&"ui.mission_cinematic.loading",
			"Loading mission cinematic · {percent}%",
			{&"percent": _status_percent},
		)
	accessibility_name = UiCopyType.text(&"ui.mission_cinematic.accessibility_name", "Mission cinematic")
	accessibility_description = _status.text
