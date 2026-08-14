extends RefCounted

const VIEWPORT := Vector2i(720, 1280)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 700
	h.root.size = VIEWPORT
	await h.frames(4)
	var game := h.autoload("Game")
	var state := _promotion_state(h.seed_value, 400)
	h.check("portrait promotion campaign creates", state != null)
	if state == null:
		return
	game.set("campaign", state)
	game.set("campaign_active", true)
	game.call("_swap_content", "res://scenes/training.tscn")
	await h.frames(4)
	var training := game.get("content") as Control
	h.check("portrait Training opens", training != null)
	if training == null:
		return
	var shell := _find(training, "TrainingScreenShell") as AetheriaScreenShell
	h.check(
		"portrait shell selects portrait mode",
		shell != null and shell.layout_mode() == &"portrait",
	)
	var view_paths := _find(training, "ViewPaths") as Button
	await _ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(4)
	var cards := _find(training, "PathCards") as BoxContainer
	var warning := _find(training, "PermanentWarning") as Control
	var actions := _find(training, "PathActions") as Control
	var viewport := Rect2(Vector2.ZERO, Vector2(VIEWPORT))
	h.check("portrait cards stack vertically", cards != null and cards.vertical)
	h.check(
		"portrait warning and actions remain fully visible",
		warning != null and actions != null
		and viewport.encloses(warning.get_global_rect())
		and viewport.encloses(actions.get_global_rect()),
	)
	var scroll := _find(training, "PathCardsScroll") as ScrollContainer
	var sorcerer := _find(training, "Path_sorcerer") as Control
	var sorcerer_heading := (
		sorcerer.find_child("AdvancedClassName", true, false) as Control
		if sorcerer != null else null
	)
	await _ensure_visible(h, sorcerer_heading)
	var clip := (
		scroll.get_global_rect().intersection(viewport)
		if scroll != null else Rect2()
	)
	h.check(
		"portrait Sorcerer heading center is reachable",
		sorcerer_heading != null
		and clip.has_point(sorcerer_heading.get_global_rect().get_center()),
	)
	var choose := _find(training, "ChoosePath") as Button
	var back := _find(training, "PathBack") as Button
	h.check(
		"portrait action centers remain reachable after card scroll",
		viewport.has_point(choose.get_global_rect().get_center())
		and viewport.has_point(back.get_global_rect().get_center()),
	)
	h.check(
		"portrait browsing does not mutate campaign",
		state.save_revision() == 1 and state.data_copy()["promotion_receipts"].is_empty(),
	)
	await h.shot("training_paths_portrait")
	print("MAGE_PROMOTION_PORTRAIT_COMPLETED")
	h.done()


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
