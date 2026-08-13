class_name MapNavigator
extends RefCounted

## TD-008 view-only map navigation. Owns height-fill layout, bounded pan state,
## and mouse/trackpad gesture interpretation; it never reads or writes the model.

const WHEEL_STEP_PX := 96.0
const ACT2_STAGE_IDS: Array[StringName] = [&"s2", &"s3"]
const SAFE_MARGIN_X := 16.0
const SAFE_TOP := 104.0

var scale := 1.0
var origin := Vector2.ZERO
var pan := Vector2.ZERO
var bounds := Rect2()
var _stage: StageDef = null
var _viewport := Vector2.ZERO
var _safe_rect := Rect2()
var _middle_dragging := false
var _initialized := false


func relayout(stage: StageDef, viewport: Vector2) -> void:
	_stage = stage
	_viewport = viewport
	_safe_rect = _act2_safe_rect(viewport) if stage.id in ACT2_STAGE_IDS else Rect2()
	if not _safe_rect.has_area():
		scale = (
			IsoProjection.fit_scale(stage.grid_size(), viewport)
			if viewport.x < viewport.y
			else IsoProjection.height_fill_scale(stage, viewport)
		)
		origin = IsoProjection.terrain_origin_for(stage, viewport, scale)
		bounds = IsoProjection.pan_bounds(stage, viewport, scale)
	else:
		scale = IsoProjection.fit_scale(stage.grid_size(), _safe_rect.size)
		var content := IsoProjection.content_box(stage.grid_size())
		origin = _safe_rect.get_center() - content.get_center() * scale
		bounds = _safe_pan_bounds(content)
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
	var content := IsoProjection.content_box(_stage.grid_size())
	return Rect2(origin + pan + content.position * scale, content.size * scale)


func is_dragging() -> bool:
	return _middle_dragging


func ensure_local_rect_visible(local_rect: Rect2) -> bool:
	var screen := Rect2(
		origin + pan + local_rect.position * scale,
		local_rect.size * scale,
	)
	var visible_rect := _safe_rect if _safe_rect.has_area() else Rect2(Vector2.ZERO, _viewport)
	var next_pan := pan
	if screen.position.x < visible_rect.position.x:
		next_pan.x += visible_rect.position.x - screen.position.x
	elif screen.end.x > visible_rect.end.x:
		next_pan.x -= screen.end.x - visible_rect.end.x
	if screen.position.y < visible_rect.position.y:
		next_pan.y += visible_rect.position.y - screen.position.y
	elif screen.end.y > visible_rect.end.y:
		next_pan.y -= screen.end.y - visible_rect.end.y
	next_pan = IsoProjection.clamp_pan(next_pan, bounds)
	var changed := not next_pan.is_equal_approx(pan)
	pan = next_pan
	return changed


func _act2_safe_rect(viewport: Vector2) -> Rect2:
	var bottom := 374.0 if viewport.x < viewport.y else (218.0 if viewport.x < 1200.0 else 154.0)
	return Rect2(
		Vector2(SAFE_MARGIN_X, SAFE_TOP),
		Vector2(viewport.x - SAFE_MARGIN_X * 2.0, viewport.y - SAFE_TOP - bottom),
	)


func _safe_pan_bounds(content: Rect2) -> Rect2:
	var screen := Rect2(origin + content.position * scale, content.size * scale)
	var min_pan := Vector2.ZERO
	var max_pan := Vector2.ZERO
	if screen.size.x > _safe_rect.size.x:
		min_pan.x = _safe_rect.end.x - screen.end.x
		max_pan.x = _safe_rect.position.x - screen.position.x
	if screen.size.y > _safe_rect.size.y:
		min_pan.y = _safe_rect.end.y - screen.end.y
		max_pan.y = _safe_rect.position.y - screen.position.y
	return Rect2(min_pan, max_pan - min_pan)


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
