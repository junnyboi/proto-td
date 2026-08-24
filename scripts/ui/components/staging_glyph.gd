class_name StagingGlyph
extends Control


enum Kind {
	CREST,
	MISSION,
	BARRACKS,
	RECRUIT,
	ARMORY,
	MEMORIAL,
	TRAINING,
}

@export var kind: Kind = Kind.CREST:
	set(value):
		kind = value
		queue_redraw()

@export var line_color := Color("d8b978"):
	set(value):
		line_color = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(38.0, 38.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.37
	var width := maxf(1.35, minf(size.x, size.y) / 28.0)
	match kind:
		Kind.CREST:
			_draw_crest(center, radius, width)
		Kind.MISSION:
			_draw_mission(center, radius, width)
		Kind.BARRACKS:
			_draw_barracks(center, radius, width)
		Kind.RECRUIT:
			_draw_recruit(center, radius, width)
		Kind.ARMORY:
			_draw_armory(center, radius, width)
		Kind.MEMORIAL:
			_draw_memorial(center, radius, width)
		Kind.TRAINING:
			_draw_training(center, radius, width)


func _draw_crest(center: Vector2, radius: float, width: float) -> void:
	draw_arc(center, radius, 0.0, TAU, 48, Color(line_color, 0.55), width)
	draw_arc(center, radius * 0.68, -2.35, 2.35, 32, line_color, width)
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.78),
		center + Vector2(radius * 0.3, 0.0),
		center + Vector2(0.0, radius * 0.78),
		center + Vector2(-radius * 0.3, 0.0),
		center + Vector2(0.0, -radius * 0.78),
	])
	draw_polyline(diamond, line_color, width, true)
	draw_circle(center, radius * 0.08, line_color)


func _draw_mission(center: Vector2, radius: float, width: float) -> void:
	draw_arc(center, radius * 0.76, 0.0, TAU, 36, line_color, width)
	draw_arc(center, radius * 0.36, 0.0, TAU, 24, Color(line_color, 0.7), width)
	draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), line_color, width)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), line_color, width)
	draw_circle(center, radius * 0.11, line_color)


func _draw_barracks(center: Vector2, radius: float, width: float) -> void:
	var shield := PackedVector2Array([
		center + Vector2(-radius * 0.62, -radius * 0.7),
		center + Vector2(radius * 0.62, -radius * 0.7),
		center + Vector2(radius * 0.48, radius * 0.34),
		center + Vector2(0.0, radius * 0.86),
		center + Vector2(-radius * 0.48, radius * 0.34),
		center + Vector2(-radius * 0.62, -radius * 0.7),
	])
	draw_polyline(shield, line_color, width, true)
	draw_line(center + Vector2(0.0, -radius * 0.62), center + Vector2(0.0, radius * 0.57), line_color, width)
	draw_line(center + Vector2(-radius * 0.35, -radius * 0.15), center + Vector2(radius * 0.35, -radius * 0.15), line_color, width)


func _draw_recruit(center: Vector2, radius: float, width: float) -> void:
	draw_arc(center, radius * 0.78, 0.0, TAU, 36, Color(line_color, 0.48), width)
	draw_circle(center + Vector2(0.0, -radius * 0.28), radius * 0.22, line_color, false, width)
	draw_arc(center + Vector2(0.0, radius * 0.47), radius * 0.5, PI, TAU, 24, line_color, width)
	draw_line(center + Vector2(radius * 0.72, -radius * 0.08), center + Vector2(radius * 0.72, radius * 0.55), line_color, width)
	draw_line(center + Vector2(radius * 0.42, radius * 0.24), center + Vector2(radius, radius * 0.24), line_color, width)


func _draw_armory(center: Vector2, radius: float, width: float) -> void:
	draw_line(center + Vector2(-radius * 0.62, radius * 0.72), center + Vector2(radius * 0.56, -radius * 0.74), line_color, width)
	draw_line(center + Vector2(radius * 0.62, radius * 0.72), center + Vector2(-radius * 0.56, -radius * 0.74), line_color, width)
	draw_line(center + Vector2(-radius * 0.78, radius * 0.42), center + Vector2(-radius * 0.28, radius * 0.8), line_color, width)
	draw_line(center + Vector2(radius * 0.78, radius * 0.42), center + Vector2(radius * 0.28, radius * 0.8), line_color, width)
	draw_circle(center, radius * 0.12, line_color, false, width)


func _draw_memorial(center: Vector2, radius: float, width: float) -> void:
	var flame := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.82),
		center + Vector2(radius * 0.3, -radius * 0.32),
		center + Vector2(0.0, radius * 0.06),
		center + Vector2(-radius * 0.28, -radius * 0.28),
		center + Vector2(0.0, -radius * 0.82),
	])
	draw_polyline(flame, line_color, width, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.32, radius * 0.05), Vector2(radius * 0.64, radius * 0.65)), line_color, false, width)
	draw_line(center + Vector2(-radius * 0.55, radius * 0.76), center + Vector2(radius * 0.55, radius * 0.76), line_color, width)


func _draw_training(center: Vector2, radius: float, width: float) -> void:
	var points := PackedVector2Array()
	for index: int in 10:
		var point_radius := radius * (0.86 if index % 2 == 0 else 0.36)
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	points.append(points[0])
	draw_polyline(points, line_color, width, true)
	draw_circle(center, radius * 0.12, line_color, false, width)
