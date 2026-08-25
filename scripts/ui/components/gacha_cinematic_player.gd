extends Control
class_name GachaCinematicPlayer

## Presentation-only Premium Resonance media owner. Gameplay state remains in gacha.gd.
## The motion stream is always replaced by the approved final plate before UI settle.

const PROFILES := {
	"lunaris_vessel": {
		"landscape_video": "res://assets/cinematics/gacha/video/lunaris-vessel-landscape.ogv",
		"portrait_video": "res://assets/cinematics/gacha/video/lunaris-vessel-portrait.ogv",
		"landscape_final": "res://assets/cinematics/gacha/posters/lunaris-vessel-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/lunaris-vessel-portrait.webp",
		"music_id": &"gacha_lunaris_vessel",
	},
	"reliquary_duelist": {
		"landscape_video": "res://assets/cinematics/gacha/video/reliquary-duelist-landscape.ogv",
		"portrait_video": "res://assets/cinematics/gacha/video/reliquary-duelist-portrait.ogv",
		"landscape_final": "res://assets/cinematics/gacha/posters/reliquary-duelist-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/reliquary-duelist-portrait.webp",
		"music_id": &"gacha_reliquary_duelist",
	},
	"archive_caster": {
		"landscape_video": "res://assets/cinematics/gacha/video/archive-caster-landscape.ogv",
		"portrait_video": "res://assets/cinematics/gacha/video/archive-caster-portrait.ogv",
		"landscape_final": "res://assets/cinematics/gacha/posters/archive-caster-landscape.webp",
		"portrait_final": "res://assets/cinematics/gacha/posters/archive-caster-portrait.webp",
		"music_id": &"gacha_archive_caster",
	},
}

var _video: VideoStreamPlayer
var _final_plate: TextureRect
var _portrait_orientation := false
var _active_profile: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	get_viewport().size_changed.connect(_fit_current_viewport)
	_fit_current_viewport()


func play_cinematic(premium_id: String, reduced_motion: bool) -> bool:
	stop()
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
	_final_plate.visible = reduced_motion or _final_plate.texture == null
	_fit_current_viewport()
	if reduced_motion:
		_final_plate.visible = true
		return false
	var video_path := String(_active_profile.get("%s_video" % orientation, ""))
	if video_path.is_empty() or not ResourceLoader.exists(video_path):
		_final_plate.visible = true
		return false
	_video.stream = load(video_path) as VideoStream
	if _video.stream == null:
		_final_plate.visible = true
		return false
	_video.visible = true
	_video.play()
	return true


func show_final_plate() -> void:
	if _video != null:
		_video.stop()
		_video.visible = false
	if _final_plate != null:
		_final_plate.visible = true


func stop() -> void:
	if _video != null:
		_video.stop()
		_video.stream = null
		_video.visible = false
	if _final_plate != null:
		_final_plate.visible = false
	_active_profile.clear()


func music_id() -> StringName:
	return StringName(_active_profile.get("music_id", &""))


func video_player() -> VideoStreamPlayer:
	return _video


func final_plate() -> TextureRect:
	return _final_plate


func is_portrait_orientation() -> bool:
	return _portrait_orientation


func _build_layers() -> void:
	_video = VideoStreamPlayer.new()
	_video.name = "CinematicVideo"
	_video.autoplay = false
	_video.loop = false
	_video.expand = true
	_video.volume_db = -80.0
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_video.visible = false
	add_child(_video)

	_final_plate = TextureRect.new()
	_final_plate.name = "CinematicFinalPlate"
	_final_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_final_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_final_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final_plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_final_plate.visible = false
	add_child(_final_plate)


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
	_final_plate.position = fitted_position
	_final_plate.size = fitted_size
