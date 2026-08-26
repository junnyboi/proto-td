extends SceneTree

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const NARROW := Vector2i(540, 960)
const SHORT := Vector2i(960, 420)
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = LANDSCAPE
	await process_frame
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 3302)
	_check(bool(game.call("start_campaign", false, true)), "battle UI campaign fixture failed")
	game.call("start_battle", &"s1", true)
	for _frame: int in range(12):
		await process_frame
	var battle := game.get("content") as Node
	_check(battle != null and bool(battle.get("startup_succeeded")), "battle view did not start")
	if battle == null:
		_finish()
		return
	var model := game.get("current_battle") as BattleModel
	var hud := battle.find_child("BattleHud", true, false) as Label
	var deploy_bar := battle.find_child("DeployBar", true, false) as Node
	var deployment_deck := battle.find_child("DeploymentCommandDeck", true, false) as PanelContainer
	var deployment_scroll := battle.find_child("DeploymentRosterScroll", true, false) as ScrollContainer
	var slot_box := battle.find_child("SlotBox", true, false) as GridContainer
	var controls := battle.find_child("BattleControls", true, false) as Node
	var confirmation_trace: Array[StringName] = []
	controls.connect(
		"confirmation_state_changed",
		func(state: StringName) -> void: confirmation_trace.append(state),
	)
	var owned_spell_bar := battle.find_child("SpellBar", true, false) as Node
	var controls_deck := battle.find_child("BattleCommandDeck", true, false) as PanelContainer
	var pause := battle.find_child("PauseButton", true, false) as Button
	var speed := battle.find_child("SpeedButton", true, false) as Button
	var resign := battle.find_child("ResignButton", true, false) as Button
	var recenter := battle.find_child("RecenterMap", true, false) as Button
	var tutorial := battle.find_child("FirstStandTutorial", true, false) as Node
	var tutorial_card := battle.find_child("TutorialCard", true, false) as PanelContainer
	var skip := battle.find_child("SkipTutorial", true, false) as Button
	var dialogue := battle.find_child("BattleDialogue", true, false) as PanelContainer
	var dialogue_speaker := battle.find_child("DialogueSpeaker", true, false) as Label
	var dialogue_line := battle.find_child("DialogueLine", true, false) as Label
	var tutorial_primary := battle.find_child("TutorialPrimary", true, false) as Button
	_check(hud != null and hud.get_theme_stylebox(&"normal") is StyleBoxTexture, "battle HUD does not use the Lunaris command frame")
	_check(deployment_deck != null and deployment_deck.get_theme_stylebox(&"panel") is StyleBoxTexture, "deployment deck is not textured")
	if deployment_deck != null:
		var deployment_style := deployment_deck.get_theme_stylebox(&"panel")
		_check(deployment_style.content_margin_left >= 24.0 and deployment_style.content_margin_top >= 24.0, "deployment deck padding is below 24px")
	_check(deployment_scroll != null and deployment_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "deployment roster is not locally scrollable")
	_check(deployment_scroll != null and deployment_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "deployment roster permits horizontal scrolling")
	_check(slot_box != null and slot_box.get_child_count() >= 3, "deployment slots are missing")
	if slot_box != null:
		for child: Node in slot_box.get_children():
			_check(child is Button and (child as Button).custom_minimum_size.y >= 116.0, "deployment slot did not receive doubled target height")
			_check(child is Button and (child as Button).get_theme_font_size(&"font_size") >= 36, "deployment slot copy did not receive doubled typography")
			_check(deployment_deck.get_global_rect().encloses((child as Button).get_global_rect()), "deployment deck does not contain a Recruit control")
		var first_slot := slot_box.get_child(0) as Button
		_check(first_slot.get_theme_stylebox(&"normal").content_margin_left >= 28.0, "first Recruit lacks the requested left content inset")
	_check(controls_deck != null and controls_deck.get_theme_stylebox(&"panel") is StyleBoxTexture, "battle command deck is not textured")
	if controls_deck != null:
		var controls_style := controls_deck.get_theme_stylebox(&"panel")
		_check(controls_style.content_margin_left >= 24.0 and controls_style.content_margin_top >= 24.0, "battle command deck padding is below 24px")
	_check(pause != null and speed != null and resign != null and pause.focus_mode == Control.FOCUS_ALL, "battle commands are not controller focusable")
	for button: Button in [pause, speed, resign]:
		_check(button.custom_minimum_size.x >= 152.0 and button.custom_minimum_size.y >= 92.0, "%s did not receive doubled target size" % button.name)
		_check(button.get_theme_font_size(&"font_size") >= 36, "%s did not receive doubled typography" % button.name)
		_check(controls_deck.get_global_rect().encloses(button.get_global_rect()), "%s overflows the battle command deck" % button.name)
	var first_action_inset := battle.find_child("FirstActionInset", true, false) as MarginContainer
	_check(first_action_inset != null and first_action_inset.get_theme_constant(&"margin_left") >= 12, "Pause lacks the requested left inset")
	_check(recenter != null and recenter.focus_mode == Control.FOCUS_ALL, "map recenter is not controller focusable")
	_check(tutorial_card != null and tutorial_card.get_theme_stylebox(&"panel") is StyleBoxTexture, "tutorial card did not inherit the Lunaris modal frame")
	_check(dialogue != null and not dialogue.visible, "mission-start dialogue competed with the guided tutorial")
	if tutorial_card != null:
		var tutorial_rect := tutorial_card.get_global_rect()
		_check(tutorial_rect.size.x >= 900.0 and tutorial_rect.size.y >= 400.0, "tutorial card did not receive the 3× width / 2× height treatment")
		_check(absf(tutorial_rect.get_center().x - LANDSCAPE.x * 0.5) <= 2.0, "tutorial card is not horizontally centered")
	_check(skip != null and tutorial_primary != null, "tutorial actions are missing")
	if skip != null and tutorial_primary != null:
		for button: Button in [skip, tutorial_primary]:
			_check(button.custom_minimum_size.x >= 260.0 and button.custom_minimum_size.y >= 84.0, "%s has insufficient padded action geometry" % button.name)
			_check(button.get_theme_font_size(&"font_size") >= 30, "%s tutorial copy is too small" % button.name)
			_check(tutorial_card.get_global_rect().encloses(button.get_global_rect()), "%s overflows the tutorial card" % button.name)
	var spell_probe := (load("res://scripts/ui/spell_bar.gd") as Script).new() as Control
	spell_probe.name = "Phase0SpellProbe"
	battle.add_child(spell_probe)
	spell_probe.call("setup", model, battle, [&"slow_field"] as Array[StringName])
	await process_frame
	var spell_deck := spell_probe.find_child("SpellCommandDeck", true, false) as PanelContainer
	_check(spell_deck != null and controls_deck != null and not spell_deck.get_global_rect().intersects(controls_deck.get_global_rect()), "landscape spell and battle command hit regions overlap")
	if controls == null or deploy_bar == null or model == null:
		_check(false, "battle controls, deployment bar, or model missing")
		_cleanup(game, battle)
		_finish()
		return

	_check(tutorial != null and bool(tutorial.call("is_holding_battle")), "First Stand tutorial is not holding the initial battle")
	_check(not bool(deploy_bar.call("operator_interaction_enabled")), "tutorial route step did not block operator cards")
	controls.call("set_interaction_enabled", true)
	_check(bool(controls.call("request_resign_confirmation")), "resign confirmation did not open under composed tutorial fixture")
	await _wait_for_confirmation_state(controls, &"active")
	_check(bool(battle.call("battle_confirmation_active")), "battle confirmation blocker was not published")
	_check(not bool(deploy_bar.call("interaction_enabled")) and not bool(owned_spell_bar.call("interaction_enabled")), "confirmation did not gate deploy/spell interaction")
	_check(not bool(deploy_bar.call("operator_interaction_enabled")), "confirmation overwrote tutorial operator blocker")
	_check(bool(controls.call("cancel_resign_confirmation")), "composed confirmation did not cancel")
	_check(StringName(controls.call("confirmation_state_name")) == &"exiting" and bool(battle.call("battle_confirmation_active")), "Cancel released the gate before exit")
	await _wait_for_confirmation_state(controls, &"closed")
	_check(bool(deploy_bar.call("interaction_enabled")) and not bool(deploy_bar.call("operator_interaction_enabled")), "Cancel did not preserve the composed tutorial gate")
	controls.call("set_interaction_enabled", false)
	if skip != null:
		skip.pressed.emit()
	for _frame: int in range(3):
		await process_frame
	_check(bool(controls.call("interaction_enabled")) and bool(deploy_bar.call("operator_interaction_enabled")), "tutorial completion did not restore controls")
	_check(dialogue != null and dialogue.visible, "mission-start dialogue did not appear after the tutorial")
	_check(dialogue_speaker != null and not dialogue_speaker.text.is_empty(), "mission-start speaker is missing")
	_check(dialogue_line != null and not dialogue_line.text.is_empty(), "mission-start dialogue line is missing")
	if dialogue != null:
		_check(dialogue.get_global_rect().end.x <= LANDSCAPE.x + 1.0, "mission-start dialogue exceeds landscape width")
		_check(
			dialogue.get_global_rect().size.y <= 240.0,
			"mission-start dialogue expanded beyond its compact tactical height: size=%s minimum=%s"
			% [dialogue.size, dialogue.get_combined_minimum_size()],
		)
	controls.call("_on_pause_pressed")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "Pause did not stop battle tick consumption")
	controls.call("_on_pause_pressed")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 1.0), "Resume did not restore prior battle speed")
	battle.set("ticks_per_frame_scale", 0.0)
	controls.call("_process", 0.0)
	_check(bool(controls.call("request_resign_confirmation")), "paused resign confirmation did not open")
	await _wait_for_confirmation_state(controls, &"active")
	_check(bool(controls.call("cancel_resign_confirmation")), "paused resign confirmation did not cancel")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0) and bool(battle.call("battle_confirmation_active")), "paused Cancel restored gates before exit")
	await _wait_for_confirmation_state(controls, &"closed")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "Cancel did not restore an exact zero-speed snapshot")

	var exact_scale := 2.375
	battle.set("ticks_per_frame_scale", exact_scale)
	controls.call("_process", 0.0)
	_check(StringName(controls.call("confirmation_state_name")) == &"closed", "initial confirmation state is not CLOSED")
	_check(bool(controls.call("request_resign_confirmation")), "resign confirmation did not open")
	_check(StringName(controls.call("confirmation_state_name")) == &"entering", "confirmation did not publish ENTERING immediately")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0) and bool(battle.call("battle_confirmation_active")), "entry did not immediately pause and gate battle")
	await _wait_for_confirmation_state(controls, &"active")
	var layer := battle.find_child("ResignConfirmLayer", true, false) as Control
	var safe := layer.find_child("SafeFrame", true, false) as MarginContainer
	var frame := layer.find_child("StateFrame", true, false) as Control
	var panel := layer.find_child("ResignConfirm", true, false) as PanelContainer
	var cancel := layer.find_child("CancelResign", true, false) as Button
	var confirm := layer.find_child("ConfirmResign", true, false) as Button
	var status := layer.find_child("Status", true, false) as Label
	_check(layer.visible and StringName(controls.call("confirmation_state_name")) == &"active", "confirmation did not enter ACTIVE")
	_check(status != null and status.get_parent().get_parent().name == "ActionDock", "withdraw status is not visible in the action dock")
	_check(panel.accessibility_labeled_by_nodes.has(panel.get_path_to(layer.find_child("Title", true, false))), "withdraw panel is not labeled by Title")
	_check(panel.accessibility_described_by_nodes.has(panel.get_path_to(status)), "withdraw panel is not described by Status")
	_check(confirm.accessibility_name != cancel.accessibility_name and not confirm.accessibility_description.is_empty(), "withdraw actions lack distinct accessibility semantics")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "confirmation did not pause battle")
	_check(cancel.has_focus(), "Cancel is not safe default focus")
	_check(layer.mouse_filter == Control.MOUSE_FILTER_STOP and _rect_matches(layer.get_global_rect(), Rect2(Vector2.ZERO, Vector2(LANDSCAPE))), "confirmation is not a full input-exclusive viewport")
	_check(_rect_matches(panel.get_global_rect(), frame.get_global_rect()), "confirmation panel does not fill the safe content frame")
	_check(not bool(battle.call("map_dragging")) and not bool(battle.call("map_inertia_active")), "confirmation did not cancel map motion")
	_check(pause.disabled and speed.disabled and resign.disabled, "confirmation did not disable underlying battle commands")
	var blocked_pan := battle.call("map_pan") as Vector2
	var blocked_wheel := InputEventMouseButton.new()
	blocked_wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	blocked_wheel.pressed = true
	battle.call("_unhandled_input", blocked_wheel)
	battle.call("_on_recenter_map_requested")
	controls.call("_on_pause_pressed")
	controls.call("_on_speed_pressed")
	deploy_bar.call("_start_placement", StringName(deploy_bar.call("first_deployment_id")))
	_check((battle.call("map_pan") as Vector2).is_equal_approx(blocked_pan), "confirmation allowed map wheel/recenter input")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "confirmation allowed pause/speed input")
	_check(not bool(deploy_bar.call("transient_intent_active")), "confirmation allowed new deployment input")
	_check(bool(controls.call("cancel_resign_confirmation")), "confirmation did not cancel")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0) and bool(battle.call("battle_confirmation_active")), "Cancel restored speed or gate before exit finalizer")
	controls.call("_unhandled_input", _action_event(&"ui_cancel"))
	_check(root.is_input_handled() and StringName(controls.call("confirmation_state_name")) == &"exiting" and bool(battle.call("battle_confirmation_active")), "ui_cancel was not consumed throughout EXITING")
	await _wait_for_confirmation_state(controls, &"closed")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), exact_scale), "Cancel did not exactly restore speed snapshot")
	_check(resign.has_focus() and model.result == BattleModel.Result.RUNNING, "Cancel failed focus/result invariance")

	var deployment_id := StringName(deploy_bar.call("first_deployment_id"))
	deploy_bar.call("_start_placement", deployment_id)
	_check(bool(deploy_bar.call("transient_intent_active")), "deployment intent did not start")
	bool(controls.call("request_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"active")
	_check(not bool(deploy_bar.call("transient_intent_active")), "confirmation did not cancel deployment/facing intent")
	bool(controls.call("cancel_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"closed")
	spell_probe.call("_start_targeting", &"slow_field")
	_check(StringName(spell_probe.call("targeting_spell")) == &"slow_field", "spell targeting did not start")
	spell_probe.call("set_interaction_enabled", false)
	_check(StringName(spell_probe.call("targeting_spell")).is_empty(), "SpellBar interaction gate did not cancel targeting")
	spell_probe.call("set_interaction_enabled", true)
	bool(controls.call("request_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"active")
	_check(not bool(owned_spell_bar.call("interaction_enabled")), "confirmation did not retain the owned SpellBar gate")
	bool(controls.call("cancel_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"closed")
	model.dp = model.config.dp_cap
	var deploy_cell := _first_valid_deploy_cell(model, deployment_id)
	_check(deploy_cell.x >= 0 and model.apply_action([&"deploy", deployment_id, deploy_cell, int(UnitState.Facing.RIGHT)]), "retreat fixture could not deploy")
	if deploy_cell.x >= 0:
		deploy_bar.call("_handle_grid_click", battle.call("cell_center", deploy_cell))
		_check(bool(deploy_bar.call("transient_intent_active")), "retreat/selection intent did not start")
		bool(controls.call("request_resign_confirmation"))
		await _wait_for_confirmation_state(controls, &"active")
		_check(not bool(deploy_bar.call("transient_intent_active")), "confirmation did not cancel retreat/selection intent")
		bool(controls.call("cancel_resign_confirmation"))
		await _wait_for_confirmation_state(controls, &"closed")
		var deployed_unit := model.alive_unit_at(deploy_cell)
		deploy_bar.call("_begin_heal_targeting", deployed_unit)
		_check(bool(deploy_bar.call("is_mend_targeting")), "mend targeting fixture did not start")
		bool(controls.call("request_resign_confirmation"))
		await _wait_for_confirmation_state(controls, &"active")
		_check(not bool(deploy_bar.call("is_mend_targeting")), "confirmation did not cancel mend targeting")
		bool(controls.call("cancel_resign_confirmation"))
		await _wait_for_confirmation_state(controls, &"closed")

	bool(controls.call("request_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"active")
	for viewport_size: Vector2i in [PORTRAIT, NARROW, SHORT]:
		root.size = viewport_size
		await process_frame
		_check(_rect_matches(layer.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))), "confirmation root missed viewport %s" % viewport_size)
		_check(_rect_matches(panel.get_global_rect(), frame.get_global_rect()), "confirmation panel missed safe content frame at %s" % viewport_size)
		var actions := layer.find_child("Actions", true, false) as GridContainer
		var body_scroll := layer.find_child("BodyScroll", true, false) as ScrollContainer
		var dock := layer.find_child("ActionDock", true, false) as PanelContainer
		_check(actions.columns == (2 if viewport_size == SHORT else 1), "actions did not reflow at %s" % viewport_size)
		_check(cancel.size.y >= 44.0 and confirm.size.y >= 44.0, "actions lost touch size at %s" % viewport_size)
		_check(body_scroll.get_global_rect().end.y <= dock.get_global_rect().position.y + 1.0, "body overlapped fixed dock at %s" % viewport_size)
	confirm.grab_focus()
	await process_frame
	var forward_target := confirm.get_node_or_null(confirm.focus_next) as Control
	_check(
		confirm.has_focus() and forward_target != null and layer.is_ancestor_of(forward_target),
		"focus trap failed on responsive sheet",
	)
	_send_action(&"ui_left")
	await process_frame
	_check(cancel.has_focus(), "wide ui_left did not swap confirmation actions")
	_send_action(&"ui_down")
	await process_frame
	_check(cancel.has_focus(), "wide ui_down should keep the action focused")
	root.size = LANDSCAPE
	await process_frame
	bool(controls.call("cancel_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"closed")
	_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), exact_scale), "responsive Cancel did not restore exact speed")

	confirmation_trace.clear()
	var committing_cancel_consumed := [false]
	var committing_cancel_probe := func(state: StringName) -> void:
		if state != &"committing":
			return
		controls.call("_unhandled_input", _action_event(&"ui_cancel"))
		committing_cancel_consumed[0] = (
			root.is_input_handled()
			and StringName(controls.call("confirmation_state_name")) == &"committing"
			and bool(battle.call("battle_confirmation_active"))
		)
	controls.connect("confirmation_state_changed", committing_cancel_probe)
	bool(controls.call("request_resign_confirmation"))
	await _wait_for_confirmation_state(controls, &"active")
	_check(bool(controls.call("commit_resign_confirmation")), "Confirm did not accept resign")
	controls.disconnect("confirmation_state_changed", committing_cancel_probe)
	var dispatch_count := int(controls.call("resign_dispatch_count"))
	_check(confirmation_trace == [&"entering", &"active", &"committing", &"exiting"], "resign state did not expose ENTERING → ACTIVE → COMMITTING → EXITING")
	_check(committing_cancel_consumed[0], "ui_cancel was not consumed throughout COMMITTING")
	_check(dispatch_count == 1 and StringName(controls.call("confirmation_state_name")) == &"exiting", "resign did not dispatch once and retain EXITING")
	_check(bool(battle.call("battle_confirmation_active")) and layer.visible, "terminal confirmation released its gate before exit")
	_check(not bool(controls.call("commit_resign_confirmation")) and int(controls.call("resign_dispatch_count")) == dispatch_count, "terminal confirmation dispatched twice")
	battle.call("_detect_result_stamp")
	var continue_during_exit := battle.find_child("ContinueButton", true, false) as Button
	_check(continue_during_exit != null and not continue_during_exit.has_focus(), "terminal Continue focused before confirmation exit closed")
	await _wait_for_confirmation_state(controls, &"closed")
	_check(confirmation_trace == [&"entering", &"active", &"committing", &"exiting", &"closed"], "terminal exit did not finalize CLOSED")
	await process_frame
	var continue_button := battle.find_child("ContinueButton", true, false) as Button
	var pan_hint := battle.find_child("MapPanHint", true, false) as Control
	_check(model.result == BattleModel.Result.DEFEAT and not layer.visible, "terminal defeat retained confirmation")
	_check(pause.disabled and speed.disabled and resign.disabled, "terminal battle controls remain actionable")
	_check(not bool(deploy_bar.call("interaction_enabled")) and not bool(owned_spell_bar.call("interaction_enabled")), "terminal deploy/spell controls remain actionable")
	_check(pan_hint == null or not pan_hint.visible, "terminal map hint remains visible")
	_check(continue_button != null and continue_button.has_focus(), "terminal Continue did not own focus")
	var terminal_pan := battle.call("map_pan") as Vector2
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	battle.call("_unhandled_input", wheel)
	_check((battle.call("map_pan") as Vector2).is_equal_approx(terminal_pan), "terminal map accepted wheel input")
	_cleanup(game, battle)
	await create_timer(0.25).timeout
	_finish()

func _wait_for_confirmation_state(controls: Node, expected: StringName, timeout_seconds := 0.8) -> void:
	var timeout := create_timer(timeout_seconds, true, false, true)
	while StringName(controls.call("confirmation_state_name")) != expected and timeout.time_left > 0.0:
		await process_frame


func _send_action(action: StringName) -> void:
	Input.parse_input_event(_action_event(action))


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _first_valid_deploy_cell(model: BattleModel, deployment_id: StringName) -> Vector2i:
	for y: int in model.stage.grid_size().y:
		for x: int in model.stage.grid_size().x:
			var cell := Vector2i(x, y)
			if model.can_deploy_at(deployment_id, cell):
				return cell
	return Vector2i(-1, -1)

func _rect_matches(actual: Rect2, expected: Rect2, tolerance := 1.5) -> bool:
	return actual.position.distance_to(expected.position) <= tolerance and actual.size.distance_to(expected.size) <= tolerance

func _cleanup(game: Node, battle: Node) -> void:
	game.set("content", null)
	game.set("current_battle", null)
	game.set("pending_stage", null)
	if battle != null and is_instance_valid(battle):
		var parent := battle.get_parent()
		if parent != null:
			parent.remove_child(battle)
		battle.free()
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("BATTLE_UI_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
