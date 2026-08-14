extends RefCounted

const IDS: Array[StringName] = [
	&"world.act1.ground",
	&"world.act1.route",
	&"world.act1.raised",
	&"world.act1.blocked",
	&"world.act1.spawn",
	&"world.act1.core",
	&"world.act1.panorama",
	&"world.act1.env.boulder",
	&"world.act1.env.barrel",
	&"world.act1.env.wall",
	&"world.act1.env.crate",
]
const COUNTS := {&"s1": 51, &"s2": 61, &"s3": 69}


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 900
	await h.frames(8)
	for stage_id: StringName in [&"s1", &"s2", &"s3"]:
		await _check_stage(h, stage_id)
	h.done()


func _check_stage(h: SelfTestHarness, stage_id: StringName) -> void:
	var game := h.autoload("Game")
	game.call("start_battle", stage_id)
	await h.frames(14)
	var model: BattleModel = game.get("current_battle")
	var view := game.get("content") as Node2D
	h.check(
		"%s model/view active" % stage_id,
		model != null and model.stage.id == stage_id and view != null
	)
	if model == null or view == null:
		return
	view.set("ticks_per_frame_scale", 0.0)
	var theme := StageArtTheme.load_for(model.stage)
	h.check(
		"%s shared theme active" % stage_id,
		theme != null and theme.theme_id == StageArtTheme.SHARED_THEME_ID
	)
	if theme == null:
		return
	h.check("%s exact shared IDs" % stage_id, theme.required_manifest_ids() == IDS)
	h.check(
		"%s approved token and human-final verdict" % stage_id,
		theme.approval_token == StageArtTheme.APPROVAL_TOKEN and theme.human_final_art
	)
	var grid := view.get_node_or_null("GridRoot") as Node2D
	h.check(
		"%s GridRoot exact inventory" % stage_id,
		grid != null and grid.get_child_count() == COUNTS[stage_id],
		"actual=%d expected=%d" % [grid.get_child_count() if grid != null else -1, COUNTS[stage_id]]
	)
	if grid == null:
		return
	(
		h
		. check(
			"%s shared Act I framing fills the review canvas" % stage_id,
			is_equal_approx(grid.scale.x, 1.75) and is_equal_approx(grid.scale.y, 1.75),
			"grid_scale=%s expected=(1.75, 1.75)" % grid.scale,
		)
	)
	var cadence_count := 0
	var prop_count := 0
	for child: Node in grid.get_children():
		if child.name.begins_with("Cadence_"):
			cadence_count += 1
		if child.name.begins_with("EnvProp_"):
			prop_count += 1
	h.check("%s zero cadence nodes" % stage_id, cadence_count == 0)
	(
		h
		. check(
			"%s exact environment prop count" % stage_id,
			prop_count == theme.env_prop_cells.size(),
			"actual=%d expected=%d" % [prop_count, theme.env_prop_cells.size()],
		)
	)
	_check_texture(h, grid, stage_id, "BackdropPanorama", &"world.act1.panorama")
	_check_texture(h, grid, stage_id, "SpawnLandmark", &"world.act1.spawn")
	_check_texture(h, grid, stage_id, "CoreLandmark", &"world.act1.core")
	for cell: Vector2i in theme.elevated_cells:
		_check_texture(h, grid, stage_id, "BaseTile_%d_%d" % [cell.x, cell.y], &"world.act1.ground")
		_check_texture(h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.raised")
	for cell: Vector2i in theme.env_prop_cells:
		(
			h
			. check(
				"%s %s remains gameplay-blocked" % [stage_id, cell],
				model.stage.tile_at(cell) == StageDef.Tile.BLOCKED,
			)
		)
		_check_texture(h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.ground")
	await h.frames(52)
	await h.shot("%s_act1_shared_clean" % stage_id)
	if stage_id == &"s1":
		await _check_selection_ring(h, model, view)


func _check_selection_ring(h: SelfTestHarness, model: BattleModel, view: Node2D) -> void:
	var cell := Vector2i(1, 1)
	var op_id: StringName = model.squad[0]
	var deployed := model.apply_action([&"deploy", op_id, cell, int(UnitState.Facing.RIGHT)])
	h.check("S1 tower deployed for selection ring", deployed)
	if not deployed:
		return
	var unit: UnitState = model.units[-1]
	var deploy_seen: Dictionary = view.get("_deploy_seen")
	var settle_budget := 32
	while int(deploy_seen.get(unit.id, -1)) != 0 and settle_budget > 0:
		settle_budget -= 1
		await h.frames(1)
	h.check(
		"deployment auto-frame settled before selection",
		int(deploy_seen.get(unit.id, -1)) == 0,
		"remaining=%d" % int(deploy_seen.get(unit.id, -1)),
	)
	await h.click_view(view.call("cell_center", cell))
	await h.frames(3)
	var ring := view.find_child("SelectionRing", true, false) as Node2D
	var deploy_bar := view.find_child("DeployBar", true, false)
	var selected_id := int(deploy_bar.get("_selected_unit_id")) if deploy_bar != null else -2
	var expected: Vector2 = view.call("cell_center", cell)
	var picked: Vector2i = view.call("cell_at", expected)
	h.check(
		"selected tower rotating ring visible",
		ring != null and ring.visible,
		"selected=%d picked=%s ring=%s" % [selected_id, picked, ring],
	)
	if ring != null:
		h.check(
			"selection ring centered on tower feet",
			ring.position.distance_to(expected) < 1.0,
			"actual=%s expected=%s selected=%d" % [ring.position, expected, selected_id],
		)
		var first_phase := float(ring.get("_phase"))
		await h.frames(6)
		(
			h
			. check(
				"selected tower ring rotates",
				absf(float(ring.get("_phase")) - first_phase) > 0.01,
				"before=%f after=%f" % [first_phase, float(ring.get("_phase"))],
			)
		)
	await h.shot("s1_act1_selected_tower")


func _check_texture(
	h: SelfTestHarness, grid: Node2D, stage_id: StringName, node_name: String, id: StringName
) -> void:
	var node := grid.get_node_or_null(node_name) as TextureRect
	h.check(
		"%s %s exact %s" % [stage_id, node_name, id],
		node != null and node.texture == Art.texture(id)
	)
