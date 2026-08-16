class_name RecruitPromotionVariantSupport
extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const PromotionPathCardType := preload(
	"res://scripts/ui/components/promotion_path_card.gd"
)
const VIEWPORTS := [
	{"size": Vector2i(1280, 720), "mode": &"regular_landscape", "tag": "1280x720"},
	{"size": Vector2i(960, 720), "mode": &"compact_landscape", "tag": "960x720"},
	{"size": Vector2i(720, 1280), "mode": &"portrait", "tag": "720x1280"},
]


func run_flow(h: SelfTestHarness, variant: StringName) -> void:
	var game := h.autoload("Game")
	var support := SupportType.new()
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return
	var before := support.authority_facts(game)
	h.root.size = VIEWPORTS[0]["size"]
	await h.frames(4)
	var training := await _open_paths(h, game, support, prepared)
	h.check("Training paths open for geometry stress", training != null)
	if training == null:
		return
	_apply_variant(training, variant)
	training.call("_apply_footer_layouts")
	for config: Dictionary in VIEWPORTS:
		h.root.size = config["size"]
		await h.frames(4)
		for card: Control in support.find(training, "PathCards").get_children():
			if is_instance_of(card, PromotionPathCardType):
				(card as PromotionPathCardType).fit_to_content()
		training.call("_apply_footer_layouts")
		await h.frames(6)
		await _check_path_geometry(h, support, training, config, variant)
		await h.shot("training_%s_%s" % [variant, config["tag"]])
	h.check(
		"%s geometry stress changes no campaign authority" % variant,
		support.authority_facts(game) == before,
	)


func run_failure(h: SelfTestHarness, variant: StringName) -> void:
	var game := h.autoload("Game")
	var support := SupportType.new()
	for config: Dictionary in VIEWPORTS:
		h.root.size = config["size"]
		await h.frames(4)
		var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
		if prepared.is_empty():
			return
		var hero_id := String(prepared["target_id"])
		var results := await support.open_results_training(h, game)
		var training := await support.open_training_from_results(h, game, results)
		if training == null:
			return
		if not await support.draft_choice(h, training, hero_id, "defender"):
			return
		if await support.open_review(h, training) == null:
			return
		var before := support.authority_facts(game)
		var tmp_path := ProjectSettings.globalize_path("user://campaign_v1.tmp")
		var made := DirAccess.make_dir_absolute(tmp_path)
		h.check("%s save fault installs" % config["tag"], made == OK)
		if made != OK:
			return
		var confirm := support.find(training, "ConfirmTraining") as Button
		await support.ensure_visible(h, confirm)
		await h.click_view(confirm.get_global_rect().get_center())
		await h.frames(5)
		_apply_variant(training, variant)
		training.call("_apply_footer_layouts")
		await h.frames(8)
		await _check_error_geometry(h, support, training, config, variant)
		h.check(
			"%s %s save error changes no authority" % [variant, config["tag"]],
			support.authority_facts(game) == before,
		)
		await h.shot("training_error_%s_%s" % [variant, config["tag"]])
		var removed := DirAccess.remove_absolute(tmp_path)
		h.check("%s save fault removes" % config["tag"], removed == OK)


func _open_paths(
	h: SelfTestHarness,
	game: Node,
	support: RecruitPromotionScenarioSupport,
	prepared: Dictionary,
) -> Control:
	game.call("training_call", &"open", &"staging")
	await h.frames(3)
	var training := await support.await_screen(h, game, "TrainingRoot")
	if training == null:
		return null
	var row := support.find(
		training, "Recruit_%s" % prepared["target_id"],
	) as Button
	await support.ensure_visible(h, row)
	await h.click_view(row.get_global_rect().get_center())
	var view_paths := support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(4)
	return training


func _apply_variant(root: Control, variant: StringName) -> void:
	var nodes := _all_nodes(root)
	for node: Node in nodes:
		if node is Label:
			var label := node as Label
			if variant == &"scaled":
				var current := maxi(16, label.get_theme_font_size(&"font_size"))
				label.add_theme_font_size_override(&"font_size", current * 2)
			elif variant == &"expanded" and not label.text.strip_edges().is_empty():
				label.text = _expanded_text(label.text)
	for node: Node in nodes:
		if is_instance_of(node, PromotionPathCardType):
			(node as PromotionPathCardType).fit_to_content()
	for index: int in range(nodes.size() - 1, -1, -1):
		if nodes[index] is Control:
			(nodes[index] as Control).update_minimum_size()


func _expanded_text(source: String) -> String:
	var result := source
	var target := ceili(float(source.length()) * 1.35)
	while result.length() < target:
		result += " · FIELD OPERATIONS"
	return result


func _check_path_geometry(
	h: SelfTestHarness,
	support: RecruitPromotionScenarioSupport,
	training: Control,
	config: Dictionary,
	variant: StringName,
) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(config["size"]))
	var shell := support.find(training, "TrainingScreenShell") as AetheriaScreenShell
	h.check(
		"%s %s layout mode" % [variant, config["tag"]],
		shell != null and shell.layout_mode() == config["mode"],
	)
	var cards := support.find(training, "PathCards") as BoxContainer
	var fit := cards != null and cards.get_child_count() == 5
	var details: Array[String] = []
	if cards != null:
		for card: Control in cards.get_children():
			var field_kit := card.find_child("FieldKit", true, false) as Control
			var enclosed := field_kit != null and card.get_global_rect().encloses(
				field_kit.get_global_rect(),
			)
			fit = fit and enclosed and card.size.x >= 44.0 and card.size.y >= 44.0
			if not enclosed:
				details.append("%s card=%s field=%s" % [
					card.name, card.get_global_rect(),
					field_kit.get_global_rect() if field_kit != null else Rect2(),
				])
	h.check(
		"%s %s cards fit without overlap" % [variant, config["tag"]],
		fit,
		"; ".join(details),
	)
	var footer := support.find(training, "PathActions") as Control
	await support.ensure_visible(h, footer)
	h.check(
		"%s %s footer is reachable" % [variant, config["tag"]],
		footer != null and viewport.encloses(footer.get_global_rect()),
		str(footer.get_global_rect() if footer != null else Rect2()),
	)
	var last := support.find(training, "Path_swordmaster") as Button
	(support.find(training, "Path_defender") as Button).grab_focus()
	await h.frames(2)
	last.grab_focus()
	var heading := last.find_child("AdvancedClassName", true, false) as Control
	await h.frames(4)
	var scroll := support.find(training, "PathCardsScroll") as ScrollContainer
	var clip := scroll.get_global_rect().intersection(viewport)
	h.check(
		"%s %s focused fifth card scrolls into view" % [variant, config["tag"]],
		training.get_viewport().gui_get_focus_owner() == last
		and heading != null and clip.has_point(heading.get_global_rect().get_center()),
	)
	var back := support.find(training, "PathBack") as Button
	var add := support.find(training, "ChoosePath") as Button
	h.check(
		"%s %s action targets meet 44px floor" % [variant, config["tag"]],
		back.size.x >= 44.0 and back.size.y >= 44.0
		and add.size.x >= 44.0 and add.size.y >= 44.0,
	)
	h.check(
		"%s %s action labels fit" % [variant, config["tag"]],
		_button_label_fits(back) and _button_label_fits(add),
	)
	await support.ensure_visible(h, footer)


func _check_error_geometry(
	h: SelfTestHarness,
	support: RecruitPromotionScenarioSupport,
	training: Control,
	config: Dictionary,
	variant: StringName,
) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(config["size"]))
	var error := support.find(training, "TrainingReviewError") as Label
	var back := support.find(training, "ReviewBack") as Button
	var confirm := support.find(training, "ConfirmTraining") as Button
	var footer := support.find(training, "ReviewActions") as Control
	await support.ensure_visible(h, footer)
	h.check(
		"%s %s save error stays visible and focused" % [variant, config["tag"]],
		error != null and not error.text.is_empty()
		and training.get_viewport().gui_get_focus_owner() == error,
	)
	h.check(
		"%s %s error actions remain reachable" % [variant, config["tag"]],
		footer != null and viewport.encloses(footer.get_global_rect())
		and back.size.x >= 44.0 and back.size.y >= 44.0
		and confirm.size.x >= 44.0 and confirm.size.y >= 44.0,
		str(footer.get_global_rect() if footer != null else Rect2()),
	)
	h.check(
		"%s %s error action labels fit" % [variant, config["tag"]],
		_button_label_fits(back) and _button_label_fits(confirm),
	)


func _button_label_fits(button: Button) -> bool:
	var label := button.find_child("PresentationLabel", false, false) as Label
	if label == null or label.text.strip_edges().is_empty() or label.size.x <= 0.0:
		return false
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	var width := font.get_string_size(
		label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
	).x
	var lines := maxi(1, ceili(width / label.size.x))
	return font.get_height(font_size) * lines <= label.size.y + 1.0


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child: Node in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes
