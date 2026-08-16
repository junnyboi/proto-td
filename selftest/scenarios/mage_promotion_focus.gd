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
	h.check("focus v3 Training opens", training != null)
	if training == null:
		return
	var row := support.find(training, "Recruit_%s" % prepared["target_id"]) as Button
	var callsign := row.find_child("RecruitCallsign", true, false) as Control
	await _assert_focus_visible(h, row, callsign, "standard roster row")
	row.pressed.emit()
	var view_paths := support.find(training, "ViewPaths") as Button
	await _assert_focus_visible(h, view_paths, view_paths, "standard View Paths action")
	view_paths.pressed.emit()
	await h.frames(3)
	var first := support.find(training, "Path_defender") as Button
	var last := support.find(training, "Path_swordmaster") as Button
	first.grab_focus()
	await h.frames(2)
	for index: int in 4:
		await _press_action(h, &"ui_focus_next")
	var cards_scroll := support.find(training, "PathCardsScroll") as ScrollContainer
	var last_heading := last.find_child("AdvancedClassName", true, false) as Control
	h.check(
		"directional focus automatically scrolls fifth path into view",
		training.get_viewport().gui_get_focus_owner() == last
		and cards_scroll.get_global_rect().has_point(
			last_heading.get_global_rect().get_center(),
		),
		"focus=%s scroll=%s heading=%s" % [
			training.get_viewport().gui_get_focus_owner(), cards_scroll.get_global_rect(),
			last_heading.get_global_rect(),
		],
	)
	last.pressed.emit()
	var add := support.find(training, "ChoosePath") as Button
	var path_back := support.find(training, "PathBack") as Button
	await _assert_focus_visible(h, add, add, "standard Add action")
	await _assert_focus_visible(h, path_back, path_back, "standard path Back action")
	path_back.pressed.emit()
	await h.frames(3)
	if not await support.draft_choice(
		h, training, String(prepared["target_id"]), "defender",
	):
		return
	if await support.open_review(h, training) == null:
		return
	var error := support.find(training, "TrainingReviewError") as Control
	var back := support.find(training, "ReviewBack") as Button
	var confirm := support.find(training, "ConfirmTraining") as Button
	h.check(
		"Review owns one focus domain",
		error != null and back != null and confirm != null
		and support.find(training, "Path_defender") == null
		and support.find(training, "Recruit_%s" % prepared["target_id"]) == null,
	)
	if back == null or confirm == null:
		return
	await _assert_focus_visible(h, back, back, "standard Review Back action")
	await _assert_focus_visible(h, confirm, confirm, "standard Confirm action")
	confirm.grab_focus()
	await h.frames(2)
	var contained := true
	for action: StringName in [
		&"ui_focus_next", &"ui_focus_prev", &"ui_left", &"ui_right", &"ui_up", &"ui_down",
	]:
		await _press_action(h, action)
		var owner := training.get_viewport().gui_get_focus_owner()
		contained = contained and (owner == error or owner == back or owner == confirm)
	h.check("all directional focus stays inside Review", contained)
	h.check("focus stress dispatches no promotion", support.authority_facts(game) == before)
	await h.shot("training_review_focus")
	print("MAGE_PROMOTION_FOCUS_COMPLETED")
	h.done()


func _assert_focus_visible(
		h: SelfTestHarness, control: Control, target: Control, label: String,
	) -> void:
	control.get_viewport().gui_release_focus()
	await h.frames(1)
	control.grab_focus()
	await h.frames(4)
	var visible := control.get_viewport().gui_get_focus_owner() == control
	var parent := target.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			visible = visible and (parent as ScrollContainer).get_global_rect().has_point(
				target.get_global_rect().get_center(),
			)
		parent = parent.get_parent()
	h.check("%s focus auto-scrolls through ancestors" % label, visible)


func _press_action(h: SelfTestHarness, action: StringName) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = is_pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await h.frames(2)
