extends GutTest

## Phase 7 Charm machine gate tests (td-phase-6-7.md §4.6, model-level).
## Shared paper derivations (written BEFORE the tests, per §4.9):
##   A grunt spawned at s has advanced (T - 1 - s) steps of 33_333 when an
##   action fires at tick T; a heavy the same with 16_666. Conversion at
##   tick T starts reversing during step T itself (the action precedes the
##   step, T1/T12), so an unengaged ally at progress P despawns during step
##   T + ceil(P / step) - 1, observable one tick later.
##   Duels engage during the step in which both first share a cell (after
##   the advance pass) and both cadences fire that same step under
##   ready-at-contact; allies strike between units and enemies, so a
##   partner killed on the ally's ready tick never lands its own hit.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const SPIKE_PATH := "res://data/traps/spike_plate.tres"
const TAR_PATH := "res://data/traps/tar_pit.tres"
const RIGHT := UnitState.Facing.RIGHT
const MAX_TICKS := 20_000
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage() -> StageDef:
	return load(STAGE_PATH) as StageDef


func _stage_with_waves(entries: Array[Dictionary]) -> StageDef:
	var stage := _stage().duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for entry: Dictionary in entries:
		waves.append(entry)
	stage.waves = waves
	return stage


func _spell_catalog() -> Dictionary:
	return {
		&"bolt": load("res://data/spells/bolt.tres") as SpellDef,
		&"charm": load("res://data/spells/charm.tres") as SpellDef,
	}


func _enemy_catalog() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"runner": load("res://data/enemies/runner.tres") as EnemyDef,
		&"heavy": load("res://data/enemies/heavy.tres") as EnemyDef,
	}


func _op_catalog() -> Dictionary:
	return {
		&"vanguard_1": load("res://data/operators/vanguard_1.tres") as OperatorDef,
		&"defender_1": load("res://data/operators/defender_1.tres") as OperatorDef,
		&"sniper_1": load("res://data/operators/sniper_1.tres") as OperatorDef,
	}


func _make_model(stage: StageDef, extra_traps: Dictionary = {}) -> BattleModel:
	var squad: Array[StringName] = [&"vanguard_1", &"defender_1", &"sniper_1"]
	return BattleModel.create(
		stage, squad, 42, _config(), _enemy_catalog(), _op_catalog(), extra_traps, _spell_catalog()
	)


func _assert_books(model: BattleModel) -> void:
	assert_eq(
		model.spawned,
		model.alive_enemy_count() + model.killed + model.leaked + model.charmed,
		"enemy books @ %d" % model.tick
	)
	assert_eq(
		model.charmed,
		model.alive_charmed_count() + model.charmed_dead + model.charmed_exited,
		"charm books @ %d" % model.tick
	)


## §4.6.1: conversion keeps current (damaged) HP and stats, releases the
## blocker, and the freed capacity blocks a later arrival (load-bearing:
## without the release the vanguard would be at full block and the runner
## would walk past).
## Derivation: vanguard (atk 6/30, block 2) at path cell 2. h0 (spawn 0)
## blocks at step 121 (P frozen 2_016_586) and eats hits at 121/151/181 ->
## hp 142 at the charm tick 200. g0 (spawn 90) blocks at step 151. After
## the charm the vanguard retargets g0 (first hit 211 -> hp 34 at 212). The
## reversing h0 exits at step 200 + 121 - 1 = 320, so a runner spawned at
## 330 (reaches cell 2 at step 361) never meets it and gets blocked.
func test_conversion_releases_blocker() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 330, "enemy_id": &"runner", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	assert_true(model.apply_action([&"deploy", &"vanguard_1", Vector2i(2, 2), int(RIGHT)]))
	model.step(200)
	var vg := model.units[0]
	var h0 := model.enemies[0]
	assert_eq(h0.blocked_by, vg.id, "heavy is mid-block at 200")
	assert_eq(h0.hp, 142, "three vanguard hits landed pre-charm")
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	assert_eq(h0.faction, EnemyState.Faction.CHARMED)
	assert_eq(h0.hp, 142, "converted at current HP")
	assert_eq(h0.atk, 12, "stats kept")
	assert_eq(h0.step_units, 16_666, "speed kept")
	assert_eq(h0.blocked_by, -1, "released from the blocker")
	assert_false(vg.blocked_ids.has(0), "blocker forgot the charmed heavy")
	assert_eq(model.charmed, 1)
	model.step(12)
	assert_eq(model.enemies[1].hp, 34, "vanguard retargeted the grunt at 211")
	model.step(362 - model.tick)
	assert_eq(model.enemies[2].blocked_by, vg.id, "freed capacity blocked the runner at 361")
	_assert_books(model)


## §4.6.2: reversal exactness — an unengaged charmed grunt at P = 99 steps
## of 33_333 = 3_299_967 despawns during step 130 + 99 - 1 = 228 (alive in
## the 228 before-state, charmed_exited observable at 229); never a leak.
func test_reversal_exactness() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	model.step(130)
	assert_eq(model.enemies[0].progress_units, 3_299_967, "P at the cast tick")
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step(228 - model.tick)
	assert_true(model.enemies[0].alive, "before-state of the despawn step")
	assert_eq(model.enemies[0].progress_units, 33_333, "one step from the spawn edge")
	model.step()
	assert_false(model.enemies[0].alive)
	assert_eq(model.charmed_exited, 1, "despawn lands exactly at cast + ceil(P/step)")
	assert_eq(model.leaked, 0, "a charmed exit is never a leak")
	assert_eq(model.base_hp, 10)
	assert_eq(model.killed, 0)
	_assert_books(model)


## §4.6.3: the duel, both directions.
## Derivation A (ally wins): heavy (spawn 0) charmed at 100 reverses to
## 1_633_268 (cell 1); grunt (spawn 60) is at 1_333_320 (cell 1) the same
## step -> engage at 100, both frozen. Ally 12/45 fires 100/145/190/235;
## grunt 5/30 fires 100/130/160/190/220. Grunt hp 40 dies during step 235
## (its 250 hit never lands); ally hp = 160 - 5*5 = 135, resumes, and exits
## ceil(1_633_268 / 16_666) = 98 steps later, during step 236 + 98 - 1 =
## 333.
## Derivation B (ally dies): grunt (spawn 0) charmed at 100 reverses from
## 3_299_967; heavy (spawn 60) walks. The ally enters cell 1 after
## ceil(1_299_967 / 33_333) = 39 reversal steps -> during step 138 (ally
## 1_999_980, heavy 1_299_948) -> engage during step 138. Ally 5/30 fires
## 138..258 (5 hits, 25 damage); heavy 12/45 fires 138/183/228/273 -> ally
## dies during step 273 (its 288 hit never lands). The heavy resumes from
## 1_299_948 and leaks ceil(5_700_052 / 16_666) = 343 steps later, during
## step 274 + 343 - 1 = 616.
func test_duel_both_outcomes() -> void:
	var win_waves: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(win_waves))
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step()
	var ally := model.enemies[0]
	var grunt := model.enemies[1]
	assert_eq(ally.engaged_with, 1, "duel engaged during the cast step")
	assert_eq(grunt.engaged_with, 0)
	var p_ally := ally.progress_units
	var p_grunt := grunt.progress_units
	model.step(2)
	assert_eq(ally.progress_units, p_ally, "both frozen mid-duel")
	assert_eq(grunt.progress_units, p_grunt, "both frozen mid-duel")
	model.step(235 - model.tick)
	assert_true(grunt.alive, "before-state of the kill step")
	assert_eq(grunt.hp, 4, "three ally hits landed")
	model.step()
	assert_false(grunt.alive)
	assert_eq(model.killed, 1, "duel kills route through killed")
	assert_eq(ally.engaged_with, -1, "winner disengages the same tick")
	assert_eq(ally.hp, 135, "five grunt hits landed")
	model.step(333 - model.tick)
	assert_true(ally.alive)
	model.step()
	assert_eq(model.charmed_exited, 1, "winner resumes and exits on schedule")
	_assert_books(model)

	var loss_waves: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"heavy", "path_idx": 0},
		FAR_WAVE,
	]
	var loss := _make_model(_stage_with_waves(loss_waves))
	loss.step(100)
	assert_true(loss.apply_action([&"cast", &"charm", 0]))
	loss.step(138 - loss.tick)
	assert_eq(loss.enemies[0].engaged_with, -1, "not yet met at 138's before-state")
	loss.step()
	assert_eq(loss.enemies[0].engaged_with, 1, "engaged during step 138")
	loss.step(273 - loss.tick)
	assert_true(loss.enemies[0].alive, "ally alive in the 273 before-state")
	loss.step()
	assert_false(loss.enemies[0].alive)
	assert_eq(loss.charmed_dead, 1, "ally death is charmed_dead, not killed")
	assert_eq(loss.killed, 0)
	assert_eq(loss.enemies[1].engaged_with, -1, "survivor freed the same tick")
	assert_eq(loss.enemies[1].hp, 135, "five ally hits landed before dying")
	loss.step(616 - loss.tick)
	assert_eq(loss.leaked, 0, "before-state of the leak step")
	loss.step()
	assert_eq(loss.leaked, 1, "freed heavy resumes toward the base and leaks on schedule")
	assert_eq(loss.base_hp, 9)
	_assert_books(loss)


## §4.6.4a: a third-party kill of the duel partner (Bolt on the shared
## cell) frees the ally the same tick and never harms it (M5), and the
## ally resumes reversing.
func test_duel_third_party_kill_disengages() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step(150 - model.tick)
	var ally := model.enemies[0]
	var grunt := model.enemies[1]
	assert_eq(ally.engaged_with, 1)
	var ally_hp := ally.hp
	assert_true(model.apply_action([&"cast", &"bolt", Vector2i(1, 2)]), "bolt the duel cell")
	assert_false(grunt.alive, "partner died to the bolt")
	assert_eq(model.killed, 1)
	assert_eq(ally.engaged_with, -1, "survivor disengaged at the kill")
	assert_eq(ally.hp, ally_hp, "the burst never touches the CHARMED ally on the same cell")
	var p := ally.progress_units
	model.step()
	assert_lt(ally.progress_units, p, "ally resumed reversing the next step")
	_assert_books(model)


## §4.6.4b/c: engagement picks the lowest-id enemy sharing the cell; the
## other enemy walks past the ongoing duel unblocked and unengaged.
func test_duel_lowest_id_and_walk_past() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 61, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step()
	assert_eq(model.enemies[0].engaged_with, 1, "lowest id sharing the cell is engaged")
	assert_eq(model.enemies[2].engaged_with, -1, "the twin is not")
	var p := model.enemies[2].progress_units
	model.step(5)
	assert_eq(model.enemies[2].engaged_with, -1, "still unengaged mid-duel")
	assert_eq(model.enemies[2].blocked_by, -1, "and unblocked")
	assert_gt(model.enemies[2].progress_units, p, "walks past the ongoing duel")
	_assert_books(model)


## §4.6.4d: an engaged enemy is excluded from block assignment (it never
## advances, so it can never be block-assigned) but stays a valid ranged
## target — the sniper damages it while the CHARMED ally is untargetable.
## Derivation: duel engages at 100 on cell (1,2); the sniper deployed at
## 110 on the ELEVATED (2,1) covers (1,2) via the facing-LEFT rotation of
## offset (1,-1) and fires the same step (ready-at-contact): grunt hp
## 40 - 12 (ally @100) - 10 (sniper @110) = 18 observable at 111.
func test_engaged_enemy_sniper_target_not_blocked() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step(110 - model.tick)
	var ally := model.enemies[0]
	var grunt := model.enemies[1]
	var ally_hp := ally.hp
	assert_true(
		model.apply_action([&"deploy", &"sniper_1", Vector2i(2, 1), int(UnitState.Facing.LEFT)])
	)
	model.step()
	assert_eq(grunt.hp, 18, "sniper hit the engaged enemy on its ready tick")
	assert_eq(grunt.engaged_with, 0, "still engaged")
	assert_eq(grunt.blocked_by, -1, "never block-assigned mid-duel")
	assert_eq(ally.hp, ally_hp, "the CHARMED ally is not a ranged candidate (M5)")
	model.step(60)
	assert_false(grunt.alive, "duel + sniper finished it")
	assert_eq(ally.engaged_with, -1)
	_assert_books(model)


## §4.6.4e: charming an enemy that is dueling another ally dissolves that
## duel — the target converts at its current (damaged) HP, both allies
## walk, nobody dies.
func test_charm_dissolves_ongoing_duel() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var stage := _stage_with_waves(entries)
	stage.wave_starts = PackedInt32Array([0, 130])
	var model := _make_model(stage)
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step(140 - model.tick)
	var h0 := model.enemies[0]
	var g0 := model.enemies[1]
	assert_eq(h0.engaged_with, 1, "duel running at 140")
	assert_eq(g0.hp, 28, "one ally hit so far")
	assert_true(model.apply_action([&"cast", &"charm", 1]), "wave-1 charm on the dueling enemy")
	assert_eq(g0.faction, EnemyState.Faction.CHARMED)
	assert_eq(g0.hp, 28, "converted at current HP")
	assert_eq(h0.engaged_with, -1, "the duel dissolved")
	assert_eq(g0.engaged_with, -1)
	assert_eq(model.charmed, 2)
	model.step(300 - model.tick)
	assert_eq(model.charmed_exited, 2, "both allies walked out")
	assert_eq(model.charmed_dead, 0)
	assert_eq(model.killed, 0)
	_assert_books(model)


## §4.6.5 gate: both conservation equations hold at EVERY tick of a battle
## containing a leak, a trap kill, a bolt kill, a unit kill, two charms
## (one exiting, one dying in a duel), and a duel survivor finished by the
## defender. Timeline (test_lane, wave_starts [0, 600], zero-cost spike
## 60dmg/1charge on cell 5 — DP exactness is P6's gate, not this one — and
## the defender at cell 2 from 180, affordable exactly then):
##   g0@0 leaks @211 (spike already spent); r0@60 dies to the spike @136;
##   g1@61 bolt-killed @200 in cell 4; g2@120 blocked @181, defender kills
##   it @301; h0@240 blocked @361, charmed @365 at hp 152, exits @485;
##   g3@600 charmed @650, duels h1@610 in cell 0 during step 668, dies
##   @803; h1 resumes @804, blocks @866, defender kills it -> CLEAR.
func test_extended_conservation_every_tick() -> void:
	var spike := TrapDef.new()
	spike.id = &"test_spike"
	spike.display_name = "Test Spike"
	spike.dp_cost = 0
	spike.trigger = TrapDef.Trigger.ON_ENTER
	spike.effect = TrapDef.Effect.DAMAGE
	spike.damage = 60
	spike.charges = 1
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"runner", "path_idx": 0},
		{"tick": 61, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 120, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 240, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 600, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 610, "enemy_id": &"heavy", "path_idx": 0},
	]
	var stage := _stage_with_waves(entries)
	stage.wave_starts = PackedInt32Array([0, 600])
	var model := _make_model(stage, {&"test_spike": spike})
	var actions := [
		[0, &"place_trap", &"test_spike", Vector2i(5, 2)],
		[180, &"deploy", &"defender_1", Vector2i(2, 2), int(RIGHT)],
		[200, &"cast", &"bolt", Vector2i(4, 2)],
		[365, &"cast", &"charm", 4],
		[650, &"cast", &"charm", 5],
	]
	var idx := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			assert_true(model.apply_action(entry.slice(1)), "timeline action @ %d" % model.tick)
			idx += 1
		model.step()
		_assert_books(model)
	assert_eq(idx, actions.size(), "every timeline action applied")
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(model.spawned, 7)
	assert_eq(model.killed, 4, "spike + bolt + two defender kills")
	assert_eq(model.leaked, 1, "g0 leaked through the spent spike")
	assert_eq(model.charmed, 2)
	assert_eq(model.charmed_exited, 1, "h0 ran back out")
	assert_eq(model.charmed_dead, 1, "g3 lost its duel")
	assert_eq(model.alive_charmed_count(), 0)


## §4.6.6 gate — the twist's composition proof: an undefended heavy wave
## with leak_limit 1 is unwinnable, and the identical timeline WITH one
## charm cast clears — the charmed heavy turns and kills the grunt behind
## it while the second grunt leaks within the limit.
## Derivation: h0@0 leaks @421, g1@240 leaks @451, g2@300 leaks @511 ->
## without the cast the second leak (451) exceeds limit 1 -> DEFEAT. With
## charm@400 (h0 at P = 6_649_734), h0 reverses and meets g1 in cell 6
## during step 421; the duel kills g1 during step 556; g2 walks past the
## duel and leaks @511 (1 <= limit); no ENEMY remains once g1 dies ->
## CLEAR while the ally is still walking back.
func test_charm_win_loss_pair() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 240, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 300, "enemy_id": &"grunt", "path_idx": 0},
	]
	var stage := _stage_with_waves(entries)
	stage.leak_limit = 1
	var with_charm := _make_model(stage)
	with_charm.run_timeline([[400, &"cast", &"charm", 0]], MAX_TICKS)
	assert_eq(with_charm.result, BattleModel.Result.CLEAR, "the charm cast wins the stage")
	assert_eq(with_charm.leaked, 1)
	assert_eq(with_charm.killed, 1, "the charmed heavy killed the grunt behind it")
	assert_eq(with_charm.charmed_dead, 0)
	_assert_books(with_charm)

	var without := _make_model(_stage_with_waves(entries))
	without.stage.leak_limit = 1
	without.run_timeline([], MAX_TICKS)
	assert_eq(without.result, BattleModel.Result.DEFEAT, "the identical timeline without it loses")
	assert_eq(without.leaked, 2, "defeat lands on the second leak")


## §4.6.7: CLEAR is evaluated on ENEMY count only — killing the last enemy
## while an ally is mid-reversal clears that tick, and the terminal state
## freezes everything (including the ally) exactly.
func test_clear_ignores_walk_back_and_freezes() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
	]
	var model := _make_model(_stage_with_waves(entries))
	model.step(100)
	assert_true(model.apply_action([&"cast", &"charm", 0]))
	model.step(150 - model.tick)
	assert_true(model.apply_action([&"cast", &"bolt", Vector2i(3, 2)]), "bolt the last enemy")
	assert_eq(model.alive_enemy_count(), 0)
	assert_eq(model.alive_charmed_count(), 1, "ally still walking back")
	model.step()
	assert_eq(model.result, BattleModel.Result.CLEAR, "victory does not wait for the ally")
	assert_eq(model.stars, 3)
	var frozen := model.state_hash()
	var frozen_tick := model.tick
	model.step(100)
	assert_eq(model.state_hash(), frozen, "terminal freeze holds with a mid-path ally")
	assert_eq(model.tick, frozen_tick)
	_assert_books(model)


## §4.6.8 gate: determinism oracle on a spell-heavy timeline (traps + bolt
## + charm + duels) — two fresh models, identical hashes every 100 ticks
## and identical outcome.
func test_determinism_oracle_with_spells() -> void:
	var actions := [
		[0, &"place_trap", &"spike_plate", Vector2i(4, 2)],
		[10, &"place_trap", &"tar_pit", Vector2i(3, 2)],
		[150, &"cast", &"charm", 0],
		[250, &"cast", &"bolt", Vector2i(4, 2)],
	]
	var runs: Array = []
	for _run: int in 2:
		var stage := ResourceLoader.load(STAGE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var grunt := ResourceLoader.load(
			"res://data/enemies/grunt.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		)
		var spike := ResourceLoader.load(SPIKE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var tar := ResourceLoader.load(TAR_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var bolt := ResourceLoader.load(
			"res://data/spells/bolt.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		)
		var charm := ResourceLoader.load(
			"res://data/spells/charm.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		)
		var squad: Array[StringName] = []
		var model := BattleModel.create(
			stage,
			squad,
			42,
			config,
			{&"grunt": grunt},
			{},
			{&"spike_plate": spike, &"tar_pit": tar},
			{&"bolt": bolt, &"charm": charm}
		)
		var idx := 0
		var hashes: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < actions.size() and int(actions[idx][0]) == model.tick:
				var entry: Array = actions[idx]
				model.apply_action(entry.slice(1))
				idx += 1
			model.step()
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		runs.append({
			"hashes": hashes,
			"outcome": [
				model.result, model.stars, model.leaked, model.killed,
				model.charmed, model.charmed_dead, model.charmed_exited, model.tick,
			],
		})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical on a spell-heavy timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")
