extends RefCounted

## TD-025 real-battle proof. It deploys the currently admitted classes through
## authoritative model verbs, lets the real combat model emit attack edges,
## and checks that BattleView projects those edges without changing model state.


func run(h: SelfTestHarness) -> void:
	h.max_frames = 900
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	stage.waves = [{"tick": 0, "enemy_id": &"mini_boss", "path_idx": 0}]
	stage.leak_limit = 99
	game.set("pending_stage", stage)
	var model := await _await_battle(h, game)
	h.check("battle started", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	view.set("ticks_per_frame_scale", 0.0)

	for template_id: StringName in [&"vanguard_2", &"defender_1"]:
		var available := model.squad.has(template_id)
		if not available:
			available = model.apply_action([&"debug_grant_operator", template_id])
		h.check("%s available in squad" % template_id, available)
	h.check("grant deployment points", model.apply_action([&"debug_set_dp", 99]))
	var placements := _find_pair(model)
	h.check("found sequential real-combat target geometry", not placements.is_empty())
	if placements.is_empty():
		return

	for template_id: StringName in [&"vanguard_2", &"defender_1"]:
		var row: Dictionary = placements[template_id]
		h.check(
			"deploy %s" % template_id,
			model.apply_action([&"deploy", template_id, row["cell"], row["facing"]]),
		)
	view.call("_project_units")
	var before_projection := model.state_hash()
	view.call("_project_units")
	h.check("view projection leaves model hash unchanged", model.state_hash() == before_projection)

	var units: Array[UnitState] = []
	for template_id: StringName in [&"vanguard_2", &"defender_1"]:
		var unit := _unit_for(model, template_id)
		h.check("%s unit exists" % template_id, unit != null)
		if unit != null:
			units.append(unit)
			_check_body(h, view, unit, &"idle")
	if units.size() != 2:
		return
	await h.shot("operator_animation_idle")

	var budget := 600
	while budget > 0 and units[0].last_attack_tick < 0:
		model.step()
		view.call("_project_units")
		budget -= 1
	h.check("Banner Guard attacked in real combat", units[0].last_attack_tick >= 0)
	if units[0].last_attack_tick < 0:
		return
	_check_body(h, view, units[0], &"attack")
	await h.shot("operator_animation_banner_attack_edge")

	for _tick: int in 8:
		model.step()
	view.call("_project_units")
	var banner_body := _body_for(view, units[0].id)
	h.check(
		"Banner Guard attack advances past frame zero",
		int(banner_body.get_meta(&"operator_animation_frame", -1)) > 0,
	)
	await h.shot("operator_animation_banner_attack_mid")
	h.check("retreat Banner Guard", model.apply_action([&"retreat", units[0].id]))
	view.call("_project_units")
	budget = 600
	while budget > 0 and units[1].last_attack_tick < 0:
		model.step()
		view.call("_project_units")
		budget -= 1
	h.check("Defender attacked in real combat", units[1].last_attack_tick >= 0)
	if units[1].last_attack_tick < 0:
		return
	_check_body(h, view, units[1], &"attack")
	await h.shot("operator_animation_defender_attack_edge")
	for _tick: int in 8:
		model.step()
	view.call("_project_units")
	var defender_body := _body_for(view, units[1].id)
	h.check(
		"Defender attack advances past frame zero",
		int(defender_body.get_meta(&"operator_animation_frame", -1)) > 0,
	)
	await h.shot("operator_animation_defender_attack_mid")
	h.done()


func _find_pair(model: BattleModel) -> Dictionary:
	var stage := model.stage
	var op_defs: Dictionary = model.get("_op_defs")
	var path := stage.path_cells(0)
	var result: Dictionary = {}
	var occupied: Dictionary = {}
	for template_id: StringName in [&"vanguard_2", &"defender_1"]:
		var found: Dictionary = {}
		for target: Vector2i in path:
			found = _placement(stage, op_defs[template_id], target, occupied)
			if not found.is_empty():
				break
		if found.is_empty():
			return {}
		result[template_id] = found
		occupied[found["cell"]] = true
	return result


func _placement(
	stage: StageDef,
	definition: OperatorDef,
	target: Vector2i,
	occupied: Dictionary,
) -> Dictionary:
	var size := stage.grid_size()
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if occupied.has(cell) or not stage.operator_cell_in_domain(definition, cell):
				continue
			for facing: int in 4:
				if Targeting.range_cells(cell, definition.range_offsets, facing).has(target):
					return {"cell": cell, "facing": facing}
	return {}


func _unit_for(model: BattleModel, template_id: StringName) -> UnitState:
	for unit: UnitState in model.units:
		if unit.op_id == template_id:
			return unit
	return null


func _check_body(
	h: SelfTestHarness,
	view: Node2D,
	unit: UnitState,
	expected_state: StringName,
) -> void:
	var body := _body_for(view, unit.id)
	h.check("%s has projected body" % unit.op_id, body != null)
	if body == null:
		return
	h.check(
		"%s projects %s" % [unit.op_id, expected_state],
		body.get_meta(&"operator_animation_state", &"") == expected_state,
	)
	h.check(
		"%s projects model facing" % unit.op_id,
		body.get_meta(&"operator_animation_direction", &"")
		== OperatorAnimator.direction_for_facing(int(unit.facing)),
	)
	var logical_id := StringName(body.get_meta(&"operator_animation_id", &""))
	h.check(
		"%s projects non-placeholder atlas" % unit.op_id,
		not logical_id.is_empty() and not bool(Art.metadata(logical_id).get(&"placeholder", true)),
	)


func _body_for(view: Node2D, unit_id: int) -> TextureRect:
	var nodes: Dictionary = view.get("_unit_nodes")
	if not nodes.has(unit_id):
		return null
	return (nodes[unit_id] as Node2D).get_node("Body/Sprite") as TextureRect


func _await_battle(h: SelfTestHarness, game: Node) -> BattleModel:
	var budget := 120
	while budget > 0:
		var model := game.get("current_battle") as BattleModel
		var content := game.get("content") as Node
		if model != null and content is Node2D:
			await h.frames(3)
			return model
		budget -= 1
		await h.frames(1)
	return null
