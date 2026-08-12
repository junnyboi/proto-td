extends RefCounted

## POLISH-BOLT visual gate. Bolt travels the already-validated cast seam; this
## scenario owns the new presentation record, manifest texture, placement,
## present/absent pixels, and render-frame expiry. Observation convention:
## an accepted verb at tick T records T immediately; the view projects it on
## the next render _process. No model step is needed to reveal the effect.

const TARGET_CELL := Vector2i(3, 2)
const PROBE_COLOR := Color("ffe9b0")
const NATIVE_EFFECT_PX := 48.0


func run(h: SelfTestHarness) -> void:
	h.max_frames = 600
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [
		{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0},
	]
	stage.waves = waves
	game.set("pending_stage", stage)
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null and model.stage == stage)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	var cfg: JuiceConfig = view.get("cfg")
	var center: Vector2 = view.call("cell_center", TARGET_CELL)
	var live_scale: float = view.call("grid_scale")
	var display_side := ceili(NATIVE_EFFECT_PX * cfg.bolt_impact_scale * live_scale)
	var probe := Rect2i(
		int(center.x) - display_side / 2,
		int(center.y) - display_side / 2,
		display_side,
		display_side,
	)

	var img_before := await h.shot_grab("bolt_impact_before")
	h.check_pixels(
		"probe color absent before Bolt",
		img_before,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, probe, PROBE_COLOR, 0.02) < 5,
	)

	var cast_tick := model.tick
	var hash_before := model.state_hash()
	h.check("Bolt cast accepted", model.apply_action([&"cast", &"bolt", TARGET_CELL]))
	h.check("accepted cast changes state", model.state_hash() != hash_before)
	h.check("Bolt record uses the cast entry tick", model.last_bolt_cast_tick == cast_tick)
	h.check("Bolt record preserves the exact target cell", model.last_bolt_cast_cell == TARGET_CELL)
	var semantics_unchanged := model.killed == 0 and model.spell_book.casts(&"bolt") == 1
	h.check("Bolt damage semantics untouched", semantics_unchanged)
	await h.frames(2)

	var impact := view.find_child("BoltImpact", true, false) as TextureRect
	h.check("manifest Bolt impact node is live", impact != null)
	if impact != null:
		var impact_center := impact.position + impact.pivot_offset
		h.check(
			"impact is centered on the recorded target cell",
			impact_center.distance_to(center) < 0.01,
			"impact=%s target=%s" % [impact_center, center],
		)
		var texture_size := impact.texture.get_size() if impact.texture != null else Vector2.ZERO
		h.check("manifest texture resolves at 48x48", texture_size == Vector2.ONE * NATIVE_EFFECT_PX)

	var img_live := await h.shot_grab("bolt_impact_live")
	h.check_pixels(
		"pale-gold Bolt pixels present at the target cell",
		img_live,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, probe, PROBE_COLOR, 0.02) > 20,
	)

	await h.frames(cfg.bolt_impact_frames + 4)
	var expired_node := view.find_child("BoltImpact", true, false) as TextureRect
	var juice := view.find_child("JuiceLayer", true, false) as JuiceLayer
	var remaining: Array = juice.get("_transients") if juice != null else []
	var child_state: Array[String] = []
	if juice != null:
		for child: Node in juice.get_children():
			child_state.append("%s:%d" % [child.name, child.get_instance_id()])
	var live_id := impact.get_instance_id() if impact != null and is_instance_valid(impact) else -1
	var expired_id := expired_node.get_instance_id() if expired_node != null else -1
	h.check(
		"Bolt impact node expires",
		expired_node == null,
		"frames=%d transients=%s live=%d expired=%d seen=%s children=%s" % [
			cfg.bolt_impact_frames,
			remaining,
			live_id,
			expired_id,
			view.get("_bolt_seen_tick"),
			child_state,
		],
	)
	var img_expired := await h.shot_grab("bolt_impact_expired")
	h.check_pixels(
		"Bolt pixels absent after the render-frame budget",
		img_expired,
		func(im: Image) -> bool:
			return SelfTestProbes.color_in_rect(im, probe, PROBE_COLOR, 0.02) < 5,
	)
	h.done()
