extends SceneTree

const VIEWPORTS := {
	"wide": Vector2i(1920, 900),
	"regular": Vector2i(1280, 720),
	"compact": Vector2i(1024, 576),
	"portrait": Vector2i(720, 1280),
	"narrow": Vector2i(390, 844),
}
const EPSILON := 1.0

var _failures: Array[String] = []
var _mission: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "mission layout fixture failed")
	game.set("selected_stage_id", &"s1")
	for label: String in VIEWPORTS:
		root.size = VIEWPORTS[label]
		_mission = load("res://scenes/squad_select.tscn").instantiate() as Control
		root.add_child(_mission)
		await process_frame
		await process_frame
		await process_frame
		_verify_layout(label, VIEWPORTS[label])
		if label == "regular":
			await _verify_deploy_ready_pulse()
			await _verify_recruitment_transaction(game)
			await _verify_launch_retry_feedback(game)
		_dispose_mission(game)
		await process_frame
	await _verify_managed_order_rail(game)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _verify_managed_order_rail(game: Node) -> void:
	root.size = Vector2i(1280, 1100)
	_mission = load("res://scenes/squad_select.tscn").instantiate() as Control
	root.add_child(_mission)
	await process_frame
	await process_frame
	await process_frame
	var order_scroll := _mission.find_child("SelectedSquadOrderScroll", true, false) as ScrollContainer
	var order_empty := _mission.find_child("SelectedSquadOrderEmpty", true, false) as Label
	_check(order_scroll != null and order_empty != null, "managed selected-squad guidance is missing")
	_check(order_empty != null and order_empty.autowrap_mode == TextServer.AUTOWRAP_OFF, "managed selected-squad guidance can collapse into vertical character wrapping")
	_check(order_empty != null and order_empty.custom_minimum_size.x >= 560.0 and order_empty.custom_minimum_size.y >= 44.0, "managed selected-squad guidance lacks stable horizontal rail geometry")
	_check(order_empty != null and order_scroll != null and order_empty.size.y <= order_scroll.size.y + EPSILON, "managed selected-squad guidance exceeds its scroll viewport vertically")
	_dispose_mission(game)
	await process_frame


func _verify_layout(label: String, viewport: Vector2i) -> void:
	var shell := _mission.find_child("MissionCommandShell", true, false) as Control
	var workspace := _mission.find_child("MissionFullscreenWorkspace", true, false) as PanelContainer
	var surface := _mission.find_child("MissionCommandSurface", true, false) as Control
	var body := _mission.find_child("MissionBody", true, false) as GridContainer
	var actions := _mission.find_child("MissionActions", true, false) as GridContainer
	var field_panel := _mission.find_child("FieldTeamPanel", true, false) as PanelContainer
	var intel_panel := _mission.find_child("MissionIntelligencePanel", true, false) as PanelContainer
	var recruit_desk_center := _mission.find_child("BasicRecruitDeskCenter", true, false) as HBoxContainer
	var recruit_desk := _mission.find_child("BasicRecruitDesk", true, false) as PanelContainer
	var recruit_grid := _mission.find_child("BasicRecruitGrid", true, false) as GridContainer
	var recruit_header := _mission.find_child("BasicRecruitHeader", true, false) as BoxContainer
	var recruit_title := _mission.find_child("BasicRecruitTitle", true, false) as Label
	var recruit_body := _mission.find_child("BasicRecruitBody", true, false) as Label
	var recruit_marks := _mission.find_child("BasicRecruitMarks", true, false) as Label
	var recruit_roster := _mission.find_child("BasicRecruitRoster", true, false) as Label
	var hire_button := _mission.find_child("HireBasicRecruit", true, false) as Button
	var hire_cost_icon := _mission.find_child("BasicRecruitCostIcon", true, false) as TextureRect
	var hire_cost_label := _mission.find_child("BasicRecruitCostLabel", true, false) as Label
	var hire_status := _mission.find_child("BasicRecruitStatus", true, false) as Label
	var launch_status := _mission.find_child("ReadinessCopy", true, false) as Label
	_check(shell != null and bool(shell.get("full_safe_area")), "%s mission shell is not full-safe-area" % label)
	_check(workspace != null and workspace.get_theme_stylebox(&"panel") is StyleBoxEmpty, "%s retained the decorative outer mission frame" % label)
	_check(
		_inside(_mission, shell) and _inside(shell, workspace),
		"%s mission workspace exceeds the viewport: mission=%s shell=%s workspace=%s" % [
			label, _mission.get_global_rect(), shell.get_global_rect(), workspace.get_global_rect(),
		],
	)
	_check(surface != null and _inside(workspace, surface), "%s mission surface exceeds the fullscreen workspace" % label)
	_check(body != null and field_panel != null and intel_panel != null, "%s mission body panels are missing" % label)
	if body != null:
		var portrait := viewport.y > viewport.x
		_check(body.columns == (1 if portrait else 2), "%s mission body uses the wrong column count" % label)
		if not portrait and field_panel != null and intel_panel != null:
			var panel_width := field_panel.size.x + intel_panel.size.x
			var field_ratio := field_panel.size.x / maxf(1.0, panel_width)
			var intel_ratio := intel_panel.size.x / maxf(1.0, panel_width)
			_check(absf(field_ratio - 0.60) <= 0.035, "%s Field Team panel is not approximately 60 percent wide" % label)
			_check(absf(intel_ratio - 0.40) <= 0.035, "%s Mission Intelligence panel is not approximately 40 percent wide" % label)
	_check(recruit_desk != null and intel_panel != null and intel_panel.is_ancestor_of(recruit_desk), "%s Company Reinforcements is not inside Mission Intelligence" % label)
	_check(recruit_desk != null and field_panel != null and not field_panel.is_ancestor_of(recruit_desk), "%s Company Reinforcements remained inside Field Team Selection" % label)
	_check(recruit_grid != null and recruit_grid.columns == 1, "%s Company Reinforcements is not a stable single-column stack" % label)
	_check(recruit_title != null and recruit_title.get_theme_font_size(&"font_size") >= 14, "%s Company Reinforcements title is below the compact readability floor" % label)
	_check(recruit_body == null, "%s redundant Company Reinforcements body copy still exists" % label)
	_check(recruit_roster == null, "%s personnel-ready copy still exists" % label)
	_check(recruit_header != null and recruit_title != null and recruit_marks != null and recruit_title.get_parent() == recruit_header and recruit_marks.get_parent() != null and recruit_marks.get_parent().get_parent() == recruit_header, "%s shard balance is not on the Company Reinforcements title row" % label)
	_check(recruit_title != null and recruit_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s Company Reinforcements title is not centered" % label)
	_check(recruit_marks != null and recruit_title != null and recruit_marks.get_global_rect().position.x >= recruit_title.get_global_rect().end.x - EPSILON, "%s shard balance is not top-right of the title" % label)
	_check(recruit_desk_center != null and recruit_desk_center.get_index() == recruit_desk_center.get_parent().get_child_count() - 1, "%s Company Reinforcements is not the last Mission Intelligence section" % label)
	_check(hire_button != null and hire_button.focus_mode == Control.FOCUS_ALL, "%s recruit action is not keyboard focusable" % label)
	_check(hire_status != null and hire_status.accessibility_live == AccessibilityServer.LIVE_POLITE, "%s recruit status is not a polite live region" % label)
	_check(launch_status != null and launch_status.accessibility_live == AccessibilityServer.LIVE_POLITE, "%s launch status is not a polite live region" % label)
	if recruit_desk != null and intel_panel != null:
		_check(_inside_horizontally(intel_panel, recruit_desk), "%s Company Reinforcements exceeds Mission Intelligence horizontally" % label)
		_check(is_equal_approx(recruit_desk.custom_minimum_size.x, 220.0), "%s Company Reinforcements does not use its compact fixed width" % label)
		_check(absf(recruit_desk.get_global_rect().get_center().x - intel_panel.get_global_rect().get_center().x) <= 6.0, "%s Company Reinforcements is not horizontally centered in Mission Intelligence" % label)
	if hire_button != null:
		var hire_content := hire_button.get_node_or_null("BasicRecruitActionContent") as HBoxContainer
		_check(hire_content != null and _inside(hire_button, hire_content), "%s recruit action content overflows" % label)
		_check(is_equal_approx(hire_button.custom_minimum_size.x, 100.0), "%s recruit action does not use the requested fixed 100px width" % label)
		_check(hire_button.custom_minimum_size.y >= 72.0, "%s recruit action cannot contain 12px vertical padding" % label)
		_check(hire_button.icon == null and hire_cost_icon != null and hire_cost_icon.texture != null, "%s recruit action lacks its explicit shard sprite" % label)
		_check(hire_cost_label != null and hire_cost_label.text == "5" and hire_cost_icon.get_index() + 1 == hire_cost_label.get_index(), "%s shard sprite is not immediately before the exact hire cost" % label)
		_check(hire_status != null and hire_status.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s recruit status copy is not centered" % label)
	_check(actions != null and not _has_scroll_ancestor(actions), "%s mission actions are trapped in body scrolling" % label)
	if actions != null:
		var expected_action_columns := 1 if viewport.y > viewport.x or viewport.x < 1280 else 3
		_check(actions.columns == expected_action_columns, "%s mission actions use the wrong column count" % label)
	for button_name: String in ["BackButton", "TrainingButton", "StartBattle"]:
		var button := _mission.find_child(button_name, true, false) as Button
		var presentation := button.get_node_or_null("PresentationLabel") as Label if button != null else null
		_check(button != null and presentation != null, "%s %s presentation is missing" % [label, button_name])
		if button != null and presentation != null:
			_check(_inside(_mission, button), "%s %s actual hitbox exceeds the viewport" % [label, button_name])
			_check(button.size.x + EPSILON >= button.custom_minimum_size.x and button.size.y + EPSILON >= button.custom_minimum_size.y, "%s %s actual hitbox collapsed below its minimum" % [label, button_name])
			_check(_inside(button, presentation), "%s %s label overflows its button" % [label, button_name])
			_check(not presentation.clip_text, "%s %s clips its presentation label" % [label, button_name])
			if button_name == "TrainingButton":
				_check(presentation.text.contains("\n") and presentation.autowrap_mode == TextServer.AUTOWRAP_OFF, "%s %s does not use its explicit two-line layout" % [label, button_name])
			elif button_name == "StartBattle":
				_check(presentation.text == "DEPLOY SQUAD", "%s Deploy Squad is not rendered on one line" % label)
				_check(not presentation.text.contains("\n") and presentation.autowrap_mode == TextServer.AUTOWRAP_OFF, "%s Deploy Squad can wrap" % label)
	for label_name: String in [
		"MissionTitle", "FieldTeamHeading", "PickCounter", "MissionIntelHeading",
		"OBJECTIVEValue", "THREATValue", "WHYITMATTERSValue",
		"TacticalHint", "LoadoutStrip", "SelectedSquadLine", "ReadinessCopy",
	]:
		var text_label := _mission.find_child(label_name, true, false) as Label
		_check(text_label != null, "%s %s is missing" % [label, label_name])
		if text_label != null:
			_check(text_label.size.x > 0.0, "%s %s collapsed horizontally" % [label, label_name])
			_check(text_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s %s cannot wrap safely" % [label, label_name])
	_check(_mission.find_child("FIELDNOTELabel", true, false) == null and _mission.find_child("FIELDNOTEValue", true, false) == null, "%s Field Note was not removed" % label)
	var intel_heading := _mission.find_child("MissionIntelHeading", true, false) as Label
	var loadout_heading := _mission.find_child("LoadoutHeading", true, false) as Label
	var loadout_inset := _mission.find_child("LoadoutHeadingInset", true, false) as MarginContainer
	var selected_line := _mission.find_child("SelectedSquadLine", true, false) as Label
	_check(loadout_heading != null and intel_heading != null and loadout_heading.get_theme_font_size(&"font_size") == intel_heading.get_theme_font_size(&"font_size"), "%s Loadout is not promoted to the Mission Intelligence H1 style" % label)
	_check(loadout_inset != null and loadout_inset.get_theme_constant(&"margin_top") >= 24, "%s Loadout lacks top padding" % label)
	_check(selected_line != null and selected_line.text.begins_with("Field Team:") and not selected_line.text.contains("//"), "%s Field Team summary does not use the requested colon" % label)
	var training := _mission.find_child("TrainingButton", true, false) as Button
	var back := _mission.find_child("BackButton", true, false) as Button
	var deploy := _mission.find_child("StartBattle", true, false) as Button
	var filter_input := _mission.find_child("DeploymentNameFilter", true, false) as LineEdit
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	var order_panel := _mission.find_child("SelectedSquadOrderPanel", true, false) as PanelContainer
	var order_scroll := _mission.find_child("SelectedSquadOrderScroll", true, false) as ScrollContainer
	var order_rail := _mission.find_child("SelectedSquadOrder", true, false) as HBoxContainer
	var order_empty := _mission.find_child("SelectedSquadOrderEmpty", true, false) as Label
	var roster_scroll := _mission.find_child("OperatorRosterScroll", true, false) as ScrollContainer
	_check(filter_input != null and filter_input.get_theme_font_size(&"font_size") >= 24, "%s name filter is below the 1.5x readable density floor" % label)
	_check(sort_select != null and not sort_select.fit_to_longest_item, "%s sort control can force toolbar overflow" % label)
	_check(sort_select != null and sort_select.size_flags_horizontal == Control.SIZE_SHRINK_END and sort_select.custom_minimum_size.x >= 300.0 and sort_select.custom_minimum_size.y >= 54.0, "%s Recruit Order does not tightly wrap its padded label" % label)
	if sort_select != null:
		var sort_style := sort_select.get_theme_stylebox(&"normal")
		_check(sort_style.content_margin_left >= 24.0 and sort_style.content_margin_right >= 24.0 and sort_style.content_margin_top >= 12.0 and sort_style.content_margin_bottom >= 12.0, "%s Recruit Order lacks 24px horizontal and 12px vertical padding" % label)
		_check(sort_select != null and sort_select.item_count >= 9, "%s sort control lacks cost, rarity, level, or name modes" % label)
		_check(sort_select != null and sort_select.accessibility_name == "Sort operators" and not sort_select.accessibility_description.is_empty(), "%s sort control lacks accessible naming" % label)
	_check(order_panel != null and field_panel != null and _inside(field_panel, order_panel), "%s selected-squad order rail exceeds Field Team" % label)
	_check(order_rail != null, "%s selected-squad drag rail is missing" % label)
	_check(order_scroll != null and order_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and order_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s selected-squad guidance does not use horizontal-only scrolling" % label)
	_check(order_empty != null and order_empty.autowrap_mode == TextServer.AUTOWRAP_OFF, "%s selected-squad guidance can collapse into vertical character wrapping" % label)
	_check(order_empty != null and order_empty.custom_minimum_size.x >= 560.0 and order_empty.custom_minimum_size.y >= 44.0, "%s selected-squad guidance lacks stable horizontal rail geometry" % label)
	_check(order_empty != null and order_scroll != null and order_empty.size.y <= order_scroll.size.y + EPSILON, "%s selected-squad guidance exceeds its scroll viewport vertically" % label)
	_check(roster_scroll != null and roster_scroll.custom_minimum_size.y >= 240.0, "%s operator list lacks a usable local scroll viewport" % label)
	var active_tab := _mission.find_child("ActiveRosterTab", true, false) as Button
	var fallen_tab := _mission.find_child("FallenRosterTab", true, false) as Button
	var all_tab := _mission.find_child("AllRosterTab", true, false) as Button
	for tab: Button in [active_tab, fallen_tab, all_tab]:
		_check(tab != null, "%s roster status tab is missing" % label)
		if tab != null:
			var expected_tab_width := minf(352.0, maxf(176.0, viewport.x - 96.0)) if viewport.y > viewport.x else 352.0
			var expected_tab_height := 54.0
			_check(is_equal_approx(tab.custom_minimum_size.x, expected_tab_width) and tab.custom_minimum_size.y >= expected_tab_height, "%s roster tab is not doubled or safely contained" % label)
			_check(tab.get_theme_font_size(&"font_size") >= 27, "%s roster tab text is below the global 1.5x scale" % label)
	_check(all_tab != null and all_tab.visible, "%s all-operators filter is not visible" % label)
	var all_factions := _mission.find_child("AllFactionFilter", true, false) as Button
	_check(all_factions != null and all_factions.get_parent() != null and not (all_factions.get_parent() as Control).visible, "%s faction filter row remains visible" % label)
	for faction_name: String in ["SolcrestAccordFactionFilter", "VesperCircuitFactionFilter", "LunarisReliquaryFactionFilter", "CrimsonAegisFactionFilter"]:
		var faction := _mission.find_child(faction_name, true, false) as Button
		_check(faction != null, "%s %s is missing" % [label, faction_name])
	var operator_grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	if operator_grid != null:
		var expected_columns := 1 if viewport.y > viewport.x or viewport.x < 1280 else 2
		_check(operator_grid.columns == expected_columns, "%s operator grid does not use the requested responsive two-column layout" % label)
		for child: Node in operator_grid.get_children():
			if child is Button:
				var expected_width := (
					minf(640.0, maxf(240.0, viewport.x - 96.0))
					if viewport.y > viewport.x
					else minf(640.0, maxf(320.0, viewport.x * 0.60 - 96.0))
					if viewport.x < 1280
					else minf(520.0, maxf(240.0, (viewport.x * 0.60 - 108.0) * 0.5))
				)
				_check(absf((child as Button).size.x - expected_width) <= EPSILON, "%s operator card does not fit the responsive grid target" % label)
				var card_label := child.get_node_or_null("PresentationLabel") as Label
				var portrait := child.get_node_or_null("OperatorPortrait") as TextureRect
				var hover_glow := child.get_node_or_null("OperatorHoverGlow") as Panel
				_check(card_label != null and card_label.get_theme_font_size(&"font_size") >= 24, "%s operator-card copy is below the global 1.5x scale" % label)
				_check(portrait != null, "%s operator-card portrait pane is missing" % label)
				_check(bool((child as Button).get_meta(&"operator_feedback_enabled", false)), "%s operator-card feedback metadata is missing" % label)
				_check(bool((child as Button).get_meta(&"operator_hover_glow_enabled", false)) and hover_glow != null, "%s operator-card luminous hover border is missing" % label)
				var normal_style := (child as Button).get_theme_stylebox(&"normal")
				var hover_style := (child as Button).get_theme_stylebox(&"hover")
				if normal_style is StyleBoxTexture and hover_style is StyleBoxTexture:
					_check((normal_style as StyleBoxTexture).modulate_color.is_equal_approx((hover_style as StyleBoxTexture).modulate_color), "%s operator hover washes out the entire card instead of using its glow border" % label)
				if hover_glow != null:
					var glow_style := hover_glow.get_theme_stylebox(&"panel") as StyleBoxFlat
					_check(glow_style != null and glow_style.border_width_left >= 2 and glow_style.shadow_size >= 8, "%s operator-card hover border is not luminous" % label)
				if card_label != null:
					_check(_inside(child as Control, card_label), "%s %s operator-card information pane overflows" % [label, child.name])
					_check(card_label.offset_left >= 24.0, "%s operator-card horizontal padding is below 24px" % label)
					_check(card_label.offset_top >= 12.0 and -card_label.offset_bottom >= 12.0, "%s operator-card vertical padding is below 12px" % label)
					_check(card_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s operator information is not centered in its pane" % label)
				if portrait != null:
					_check(_inside(child as Control, portrait), "%s operator portrait pane overflows" % label)
					var expected_portrait_width := minf(180.0, maxf(90.0, (child as Control).size.x * 0.30))
					_check(portrait.size.x >= expected_portrait_width and portrait.size.y >= (child as Control).size.y - 24.0, "%s operator portrait is not enlarged with the doubled card" % label)
					_check(card_label == null or card_label.get_global_rect().end.x <= portrait.get_global_rect().position.x + EPSILON, "%s operator information overlaps the portrait pane" % label)
	var command_scroll := _mission.find_child("MissionCommandScroll", true, false) as ScrollContainer
	if label == "regular" and command_scroll != null:
		_check(command_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "regular mission cannot scroll its expanded Field Team workspace")
		var footer := _mission.find_child("MissionActionDock", true, false) as BoxContainer
		_check(footer != null and not footer.vertical, "regular mission footer collapses the Field Team into a narrow strip")
	if training != null and back != null and deploy != null:
		var expected_training_width := 220.0 if label == "regular" else (minf(336.0, viewport.x - 96.0) if viewport.y > viewport.x else 336.0)
		var expected_back_width := 180.0 if label == "regular" else 238.0
		var expected_deploy_width := 400.0 if label == "regular" else (minf(588.0, maxf(220.0, viewport.x - 96.0)) if viewport.y > viewport.x else 588.0)
		_check(is_equal_approx(training.custom_minimum_size.x, expected_training_width), "%s Train Operators does not match its contained responsive width" % label)
		_check(is_equal_approx(back.custom_minimum_size.x, expected_back_width), "%s Back does not match its contained responsive width" % label)
		_check(is_equal_approx(deploy.custom_minimum_size.x, expected_deploy_width), "%s Deploy Squad is not exactly twice its prior width" % label)
		for action: Button in [back, training, deploy]:
			_check(is_equal_approx(action.custom_minimum_size.y, 112.0), "%s %s does not share the 112px deployment action height" % [label, action.name])
			_check(absf(action.size.y - deploy.size.y) <= EPSILON, "%s %s does not match Deploy Squad's rendered height" % [label, action.name])
		var deploy_copy := deploy.get_node_or_null("PresentationLabel") as Label
		_check(deploy_copy != null and deploy_copy.get_theme_color(&"font_color").is_equal_approx(Color("fff8e7")), "%s Deploy Squad does not use the high-contrast ivory label" % label)
		_check(deploy_copy != null and deploy_copy.get_theme_constant(&"outline_size") >= 5, "%s Deploy Squad lacks its dark readability outline" % label)
		_check(deploy_copy != null and deploy_copy.get_theme_color(&"font_outline_color").get_luminance() < 0.05, "%s Deploy Squad outline is not dark enough against gold" % label)
		_check(training.get_theme_stylebox(&"normal") is StyleBoxFlat, "%s Train Operators still uses the strike-through ornament" % label)
		_check(actions.get_theme_constant(&"h_separation") >= 28, "%s action gap remains claustrophobic" % label)
	var faction_symbol := _mission.find_child("LunarisReliquarySymbol", true, false) as TextureRect
	_check(faction_symbol != null, "%s First Stand faction symbol is missing" % label)
	if faction_symbol != null and faction_symbol.texture != null:
		_check(faction_symbol.texture.resource_path.ends_with(".png"), "%s First Stand symbol does not use the transparent PNG" % label)


func _verify_recruitment_transaction(game: Node) -> void:
	var i18n := root.get_node_or_null("I18n")
	var recruit_title := _mission.find_child("BasicRecruitTitle", true, false) as Label
	var recruit_body := _mission.find_child("BasicRecruitBody", true, false) as Label
	var hire_button := _mission.find_child("HireBasicRecruit", true, false) as Button
	var hire_action_label := _mission.find_child("BasicRecruitActionLabel", true, false) as Label
	var hire_cost_icon := _mission.find_child("BasicRecruitCostIcon", true, false) as TextureRect
	var hire_cost_label := _mission.find_child("BasicRecruitCostLabel", true, false) as Label
	var hire_marks := _mission.find_child("BasicRecruitMarks", true, false) as Label
	var hire_currency := _mission.find_child("BasicRecruitCurrency", true, false) as HBoxContainer
	var hire_icon := hire_currency.find_child("ResonanceShardIcon", true, false) as TextureRect if hire_currency != null else null
	var hire_status := _mission.find_child("BasicRecruitStatus", true, false) as Label
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	_check(hire_button != null and not hire_button.disabled, "Field Team five-shard recruit action is unavailable")
	_check(hire_button != null and hire_button.icon == null and hire_button.text.is_empty() and hire_button.accessibility_name.contains("5") and not hire_button.accessibility_name.contains("MARKS"), "Field Team recruit action still uses the legacy native presentation or wording")
	_check(hire_action_label != null and hire_action_label.text == "HIRE" and hire_cost_icon != null and hire_cost_icon.texture != null and hire_cost_label != null and hire_cost_label.text == "5", "Field Team recruit action does not expose its explicit sprite-backed exact price")
	_check(hire_marks != null and hire_marks.text == "120" and hire_icon != null and hire_icon.texture != null, "Field Team does not show the current shard balance")
	_check(hire_currency != null and hire_currency.tooltip_text.contains("ordinary salvage") and hire_currency.tooltip_text.contains("no anima or souls"), "Field Team Marks balance is not explained as ordinary soul-free campaign payment")
	_check(hire_button != null and hire_button.tooltip_text.contains("ordinary salvage") and hire_button.tooltip_text.contains("no anima or souls"), "Field Team recruit action lacks its ordinary Marks explanation")
	_check(hire_button != null and not hire_button.tooltip_text.contains("5, 5"), "Field Team shard tooltip duplicates its exact cost")
	_check(recruit_body == null, "Field Team still creates redundant recruitment body copy")
	_check(_mission.find_child("BasicRecruitRoster", true, false) == null, "Field Team still creates personnel-ready copy")
	_check(ResonanceCurrencyDisplay.tooltip_copy("", &"marks").contains("ordinary salvage") and ResonanceCurrencyDisplay.tooltip_copy("", &"marks").contains("no anima or souls"), "Marks are not explained as ordinary soul-free campaign payment")
	if i18n != null:
		_check(bool(i18n.call("set_locale", &"zh-CN")), "Field Team could not activate Chinese")
		await process_frame
		await process_frame
		_check(recruit_title != null and recruit_title.text == "连队增援", "Field Team recruitment title did not refresh to Chinese")
		_check(hire_button != null and hire_button.accessibility_name.contains("招募") and hire_button.accessibility_name.contains("5") and hire_action_label != null and hire_action_label.text == "招募" and hire_cost_icon != null and hire_cost_icon.texture != null, "Field Team icon-backed recruitment action did not refresh to Chinese")
		_check(hire_marks != null and hire_marks.text == "120", "Field Team shard amount changed during Chinese refresh")
		_check(hire_currency.tooltip_text.contains("普通打捞物") and hire_button.tooltip_text.contains("不含anima或灵魂"), "Field Team ordinary-Marks tooltips did not refresh to Chinese")
		_check(hire_status != null and hire_status.text.contains("基础新兵合约"), "Field Team recruitment status did not refresh to Chinese")
		_check(sort_select != null and sort_select.accessibility_name == "干员排序" and _sort_item_text(sort_select, &"cost_asc") == "部署费用从低到高", "Field Team cost sorting did not refresh to Chinese")
		_check(bool(i18n.call("set_locale", &"en-US")), "Field Team could not restore English")
		await process_frame
		await process_frame
		_check(sort_select != null and sort_select.accessibility_name == "Sort operators" and _sort_item_text(sort_select, &"cost_desc") == "Cost high–low", "Field Team cost sorting did not restore English")
	var projection_before: Dictionary = game.call("campaign_projection")
	if hire_button != null:
		hire_button.pressed.emit()
		await process_frame
		await process_frame
	var projection_after: Dictionary = game.call("campaign_projection")
	_check(int(projection_after.get("marks", 0)) == int(projection_before.get("marks", 0)) - 5, "Field Team hire charged the wrong amount")
	_check((projection_after.get("ready_heroes", []) as Array).size() == (projection_before.get("ready_heroes", []) as Array).size() + 1, "Field Team hire did not add exactly one Recruit")
	var newest: Dictionary = (projection_after.get("ready_heroes", []) as Array)[-1]
	_check(newest.get("recruit_source") == "basic_hire" and newest.get("source_id") == "mission_control", "Field Team hire bypassed the authoritative source contract")
	_check(hire_marks != null and hire_marks.text == "115", "Field Team did not refresh the shard balance")
	_check(hire_status != null and hire_status.text.contains("JOINED COMPANY MANUS") and hire_status.text.contains("115 MARKS REMAIN"), "Field Team did not announce the accepted Company Manus hire and exact Marks receipt")
	_check(hire_button != null and hire_button.has_focus(), "accepted Field Team hire did not restore action focus")
	_check(_mission.find_child("Pick_%s" % newest.get("hero_id", ""), true, false) != null, "new Recruit did not appear in the Field Team roster")
	var revision_after_hire := int(projection_after.get("save_revision", 0))
	game.set("_pending_promotion_mutation", RefCounted.new())
	if hire_button != null:
		hire_button.pressed.emit()
		await process_frame
		await process_frame
	_check(hire_button != null and not hire_button.disabled and hire_button.has_focus(), "rejected Field Team hire did not restore retry focus")
	_check(hire_status != null and hire_status.text.contains("pending Company command"), "rejected Field Team hire did not explain command serialization")
	_check(int(game.call("campaign_projection").get("save_revision", 0)) == revision_after_hire, "rejected Field Team hire advanced the campaign")
	game.set("_pending_promotion_mutation", null)
	game.set("_pending_recruitment_mutation", RefCounted.new())
	var blocked_pull: Dictionary = game.call("pull_premium_hero")
	var blocked_rename: Dictionary = game.call(
		"rename_hero", String(newest.get("hero_id", "")), "Sentinel",
	)
	var launch_squad: Array[StringName] = [StringName(newest.get("hero_id", ""))]
	var blocked_launch: Dictionary = game.call("start_stage", &"s1", launch_squad, false)
	var blocked_promotion: Dictionary = game.call("training_call", &"commit", [])
	var blocked_generic: Dictionary = game.call("commit_campaign_command", {})
	for blocked: Dictionary in [
		blocked_pull, blocked_rename, blocked_launch, blocked_promotion, blocked_generic,
	]:
		_check(blocked.get("error_code") == &"strategic_mutation_pending", "pending Field Team hire did not serialize every strategic facade")
	_check(int(game.call("campaign_projection").get("save_revision", 0)) == revision_after_hire, "blocked strategic command advanced the campaign")
	game.set("_pending_recruitment_mutation", null)


func _verify_deploy_ready_pulse() -> void:
	var start := _mission.find_child("StartBattle", true, false) as Button
	var picks: Array[Button] = []
	for candidate: Node in _mission.find_children("Pick_*", "Button", true, false):
		var pick := candidate as Button
		if pick != null and not pick.disabled:
			picks.append(pick)
		if picks.size() == 3:
			break
	_check(start != null and picks.size() == 3, "ready-pulse fixture could not find a complete squad")
	if start == null or picks.size() != 3:
		return
	for pick: Button in picks:
		var hero: Dictionary = pick.get_meta(&"hero", {})
		var hero_id := StringName(hero.get("hero_id", &""))
		pick.set_pressed_no_signal(true)
		_mission.call("_on_pick_toggled", true, hero_id)
	await process_frame
	_check(not start.disabled, "full squad did not enable Deploy Squad")
	_check(bool(_mission.call("deploy_ready_pulse_active")), "full ready squad did not start the Deploy Squad pulse")
	_check(bool(start.get_meta(&"ready_pulse_active", false)), "Deploy Squad does not expose active pulse telemetry")
	await create_timer(0.42).timeout
	_check(start.scale.x > 1.001 and start.scale.x <= 1.019, "Deploy Squad ready pulse is absent or no longer subtle")
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	_mission.call("_refresh")
	await process_frame
	_check(not bool(_mission.call("deploy_ready_pulse_active")), "reduced motion did not suppress the Deploy Squad pulse")
	_check(start.scale.is_equal_approx(Vector2.ONE), "reduced motion did not restore Deploy Squad scale")
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	_mission.call("_refresh")
	await process_frame
	_check(bool(_mission.call("deploy_ready_pulse_active")), "Deploy Squad pulse did not recover after reduced motion was disabled")
	for pick: Button in picks:
		var hero: Dictionary = pick.get_meta(&"hero", {})
		var hero_id := StringName(hero.get("hero_id", &""))
		pick.set_pressed_no_signal(false)
		_mission.call("_on_pick_toggled", false, hero_id)
	await process_frame
	_check(not bool(_mission.call("deploy_ready_pulse_active")), "Deploy Squad pulse continued after the squad stopped being full")
	_check(start.scale.is_equal_approx(Vector2.ONE), "Deploy Squad did not reset after the ready pulse stopped")


func _verify_launch_retry_feedback(game: Node) -> void:
	var start := _mission.find_child("StartBattle", true, false) as Button
	var training := _mission.find_child("TrainingButton", true, false) as Button
	var status := _mission.find_child("ReadinessCopy", true, false) as Label
	var first_pick := _mission.find_child("Pick_*", true, false) as Button
	game.set("_pending_launch_mutation", RefCounted.new())
	_mission.call("_refresh")
	await process_frame
	_check(start != null and not start.disabled, "retryable Mission launch did not expose an enabled retry action")
	_check(start != null and start.text == "Retry Deployment", "retryable Mission launch action is not explicit")
	_check(status != null and status.text.contains("not saved"), "retryable Mission launch failure is silent")
	_check(status != null and status.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "retryable Mission launch failure is not an assertive live region")
	_check(training != null and training.disabled, "Training remained interactive behind a pending Mission launch")
	_check(first_pick != null and first_pick.disabled, "operator selection remained interactive behind a pending Mission launch")
	_check(bool(game.call("cancel_mission_launch_retry")), "Mission launch retry could not be safely cancelled")
	_mission.call("_refresh")
	await process_frame
	_check(start != null and start.disabled, "empty Mission selection did not restore the disabled Start gate")
	_check(training != null and not training.disabled, "Training did not recover after cancelling Mission launch retry")
	_check(status != null and status.accessibility_live == AccessibilityServer.LIVE_POLITE, "Mission launch status did not return to polite mode")


func _has_scroll_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


func _sort_item_text(select: OptionButton, mode: StringName) -> String:
	if select == null:
		return ""
	for index: int in select.item_count:
		if StringName(select.get_item_metadata(index)) == mode:
			return select.get_item_text(index)
	return ""


func _inside(parent: Control, child: Control) -> bool:
	if parent == null or child == null:
		return false
	var outer := parent.get_global_rect()
	var inner := child.get_global_rect()
	return (
		inner.position.x >= outer.position.x - EPSILON
		and inner.position.y >= outer.position.y - EPSILON
		and inner.end.x <= outer.end.x + EPSILON
		and inner.end.y <= outer.end.y + EPSILON
	)


func _inside_horizontally(parent: Control, child: Control) -> bool:
	if parent == null or child == null:
		return false
	var outer := parent.get_global_rect()
	var inner := child.get_global_rect()
	return inner.position.x >= outer.position.x - EPSILON and inner.end.x <= outer.end.x + EPSILON


func _dispose_mission(game: Node) -> void:
	if game.get("content") == _mission:
		game.set("content", null)
	if _mission != null and is_instance_valid(_mission):
		var parent := _mission.get_parent()
		if parent != null:
			parent.remove_child(_mission)
		_mission.free()
	_mission = null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MISSION_UI_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
