extends RefCounted

## TD-006 map navigation: real middle-drag and wheel events drive the view-only
## adapter. Runtime checks independently measure rendered tile nodes, exercise
## release-over-UI recovery, and prove targeting/VFX/layout after pan + resize.
## Budget: boot + input batches + resize + targeting rituals + three shots,
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
	_check_rendered_height_fill(h, view, viewport, "boot", true)
	_check_round_trip(h, view, "boot")
	var bounds: Rect2 = view.call("map_pan_bounds")
	h.check(
		"both pan axes are non-vacuous",
		bounds.size.x > 0.0 and bounds.size.y > 0.0,
		"bounds %s" % bounds,
	)
	await h.shot("map_height_fill")

	# A release consumed over STOP-filter UI must still clear the global drag
	# state, and a later ordinary motion must not pan.
	var pointer := viewport * 0.5
	var pan_before_release: Vector2 = view.call("map_pan")
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	await h.frames(1)
	h.check("middle drag latched", bool(view.call("map_dragging")))
	var resign := view.find_child("ResignButton", true, false) as Button
	h.check("resign control present", resign != null)
	if resign != null:
		_send_button(resign.get_global_rect().get_center(), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(2)
	h.check("release over UI clears middle drag", not bool(view.call("map_dragging")))
	_send_motion(pointer + Vector2(40, 40), Vector2(40, 40), false)
	await h.frames(2)
	h.check(
		"ordinary motion after missed release cannot pan",
		view.call("map_pan") == pan_before_release,
	)

	# Real middle-button drag drives both axes and clamps at the far edges.
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	_send_motion(
		pointer - Vector2(10000.0, 10000.0), Vector2(-10000.0, -10000.0), true
	)
	_send_button(pointer - Vector2(10000.0, 10000.0), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(3)
	var pan_min: Vector2 = view.call("map_pan")
	h.check("middle drag clamps to minimum pan", pan_min.is_equal_approx(bounds.position))
	var far_rect: Rect2 = view.call("map_content_rect")
	h.check(
		"far content edges meet viewport edges",
		absf(far_rect.end.x - viewport.x) < EPS and absf(far_rect.end.y - viewport.y) < EPS,
		"rect %s viewport %s" % [far_rect, viewport],
	)
	_check_round_trip(h, view, "far edges")
	await h.shot("map_pan_far_edges")

	# Vertical, Shift+vertical, and native horizontal wheel routes all drive the
	# same real adapter without a shared input-map action.
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, false)
	await h.frames(2)
	var after_y: Vector2 = view.call("map_pan")
	h.check("vertical wheel scrolls Y only", after_y.x == pan_min.x and after_y.y > pan_min.y)
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, true)
	await h.frames(2)
	var after_shift_x: Vector2 = view.call("map_pan")
	h.check(
		"shift wheel scrolls X only",
		after_shift_x.x > after_y.x and after_shift_x.y == after_y.y,
	)
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_RIGHT, false)
	await h.frames(2)
	var after_native_x: Vector2 = view.call("map_pan")
	h.check(
		"native horizontal wheel scrolls X only",
		after_native_x.x < after_shift_x.x and after_native_x.y == after_shift_x.y,
	)

	# A stationary heart from a grid-local swirl must retain its offset to the
	# target cell while a wheel event pans the map.
	var juice := view.find_child("JuiceLayer", true, false)
	juice.call("swirl", IsoProjection.face_center(TARGET_CELL))
	await h.frames(1)
	var heart := juice.find_child("MapTransientHeart", true, false) as Control
	h.check("map-local transient exists", heart != null)
	if heart != null:
		var offset_before := heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
		_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, false)
		await h.frames(1)
		var offset_after := heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
		h.check(
			"active map VFX stays anchored while panning",
			offset_after.distance_to(offset_before) < EPS,
			"before %s after %s" % [offset_before, offset_after],
		)

	# Drag to the opposite extreme and prove the near edges.
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	_send_motion(
		pointer + Vector2(10000.0, 10000.0), Vector2(10000.0, 10000.0), true
	)
	_send_button(pointer + Vector2(10000.0, 10000.0), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(3)
	var pan_max: Vector2 = view.call("map_pan")
	h.check("middle drag clamps to maximum pan", pan_max.is_equal_approx(bounds.end))
	var near_rect: Rect2 = view.call("map_content_rect")
	h.check(
		"near content edges meet viewport edges",
		absf(near_rect.position.x) < EPS and absf(near_rect.position.y) < EPS,
		"rect %s" % near_rect,
	)
	_check_round_trip(h, view, "near edges")
	await h.shot("map_pan_near_edges")

	# Resize preserves the pixel pan exactly where legal, clamps only impossible
	# axes, and updates independently measured terrain + wave-banner geometry.
	var pan_before_resize := pan_max
	h.root.size = Vector2i(960, 640)
	await h.frames(4)
	viewport = view.get_viewport_rect().size
	_check_rendered_height_fill(h, view, viewport, "resized", false)
	var resized_bounds: Rect2 = view.call("map_pan_bounds")
	var resized_pan: Vector2 = view.call("map_pan")
	var expected_pan := Vector2(
		clampf(pan_before_resize.x, resized_bounds.position.x, resized_bounds.end.x),
		clampf(pan_before_resize.y, resized_bounds.position.y, resized_bounds.end.y),
	)
	h.check("resize preserves then clamps exact pixel pan", resized_pan.is_equal_approx(expected_pan))
	_check_round_trip(h, view, "resized")
	var banner_back := view.find_child("WaveBannerBack", true, false) as ColorRect
	var banner := view.find_child("WaveBanner", true, false) as Label
	h.check(
		"wave banner relayouts to resized viewport",
		banner_back != null and banner != null
			and absf(banner_back.size.x - viewport.x) < EPS
			and absf(banner_back.position.y - viewport.y * 0.48) < EPS
			and absf(banner.size.x - viewport.x) < EPS,
	)

	# Spell cursor and full deploy ritual still resolve through live pan/scale.
	var bolt := view.find_child("Spell_bolt", true, false) as Button
	h.check("bolt target control available after pan+resize", bolt != null and not bolt.disabled)
	if bolt != null and not bolt.disabled:
		await h.press_mouse_at(bolt.get_global_rect().get_center())
		await h.release_mouse_at(bolt.get_global_rect().get_center())
		h.move_mouse_to_view(view.call("cell_center", TARGET_CELL))
		await h.frames(2)
		var spell_cursor := view.find_child("SpellCursor", true, false) as Polygon2D
		h.check(
			"spell cursor follows target cell after pan+resize",
			spell_cursor != null and spell_cursor.visible
				and spell_cursor.position.distance_to(view.call("cell_center", TARGET_CELL)) < EPS,
		)
		h.press("ui_cancel")
		await h.frames(1)
		h.release("ui_cancel")
		await h.frames(1)

	h.check("map-only interactions leave model hash unchanged", model.state_hash() == hash_before)

	# Fresh battle isolates the deploy ritual from the completed spell-target
	# ritual while retaining the 960x640 viewport and an actively panned map.
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	model = game.get("current_battle")
	view = game.get("content") as Node2D
	view.set("ticks_per_frame_scale", 0.0)
	pointer = view.get_viewport_rect().size * 0.5
	var deploy_pan_before: Vector2 = view.call("map_pan")
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_UP, false)
	await h.frames(2)
	h.check("deploy battle map was actively panned", view.call("map_pan") != deploy_pan_before)
	var deploy_bar := view.find_child("DeployBar", true, false)
	var slot := deploy_bar.find_child("Slot_vanguard_1", true, false) as Button
	h.check("vanguard deploy control available after pan+resize", slot != null and not slot.disabled)
	if slot != null and not slot.disabled:
		await h.press_mouse_at(slot.get_global_rect().get_center())
		h.move_mouse_to_view(view.call("cell_center", TARGET_CELL))
		await h.frames(2)
		var deploy_cursor := deploy_bar.find_child("CursorRect", true, false) as Polygon2D
		h.check(
			"deploy cursor tracks panned target cell",
			deploy_cursor != null and deploy_cursor.visible
				and deploy_cursor.position.distance_to(view.call("cell_center", TARGET_CELL)) < EPS,
		)
		h.check(
			"panned target cell remains deploy-valid",
			model.can_deploy_at(&"vanguard_1", TARGET_CELL),
		)
		await h.release_mouse_at(view.call("cell_center", TARGET_CELL))
		await h.frames(2)
		var facing := deploy_bar.find_child("FacingRight", true, false) as Button
		h.check("facing chooser tracks panned cell", facing != null and facing.visible)
		if facing != null:
			await h.click_view(facing.get_global_rect().get_center())
		await h.frames(3)
		h.check("deploy lands on panned target cell", model.alive_unit_at(TARGET_CELL) != null)

	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	h.done()


func _check_rendered_height_fill(
	h: SelfTestHarness, view: Node2D, viewport: Vector2, label: String, centered: bool
) -> void:
	var seam_rect: Rect2 = view.call("map_screen_rect")
	var node_rect := _rendered_tile_bounds(view)
	h.check(
		"%s rendered terrain matches view seam" % label,
		node_rect.position.distance_to(seam_rect.position) < EPS
			and node_rect.size.distance_to(seam_rect.size) < EPS,
		"nodes %s seam %s" % [node_rect, seam_rect],
	)
	h.check(
		"%s rendered terrain height fills viewport" % label,
		absf(node_rect.size.y - viewport.y) < EPS,
	)
	if centered:
		h.check(
			"%s centered terrain reaches top and bottom edges" % label,
			absf(node_rect.position.y) < EPS and absf(node_rect.end.y - viewport.y) < EPS,
			"terrain %s viewport %s" % [node_rect, viewport],
		)


func _rendered_tile_bounds(view: Node2D) -> Rect2:
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var result := Rect2()
	var first := true
	for child: Node in grid.get_children():
		if not child.name.begins_with("Tile_"):
			continue
		var rect := Rect2()
		if child is Control:
			rect = (child as Control).get_global_rect()
		elif child is Polygon2D:
			var poly := child as Polygon2D
			for point: Vector2 in poly.polygon:
				var global_point := poly.to_global(point)
				if rect.size == Vector2.ZERO:
					rect = Rect2(global_point, Vector2.ZERO)
				else:
					rect = rect.expand(global_point)
		else:
			continue
		result = rect if first else result.merge(rect)
		first = false
	return result


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


func _send_motion(position: Vector2, relative: Vector2, middle_pressed: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE if middle_pressed else 0
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
