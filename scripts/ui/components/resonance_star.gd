class_name ResonanceStar
extends Control

const ASTRAL_STAR := preload("res://assets/ui/gacha/astral_star.png")

var _accent := Color.WHITE
var _lit := false
var _star_art: TextureRect


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(34.0, 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_art = TextureRect.new()
	_star_art.name = "AstralStarArt"
	_star_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_star_art.texture = ASTRAL_STAR
	_star_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_star_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_star_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_star_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_star_art)
	_sync_presentation()


func set_state(accent: Color, lit: bool) -> void:
	_accent = accent
	_lit = lit
	_sync_presentation()


func uses_generated_art() -> bool:
	return _star_art != null and _star_art.texture == ASTRAL_STAR


func _sync_presentation() -> void:
	if _star_art == null:
		return
	if not _lit:
		_star_art.self_modulate = Color(0.46, 0.54, 0.62, 0.24)
		return
	var gold_weight := clampf((_accent.r + _accent.g - _accent.b) * 0.5, 0.0, 1.0)
	var cyan_tint := Color(0.72, 1.0, 1.0, 1.0)
	var gold_tint := Color(1.0, 0.97, 0.86, 1.0)
	_star_art.self_modulate = cyan_tint.lerp(gold_tint, gold_weight)
