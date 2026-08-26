extends SceneTree

const VIEWPORTS := {
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
		_dispose_mission(game)
		await process_frame
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


func _verify_layout(label: String, viewport: Vector2i) -> void:
	var shell := _mission.find_child("MissionCommandShell", true, false) as Control
	var workspace := _mission.find_child("MissionFullscreenWorkspace", true, false) as PanelContainer
	var surface := _mission.find_child("MissionCommandSurface", true, false) as Control
	var body := _mission.find_child("MissionBody", true, false) as GridContainer
	var actions := _mission.find_child("MissionActions", true, false) as GridContainer
	var field_panel := _mission.find_child("FieldTeamPanel", true, false) as PanelContainer
	var intel_panel := _mission.find_child("MissionIntelligencePanel", true, false) as PanelContainer
	_check(shell != null and bool(shell.get("full_safe_area")), "%s mission shell is not full-safe-area" % label)
	_check(workspace != null and workspace.get_theme_stylebox(&"panel") is StyleBoxEmpty, "%s retained the decorative outer mission frame" % label)
	_check(_inside(_mission, shell) and _inside(shell, workspace), "%s mission workspace exceeds the viewport" % label)
	_check(surface != null and _inside(workspace, surface), "%s mission surface exceeds the fullscreen workspace" % label)
	_check(body != null and field_panel != null and intel_panel != null, "%s mission body panels are missing" % label)
	if body != null:
		var portrait := viewport.y > viewport.x
		_check(body.columns == (1 if portrait else 2), "%s mission body uses the wrong column count" % label)
		if not portrait and field_panel != null and intel_panel != null:
			_check(field_panel.size.x >= intel_panel.size.x * 2.5, "%s mission intelligence did not shrink to the quarter-width rail" % label)
			_check(intel_panel.size.x <= viewport.x * 0.32, "%s mission intelligence remains oversized" % label)
	_check(actions != null and not _has_scroll_ancestor(actions), "%s mission actions are trapped in body scrolling" % label)
	if actions != null:
		_check(actions.columns == (1 if viewport.y > viewport.x else 3), "%s mission actions use the wrong column count" % label)
	for button_name: String in ["BackButton", "TrainingButton", "StartBattle"]:
		var button := _mission.find_child(button_name, true, false) as Button
		var presentation := button.get_node_or_null("PresentationLabel") as Label if button != null else null
		_check(button != null and presentation != null, "%s %s presentation is missing" % [label, button_name])
		if button != null and presentation != null:
			_check(_inside(button, presentation), "%s %s label overflows its button" % [label, button_name])
			_check(not presentation.clip_text, "%s %s clips its presentation label" % [label, button_name])
			if button_name != "BackButton":
				_check(presentation.text.contains("\n") and presentation.autowrap_mode == TextServer.AUTOWRAP_OFF, "%s %s does not use its explicit two-line layout" % [label, button_name])
	for label_name: String in [
		"MissionTitle", "FieldTeamHeading", "PickCounter", "MissionIntelHeading",
		"OBJECTIVEValue", "THREATValue", "WHYITMATTERSValue", "FIELDNOTEValue",
		"TacticalHint", "LoadoutStrip", "SelectedSquadLine", "ReadinessCopy",
	]:
		var text_label := _mission.find_child(label_name, true, false) as Label
		_check(text_label != null, "%s %s is missing" % [label, label_name])
		if text_label != null:
			_check(text_label.size.x > 0.0, "%s %s collapsed horizontally" % [label, label_name])
			_check(text_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s %s cannot wrap safely" % [label, label_name])
	var training := _mission.find_child("TrainingButton", true, false) as Button
	var back := _mission.find_child("BackButton", true, false) as Button
	var filter_input := _mission.find_child("DeploymentNameFilter", true, false) as LineEdit
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	_check(filter_input != null and filter_input.get_theme_font_size(&"font_size") >= 24, "%s name filter is below the 1.5x readable density floor" % label)
	_check(sort_select != null and not sort_select.fit_to_longest_item, "%s sort control can force toolbar overflow" % label)
	var active_tab := _mission.find_child("ActiveRosterTab", true, false) as Button
	var fallen_tab := _mission.find_child("FallenRosterTab", true, false) as Button
	for tab: Button in [active_tab, fallen_tab]:
		_check(tab != null, "%s roster status tab is missing" % label)
		if tab != null:
			_check(tab.custom_minimum_size.x >= 176.0 and tab.custom_minimum_size.y >= 54.0, "%s roster tab lacks full text padding" % label)
			_check(tab.get_theme_font_size(&"font_size") >= 27, "%s roster tab text is below the global 1.5x scale" % label)
	var operator_grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	if operator_grid != null:
		_check(operator_grid.columns == (1 if viewport.y > viewport.x else 2), "%s operator grid does not use the split-card column contract" % label)
		for child: Node in operator_grid.get_children():
			if child is Button:
				var card_label := child.get_node_or_null("PresentationLabel") as Label
				var portrait := child.get_node_or_null("OperatorPortrait") as TextureRect
				_check(card_label != null and card_label.get_theme_font_size(&"font_size") >= 24, "%s operator-card copy is below the global 1.5x scale" % label)
				_check(portrait != null, "%s operator-card portrait pane is missing" % label)
				if card_label != null:
					_check(_inside(child as Control, card_label), "%s operator-card information pane overflows" % label)
					_check(card_label.offset_left >= 22.0, "%s operator-card information padding is below 22px" % label)
					_check(-card_label.offset_bottom >= 16.0, "%s operator-card bottom padding is below 16px" % label)
					_check(card_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and card_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s operator information is not centered in its pane" % label)
				if portrait != null:
					_check(_inside(child as Control, portrait), "%s operator portrait pane overflows" % label)
					_check(portrait.size.x >= 90.0 and portrait.size.y >= (child as Control).size.y - 24.0, "%s operator portrait is not enlarged" % label)
					_check(card_label == null or card_label.get_global_rect().end.x <= portrait.get_global_rect().position.x + EPSILON, "%s operator information overlaps the portrait pane" % label)
	var command_scroll := _mission.find_child("MissionCommandScroll", true, false) as ScrollContainer
	if label == "regular" and command_scroll != null:
		_check(command_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "regular mission still uses document scrolling")
	if training != null and back != null:
		_check(is_equal_approx(training.custom_minimum_size.x, 168.0), "%s Train Operators is not 30 percent shorter" % label)
		_check(is_equal_approx(back.custom_minimum_size.x, 119.0), "%s Back is not 30 percent shorter" % label)
		_check(training.get_theme_stylebox(&"normal") is StyleBoxFlat, "%s Train Operators still uses the strike-through ornament" % label)
	var faction_symbol := _mission.find_child("LunarisReliquarySymbol", true, false) as TextureRect
	_check(faction_symbol != null, "%s First Stand faction symbol is missing" % label)
	if faction_symbol != null and faction_symbol.texture != null:
		_check(faction_symbol.texture.resource_path.ends_with(".png"), "%s First Stand symbol does not use the transparent PNG" % label)


func _has_scroll_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


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
