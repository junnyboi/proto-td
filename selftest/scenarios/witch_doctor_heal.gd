extends RefCounted

## TD-021 exact-candidate scenario. The first healer click arms target mode;
## the second valid click heals one injured ally through the public Mend verb.
## Every required input path is synthetic, state checks run in both lanes, and
## mint burst pixels gate the windowed lane with a present/absent pair.

const SQUAD: Array[StringName] = [&"defender_1", &"witch_doctor_1"]
const DEFENDER_CELL := Vector2i(4, 2)
const HEALER_CELL := Vector2i(2, 1)
const EMPTY_CELL := Vector2i(0, 0)
const RIGHT := int(UnitState.Facing.RIGHT)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 2400
	await h.frames(10)
	var game := h.autoload("Game")
	game.set("default_squad", SQUAD)
	game.call("start_battle", &"test_skill")
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	var cfg: JuiceConfig = view.get("cfg")
	var telemetry := h.autoload("Telemetry")
	var bar := view.find_child("DeployBar", true, false) as DeployBar
	var grid := view.find_child("GridRoot", true, false) as Node2D

	h.check("DP funded through public debug verb", model.apply_action([&"debug_set_dp", 99]))
	h.check(
		"defender deployed",
		model.apply_action([&"deploy", &"defender_1", DEFENDER_CELL, RIGHT]),
	)
	h.check(
		"Witch Doctor deployed",
		model.apply_action([&"deploy", &"witch_doctor_1", HEALER_CELL, RIGHT]),
	)
	var defender: UnitState = model.units[0]
	var healer: UnitState = model.units[1]

	view.set("ticks_per_frame_scale", 4.0)
	while (
		model.result == BattleModel.Result.RUNNING
		and (
			defender.hp > defender.hp_max - 60
			or not healer.is_skill_ready()
			or not defender.is_skill_ready()
		)
	):
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 0.0)
	h.check(
		"injured ally and both charged skills reached",
		defender.alive
			and defender.hp <= defender.hp_max - 60
			and healer.is_skill_ready()
			and defender.is_skill_ready(),
		"tick=%d hp=%d healer_sp=%d defender_sp=%d"
			% [model.tick, defender.hp, healer.sp, defender.sp],
	)

	# Invalid empty-cell click leaves mode armed and the model byte-identical.
	await h.click_view(view.call("cell_center", HEALER_CELL))
	var idle_hash := model.state_hash()
	await h.click_view(view.call("cell_center", EMPTY_CELL))
	h.check("invalid target click is hash-equal", model.state_hash() == idle_hash)
	h.check("invalid target click keeps target mode active", bar.is_mend_targeting())

	# Right-click is an explicit cancel with no model mutation.
	await h.click_view(view.call("cell_center", EMPTY_CELL), MOUSE_BUTTON_RIGHT)
	h.check("right-click exits target mode", not bar.is_mend_targeting())
	h.check("right-click cancel is hash-equal", model.state_hash() == idle_hash)

	# ui_cancel is independently executable and hash-equal.
	await h.click_view(view.call("cell_center", HEALER_CELL))
	var ui_cancel_hash := model.state_hash()
	h.press("ui_cancel")
	await h.frames(2)
	h.release("ui_cancel")
	await h.frames(2)
	h.check("ui_cancel exits target mode", not bar.is_mend_targeting())
	h.check("ui_cancel is hash-equal", model.state_hash() == ui_cancel_hash)

	# Mend targeting blocks a real middle-button drag at the BattleView seam.
	await h.click_view(view.call("cell_center", HEALER_CELL))
	var pan_bounds: Rect2 = view.call("map_pan_bounds")
	h.check(
		"map drag proof has a non-vacuous axis",
		pan_bounds.size.x > 0.0 or pan_bounds.size.y > 0.0,
		"bounds=%s" % pan_bounds,
	)
	var pan_before: Vector2 = view.call("map_pan")
	var root_before := grid.position
	var pointer := view.get_viewport_rect().size * 0.5
	_send_button(pointer, MOUSE_BUTTON_MIDDLE, true)
	_send_motion(pointer + Vector2(80, 80), Vector2(80, 80), true)
	_send_button(pointer + Vector2(80, 80), MOUSE_BUTTON_MIDDLE, false)
	await h.frames(3)
	h.check("Mend targeting blocks map drag", view.call("map_pan") == pan_before)
	h.check("Mend targeting keeps GridRoot fixed", grid.position == root_before)
	h.check("blocked drag never latches", not bool(view.call("map_dragging")))
	await h.click_view(view.call("cell_center", EMPTY_CELL), MOUSE_BUTTON_RIGHT)

	# Final target ritual: arming is state-free, exactly one ally is highlighted.
	var targeting_hash := model.state_hash()
	await h.click_view(view.call("cell_center", HEALER_CELL))
	var targets := bar.find_children("HealTarget_*", "Polygon2D", true, false)
	h.check("healer click enters target mode", bar.is_mend_targeting())
	h.check("entering target mode is hash-equal", model.state_hash() == targeting_hash)
	h.check("injured ally is highlighted", targets.size() == 1, "targets=%d" % targets.size())
	await h.shot("mend_targeting")

	var hp_before := defender.hp
	var hash_before := model.state_hash()
	await h.click_view(view.call("cell_center", DEFENDER_CELL))
	h.check("target click changes model state", model.state_hash() != hash_before)
	h.check(
		"Mend heals exactly 60 HP",
		defender.hp == hp_before + 60,
		"%d -> %d" % [hp_before, defender.hp],
	)
	h.check("Mend spends all SP", healer.sp == 0, "sp=%d" % healer.sp)
	h.check("Mend records target id", healer.skill_target_unit_id == defender.id)
	h.check("one skill fired", model.skills_fired == 1, "skills=%d" % model.skills_fired)
	h.check("valid target exits target mode", not bar.is_mend_targeting())

	# Target-side presentation: detect by model edge, capture, then prove decay.
	await h.frames(2)
	var center: Vector2 = view.call("cell_center", DEFENDER_CELL)
	var probe := Rect2i(int(center.x) - 70, int(center.y) - 70, 140, 140)
	var image_live := await h.shot_grab("mend_effect")
	h.check_pixels(
		"mint heal burst appears at the healed ally",
		image_live,
		func(image: Image) -> bool:
			return SelfTestProbes.color_in_rect(image, probe, cfg.heal_burst_color, 0.05) > 12,
	)
	await h.frames(cfg.heal_burst_frames + 4)
	var image_gone := await h.shot_grab("mend_decay")
	h.check_pixels(
		"mint heal burst expires after its frame budget",
		image_gone,
		func(image: Image) -> bool:
			return SelfTestProbes.color_in_rect(image, probe, cfg.heal_burst_color, 0.05) < 2,
	)
	h.check("healed HP survives visual decay", defender.hp == hp_before + 60)

	# Existing instant skills still fire from one unit click.
	var defender_sp_before := defender.sp
	await h.click_view(view.call("cell_center", DEFENDER_CELL))
	h.check("legacy non-healer click fires instantly", defender.sp < defender_sp_before)
	h.check("legacy skill increments count once", model.skills_fired == 2)

	# Recharge boundary remains exact for the same deployed healer.
	model.step(299)
	h.check("same healer has 9 SP after 299 ticks", healer.sp == 9, "sp=%d" % healer.sp)
	h.check("same healer has 29 progress", healer.sp_progress == 29)
	model.step()
	h.check("same healer is full at 300 ticks", healer.sp == healer.sp_cost)

	await h.frames(2)
	var mend_sfx := 0
	for event: Dictionary in telemetry.get("_events"):
		if event["name"] == "sfx_played" and String(event["data"]["id"]) == "mend":
			mend_sfx += 1
	h.check("Mend plays one routed SFX", mend_sfx == 1, "events=%d" % mend_sfx)
	h.done()


func _send_button(position: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _send_motion(position: Vector2, relative: Vector2, middle_pressed: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.device = SelfTestHarness.SYNTHETIC_DEVICE
	event.position = position
	event.global_position = position
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE if middle_pressed else 0
	Input.parse_input_event(event)
	Input.flush_buffered_events()
