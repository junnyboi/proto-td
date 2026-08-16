extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VIEWPORT := Vector2i(720, 1280)


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
	h.check("portrait v3 Training opens", training != null)
	if training == null:
		return
	var shell := support.find(training, "TrainingScreenShell") as AetheriaScreenShell
	h.check(
		"portrait shell selects portrait mode",
		shell != null and shell.layout_mode() == &"portrait",
	)
	var row := support.find(training, "Recruit_%s" % prepared["target_id"]) as Control
	var roster_text_fit := row != null
	var roster_details: Array[String] = []
	for node_name: String in ["Callsign", "CurrentClass", "XpProgress", "EligibilityReason"]:
		var label := row.find_child(node_name, true, false) as Label if row != null else null
		var fits := (
			label != null and not label.text.strip_edges().is_empty()
			and label.is_visible_in_tree() and label.size.x > 1.0 and label.size.y > 1.0
			and row.get_global_rect().encloses(label.get_global_rect())
		)
		roster_text_fit = roster_text_fit and fits
		if not fits:
			roster_details.append("%s=%s text=%s" % [
				node_name, label.get_global_rect() if label != null else Rect2(),
				label.text if label != null else "missing",
			])
	h.check(
		"portrait roster identity facts fit inside each row",
		roster_text_fit,
		"; ".join(roster_details),
	)
	await h.frames(6)
	await h.shot("training_recruit_roster_portrait")
	var view_paths := support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(4)
	var cards := support.find(training, "PathCards") as BoxContainer
	var warning := support.find(training, "PermanentWarning") as Control
	var actions := support.find(training, "PathActions") as Control
	var viewport := Rect2(Vector2.ZERO, Vector2(VIEWPORT))
	h.check("portrait class cards stack vertically", cards != null and cards.vertical)
	var facts_fit := cards != null
	var overflow_details: Array[String] = []
	if cards != null:
		for card: Control in cards.get_children():
			var field_kit := card.find_child("FieldKit", true, false) as Control
			facts_fit = facts_fit and field_kit != null
			if field_kit != null:
				var enclosed := card.get_global_rect().encloses(field_kit.get_global_rect())
				facts_fit = facts_fit and enclosed
				if not enclosed:
					overflow_details.append(
						"%s card=%s field=%s" % [
							card.name, card.get_global_rect(), field_kit.get_global_rect(),
						],
					)
	h.check(
		"portrait card facts do not overflow into adjacent cards",
		facts_fit,
		"; ".join(overflow_details),
	)
	await support.ensure_visible(h, warning)
	var warning_reachable := warning != null and viewport.encloses(warning.get_global_rect())
	await support.ensure_visible(h, actions)
	h.check(
		"portrait warning and actions are both scroll-reachable",
		warning_reachable and actions != null and viewport.encloses(actions.get_global_rect()),
		"warning=%s actions=%s" % [
			warning.get_global_rect() if warning != null else Rect2(),
			actions.get_global_rect() if actions != null else Rect2(),
		],
	)
	var scroll := support.find(training, "PathCardsScroll") as ScrollContainer
	var fifth := support.find(training, "Path_swordmaster") as Control
	var fifth_heading := (
		fifth.find_child("AdvancedClassName", true, false) as Control
		if fifth != null else null
	)
	await support.ensure_visible(h, fifth_heading)
	var clip := (
		scroll.get_global_rect().intersection(viewport)
		if scroll != null else Rect2()
	)
	h.check(
		"portrait fifth class heading center is reachable",
		fifth_heading != null
		and clip.has_point(fifth_heading.get_global_rect().get_center()),
	)
	var choose := support.find(training, "ChoosePath") as Button
	var back := support.find(training, "PathBack") as Button
	h.check(
		"portrait action centers remain reachable after card scroll",
		viewport.has_point(choose.get_global_rect().get_center())
		and viewport.has_point(back.get_global_rect().get_center()),
	)
	h.check("portrait browsing changes no authority", support.authority_facts(game) == before)
	await h.shot("training_recruit_paths_portrait")
	print("MAGE_PROMOTION_PORTRAIT_COMPLETED")
	h.done()
