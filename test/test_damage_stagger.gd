extends GutTest

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"heavy", "path_idx": 0}


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var definition: Resource = load(dir_path + "/" + file)
			defs[definition.get("id")] = definition
	return defs


func _model(enemy_ids: Array[StringName]) -> BattleModel:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for enemy_id: StringName in enemy_ids:
		waves.append({"tick": 0, "enemy_id": enemy_id, "path_idx": 0})
	waves.append(FAR_WAVE)
	stage.waves = waves
	var squad: Array[StringName] = [&"guard_1"]
	var model := (
		BattleModel
		. create(
			stage,
			squad,
			42,
			load(CONFIG_PATH) as GameConfig,
			_catalog("res://data/enemies"),
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
		)
	)
	model.step()
	return model


func _damage(model: BattleModel, enemy: EnemyState, amount: int) -> void:
	model.call("_damage_enemy", enemy, amount)


func test_config_uses_non_undershooting_nearest_tick_count() -> void:
	var config := load(CONFIG_PATH) as GameConfig
	assert_eq(config.ticks_per_second, 30)
	assert_eq(config.damage_stagger_ticks, 8)
	assert_almost_eq(
		float(config.damage_stagger_ticks) / config.ticks_per_second, 0.2666667, 0.0001
	)


func test_hostile_movement_pauses_eight_ticks_and_attack_counter_does_not() -> void:
	var model := _model([&"heavy"])
	var enemy := model.enemies[0]
	enemy.atk_counter = 5
	var start_tick := model.tick
	var start_progress := enemy.progress_units
	_damage(model, enemy, 1)
	assert_eq(enemy.last_damage_tick, start_tick)
	assert_eq(enemy.damage_stagger_until_tick, start_tick + 8)
	for _i: int in 8:
		model.step()
		assert_eq(enemy.progress_units, start_progress, "movement frozen through T+7")
	assert_eq(model.tick, start_tick + 8)
	assert_eq(enemy.atk_counter, 0, "damage stagger does not change attack cadence")
	model.step()
	assert_gt(enemy.progress_units, start_progress, "movement resumes on entry tick T+8")


func test_charmed_movement_obeys_damage_stagger_but_not_skill_stun() -> void:
	var model := _model([&"heavy"])
	var enemy := model.enemies[0]
	enemy.faction = EnemyState.Faction.CHARMED
	enemy.progress_units = 4 * Pathing.PROGRESS_SCALE
	enemy.stunned_until_tick = model.tick + 100
	var start_progress := enemy.progress_units
	_damage(model, enemy, 1)
	model.step(8)
	assert_eq(enemy.progress_units, start_progress, "charmed movement freezes for hit stagger")
	model.step()
	assert_lt(enemy.progress_units, start_progress, "charmed still ignores operator skill stun")


func test_repeat_damage_extends_from_latest_hit_without_shortening_other_stun() -> void:
	var model := _model([&"heavy"])
	var enemy := model.enemies[0]
	var start_progress := enemy.progress_units
	_damage(model, enemy, 1)
	model.step(4)
	_damage(model, enemy, 1)
	assert_eq(enemy.damage_stagger_until_tick, model.tick + 8)
	enemy.stunned_until_tick = model.tick + 20
	var damage_end := enemy.damage_stagger_until_tick
	model.step(damage_end - model.tick)
	assert_eq(enemy.progress_units, start_progress, "repeat damage extends the movement pause")
	model.step(enemy.stunned_until_tick - model.tick)
	assert_eq(enemy.progress_units, start_progress, "longer skill stun remains effective")
	model.step()
	assert_gt(enemy.progress_units, start_progress)


func test_bolt_stamps_nonlethal_damage_and_changes_hash() -> void:
	var first := _model([&"heavy"])
	var second := _model([&"heavy"])
	var enemy := first.enemies[0]
	enemy.progress_units = 3 * Pathing.PROGRESS_SCALE
	second.enemies[0].progress_units = enemy.progress_units
	assert_eq(first.state_hash(), second.state_hash())
	var cell := Pathing.cell_of(first.path_for(enemy.path_idx), enemy.progress_units)
	assert_true(first.apply_action([&"cast", &"bolt", cell]))
	assert_eq(enemy.hp, 100)
	assert_eq(enemy.last_damage_tick, first.tick)
	assert_eq(enemy.damage_stagger_until_tick, first.tick + 8)
	assert_ne(first.state_hash(), second.state_hash(), "damage event and stagger are hash-visible")


func test_both_duel_damage_directions_stamp_records() -> void:
	var model := _model([&"grunt", &"heavy"])
	var ally := model.enemies[0]
	var foe := model.enemies[1]
	ally.faction = EnemyState.Faction.CHARMED
	ally.engaged_with = foe.id
	foe.engaged_with = ally.id
	ally.atk_counter = 0
	foe.atk_counter = 0
	model.call("_tick_combat")
	assert_eq(foe.last_damage_tick, model.tick, "charmed-on-hostile damage recorded")
	assert_eq(ally.last_damage_tick, model.tick, "hostile-on-charmed damage recorded")
	assert_eq(foe.damage_stagger_until_tick, model.tick + 8)
	assert_eq(ally.damage_stagger_until_tick, model.tick + 8)


func test_every_enemy_hp_write_is_owned_by_the_damage_seam() -> void:
	var battle_source := FileAccess.get_file_as_string("res://sim/battle_model.gd")
	var seam_source := FileAccess.get_file_as_string("res://sim/enemy_damage.gd")
	assert_eq(battle_source.count("_damage_enemy("), 7, "six callers plus the wrapper")
	for bypass: String in [
		"v.hp -=",
		"e.hp -= damage",
		"e.hp -= trap.damage",
		"foe.hp -=",
		"ally.hp -=",
		"target.hp -=",
	]:
		assert_false(battle_source.contains(bypass), "EnemyState bypass: %s" % bypass)
	assert_eq(seam_source.count("enemy.hp -= damage"), 1, "one authoritative HP mutation")


func test_damage_timeline_is_deterministic() -> void:
	var traces: Array = []
	for _run: int in 2:
		var model := _model([&"heavy"])
		var enemy := model.enemies[0]
		enemy.progress_units = 3 * Pathing.PROGRESS_SCALE
		var cell := Pathing.cell_of(model.path_for(enemy.path_idx), enemy.progress_units)
		assert_true(model.apply_action([&"cast", &"bolt", cell]))
		var trace: Array[int] = []
		for _i: int in 20:
			model.step()
			trace.append(model.state_hash())
		traces.append(trace)
	assert_eq(traces[0], traces[1])
