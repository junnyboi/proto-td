extends RefCounted

## Phase 2 scenario (td-phase-2-3.md §3.6). One deploy travels the full
## raw-input path (slot press -> drag -> release -> facing arrow) and one
## retreat travels the chip path — rule 3's once-per-verb validation. All
## other verbs go through the seam. Model-state asserts only (never node
## positions); DP asserts use ledger fields, which are monotonic, because
## regen keeps running during the drag. Everything completes well before
## test_lane's idle defeat (~tick 421).

const TARGET_CELL := Vector2i(3, 2)
const ELEV_CELL := Vector2i(2, 1)
const SEAM_CELL := Vector2i(1, 0)


func run(h: SelfTestHarness) -> void:
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D

	var bar := view.find_child("DeployBar", true, false)
	var vg_slot := bar.find_child("Slot_vanguard_1", true, false) as Button
	var def_slot := bar.find_child("Slot_defender_1", true, false) as Button
	h.check("both squad slots present", vg_slot != null and def_slot != null)
	if vg_slot == null or def_slot == null:
		return
	await h.frames(2)
	h.check(
		"defender slot disabled while broke",
		def_slot.disabled and model.dp < 16,
		"dp=%d disabled=%s" % [model.dp, def_slot.disabled],
	)
	h.check("vanguard slot enabled at start", not vg_slot.disabled)

	# raw-input deploy: press the slot, drag across an invalid E cell (red
	# cursor + green overlays in the shot), release on a path cell, face RIGHT
	await h.press_mouse_at(vg_slot.get_global_rect().get_center())
	h.move_mouse_to_view(view.call("cell_center", ELEV_CELL))
	await h.frames(3)
	h.check(
		"E cell invalid for GROUND op during drag",
		not model.can_deploy_at(&"vanguard_1", ELEV_CELL),
	)
	await h.shot("placement_mode")
	h.move_mouse_to_view(view.call("cell_center", TARGET_CELL))
	await h.frames(3)
	await h.release_mouse_at(view.call("cell_center", TARGET_CELL))
	await h.frames(3)
	var right_btn := bar.find_child("FacingRight", true, false) as Button
	h.check("facing chooser visible", right_btn != null and right_btn.visible)
	await h.shot("facing_chooser")
	if right_btn != null:
		await h.click_view(right_btn.get_global_rect().get_center())
	await h.frames(3)

	var unit: UnitState = model.alive_unit_at(TARGET_CELL)
	h.check("raw-input deploy placed the unit", unit != null)
	h.check(
		"deployed facing RIGHT",
		unit != null and unit.facing == UnitState.Facing.RIGHT,
	)
	h.check("dp_spent == vanguard cost", model.dp_spent == 8, "spent=%d" % model.dp_spent)
	h.check("vanguard slot disabled while deployed", vg_slot.disabled)
	await h.shot("deployed")

	# raw-input retreat: click the unit -> chip -> click Retreat
	await h.click_view(view.call("cell_center", TARGET_CELL))
	await h.frames(3)
	var chip := bar.find_child("RetreatChip", true, false) as Button
	h.check("retreat chip visible after unit click", chip != null and chip.visible)
	if chip != null:
		await h.click_view(chip.get_global_rect().get_center())
	await h.frames(3)
	h.check("unit retreated", model.alive_unit_at(TARGET_CELL) == null)
	h.check("refund == floor(8 * 50%)", model.dp_refunded == 4, "refunded=%d" % model.dp_refunded)
	h.check("retreated counter", model.retreated == 1)

	# slot re-enables as soon as the model says deployable again (regen)
	while not model.is_deployable(&"vanguard_1") and model.tick < 350:
		await h.physics_frames(5)
	await h.frames(2)
	h.check("vanguard slot re-enabled after retreat", not vg_slot.disabled)
	await h.shot("after_retreat")

	# second deploy via the seam (raw input already validated once per verb)
	var ok := model.apply_action(
		[&"deploy", &"vanguard_1", SEAM_CELL, int(UnitState.Facing.DOWN)]
	)
	h.check("seam deploy accepted", ok)
	h.check("seam unit on the field", model.alive_unit_at(SEAM_CELL) != null)
	var expected_dp := (
		model.config.dp_start
		+ model.dp_regen_accrued
		+ model.dp_vanguard_generated
		+ model.dp_refunded
		- model.dp_spent
		- model.dp_lost_to_cap
	)
	h.check("DP ledger holds in the running view", model.dp == expected_dp)

	# --- P12.2: the lift actually renders + positive ELEVATED deploy ---
	# probe pair BEFORE anything stands on the E cell: the lifted face and
	# the wall band (at the unlifted face position) must render differently
	var lift_px := 16.0 * float(view.call("grid_scale"))
	var lifted_pt: Vector2 = view.call("cell_center", ELEV_CELL)
	var unlifted_pt := lifted_pt + Vector2(0.0, lift_px)
	var img_elev := await h.shot_grab("elevated_lift")
	h.check_pixels(
		"lifted face differs from the wall band below it", img_elev,
		func(im: Image) -> bool:
			var diff := 0
			for dy: int in 6:
				for dx: int in 12:
					var a := im.get_pixel(int(lifted_pt.x) - 6 + dx, int(lifted_pt.y) - 3 + dy)
					var b := im.get_pixel(
						int(unlifted_pt.x) - 6 + dx, int(unlifted_pt.y) - 3 + dy
					)
					if a != b:
						diff += 1
			return diff > 30,
	)
	# grant + fund through the debug verbs (dispatcher clients, rule 5) so
	# the elevated deploy lands well before test_lane's idle defeat
	h.check("sniper granted", model.apply_action([&"debug_grant_operator", &"sniper_1"]))
	h.check("dp funded", model.apply_action([&"debug_set_dp", 50]))
	var ok_elev := model.apply_action(
		[&"deploy", &"sniper_1", ELEV_CELL, int(UnitState.Facing.LEFT)]
	)
	h.check("ELEVATED op deploys on the E cell", ok_elev)
	h.check("sniper on the field", model.alive_unit_at(ELEV_CELL) != null)
	await h.frames(3)
	# HP bar rides the lifted body (P12.2: assert, don't assume). The whole
	# unit column scales with the grid: bar local y is [-66, -61] from the
	# face point, so the band must be s-scaled or it probes below the bar
	# (the unscaled version passed only when a passing enemy's bar drifted
	# through it — wrong pixels, right color).
	var s := float(view.call("grid_scale"))
	var img_sniper := await h.shot_grab("elevated_sniper")
	h.check_pixels(
		"HP fill visible above the lifted sniper", img_sniper,
		func(im: Image) -> bool:
			var band := Rect2i(
				int(lifted_pt.x - 32.0 * s), int(lifted_pt.y - 70.0 * s),
				int(64.0 * s), int(70.0 * s)
			)
			return SelfTestProbes.color_in_rect(im, band, Color("a7f070"), 0.05) > 10,
	)
	# raw click on the LIFTED face opens the retreat chip: real-input proof
	# that elevated picking resolves through the iso seam (sniper SP is not
	# full this early, so the click takes the chip path, not the skill)
	await h.click_view(view.call("cell_center", ELEV_CELL))
	await h.frames(3)
	h.check("lifted-face click selects the sniper", chip != null and chip.visible)
