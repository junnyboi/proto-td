extends RefCounted

## TD-008 map navigation: real middle-drag and wheel events drive the view-only
## adapter. Runtime checks independently measure rendered tile nodes, exercise
## release-over-UI recovery, and prove targeting/VFX/layout after pan + resize.
## Budget: boot + input batches + resize + targeting rituals + three shots,
## doubled for 120 Hz with generous headroom -> 1100 render frames.

const TARGET_CELL := Vector2i(3, 2)
const EDGE_DEPLOY_CELL := Vector2i(0, 0)
const EPS := 0.01
const HEART_COLOR := Color("ef7d57")
const VIGNETTE_COLOR := Color(0.9, 0.1, 0.1, 1.0)
const VIGNETTE_THICKNESS := 10.0


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1100
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
	_check_polygon_fallback_bounds(h, view)
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

	# Keep one exact VFX instance and the screen-edge/result overlays alive across
	# a real scale change. This makes resize anchoring and relayout falsifiable.
	var resize_heart := _spawn_heart(juice, IsoProjection.face_center(TARGET_CELL))
	await h.frames(1)
	h.check("resize VFX instance exists", resize_heart != null)
	var resize_offset_before := Vector2.ZERO
	if resize_heart != null:
		resize_offset_before = resize_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
	juice.call("vignette")
	juice.call("stamp", "CLEAR", 3)

	# Resize preserves the pixel pan exactly where legal, clamps only impossible
	# axes, and updates independently measured terrain + all live overlay geometry.
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
	if resize_heart != null:
		var resize_offset_after := resize_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
		h.check(
			"same active map VFX stays anchored through scale change",
			is_instance_valid(resize_heart)
				and resize_offset_after.distance_to(resize_offset_before) < EPS,
			"before %s after %s" % [resize_offset_before, resize_offset_after],
		)
	_check_screen_effect_relayout(h, view, viewport)

	# The same live heart must follow a whitelisted shake and return to exactly
	# the unshaken map anchor after the effect settles.
	var shake_heart := _spawn_heart(juice, IsoProjection.face_center(TARGET_CELL))
	h.check("shake VFX instance exists", shake_heart != null)
	var shake_offset_before := Vector2.ZERO
	if shake_heart != null:
		shake_offset_before = shake_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var grid_before_shake := grid.position
	juice.call("shake", "leak", 6.0, 8)
	await h.frames(1)
	var shake_offset := Vector2.ZERO
	if shake_heart != null and is_instance_valid(shake_heart):
		shake_offset = shake_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
	h.check(
		"whitelisted shake moves the grid",
		grid.position.distance_to(grid_before_shake) > EPS,
		"before %s during %s" % [grid_before_shake, grid.position],
	)
	h.check(
		"same active map VFX stays anchored during shake",
		shake_heart != null and is_instance_valid(shake_heart)
			and shake_offset.distance_to(shake_offset_before) < EPS,
		"base %s during %s" % [shake_offset_before, shake_offset],
	)
	await h.frames(2)
	var late_shake_offset := Vector2.ZERO
	if shake_heart != null and is_instance_valid(shake_heart):
		late_shake_offset = shake_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
	h.check(
		"same active map VFX stays anchored late in shake",
		grid.position.distance_to(grid_before_shake) > EPS
			and shake_heart != null and is_instance_valid(shake_heart)
			and late_shake_offset.distance_to(shake_offset_before) < EPS,
		"base %s late %s grid %s" % [shake_offset_before, late_shake_offset, grid.position],
	)
	await h.frames(5)
	var settled_offset := Vector2.ZERO
	if shake_heart != null and is_instance_valid(shake_heart):
		settled_offset = shake_heart.get_global_rect().get_center() \
			- Vector2(view.call("cell_center", TARGET_CELL))
	h.check(
		"shake settles to exact map base",
		grid.position.distance_to(grid_before_shake) < EPS,
		"expected %s got %s" % [grid_before_shake, grid.position],
	)
	h.check(
		"same active map VFX survives and reanchors after shake",
		shake_heart != null and is_instance_valid(shake_heart)
			and settled_offset.distance_to(shake_offset_before) < EPS,
		"base %s settled %s" % [shake_offset_before, settled_offset],
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

	# Fresh battle isolates a real clipped deployment. The scenario derives the
	# minimum correction from the live presentation rectangle, not MapNavigator.
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	model = game.get("current_battle")
	view = game.get("content") as Node2D
	view.set("ticks_per_frame_scale", 0.0)
	pointer = view.get_viewport_rect().size * 0.5
	var deploy_initial_pan: Vector2 = view.call("map_pan")
	_send_wheel(pointer, MOUSE_BUTTON_WHEEL_DOWN, false)
	await h.frames(2)
	var deploy_pan_before: Vector2 = view.call("map_pan")
	h.check("deploy battle map was actively panned", deploy_pan_before != deploy_initial_pan)
	var deploy_bar := view.find_child("DeployBar", true, false)
	var slot := deploy_bar.find_child("Slot_vanguard_1", true, false) as Button
	h.check("vanguard deploy control available after pan+resize", slot != null and not slot.disabled)
	if slot != null and not slot.disabled:
		await h.press_mouse_at(slot.get_global_rect().get_center())
		h.move_mouse_to_view(view.call("cell_center", EDGE_DEPLOY_CELL))
		await h.frames(2)
		var deploy_cursor := deploy_bar.find_child("CursorRect", true, false) as Polygon2D
		h.check(
			"deploy cursor tracks panned target cell",
			deploy_cursor != null and deploy_cursor.visible
				and deploy_cursor.position.distance_to(view.call("cell_center", EDGE_DEPLOY_CELL)) < EPS,
		)
		h.check(
			"panned target cell remains deploy-valid",
			model.can_deploy_at(&"vanguard_1", EDGE_DEPLOY_CELL),
		)
		await h.release_mouse_at(view.call("cell_center", EDGE_DEPLOY_CELL))
		await h.frames(2)
		var facing := deploy_bar.find_child("FacingRight", true, false) as Button
		h.check("facing chooser tracks panned cell", facing != null and facing.visible)
		if facing != null:
			await h.click_view(facing.get_global_rect().get_center())
		await h.frames(3)
		var deployed := model.alive_unit_at(EDGE_DEPLOY_CELL)
		h.check("deploy lands on clipped boundary cell", deployed != null)
		var unit_node := _find_unit_node(view, EDGE_DEPLOY_CELL)
		h.check("real deployed presentation exists", unit_node != null)
		if unit_node != null:
			var deploy_pan_after: Vector2 = view.call("map_pan")
			var correction := deploy_pan_after - deploy_pan_before
			var visible_rect := _unit_presentation_rect(unit_node)
			var pre_frame_rect := Rect2(visible_rect.position - correction, visible_rect.size)
			var expected_auto_pan := _minimum_visible_pan(
				deploy_pan_before,
				pre_frame_rect,
				view.get_viewport_rect().size,
				view.call("map_pan_bounds"),
			)
			h.check(
				"real deployment was clipped before auto-frame",
				pre_frame_rect.position.x < -EPS or pre_frame_rect.position.y < -EPS
					or pre_frame_rect.end.x > view.get_viewport_rect().size.x + EPS
					or pre_frame_rect.end.y > view.get_viewport_rect().size.y + EPS,
				"pre-frame rect %s viewport %s" % [pre_frame_rect, view.get_viewport_rect().size],
			)
			h.check(
				"real deployment applies minimum auto-frame correction",
				deploy_pan_after.distance_to(expected_auto_pan) < EPS,
				"before %s expected %s got %s" % [
					deploy_pan_before, expected_auto_pan, deploy_pan_after,
				],
			)
			h.check(
				"real deployed body and bars are fully visible",
				_rect_inside_viewport(visible_rect, view.get_viewport_rect().size),
				"rect %s viewport %s" % [visible_rect, view.get_viewport_rect().size],
			)

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
			rect = _polygon_global_bounds(child as Polygon2D)
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				continue
		else:
			continue
		result = rect if first else result.merge(rect)
		first = false
	return result


func _polygon_global_bounds(poly: Polygon2D) -> Rect2:
	var rect := Rect2()
	var first_point := true
	for point: Vector2 in poly.polygon:
		var global_point := poly.to_global(point)
		if first_point:
			rect = Rect2(global_point, Vector2.ZERO)
			first_point = false
		else:
			rect = rect.expand(global_point)
	return rect


func _check_polygon_fallback_bounds(h: SelfTestHarness, view: Node2D) -> void:
	var poly := Polygon2D.new()
	poly.position = Vector2(13.0, 17.0)
	poly.polygon = PackedVector2Array([
		Vector2(-2.0, -1.0), Vector2(4.0, -1.0), Vector2(4.0, 5.0), Vector2(-2.0, 5.0),
	])
	view.add_child(poly)
	var measured := _polygon_global_bounds(poly)
	var expected := Rect2(11.0, 16.0, 6.0, 6.0)
	h.check(
		"Polygon2D fallback union uses every rendered vertex",
		measured.position.distance_to(expected.position) < EPS
			and measured.size.distance_to(expected.size) < EPS,
		"expected %s got %s" % [expected, measured],
	)
	poly.queue_free()


func _check_screen_effect_relayout(
	h: SelfTestHarness, view: Node2D, viewport: Vector2
) -> void:
	var juice := view.find_child("JuiceLayer", true, false)
	var vignette_rects: Array[ColorRect] = []
	for child: Node in juice.get_children():
		if child is ColorRect and (child as ColorRect).color.is_equal_approx(VIGNETTE_COLOR):
			vignette_rects.append(child as ColorRect)
	var expected := [
		Rect2(0, 0, viewport.x, VIGNETTE_THICKNESS),
		Rect2(0, viewport.y - VIGNETTE_THICKNESS, viewport.x, VIGNETTE_THICKNESS),
		Rect2(0, 0, VIGNETTE_THICKNESS, viewport.y),
		Rect2(viewport.x - VIGNETTE_THICKNESS, 0, VIGNETTE_THICKNESS, viewport.y),
	]
	var vignette_ok := vignette_rects.size() == expected.size()
	var measured: Array[Rect2] = []
	for i: int in mini(vignette_rects.size(), expected.size()):
		var rect := vignette_rects[i]
		var actual := Rect2(rect.position, rect.size)
		var spec: Rect2 = expected[i]
		measured.append(actual)
		vignette_ok = vignette_ok and rect.visible \
			and actual.position.distance_to(spec.position) < EPS \
			and actual.size.distance_to(spec.size) < EPS
	h.check(
		"active vignette visibly relayouts top bottom left right one-to-one",
		vignette_ok,
		"visible %s measured %s expected %s" % [
			vignette_rects.map(func(rect: ColorRect) -> bool: return rect.visible),
			measured,
			expected,
		],
	)
	var stamp := view.find_child("ResultStamp", true, false) as Control
	var label := view.find_child("ResultStampLabel", true, false) as Label
	var stars := view.find_child("StampStars", true, false) as Node2D
	h.check(
		"active result stamp relayouts to resized viewport",
		stamp != null and label != null and stars != null
			and stamp.size.distance_to(Vector2(viewport.x, 200.0)) < EPS
			and stamp.position.distance_to(Vector2(0, (viewport.y - 200.0) * 0.5)) < EPS
			and label.size.distance_to(Vector2(viewport.x, 90.0)) < EPS
			and stars.position.distance_to(Vector2(viewport.x * 0.5, 150.0)) < EPS,
		"stamp %s/%s label %s stars %s" % [
			stamp.position if stamp != null else Vector2.INF,
			stamp.size if stamp != null else Vector2.INF,
			label.size if label != null else Vector2.INF,
			stars.position if stars != null else Vector2.INF,
		],
	)


func _spawn_heart(juice: Node, local_center: Vector2) -> ColorRect:
	var root := juice.find_child("MapTransientRoot", true, false) as Node2D
	var prior_ids: Dictionary = {}
	for child: Node in root.get_children():
		prior_ids[child.get_instance_id()] = true
	juice.call("swirl", local_center)
	for child: Node in root.get_children():
		if prior_ids.has(child.get_instance_id()) or not child is ColorRect:
			continue
		var rect := child as ColorRect
		if rect.color.is_equal_approx(HEART_COLOR):
			return rect
	return null


func _find_unit_node(view: Node2D, cell: Vector2i) -> Node2D:
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var expected := IsoProjection.face_center(cell)
	for child: Node in grid.get_children():
		if child is Node2D and child.has_node("Body"):
			var node := child as Node2D
			if node.position.distance_to(expected) < EPS:
				return node
	return null


func _unit_presentation_rect(unit_node: Node2D) -> Rect2:
	var body := unit_node.get_node("Body") as ColorRect
	var result := body.get_global_rect()
	var hp := body.get_node("HpBarBg") as ColorRect
	result = result.merge(hp.get_global_rect())
	var sp := body.get_node_or_null("SpBarBg") as ColorRect
	if sp != null:
		result = result.merge(sp.get_global_rect())
	return result


func _minimum_visible_pan(
	pan: Vector2, screen_rect: Rect2, viewport: Vector2, bounds: Rect2
) -> Vector2:
	var expected := pan
	if screen_rect.position.x < 0.0:
		expected.x -= screen_rect.position.x
	elif screen_rect.end.x > viewport.x:
		expected.x -= screen_rect.end.x - viewport.x
	if screen_rect.position.y < 0.0:
		expected.y -= screen_rect.position.y
	elif screen_rect.end.y > viewport.y:
		expected.y -= screen_rect.end.y - viewport.y
	return Vector2(
		clampf(expected.x, bounds.position.x, bounds.end.x),
		clampf(expected.y, bounds.position.y, bounds.end.y),
	)


func _rect_inside_viewport(rect: Rect2, viewport: Vector2) -> bool:
	return rect.position.x >= -EPS and rect.position.y >= -EPS \
		and rect.end.x <= viewport.x + EPS and rect.end.y <= viewport.y + EPS


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
