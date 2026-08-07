extends RefCounted

## Phase 3 scenario (td-phase-2-3.md §4.5): the signature 2-block case,
## rendered. Deploys via the seam (raw input was validated once per verb in
## deploy_flow); vanguard (block 2) on (3,2) vs the first 3 grunts of
## test_lane. #0/#1 block at ticks 121/181, #2 finds no capacity and walks
## past (leaks at 361), kills land at 301 and 511 -> CLEAR ~tick 512 (D22
## budget). Model-state asserts only; the HUD string is checked against the
## model, never against pixels.

const LANE_CELL := Vector2i(3, 2)


func run(h: SelfTestHarness) -> void:
	# ~512 ticks = ~17s wall clock in the windowed lane; on high-refresh
	# displays that alone is ~3600 process frames, so the default runaway
	# watchdog budget is too tight for a full D22-length battle.
	h.max_frames = 9000
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	# trim to the signature 3-grunt wave before the deferred scene swap reads
	# pending_stage (the swap runs end-of-frame, this assignment is same-frame)
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for i: int in 3:
		waves.append(stage.waves[i])
	stage.waves = waves
	game.set("pending_stage", stage)
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var hud := view.find_child("BattleHud", true, false) as Label

	var deploy_ok := model.apply_action(
		[&"deploy", &"vanguard_1", LANE_CELL, int(UnitState.Facing.RIGHT)]
	)
	h.check("seam deploy accepted", deploy_ok)
	if not deploy_ok:
		return

	# two grunts held on the lane cell (blocked at ticks 121 and 181)
	while model.units[0].blocked_ids.size() < 2 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(5)
	var held := model.units[0].blocked_ids.size()
	h.check("blocked count reaches 2", held == 2, "held=%d tick=%d" % [held, model.tick])
	var path := model.path_for(0)
	var e0_cell := Pathing.cell_of(path, model.enemies[0].progress_units)
	var e1_cell := Pathing.cell_of(path, model.enemies[1].progress_units)
	var frozen_on_cell := e0_cell == LANE_CELL and e1_cell == LANE_CELL
	h.check("both held grunts frozen on the lane cell", frozen_on_cell)
	await h.frames(2)
	await h.shot("block_cluster")

	# first kill at tick 301; the HUD kill counter mirrors the model
	while model.killed < 1 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(5)
	h.check("first kill lands", model.killed >= 1, "tick=%d" % model.tick)
	var hud_text := hud.text if hud != null else "no hud"
	var hud_matches := hud != null and hud_text.contains("kills %d" % model.killed)
	h.check("HUD kill counter matches the model", hud_matches, hud_text)
	await h.frames(2)
	await h.shot("first_kill")

	# overflow grunt leaked at 361; refocused kill at 511 ends the battle
	while model.result == BattleModel.Result.RUNNING and model.tick < 1000:
		await h.physics_frames(10)
	h.check("battle clears", model.result == BattleModel.Result.CLEAR, "tick=%d" % model.tick)
	var tally := "killed=%d leaked=%d" % [model.killed, model.leaked]
	h.check("two kills, one leak", model.killed == 2 and model.leaked == 1, tally)
	var books := model.alive_count() + model.killed + model.leaked
	h.check("conservation at terminal", model.spawned == books)
	await h.frames(2)
	await h.shot("battle_end")
