extends RefCounted

const HEROES: Array[StringName] = [
	&"caster_1", &"caster_2", &"defender_2", &"sniper_1", &"sniper_2",
]
const FACINGS: Dictionary = {
	&"caster_1": UnitState.Facing.RIGHT,
	&"caster_2": UnitState.Facing.DOWN,
	&"defender_2": UnitState.Facing.LEFT,
	&"sniper_1": UnitState.Facing.UP,
	&"sniper_2": UnitState.Facing.UP,
}


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	stage.grid_rows = PackedStringArray(
		["EEEEEEEE", "EEEEEEEE", "SGGGGGB.", "EEEEEEEE", "EEEEEEEE"]
	)
	stage.waves = [{"tick": 0, "enemy_id": &"mini_boss", "path_idx": 0}]
	stage.leak_limit = 99
	game.set("pending_stage", stage)
	var model := await _await_battle(h, game)
	h.check("Part 2 battle started", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	view.set("ticks_per_frame_scale", 0.0)
	for template_id: StringName in HEROES:
		var available := model.squad.has(template_id)
		if not available:
			available = model.apply_action([&"debug_grant_operator", template_id])
		h.check("%s available" % template_id, available)
	h.check("Part 2 deployment points granted", model.apply_action([&"debug_set_dp", 99]))
	var placements := _find_placements(model, view)
	h.check("five legal combat placements found", placements.size() == HEROES.size())
	if placements.size() != HEROES.size():
		return
	for template_id: StringName in HEROES:
		var row := placements[template_id] as Dictionary
		h.check(
			"deploy %s" % template_id,
			model.apply_action([&"deploy", template_id, row["cell"], row["facing"]]),
		)
	view.call("_project_units")
	var before_projection := model.state_hash()
	view.call("_project_units")
	h.check("Part 2 projection leaves model hash unchanged", model.state_hash() == before_projection)
	var units: Array[UnitState] = []
	for template_id: StringName in HEROES:
		var unit := _unit_for(model, template_id)
		h.check("%s unit exists" % template_id, unit != null)
		if unit != null:
			units.append(unit)
			_check_body(h, view, unit, &"idle")
	if units.size() != HEROES.size():
		return
	await h.frames(60)
	await h.shot("operator_animation_part2_idle")

	var attacked: Dictionary = {}
	var advanced: Dictionary = {}
	var sniper_placeholder_seen := false
	var budget := 240
	while budget > 0 and (attacked.size() < HEROES.size() or advanced.size() < HEROES.size()):
		model.step()
		view.call("_project_units")
		for unit: UnitState in units:
			var body := _body_for(view, unit.id)
			var state := StringName(body.get_meta(&"operator_animation_state", &""))
			var frame := int(body.get_meta(&"operator_animation_frame", -1))
			if state == &"attack" and unit.last_attack_tick >= 0 and not attacked.has(unit.id):
				attacked[unit.id] = true
				_check_body(h, view, unit, &"attack")
			if state == &"attack" and frame > 0:
				advanced[unit.id] = true
			if unit.op_id == &"sniper_2" and state == &"attack":
				var logical_id := StringName(body.get_meta(&"operator_animation_id", &""))
				var definition := OperatorVisualCatalog.get_animation(&"sniper_2")
				sniper_placeholder_seen = (
					logical_id == &"op_anim_sniper_2_attack_ne"
					and bool(Art.metadata(logical_id).get(&"placeholder", false))
					and definition.placeholder_source_direction(logical_id) == &"se"
				)
		budget -= 1
	h.check("all five heroes attacked in real combat", attacked.size() == HEROES.size())
	if attacked.size() != HEROES.size():
		return
	h.check(
		"all five attack animations advance past frame zero",
		advanced.size() == HEROES.size(),
		"advanced=%d" % advanced.size(),
	)
	h.check("sniper_2 projects its declared NE-from-SE attack placeholder", sniper_placeholder_seen)
	await h.frames(3)
	await h.shot("operator_animation_part2_attack_mid")
	h.done()


func _find_placements(model: BattleModel, view: Node2D) -> Dictionary:
	var stage := model.stage
	var op_defs: Dictionary = model.get("_op_defs")
	var result: Dictionary = {}
	var occupied: Dictionary = {}
	for template_id: StringName in HEROES:
		var found: Dictionary = {}
		for target: Vector2i in stage.path_cells(0):
			found = _placement(
				stage, op_defs[template_id], target, occupied, view, int(FACINGS[template_id])
			)
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
	view: Node2D,
	facing: int,
) -> Dictionary:
	var size := stage.grid_size()
	var viewport := view.get_viewport_rect().size
	var best: Dictionary = {}
	var best_score := INF
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if occupied.has(cell) or not stage.operator_cell_in_domain(definition, cell):
				continue
			if not Targeting.range_cells(cell, definition.range_offsets, facing).has(target):
				continue
			var screen: Vector2 = view.call("cell_center", cell)
			if screen.x < 96.0 or screen.x > viewport.x - 96.0:
				continue
			if screen.y < 150.0 or screen.y > viewport.y - 180.0:
				continue
			var score := absf(screen.y - viewport.y * 0.52)
			score += absf(screen.x - viewport.x * 0.5) * 0.2
			if score < best_score:
				best_score = score
				best = {"cell": cell, "facing": facing}
	return best


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
		"%s sprite obeys calibrated footprint" % unit.op_id,
		body.expand_mode == TextureRect.EXPAND_IGNORE_SIZE and body.size.y < 96.0,
		"size=%s" % body.size,
	)
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
	h.check("%s resolves an admitted atlas" % unit.op_id, not logical_id.is_empty())


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
