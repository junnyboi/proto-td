extends SceneTree

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const ENTRY_WAIT := 0.24
const EXIT_WAIT := 0.19
const TIMEOUT := 35.0

var _failures: Array[String] = []
var _timed_out := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(TIMEOUT).timeout.connect(_on_timeout, CONNECT_ONE_SHOT)
	var game: Node = root.get_node_or_null("Game")
	var music: Node = root.get_node_or_null("Music")
	_check(game != null and music != null, "required autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 99)
	_check(bool(game.call("start_campaign", false, true)), "campaign fixture failed")
	var screen: Node = load("res://scenes/gacha.tscn").instantiate()
	root.add_child(screen)
	await _frames(2)
	var grid := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
	var pull := screen.find_child("PremiumPullButton", true, false) as Button
	var back := screen.find_child("BackButton", true, false) as Button
	var marks := screen.find_child("MarksLabel", true, false) as Label
	var pity := screen.find_child("PityLabel", true, false) as Label
	_check(grid != null and grid.get_child_count() == 3, "premium pool did not render")
	_check(marks.text == "120 MARKS" and pity.text.contains("10 PULLS"), "initial economy projection changed")
	_check(not pull.disabled and not back.disabled, "browse actions unavailable")
	for premium_id: String in ["archive_caster", "lunaris_vessel", "reliquary_duelist"]:
		var card := grid.get_node_or_null("Premium_%s" % premium_id)
		_check(card != null and card.find_child("Portrait", true, false).texture != null, "missing portrait %s" % premium_id)
		_check(Art.size(StringName("portrait_%s_fullsize" % premium_id)) == Vector2i(640, 800), "full-size portrait changed for %s" % premium_id)

	var before: Dictionary = game.get("campaign").runtime_projection()
	root.size = Vector2i(360, 800)
	await _frames(1)
	pull.grab_focus()
	pull.pressed.emit()
	await _frames(1)
	var layer := screen.find_child("PremiumPullConfirmationLayer", true, false) as Control
	var frame := screen.find_child("ConfirmationCommandFrame", true, false) as PanelContainer
	var header := screen.find_child("ConfirmationHeader", true, false) as GridContainer
	var title := screen.find_child("ConfirmationTitle", true, false) as Label
	var body_scroll := screen.find_child("ConfirmationBodyScroll", true, false) as ScrollContainer
	var body := screen.find_child("ConfirmationBodyGrid", true, false) as GridContainer
	var context := screen.find_child("ConfirmationContextCopy", true, false) as Label
	var review := screen.find_child("ConfirmationTransactionCopy", true, false) as Label
	var dock := screen.find_child("ConfirmationActionDock", true, false) as PanelContainer
	var actions := screen.find_child("ConfirmationActions", true, false) as GridContainer
	var header_cancel := screen.find_child("CancelPremiumPull", true, false) as Button
	var dock_cancel := screen.find_child("CancelPremiumPullDock", true, false) as Button
	var confirm := screen.find_child("ConfirmPremiumPull", true, false) as Button
	var modal_status := screen.find_child("ConfirmationStatusLabel", true, false) as Label
	_check(layer.visible and screen.call("flow_state_name") == &"CONFIRM", "confirmation did not open")
	_check(screen.call("transition_state_name") == &"ENTERING" and screen.call("transition_active"), "normal entry state missing")
	_check(root.gui_get_focus_owner() == null and not pull.has_focus(), "entry assigned or retained focus early")
	_check(layer.modulate.a < 1.0 and frame.offset_transform_position.y > 0.0, "entry animation did not begin from offset/opacity")
	_check(game.get("campaign").runtime_projection() == before, "opening eagerly mutated domain")
	_check(screen.call("confirmation_projection_snapshot") == before, "confirmation snapshot changed")
	await _seconds(ENTRY_WAIT)
	_check(screen.call("transition_state_name") == &"OPEN" and not screen.call("transition_active"), "normal entry did not settle OPEN")
	_check(root.gui_get_focus_owner() == dock_cancel, "entry finalizer did not focus visible Cancel")
	_check(is_equal_approx(layer.modulate.a, 1.0) and frame.offset_transform_position.is_zero_approx(), "entry visuals did not settle")
	_check(layer.get_global_rect().size.is_equal_approx(Vector2(360, 800)), "confirmation is not full-screen")
	_check(layer.mouse_filter == Control.MOUSE_FILTER_STOP and not grid.is_visible_in_tree(), "modal did not suppress browse")
	_check(body.columns == 1 and actions.columns == 1, "narrow confirmation did not stack")
	_check(body_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and body_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "body scroll contract changed")
	_check(title.autowrap_mode != TextServer.AUTOWRAP_OFF, "title does not wrap")
	_check(title.get_theme_font_size(&"font_size") == 44, "narrow confirmation title lost readable scale")
	_check(context.get_theme_font_size(&"font_size") == 36 and review.get_theme_font_size(&"font_size") == 36, "confirmation body typography is not doubled")
	_check(confirm.get_theme_font_size(&"font_size") == 36 and dock_cancel.get_theme_font_size(&"font_size") == 36, "confirmation action typography is not doubled")
	_check(not header_cancel.visible and header_cancel.focus_mode == Control.FOCUS_NONE, "hidden header Cancel remained interactive")
	for button: Button in [header_cancel, dock_cancel, confirm]:
		_check(button.custom_minimum_size.y >= 44.0, "%s target is below 44 px" % button.name)
		_check(button.autowrap_mode != TextServer.AUTOWRAP_OFF and not button.clip_text, "%s clips instead of wrapping" % button.name)
	_check(dock_cancel.focus_next == dock_cancel.get_path_to(confirm), "dock Tab order changed")
	_check(confirm.focus_next == confirm.get_path_to(dock_cancel), "Confirm Tab wrap changed")
	_check(dock_cancel.focus_neighbor_bottom == dock_cancel.get_path_to(confirm), "stacked dock Down changed")
	_check(confirm.focus_neighbor_bottom == confirm.get_path_to(dock_cancel), "stacked boundary wrap changed")
	_check(dock_cancel.focus_neighbor_right == dock_cancel.get_path_to(dock_cancel), "stacked Right escaped")

	_check(layer.accessibility_description.contains("40") and layer.accessibility_description.contains("120") and layer.accessibility_description.contains("10"), "root metadata lacks cost/balance/guarantee")
	_check(not layer.accessibility_name.is_empty() and not layer.accessibility_labeled_by_nodes.is_empty() and not layer.accessibility_described_by_nodes.is_empty(), "root metadata relationships missing")
	_check(not frame.accessibility_name.is_empty() and not frame.accessibility_described_by_nodes.is_empty(), "frame relationships missing")
	_check(not title.accessibility_description.is_empty() and not title.accessibility_controls_nodes.is_empty(), "title relationships missing")
	_check(not body.accessibility_name.is_empty() and not dock.accessibility_name.is_empty(), "body/action accessible names missing")
	_check(header_cancel.accessibility_name != dock_cancel.accessibility_name, "Cancel accessible names are not distinct")
	_check(confirm.accessibility_description.contains("40") and confirm.accessibility_description.contains("120"), "Confirm description lacks transaction facts")
	_check(modal_status.accessibility_live == AccessibilityServer.LIVE_POLITE, "pending live region is not polite")

	var i18n := root.get_node_or_null("I18n")
	if i18n != null:
		dock_cancel.grab_focus()
		_check(bool(i18n.call("set_locale", &"zh-CN")), "locale switch failed")
		await _frames(2)
		_check(root.gui_get_focus_owner() == dock_cancel and screen.call("transition_state_name") == &"OPEN", "locale refresh lost logical focus/state")
		_check(title.text != "CONFIRM RESONANCE" and screen.call("confirmation_projection_snapshot") == before, "locale refresh lost copy/snapshot")
		_check(bool(i18n.call("set_locale", &"en-US")), "locale restore failed")
		await _frames(2)

	await _action(&"ui_cancel")
	_check(screen.call("flow_state_name") == &"CONFIRM" and screen.call("transition_state_name") == &"EXITING", "actual ui_cancel did not begin EXITING")
	_check(layer.visible and root.gui_get_focus_owner() == dock_cancel, "EXITING hid modal or lost dialog focus")
	_check(screen.call("confirmation_projection_snapshot") == before, "EXITING cleared snapshot early")
	await _seconds(EXIT_WAIT)
	_check(not layer.visible and screen.call("flow_state_name") == &"BROWSE" and screen.call("transition_state_name") == &"NONE", "normal exit did not settle BROWSE/NONE")
	_check(game.get("campaign").runtime_projection() == before and root.gui_get_focus_owner() == pull, "normal cancel changed domain/focus")

	# Cancel during entry reverses current opacity/offset instead of flashing.
	pull.pressed.emit()
	await _frames(1)
	var alpha_before_reverse := layer.modulate.a
	await _action(&"ui_cancel")
	_check(screen.call("transition_state_name") == &"EXITING", "entry cancel did not reverse to EXITING")
	_check(layer.modulate.a <= alpha_before_reverse + 0.08, "entry reversal flashed to fully opaque")
	await _seconds(EXIT_WAIT)
	_check(screen.call("flow_state_name") == &"BROWSE" and root.gui_get_focus_owner() == pull, "entry reversal did not finalize")

	root.size = Vector2i(720, 1280)
	screen.set("reduced_motion", true)
	await _frames(1)
	pull.pressed.emit()
	_check(screen.call("transition_state_name") == &"OPEN" and not screen.call("transition_active"), "reduced entry finalizer was not immediate")
	await _frames(1)
	_check(root.gui_get_focus_owner() == dock_cancel and frame.offset_transform_position.is_zero_approx(), "reduced entry focus/visuals did not settle")
	await _action(&"ui_cancel")
	_check(screen.call("flow_state_name") == &"BROWSE" and screen.call("transition_state_name") == &"NONE" and not layer.visible, "reduced exit finalizer was not immediate")
	await _frames(1)
	_check(root.gui_get_focus_owner() == pull, "reduced exit did not restore opener")
	screen.set("reduced_motion", false)

	root.size = Vector2i(1280, 720)
	await _frames(1)
	pull.pressed.emit()
	await _wait_for_transition_open(screen)
	_check(body.columns == 2 and actions.columns == 2, "wide confirmation did not use two columns")
	_check(dock_cancel.focus_neighbor_left == dock_cancel.get_path_to(confirm) and dock_cancel.focus_neighbor_right == dock_cancel.get_path_to(confirm), "wide dock Cancel does not swap")
	_check(confirm.focus_neighbor_left == confirm.get_path_to(dock_cancel) and confirm.focus_neighbor_right == confirm.get_path_to(dock_cancel), "wide Confirm does not swap")
	_check(dock_cancel.focus_neighbor_top == dock_cancel.get_path_to(dock_cancel) and confirm.focus_neighbor_top == confirm.get_path_to(confirm), "wide Up should retain the action")
	_check(dock_cancel.focus_neighbor_bottom == dock_cancel.get_path_to(dock_cancel) and confirm.focus_neighbor_bottom == confirm.get_path_to(confirm), "wide Down should retain the action")
	confirm.grab_focus()
	root.size = Vector2i(960, 420)
	await _frames(2)
	_check(actions.columns == 2 and root.gui_get_focus_owner() == confirm, "resize changed layout/logical focus")
	root.size = Vector2i(1280, 720)
	await _frames(2)

	# Authoritative rejection: deferred dispatch, one lock, assertive exact error, animated close.
	var durable_store: Variant = game.get("campaign_store")
	game.set("campaign_store", null)
	await _action(&"ui_accept")
	_check(screen.call("flow_state_name") == &"COMMITTING", "actual ui_accept did not enter COMMITTING")
	_check(header_cancel.disabled and dock_cancel.disabled and confirm.disabled, "COMMITTING did not lock actions")
	_check(confirm.text == "ALIGNING…" and modal_status.visible and modal_status.text == "Aligning the reliquary signal…", "pending copy/status changed")
	_check(modal_status.accessibility_live == AccessibilityServer.LIVE_POLITE and game.get("campaign").runtime_projection() == before, "pending was not polite or mutated eagerly")
	await _action(&"ui_accept")
	await _action(&"ui_cancel")
	await _frames(1)
	_check(screen.call("flow_state_name") == &"COMMITTING" and screen.call("transition_state_name") == &"EXITING", "rejection did not animate closed")
	_check(layer.visible and modal_status.text == "No active campaign is available.", "exact rejection was not visible during EXITING")
	_check(modal_status.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "rejection live status is not assertive")
	_check(game.get("campaign").runtime_projection() == before, "rejection changed economy/pity")
	await _seconds(EXIT_WAIT)
	var browse_status := screen.find_child("PullStatusLabel", true, false) as Label
	var reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(screen.call("flow_state_name") == &"BROWSE" and not layer.visible and not reveal.visible, "rejection did not settle without reveal")
	_check(browse_status.text == "No active campaign is available." and browse_status.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "browse rejection status changed")
	_check(root.gui_get_focus_owner() == pull, "rejection did not restore opener")
	game.set("campaign_store", durable_store)

	# Accepted path: observable lock, exactly one authoritative dispatch, immediate reveal handoff.
	pull.pressed.emit()
	await _wait_for_transition_open(screen)
	confirm.grab_focus()
	var data_before: Dictionary = game.get("campaign").data_copy()
	var receipt_count := int((data_before["command_receipts"] as Array).size())
	var projection_before: Dictionary = game.get("campaign").runtime_projection()
	await _action(&"ui_accept")
	_check(screen.call("flow_state_name") == &"COMMITTING" and game.get("campaign").runtime_projection() == projection_before, "accept lock was not observable before dispatch")
	await _action(&"ui_accept")
	await _action(&"ui_cancel")
	await _frames(1)
	var data_after: Dictionary = game.get("campaign").data_copy()
	var projection_after: Dictionary = game.get("campaign").runtime_projection()
	_check(data_after["command_receipts"].size() == receipt_count + 1, "confirmation did not dispatch exactly once")
	_check(int(projection_after["marks"]) == int(projection_before["marks"]) - 40, "accepted pull charged wrong amount")
	_check(int(projection_after["next_premium_pull_index"]) == int(projection_before["next_premium_pull_index"]) + 1, "accepted pull index changed more than once")
	_check(screen.call("flow_state_name") == &"REVEAL" and screen.call("transition_state_name") == &"NONE" and not screen.call("transition_active"), "accepted receipt did not hand off coherently")
	_check(reveal.visible and not layer.visible, "accepted handoff delayed or retained confirmation")
	var receipt: Dictionary = {}
	if data_after["command_receipts"].size() > receipt_count:
		var command_receipt: Dictionary = data_after["command_receipts"][-1]
		var receipt_payload: Dictionary = command_receipt.get("receipt", {})
		receipt = receipt_payload.get("premium_pull", {})
	_check(not receipt.is_empty(), "accepted dispatch did not persist a premium pull receipt")
	if not receipt.is_empty():
		_check(screen.get("_pending_pull") == receipt, "authoritative receipt changed before reveal")
	screen.call("_finish_reveal")
	await _frames(2)
	_check(screen.call("flow_state_name") == &"BROWSE" and root.gui_get_focus_owner() == pull, "receipt reveal did not restore exact opener")

	# Preserve upstream cinematic, full-size identity, click skip, music, and reduced-motion lifecycle.
	var five_star := _sample_pull(5, true)
	screen.call("_begin_reveal", five_star)
	await _frames(1)
	var reveal_title := screen.find_child("RevealTitle", true, false) as Label
	var reveal_stack := screen.find_child("CinematicIdentityReveal", true, false) as VBoxContainer
	var stars := screen.find_child("RarityStars", true, false) as HBoxContainer
	var reveal_hint := screen.find_child("RevealContinueHint", true, false) as Label
	var skip := screen.find_child("SkipRevealButton", true, false) as Button
	var cinematic := screen.find_child("GachaCinematicPlayer", true, false) as Control
	var video := screen.find_child("CinematicVideo", true, false) as VideoStreamPlayer
	var plate := screen.find_child("CinematicFinalPlate", true, false) as TextureRect
	_check(reveal.visible and pull.disabled and back.disabled, "five-star reveal did not lock browse")
	_check(reveal_title.text == "LUNARIS VESSEL" and not reveal_stack.visible, "identity appeared before cinematic completion")
	_check(stars.get_child_count() == 5 and video.stream != null and video.is_playing(), "five-star cinematic resources did not start")
	_check(reveal_title.get_theme_font_size(&"font_size") == 104, "landscape reveal title typography is not doubled")
	_check(reveal_hint != null and reveal_hint.get_theme_font_size(&"font_size") == 28, "reveal continuation typography is not doubled")
	_check(skip != null and skip.get_theme_font_size(&"font_size") == 36, "Skip Reveal typography is not doubled")
	_check(skip.custom_minimum_size.x >= 340.0 and skip.custom_minimum_size.y >= 92.0, "Skip Reveal container is not wide or tall enough")
	var skip_style := skip.get_theme_stylebox(&"normal")
	_check(skip_style.content_margin_left >= 42.0 and skip_style.content_margin_right >= 42.0, "Skip Reveal container lacks horizontal padding")
	_check(not skip.clip_text and skip.autowrap_mode != TextServer.AUTOWRAP_OFF, "Skip Reveal can still overflow or clip")
	_check(plate.texture != null and StringName(music.call("current_id")) == &"gacha_lunaris_vessel", "final plate/music changed")
	cinematic.call("_on_video_finished")
	await _frames(1)
	_check(reveal_stack.visible, "cinematic completion did not reveal identity")
	await _seconds(4.0)
	for index: int in 5:
		var star := stars.get_child(index) as ResonanceStar
		_check(star.visible and star.modulate.a > 0.99 and absf(star.rotation) < 0.01, "five-star item %d did not settle" % (index + 1))
		_check(bool(star.call("uses_generated_art")), "five-star item %d is not using GPT Image 2 art" % (index + 1))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen.call("_on_reveal_gui_input", click)
	await _frames(1)
	_check(not reveal.visible and video.stream == null and not pull.disabled and not back.disabled, "click skip did not finalize/release")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "click skip did not restore music")

	screen.set("reduced_motion", true)
	screen.call("_begin_reveal", _sample_pull(4, false))
	await _frames(1)
	_check(reveal.visible and reveal_stack.visible and reveal_title.text == "ARCHIVE CASTER", "reduced reveal did not settle identity")
	_check(reveal_title.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Archive Caster title is not gold")
	_check(plate.visible and plate.texture != null and video.stream == null, "reduced reveal loaded video instead of final plate")
	for index: int in 5:
		var star := stars.get_child(index) as ResonanceStar
		_check(star.visible == (index < 4), "reduced reveal star count changed")
		if index < 4:
			var star_accent: Color = star.get("_accent")
			_check(star_accent.is_equal_approx(Style.GOLD), "Archive Caster star %d is not gold" % (index + 1))
			_check(bool(star.call("uses_generated_art")), "Archive Caster star %d is not using generated art" % (index + 1))
	await _action(&"ui_cancel")
	_check(not reveal.visible and screen.call("flow_state_name") == &"BROWSE", "reduced reveal cancel did not finalize")

	pull.disabled = true
	back.disabled = false
	screen.call("_restore_pull_focus")
	await _frames(1)
	_check(root.gui_get_focus_owner() == back, "disabled Pull did not use Back fallback")
	var navigation_projection: Dictionary = game.get("campaign").runtime_projection()
	await _action(&"ui_cancel")
	await _frames(4)
	var content := game.get("content") as Node
	_check(content != null and content.get_script().resource_path == "res://scripts/ui/staging.gd", "idle ui_cancel did not navigate")
	_check(game.get("campaign").runtime_projection() == navigation_projection, "idle ui_cancel changed campaign")
	game.set("content", null)
	if content != null and is_instance_valid(content):
		var parent := content.get_parent()
		if parent != null:
			parent.remove_child(content)
		content.free()
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	await _seconds(0.25)
	_finish()


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func _wait_for_transition_open(screen: Node) -> void:
	for _frame: int in range(30):
		if screen.call("transition_state_name") == &"OPEN":
			return
		await process_frame


func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _sample_pull(rarity: int, forced: bool) -> Dictionary:
	return {
		"premium_id": "lunaris_vessel" if rarity == 5 else "archive_caster",
		"hero_id": "0123456789abcdef",
		"pull_index": 9 if forced else 0,
		"new_hero": true,
		"revived": false,
		"lives_before": 0,
		"lives_after": 1,
		"pull_count_after": 1,
		"marks_before": 120,
		"marks_after": 80,
		"rarity": rarity,
		"five_star": rarity == 5,
		"pity_eligible": true,
		"pity_before": 9 if forced else 0,
		"pity_after": 0 if rarity == 5 else 1,
		"pity_forced": forced,
		"guarantee_in_after": 10 if rarity == 5 else 9,
		"save_revision": 2,
	}


func _on_timeout() -> void:
	if _timed_out:
		return
	_timed_out = true
	push_error("premium Gacha UI test timed out")
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _timed_out:
		return
	if _failures.is_empty():
		print("PREMIUM_GACHA_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
