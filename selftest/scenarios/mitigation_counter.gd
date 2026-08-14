extends RefCounted

const DamageRulesScript := preload("res://sim/damage_rules.gd")
const RIGHT := int(UnitState.Facing.RIGHT)
const RAW_ATTACK := 20


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 300
	var physical_armor := _outcome(DamageRulesScript.Kind.PHYSICAL, &"test_high_def")
	var arts_armor := _outcome(DamageRulesScript.Kind.ARTS, &"test_high_def")
	var physical_ward := _outcome(DamageRulesScript.Kind.PHYSICAL, &"test_high_res")
	var arts_ward := _outcome(DamageRulesScript.Kind.ARTS, &"test_high_res")
	h.check(
		"armor exact mitigation",
		physical_armor["damage"] == 8 and arts_armor["damage"] == 20,
		"physical=%s arts=%s" % [physical_armor["damage"], arts_armor["damage"]],
	)
	h.check(
		"ward exact mitigation",
		physical_ward["damage"] == 20 and arts_ward["damage"] == 4,
		"physical=%s arts=%s" % [physical_ward["damage"], arts_ward["damage"]],
	)
	h.check(
		"Arts counters armor",
		arts_armor["damage"] > physical_armor["damage"],
		"Arts %s versus Physical %s" % [arts_armor["damage"], physical_armor["damage"]],
	)
	h.check(
		"Physical counters ward",
		physical_ward["damage"] > arts_ward["damage"],
		"Physical %s versus Arts %s" % [physical_ward["damage"], arts_ward["damage"]],
	)
	var repeated := _outcome(DamageRulesScript.Kind.ARTS, &"test_high_def")
	h.check(
		"mitigation replay is deterministic",
		repeated == arts_armor,
		"first=%s repeated=%s" % [arts_armor["hash"], repeated["hash"]],
	)
	h.check(
		"mitigation snapshot is primitive",
		BattleObservation.recursive_primitive_only(arts_armor["snapshot"]),
		"version=%s" % arts_armor["snapshot"]["damage_rules_version"],
	)
	h.done()


func _outcome(damage_kind: int, enemy_id: StringName) -> Dictionary:
	var stage := (
		load("res://data/stages/test_mitigation.tres") as StageDef
	).duplicate(true) as StageDef
	stage.waves = [{"tick": 0, "enemy_id": enemy_id, "path_idx": 0}]
	var operator := (
		load("res://data/operators/vanguard_1.tres") as OperatorDef
	).duplicate(true) as OperatorDef
	operator.id = &"mitigation_attacker"
	operator.atk = RAW_ATTACK
	operator.attack_damage_kind = damage_kind
	operator.dp_cost = 0
	var enemy := load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
	var model := BattleModel.create(
		stage,
		[operator.id] as Array[StringName],
		42,
		load("res://data/config/game.tres") as GameConfig,
		{enemy.id: enemy},
		{operator.id: operator},
	)
	model.apply_action([&"deploy", operator.id, Vector2i(3, 2), RIGHT])
	model.step(92)
	return {
		"damage": enemy.hp - model.enemies[0].hp,
		"hp": model.enemies[0].hp,
		"hash": HeroIdentity.format_u64_hex(model.state_hash()),
		"snapshot": model.snapshot(),
	}
