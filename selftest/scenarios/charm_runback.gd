extends RefCounted

## Phase 7 scenario (td-phase-6-7.md §4.7). Bolt travels the full raw-input
## path once (spell button -> targeting cursor -> grid click casts on the
## press) — rule 3's once-per-verb validation; the charm cast goes through
## the seam. All battle asserts are model-state; the battle fast-forwards
## via the view's ticks-per-frame seam (E12) between interaction points.
## Timeline (test_lane, grunts @30/90/150/210/270): bolt kills g0 ~tick 120;
## g1/g2 leak (2 <= limit 3); g3 charmed ~tick 315 reverses and duels the
## oncoming g4 (~tick 345, mutual 5/30 cadence — the ally strikes first
## each ready tick, so it wins at 5 hp); g4's death leaves no ENEMY alive
## -> CLEAR while the ally is still mid-reversal (§2.4.11: charmed_exit
## never fires after terminal freeze — exit exactness is GUT-gated).

const GRUNT_STEP := 33_333


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
	var view := game.get("content") as Node2D
	var telemetry := h.autoload("Telemetry")

	var bar := view.find_child("SpellBar", true, false)
	var bolt_btn := bar.find_child("Spell_bolt", true, false) as Button
	var charm_btn := bar.find_child("Spell_charm", true, false) as Button
	h.check("both spell buttons present", bolt_btn != null and charm_btn != null)
	if bolt_btn == null or charm_btn == null:
		return
	await h.frames(2)
	h.check("bolt ready at battle start", not bolt_btn.disabled)
	h.check("charm shows its once-per-wave label", charm_btn.text.contains("1/wave"))

	# fast-forward until g0 is mid-lane, then cast bolt via the raw path:
	# button click -> targeting -> grid click (cast fires on the press)
	view.set("ticks_per_frame_scale", 8.0)
	while model.tick < 100 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	await h.click_view(bolt_btn.get_global_rect().get_center())
	var g0: EnemyState = model.enemies[0]
	var g0_cell := Pathing.cell_of(model.path_for(g0.path_idx), g0.progress_units)
	# grid clicks go through the view's cell_center seam (grid_root is
	# centered in the viewport; the harness's origin-anchored click_cell
	# would land ~5 cells off — same convention as trap_flow)
	await h.click_view(view.call("cell_center", g0_cell))
	await h.frames(3)
	h.check("bolt killed the grunt under the cursor", not g0.alive and model.killed >= 1)
	h.check(
		"bolt is on cooldown",
		model.spell_book.ready_at(&"bolt") > model.tick,
		"ready_at=%d tick=%d" % [model.spell_book.ready_at(&"bolt"), model.tick],
	)
	h.check("bolt button disabled while cooling", bolt_btn.disabled)
	await h.shot("bolt_cast")

	# charm g3 through the seam once it is on the field
	view.set("ticks_per_frame_scale", 8.0)
	while model.tick < 315 and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	var g3: EnemyState = model.enemies[3]
	var convert_progress := g3.progress_units
	h.check("seam charm accepted", model.apply_action([&"cast", &"charm", 3]))
	h.check("charm flipped the faction", g3.faction == EnemyState.Faction.CHARMED)
	h.check("charm counted", model.charmed == 1)
	await h.frames(3)
	h.check("charm button dimmed after use", charm_btn.disabled)
	await h.shot("charm_convert")

	# reversal: progress strictly decreasing at exactly the grunt step
	var t1 := model.tick
	var p1 := g3.progress_units
	await h.physics_frames(8)
	var t2 := model.tick
	var p2 := g3.progress_units
	h.check(
		"reversal moves backward at full speed",
		t2 > t1 and (p1 - p2) == GRUNT_STEP * (t2 - t1),
		"dp=%d dt=%d" % [p1 - p2, t2 - t1],
	)

	# the oncoming g4 engages: both freeze, mutual cadence, ally wins
	var g4: EnemyState = model.enemies[4]
	view.set("ticks_per_frame_scale", 8.0)
	while g3.engaged_with < 0 and model.tick < 420:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("duel engaged with the oncoming grunt", g3.engaged_with == 4 and g4.engaged_with == 3)
	h.check(
		"duel happens left of the conversion point",
		g3.progress_units < convert_progress,
		"duel_p=%d convert_p=%d" % [g3.progress_units, convert_progress],
	)
	var frozen_ally := g3.progress_units
	var frozen_enemy := g4.progress_units
	await h.physics_frames(6)
	h.check(
		"both duelists frozen",
		g3.progress_units == frozen_ally and g4.progress_units == frozen_enemy,
	)
	await h.shot("charm_duel")

	# run out the duel: the ally survives at 5 hp, g4's death clears the
	# stage while the ally is still walking back
	view.set("ticks_per_frame_scale", 8.0)
	while model.result == BattleModel.Result.RUNNING and model.tick < 700:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check("stage cleared", model.result == BattleModel.Result.CLEAR)
	h.check("ally won the mirror duel", not g4.alive and g3.alive and g3.hp == 5, "hp=%d" % g3.hp)
	h.check(
		"victory ignores the walk-back",
		model.alive_charmed_count() == 1 and model.charmed_exited == 0,
	)
	h.check("two leaks within limit", model.leaked == 2 and model.stars == 2)
	var counters: Dictionary = telemetry.get("_counters")
	h.check(
		"telemetry counted both casts and the charm",
		int(counters.get("spells_cast_bolt", 0)) == 1
			and int(counters.get("spells_cast_charm", 0)) == 1
			and int(counters.get("enemies_charmed", 0)) == 1,
		"bolt=%s charm=%s charmed=%s" % [
			counters.get("spells_cast_bolt"),
			counters.get("spells_cast_charm"),
			counters.get("enemies_charmed"),
		],
	)
	var events: Array = telemetry.get("_events")
	var sfx_ids: Array[String] = []
	var lifecycle: Array[String] = []
	for ev: Dictionary in events:
		if ev["name"] == "sfx_played":
			sfx_ids.append(str((ev["data"] as Dictionary).get("id")))
		elif str(ev["name"]).begins_with("charm_"):
			lifecycle.append(str(ev["name"]))
	h.check(
		"sfx wiring events fired for both spells",
		sfx_ids.has("bolt") and sfx_ids.has("charm"),
		",".join(sfx_ids),
	)
	h.check("charm_convert lifecycle event fired", lifecycle.has("charm_convert"))
	await h.frames(2)
	await h.shot("charm_victory")
