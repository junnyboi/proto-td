extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 2200
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	var game := h.autoload("Game")
	var support := SupportType.new()
	if not await _run_case(h, game, support, false):
		return
	game.call("open_title")
	await h.frames(5)
	if not await _run_case(h, game, support, true):
		return
	print("RECRUIT_PROMOTION_STALE_RECONCILIATION_COMPLETED")
	h.done()


func _run_case(
	h: SelfTestHarness,
	game: Node,
	support: RecruitPromotionScenarioSupport,
	total: bool,
) -> bool:
	var context := await _prepare_review(h, game, support)
	if context.is_empty():
		return false
	var first_id := String(context["first_id"])
	var second_id := String(context["second_id"])
	var training := context["training"] as Control
	var concurrent: Array[Dictionary] = [
		{"hero_id": first_id, "to_class_id": "defender"},
	]
	if total:
		concurrent.append({"hero_id": second_id, "to_class_id": "gunner"})
	var committed := game.call("training_call", &"commit", concurrent) as Dictionary
	(
		h
		. check(
			"%s concurrent training durably commits" % _tag(total),
			bool(committed.get("accepted", false)),
			String(committed.get("error_code", "missing")),
		)
	)
	if not bool(committed.get("accepted", false)):
		return false
	(support.find(training, "ConfirmTraining") as Button).pressed.emit()
	await h.frames(5)
	_check_stale_review(h, training, support, first_id, total)
	_check_reconciled_draft(h, training, support, second_id, total)
	return true


func _prepare_review(
	h: SelfTestHarness,
	game: Node,
	support: RecruitPromotionScenarioSupport,
) -> Dictionary:
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return {}
	var first_id := String(prepared["target_id"])
	var second_id := String((prepared["eligible_ids"] as Array)[0])
	game.call("training_call", &"open", &"staging")
	var training := await support.await_screen(h, game, "TrainingRoot")
	if training == null:
		return {}
	if not await support.draft_choice(h, training, first_id, "defender"):
		return {}
	if not await support.draft_choice(h, training, second_id, "gunner"):
		return {}
	if await support.open_review(h, training) == null:
		return {}
	return {"first_id": first_id, "second_id": second_id, "training": training}


func _check_stale_review(
	h: SelfTestHarness,
	training: Control,
	support: RecruitPromotionScenarioSupport,
	first_id: String,
	total: bool,
) -> void:
	var error := support.find(training, "TrainingReviewError") as Label
	var removed := support.find(training, "Removed_%s" % first_id) as Label
	(
		h
		. check(
			"%s stale rejection stays in focused Review with removed assignment" % _tag(total),
			(
				training.call("mode") == &"review"
				and error != null
				and not error.text.is_empty()
				and removed != null
				and training.get_viewport().gui_get_focus_owner() == error
			),
		)
	)


func _check_reconciled_draft(
	h: SelfTestHarness,
	training: Control,
	support: RecruitPromotionScenarioSupport,
	second_id: String,
	total: bool,
) -> void:
	var draft := training.get("_draft") as Dictionary
	var confirm := support.find(training, "ConfirmTraining") as Button
	if total:
		(
			h
			. check(
				"total stale invalidation keeps explanation and disables confirmation",
				(
					draft.is_empty()
					and confirm.disabled
					and support.find(training, "Removed_%s" % second_id) != null
				),
			)
		)
	else:
		(
			h
			. check(
				"partial stale invalidation retains the still-legal assignment",
				(
					draft == {second_id: "gunner"}
					and not confirm.disabled
					and support.find(training, "Review_%s" % second_id) != null
				),
			)
		)


func _tag(total: bool) -> String:
	return "total" if total else "partial"
