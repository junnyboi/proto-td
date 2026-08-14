extends RefCounted

## Phase 5 scenario (td-phase-4-5.md §4.3): the S7 winning timeline rendered,
## plus the SP UI and trigger wiring. guard_2 blocks both heavies on
## test_skill; Overpower fires via the VERB at SP-full (~780) and the battle
## clears. vanguard_1 (parked off-lane) supplies the raw-input wiring check:
## one CLICK on the full-SP unit fires Rally through the same verb (rule 3 —
## input adapters validate once per verb). Falsifiable shot checklist:
## sp_fill shows a part-filled amber bar under the guard; sp_full shows it
## full-width and flashing; skill_flash shows the portrait quad top-center;
## battle_end HUD reads CLEAR. Telemetry: skills_fired == 2, sfx_played ids
## match both skills. ticks_per_frame_scale fast-forwards dull stretches
## (speed can never change outcomes — rule 6).

const SQUAD: Array[StringName] = [&"guard_2", &"vanguard_1"]
const GUARD_CELL := Vector2i(4, 2)
const VANGUARD_CELL := Vector2i(1, 4)
const RIGHT := int(UnitState.Facing.RIGHT)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 12_000
	await h.frames(10)
	var game := h.autoload("Game")
	game.set("default_squad", SQUAD)
	game.call("start_battle", &"test_skill")
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var hud := view.find_child("BattleHud", true, false) as Label
	h.expect_done()
	var telemetry := h.autoload("Telemetry")

	# deploy the guard at ~180 and the wiring-check vanguard at ~455
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 180:
		await h.physics_frames(1)
	h.check("guard deployed via seam", model.apply_action([&"deploy", &"guard_2", GUARD_CELL, RIGHT]))
	var guard := model.units[0]
	while model.tick < 455:
		await h.physics_frames(1)
	var van_ok := model.apply_action([&"deploy", &"vanguard_1", VANGUARD_CELL, RIGHT])
	h.check("vanguard deployed off-lane", van_ok)

	# SP pip fills: shot at ~half charge, then at full (flash state)
	while guard.sp < 10 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("guard SP half charged", guard.sp >= 10, "sp=%d tick=%d" % [guard.sp, model.tick])
	await h.frames(2)
	await h.shot("sp_fill")
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 740 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	while guard.sp < guard.sp_cost and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	h.check("guard SP full", guard.sp == guard.sp_cost, "tick=%d" % model.tick)
	await h.frames(2)
	await h.shot("sp_full")

	# PRIMARY: Overpower through the verb at the S7-pinned window
	var trigger_tick := model.tick
	h.check("Overpower verb accepted", model.apply_action([&"trigger_skill", guard.id]))
	h.check("trigger inside the winning window", trigger_tick <= 800, "tick=%d" % trigger_tick)
	h.check("SP bar resets after trigger", guard.sp == 0)
	h.check("effect applied", guard.active_effects.size() == 1)
	await h.frames(4)
	# Phase 9 item 2 upgrade (td-phase-9.md §4.5): pixel probes on the flash
	# quad + SP-fill node read + decay probe. Existing checks untouched.
	var cfg: JuiceConfig = view.get("cfg")
	var flash := view.find_child("PortraitFlash", true, false) as ColorRect
	var flash_rect := Rect2i(flash.get_global_rect())
	var flash_color := flash.color
	var img_flash := await h.shot_grab("skill_flash")
	h.check_pixels(
		"flash pixels fill the PortraitFlash region", img_flash,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, flash_rect, flash_color, 0.05) > 2_000,
	)
	var unit_nodes: Dictionary = view.get("_unit_nodes")
	var sp_fill := (unit_nodes[guard.id] as Node2D).get_node("Body/SpBarBg/SpBarFill") as ColorRect
	h.check("SP fill rect reset to zero width", sp_fill.size.x == 0.0, "w=%f" % sp_fill.size.x)
	await h.frames(cfg.skill_flash_frames + 4)
	var img_decay := await h.shot_grab("skill_flash_decay")
	h.check("flash node hidden after its frame budget", not flash.visible)
	h.check_pixels(
		"flash gone after its frame budget", img_decay,
		func(im: Image) -> bool:
			return _changed_pixels_in_rect(img_flash, im, flash_rect, 0.05) > 2_000,
	)

	# WIRING CHECK: one click on the full-SP vanguard fires Rally
	view.set("ticks_per_frame_scale", 4.0)
	var vanguard := model.units[1]
	while vanguard.sp < vanguard.sp_cost and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	var click_pos: Vector2 = view.call("cell_center", VANGUARD_CELL)
	await h.click_view(click_pos)
	h.check("click on full-SP unit fires the skill", vanguard.sp == 0, "sp=%d" % vanguard.sp)
	h.check("both skills fired", model.skills_fired == 2, "fired=%d" % model.skills_fired)

	# run out the battle: boosted guard kills both heavies
	view.set("ticks_per_frame_scale", 4.0)
	while model.result == BattleModel.Result.RUNNING and model.tick < 1400:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("battle clears", model.result == BattleModel.Result.CLEAR, "tick=%d" % model.tick)
	var tally := "killed=%d leaked=%d" % [model.killed, model.leaked]
	h.check("two kills, zero leaks", model.killed == 2 and model.leaked == 0, tally)
	var counters: Dictionary = telemetry.get("_counters")
	h.check("telemetry skills_fired == 2", int(counters.get("skills_fired", 0)) == 2)
	var sfx_ids: Array[String] = []
	for ev: Dictionary in telemetry.get("_events"):
		if ev["name"] == "sfx_played":
			sfx_ids.append(String(ev["data"]["id"]))
	var sfx_ok := sfx_ids.has("overpower") and sfx_ids.has("rally")
	h.check("sfx_played ids match both skills", sfx_ok, ", ".join(sfx_ids))
	var hud_text := hud.text if hud != null else "no hud"
	h.check("HUD shows CLEAR", hud != null and hud_text.contains("CLEAR"), hud_text)
	await h.frames(2)
	await h.shot("battle_end")
	h.done()


func _changed_pixels_in_rect(before: Image, after: Image, rect: Rect2i, tolerance: float) -> int:
	var image_rect := Rect2i(Vector2i.ZERO, before.get_size())
	var clipped := rect.intersection(image_rect).intersection(Rect2i(Vector2i.ZERO, after.get_size()))
	var changed := 0
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			var lhs := before.get_pixel(x, y)
			var rhs := after.get_pixel(x, y)
			var delta := maxf(absf(lhs.r - rhs.r), absf(lhs.g - rhs.g))
			delta = maxf(delta, maxf(absf(lhs.b - rhs.b), absf(lhs.a - rhs.a)))
			if delta > tolerance:
				changed += 1
	return changed
