class_name CampaignReadyShimmer
extends Control

## A restrained diagonal gold sweep for the ready operation status. The shimmer
## remains a static highlight when Reduced Motion is enabled.

const SWEEP_SECONDS := 2.8
const BAND_WIDTH_RATIO := 0.24
const GOLD_LIGHT := Color("fff4c9")
const GOLD_EDGE := Color("f0d89a")

var _elapsed := 0.0
var _active := false
var _reduced_motion := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	set_process(_active and not _reduced_motion)
	queue_redraw()


func set_active(value: bool) -> void:
	_active = value
	visible = value
	if value:
		_elapsed = 0.0
	set_process(value and not _reduced_motion)
	queue_redraw()


func is_active() -> bool:
	return _active


func motion_reduced() -> bool:
	return _reduced_motion


func sweep_phase() -> float:
	return 0.5 if _reduced_motion else _elapsed / SWEEP_SECONDS


func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, SWEEP_SECONDS)
	queue_redraw()


func _draw() -> void:
	if not _active or size.x <= 8.0 or size.y <= 4.0:
		return
	var phase := sweep_phase()
	var band_width := maxf(20.0, size.x * BAND_WIDTH_RATIO)
	var center_x := lerpf(-band_width, size.x + band_width, phase)
	var lean := size.y * 0.72
	var left := center_x - band_width * 0.5
	var right := center_x + band_width * 0.5
	var band := PackedVector2Array([
		Vector2(left - lean, 0.0),
		Vector2(right - lean, 0.0),
		Vector2(right + lean, size.y),
		Vector2(left + lean, size.y),
	])
	var alpha := 0.16 if _reduced_motion else 0.26
	draw_colored_polygon(band, Color(GOLD_LIGHT, alpha))
	var gleam_x := center_x + lean * 0.15
	draw_line(
		Vector2(gleam_x - lean, 0.0),
		Vector2(gleam_x + lean, size.y),
		Color(GOLD_EDGE, 0.28 if _reduced_motion else 0.58),
		1.2,
	)
