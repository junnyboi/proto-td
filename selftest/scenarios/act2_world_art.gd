extends RefCounted

func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 1200
	await h.frames(8)
	await _check_stage(h, &"s2", 59)
	await _check_stage(h, &"s3", 68)
	h.done()

func _check_stage(h: SelfTestHarness, stage_id: StringName, expected_count: int) -> void:
	var game := h.autoload("Game")
	game.call("start_battle", stage_id)
	await h.frames(14)
	var model: BattleModel = game.get("current_battle")
	var view := game.get("content") as Node2D
	h.check("%s real model/view exists" % stage_id, model != null and model.stage.id == stage_id and view != null)
	if model == null or view == null:
		return
	var theme := StageArtTheme.load_for(model.stage)
	h.check("%s real theme active and H1 pending" % stage_id, theme != null and not theme.human_final_art and theme.approval_manifest_sha256.is_empty())
	var grid := view.get_node_or_null("GridRoot") as Node2D
	h.check("%s GridRoot exact inventory" % stage_id, grid != null and grid.get_child_count() == expected_count)
	if theme == null or grid == null:
		return
	var panorama_count := 0
	var cadence_count := 0
	var dynamic_count := 0
	for child: Node in grid.get_children():
		if child.name == "BackdropPanorama": panorama_count += 1
		if child.name.begins_with("Cadence_"): cadence_count += 1
		if child is Light2D or child is GPUParticles2D or child is CPUParticles2D: dynamic_count += 1
	h.check("%s exactly one panorama" % stage_id, panorama_count == 1)
	h.check("%s exactly four cadence overlays" % stage_id, cadence_count == 4)
	h.check("%s has no dynamic lights or particles" % stage_id, dynamic_count == 0)
	_check_texture(h, grid, "BackdropPanorama", theme.backdrop_panorama_id)
	_check_texture(h, grid, "SpawnLandmark", theme.spawn_landmark_id)
	_check_texture(h, grid, "CoreLandmark", theme.core_landmark_id)
	for cell: Vector2i in theme.cadence_cells:
		_check_texture(h, grid, "Cadence_%d_%d" % [cell.x, cell.y], theme.cadence_id_at(cell))
	for index: int in theme.elevated_cells.size():
		var cell := theme.elevated_cells[index]
		_check_texture(h, grid, "Tile_%d_%d" % [cell.x, cell.y], theme.elevated_variant_ids[index])
	for index: int in theme.blocked_cells.size():
		var cell := theme.blocked_cells[index]
		_check_texture(h, grid, "Tile_%d_%d" % [cell.x, cell.y], theme.blocked_variant_ids[index])
	for cell: Vector2i in [theme.spawn_cell, theme.core_cell, theme.elevated_cells[0]]:
		var picked: Vector2i = view.call("cell_at", view.call("cell_center", cell))
		h.check("%s picking round-trip %s" % [stage_id, cell], picked == cell, "got %s" % picked)
	view.set("ticks_per_frame_scale", 0.0)
	await h.frames(52)
	await h.shot("%s_world_integrated" % stage_id)

func _check_texture(h: SelfTestHarness, grid: Node2D, node_name: String, id: StringName) -> void:
	var node := grid.get_node_or_null(node_name) as TextureRect
	h.check("%s exists" % node_name, node != null)
	if node != null:
		h.check("%s exact texture" % node_name, node.texture == Art.texture(id))
		h.check("%s ignores input" % node_name, node.mouse_filter == Control.MOUSE_FILTER_IGNORE)
