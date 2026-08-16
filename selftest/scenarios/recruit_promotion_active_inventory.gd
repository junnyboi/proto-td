extends RefCounted

const INVENTORY_PATH := "res://test/test_ui_components.gd.inventory.json"
const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VariantSupportType := preload("res://selftest/recruit_promotion_variant_support.gd")
const VIEWPORTS := [
	{"size": Vector2i(1280, 720), "tag": "1280x720"},
	{"size": Vector2i(960, 720), "tag": "960x720"},
	{"size": Vector2i(720, 1280), "tag": "720x1280"},
]
const VARIANTS: Array[StringName] = [&"standard", &"scaled", &"expanded"]


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 1200
	h.root.size = VIEWPORTS[0]["size"]
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
	_check_duplicate_rejection(h)
	var variant_support := VariantSupportType.new()
	var cells := 0
	for variant: StringName in VARIANTS:
		for config: Dictionary in VIEWPORTS:
			await _capture(
				h, game, variant_support, inventory, variant, config, &"staging",
			)
			await _capture(
				h, game, variant_support, inventory, variant, config, &"results",
			)
			cells += 2
	h.check("Training-active exact inventory matrix covers 18 cells", cells == 18)
	print("RECRUIT_PROMOTION_ACTIVE_INVENTORY_COMPLETED")
	h.done()


func _check_duplicate_rejection(h: SelfTestHarness) -> void:
	var first := Button.new()
	var second := Button.new()
	first.name = "DuplicateSelector"
	second.name = "DuplicateSelector"
	var controls: Array[Control] = [first, second]
	var expected := [{
		"selector": "DuplicateSelector", "type": "Button",
		"variation": [""], "owner": "", "enabled": true,
	}]
	h.check(
		"duplicate inventory selectors fail closed",
		_control_names(controls) == ["DuplicateSelector", "DuplicateSelector"]
		and not _check_rows(controls, expected, true),
	)
	first.free()
	second.free()


func _capture(
		h: SelfTestHarness,
		game: Node,
		variant_support: RefCounted,
		inventory: Dictionary,
		variant: StringName,
		config: Dictionary,
		screen: StringName,
	) -> void:
	h.root.size = Vector2i(config["size"])
	await h.frames(3)
	game.call("open_staging" if screen == &"staging" else "open_results")
	await h.frames(5)
	var content := game.get("content") as Control
	if variant != &"standard":
		variant_support.call("_apply_variant", content, variant)
		await h.frames(5)
	var state_name := "%s_training_active" % screen
	var label := "%s %s %s" % [state_name, variant, config["tag"]]
	_check_state(h, content, inventory, state_name, label)


func _check_state(
		h: SelfTestHarness,
		content: Control,
		inventory: Dictionary,
		state_name: String,
		label: String,
	) -> void:
	var state := (inventory["states"] as Dictionary)[state_name] as Dictionary
	var targets := _visible_targets(content)
	var texts := _visible_text(content)
	h.check(
		"%s target inventory exact" % label,
		_check_rows(targets, state["targets"] as Array, true)
		and targets.size() == int(state["target_count"]),
		"actual=%s expected=%s" % [_control_names(targets), _selectors(state["targets"] as Array)],
	)
	h.check(
		"%s text inventory exact" % label,
		_check_rows(texts, state["text"] as Array, false)
		and texts.size() == int(state["text_count"]),
		"actual=%s expected=%s" % [_control_names(texts), _selectors(state["text"] as Array)],
	)
	h.check(
		"%s focus order exact" % label,
		_focus_order_exact(content, state["focus_order"] as Array),
		str(state["focus_order"]),
	)


func _check_rows(actual: Array[Control], expected: Array, check_enabled: bool) -> bool:
	var valid := actual.size() == expected.size()
	for row: Dictionary in expected:
		if not valid:
			break
		var selector := String(row["selector"])
		var matches: Array[Control] = []
		for candidate: Control in actual:
			if String(candidate.name) == selector:
				matches.append(candidate)
		if matches.size() != 1:
			valid = false
			continue
		var node := matches[0]
		valid = (
			node.is_class(StringName(row["type"]))
			and String(node.theme_type_variation) in row["variation"]
			and _has_ancestor(node, StringName(row["owner"]))
		)
		if check_enabled and node is BaseButton:
			valid = valid and (
				(not (node as BaseButton).disabled) == bool(row["enabled"])
			)
	return valid


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


func _visible_targets(content: Control) -> Array[Control]:
	var result: Array[Control] = []
	for node: Node in _all_nodes(content):
		if node is Control and (node is BaseButton or node is ItemList):
			var control := node as Control
			if control.is_visible_in_tree():
				result.append(control)
	return result


func _visible_text(content: Control) -> Array[Control]:
	var result: Array[Control] = []
	for node: Node in _all_nodes(content):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		if node is Label and node.name != &"PresentationLabel":
			result.append(node)
		elif node is BaseButton and not (node as BaseButton).text.strip_edges().is_empty():
			result.append(node)
	return result


func _control_names(controls: Array[Control]) -> Array[String]:
	var result: Array[String] = []
	for control: Control in controls:
		result.append(String(control.name))
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
