extends RefCounted

const LANDSCAPE := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 2200
	h.root.size = LANDSCAPE
	await h.frames(4)
	var game := h.autoload("Game")
	var state := _promotion_state(h.seed_value, 400)
	h.check("promotion-ready canonical campaign creates", state != null)
	if state == null:
		return
	game.set("campaign", state)
	game.set("campaign_active", true)
	game.call("open_staging")
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("canonical campaign opens Staging", staging != null)
	if staging == null:
		return
	var training_button := _find(staging, "TrainingButton") as Button
	h.check(
		"canonical Staging enables Training",
		training_button != null and not training_button.disabled
		and training_button.text == "Training",
	)
	if training_button == null:
		return
	await _press_action(h, &"ui_focus_next")
	h.check(
		"keyboard focus reaches enabled Training",
		staging.get_viewport().gui_get_focus_owner() == training_button,
	)
	await _press_action(h, &"ui_accept")
	var training := await _await_screen(h, game, "TrainingRoot")
	h.check("Training route opens", training != null)
	if training == null:
		return
	var mage_id := _mage_hero(state).hero_id()
	_check_roster(h, training, mage_id)
	await h.shot("training_roster")
	var navigation_hash := state.strategic_hash().duplicate(true)
	await _press_action(h, &"ui_cancel")
	h.check(
		"ui_cancel is inert outside the roster modal",
		game.get("content") == training and training.call("mode") == &"roster"
		and state.strategic_hash() == navigation_hash,
	)
	var view_paths := _find(training, "ViewPaths") as Button
	await _ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	h.check(
		"View Paths real input enters path mode",
		training.call("mode") == &"paths",
	)
	if training.call("mode") != &"paths":
		return
	await _press_action(h, &"ui_cancel")
	h.check(
		"ui_cancel is inert outside the path modal",
		game.get("content") == training and training.call("mode") == &"paths"
		and state.strategic_hash() == navigation_hash,
	)
	_check_paths(h, training)
	var witch := _find(training, "Path_witch_doctor") as Button
	if witch == null:
		return
	var witch_heading := witch.find_child("AdvancedClassName", true, false) as Label
	await _ensure_visible(h, witch_heading)
	await h.click_view(witch_heading.get_global_rect().get_center())
	await h.frames(2)
	h.check(
		"Witch Doctor selection is cyan",
		witch.theme_type_variation == &"AuiSelectedButton",
	)
	await h.shot("training_paths_witch_doctor")
	var witch_kit := witch.find_child("FieldKit", true, false) as Label
	await _ensure_visible(h, witch_kit)
	h.check(
		"Witch Doctor kit tail is reachable",
		witch_kit != null and witch_kit.text == "Kit: medicine, charge, repair tools."
		and Rect2(Vector2.ZERO, Vector2(LANDSCAPE)).intersects(
			witch_kit.get_global_rect(),
		),
	)
	await h.shot("training_paths_kit_tail")
	await _ensure_visible(h, witch_heading)
	var sorcerer := _find(training, "Path_sorcerer") as Button
	var sorcerer_heading := sorcerer.find_child(
		"AdvancedClassName", true, false,
	) as Label
	await _ensure_visible(h, sorcerer_heading)
	await h.click_view(sorcerer_heading.get_global_rect().get_center())
	await h.frames(2)
	h.check(
		"Sorcerer selection is cyan",
		sorcerer.theme_type_variation == &"AuiSelectedButton",
	)
	await h.shot("training_paths_sorcerer")
	await _ensure_visible(h, witch_heading)
	await h.click_view(witch_heading.get_global_rect().get_center())
	var choose := _find(training, "ChoosePath") as Button
	await _ensure_visible(h, choose)
	await h.click_view(choose.get_global_rect().get_center())
	await h.frames(3)
	_check_confirmation(h, training)
	await h.shot("training_confirmation_witch_doctor")
	var before_data := state.data_copy()
	var before_hash := state.strategic_hash().duplicate(true)
	await _press_action(h, &"ui_cancel")
	await h.frames(3)
	h.check(
		"cancel closes only confirmation",
		_find(training, "PromotionConfirmationLayer") == null
		and _find(training, "ChoosePath") != null,
	)
	h.check("cancel preserves exact campaign data", state.data_copy() == before_data)
	h.check("cancel preserves strategic hash", state.strategic_hash() == before_hash)
	h.check(
		"cancel restores Choose Path focus",
		training.get_viewport().gui_get_focus_owner() == _find(training, "ChoosePath"),
	)
	choose = _find(training, "ChoosePath") as Button
	await _ensure_visible(h, choose)
	await h.click_view(choose.get_global_rect().get_center())
	await h.frames(2)
	var confirm := _find(training, "ConfirmTraining") as Button
	await _ensure_visible(h, confirm)
	await h.click_view(confirm.get_global_rect().get_center())
	await h.frames(4)
	_check_success(h, training, state, mage_id)
	await h.shot("training_success_witch_doctor")
	print("MAGE_PROMOTION_COMPLETED")
	h.done()


func _check_roster(
	h: SelfTestHarness, training: Control, mage_id: String,
) -> void:
	var title := _find(training, "TrainingTitleHeading") as Label
	var count := _find(training, "PromotionReadyCount") as Label
	var mage := _find(training, "Recruit_%s" % mage_id) as Button
	var view_paths := _find(training, "ViewPaths") as Button
	h.check("Training title exact", title != null and title.text == "TRAINING")
	h.check(
		"Training belongs to Company 33",
		_find(training, "TrainingExplainer") != null
		and not _visible_text(training).contains("Aetheria"),
	)
	h.check(
		"roster reports one promotion-ready recruit",
		count != null and count.text == "1 PROMOTION READY",
	)
	h.check(
		"promotion-ready Mage row carries full plain state",
		mage != null and mage.text.contains("Mage Apprentice")
		and mage.text.contains("READY") and mage.text.contains("XP 400 / 400")
		and mage.text.contains("Promotion ready"),
		mage.text if mage != null else "missing",
	)
	h.check(
		"eligible Mage is selected and can view paths",
		mage != null and mage.theme_type_variation == &"AuiSelectedButton"
		and view_paths != null and not view_paths.disabled,
	)
	var portrait := mage.find_child("IdentityPortrait", true, false) as TextureRect
	h.check("identity portrait is manifest-backed", portrait != null and portrait.texture != null)


func _check_paths(h: SelfTestHarness, training: Control) -> void:
	var witch := _find(training, "Path_witch_doctor") as Button
	var sorcerer := _find(training, "Path_sorcerer") as Button
	var warning := _find(training, "PermanentWarning") as Label
	h.check("both advanced path cards exist", witch != null and sorcerer != null)
	if witch == null or sorcerer == null:
		return
	var scroll := _find(training, "PathCardsScroll") as ScrollContainer
	h.check("path cards own a bounded scroll viewport", scroll != null)
	if scroll == null:
		return
	var clip := scroll.get_global_rect().intersection(
		Rect2(Vector2.ZERO, Vector2(LANDSCAPE)),
	)
	var witch_heading := witch.find_child("AdvancedClassName", true, false) as Label
	var sorcerer_heading := sorcerer.find_child(
		"AdvancedClassName", true, false,
	) as Label
	var witch_visible := clip.intersection(witch.get_global_rect())
	var sorcerer_visible := clip.intersection(sorcerer.get_global_rect())
	h.check(
		"both path headings and usable card areas are simultaneously visible",
		clip.has_point(witch_heading.get_global_rect().get_center())
		and clip.has_point(sorcerer_heading.get_global_rect().get_center())
		and witch_visible.size.x >= 400.0 and witch_visible.size.y >= 160.0
		and sorcerer_visible.size.x >= 400.0 and sorcerer_visible.size.y >= 160.0,
	)
	h.check(
		"Witch Doctor exact facts are visible",
		witch.text.contains("WITCH DOCTOR") and witch.text.contains("HEALER / SUPPORT")
		and witch.text.contains("Mend") and witch.text.contains("60 HP")
		and witch.text.contains("18 DP") and witch.text.contains("CLASS KIT"),
	)
	h.check(
		"Sorcerer exact facts are visible",
		sorcerer.text.contains("SORCERER") and sorcerer.text.contains("DAMAGE / CONTROL")
		and sorcerer.text.contains("Tempest") and sorcerer.text.contains("20 DP")
		and sorcerer.text.contains("CLASS KIT"),
	)
	h.check(
		"permanent warning precedes mutation",
		warning != null and warning.text == "THIS CHOICE IS PERMANENT.",
	)


func _check_confirmation(h: SelfTestHarness, training: Control) -> void:
	var modal := _find(training, "PromotionConfirmation") as Control
	var title := _find(training, "ConfirmationTitle") as Label
	var current_portrait := _find(training, "CurrentIdentityPortrait") as TextureRect
	var new_portrait := _find(training, "NewDutyIdentityPortrait") as TextureRect
	var warning := _find(training, "NoReviveWarning") as Label
	var cancel := _find(training, "CancelTraining") as Button
	var confirm := _find(training, "ConfirmTraining") as Button
	h.check("confirmation modal opens", modal != null)
	h.check(
		"confirmation names Witch Doctor",
		title != null and title.text == "CONFIRM WITCH DOCTOR TRAINING?",
	)
	h.check(
		"same immutable portrait appears before and after",
		current_portrait != null and new_portrait != null
		and current_portrait.texture == new_portrait.texture,
	)
	h.check(
		"Witch Doctor no-revive warning is explicit",
		warning != null and warning.text.contains("Death remains permanent")
		and warning.text.contains("cannot revive the dead"),
	)
	h.check(
		"modal focus is trapped to two actions",
		cancel != null and confirm != null
		and cancel.focus_next == cancel.get_path_to(confirm)
		and confirm.focus_next == confirm.get_path_to(cancel),
	)


func _check_success(
	h: SelfTestHarness, training: Control, state: CampaignState, hero_id: String,
) -> void:
	var hero := state.roster().by_id(hero_id)
	var success := _find(training, "TrainingSuccess") as Label
	var view_paths := _find(training, "ViewPaths") as Button
	h.check("promotion keeps the same hero ID", hero != null and hero.hero_id() == hero_id)
	h.check("promotion projects Witch Doctor", hero.operator_def_id() == &"witch_doctor_1")
	h.check("promotion records permanent class", hero.advanced_class_id() == &"witch_doctor")
	h.check(
		"promotion stores exactly one receipt",
		state.data_copy()["promotion_receipts"].size() == 1,
	)
	h.check(
		"success announces the new duty",
		success != null and success.text.contains("Witch Doctor"),
	)
	h.check(
		"promoted hero cannot reopen paths",
		view_paths != null and view_paths.disabled and view_paths.focus_mode == Control.FOCUS_NONE,
	)


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


func _mage_hero(state: CampaignState) -> HeroState:
	for hero: HeroState in state.roster().all():
		if hero.first_class_id() == &"mage_apprentice":
			return hero
	return null


func _await_screen(
	h: SelfTestHarness, game: Node, marker: String,
) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control:
			if content.name == marker or content.find_child(marker, true, false) != null:
				await h.frames(3)
				return content
		budget -= 1
		await h.frames(1)
	return null


func _find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


func _ensure_visible(h: SelfTestHarness, control: Control) -> void:
	if control == null:
		return
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			(parent as ScrollContainer).ensure_control_visible(control)
		parent = parent.get_parent()
	await h.frames(3)


func _press_action(h: SelfTestHarness, action: StringName) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = is_pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await h.frames(2)


func _visible_text(root: Node) -> String:
	var text := ""
	if root is Label and (root as Label).visible:
		text += (root as Label).text
	elif root is BaseButton and (root as BaseButton).visible:
		text += (root as BaseButton).text
	for child: Node in root.get_children():
		text += _visible_text(child)
	return text


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
