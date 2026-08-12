extends RefCounted

## TD-006 campaign-only resign proof: Start -> Staging -> seeded S1 campaign
## battle -> resign -> DEFEAT stamp -> Results. Retry returns to squad select;
## Return to Staging preserves the campaign; Back to Title resets the session.
## Falsifiable shot checklist:
##   defeat_stamp    — dark band + DEFEAT text, Continue button below it
##   results_defeat  — DEFEAT headline + Retry, Return to Staging, Back to Title
##   back_at_title   — title screen with exactly one Start button
## Watchdog: 150 ticks at 4x (~75 physics frames) + bounded content swaps +
## shots/asserts fit the existing measured 1200-frame budget.

const RESIGN_TICK := 150  # mid-wave, before s1's first possible leak
const BAND_COLOR := Color("1a1c2c")
const PICKS: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()

	var campaign_ref := await _start_campaign_battle(h, game)
	if campaign_ref == null:
		return
	var model := await _await_battle(h, game)
	h.check("campaign battle started", model != null and model.stage.id == &"s1")
	if model == null:
		return
	var results := await _resign_to_results(h, game, model)
	if results == null:
		return
	var staging := await _retry_then_return_to_staging(
		h, game, results, campaign_ref,
	)
	if staging == null:
		return
	if not await _return_to_title(h, game, staging):
		return
	h.done()


func _resign_to_results(
		h: SelfTestHarness, game: Node, model: BattleModel,
) -> Control:
	var view := game.get("content") as Node2D
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

	await h.frames(4)
	var stamp_label := view.find_child("ResultStampLabel", true, false) as Label
	h.check("stamp shows DEFEAT", stamp_label != null and stamp_label.text == "DEFEAT")
	var last: Dictionary = game.get("last_result")
	h.check("campaign defeat grants no rewards", (last["rewards_granted"] as Array).is_empty())
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
	h.check("Continue button exists for campaign defeat", continue_btn != null)
	if continue_btn == null:
		return null

	await h.click_view(continue_btn.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("results opened from campaign defeat", results != null)
	if results == null:
		return null
	var headline := results.find_child("Headline", true, false) as Label
	h.check("headline reads DEFEAT", headline != null and headline.text == "DEFEAT")
	var retry := results.find_child("RetryButton", true, false) as Button
	var return_btn := results.find_child("ReturnToStaging", true, false) as Button
	var back_btn := results.find_child("BackToTitle", true, false) as Button
	h.check("retry offered", retry != null)
	h.check("Return to Staging offered", return_btn != null)
	h.check("back to title offered", back_btn != null)
	await h.shot("results_defeat")
	if retry == null or return_btn == null or back_btn == null:
		return null
	return results


func _retry_then_return_to_staging(
		h: SelfTestHarness, game: Node, results: Control,
		campaign_ref: CampaignState,
) -> Control:
	var retry := results.find_child("RetryButton", true, false) as Button
	await h.click_view(retry.get_global_rect().get_center())
	var squad := await _await_screen(h, game, "SquadColumn")
	h.check("Retry returns to squad select", squad != null)
	h.check("Retry preserves campaign object", game.get("campaign") == campaign_ref)
	h.check("Retry preserves selected stage", game.get("selected_stage_id") == &"s1")
	if squad == null:
		return null

	game.call("open_results")
	results = await _await_screen(h, game, "ResultsColumn")
	h.check("campaign defeat results re-open", results != null)
	if results == null:
		return null
	var return_btn := results.find_child("ReturnToStaging", true, false) as Button
	h.check("Return to Staging survives result reopen", return_btn != null)
	if return_btn == null:
		return null
	await h.click_view(return_btn.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("campaign defeat returns to Staging", staging != null)
	h.check("Staging preserves campaign object", game.get("campaign") == campaign_ref)
	return staging


func _return_to_title(
		h: SelfTestHarness, game: Node, staging: Control,
) -> bool:
	var staging_back := staging.find_child("BackToTitleButton", true, false) as Button
	h.check("Staging offers Back to Title", staging_back != null)
	if staging_back == null:
		return false
	await h.click_view(staging_back.get_global_rect().get_center())
	var title := await _await_screen(h, game, "TitleBox")
	h.check("title reached", title != null)
	h.check("campaign cleared", game.get("campaign") == null)
	h.check("campaign mode cleared", not bool(game.get("campaign_active")))
	h.check("pending stage cleared", game.get("pending_stage") == null)
	h.check("battle model cleared", game.get("current_battle") == null)
	h.check("selected stage cleared", game.get("selected_stage_id") == &"")
	h.check("selected squad cleared", (game.get("selected_squad") as Array).is_empty())
	h.check("last result cleared", (game.get("last_result") as Dictionary).is_empty())
	if title == null:
		return false
	var start := title.find_child("StartButton", true, false) as Button
	var buttons: Array[Node] = title.find_children("*", "Button", true, false)
	h.check(
		"title has one Start action",
		start != null and start.text == "Start" and buttons.size() == 1,
		"buttons=%d" % buttons.size(),
	)
	h.check(
		"Campaign button remains absent",
		title.find_child("CampaignButton", true, false) == null,
	)
	await h.shot("back_at_title")
	return true


func _start_campaign_battle(h: SelfTestHarness, game: Node) -> CampaignState:
	var title := game.get("content") as Control
	var start := title.find_child("StartButton", true, false) as Button
	h.check("Start button on the title", start != null and start.text == "Start")
	h.check("Campaign button removed", title.find_child("CampaignButton", true, false) == null)
	if start == null:
		return null
	await h.click_view(start.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("Start opens campaign Staging", staging != null)
	var campaign: CampaignState = game.get("campaign")
	h.check("campaign is active", campaign != null and bool(game.get("campaign_active")))
	if staging == null or campaign == null:
		return null
	game.call("start_stage", &"s1", PICKS)
	return campaign


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


func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control \
				and (content.name == marker or content.find_child(marker, true, false) != null):
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
