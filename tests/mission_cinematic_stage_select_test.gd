extends SceneTree

const CampaignFixture := preload("res://test/support/authoritative_campaign_fixture.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 94117)
	_check(bool(game.call("start_campaign", false, true)), "mission cinematic gate fixture failed")
	var clear_fixture := CampaignFixture.clear_stage(
		game, &"s1", "mission-cinematic-stage-select",
	)
	_check(
		clear_fixture.get("accepted", false),
		"authoritative S1 clear fixture failed: %s" % clear_fixture.get("error_code", &"unknown"),
	)
	if not clear_fixture.get("accepted", false):
		_finish()
		return
	var state := game.get("campaign") as CampaignStateV3
	var before_data := state.data_copy()
	var before_strategic := state.strategic_hash()
	var before_core := state.core_hash()
	var before_revision := state.save_revision()
	var campaign := load("res://scenes/stage_select.tscn").instantiate() as Control
	root.add_child(campaign)
	await process_frame
	await process_frame
	for index: int in range(1, 17):
		var row := campaign.find_child("Stage_s%d" % index, true, false) as Button
		_check(row != null, "Stage Select is missing mission row s%d" % index)
		if row != null:
			_check(row.disabled == (index > 2), "Stage Select lock state changed for s%d" % index)
	var cleared := campaign.find_child("Stage_s1", true, false) as Button
	var next := campaign.find_child("Stage_s2", true, false) as Button
	var locked := campaign.find_child("Stage_s3", true, false) as Button
	var start_mission := campaign.find_child("StartMission", true, false) as Button
	var dossier_status := campaign.find_child("DossierStatus", true, false) as Label
	var enabled_rows: Array = campaign.get("_enabled_rows")
	var cleared_hover := cleared.get_node_or_null("RouteHoverBackground") as ColorRect if cleared != null else null
	_check(cleared != null and not cleared.disabled and cleared.focus_mode == Control.FOCUS_ALL, "cleared mission row is not replayable by keyboard")
	_check(cleared_hover != null, "cleared mission row lacks pointer interaction feedback")
	_check(next != null and not next.disabled, "next mission row is not available after the prior clear")
	_check(enabled_rows.size() == 2 and enabled_rows.has(cleared) and enabled_rows.has(next), "cleared and next mission rows are not both in the enabled focus set")
	_check(cleared != null and next != null and cleared.get_node_or_null(cleared.focus_neighbor_bottom) == next, "cleared mission row does not focus the next available operation")
	_check(cleared != null and next != null and next.get_node_or_null(next.focus_neighbor_top) == cleared, "next operation does not focus back to the cleared mission row")
	locked.pressed.emit()
	await process_frame
	_check(campaign.find_child("MissionCinematicOverlay", true, false) == null, "locked mission row opened a cinematic")
	cleared.mouse_entered.emit()
	await create_timer(0.22).timeout
	_check(campaign.get("_dossier_stage_id") == &"s1", "hovering a cleared route did not preview its dossier")
	_check(cleared_hover != null and cleared_hover.color.a >= 0.38 and cleared.scale.x >= 1.024, "cleared route hover feedback did not activate")
	cleared.mouse_exited.emit()
	await create_timer(0.22).timeout
	campaign.call("_show_dossier", &"s2")
	await process_frame
	cleared.pressed.emit()
	await process_frame
	await process_frame
	_check(campaign.find_child("MissionCinematicOverlay", true, false) == null, "selecting a cleared route card bypassed Start Mission")
	_check(campaign.get("_dossier_stage_id") == &"s1", "cleared route card did not select its exact operation")
	_check(dossier_status != null and dossier_status.text.contains("Replay available"), "cleared route selection did not expose replay status")
	_check(start_mission != null and not start_mission.disabled and start_mission.has_focus(), "cleared route selection did not hand focus to Start Mission")
	if start_mission != null:
		start_mission.pressed.emit()
	await process_frame
	var overlay := campaign.find_child("MissionCinematicOverlay", true, false)
	_check(overlay != null, "Start Mission did not open the cinematic overlay")
	_check(bool(campaign.call("cinematic_gate_active")), "Stage Select route input did not lock during the overlay")
	_check(game.get("selected_stage_id") == &"", "Stage Select routed before the terminal signal")
	_check(not cleared.disabled and cleared.focus_mode == Control.FOCUS_NONE, "route input was not disabled behind the overlay")
	_check(state.save_revision() == before_revision and state.data_copy() == before_data, "opening the mission cinematic mutated campaign save data")
	_check(state.strategic_hash() == before_strategic, "opening the mission cinematic changed the strategic hash")
	_check(state.core_hash() == before_core, "opening the mission cinematic changed the core hash")
	if overlay != null:
		var skip := overlay.call("action_button") as Button
		_check(skip != null and skip.has_focus(), "mission cinematic Skip did not own initial focus")
		if skip != null:
			skip.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	_check(game.get("selected_stage_id") == &"s1", "terminal signal did not route the exact stage to Field Team")
	_check(state.save_revision() == before_revision and state.data_copy() == before_data, "terminal route mutated campaign save data")
	_check(state.strategic_hash() == before_strategic and state.core_hash() == before_core, "terminal route changed strategic/core hashes")
	var content := game.get("content") as Node
	_check(content != null and content.name == "SquadSelect", "terminal route did not open Field Team")
	if content != null and is_instance_valid(content):
		var parent := content.get_parent()
		if parent != null:
			parent.remove_child(content)
		content.free()
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
		for child: Node in music.get_children():
			if child is AudioStreamPlayer:
				var player := child as AudioStreamPlayer
				player.stop()
				player.stream = null
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MISSION_CINEMATIC_STAGE_SELECT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
