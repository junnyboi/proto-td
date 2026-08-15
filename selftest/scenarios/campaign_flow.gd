extends RefCounted

## Phase 10 + P15 + TD-006 scenario: title -> Start -> Staging -> stage select
## (locks) -> squad select (picks, counter, empty loadout) -> S1 battle
## (three frozen Recruit battle IDs) -> Continue -> results (stars, class
## entitlement) -> stage select (durable progress) -> s2 Recruit squad select.
## Raw input once per new surface; every screen node fetched only after the
## deferred swap lands (the P9 null-rect lesson); completion sentinel on.

const MAX_MODEL_TICKS := 2_400


func run(h: SelfTestHarness) -> void:
	h.max_frames = 2100
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()

	# title -> Start campaign (raw click)
	var title := game.get("content") as Control
	var title_start := title.find_child("StartButton", true, false) as Button
	h.check("Start button on the title", title_start != null and title_start.text == "Start")
	h.check(
		"Campaign button removed from the title",
		title.find_child("CampaignButton", true, false) == null,
	)
	if title_start == null:
		return
	await h.click_view(title_start.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("Start opens Staging", staging != null)
	if staging == null:
		return
	var campaign_uid := String(game.get("campaign").campaign_uid())
	game.call("open_stage_select")
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

	# s1 -> five distinct persistent Recruit cards (raw clicks)
	var s1_row := select.find_child("Stage_s1", true, false) as Button
	await h.click_view(s1_row.get_global_rect().get_center())
	var squad_screen := await _await_screen(h, game, "SquadColumn")
	h.check("squad select opened", squad_screen != null)
	if squad_screen == null:
		return
	var grid := squad_screen.find_child("OperatorGrid", true, false)
	var starters: Array = game.call("campaign_projection")["ready_heroes"]
	var starter_ids: Array[StringName] = []
	var starter_portraits := {}
	for hero: Dictionary in starters:
		starter_ids.append(StringName(hero["hero_id"]))
		starter_portraits[hero["portrait_asset_id"]] = true
	h.check(
		"exactly five distinct Recruit starters",
		grid.get_child_count() == 5 and starter_ids.size() == 5,
	)
	h.check("all starter classes are Recruit", _all_recruits(starters))
	h.check("five distinct starter portraits", starter_portraits.size() == 5)
	var squad_scroll := (
		squad_screen.find_child("SquadScroll", true, false) as ScrollContainer
	)
	var start_btn := squad_screen.find_child("StartBattle", true, false) as Button
	h.check("StartBattle disabled before any pick", start_btn.disabled)
	var picks: Array[StringName] = []
	for index: int in 3:
		picks.append(starter_ids[index])
	for hero_id: StringName in picks:
		var pick := squad_screen.find_child("Pick_%s" % hero_id, true, false) as Button
		squad_scroll.ensure_control_visible(pick)
		await h.frames(3)
		h.check(
			"Recruit card visible for real pick input",
			squad_scroll.get_global_rect().intersects(pick.get_global_rect()),
		)
		h.check("Recruit card hides internal hero ID", not pick.text.contains(String(hero_id)))
		await h.click_view(pick.get_global_rect().get_center())
	var counter := squad_screen.find_child("PickCounter", true, false) as Label
	h.check("counter reads 3/3", counter.text.begins_with("3/3"), counter.text)
	var fourth := squad_screen.find_child("Pick_%s" % starter_ids[3], true, false) as Button
	squad_scroll.ensure_control_visible(fourth)
	await h.frames(3)
	h.check(
		"fourth pick visible for real input",
		squad_scroll.get_global_rect().intersects(fourth.get_global_rect()),
	)
	await h.click_view(fourth.get_global_rect().get_center())
	h.check("a fourth pick rejects", counter.text.begins_with("3/3"), counter.text)
	h.check("fourth button not stuck pressed", not fourth.button_pressed)
	var strip := squad_screen.find_child("LoadoutStrip", true, false) as Label
	h.check("loadout strip empty pre-unlocks", strip.text.contains("nothing unlocked"))
	h.check("StartBattle enabled after picks", not start_btn.disabled)
	squad_scroll.ensure_control_visible(start_btn)
	await h.frames(3)
	h.check(
		"StartBattle visible for real input",
		squad_scroll.get_global_rect().intersects(start_btn.get_global_rect()),
	)
	await h.shot("squad_select")
	await _battle_and_progress(h, game, start_btn, campaign_uid, picks)


## Second half (own function to keep run() within the lint's return
## budget): S1 battle -> Continue -> results -> progress -> s2 gate.
func _battle_and_progress(
		h: SelfTestHarness, game: Node, start_btn: Button,
		campaign_uid: String, picks: Array[StringName],
	) -> void:
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
	var ticket: Dictionary = model.snapshot()["ticket"]
	var ticket_hero_ids: Array[StringName] = []
	for row: Dictionary in ticket["squad"]:
		ticket_hero_ids.append(StringName(row["hero_id"]))
	h.check("ticket hero identities == picked squad", ticket_hero_ids == picks, str(ticket_hero_ids))
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
	var rows_tl: Array = [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[180, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(1, 2), 0],
		[420, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(2, 2), 0],
	]
	var idx := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_MODEL_TICKS:
		while idx < rows_tl.size() and int(rows_tl[idx][0]) == model.tick:
			h.check(
				"s1 timeline action accepted",
				model.apply_action((rows_tl[idx] as Array).slice(1)),
			)
			idx += 1
		model.step()
		if model.tick % 300 == 0:
			await h.frames(1)
	h.check(
		"s1 cleared within pinned model budget",
		model.result == BattleModel.Result.CLEAR,
		"tick=%d/%d leaked=%d" % [model.tick, MAX_MODEL_TICKS, model.leaked],
	)
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
	var entitlement_label := results.find_child("Entitlement0", true, false) as Label
	h.check(
		"result reveals S1 class entitlement",
		entitlement_label != null
		and (game.get("last_result")["class_entitlements_granted"] as Array).has("sword_saint"),
		str(entitlement_label),
	)
	await h.shot("results_reward")

	# back through Staging: progress visible there, then s2 open in Mission Control
	var select2 := await _return_to_stage_select(h, game, results, campaign_uid)
	h.check("stage select re-opened", select2 != null)
	if select2 == null:
		return
	var s1_after := select2.find_child("Stage_s1", true, false) as Button
	h.check("s1 row shows stars", s1_after.text.contains("*"), s1_after.text)
	var s2_after := select2.find_child("Stage_s2", true, false) as Button
	h.check("s2 unlocked after the clear", not s2_after.disabled)
	await h.shot("stage_select_progress")

	# S2 survivors remain persistent people, not specialist rewards.
	game.set("selected_stage_id", &"s2")
	game.call("open_squad_select")
	var squad2 := await _await_screen(h, game, "SquadColumn")
	h.check("s2 squad select opened", squad2 != null)
	if squad2 == null:
		return
	var grid2 := squad2.find_child("OperatorGrid", true, false)
	var ready_after: Array = game.call("campaign_projection")["ready_heroes"]
	h.check(
		"S2 grid contains only ready persistent heroes",
		grid2.get_child_count() == ready_after.size(),
	)
	h.check("S1 granted no specialist person", _all_recruits(ready_after))
	var strip2 := squad2.find_child("LoadoutStrip", true, false) as Label
	h.check(
		"spike still locked (unlocks at s2's clear, not before)",
		strip2.text.contains("nothing unlocked"), strip2.text,
	)
	h.done()


func _return_to_stage_select(
		h: SelfTestHarness, game: Node, results: Control,
		campaign_uid: String,
) -> Control:
	var to_staging := results.find_child("ReturnToStaging", true, false) as Button
	h.check("campaign CLEAR offers Return to Staging", to_staging != null)
	if to_staging == null:
		return null
	var results_scroll := (
		results.find_child("ResultsScroll", true, false) as ScrollContainer
	)
	results_scroll.ensure_control_visible(to_staging)
	await h.frames(3)
	h.check(
		"Return to Staging visible for real input",
		results_scroll.get_global_rect().intersects(to_staging.get_global_rect()),
	)
	await h.shot("results_compact_action_row")
	await h.click_view(to_staging.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("Staging re-opened after clear", staging != null)
	if staging == null:
		return null
	h.check(
		"campaign identity preserved through Staging",
		String(game.get("campaign").campaign_uid()) == campaign_uid,
	)
	var summary := staging.find_child("CampaignSummary", true, false) as Label
	h.check("Staging summary exists", summary != null)
	if summary == null:
		return null
	h.check("Staging summary advances to 1/8", summary.text.contains("1/8"), summary.text)
	game.call("open_stage_select")
	return await _await_screen(h, game, "StageColumn")


func _all_recruits(heroes: Array) -> bool:
	for hero: Dictionary in heroes:
		if hero["operator_def_id"] != "recruit":
			return false
	return true


## Awaits the deferred content swap and returns the new screen (null on
## timeout) — nodes are only fetched after the swap lands (L4).
func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control \
				and (content.name == marker or content.find_child(marker, true, false) != null):
			# let a layout pass position the fresh Controls before anyone
			# reads get_global_rect() for a click (unsettled rects overlap
			# at origin and rapid clicks land on the wrong button)
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
