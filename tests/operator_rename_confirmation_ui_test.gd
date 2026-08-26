extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0

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
	game.call("set_run_seed", 8848)
	_check(bool(game.call("start_campaign", false, true)), "rename UI fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var hero_id := String(screen.call("selected_hero_id"))
	var callsign := screen.find_child("RenameUnitInput", true, false) as LineEdit
	var title := screen.find_child("RenameTitleInput", true, false) as LineEdit
	var review := screen.find_child("RenameUnitAction", true, false) as Button
	_check(not hero_id.is_empty(), "Training did not select a renameable operator")
	_check(callsign != null and title != null and review != null, "rename editor controls are missing")
	if callsign == null or title == null or review == null:
		_dispose(screen)
		_finish()
		return

	_set_line_edit_text(callsign, "Aster Vale")
	_set_line_edit_text(title, "Night Watch")
	await process_frame
	_check(not review.disabled, "valid rename draft did not enable Review")
	review.pressed.emit()
	await process_frame
	_check(StringName(screen.call("mode")) == &"rename_confirmation", "Review did not enter rename_confirmation mode")
	_check(screen.find_child("RenameConfirmationDialog", true, false) == null, "native rename popup still exists")
	var snapshot := screen.call("pending_identity_snapshot") as Dictionary
	_check(String(snapshot.get("hero_id", "")) == hero_id, "pending snapshot lost hero identity")
	_check(String(snapshot.get("callsign", "")) == "Aster Vale", "pending snapshot lost callsign")
	_check(String(snapshot.get("title", "")) == "Night Watch", "pending snapshot lost title")
	var confirm := screen.find_child("RenameConfirm", true, false) as Button
	var cancel := screen.find_child("RenameCancel", true, false) as Button
	var comparison := screen.find_child("RenameIdentityComparison", true, false) as BoxContainer
	var dock := screen.find_child("TrainingActionDock", true, false) as VBoxContainer
	var persistent_header := screen.find_child("TrainingPersistentHeader", true, false) as VBoxContainer
	_check(confirm != null and cancel != null and comparison != null, "rename confirmation composition is incomplete")
	_check(dock != null and confirm != null and not _has_scroll_ancestor(confirm), "rename actions are not fixed in TrainingActionDock")
	_check(persistent_header != null and persistent_header.visible and not _has_scroll_ancestor(persistent_header), "rename header is not persistent")
	_check(confirm != null and confirm.custom_minimum_size.y >= 44.0, "rename Confirm hit target is under 44px")
	_check(cancel != null and cancel.custom_minimum_size.y >= 44.0, "rename Cancel hit target is under 44px")
	_check(comparison != null and not comparison.vertical, "regular landscape rename comparison did not use two readable columns")
	if confirm != null and cancel != null:
		_check(confirm.focus_next == confirm.get_path_to(cancel), "Confirm does not wrap forward to Cancel")
		_check(cancel.focus_previous == cancel.get_path_to(confirm), "Cancel does not wrap backward to Confirm")

	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	comparison = screen.find_child("RenameIdentityComparison", true, false) as BoxContainer
	var actions := screen.find_child("RenameConfirmationActions", true, false) as BoxContainer
	_check(comparison != null and comparison.vertical, "portrait rename comparison did not stack")
	_check(actions != null and actions.vertical, "portrait rename actions did not stack")
	_check(screen.call("pending_identity_snapshot") == snapshot, "resize changed the immutable pending snapshot")

	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	await process_frame
	await process_frame
	_check(StringName(screen.call("mode")) == &"rename_confirmation", "locale refresh exited rename confirmation")
	_check(screen.call("pending_identity_snapshot") == snapshot, "locale refresh changed pending snapshot")
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	_check(confirm != null and confirm.text == "确认", "mounted rename confirmation did not refresh Chinese copy")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
	await process_frame

	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	screen.call("_unhandled_input", cancel_event)
	await process_frame
	await process_frame
	_check(StringName(screen.call("mode")) == &"roster", "Cancel did not restore roster/editor mode")
	_check((screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "Cancel retained pending snapshot")
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_check(callsign != null and callsign.text == "Aster Vale", "Cancel lost callsign draft")
	_check(title != null and title.text == "Night Watch", "Cancel lost title draft")
	_check(callsign != null and callsign.has_focus(), "Cancel did not restore callsign focus")

	var roster_rows: Array = game.get("campaign").runtime_projection()["ready_heroes"]
	var duplicate := ""
	for row: Dictionary in roster_rows:
		if String(row["hero_id"]) != hero_id:
			duplicate = str(row["callsign"])
			break
	_check(not duplicate.is_empty(), "duplicate rename fixture is unavailable")
	_set_line_edit_text(callsign, duplicate)
	_set_line_edit_text(title, "Night Watch")
	await process_frame
	review = screen.find_child("RenameUnitAction", true, false) as Button
	if review != null:
		review.pressed.emit()
	await process_frame
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	await process_frame
	await process_frame
	_check(int(screen.call("rename_dispatch_count")) == 1, "rejection dispatched rename more than once")
	_check(StringName(screen.call("mode")) == &"roster", "rejection did not restore editor")
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	var error := screen.find_child("RenameUnitError", true, false) as Label
	_check(callsign != null and callsign.text == duplicate, "rejection lost callsign draft")
	_check(error != null and not error.text.is_empty(), "rejection did not expose authoritative error")
	_check(callsign != null and callsign.has_focus(), "rejection did not focus callsign")

	_set_line_edit_text(callsign, "Aster Vale")
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_set_line_edit_text(title, "Night Watch")
	await process_frame
	review = screen.find_child("RenameUnitAction", true, false) as Button
	if review != null:
		review.pressed.emit()
	await process_frame
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	await process_frame
	await process_frame
	_check(int(screen.call("rename_dispatch_count")) == 2, "success dispatch was not exactly one additional rename call")
	_check((screen.call("identity_edit_draft") as Dictionary).is_empty(), "success retained editor draft")
	_check((screen.call("pending_identity_snapshot") as Dictionary).is_empty(), "success retained pending snapshot")
	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_check(callsign != null and callsign.text == "Aster Vale", "success did not refresh the callsign editor")
	_check(title != null and title.text == "Night Watch", "success did not refresh the title editor")
	var committed := _hero(game.get("campaign").runtime_projection()["ready_heroes"], hero_id)
	_check(str(committed.get("callsign", "")) == "Aster Vale", "authoritative roster did not refresh committed callsign")
	_check(str(committed.get("custom_title", "")) == "Night Watch", "authoritative roster did not refresh committed title")

	callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
	title = screen.find_child("RenameTitleInput", true, false) as LineEdit
	_set_line_edit_text(title, "")
	await process_frame
	review = screen.find_child("RenameUnitAction", true, false) as Button
	_check(review != null and not review.disabled, "clearing an optional title did not enable Review")
	if review != null:
		review.pressed.emit()
	await process_frame
	var clear_title_snapshot := screen.call("pending_identity_snapshot") as Dictionary
	_check(clear_title_snapshot.has("title") and clear_title_snapshot["title"] == null, "blank title was not snapshotted as null")
	confirm = screen.find_child("RenameConfirm", true, false) as Button
	if confirm != null:
		confirm.pressed.emit()
	await process_frame
	await process_frame
	_check(int(screen.call("rename_dispatch_count")) == 3, "title clearing did not issue exactly one rename call")
	committed = _hero(game.get("campaign").runtime_projection()["ready_heroes"], hero_id)
	_check(committed.has("custom_title") and committed["custom_title"] == null, "authoritative roster stored a blank title instead of null")

	_dispose(screen)
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	root.size = Vector2i(1280, 720)
	await create_timer(0.15).timeout
	_finish()


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
