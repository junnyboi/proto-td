extends GutTest

const SQUAD: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]
const VANGUARD_CELL := Vector2i(3, 2)
const GUARD_CELL := Vector2i(4, 2)
const DEFENDER_CELL := Vector2i(5, 2)
const RIGHT := int(UnitState.Facing.RIGHT)


func _catalog(directory: String) -> Dictionary:
	var catalog: Dictionary = {}
	var dir := DirAccess.open(directory)
	assert_not_null(dir, directory)
	if dir == null:
		return catalog
	for filename: String in dir.get_files():
		var resource_name := filename.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var resource: Resource = load("%s/%s" % [directory, resource_name])
		if resource != null and resource.get("id") != null:
			catalog[resource.get("id")] = resource
	return catalog


func _model() -> BattleModel:
	var stage := load("res://data/stages/s1.tres") as StageDef
	return BattleModel.create(
		stage,
		SQUAD,
		42,
		load("res://data/config/game.tres") as GameConfig,
		{&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef},
		_catalog("res://data/operators"),
	)


func _step_to(model: BattleModel, target_tick: int) -> void:
	while model.tick < target_tick and model.result == BattleModel.Result.RUNNING:
		model.step()


func test_cues_have_authoritative_sources_and_absent_warning_lethal_output() -> void:
	var cues := load("res://data/presentation/s1_slice_cues.tres") as TacticalCueConfig
	assert_not_null(cues)
	if cues == null:
		return
	assert_eq(cues.validate_contract(), PackedStringArray())
	assert_gt(cues.cues[&"legal"][&"color"].a, 0.0)
	assert_gt(cues.cues[&"invalid"][&"color"].a, 0.0)
	assert_gt(cues.cues[&"range"][&"color"].a, 0.0)
	assert_gt(cues.cues[&"skill"][&"color"].a, 0.0)
	assert_eq(cues.cues[&"warning"][&"color"].a, 0.0, "no warning source means zero output")
	assert_eq(cues.cues[&"lethal"][&"color"].a, 0.0, "no lethal source means zero output")

	var model := _model()
	assert_true(model.can_deploy_at(&"vanguard_1", VANGUARD_CELL))
	assert_false(model.can_deploy_at(&"vanguard_1", Vector2i(0, 2)))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", VANGUARD_CELL, RIGHT]))
	var unit := model.units[0]
	assert_eq(
		Targeting.range_cells(unit.cell, unit.range_offsets, int(unit.facing)),
		{VANGUARD_CELL: true},
	)
	assert_false(unit.is_skill_ready())
	unit.sp = unit.sp_cost
	assert_true(unit.is_skill_ready(), "readiness source is UnitState validator")


func test_seed42_measured_s1_sequence_and_outcome_remain_exact() -> void:
	var model := _model()
	_step_to(model, 6)
	assert_true(model.apply_action([&"deploy", &"vanguard_1", VANGUARD_CELL, RIGHT]))
	_step_to(model, 306)
	assert_true(model.apply_action([&"deploy", &"guard_1", GUARD_CELL, RIGHT]))
	_step_to(model, 332)
	assert_eq(model.killed, 1, "first kill observed at tick 332")
	_step_to(model, 456)
	var vanguard := model.units[0]
	assert_true(vanguard.is_skill_ready(), "vanguard ready at measured click tick")
	assert_true(model.apply_action([&"trigger_skill", vanguard.id]))
	_step_to(model, 800)
	assert_true(model.apply_action([&"deploy", &"defender_1", DEFENDER_CELL, RIGHT]))
	model.step()
	assert_eq(model.tick, 801)
	assert_eq(model.units.size(), 3)
	assert_eq(model.alive_enemy_count(), 2)
	assert_eq(model.spawned, 6)
	assert_eq(model.killed, 4)
	assert_eq(model.leaked, 0)
	assert_eq(model.result, BattleModel.Result.RUNNING)
	_step_to(model, 902)
	assert_eq(model.tick, 902)
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(model.killed, 6)
	assert_eq(model.leaked, 0)
	assert_eq(model.stars, 3)
