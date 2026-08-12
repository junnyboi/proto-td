extends RefCounted

## Phase 13a scenario (td-phase-13.md §3): quick battle -> resign via the
## model seam (13a has no button yet) -> DEFEAT stamp -> the terminal
## Continue button now exists in QUICK mode too (the 13a fix — quick
## battles used to dead-end on the stamp) -> results screen (DEFEAT
## headline, Retry + Back to Title, no ContinueToMap) -> Back to Title
## resets the campaign session.
## Falsifiable shot checklist:
##   defeat_stamp    — dark band + DEFEAT text, Continue button below it
##   results_defeat  — DEFEAT headline + tallies, Retry and Back to Title
##   back_at_title   — title screen with Start/Campaign buttons
## Watchdog: 150 ticks at 4x (~75 physics frames) + 3 content swaps
## (<=120-frame polls) + shots/asserts ~= 550 worst case -> 1200 keeps 2x.

const RESIGN_TICK := 150  # mid-wave, before test_lane's first possible leak (~240)
const BAND_COLOR := Color("1a1c2c")


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()

	# title -> quick battle (raw click on StartButton)
	var title := game.get("content") as Control
	var start_btn := title.find_child("StartButton", true, false) as Button
	h.check("start button on the title", start_btn != null)
	if start_btn == null:
		return
	await h.click_view(start_btn.get_global_rect().get_center())
	var model := await _await_battle(h, game)
	h.check("quick battle started", model != null)
	if model == null:
		return
	h.check("quick battle is non-campaign", not bool(game.get("campaign_active")))
	var view := game.get("content") as Node2D

	# run to the pinned resign tick, then concede through the verb seam
	view.set("ticks_per_frame_scale", 4.0)
	while model.tick < RESIGN_TICK and model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(1)
	view.set("ticks_per_frame_scale", 1.0)
	h.check(
		"still running at the resign tick", model.result == BattleModel.Result.RUNNING,
		"tick=%d result=%d" % [model.tick, model.result],
	)
	h.check("resign accepted", model.apply_action([&"resign"]))
	h.check("DEFEAT immediately (DC1)", model.result == BattleModel.Result.DEFEAT)
	h.check("resign is a 0-star defeat", model.stars == 0)

	# stamp edge: DEFEAT band + the quick-mode Continue button
	await h.frames(4)
	var stamp_label := view.find_child("ResultStampLabel", true, false) as Label
	h.check("stamp shows DEFEAT", stamp_label != null and stamp_label.text == "DEFEAT")
	var last: Dictionary = game.get("last_result")
	h.check("no rewards granted in quick mode", (last["rewards_granted"] as Array).is_empty())
	var stamp := view.find_child("ResultStamp", true, false) as ColorRect
	var img := await h.shot_grab("defeat_stamp")
	if stamp != null:
		var band_rect := Rect2i(stamp.get_global_rect())
		h.check_pixels(
			"defeat band pixels present", img,
			func(im: Image) -> bool:
				return SelfTestProbes.color_in_rect(im, band_rect, BAND_COLOR, 0.05) > 2000,
		)
	var continue_btn := view.find_child("ContinueButton", true, false) as Button
	h.check("Continue button exists in quick mode", continue_btn != null)
	if continue_btn == null:
		return

	# -> results: DEFEAT actions are Retry + Back to Title only
	await h.click_view(continue_btn.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("results opened from a quick battle", results != null)
	if results == null:
		return
	var headline := results.find_child("Headline", true, false) as Label
	h.check("headline reads DEFEAT", headline != null and headline.text == "DEFEAT")
	h.check("retry offered", results.find_child("RetryButton", true, false) != null)
	var back_btn := results.find_child("BackToTitle", true, false) as Button
	h.check("back to title offered", back_btn != null)
	h.check(
		"no ContinueToMap outside a campaign",
		results.find_child("ContinueToMap", true, false) == null,
	)
	h.check(
		"no ReturnToStaging outside a campaign",
		results.find_child("ReturnToStaging", true, false) == null,
	)
	await h.shot("results_defeat")
	if back_btn == null:
		return

	# -> title: session reset (squad/stage/campaign cleared)
	await h.click_view(back_btn.get_global_rect().get_center())
	var back := await _await_screen(h, game, "TitleBox")
	h.check("title reached", back != null)
	h.check("campaign cleared", game.get("campaign") == null)
	h.check("selected squad cleared", (game.get("selected_squad") as Array).is_empty())
	await h.shot("back_at_title")
	h.done()


## Awaits the deferred battle swap and returns the live model (null on
## timeout) — the battle view is a Node2D, so the Control marker poll
## doesn't apply here.
func _await_battle(h: SelfTestHarness, game: Node) -> BattleModel:
	var budget := 120
	while budget > 0:
		var model: BattleModel = game.get("current_battle")
		var content := game.get("content") as Node
		if model != null and content != null and content is Node2D:
			await h.frames(3)
			return model
		budget -= 1
		await h.frames(1)
	return null


## Awaits the deferred content swap and returns the new screen (null on
## timeout) — nodes are only fetched after the swap lands.
func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) \
				and content is Control and content.find_child(marker, true, false) != null:
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
