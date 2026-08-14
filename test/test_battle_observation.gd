extends GutTest

const OBSERVATION := preload("res://sim/battle_observation.gd")
const RIGHT := UnitState.Facing.RIGHT


func _config() -> GameConfig:
	return load("res://data/config/game.tres") as GameConfig


func _enemy(id: StringName, aerial := false, weight := 1, leak := 1) -> EnemyDef:
	var definition := EnemyDef.new()
	definition.id = id
	definition.hp = 100
	definition.speed_tiles_per_s = 1.0
	definition.aerial = aerial
	definition.block_weight = weight
	definition.leak_damage = leak
	return definition


func _stage(waves: Array[Dictionary] = []) -> StageDef:
	var stage := StageDef.new()
	stage.id = &"observation_test"
	stage.grid_rows = PackedStringArray(["SGGB", "SGGB"])
	stage.paths = [
		PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)]),
		PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)]),
	]
	stage.waves = waves
	stage.wave_starts = PackedInt32Array([0])
	stage.leak_limit = 99
	return stage


func _model(waves: Array[Dictionary] = []) -> BattleModel:
	var defs := {
		&"ground": _enemy(&"ground", false, 2, 3),
		&"drone": _enemy(&"drone", true, 1, 2),
	}
	var vanguard := load("res://data/operators/vanguard_1.tres") as OperatorDef
	var squad: Array[StringName] = [&"vanguard_1"]
	return BattleModel.create(
		_stage(waves), squad, 42, _config(), defs, {&"vanguard_1": vanguard}
	)


func _row(tick: int, enemy_id: StringName, path_idx: int) -> Dictionary:
	return {"tick": tick, "enemy_id": enemy_id, "path_idx": path_idx}


func _cold_model() -> BattleModel:
	var stage := ResourceLoader.load(
		"res://data/stages/s6.tres", "", ResourceLoader.CACHE_MODE_IGNORE
	) as StageDef
	var config := ResourceLoader.load(
		"res://data/config/game.tres", "", ResourceLoader.CACHE_MODE_IGNORE
	) as GameConfig
	var enemies := {
		&"grunt": ResourceLoader.load(
			"res://data/enemies/grunt.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		),
		&"heavy": ResourceLoader.load(
			"res://data/enemies/heavy.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		),
	}
	return BattleModel.create(stage, [], 42, config, enemies)


func test_schema_deep_copy_primitive_only_and_hash_unchanged() -> void:
	var model := _model([_row(0, &"ground", 0)])
	model.step()
	var before := model.state_hash()
	var observation := OBSERVATION.from_model(model)
	var value := observation.to_dictionary()
	assert_eq(value["schema_id"], "prototype_td_battle_observation")
	assert_eq(value["version"], 1)
	assert_true(OBSERVATION.recursive_primitive_only(value))
	(value["paths"] as Array).clear()
	assert_eq((observation.to_dictionary()["paths"] as Array).size(), 2)
	assert_eq(model.state_hash(), before)


func test_t_and_t_plus_one_observability_and_upcoming_boundaries() -> void:
	var model := _model([
		_row(0, &"ground", 0),
		_row(299, &"ground", 0),
		_row(300, &"drone", 1),
	])
	var at_zero := OBSERVATION.from_model(model).to_dictionary()
	assert_eq(at_zero["paths"][0]["active_count"], 0)
	assert_eq(at_zero["paths"][0]["upcoming_count"], 2)
	assert_eq(at_zero["paths"][1]["upcoming_count"], 0, "exclusive 10-second end")
	model.step()
	var at_one := OBSERVATION.from_model(model).to_dictionary()
	assert_eq(at_one["paths"][0]["active_count"], 1)
	assert_eq(at_one["enemies"][0]["progress_units"], 0)
	model.step()
	var at_two := OBSERVATION.from_model(model).to_dictionary()
	assert_gt(int(at_two["enemies"][0]["progress_units"]), 0)


func test_empty_two_path_order_and_source_permutation() -> void:
	var model := _model()
	var first := OBSERVATION.from_model(model).to_dictionary()
	assert_eq(first["paths"][0]["path_idx"], 0)
	assert_eq(first["paths"][1]["path_idx"], 1)
	assert_eq(first["paths"][0]["minimum_unopposed_base_eta"], -1)
	var waves: Array[Dictionary] = [_row(10, &"drone", 1), _row(5, &"ground", 0)]
	var a := _model(waves)
	var b := _model([waves[1], waves[0]])
	assert_eq(OBSERVATION.from_model(a).sha256(), OBSERVATION.from_model(b).sha256())


func test_same_tick_source_permutations_are_canonical() -> void:
	var model := _model([
		_row(5, &"ground", 0), _row(5, &"drone", 1), _row(5, &"ground", 1),
	])
	model.step(6)
	var before := OBSERVATION.from_model(model).to_dictionary()
	model.enemies.reverse()
	assert_eq(OBSERVATION.from_model(model).to_dictionary(), before)


func test_cache_ignored_cold_loads_have_equal_observations() -> void:
	var a := _cold_model()
	var b := _cold_model()
	assert_ne(a.stage, b.stage)
	assert_ne(a.config, b.config)
	assert_eq(OBSERVATION.from_model(a).to_dictionary(), OBSERVATION.from_model(b).to_dictionary())
	assert_eq(OBSERVATION.from_model(a).sha256(), OBSERVATION.from_model(b).sha256())


func test_eta_ceiling_block_saturation_overflow_and_aerial() -> void:
	var model := _model([
		_row(0, &"ground", 0),
		_row(0, &"ground", 0),
		_row(0, &"drone", 1),
	])
	assert_true(model.apply_action([&"deploy", &"vanguard_1", Vector2i(1, 0), RIGHT]))
	model.step()
	var value := OBSERVATION.from_model(model).to_dictionary()
	var lane0: Dictionary = value["paths"][0]
	var lane1: Dictionary = value["paths"][1]
	assert_eq(lane0["block_weight"], 4)
	assert_eq(lane0["effective_block_capacity"], 2)
	assert_eq(lane0["overflow_weight"], 2)
	assert_eq(lane0["saturation_permille"], 0)
	assert_eq(lane0["nearest_blocker_contact_eta"], 31)
	assert_eq(lane0["minimum_unopposed_base_eta"], 121)
	assert_eq(lane1["aerial_count"], 1)
	assert_true(lane1["uncountered_aerial"])
	assert_eq(lane1["overflow_weight"], 0, "aerial enemies bypass block capacity")
	model.step(31)
	value = OBSERVATION.from_model(model).to_dictionary()
	lane0 = value["paths"][0]
	assert_eq(lane0["blocked_weight"], 2)
	assert_eq(lane0["saturation_permille"], 1000)
	assert_eq(lane0["overflow_weight"], 2)


func test_terminal_cause_and_numeric_id_order() -> void:
	var model := _model([_row(0, &"ground", 0), _row(0, &"drone", 1)])
	model.step()
	model.enemies.reverse()
	var value := OBSERVATION.from_model(model).to_dictionary()
	assert_eq(value["enemies"][0]["id"], 0)
	assert_eq(value["enemies"][1]["id"], 1)
	assert_true(model.apply_action([&"resign"]))
	value = OBSERVATION.from_model(model).to_dictionary()
	assert_eq(value["result"], "defeat")
	assert_eq(value["terminal_cause"], "resign")


func test_source_array_permutation_preserves_blocked_weight_and_hash() -> void:
	var model := _model([_row(0, &"ground", 0), _row(0, &"ground", 0)])
	assert_true(model.apply_action([&"deploy", &"vanguard_1", Vector2i(1, 0), RIGHT]))
	model.step(32)
	var before_hash := model.state_hash()
	var before := OBSERVATION.from_model(model).to_dictionary()
	model.enemies.reverse()
	var after := OBSERVATION.from_model(model).to_dictionary()
	assert_eq(after, before)
	model.enemies.reverse()
	assert_eq(model.state_hash(), before_hash)


func test_clear_leak_and_base_terminal_causes() -> void:
	var clear_model := _model()
	clear_model.step()
	assert_eq(OBSERVATION.from_model(clear_model).to_dictionary()["terminal_cause"], "clear")
	var leak_model := _model([_row(0, &"ground", 0)])
	leak_model.stage.leak_limit = 0
	leak_model.run_to_terminal(200)
	assert_eq(OBSERVATION.from_model(leak_model).to_dictionary()["terminal_cause"], "leak_defeat")
	var base_model := _model([_row(0, &"ground", 0)])
	base_model.stage.leak_limit = 99
	base_model.base_hp = 1
	base_model.run_to_terminal(200)
	assert_eq(OBSERVATION.from_model(base_model).to_dictionary()["terminal_cause"], "base_defeat")
