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
	game.call("set_run_seed", 2026)
	_check(bool(game.call("start_campaign", false, true)), "results campaign fixture failed")
	var projection: Dictionary = game.call("campaign_projection")
	var hero_id := String(projection.get("ready_heroes", [])[0].get("hero_id", ""))
	game.set("last_result", {
		"stage_id": &"s1",
		"result": BattleModel.Result.CLEAR,
		"stars": 3,
		"kills": 14,
		"leaks": 0,
		"rewards_granted": [{"kind": "currency", "id": "marks", "amount": 40}],
		"class_entitlements_granted": [&"mage_apprentice"],
		"xp_awards": [{"hero_id": hero_id, "xp": 6}],
		"dead_hero_ids": [],
		"premium_life_losses": [],
	})
	var screen: Node = load("res://scenes/results.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var shell := screen.find_child("ResultsShell", true, false)
	var ceremony := screen.find_child("OutcomeCeremony", true, false) as PanelContainer
	var headline := screen.find_child("Headline", true, false) as Label
	var stars := screen.find_child("ResultStars", true, false) as HBoxContainer
	var reward := screen.find_child("Reward0", true, false) as PanelContainer
	var entitlement := screen.find_child("Entitlement0", true, false) as PanelContainer
	var xp := screen.find_child("XpAward0", true, false) as PanelContainer
	var no_casualties := screen.find_child("NoCasualties", true, false) as PanelContainer
	var transmission := screen.find_child("ClearTransmission", true, false) as PanelContainer
	var transmission_speaker := screen.find_child("TransmissionSpeaker", true, false) as Label
	var transmission_body := screen.find_child("TransmissionBody", true, false) as Label
	var actions := screen.find_child("ActionRow", true, false) as GridContainer
	var staging := screen.find_child("ReturnToStaging", true, false) as Button
	var title := screen.find_child("BackToTitle", true, false) as Button
	_check(shell != null and bool(shell.get("full_safe_area")), "Results did not opt into full-safe-area shell")
	_check(ceremony != null and headline != null and headline.get_theme_font_size(&"font_size") >= 40, "Results outcome ceremony is not dominant")
	_check(stars != null and stars.get_child_count() == 3, "native result stars are missing")
	_check(reward != null and entitlement != null and xp != null, "typed result payload cards are incomplete")
	_check(no_casualties != null, "no-casualty state is missing")
	_check(transmission != null, "clear result omitted its canon transmission")
	_check(transmission_speaker != null and transmission_speaker.text == "ARCHIVE CASTER", "clear transmission speaker is incorrect")
	_check(transmission_body != null and transmission_body.text.contains("PROTOS"), "clear transmission body is not canonical")
	_check(actions != null and staging != null and title != null, "persistent Results actions are incomplete")
	_check(actions != null and not _has_scroll_ancestor(actions), "Results actions remain buried inside scroll content")
	if actions != null:
		for child: Node in actions.get_children():
			if child is Button:
				_check((child as Button).custom_minimum_size.y >= 44.0, "Results action is not touch safe")

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	screen.call("_unhandled_input", cancel)
	for _frame: int in range(4):
		await process_frame
	var content := game.get("content") as Node
	_check(content != null and content.get_script().resource_path == "res://scripts/ui/staging.gd", "active-campaign ui_cancel did not return safely to Company Command")
	game.set("content", null)
	if content != null and is_instance_valid(content):
		var parent := content.get_parent()
		if parent != null:
			parent.remove_child(content)
		content.free()
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


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("RESULTS_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
