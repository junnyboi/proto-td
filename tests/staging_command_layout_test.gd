extends SceneTree

const VIEWPORT_CASES := [
	{"name": "standard", "size": Vector2i(1280, 720), "rail": true, "portrait": false},
	{"name": "tall", "size": Vector2i(1280, 1100), "rail": false, "portrait": false},
	{"name": "compact", "size": Vector2i(1024, 768), "rail": false, "portrait": false},
	{"name": "portrait", "size": Vector2i(720, 1280), "rail": false, "portrait": true},
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null, "Game autoload missing")
	_check(i18n != null, "I18n autoload missing")
	if game == null or i18n == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "Company Command fixture failed")
	game.set("selected_stage_id", &"s1")

	_check(bool(i18n.call("set_locale", &"en-US")), "English locale activation failed")
	for viewport_case: Dictionary in VIEWPORT_CASES:
		await _verify_case(game, viewport_case, "en-US")

	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	await _verify_case(game, VIEWPORT_CASES[0], "zh-CN")
	await _verify_case(game, VIEWPORT_CASES[3], "zh-CN")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")

	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _verify_case(game: Node, viewport_case: Dictionary, locale_id: String) -> void:
	var viewport_size: Vector2i = viewport_case["size"]
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	await process_frame
	await process_frame

	var staging := load("res://scenes/staging.tscn").instantiate() as Control
	root.add_child(staging)
	await process_frame
	await process_frame
	await process_frame

	var context := "%s/%s" % [locale_id, viewport_case["name"]]
	var top_bar := staging.find_child("TopCommandBar", true, false) as PanelContainer
	var identity_plate := staging.find_child("IdentityPlate", true, false) as PanelContainer
	var utility_plate := staging.find_child("UtilityPlate", true, false) as PanelContainer
	var exit_label := staging.find_child("ExitLabel", true, false) as Label
	var navigation := staging.find_child("NavigationRail", true, false) as PanelContainer
	var command_deck := staging.find_child("CommandDeck", true, false) as PanelContainer
	var command_sheet := staging.find_child("CommandSheet", true, false) as PanelContainer
	var command_heading := staging.find_child("CommandHeading", true, false) as Label
	var progress_text := staging.find_child("CampaignProgressText", true, false) as Label
	var next_label := staging.find_child("NextOperationLabel", true, false) as Label
	var mission_card := staging.find_child("NextOperationCard", true, false) as PanelContainer
	var mission_title := staging.find_child("NextOperationTitle", true, false) as Label
	var objective := staging.find_child("NextOperationObjective", true, false) as Label
	var mission_action := staging.find_child("MissionControlButton", true, false) as Button
	var mission_action_label := mission_action.find_child("PresentationLabel", true, false) as Label
	var operation_label := staging.find_child("OperationsLabel", true, false) as Label
	var operation_grid := staging.find_child("OperationGrid", true, false) as GridContainer

	_check(top_bar != null and top_bar.size.y >= 96.0, "%s: segmented top HUD is shorter than 96px" % context)
	_check(identity_plate != null and utility_plate != null, "%s: segmented identity/utility plates missing" % context)
	_check(exit_label != null and _contains(utility_plate, exit_label), "%s: Exit label escaped or touched its compact frame" % context)
	_check(command_deck != null and command_deck.visible, "%s: command deck missing" % context)
	_check(command_heading != null and _font_size(command_heading) >= 22, "%s: command heading below 22px" % context)
	_check(progress_text != null and _font_size(progress_text) >= 18, "%s: campaign progress below 18px" % context)
	_check(next_label != null and _font_size(next_label) >= 17, "%s: next-operation heading below 17px" % context)
	_check(mission_title != null and _font_size(mission_title) >= 24, "%s: mission title below 24px" % context)
	_check(objective != null and _font_size(objective) >= 18, "%s: mission body below 18px" % context)
	_check(mission_action != null and mission_action.custom_minimum_size.y >= 72.0, "%s: primary action below 72px" % context)
	_check(mission_action_label != null and _font_size(mission_action_label) >= 24, "%s: primary action type below 24px" % context)
	_check(operation_label != null and _font_size(operation_label) >= 18, "%s: operations heading below 18px" % context)
	_check(mission_card != null and _contains(mission_card, mission_title), "%s: mission title escaped its frame" % context)
	_check(mission_card != null and _contains(mission_card, objective), "%s: mission objective escaped its frame" % context)
	_check(objective.get_visible_line_count() == objective.get_line_count(), "%s: mission objective lines are clipped" % context)

	var deck_style := command_deck.get_theme_stylebox(&"panel") as StyleBoxTexture
	var mission_style := mission_card.get_theme_stylebox(&"panel") as StyleBoxTexture
	_check(deck_style != null and deck_style.content_margin_left >= 48.0 and deck_style.content_margin_top >= 36.0, "%s: command-deck safe inset regressed" % context)
	_check(mission_style != null and mission_style.content_margin_left >= 44.0 and mission_style.content_margin_top >= 32.0, "%s: mission-frame safe inset regressed" % context)

	var expects_rail := bool(viewport_case["rail"])
	_check(navigation != null and navigation.is_visible_in_tree() == expects_rail, "%s: navigation rail breakpoint mismatch" % context)
	if expects_rail:
		var rail_style := navigation.get_theme_stylebox(&"panel") as StyleBoxTexture
		_check(command_deck.size.x >= 620.0, "%s: standard command deck below 620px" % context)
		_check(rail_style != null and rail_style.content_margin_top >= 64.0, "%s: rail copy can enter corner ornament" % context)
		for tile_name: String in ["BarracksButton", "RecruitButton", "ArmoryButton", "VahallaButton", "MercyArchiveButton", "TrainingButton"]:
			var tile := staging.find_child(tile_name, true, false) as Button
			var state := tile.find_child("State", true, false) as Label
			_check(tile != null and tile.custom_minimum_size.y >= 72.0, "%s: %s below 72px" % [context, tile_name])
			_check(_contains(navigation, tile), "%s: %s escaped navigation rail" % [context, tile_name])
			if state.visible:
				_check(_font_size(state) >= 15, "%s: %s state below 15px" % [context, tile_name])
	else:
		_check(operation_grid != null and not _has_ancestor(operation_grid, navigation), "%s: operations did not reflow into command surface" % context)

	if bool(viewport_case["portrait"]):
		_check(command_sheet != null and command_sheet.visible, "%s: portrait command sheet missing" % context)
		_check(command_sheet.size.y >= 760.0, "%s: portrait command sheet below 760px" % context)
		_check(command_sheet.get_global_rect().position.y >= 360.0, "%s: portrait sheet erased the hero stage" % context)
		_check(_contains(command_sheet, mission_action), "%s: portrait primary action escaped sheet" % context)
	else:
		_check(command_deck.size.x >= 560.0, "%s: landscape command deck below 560px" % context)

	_dispose(staging)
	game.set("content", null)
	await process_frame


func _font_size(label: Label) -> int:
	return label.get_theme_font_size(&"font_size") if label != null else 0


func _contains(outer: Control, inner: Control) -> bool:
	if outer == null or inner == null:
		return false
	var outer_rect := outer.get_global_rect().grow(1.0)
	var inner_rect := inner.get_global_rect()
	return outer_rect.has_point(inner_rect.position) and outer_rect.has_point(inner_rect.end - Vector2.ONE)


func _has_ancestor(node: Node, ancestor: Node) -> bool:
	if node == null or ancestor == null:
		return false
	var current := node.get_parent()
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false


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
	if _failures.is_empty():
		print("STAGING_COMMAND_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
