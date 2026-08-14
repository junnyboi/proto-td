extends GutTest

const CONFIG_PATH := "res://data/config/game.tres"
const STAGE_LANE := "res://data/stages/test_lane.tres"
const STAGE_SKILL := "res://data/stages/test_skill.tres"
const RIGHT := int(UnitState.Facing.RIGHT)
const HEALER_ID := &"witch_doctor_1"
const MEND_EFFECT := 6
const MEND_AMOUNT := 60
const MEND_RANGE := 2
const I32_MAX := 2_147_483_647


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _enemy_defs() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"heavy": load("res://data/enemies/heavy.tres") as EnemyDef,
	}


func _stage_with(base_path: String, waves: Array[Dictionary]) -> StageDef:
	var stage := (load(base_path) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _idle_stage() -> StageDef:
	return _stage_with(
		STAGE_LANE,
		[{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}] as Array[Dictionary],
	)


func _healer_def() -> OperatorDef:
	var base := load("res://data/operators/caster_2.tres") as OperatorDef
	var def := base.duplicate(true) as OperatorDef
	def.id = HEALER_ID
	def.display_name = "Witch Doctor"
	def.op_class = MEND_EFFECT - 1 as OperatorDef.OpClass
	def.rarity = 3
	def.dp_cost = 18
	def.block = 0
	def.hp = 110
	def.atk = 0
	def.atk_interval_ticks = 45
	def.splash_dim = 0
	def.placement = OperatorDef.Placement.ELEVATED
	var skill := SkillDef.new()
	skill.id = &"mend"
	skill.display_name = "Mend"
	skill.sp_cost = 10
	skill.duration_ticks = 0
	skill.effect = MEND_EFFECT as SkillDef.Effect
	skill.params = {"amount": MEND_AMOUNT, "range_cells": MEND_RANGE}
	def.skill = skill
	return def


func _pair_model(
	target_id: StringName = &"defender_1",
	target_cell: Vector2i = Vector2i(4, 2),
	healer_cell: Vector2i = Vector2i(2, 1),
) -> BattleModel:
	var target := load("res://data/operators/%s.tres" % target_id) as OperatorDef
	var healer := _healer_def()
	var ops := {target_id: target, HEALER_ID: healer}
	var squad: Array[StringName] = [target_id, HEALER_ID]
	var model := BattleModel.create(_idle_stage(), squad, 42, _config(), _enemy_defs(), ops)
	assert_true(model.apply_action([&"debug_set_dp", 99]))
	assert_true(model.apply_action([&"deploy", target_id, target_cell, RIGHT]))
	assert_true(model.apply_action([&"deploy", HEALER_ID, healer_cell, RIGHT]))
	return model


func _ready_pair(
	target_id: StringName = &"defender_1",
	target_cell: Vector2i = Vector2i(4, 2),
	healer_cell: Vector2i = Vector2i(2, 1),
) -> BattleModel:
	var model := _pair_model(target_id, target_cell, healer_cell)
	model.units[0].hp = 40
	model.units[1].sp = model.units[1].sp_cost
	return model


func _assert_rejected(model: BattleModel, action: Array, label: String) -> void:
	var before := model.state_hash()
	assert_false(model.apply_action(action), "%s rejects" % label)
	assert_eq(model.state_hash(), before, "%s leaves the full state hash unchanged" % label)


func test_append_only_ordinals_and_existing_resources() -> void:
	assert_eq(int(OperatorDef.OpClass.CASTER), 4, "existing CASTER ordinal is immutable")
	assert_eq(int(OperatorDef.OpClass.HEALER), 5, "HEALER appends at ordinal 5")
	assert_eq(int(SkillDef.Effect.STUN_IN_RANGE), 5, "existing stun ordinal is immutable")
	assert_eq(int(SkillDef.Effect.HEAL_TARGET), 6, "HEAL_TARGET appends at ordinal 6")
	var expected_classes := {
		&"vanguard_1": 0,
		&"vanguard_2": 0,
		&"guard_1": 1,
		&"guard_2": 1,
		&"defender_1": 2,
		&"defender_2": 2,
		&"sniper_1": 3,
		&"sniper_2": 3,
		&"caster_1": 4,
		&"caster_2": 4,
	}
	for op_id: StringName in expected_classes:
		var def := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		assert_eq(int(def.op_class), expected_classes[op_id], "%s semantic class" % op_id)
	var expected_effects := {
		&"bastion_slam": 5,
		&"conflagration": 4,
		&"deadeye": 0,
		&"flurry": 1,
		&"hold_the_line": 2,
		&"overpower": 0,
		&"rally": 3,
		&"rapid_volley": 1,
		&"tempest": 0,
		&"war_banner": 3,
	}
	for skill_id: StringName in expected_effects:
		var skill := load("res://data/skills/%s.tres" % skill_id) as SkillDef
		assert_eq(int(skill.effect), expected_effects[skill_id], "%s semantic effect" % skill_id)


func test_template_contract_is_a_separate_advanced_mage_path() -> void:
	var def := load("res://data/operators/witch_doctor_1.tres") as OperatorDef
	assert_not_null(def)
	if def == null:
		return
	assert_eq(def.id, HEALER_ID)
	assert_eq(def.display_name, "Witch Doctor")
	assert_eq(int(def.op_class), 5)
	assert_eq(def.rarity, 3)
	assert_eq(def.dp_cost, 18)
	assert_eq(def.block, 0)
	assert_eq(def.hp, 110)
	assert_eq(def.atk, 0)
	assert_eq(def.atk_interval_ticks, 45)
	assert_eq(def.splash_dim, 0)
	assert_eq(int(def.placement), int(OperatorDef.Placement.ELEVATED))
	assert_eq(def.skill.id, &"mend")
	assert_eq(def.skill.sp_cost, 10)
	assert_eq(def.skill.duration_ticks, 0)
	assert_eq(int(def.skill.effect), 6)
	assert_eq(def.skill.params, {"amount": 60, "range_cells": 2})
	assert_ne(def.id, &"caster_2", "Witch Doctor never aliases Sorcerer")


func test_sp_is_full_at_exactly_deploy_plus_300_ticks() -> void:
	var model := _pair_model()
	var healer := model.units[1]
	model.step(299)
	assert_eq(healer.sp, 9, "one SP short at tick 299")
	assert_eq(healer.sp_progress, 29)
	model.step()
	assert_eq(model.tick, 300)
	assert_eq(healer.sp, 10, "full at exactly 10 x 30 alive ticks")
	assert_eq(healer.sp_progress, 0)


func test_mend_heals_exact_amount_clamps_and_records_target() -> void:
	var model := _ready_pair()
	var before := model.state_hash()
	assert_true(model.apply_action([&"mend", 1, 0]))
	assert_ne(model.state_hash(), before)
	assert_eq(model.units[0].hp, 100, "40 + 60")
	assert_eq(model.units[1].sp, 0)
	assert_eq(model.units[1].skill_triggered_tick, 0)
	assert_eq(model.units[1].skill_target_unit_id, 0)
	assert_eq(model.skills_fired, 1)

	model = _ready_pair()
	model.units[0].hp = 170
	assert_true(model.apply_action([&"mend", 1, 0]))
	assert_eq(model.units[0].hp, 200, "Mend clamps to target max HP")


func test_mend_rejects_invalid_targets_and_never_revives() -> void:
	var model := _ready_pair()
	_assert_rejected(model, [&"trigger_skill", 1], "untargeted healer trigger")
	_assert_rejected(model, [&"mend", 1, 1], "self target")
	_assert_rejected(model, [&"mend", 1, 99], "unknown target")
	_assert_rejected(model, [&"mend", 99, 0], "unknown healer")

	model = _ready_pair()
	model.units[0].hp = model.units[0].hp_max
	_assert_rejected(model, [&"mend", 1, 0], "full HP target")

	model = _ready_pair(&"defender_1", Vector2i(5, 2), Vector2i(2, 1))
	_assert_rejected(model, [&"mend", 1, 0], "out-of-range target")

	model = _ready_pair()
	model.units[1].sp -= 1
	_assert_rejected(model, [&"mend", 1, 0], "uncharged healer")

	model = _ready_pair()
	model.units[1].skill_effect = int(SkillDef.Effect.ATK_MULT)
	_assert_rejected(model, [&"mend", 1, 0], "wrong skill effect")

	model = _ready_pair()
	model.units[0].alive = false
	model.units[0].hp = 0
	_assert_rejected(model, [&"mend", 1, 0], "dead target")
	assert_false(model.units[0].alive, "Mend cannot revive")
	assert_eq(model.units[0].hp, 0)

	model = _ready_pair()
	assert_true(model.apply_action([&"retreat", 0]))
	model.units[1].sp = model.units[1].sp_cost
	_assert_rejected(model, [&"mend", 1, 0], "retreated target")

	model = _ready_pair()
	model.result = BattleModel.Result.DEFEAT
	_assert_rejected(model, [&"mend", 1, 0], "terminal battle")


func test_mend_malformed_actions_fail_closed_without_integer_coercion() -> void:
	var cases: Array[Dictionary] = [
		{"label": "String verb", "action": ["mend", 1, 0]},
		{"label": "integer verb", "action": [1, 1, 0]},
		{"label": "bool verb", "action": [true, 1, 0]},
		{"label": "null verb", "action": [null, 1, 0]},
		{"label": "missing target", "action": [&"mend", 1]},
		{"label": "extra arg", "action": [&"mend", 1, 0, 0]},
		{"label": "string healer", "action": [&"mend", "1", 0]},
		{"label": "float healer", "action": [&"mend", 1.0, 0]},
		{"label": "bool healer", "action": [&"mend", true, 0]},
		{"label": "null healer", "action": [&"mend", null, 0]},
		{"label": "negative healer", "action": [&"mend", -1, 0]},
		{"label": "overflow healer", "action": [&"mend", I32_MAX + 1, 0]},
		{"label": "string target", "action": [&"mend", 1, "0"]},
		{"label": "float target", "action": [&"mend", 1, 0.0]},
		{"label": "bool target", "action": [&"mend", 1, false]},
		{"label": "null target", "action": [&"mend", 1, null]},
		{"label": "negative target", "action": [&"mend", 1, -1]},
		{"label": "overflow target", "action": [&"mend", 1, I32_MAX + 1]},
	]
	for case: Dictionary in cases:
		_assert_rejected(_ready_pair(), case["action"], case["label"])


func test_three_mends_create_exact_clear_vs_defeat_differential() -> void:
	var with_mend := _run_differential(true)
	assert_eq(with_mend["verdicts"], [true, true, true], "all three Mends accept")
	assert_eq(with_mend["hp_rows"], [[142, 202], [58, 118], [22, 82]])
	assert_eq(with_mend["result"], BattleModel.Result.CLEAR)
	assert_eq(with_mend["terminal_tick"], 1762)
	assert_eq(with_mend["killed"], 2)
	assert_eq(with_mend["leaked"], 0)
	assert_eq(with_mend["final_hp"], 10)
	assert_eq(with_mend["death_tick"], -1)

	var without := _run_differential(false)
	assert_eq(without["result"], BattleModel.Result.DEFEAT)
	assert_eq(without["death_tick"], 1161)
	assert_eq(without["terminal_tick"], 1402)
	assert_eq(without["killed"], 0)
	assert_eq(without["leaked"], 1, "stagger desynchronizes same-terminal-tick leaks")
	assert_eq(without["hp_at_900"], 142)
	assert_true(with_mend["alive_at_1162"])
	assert_false(without["alive_at_1162"])


func _run_differential(with_mend: bool) -> Dictionary:
	var target := load("res://data/operators/defender_2.tres") as OperatorDef
	var healer := _healer_def()
	var ops := {&"defender_2": target, HEALER_ID: healer}
	var squad: Array[StringName] = [&"defender_2", HEALER_ID]
	var model := (
		BattleModel
		. create(
			load(STAGE_SKILL) as StageDef,
			squad,
			42,
			_config(),
			_enemy_defs(),
			ops,
		)
	)
	assert_true(model.apply_action([&"debug_set_dp", 99]))
	assert_true(model.apply_action([&"deploy", &"defender_2", Vector2i(4, 2), RIGHT]))
	assert_true(model.apply_action([&"deploy", HEALER_ID, Vector2i(2, 1), RIGHT]))
	var heal_ticks: Array[int] = [900, 1200, 1500]
	var verdicts: Array[bool] = []
	var hp_rows: Array[Array] = []
	var death_tick := -1
	var hp_at_900 := -1
	var alive_at_1162 := false
	while model.result == BattleModel.Result.RUNNING and model.tick < 3000:
		if model.tick == 900:
			hp_at_900 = model.units[0].hp
		if with_mend and heal_ticks.has(model.tick):
			var before := model.units[0].hp
			verdicts.append(model.apply_action([&"mend", 1, 0]))
			hp_rows.append([before, model.units[0].hp])
		var was_alive := model.units[0].alive
		model.step()
		if was_alive and not model.units[0].alive:
			death_tick = model.tick - 1
		if model.tick == 1162:
			alive_at_1162 = model.units[0].alive
	return {
		"verdicts": verdicts,
		"hp_rows": hp_rows,
		"result": model.result,
		"terminal_tick": model.tick,
		"killed": model.killed,
		"leaked": model.leaked,
		"final_hp": model.units[0].hp,
		"death_tick": death_tick,
		"hp_at_900": hp_at_900,
		"alive_at_1162": alive_at_1162,
	}


func test_mend_replay_round_trip_is_canonical_and_targeted() -> void:
	var context := _replay_context()
	var squad: Array[StringName] = [&"defender_1", HEALER_ID]
	var timeline: Array = [
		[180, &"deploy", &"defender_1", Vector2i(4, 2), RIGHT],
		[720, &"deploy", HEALER_ID, Vector2i(2, 1), RIGHT],
		[1020, &"mend", 1, 0],
	]
	var encoded := ReplayCodec.encode_document(&"test_skill", squad, 42, timeline, context)
	assert_true(encoded["accepted"])
	assert_string_contains(
		encoded["text"],
		'"tick":1020,"verb":"mend","args":{"healer_unit_id":1,"target_unit_id":0}',
	)
	var decoded := ReplayCodec.decode_document(encoded["value"], context)
	assert_true(decoded["accepted"])
	assert_eq(decoded["timeline"], timeline)


func test_mend_replay_codec_rejects_malformed_and_out_of_range_ids() -> void:
	var context := _replay_context()
	var cases: Array[Dictionary] = [
		{},
		{"healer_unit_id": 1},
		{"healer_unit_id": 1, "target_unit_id": 0, "extra": 0},
		{"healer_unit_id": "1", "target_unit_id": 0},
		{"healer_unit_id": 1, "target_unit_id": 0.0},
		{"healer_unit_id": -1, "target_unit_id": 0},
		{"healer_unit_id": 1, "target_unit_id": I32_MAX + 1},
	]
	for args: Dictionary in cases:
		var source := _replay_fixture("s1")
		source["actions"][0] = {"tick": 6, "verb": "mend", "args": args}
		var decoded := ReplayCodec.decode_document(source, context)
		assert_false(decoded["accepted"], JSON.stringify(args))
		assert_false(decoded.has("timeline"), "rejection exposes no partial timeline")


func test_p16_union_environment_binds_witch_doctor_catalog_and_s7_reward() -> void:
	var definition := load("res://data/campaigns/p16_v2.tres") as CampaignDef
	assert_eq(
		definition.environment_sha256,
		"766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5",
	)
	var catalogs := _p16_catalog_ids()
	var stages := _p16_stages()
	var without_template: Dictionary = catalogs.duplicate(true)
	without_template["operators"].erase(&"witch_doctor_1")
	var missing_template := (
		CampaignState
		. create(
			42,
			1,
			definition,
			without_template,
			stages,
		)
	)
	assert_false(missing_template["accepted"])
	assert_eq(missing_template["error_code"], &"invalid_stage_reward")

	var without_reward: Array = stages.duplicate()
	var s7 := (without_reward[6] as StageDef).duplicate(true) as StageDef
	s7.rewards = []
	without_reward[6] = s7
	var missing_reward := (
		CampaignState
		. create(
			42,
			1,
			definition,
			catalogs,
			without_reward,
		)
	)
	assert_false(missing_reward["accepted"])
	assert_eq(missing_reward["error_code"], &"campaign_environment_mismatch")


func _replay_fixture(stage_id: String) -> Dictionary:
	var loaded := (
		ReplayCodec
		. load_file(
			"res://playtests/replays/v1/%s.json" % stage_id,
			_replay_context(),
		)
	)
	assert_true(loaded["accepted"])
	return (
		ReplayCodec
		. encode_document(
			loaded["stage_id"],
			loaded["squad"],
			loaded["seed"],
			loaded["timeline"],
			_replay_context(),
		)["value"]
	)


func _replay_context() -> Dictionary:
	return (
		ReplayCodec
		. build_context(
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			_catalog("res://data/stages"),
			_config(),
		)
	)


func _catalog(path: String) -> Dictionary:
	var result := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _p16_catalog_ids() -> Dictionary:
	return {
		"operators": _catalog_names("res://data/operators"),
		"traps": _catalog_names("res://data/traps"),
		"spells": _catalog_names("res://data/spells"),
	}


func _catalog_names(path: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(StringName(source.trim_suffix(".tres")))
	return result


func _p16_stages() -> Array:
	var result: Array = []
	for index: int in range(1, 9):
		result.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return result
