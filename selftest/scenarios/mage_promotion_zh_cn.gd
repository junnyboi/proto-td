extends RefCounted

const VIEWPORT := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 700
	h.root.size = VIEWPORT
	await h.frames(4)
	var i18n := h.autoload("I18n")
	var game := h.autoload("Game")
	h.check("zh-CN locale activates", bool(i18n.call("set_locale", &"zh-CN")))
	var state := _promotion_state(h.seed_value, 400)
	h.check("Chinese promotion campaign creates", state != null)
	if state == null:
		return
	game.set("campaign", state)
	game.set("campaign_active", true)
	game.call("_swap_content", "res://scenes/training.tscn")
	await h.frames(4)
	var training := game.get("content") as Control
	h.check("Chinese Training opens", training != null)
	if training == null:
		return
	var title := _find(training, "TrainingTitleHeading") as Label
	var mage := _find_mage_row(training)
	var view_paths := _find(training, "ViewPaths") as Button
	h.check("Chinese Training title is exact", title != null and title.text == "训练")
	h.check(
		"Chinese roster presents class, XP, and readiness",
		mage != null and mage.text.contains("见习法师")
		and mage.text.contains("经验值 400 / 400")
		and mage.text.contains("已满足晋升条件"),
	)
	await _ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	var witch := _find(training, "Path_witch_doctor") as Button
	var sorcerer := _find(training, "Path_sorcerer") as Button
	var choose := _find(training, "ChoosePath") as Button
	var warning := _find(training, "PermanentWarning") as Label
	h.check(
		"Chinese path cards preserve both role identities",
		witch != null and sorcerer != null
		and witch.text.contains("巫医") and witch.text.contains("治疗 / 支援")
		and sorcerer.text.contains("术士") and sorcerer.text.contains("输出 / 控制"),
	)
	h.check(
		"Chinese warning and action copy are exact",
		warning != null and warning.text == "此选择不可更改。"
		and choose != null and choose.text == "选择路线",
	)
	h.check(
		"Chinese browsing remains state-equal",
		state.save_revision() == 1 and state.data_copy()["promotion_receipts"].is_empty(),
	)
	await h.shot("training_paths_zh_cn")
	print("MAGE_PROMOTION_ZH_CN_COMPLETED")
	h.done()


func _find_mage_row(training: Control) -> Button:
	for node: Node in training.find_children("Recruit_*", "Button", true, false):
		var button := node as Button
		if button != null and button.text.contains("见习法师"):
			return button
	return null


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
