extends GutTest

## Phase 1 gate tests (model-level, no scene tree — architecture rule 2).
## Pinned math (td-phase-0-1.md §4.3): grunt at 1.0 tiles/s -> step_units
## 33_333; test_lane path = 7 cells -> 7_000_000 units -> leak exactly
## 211 ticks after spawn.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"

const GRUNT_TRAVEL_TICKS := 211
const MAX_TICKS := 20_000


func _defs() -> Dictionary:
	var grunt := load(GRUNT_PATH) as EnemyDef
	return {&"grunt": grunt}


func _stage() -> StageDef:
	return load(STAGE_PATH) as StageDef


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _model(stage: StageDef) -> BattleModel:
	var squad: Array[StringName] = []
	return BattleModel.create(stage, squad, 42, _config(), _defs())


func _stage_with_waves(spawn_ticks: Array[int]) -> StageDef:
	var stage := _stage().duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for t: int in spawn_ticks:
		waves.append({"tick": t, "enemy_id": &"grunt", "path_idx": 0})
	stage.waves = waves
	return stage


func test_determinism_oracle() -> void:
	var runs: Array = []
	for _run: int in 2:
		# fresh, cache-bypassing loads so the two runs share no state
		var stage := ResourceLoader.load(STAGE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var grunt := ResourceLoader.load(GRUNT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var squad: Array[StringName] = []
		var model := BattleModel.create(stage, squad, 42, config, {&"grunt": grunt})
		var hashes: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			model.step()
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		runs.append({
			"hashes": hashes,
			"outcome": [model.result, model.stars, model.leaked, model.base_hp, model.tick],
		})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "state_hash identical at every 100th tick")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")


func test_spawn_conservation_every_tick() -> void:
	var model := _model(_stage())
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		model.step()
		var books := model.alive_count() + model.leaked + model.killed
		assert_eq(model.spawned, books, "spawned == alive + leaked + killed @ tick %d" % model.tick)
	assert_ne(model.result, BattleModel.Result.RUNNING, "battle reached a terminal state")


func test_arrival_tick_exactness() -> void:
	var spawn_ticks: Array[int] = [30]
	var model := _model(_stage_with_waves(spawn_ticks))
	var leak_tick := 30 + GRUNT_TRAVEL_TICKS
	model.step(leak_tick)
	assert_eq(model.leaked, 0, "no leak before tick %d (tick=%d)" % [leak_tick, model.tick])
	model.step()
	assert_eq(model.leaked, 1, "leak lands exactly at tick %d" % leak_tick)
	assert_eq(model.base_hp, _config().base_hp_start - 1, "leak costs exactly leak_damage")


func test_leak_limit_defeat_exactness() -> void:
	# 4 grunts vs leak_limit 3: DEFEAT flips on the exact tick of the 4th leak
	var spawn_ticks: Array[int] = [30, 90, 150, 210]
	var model := _model(_stage_with_waves(spawn_ticks))
	var defeat_tick := 210 + GRUNT_TRAVEL_TICKS
	model.step(defeat_tick)
	assert_eq(model.result, BattleModel.Result.RUNNING, "still RUNNING one tick before")
	assert_eq(model.leaked, 3, "3 leaks in the books (limit not exceeded)")
	model.step()
	assert_eq(model.result, BattleModel.Result.DEFEAT, "DEFEAT on the 4th leak's tick")
	assert_eq(model.stars, 0, "no stars on defeat")


func test_leaks_within_limit_clear() -> void:
	# 3 grunts vs leak_limit 3: all leak, still a CLEAR at 1 star
	var spawn_ticks: Array[int] = [30, 90, 150]
	var model := _model(_stage_with_waves(spawn_ticks))
	model.run_to_terminal(MAX_TICKS)
	assert_eq(model.result, BattleModel.Result.CLEAR, "leaks <= leak_limit clears")
	assert_eq(model.leaked, 3, "all three leaked")
	assert_eq(model.stars, 1, "1 star: win with leaks <= leak_limit")


func test_star_table_and_empty_stage() -> void:
	assert_eq(StarCalc.star_for(0, 3), 3)
	assert_eq(StarCalc.star_for(1, 3), 2)
	assert_eq(StarCalc.star_for(2, 3), 2)
	assert_eq(StarCalc.star_for(3, 3), 1)
	assert_eq(StarCalc.star_for(4, 3), 0)
	var empty_ticks: Array[int] = []
	var model := _model(_stage_with_waves(empty_ticks))
	model.step()
	assert_eq(model.result, BattleModel.Result.CLEAR, "empty timeline clears immediately")
	assert_eq(model.stars, 3, "0 leaks = 3 stars")


func test_terminal_freeze() -> void:
	var model := _model(_stage())
	model.run_to_terminal(MAX_TICKS)
	var frozen_hash := model.state_hash()
	var frozen_tick := model.tick
	model.step(100)
	assert_eq(model.state_hash(), frozen_hash, "state hash unchanged after terminal")
	assert_eq(model.tick, frozen_tick, "tick does not advance after terminal")


func test_unknown_verb_rejects_without_state_change() -> void:
	var model := _model(_stage())
	model.step(50)
	var before := model.state_hash()
	var ok := model.apply_action([&"deploy", Vector2i(1, 1), 0])
	assert_false(ok, "unknown verb returns false")
	assert_eq(model.state_hash(), before, "state untouched by rejected action")
