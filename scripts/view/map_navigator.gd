class_name MapNavigator
extends RefCounted

## TD-008 view-only map navigation. Owns height-fill layout, bounded pan state,
## and mouse/trackpad gesture interpretation; it never reads or writes the model.

const WHEEL_STEP_PX := 96.0

var scale := 1.0
var origin := Vector2.ZERO
var pan := Vector2.ZERO
var bounds := Rect2()
var _stage: StageDef = null
var _viewport := Vector2.ZERO
var _middle_dragging := false
var _initialized := false


func relayout(stage: StageDef, viewport: Vector2) -> void:
	_stage = stage
	_viewport = viewport
	scale = IsoProjection.height_fill_scale(stage, viewport)
	origin = IsoProjection.terrain_origin_for(stage, viewport, scale)
	bounds = IsoProjection.pan_bounds(stage, viewport, scale)
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
	return IsoProjection.content_screen_rect(_stage, _viewport, scale, pan)


func is_dragging() -> bool:
	return _middle_dragging


func ensure_local_rect_visible(local_rect: Rect2) -> bool:
	var screen := Rect2(
		origin + pan + local_rect.position * scale,
		local_rect.size * scale,
	)
	var next_pan := pan
	if screen.position.x < 0.0:
		next_pan.x -= screen.position.x
	elif screen.end.x > _viewport.x:
		next_pan.x -= screen.end.x - _viewport.x
	if screen.position.y < 0.0:
		next_pan.y -= screen.position.y
	elif screen.end.y > _viewport.y:
		next_pan.y -= screen.end.y - _viewport.y
	next_pan = IsoProjection.clamp_pan(next_pan, bounds)
	var changed := not next_pan.is_equal_approx(pan)
	pan = next_pan
	return changed


func recover_missed_release(event: InputEvent) -> void:
	if not _middle_dragging:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_MIDDLE and not button.pressed:
			_middle_dragging = false
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE == 0:
			_middle_dragging = false


## Returns true only for a consumed map-navigation event. BattleView applies
## the resulting transform and marks the viewport event handled.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_button(event as InputEventMouseButton)
	if event is InputEventMouseMotion and _middle_dragging:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE == 0:
			_middle_dragging = false
			return false
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
