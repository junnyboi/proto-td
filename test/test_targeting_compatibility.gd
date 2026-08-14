extends GutTest

const FIXTURE_PATH := "res://test/fixtures/targeting_compat_v1.json"
const CONFIG_PATH := "res://data/config/game.tres"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const RIGHT := int(UnitState.Facing.RIGHT)
const ENEMY_IDS: Array[StringName] = [
	&"drone", &"grunt", &"heavy", &"mini_boss", &"runner", &"spellcaster",
]
const OPERATOR_IDS: Array[StringName] = [
	&"vanguard_1", &"vanguard_2", &"guard_1", &"guard_2",
	&"defender_1", &"defender_2", &"sniper_1", &"sniper_2",
	&"caster_1", &"caster_2", &"witch_doctor_1",
]


func _fixture() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	return parsed as Dictionary


func _policy(policy_id: String) -> TargetPolicyDef:
	return load("res://data/target_policies/%s.tres" % policy_id) as TargetPolicyDef


func _enemy_defs() -> Dictionary:
	var definitions: Dictionary = {}
	for enemy_id: StringName in ENEMY_IDS:
		definitions[enemy_id] = load("res://data/enemies/%s.tres" % enemy_id)
	return definitions


func _operator_defs() -> Dictionary:
	var definitions: Dictionary = {}
	for operator_id: StringName in OPERATOR_IDS:
		definitions[operator_id] = load("res://data/operators/%s.tres" % operator_id)
	return definitions


func _stage_with(waves: Array[Dictionary]) -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _model(stage: StageDef, operators: Dictionary = {}) -> BattleModel:
	var definitions := operators if not operators.is_empty() else _operator_defs()
	var squad: Array[StringName] = []
	for operator_id: StringName in definitions:
		squad.append(operator_id)
	return BattleModel.create(
		stage,
		squad,
		42,
		load(CONFIG_PATH) as GameConfig,
		_enemy_defs(),
		definitions,
	)


func _cell(value: Dictionary) -> Vector2i:
	return Vector2i(int(value["x"]), int(value["y"]))


func _fixture_candidates(row: Dictionary) -> Array:
	var offsets: Array[Vector2i] = []
	for offset_value: Variant in row["offsets"]:
		offsets.append(_cell(offset_value as Dictionary))
	var covered_cells := Targeting.range_cells(
		_cell(row["origin"]), offsets, int(row["facing"])
	)
	var candidates: Array = []
	for candidate_value: Variant in row["candidates"]:
		var source := candidate_value as Dictionary
		var cell := _cell(source["cell"])
		candidates.append({
			"id": int(source["id"]),
			"alive": true,
			"faction": Targeting.FACTION_ENEMY,
			"relation": Targeting.RELATION_NONE,
			"in_range": covered_cells.has(cell),
			"aerial": bool(source["aerial"]),
			"progress_units": int(source["progress_units"]),
			"distance": -1,
		})
	return candidates


func test_every_frozen_selection_row_replays_exactly() -> void:
	var fixture := _fixture()
	assert_eq(fixture["captured_from_commit"], "3b3fdfba2a749597e2f8ad1d87f74d365c18b231")
	for value: Variant in fixture["selection_rows"]:
		var row := value as Dictionary
		var policy := Targeting.compile(
			_policy(String(row["policy_id"])), TargetPolicyDef.OwnerKind.OPERATOR
		)
		var candidates := _fixture_candidates(row)
		var decision := Targeting.decide(policy, "operator", 0, candidates)
		assert_eq(
			int(decision["selected_id"]),
			int(row["selected_id"]),
			"%s frozen selected ID" % row["case_id"],
		)
		var reversed := candidates.duplicate(true)
		reversed.reverse()
		assert_eq(
			CanonicalJson.text(
				Targeting.decide(policy, "operator", 0, reversed)
			),
			CanonicalJson.text(decision),
			"%s reversed input is byte-identical" % row["case_id"],
		)


func test_frozen_blocked_and_nearest_rows_replay_exactly() -> void:
	var fixture := _fixture()
	var blocked := fixture["blocked_row"] as Dictionary
	var blocked_candidates: Array = []
	for engagement_index: int in blocked["blocked_ids"].size():
		var blocked_id: Variant = blocked["blocked_ids"][engagement_index]
		blocked_candidates.append({
			"id": int(blocked_id),
			"alive": true,
			"faction": Targeting.FACTION_ENEMY,
			"relation": Targeting.RELATION_BLOCKED,
			"in_range": true,
			"aerial": false,
			"progress_units": 0,
			"distance": -1,
			"engagement_order": engagement_index,
		})
	var blocked_policy := Targeting.compile(
		_policy(String(blocked["policy_id"])), TargetPolicyDef.OwnerKind.OPERATOR
	)
	assert_eq(
		int(Targeting.decide(blocked_policy, "operator", 0, blocked_candidates)["selected_id"]),
		int(blocked["selected_id"]),
	)

	var nearest := fixture["nearest_row"] as Dictionary
	var enemy_cell := _cell(nearest["enemy_cell"])
	var nearest_candidates: Array = []
	for unit_value: Variant in nearest["units"]:
		var unit := unit_value as Dictionary
		var unit_cell := _cell(unit["cell"])
		var distance := maxi(
			absi(unit_cell.x - enemy_cell.x),
			absi(unit_cell.y - enemy_cell.y),
		)
		nearest_candidates.append({
			"id": int(unit["id"]),
			"alive": true,
			"faction": Targeting.FACTION_OPERATOR,
			"relation": Targeting.RELATION_DEPLOYED_UNIT,
			"in_range": distance <= int(nearest["range_cells"]),
			"aerial": false,
			"progress_units": 0,
			"distance": distance,
		})
	var nearest_policy := Targeting.compile(
		_policy(String(nearest["policy_id"])), TargetPolicyDef.OwnerKind.ENEMY
	)
	assert_eq(
		int(Targeting.decide(nearest_policy, "enemy", 0, nearest_candidates)["selected_id"]),
		int(nearest["selected_id"]),
	)


func test_sniper_and_caster_decisions_are_state_neutral_observation_queries() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"drone", "path_idx": 0},
	]
	var sniper_model := _model(_stage_with(waves))
	sniper_model.step(150)
	assert_true(sniper_model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		sniper_model.apply_action([&"deploy", &"sniper_1", Vector2i(2, 1), RIGHT])
	)
	var before_hash := sniper_model.state_hash()
	var before_observation := BattleObservation.from_model(sniper_model).sha256()
	var sniper_decision := TargetDecisionProjection.unit_target_decision(sniper_model, 0)
	assert_eq(int(sniper_decision["selected_id"]), 1, "Sniper prefers the drone")
	assert_eq(sniper_decision["policy_id"], "operator_aerial_first_frontmost")
	assert_eq(sniper_model.state_hash(), before_hash, "diagnostic query preserves model hash")
	assert_eq(
		BattleObservation.from_model(sniper_model).sha256(),
		before_observation,
		"diagnostic query preserves the TD-OBS projection",
	)
	assert_eq(
		CanonicalJson.text(
			TargetDecisionProjection.unit_target_decision(sniper_model, 0)
		),
		CanonicalJson.text(sniper_decision),
		"repeated query is byte-identical",
	)

	var caster_model := _model(_stage_with(waves))
	caster_model.step(150)
	assert_true(caster_model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		caster_model.apply_action([&"deploy", &"caster_1", Vector2i(2, 1), RIGHT])
	)
	var caster_decision := TargetDecisionProjection.unit_target_decision(caster_model, 0)
	assert_eq(int(caster_decision["selected_id"]), 0, "Caster excludes the drone")
	assert_eq(caster_decision["policy_id"], "operator_ground_only_frontmost")


func test_melee_and_spellcaster_integration_use_the_same_public_decisions() -> void:
	var wall := (
		load("res://data/operators/defender_1.tres") as OperatorDef
	).duplicate(true) as OperatorDef
	wall.id = &"target_wall"
	wall.atk = 0
	wall.hp = 9999
	wall.dp_cost = 8
	var operators := _operator_defs()
	operators[wall.id] = wall
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
	]
	var melee_model := _model(_stage_with(waves), operators)
	assert_true(melee_model.apply_action([&"deploy", wall.id, Vector2i(3, 2), RIGHT]))
	melee_model.step(220)
	var melee_decision := TargetDecisionProjection.unit_target_decision(melee_model, 0)
	assert_eq(melee_model.units[0].blocked_ids, [0, 1] as Array[int])
	assert_eq(int(melee_decision["selected_id"]), 0)
	assert_eq(melee_decision["policy_id"], "operator_blocked_assignment_order")

	var ranged_model := _model(_stage_with([]))
	assert_true(ranged_model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		ranged_model.apply_action([&"deploy", &"vanguard_1", Vector2i(2, 2), RIGHT])
	)
	assert_true(
		ranged_model.apply_action([&"deploy", &"vanguard_2", Vector2i(1, 1), RIGHT])
	)
	ranged_model._spawn({"enemy_id": &"spellcaster", "path_idx": 0})
	ranged_model.enemies[0].progress_units = Pathing.PROGRESS_SCALE
	var nearest := TargetDecisionProjection.enemy_target_decision(ranged_model, 0)
	assert_eq(int(nearest["selected_id"]), 0, "equal distance uses lower runtime ID")
	ranged_model.enemies[0].blocked_by = 1
	var blocked := TargetDecisionProjection.enemy_target_decision(ranged_model, 0)
	assert_eq(int(blocked["selected_id"]), 1, "current blocker overrides nearest")


func test_missing_policy_and_witch_doctor_fail_closed_without_fallback() -> void:
	var invalid_sniper := (
		load("res://data/operators/sniper_1.tres") as OperatorDef
	).duplicate(true) as OperatorDef
	invalid_sniper.id = &"invalid_sniper"
	invalid_sniper.target_policy = null
	var operators := _operator_defs()
	operators[invalid_sniper.id] = invalid_sniper
	var model := _model(_stage_with([]), operators)
	assert_true(model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		model.apply_action([&"deploy", invalid_sniper.id, Vector2i(2, 1), RIGHT])
	)
	model._spawn({"enemy_id": &"grunt", "path_idx": 0})
	model.enemies[0].progress_units = Pathing.PROGRESS_SCALE
	var invalid := TargetDecisionProjection.unit_target_decision(model, 0)
	assert_eq(int(invalid["selected_id"]), Targeting.NO_TARGET)
	assert_eq(invalid["selection_reason"], "invalid_policy")

	var witch_model := _model(_stage_with([]))
	assert_true(witch_model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		witch_model.apply_action([&"deploy", &"witch_doctor_1", Vector2i(2, 1), RIGHT])
	)
	witch_model._spawn({"enemy_id": &"grunt", "path_idx": 0})
	witch_model.enemies[0].progress_units = Pathing.PROGRESS_SCALE
	var disabled := TargetDecisionProjection.unit_target_decision(witch_model, 0)
	assert_eq(int(disabled["selected_id"]), Targeting.NO_TARGET)
	assert_eq(disabled["selection_reason"], "automatic_target_disabled")
