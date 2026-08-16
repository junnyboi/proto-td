extends RefCounted

const INVENTORY_PATH := "res://test/test_ui_components.gd.inventory.json"
const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VIEWPORT := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 600
	h.root.size = VIEWPORT
	await h.frames(3)
	var game := h.autoload("Game")
	var support := SupportType.new()
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return
	var inventory := JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH)) as Dictionary
	h.check("Training-active inventory contract loads", not inventory.is_empty())
	if inventory.is_empty():
		return
	game.call("open_staging")
	await h.frames(5)
	_check_state(h, game.get("content") as Control, inventory, "staging_training_active")
	game.call("open_results")
	await h.frames(5)
	_check_state(h, game.get("content") as Control, inventory, "results_training_active")
	print("RECRUIT_PROMOTION_ACTIVE_INVENTORY_COMPLETED")
	h.done()


func _check_state(
		h: SelfTestHarness, content: Control, inventory: Dictionary, state_name: String,
	) -> void:
	var state := (inventory["states"] as Dictionary)[state_name] as Dictionary
	var targets := _visible_targets(content)
	var texts := _visible_text(content)
	h.check(
		"%s target inventory exact" % state_name,
		_check_rows(targets, state["targets"] as Array, true)
		and targets.size() == int(state["target_count"]),
		"actual=%s expected=%s" % [targets.keys(), _selectors(state["targets"] as Array)],
	)
	h.check(
		"%s text inventory exact" % state_name,
		_check_rows(texts, state["text"] as Array, false)
		and texts.size() == int(state["text_count"]),
		"actual=%s expected=%s" % [texts.keys(), _selectors(state["text"] as Array)],
	)
	h.check(
		"%s focus order exact" % state_name,
		_focus_order_exact(content, state["focus_order"] as Array),
		str(state["focus_order"]),
	)


func _check_rows(
		actual: Dictionary, expected: Array, check_enabled: bool,
	) -> bool:
	if actual.size() != expected.size():
		return false
	for row: Dictionary in expected:
		var selector := String(row["selector"])
		var node := actual.get(selector) as Control
		if node == null or not node.is_class(StringName(row["type"])):
			return false
		if String(node.theme_type_variation) not in row["variation"]:
			return false
		if not _has_ancestor(node, StringName(row["owner"])):
			return false
		if check_enabled and node is BaseButton:
			if (not (node as BaseButton).disabled) != bool(row["enabled"]):
				return false
	return true


func _focus_order_exact(content: Control, expected: Array) -> bool:
	if expected.is_empty():
		return true
	for index: int in expected.size():
		var current := content.find_child(String(expected[index]), true, false) as Control
		var following := content.find_child(
			String(expected[(index + 1) % expected.size()]), true, false,
		) as Control
		if current == null or following == null:
			return false
		if current.get_node_or_null(current.focus_next) != following:
			return false
	return true


func _visible_targets(content: Control) -> Dictionary:
	var result := {}
	for node: Node in _all_nodes(content):
		if node is Control and (node is BaseButton or node is ItemList):
			var control := node as Control
			if control.is_visible_in_tree():
				result[String(control.name)] = control
	return result


func _visible_text(content: Control) -> Dictionary:
	var result := {}
	for node: Node in _all_nodes(content):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		if node is Label and node.name != &"PresentationLabel":
			result[String(node.name)] = node
		elif node is BaseButton and not (node as BaseButton).text.strip_edges().is_empty():
			result[String(node.name)] = node
	return result


func _has_ancestor(node: Node, ancestor_name: StringName) -> bool:
	var current := node.get_parent()
	while current != null:
		if current.name == ancestor_name:
			return true
		current = current.get_parent()
	return false


func _selectors(rows: Array) -> Array[String]:
	var result: Array[String] = []
	for row: Dictionary in rows:
		result.append(String(row["selector"]))
	return result


func _all_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child: Node in root.get_children():
		result.append_array(_all_nodes(child))
	return result
