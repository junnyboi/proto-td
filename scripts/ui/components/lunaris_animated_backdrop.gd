extends Control

## Shared full-opacity Lunaris background for title and Company Command.
## The static image is visible only while the first video frame decodes.

const TITLE_ART := preload("res://assets/loading/lunaris_reliquary_loading.png")
const TITLE_LOOP := preload("res://assets/title/lunaris-title-loop.ogv")
const VIDEO_SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform float sharpen_strength : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 uv = UV;
	vec2 step_size = TEXTURE_PIXEL_SIZE;
	vec3 center = texture(TEXTURE, uv).rgb;
	vec3 neighbors = texture(TEXTURE, uv + vec2(step_size.x, 0.0)).rgb;
	neighbors += texture(TEXTURE, uv - vec2(step_size.x, 0.0)).rgb;
	neighbors += texture(TEXTURE, uv + vec2(0.0, step_size.y)).rgb;
	neighbors += texture(TEXTURE, uv - vec2(0.0, step_size.y)).rgb;
	vec3 detail = center - neighbors * 0.25;
	COLOR = vec4(clamp(center + detail * sharpen_strength, vec3(0.0), vec3(1.0)), 1.0);
}
"""

var _fallback: TextureRect = null
var _video: VideoStreamPlayer = null
var _video_ready := false
var _reduced_motion := bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	get_viewport().size_changed.connect(_fit_current_viewport)
	_fit_current_viewport()


func _process(_delta: float) -> void:
	if _video_ready or _reduced_motion or _video == null or _fallback == null:
		return
	if _video.is_playing() and _video.get_stream_position() > 0.0:
		_video_ready = true
		_fallback.visible = false
		set_process(false)


func fit_top_cover(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	const SOURCE_ASPECT := 16.0 / 9.0
	var viewport_aspect := viewport_size.x / viewport_size.y
	var fitted_size: Vector2
	if viewport_aspect > SOURCE_ASPECT:
		fitted_size = Vector2(viewport_size.x, viewport_size.x / SOURCE_ASPECT)
	else:
		fitted_size = Vector2(viewport_size.y * SOURCE_ASPECT, viewport_size.y)
	var fitted_position := Vector2((viewport_size.x - fitted_size.x) * 0.5, 0.0)
	_fallback.position = fitted_position
	_fallback.size = fitted_size
	_video.position = fitted_position
	_video.size = fitted_size


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _fallback == null or _video == null:
		return
	if enabled:
		_fallback.visible = true
		_video.visible = false
		_video.paused = true
		set_process(false)
		return
	_video.visible = true
	_video.paused = false
	if not _video.is_playing():
		_video.play()
	_video_ready = _video.get_stream_position() > 0.0
	_fallback.visible = not _video_ready
	set_process(not _video_ready)


func stop() -> void:
	if _video != null:
		_video.stop()


func is_video_ready() -> bool:
	return _video_ready


func video_player() -> VideoStreamPlayer:
	return _video


func fallback_texture() -> TextureRect:
	return _fallback


func _build_layers() -> void:
	_fallback = TextureRect.new()
	_fallback.name = "LunarisFallback"
	_fallback.texture = TITLE_ART
	_fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fallback)

	_video = VideoStreamPlayer.new()
	_video.name = "LunarisTitleLoop"
	_video.stream = TITLE_LOOP
	_video.autoplay = not _reduced_motion
	_video.loop = true
	_video.expand = true
	_video.volume_db = -80.0
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_video.modulate.a = 1.0
	_video.visible = not _reduced_motion
	var shader := Shader.new()
	shader.code = VIDEO_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	_video.material = material
	add_child(_video)
	if not _reduced_motion:
		_video.play()
	else:
		_video.paused = true
		set_process(false)


func _fit_current_viewport() -> void:
	fit_top_cover(get_viewport_rect().size)
