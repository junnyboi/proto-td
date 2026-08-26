extends Control
class_name GachaCinematicPlayer

## Presentation-only Premium Resonance media owner. Gameplay state remains in gacha.gd.
## Web exports omit the heavy Ogg Theora streams from the base PCK. The active
## orientation is downloaded on demand, verified, cached in user://, and played
## through VideoStreamTheora. Native/editor builds retain the bundled fallback.

signal cinematic_started(music_id: StringName)
signal cinematic_finished
signal cinematic_failed(stream_key: StringName, reason: String)
signal stream_state_changed(stream_key: StringName, state: StringName, current: int, total: int)

const STREAM_ARG_PREFIX := "--cinematic-stream="
const CACHE_DIR := "user://cinematic-streams"
const COPY_CHUNK_BYTES := 1024 * 1024
const DOWNLOAD_TIMEOUT_SECONDS := 75.0
const FIRST_CYCLE_SECONDS := 8.0
const PLATE_HOVER_SCALE := 1.025
const PLATE_HOVER_RESPONSE := 12.0
const PLATE_HOVER_PARALLAX := Vector2(12.0, 8.0)
const PLATE_HOVER_TINT := Color(1.055, 1.035, 1.0, 1.0)

const STREAMS := {
	"lunaris-vessel-landscape": {
		"bundled_path": "res://assets/cinematics/gacha/video/lunaris-vessel-landscape.ogv",
		"bytes": 1257821,
		"sha256": "38361f28ba7c40e8e95c5aa59919028b0d181d97bd6b7f58f01fd7a31deb59cd",
	},
	"lunaris-vessel-portrait": {
		"bundled_path": "res://assets/cinematics/gacha/video/lunaris-vessel-portrait.ogv",
		"bytes": 2502584,
		"sha256": "cd806d989623cbce1180df154efe892aaf8c2b047cee07906ec330f55c6fb6bb",
	},
	"reliquary-duelist-landscape": {
		"bundled_path": "res://assets/cinematics/gacha/video/reliquary-duelist-landscape.ogv",
		"bytes": 1395676,
		"sha256": "cfa5bdab1002b428347e4d2d46cd0517acfc876a3460693d7330c8abb0e90151",
	},
	"reliquary-duelist-portrait": {
		"bundled_path": "res://assets/cinematics/gacha/video/reliquary-duelist-portrait.ogv",
		"bytes": 2090359,
		"sha256": "ed78d0f92c19dc253a47454e13bb411fed64514f768c3db2157e5deb15b9026c",
	},
	"archive-caster-landscape": {
		"bundled_path": "res://assets/cinematics/gacha/video/archive-caster-landscape.ogv",
		"bytes": 778793,
		"sha256": "bcb3251e11269027b49a332487964db64fb8e6fe83358c2bb1b78317558c55af",
	},
	"archive-caster-portrait": {
		"bundled_path": "res://assets/cinematics/gacha/video/archive-caster-portrait.ogv",
		"bytes": 2452205,
		"sha256": "dd09537610bb5bc0ed7fd2ed6715e4d6b870dce521075b1defe77c6bc6ee0c0f",
	},
}

const PROFILES := {
	"lunaris_vessel": {
		"landscape_stream": "lunaris-vessel-landscape",
		"portrait_stream": "lunaris-vessel-portrait",
		"landscape_final": "res://assets/cinematics/gacha/posters/lunaris-vessel-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/lunaris-vessel-portrait.webp",
		"music_id": &"gacha_lunaris_vessel",
	},
	"reliquary_duelist": {
		"landscape_stream": "reliquary-duelist-landscape",
		"portrait_stream": "reliquary-duelist-portrait",
		"landscape_final": "res://assets/cinematics/gacha/posters/reliquary-duelist-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/reliquary-duelist-portrait.webp",
		"music_id": &"gacha_reliquary_duelist",
	},
	"archive_caster": {
		"landscape_stream": "archive-caster-landscape",
		"portrait_stream": "archive-caster-portrait",
		"landscape_final": "res://assets/cinematics/gacha/posters/archive-caster-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/archive-caster-portrait.webp",
		"music_id": &"gacha_archive_caster",
	},
}

var _video: VideoStreamPlayer
var _final_plate: TextureRect
var _status_panel: PanelContainer
var _status_label: Label
var _status_progress: ProgressBar
var _portrait_orientation := false
var _active_profile: Dictionary = {}
var _active_stream_key := ""
var _allow_video_start := false
var _playback_active := false
var _reduced_motion := false
var _plate_hovered := false
var _plate_hover_target_scale := Vector2.ONE
var _plate_hover_target_offset := Vector2.ZERO
var _plate_hover_target_tint := Color.WHITE
var _first_cycle_complete := false
var _first_cycle_timer: Timer

var _stream_urls: Dictionary = {}
var _request: HTTPRequest
var _download_key := ""
var _download_temp_path := ""
var _download_total := 0
var _last_progress_bytes := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_layers()
	configure_streams(OS.get_cmdline_user_args())
	get_viewport().size_changed.connect(_fit_current_viewport)
	_fit_current_viewport()
	set_process(true)


func configure_streams(arguments: PackedStringArray) -> void:
	_stream_urls.clear()
	for argument: String in arguments:
		if not argument.begins_with(STREAM_ARG_PREFIX):
			continue
		var payload := argument.substr(STREAM_ARG_PREFIX.length())
		var separator := payload.find("|")
		if separator <= 0 or separator >= payload.length() - 1:
			continue
		var stream_key := payload.substr(0, separator)
		var url := payload.substr(separator + 1)
		if STREAMS.has(stream_key) and (url.begins_with("https://") or url.begins_with("http://")):
			_stream_urls[stream_key] = url


func play_cinematic(premium_id: String, reduced_motion: bool) -> bool:
	_stop_playback()
	_reduced_motion = reduced_motion
	_reset_final_plate_hover(true)
	var profile: Dictionary = PROFILES.get(premium_id, {})
	_active_profile = profile.duplicate()
	if _active_profile.is_empty():
		return false
	_portrait_orientation = get_viewport_rect().size.x < 900.0
	var orientation := "portrait" if _portrait_orientation else "landscape"
	var final_path := String(_active_profile.get("%s_final" % orientation, ""))
	_final_plate.texture = null
	if ResourceLoader.exists(final_path):
		_final_plate.texture = load(final_path) as Texture2D
	_final_plate.visible = true
	_fit_current_viewport()
	if reduced_motion:
		return false
	_active_stream_key = String(_active_profile.get("%s_stream" % orientation, ""))
	_allow_video_start = true
	if _active_stream_key.is_empty() or not STREAMS.has(_active_stream_key):
		_fail_active("Cinematic identity is unavailable.")
		return false
	if _stream_urls.has(_active_stream_key):
		var cached_path := _validated_cache_path(_active_stream_key)
		if not cached_path.is_empty():
			return _start_file_stream(cached_path)
		_start_download(_active_stream_key)
		return false
	var bundled_path := String(STREAMS[_active_stream_key].get("bundled_path", ""))
	if bundled_path.is_empty() or not ResourceLoader.exists(bundled_path):
		_fail_active("Cinematic stream is not bundled and no remote source is configured.")
		return false
	var bundled_stream := load(bundled_path) as VideoStream
	if bundled_stream == null:
		_fail_active("Cinematic stream could not be opened.")
		return false
	return _start_stream(bundled_stream)


func show_final_plate() -> void:
	_allow_video_start = false
	_playback_active = false
	_first_cycle_complete = false
	if _first_cycle_timer != null:
		_first_cycle_timer.stop()
	if _video != null:
		_video.stop()
		_video.visible = false
	if _final_plate != null:
		_final_plate.visible = true


func stop() -> void:
	_allow_video_start = false
	_active_stream_key = ""
	_active_profile.clear()
	_reduced_motion = false
	_reset_final_plate_hover(true)
	_stop_playback()
	if _final_plate != null:
		_final_plate.visible = false
	if _download_key.is_empty():
		_set_status_visible(false)


func music_id() -> StringName:
	return StringName(_active_profile.get("music_id", &""))


func video_player() -> VideoStreamPlayer:
	return _video


func final_plate() -> TextureRect:
	return _final_plate


func final_plate_hovered() -> bool:
	return _plate_hovered


func hover_surface() -> Control:
	return _active_hover_surface()


func is_portrait_orientation() -> bool:
	return _portrait_orientation


func configured_stream_count() -> int:
	return _stream_urls.size()


func cached_stream_path(stream_key: String) -> String:
	return _validated_cache_path(stream_key)


func stream_url(stream_key: String) -> String:
	return String(_stream_urls.get(stream_key, ""))


func download_key() -> String:
	return _download_key


func _process(delta: float) -> void:
	if _request != null and not _download_key.is_empty():
		var downloaded := _request.get_downloaded_bytes()
		var total := _request.get_body_size()
		if total <= 0:
			total = _download_total
		if downloaded != _last_progress_bytes:
			_last_progress_bytes = downloaded
			_update_download_status(downloaded, total)
	_update_final_plate_hover(delta)


func _start_download(stream_key: String) -> void:
	if _download_key == stream_key and _request != null:
		_set_status_visible(true)
		return
	_cancel_download(true)
	var spec: Dictionary = STREAMS.get(stream_key, {})
	var url := String(_stream_urls.get(stream_key, ""))
	if spec.is_empty() or url.is_empty():
		_fail_active("Cinematic source is not configured.")
		return
	_ensure_cache_dir()
	_download_key = stream_key
	_download_total = int(spec.get("bytes", 0))
	_download_temp_path = "%s/.%s.part" % [CACHE_DIR, stream_key]
	if FileAccess.file_exists(_download_temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_download_temp_path))
	_request = HTTPRequest.new()
	_request.name = "CinematicDownload"
	_request.accept_gzip = false
	_request.body_size_limit = _download_total + COPY_CHUNK_BYTES
	_request.download_chunk_size = 256 * 1024
	# Emscripten's direct-to-file HTTP path can report success while leaving no
	# durable user:// record. Keep the Web body in memory, then write it through
	# FileAccess in _on_request_completed so verification and cache promotion use
	# the same filesystem API. Native builds retain streaming-to-disk behavior.
	if not OS.has_feature("web"):
		_request.download_file = _download_temp_path
	_request.timeout = DOWNLOAD_TIMEOUT_SECONDS
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)
	_last_progress_bytes = -1
	_update_download_status(0, _download_total)
	var error := _request.request(url)
	if error != OK:
		_fail_download("Request could not start (%s)." % error_string(error))


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
) -> void:
	var completed_key := _download_key
	var temp_path := _download_temp_path
	var spec: Dictionary = STREAMS.get(completed_key, {})
	var expected_bytes := int(spec.get("bytes", 0))
	var expected_sha := String(spec.get("sha256", ""))
	_dispose_request()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_cleanup_failed_download(temp_path)
		_fail_download("Download failed (result %d, HTTP %d)." % [result, response_code], completed_key)
		return
	if not FileAccess.file_exists(temp_path) and not body.is_empty():
		var fallback_file := FileAccess.open(temp_path, FileAccess.WRITE)
		if fallback_file != null:
			fallback_file.store_buffer(body)
			fallback_file.close()
	if not _verify_file(temp_path, expected_bytes, expected_sha):
		_cleanup_failed_download(temp_path)
		_fail_download("Downloaded cinematic failed size or SHA-256 verification.", completed_key)
		return
	var cache_path := _cache_path(completed_key)
	var playable_path := _promote_verified_file(temp_path, cache_path)
	if playable_path.is_empty():
		_cleanup_failed_download(temp_path)
		_fail_download("Verified cinematic could not be cached.", completed_key)
		return
	_download_key = ""
	_download_temp_path = ""
	_download_total = 0
	_set_status_visible(false)
	stream_state_changed.emit(StringName(completed_key), &"ready", expected_bytes, expected_bytes)
	if _allow_video_start and _active_stream_key == completed_key and not _active_profile.is_empty():
		_start_file_stream(playable_path)


func _start_file_stream(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		_fail_active("Cached cinematic is unavailable.")
		return false
	var runtime_stream := VideoStreamTheora.new()
	runtime_stream.file = path
	return _start_stream(runtime_stream)


func _start_stream(stream: VideoStream) -> bool:
	if stream == null or not _allow_video_start:
		return false
	_video.stream = stream
	_video.loop = true
	_video.visible = true
	_final_plate.visible = false
	_playback_active = true
	_first_cycle_complete = false
	_video.play()
	_first_cycle_timer.start(FIRST_CYCLE_SECONDS)
	var cue_id := music_id()
	cinematic_started.emit(cue_id)
	return true


func _stop_playback() -> void:
	_playback_active = false
	_first_cycle_complete = false
	if _first_cycle_timer != null:
		_first_cycle_timer.stop()
	if _video == null:
		return
	_video.stop()
	_video.stream = null
	_video.visible = false


func _on_video_finished() -> void:
	if not _playback_active:
		return
	# VideoStreamPlayer.loop should keep the stream alive. Some Theora backends
	# still report `finished` at the loop boundary, so restart defensively and
	# announce only the first completed cycle to the reveal controller.
	if _video != null and not _video.is_playing():
		_video.play()
	_complete_first_cycle()


func _on_first_cycle_elapsed() -> void:
	if _playback_active:
		_complete_first_cycle()


func _complete_first_cycle() -> void:
	if _first_cycle_complete:
		return
	_first_cycle_complete = true
	cinematic_finished.emit()


func _validated_cache_path(stream_key: String) -> String:
	if not STREAMS.has(stream_key):
		return ""
	var path := _cache_path(stream_key)
	var spec: Dictionary = STREAMS[stream_key]
	if _verify_file(path, int(spec.get("bytes", 0)), String(spec.get("sha256", ""))):
		return path
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return ""


func _cache_path(stream_key: String) -> String:
	var spec: Dictionary = STREAMS.get(stream_key, {})
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


func _cancel_download(remove_partial: bool) -> void:
	if _request != null:
		_request.cancel_request()
		_dispose_request()
	if remove_partial and not _download_temp_path.is_empty() and FileAccess.file_exists(_download_temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_download_temp_path))
	_download_key = ""
	_download_temp_path = ""
	_download_total = 0
	_last_progress_bytes = -1


func _dispose_request() -> void:
	if _request == null:
		return
	if _request.request_completed.is_connected(_on_request_completed):
		_request.request_completed.disconnect(_on_request_completed)
	_request.queue_free()
	_request = null


func _cleanup_failed_download(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail_download(reason: String, failed_key: String = "") -> void:
	var stream_key := failed_key if not failed_key.is_empty() else _download_key
	printerr("Cinematic stream '%s' failed: %s" % [stream_key, reason])
	_download_key = ""
	_download_temp_path = ""
	_download_total = 0
	_set_failure_status(reason)
	stream_state_changed.emit(StringName(stream_key), &"failed", 0, 0)
	cinematic_failed.emit(StringName(stream_key), reason)
	if _active_stream_key == stream_key:
		_final_plate.visible = true


func _fail_active(reason: String) -> void:
	printerr("Cinematic stream '%s' unavailable: %s" % [_active_stream_key, reason])
	_set_failure_status(reason)
	stream_state_changed.emit(StringName(_active_stream_key), &"failed", 0, 0)
	cinematic_failed.emit(StringName(_active_stream_key), reason)
	_final_plate.visible = true


func _update_download_status(current: int, total: int) -> void:
	_set_status_visible(true)
	var percent := int(clampf(float(current) / float(total), 0.0, 1.0) * 100.0) if total > 0 else 0
	_status_label.text = "RECEIVING CINEMATIC  //  %d%%" % percent
	_status_progress.indeterminate = total <= 0
	if total > 0:
		_status_progress.value = percent
	stream_state_changed.emit(StringName(_download_key), &"downloading", current, total)


func _set_failure_status(_reason: String) -> void:
	_set_status_visible(true)
	_status_label.text = "CINEMATIC OFFLINE  //  FINAL PLATE ACTIVE"
	_status_progress.indeterminate = false
	_status_progress.value = 0.0


func _set_status_visible(visible: bool) -> void:
	if _status_panel != null:
		_status_panel.visible = visible


func _build_layers() -> void:
	_video = VideoStreamPlayer.new()
	_video.name = "CinematicVideo"
	_video.autoplay = false
	_video.loop = true
	_video.expand = true
	_video.volume_db = -80.0
	_video.mouse_filter = Control.MOUSE_FILTER_PASS
	_video.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_video.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_video.visible = false
	_video.finished.connect(_on_video_finished)
	_video.mouse_entered.connect(_on_final_plate_mouse_entered)
	_video.mouse_exited.connect(_on_final_plate_mouse_exited)
	_video.gui_input.connect(_on_final_plate_gui_input)
	add_child(_video)

	_first_cycle_timer = Timer.new()
	_first_cycle_timer.name = "CinematicFirstCycleTimer"
	_first_cycle_timer.one_shot = true
	_first_cycle_timer.wait_time = FIRST_CYCLE_SECONDS
	_first_cycle_timer.timeout.connect(_on_first_cycle_elapsed)
	add_child(_first_cycle_timer)

	_final_plate = TextureRect.new()
	_final_plate.name = "CinematicFinalPlate"
	_final_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_final_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_final_plate.mouse_filter = Control.MOUSE_FILTER_PASS
	_final_plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_final_plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_final_plate.visible = false
	_final_plate.mouse_entered.connect(_on_final_plate_mouse_entered)
	_final_plate.mouse_exited.connect(_on_final_plate_mouse_exited)
	_final_plate.gui_input.connect(_on_final_plate_gui_input)
	add_child(_final_plate)

	_status_panel = PanelContainer.new()
	_status_panel.name = "CinematicStreamStatus"
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.055, 0.08, 0.9)
	panel_style.border_color = Color(0.73, 0.65, 0.39, 0.62)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
	panel_style.content_margin_left = 16
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 16
	panel_style.content_margin_bottom = 10
	_status_panel.add_theme_stylebox_override(&"panel", panel_style)
	add_child(_status_panel)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override(&"separation", 7)
	_status_panel.add_child(status_box)
	_status_label = Label.new()
	_status_label.name = "CinematicStreamLabel"
	_status_label.text = "RECEIVING CINEMATIC"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override(&"font_color", Color(0.92, 0.83, 0.55))
	_status_label.add_theme_font_size_override(&"font_size", 13)
	status_box.add_child(_status_label)
	_status_progress = ProgressBar.new()
	_status_progress.name = "CinematicStreamProgress"
	_status_progress.custom_minimum_size = Vector2(0, 5)
	_status_progress.show_percentage = false
	_status_progress.min_value = 0.0
	_status_progress.max_value = 100.0
	status_box.add_child(_status_progress)


func _fit_current_viewport() -> void:
	if _video == null or _final_plate == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var source_aspect := 9.0 / 16.0 if _portrait_orientation else 16.0 / 9.0
	var viewport_aspect := viewport_size.x / viewport_size.y
	var fitted_size: Vector2
	if viewport_aspect > source_aspect:
		fitted_size = Vector2(viewport_size.x, viewport_size.x / source_aspect)
	else:
		fitted_size = Vector2(viewport_size.y * source_aspect, viewport_size.y)
	var fitted_position := (viewport_size - fitted_size) * 0.5
	_video.position = fitted_position
	_video.size = fitted_size
	_video.pivot_offset = fitted_size * 0.5
	_final_plate.position = fitted_position
	_final_plate.size = fitted_size
	_final_plate.pivot_offset = fitted_size * 0.5
	if _status_panel != null:
		var panel_width := minf(460.0, maxf(280.0, viewport_size.x - 40.0))
		_status_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, 74.0)
		_status_panel.size = Vector2(panel_width, 58.0)


func _on_final_plate_mouse_entered() -> void:
	if _reduced_motion or _active_hover_surface() == null:
		return
	_plate_hovered = true
	_plate_hover_target_scale = Vector2.ONE * PLATE_HOVER_SCALE
	_plate_hover_target_tint = PLATE_HOVER_TINT


func _on_final_plate_mouse_exited() -> void:
	_reset_final_plate_hover(false)


func _on_final_plate_gui_input(event: InputEvent) -> void:
	var surface := _active_hover_surface()
	if (
			not _plate_hovered
			or _reduced_motion
			or not (event is InputEventMouseMotion)
			or surface == null
			or surface.size.x <= 0.0
			or surface.size.y <= 0.0
	):
		return
	var motion := event as InputEventMouseMotion
	var local_ratio: Vector2 = (motion.position / surface.size - Vector2(0.5, 0.5)) * 2.0
	_plate_hover_target_offset = Vector2(
		clampf(local_ratio.x, -1.0, 1.0) * -PLATE_HOVER_PARALLAX.x,
		clampf(local_ratio.y, -1.0, 1.0) * -PLATE_HOVER_PARALLAX.y,
	)


func _update_final_plate_hover(delta: float) -> void:
	var surface := _active_hover_surface()
	if surface == null:
		_reset_final_plate_hover(true)
		return
	if _reduced_motion:
		_reset_final_plate_hover(true)
		return
	var weight := 1.0 - exp(-PLATE_HOVER_RESPONSE * maxf(delta, 0.0))
	_reset_inactive_hover_surface(surface)
	surface.scale = surface.scale.lerp(_plate_hover_target_scale, weight)
	surface.offset_transform_position = surface.offset_transform_position.lerp(
		_plate_hover_target_offset, weight,
	)
	surface.modulate = surface.modulate.lerp(_plate_hover_target_tint, weight)


func _reset_final_plate_hover(immediate: bool) -> void:
	_plate_hovered = false
	_plate_hover_target_scale = Vector2.ONE
	_plate_hover_target_offset = Vector2.ZERO
	_plate_hover_target_tint = Color.WHITE
	if immediate:
		_reset_surface_transform(_video)
		_reset_surface_transform(_final_plate)


func _active_hover_surface() -> Control:
	if _video != null and _video.visible and _playback_active:
		return _video
	if _final_plate != null and _final_plate.visible:
		return _final_plate
	return null


func _reset_inactive_hover_surface(active: Control) -> void:
	if active != _video:
		_reset_surface_transform(_video)
	if active != _final_plate:
		_reset_surface_transform(_final_plate)


func _reset_surface_transform(surface: Control) -> void:
	if surface == null:
		return
	surface.scale = Vector2.ONE
	surface.offset_transform_position = Vector2.ZERO
	surface.modulate = Color.WHITE
