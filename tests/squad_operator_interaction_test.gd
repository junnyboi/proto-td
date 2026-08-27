extends SceneTree

const EPSILON := 0.001

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
	game.call("set_run_seed", 20260827)
	_check(bool(game.call("start_campaign", false, true)), "interaction fixture failed")
	game.set("selected_stage_id", &"s1")
	root.size = Vector2i(1280, 720)
	_mission = load("res://scenes/squad_select.tscn").instantiate() as Control
	root.add_child(_mission)
	await process_frame
	await process_frame
	await process_frame
	await _verify_sorting()
	await _verify_selection_feedback_and_reorder()
	_dispose(game)
	await process_frame
	_finish()


func _verify_sorting() -> void:
	var sort_select := _mission.find_child("DeploymentNameSort", true, false) as OptionButton
	_check(sort_select != null, "operator sort dropdown missing")
	if sort_select == null:
		return
	var metadata: Array[StringName] = []
	for index: int in sort_select.item_count:
		metadata.append(StringName(sort_select.get_item_metadata(index)))
	for required: StringName in [&"rarity_desc", &"rarity_asc", &"level_desc", &"level_asc"]:
		_check(metadata.has(required), "operator sort dropdown missing %s" % required)
	await _select_sort(sort_select, &"rarity_desc")
	var rows := _visible_hero_rows()
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
	for hero: Dictionary in rows:
		_check(int(hero.get("rarity", 0)) >= 1, "operator row lacks rarity")
		_check(int(hero.get("level", 0)) >= 1, "operator row lacks level")


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
		_check(animated_card.scale.x >= 1.02, "operator focus feedback does not reach its emphasized scale")
		animated_card.button_pressed = false
		_check(await _wait_for_scale_x(animated_card, 1.0, true), "operator deselection animation lacks a visible release phase")
		animated_card.button_pressed = true
		_check(await _wait_for_scale_x(animated_card, 1.03, false), "operator selection animation lacks a visible confirmation pulse")


func _wait_for_scale_x(card: Control, threshold: float, less_than: bool, timeout_seconds := 0.24) -> bool:
	var elapsed := 0.0
	while elapsed <= timeout_seconds:
		if (card.scale.x < threshold) if less_than else (card.scale.x > threshold):
			return true
		await create_timer(0.01).timeout
		elapsed += 0.01
	return false


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
