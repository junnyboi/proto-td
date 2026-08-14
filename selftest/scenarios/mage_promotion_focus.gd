extends RefCounted

const VIEWPORT := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 700
	h.root.size = VIEWPORT
	await h.frames(4)
	var game := h.autoload("Game")
	var state := _promotion_state(h.seed_value, 400)
	h.check("focus promotion campaign creates", state != null)
	if state == null:
		return
	game.set("campaign", state)
	game.set("campaign_active", true)
	game.call("_swap_content", "res://scenes/training.tscn")
	await h.frames(4)
	var training := game.get("content") as Control
	h.check("focus Training opens", training != null)
	if training == null:
		return
	var view_paths := _find(training, "ViewPaths") as Button
	await _ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	var witch := _find(training, "Path_witch_doctor") as Button
	var heading := witch.find_child("AdvancedClassName", true, false) as Control
	await _ensure_visible(h, heading)
	await h.click_view(heading.get_global_rect().get_center())
	var choose := _find(training, "ChoosePath") as Button
	await _ensure_visible(h, choose)
	await h.click_view(choose.get_global_rect().get_center())
	await h.frames(3)
	var cancel := _find(training, "CancelTraining") as Button
	var confirm := _find(training, "ConfirmTraining") as Button
	var path := _find(training, "Path_witch_doctor") as Button
	choose = _find(training, "ChoosePath") as Button
	h.check(
		"modal suspends every background action",
		cancel != null and confirm != null and path != null and choose != null
		and path.focus_mode == Control.FOCUS_NONE
		and choose.focus_mode == Control.FOCUS_NONE,
	)
	if cancel == null or confirm == null:
		return
	cancel.grab_focus()
	await h.frames(2)
	var trapped := true
	var switches := true
	for action: StringName in [
		&"ui_focus_next", &"ui_focus_prev", &"ui_left",
		&"ui_right", &"ui_up", &"ui_down",
	]:
		var before := training.get_viewport().gui_get_focus_owner()
		await _press_action(h, action)
		var owner := training.get_viewport().gui_get_focus_owner()
		trapped = trapped and (owner == cancel or owner == confirm)
		switches = switches and owner != before
	h.check("all directional focus stays inside modal", trapped)
	h.check("every directional action switches modal action", switches)
	h.check(
		"focus stress does not dispatch promotion",
		state.save_revision() == 1
		and state.data_copy()["promotion_receipts"].is_empty(),
	)
	await h.shot("training_confirmation_focus")
	print("MAGE_PROMOTION_FOCUS_COMPLETED")
	h.done()


func _press_action(h: SelfTestHarness, action: StringName) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = is_pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await h.frames(2)


func _ensure_visible(h: SelfTestHarness, control: Control) -> void:
	if control == null:
		return
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			(parent as ScrollContainer).ensure_control_visible(control)
		parent = parent.get_parent()
	await h.frames(3)


func _find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


func _promotion_state(seed_value: int, xp: int) -> CampaignState:
	var created := CampaignState.create(
		seed_value, 1, _definition(), _catalogs(), _stages(),
	)
	if not created["accepted"]:
		return null
	var data: Dictionary = (created["value"] as CampaignState).data_copy()
	for row: Dictionary in data["heroes"]:
		if row["first_class_id"] == "mage_apprentice":
			row["xp"] = xp
	var restored := CampaignState.restore(
		data, _definition(), _catalogs(), _stages(),
	)
	return restored["value"] if restored["accepted"] else null


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _stages() -> Array:
	var values: Array = []
	for index: int in range(1, 9):
		values.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return values


func _catalog_ids(path: String) -> Array[StringName]:
	var values: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			values.append(StringName(source.trim_suffix(".tres")))
	return values
