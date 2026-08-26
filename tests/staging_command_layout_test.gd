extends SceneTree

const VIEWPORT_CASES := [
	{"name": "annotated-wide", "size": Vector2i(1915, 778), "rail": true, "portrait": false},
	{"name": "ultrawide", "size": Vector2i(1920, 900), "rail": true, "portrait": false},
	{"name": "standard", "size": Vector2i(1280, 720), "rail": false, "portrait": false},
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
	await _verify_case(game, VIEWPORT_CASES[5], "zh-CN")
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
	var top_row := staging.find_child("TopBarContent", true, false) as HBoxContainer
	var identity_plate := staging.find_child("IdentityPlate", true, false) as PanelContainer
	var identity_label := staging.find_child("FactionIdentity", true, false) as Label
	var status_chip := staging.find_child("CampaignStatusChip", true, false) as PanelContainer
	var status_label := staging.find_child("TopCampaignSummary", true, false) as Label
	var utility_plate := staging.find_child("UtilityPlate", true, false) as PanelContainer
	var exit_alignment_spacer := staging.find_child("ExitAlignmentSpacer", true, false) as Control
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
	var mission_action_plate := mission_action.find_child("MissionControlPlate", true, false) as TextureRect
	var operation_label := staging.find_child("OperationsLabel", true, false) as Label
	var operation_grid := staging.find_child("OperationGrid", true, false) as GridContainer
	var operation_scroll := staging.find_child("OperationsScroll", true, false) as ScrollContainer
	var operation_list_margin := staging.find_child("OperationListMargin", true, false) as MarginContainer
	var command_scroll_name := "PortraitCommandScroll" if bool(viewport_case["portrait"]) else "LandscapeCommandScroll"
	var command_scroll := staging.find_child(command_scroll_name, true, false) as ScrollContainer
	var expected_identity := "PROTOS 防线" if locale_id == "zh-CN" else "PROTOS DEFENSE"

	_check(top_bar != null and top_bar.size.y >= 156.0, "%s: segmented top HUD is shorter than 156px" % context)
	_check(identity_plate != null and utility_plate != null, "%s: segmented identity/utility plates missing" % context)
	_check(exit_alignment_spacer != null and exit_alignment_spacer.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "%s: Exit right-alignment spacer missing" % context)
	_check(top_row != null and absf(utility_plate.get_global_rect().end.x - top_row.get_global_rect().end.x) <= 1.0, "%s: Exit is not aligned to the top row's right edge" % context)
	_check(identity_plate.get_theme_stylebox(&"panel") is StyleBoxEmpty, "%s: PROTOS DEFENSE identity retained a container frame" % context)
	_check(identity_label != null and identity_label.text == expected_identity, "%s: top-left identity is not localized game identity" % context)
	_check(identity_label != null and _contains(identity_plate, identity_label), "%s: faction identity text escaped its enlarged plate" % context)
	_check(exit_label != null and _contains(utility_plate, exit_label), "%s: Exit label escaped or touched its compact frame" % context)
	_check(staging.find_child("BottomShade", true, false) == null, "%s: duplicate lower mask remains" % context)
	_check(staging.find_child("HeroIdentity", true, false) == null, "%s: duplicate lower identity copy remains" % context)
	_check(command_deck != null and command_deck.visible, "%s: command deck missing" % context)
	_check(command_heading != null and command_heading.text == ("指挥中心" if locale_id == "zh-CN" else "COMMAND CENTER"), "%s: command heading rename missing" % context)
	_check(command_heading != null and _font_size(command_heading) >= 22, "%s: command heading below responsive 22px floor" % context)
	_check(progress_text != null and _font_size(progress_text) >= 18, "%s: campaign progress below responsive 18px floor" % context)
	_check(next_label != null and _font_size(next_label) >= 17, "%s: next-operation heading below responsive 17px floor" % context)
	_check(mission_title != null and _font_size(mission_title) >= 24, "%s: mission title below 24px" % context)
	_check(objective != null and _font_size(objective) >= 18, "%s: mission body below 18px" % context)
	_check(mission_action != null and mission_action.custom_minimum_size.y >= 150.0, "%s: primary action below responsive 150px floor" % context)
	_check(mission_action_label != null and is_equal_approx(mission_action_label.offset_top, 12.0) and is_equal_approx(mission_action_label.offset_bottom, -12.0), "%s: Mission Control action lacks exact 12px top/bottom padding" % context)
	_check(mission_action_label != null and _font_size(mission_action_label) >= 36, "%s: primary action type below 36px" % context)
	_check(mission_action_label != null and mission_action_label.text.contains("\n"), "%s: primary action does not use two-line copy" % context)
	_check(mission_action != null and mission_action.tooltip_text == ("任务指挥" if locale_id == "zh-CN" else "Mission Control"), "%s: Mission Control primary action copy is missing" % context)
	_check(mission_action_label != null and mission_action_label.get_visible_line_count() == mission_action_label.get_line_count(), "%s: primary action copy is clipped" % context)
	_check(mission_action_plate != null and mission_action_plate.texture.resource_path.ends_with("mission_control_plate.png"), "%s: generated Mission Control plate missing" % context)
	if locale_id == "en-US" and String(viewport_case["name"]) == "annotated-wide":
		mission_action.release_focus()
		await process_frame
		staging.call("_on_mission_hover_changed", true)
		await create_timer(0.22).timeout
		_check(mission_action_plate.scale.x > 1.005 and mission_action_plate.modulate.b > 1.15, "%s: mission hover plate lift/brightening missing" % context)
		_check(mission_action_label.scale.x > 1.01, "%s: mission hover label lift missing" % context)
		_check(mission_action_label.get_theme_color(&"font_shadow_color").a <= 0.01, "%s: mission action reintroduced a text drop shadow" % context)
		_check(mission_action_label.get_theme_constant(&"shadow_outline_size") == 0, "%s: mission action shadow outline is not disabled" % context)
		_check(mission_action_label.get_theme_constant(&"shadow_offset_x") == 0 and mission_action_label.get_theme_constant(&"shadow_offset_y") == 0, "%s: mission action shadow offset is not zero" % context)
		staging.call("_on_mission_hover_changed", false)
		mission_action.release_focus()
		await create_timer(0.22).timeout
		_check(mission_action_plate.scale.is_equal_approx(Vector2.ONE), "%s: mission hover plate did not reset" % context)
		_check(mission_action_label.get_theme_color(&"font_shadow_color").a <= 0.01, "%s: mission hover text glow did not reset" % context)
	_check(operation_label != null and _font_size(operation_label) >= 18, "%s: operations heading below responsive 18px floor" % context)
	_check(operation_list_margin != null and operation_list_margin.get_theme_constant(&"margin_left") >= 20 and operation_list_margin.get_theme_constant(&"margin_right") >= 20, "%s: operation list lacks 20px side margins" % context)
	if bool(viewport_case["portrait"]) and viewport_size.x <= 720:
		_check(operation_grid != null and operation_grid.columns == 1, "%s: narrow portrait operations must use one no-wrap column" % context)
	_check(operation_scroll != null and operation_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s: operations do not own local overflow" % context)
	_check(command_scroll != null and command_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s: command deck still uses document scrolling" % context)
	_check(mission_card != null and _contains(mission_card, mission_title), "%s: mission title escaped its frame" % context)
	_check(mission_card != null and _contains(mission_card, objective), "%s: mission objective escaped its frame" % context)
	_check(objective.get_visible_line_count() == objective.get_line_count(), "%s: mission objective lines are clipped" % context)

	var deck_style := command_deck.get_theme_stylebox(&"panel") as StyleBoxTexture
	var mission_style := mission_card.get_theme_stylebox(&"panel") as StyleBoxTexture
	_check(deck_style != null and deck_style.content_margin_left >= 48.0 and deck_style.content_margin_top >= 24.0, "%s: command-deck safe inset regressed" % context)
	_check(mission_style != null and mission_style.content_margin_left >= 44.0 and mission_style.content_margin_top >= 32.0, "%s: mission-frame safe inset regressed" % context)

	var expects_rail := bool(viewport_case["rail"])
	_check(navigation != null and navigation.is_visible_in_tree() == expects_rail, "%s: navigation rail breakpoint mismatch" % context)
	if expects_rail:
		var rail_style := navigation.get_theme_stylebox(&"panel") as StyleBoxTexture
		_check(navigation.size.x >= 650.0, "%s: navigation rail did not receive the requested 50 percent width increase" % context)
		_check(operation_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s: Operations heading is not centered" % context)
		_check(_font_size(operation_label) >= 32, "%s: Operations heading below attachment-relative 1.5x size" % context)
		_check(identity_plate.custom_minimum_size.x >= 420.0 and identity_plate.custom_minimum_size.y >= 112.0, "%s: identity region did not expand" % context)
		_check(status_chip != null and status_chip.visible and status_chip.custom_minimum_size.x >= 354.0 and status_chip.custom_minimum_size.y >= 112.0, "%s: campaign status plate did not expand" % context)
		_check(status_label != null and _font_size(status_label) >= 22 and _contains(status_chip, status_label), "%s: campaign status text is clipped" % context)
		_check(utility_plate.custom_minimum_size.x >= 228.0 and utility_plate.custom_minimum_size.y >= 112.0, "%s: Exit plate did not expand" % context)
		_check(_font_size(identity_label) >= 28, "%s: PROTOS DEFENSE identity type below attachment-relative doubled size" % context)
		_check(_font_size(exit_label) >= 22, "%s: Exit type below 22px" % context)
		_check(command_deck.size.x >= 620.0, "%s: standard command deck below 620px" % context)
		_check(_font_size(command_heading) >= 24 and _font_size(progress_text) >= 18 and _font_size(next_label) >= 18, "%s: command header typography below attachment-relative doubled size" % context)
		_check(mission_card.custom_minimum_size.y >= 260.0 and mission_card.size.y >= 260.0, "%s: next-mission card lacks its doubled 260px minimum height" % context)
		var expected_action_height := 168.0 if viewport_size.y < 850 else 180.0
		_check(mission_action.custom_minimum_size.y >= expected_action_height, "%s: ultrawide primary action below attachment-relative 1.5x height" % context)
		_check(deck_style.content_margin_top >= (24.0 if viewport_size.y < 850 else 36.0), "%s: ultrawide deck lost its safe inset" % context)
		_check(rail_style != null and rail_style.content_margin_top >= 64.0, "%s: rail copy can enter corner ornament" % context)
		_check(operation_scroll.get_v_scroll_bar().max_value <= operation_scroll.get_v_scroll_bar().page + 1.0, "%s: wide navigation rail still requires scrolling" % context)
		_check(_contains(staging, command_deck), "%s: command deck extends beyond the viewport" % context)
		_check(_contains(staging, mission_action), "%s: Mission Control action is clipped below the viewport" % context)
		for tile_name: String in ["BarracksButton", "RecruitButton", "ArmoryButton", "VahallaButton", "MercyArchiveButton", "TrainingButton"]:
			var tile := staging.find_child(tile_name, true, false) as Button
			var title := tile.find_child("Title", true, false) as Label
			var state := tile.find_child("State", true, false) as Label
			var expected_tile_height := 64.0 if viewport_size.y < 850 else 86.0
			_check(tile != null and tile.custom_minimum_size.y >= expected_tile_height, "%s: %s below responsive rail height" % [context, tile_name])
			_check(_has_ancestor(tile, navigation), "%s: %s escaped navigation rail ownership" % [context, tile_name])
			_check(_horizontally_contains(navigation, tile), "%s: %s overflows navigation rail horizontally" % [context, tile_name])
			var expected_title_size := 40 if viewport_size.y < 850 else 49
			_check(title != null and _font_size(title) >= expected_title_size, "%s: %s title below responsive rail size" % [context, tile_name])
			_check(state != null and not state.visible, "%s: %s still renders unavailable state copy" % [context, tile_name])
			_check(tile.text.is_empty() and not tile.accessibility_name.is_empty(), "%s: %s native copy still distorts layout or lost accessibility" % [context, tile_name])
			if tile.disabled:
				_check(tile.focus_mode == Control.FOCUS_NONE, "%s: %s disabled tile remains selectable" % [context, tile_name])
	else:
		_check(operation_grid != null and not _has_ancestor(operation_grid, navigation), "%s: operations did not reflow into command surface" % context)

	if bool(viewport_case["portrait"]):
		_check(command_sheet != null and command_sheet.visible, "%s: portrait command sheet missing" % context)
		_check(command_sheet.size.y >= 760.0, "%s: portrait command sheet below 760px" % context)
		_check(command_sheet.get_global_rect().position.y >= 300.0, "%s: taller portrait sheet erased the hero stage" % context)
		_check(_contains(command_sheet, mission_action), "%s: portrait primary action escaped sheet" % context)
	else:
		_check(command_deck.size.x >= 560.0, "%s: landscape command deck below 560px" % context)
		_check(_contains(command_deck, mission_action), "%s: bottom Mission Control action escaped the command deck" % context)

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


func _horizontally_contains(outer: Control, inner: Control) -> bool:
	if outer == null or inner == null:
		return false
	var outer_rect := outer.get_global_rect().grow(1.0)
	var inner_rect := inner.get_global_rect()
	return inner_rect.position.x >= outer_rect.position.x and inner_rect.end.x <= outer_rect.end.x


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
