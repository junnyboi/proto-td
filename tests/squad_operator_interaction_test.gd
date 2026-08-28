extends SceneTree

const EPSILON := 0.001
const ArtType := preload("res://scripts/view/art.gd")

var _failures: Array[String] = []
var _mission: Control = null
var _expected_portraits := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 20260827)
	_check(bool(game.call("start_campaign", false, true)), "interaction fixture failed")
	_prepare_portrait_fixtures(game)
	game.set("selected_stage_id", &"s1")
	root.size = Vector2i(1280, 720)
	_mission = load("res://scenes/squad_select.tscn").instantiate() as Control
	root.add_child(_mission)
	await process_frame
	await process_frame
	await process_frame
	_verify_promoted_portraits()
	await _verify_sorting()
	await _verify_responsive_grid()
	await _verify_selection_feedback_and_reorder()
	_dispose(game)
	await process_frame
	_finish()


func _prepare_portrait_fixtures(game: Node) -> void:
	var state: Variant = game.get("campaign")
	var data := state.get("_data") as Dictionary
	var rows: Array = data.get("heroes", [])
	var targets := {
		"portrait_recruit_00": {
			"class_id": "shock_trooper",
			"operator_def_id": "vanguard_1",
			"portrait_asset_id": &"portrait_specialization_shock_trooper_female",
		},
		"portrait_recruit_01": {
			"class_id": "defender",
			"operator_def_id": "defender_1",
			"portrait_asset_id": &"portrait_specialization_defender_male",
		},
	}
	var premium_assigned := false
	for hero: Dictionary in rows:
		var identity_id := String(hero.get("portrait_asset_id", ""))
		if targets.has(identity_id):
			var target: Dictionary = targets[identity_id]
			hero["current_class_id"] = target["class_id"]
			hero["operator_def_id"] = target["operator_def_id"]
			_expected_portraits[StringName(hero["hero_id"])] = target["portrait_asset_id"]
			continue
		if not premium_assigned:
			hero["hero_kind"] = "premium"
			hero["premium_id"] = "archive_caster"
			hero["current_class_id"] = "mage_apprentice"
			hero["operator_def_id"] = "caster_1"
			hero["portrait_asset_id"] = "portrait_archive_caster"
			_expected_portraits[StringName(hero["hero_id"])] = &"portrait_archive_caster"
			premium_assigned = true
	_check(_expected_portraits.size() == 3, "portrait fixtures did not cover female, male, and premium rows")


func _verify_promoted_portraits() -> void:
	for hero_id: StringName in _expected_portraits:
		var card := _card_by_hero_id(hero_id)
		var expected_id := StringName(_expected_portraits[hero_id])
		_check(card != null, "portrait fixture card missing for %s" % hero_id)
		if card == null:
			continue
		var hero: Dictionary = card.get_meta(&"hero", {})
		_check(
			StringName(hero.get("portrait_asset_id", &"")) == expected_id,
			"Field Team projected the wrong portrait for %s" % hero_id,
		)
		var portrait := card.find_child("OperatorPortrait", true, false) as TextureRect
		_check(
			portrait != null and portrait.texture == ArtType.texture(expected_id),
			"Field Team card did not bind the expected portrait texture for %s" % hero_id,
		)


func _verify_sorting() -> void:
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	_check(sort_select != null, "operator sort dropdown missing")
	if sort_select == null:
		return
	var metadata: Array[StringName] = []
	for index: int in sort_select.item_count:
		metadata.append(StringName(sort_select.get_item_metadata(index)))
	for required: StringName in [
		&"cost_asc", &"cost_desc", &"rarity_desc", &"rarity_asc",
		&"level_desc", &"level_asc", &"name_asc", &"name_desc",
	]:
		_check(metadata.has(required), "operator sort dropdown missing %s" % required)
	_check(sort_select.accessibility_name == "Sort operators", "operator sort dropdown lacks an explicit accessible name")
	await _select_sort(sort_select, &"cost_asc")
	var rows := _visible_hero_rows()
	_check(rows.size() >= 3, "cost sort fixture lacks enough operators")
	_check(_nondecreasing(rows, "dp_cost", "recruitment_index"), "cost low-high order is unstable")
	await _select_sort(sort_select, &"cost_desc")
	rows = _visible_hero_rows()
	_check(_nonincreasing(rows, "dp_cost", "recruitment_index"), "cost high-low order is unstable")
	await _select_sort(sort_select, &"rarity_desc")
	rows = _visible_hero_rows()
	_check(rows.size() >= 3, "rarity sort fixture lacks enough operators")
	_check(_nonincreasing(rows, "rarity", "recruitment_index"), "rarity high-low order is unstable")
	await _select_sort(sort_select, &"rarity_asc")
	rows = _visible_hero_rows()
	_check(_nondecreasing(rows, "rarity", "recruitment_index"), "rarity low-high order is unstable")
	await _select_sort(sort_select, &"level_desc")
	rows = _visible_hero_rows()
	_check(_nonincreasing(rows, "level", "xp"), "level high-low order is unstable")
	await _select_sort(sort_select, &"level_asc")
	rows = _visible_hero_rows()
	_check(_nondecreasing(rows, "level", "xp"), "level low-high order is unstable")
	await _select_sort(sort_select, &"name_asc")
	rows = _visible_hero_rows()
	_check(_names_sorted(rows, true), "name A-Z order is unstable")
	await _select_sort(sort_select, &"name_desc")
	rows = _visible_hero_rows()
	_check(_names_sorted(rows, false), "name Z-A order is unstable")
	for hero: Dictionary in rows:
		_check(int(hero.get("rarity", 0)) >= 1, "operator row lacks rarity")
		_check(int(hero.get("level", 0)) >= 1, "operator row lacks level")
		_check(int(hero.get("dp_cost", 0)) > 0, "operator row lacks deployment cost")


func _verify_selection_feedback_and_reorder() -> void:
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	if sort_select != null:
		await _select_sort(sort_select, &"recruitment")
	var cards: Array[Button] = []
	var grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	if grid != null:
		for child: Node in grid.get_children():
			if child is Button and not (child as Button).disabled:
				cards.append(child as Button)
	_check(cards.size() >= 3, "selected-squad reorder fixture lacks three active operators")
	if cards.size() < 3:
		return
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	for index: int in 3:
		cards[index].button_pressed = true
		await process_frame
		_check(cards[index].scale.x > 1.0, "selected operator card lacks immediate reduced-motion feedback")
		_check(bool(cards[index].get_meta(&"operator_feedback_enabled", false)), "operator card feedback contract missing")
	var initial: Array[StringName] = _mission.call("selected_squad_order")
	_check(initial.size() == 3, "selected squad order does not contain three operators")
	var rail := _mission.find_child("SelectedSquadOrder", true, false) as HBoxContainer
	_check(rail != null and rail.get_child_count() == 3, "selected squad order rail did not create three chips")
	if rail == null or rail.get_child_count() < 3:
		ProjectSettings.set_setting("accessibility/reduced_motion", false)
		return
	var first := rail.get_child(0) as Control
	var third := rail.get_child(2) as Control
	var drag_data: Variant = {
		"type": &"selected_squad_operator",
		"hero_id": StringName(first.get_meta(&"hero_id", &"")),
	}
	_check(typeof(drag_data) == TYPE_DICTIONARY, "selected squad chip does not expose drag payload")
	_check(bool(third.call("_can_drop_data", Vector2.ZERO, drag_data)), "selected squad chip rejects valid reorder payload")
	third.call("_drop_data", Vector2.ZERO, drag_data)
	await process_frame
	var reordered: Array[StringName] = _mission.call("selected_squad_order")
	_check(reordered == [initial[1], initial[2], initial[0]], "drag-and-drop did not move the first operator onto the third slot")
	_check(bool(_mission.call("move_selected_squad_operator", initial[0], -1)), "keyboard reorder helper rejected a valid move")
	var keyboard_order: Array[StringName] = _mission.call("selected_squad_order")
	_check(keyboard_order == [initial[1], initial[0], initial[2]], "keyboard reorder helper changed the wrong slots")
	var moved_chip := _mission.find_child("SelectedSquad_%s" % initial[0], true, false) as Button
	_check(moved_chip != null and moved_chip.text.begins_with("2"), "selected-squad chips did not renumber after reorder")
	_check(moved_chip != null and moved_chip.accessibility_description.contains("Alt"), "reorder chip lacks keyboard accessibility guidance")
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	await process_frame
	await process_frame
	var animated_card := _card_by_hero_id(initial[0])
	_check(animated_card != null, "animated operator card fixture disappeared after reorder")
	if animated_card != null:
		animated_card.grab_focus()
		await create_timer(0.18).timeout
		_check(animated_card.scale.x >= 1.015 and animated_card.scale.x <= 1.021, "operator focus feedback is not subtle and bounded")
		var hover_glow := animated_card.find_child("OperatorHoverGlow", true, false) as Panel
		_check(bool(animated_card.get_meta(&"operator_hover_glow_enabled", false)), "operator card lacks hover-glow telemetry")
		_check(hover_glow != null, "operator card hover glow is missing")
		if hover_glow != null:
			var glow_style := hover_glow.get_theme_stylebox(&"panel") as StyleBoxFlat
			_check(hover_glow.self_modulate.a <= 0.05, "operator keyboard focus still reveals an outline glow")
			_check(glow_style != null and glow_style.border_width_left >= 2 and glow_style.shadow_size >= 8, "operator glow lacks a luminous border")
		animated_card.button_pressed = false
		await process_frame
		_check(_feedback_tween_active(animated_card), "operator deselection did not schedule release feedback")
		await create_timer(0.30).timeout
		_check(animated_card.scale.x >= 1.015, "deselected focused operator did not return to its focus scale")
		animated_card.button_pressed = true
		await process_frame
		_check(_feedback_tween_active(animated_card), "operator selection did not schedule confirmation feedback")
		await create_timer(0.30).timeout
		_check(animated_card.scale.x >= 1.015, "selected focused operator did not return to its focus scale")
		if sort_select != null:
			sort_select.grab_focus()
			await create_timer(0.20).timeout
			_check(hover_glow == null or hover_glow.self_modulate.a <= 0.05, "operator glow remains visible after focus exits")
		animated_card.set_pressed_no_signal(false)
		var card_size := animated_card.size
		_mission.call(
			"_animate_operator_card_scale",
			animated_card,
			Vector2(1.018, 1.018),
			0.14,
			true,
		)
		await create_timer(0.20).timeout
		_check(animated_card.scale.x >= 1.015 and animated_card.scale.x <= 1.021, "operator hover scale is missing or excessive")
		_check(animated_card.size.is_equal_approx(card_size), "operator hover animation changed responsive grid geometry")
		_check(hover_glow == null or hover_glow.self_modulate.a >= 0.95, "operator hover lacks its subtle luminous response")
		_mission.call(
			"_animate_operator_card_scale",
			animated_card,
			Vector2.ONE,
			0.14,
			false,
		)
		await create_timer(0.20).timeout
		_check(animated_card.scale.is_equal_approx(Vector2.ONE), "operator hover did not settle to rest")
		animated_card.set_pressed_no_signal(true)


func _verify_responsive_grid() -> void:
	var scroll := _mission.find_child("OperatorRosterScroll", true, false) as ScrollContainer
	var grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	_check(scroll != null and grid != null and grid.get_child_count() >= 3, "responsive grid fixture lacks populated cards")
	if scroll == null or grid == null or grid.get_child_count() < 3:
		return
	var regular_columns := grid.columns
	var first_card := grid.get_child(0)
	_check(regular_columns >= 2 and regular_columns < grid.get_child_count(), "regular Field Team does not pack a bounded grid")
	_check(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "responsive grid owns the wrong scroll axis")
	_check(not bool(scroll.get_meta(&"operator_snap_enabled", true)), "obsolete carousel snapping remains enabled")
	scroll.scroll_horizontal = 730
	_mission.call("_snap_operator_rail")
	await process_frame
	_check(scroll.scroll_horizontal == 0, "disabled responsive grid accepted horizontal carousel movement")
	root.size = Vector2i(1440, 800)
	await process_frame
	await process_frame
	await process_frame
	_check(grid.columns == regular_columns, "same-mode responsive grid changed regular fitted columns")
	_check(grid.get_child(0) == first_card, "same-mode responsive grid rebuilt operator cards")
	root.size = Vector2i(1920, 900)
	await process_frame
	await process_frame
	await process_frame
	_check(grid.columns > regular_columns, "wide responsive grid did not add an operator column")
	_check(grid.get_child(0) == first_card, "wide responsive grid rebuilt operator cards")
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	await process_frame
	_check(grid.columns == regular_columns, "responsive grid did not restore regular columns")
	_check(grid.get_child(0) == first_card, "restored responsive grid rebuilt operator cards")


func _feedback_tween_active(card: Control) -> bool:
	var tweens := _mission.get("_operator_feedback_tweens") as Dictionary
	var tween := tweens.get(card.get_instance_id()) as Tween
	return tween != null and tween.is_valid()


func _select_sort(select: OptionButton, mode: StringName) -> void:
	for index: int in select.item_count:
		if StringName(select.get_item_metadata(index)) == mode:
			select.select(index)
			select.item_selected.emit(index)
			await process_frame
			await process_frame
			return
	_check(false, "could not select sort mode %s" % mode)


func _visible_hero_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	if grid == null:
		return rows
	for child: Node in grid.get_children():
		if child is Button:
			rows.append((child as Button).get_meta(&"hero", {}))
	return rows


func _card_by_hero_id(hero_id: StringName) -> Button:
	var grid := _mission.find_child("OperatorGrid", true, false) as GridContainer
	if grid == null:
		return null
	for child: Node in grid.get_children():
		if child is Button:
			var hero: Dictionary = (child as Button).get_meta(&"hero", {})
			if StringName(hero.get("hero_id", &"")) == hero_id:
				return child as Button
	return null


func _nonincreasing(rows: Array[Dictionary], primary: String, secondary: String) -> bool:
	for index: int in range(1, rows.size()):
		var previous := rows[index - 1]
		var current := rows[index]
		if int(previous.get(primary, 0)) < int(current.get(primary, 0)):
			return false
		if int(previous.get(primary, 0)) == int(current.get(primary, 0)) and primary == "level":
			if int(previous.get(secondary, 0)) < int(current.get(secondary, 0)):
				return false
	return true


func _nondecreasing(rows: Array[Dictionary], primary: String, secondary: String) -> bool:
	for index: int in range(1, rows.size()):
		var previous := rows[index - 1]
		var current := rows[index]
		if int(previous.get(primary, 0)) > int(current.get(primary, 0)):
			return false
		if int(previous.get(primary, 0)) == int(current.get(primary, 0)) and primary == "level":
			if int(previous.get(secondary, 0)) > int(current.get(secondary, 0)):
				return false
	return true


func _names_sorted(rows: Array[Dictionary], ascending: bool) -> bool:
	for index: int in range(1, rows.size()):
		var previous := String(rows[index - 1].get("callsign", "")).to_lower()
		var current := String(rows[index].get("callsign", "")).to_lower()
		if ascending and previous > current:
			return false
		if not ascending and previous < current:
			return false
	return true


func _dispose(game: Node) -> void:
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	if game.get("content") == _mission:
		game.set("content", null)
	if _mission != null and is_instance_valid(_mission):
		var parent := _mission.get_parent()
		if parent != null:
			parent.remove_child(_mission)
		_mission.free()
	_mission = null
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SQUAD_OPERATOR_INTERACTION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
