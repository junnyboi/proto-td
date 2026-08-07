extends GutTest

## Phase 4 battle-level gate tests (td-phase-4-5.md §3.2 G3-G9). Tick math is
## decided on paper first (td-phase-0-1.md discipline): an event "at tick T"
## happens during the step whose entry tick is T, observable at model.tick ==
## T+1. Step units: grunt 33_333, runner 66_666, heavy 16_666, drone 40_000,
## spellcaster 26_666, mini_boss 13_333 (floori(speed * 1M / 30)). A walker
## enters path cell k during advance ceil(k * 1M / step_units); test_lane's
## path is 7 cells (leak after 7M units), test_drone's is 10.

const CONFIG_PATH := "res://data/config/game.tres"
const STAGE_LANE := "res://data/stages/test_lane.tres"
const STAGE_DRONE := "res://data/stages/test_drone.tres"
const ENEMY_IDS: Array[StringName] = [
	&"grunt", &"runner", &"heavy", &"drone", &"spellcaster", &"mini_boss",
]
const OP_IDS: Array[StringName] = [
	&"vanguard_1", &"defender_1", &"defender_2", &"sniper_1", &"caster_1",
]

const RIGHT := int(UnitState.Facing.RIGHT)
const UP := int(UnitState.Facing.UP)
const MAX_TICKS := 20_000


func _enemy_defs() -> Dictionary:
	var defs: Dictionary = {}
	for enemy_id: StringName in ENEMY_IDS:
		defs[enemy_id] = load("res://data/enemies/%s.tres" % enemy_id)
	return defs


func _op_defs(extra_ops: Array[OperatorDef] = []) -> Dictionary:
	var defs: Dictionary = {}
	for op_id: StringName in OP_IDS:
		defs[op_id] = load("res://data/operators/%s.tres" % op_id)
	for def: OperatorDef in extra_ops:
		defs[def.id] = def
	return defs


## A block-3 wall that never attacks and never dies (A10: tests may build
## defs programmatically) — isolates blocking mechanics from kill timing.
func _wall_def() -> OperatorDef:
	var wall := (load("res://data/operators/defender_1.tres") as OperatorDef).duplicate()
	wall.id = &"wall_1"
	wall.atk = 0
	wall.hp = 9999
	wall.dp_cost = 8
	return wall


func _stage_with(base_path: String, waves: Array[Dictionary]) -> StageDef:
	var stage := (load(base_path) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _make_model(stage: StageDef, extra_ops: Array[OperatorDef] = []) -> BattleModel:
	var ops := _op_defs(extra_ops)
	var squad: Array[StringName] = []
	for op_id: StringName in ops:
		squad.append(op_id)
	var config := load(CONFIG_PATH) as GameConfig
	return BattleModel.create(stage, squad, 42, config, _enemy_defs(), ops)


func _assert_conservation(model: BattleModel) -> void:
	var books := model.alive_count() + model.killed + model.leaked
	assert_eq(model.spawned, books, "spawned == alive + killed + leaked @ tick %d" % model.tick)


func _assert_block_capacity(model: BattleModel) -> void:
	for u: UnitState in model.units:
		var held := 0
		for enemy_id: int in u.blocked_ids:
			held += model.enemies[enemy_id].block_weight
		assert_true(
			held <= u.block, "unit %d holds %d/%d @ tick %d" % [u.id, held, u.block, model.tick]
		)


## G5: aerial is an absolute counter — a drone crosses a full-capacity
## Defender cell without ever entering block assignment, melee never damages
## it, and it leaks on the pure Phase-1 arrival math (spawn 300 + ceil(7M /
## 40_000) = 475).
func test_aerial_bypass_never_blocked() -> void:
	var waves: Array[Dictionary] = [{"tick": 300, "enemy_id": &"drone", "path_idx": 0}]
	var model := _make_model(_stage_with(STAGE_LANE, waves))
	model.step(180)
	assert_true(model.apply_action([&"deploy", &"defender_1", Vector2i(3, 2), RIGHT]))
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		model.step()
		_assert_conservation(model)
		for e: EnemyState in model.enemies:
			assert_eq(e.blocked_by, -1, "drone never blocked @ tick %d" % model.tick)
		assert_eq(model.units[0].blocked_ids.size(), 0, "block ledger untouched")
	assert_eq(model.tick, 476, "drone leaks exactly at 475 — pure arrival math")
	assert_eq(model.leaked, 1)
	assert_eq(model.enemies[0].hp, 30, "melee never damaged the drone")
	assert_eq(model.units[0].last_attack_tick, -1, "defender never fired")


## G3 battle-level: sniper anti-air priority picks the drone over a
## further-progressed ground grunt, then falls back to ground once the air is
## clear. Deploy at 150: grunt (spawn 30) is at 3_999_960, drone (spawn 60)
## at 3_600_000 — both in the 4x3 range from (2,1) facing RIGHT (cells
## x3..6, y0..2). Hits at 150/180/210 kill the 30 hp drone at 210; the grunt
## takes one fallback hit at 240 and leaks at 30 + 211 = 241.
func test_sniper_anti_air_priority_battle() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"drone", "path_idx": 0},
	]
	var model := _make_model(_stage_with(STAGE_LANE, waves))
	model.step(150)
	assert_true(model.apply_action([&"deploy", &"sniper_1", Vector2i(2, 1), RIGHT]))
	model.step()
	assert_eq(model.enemies[1].hp, 20, "first shot hits the drone on the deploy tick")
	assert_eq(model.enemies[0].hp, 40, "grunt untouched while a drone is in range")
	model.step(211 - model.tick)
	assert_eq(model.killed, 1, "drone down on the third shot at 210")
	assert_false(model.enemies[1].alive)
	model.step(242 - model.tick)
	assert_eq(model.enemies[0].hp, 30, "one fallback ground hit at 240")
	assert_eq(model.leaked, 1, "grunt leaks at 241")
	assert_eq(model.result, BattleModel.Result.CLEAR)


## G4 battle-level: caster splash damages exactly the 3x3 set around the
## primary and never touches aerial. Wall (block 3, atk 0) on (4,2) holds
## three grunts frozen at 4_033_293 (blocked at 151/211/271); a fourth grunt
## (spawn 400) is still on cell 1 at the caster's first shot; a drone (spawn
## 330) is INSIDE the blast cell at 4.8M progress — the highest progress in
## range — and must be excluded from both primary selection and splash.
## Caster deploys at 450 (dp = 2 + 14 regen = 16 exactly) and fires the same
## tick: primary = lowest-id tied grunt, splash = cells x3..5 / y1..3.
func test_caster_splash_exactness() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 150, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 330, "enemy_id": &"drone", "path_idx": 0},
		{"tick": 400, "enemy_id": &"grunt", "path_idx": 0},
	]
	var extra: Array[OperatorDef] = [_wall_def()]
	var model := _make_model(_stage_with(STAGE_LANE, waves), extra)
	assert_true(model.apply_action([&"deploy", &"wall_1", Vector2i(4, 2), RIGHT]))
	model.step(450)
	assert_eq(model.units[0].blocked_ids.size(), 3, "wall holds all three grunts")
	assert_true(model.apply_action([&"deploy", &"caster_1", Vector2i(2, 1), RIGHT]))
	model.step()
	assert_eq(model.units[1].last_attack_tick, 450, "caster fires on its deploy tick")
	assert_eq(model.units[1].last_attack_cell, Vector2i(4, 2), "primary is the blocked cluster")
	for i: int in 3:
		assert_eq(model.enemies[i].hp, 31, "grunt %d took exactly one 9-dmg splash" % i)
	assert_eq(model.enemies[3].hp, 30, "aerial inside the blast untouched")
	assert_eq(model.enemies[4].hp, 40, "walker on cell 1 outside the 3x3 untouched")
	model.step(496 - model.tick)
	assert_eq(model.enemies[0].hp, 22, "second splash lands exactly one interval later (495)")


## G6a: spellcaster ranged attack while walking — hits the nearest unit
## within Chebyshev 2 on ready-at-contact cadence (enters cell 1 at 30 + 38
## = 68; hits every 54: 68/122, blocked on cell 3 at 143, cadence continues
## against the blocker: 176/230/284/338). Vanguard (atk 6) kills the 45 hp
## spellcaster on the 8th hit at 143 + 210 = 353; total intake 6 x 7 = 42.
func test_spellcaster_ranged_and_blocked() -> void:
	var waves: Array[Dictionary] = [{"tick": 30, "enemy_id": &"spellcaster", "path_idx": 0}]
	var model := _make_model(_stage_with(STAGE_LANE, waves))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", Vector2i(3, 2), RIGHT]))
	model.step(68)
	assert_eq(model.units[0].hp, 120, "out of range until cell 1 (tick 68)")
	model.step()
	assert_eq(model.units[0].hp, 113, "first ranged hit at 68 from Chebyshev 2")
	model.step(123 - model.tick)
	assert_eq(model.units[0].hp, 106, "second hit on exact 54-tick cadence (122)")
	model.step(144 - model.tick)
	assert_eq(model.enemies[0].blocked_by, 0, "blocked on cell 3 at 143")
	model.step(354 - model.tick)
	assert_eq(model.killed, 1, "vanguard kills it on the 8th hit at 353")
	assert_eq(model.units[0].hp, 78, "six spellcaster hits total (42 damage)")


## G6b: a unit at Chebyshev 3 from every path cell is never attacked
## (test_drone's 6-row grid provides the distance; test_lane cannot).
func test_spellcaster_ignores_chebyshev_3() -> void:
	var waves: Array[Dictionary] = [{"tick": 30, "enemy_id": &"spellcaster", "path_idx": 0}]
	var model := _make_model(_stage_with(STAGE_DRONE, waves))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", Vector2i(3, 5), RIGHT]))
	model.run_to_terminal(MAX_TICKS)
	assert_eq(model.units[0].hp, 120, "unit at distance 3 never hit")
	assert_eq(model.leaked, 1, "spellcaster walked home unopposed")


## G7: mini-boss block weight — a block-3 wall holds boss (2) + grunt (1);
## a second grunt finds zero capacity and walks past (leaks at 300 + 211 =
## 511). Boss enters cell 3 at 30 + ceil(3M / 13_333) = 256; the first grunt
## at 90 + 91 = 181.
func test_mini_boss_block_weight() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"mini_boss", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 300, "enemy_id": &"grunt", "path_idx": 0},
	]
	var extra: Array[OperatorDef] = [_wall_def()]
	var model := _make_model(_stage_with(STAGE_LANE, waves), extra)
	assert_true(model.apply_action([&"deploy", &"wall_1", Vector2i(3, 2), RIGHT]))
	var checkpoints := {
		181: func() -> void: assert_eq(model.enemies[1].blocked_by, 0, "grunt #1 blocked at 181"),
		256: func() -> void: assert_eq(model.enemies[0].blocked_by, 0, "boss blocked at 256"),
		511: func() -> void: assert_eq(model.leaked, 1, "grunt #2 leaks at 511"),
	}
	while model.tick < 600:
		var entry_tick := model.tick
		model.step()
		_assert_conservation(model)
		_assert_block_capacity(model)
		if model.enemies.size() > 2:
			assert_eq(model.enemies[2].blocked_by, -1, "grunt #2 never blocked")
		if checkpoints.has(entry_tick):
			(checkpoints[entry_tick] as Callable).call()
	var held := model.units[0].blocked_ids
	assert_eq(held, [1, 0] as Array[int], "wall holds grunt #1 + boss, weight 3 of 3")


## G8 — THE PHASE GATE (acceptance #4, composition proof): on test_drone the
## same deploy timeline flips on exactly one swapped operator. All-Defender:
## grunts get blocked and killed, but the three drones bypass every blocker
## and leak (750/950/1050) past leak_limit 2 -> DEFEAT at 1050. Swapping the
## second Defender for sniper_1 on the elevated tile (4,1): drone #0 leaks
## at 750 before the 720 deploy can finish it, drones #1/#2 die in range
## (3 x 10 dmg at 825..885 and 925..985) -> CLEAR at 985 with 1 leak.
func test_composition_proof() -> void:
	var defender_timeline := [
		[180, &"deploy", &"defender_1", Vector2i(3, 2), RIGHT],
		[720, &"deploy", &"defender_2", Vector2i(5, 2), RIGHT],
	]
	var sniper_timeline := [
		[180, &"deploy", &"defender_1", Vector2i(3, 2), RIGHT],
		[720, &"deploy", &"sniper_1", Vector2i(4, 1), RIGHT],
	]

	var all_defender := _make_model(load(STAGE_DRONE) as StageDef)
	all_defender.run_timeline(defender_timeline, MAX_TICKS)
	assert_eq(all_defender.result, BattleModel.Result.DEFEAT, "all-Defender loses the drone stage")
	assert_eq(all_defender.tick, 1051, "third drone leak at 1050 breaks leak_limit 2")
	assert_eq(all_defender.leaked, 3, "every drone leaked")
	assert_eq(all_defender.killed, 3, "the grunts still died to melee")

	var with_sniper := _make_model(load(STAGE_DRONE) as StageDef)
	with_sniper.run_timeline(sniper_timeline, MAX_TICKS)
	assert_eq(with_sniper.result, BattleModel.Result.CLEAR, "one Sniper flips the same timeline")
	assert_eq(with_sniper.tick, 986, "last drone dies at 985")
	assert_eq(with_sniper.leaked, 1, "only the pre-deploy drone slipped through")
	assert_eq(with_sniper.killed, 5, "3 grunts + 2 drones")
	for i: int in [3, 4, 5]:
		assert_eq(with_sniper.enemies[i].blocked_by, -1, "drone %d was never blocked" % i)


## G9: determinism oracle + conservation on a class-heavy timeline — all six
## enemy types spawn, sniper/caster/spellcaster/aerial/boss-weight paths all
## execute, kills > 0, two cache-bypassed runs hash identically.
func test_determinism_oracle_class_heavy() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"runner", "path_idx": 0},
		{"tick": 90, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 120, "enemy_id": &"drone", "path_idx": 0},
		{"tick": 150, "enemy_id": &"spellcaster", "path_idx": 0},
		{"tick": 180, "enemy_id": &"mini_boss", "path_idx": 0},
		{"tick": 600, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 660, "enemy_id": &"runner", "path_idx": 0},
	]
	var actions := [
		[60, &"deploy", &"vanguard_1", Vector2i(3, 2), RIGHT],
		[240, &"deploy", &"sniper_1", Vector2i(2, 1), RIGHT],
		[600, &"deploy", &"caster_1", Vector2i(5, 3), UP],
		[990, &"deploy", &"defender_1", Vector2i(4, 2), RIGHT],
	]
	var runs: Array = []
	for run_i: int in 2:
		var stage := ResourceLoader.load(
			STAGE_LANE, "", ResourceLoader.CACHE_MODE_IGNORE
		).duplicate(true) as StageDef
		stage.waves = waves
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var enemy_defs: Dictionary = {}
		for enemy_id: StringName in ENEMY_IDS:
			enemy_defs[enemy_id] = ResourceLoader.load(
				"res://data/enemies/%s.tres" % enemy_id, "", ResourceLoader.CACHE_MODE_IGNORE
			)
		var ops: Dictionary = {}
		var squad: Array[StringName] = []
		for op_id: StringName in OP_IDS:
			ops[op_id] = ResourceLoader.load(
				"res://data/operators/%s.tres" % op_id, "", ResourceLoader.CACHE_MODE_IGNORE
			)
			squad.append(op_id)
		var model := BattleModel.create(stage, squad, 42, config, enemy_defs, ops)
		var idx := 0
		var hashes: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < actions.size() and int(actions[idx][0]) == model.tick:
				var entry: Array = actions[idx]
				model.apply_action(entry.slice(1))
				idx += 1
			model.step()
			if run_i == 0:
				_assert_conservation(model)
				_assert_block_capacity(model)
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		var outcome := [model.result, model.stars, model.killed, model.leaked, model.tick]
		runs.append({"hashes": hashes, "outcome": outcome, "killed": model.killed})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical on a class-heavy timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")
	assert_true(int(runs[0]["killed"]) > 0, "combat actually happened")
