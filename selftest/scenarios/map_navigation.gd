extends RefCounted

## TD-006 map navigation: real middle-drag and wheel events drive the view-only
## adapter while geometry seams prove exact height-fill and edge clamps.
## View-only budget: boot/settle + four input batches + resize + three shots,
## doubled for 120 Hz with generous headroom -> 900 render frames.

const TARGET_CELL := Vector2i(3, 2)
const EPS := 0.01


func run(h: SelfTestHarness) -> void:
	h.max_frames = 900
	h.expect_done()
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	var view := game.get("content") as Node2D
	h.check("battle model exists", model != null)
	h.check("battle view exists", view != null)
	if model == null or view == null:
		return
	view.set("ticks_per_frame_scale", 0.0)
	var hash_before := model.state_hash()
	var viewport := view.get_viewport_rect().size
	_check_height_fill(h, view, viewport, "boot")
	_check_round_trip(h, view, "center")
	var bounds: Rect2 = view.call("map_pan_bounds")
	h.check(
		"both pan axes are non-vacuous",
		bounds.size.x > 0.0 and bounds.size.y > 0.0,
		"bounds %s" % bounds,
	)
	await h.shot("map_height_fill")

	# Real middle-button drag drives both axes and clamps at the far edges.
	var pointer := viewport * 0.5
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	_send_motion(pointer - Vector2(10000.0, 10000.0), Vector2(-10000.0, -10000.0))
	_send_button(pointer - Vector2(10000.0, 10000.0), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(3)
	var pan_min: Vector2 = view.call("map_pan")
	h.check(
		"middle drag clamps to minimum pan",
		pan_min.is_equal_approx(bounds.position),
		"pan %s" % pan_min,
	)
	var far_rect: Rect2 = view.call("map_content_rect")
	h.check(
		"far content edges meet viewport edges",
		absf(far_rect.end.x - viewport.x) < EPS and absf(far_rect.end.y - viewport.y) < EPS,
		"rect %s viewport %s" % [far_rect, viewport],
	)
	_check_round_trip(h, view, "far edges")
	await h.shot("map_pan_far_edges")

	# Wheel-down moves Y toward the minimum; wheel-up reverses it. Shift+wheel
	# uses the same real adapter for X without adding a shared input action.
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, false)
	await h.frames(2)
	var after_y: Vector2 = view.call("map_pan")
	h.check(
		"vertical wheel scrolls Y only",
		after_y.x == pan_min.x and after_y.y > pan_min.y,
		"before %s after %s" % [pan_min, after_y],
	)
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, true)
	await h.frames(2)
	var after_x: Vector2 = view.call("map_pan")
	h.check(
		"shift wheel scrolls X only",
		after_x.x > after_y.x and after_x.y == after_y.y,
		"before %s after %s" % [after_y, after_x],
	)

	# Drag to the opposite extreme and prove the near edges, then resize and
	# verify the camera recomputes height while retaining only a legal offset.
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	_send_motion(pointer + Vector2(10000.0, 10000.0), Vector2(10000.0, 10000.0))
	_send_button(pointer + Vector2(10000.0, 10000.0), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(3)
	var pan_max: Vector2 = view.call("map_pan")
	h.check(
		"middle drag clamps to maximum pan",
		pan_max.is_equal_approx(bounds.end),
		"pan %s" % pan_max,
	)
	var near_rect: Rect2 = view.call("map_content_rect")
	h.check(
		"near content edges meet viewport edges",
		absf(near_rect.position.x) < EPS and absf(near_rect.position.y) < EPS,
		"rect %s" % near_rect,
	)
	_check_round_trip(h, view, "near edges")
	await h.shot("map_pan_near_edges")

	h.root.size = Vector2i(960, 640)
	await h.frames(4)
	viewport = view.get_viewport_rect().size
	_check_height_fill(h, view, viewport, "resized")
	var resized_bounds: Rect2 = view.call("map_pan_bounds")
	var resized_pan: Vector2 = view.call("map_pan")
	h.check(
		"resize reclamps pan inside new bounds",
		resized_pan.x >= resized_bounds.position.x - EPS
			and resized_pan.x <= resized_bounds.end.x + EPS
			and resized_pan.y >= resized_bounds.position.y - EPS
			and resized_pan.y <= resized_bounds.end.y + EPS,
		"pan %s bounds %s" % [resized_pan, resized_bounds],
	)
	_check_round_trip(h, view, "resized")
	h.check(
		"map navigation leaves model hash unchanged",
		model.state_hash() == hash_before,
		"before %d after %d" % [hash_before, model.state_hash()],
	)
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	h.done()


func _check_height_fill(
	h: SelfTestHarness, view: Node2D, viewport: Vector2, label: String
) -> void:
	var map_rect: Rect2 = view.call("map_screen_rect")
	h.check(
		"%s terrain height equals viewport height" % label,
		absf(map_rect.size.y - viewport.y) < EPS,
		"map %f viewport %f" % [map_rect.size.y, viewport.y],
	)


func _check_round_trip(h: SelfTestHarness, view: Node2D, label: String) -> void:
	var picked: Vector2i = view.call("cell_at", view.call("cell_center", TARGET_CELL))
	h.check("%s cell seam round-trips" % label, picked == TARGET_CELL, "got %s" % picked)


func _send_button(position: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _send_motion(position: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.relative = relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _send_wheel(position: Vector2, button: MouseButton, shifted: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = true
	event.shift_pressed = shifted
	Input.parse_input_event(event)
	Input.flush_buffered_events()
