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
	game.call("set_run_seed", 94117)
	_check(bool(game.call("start_campaign", false, true)), "mission cinematic gate fixture failed")
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
			_check(row.disabled == (index > 1), "Stage Select lock state changed for s%d" % index)
	var unlocked := campaign.find_child("Stage_s1", true, false) as Button
	var locked := campaign.find_child("Stage_s2", true, false) as Button
	locked.pressed.emit()
	await process_frame
	_check(campaign.find_child("MissionCinematicOverlay", true, false) == null, "locked mission row opened a cinematic")
	unlocked.pressed.emit()
	await process_frame
	var overlay := campaign.find_child("MissionCinematicOverlay", true, false)
	_check(overlay != null, "unlocked mission row did not open the cinematic overlay")
	_check(bool(campaign.call("cinematic_gate_active")), "Stage Select route input did not lock during the overlay")
	_check(game.get("selected_stage_id") == &"", "Stage Select routed before the terminal signal")
	_check(not unlocked.disabled and unlocked.focus_mode == Control.FOCUS_NONE, "route input was not disabled behind the overlay")
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
