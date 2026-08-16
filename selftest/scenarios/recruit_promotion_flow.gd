extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 2400
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	var game := h.autoload("Game")
	var support := SupportType.new()
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return
	var hero_id := String(prepared["target_id"])
	var second_id := String((prepared["eligible_ids"] as Array)[0])
	var second_before := support.hero_by_id(game, second_id)
	var results := await support.open_results_training(h, game)
	if results == null:
		return
	var available := support.find(results, "TrainingAvailable") as Label
	h.check(
		"Results reports the exact eligible Recruit count",
		available != null and available.text.contains("3"),
		available.text if available != null else "missing",
	)
	await support.ensure_visible(h, support.find(results, "TrainRecruits") as Control)
	await h.shot("recruit_promotion_results")
	var training := await support.open_training_from_results(h, game, results)
	if training == null:
		return
	h.check(
		"Training remembers Results return context",
		game.get("training_return_path") == &"results",
	)
	var ready_count := support.find(training, "PromotionReadyCount") as Label
	var target_row := support.find(training, "Recruit_%s" % hero_id) as Button
	h.check(
		"Training roster projects the persistent eligible Recruit",
		ready_count != null and ready_count.text.begins_with("3 ")
		and target_row != null and target_row.text.contains("XP 100 / 100")
		and target_row.text.contains("Promotion ready"),
		target_row.text if target_row != null else "missing",
	)
	await h.shot("recruit_promotion_roster")
	await support.ensure_visible(h, target_row)
	await h.click_view(target_row.get_global_rect().get_center())
	var paths := support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, paths)
	await h.click_view(paths.get_global_rect().get_center())
	await h.frames(3)
	var standard_ids := [
		"defender", "gunner", "mage_apprentice", "shock_trooper", "swordmaster",
	]
	var class_cards := 0
	for class_id: String in standard_ids:
		var card := support.find(training, "Path_%s" % class_id) as Button
		if card != null:
			class_cards += 1
			h.check(
				"%s card shows combat and equipment facts" % class_id,
				card.text.contains("DP") and card.text.contains("CLASS KIT"),
			)
	h.check("Recruit has exactly five standard class choices", class_cards == 5)
	h.check(
		"permanence warning is visible before drafting",
		support.find(training, "PermanentWarning") != null,
	)
	await h.shot("recruit_promotion_five_paths")
	var before_draft := support.authority_facts(game)
	var defender := support.find(training, "Path_defender") as Button
	var defender_heading := defender.find_child("AdvancedClassName", true, false) as Control
	await support.ensure_visible(h, defender_heading)
	await h.click_view(defender_heading.get_global_rect().get_center())
	var add := support.find(training, "ChoosePath") as Button
	await support.ensure_visible(h, add)
	await h.click_view(add.get_global_rect().get_center())
	await h.frames(3)
	h.check("draft selection does not mutate authority", support.authority_facts(game) == before_draft)
	var drafted_row := support.find(training, "Recruit_%s" % hero_id) as Button
	h.check("roster explicitly shows drafted class", drafted_row.text.contains("Planned: Defender"))
	if not await support.draft_choice(h, training, second_id, "gunner"):
		return
	h.check(
		"two-person draft still changes no authority",
		support.authority_facts(game) == before_draft,
	)
	var review := await support.open_review(h, training)
	if review == null:
		return
	var review_entry := support.find(training, "Review_%s" % hero_id) as Label
	var second_entry := support.find(training, "Review_%s" % second_id) as Label
	h.check(
		"Review maps two persistent callsigns to distinct classes",
		review_entry != null and review_entry.text.contains("Defender")
		and second_entry != null and second_entry.text.contains("Gunner"),
	)
	await h.shot("recruit_promotion_review")
	var review_back := support.find(training, "ReviewBack") as Button
	await h.click_view(review_back.get_global_rect().get_center())
	await h.frames(3)
	h.check("Review Back returns to the edited class path", training.call("mode") == &"paths")
	var path_back := support.find(training, "PathBack") as Button
	await support.ensure_visible(h, path_back)
	await h.click_view(path_back.get_global_rect().get_center())
	await h.frames(3)
	h.check(
		"Back preserves the local draft without mutation",
		support.authority_facts(game) == before_draft,
	)
	await support.open_review(h, training)
	var before_commit := support.authority_facts(game)
	var confirm := support.find(training, "ConfirmTraining") as Button
	var confirm_label := confirm.find_child("PresentationLabel", false, false) as Label
	h.check(
		"Confirm Training label fits its primary action",
		confirm_label != null
		and confirm_label.get_combined_minimum_size().x <= confirm.size.x,
	)
	await support.ensure_visible(h, confirm)
	await h.click_view(confirm.get_global_rect().get_center())
	var staging := await support.await_screen(h, game, "StagingRoot")
	h.check("accepted promotion returns to Staging", staging != null)
	if staging == null:
		return
	var after := support.hero_by_id(game, hero_id)
	var second_after := support.hero_by_id(game, second_id)
	var before_person: Dictionary = prepared["target_before"]
	h.check(
		"one durable revision commits the entire batch",
		game.get("campaign").save_revision() == int(before_commit["revision"]) + 1,
	)
	h.check(
		"promotion preserves person identity and changes only duty projection",
		after["hero_id"] == before_person["hero_id"]
		and after["portrait_asset_id"] == before_person["portrait_asset_id"]
		and after["custom_callsign"] == before_person["custom_callsign"]
		and after["current_class_id"] == "defender"
		and after["operator_def_id"] == "defender_1",
		str(after),
	)
	h.check(
		"atomic batch preserves the second person and applies Gunner",
		second_after["hero_id"] == second_before["hero_id"]
		and second_after["portrait_asset_id"] == second_before["portrait_asset_id"]
		and second_after["current_class_id"] == "gunner"
		and second_after["operator_def_id"] == "sniper_1",
		str(second_after),
	)
	h.check(
		"exactly one promotion receipt was appended",
		game.get("campaign").data_copy()["promotion_receipts"].size()
		== (before_commit["receipts"] as Array).size() + 1,
	)
	var acknowledgement := support.find(staging, "TrainingAcknowledgement") as Label
	h.check(
		"Staging acknowledges both accepted callsign-to-class mappings once",
		acknowledgement != null and acknowledgement.text.contains("Defender")
		and acknowledgement.text.contains("Gunner"),
		acknowledgement.text if acknowledgement != null else "missing",
	)
	h.check(
		"acknowledgement transient is consumed after visible projection",
		(game.call("training_call", &"peek_acknowledgement") as Array).is_empty(),
	)
	await support.ensure_visible(h, acknowledgement)
	await h.shot("recruit_promotion_staging_acknowledgement")
	print("RECRUIT_PROMOTION_FLOW_COMPLETED")
	h.done()
