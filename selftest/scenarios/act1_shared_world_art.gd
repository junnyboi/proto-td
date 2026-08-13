extends RefCounted

const IDS: Array[StringName] = [
	&"world.act1.ground",
	&"world.act1.route",
	&"world.act1.raised",
	&"world.act1.blocked",
	&"world.act1.spawn",
	&"world.act1.core",
	&"world.act1.panorama",
]
const COUNTS := {&"s1": 45, &"s2": 55, &"s3": 64}


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
		"%s approved token and pending final verdict" % stage_id,
		theme.approval_token == StageArtTheme.APPROVAL_TOKEN and not theme.human_final_art
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
	for child: Node in grid.get_children():
		if child.name.begins_with("Cadence_"):
			cadence_count += 1
	h.check("%s zero cadence nodes" % stage_id, cadence_count == 0)
	_check_texture(h, grid, stage_id, "BackdropPanorama", &"world.act1.panorama")
	_check_texture(h, grid, stage_id, "SpawnLandmark", &"world.act1.spawn")
	_check_texture(h, grid, stage_id, "CoreLandmark", &"world.act1.core")
	for cell: Vector2i in theme.elevated_cells:
		_check_texture(h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.raised")
	for cell: Vector2i in theme.blocked_cells:
		_check_texture(h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.blocked")
	await h.frames(52)
	await h.shot("%s_act1_shared_clean" % stage_id)


func _check_texture(
	h: SelfTestHarness, grid: Node2D, stage_id: StringName, node_name: String, id: StringName
) -> void:
	var node := grid.get_node_or_null(node_name) as TextureRect
	h.check(
		"%s %s exact %s" % [stage_id, node_name, id],
		node != null and node.texture == Art.texture(id)
	)
