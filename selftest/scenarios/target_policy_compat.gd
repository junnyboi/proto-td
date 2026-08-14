extends RefCounted

const RIGHT := int(UnitState.Facing.RIGHT)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 600
	var sniper_model := _ranged_model(&"sniper_1")
	var sniper_before := BattleObservation.from_model(sniper_model).sha256()
	var sniper := TargetDecisionProjection.unit_target_decision(sniper_model, 0)
	h.check(
		"Sniper policy prefers aerial",
		int(sniper["selected_id"]) == 1,
		"selected=%s policy=%s" % [sniper["selected_id"], sniper["policy_id"]],
	)
	h.check(
		"target diagnostic preserves TD-OBS",
		BattleObservation.from_model(sniper_model).sha256() == sniper_before,
		"observation=%s" % sniper_before,
	)
	var caster := TargetDecisionProjection.unit_target_decision(
		_ranged_model(&"caster_1"), 0
	)
	h.check(
		"Caster policy excludes aerial",
		int(caster["selected_id"]) == 0,
		"selected=%s policy=%s" % [caster["selected_id"], caster["policy_id"]],
	)
	var melee_model := _melee_model()
	var melee := TargetDecisionProjection.unit_target_decision(melee_model, 0)
	h.check(
		"melee policy preserves blocked assignment order",
		melee_model.units[0].blocked_ids == [0, 1]
		and int(melee["selected_id"]) == 0,
		"blocked=%s selected=%s" % [melee_model.units[0].blocked_ids, melee["selected_id"]],
	)
	var enemy_model := _enemy_model()
	var nearest := TargetDecisionProjection.enemy_target_decision(enemy_model, 0)
	enemy_model.enemies[0].blocked_by = 1
	var blocked := TargetDecisionProjection.enemy_target_decision(enemy_model, 0)
	h.check(
		"enemy policy uses nearest then current blocker",
		int(nearest["selected_id"]) == 0 and int(blocked["selected_id"]) == 1,
		"nearest=%s blocker=%s" % [nearest["selected_id"], blocked["selected_id"]],
	)
	h.check(
		"diagnostics are primitive-only",
		BattleObservation.recursive_primitive_only(sniper)
		and BattleObservation.recursive_primitive_only(caster)
		and BattleObservation.recursive_primitive_only(melee)
		and BattleObservation.recursive_primitive_only(blocked),
		"sniper=%s caster=%s melee=%s enemy=%s" % [
			sniper["policy_id"], caster["policy_id"], melee["policy_id"], blocked["policy_id"],
		],
	)
	h.done()


func _ranged_model(operator_id: StringName) -> BattleModel:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"drone", "path_idx": 0},
	]
	var model := _model(_stage(waves), _operators())
	model.step(150)
	model.apply_action([&"debug_set_dp", 99])
	model.apply_action([&"deploy", operator_id, Vector2i(2, 1), RIGHT])
	return model


func _melee_model() -> BattleModel:
	var wall := (
		load("res://data/operators/defender_1.tres") as OperatorDef
	).duplicate(true) as OperatorDef
	wall.id = &"target_wall"
	wall.atk = 0
	wall.hp = 9999
	wall.dp_cost = 8
	var operators := _operators()
	operators[wall.id] = wall
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
	]
	var model := _model(_stage(waves), operators)
	model.apply_action([&"deploy", wall.id, Vector2i(3, 2), RIGHT])
	model.step(220)
	return model


func _enemy_model() -> BattleModel:
	var model := _model(_stage([]), _operators())
	model.apply_action([&"debug_set_dp", 99])
	model.apply_action([&"deploy", &"vanguard_1", Vector2i(2, 2), RIGHT])
	model.apply_action([&"deploy", &"vanguard_2", Vector2i(1, 1), RIGHT])
	model._spawn({"enemy_id": &"spellcaster", "path_idx": 0})
	model.enemies[0].progress_units = Pathing.PROGRESS_SCALE
	return model


func _stage(waves: Array[Dictionary]) -> StageDef:
	var stage := (
		load("res://data/stages/test_lane.tres") as StageDef
	).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _model(stage: StageDef, operators: Dictionary) -> BattleModel:
	var squad: Array[StringName] = []
	for operator_id: StringName in operators:
		squad.append(operator_id)
	return BattleModel.create(
		stage,
		squad,
		42,
		load("res://data/config/game.tres") as GameConfig,
		_enemies(),
		operators,
	)


func _operators() -> Dictionary:
	var values: Dictionary = {}
	for operator_id: StringName in [
		&"vanguard_1", &"vanguard_2", &"defender_1", &"sniper_1", &"caster_1",
	]:
		values[operator_id] = load("res://data/operators/%s.tres" % operator_id)
	return values


func _enemies() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"drone": load("res://data/enemies/drone.tres") as EnemyDef,
		&"spellcaster": load("res://data/enemies/spellcaster.tres") as EnemyDef,
	}
