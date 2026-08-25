class_name ResonanceStar
extends Control

var _accent := Color.WHITE
var _lit := false


func _ready() -> void:
	custom_minimum_size = Vector2(34.0, 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_state(accent: Color, lit: bool) -> void:
	_accent = accent
	_lit = lit
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var outer := minf(size.x, size.y) * 0.45
	var inner := outer * 0.44
	var points := PackedVector2Array()
	for index: int in 10:
		var radius := outer if index % 2 == 0 else inner
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var fill := _accent if _lit else Color(0.35, 0.45, 0.52, 0.20)
	if _lit:
		draw_circle(center, outer * 0.82, Color(_accent.r, _accent.g, _accent.b, 0.10))
	draw_colored_polygon(points, fill)
	if _lit:
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, Color(1.0, 1.0, 1.0, 0.55), 1.35, true)
