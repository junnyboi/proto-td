class_name MapNavigator
extends RefCounted

## TD-008 view-only map navigation. Owns height-fill layout, bounded pan state,
## and pointer/trackpad gesture interpretation; it never reads or writes the model.

const WHEEL_STEP_PX := 96.0
const PRIMARY_DRAG_THRESHOLD_PX := 10.0
const INERTIA_MAX_SPEED_PX_PER_SECOND := 1800.0
const INERTIA_START_SPEED_PX_PER_SECOND := 90.0
const INERTIA_STOP_SPEED_PX_PER_SECOND := 18.0
const INERTIA_DECELERATION_PX_PER_SECOND_SQUARED := 2600.0
const INERTIA_VELOCITY_BLEND := 0.45
const INERTIA_SAMPLE_MIN_SECONDS := 1.0 / 240.0
const INERTIA_SAMPLE_MAX_SECONDS := 0.08
const INERTIA_RELEASE_MAX_IDLE_USEC := 120_000
const SHARED_ACT1_FIT_STAGE_IDS: Array[StringName] = [&"s1", &"s2", &"s3"]
const SHARED_ACT1_PANORAMA_SIZE := Vector2(512.0, 256.0)
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
var _primary_pressed := false
var _primary_dragging := false
var _primary_press_position := Vector2.ZERO
var _primary_pointer_position := Vector2.ZERO
var _primary_touch_index := -1
var _suppress_primary_click := false
var _drag_velocity_x := 0.0
var _inertia_velocity_x := 0.0
var _last_drag_sample_usec := 0
var _initialized := false


func relayout(stage: StageDef, viewport: Vector2) -> void:
	cancel_inertia()
	_stage = stage
	_viewport = viewport
	if _is_portrait():
		var content := _content_box(stage)
		# Portrait deliberately fills from the rendered terrain height. The same
		# scalar is applied on both axes, so wide maps overflow only horizontally.
		scale = IsoProjection.height_fill_scale(stage, viewport)
		origin = IsoProjection.terrain_origin_for(stage, viewport, scale)
		_safe_rect = Rect2(Vector2.ZERO, viewport)
		bounds = _pan_bounds_for(content, _safe_rect)
		bounds.position.y = 0.0
		bounds.size.y = 0.0
		if not _initialized:
			pan = Vector2(bounds.position.x, 0.0)
			_initialized = true
		else:
			pan = IsoProjection.clamp_pan(pan, bounds)
		return
	_safe_rect = (
		_shared_act1_safe_rect(viewport) if stage.id in SHARED_ACT1_FIT_STAGE_IDS else Rect2()
	)
	if not _safe_rect.has_area():
		scale = (
			IsoProjection.fit_scale(stage.grid_size(), viewport)
			if viewport.x < viewport.y
			else IsoProjection.height_fill_scale(stage, viewport)
		)
		origin = IsoProjection.terrain_origin_for(stage, viewport, scale)
		bounds = IsoProjection.pan_bounds(stage, viewport, scale)
	else:
		var content := shared_act1_content_box(stage)
		scale = shared_act1_fit_scale(stage, _safe_rect.size)
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
	var content := _content_box(_stage)
	return Rect2(origin + pan + content.position * scale, content.size * scale)


func is_dragging() -> bool:
	return _middle_dragging or _primary_dragging


func is_inertia_active() -> bool:
	return absf(_inertia_velocity_x) >= INERTIA_STOP_SPEED_PX_PER_SECOND


func cancel_inertia() -> void:
	_inertia_velocity_x = 0.0
	_drag_velocity_x = 0.0
	_last_drag_sample_usec = 0


## Advances view-only momentum in render time. Returns true only when the pan
## changed and BattleView needs to re-apply the map transform.
func advance_inertia(delta: float) -> bool:
	if not _is_portrait() or _primary_pressed or _middle_dragging or not is_inertia_active():
		if not _is_portrait():
			cancel_inertia()
		return false
	var previous_x := pan.x
	pan.x = clampf(
		pan.x + _inertia_velocity_x * maxf(delta, 0.0),
		bounds.position.x,
		bounds.end.x,
	)
	var hit_min := is_equal_approx(pan.x, bounds.position.x) and _inertia_velocity_x < 0.0
	var hit_max := is_equal_approx(pan.x, bounds.end.x) and _inertia_velocity_x > 0.0
	if hit_min or hit_max:
		cancel_inertia()
	else:
		_inertia_velocity_x = move_toward(
			_inertia_velocity_x,
			0.0,
			INERTIA_DECELERATION_PX_PER_SECOND_SQUARED * maxf(delta, 0.0),
		)
		if absf(_inertia_velocity_x) < INERTIA_STOP_SPEED_PX_PER_SECOND:
			cancel_inertia()
	return not is_equal_approx(previous_x, pan.x)


func consume_primary_click_suppression() -> bool:
	var suppressed := _suppress_primary_click
	_suppress_primary_click = false
	return suppressed


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
	if not _is_portrait():
		if screen.position.y < visible_rect.position.y:
			next_pan.y += visible_rect.position.y - screen.position.y
		elif screen.end.y > visible_rect.end.y:
			next_pan.y -= screen.end.y - visible_rect.end.y
	else:
		next_pan.y = 0.0
	# Large admitted presentation can extend beyond terrain-owned pan bounds.
	# Expand only toward the exact minimum correction requested by this rect.
	var expanded_min := Vector2(minf(bounds.position.x, next_pan.x), bounds.position.y)
	var expanded_max := Vector2(maxf(bounds.end.x, next_pan.x), bounds.end.y)
	if not _is_portrait():
		expanded_min.y = minf(bounds.position.y, next_pan.y)
		expanded_max.y = maxf(bounds.end.y, next_pan.y)
	bounds = Rect2(expanded_min, expanded_max - expanded_min)
	next_pan = IsoProjection.clamp_pan(next_pan, bounds)
	var changed := not next_pan.is_equal_approx(pan)
	pan = next_pan
	return changed


static func shared_act1_content_box(stage: StageDef) -> Rect2:
	var content := IsoProjection.terrain_box(stage)
	var center := IsoProjection.project(Vector2(stage.grid_size()) * 0.5)
	var panorama := Rect2(center - SHARED_ACT1_PANORAMA_SIZE * 0.5, SHARED_ACT1_PANORAMA_SIZE)
	return content.merge(panorama)


static func shared_act1_fit_scale(stage: StageDef, available: Vector2) -> float:
	var content := shared_act1_content_box(stage)
	var candidate := minf(available.x / content.size.x, available.y / content.size.y)
	return clampf(floorf(candidate * 4.0) * 0.25, 1.0, 3.0)


func _shared_act1_safe_rect(viewport: Vector2) -> Rect2:
	var bottom := 374.0 if viewport.x < viewport.y else (218.0 if viewport.x < 1200.0 else 154.0)
	return Rect2(
		Vector2(SAFE_MARGIN_X, SAFE_TOP),
		Vector2(viewport.x - SAFE_MARGIN_X * 2.0, viewport.y - SAFE_TOP - bottom),
	)


func _safe_pan_bounds(content: Rect2) -> Rect2:
	return _pan_bounds_for(content, _safe_rect)


func _pan_bounds_for(content: Rect2, visible_rect: Rect2) -> Rect2:
	var screen := Rect2(origin + content.position * scale, content.size * scale)
	var min_pan := Vector2.ZERO
	var max_pan := Vector2.ZERO
	if screen.size.x > visible_rect.size.x:
		min_pan.x = visible_rect.end.x - screen.end.x
		max_pan.x = visible_rect.position.x - screen.position.x
	if screen.size.y > visible_rect.size.y:
		min_pan.y = visible_rect.end.y - screen.end.y
		max_pan.y = visible_rect.position.y - screen.position.y
	return Rect2(min_pan, max_pan - min_pan)


func _content_box(stage: StageDef) -> Rect2:
	return (
		shared_act1_content_box(stage)
		if stage.id in SHARED_ACT1_FIT_STAGE_IDS
		else IsoProjection.content_box(stage.grid_size())
	)


func _is_portrait() -> bool:
	return _viewport.x < _viewport.y


func recover_missed_release(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_MIDDLE and not button.pressed:
			_middle_dragging = false
		elif button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_finish_primary_drag()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _middle_dragging and motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE == 0:
			_middle_dragging = false
		if _primary_pressed and motion.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
			_finish_primary_drag()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and touch.index == _primary_touch_index:
			_finish_primary_drag()


## Returns true only for a consumed map-navigation event. BattleView applies
## the resulting transform and marks the viewport event handled.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_button(event as InputEventMouseButton)
	if event is InputEventScreenTouch:
		return _handle_touch(event as InputEventScreenTouch)
	if event is InputEventScreenDrag:
		return _handle_touch_drag(event as InputEventScreenDrag)
	if event is InputEventMouseMotion and _middle_dragging:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE == 0:
			_middle_dragging = false
			return false
		pan = IsoProjection.clamp_pan(pan + motion.relative, bounds)
		return true
	if event is InputEventMouseMotion and _primary_pressed:
		return _handle_primary_motion(event as InputEventMouseMotion)
	return false


func _handle_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			cancel_inertia()
		_middle_dragging = event.pressed
		return true
	if event.button_index == MOUSE_BUTTON_LEFT:
		return _handle_primary_button(event)
	if not event.pressed:
		return false
	cancel_inertia()
	var delta := Vector2.ZERO
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			delta = (
				Vector2(WHEEL_STEP_PX, 0.0) if event.shift_pressed else Vector2(0.0, WHEEL_STEP_PX)
			)
		MOUSE_BUTTON_WHEEL_DOWN:
			delta = (
				Vector2(-WHEEL_STEP_PX, 0.0)
				if event.shift_pressed
				else Vector2(0.0, -WHEEL_STEP_PX)
			)
		MOUSE_BUTTON_WHEEL_LEFT:
			delta.x = WHEEL_STEP_PX
		MOUSE_BUTTON_WHEEL_RIGHT:
			delta.x = -WHEEL_STEP_PX
		_:
			return false
	pan = IsoProjection.clamp_pan(pan + delta, bounds)
	return true


func _handle_primary_button(event: InputEventMouseButton) -> bool:
	if event.pressed:
		if not _is_portrait() or _primary_touch_index >= 0:
			return false
		cancel_inertia()
		_suppress_primary_click = false
		_primary_pressed = true
		_primary_dragging = false
		_primary_touch_index = -1
		_primary_press_position = event.position
		_primary_pointer_position = event.position
		return false
	var consumed := _primary_dragging or _suppress_primary_click
	_finish_primary_drag()
	return consumed


func _handle_primary_motion(event: InputEventMouseMotion) -> bool:
	if _primary_touch_index >= 0:
		return false
	if event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
		_finish_primary_drag()
		return false
	_primary_pointer_position = event.position
	if not _primary_dragging:
		_primary_dragging = (
			_primary_pointer_position.distance_to(_primary_press_position)
			>= PRIMARY_DRAG_THRESHOLD_PX
		)
	if not _primary_dragging:
		return false
	var previous_x := pan.x
	pan.x = clampf(pan.x + event.relative.x, bounds.position.x, bounds.end.x)
	_sample_drag_velocity(pan.x - previous_x)
	_suppress_primary_click = true
	return true


func _handle_touch(event: InputEventScreenTouch) -> bool:
	if event.pressed:
		if not _is_portrait() or _primary_touch_index >= 0:
			return false
		cancel_inertia()
		_suppress_primary_click = false
		_primary_pressed = true
		_primary_dragging = false
		_primary_touch_index = event.index
		_primary_press_position = event.position
		_primary_pointer_position = event.position
		return false
	if event.index != _primary_touch_index:
		return _primary_touch_index < 0 and _suppress_primary_click
	var consumed := _primary_dragging or _suppress_primary_click
	_finish_primary_drag()
	return consumed


func _handle_touch_drag(event: InputEventScreenDrag) -> bool:
	if not _primary_pressed or event.index != _primary_touch_index:
		return false
	_primary_pointer_position = event.position
	if not _primary_dragging:
		_primary_dragging = (
			_primary_pointer_position.distance_to(_primary_press_position)
			>= PRIMARY_DRAG_THRESHOLD_PX
		)
	if not _primary_dragging:
		return false
	var previous_x := pan.x
	pan.x = clampf(pan.x + event.relative.x, bounds.position.x, bounds.end.x)
	_sample_drag_velocity(pan.x - previous_x)
	_suppress_primary_click = true
	return true


func _finish_primary_drag() -> void:
	if _primary_dragging:
		_suppress_primary_click = true
		_start_inertia()
	_primary_pressed = false
	_primary_dragging = false
	_primary_touch_index = -1


func _sample_drag_velocity(actual_delta_x: float) -> void:
	var now := Time.get_ticks_usec()
	if is_zero_approx(actual_delta_x):
		_drag_velocity_x = 0.0
		_last_drag_sample_usec = now
		return
	var seconds := INERTIA_SAMPLE_MIN_SECONDS
	if _last_drag_sample_usec > 0:
		seconds = clampf(
			float(now - _last_drag_sample_usec) / 1_000_000.0,
			INERTIA_SAMPLE_MIN_SECONDS,
			INERTIA_SAMPLE_MAX_SECONDS,
		)
	var measured := clampf(
		actual_delta_x / seconds,
		-INERTIA_MAX_SPEED_PX_PER_SECOND,
		INERTIA_MAX_SPEED_PX_PER_SECOND,
	)
	if is_zero_approx(_drag_velocity_x) or signf(measured) != signf(_drag_velocity_x):
		_drag_velocity_x = measured
	else:
		_drag_velocity_x = lerpf(_drag_velocity_x, measured, INERTIA_VELOCITY_BLEND)
	_last_drag_sample_usec = now


func _start_inertia() -> void:
	if not _is_portrait() or _last_drag_sample_usec <= 0:
		cancel_inertia()
		return
	if Time.get_ticks_usec() - _last_drag_sample_usec > INERTIA_RELEASE_MAX_IDLE_USEC:
		cancel_inertia()
		return
	if absf(_drag_velocity_x) < INERTIA_START_SPEED_PX_PER_SECOND:
		cancel_inertia()
		return
	_inertia_velocity_x = clampf(
		_drag_velocity_x,
		-INERTIA_MAX_SPEED_PX_PER_SECOND,
		INERTIA_MAX_SPEED_PX_PER_SECOND,
	)
	_drag_velocity_x = 0.0
