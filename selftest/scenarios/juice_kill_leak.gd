extends RefCounted

## Phase 9 items 3 + 4 (td-phase-9.md §4.2, burst engine per §1.4 C2). A
## runner leaks first (vignette + knock + shake + leak SFX); then a Bolt
## one-shots a 20-grunt cluster in a single tick — the strongest possible
## cap test (20 spark spawns attempted -> live count == kill_spark_cap
## exactly) while the sfx_played:kill event count stays exact (C1: the
## throttle gates audio only). Stage built in-test via the pending-stage
## seam; shots triggered on model conditions, never scheduled ticks.

const RUNNER_LEAK_APPROX := 136
const SPARK_COLOR := Color("ffcd75")
const VIGNETTE_COLOR := Color(0.9, 0.1, 0.1)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 3600
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [{"tick": 30, "enemy_id": &"runner", "path_idx": 0}]
	for i: int in 20:
		waves.append({"tick": 150 + i, "enemy_id": &"grunt", "path_idx": 0})
	waves.append({"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0})
	stage.waves = waves
	game.set("pending_stage", stage)
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null and model.stage == stage)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var cfg: JuiceConfig = view.get("cfg")
	var juice := view.find_child("JuiceLayer", true, false)
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var grid_base: Vector2 = grid.position
	h.expect_done()
	var telemetry := h.autoload("Telemetry")

	# --- item 4: the runner leaks ---
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < RUNNER_LEAK_APPROX - 20 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	while model.leaked == 0 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	h.check("the runner leaked", model.leaked == 1, "tick=%d" % model.tick)
	await h.frames(2)
	var img_leak := await h.shot_grab("leak_vignette")
	var edge := Rect2i(0, 0, 1280, 8)
	h.check_pixels(
		"vignette red at the screen edge on the leak", img_leak,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, edge, VIGNETTE_COLOR, 0.08) > 2_000,
	)
	await h.frames(20)
	var img_clear := await h.shot_grab("leak_clear")
	h.check_pixels(
		"vignette gone 20 frames later", img_clear,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, edge, VIGNETTE_COLOR, 0.08) < 100,
	)
	h.check(
		"grid position restored after the leak shake",
		grid.position == grid_base,
		"pos=%s base=%s" % [grid.position, grid_base],
	)

	# --- item 3: bolt the cluster ---
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 300 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("all 20 grunts alive and clustered", model.alive_enemy_count() == 20)
	var median: EnemyState = model.enemies[10]
	var target := Pathing.cell_of(model.path_for(median.path_idx), median.progress_units)
	var killed_before := model.killed
	h.check("bolt cast at the cluster", model.apply_action([&"cast", &"bolt", target]))
	var killed_delta := model.killed - killed_before
	h.check("the burst killed all 20 in one tick", killed_delta == 20, "delta=%d" % killed_delta)
	# process_frame fires BEFORE _process runs, so detection needs 2 awaits
	await h.frames(2)
	var spark_count := int(juice.call("spark_count"))
	h.check(
		"spark count capped exactly (20 attempted)",
		spark_count == cfg.kill_spark_cap,
		"count=%d cap=%d" % [spark_count, cfg.kill_spark_cap],
	)
	# shot inside the spark window (they live kill_spark_frames frames)
	var center: Vector2 = view.call("cell_center", target)
	var probe := Rect2i(int(center.x) - 80, int(center.y) - 80, 160, 160)
	var img_burst := await h.shot_grab("kill_burst")
	h.check_pixels(
		"spark pixels at the burst cells", img_burst,
		func(im: Image) -> bool: return SelfTestProbes.color_in_rect(im, probe, SPARK_COLOR, 0.05) > 10,
	)
	for _i: int in cfg.kill_spark_frames + 2:
		h.check(
			"spark count <= cap during the burst decay",
			int(juice.call("spark_count")) <= cfg.kill_spark_cap,
		)
		await h.frames(1)

	# --- telemetry: exact wiring counts (C1) ---
	var kill_events := 0
	var leak_events := 0
	for ev: Dictionary in telemetry.get("_events"):
		if ev["name"] == "sfx_played":
			match String(ev["data"]["id"]):
				"kill":
					kill_events += 1
				"leak":
					leak_events += 1
	h.check(
		"sfx_played:kill == kills (>= 0.9x band holds with slack)",
		kill_events == model.killed,
		"events=%d killed=%d" % [kill_events, model.killed],
	)
	h.check("sfx_played:leak == 1", leak_events == 1, "events=%d" % leak_events)
	h.done()
