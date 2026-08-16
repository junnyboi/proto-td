extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VIEWPORT := Vector2i(960, 720)


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
	h.check("compact v3 Training opens", training != null)
	if training == null:
		return
	var shell := support.find(training, "TrainingScreenShell") as AetheriaScreenShell
	h.check(
		"compact shell selects compact landscape",
		shell != null and shell.layout_mode() == &"compact_landscape",
	)
	var view_paths := support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	var cards := support.find(training, "PathCards") as BoxContainer
	var scroll := support.find(training, "PathCardsScroll") as ScrollContainer
	var first := support.find(training, "Path_defender") as Button
	var last := support.find(training, "Path_swordmaster") as Button
	h.check(
		"compact five-choice board stacks in one bounded viewport",
		cards != null and cards.vertical and scroll != null
		and first != null and last != null,
	)
	if cards == null or scroll == null or first == null or last == null:
		return
	var first_heading := first.find_child("AdvancedClassName", true, false) as Control
	var last_heading := last.find_child("AdvancedClassName", true, false) as Control
	await support.ensure_visible(h, first_heading)
	var clip := scroll.get_global_rect().intersection(
		Rect2(Vector2.ZERO, Vector2(VIEWPORT)),
	)
	h.check(
		"compact first class heading is reachable",
		clip.has_point(first_heading.get_global_rect().get_center()),
	)
	await support.ensure_visible(h, last_heading)
	h.check(
		"compact fifth class heading is reachable",
		clip.has_point(last_heading.get_global_rect().get_center()),
	)
	await h.click_view(last_heading.get_global_rect().get_center())
	var choose := support.find(training, "ChoosePath") as Button
	var back := support.find(training, "PathBack") as Button
	await support.ensure_visible(h, choose)
	var viewport := Rect2(Vector2.ZERO, Vector2(VIEWPORT))
	h.check(
		"compact Back and Add to Plan centers are reachable",
		viewport.has_point(choose.get_global_rect().get_center())
		and viewport.has_point(back.get_global_rect().get_center()),
	)
	h.check("compact browsing changes no authority", support.authority_facts(game) == before)
	await h.shot("training_recruit_paths_compact")
	print("MAGE_PROMOTION_COMPACT_COMPLETED")
	h.done()
