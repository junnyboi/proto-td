extends GutTest

const DamageRulesScript := preload("res://sim/damage_rules.gd")
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const BOLT_PATH := "res://data/spells/bolt.tres"
const RIGHT := int(UnitState.Facing.RIGHT)
const PHYSICAL := int(DamageRulesScript.Kind.PHYSICAL)
const ARTS := int(DamageRulesScript.Kind.ARTS)


func test_operator_and_enemy_attacks_use_target_mitigation() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.defense = 12
	var operator := _operator(&"vanguard_1", 20)
	operator.defense = 3
	var model := _model(
		_stage([{"tick": 30, "enemy_id": enemy.id, "path_idx": 0}]),
		{enemy.id: enemy}, {operator.id: operator}, [operator.id],
	)
	assert_true(model.apply_action([&"deploy", operator.id, Vector2i(3, 2), RIGHT]))
	model.step(122)
	assert_eq(model.enemies[0].hp, 92, "20 Physical - 12 DEF = 8")
	assert_eq(model.units[0].hp, operator.hp - 2, "5 Physical - 3 DEF = 2")
	assert_eq(model.units[0].defense, 3)
	assert_eq(model.enemies[0].defense, 12)


func test_enemy_arts_attack_uses_operator_resistance() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.atk = 10
	enemy.attack_damage_kind = ARTS
	var operator := _operator(&"vanguard_1", 0)
	operator.resistance_permille = 500
	var model := _model(
		_stage([{"tick": 30, "enemy_id": enemy.id, "path_idx": 0}]),
		{enemy.id: enemy}, {operator.id: operator}, [operator.id],
	)
	assert_true(model.apply_action([&"deploy", operator.id, Vector2i(3, 2), RIGHT]))
	model.step(122)
	assert_eq(model.units[0].hp, operator.hp - 5, "10 Arts at 500 RES = 5")
	assert_eq(model.enemies[0].attack_damage_kind, ARTS)


func test_caster_primary_and_splash_each_resolve_arts() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.resistance_permille = 500
	var caster := _operator(&"caster_1", 20)
	caster.attack_damage_kind = ARTS
	caster.dp_cost = 0
	var wall := _operator(&"defender_1", 0)
	wall.id = &"mitigation_wall"
	wall.hp = 9999
	wall.dp_cost = 0
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": enemy.id, "path_idx": 0},
		{"tick": 90, "enemy_id": enemy.id, "path_idx": 0},
		{"tick": 150, "enemy_id": enemy.id, "path_idx": 0},
	]
	var model := _model(
		_stage(waves), {enemy.id: enemy},
		{caster.id: caster, wall.id: wall}, [caster.id, wall.id],
	)
	assert_true(model.apply_action([&"deploy", wall.id, Vector2i(4, 2), RIGHT]))
	model.step(450)
	assert_true(model.apply_action([&"deploy", caster.id, Vector2i(2, 1), RIGHT]))
	model.step()
	for index: int in 3:
		assert_eq(model.enemies[index].hp, 90, "splash target %d takes 10 Arts" % index)
	assert_eq(model.units[1].attack_damage_kind, ARTS)


func test_bolt_uses_spell_damage_kind() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.resistance_permille = 500
	var bolt := (load(BOLT_PATH) as SpellDef).duplicate(true) as SpellDef
	bolt.damage = 60
	bolt.damage_kind = ARTS
	var model := _model(
		_stage([{"tick": 0, "enemy_id": enemy.id, "path_idx": 0}]),
		{enemy.id: enemy}, {}, [], {}, {bolt.id: bolt},
	)
	bolt.damage_kind = PHYSICAL
	model.step(100)
	assert_true(model.apply_action([&"cast", bolt.id, Vector2i(3, 2)]))
	assert_eq(model.enemies[0].hp, 70, "60 Arts at 500 RES = 30")


func test_trap_uses_copied_damage_kind() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.defense = 12
	var spike := (
		load("res://data/traps/spike_plate.tres") as TrapDef
	).duplicate(true) as TrapDef
	spike.damage = 20
	spike.damage_kind = PHYSICAL
	spike.dp_cost = 0
	var model := _model(
		_stage([{"tick": 0, "enemy_id": enemy.id, "path_idx": 0}]),
		{enemy.id: enemy}, {}, [], {spike.id: spike},
	)
	assert_true(model.apply_action([&"place_trap", spike.id, Vector2i(4, 2)]))
	model.step(122)
	assert_eq(model.enemies[0].hp, 92, "20 Physical - 12 DEF = 8")
	assert_eq(model.traps[0].damage_kind, PHYSICAL)


func test_charm_duel_resolves_both_attack_directions() -> void:
	var heavy := _enemy(&"heavy", 160)
	heavy.atk = 12
	heavy.attack_damage_kind = ARTS
	heavy.defense = 3
	var grunt := _enemy(&"grunt", 40)
	grunt.atk = 5
	grunt.attack_damage_kind = PHYSICAL
	grunt.resistance_permille = 500
	var charm := load("res://data/spells/charm.tres") as SpellDef
	var waves: Array[Dictionary] = [
		{"tick": 0, "enemy_id": heavy.id, "path_idx": 0},
		{"tick": 60, "enemy_id": grunt.id, "path_idx": 0},
		{"tick": 100000, "enemy_id": grunt.id, "path_idx": 0},
	]
	var model := _model(
		_stage(waves), {heavy.id: heavy, grunt.id: grunt},
		{}, [], {}, {charm.id: charm},
	)
	model.step(100)
	assert_true(model.apply_action([&"cast", charm.id, 0]))
	model.step()
	assert_eq(model.enemies[0].hp, 158, "grunt hits charmed heavy for 5 - 3 DEF")
	assert_eq(model.enemies[1].hp, 34, "charmed heavy hits grunt for 12 at 500 RES")
	assert_eq(model.enemies[0].engaged_with, 1)
	assert_eq(model.enemies[1].engaged_with, 0)


func test_runtime_snapshot_is_primitive_and_reports_copied_fields() -> void:
	var enemy := _enemy(&"grunt", 100)
	enemy.defense = 12
	enemy.resistance_permille = 300
	var operator := _operator(&"vanguard_1", 20)
	operator.resistance_permille = 500
	operator.attack_damage_kind = ARTS
	var bolt := (load(BOLT_PATH) as SpellDef).duplicate(true) as SpellDef
	bolt.damage_kind = ARTS
	var model := _model(
		_stage([{"tick": 0, "enemy_id": enemy.id, "path_idx": 0}]),
		{enemy.id: enemy}, {operator.id: operator}, [operator.id], {}, {bolt.id: bolt},
	)
	bolt.damage_kind = PHYSICAL
	assert_true(model.apply_action([&"deploy", operator.id, Vector2i(3, 2), RIGHT]))
	model.step()
	var snapshot := model.snapshot()
	assert_eq(snapshot["damage_rules_version"], DamageRulesScript.VERSION)
	assert_eq(snapshot["mitigation"]["units"][0]["resistance_permille"], 500)
	assert_eq(snapshot["mitigation"]["units"][0]["attack_damage_kind"], ARTS)
	assert_eq(snapshot["mitigation"]["enemies"][0]["defense"], 12)
	assert_eq(snapshot["mitigation"]["enemies"][0]["resistance_permille"], 300)
	assert_eq(snapshot["mitigation"]["spells"][0]["damage_kind"], ARTS)
	assert_true(BattleObservation.recursive_primitive_only(snapshot))


func _stage(waves: Array[Dictionary]) -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _model(
	stage: StageDef,
	enemies: Dictionary,
	operators: Dictionary,
	squad: Array[StringName],
	traps: Dictionary = {},
	spells: Dictionary = {},
) -> BattleModel:
	return BattleModel.create(
		stage, squad, 42, load(CONFIG_PATH) as GameConfig,
		enemies, operators, traps, spells,
	)


func _enemy(enemy_id: StringName, hp: int) -> EnemyDef:
	var definition := (
		load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
	).duplicate(true) as EnemyDef
	definition.hp = hp
	return definition


func _operator(operator_id: StringName, atk: int) -> OperatorDef:
	var definition := (
		load("res://data/operators/%s.tres" % operator_id) as OperatorDef
	).duplicate(true) as OperatorDef
	definition.atk = atk
	definition.dp_cost = 0
	return definition
