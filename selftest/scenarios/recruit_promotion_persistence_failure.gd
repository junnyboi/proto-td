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
	var results := await support.open_results_training(h, game)
	if results == null:
		return
	var training := await support.open_training_from_results(h, game, results)
	if training == null:
		return
	if not await support.draft_choice(h, training, hero_id, "defender"):
		return
	if await support.open_review(h, training) == null:
		return
	await _exercise_failure(h, game, support, training, prepared, hero_id)


func _exercise_failure(
	h: SelfTestHarness,
	game: Node,
	support: RecruitPromotionScenarioSupport,
	training: Control,
	prepared: Dictionary,
	hero_id: String,
) -> void:
	var before := support.authority_facts(game)
	var tmp_path := ProjectSettings.globalize_path("user://campaign_v1.tmp")
	var made := DirAccess.make_dir_absolute(tmp_path)
	h.check("production save fault is installed", made == OK, error_string(made))
	if made != OK:
		return
	var confirm := support.find(training, "ConfirmTraining") as Button
	await _assert_focus_visible(h, confirm, "standard Confirm action")
	await h.click_view(confirm.get_global_rect().get_center())
	await h.frames(5)
	var error := support.find(training, "TrainingReviewError") as Label
	var back := support.find(training, "ReviewBack") as Button
	var retry := support.find(training, "ConfirmTraining") as Button
	var retry_label := retry.find_child("PresentationLabel", false, false) as Label
	h.check(
		"save failure remains on Review with visible localized error",
		game.get("content") == training and training.call("mode") == &"review"
		and error != null and not error.text.is_empty(),
		error.text if error != null else "missing",
	)
	h.check(
		"save failure focus lands on the error and blocks escape",
		training.get_viewport().gui_get_focus_owner() == error
		and back != null and back.disabled and back.focus_mode == Control.FOCUS_NONE
		and retry != null and not retry.disabled,
	)
	h.check(
		"retry label fits its primary action",
		retry_label != null and retry_label.get_combined_minimum_size().x <= retry.size.x,
	)
	h.check(
		"failed persistence changes no campaign byte, hash, receipt, or hero row",
		support.authority_facts(game) == before,
	)
	h.check(
		"exact failed mutation remains pending for retry",
		bool(game.call("training_call", &"retry_pending")),
	)
	await h.shot("recruit_promotion_save_failure")
	var removed := DirAccess.remove_absolute(tmp_path)
	h.check("production save fault is removed", removed == OK, error_string(removed))
	if removed != OK:
		return
	await _assert_focus_visible(h, retry, "standard Retry action")
	await h.click_view(retry.get_global_rect().get_center())
	var staging := await support.await_screen(h, game, "StagingRoot")
	h.check("retry accepts and returns to Staging", staging != null)
	if staging == null:
		return
	var after := support.hero_by_id(game, hero_id)
	var before_person: Dictionary = prepared["target_before"]
	h.check(
		"retry commits exactly one revision and one receipt",
		game.get("campaign").save_revision() == int(before["revision"]) + 1
		and game.get("campaign").data_copy()["promotion_receipts"].size()
		== (before["receipts"] as Array).size() + 1,
	)
	h.check(
		"retry preserves identity and applies the exact drafted destination",
		after["hero_id"] == before_person["hero_id"]
		and after["portrait_asset_id"] == before_person["portrait_asset_id"]
		and after["custom_callsign"] == before_person["custom_callsign"]
		and after["current_class_id"] == "defender"
		and after["operator_def_id"] == "defender_1",
		str(after),
	)
	h.check(
		"retry clears pending ownership and publishes acknowledgement",
		not bool(game.call("training_call", &"retry_pending"))
		and support.find(staging, "TrainingAcknowledgement") != null,
	)
	await support.ensure_visible(
		h, support.find(staging, "TrainingAcknowledgement") as Control,
	)
	await h.shot("recruit_promotion_retry_success")
	print("RECRUIT_PROMOTION_PERSISTENCE_FAILURE_COMPLETED")
	h.done()


func _assert_focus_visible(
		h: SelfTestHarness, control: Control, label: String,
	) -> void:
	control.get_viewport().gui_release_focus()
	await h.frames(1)
	control.grab_focus()
	await h.frames(4)
	var visible := control.get_viewport().gui_get_focus_owner() == control
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			visible = visible and (parent as ScrollContainer).get_global_rect().has_point(
				control.get_global_rect().get_center(),
			)
		parent = parent.get_parent()
	h.check("%s focus auto-scrolls through ancestors" % label, visible)
