extends RefCounted

const STAGE_IDS: Array[StringName] = [&"s2", &"s3"]
const CAPTURE_SQUAD: Array[StringName] = [
	&"vanguard_1", &"guard_1", &"defender_1", &"caster_1",
]
const BOOT_FRAMES := 8
const STAGE_FRAME_BUDGET := 600
const STARTUP_FRAMES := 14
const CLEAN_TICK := 8
const BANNER_SETTLE_FRAMES := 52
const POPULATED_TICK := 150
const PROJECTION_SETTLE_FRAMES := 8
const CURSOR_EPS := 0.01


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = BOOT_FRAMES + STAGE_IDS.size() * STAGE_FRAME_BUDGET
	await h.frames(BOOT_FRAMES)
	var game := h.autoload("Game")
	var saved_default_squad: Array[StringName] = game.get("default_squad").duplicate()
	game.set("default_squad", CAPTURE_SQUAD.duplicate())
	await _check_stage(h, &"s2", 59)
	await _check_stage(h, &"s3", 68)
	game.set("default_squad", saved_default_squad)
	h.check(
		"Game.default_squad restored after Act II captures",
		game.get("default_squad") == saved_default_squad,
		"restored=%s expected=%s" % [game.get("default_squad"), saved_default_squad],
	)
	h.done()


func _check_stage(h: SelfTestHarness, stage_id: StringName, expected_count: int) -> void:
	var game := h.autoload("Game")
	game.call("start_battle", stage_id)
	var model: BattleModel = null
	var view: Node2D = null
	for _frame: int in STARTUP_FRAMES:
		await h.frames(1)
		model = game.get("current_battle")
		view = game.get("content") as Node2D
		if model != null and view != null:
			view.set("ticks_per_frame_scale", 0.0)
			break
	h.check(
		"%s real model/view exists" % stage_id,
		model != null and model.stage.id == stage_id and view != null,
		"model=%s model_stage=%s view=%s" % [
			model != null, model.stage.id if model != null else &"", view != null,
		],
	)
	if model == null or view == null:
		return
	var theme := StageArtTheme.load_for(model.stage)
	h.check(
		"%s real theme active and H1 pending" % stage_id,
		theme != null and not theme.human_final_art and theme.approval_manifest_sha256.is_empty(),
		"theme=%s human_final=%s approval_sha='%s'" % [
			theme != null,
			theme.human_final_art if theme != null else true,
			theme.approval_manifest_sha256 if theme != null else "missing",
		],
	)
	var grid := view.get_node_or_null("GridRoot") as Node2D
	h.check(
		"%s GridRoot exact inventory" % stage_id,
		grid != null and grid.get_child_count() == expected_count,
		"children=%d expected=%d" % [grid.get_child_count() if grid != null else -1, expected_count],
	)
	if theme == null or grid == null:
		return
	var panorama_count := 0
	var cadence_count := 0
	var dynamic_count := 0
	for child: Node in grid.get_children():
		if child.name == "BackdropPanorama": panorama_count += 1
		if child.name.begins_with("Cadence_"): cadence_count += 1
		if child is Light2D or child is GPUParticles2D or child is CPUParticles2D: dynamic_count += 1
	h.check(
		"%s exactly one panorama" % stage_id,
		panorama_count == 1,
		"panoramas=%d expected=1" % panorama_count,
	)
	h.check(
		"%s exactly four cadence overlays" % stage_id,
		cadence_count == 4,
		"cadence_overlays=%d expected=4" % cadence_count,
	)
	h.check(
		"%s has no dynamic lights or particles" % stage_id,
		dynamic_count == 0,
		"dynamic_nodes=%d expected=0" % dynamic_count,
	)
	_check_texture(h, grid, stage_id, "BackdropPanorama", theme.backdrop_panorama_id)
	_check_texture(h, grid, stage_id, "SpawnLandmark", theme.spawn_landmark_id)
	_check_texture(h, grid, stage_id, "CoreLandmark", theme.core_landmark_id)
	for cell: Vector2i in theme.cadence_cells:
		_check_texture(
			h, grid, stage_id, "Cadence_%d_%d" % [cell.x, cell.y], theme.cadence_id_at(cell)
		)
	for index: int in theme.elevated_cells.size():
		var cell := theme.elevated_cells[index]
		_check_texture(
			h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], theme.elevated_variant_ids[index]
		)
	for index: int in theme.blocked_cells.size():
		var cell := theme.blocked_cells[index]
		_check_texture(
			h, grid, stage_id, "Tile_%d_%d" % [cell.x, cell.y], theme.blocked_variant_ids[index]
		)
	var picking_cells := _picking_cells(model.stage, theme)
	for cell: Vector2i in picking_cells:
		var picked: Vector2i = view.call("cell_at", view.call("cell_center", cell))
		h.check(
			"%s picking round-trip %s" % [stage_id, cell],
			picked == cell,
			"center=%s picked=%s expected=%s coverage=%d" % [
				view.call("cell_center", cell), picked, cell, picking_cells.size(),
			],
		)
	await _advance_view_to_tick(h, view, model, CLEAN_TICK)
	view.set("ticks_per_frame_scale", 0.0)
	await h.frames(BANNER_SETTLE_FRAMES)
	h.check(
		"%s clean capture frozen at tick %d" % [stage_id, CLEAN_TICK],
		model.tick == CLEAN_TICK and model.deployed_count() == 0 and model.alive_enemy_count() == 0,
		"tick=%d units=%d enemies=%d scale=%.1f settle_frames=%d" % [
			model.tick, model.deployed_count(), model.alive_enemy_count(),
			float(view.get("ticks_per_frame_scale")), BANNER_SETTLE_FRAMES,
		],
	)
	await h.shot("%s_world_clean" % stage_id)

	h.check(
		"%s DP funded through debug_set_dp" % stage_id,
		model.apply_action([&"debug_set_dp", 99]),
		"tick=%d requested_dp=99 dp_after=%d" % [model.tick, model.dp],
	)
	var deployments := _deployments_for(stage_id)
	for row: Array in deployments:
		var op_id: StringName = row[0]
		var cell: Vector2i = row[1]
		var facing := int(row[2])
		var is_non_route := not model.stage.path_cells(0).has(cell)
		var deployed := model.apply_action([&"deploy", op_id, cell, facing])
		var unit := model.alive_unit_at(cell)
		h.check(
			"%s normal deploy %s on legal non-route cell" % [stage_id, op_id],
			is_non_route and deployed and unit != null and int(unit.facing) == facing,
			"cell=%s non_route=%s deployed=%s live=%s facing=%d expected_facing=%d dp=%d" % [
				cell, is_non_route, deployed, unit != null,
				int(unit.facing) if unit != null else -1, facing, model.dp,
			],
		)
	await _advance_view_to_tick(h, view, model, POPULATED_TICK)
	view.set("ticks_per_frame_scale", 0.0)
	await h.frames(PROJECTION_SETTLE_FRAMES)
	var live_unit_nodes := _live_unit_node_count(grid)
	var live_enemy_nodes := _live_enemy_node_count(grid)
	var alive_units := model.deployed_count()
	var alive_enemies := model.alive_enemy_count()
	h.check(
		"%s deterministic populated model remains running" % stage_id,
		model.result == BattleModel.Result.RUNNING and model.tick == POPULATED_TICK
			and alive_units >= 3 and alive_enemies >= 2,
		"tick=%d target=%d result=%d units=%d enemies=%d killed=%d leaked=%d" % [
			model.tick, POPULATED_TICK, int(model.result), alive_units, alive_enemies,
			model.killed, model.leaked,
		],
	)
	h.check(
		"%s populated view projects 3+ units and 2+ enemies" % stage_id,
		live_unit_nodes >= 3 and live_enemy_nodes >= 2,
		"unit_nodes=%d model_units=%d enemy_nodes=%d model_enemies=%d settle_frames=%d" % [
			live_unit_nodes, alive_units, live_enemy_nodes, alive_enemies, PROJECTION_SETTLE_FRAMES,
		],
	)
	if stage_id == &"s3":
		var choke_presence := _enemy_cells(model).filter(
			func(cell: Vector2i) -> bool:
				return cell in [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)]
		)
		h.check(
			"s3 populated state has enemy presence around the E-S-E choke",
			not choke_presence.is_empty(),
			"enemy_cells=%s choke_cells=%s matches=%s tick=%d" % [
				_enemy_cells(model), [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)],
				choke_presence, model.tick,
			],
		)
	await h.shot("%s_world_populated" % stage_id)

	var target_cell := Vector2i(4, 2) if stage_id == &"s2" else Vector2i(4, 3)
	var spell_bar := view.find_child("SpellBar", true, false) as SpellBar
	var bolt := view.find_child("Spell_bolt", true, false) as Button
	h.check(
		"%s real SpellBar Bolt targeting control available" % stage_id,
		spell_bar != null and bolt != null and not bolt.disabled,
		"spell_bar=%s bolt=%s disabled=%s tick=%d" % [
			spell_bar != null, bolt != null, bolt.disabled if bolt != null else true, model.tick,
		],
	)
	if spell_bar == null or bolt == null:
		return
	var casts_before: int = model.spell_book.total_casts()
	spell_bar.call("_start_targeting", &"bolt")
	h.move_mouse_to_view(view.call("cell_center", target_cell))
	await h.frames(2)
	var spell_cursor := view.find_child("SpellCursor", true, false) as Polygon2D
	var cursor_center := spell_cursor.position if spell_cursor != null else Vector2(-1, -1)
	var expected_center: Vector2 = view.call("cell_center", target_cell)
	var polygon_points := spell_cursor.polygon.size() if spell_cursor != null else 0
	h.check(
		"%s real Bolt cursor targets key cell %s" % [stage_id, target_cell],
		spell_cursor != null and spell_cursor.visible and polygon_points > 0
			and cursor_center.distance_to(expected_center) < CURSOR_EPS,
		"visible=%s polygon_points=%d center=%s expected=%s distance=%.4f tick=%d" % [
			spell_cursor.visible if spell_cursor != null else false, polygon_points,
			cursor_center, expected_center, cursor_center.distance_to(expected_center), model.tick,
		],
	)
	await h.shot("%s_world_targeting" % stage_id)
	var casts_after: int = model.spell_book.total_casts()
	h.check(
		"%s targeting capture does not cast Bolt" % stage_id,
		casts_after == casts_before and model.tick == POPULATED_TICK,
		"casts_before=%d casts_after=%d tick=%d frozen_tick=%d" % [
			casts_before, casts_after, model.tick, POPULATED_TICK,
		],
	)
	spell_bar.call("_stop_targeting")
	await h.frames(1)
	h.check(
		"%s Bolt targeting stopped after capture" % stage_id,
		not spell_cursor.visible,
		"cursor_visible=%s tick=%d" % [spell_cursor.visible, model.tick],
	)


func _advance_view_to_tick(
	h: SelfTestHarness, view: Node2D, model: BattleModel, target_tick: int
) -> void:
	view.set("ticks_per_frame_scale", 0.0)
	while model.tick < target_tick and model.result == BattleModel.Result.RUNNING:
		model.step()
	await h.physics_frames(1)
	await h.frames(1)


func _picking_cells(stage: StageDef, theme: StageArtTheme) -> Array[Vector2i]:
	var unique: Dictionary = {}
	for path_index: int in stage.paths.size():
		var path := stage.path_cells(path_index)
		if not path.is_empty():
			unique[path.front()] = true
			unique[path.back()] = true
	for cell: Vector2i in theme.elevated_cells:
		unique[cell] = true
	for cell: Vector2i in theme.blocked_cells:
		unique[cell] = true
	for cell: Vector2i in theme.cadence_cells:
		unique[cell] = true
	if stage.id == &"s3":
		unique[Vector2i(4, 3)] = true
	unique[Vector2i(1, 0)] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in unique:
		cells.append(cell)
	return cells


func _deployments_for(stage_id: StringName) -> Array[Array]:
	if stage_id == &"s2":
		return [
			[&"vanguard_1", Vector2i(8, 0), int(UnitState.Facing.RIGHT)],
			[&"guard_1", Vector2i(8, 1), int(UnitState.Facing.DOWN)],
			[&"defender_1", Vector2i(8, 3), int(UnitState.Facing.LEFT)],
			[&"caster_1", Vector2i(3, 1), int(UnitState.Facing.UP)],
		]
	return [
		[&"vanguard_1", Vector2i(8, 1), int(UnitState.Facing.RIGHT)],
		[&"guard_1", Vector2i(8, 2), int(UnitState.Facing.DOWN)],
		[&"defender_1", Vector2i(8, 3), int(UnitState.Facing.LEFT)],
		[&"caster_1", Vector2i(2, 3), int(UnitState.Facing.UP)],
	]


func _enemy_cells(model: BattleModel) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for enemy: EnemyState in model.enemies:
		if enemy.alive:
			cells.append(Pathing.cell_of(model.path_for(enemy.path_idx), enemy.progress_units))
	return cells


func _live_unit_node_count(grid: Node2D) -> int:
	var count := 0
	for child: Node in grid.get_children():
		if child is Node2D and child.get_node_or_null("Body") != null:
			count += 1
	return count


func _live_enemy_node_count(grid: Node2D) -> int:
	var count := 0
	for child: Node in grid.get_children():
		if child is ColorRect and child.name.begins_with("Enemy"):
			count += 1
	return count


func _check_texture(
	h: SelfTestHarness, grid: Node2D, stage_id: StringName, node_name: String, id: StringName
) -> void:
	var node := grid.get_node_or_null(node_name) as TextureRect
	h.check(
		"%s %s exists" % [stage_id, node_name],
		node != null,
		"node=%s path=GridRoot/%s expected_texture_id=%s" % [node != null, node_name, id],
	)
	if node != null:
		h.check(
			"%s %s exact texture" % [stage_id, node_name],
			node.texture == Art.texture(id),
			"actual_rid=%s expected_rid=%s texture_id=%s" % [
				node.texture.get_rid() if node.texture != null else RID(),
				Art.texture(id).get_rid() if Art.texture(id) != null else RID(), id,
			],
		)
		h.check(
			"%s %s ignores input" % [stage_id, node_name],
			node.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"mouse_filter=%d expected=%d" % [
				node.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			],
		)
