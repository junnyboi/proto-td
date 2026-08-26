extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0


class TrainingLayoutCampaign:
	extends RefCounted

	const HERO_ID := "0000000000000001"
	const PATHS := [
		{"to_class_id": "defender", "operator_def_id": "defender_1"},
		{"to_class_id": "gunner", "operator_def_id": "sniper_1"},
		{"to_class_id": "mage_apprentice", "operator_def_id": "caster_1"},
		{"to_class_id": "shock_trooper", "operator_def_id": "vanguard_1"},
		{"to_class_id": "swordmaster", "operator_def_id": "guard_1"},
	]

	var _data := {
		"heroes": [{
			"hero_id": HERO_ID,
			"custom_callsign": "Niko Cinder",
			"custom_title": null,
			"name_version": 1,
			"recruitment_index": 0,
			"current_class_id": "recruit",
			"first_class_id": null,
			"advanced_class_id": null,
			"operator_def_id": "recruit",
			"portrait_asset_id": "portrait_recruit",
			"identity_portrait_id": "portrait_recruit",
			"life_status": "ready",
			"hero_kind": "recruit",
			"premium_id": null,
			"premium_lives": 0,
			"premium_pull_count": 0,
			"xp": 100,
		}],
	}

	func data_copy() -> Dictionary:
		return _data.duplicate(true)

	func promotion_options(hero_id: Variant) -> Dictionary:
		if String(hero_id) != HERO_ID:
			return {"accepted": false, "error_code": &"unknown_hero", "choices": []}
		var choices: Array[Dictionary] = []
		for path: Dictionary in PATHS:
			choices.append({
				"from_class_id": "recruit",
				"to_class_id": path["to_class_id"],
				"operator_def_id": path["operator_def_id"],
			})
		return {"accepted": true, "error_code": &"", "choices": choices}

	func campaign_uid() -> String:
		return "training-layout-fixture"

	func save_revision() -> int:
		return 1

	func strategic_hash() -> Dictionary:
		return {"accepted": true, "value": "training-layout-fixture"}

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "Training readability fixture failed")
	_prepare_promotion_ready_campaign(game)
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame

	var outer := screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	var page := screen.find_child("TrainingPage", true, false) as VBoxContainer
	var body := screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	var roster_scroll := screen.find_child("TrainingRosterScroll", true, false) as ScrollContainer
	var inspector := screen.find_child("TrainingInspector", true, false) as PanelContainer
	var inspector_scroll := screen.find_child("TrainingInspectorScroll", true, false) as ScrollContainer
	var roster_controls := screen.find_child("TrainingRosterControls", true, false) as BoxContainer
	var filters := screen.find_child("RosterFilterControls", true, false) as BoxContainer
	var filter_summary := screen.find_child("TrainingFilterSummary", true, false) as Label
	var promotion_tab := screen.find_child("PromotionReadyRosterTab", true, false) as Button
	_check(outer != null and page != null and body != null, "Training workspace is incomplete")
	_check(roster_scroll != null and inspector != null and inspector_scroll != null, "Training local panels are incomplete")
	_check(roster_controls != null and filters != null and promotion_tab != null, "Training header/filter composition is incomplete")
	_check(screen.find_child("PromotionReadyCount", true, false) == null, "redundant promotion-ready metric was not removed")
	if outer != null:
		_check(outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "desktop Training still uses document scrolling")
	if page != null and outer != null:
		_check(page.size.y >= outer.size.y - 12.0, "Training page does not fill the available document viewport")
	if body != null:
		_check(not body.vertical, "desktop Training roster/inspector should remain side by side")
		_check(body.get_theme_constant("separation") == 64, "desktop Training right gutter is not 64px")
		_check(body.size.y >= 150.0, "desktop Training roster/inspector is no longer usable with 1.5× type")
		_check(_contained(body.get_global_rect(), page.get_global_rect(), 1.0), "desktop Training body overflows its page")
	if roster_scroll != null and inspector != null:
		_check(roster_scroll.size.y >= 150.0 and inspector.size.y >= 150.0, "Training panels are too short for 1.5× type")
		_check(roster_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Training roster can scroll horizontally")
		_check(_near(roster_scroll.custom_minimum_size.x, 584.0, 1.0), "desktop roster rail is not fixed around the 560px cards")
	if inspector_scroll != null:
		_check(inspector_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Training inspector does not expand vertically")
	if filters != null:
		_check(filters.vertical and filters.size.y <= 260.0, "desktop Training filters exceed the padded responsive rail")
	if roster_controls != null:
		_check(not roster_controls.vertical and roster_controls.size.y <= 180.0, "desktop Training filters and identity tools are not consolidated")
	_check(filter_summary != null and not filter_summary.visible, "redundant desktop shown-count still consumes toolbar width")
	if promotion_tab != null:
		_check(promotion_tab.visible and promotion_tab.custom_minimum_size.x >= 280.0, "Promotion Ready tab lacks a padded text-safe width")
		_check(_button_padding_at_least(promotion_tab, 12.0), "Promotion Ready tab lacks 12px vertical padding")
		promotion_tab.pressed.emit()
		await _frames(3)
		_check(StringName(screen.get("_filter_status")) == &"promotion_ready", "Promotion Ready tab did not activate the filter")
		var filtered_rows := screen.call("_visible_roster_rows") as Array
		_check(not filtered_rows.is_empty(), "Promotion Ready filter hid the eligible fixture")
		for filtered: Dictionary in filtered_rows:
			_check(bool(filtered.get("can_promote", false)), "Promotion Ready filter exposed an ineligible operator")

	_check(_font(screen, "TrainingTitleHeading") >= 40, "Training title is below 40px")
	_check(screen.find_child("TrainingTitleSubtitle", true, false) == null, "annotated Training subtitle was not removed")
	_check(_font(screen, "Callsign") >= 19, "Training roster callsign is below 19px")
	_check(_font(screen, "CurrentClass") >= 16, "Training roster class is below 16px")
	_check(_font(screen, "RenameUnitHeading") >= 24, "Training inspector heading is below 24px")
	_check(_font(screen, "RenameUnitGuidance") >= 16, "Training guidance is below 16px")
	_check(_font(screen, "CallsignFieldLabel") >= 16, "Training field label is below 16px")
	var rename := screen.find_child("RenameUnitInput", true, false) as LineEdit
	_check(rename != null and rename.get_theme_font_size("font_size") >= 20, "Training identity input is below 20px")
	var rename_panel := screen.find_child("RenameUnitPanel", true, false) as PanelContainer
	var dossier := screen.find_child("SelectedOperatorDossier", true, false) as Control
	var edit_identity := screen.find_child("EditIdentity", true, false) as Button
	_check(rename_panel != null and not rename_panel.visible, "Field Identity editor is visible before Edit Identity is requested")
	_check(rename != null and not rename.is_visible_in_tree(), "identity input is exposed before Edit Identity is requested")
	_check(dossier != null and rename_panel != null and dossier.get_index() < rename_panel.get_index(), "operator information does not precede Field Identity")
	_check(edit_identity != null and edit_identity.is_visible_in_tree(), "selected operator identity lacks an Edit control")
	if edit_identity != null:
		edit_identity.pressed.emit()
		await _frames(3)
		rename_panel = screen.find_child("RenameUnitPanel", true, false) as PanelContainer
		rename = screen.find_child("RenameUnitInput", true, false) as LineEdit
		_check(rename_panel != null and rename_panel.visible, "Edit Identity did not reveal Field Identity")
		_check(rename != null and rename.is_visible_in_tree(), "Edit Identity did not reveal the inputs")
	var row_margin := screen.find_child("RosterRowMargin", true, false) as MarginContainer
	_check(row_margin != null and row_margin.get_theme_constant("margin_left") == 48, "Training roster row horizontal padding is not 48px")
	_check(row_margin != null and row_margin.get_theme_constant("margin_top") == 24, "Training roster row vertical padding is not 24px")
	if inspector != null:
		var style: StyleBox = inspector.get_theme_stylebox("panel")
		_check(style.content_margin_left >= 22.0 and style.content_margin_right >= 22.0, "Training inspector horizontal padding is under 22px")
		_check(style.content_margin_top >= 22.0 and style.content_margin_bottom >= 22.0, "Training inspector vertical padding is under 22px")
	var roster_detail := screen.find_child("EligibilityReason", true, false) as Label
	_check(roster_detail != null and roster_detail.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "Training roster metadata can be clipped with ellipsis")
	var roster_row := screen.find_child("Recruit_*", true, false) as Control
	_check(roster_row != null, "Training roster did not render a hoverable operator row")
	if roster_row != null:
		_check(_near(roster_row.custom_minimum_size.x, 560.0, 1.0), "desktop operator card is not fixed at 560px")
		_check(_has_detailed_stats(roster_row.tooltip_text), "Training roster tooltip omits detailed combat statistics")
	if inspector != null:
		_check(_has_detailed_stats(inspector.tooltip_text), "Training inspector tooltip omits detailed combat statistics")

	root.size = Vector2i(720, 1280)
	await _frames(4)
	outer = screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	page = screen.find_child("TrainingPage", true, false) as VBoxContainer
	body = screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	filters = screen.find_child("RosterFilterControls", true, false) as BoxContainer
	roster_controls = screen.find_child("TrainingRosterControls", true, false) as BoxContainer
	var filter_lower_rail := screen.find_child("RosterFilterLowerRail", true, false) as BoxContainer
	filter_summary = screen.find_child("TrainingFilterSummary", true, false) as Label
	var dock := screen.find_child("TrainingActionDock", true, false) as VBoxContainer
	var roster_actions := screen.find_child("RosterActions", true, false) as BoxContainer
	_check(outer != null and outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "standard portrait Training does not expose enlarged content through scrolling")
	_check(body != null and body.vertical, "portrait Training roster/inspector did not stack")
	_check(filters != null and filters.vertical, "portrait Training filters did not stack")
	_check(roster_controls != null and not roster_controls.vertical and filter_lower_rail != null and filter_lower_rail.vertical, "portrait Training control groups did not stack")
	_check(filter_summary != null and filter_summary.visible, "portrait Training shown-count is missing")
	_check(dock != null and roster_actions != null and roster_actions.vertical, "portrait Training actions did not stack in the fixed dock")
	if roster_actions != null:
		for child: Node in roster_actions.get_children():
			if child is Button:
				var action := child as Button
				_check(action.custom_minimum_size.x <= 260.0, "roster action exceeds the fixed compact width")
				_check(action.custom_minimum_size.y >= 84.0, "roster action lacks 12px top/bottom padding height")
				_check(_button_padding_at_least(action, 12.0), "roster action style lacks 12px vertical padding")
	if page != null and outer != null:
		_check(page.size.y > outer.size.y, "portrait Training does not expose vertical overflow for 1.5× content")
		_check(page.get_global_rect().position.x >= outer.get_global_rect().position.x - 1.0 and page.get_global_rect().end.x <= outer.get_global_rect().end.x + 1.0, "portrait Training page overflows horizontally")
	if dock != null:
		_check(dock.get_global_rect().end.y <= 1280.0, "portrait Training action dock overflows the viewport")

	root.size = Vector2i(2048, 826)
	await _frames(4)
	var ready_hero_id := ""
	var roster_rows: Array = screen.get("_roster_rows")
	for summary: Dictionary in roster_rows:
		if bool(summary.get("can_promote", false)):
			ready_hero_id = String(summary["hero_id"])
			break
	_check(not ready_hero_id.is_empty(), "training fixture has no promotion-ready recruit")
	if not ready_hero_id.is_empty():
		screen.set("_selected_hero_id", ready_hero_id)
		screen.call("_show_roster")
		await _frames(4)
	var view_paths := screen.find_child("ViewPaths", true, false) as Button
	_check(view_paths != null and not view_paths.disabled, "advanced Training paths are unavailable in the fixture")
	if view_paths != null and not view_paths.disabled:
		view_paths.emit_signal("pressed")
	await _frames(4)
	var path_grid := screen.find_child("PathCards", true, false) as GridContainer
	var nested_path_scroll := screen.find_child("PathCardsScroll", true, false) as ScrollContainer
	var path_title := screen.find_child("ChooseTrainingTitleHeading", true, false) as Label
	var path_action_safe := screen.find_child("PathActionSafe", true, false) as MarginContainer
	var path_content_gutter := screen.get("_content_gutter") as MarginContainer
	var path_actions := screen.find_child("PathActions", true, false) as BoxContainer
	var path_back := screen.find_child("PathBack", true, false) as Button
	var choose_path := screen.find_child("ChoosePath", true, false) as Button
	var path_cards: Array[Control] = []
	if path_grid != null:
		for child: Node in path_grid.get_children():
			if child is Control:
				path_cards.append(child as Control)
	_check(path_grid != null and path_cards.size() >= 2, "advanced Training fixed-card grid did not render")
	_check(path_title != null and path_title.text.begins_with("CHOOSE A NEW SPECIALIZATION FOR "), "advanced Training title does not name the selected operator")
	_check(nested_path_scroll != null and nested_path_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and nested_path_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "doubled specialization cards do not use the dedicated horizontal rail")
	_check(path_content_gutter.get_theme_constant(&"margin_left") == 60 and path_content_gutter.get_theme_constant(&"margin_right") == 60, "advanced Training does not retain 60px side gutters")
	if path_grid != null and not path_cards.is_empty():
		_check(path_grid.columns == path_cards.size(), "wide initial entry does not place each training option in the fixed card row")
		var first_y := path_cards[0].global_position.y
		for card: Control in path_cards:
			_check(_near(card.size.x, 680.0, 1.0) and _near(card.size.y, 450.0, 1.0), "wide training option is not a doubled 680x450 card")
			_check(_near(card.global_position.y, first_y, 1.0), "wide training options have inconsistent initial vertical spacing")
			_check(_contained(card.get_global_rect(), path_grid.get_global_rect(), 1.0), "wide training card overflows the fixed grid")
		var first_card := path_cards[0]
		var portrait := first_card.find_child("ClassKitPortrait", true, false) as TextureRect
		var class_title := first_card.find_child("AdvancedClassName", true, false) as Label
		var detail := first_card.find_child("ClassDescription", true, false) as Label
		_check(portrait != null and portrait.custom_minimum_size.x >= 124.0 and portrait.custom_minimum_size.y >= 128.0, "specialization portrait was not scaled with the doubled card")
		_check(class_title != null and class_title.get_theme_font_size(&"font_size") >= 40, "specialization title typography was not doubled")
		_check(detail != null and detail.get_theme_font_size(&"font_size") >= 26, "specialization body typography was not doubled")
		_check(bool(first_card.call("uses_flat_color_states")), "specialization card still depends on ornamental selected-state graphics")
		var normal_style := first_card.get_theme_stylebox(&"normal") as StyleBoxFlat
		first_card.emit_signal("pressed")
		await _frames(2)
		var selected_style := first_card.get_theme_stylebox(&"normal") as StyleBoxFlat
		_check(normal_style != null and selected_style != null and not normal_style.bg_color.is_equal_approx(selected_style.bg_color), "selected specialization does not use a background color change")
		_check(first_card.get_theme_stylebox(&"hover") is StyleBoxFlat, "specialization hover state is not a scalable flat background")
	if path_actions != null and path_back != null and choose_path != null:
		_check(not path_actions.vertical and path_actions.alignment == BoxContainer.ALIGNMENT_END, "wide path actions are not a bottom-right row")
		_check(_near(path_back.size.x, 260.0, 1.0) and _near(choose_path.size.x, 260.0, 1.0), "path actions do not share the enlarged 260px width")
		_check(_near(path_back.size.y, 84.0, 1.0) and _near(choose_path.size.y, 84.0, 1.0), "path actions do not share the enlarged 84px height")
		_check(path_back.theme_type_variation == choose_path.theme_type_variation, "Back and Add to Plan do not share one visual treatment")
		_check(choose_path.get_global_rect().end.x >= path_actions.get_global_rect().end.x - 2.0, "path actions are not flush to the bottom-right edge")
		_check(path_action_safe != null and path_action_safe.get_theme_constant(&"margin_left") == 60 and path_action_safe.get_theme_constant(&"margin_right") == 60, "path action bar does not preserve 60px side padding")
		for action: Button in [path_back, choose_path]:
			var label := action.find_child("PresentationLabel", true, false) as Label
			var style := action.get_theme_stylebox(&"normal")
			_check(label != null and label.get_theme_font_size(&"font_size") >= 28 and not label.clip_text, "%s text is not enlarged and overflow-safe" % action.name)
			_check(_near(label.offset_left, 24.0, 0.1) and _near(label.offset_top, 12.0, 0.1) and _near(label.offset_right, -24.0, 0.1) and _near(label.offset_bottom, -12.0, 0.1), "%s lacks 24x12 internal padding" % action.name)
			_check(_near(style.content_margin_left, 24.0, 0.1) and _near(style.content_margin_top, 12.0, 0.1), "%s style does not retain requested internal padding" % action.name)
	var initial_columns := path_grid.columns if path_grid != null else 0

	root.size = Vector2i(720, 1280)
	await _frames(4)
	outer = screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	page = screen.find_child("TrainingPage", true, false) as VBoxContainer
	dock = screen.find_child("TrainingActionDock", true, false) as VBoxContainer
	path_grid = screen.find_child("PathCards", true, false) as GridContainer
	path_actions = screen.find_child("PathActions", true, false) as BoxContainer
	nested_path_scroll = screen.find_child("PathCardsScroll", true, false) as ScrollContainer
	path_back = screen.find_child("PathBack", true, false) as Button
	choose_path = screen.find_child("ChoosePath", true, false) as Button
	_check(outer != null and outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "standard portrait Training does not expose enlarged content through scrolling")
	_check(dock != null and path_actions != null and path_actions.vertical, "portrait Training actions did not stack in the fixed dock")
	if path_grid != null:
		_check(path_grid.columns == 1, "portrait training grid does not reflow to one centered fixed column")
		_check(nested_path_scroll != null and nested_path_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "portrait specialization rail still scrolls horizontally")
		for child: Node in path_grid.get_children():
			if child is Control:
				var card := child as Control
				_check(_near(card.size.x, 600.0, 1.0) and _near(card.size.y, 450.0, 1.0), "portrait training option is not a doubled 600x450 card")
	if path_actions != null and path_back != null and choose_path != null:
		_check(path_actions.alignment == BoxContainer.ALIGNMENT_END, "portrait path actions are not right-aligned")
		_check(_near(path_back.size.x, choose_path.size.x, 1.0) and _near(path_back.size.y, choose_path.size.y, 1.0), "portrait path actions do not share identical geometry")
	if page != null and outer != null:
		_check(page.size.y > outer.size.y, "portrait Training does not expose vertical overflow for 1.5× content")
		_check(page.get_global_rect().position.x >= outer.get_global_rect().position.x - 1.0 and page.get_global_rect().end.x <= outer.get_global_rect().end.x + 1.0, "portrait Training page overflows horizontally")
	if dock != null:
		_check(dock.get_global_rect().end.y <= 1280.0, "portrait Training action dock overflows the viewport")

	root.size = Vector2i(2048, 826)
	await _frames(4)
	path_grid = screen.find_child("PathCards", true, false) as GridContainer
	path_back = screen.find_child("PathBack", true, false) as Button
	choose_path = screen.find_child("ChoosePath", true, false) as Button
	_check(path_grid != null and path_grid.columns == initial_columns, "wide card columns change after a narrow-wide resize cycle")
	if path_grid != null:
		for child: Node in path_grid.get_children():
			if child is Control:
				var card := child as Control
				_check(_near(card.size.x, 680.0, 1.0) and _near(card.size.y, 450.0, 1.0), "wide doubled-card geometry changes after a resize cycle")
	if path_back != null and choose_path != null:
		_check(_near(path_back.size.x, 260.0, 1.0) and _near(choose_path.size.x, 260.0, 1.0), "path action width changes after a resize cycle")

	_dispose(screen)
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	root.size = Vector2i(1280, 720)
	await create_timer(0.1).timeout
	_finish()


func _font(screen: Node, node_name: String) -> int:
	var label := screen.find_child(node_name, true, false) as Label
	return label.get_theme_font_size("font_size") if label != null else 0


func _prepare_promotion_ready_campaign(game: Node) -> void:
	game.set("campaign", TrainingLayoutCampaign.new())


func _frames(count: int) -> void:
	for _index: int in count:
		await process_frame


func _near(value: float, expected: float, tolerance: float) -> bool:
	return absf(value - expected) <= tolerance


func _contained(inner: Rect2, outer: Rect2, tolerance: float) -> bool:
	return (
		inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance
	)


func _has_detailed_stats(value: String) -> bool:
	var lines := value.split("\n", false)
	var numeric_lines := 0
	for line: String in lines:
		if line.contains("0") or line.contains("1") or line.contains("2") or line.contains("3"):
			numeric_lines += 1
	return lines.size() >= 7 and numeric_lines >= 3 and value.contains(" • ")


func _button_padding_at_least(button: Button, minimum: float) -> bool:
	var style := button.get_theme_stylebox("normal")
	return style.content_margin_top >= minimum and style.content_margin_bottom >= minimum


func _dispose(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("TRAINING_READABILITY_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("Training readability test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
