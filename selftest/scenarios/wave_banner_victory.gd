extends RefCounted

## Phase 9 item 5 (td-phase-9.md §4.4). Two-wave winnable stage
## (wave_starts [0, 300]): the banner appears at both crossings (incl. the
## tick-0 banner) and is gone after its frame budget; a lone guard clears
## with 0 leaks -> 3 stars, and the victory stamp renders exactly
## model.stars star polygons (node read) + star pixels (probe). A second,
## headless-only run drives a DEFEAT (leak_limit 0) and asserts the DEFEAT
## stamp + sfx counts. Deploys funded via the P8 debug verb (§1.4 K3).

const GUARD_CELL := Vector2i(3, 2)
const LABEL_TEXT_COLOR := Color(0.875, 0.875, 0.875)
const STAR_COLOR := Color("f4b41b")


func run(h: SelfTestHarness) -> void:
	h.max_frames = 4200
	await h.frames(10)
	var game := h.autoload("Game")
	var telemetry := h.autoload("Telemetry")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	stage.wave_starts = PackedInt32Array([0, 300])
	var waves: Array[Dictionary] = [
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 360, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 390, "enemy_id": &"grunt", "path_idx": 0},
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
	h.expect_done()
	var juice := view.find_child("JuiceLayer", true, false)
	model.apply_action([&"debug_set_dp", 99])
	model.apply_action([&"debug_grant_operator", &"guard_1"])
	h.check(
		"guard deployed at the choke",
		model.apply_action([&"deploy", &"guard_1", GUARD_CELL, int(UnitState.Facing.RIGHT)]),
	)

	# banner 1: the tick-0 crossing
	await h.frames(3)
	h.check("wave-1 banner visible at battle start", juice.call("banner_visible"))
	var back := (juice as Node).find_child("WaveBannerBack", true, false) as ColorRect
	var img_b1 := await h.shot_grab("wave_banner_1")
	var banner_rect := Rect2i(back.get_global_rect())
	h.check_pixels(
		"banner text pixels present", img_b1,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, banner_rect, LABEL_TEXT_COLOR, 0.12) > 100,
	)
	await h.frames(cfg.wave_banner_frames + 15)
	h.check("banner gone after its frame budget", not juice.call("banner_visible"))

	# banner 2: the tick-300 crossing
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < 295 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	while model.spell_book.wave_index_of(model.tick) < 1 \
			and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	await h.frames(3)
	h.check("wave-2 banner visible at the crossing", juice.call("banner_visible"))
	await h.shot("wave_banner_2")

	# run to CLEAR: the guard holds and kills all four grunts
	view.set("ticks_per_frame_scale", 4.0)
	while model.result == BattleModel.Result.RUNNING and model.tick < 1500:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("battle clears with 0 leaks", model.result == BattleModel.Result.CLEAR
		and model.leaked == 0, "result=%d leaked=%d" % [model.result, model.leaked])
	h.check("3 stars", model.stars == 3)
	await h.frames(cfg.star_burst_stagger_frames * 3 + 6)
	var stamp := view.find_child("ResultStamp", true, false)
	var stamp_label := view.find_child("ResultStampLabel", true, false) as Label
	var stars := view.find_child("StampStars", true, false) as Node2D
	h.check("stamp shows CLEAR", stamp != null and stamp_label.text == "CLEAR")
	h.check(
		"stamp star count == model.stars",
		stars != null and stars.get_child_count() == model.stars,
		"children=%d stars=%d" % [stars.get_child_count(), model.stars],
	)
	var stars_center: Vector2 = stars.global_position
	var stars_probe := Rect2i(int(stars_center.x) - 90, int(stars_center.y) - 22, 180, 44)
	var img_stamp := await h.shot_grab("victory_stamp")
	h.check_pixels(
		"star pixels in the stamp", img_stamp,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, stars_probe, STAR_COLOR, 0.05) > 200,
	)
	var wave_events := _sfx_count(telemetry, "wave")
	h.check("sfx_played:wave == 2 crossings", wave_events == 2, "events=%d" % wave_events)
	h.check("sfx_played:victory == 1", _sfx_count(telemetry, "victory") == 1)

	# DEFEAT sub-run — headless only (no shots; keeps R4b wall clock sane)
	if DisplayServer.get_name() != "headless":
		h.done()
		return
	var defeats_before := _sfx_count(telemetry, "defeat")
	game.call("start_battle", game.get("default_stage_id"))
	var lose_stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var lose_waves: Array[Dictionary] = [{"tick": 30, "enemy_id": &"grunt", "path_idx": 0}]
	lose_stage.waves = lose_waves
	lose_stage.leak_limit = 0
	game.set("pending_stage", lose_stage)
	var budget := 120
	while budget > 0:
		var current: BattleModel = game.get("current_battle")
		if current != null and current != model:
			break
		budget -= 1
		await h.frames(1)
	var lose_model: BattleModel = game.get("current_battle")
	h.check("defeat battle started", lose_model != null and lose_model != model)
	var lose_view := game.get("content") as Node2D
	lose_view.set("ticks_per_frame_scale", 8.0)
	while lose_model.result == BattleModel.Result.RUNNING and lose_model.tick < 400:
		await h.physics_frames(1)
	h.check("the leak defeats at leak_limit 0", lose_model.result == BattleModel.Result.DEFEAT)
	await h.frames(3)
	var lose_label := lose_view.find_child("ResultStampLabel", true, false) as Label
	h.check("stamp shows DEFEAT", lose_label != null and lose_label.text == "DEFEAT")
	h.check("sfx_played:defeat == 1", _sfx_count(telemetry, "defeat") - defeats_before == 1)
	h.done()


func _sfx_count(telemetry: Node, id: String) -> int:
	var n := 0
	for ev: Dictionary in telemetry.get("_events"):
		if ev["name"] == "sfx_played" and String(ev["data"]["id"]) == id:
			n += 1
	return n
