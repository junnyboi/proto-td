extends RefCounted

## Phase 9 items 6 + 7 (td-phase-9.md §4.3). Reuses trap_flow's derived
## layout (tar on cell 3, spike on cell 4, grunts at 30/90/150 -> triggers
## at ~180/240/300): the 3rd trigger is the FINAL charge, so the sprung
## frame must outlive the trap's model entry (the adoption path). Tar
## shimmer asserts via modulate node reads half a period apart — occupied
## reads differ, unoccupied reads are constant. Charm: pre/post pixel
## probes on the ally palette at the target's model-derived rect, plus the
## beat time-scale push/restore. SFX wiring counts are exact (C1).

const SPIKE_CELL := Vector2i(4, 2)
const TAR_CELL := Vector2i(3, 2)
const SPRUNG_COLOR := Color("f4f4f4")
const CHARMED_COLOR := Color("41a6f6")
const HEAVY_ID := 3


func run(h: SelfTestHarness) -> void:
	h.max_frames = 3600
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 150, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 300, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0},
	]
	stage.waves = waves
	game.set("pending_stage", stage)
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null and model.stage == stage)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var cfg: JuiceConfig = view.get("cfg")
	var telemetry := h.autoload("Telemetry")

	h.expect_done()
	h.check("spike placed", model.apply_action([&"place_trap", &"spike_plate", SPIKE_CELL]))
	h.check("tar placed", model.apply_action([&"place_trap", &"tar_pit", TAR_CELL]))
	var tar_id: int = model.traps[1].id

	# --- item 6: first trigger -> sprung frame on the surviving trap ---
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 165 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	while model.traps_triggered < 1 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	await h.frames(2)
	var spike_center: Vector2 = view.call("cell_center", SPIKE_CELL)
	var spike_probe := Rect2i(int(spike_center.x) - 16, int(spike_center.y) - 16, 32, 32)
	var img_sprung := await h.shot_grab("trap_sprung")
	h.check_pixels(
		"sprung pixels at the spike cell", img_sprung,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, spike_probe, SPRUNG_COLOR, 0.05) > 15,
	)

	# --- item 6: tar shimmer while g1 crosses the tar cell ---
	# (the rect only exists after a projection frame — never fetch it at
	# placement time, that null aborted an entire windowed run once)
	var tar_rect := view.find_child("Trap%d" % tar_id, true, false) as ColorRect
	h.check("tar rect projected", tar_rect != null)
	if tar_rect == null:
		return
	var g1: EnemyState = model.enemies[1]
	while model.result == BattleModel.Result.RUNNING and model.tick < 260:
		if Pathing.cell_of(model.path_for(g1.path_idx), g1.progress_units) == TAR_CELL:
			break
		await h.physics_frames(1)
	await h.frames(2)
	@warning_ignore("integer_division")
	var half_period: int = maxi(cfg.tar_shimmer_period_frames, 2) / 2
	var occupied_a := tar_rect.modulate
	await h.frames(half_period)
	var occupied_b := tar_rect.modulate
	h.check(
		"tar modulate oscillates while occupied",
		occupied_a != occupied_b,
		"a=%s b=%s" % [occupied_a, occupied_b],
	)

	# --- item 6: final charge — the sprung rect outlives the model entry ---
	view.set("ticks_per_frame_scale", 4.0)
	while model.traps_triggered < 3 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("spike removed from the model", model.traps.size() == 1)
	await h.frames(2)
	var img_final := await h.shot_grab("trap_sprung_final")
	h.check_pixels(
		"final-charge sprung pixels after model removal", img_final,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, spike_probe, SPRUNG_COLOR, 0.05) > 15,
	)
	await h.frames(cfg.trap_sprung_frames + 4)
	var img_gone := await h.shot_grab("trap_gone")
	h.check_pixels(
		"adopted rect freed after the sprung frames", img_gone,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, spike_probe, SPRUNG_COLOR, 0.05) < 5,
	)

	# --- item 6: tar static while unoccupied (grunts leaked, heavy not yet there) ---
	var idle_a := tar_rect.modulate
	await h.frames(half_period)
	var idle_b := tar_rect.modulate
	h.check("tar modulate constant while empty", idle_a == idle_b)

	# --- item 7: charm the heavy — palette flip + beat + restore ---
	var heavy: EnemyState = model.enemies[HEAVY_ID]
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 430 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("heavy alive and uncharmed", heavy.alive and heavy.faction == EnemyState.Faction.ENEMY)
	await h.frames(2)
	var pos := Pathing.position_of(model.path_for(heavy.path_idx), heavy.progress_units)
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var center: Vector2 = grid.position + (pos + Vector2.ONE * 0.5) * 64.0
	var heavy_probe := Rect2i(int(center.x) - 26, int(center.y) - 26, 52, 52)
	var img_before := await h.shot_grab("charm_before")
	h.check_pixels(
		"no ally palette before the cast", img_before,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, heavy_probe, CHARMED_COLOR, 0.05) < 5,
	)
	h.check("charm cast accepted", model.apply_action([&"cast", &"charm", HEAVY_ID]))
	await h.frames(2)
	h.check(
		"beat time scale on conversion",
		Engine.time_scale == cfg.charm_beat_time_scale,
		"scale=%f" % Engine.time_scale,
	)
	var img_after := await h.shot_grab("charm_after")
	h.check_pixels(
		"ally palette present after the cast", img_after,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, heavy_probe, CHARMED_COLOR, 0.08) > 100,
	)
	await h.frames(cfg.charm_beat_frames + 4)
	h.check("beat restored to 1.0", Engine.time_scale == 1.0)

	# --- exact wiring counts (C1) ---
	var snap_events := 0
	var charm_events := 0
	for ev: Dictionary in telemetry.get("_events"):
		if ev["name"] == "sfx_played":
			match String(ev["data"]["id"]):
				"trap_snap":
					snap_events += 1
				"charm":
					charm_events += 1
	var counters: Dictionary = telemetry.get("_counters")
	h.check(
		"sfx_played:trap_snap == trap_triggers",
		snap_events == 3 and model.traps_triggered == 3,
		"events=%d triggers=%d" % [snap_events, model.traps_triggered],
	)
	h.check(
		"sfx_played:charm == spells_cast_charm",
		charm_events == 1 and int(counters.get("spells_cast_charm", 0)) == 1,
		"events=%d counter=%s" % [charm_events, counters.get("spells_cast_charm")],
	)
	h.done()
