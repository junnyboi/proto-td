extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0


class TrainingLayoutCampaign:
	extends RefCounted

	const HERO_ID := "0000000000000001"
	const HERO_ID_2 := "0000000000000002"
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
			"portrait_asset_id": "portrait_recruit_00",
			"identity_portrait_id": "portrait_recruit_00",
			"life_status": "ready",
			"hero_kind": "recruit",
			"premium_id": null,
			"premium_lives": 0,
			"premium_pull_count": 0,
			"xp": 100,
		}, {
			"hero_id": HERO_ID_2,
			"custom_callsign": "Kira Jade",
			"custom_title": "Second Watch",
			"name_version": 1,
			"recruitment_index": 1,
			"current_class_id": "recruit",
			"first_class_id": null,
			"advanced_class_id": null,
			"operator_def_id": "recruit",
			"portrait_asset_id": "portrait_recruit_01",
			"identity_portrait_id": "portrait_recruit_01",
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
		if String(hero_id) not in [HERO_ID, HERO_ID_2]:
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
	var faction_filter := screen.find_child("SolcrestAccordFactionFilter", true, false) as Button
	var sort_select := screen.find_child("TrainingNameSort", true, false) as OptionButton
	_check(outer != null and page != null and body != null, "Training workspace is incomplete")
	_check(roster_scroll != null and inspector != null and inspector_scroll != null, "Training local panels are incomplete")
	_check(roster_controls != null and filters != null and promotion_tab != null, "Training header/filter composition is incomplete")
	_check(faction_filter != null and String(faction_filter.accessibility_name).contains("SOLCREST") and String(faction_filter.accessibility_name).contains(": "), "faction filter accessibility does not distinguish its heraldry and count")
	_check(screen.find_child("PromotionReadyCount", true, false) == null, "redundant promotion-ready metric was not removed")
	if outer != null:
		_check(outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "desktop Training still uses document scrolling")
	if page != null and outer != null:
		_check(page.size.y >= outer.size.y - 12.0, "Training page does not fill the available document viewport")
	if body != null:
		_check(not body.vertical, "desktop Training roster/inspector should remain side by side")
		_check(body.get_theme_constant("separation") == 64, "desktop Training right gutter is not 64px")
		_check(body.size.y >= 100.0, "desktop Training roster/inspector is no longer usable with padded controls")
		_check(_contained(body.get_global_rect(), page.get_global_rect(), 1.0), "desktop Training body overflows its page")
	if roster_scroll != null and inspector != null:
		_check(roster_scroll.size.y >= 100.0 and inspector.size.y >= 100.0, "Training panels are too short for the padded desktop workspace")
		_check(roster_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Training roster can scroll horizontally")
		_check(_near(roster_scroll.custom_minimum_size.x, 584.0, 1.0), "desktop roster rail is not fixed around the 560px cards")
	if inspector_scroll != null:
		_check(inspector_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Training inspector does not expand vertically")
	if filters != null:
		_check(filters.vertical and filters.size.y <= 210.0, "desktop Training filters exceed the padded responsive rail")
	if roster_controls != null:
		_check(not roster_controls.vertical and roster_controls.size.y <= 210.0, "desktop Training filters and identity tools are not consolidated")
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
	var filter_buttons: Array[Button] = []
	for filter_name: String in [
		"ActiveRosterTab", "FallenRosterTab", "PromotionReadyRosterTab",
		"AllFactionFilter", "SolcrestAccordFactionFilter", "VesperCircuitFactionFilter",
		"LunarisReliquaryFactionFilter", "CrimsonAegisFactionFilter",
	]:
		var filter_button := screen.find_child(filter_name, true, false) as Button
		_check(filter_button != null, "%s is missing" % filter_name)
		if filter_button != null:
			filter_buttons.append(filter_button)
			_check(_button_padding_at_least(filter_button, 24.0, 12.0), "%s lacks exact requested 24x12 padding" % filter_name)
	if sort_select != null:
		_check(_near(sort_select.custom_minimum_size.x, 220.0, 1.0) and _near(sort_select.custom_minimum_size.y, 96.0, 1.0), "Recruitment Order does not retain fixed wrapped geometry")
		_check(sort_select.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and sort_select.alignment == HORIZONTAL_ALIGNMENT_CENTER, "Recruitment Order is not centered and word-wrapped")
		_check(_button_padding_at_least(sort_select, 24.0, 12.0), "Recruitment Order lacks 24x12 padding")

	_check(_font(screen, "TrainingTitleHeading") >= 40, "Training title is below 40px")
	_check(screen.find_child("TrainingTitleSubtitle", true, false) == null, "annotated Training subtitle was not removed")
	_check(_font(screen, "Callsign") >= 19, "Training roster callsign is below 19px")
	_check(_font(screen, "CurrentClass") >= 16, "Training roster class is below 16px")
	_check(_font(screen, "SelectedCallsign") >= 40, "selected operator callsign was not enlarged")
	_check(_font(screen, "SelectedClass") >= 42, "selected operator class was not enlarged")
	_check(_font(screen, "TrainingExplainer") >= 32, "selected operator field record copy was not enlarged")
	_check(_font(screen, "RenameUnitHeading") >= 42, "Training inspector heading was not enlarged")
	_check(_font(screen, "RenameUnitGuidance") >= 30, "Training guidance was not enlarged")
	_check(_font(screen, "CallsignFieldLabel") >= 30, "Training field label was not enlarged")
	var rename := screen.find_child("RenameUnitInput", true, false) as LineEdit
	_check(rename != null and rename.get_theme_font_size("font_size") >= 34, "Training identity input was not enlarged")
	var rename_panel := screen.find_child("RenameUnitPanel", true, false) as PanelContainer
	var dossier := screen.find_child("SelectedOperatorDossier", true, false) as Control
	var edit_identity := screen.find_child("EditIdentity", true, false) as Button
	_check(rename_panel != null and not rename_panel.visible, "Field Identity editor is visible before Edit Identity is requested")
	_check(rename != null and not rename.is_visible_in_tree(), "identity input is exposed before Edit Identity is requested")
	_check(dossier != null and rename_panel != null and dossier.get_index() < rename_panel.get_index(), "operator information does not precede Field Identity")
	_check(edit_identity != null and edit_identity.is_visible_in_tree(), "selected operator identity lacks an Edit control")
	if edit_identity != null:
		var edit_presentation := edit_identity.find_child("PresentationLabel", true, false) as Label
		_check(edit_identity.text == "Edit" and edit_presentation != null and edit_presentation.text == "Edit", "selected operator action is not presented as Edit")
		_check(edit_identity.find_child("EditIdentityLabel", true, false) == null, "Edit still uses its retired bespoke presentation")
		_check(_near(edit_identity.custom_minimum_size.x, 140.0, 1.0) and _near(edit_identity.custom_minimum_size.y, 84.0, 1.0), "Edit control lacks fixed padded geometry")
		_check(_button_padding_at_least(edit_identity, 24.0, 12.0), "Edit control lacks 24x12 padding")
		edit_identity.pressed.emit()
		await _frames(3)
		rename_panel = screen.find_child("RenameUnitPanel", true, false) as PanelContainer
		rename = screen.find_child("RenameUnitInput", true, false) as LineEdit
		var rename_title := screen.find_child("RenameTitleInput", true, false) as LineEdit
		_check(rename_panel != null and rename_panel.visible, "Edit Identity did not reveal Field Identity")
		_check(rename != null and rename.is_visible_in_tree(), "Edit Identity did not reveal the inputs")
		if rename != null and rename_title != null:
			rename.text = "Faye Ember II"
			rename.emit_signal("text_changed", rename.text)
			await _frames(2)
			_check(rename.get_theme_font_size("font_size") >= 34, "callsign input typography shrank after editing")
			_check(rename_title.get_theme_font_size("font_size") >= 34, "title input typography shrank after callsign editing")
	var row_margin := screen.find_child("RosterRowMargin", true, false) as MarginContainer
	_check(row_margin != null and row_margin.get_theme_constant("margin_left") == 48, "Training roster row horizontal padding is not 48px")
	_check(row_margin != null and row_margin.get_theme_constant("margin_top") == 24, "Training roster row vertical padding is not 24px")
	if inspector != null:
		var style := inspector.get_theme_stylebox("panel") as StyleBoxFlat
		_check(style != null and style.bg_color.a <= 0.01, "Training inspector retains the annotated cyan background slab")
		_check(style != null and _color_near(style.border_color, Color("d9b96e"), 0.02), "Training inspector border is not gold")
		_check(style != null and _near(style.content_margin_left, 24.0, 0.1) and _near(style.content_margin_top, 24.0, 0.1), "Training inspector lacks 24px internal padding")
	var selected_portrait := screen.find_child("SelectedOperatorPortrait", true, false) as TextureRect
	_check(selected_portrait != null and _near(selected_portrait.custom_minimum_size.x, 378.0, 1.0) and _near(selected_portrait.custom_minimum_size.y, 480.0, 1.0), "selected operator portrait was not tripled")
	var selected_xp := screen.find_child("SelectedXp", true, false) as Label
	_check(selected_xp != null and _color_near(selected_xp.get_theme_color("font_color"), Color("d9b96e"), 0.02), "selected operator metric still uses cyan instead of gold")
	var choose_promotion := screen.find_child("ChoosePromotion", true, false) as Button
	var selected_status := screen.find_child("SelectedRecruitStatus", true, false) as Label
	_check(screen.find_child("ViewPaths", true, false) == null, "obsolete View Paths footer action is still present")
	_check(screen.find_child("ReviewPlan", true, false) == null, "removed bulk promotion review action is still present")
	_check(choose_promotion != null and choose_promotion.is_visible_in_tree(), "promotion-ready operator lacks contextual Choose Promotion action")
	if choose_promotion != null:
		_check(choose_promotion.text == "Choose Promotion", "contextual promotion action has incorrect copy")
		_check(_near(choose_promotion.custom_minimum_size.x, 360.0, 1.0) and _near(choose_promotion.custom_minimum_size.y, 96.0, 1.0), "Choose Promotion action lacks text-safe fixed geometry")
		var promotion_label := choose_promotion.find_child("ChoosePromotionLabel", true, false) as Label
		_check(promotion_label != null and promotion_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and promotion_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Choose Promotion copy is not centered and safely wrapped")
		_check(promotion_label != null and promotion_label.get_visible_line_count() == promotion_label.get_line_count(), "Choose Promotion clips part of its label")
		_check(_button_padding_at_least(choose_promotion, 24.0, 12.0), "Choose Promotion action lacks 24x12 padding")
		_check(selected_status != null and choose_promotion.get_parent() == selected_status.get_parent() and choose_promotion.get_index() == selected_status.get_index() + 1, "Choose Promotion is not directly below Promotion Ready")
	var roster_detail := screen.find_child("EligibilityReason", true, false) as Label
	_check(roster_detail != null and roster_detail.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "Training roster metadata can be clipped with ellipsis")
	var roster_row := screen.find_child("Recruit_*", true, false) as Control
	_check(roster_row != null, "Training roster did not render a hoverable operator row")
	if roster_row != null:
		_check(_near(roster_row.custom_minimum_size.x, 560.0, 1.0), "desktop operator card is not fixed at 560px")
		_check(_has_detailed_stats(roster_row.tooltip_text), "Training roster tooltip omits detailed combat statistics")
	if inspector != null:
		_check(_has_detailed_stats(inspector.tooltip_text), "Training inspector tooltip omits detailed combat statistics")

	var text_scale_autoload := root.get_node("TextScale")
	text_scale_autoload.call("set_scale", 1.5)
	screen.call("_on_layout_mode_changed", screen.get("_layout_mode"))
	await _frames(4)
	outer = screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	body = screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	sort_select = screen.find_child("TrainingNameSort", true, false) as OptionButton
	var large_text_actions := screen.find_child("RosterActions", true, false) as BoxContainer
	_check(outer != null and outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "150% landscape Training is not scroll-owned")
	_check(body != null and body.vertical, "150% landscape Training did not stack roster and inspector")
	_check(sort_select != null and sort_select.custom_minimum_size.x >= 320.0, "150% Recruitment Order selector remains too narrow")
	_check(large_text_actions != null and large_text_actions.vertical, "150% Training actions did not stack")
	if large_text_actions != null:
		for child: Node in large_text_actions.get_children():
			if child is Button:
				_check((child as Button).custom_minimum_size.x >= 300.0, "150% Training action remains claustrophobic")
	text_scale_autoload.call("set_scale", 1.0)
	screen.call("_on_layout_mode_changed", screen.get("_layout_mode"))
	await _frames(4)

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
	choose_promotion = screen.find_child("ChoosePromotion", true, false) as Button
	_check(choose_promotion != null and _near(choose_promotion.custom_minimum_size.x, 260.0, 1.0), "portrait Choose Promotion does not use its compact wrapped width")
	if roster_actions != null:
		for child: Node in roster_actions.get_children():
			if child is Button:
				var action := child as Button
				_check(action.custom_minimum_size.x <= 260.0, "roster action exceeds the fixed compact width")
				_check(action.custom_minimum_size.y >= 84.0, "roster action lacks 12px top/bottom padding height")
				_check(_button_padding_at_least(action, 24.0, 12.0), "roster action style lacks requested 24x12 padding")
	if page != null and outer != null:
		_check(page.size.y > outer.size.y, "portrait Training does not expose vertical overflow for 1.5× content")
		_check(page.get_global_rect().position.x >= outer.get_global_rect().position.x - 1.0 and page.get_global_rect().end.x <= outer.get_global_rect().end.x + 1.0, "portrait Training page overflows horizontally")
	if dock != null:
		_check(dock.get_global_rect().end.y <= 1280.0, "portrait Training action dock overflows the viewport")

	root.size = Vector2i(1911, 826)
	await _frames(4)
	var boundary_grid := screen.find_child("TrainingRosterList", true, false) as GridContainer
	var boundary_scroll := screen.find_child("TrainingRosterScroll", true, false) as ScrollContainer
	var boundary_body := screen.find_child("TrainingRosterBody", true, false) as Control
	var boundary_page := screen.find_child("TrainingPage", true, false) as Control
	var boundary_inspector := screen.find_child("TrainingInspector", true, false) as Control
	_check(boundary_grid != null and boundary_grid.columns == 1, "two-column roster activates below its measured safe breakpoint")
	_check(boundary_scroll != null and _near(boundary_scroll.custom_minimum_size.x, 584.0, 1.0), "below-breakpoint roster does not return to its single-column rail")
	_check(boundary_body != null and boundary_page != null and _contained(boundary_body.get_global_rect(), boundary_page.get_global_rect(), 1.0), "below-breakpoint Training body is not contained")
	_check(boundary_inspector != null and boundary_inspector.get_global_rect().end.x <= 1911.0, "below-breakpoint inspector escapes the viewport")

	root.size = Vector2i(1912, 826)
	await _frames(4)
	boundary_grid = screen.find_child("TrainingRosterList", true, false) as GridContainer
	boundary_body = screen.find_child("TrainingRosterBody", true, false) as Control
	boundary_page = screen.find_child("TrainingPage", true, false) as Control
	boundary_inspector = screen.find_child("TrainingInspector", true, false) as Control
	_check(boundary_grid != null and boundary_grid.columns == 2, "two-column roster does not activate at the measured safe breakpoint")
	_check(boundary_body != null and boundary_page != null and _contained(boundary_body.get_global_rect(), boundary_page.get_global_rect(), 1.0), "safe-breakpoint two-column body is not contained")
	_check(boundary_inspector != null and boundary_inspector.get_global_rect().end.x <= 1912.0, "safe-breakpoint inspector escapes the viewport")

	root.size = Vector2i(2048, 826)
	await _frames(4)
	var roster_grid := screen.find_child("TrainingRosterList", true, false) as GridContainer
	roster_scroll = screen.find_child("TrainingRosterScroll", true, false) as ScrollContainer
	var dossier_wide := screen.find_child("SelectedOperatorDossier", true, false) as BoxContainer
	_check(roster_grid != null and roster_grid.columns == 2, "wide Training roster does not use two columns")
	_check(roster_scroll != null and _near(roster_scroll.custom_minimum_size.x, 1160.0, 1.0), "wide operator list is not doubled to the fixed 1120px two-card rail")
	_check(dossier_wide != null and not dossier_wide.vertical, "wide selected operator dossier does not keep portrait beside information")
	if roster_grid != null:
		var roster_cards: Array[Control] = []
		for child: Node in roster_grid.get_children():
			if child is Control:
				roster_cards.append(child as Control)
		_check(roster_cards.size() >= 2, "wide Training fixture does not expose two roster cards")
		if roster_cards.size() >= 2:
			_check(_near(roster_cards[0].custom_minimum_size.x, 560.0, 1.0) and _near(roster_cards[1].custom_minimum_size.x, 560.0, 1.0), "wide roster cards lost their fixed 560px width")
			_check(_near(roster_cards[0].global_position.y, roster_cards[1].global_position.y, 1.0), "first two operators are not rendered in one row")
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
	choose_promotion = screen.find_child("ChoosePromotion", true, false) as Button
	_check(choose_promotion != null and not choose_promotion.disabled, "advanced Training paths are unavailable in the eligible operator dossier")
	if choose_promotion != null and not choose_promotion.disabled:
		choose_promotion.emit_signal("pressed")
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
		_check(
			StringName(first_card.get("portrait_asset_id"))
			== StringName("portrait_specialization_%s_female" % first_card.get("class_id")),
			"female Recruit did not receive the matching female specialization portrait",
		)
		_check(portrait != null and portrait.texture != null, "generated specialization portrait did not load")
		_check(class_title != null and class_title.get_theme_font_size(&"font_size") >= 40, "specialization title typography was not doubled")
		_check(detail != null and detail.get_theme_font_size(&"font_size") >= 26, "specialization body typography was not doubled")
		_check(bool(first_card.call("uses_flat_color_states")), "specialization card still depends on ornamental selected-state graphics")
		_check(first_card.get_theme_stylebox(&"hover") is StyleBoxFlat, "specialization hover state is not a scalable flat background")
	_check(choose_path == null, "specialization screen still exposes a separate promotion approval action")
	if path_actions != null and path_back != null:
		_check(not path_actions.vertical and path_actions.alignment == BoxContainer.ALIGNMENT_END, "wide path actions are not a bottom-right row")
		_check(_near(path_back.size.x, 260.0, 1.0) and _near(path_back.size.y, 84.0, 1.0), "Back action does not retain enlarged path geometry")
		_check(path_back.get_global_rect().end.x >= path_actions.get_global_rect().end.x - 2.0, "path action is not flush to the bottom-right edge")
		_check(path_action_safe != null and path_action_safe.get_theme_constant(&"margin_left") == 60 and path_action_safe.get_theme_constant(&"margin_right") == 60, "path action bar does not preserve 60px side padding")
		var label := path_back.find_child("PresentationLabel", true, false) as Label
		var style := path_back.get_theme_stylebox(&"normal")
		_check(label != null and label.get_theme_font_size(&"font_size") >= 28 and not label.clip_text, "Back text is not enlarged and overflow-safe")
		_check(_near(label.offset_left, 24.0, 0.1) and _near(label.offset_top, 12.0, 0.1) and _near(label.offset_right, -24.0, 0.1) and _near(label.offset_bottom, -12.0, 0.1), "Back lacks 24x12 internal padding")
		_check(_near(style.content_margin_left, 24.0, 0.1) and _near(style.content_margin_top, 12.0, 0.1), "Back style does not retain requested internal padding")
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
	_check(choose_path == null, "portrait specialization screen exposes a separate approval action")
	if path_actions != null and path_back != null:
		_check(path_actions.alignment == BoxContainer.ALIGNMENT_END, "portrait path actions are not right-aligned")
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
	_check(choose_path == null, "wide specialization screen exposes a separate approval action after resizing")
	if path_back != null:
		_check(_near(path_back.size.x, 260.0, 1.0), "path action width changes after a resize cycle")

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


func _button_padding_at_least(
	button: Button, horizontal: float, vertical: float = -1.0,
) -> bool:
	if vertical < 0.0:
		vertical = horizontal
	var style := button.get_theme_stylebox("normal")
	return (
		style.content_margin_left >= horizontal
		and style.content_margin_right >= horizontal
		and style.content_margin_top >= vertical
		and style.content_margin_bottom >= vertical
	)


func _color_near(value: Color, expected: Color, tolerance: float) -> bool:
	return (
		absf(value.r - expected.r) <= tolerance
		and absf(value.g - expected.g) <= tolerance
		and absf(value.b - expected.b) <= tolerance
		and absf(value.a - expected.a) <= tolerance
	)


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
