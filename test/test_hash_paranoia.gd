extends GutTest

## P14 paranoia table: EVERY hashed mutable field group flips the hash
## (ban-list rule enforcement — battle_hash.gd's field order is append-only
## and this table must grow with it). One mutation per row against a live
## fixture that has units, enemies, traps, spells, active effects and
## blocked ids; each mutation must change BattleHash.of(). Mutations are
## cumulative — each row asserts against the previous row's hash.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			defs[def.get("id")] = def
	return defs


## Fixture: one deployed unit (with an active effect + a blocked id pushed
## directly — this suite tests the HASH over state shapes, not gameplay),
## one live enemy, one placed trap, spells in the book.
func _fixture() -> BattleModel:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [
		{"tick": 5, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0},
	]
	stage.waves = waves
	var squad: Array[StringName] = [&"vanguard_1"]
	var m := BattleModel.create(
		stage, squad, 42, load(CONFIG_PATH) as GameConfig,
		{&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef},
		_catalog("res://data/operators"), _catalog("res://data/traps"),
		_catalog("res://data/spells"),
	)
	assert_true(m.apply_action([&"debug_set_dp", 99]))
	assert_true(
		m.apply_action([&"deploy", &"vanguard_1", Vector2i(3, 2), int(UnitState.Facing.RIGHT)])
	)
	assert_true(m.apply_action([&"place_trap", &"spike_plate", Vector2i(4, 2)]))
	m.step(10)
	assert_true(m.enemies.size() >= 1, "fixture needs a spawned enemy")
	var u: UnitState = m.units[0]
	u.active_effects.append(
		{"effect": SkillDef.Effect.ATK_MULT, "expires_tick": 500, "params": {"mult": 1.5}}
	)
	u.blocked_ids.append(7)
	return m


func test_every_hashed_field_group_flips_the_hash() -> void:
	var m := _fixture()
	var cases: Dictionary = {
		"tick": func() -> void: m.tick += 1,
		"base_hp": func() -> void: m.base_hp -= 1,
		"result": func() -> void: m.result = BattleModel.Result.CLEAR,
		"stars": func() -> void: m.stars += 1,
		"spawned": func() -> void: m.spawned += 1,
		"leaked": func() -> void: m.leaked += 1,
		"killed": func() -> void: m.killed += 1,
		"timeline.next_index": func() -> void: m.timeline.next_index += 1,
		"dp": func() -> void: m.dp += 1,
		"dp_regen_counter": func() -> void: m.dp_regen_counter += 1,
		"dp_regen_accrued": func() -> void: m.dp_regen_accrued += 1,
		"dp_vanguard_generated": func() -> void: m.dp_vanguard_generated += 1,
		"dp_refunded": func() -> void: m.dp_refunded += 1,
		"dp_spent": func() -> void: m.dp_spent += 1,
		"dp_lost_to_cap": func() -> void: m.dp_lost_to_cap += 1,
		"dp_skill_granted": func() -> void: m.dp_skill_granted += 1,
		"retreated": func() -> void: m.retreated += 1,
		"skills_fired": func() -> void: m.skills_fired += 1,
		"unit.cell": func() -> void: m.units[0].cell.x += 1,
		"unit.facing": func() -> void: m.units[0].facing = UnitState.Facing.DOWN,
		"unit.hp": func() -> void: m.units[0].hp -= 1,
		"unit.alive": func() -> void: m.units[0].alive = not m.units[0].alive,
		"unit.atk_counter": func() -> void: m.units[0].atk_counter += 1,
		"unit.dp_generation_counter": func() -> void: m.units[0].dp_generation_counter += 1,
		"unit.last_attack_tick": func() -> void: m.units[0].last_attack_tick += 1,
		"unit.last_attack_cell": func() -> void: m.units[0].last_attack_cell.x += 1,
		"unit.sp": func() -> void: m.units[0].sp += 1,
		"unit.sp_progress": func() -> void: m.units[0].sp_progress += 1,
		"unit.skill_triggered_tick": func() -> void: m.units[0].skill_triggered_tick += 1,
		"unit.active_effects.size": func() -> void: _push_second_effect(m),
		"unit.effect.expires_tick": func() -> void: _bump_effect_expiry(m),
		"unit.effect.float_param_x1000": func() -> void: _nudge_effect_float(m),
		"unit.blocked_ids": func() -> void: m.units[0].blocked_ids.append(9),
		"enemy.path_idx": func() -> void: m.enemies[0].path_idx += 1,
		"enemy.progress_units": func() -> void: m.enemies[0].progress_units += 1,
		"enemy.hp": func() -> void: m.enemies[0].hp -= 1,
		"enemy.atk_counter": func() -> void: m.enemies[0].atk_counter += 1,
		"enemy.blocked_by": func() -> void: m.enemies[0].blocked_by += 1,
		"enemy.stunned_until_tick": func() -> void: m.enemies[0].stunned_until_tick += 1,
		"enemy.alive": func() -> void: m.enemies[0].alive = not m.enemies[0].alive,
		"enemy.faction": func() -> void: m.enemies[0].faction = EnemyState.Faction.CHARMED,
		"enemy.engaged_with": func() -> void: m.enemies[0].engaged_with += 1,
		"enemy.died_at_tick": func() -> void: m.enemies[0].died_at_tick += 2,
		"traps_triggered": func() -> void: m.traps_triggered += 1,
		"_next_trap_id": func() -> void: m._next_trap_id += 1,
		"trap.cell": func() -> void: m.traps[0].cell.x += 1,
		"trap.charges_left": func() -> void: m.traps[0].charges_left -= 1,
		"trap.last_trigger_tick": func() -> void: m.traps[0].last_trigger_tick += 2,
		"charmed": func() -> void: m.charmed += 1,
		"charmed_dead": func() -> void: m.charmed_dead += 1,
		"charmed_exited": func() -> void: m.charmed_exited += 1,
		"spell.ready_at": func() -> void: m.spell_book._ready_at[m.spell_book.ids[0]] = 123,
		"spell.used_in_wave": func() -> void: m.spell_book._used_in_wave[m.spell_book.ids[0]] = 3,
		"spell.casts": func() -> void: m.spell_book._casts[m.spell_book.ids[0]] += 1,
		"dp_debug_adjusted": func() -> void: m.dp_debug_adjusted += 1,
		"squad": func() -> void: m.squad.append(&"guard_1"),
		"last_cell_spell_id": func() -> void: m.last_cell_spell_id = &"bolt",
		"last_cell_spell_target": func() -> void: m.last_cell_spell_target.x += 1,
	}
	var prev := BattleHash.of(m)
	for case_name: String in cases:
		(cases[case_name] as Callable).call()
		var now := BattleHash.of(m)
		assert_ne(now, prev, "hashed group must flip the hash: %s" % case_name)
		prev = now


func _push_second_effect(m: BattleModel) -> void:
	var fx := {
		"effect": SkillDef.Effect.BLOCK_PLUS, "expires_tick": 400, "params": {"amount": 1}
	}
	m.units[0].active_effects.append(fx)


func _bump_effect_expiry(m: BattleModel) -> void:
	m.units[0].active_effects[0]["expires_tick"] = 501


func _nudge_effect_float(m: BattleModel) -> void:
	# exercises the x1000 quantization channel: 1.5 -> 1.501 must flip
	(m.units[0].active_effects[0]["params"] as Dictionary)["mult"] = 1.501
