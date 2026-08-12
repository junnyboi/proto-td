extends RefCounted

## AUI-10R runtime proof. The checks identify the exact textures and nodes in
## the live BattleView; the windowed shot is the human visual-review artifact.


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 1200
	await h.frames(8)
	var game := h.autoload("Game")
	game.call("start_battle", &"s1")
	await h.frames(12)
	var model: BattleModel = game.get("current_battle")
	var view := game.get("content") as Node2D
	h.check("S1 battle model exists", model != null and model.stage.id == &"s1")
	h.check("S1 BattleView exists", view != null)
	if model == null or view == null:
		h.done()
		return

	var theme := StageArtTheme.load_for(model.stage)
	h.check("S1 runtime theme is active", theme != null and theme.applies_to(model.stage))
	if theme == null:
		h.done()
		return
	h.check("theme carries Poseidon's human-final verdict", theme.human_final_art)

	var grid := view.get_node_or_null("GridRoot") as Node2D
	h.check("GridRoot exists", grid != null)
	if grid == null:
		h.done()
		return

	_check_texture(h, grid, "Tile_1_1", &"world.s1.ground")
	_check_texture(h, grid, "Tile_1_2", &"world.s1.route")
	_check_texture(h, grid, "Tile_0_2", &"world.s1.route")
	_check_texture(h, grid, "Tile_7_2", &"world.s1.route")
	_check_texture(h, grid, "Tile_3_1", &"world.s1.elevated")
	var backdrop_count := 0
	for child: Node in grid.get_children():
		if child.name.begins_with("Backdrop"):
			backdrop_count += 1
	h.check("exactly one mountain panorama renders", backdrop_count == 1)
	var panorama := grid.get_node_or_null("BackdropPanorama") as TextureRect
	h.check("mountain panorama renders", panorama != null)
	if panorama != null:
		h.check(
			"panorama uses approved texture",
			panorama.texture == Art.texture(theme.backdrop_panorama_id),
		)
		h.check(
			"panorama ignores input",
			panorama.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		)

	var notch_count := 0
	for child: Node in grid.get_children():
		if child.name.begins_with("RouteNotch_"):
			notch_count += 1
			var notch := child as TextureRect
			h.check("route notch ignores input", notch.mouse_filter == Control.MOUSE_FILTER_IGNORE)
			h.check("route notch uses approved texture", notch.texture == Art.texture(theme.route_notch_id))
	h.check("exactly three route notches render", notch_count == 3, "count=%d" % notch_count)

	var spawn := grid.get_node_or_null("SpawnLandmark") as TextureRect
	var core := grid.get_node_or_null("CoreLandmark") as TextureRect
	h.check(
		"Spawn landmark renders",
		spawn != null and spawn.texture == Art.texture(theme.spawn_landmark_id),
	)
	h.check(
		"Core landmark renders",
		core != null and core.texture == Art.texture(theme.core_landmark_id),
	)
	if spawn != null:
		var expected_spawn := (
			IsoProjection.face_center(theme.spawn_cell)
			- Vector2(theme.spawn_pivot) * IsoGridBuilder.SPRITE_SCALE
			+ Vector2(theme.spawn_offset) * IsoGridBuilder.SPRITE_SCALE
		)
		h.check("Spawn landmark placement is exact", spawn.position == expected_spawn)
		h.check("Spawn landmark ignores input", spawn.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	if core != null:
		var expected_core := (
			IsoProjection.face_center(theme.core_cell)
			- Vector2(theme.core_pivot) * IsoGridBuilder.SPRITE_SCALE
			+ Vector2(theme.core_offset) * IsoGridBuilder.SPRITE_SCALE
		)
		h.check("Core landmark placement is exact", core.position == expected_core)
		h.check("Core landmark ignores input", core.mouse_filter == Control.MOUSE_FILTER_IGNORE)

	h.check(
		"rain measure is intentionally unplaced",
		grid.find_child("RainMeasure", true, false) == null,
	)
	for cell: Vector2i in [Vector2i(0, 2), Vector2i(3, 1), Vector2i(7, 2)]:
		var picked: Vector2i = view.call("cell_at", view.call("cell_center", cell))
		h.check("theme keeps picking round-trip at %s" % cell, picked == cell, "got %s" % picked)

	# Freeze model progress for a clean art-review frame; render-frame UI
	# transients keep aging, so the 45-frame startup banner clears normally.
	view.set("ticks_per_frame_scale", 0.0)
	await h.frames(52)
	await h.shot("s1_world_integrated")
	h.done()


func _check_texture(
	h: SelfTestHarness, grid: Node2D, node_name: String, expected_id: StringName
) -> void:
	var node := grid.get_node_or_null(node_name) as TextureRect
	h.check("%s exists" % node_name, node != null)
	if node != null:
		h.check("%s uses %s" % [node_name, expected_id], node.texture == Art.texture(expected_id))
		h.check("%s ignores input" % node_name, node.mouse_filter == Control.MOUSE_FILTER_IGNORE)
