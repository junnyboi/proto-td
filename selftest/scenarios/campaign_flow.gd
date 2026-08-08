extends RefCounted

## Phase 10 scenario (td-phase-10.md §5): title -> Campaign -> stage select
## (locks) -> squad select (picks, counter, empty loadout) -> S1 battle
## (bot_stage_01's timeline through the seam) -> Continue -> results (stars,
## reward reveal) -> stage select (progress) -> s2 squad select (guard_2
## present, spike still absent — it unlocks at s2's clear, not before).
## Raw input once per new surface; every screen node fetched only after the
## deferred swap lands (the P9 null-rect lesson); completion sentinel on.

const PICKS: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 3000
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()

	# title -> Campaign (raw click)
	var title := game.get("content") as Control
	var campaign_btn := title.find_child("CampaignButton", true, false) as Button
	h.check("campaign button on the title", campaign_btn != null)
	if campaign_btn == null:
		return
	await h.click_view(campaign_btn.get_global_rect().get_center())
	var select := await _await_screen(h, game, "StageColumn")
	h.check("stage select opened", select != null)
	if select == null:
		return

	# locks: exactly s1 unlocked, s2 dimmed and click is a no-op
	var rows := 0
	for stage_id: StringName in game.call("campaign_stage_ids"):
		var row := select.find_child("Stage_%s" % stage_id, true, false) as Button
		if row != null:
			rows += 1
			var should_lock := stage_id != &"s1"
			h.check(
				"row %s lock state" % stage_id, row.disabled == should_lock,
				"disabled=%s" % row.disabled,
			)
	h.check("eight campaign rows", rows == 8)
	var s2_row := select.find_child("Stage_s2", true, false) as Button
	await h.click_view(s2_row.get_global_rect().get_center())
	await h.frames(5)
	h.check("locked row click is a no-op", game.get("content") == select)
	await h.shot("stage_select_locked")

	# s1 -> squad select (raw click)
	var s1_row := select.find_child("Stage_s1", true, false) as Button
	await h.click_view(s1_row.get_global_rect().get_center())
	var squad_screen := await _await_screen(h, game, "SquadColumn")
	h.check("squad select opened", squad_screen != null)
	if squad_screen == null:
		return
	var grid := squad_screen.find_child("OperatorGrid", true, false)
	h.check("exactly the five starting operators", grid.get_child_count() == 5)
	var start_btn := squad_screen.find_child("StartBattle", true, false) as Button
	h.check("StartBattle disabled before any pick", start_btn.disabled)
	for op_id: StringName in PICKS:
		var pick := squad_screen.find_child("Pick_%s" % op_id, true, false) as Button
		await h.click_view(pick.get_global_rect().get_center())
	var counter := squad_screen.find_child("PickCounter", true, false) as Label
	h.check("counter reads 3/3", counter.text.begins_with("3/3"), counter.text)
	var fourth := squad_screen.find_child("Pick_caster_1", true, false) as Button
	await h.click_view(fourth.get_global_rect().get_center())
	h.check("a fourth pick rejects", counter.text.begins_with("3/3"), counter.text)
	h.check("fourth button not stuck pressed", not fourth.button_pressed)
	var strip := squad_screen.find_child("LoadoutStrip", true, false) as Label
	h.check("loadout strip empty pre-unlocks", strip.text.contains("nothing unlocked"))
	h.check("StartBattle enabled after picks", not start_btn.disabled)
	await h.shot("squad_select")
	await _battle_and_progress(h, game, start_btn)


## Second half (own function to keep run() within the lint's return
## budget): S1 battle -> Continue -> results -> progress -> s2 gate.
func _battle_and_progress(h: SelfTestHarness, game: Node, start_btn: Button) -> void:
	await h.click_view(start_btn.get_global_rect().get_center())
	var budget := 120
	while budget > 0 and game.get("current_battle") == null:
		budget -= 1
		await h.frames(1)
	await h.frames(2)
	var model: BattleModel = game.get("current_battle")
	h.check("s1 booted", model != null and model.stage.id == &"s1")
	if model == null:
		return
	h.check("model squad == picked squad", model.squad == PICKS, str(model.squad))
	var view := game.get("content") as Node2D
	# loadout gating in the battle itself (audit F1): no spells unlocked at
	# S1 -> the spell bar must be EMPTY, not fail open to the full catalog
	var spell_box := view.find_child("SpellBox", true, false)
	h.check(
		"S1 spell bar empty (nothing unlocked)",
		spell_box != null and spell_box.get_child_count() == 0,
		"buttons=%d" % (spell_box.get_child_count() if spell_box != null else -1),
	)
	view.set("ticks_per_frame_scale", 0.0)
	var bot: StageBot = (load("res://playtests/bots/bot_stage_01.gd") as GDScript).new()
	var rows_tl: Array = bot.timeline()
	rows_tl.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var idx := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < 4000:
		while idx < rows_tl.size() and int(rows_tl[idx][0]) == model.tick:
			h.check(
				"s1 timeline action accepted",
				model.apply_action((rows_tl[idx] as Array).slice(1)),
			)
			idx += 1
		model.step()
		if model.tick % 300 == 0:
			await h.frames(1)
	h.check("s1 cleared", model.result == BattleModel.Result.CLEAR, "leaked=%d" % model.leaked)
	await h.frames(4)

	# terminal -> Continue button -> results
	var continue_btn := view.find_child("ContinueButton", true, false) as Button
	h.check("ContinueButton appeared (campaign active)", continue_btn != null)
	if continue_btn == null:
		return
	await h.click_view(continue_btn.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("results opened", results != null)
	if results == null:
		return
	var headline := results.find_child("Headline", true, false) as Label
	h.check("headline reads CLEAR", headline.text == "CLEAR")
	var stars_label := results.find_child("StarLine", true, false) as Label
	h.check(
		"star line matches the model", stars_label.text == "*".repeat(model.stars),
		"%s vs %d" % [stars_label.text, model.stars],
	)
	var reward_label := results.find_child("Reward0", true, false) as Label
	var guard_2 := load("res://data/operators/guard_2.tres") as OperatorDef
	h.check(
		"reward reveal names s1's reward", reward_label != null
		and reward_label.text.contains(guard_2.display_name), str(reward_label),
	)
	await h.shot("results_reward")

	# back to stage select: progress visible, s2 open
	var to_map := results.find_child("ContinueToMap", true, false) as Button
	await h.click_view(to_map.get_global_rect().get_center())
	var select2 := await _await_screen(h, game, "StageColumn")
	h.check("stage select re-opened", select2 != null)
	if select2 == null:
		return
	var s1_after := select2.find_child("Stage_s1", true, false) as Button
	h.check("s1 row shows stars", s1_after.text.contains("*"), s1_after.text)
	var s2_after := select2.find_child("Stage_s2", true, false) as Button
	h.check("s2 unlocked after the clear", not s2_after.disabled)
	await h.shot("stage_select_progress")

	# s2 squad select via seam: guard_2 present, spike_plate still absent
	game.set("selected_stage_id", &"s2")
	game.call("open_squad_select")
	var squad2 := await _await_screen(h, game, "SquadColumn")
	h.check("s2 squad select opened", squad2 != null)
	if squad2 == null:
		return
	var grid2 := squad2.find_child("OperatorGrid", true, false)
	h.check("guard_2 joined the grid (6 operators)", grid2.get_child_count() == 6)
	h.check(
		"guard_2 button present",
		squad2.find_child("Pick_guard_2", true, false) != null,
	)
	var strip2 := squad2.find_child("LoadoutStrip", true, false) as Label
	h.check(
		"spike still locked (unlocks at s2's clear, not before)",
		strip2.text.contains("nothing unlocked"), strip2.text,
	)
	h.done()


## Awaits the deferred content swap and returns the new screen (null on
## timeout) — nodes are only fetched after the swap lands (L4).
func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) \
				and content is Control and content.find_child(marker, true, false) != null:
			# let a layout pass position the fresh Controls before anyone
			# reads get_global_rect() for a click (unsettled rects overlap
			# at origin and rapid clicks land on the wrong button)
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
