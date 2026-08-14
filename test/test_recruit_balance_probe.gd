extends GutTest

## Phase 0 bounded Recruit probe. Event rows scheduled at tick T are applied
## before stepping T and are observable at model.tick == T + 1.
const RECRUIT_TEMPLATE := preload("res://test/fixtures/operators/recruit_probe.tres")
const PROBE_TIMELINE := preload("res://test/fixtures/timelines/recruit_s1_probe.gd")
const MAX_TICKS := 2_400
const HASH_INTERVAL := 100
const RECRUIT_IDS := [
	&"recruit_probe_a",
	&"recruit_probe_b",
	&"recruit_probe_c",
]


func test_probe_fixture_matches_the_basic_recruit_contract() -> void:
	var recruit := RECRUIT_TEMPLATE as OperatorDef
	var swordmaster := load("res://data/operators/guard_1.tres") as OperatorDef
	var defender := load("res://data/operators/defender_1.tres") as OperatorDef
	assert_eq(recruit.dp_cost, 8)
	assert_eq(recruit.block, 1)
	assert_eq(recruit.hp, 110)
	assert_eq(recruit.atk, 4)
	assert_eq(recruit.atk_interval_ticks, 36)
	assert_eq(recruit.range_offsets, [Vector2i.ZERO] as Array[Vector2i])
	assert_not_null(recruit.target_policy)
	assert_eq(recruit.target_policy.id, &"operator_blocked_assignment_order")
	assert_eq(recruit.placement, OperatorDef.Placement.GROUND)
	assert_eq(recruit.dp_generation_interval_ticks, 0)
	assert_eq(recruit.splash_dim, 0)
	assert_null(recruit.skill)
	assert_lte(recruit.block, 1, "Recruit never gains specialist block capacity")
	assert_lt(recruit.hp, defender.hp, "Recruit stays below Defender durability")
	assert_lt(recruit.atk, swordmaster.atk, "Recruit stays below Swordmaster attack")


func test_seed_42_recruits_clear_s1_deterministically_and_contribute() -> void:
	var first := _run(PROBE_TIMELINE.winner())
	var second := _run(PROBE_TIMELINE.winner())
	var model := first["model"] as BattleModel
	assert_eq(first["rejected"], [], "every winner action is accepted")
	assert_eq(second["rejected"], [], "repeat winner actions are accepted")
	assert_eq(first["trace"], second["trace"], "hash every 100 ticks is deterministic")
	assert_eq(first["terminal_hash"], second["terminal_hash"], "terminal hash is deterministic")
	assert_eq(model.result, BattleModel.Result.CLEAR, _snapshot_line(model))
	assert_eq(model.tick, 1_202, "winner terminal tick stays exact")
	assert_eq(model.killed, 4, "winner kills four grunts")
	assert_eq(model.leaked, 2, "winner leaks two grunts")
	assert_lte(model.leaked, 2, "D20 leak band: %d <= 2" % model.leaked)
	assert_eq(model.units.size(), 3, "all three Recruit aliases deploy")
	var surviving := 0
	for unit: UnitState in model.units:
		if unit.alive:
			surviving += 1
		assert_gte(unit.last_attack_tick, 0, "Recruit %d contributes at least one attack" % unit.id)
	assert_eq(surviving, 1, "exactly one deployed Recruit survives")


func test_filtered_timeline_without_one_recruit_loses() -> void:
	var winner: Array = PROBE_TIMELINE.winner()
	var filtered: Array = PROBE_TIMELINE.filtered_loser()
	assert_eq(filtered.size(), winner.size() - 1, "loser filters exactly one deploy")
	var result := _run(filtered)
	var model := result["model"] as BattleModel
	assert_eq(result["rejected"], [], "every filtered action is accepted")
	assert_eq(model.result, BattleModel.Result.DEFEAT, _snapshot_line(model))
	assert_eq(model.tick, 1_082, "filtered loser terminal tick stays exact")
	assert_eq(model.killed, 2, "filtered loser kills only two grunts")
	assert_eq(model.leaked, 4, "filtered loser leaks four grunts")
	assert_gte(
		model.leaked,
		model.stage.leak_limit,
		"filtered timeline reaches the authoritative leak limit",
	)


func _run(actions: Array) -> Dictionary:
	var model := _make_model()
	var rows := actions.duplicate(true)
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var index := 0
	var rejected: Array = []
	var trace: Array = []
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while index < rows.size() and int((rows[index] as Array)[0]) == model.tick:
			var row: Array = rows[index]
			if not model.apply_action(row.slice(1)):
				rejected.append({"tick": model.tick, "row": row, "dp": model.dp})
			index += 1
		model.step()
		if model.tick % HASH_INTERVAL == 0:
			trace.append([model.tick, model.state_hash()])
	return {
		"model": model,
		"rejected": rejected,
		"rows_played": index,
		"trace": trace,
		"terminal_hash": model.state_hash(),
	}


func _make_model() -> BattleModel:
	var operators: Dictionary = {}
	var squad: Array[StringName] = []
	for recruit_id: StringName in RECRUIT_IDS:
		var recruit := (RECRUIT_TEMPLATE as OperatorDef).duplicate(true) as OperatorDef
		recruit.id = recruit_id
		operators[recruit_id] = recruit
		squad.append(recruit_id)
	var enemies := {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
	}
	return BattleModel.create(
		load("res://data/stages/s1.tres") as StageDef,
		squad,
		42,
		load("res://data/config/game.tres") as GameConfig,
		enemies,
		operators,
	)


func _snapshot_line(model: BattleModel) -> String:
	return "result=%d tick=%d leaked=%d killed=%d alive=%d base_hp=%d units=%d" % [
		model.result,
		model.tick,
		model.leaked,
		model.killed,
		model.alive_enemy_count(),
		model.base_hp,
		model.units.size(),
	]
