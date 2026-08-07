extends GutTest

## Phase 2 gate tests (td-phase-2-3.md §3.5, model-level). Pinned math (§3.4):
## regen grants land at ticks 30/60/90/... (observed post-step); a vanguard
## deployed at tick T generates its first point at tick T+90; the DP ledger
## dp == dp_start + regen + vanguard + refunded - spent - lost_to_cap holds
## EXACTLY at every tick (D4/D5 overflow bucket makes it an equality).

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const VG_PATH := "res://data/operators/vanguard_1.tres"
const DEF_PATH := "res://data/operators/defender_1.tres"

const PATH_CELL := Vector2i(3, 2)
const GROUND_CELL := Vector2i(1, 0)
const GROUND_CELL_2 := Vector2i(2, 0)
const ELEV_CELL := Vector2i(2, 1)
const SPAWN_CELL := Vector2i(0, 2)
const BASE_CELL := Vector2i(6, 2)
const VOID_CELL := Vector2i(7, 2)

const RIGHT := UnitState.Facing.RIGHT
const DOWN := UnitState.Facing.DOWN
const UP := UnitState.Facing.UP
const MAX_TICKS := 20_000


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


## test_lane with the wave pushed beyond reach so idle economy runs never end.
func _far_stage() -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}]
	stage.waves = waves
	return stage


func _dup_op(base_path: String, new_id: StringName) -> OperatorDef:
	var def := (load(base_path) as OperatorDef).duplicate() as OperatorDef
	def.id = new_id
	return def


func _make_model(
	stage: StageDef, config: GameConfig, extra_ops: Array[OperatorDef] = []
) -> BattleModel:
	var ops: Dictionary = {
		&"vanguard_1": load(VG_PATH) as OperatorDef,
		&"defender_1": load(DEF_PATH) as OperatorDef,
	}
	var squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
	for def: OperatorDef in extra_ops:
		ops[def.id] = def
		squad.append(def.id)
	return BattleModel.create(stage, squad, 42, config, {&"grunt": load(GRUNT_PATH)}, ops)


func _assert_ledger(model: BattleModel) -> void:
	var expected := (
		model.config.dp_start
		+ model.dp_regen_accrued
		+ model.dp_vanguard_generated
		+ model.dp_refunded
		- model.dp_spent
		- model.dp_lost_to_cap
	)
	assert_eq(model.dp, expected, "DP ledger exact @ tick %d" % model.tick)


func _assert_rejected(model: BattleModel, action: Array, label: String) -> void:
	var before := model.state_hash()
	assert_false(model.apply_action(action), label + " rejects")
	assert_eq(model.state_hash(), before, label + " leaves state untouched")


func test_regen_exactness() -> void:
	var model := _make_model(_far_stage(), _config())
	model.step(29)
	assert_eq(model.dp, 10, "no regen before tick 30")
	model.step()
	assert_eq(model.dp, 11, "first regen point lands exactly at tick 30")
	assert_eq(model.dp_regen_accrued, 1)


func test_cap_overflow_ledger() -> void:
	var config := _config().duplicate() as GameConfig
	config.dp_cap = 12
	var model := _make_model(_far_stage(), config)
	for _i: int in 900:
		model.step()
		assert_true(model.dp <= config.dp_cap, "dp never exceeds cap @ tick %d" % model.tick)
		_assert_ledger(model)
	assert_eq(model.dp, 12, "dp pinned at cap")
	assert_eq(model.dp_regen_accrued, 30, "regen accrues gross at cap")
	assert_eq(model.dp_lost_to_cap, 28, "overage lands in the overflow bucket")


func test_vanguard_generation_exactness() -> void:
	# dp_start 20 so both deploys (8 + 8) are affordable at ticks 60/90
	var config := _config().duplicate() as GameConfig
	config.dp_start = 20
	var vg2 := _dup_op(VG_PATH, &"vanguard_2")
	var extra: Array[OperatorDef] = [vg2]
	var model := _make_model(_far_stage(), config, extra)
	var actions := [
		[60, &"deploy", &"vanguard_1", GROUND_CELL, int(RIGHT)],
		[90, &"deploy", &"vanguard_2", GROUND_CELL_2, int(RIGHT)],
	]
	model.run_timeline(actions, 149)
	assert_eq(model.dp_vanguard_generated, 0, "no generation before tick 150")
	model.step()
	assert_eq(model.dp_vanguard_generated, 1, "first vanguard point at deploy tick + 90")
	model.run_timeline([], 179)
	assert_eq(model.dp_vanguard_generated, 1, "second vanguard not due yet")
	model.step()
	assert_eq(model.dp_vanguard_generated, 2, "per-unit counters are independent")


func test_vanguard_retreat_math() -> void:
	# §3.4 worked example: deploy at 60 (cost 8), retreat at 200 (refund 4);
	# at tick 300: dp == 10 + regen 10 + generated 1 + refund 4 - spent 8 == 17
	var model := _make_model(_far_stage(), _config())
	var actions := [
		[60, &"deploy", &"vanguard_1", GROUND_CELL, int(RIGHT)],
		[200, &"retreat", 0],
	]
	model.run_timeline(actions, 300)
	assert_eq(model.dp_vanguard_generated, 1, "generation stopped by retreat (240 never fires)")
	assert_eq(model.dp_refunded, 4, "refund = floor(8 * 50%)")
	assert_eq(model.retreated, 1)
	assert_eq(model.dp, 17, "10 + 10 + 1 + 4 - 8")
	_assert_ledger(model)


func test_deploy_rejection_matrix() -> void:
	# static rejections at dp_start 10 (defender genuinely unaffordable)
	var elev := _dup_op(VG_PATH, &"elev_1")
	elev.placement = OperatorDef.Placement.ELEVATED
	var extra: Array[OperatorDef] = [elev]
	var model := _make_model(_far_stage(), _config(), extra)
	_assert_rejected(model, [&"deploy", &"sniper_x", GROUND_CELL, 0], "op not in squad")
	_assert_rejected(model, [&"deploy", &"defender_1", GROUND_CELL, 0], "broke (10 < 16)")
	_assert_rejected(model, [&"deploy", &"vanguard_1", ELEV_CELL, 0], "GROUND op on ELEVATED")
	_assert_rejected(model, [&"deploy", &"elev_1", GROUND_CELL, 0], "ELEVATED op on GROUND")
	_assert_rejected(model, [&"deploy", &"vanguard_1", VOID_CELL, 0], "VOID cell")
	_assert_rejected(model, [&"deploy", &"vanguard_1", SPAWN_CELL, 0], "SPAWN cell")
	_assert_rejected(model, [&"deploy", &"vanguard_1", BASE_CELL, 0], "BASE cell")
	_assert_rejected(model, [&"deploy", &"vanguard_1", Vector2i(99, 99), 0], "out of bounds")
	_assert_rejected(model, [&"deploy", &"vanguard_1", GROUND_CELL, 4], "facing out of range")
	_assert_rejected(model, [&"deploy", &"vanguard_1", GROUND_CELL, -1], "negative facing")


func test_deploy_occupancy_and_elevated() -> void:
	# dp_start 30: every deploy below is affordable, so each rejection is for
	# the reason under test, not a hidden broke rejection
	var config := _config().duplicate() as GameConfig
	config.dp_start = 30
	var elev := _dup_op(VG_PATH, &"elev_1")
	elev.placement = OperatorDef.Placement.ELEVATED
	var vg2 := _dup_op(VG_PATH, &"vanguard_2")
	var extra: Array[OperatorDef] = [elev, vg2]
	var model := _make_model(_far_stage(), config, extra)
	assert_true(model.apply_action([&"deploy", &"vanguard_1", GROUND_CELL, 0]), "valid deploy")
	_assert_rejected(model, [&"deploy", &"vanguard_2", GROUND_CELL, 0], "occupied cell")
	_assert_rejected(model, [&"deploy", &"vanguard_1", GROUND_CELL_2, 0], "already deployed")
	assert_true(model.apply_action([&"deploy", &"elev_1", ELEV_CELL, 0]), "ELEVATED op on E tile")
	_assert_ledger(model)


func test_verbs_reject_after_terminal() -> void:
	var model := _make_model(load(STAGE_PATH) as StageDef, _config())
	model.run_to_terminal(MAX_TICKS)
	assert_eq(model.result, BattleModel.Result.DEFEAT, "test_lane idles to defeat")
	_assert_rejected(model, [&"deploy", &"vanguard_1", GROUND_CELL, 0], "deploy after terminal")


func test_deploy_success_state() -> void:
	var model := _make_model(_far_stage(), _config())
	assert_true(model.is_deployable(&"vanguard_1"))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", GROUND_CELL, int(DOWN)]))
	assert_eq(model.dp, 2, "10 - 8")
	assert_eq(model.dp_spent, 8)
	assert_eq(model.units.size(), 1)
	var u := model.units[0]
	assert_eq(u.cell, GROUND_CELL)
	assert_eq(u.facing, UnitState.Facing.DOWN)
	assert_eq(u.hp, 120)
	assert_eq(u.block, 2)
	assert_false(model.is_deployable(&"vanguard_1"), "deployed op leaves the pool")
	assert_eq(model.alive_unit_at(GROUND_CELL), u)
	_assert_ledger(model)


func test_retreat_round_trip() -> void:
	var model := _make_model(_far_stage(), _config())
	model.step(180)
	assert_eq(model.dp, 16, "regen reaches defender cost at tick 180")
	assert_true(model.apply_action([&"deploy", &"defender_1", PATH_CELL, int(RIGHT)]))
	assert_eq(model.dp, 0)
	assert_true(model.apply_action([&"retreat", 0]))
	assert_eq(model.dp_refunded, 8, "refund = floor(16 * 50%)")
	assert_eq(model.dp, 8)
	assert_null(model.alive_unit_at(PATH_CELL), "cell freed")
	assert_false(model.is_deployable(&"defender_1"), "8 < 16: broke until regen")
	model.step(240)
	assert_true(model.apply_action([&"deploy", &"defender_1", PATH_CELL, int(RIGHT)]))
	var redeployed := model.units[1]
	assert_eq(redeployed.hp, 200, "fresh hp on redeploy")
	_assert_rejected(model, [&"retreat", 99], "unknown unit id")
	_assert_rejected(model, [&"retreat", 0], "already-retreated unit")
	_assert_ledger(model)


func test_ledger_property_over_timeline() -> void:
	var config := _config().duplicate() as GameConfig
	config.dp_cap = 14
	var vg2 := _dup_op(VG_PATH, &"vanguard_2")
	var extra: Array[OperatorDef] = [vg2]
	var model := _make_model(_far_stage(), config, extra)
	var actions := [
		[30, &"deploy", &"vanguard_1", GROUND_CELL, int(RIGHT)],
		[60, &"deploy", &"vanguard_2", GROUND_CELL_2, int(RIGHT)],
		[300, &"retreat", 0],
		[450, &"deploy", &"vanguard_1", PATH_CELL, int(RIGHT)],
	]
	var idx := 0
	while model.tick < 900:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			model.apply_action(entry.slice(1))
			idx += 1
		model.step()
		assert_true(model.dp >= 0 and model.dp <= config.dp_cap, "dp in [0, cap] @ %d" % model.tick)
		_assert_ledger(model)
	assert_eq(idx, actions.size(), "every timeline action was applied")
	assert_true(model.dp_lost_to_cap > 0, "the cap actually clamped during the run")


func test_determinism_oracle_with_actions() -> void:
	var actions := [
		[30, &"deploy", &"vanguard_1", PATH_CELL, int(RIGHT)],
		[600, &"deploy", &"defender_1", Vector2i(2, 2), int(RIGHT)],
		[700, &"retreat", 0],
	]
	var runs: Array = []
	for _run: int in 2:
		var stage := ResourceLoader.load(STAGE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var grunt := ResourceLoader.load(GRUNT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var vg := ResourceLoader.load(VG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var dfd := ResourceLoader.load(DEF_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var far := (stage as StageDef).duplicate(true) as StageDef
		var waves: Array[Dictionary] = [{"tick": 1_000, "enemy_id": &"grunt", "path_idx": 0}]
		far.waves = waves
		var squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
		var model := BattleModel.create(
			far, squad, 42, config, {&"grunt": grunt}, {&"vanguard_1": vg, &"defender_1": dfd}
		)
		var idx := 0
		var hashes: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < actions.size() and int(actions[idx][0]) == model.tick:
				var entry: Array = actions[idx]
				model.apply_action(entry.slice(1))
				idx += 1
			model.step()
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		runs.append({
			"hashes": hashes,
			"outcome": [model.result, model.stars, model.leaked, model.dp, model.tick],
		})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical with a deploy/retreat timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")


func test_facing_stored_and_hashed() -> void:
	var a := _make_model(_far_stage(), _config())
	var b := _make_model(_far_stage(), _config())
	assert_true(a.apply_action([&"deploy", &"vanguard_1", GROUND_CELL, int(RIGHT)]))
	assert_true(b.apply_action([&"deploy", &"vanguard_1", GROUND_CELL, int(UP)]))
	assert_eq(a.units[0].facing, UnitState.Facing.RIGHT)
	assert_eq(b.units[0].facing, UnitState.Facing.UP)
	assert_ne(a.state_hash(), b.state_hash(), "facing participates in the state hash")
