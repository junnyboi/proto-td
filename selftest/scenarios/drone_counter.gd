extends RefCounted

## Phase 4 scenario (td-phase-4-5.md §3.3): the composition proof's winning
## timeline, rendered. Squad defender_1 + sniper_1 on test_drone: grunts get
## blocked at (3,2), the three drones bypass every blocker; the sniper on the
## elevated tile (4,1) kills drones #1/#2 in range (#0 leaks pre-deploy).
## Model asserts: drones never blocked, sniper killed >= 1 drone, CLEAR.
## Falsifiable shot checklist: drone visually distinct at 1x (cyan, smaller
## body, offset shadow) passing over the blocked cluster; white tracer line
## visible in the post-attack frame; HUD result CLEAR. Uses the view's
## ticks_per_frame_scale seam to fast-forward dull stretches (speed can never
## change outcomes — architecture rule 6).

const SQUAD: Array[StringName] = [&"defender_1", &"defender_2", &"sniper_1"]
const DEFENDER_CELL := Vector2i(3, 2)
const SNIPER_CELL := Vector2i(4, 1)
const RIGHT := int(UnitState.Facing.RIGHT)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 12_000
	await h.frames(10)
	var game := h.autoload("Game")
	game.set("default_squad", SQUAD)
	game.call("start_battle", &"test_drone")
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	var hud := view.find_child("BattleHud", true, false) as Label
	var drones_ever_blocked := false

	# deploy the defender at ~180, then fast-forward to the drone flyover
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 180:
		await h.physics_frames(1)
	var defender_ok := model.apply_action([&"deploy", &"defender_1", DEFENDER_CELL, RIGHT])
	h.check("defender deployed via seam", defender_ok)

	# drone #0 (enemy id 3) crosses the blocked cluster's cell during ticks
	# 575..599 — catch it at 1x for the flyover shot
	while model.tick < 555 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	var flyover_seen := false
	while model.tick < 620 and model.result == BattleModel.Result.RUNNING:
		drones_ever_blocked = drones_ever_blocked or _any_drone_blocked(model)
		var drone := _enemy_or_null(model, 3)
		if not flyover_seen and drone != null and drone.alive \
				and Pathing.cell_of(model.path_for(0), drone.progress_units) == DEFENDER_CELL:
			var held := model.units[0].blocked_ids.size()
			h.check("drone passes over a blocked cluster", held >= 2, "held=%d" % held)
			await h.shot("drones_over_defenders")
			flyover_seen = true
		await h.physics_frames(1)
	h.check("flyover observed", flyover_seen, "tick=%d" % model.tick)

	# deploy the sniper at ~720, then catch its first shot (~825) at 1x
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 720 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	var sniper_ok := model.apply_action([&"deploy", &"sniper_1", SNIPER_CELL, RIGHT])
	h.check("sniper deployed on the elevated tile", sniper_ok)
	while model.tick < 810 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	var sniper := model.units[1] if model.units.size() > 1 else null
	var shot_seen := false
	while model.tick < 900 and model.result == BattleModel.Result.RUNNING:
		drones_ever_blocked = drones_ever_blocked or _any_drone_blocked(model)
		if not shot_seen and sniper != null and sniper.last_attack_tick >= 0 \
				and model.tick - sniper.last_attack_tick <= 2:
			await h.shot("sniper_shot")
			shot_seen = true
		await h.physics_frames(1)
	h.check("sniper fired at a drone", shot_seen, "tick=%d" % model.tick)

	# run out the battle: drones #1/#2 die in range -> CLEAR with one leak
	view.set("ticks_per_frame_scale", 4.0)
	while model.result == BattleModel.Result.RUNNING and model.tick < 1200:
		drones_ever_blocked = drones_ever_blocked or _any_drone_blocked(model)
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("drones never blocked", not drones_ever_blocked)
	h.check("battle clears", model.result == BattleModel.Result.CLEAR, "tick=%d" % model.tick)
	var drone_kills := 0
	for e: EnemyState in model.enemies:
		if e.aerial and not e.alive and e.hp <= 0:
			drone_kills += 1
	h.check("sniper killed drones", drone_kills >= 1, "drone_kills=%d" % drone_kills)
	var tally := "killed=%d leaked=%d" % [model.killed, model.leaked]
	h.check("five kills, one leak", model.killed == 5 and model.leaked == 1, tally)
	var hud_text := hud.text if hud != null else "no hud"
	h.check("HUD shows CLEAR", hud != null and hud_text.contains("CLEAR"), hud_text)
	await h.frames(2)
	await h.shot("battle_end")
	h.done()


func _enemy_or_null(model: BattleModel, enemy_id: int) -> EnemyState:
	if enemy_id < model.enemies.size():
		return model.enemies[enemy_id]
	return null


func _any_drone_blocked(model: BattleModel) -> bool:
	for e: EnemyState in model.enemies:
		if e.aerial and e.blocked_by >= 0:
			return true
	return false
