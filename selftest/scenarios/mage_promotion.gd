extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VIEWPORT := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 1000
	h.root.size = VIEWPORT
	await h.frames(4)
	var game := h.autoload("Game")
	var support := SupportType.new()
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return
	var before := support.authority_facts(game)
	game.call("training_call", &"open", &"staging")
	var training := await support.await_screen(h, game, "TrainingRoot")
	h.check("v3 Recruit Training opens", training != null)
	if training == null:
		return
	var title := support.find(training, "TrainingTitleHeading") as Label
	var count := support.find(training, "PromotionReadyCount") as Label
	var target := support.find(
		training, "Recruit_%s" % prepared["target_id"],
	) as Button
	h.check("Training title exact", title != null and title.text == "TRAINING")
	h.check(
		"three real S1 survivors are promotion-ready",
		count != null and count.text.begins_with("3 ")
		and target != null and target.text.contains("XP 100 / 100")
		and target.text.contains("Promotion ready"),
	)
	var portrait := target.find_child("IdentityPortrait", true, false) as TextureRect
	h.check(
		"Recruit identity portrait is manifest-backed",
		portrait != null and portrait.texture != null,
	)
	await h.shot("training_roster")
	await support.ensure_visible(h, target)
	await h.click_view(target.get_global_rect().get_center())
	var view_paths := support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	var mage := support.find(training, "Path_mage_apprentice") as Button
	var defender := support.find(training, "Path_defender") as Button
	var gunner := support.find(training, "Path_gunner") as Button
	var shock := support.find(training, "Path_shock_trooper") as Button
	var sword := support.find(training, "Path_swordmaster") as Button
	h.check(
		"all five standard destination cards exist",
		mage != null and defender != null and gunner != null and shock != null and sword != null,
	)
	if mage == null:
		return
	var mage_heading := mage.find_child("AdvancedClassName", true, false) as Control
	await support.ensure_visible(h, mage_heading)
	await h.click_view(mage_heading.get_global_rect().get_center())
	await h.shot("training_paths_mage_apprentice")
	var choose := support.find(training, "ChoosePath") as Button
	await support.ensure_visible(h, choose)
	await h.click_view(choose.get_global_rect().get_center())
	await h.frames(3)
	h.check("drafting changes no campaign authority", support.authority_facts(game) == before)
	if await support.open_review(h, training) == null:
		return
	var entry := support.find(training, "Review_%s" % prepared["target_id"]) as Label
	h.check(
		"Review identifies the same Recruit and Mage Apprentice destination",
		entry != null and entry.text.contains("Mage Apprentice"),
	)
	var confirm := support.find(training, "ConfirmTraining") as Button
	var back := support.find(training, "ReviewBack") as Button
	h.check(
		"Review exposes explicit Back and Confirm actions",
		confirm != null and back != null and not confirm.disabled and not back.disabled,
	)
	await h.shot("training_review_mage_apprentice")
	await h.click_view(back.get_global_rect().get_center())
	await h.frames(3)
	h.check(
		"Review Back returns to class choice without mutation",
		training.call("mode") == &"paths" and support.authority_facts(game) == before,
	)
	print("MAGE_PROMOTION_COMPLETED")
	h.done()
