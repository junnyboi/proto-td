extends RefCounted

## TD-025 real-battle proof. It deploys the currently admitted classes through
## authoritative model verbs, lets the real combat model emit attack edges,
## and checks that BattleView projects those edges without changing model state.

const CORE_CLASSES: Array[StringName] = [
	&"vanguard_2", &"defender_1", &"vanguard_1", &"guard_1", &"guard_2",
]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1800
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	stage.waves = []
	for _index: int in CORE_CLASSES.size():
		stage.waves.append({"tick": 0, "enemy_id": &"heavy", "path_idx": 0})
	stage.leak_limit = 99
	game.set("pending_stage", stage)
	var model := await _await_battle(h, game)
	h.check("battle started", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	view.set("ticks_per_frame_scale", 0.0)
	# Presentation transients age in render frames. Clear the Wave 1 banner before
	# capturing any operator so idle and attack evidence remains unobscured.
	await h.frames(60)

	for template_id: StringName in CORE_CLASSES:
		var available := model.squad.has(template_id)
		if not available:
			available = model.apply_action([&"debug_grant_operator", template_id])
		h.check("%s available in squad" % template_id, available)
	h.check("grant deployment points", model.apply_action([&"debug_set_dp", 99]))
	var used_cells: Dictionary = {}

	for template_id: StringName in CORE_CLASSES:
		var row := _find_placement(model, view, template_id, used_cells)
		h.check("found %s combat placement" % template_id, not row.is_empty())
		if row.is_empty():
			return
		h.check(
			"deploy %s" % template_id,
			model.apply_action([&"deploy", template_id, row["cell"], row["facing"]]),
		)
		used_cells[row["cell"]] = true
		view.call("_project_units")
		var before_projection := model.state_hash()
		view.call("_project_units")
		h.check(
			"%s projection leaves model hash unchanged" % template_id,
			model.state_hash() == before_projection,
		)
		var unit := _unit_for(model, template_id)
		h.check("%s unit exists" % template_id, unit != null)
		if unit == null:
			return
		_check_body(h, view, unit, &"idle")
		var idle_body := _body_for(view, unit.id)
		var idle_texture_hash := hash(idle_body.texture.get_image().get_data())
		await h.frames(3)
		await h.shot("operator_animation_%s_idle" % template_id)

		var budget := 600
		while budget > 0 and unit.last_attack_tick < 0:
			model.step()
			view.call("_project_units")
			budget -= 1
		h.check("%s attacked in real combat" % template_id, unit.last_attack_tick >= 0)
		if unit.last_attack_tick < 0:
			return
		_check_body(h, view, unit, &"attack")
		var body := _body_for(view, unit.id)
		var target_frame := 6
		var frame_budget := 30
		while frame_budget > 0 and int(
			body.get_meta(&"operator_animation_frame", -1)
		) < target_frame:
			model.step()
			view.call("_project_units")
			frame_budget -= 1
		h.check(
			"%s attack reaches mid-frame" % template_id,
			int(body.get_meta(&"operator_animation_frame", -1)) >= target_frame,
		)
		h.check(
			"%s attack texture differs from idle" % template_id,
			hash(body.texture.get_image().get_data()) != idle_texture_hash,
		)
		await h.shot("operator_animation_%s_attack_mid" % template_id)
		h.check("retreat %s" % template_id, model.apply_action([&"retreat", unit.id]))
		view.call("_project_units")
	h.done()


func _find_placement(
	model: BattleModel,
	view: Node2D,
	template_id: StringName,
	occupied: Dictionary,
) -> Dictionary:
	var stage := model.stage
	var op_defs: Dictionary = model.get("_op_defs")
	var path := stage.path_cells(0)
	for target: Vector2i in path:
		var found := _placement(stage, op_defs[template_id], target, occupied, view)
		if not found.is_empty():
			return found
	return {}


func _placement(
	stage: StageDef,
	definition: OperatorDef,
	target: Vector2i,
	occupied: Dictionary,
	view: Node2D,
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
			var screen: Vector2 = view.call("cell_center", cell)
			if screen.x < 96.0 or screen.x > viewport.x - 96.0:
				continue
			if screen.y < 150.0 or screen.y > viewport.y - 180.0:
				continue
			for facing: int in 4:
				if Targeting.range_cells(cell, definition.range_offsets, facing).has(target):
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
		"%s projects %s" % [unit.op_id, expected_state],
		body.get_meta(&"operator_animation_state", &"") == expected_state,
	)
	h.check(
		"%s projects model facing" % unit.op_id,
		body.get_meta(&"operator_animation_direction", &"")
		== OperatorAnimator.direction_for_facing(int(unit.facing)),
	)
	var logical_id := StringName(body.get_meta(&"operator_animation_id", &""))
	var animation := OperatorVisualCatalog.get_animation(unit.op_id)
	var expected_placeholder := (
		animation != null and animation.is_placeholder(logical_id)
	)
	h.check(
		"%s projects truthfully flagged atlas" % unit.op_id,
		not logical_id.is_empty()
		and bool(Art.metadata(logical_id).get(&"placeholder", true)) == expected_placeholder,
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
