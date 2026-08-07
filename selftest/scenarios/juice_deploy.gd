extends RefCounted

## Phase 9 item 1 — deployment ritual (td-phase-9.md §4.1). One raw-input
## drag validates the adapter hooks (cancelled drag first, then a real
## deploy through the facing chooser); a second unit deploys via the seam to
## prove landing juice keys off the model edge, not the mouse. Time-scale
## checks run in both lanes; dust pixels only windowed (check_pixels skips
## headless, recorded). All magnitudes read through cfg so data retunes
## never break this scenario.

const DEPLOY_CELL := Vector2i(1, 1)
const SEAM_CELL := Vector2i(1, 3)
const DUST_COLOR := Color("efe1a7")


func run(h: SelfTestHarness) -> void:
	h.max_frames = 3600
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var cfg: JuiceConfig = view.get("cfg")
	var telemetry := h.autoload("Telemetry")
	h.expect_done()
	var bar := view.find_child("DeployBar", true, false)
	var slot := bar.find_child("Slot_vanguard_1", true, false) as Button

	# cancelled drag: slowdown during, exactly 1.0 after the right-click
	await h.press_mouse_at(slot.get_global_rect().get_center())
	h.check(
		"time scale at drag value mid-drag",
		Engine.time_scale == cfg.deploy_drag_time_scale,
		"scale=%f" % Engine.time_scale,
	)
	await h.click_view(view.call("cell_center", DEPLOY_CELL), MOUSE_BUTTON_RIGHT)
	h.check("right-click cancel restores 1.0", Engine.time_scale == 1.0)
	await h.release_mouse_at(slot.get_global_rect().get_center())

	# real drag-deploy: press slot -> drag -> release -> facing chooser
	await h.press_mouse_at(slot.get_global_rect().get_center())
	h.move_mouse_to_view(view.call("cell_center", DEPLOY_CELL))
	await h.frames(3)
	h.check(
		"time scale at drag value during deploy drag",
		Engine.time_scale == cfg.deploy_drag_time_scale,
	)
	await h.shot("deploy_drag")
	await h.release_mouse_at(view.call("cell_center", DEPLOY_CELL))
	await h.frames(2)
	h.check("drag end restores 1.0 at the facing chooser", Engine.time_scale == 1.0)
	var facing := bar.find_child("FacingRight", true, false) as Button
	h.check("facing chooser open", facing != null and facing.visible)
	await h.click_view(facing.get_global_rect().get_center())
	await h.frames(2)
	h.check("unit deployed", model.alive_unit_at(DEPLOY_CELL) != null)

	# seam deploy: landing juice keys off the model edge, no mouse involved —
	# and the dust probes anchor HERE, where the trigger-to-shot distance is
	# exactly controlled (the raw path's click_view holds consume most of the
	# dust window at high refresh rates; the raw deploy above still proves
	# the adapter, this one proves the pixels)
	h.check("dp funded via debug verb", model.apply_action([&"debug_set_dp", 99]))
	var seam_ok := model.apply_action(
		[&"deploy", &"defender_1", SEAM_CELL, int(UnitState.Facing.RIGHT)]
	)
	h.check("seam deploy accepted", seam_ok)
	await h.frames(2)
	var center: Vector2 = view.call("cell_center", SEAM_CELL)
	var probe := Rect2i(int(center.x) - 44, int(center.y) - 44, 88, 88)
	var img := await h.shot_grab("deploy_land")
	h.check_pixels(
		"dust pixels at the landing cell", img,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, probe, DUST_COLOR, 0.05) > 30,
	)
	await h.frames(cfg.deploy_dust_frames + 4)
	var img_settled := await h.shot_grab("deploy_settled")
	h.check_pixels(
		"dust gone after its frame budget", img_settled,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, probe, DUST_COLOR, 0.05) < 8,
	)
	await h.frames(1)
	var deploy_events := 0
	for ev: Dictionary in telemetry.get("_events"):
		if ev["name"] == "sfx_played" and String(ev["data"]["id"]) == "deploy":
			deploy_events += 1
	h.check(
		"one sfx_played:deploy per deploy (raw + seam)",
		deploy_events == 2 and model.units.size() == 2,
		"events=%d units=%d" % [deploy_events, model.units.size()],
	)
	h.done()
