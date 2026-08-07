extends GutTest

## Phase 8 debug-verb gate tests (td-phase-8.md §4, model-level). The debug
## verbs ride apply_action (rule 5), so the reject discipline, the terminal
## gate, and the determinism oracle all apply to them unchanged. Convention
## check reused from CLAUDE.md: a verb at tick T is observable at
## model.tick == T + 1.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}
const ELEVATED_CELL := Vector2i(2, 1)
const GROUND_CELL := Vector2i(1, 1)


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage() -> StageDef:
	return load(STAGE_PATH) as StageDef


func _stage_with_waves(entries: Array[Dictionary]) -> StageDef:
	var stage := _stage().duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for entry: Dictionary in entries:
		waves.append(entry)
	stage.waves = waves
	return stage


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			defs[def.get("id")] = def
	return defs


func _enemy_catalog() -> Dictionary:
	return {&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef}


func _make_model(stage: StageDef, squad: Array[StringName] = [&"guard_1"]) -> BattleModel:
	return BattleModel.create(
		stage, squad, 42, _config(), _enemy_catalog(),
		_catalog("res://data/operators"), _catalog("res://data/traps"),
		_catalog("res://data/spells"),
	)


func _assert_rejected(model: BattleModel, action: Array, label: String) -> void:
	var before := model.state_hash()
	assert_false(model.apply_action(action), label + " rejects")
	assert_eq(model.state_hash(), before, label + " leaves state untouched")


## §4.1 gate: grant validation — unknown/duplicate ids reject hash-equal; a
## granted operator then deploys through the untouched can_deploy_at (the
## parent plan's "granting mid-battle passes the same validation"); the
## grant itself flips the hash (squad is hashed state now).
func test_grant_validation() -> void:
	var model := _make_model(_stage_with_waves([FAR_WAVE] as Array[Dictionary]))
	_assert_rejected(model, [&"debug_grant_operator", &"nope"], "unknown operator")
	_assert_rejected(model, [&"debug_grant_operator", &"guard_1"], "already-in-squad grant")
	_assert_rejected(
		model, [&"deploy", &"sniper_1", ELEVATED_CELL, int(UnitState.Facing.RIGHT)],
		"deploy before grant",
	)
	var before := model.state_hash()
	assert_true(model.apply_action([&"debug_grant_operator", &"sniper_1"]), "grant accepted")
	assert_ne(model.state_hash(), before, "grant flips the hash")
	assert_true(model.squad.has(&"sniper_1"))
	assert_true(model.is_deployable(&"sniper_1"), "granted -> deployable (dp 10 covers cost 10)")
	assert_true(model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		model.apply_action([&"deploy", &"sniper_1", ELEVATED_CELL, int(UnitState.Facing.RIGHT)]),
		"granted operator deploys through normal validation",
	)
	_assert_rejected(
		model, [&"deploy", &"sniper_1", GROUND_CELL, int(UnitState.Facing.RIGHT)],
		"granted sniper still rejects GROUND tiles (already fielded anyway)",
	)
	for op_id: StringName in [&"caster_1", &"caster_2", &"defender_1", &"defender_2",
			&"guard_2", &"sniper_2", &"vanguard_1", &"vanguard_2"]:
		assert_true(model.apply_action([&"debug_grant_operator", op_id]), "grant %s" % op_id)
	assert_eq(model.squad.size(), 10, "the full catalog fits in the squad")


## §4.2: removal edits the squad only — the op stops being deployable, its
## fielded unit stays alive; non-squad removals reject hash-equal.
func test_remove_semantics() -> void:
	var squad: Array[StringName] = [&"guard_1", &"vanguard_1"]
	var model := _make_model(_stage_with_waves([FAR_WAVE] as Array[Dictionary]), squad)
	_assert_rejected(model, [&"debug_remove_operator", &"nope"], "non-squad removal")
	assert_true(model.apply_action([&"debug_set_dp", 99]))
	assert_true(
		model.apply_action([&"deploy", &"guard_1", GROUND_CELL, int(UnitState.Facing.RIGHT)])
	)
	assert_true(model.apply_action([&"debug_remove_operator", &"guard_1"]), "removal accepted")
	assert_false(model.is_deployable(&"guard_1"), "removed op no longer deployable")
	var unit := model.alive_unit_at(GROUND_CELL)
	assert_not_null(unit, "the fielded unit stays after removal")
	assert_true(unit.alive)
	_assert_rejected(model, [&"debug_remove_operator", &"guard_1"], "second removal")


## §4.3 gate: the extended DP ledger property — with debug sets up AND down
## in a timeline that also regens, deploys, and places a trap, the equation
## dp == start + regen + vanguard + refunded + skill - spent - lost_to_cap
##       + debug_adjusted
## holds at every tick. (P2/P6 ledger timelines never use debug verbs, so
## their bucket stays 0 and those tests are untouched by construction.)
func test_extended_dp_ledger() -> void:
	var model := _make_model(
		_stage_with_waves([FAR_WAVE] as Array[Dictionary]), [&"vanguard_1"] as Array[StringName]
	)
	var actions := {
		10: [&"debug_set_dp", 50],
		20: [&"deploy", &"vanguard_1", GROUND_CELL, int(UnitState.Facing.RIGHT)],
		30: [&"place_trap", &"spike_plate", Vector2i(3, 2)],
		40: [&"debug_set_dp", 5],
	}
	var start := _config().dp_start
	while model.tick < 200:
		if actions.has(model.tick):
			assert_true(model.apply_action(actions[model.tick]), "action @ %d" % model.tick)
		model.step()
		var expected := (
			start + model.dp_regen_accrued + model.dp_vanguard_generated + model.dp_refunded
			+ model.dp_skill_granted - model.dp_spent - model.dp_lost_to_cap
			+ model.dp_debug_adjusted
		)
		assert_eq(model.dp, expected, "ledger @ %d" % model.tick)
	assert_true(model.dp_debug_adjusted != 0, "the debug bucket saw both sets")


## §4.4: set-DP range validation; a max-DP set spends normally afterward.
func test_set_dp_validation() -> void:
	var model := _make_model(_stage_with_waves([FAR_WAVE] as Array[Dictionary]))
	_assert_rejected(model, [&"debug_set_dp", -1], "negative DP")
	_assert_rejected(model, [&"debug_set_dp", _config().dp_cap + 1], "DP above cap")
	assert_true(model.apply_action([&"debug_set_dp", _config().dp_cap]))
	assert_eq(model.dp, _config().dp_cap)
	assert_true(
		model.apply_action([&"deploy", &"guard_1", GROUND_CELL, int(UnitState.Facing.RIGHT)])
	)
	assert_eq(model.dp, _config().dp_cap - 12, "the set DP spends through the normal path")


## §4.5: base-HP set reaches DEFEAT only through the untouched
## _check_terminal — set 0 at tick T, DEFEAT observable at T + 1; a raised
## base HP absorbs leaks that would otherwise end a hp-3 run (leak_limit
## pinned high so only the HP path can defeat).
func test_set_base_hp() -> void:
	var model := _make_model(_stage_with_waves([FAR_WAVE] as Array[Dictionary]))
	_assert_rejected(model, [&"debug_set_base_hp", -1], "negative base HP")
	model.step(100)
	assert_true(model.apply_action([&"debug_set_base_hp", 0]))
	assert_eq(model.result, BattleModel.Result.RUNNING, "set at tick 100 shows before-state")
	model.step()
	assert_eq(model.result, BattleModel.Result.DEFEAT, "DEFEAT observable at tick 101")
	assert_eq(model.stars, 0)

	# 5 grunts all leak (nothing defends); leak_limit 99 isolates the HP path
	var stage := _stage().duplicate(true) as StageDef
	stage.leak_limit = 99
	var low := _make_model(stage)
	assert_true(low.apply_action([&"debug_set_base_hp", 3]))
	low.run_to_terminal(2_000)
	assert_eq(low.result, BattleModel.Result.DEFEAT, "hp 3 dies to the 3rd of 5 leaks")
	var high := _make_model(stage)
	assert_true(high.apply_action([&"debug_set_base_hp", 50]))
	high.run_to_terminal(2_000)
	assert_eq(high.result, BattleModel.Result.CLEAR, "hp 50 absorbs all 5 leaks")
	assert_eq(high.base_hp, 45)
	assert_eq(high.leaked, 5)


## §4.6 gate: spell reset — a spent Bolt is castable again right after the
## reset; a used ONCE_PER_WAVE Charm re-arms within the same wave.
func test_reset_spell() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	_assert_rejected(model, [&"debug_reset_spell", &"nope"], "unknown spell")
	assert_true(model.apply_action([&"cast", &"bolt", Vector2i(3, 2)]), "bolt at tick 0")
	model.step(100)
	_assert_rejected(model, [&"cast", &"bolt", Vector2i(3, 2)], "bolt on cooldown at 100")
	assert_true(model.apply_action([&"debug_reset_spell", &"bolt"]))
	assert_true(model.is_castable(&"bolt"), "reset clears the cooldown")
	assert_true(model.apply_action([&"cast", &"bolt", Vector2i(0, 0)]))
	assert_true(model.apply_action([&"cast", &"charm", 0]), "charm the first grunt")
	_assert_rejected(model, [&"cast", &"charm", 1], "charm used this wave")
	assert_true(model.apply_action([&"debug_reset_spell", &"charm"]))
	assert_true(
		model.apply_action([&"cast", &"charm", 1]), "reset re-arms charm within the wave"
	)
	assert_eq(model.charmed, 2)


## §4.7: the apply_action terminal gate covers debug verbs unchanged.
func test_terminal_gate() -> void:
	var model := _make_model(_stage_with_waves([] as Array[Dictionary]))
	model.step()
	assert_eq(model.result, BattleModel.Result.CLEAR, "enemy-free battle clears on first step")
	_assert_rejected(model, [&"debug_set_dp", 50], "debug verb after terminal")
	_assert_rejected(model, [&"debug_grant_operator", &"sniper_1"], "grant after terminal")


## §4.8 gate: determinism oracle over a debug-heavy timeline — two fresh
## models, identical hashes at every 100th tick and identical outcomes.
func test_debug_determinism_oracle() -> void:
	var first := _run_debug_timeline()
	var second := _run_debug_timeline()
	assert_eq(first, second, "debug-heavy timeline is deterministic")


func _run_debug_timeline() -> Array[int]:
	var entries: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	var actions := {
		5: [&"debug_set_dp", 99],
		10: [&"debug_grant_operator", &"sniper_1"],
		20: [&"deploy", &"sniper_1", ELEVATED_CELL, int(UnitState.Facing.RIGHT)],
		40: [&"cast", &"bolt", Vector2i(3, 2)],
		50: [&"debug_reset_spell", &"bolt"],
		60: [&"cast", &"bolt", Vector2i(0, 2)],
		70: [&"debug_set_base_hp", 42],
		80: [&"debug_remove_operator", &"guard_1"],
	}
	var trace: Array[int] = []
	while model.tick < 500:
		if actions.has(model.tick):
			model.apply_action(actions[model.tick])
		model.step()
		if model.tick % 100 == 0:
			trace.append(model.state_hash())
	trace.append(int(model.result))
	return trace
