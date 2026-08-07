extends GutTest

## Phase 5 gate tests (td-phase-4-5.md §4.2 S1-S8). Pinned SP/effect
## arithmetic, decided on paper first:
## - SP: +1 sp_progress per alive tick while sp < sp_cost; at 30 -> sp += 1.
##   A unit deployed at tick T is full at exactly T + sp_cost * 30; progress
##   freezes at full. Triggering consumes SP to 0 and accrual restarts.
## - Timed effects: expires_tick = trigger_tick + duration_ticks; the sweep
##   runs at the START of the step whose entry tick is expires_tick, so
##   combat sees the effect for exactly duration_ticks ticks (trigger tick
##   inclusive, expiry tick exclusive). The active_effects LIST is therefore
##   observably empty from model.tick == expires_tick + 1 (the getter lens
##   lags the combat semantics by the sweep step).
## - BLOCK_PLUS lapse: release most-recently-blocked first until held weight
##   fits; released enemies advance in the SAME tick's sub-step 2.
## - STUN: stunned_until = trigger_tick + stun_ticks; progress and cadence
##   both freeze for steps trigger_tick..stunned_until-1 (exactly stun_ticks).

const CONFIG_PATH := "res://data/config/game.tres"
const STAGE_LANE := "res://data/stages/test_lane.tres"
const STAGE_SKILL := "res://data/stages/test_skill.tres"
const OP_DIR := "res://data/operators"
const ALL_OP_IDS: Array[StringName] = [
	&"vanguard_1", &"vanguard_2", &"guard_1", &"guard_2", &"defender_1",
	&"defender_2", &"sniper_1", &"sniper_2", &"caster_1", &"caster_2",
]

const RIGHT := int(UnitState.Facing.RIGHT)
const LANE_CELL := Vector2i(3, 2)
const MAX_TICKS := 20_000


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _grunt_defs() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres"),
		&"drone": load("res://data/enemies/drone.tres"),
		&"heavy": load("res://data/enemies/heavy.tres"),
		&"spellcaster": load("res://data/enemies/spellcaster.tres"),
	}


func _stage_with(base_path: String, waves: Array[Dictionary]) -> StageDef:
	var stage := (load(base_path) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


## An enemy-free battle terminates CLEAR on its very first step (timeline
## exhausted + nothing alive), so pure-economy tests pin the battle open
## with one never-reached wave entry.
func _idle_stage() -> StageDef:
	var waves: Array[Dictionary] = [{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}]
	return _stage_with(STAGE_LANE, waves)


## In-test operator carrying a custom skill (A10: tests build defs
## programmatically) — decouples effect mechanics from roster charge times.
func _skilled_op(
	op_id: StringName, effect: int, params: Dictionary, duration: int, sp_cost: int
) -> OperatorDef:
	var def := (load(OP_DIR + "/defender_1.tres") as OperatorDef).duplicate() as OperatorDef
	def.id = op_id
	def.dp_cost = 8
	def.atk = 0
	def.hp = 9999
	var sk := SkillDef.new()
	sk.id = op_id
	sk.sp_cost = sp_cost
	sk.duration_ticks = duration
	sk.effect = effect as SkillDef.Effect
	sk.params = params
	def.skill = sk
	return def


func _make_model(
	stage: StageDef, extra_ops: Array[OperatorDef] = [], config: GameConfig = null
) -> BattleModel:
	var ops: Dictionary = {}
	var squad: Array[StringName] = []
	for op_id: StringName in [&"vanguard_1", &"guard_2", &"sniper_1", &"defender_1"]:
		ops[op_id] = load("%s/%s.tres" % [OP_DIR, op_id])
		squad.append(op_id)
	for def: OperatorDef in extra_ops:
		ops[def.id] = def
		squad.append(def.id)
	var cfg := config if config != null else _config()
	return BattleModel.create(stage, squad, 42, cfg, _grunt_defs(), ops)


func _assert_ledger(model: BattleModel) -> void:
	var expected := (
		model.config.dp_start
		+ model.dp_regen_accrued
		+ model.dp_vanguard_generated
		+ model.dp_refunded
		+ model.dp_skill_granted
		- model.dp_spent
		- model.dp_lost_to_cap
	)
	assert_eq(model.dp, expected, "extended DP ledger exact @ tick %d" % model.tick)


## S1: SP exactness — vanguard_1 (rally, sp_cost 15) deployed at tick 0 is
## full at exactly 450; never exceeds; progress frozen at full.
func test_sp_exactness() -> void:
	var model := _make_model(_idle_stage())
	assert_true(model.apply_action([&"deploy", &"vanguard_1", LANE_CELL, RIGHT]))
	model.step(449)
	var u := model.units[0]
	assert_eq(u.sp, 14, "one point short at tick 449")
	assert_eq(u.sp_progress, 29, "one tick short of the 15th point")
	model.step()
	assert_eq(u.sp, 15, "full at exactly deploy + 15 * 30")
	assert_eq(u.sp_progress, 0)
	model.step(150)
	assert_eq(u.sp, 15, "capped at sp_cost")
	assert_eq(u.sp_progress, 0, "progress frozen while full")


## S2: trigger validation — rejected one tick before full and on dead or
## unknown units (all hash-equal), accepted exactly at full, SP consumed to 0.
func test_trigger_validation() -> void:
	var model := _make_model(_idle_stage())
	assert_true(model.apply_action([&"deploy", &"vanguard_1", LANE_CELL, RIGHT]))
	model.step(449)
	var before := model.state_hash()
	assert_false(model.apply_action([&"trigger_skill", 0]), "rejected one tick before full")
	assert_eq(model.state_hash(), before, "rejection is zero state change")
	model.step()
	var dp_before := model.dp
	assert_true(model.apply_action([&"trigger_skill", 0]), "accepted exactly at full SP")
	assert_eq(model.units[0].sp, 0, "SP consumed to 0")
	assert_eq(model.dp, dp_before + 6, "Rally burst credited instantly")
	assert_eq(model.skills_fired, 1)
	_assert_ledger(model)
	before = model.state_hash()
	assert_false(model.apply_action([&"trigger_skill", 0]), "empty SP rejects")
	assert_false(model.apply_action([&"trigger_skill", 99]), "unknown unit rejects")
	assert_eq(model.state_hash(), before, "both rejections hash-equal")
	assert_true(model.apply_action([&"retreat", 0]))
	before = model.state_hash()
	assert_false(model.apply_action([&"trigger_skill", 0]), "retreated unit rejects")
	assert_eq(model.state_hash(), before)


## S3: effect table over every timed effect — derived stat reflects the
## effect from the trigger tick; combat-active for exactly duration_ticks;
## the effects list is empty again one step after expires_tick. Instants
## (DP_BURST, STUN_IN_RANGE) are covered by S2/S4 and S6.
func test_effect_table_timed() -> void:
	var cases := [
		{
			"effect": SkillDef.Effect.ATK_MULT,
			"params": {"mult": 2.0},
			"probe": func(u: UnitState) -> int: return u.effective_atk(),
			"base": 0,
			"boosted": 0,
		},
		{
			"effect": SkillDef.Effect.ATK_INTERVAL_MULT,
			"params": {"mult": 0.5},
			"probe": func(u: UnitState) -> int: return u.effective_interval(),
			"base": 30,
			"boosted": 15,
		},
		{
			"effect": SkillDef.Effect.BLOCK_PLUS,
			"params": {"amount": 1},
			"probe": func(u: UnitState) -> int: return u.effective_block(),
			"base": 3,
			"boosted": 4,
		},
		{
			"effect": SkillDef.Effect.SPLASH_RADIUS_PLUS,
			"params": {"dim": 5},
			"probe": func(u: UnitState) -> int: return u.splash_dim(),
			"base": 3,
			"boosted": 5,
		},
	]
	for case: Dictionary in cases:
		var op := _skilled_op(
			&"fx_op", int(case["effect"]), case["params"], 150, 5
		)
		var extra: Array[OperatorDef] = [op]
		var model := _make_model(_idle_stage(), extra)
		assert_true(model.apply_action([&"deploy", &"fx_op", LANE_CELL, RIGHT]))
		model.step(150)
		var u := model.units[0]
		var probe: Callable = case["probe"]
		assert_eq(int(probe.call(u)), int(case["base"]), "base before trigger")
		assert_true(model.apply_action([&"trigger_skill", 0]), "trigger at full (150)")
		assert_eq(int(probe.call(u)), int(case["boosted"]), "boosted on the trigger tick")
		model.step(149)
		assert_eq(int(probe.call(u)), int(case["boosted"]), "still boosted at tick 299")
		model.step(2)
		assert_eq(int(probe.call(u)), int(case["base"]), "base restored after expiry sweep")
		assert_eq(u.active_effects.size(), 0, "effect list empty at 301")
		# recharge >= duration: SP refilled at 300 while the effect is already
		# combat-expired -> a re-trigger never stacks (assert at 301)
		assert_eq(u.sp, 5, "SP refilled during the effect's own duration window")
		assert_true(model.apply_action([&"trigger_skill", 0]), "re-trigger accepted at 301")
		assert_eq(u.active_effects.size(), 1, "no stacking: exactly one live effect")


## Roster data property backing the no-stacking argument: every timed skill
## recharges no faster than it expires (sp_cost * 30 >= duration_ticks).
func test_roster_recharge_covers_duration() -> void:
	var interval := _config().sp_progress_interval_ticks
	for op_id: StringName in ALL_OP_IDS:
		var def := load("%s/%s.tres" % [OP_DIR, op_id]) as OperatorDef
		assert_not_null(def.skill, "%s has a skill" % op_id)
		if def.skill.duration_ticks > 0:
			assert_true(
				def.skill.sp_cost * interval >= def.skill.duration_ticks,
				"%s: recharge %d >= duration %d" % [
					op_id, def.skill.sp_cost * interval, def.skill.duration_ticks,
				]
			)


## S4: DP_BURST through the ledger under a pinned cap — the extended
## equation holds at every tick of a burst-heavy, cap-clipped timeline.
func test_dp_burst_ledger_capped() -> void:
	var config := (_config().duplicate() as GameConfig)
	config.dp_cap = 12
	var model := _make_model(_idle_stage(), [], config)
	var actions := [
		[0, &"deploy", &"vanguard_1", LANE_CELL, RIGHT],
		[450, &"trigger_skill", 0],
		[900, &"trigger_skill", 0],
	]
	var idx := 0
	while model.tick < 1200 and model.result == BattleModel.Result.RUNNING:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			assert_true(model.apply_action(entry.slice(1)), "action @ %d accepted" % model.tick)
			idx += 1
		model.step()
		_assert_ledger(model)
	assert_eq(model.skills_fired, 2)
	assert_eq(model.dp_skill_granted, 12, "both bursts accrued gross")
	assert_true(model.dp_lost_to_cap > 0, "cap actually clipped")


## S5: BLOCK_PLUS expiry edge — block 3+1 holds a fourth grunt; when the
## effect lapses at 460 the MOST-RECENTLY-blocked (#3) releases, resumes
## walking the same tick, and leaks at 460 + 120 = 579 (frozen progress
## 3_033_303 + 120 * 33_333 crosses 7M). Grunts #0-#2 stay blocked.
func test_block_plus_expiry_release_order() -> void:
	var waves: Array[Dictionary] = []
	for t: int in [60, 120, 180, 240]:
		waves.append({"tick": t, "enemy_id": &"grunt", "path_idx": 0})
	var op := _skilled_op(&"holdwall", SkillDef.Effect.BLOCK_PLUS, {"amount": 1}, 300, 5)
	var extra: Array[OperatorDef] = [op]
	var model := _make_model(_stage_with(STAGE_LANE, waves), extra)
	assert_true(model.apply_action([&"deploy", &"holdwall", LANE_CELL, RIGHT]))
	model.step(160)
	assert_true(model.apply_action([&"trigger_skill", 0]), "boost at 160 (expires 460)")
	model.step(332 - model.tick)
	assert_eq(
		model.units[0].blocked_ids, [0, 1, 2, 3] as Array[int],
		"all four held under block 3+1"
	)
	model.step(460 - model.tick)
	assert_eq(model.units[0].blocked_ids.size(), 4, "still held at tick 460 (pre-sweep)")
	model.step()
	assert_eq(
		model.units[0].blocked_ids, [0, 1, 2] as Array[int],
		"most-recently-blocked released first"
	)
	assert_eq(model.enemies[3].blocked_by, -1, "#3 free")
	assert_eq(model.enemies[0].blocked_by, 0, "#0 still held")
	model.step(579 - model.tick)
	assert_eq(model.leaked, 0, "not home at entry tick 579")
	model.step()
	assert_eq(model.leaked, 1, "#3 leaks exactly at 579 after same-tick resume")
	for i: int in 3:
		assert_eq(model.enemies[i].blocked_by, 0, "#%d never released" % i)


## S6a: STUN freezes progress for exactly stun_ticks — a grunt stunned at
## 130 (progress 3_299_967) resumes at 220 and leaks at 241 + 90 = 331; the
## aerial drone inside the stun square is untouched (leaks at 205 as ever).
func test_stun_freezes_walkers_not_aerial() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 30, "enemy_id": &"drone", "path_idx": 0},
	]
	var op := _skilled_op(
		&"stunner", SkillDef.Effect.STUN_IN_RANGE, {"dim": 3, "stun_ticks": 90}, 0, 4
	)
	var extra: Array[OperatorDef] = [op]
	var model := _make_model(_stage_with(STAGE_LANE, waves), extra)
	assert_true(model.apply_action([&"deploy", &"stunner", Vector2i(3, 3), RIGHT]))
	model.step(130)
	var grunt := model.enemies[0]
	var drone := model.enemies[1]
	assert_eq(grunt.progress_units, 3_299_967, "99 advances by tick 130")
	assert_true(model.apply_action([&"trigger_skill", 0]))
	assert_eq(grunt.stunned_until_tick, 220, "stunned for 90 ticks")
	assert_eq(drone.stunned_until_tick, 0, "aerial unaffected by the stun field")
	model.step(220 - model.tick)
	assert_eq(grunt.progress_units, 3_299_967, "progress frozen through tick 219")
	model.step()
	assert_eq(grunt.progress_units, 3_333_300, "first resumed advance at 220")
	model.step(206 - model.tick)
	assert_eq(model.leaked, 1, "drone leak at 205 unchanged")
	model.step(332 - model.tick)
	assert_eq(model.leaked, 2, "grunt leak delayed by exactly 90 (331)")


## S6b: STUN freezes attack cadence — a blocked grunt (hits at 121/151)
## stunned at 160 with 21 ticks left on its counter fires next at exactly
## 250 + 21 = 271; the vanguard's own cadence is untouched and kills at 301.
func test_stun_freezes_attack_cadence() -> void:
	var waves: Array[Dictionary] = [{"tick": 30, "enemy_id": &"grunt", "path_idx": 0}]
	var op := _skilled_op(
		&"stunner", SkillDef.Effect.STUN_IN_RANGE, {"dim": 3, "stun_ticks": 90}, 0, 4
	)
	op.dp_cost = 2
	var extra: Array[OperatorDef] = [op]
	var model := _make_model(_stage_with(STAGE_LANE, waves), extra)
	assert_true(model.apply_action([&"deploy", &"vanguard_1", LANE_CELL, RIGHT]))
	assert_true(model.apply_action([&"deploy", &"stunner", Vector2i(3, 3), RIGHT]))
	model.step(160)
	assert_eq(model.units[0].hp, 110, "two grunt hits (121/151) before the stun")
	assert_true(model.apply_action([&"trigger_skill", 1]))
	model.step(271 - model.tick)
	assert_eq(model.units[0].hp, 110, "no hits while stunned or counting back down")
	model.step()
	assert_eq(model.units[0].hp, 105, "frozen counter resumes: next hit exactly at 271")
	model.step(302 - model.tick)
	assert_eq(model.killed, 1, "vanguard cadence untouched: kill on schedule at 301")
	assert_eq(model.units[0].hp, 105, "grunt died before its 301 swing (units strike first)")


## S7 — THE PHASE GATE (skill-timing win/loss pair): on test_skill, guard_2
## (deployed 180 at (4,2), SP full at 780) blocks both heavies (711/756).
## Overpower at 780 -> #0 dies at 891 (boosted), #1 at 1191, guard survives
## on 17 hp -> CLEAR at 1191. The identical timeline with the trigger 300
## late (1080) -> #0 dies unboosted at 1011, the guard falls at 1116, #1
## (hp 100) resumes 3_983_494 units from home and leaks at 1356 -> DEFEAT.
func test_skill_timing_pair() -> void:
	var outcomes := {}
	for trigger_tick: int in [780, 1080]:
		var model := _make_model(load(STAGE_SKILL) as StageDef)
		var actions := [
			[180, &"deploy", &"guard_2", Vector2i(4, 2), RIGHT],
			[trigger_tick, &"trigger_skill", 0],
		]
		var idx := 0
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < actions.size() and int(actions[idx][0]) == model.tick:
				var entry: Array = actions[idx]
				assert_true(
					model.apply_action(entry.slice(1)),
					"action @ %d accepted (trigger %d)" % [model.tick, trigger_tick]
				)
				idx += 1
			model.step()
		outcomes[trigger_tick] = model
	var win: BattleModel = outcomes[780]
	assert_eq(win.result, BattleModel.Result.CLEAR, "Overpower at 780 clears")
	assert_eq(win.tick, 1192, "second heavy dies at 1191")
	assert_eq(win.killed, 2)
	assert_eq(win.leaked, 0)
	assert_true(win.units[0].alive, "guard survives")
	assert_eq(win.units[0].hp, 17, "guard intake 48 + 120 exactly")
	var loss: BattleModel = outcomes[1080]
	assert_eq(loss.result, BattleModel.Result.DEFEAT, "the same trigger 300 late loses")
	assert_eq(loss.tick, 1357, "released heavy leaks at 1356")
	assert_eq(loss.killed, 1, "only the first heavy died")
	assert_eq(loss.leaked, 1)
	assert_false(loss.units[0].alive, "guard fell at 1116")


## S8: determinism oracle on a skill-heavy timeline — the hash now covers
## sp/sp_progress/effects/stun; two cache-bypassed runs stay identical.
func test_determinism_oracle_skill_heavy() -> void:
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"drone", "path_idx": 0},
		{"tick": 300, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 400, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 500, "enemy_id": &"spellcaster", "path_idx": 0},
	]
	var actions := [
		[0, &"deploy", &"vanguard_1", LANE_CELL, RIGHT],
		[450, &"trigger_skill", 0],
		[480, &"deploy", &"sniper_1", Vector2i(2, 1), RIGHT],
		[900, &"trigger_skill", 0],
		[930, &"trigger_skill", 1],
	]
	var runs: Array = []
	for run_i: int in 2:
		var stage := ResourceLoader.load(
			STAGE_LANE, "", ResourceLoader.CACHE_MODE_IGNORE
		).duplicate(true) as StageDef
		stage.waves = waves
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var enemy_defs: Dictionary = {}
		for enemy_id: StringName in [&"grunt", &"drone", &"heavy", &"spellcaster"]:
			enemy_defs[enemy_id] = ResourceLoader.load(
				"res://data/enemies/%s.tres" % enemy_id, "", ResourceLoader.CACHE_MODE_IGNORE
			)
		var ops: Dictionary = {}
		var squad: Array[StringName] = []
		for op_id: StringName in [&"vanguard_1", &"sniper_1"]:
			ops[op_id] = ResourceLoader.load(
				"%s/%s.tres" % [OP_DIR, op_id], "", ResourceLoader.CACHE_MODE_IGNORE
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
				var books := model.alive_count() + model.killed + model.leaked
				assert_eq(model.spawned, books, "conservation @ tick %d" % model.tick)
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		var outcome := [model.result, model.stars, model.killed, model.leaked, model.tick]
		runs.append({"hashes": hashes, "outcome": outcome, "fired": model.skills_fired})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical on a skill-heavy timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")
	assert_true(int(runs[0]["fired"]) >= 2, "skills actually fired")
