extends RefCounted

## Phase 8 scenario (td-phase-8.md §5) — acceptance #5: debug reaches
## everything. Sweeps EVERY StageDef on disk (directory scan, never a
## hardcoded list) and jumps to each; grants the full operator catalog and
## deploys a granted op through normal validation; asserts both traps
## placeable and every spell castable via model state; sets DP / base HP /
## spell cooldowns; pauses and fast-forwards through the view's speed seam.
## Raw input is validated once per surface (F12 key, one stage-jump button,
## the DP-max button); everything else drives the Debug seam methods (G6).

const OPERATOR_COUNT := 10
const TRAP_IDS: Array[StringName] = [&"spike_plate", &"tar_pit"]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 3600
	await h.frames(10)
	var game := h.autoload("Game")
	var debug := h.autoload("Debug")

	# raw F12 opens the overlay (the one raw-key validation)
	_send_f12()
	await h.frames(3)
	h.check("F12 opens the overlay", debug.call("is_open"))
	debug.call("toggle")
	await h.frames(2)
	h.check("seam toggle closes it", not debug.call("is_open"))
	debug.call("toggle")
	await h.frames(2)
	h.check("seam toggle reopens it", debug.call("is_open"))
	await h.shot("overlay_open")

	# stage sweep: every StageDef on disk is reachable (scan, count-guarded)
	var stage_ids: Array = game.call("stage_ids")
	h.check("stage scan is not vacuous (>= 3)", stage_ids.size() >= 3,
		"found %d" % stage_ids.size())
	var first := true
	for stage_id: StringName in stage_ids:
		var prev: BattleModel = game.get("current_battle")
		if first:
			# one stage jump through the real overlay button (raw click)
			var btn := (debug as Node).find_child("Jump_%s" % stage_id, true, false) as Button
			h.check("jump button exists for %s" % stage_id, btn != null)
			if btn == null:
				return
			await h.click_view(btn.get_global_rect().get_center())
			first = false
		else:
			debug.call("jump_to_stage", stage_id)
		var budget := 120
		while budget > 0:
			var current: BattleModel = game.get("current_battle")
			if current != null and current != prev and current.stage.id == stage_id:
				break
			budget -= 1
			await h.frames(1)
		var model: BattleModel = game.get("current_battle")
		var jumped := model != null and model != prev and model.stage.id == stage_id
		h.check("jumped to %s" % stage_id, jumped)
		if not jumped:
			return
		h.check("%s is RUNNING" % stage_id, model.result == BattleModel.Result.RUNNING)
		var tick_before: int = model.tick
		await h.physics_frames(10)
		h.check("%s is ticking" % stage_id, model.tick > tick_before)
		if stage_id == stage_ids[0]:
			await h.shot("overlay_battle")

	# grants: full operator catalog into the squad, on the last swept stage
	var model: BattleModel = game.get("current_battle")
	var op_ids: Array = debug.call("operator_ids")
	h.check("operator catalog holds all %d" % OPERATOR_COUNT, op_ids.size() == OPERATOR_COUNT)
	debug.call("grant_all_operators")
	await h.frames(2)
	h.check("squad holds the full catalog", model.squad.size() == op_ids.size(),
		"squad=%d" % model.squad.size())
	await h.shot("overlay_granted")

	# DP max through the real overlay button (raw click), then a granted op
	# deploys through the untouched validation path
	var dp_btn := (debug as Node).find_child("DpMax", true, false) as Button
	h.check("DP max button exists", dp_btn != null)
	if dp_btn == null:
		return
	await h.click_view(dp_btn.get_global_rect().get_center())
	await h.frames(2)
	h.check("DP set to cap", model.dp == model.config.dp_cap, "dp=%d" % model.dp)
	var deploy_cell := _first_deployable_cell(model, &"guard_1")
	h.check("granted guard_1 has a valid cell", deploy_cell.x >= 0)
	var deployed := model.apply_action(
		[&"deploy", &"guard_1", deploy_cell, int(UnitState.Facing.RIGHT)]
	)
	h.check("granted operator deploys via normal validation", deployed)
	h.check("the unit is fielded", model.alive_unit_at(deploy_cell) != null)

	# trap + spell reach (catalog-validated, td-phase-8.md §2.1)
	for trap_id: StringName in TRAP_IDS:
		h.check("%s placeable" % trap_id, model.is_trap_placeable(trap_id))
	h.check(
		"a trap cell validates",
		_first_trap_cell(model, TRAP_IDS[0]).x >= 0,
	)
	for spell_id: StringName in model.spell_book.ids:
		h.check("%s castable" % spell_id, model.is_castable(spell_id))
	h.check("bolt cast accepted", model.apply_action([&"cast", &"bolt", Vector2i(3, 2)]))
	h.check("bolt re-cast rejected", not model.apply_action([&"cast", &"bolt", Vector2i(3, 2)]))
	h.check("cooldown reset via verb", model.apply_action([&"debug_reset_spell", &"bolt"]))
	h.check("bolt castable again", model.is_castable(&"bolt"))

	# base-HP set via verb, read back through the snapshot
	h.check("base HP set", model.apply_action([&"debug_set_base_hp", 1]))
	h.check("readout shows base HP 1", int(model.snapshot()["base_hp"]) == 1)
	h.check("base HP restored", model.apply_action([&"debug_set_base_hp", 10]))

	# speed seam: pause freezes the model exactly; 4x resumes it
	var view: Node = game.get("content")
	debug.call("set_speed", 0.0)
	await h.frames(2)
	var frozen_tick: int = model.tick
	await h.physics_frames(20)
	h.check("pause freezes the model", model.tick == frozen_tick,
		"tick %d -> %d" % [frozen_tick, model.tick])
	debug.call("set_speed", 4.0)
	h.check("speed readback is 4x", float(view.get("ticks_per_frame_scale")) == 4.0)
	await h.physics_frames(10)
	h.check("4x is ticking", model.tick > frozen_tick)
	debug.call("set_speed", 1.0)


func _send_f12() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.device = SelfTestHarness.SYNTHETIC_DEVICE
		ev.keycode = KEY_F12
		ev.physical_keycode = KEY_F12
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()


func _first_deployable_cell(model: BattleModel, op_id: StringName) -> Vector2i:
	var size := model.stage.grid_size()
	for y: int in size.y:
		for x: int in size.x:
			if model.can_deploy_at(op_id, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _first_trap_cell(model: BattleModel, trap_id: StringName) -> Vector2i:
	var size := model.stage.grid_size()
	for y: int in size.y:
		for x: int in size.x:
			if model.can_place_trap_at(trap_id, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)
