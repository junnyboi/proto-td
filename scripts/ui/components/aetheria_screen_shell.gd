class_name AetheriaScreenShell
extends Control

signal layout_mode_changed(mode: StringName)

const MODES: Array[StringName] = [
	&"regular_landscape", &"compact_landscape", &"portrait",
]

@export var preferred_size: Vector2:
	get:
		return _preferred_size
	set(value):
		set_preferred_size(value)

var _preferred_size := Vector2(720.0, 520.0)
var _layout_mode: StringName = &"regular_landscape"

@onready var _safe_margin: MarginContainer = $SafeMargin
@onready var _reading_plate: PanelContainer = $SafeMargin/Center/ReadingPlate
@onready var _content_margin: MarginContainer = (
	$SafeMargin/Center/ReadingPlate/ContentMargin
)
@onready var _content_host: MarginContainer = (
	$SafeMargin/Center/ReadingPlate/ContentMargin/ContentHost
)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	relayout(Vector2i(size))


func set_preferred_size(value: Vector2) -> bool:
	if value.x <= 0.0 or value.y <= 0.0:
		return false
	_preferred_size = value
	if is_node_ready():
		relayout(Vector2i(size))
	return true


func content_host() -> Control:
	return _content_host


func layout_mode() -> StringName:
	return _layout_mode


func relayout(viewport: Vector2i) -> void:
	if not is_node_ready() or viewport.x <= 0 or viewport.y <= 0:
		return
	var next_mode := _mode_for(viewport)
	var compact := next_mode != &"regular_landscape"
	var inset := 24 if compact else 36
	var padding := 32 if compact else 40
	_set_margins(_safe_margin, inset)
	_set_margins(_content_margin, padding)
	var available := Vector2(
		maxi(1, viewport.x - inset * 2),
		maxi(1, viewport.y - inset * 2),
	)
	_reading_plate.custom_minimum_size = Vector2(
		minf(_preferred_size.x, available.x),
		minf(_preferred_size.y, available.y),
	)
	if next_mode != _layout_mode:
		_layout_mode = next_mode
		layout_mode_changed.emit(_layout_mode)


func _mode_for(viewport: Vector2i) -> StringName:
	if viewport.y > viewport.x:
		return &"portrait"
	if viewport.x < 1100 or viewport.y < 720:
		return &"compact_landscape"
	return &"regular_landscape"


func _set_margins(container: MarginContainer, value: int) -> void:
	for side: StringName in [
		&"margin_left", &"margin_top", &"margin_right", &"margin_bottom",
	]:
		container.add_theme_constant_override(side, value)


func _on_resized() -> void:
	relayout(Vector2i(size))
