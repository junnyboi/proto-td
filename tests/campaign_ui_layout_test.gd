extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "campaign layout fixture failed")
	game.set("selected_stage_id", &"s1")
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	var staging: Node = load("res://scenes/staging.tscn").instantiate()
	root.add_child(staging)
	await process_frame
	await process_frame
	var backdrop_video := staging.find_child("LunarisTitleLoop", true, false) as VideoStreamPlayer
	var backdrop_fallback := staging.find_child("LunarisFallback", true, false) as TextureRect
	var archive_button := staging.find_child("MercyArchiveButton", true, false) as Button
	_check(staging.find_child("MockResourceWallet", true, false) == null, "Company Command still presents the fabricated wallet")
	_check(staging.find_child("UtilityIcons", true, false) == null, "Company Command still presents inert utility chrome")
	_check(backdrop_video != null and not backdrop_video.visible and not backdrop_video.is_playing(), "reduced motion did not suppress Company Command video playback")
	_check(backdrop_fallback != null and backdrop_fallback.visible, "reduced motion did not preserve the Company Command static backdrop")
	_check(archive_button != null and not archive_button.disabled, "Company Command is missing the Mercy Archive route")
	_dispose(staging)
	game.set("content", null)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)

	var campaign: Node = load("res://scenes/stage_select.tscn").instantiate()
	root.add_child(campaign)
	await process_frame
	await process_frame
	var campaign_shell := campaign.find_child("CampaignShell", true, false)
	var progress := campaign.find_child("CampaignProgress", true, false) as Label
	var dossier := campaign.find_child("MissionDossier", true, false) as PanelContainer
	var dossier_scroll := campaign.find_child("MissionDossierScroll", true, false) as ScrollContainer
	var dossier_objective := campaign.find_child("DossierObjective", true, false) as Label
	var dossier_reward := campaign.find_child("DossierReward", true, false) as Label
	var next_stage := campaign.find_child("Stage_s1", true, false) as Button
	_check(campaign_shell != null and bool(campaign_shell.get("full_safe_area")), "Campaign did not use the full-safe-area shell")
	_check(progress != null and progress.custom_minimum_size.x >= 190.0 and progress.autowrap_mode == TextServer.AUTOWRAP_OFF, "Campaign progress can collapse or wrap vertically")
	_check(dossier != null and next_stage != null and not next_stage.disabled, "Campaign route or selected dossier is incomplete")
	_check(dossier_scroll != null and dossier_objective != null and dossier_objective.text.contains("OBJECTIVE"), "Campaign dossier objective or local scroll is missing")
	_check(dossier_reward != null and dossier_reward.text.contains("SWORD SAINT"), "Campaign dossier does not expose the typed first-clear reward")
	_dispose(campaign)
	game.set("content", null)

	var mission: Node = load("res://scenes/squad_select.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	var mission_actions := mission.find_child("MissionActions", true, false) as GridContainer
	_check(mission_actions != null and not _has_scroll_ancestor(mission_actions), "Mission actions remain trapped in body scrolling")
	if mission_actions != null:
		_check(mission_actions.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "Mission action grid does not fill portrait width")
		_check(mission_actions.get_child_count() == 3, "Mission action contract changed")
		for child: Node in mission_actions.get_children():
			_check(child is Button and (child as Button).size_flags_horizontal == Control.SIZE_EXPAND_FILL, "Mission action does not expand safely")
	_dispose(mission)
	game.set("content", null)

	var training: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(training)
	await process_frame
	await process_frame
	var training_shell := training.find_child("ReliquaryAtelierShell", true, false)
	var training_dock := training.find_child("TrainingActionDock", true, false) as VBoxContainer
	var not_now := training.find_child("TrainingBack", true, false) as Button
	_check(training_shell != null and bool(training_shell.get("full_safe_area")), "Training did not use the full-safe-area workspace")
	_check(not_now != null, "Training safe exit action is missing")
	_check(training_dock != null and not_now != null and not _has_scroll_ancestor(not_now), "Training actions remain trapped in document scrolling")
	var rename_input := training.find_child("RenameUnitInput", true, false) as LineEdit
	var rename_title := training.find_child("RenameTitleInput", true, false) as LineEdit
	var rename_review := training.find_child("RenameUnitAction", true, false) as Button
	_check(rename_input != null and rename_title != null and rename_review != null, "Training rename editor is incomplete")
	if rename_input != null and rename_title != null and rename_review != null:
		rename_input.text = "Layout Sentinel"
		rename_input.text_changed.emit(rename_input.text)
		rename_title.text = "Safe Area"
		rename_title.text_changed.emit(rename_title.text)
		await process_frame
		rename_review.pressed.emit()
		await process_frame
		var rename_confirm := training.find_child("RenameConfirm", true, false) as Button
		var rename_header := training.find_child("TrainingPersistentHeader", true, false) as VBoxContainer
		_check(StringName(training.call("mode")) == &"rename_confirmation", "Training rename review is not an in-page mode")
		_check(rename_confirm != null and not _has_scroll_ancestor(rename_confirm), "Training rename confirmation action scrolls with the body")
		_check(rename_header != null and rename_header.visible and not _has_scroll_ancestor(rename_header), "Training rename confirmation header scrolls with the body")
	_dispose(training)
	game.set("content", null)

	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _has_scroll_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is ScrollContainer:
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
		print("CAMPAIGN_UI_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
