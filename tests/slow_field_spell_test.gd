extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	_test_assets()
	_test_campaign_unlock_contract()
	_test_slow_field_lifecycle()
	if _failures.is_empty():
		print("SLOW_FIELD_SPELL_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_assets() -> void:
	_check(Art.texture(&"icon_slow_field") != null, "Slow Field icon is missing from Art")
	_check(Art.size(&"icon_slow_field") == Vector2i(24, 24), "Slow Field icon size drifted")
	_check(Art.texture(&"vfx_slow_field") != null, "Slow Field VFX is missing from Art")
	_check(Art.size(&"vfx_slow_field") == Vector2i(96, 48), "Slow Field VFX size drifted")


func _test_campaign_unlock_contract() -> void:
	var context := CampaignRuntimeContext.build()
	_check(not context.is_empty(), "campaign context rejected the Slow Field catalog")
	if context.is_empty():
		return
	var s6_rewards: Array = []
	for row: Dictionary in context["campaign"]["v3_stage_rewards"]:
		if row["stage_id"] == "s6":
			s6_rewards = row["rewards"]
			break
	_check(
		s6_rewards.has({"id": "slow_field", "kind": "spell"}),
		"V3 S6 rewards do not grant Slow Field",
	)


func _test_slow_field_lifecycle() -> void:
	var stage := StageDef.new()
	stage.id = &"slow_field_fixture"
	stage.grid_rows = PackedStringArray(["SGGGGGGGGGGGGGGGGGB"])
	var path := PackedVector2Array()
	for x: int in stage.grid_rows[0].length():
		path.append(Vector2(x, 0))
	var paths: Array[PackedVector2Array] = [path]
	stage.paths = paths
	stage.waves = [
		{"tick": 0, "enemy_id": &"ground", "path_idx": 0},
		{"tick": 0, "enemy_id": &"aerial", "path_idx": 0},
	]
	stage.wave_starts = PackedInt32Array([0])
	stage.leak_limit = 10

	var ground_def := EnemyDef.new()
	ground_def.id = &"ground"
	ground_def.hp = 100
	ground_def.speed_tiles_per_s = 1.0
	ground_def.sprite_id = &"grunt"
	var aerial_def := EnemyDef.new()
	aerial_def.id = &"aerial"
	aerial_def.hp = 100
	aerial_def.speed_tiles_per_s = 1.0
	aerial_def.aerial = true
	aerial_def.sprite_id = &"drone"

	var spell := load("res://data/spells/slow_field.tres") as SpellDef
	_check(spell != null, "Slow Field resource failed to load")
	if spell == null:
		return
	var model := BattleModel.create(
		stage,
		[],
		101,
		GameConfig.new(),
		{&"ground": ground_def, &"aerial": aerial_def},
		{},
		{},
		{&"slow_field": spell},
	)
	_check(model != null, "Slow Field fixture model failed to create")
	if model == null:
		return

	model.step()
	var ground := _enemy(model, &"ground")
	var aerial := _enemy(model, &"aerial")
	_check(ground != null and aerial != null, "fixture enemies did not spawn")
	if ground == null or aerial == null:
		return
	var baseline_hash := model.state_hash()
	_check(
		not model.apply_action([&"cast", &"slow_field", Vector2i(99, 0)]),
		"out-of-grid Slow Field cast was accepted",
	)
	_check(model.state_hash() == baseline_hash, "rejected Slow Field cast mutated state")

	var cast_tick := model.tick
	_check(
		model.apply_action([&"cast", &"slow_field", Vector2i(0, 0)]),
		"valid Slow Field cast was rejected",
	)
	_check(model.slow_fields.size() == 1, "valid cast did not create one active field")
	var field := model.slow_fields[0] if not model.slow_fields.is_empty() else null
	if field != null:
		_check(field.center == Vector2i(0, 0), "Slow Field center drifted")
		_check(field.radius == 1, "Slow Field radius drifted")
		_check(field.slow_permille == 500, "Slow Field slow amount drifted")
		_check(field.expires_tick == cast_tick + 240, "Slow Field expiry tick drifted")
	_check(
		model.spell_book.ready_at(&"slow_field") == cast_tick + 600,
		"Slow Field cooldown accounting drifted",
	)
	_check(model.spell_book.casts(&"slow_field") == 1, "Slow Field cast ledger drifted")
	_check(model.state_hash() != baseline_hash, "successful Slow Field cast did not change hash")
	var replay := BattleModel.create(
		stage,
		[],
		101,
		GameConfig.new(),
		{&"ground": ground_def, &"aerial": aerial_def},
		{},
		{},
		{&"slow_field": spell},
	)
	replay.step()
	_check(
		replay.apply_action([&"cast", &"slow_field", Vector2i(0, 0)]),
		"deterministic replay cast was rejected",
	)
	_check(replay.state_hash() == model.state_hash(), "Slow Field replay hash diverged")
	_check(model.snapshot()["slow_fields_active"] == 1, "snapshot omitted active Slow Field")
	var observation := BattleObservation.from_model(model).to_dictionary()
	_check(observation["version"] == 2, "battle observation schema version was not advanced")
	_check((observation["slow_fields"] as Array).size() == 1, "observation omitted Slow Field")

	var ground_before := ground.progress_units
	var aerial_before := aerial.progress_units
	model.step()
	_check(
		ground.progress_units - ground_before == ground.step_units / 2,
		"ground enemy did not receive the 50% Slow Field movement modifier",
	)
	_check(
		aerial.progress_units - aerial_before == aerial.step_units,
		"aerial enemy was incorrectly slowed by the ground field",
	)
	var tar := TrapState.new()
	tar.id = 0
	tar.def_id = &"tar_pit"
	tar.cell = Vector2i(0, 0)
	tar.trigger = TrapDef.Trigger.CELL_AURA
	tar.slow_permille = 700
	model.traps.append(tar)
	ground_before = ground.progress_units
	model.step()
	@warning_ignore("integer_division")
	var expected_tar_step := ground.step_units * 300 / 1000
	_check(
		ground.progress_units - ground_before == expected_tar_step,
		"Slow Field and Tar Pit did not resolve to the strongest single slow",
	)
	model.traps.erase(tar)

	while model.tick < cast_tick + spell.duration_ticks:
		model.step()
	_check(model.slow_fields.is_empty(), "Slow Field did not expire at its exclusive end tick")
	_check(model.snapshot()["slow_fields_active"] == 0, "snapshot retained an expired Slow Field")


func _enemy(model: BattleModel, def_id: StringName) -> EnemyState:
	for enemy: EnemyState in model.enemies:
		if enemy.def_id == def_id:
			return enemy
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
