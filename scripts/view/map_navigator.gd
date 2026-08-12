class_name MapNavigator
extends RefCounted

## TD-006 view-only map navigation. Owns height-fill layout, bounded pan state,
## and mouse/trackpad gesture interpretation; it never reads or writes the model.

const WHEEL_STEP_PX := 96.0

var scale := 1.0
var origin := Vector2.ZERO
var pan := Vector2.ZERO
var bounds := Rect2()
var _grid_size := Vector2i.ZERO
var _viewport := Vector2.ZERO
var _middle_dragging := false
var _initialized := false


func relayout(grid_size: Vector2i, viewport: Vector2) -> void:
	_grid_size = grid_size
	_viewport = viewport
	scale = IsoProjection.height_fill_scale(grid_size, viewport)
	origin = IsoProjection.terrain_origin_for(grid_size, viewport, scale)
	bounds = IsoProjection.pan_bounds(grid_size, viewport, scale)
	if not _initialized:
		# TD stages terminate at the base on the right: boot with that critical
		# edge visible, while Y stays centered until the player scrolls.
		pan = Vector2(bounds.position.x, 0.0)
		_initialized = true
	else:
		pan = IsoProjection.clamp_pan(pan, bounds)


func root_position() -> Vector2:
	return origin + pan


func content_screen_rect() -> Rect2:
	return IsoProjection.content_screen_rect(_grid_size, _viewport, scale, pan)


## Returns true only for a consumed map-navigation event. BattleView applies
## the resulting transform and marks the viewport event handled.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_button(event as InputEventMouseButton)
	if event is InputEventMouseMotion and _middle_dragging:
		var motion := event as InputEventMouseMotion
		pan = IsoProjection.clamp_pan(pan + motion.relative, bounds)
		return true
	return false


func _handle_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_middle_dragging = event.pressed
		return true
	if not event.pressed:
		return false
	var delta := Vector2.ZERO
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			delta = Vector2(WHEEL_STEP_PX, 0.0) if event.shift_pressed \
				else Vector2(0.0, WHEEL_STEP_PX)
		MOUSE_BUTTON_WHEEL_DOWN:
			delta = Vector2(-WHEEL_STEP_PX, 0.0) if event.shift_pressed \
				else Vector2(0.0, -WHEEL_STEP_PX)
		MOUSE_BUTTON_WHEEL_LEFT:
			delta.x = WHEEL_STEP_PX
		MOUSE_BUTTON_WHEEL_RIGHT:
			delta.x = -WHEEL_STEP_PX
		_:
			return false
	pan = IsoProjection.clamp_pan(pan + delta, bounds)
	return true
