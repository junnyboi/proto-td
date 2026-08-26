extends SceneTree

const TEST_TIMEOUT_SECONDS := 30.0
const STATE_WAIT_SECONDS := 2.0

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null, "Game autoload missing")
	_check(i18n != null, "I18n autoload missing")
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
	var campaign_scroll := campaign.find_child("CampaignScroll", true, false) as ScrollContainer
	var dossier := campaign.find_child("MissionDossier", true, false) as PanelContainer
	var dossier_scroll := campaign.find_child("MissionDossierScroll", true, false) as ScrollContainer
	var dossier_objective := campaign.find_child("DossierObjective", true, false) as Label
	var dossier_reward := campaign.find_child("DossierReward", true, false) as Label
	var next_stage := campaign.find_child("Stage_s1", true, false) as Button
	var route_panel := campaign.find_child("CampaignRoutePanel", true, false) as PanelContainer
	var route_header_inset := campaign.find_child("RouteHeaderInset", true, false) as MarginContainer
	var route_heading := campaign.find_child("RouteHeading", true, false) as Label
	var route_note := campaign.find_child("RouteNote", true, false) as Label
	var stage_label := next_stage.get_node_or_null("PresentationLabel") as Label if next_stage != null else null
	_check(campaign_shell != null and bool(campaign_shell.get("full_safe_area")), "Campaign did not use the full-safe-area shell")
	_check(progress != null and progress.custom_minimum_size.x >= 190.0 and progress.autowrap_mode == TextServer.AUTOWRAP_OFF, "Campaign progress can collapse or wrap vertically")
	_check(dossier != null and next_stage != null and not next_stage.disabled, "Campaign route or selected dossier is incomplete")
	_check(dossier_scroll != null and dossier_objective != null and not dossier_objective.text.is_empty(), "Campaign dossier objective or local scroll is missing")
	_check(dossier_reward != null and not dossier_reward.text.is_empty(), "Campaign dossier does not expose the typed first-clear reward")
	_check(route_panel != null and is_equal_approx(route_panel.size.x, 480.0), "Campaign route rail is not fixed at the annotated half-width")
	_check(route_panel != null and route_panel.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN, "Campaign route rail can still absorb surplus landscape width")
	_check(route_header_inset != null and route_header_inset.get_theme_constant(&"margin_left") == 12 and route_header_inset.get_theme_constant(&"margin_top") == 12, "Campaign route heading inset is not the requested 12px top/left")
	_check(route_panel != null and route_heading != null and route_heading.global_position.x - route_panel.global_position.x >= 28.0, "Campaign route title does not clear the panel border")
	_check(route_panel != null and route_note != null and route_note.global_position.x - route_panel.global_position.x >= 28.0, "Campaign route subtitle does not clear the panel border")
	_check(stage_label != null and is_equal_approx(stage_label.offset_top, 12.0) and is_equal_approx(stage_label.offset_bottom, -12.0), "Campaign list item does not retain exact 12px top/bottom padding")
	_check(next_stage != null and next_stage.custom_minimum_size.y >= 76.0, "Campaign list item height does not contain its vertical padding")
	_check(campaign.find_child("BasicRecruitDesk", true, false) == null, "Company Reinforcements still appears on Mission Selection")
	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	_check(
		route_panel != null and route_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL,
		"portrait Mission Selection did not restore a fluid full-width route panel",
	)
	_check(campaign_scroll != null and campaign_scroll.size.y >= 96.0, "portrait Mission Control did not reserve a visible stage list")
	_check(next_stage != null and next_stage.get_global_rect().position.y < 1280.0, "portrait First Stand action is below the viewport")
	root.size = Vector2i(1280, 720)
	_dispose(campaign)
	game.set("content", null)

	var mission: Node = load("res://scenes/squad_select.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	var mission_actions := mission.find_child("MissionActions", true, false) as GridContainer
	_check(mission_actions != null and not _has_scroll_ancestor(mission_actions), "Mission actions remain trapped in body scrolling")
	if mission_actions != null:
		_check(mission_actions.get_child_count() == 3, "Mission action contract changed")
		var mission_widths := {"BackButton": 119.0, "TrainingButton": 168.0, "StartBattle": 147.0}
		for child: Node in mission_actions.get_children():
			var action := child as Button
			_check(action != null and action.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "Mission action does not retain its compact alignment")
			if action != null and mission_widths.has(String(action.name)):
				_check(is_equal_approx(action.custom_minimum_size.x, float(mission_widths[String(action.name)])), "Mission action width reduction changed")
	_dispose(mission)
	game.set("content", null)

	game.set("training_return_path", &"mission")
	root.size = Vector2i(1280, 720)
	var training: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(training)
	await process_frame
	await process_frame
	var training_shell := training.find_child("ReliquaryAtelierShell", true, false)
	var training_dock := training.find_child("TrainingActionDock", true, false) as VBoxContainer
	var not_now := training.find_child("TrainingBack", true, false) as Button
	var return_to_mission := training.find_child("ReturnToMission", true, false) as Button
	_check(training_shell != null and bool(training_shell.get("full_safe_area")), "Training did not use the full-safe-area workspace")
	_check(not_now != null, "Training safe exit action is missing")
	_check(return_to_mission != null, "Training mission-return fixture is unavailable")
	_check(training_dock != null and not_now != null and not _has_scroll_ancestor(not_now), "Training actions remain trapped in document scrolling")
	_check(not String(training.get("accessibility_name")).is_empty() and not String(training.get("accessibility_description")).is_empty(), "Training root lacks accessibility metadata")
	var rename_input := training.find_child("RenameUnitInput", true, false) as LineEdit
	var rename_title := training.find_child("RenameTitleInput", true, false) as LineEdit
	var rename_review := training.find_child("RenameUnitAction", true, false) as Button
	_check(rename_input != null and rename_title != null and rename_review != null, "Training rename editor is incomplete")
	if rename_input != null and rename_title != null and rename_review != null:
		await _check_nested_scroll_visibility(training, rename_input)
		rename_input.text = "Layout Sentinel"
		rename_input.text_changed.emit(rename_input.text)
		rename_title.text = "Safe Area"
		rename_title.text_changed.emit(rename_title.text)
		await process_frame
		rename_review.pressed.emit()
		_check(StringName(training.call("rename_presentation_state")) == &"entering", "Training rename review did not begin ENTERING")
		_check(_owned_focus(training) == null, "Training confirmation focused a control during ENTERING")
		_check(training.find_child("ReturnToMission", true, false) == null, "ReturnToMission was not excluded while confirmation was active")
		_check(await _wait_for_state(training, &"active"), "Training rename confirmation never settled")
		await process_frame
		var rename_confirm := training.find_child("RenameConfirm", true, false) as Button
		var rename_cancel := training.find_child("RenameCancel", true, false) as Button
		var rename_comparison := training.find_child("RenameIdentityComparison", true, false) as BoxContainer
		var rename_actions := training.find_child("RenameConfirmationActions", true, false) as BoxContainer
		var rename_header := training.find_child("TrainingPersistentHeader", true, false) as VBoxContainer
		var rename_status := training.find_child("RenameConfirmationStatus", true, false) as Label
		_check(StringName(training.call("mode")) == &"rename_confirmation", "Training rename review is not an in-page mode")
		_check(rename_confirm != null and rename_confirm.has_focus(), "Training confirmation did not focus Confirm after settling")
		_check(rename_confirm != null and not _has_scroll_ancestor(rename_confirm), "Training rename confirmation action scrolls with the body")
		_check(rename_header != null and rename_header.visible and not _has_scroll_ancestor(rename_header), "Training rename confirmation header scrolls with the body")
		_check(rename_comparison != null and not rename_comparison.vertical, "wide Training rename comparison did not use columns")
		_check(rename_actions != null and not rename_actions.vertical, "wide Training rename actions did not use a row")
		_check(rename_status != null and rename_status.accessibility_live == AccessibilityServer.LIVE_POLITE, "Training rename status is not a polite live region")
		_check(rename_status != null and not String(rename_status.accessibility_name).is_empty() and not String(rename_status.accessibility_description).is_empty(), "Training rename status lacks accessibility metadata")
		if rename_confirm != null and rename_cancel != null:
			_check(rename_confirm.focus_neighbor_left == rename_confirm.get_path_to(rename_cancel), "wide Confirm left graph is incorrect")
			_check(rename_confirm.focus_neighbor_right == rename_confirm.get_path_to(rename_cancel), "wide Confirm right graph is incorrect")
			_check(rename_confirm.focus_neighbor_top == rename_confirm.get_path_to(rename_confirm), "wide Confirm retained a stale top edge")
			_check(rename_confirm.focus_neighbor_bottom == rename_confirm.get_path_to(rename_confirm), "wide Confirm retained a stale bottom edge")

		root.size = Vector2i(720, 1280)
		await process_frame
		await process_frame
		rename_confirm = training.find_child("RenameConfirm", true, false) as Button
		rename_cancel = training.find_child("RenameCancel", true, false) as Button
		rename_comparison = training.find_child("RenameIdentityComparison", true, false) as BoxContainer
		rename_actions = training.find_child("RenameConfirmationActions", true, false) as BoxContainer
		_check(rename_comparison != null and rename_comparison.vertical, "stacked Training rename comparison did not use rows")
		_check(rename_actions != null and rename_actions.vertical, "stacked Training rename actions did not use a column")
		if rename_confirm != null and rename_cancel != null:
			_check(rename_confirm.focus_neighbor_top == rename_confirm.get_path_to(rename_cancel), "stacked Confirm top graph is incorrect")
			_check(rename_confirm.focus_neighbor_bottom == rename_confirm.get_path_to(rename_cancel), "stacked Confirm bottom graph is incorrect")
			_check(rename_confirm.focus_neighbor_left == rename_confirm.get_path_to(rename_confirm), "stacked Confirm retained a stale left edge")
			_check(rename_confirm.focus_neighbor_right == rename_confirm.get_path_to(rename_confirm), "stacked Confirm retained a stale right edge")
		if rename_cancel != null:
			rename_cancel.pressed.emit()
		_check(StringName(training.call("rename_presentation_state")) == &"exiting", "Training cancel did not begin EXITING")
		_check(StringName(training.call("mode")) == &"rename_confirmation", "Training confirmation stopped being modal during EXITING")
		_check(training.find_child("ReturnToMission", true, false) == null, "ReturnToMission appeared before confirmation exit completed")
		_check(await _wait_for_state(training, &"idle"), "Training confirmation exit never completed")
		await process_frame
		await process_frame
		rename_input = training.find_child("RenameUnitInput", true, false) as LineEdit
		_check(rename_input != null and rename_input.has_focus(), "Training cancel did not restore callsign focus")
		_check(training.find_child("ReturnToMission", true, false) != null, "ReturnToMission did not return after confirmation exit")

		ProjectSettings.set_setting("accessibility/reduced_motion", true)
		rename_review = training.find_child("RenameUnitAction", true, false) as Button
		if rename_review != null:
			rename_review.pressed.emit()
		_check(StringName(training.call("rename_presentation_state")) == &"active", "reduced-motion Training confirmation was not immediate")
		rename_cancel = training.find_child("RenameCancel", true, false) as Button
		if rename_cancel != null:
			rename_cancel.pressed.emit()
		_check(StringName(training.call("rename_presentation_state")) == &"idle", "reduced-motion Training exit was not immediate")
		ProjectSettings.set_setting("accessibility/reduced_motion", false)
	_dispose(training)
	game.set("content", null)

	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("training_return_path", &"staging")
	root.size = Vector2i(1280, 720)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _wait_for_state(screen: Node, expected: StringName, timeout_seconds := STATE_WAIT_SECONDS) -> bool:
	var elapsed := 0.0
	while is_instance_valid(screen) and StringName(screen.call("rename_presentation_state")) != expected and elapsed < timeout_seconds:
		await create_timer(0.02).timeout
		elapsed += 0.02
	return is_instance_valid(screen) and StringName(screen.call("rename_presentation_state")) == expected


func _check_nested_scroll_visibility(screen: Node, control: Control) -> void:
	var ancestors: Array[ScrollContainer] = []
	var current := control.get_parent()
	while current != null:
		if current is ScrollContainer:
			ancestors.append(current as ScrollContainer)
		current = current.get_parent()
	_check(ancestors.size() >= 2, "Training rename editor is not nested inside both local and document ScrollContainers")
	for scroll: ScrollContainer in ancestors:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	screen.call("_ensure_focus_visible", control)
	await process_frame
	await process_frame
	for scroll: ScrollContainer in ancestors:
		var visible_rect := scroll.get_global_rect().intersection(control.get_global_rect())
		_check(visible_rect.size.x > 0.0 and visible_rect.size.y > 0.0, "%s did not reveal the focused Training rename control" % scroll.name)


func _owned_focus(screen: Node) -> Control:
	var focused := root.gui_get_focus_owner()
	if focused != null and screen.is_ancestor_of(focused):
		return focused
	return null


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
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("CAMPAIGN_UI_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("campaign UI layout test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
