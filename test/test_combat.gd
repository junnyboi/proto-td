extends GutTest

## Phase 3 gate tests (td-phase-2-3.md §4.4, model-level). Pinned math (§4.3),
## all on test_lane's 7-cell path with the unit on path cell (3,2):
## a grunt spawned at tick S enters cell 3 on its 91st advance -> blocked at
## tick S+91, frozen at progress 3_033_303. Tick convention (Phase 1 as-built):
## an event "at tick T" happens during the step whose entry tick is T, so it is
## observable at model.tick == T+1 — step(T) shows the before-state, one more
## step() shows the event. Ready-at-contact cadence: first hit on the block
## tick, then every atk_interval_ticks. Units strike first, so an enemy dying
## on its ready-tick never lands that hit: vanguard (atk 6) kills a 40 hp grunt
## on hit 7 at S+91+180; the grunt lands 6 hits (30 damage) before dying.
## A released enemy resumes from frozen progress and needs 120 more advances
## to leak (3_033_303 + 119*33_333 < 7M). D12 corollary: an enemy occupies a
## cell for ~30 advances, so one passing a full unit is still caught mid-cell
## if capacity frees before it walks off the cell.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const VG_PATH := "res://data/operators/vanguard_1.tres"
const DEF_PATH := "res://data/operators/defender_1.tres"

const PATH_CELL := Vector2i(3, 2)
const RIGHT := int(UnitState.Facing.RIGHT)
const FROZEN_PROGRESS := 3_033_303
const MAX_TICKS := 20_000


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage_with_waves(spawn_ticks: Array[int]) -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for t: int in spawn_ticks:
		waves.append({"tick": t, "enemy_id": &"grunt", "path_idx": 0})
	stage.waves = waves
	return stage


func _make_model(stage: StageDef, extra_ops: Array[OperatorDef] = []) -> BattleModel:
	var ops: Dictionary = {
		&"vanguard_1": load(VG_PATH) as OperatorDef,
		&"defender_1": load(DEF_PATH) as OperatorDef,
	}
	var squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
	for def: OperatorDef in extra_ops:
		ops[def.id] = def
		squad.append(def.id)
	return BattleModel.create(stage, squad, 42, _config(), {&"grunt": load(GRUNT_PATH)}, ops)


func _assert_conservation(model: BattleModel) -> void:
	var books := model.alive_count() + model.killed + model.leaked
	assert_eq(model.spawned, books, "spawned == alive + killed + leaked @ tick %d" % model.tick)


func _assert_block_capacity(model: BattleModel) -> void:
	for u: UnitState in model.units:
		var held := 0
		for enemy_id: int in u.blocked_ids:
			held += model.enemies[enemy_id].block_weight
		var label := "unit %d holds %d/%d @ tick %d" % [u.id, held, u.block, model.tick]
		assert_true(held <= u.block, label)


func _walks_past(model: BattleModel, enemy_idx: int) -> bool:
	return model.enemies[enemy_idx].blocked_by == -1 and model.enemies[enemy_idx].alive


## Steps the model with actions applied at their ticks, asserting the
## conservation + block-capacity invariants at EVERY tick (A9: GUT is free).
func _run_asserted(model: BattleModel, actions: Array, until_tick: int) -> void:
	var idx := 0
	while model.tick < until_tick and model.result == BattleModel.Result.RUNNING:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			model.apply_action(entry.slice(1))
			idx += 1
		model.step()
		_assert_conservation(model)
		_assert_block_capacity(model)


## Gate tests 1+2: conservation + block capacity every tick of a full battle.
## Defender (block 3, atk 8) on path cell (4,2) at tick 180 (dp exactly 16;
## grunt #0 is on its last tick inside cell 4). Kill ticks 300/450/600/750;
## #4 arrives at 391 with capacity full, walks past, leaks at 270+211=481.
## Vanguard deployed at 420 (dp exactly 8) on (3,2) behind the traffic stays
## idle at full hp. Defender intake 4+8+11+14 = 37 hits -> hp 200-185 = 15.
func test_full_conservation_with_kills() -> void:
	var spawn_ticks: Array[int] = [30, 90, 150, 210, 270]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	var actions := [
		[180, &"deploy", &"defender_1", Vector2i(4, 2), RIGHT],
		[420, &"deploy", &"vanguard_1", PATH_CELL, RIGHT],
	]
	_run_asserted(model, actions, MAX_TICKS)
	assert_eq(model.result, BattleModel.Result.CLEAR, "defender holds the lane to a clear")
	assert_eq(model.tick, 751, "last kill at tick 750")
	assert_eq(model.killed, 4, "defender kills the four it blocks")
	assert_eq(model.leaked, 1, "the overflow grunt leaks")
	assert_eq(model.stars, 2, "1 leak -> 2 stars")
	assert_eq(model.units[0].hp, 15, "defender took 37 grunt hits (200 - 185)")
	assert_eq(model.units[1].hp, 120, "idle vanguard never engaged")


func test_block_tick_and_freeze() -> void:
	var spawn_ticks: Array[int] = [30]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", PATH_CELL, RIGHT]))
	model.step(121)
	assert_eq(model.enemies[0].blocked_by, -1, "90 advances by entry tick 120: cell 2, free")
	model.step()
	var e := model.enemies[0]
	assert_eq(e.blocked_by, 0, "blocked exactly at tick 121 (spawn + 91)")
	assert_eq(e.progress_units, FROZEN_PROGRESS, "frozen where the 91st advance landed")
	assert_eq(model.units[0].blocked_ids, [0] as Array[int])
	model.step(50)
	assert_eq(e.progress_units, FROZEN_PROGRESS, "progress frozen while blocked")


func test_kill_cadence_vanguard() -> void:
	var spawn_ticks: Array[int] = [30]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", PATH_CELL, RIGHT]))
	model.step(301)
	assert_eq(model.killed, 0, "grunt survives 6 hits (36 < 40)")
	assert_eq(model.enemies[0].hp, 4, "40 - 6*6")
	model.step()
	assert_eq(model.killed, 1, "7th hit kills exactly at tick 301")
	assert_eq(model.units[0].blocked_ids.size(), 0, "capacity freed on kill")
	assert_eq(model.units[0].hp, 90, "blocker took 6 grunt hits (120 - 30)")


func test_kill_cadence_defender() -> void:
	# grunt spawned at 90 blocks at 181; defender affordable at tick 180 exactly.
	# atk 8: 5 hits (181..301) kill the 40 hp grunt; the grunt lands 4 hits
	# (181..271) for 20 before dying (units strike first at 301).
	var spawn_ticks: Array[int] = [90]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	model.step(180)
	assert_true(model.apply_action([&"deploy", &"defender_1", PATH_CELL, RIGHT]))
	model.step(2)
	assert_eq(model.enemies[0].blocked_by, 0, "blocked at 181 (spawn 90 + 91)")
	model.step(301 - model.tick)
	assert_eq(model.killed, 0, "grunt survives 4 defender hits (32 < 40)")
	model.step()
	assert_eq(model.killed, 1, "5th hit kills exactly at tick 301")
	assert_eq(model.units[0].hp, 180, "defender took 4 grunt hits (200 - 20)")


## The signature 2-block case (§4.3): vanguard (block 2) on (3,2), grunts at
## 30/90/150. #2 arrives at 241 with capacity full and is off cell 3 by 271 —
## before #0's death frees a slot at 301 — so it truly walks past and leaks.
func test_signature_two_block() -> void:
	var spawn_ticks: Array[int] = [30, 90, 150]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", PATH_CELL, RIGHT]))
	var checkpoints := {
		121: func() -> void: assert_eq(model.enemies[0].blocked_by, 0, "#0 blocked at 121"),
		181: func() -> void: assert_eq(model.enemies[1].blocked_by, 0, "#1 blocked at 181"),
		241: func() -> void: assert_true(_walks_past(model, 2), "#2 unblocked, walks past"),
		301: func() -> void: assert_eq(model.killed, 1, "#0 dies at 301"),
		360: func() -> void: assert_eq(model.leaked, 0, "no leak before 361"),
		361: func() -> void: assert_eq(model.leaked, 1, "#2 leaks exactly at 150 + 211"),
	}
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		var entry_tick := model.tick
		model.step()
		_assert_conservation(model)
		_assert_block_capacity(model)
		if checkpoints.has(entry_tick):
			(checkpoints[entry_tick] as Callable).call()
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(model.tick, 512, "#1 dies on the 7th hit after refocus (331 + 180)")
	assert_eq(model.killed, 2)
	assert_eq(model.leaked, 1)
	assert_eq(model.stars, 2, "1 leak -> 2 stars")
	assert_eq(model.units[0].hp, 35, "120 - 6 hits from #0 - 11 hits from #1")


func test_release_on_retreat() -> void:
	var spawn_ticks: Array[int] = [30]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	var actions := [
		[0, &"deploy", &"vanguard_1", PATH_CELL, RIGHT],
		[200, &"retreat", 0],
	]
	_run_asserted(model, actions, 319)
	assert_eq(model.enemies[0].blocked_by, -1, "released by retreat")
	assert_eq(model.enemies[0].hp, 22, "took hits at 121/151/181 before release")
	assert_eq(model.dp_refunded, 4, "retreat still refunds under block")
	assert_eq(model.leaked, 0, "resumed grunt not home yet at 319")
	model.step()
	assert_eq(model.leaked, 1, "leaks exactly at 319 (resume at 200 + 120 advances)")


func test_release_on_unit_death_no_refund() -> void:
	var glass := (load(VG_PATH) as OperatorDef).duplicate() as OperatorDef
	glass.id = &"glass_1"
	glass.hp = 5
	glass.atk = 0
	var spawn_ticks: Array[int] = [30]
	var extra: Array[OperatorDef] = [glass]
	var model := _make_model(_stage_with_waves(spawn_ticks), extra)
	assert_true(model.apply_action([&"deploy", &"glass_1", PATH_CELL, RIGHT]))
	model.step(122)
	var u := model.units[0]
	assert_false(u.alive, "one grunt hit (5) kills the glass unit on the block tick 121")
	assert_eq(model.enemies[0].blocked_by, -1, "released by death")
	assert_eq(model.dp_refunded, 0, "death refunds nothing")
	assert_eq(model.retreated, 0, "death is not a retreat")
	model.step(180 - model.tick)
	assert_true(model.is_deployable(&"glass_1"), "dead op redeployable once dp recovers")
	model.step(241 - model.tick)
	assert_eq(model.leaked, 0, "not home at entry tick 240")
	model.step()
	assert_eq(model.leaked, 1, "leaks exactly at 241 (resume at 122 + 120 advances)")


func test_capacity_refill_after_kill() -> void:
	var spawn_ticks: Array[int] = [30, 270]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", PATH_CELL, RIGHT]))
	model.step(362)
	assert_eq(model.enemies[1].blocked_by, 0, "late grunt caught by freed capacity at 361")
	model.step(541 - model.tick)
	assert_eq(model.killed, 1, "second kill not yet at entry tick 540")
	model.step()
	assert_eq(model.killed, 2, "idle-ready unit kills on schedule (361 + 180)")
	model.run_to_terminal(MAX_TICKS)
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(model.stars, 3, "no leaks -> 3 stars")


func test_determinism_oracle_combat() -> void:
	var runs: Array = []
	for _run: int in 2:
		var stage := ResourceLoader.load(STAGE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var grunt := ResourceLoader.load(GRUNT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var vg := ResourceLoader.load(VG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var dfd := ResourceLoader.load(DEF_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
		var model := BattleModel.create(
			stage, squad, 42, config, {&"grunt": grunt}, {&"vanguard_1": vg, &"defender_1": dfd}
		)
		var actions := [
			[60, &"deploy", &"vanguard_1", PATH_CELL, RIGHT],
			[480, &"deploy", &"defender_1", Vector2i(2, 2), RIGHT],
			[550, &"retreat", 1],
		]
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
		var outcome := [model.result, model.stars, model.killed, model.leaked, model.tick]
		runs.append({"hashes": hashes, "outcome": outcome})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical on a combat timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")


func test_ledger_under_combat() -> void:
	var spawn_ticks: Array[int] = [30, 90, 150, 210, 270]
	var model := _make_model(_stage_with_waves(spawn_ticks))
	var actions := [
		[60, &"deploy", &"vanguard_1", PATH_CELL, RIGHT],
		[480, &"deploy", &"defender_1", Vector2i(2, 2), RIGHT],
		[550, &"retreat", 1],
	]
	var idx := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			model.apply_action(entry.slice(1))
			idx += 1
		model.step()
		var expected := (
			model.config.dp_start
			+ model.dp_regen_accrued
			+ model.dp_vanguard_generated
			+ model.dp_refunded
			- model.dp_spent
			- model.dp_lost_to_cap
		)
		assert_eq(model.dp, expected, "DP ledger exact under combat @ tick %d" % model.tick)
	assert_true(model.killed > 0, "combat actually happened")
	assert_eq(model.dp_refunded, 8, "defender retreat mid-combat refunded")
