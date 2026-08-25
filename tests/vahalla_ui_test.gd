extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(31337, 1, context)
	_check(created.get("accepted", false), "Vahalla campaign fixture failed")
	if not created.get("accepted", false):
		_finish()
		return
	var state: Variant = created["value"]
	var initial: Dictionary = state.runtime_projection()
	var fallen_id := String(initial["ready_heroes"][0]["hero_id"])
	state = _fall_once(state, context, fallen_id)
	if state == null:
		_finish()
		return

	var game: Node = root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.set("campaign", state)
	game.set("campaign_active", true)
	game.set("selected_stage_id", &"s1")

	var squad: Node = load("res://scenes/squad_select.tscn").instantiate()
	root.add_child(squad)
	await process_frame
	await process_frame
	var grid := squad.find_child("OperatorGrid", true, false) as GridContainer
	var active_tab := squad.find_child("ActiveRosterTab", true, false) as Button
	var fallen_tab := squad.find_child("FallenRosterTab", true, false) as Button
	_check(grid != null, "squad roster grid missing")
	_check(active_tab != null and active_tab.text.contains("4"), "active tab count is wrong")
	_check(fallen_tab != null and fallen_tab.text.contains("1"), "fallen tab count is wrong")
	if grid != null:
		_check(grid.get_node_or_null("Pick_%s" % fallen_id) == null, "fallen soldier visible by default")
	if fallen_tab != null:
		fallen_tab.pressed.emit()
		await process_frame
		var fallen_card := grid.get_node_or_null("Pick_%s" % fallen_id) as Button
		_check(fallen_card != null, "fallen tab did not reveal the dead soldier")
		_check(fallen_card != null and fallen_card.disabled, "fallen squad card remained deployable")
	_dispose(squad)
	game.set("content", null)
	await process_frame

	var staging: Node = load("res://scenes/staging.tscn").instantiate()
	root.add_child(staging)
	await process_frame
	await process_frame
	var vahalla_tile := staging.find_child("VahallaButton", true, false) as Button
	var faction_heading := staging.find_child("FactionStandardsHeading", true, false)
	var faction_grid := staging.find_child("FactionStandardsGrid", true, false)
	_check(vahalla_tile != null, "Company Command Vahalla tile missing")
	_check(vahalla_tile != null and not vahalla_tile.disabled, "Company Command Vahalla tile disabled")
	_check(faction_heading == null, "Company Command faction standards heading still visible")
	_check(faction_grid == null, "Company Command faction standards grid still visible")
	_dispose(staging)
	game.set("content", null)
	await process_frame

	var memorial: Node = load("res://scenes/vahalla.tscn").instantiate()
	root.add_child(memorial)
	await process_frame
	await process_frame
	var memorial_grid := memorial.find_child("VahallaMemorialGrid", true, false) as GridContainer
	var honor := memorial.find_child("Honor_%s" % fallen_id, true, false) as Button
	_check(memorial_grid != null and memorial_grid.get_child_count() == 1, "Vahalla memorial card missing")
	_check(honor != null and not honor.disabled, "Vahalla honor action unavailable")
	if honor != null:
		honor.pressed.emit()
		await process_frame
		var honored := memorial.find_child("Honor_%s" % fallen_id, true, false) as Button
		_check(honored != null and honored.disabled, "honor action did not become visit-local honored state")
		_check(honored != null and honored.text == "HONORED", "honor action copy did not update")
	_dispose(memorial)
	game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	game.set("campaign_active", false)
	game.set("campaign", null)
	await process_frame
	await create_timer(0.1).timeout
	_finish()


func _fall_once(state: Variant, context: Dictionary, hero_id: String) -> Variant:
	var begin: Dictionary = state.begin_attempt(
		"test:vahalla:begin", "s1", [hero_id], 404, state.save_revision(),
	)
	_check(begin.get("accepted", false), "Vahalla fixture attempt failed")
	if not begin.get("accepted", false):
		return null
	state = _restore_mutation(begin, context)
	if state == null:
		return null
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "defeat",
		"terminal_reason": "resign",
		"terminal_tick": 20,
		"stars": 0,
		"leaks": 0,
		"kills": 0,
		"rows": [{
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": true,
			"first_fall_tick": 10,
		}],
	}, ticket)
	_check(outcome.get("accepted", false), "Vahalla fixture outcome failed")
	if not outcome.get("accepted", false):
		return null
	var resolved: Dictionary = state.resolve_attempt(
		"test:vahalla:resolve", ticket["attempt_id"], outcome["value"], state.save_revision(),
	)
	_check(resolved.get("accepted", false), "Vahalla fixture resolution failed")
	return _restore_mutation(resolved, context) if resolved.get("accepted", false) else null


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "Vahalla fixture mutation missing")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "Vahalla fixture save restore failed")
	return restored["value"] if restored.get("accepted", false) else null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _dispose(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _finish() -> void:
	if _failures.is_empty():
		print("VAHALLA_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
