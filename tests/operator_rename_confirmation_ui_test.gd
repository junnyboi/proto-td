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
	if game == null or i18n == null:
		_finish()
		return
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	game.call("set_run_seed", 8848)
	_check(bool(game.call("start_campaign", false, true)), "rename UI fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	game.set("training_return_path", &"mission")
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var hero_id := String(screen.call("selected_hero_id"))
	var callsign := screen.find_child("RenameUnitInput", true, false) as LineEdit
	var title := screen.find_child("RenameTitleInput", true, false) as LineEdit
	var review := screen.find_child("RenameUnitAction", true, false) as Button
	var workspace := screen.find_child("TrainingWorkspace", true, false) as Control
	_check(not hero_id.is_empty(), "Training did not select a renameable operator")
	_check(callsign != null and title != null and review != null and workspace != null, "rename editor controls are missing")
	_check(not String(screen.get("accessibility_name")).is_empty(), "Training screen lacks an accessibility name")
	_check(not String(screen.get("accessibility_description")).is_empty(), "Training screen lacks an accessibility description")
	_check(screen.find_child("ReturnToMission", true, false) != null, "mission return action fixture is unavailable")
	if callsign == null or title == null or review == null or workspace == null:
		_dispose(screen)
		_finish()
		return
	_check(not String(callsign.accessibility_name).is_empty() and not String(callsign.accessibility_description).is_empty(), "callsign field lacks accessibility metadata")
	_check(not String(title.accessibility_name).is_empty() and not String(title.accessibility_description).is_empty(), "title field lacks accessibility metadata")

	_set_line_edit_text(callsign, "Aster Vale")
	_set_line_edit_text(title, "Night Watch")
	await process_frame
	_check(not review.disabled, "valid rename draft did not enable Review")
	var editor_origin := workspace.position
	review.pressed.emit()
	_check(StringName(screen.call("rename_presentation_state")) == &"entering", "Review did not synchronously enter ENTERING")
	_check(StringName(screen.call("mode")) == &"rename_confirmation", "Review did not enter rename_confirmation mode")
	_check(StringName(screen.call("rename_domain_state")) == &"active", "rename domain was not active during entry")
	_check(_owned_focus(screen) == null, "confirmation acquired focus during ENTERING")
	_check(is_equal_approx(workspace.modulate.a, 0.0), "entry did not start fully transparent")
	var timing := screen.call("rename_transition_timing") as Dictionary
	_check(is_equal_approx(workspace.position.y - editor_origin.y, float(timing["vertical_offset"])), "entry did not start at the configured vertical offset")
	_check(screen.find_child("ReturnToMission", true, false) == null, "ReturnToMission remained available while confirmation was active")
	_check(screen.find_child("RenameConfirmationDialog", true, false) == null, "native rename popup still exists")
	var snapshot := screen.call("pending_identity_snapshot") as Dictionary
	_check(String(snapshot.get("hero_id", "")) == hero_id, "pending snapshot lost hero identity")
	_check(String(snapshot.get("callsign", "")) == "Aster Vale", "pending snapshot lost callsign")
	_check(String(snapshot.get("title", "")) == "Night Watch", "pending snapshot lost title")
	var entering_status := screen.find_child("RenameConfirmationStatus", true, false) as Label
	_check(entering_status != null and entering_status.accessibility_live == AccessibilityServer.LIVE_POLITE, "entry status is not exposed as a polite live region")

	root.size = Vector2i(720, 1280)
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed during ENTERING")
	await process_frame
	_check(StringName(screen.call("rename_presentation_state")) == &"entering", "locale/resize interrupted ENTERING")
	_check(screen.call("pending_identity_snapshot") == snapshot, "locale/resize changed the immutable pending snapshot")
	_check(_owned_focus(screen) == null, "locale/resize acquired focus during ENTERING")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed during ENTERING")
	_check(await _wait_for_state(screen, &"active"), "rename confirmation never settled ACTIVE")
	await process_frame
	var confirm := screen.find_child("RenameConfirm", true, false) as Button
	var cancel := screen.find_child("RenameCancel", true, false) as Button
	var comparison := screen.find_child("RenameIdentityComparison", true, false) as BoxContainer
	var actions := screen.find_child("RenameConfirmationActions", true, false) as BoxContainer
	var dock := screen.find_child("TrainingActionDock", true, false) as VBoxContainer
	var persistent_header := screen.find_child("TrainingPersistentHeader", true, false) as VBoxContainer
	var status := screen.find_child("RenameConfirmationStatus", true, false) as Label
	_check(confirm != null and cancel != null and comparison != null and actions != null, "rename confirmation composition is incomplete")
	_check(confirm != null and confirm.has_focus(), "Confirm did not receive focus after entry settled")
	_check(is_equal_approx(workspace.modulate.a, 1.0), "settled confirmation opacity is not 1")
	_check(workspace.position.is_equal_approx(editor_origin), "settled confirmation retained an entry offset")
	_check(dock != null and confirm != null and not _has_scroll_ancestor(confirm), "rename actions are not fixed in TrainingActionDock")
	_check(persistent_header != null and persistent_header.visible and not _has_scroll_ancestor(persistent_header), "rename header is not persistent")
	_check(confirm != null and confirm.custom_minimum_size.y >= 44.0, "rename Confirm hit target is under 44px")
	_check(cancel != null and cancel.custom_minimum_size.y >= 44.0, "rename Cancel hit target is under 44px")
	_check(comparison != null and comparison.vertical and actions != null and actions.vertical, "portrait confirmation did not stack")
	_check(status != null and not String(status.accessibility_name).is_empty() and not String(status.accessibility_description).is_empty(), "rename status lacks accessibility metadata")
	_check(status != null and status.accessibility_live == AccessibilityServer.LIVE_POLITE, "ready status is not a polite live region")
	_check(confirm != null and not String(confirm.accessibility_name).is_empty() and not String(confirm.accessibility_description).is_empty(), "Confirm lacks accessibility metadata")
	_check(cancel != null and not String(cancel.accessibility_name).is_empty() and not String(cancel.accessibility_description).is_empty(), "Cancel lacks accessibility metadata")
	if confirm != null and cancel != null:
		_check(confirm.focus_neighbor_top == confirm.get_path_to(cancel), "stacked Confirm top neighbor is not Cancel")
		_check(confirm.focus_neighbor_bottom == confirm.get_path_to(cancel), "stacked Confirm bottom neighbor is not Cancel")
		_check(confirm.focus_neighbor_left == confirm.get_path_to(confirm), "stacked Confirm retained a stale left neighbor")
		_check(confirm.focus_neighbor_right == confirm.get_path_to(confirm), "stacked Confirm retained a stale right neighbor")
		_check(confirm.focus_next == confirm.get_path_to(cancel), "stacked Confirm does not wrap forward to Cancel")

	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	comparison = screen.find_child("RenameIdentityComparison", true, false) as BoxContainer
	actions = screen.find_child("RenameConfirmationActions", true, false) as BoxContainer
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	cancel = screen.find_child("RenameCancel", true, false) as Button
	_check(comparison != null and not comparison.vertical and actions != null and not actions.vertical, "wide confirmation did not use horizontal layout")
	if confirm != null and cancel != null:
		_check(confirm.focus_neighbor_left == confirm.get_path_to(cancel), "wide Confirm left neighbor is not Cancel")
		_check(confirm.focus_neighbor_right == confirm.get_path_to(cancel), "wide Confirm right neighbor is not Cancel")
		_check(confirm.focus_neighbor_top == confirm.get_path_to(confirm), "wide Confirm retained a stale top neighbor")
		_check(confirm.focus_neighbor_bottom == confirm.get_path_to(confirm), "wide Confirm retained a stale bottom neighbor")
		_check(cancel.focus_previous == cancel.get_path_to(confirm), "Cancel does not wrap backward to Confirm")

	if cancel != null:
		cancel.pressed.emit()
	_check(StringName(screen.call("rename_presentation_state")) == &"exiting", "Cancel did not synchronously begin EXITING")
	_check(StringName(screen.call("mode")) == &"rename_confirmation", "confirmation stopped being modal at exit start")
	_check(not (screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "exit cleared pending snapshot before completion")
	_check(screen.find_child("ReturnToMission", true, false) == null, "ReturnToMission appeared during EXITING")
	_check(_owned_focus(screen) == null, "EXITING retained focus on a disabled confirmation action")
	await create_timer(float(timing["exit_seconds"]) * 0.45).timeout
	_check(StringName(screen.call("rename_presentation_state")) == &"exiting", "confirmation exit completed before its configured duration")
	_check(StringName(screen.call("mode")) == &"rename_confirmation", "confirmation was not modal throughout EXITING")
	_check(await _wait_for_state(screen, &"idle"), "cancel exit never completed")
	await process_frame
	await process_frame
	_check(StringName(screen.call("mode")) == &"roster", "Cancel did not restore roster/editor mode")
	_check((screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "Cancel retained pending snapshot")
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_check(callsign != null and callsign.text == "Aster Vale", "Cancel lost callsign draft")
	_check(title != null and title.text == "Night Watch", "Cancel lost title draft")
	_check(callsign != null and callsign.has_focus(), "Cancel did not restore callsign focus")
	if callsign != null:
		await _check_nested_scroll_visibility(screen, callsign)

	# Reopen before any stale focus callback can take ownership of the new modal.
	review = screen.find_child("RenameUnitAction", true, false) as Button
	var generation_before_reopen := int(screen.call("rename_transition_generation"))
	if review != null:
		review.pressed.emit()
	_check(int(screen.call("rename_transition_generation")) > generation_before_reopen, "rapid reopen did not invalidate stale transition callbacks")
	_check(StringName(screen.call("rename_presentation_state")) == &"entering", "rapid reopen did not start a fresh ENTERING transition")
	await process_frame
	_check(_owned_focus(screen) == null, "stale editor focus callback stole focus during rapid reopen")
	_check(await _wait_for_state(screen, &"active"), "rapidly reopened confirmation never settled")
	cancel = screen.find_child("RenameCancel", true, false) as Button
	if cancel != null:
		cancel.pressed.emit()
	_check(await _wait_for_state(screen, &"idle"), "rapid reopen cancel never completed")
	await process_frame
	await process_frame

	# Force an authoritative invalid-title rejection after a valid draft was snapshotted.
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	review = screen.find_child("RenameUnitAction", true, false) as Button
	if review != null:
		review.pressed.emit()
	_check(await _wait_for_state(screen, &"active"), "rejection confirmation never settled")
	var invalid_snapshot := screen.call("pending_identity_snapshot") as Dictionary
	invalid_snapshot["title"] = "XXXXXXXXXXXXXXXXXXXXXXXXX"
	screen.set("_pending_identity", invalid_snapshot)
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	var dispatch_before := int(screen.call("rename_dispatch_count"))
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	_check(int(screen.call("rename_dispatch_count")) == dispatch_before + 1, "rejection dispatched Game.rename_hero more than once")
	_check(StringName(screen.call("rename_presentation_state")) == &"exiting", "rejection did not remain modal while exiting")
	_check(await _wait_for_state(screen, &"idle"), "rejection exit never completed")
	await process_frame
	await process_frame
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	var error := screen.find_child("RenameUnitError", true, false) as Label
	_check(StringName(screen.call("mode")) == &"roster", "rejection did not restore editor")
	_check(callsign != null and callsign.text == "Aster Vale", "rejection lost callsign draft")
	_check(title != null and title.text == "Night Watch", "rejection lost title draft")
	_check(error != null and not error.text.is_empty(), "rejection did not expose authoritative error")
	_check(error != null and error.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "authoritative error is not an assertive live region")
	_check(title != null and title.has_focus(), "invalid-title rejection did not focus title")

	# Successful commit must consume exactly one dispatch and clear the draft only after exit.
	review = screen.find_child("RenameUnitAction", true, false) as Button
	if review != null:
		review.pressed.emit()
	_check(await _wait_for_state(screen, &"active"), "success confirmation never settled")
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	dispatch_before = int(screen.call("rename_dispatch_count"))
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	_check(int(screen.call("rename_dispatch_count")) == dispatch_before + 1, "success did not dispatch Game.rename_hero exactly once")
	_check(StringName(screen.call("rename_domain_state")) == &"committing", "successful dispatch did not remain COMMITTING during exit")
	_check(not (screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "success cleared pending snapshot before exit completed")
	_check(not (screen.call("identity_edit_draft") as Dictionary).is_empty(), "success cleared editor draft before exit completed")
	_check(await _wait_for_state(screen, &"idle"), "success exit never completed")
	await process_frame
	_check((screen.call("identity_edit_draft") as Dictionary).is_empty(), "success retained editor draft")
	_check((screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "success retained pending snapshot")
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_check(callsign != null and callsign.text == "Aster Vale", "success did not refresh the callsign editor")
	_check(title != null and title.text == "Night Watch", "success did not refresh the title editor")
	var committed := _hero(game.get("campaign").runtime_projection()["ready_heroes"], hero_id)
	_check(str(committed.get("callsign", "")) == "Aster Vale", "authoritative roster did not refresh committed callsign")
	_check(str(committed.get("custom_title", "")) == "Night Watch", "authoritative roster did not refresh committed title")

	# Blank optional title is represented as null in both the immutable snapshot and authority.
	_set_line_edit_text(title, "")
	await process_frame
	review = screen.find_child("RenameUnitAction", true, false) as Button
	_check(review != null and not review.disabled, "clearing an optional title did not enable Review")
	if review != null:
		review.pressed.emit()
	_check(await _wait_for_state(screen, &"active"), "title-clearing confirmation never settled")
	var clear_title_snapshot := screen.call("pending_identity_snapshot") as Dictionary
	_check(clear_title_snapshot.has("title") and clear_title_snapshot["title"] == null, "blank title was not snapshotted as null")
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	dispatch_before = int(screen.call("rename_dispatch_count"))
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	_check(int(screen.call("rename_dispatch_count")) == dispatch_before + 1, "title clearing did not issue exactly one rename call")
	_check(await _wait_for_state(screen, &"idle"), "title-clearing exit never completed")
	await process_frame
	committed = _hero(game.get("campaign").runtime_projection()["ready_heroes"], hero_id)
	_check(committed.has("custom_title") and committed["custom_title"] == null, "authoritative roster stored a blank title instead of null")

	# Reduced motion has the same final lifecycle synchronously, without transient offsets.
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_set_line_edit_text(title, "Reduced Motion")
	await process_frame
	review = screen.find_child("RenameUnitAction", true, false) as Button
	var reduced_origin := workspace.position
	if review != null:
		review.pressed.emit()
	_check(StringName(screen.call("rename_presentation_state")) == &"active", "reduced motion did not complete entry immediately")
	_check(is_equal_approx(workspace.modulate.a, 1.0) and workspace.position.is_equal_approx(reduced_origin), "reduced-motion entry did not land on the normal final opacity/offset")
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	_check(confirm != null and confirm.has_focus(), "reduced-motion entry did not focus Confirm")
	cancel = screen.find_child("RenameCancel", true, false) as Button
	if cancel != null:
		cancel.pressed.emit()
	_check(StringName(screen.call("rename_presentation_state")) == &"idle", "reduced motion did not complete exit immediately")
	_check(StringName(screen.call("mode")) == &"roster", "reduced-motion exit did not restore editor immediately")
	_check(is_equal_approx(workspace.modulate.a, 1.0) and workspace.position.is_equal_approx(reduced_origin), "reduced-motion exit did not restore normal final opacity/offset")
	_check(not (screen.call("identity_edit_draft") as Dictionary).is_empty(), "reduced-motion cancel lost the editor draft")
	await process_frame

	# Disposing during ENTERING must invalidate the tween callback and locale listener safely.
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	review = screen.find_child("RenameUnitAction", true, false) as Button
	if review != null:
		review.pressed.emit()
	_check(StringName(screen.call("rename_presentation_state")) == &"entering", "disposal fixture did not enter transition")
	_dispose(screen)
	_check(bool(i18n.call("set_locale", &"zh-CN")), "locale switch after node disposal failed")
	await create_timer(float(timing["entry_seconds"]) + 0.1).timeout
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration after node disposal failed")

	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("training_return_path", &"staging")
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	root.size = Vector2i(1280, 720)
	await create_timer(0.15).timeout
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
	_check(ancestors.size() >= 2, "rename field is not nested in both inspector and document ScrollContainers")
	for scroll: ScrollContainer in ancestors:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	screen.call("_ensure_focus_visible", control)
	await process_frame
	await process_frame
	for scroll: ScrollContainer in ancestors:
		var visible_rect := scroll.get_global_rect().intersection(control.get_global_rect())
		_check(visible_rect.size.x > 0.0 and visible_rect.size.y > 0.0, "%s did not make the focused rename field visible" % scroll.name)


func _owned_focus(screen: Node) -> Control:
	var focused := root.gui_get_focus_owner()
	if focused != null and screen.is_ancestor_of(focused):
		return focused
	return null


func _set_line_edit_text(field: LineEdit, value: String) -> void:
	if field == null:
		return
	field.text = value
	field.text_changed.emit(value)


func _hero(rows: Array, hero_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("hero_id", "")) == hero_id:
			return row
	return {}


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
		print("OPERATOR_RENAME_CONFIRMATION_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("operator rename confirmation UI test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
