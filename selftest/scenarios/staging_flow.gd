extends RefCounted

## P15 focused route/UI proof. Raw input validates each new surface once;
## campaign_flow retains the real CLEAR/progression proof and resign_flow keeps
## quick-mode separation.

const FUTURE_BUTTONS: Array[String] = [
	"BarracksButton",
	"RecruitButton",
	"TrainingButton",
	"ArmoryButton",
	"MemorialButton",
]
const VIEWPORT_RECT := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1400
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()
	var staging := await _open_initial_staging(h, game)
	if staging == null:
		return
	var initial := _snapshot(game)
	await _check_initial_staging(h, game, staging, initial)
	await h.shot("staging_initial")
	staging = await _mission_round_trip(h, game, staging, initial)
	if staging == null:
		return
	staging = await _defeat_round_trip(h, game, initial)
	if staging == null:
		return
	if not await _return_to_title(h, game, staging):
		return
	h.done()


func _open_initial_staging(h: SelfTestHarness, game: Node) -> Control:
	var title := game.get("content") as Control
	var campaign_button := title.find_child("CampaignButton", true, false) as Button
	h.check("Campaign button exists", campaign_button != null)
	if campaign_button == null:
		return null
	await h.click_view(campaign_button.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("Campaign opens Staging", staging != null)
	return staging


func _mission_round_trip(
		h: SelfTestHarness, game: Node, staging: Control, initial: Dictionary,
) -> Control:
	var mission := _find(staging, "MissionControlButton") as Button
	await h.click_view(mission.get_global_rect().get_center())
	var stage_select := await _await_screen(h, game, "StageColumn")
	h.check("Mission Control opens stage select", stage_select != null)
	if stage_select == null:
		return null
	h.check("Stage s1 is available", _find(stage_select, "Stage_s1") != null)
	await h.shot("staging_to_missions")
	var back := _find(stage_select, "BackToStaging") as Button
	h.check("stage select offers Back to Staging", back != null)
	if back == null:
		return null
	await h.click_view(back.get_global_rect().get_center())
	var returned := await _await_screen(h, game, "StagingRoot")
	h.check("Back returns to Staging", returned != null)
	if returned != null:
		_check_snapshot(h, game, initial, "stage-select return")
	return returned


func _defeat_round_trip(
		h: SelfTestHarness, game: Node, initial: Dictionary,
) -> Control:
	game.set("last_result", {
		"stage_id": &"s1", "result": BattleModel.Result.DEFEAT, "stars": 0,
		"leaks": 3, "kills": 0, "rewards_granted": [],
	})
	game.call("open_results")
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("campaign defeat results opened", results != null)
	if results == null:
		return null
	var headline := _find(results, "Headline") as Label
	h.check(
		"campaign result reads DEFEAT",
		headline != null and headline.text == "DEFEAT",
	)
	var return_button := _find(results, "ReturnToStaging") as Button
	h.check("campaign defeat offers Return to Staging", return_button != null)
	if return_button == null:
		return null
	await h.shot("results_return_to_staging")
	await h.click_view(return_button.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("defeat returns to Staging", staging != null)
	if staging != null:
		_check_snapshot(h, game, initial, "defeat return")
	return staging


func _return_to_title(h: SelfTestHarness, game: Node, staging: Control) -> bool:
	var back := _find(staging, "BackToTitleButton") as Button
	h.check("Staging offers Back to Title", back != null)
	if back == null:
		return false
	await h.click_view(back.get_global_rect().get_center())
	var title := await _await_screen(h, game, "TitleBox")
	h.check("Back to Title reaches title", title != null)
	h.check("Back to Title clears campaign", game.get("campaign") == null)
	h.check("Back to Title clears campaign mode", not bool(game.get("campaign_active")))
	h.check("Back to Title clears stage", game.get("selected_stage_id") == &"")
	h.check("Back to Title clears squad", (game.get("selected_squad") as Array).is_empty())
	return title != null


func _check_initial_staging(
		h: SelfTestHarness, game: Node, staging: Control, initial: Dictionary,
) -> void:
	for node_name: String in [
		"StagingHeading", "CampaignSummary", "NextMissionSummary",
		"MissionControlButton", "BarracksButton", "RecruitButton",
		"TrainingButton", "ArmoryButton", "MemorialButton",
		"BackToTitleButton", "OperationStatus",
	]:
		h.check(
			"Staging node %s exists" % node_name,
			_find(staging, node_name) != null,
		)

	var summary := _find(staging, "CampaignSummary") as Label
	var next_mission := _find(staging, "NextMissionSummary") as Label
	var status := _find(staging, "OperationStatus") as Label
	h.check(
		"campaign summary starts at 0/8",
		summary.text.contains("0/8"), summary.text,
	)
	h.check(
		"next mission names First Stand",
		next_mission.text.contains("First Stand"), next_mission.text,
	)
	h.check(
		"operation status marks future work unavailable",
		status.text.contains("UNAVAILABLE"), status.text,
	)
	h.check("Staging has no stage rows", _find(staging, "StageColumn") == null)
	h.check("Staging has no results panel", _find(staging, "ResultsColumn") == null)

	var shell := _find(staging, "StagingShell") as Control
	h.check("Staging shell exists", shell != null)
	if shell != null:
		var shell_rect := shell.get_global_rect()
		h.check(
			"Staging shell width is 1080",
			is_equal_approx(shell_rect.size.x, 1080.0), str(shell_rect.size),
		)
		h.check(
			"Staging shell height is 620",
			is_equal_approx(shell_rect.size.y, 620.0), str(shell_rect.size),
		)
		h.check("Staging shell fits the viewport", VIEWPORT_RECT.encloses(shell_rect), str(shell_rect))

	var heading := _find(staging, "StagingHeading") as Label
	var mission := _find(staging, "MissionControlButton") as Button
	var back := _find(staging, "BackToTitleButton") as Button
	h.check("heading meets 48px floor", heading.get_theme_font_size("font_size") >= 48)
	h.check("Mission Control is enabled", not mission.disabled)
	h.check("Back to Title is enabled", not back.disabled)
	h.check("Mission Control meets 32px floor", mission.get_theme_font_size("font_size") >= 32)
	h.check("detail text meets 24px floor", summary.get_theme_font_size("font_size") >= 24)

	for button_name: String in FUTURE_BUTTONS:
		var button := _find(staging, button_name) as Button
		h.check("%s is disabled" % button_name, button.disabled)
		h.check("%s is unfocusable" % button_name, button.focus_mode == Control.FOCUS_NONE)
		h.check("%s says unavailable" % button_name, button.text.contains("Unavailable"), button.text)
		h.check("%s lies inside viewport" % button_name, VIEWPORT_RECT.encloses(button.get_global_rect()))
		await h.click_view(button.get_global_rect().get_center())
		h.check("%s click keeps Staging open" % button_name, game.get("content") == staging)
		_check_snapshot(h, game, initial, "%s disabled click" % button_name)


func _snapshot(game: Node) -> Dictionary:
	var campaign: CampaignState = game.get("campaign")
	return {
		"campaign": campaign,
		"stars": campaign.stage_stars.duplicate(true),
		"operators": campaign.unlocked_operators.duplicate(),
		"traps": campaign.unlocked_traps.duplicate(),
		"spells": campaign.unlocked_spells.duplicate(),
		"stage": game.get("selected_stage_id"),
		"squad": (game.get("selected_squad") as Array).duplicate(),
	}


func _check_snapshot(h: SelfTestHarness, game: Node, expected: Dictionary, label: String) -> void:
	var current := _snapshot(game)
	h.check("%s preserves campaign object" % label, current["campaign"] == expected["campaign"])
	h.check("%s preserves stars" % label, current["stars"] == expected["stars"])
	h.check("%s preserves unlocks" % label, current["operators"] == expected["operators"] \
		and current["traps"] == expected["traps"] and current["spells"] == expected["spells"])
	h.check("%s preserves selection" % label, current["stage"] == expected["stage"] \
		and current["squad"] == expected["squad"])


func _find(screen: Control, node_name: String) -> Node:
	if screen.name == node_name:
		return screen
	return screen.find_child(node_name, true, false)


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
