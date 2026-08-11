extends RefCounted

## Phase 6 scenario (td-phase-6-7.md §3.6). One spike placement travels the
## full raw-input path (slot press -> drag under amber highlights -> release
## on a path cell places immediately, no facing) — rule 3's once-per-verb
## validation; the tar placement goes through the seam. All battle asserts
## are model-state (never node positions). Wall-clock cost is bounded by the
## view's ticks-per-frame seam (E12): the battle fast-forwards at 8x between
## interaction points. Timeline (test_lane, tar on cell 3, spike on cell 4):
## g0 spawn 30 -> slowed by tar -> enters the spike cell at tick 180; g1/g2
## follow at 240/300; the 3-charge spike is exhausted at tick 300.

const SPIKE_CELL := Vector2i(4, 2)
const TAR_CELL := Vector2i(3, 2)
const SLOWED_STEP := 16_666


func run(h: SelfTestHarness) -> void:
	h.max_frames = 4000
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	var telemetry := h.autoload("Telemetry")

	var bar := view.find_child("DeployBar", true, false)
	var spike_slot := bar.find_child("Slot_spike_plate", true, false) as Button
	var tar_slot := bar.find_child("Slot_tar_pit", true, false) as Button
	h.check("both trap slots present", spike_slot != null and tar_slot != null)
	if spike_slot == null or tar_slot == null:
		return
	await h.frames(2)
	h.check("spike slot enabled at start (dp 10 >= 4)", not spike_slot.disabled)

	# raw-input placement: press the slot, drag over the grid (amber valid
	# highlights in the shot), release on a GROUND path cell -> verb fires
	await h.press_mouse_at(spike_slot.get_global_rect().get_center())
	h.move_mouse_to_view(view.call("cell_center", SPIKE_CELL))
	await h.frames(3)
	h.check(
		"off-path ground is invalid for traps",
		not model.can_place_trap_at(&"spike_plate", Vector2i(1, 0)),
	)
	await h.shot("traps_placed")
	await h.release_mouse_at(view.call("cell_center", SPIKE_CELL))
	await h.frames(3)
	h.check("raw-input placement landed", model.alive_trap_at(SPIKE_CELL) != null)
	h.check("spike DP spent", model.dp_spent == 4, "spent=%d" % model.dp_spent)

	# seam placement for the second trap kind (raw input validated once/verb)
	var ok := model.apply_action([&"place_trap", &"tar_pit", TAR_CELL])
	h.check("seam tar placement accepted", ok)
	h.check("tar DP spent", model.dp_spent == 10, "spent=%d" % model.dp_spent)
	h.check("two traps on the field", model.traps.size() == 2)
	await h.frames(3)
	await h.shot("spike_armed")
	await h.shot("tar_overlay")

	# fast-forward to the first trigger (g0 enters the spike cell at 180)
	view.set("ticks_per_frame_scale", 8.0)
	while model.tick < 185 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(2)
	var spike: TrapState = model.alive_trap_at(SPIKE_CELL)
	h.check("spike charge consumed", spike != null and spike.charges_left == 2)
	h.check(
		"g0 paid the spike damage",
		model.enemies[0].hp == 20,
		"hp=%d" % model.enemies[0].hp,
	)
	h.check("model counted the trigger", model.traps_triggered >= 1)
	var counters: Dictionary = telemetry.get("_counters")
	h.check(
		"telemetry counted trap placements + triggers",
		int(counters.get("traps_placed", 0)) == 2 and int(counters.get("trap_triggers", 0)) >= 1,
		"placed=%s triggers=%s" % [counters.get("traps_placed"), counters.get("trap_triggers")],
	)

	# tar slow, sampled on the model: while g1 stands on the tar cell its
	# per-tick advance is exactly the slowed step
	var g1: EnemyState = model.enemies[1]
	while model.result == BattleModel.Result.RUNNING and model.tick < 400:
		if g1.alive and Pathing.cell_of(model.path_for(g1.path_idx), g1.progress_units) == TAR_CELL:
			break
		await h.physics_frames(1)
	var t1 := model.tick
	var p1 := g1.progress_units
	await h.physics_frames(2)
	var t2 := model.tick
	var p2 := g1.progress_units
	var on_tar := Pathing.cell_of(model.path_for(g1.path_idx), g1.progress_units) == TAR_CELL
	h.check(
		"tar-slowed advance is exactly the slowed step",
		on_tar and t2 > t1 and (p2 - p1) == SLOWED_STEP * (t2 - t1),
		"dp=%d dt=%d" % [p2 - p1, t2 - t1],
	)

	# run past the third trigger (tick 300): the spike is exhausted + removed
	while model.tick < 310 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(2)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("spike removed after 3 triggers", model.alive_trap_at(SPIKE_CELL) == null)
	h.check(
		"three triggers counted",
		model.traps_triggered == 3,
		"triggers=%d" % model.traps_triggered,
	)
	h.check("tar is permanent", model.alive_trap_at(TAR_CELL) != null)
	await h.frames(2)
	await h.shot("spike_after")
	h.done()
