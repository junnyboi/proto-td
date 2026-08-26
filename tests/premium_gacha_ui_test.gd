extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node_or_null("Game")
	var music: Node = root.get_node_or_null("Music")
	_check(game != null, "Game autoload missing")
	_check(music != null, "Music autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 99)
	_check(bool(game.call("start_campaign", false, true)), "durable campaign fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	var screen: Node = load("res://scenes/gacha.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var grid := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
	var marks := screen.find_child("MarksLabel", true, false) as Label
	var pull := screen.find_child("PremiumPullButton", true, false) as Button
	var back := screen.find_child("BackButton", true, false) as Button
	var pity_label := screen.find_child("PityLabel", true, false) as Label
	var pity_segments := screen.find_child("PitySegments", true, false) as HBoxContainer
	_check(grid != null, "premium hero grid missing")
	_check(marks != null and marks.text == "120 MARKS", "Marks projection is incorrect")
	_check(pull != null and not pull.disabled, "pull action should be available at 120 Marks")
	_check(back != null and not back.disabled, "back action should initially be available")
	_check(pity_label != null and pity_label.text.contains("10 PULLS"), "fresh pity copy is incorrect")
	_check(pity_segments != null and pity_segments.get_child_count() == 10, "pity meter is not ten segments")
	if grid != null:
		_check(grid.get_child_count() == 3, "premium pool did not render three cards")
		var featured := grid.get_node_or_null("Premium_lunaris_vessel") as PanelContainer
		var side_card := grid.get_node_or_null("Premium_archive_caster") as PanelContainer
		_check(featured != null and side_card != null and featured.custom_minimum_size.x > side_card.custom_minimum_size.x, "premium featured identity is not visually dominant")
		for premium_id: String in ["archive_caster", "lunaris_vessel", "reliquary_duelist"]:
			var card := grid.get_node_or_null("Premium_%s" % premium_id)
			_check(card != null, "missing premium card %s" % premium_id)
			if card != null:
				var portrait := card.find_child("Portrait", true, false) as TextureRect
				_check(portrait != null and portrait.texture != null, "missing portrait %s" % premium_id)

	var before_cancel: Dictionary = game.get("campaign").runtime_projection()
	root.size = Vector2i(360, 800)
	await process_frame
	pull.pressed.emit()
	await process_frame
	await process_frame
	var confirmation := screen.find_child("PremiumPullConfirmationLayer", true, false) as Control
	var confirm_frame := screen.find_child("ConfirmationCommandFrame", true, false) as PanelContainer
	var confirm_header := screen.find_child("ConfirmationHeader", true, false) as GridContainer
	var confirm_title := screen.find_child("ConfirmationTitle", true, false) as Label
	var confirm_body_scroll := screen.find_child("ConfirmationBodyScroll", true, false) as ScrollContainer
	var confirm_body := screen.find_child("ConfirmationBodyGrid", true, false) as GridContainer
	var confirm_dock := screen.find_child("ConfirmationActionDock", true, false) as PanelContainer
	var confirm_actions := screen.find_child("ConfirmationActions", true, false) as GridContainer
	var confirm_pull := screen.find_child("ConfirmPremiumPull", true, false) as Button
	var header_cancel := screen.find_child("CancelPremiumPull", true, false) as Button
	var dock_cancel := screen.find_child("CancelPremiumPullDock", true, false) as Button
	_check(confirmation != null and confirmation.visible, "full-screen pull confirmation did not open")
	_check(screen.call("flow_state_name") == &"CONFIRM", "opening did not enter CONFIRM")
	_check(confirm_frame != null and confirm_header != null and confirm_dock != null, "confirmation frame regions are missing")
	_check(confirm_body_scroll != null and confirm_body != null and confirm_actions != null, "confirmation body/action layout is missing")
	_check(confirm_pull != null and header_cancel != null and dock_cancel != null, "confirmation focus actions are missing")
	if confirmation != null:
		var root_rect := confirmation.get_global_rect()
		_check(root_rect.position.is_equal_approx(Vector2.ZERO), "confirmation root is not viewport-aligned")
		_check(root_rect.size.is_equal_approx(Vector2(360, 800)), "confirmation root is not full viewport")
		_check(confirmation.mouse_filter == Control.MOUSE_FILTER_STOP, "confirmation root does not stop pointer input")
	if confirm_frame != null:
		var frame_rect := confirm_frame.get_global_rect()
		_check(frame_rect.position.x >= 0.0 and frame_rect.end.x <= 360.0, "narrow confirmation frame overflows horizontally")
		_check(frame_rect.position.y >= 0.0 and frame_rect.end.y <= 800.0, "narrow confirmation frame overflows vertically")
	_check(not screen.find_child("PremiumHeroGrid", true, false).is_visible_in_tree(), "browse tree remained visible under confirmation")
	_check(confirm_body.columns == 1, "narrow confirmation body did not collapse to one column")
	_check(confirm_actions.columns == 1, "narrow confirmation actions do not stack")
	_check(header_cancel.custom_minimum_size.y >= 44.0, "header Cancel is below minimum hit height")
	_check(dock_cancel.custom_minimum_size.y >= 44.0 and confirm_pull.custom_minimum_size.y >= 44.0, "dock actions are below minimum hit height")
	_check(confirm_body_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "confirmation body permits horizontal scrolling")
	_check(confirm_body_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "confirmation body is not the flexible region")
	_check(confirm_title.autowrap_mode != TextServer.AUTOWRAP_OFF, "confirmation title does not wrap")
	_check(game.get("campaign").runtime_projection() == before_cancel, "opening confirmation mutated campaign state")
	_check(screen.call("confirmation_projection_snapshot") == before_cancel, "confirmation did not snapshot runtime projection")
	_check(root.gui_get_focus_owner() == header_cancel, "safe entry focus is not header Cancel")
	if header_cancel != null and dock_cancel != null and confirm_pull != null:
		_check(header_cancel.focus_next == header_cancel.get_path_to(dock_cancel), "header Cancel focus escapes scope")
		_check(dock_cancel.focus_next == dock_cancel.get_path_to(confirm_pull), "dock Cancel focus order is incorrect")
		_check(confirm_pull.focus_next == confirm_pull.get_path_to(header_cancel), "Confirm does not wrap focus to header Cancel")

	var i18n := root.get_node_or_null("I18n")
	if i18n != null:
		dock_cancel.grab_focus()
		_check(bool(i18n.call("set_locale", &"zh-CN")), "mounted confirmation locale switch failed")
		await process_frame
		await process_frame
		_check(screen.call("flow_state_name") == &"CONFIRM", "locale refresh changed confirmation state")
		_check(screen.call("confirmation_projection_snapshot") == before_cancel, "locale refresh changed snapshot")
		_check(root.gui_get_focus_owner() == dock_cancel, "locale refresh lost logical focus")
		_check(confirm_title.text != "CONFIRM RESONANCE", "mounted confirmation copy did not localize")
		_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
		await process_frame
		await process_frame

	header_cancel.pressed.emit()
	await process_frame
	await process_frame
	_check(not confirmation.visible, "Cancel did not close pull confirmation")
	_check(screen.call("flow_state_name") == &"BROWSE", "Cancel did not return to BROWSE")
	_check(game.get("campaign").runtime_projection() == before_cancel, "Cancel mutated campaign state")
	_check(root.gui_get_focus_owner() == pull, "Cancel did not restore PremiumPullButton focus")

	root.size = Vector2i(720, 1280)
	await process_frame
	pull.pressed.emit()
	await process_frame
	await process_frame
	_check(confirmation.get_global_rect().size.is_equal_approx(Vector2(720, 1280)), "portrait confirmation root is not full viewport")
	_check(confirm_frame.get_global_rect().end.y <= 1280.0, "portrait confirmation frame overflows vertically")
	_check(confirm_body.columns == 1, "portrait confirmation body did not collapse to one column")
	_check(confirm_actions.columns == 1, "portrait confirmation actions do not stack")
	_check(confirm_header.get_global_rect().end.y <= confirm_body_scroll.get_global_rect().position.y + 2.0, "portrait header overlaps scroll body")
	_check(confirm_body_scroll.get_global_rect().end.y <= confirm_dock.get_global_rect().position.y + 2.0, "portrait body overlaps persistent dock")
	header_cancel.pressed.emit()
	await process_frame
	await process_frame

	root.size = Vector2i(1280, 720)
	await process_frame
	pull.pressed.emit()
	await process_frame
	await process_frame
	var durable_store: Variant = game.get("campaign_store")
	game.set("campaign_store", null)
	confirm_pull.pressed.emit()
	_check(screen.call("flow_state_name") == &"COMMITTING", "rejection seam did not enter COMMITTING")
	await process_frame
	await process_frame
	_check(screen.call("flow_state_name") == &"BROWSE", "authoritative rejection did not return to BROWSE")
	_check(not confirmation.visible, "authoritative rejection left confirmation visible")
	var rejection_reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(rejection_reveal != null and not rejection_reveal.visible, "authoritative rejection opened a false reveal")
	_check(game.get("campaign").runtime_projection() == before_cancel, "authoritative rejection mutated economy or pity")
	var rejection_status := screen.find_child("PullStatusLabel", true, false) as Label
	_check(rejection_status != null and rejection_status.text == "No active campaign is available.", "authoritative rejection did not expose exact error copy")
	_check(root.gui_get_focus_owner() == pull, "authoritative rejection did not focus PremiumPullButton")
	game.set("campaign_store", durable_store)
	pull.pressed.emit()
	await process_frame
	await process_frame
	_check(confirm_body.columns == 2, "wide confirmation body is not two-column")
	_check(confirm_actions.columns == 2, "wide confirmation actions are not horizontal")
	_check(screen.call("confirmation_projection_snapshot") == before_cancel, "wide reopen changed snapshot")
	confirm_pull.grab_focus()
	root.size = Vector2i(960, 420)
	await process_frame
	await process_frame
	_check(confirm_actions.columns == 2, "short regular-width actions should remain horizontal")
	_check(confirm_header.get_global_rect().end.y <= confirm_body_scroll.get_global_rect().position.y + 2.0, "short header overlaps scroll body")
	_check(confirm_body_scroll.get_global_rect().end.y <= confirm_dock.get_global_rect().position.y + 2.0, "short body overlaps persistent dock")
	_check(confirm_dock.get_global_rect().end.y <= confirm_frame.get_global_rect().end.y + 1.0, "short action dock is outside frame")
	_check(root.gui_get_focus_owner() == confirm_pull, "live resize lost logical focus")
	root.size = Vector2i(1280, 720)
	await process_frame

	confirm_pull.pressed.emit()
	_check(screen.call("flow_state_name") == &"COMMITTING", "Confirm did not atomically enter COMMITTING")
	_check(header_cancel.disabled and dock_cancel.disabled and confirm_pull.disabled, "COMMITTING did not lock every confirmation action")
	_check(confirm_pull.text == "ALIGNING…", "COMMITTING pending label is incorrect")
	_check(game.get("campaign").runtime_projection() == before_cancel, "commit dispatched before atomic lock was observable")
	confirm_pull.pressed.emit()
	header_cancel.pressed.emit()
	dock_cancel.pressed.emit()
	screen.call("_on_back_pressed")
	_check(screen.call("flow_state_name") == &"COMMITTING", "repeat accept/cancel escaped COMMITTING")
	await process_frame
	var after_confirm: Dictionary = game.get("campaign").runtime_projection()
	_check(int(after_confirm["marks"]) == int(before_cancel["marks"]) - 40, "Confirm did not charge exactly one authoritative pull cost")
	_check(int(after_confirm["next_premium_pull_index"]) == int(before_cancel["next_premium_pull_index"]) + 1, "repeat Confirm dispatched more than one pull")
	_check(screen.call("flow_state_name") == &"REVEAL", "accepted commit did not enter REVEAL")
	var committed_reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(committed_reveal != null and committed_reveal.visible, "accepted Confirm did not begin receipt reveal")
	var receipt: Dictionary = game.get("campaign").data_copy()["command_receipts"][-1]["receipt"]["premium_pull"]
	_check(screen.get("_pending_pull") == receipt, "authoritative premium_pull receipt changed before reveal")
	screen.call("_finish_reveal")
	await process_frame
	await process_frame
	_check(screen.call("flow_state_name") == &"BROWSE", "finished receipt reveal did not return to BROWSE")
	_check(root.gui_get_focus_owner() == pull, "finished receipt reveal did not restore Pull focus")

	var five_star := _sample_pull(5, true)
	screen.call("_begin_reveal", five_star)
	await process_frame
	var reveal_layer := screen.find_child("PullRevealLayer", true, false) as Control
	var reveal_title := screen.find_child("RevealTitle", true, false) as Label
	var reveal_result := screen.find_child("RevealResult", true, false) as Label
	var skip := screen.find_child("SkipRevealButton", true, false) as Button
	var cinematic := screen.find_child("GachaCinematicPlayer", true, false) as Control
	var cinematic_video := screen.find_child("CinematicVideo", true, false) as VideoStreamPlayer
	var final_plate := screen.find_child("CinematicFinalPlate", true, false) as TextureRect
	_check(reveal_layer != null and reveal_layer.visible, "five-star reveal layer did not open")
	_check(pull.disabled and back.disabled, "reveal did not lock pull and back actions")
	_check(reveal_title != null and reveal_title.text == "5-STAR RESONANCE", "five-star title is incorrect")
	_check(reveal_result != null and reveal_result.text.contains("NEW HERO"), "reveal result kind is missing")
	_check(skip != null and skip.visible and not skip.disabled, "skip action is unavailable")
	_check(cinematic != null, "cinematic player is missing")
	_check(cinematic_video != null and cinematic_video.stream != null, "five-star cinematic stream did not load")
	_check(cinematic_video != null and cinematic_video.is_playing(), "five-star cinematic did not start")
	_check(final_plate != null and final_plate.texture != null, "five-star final identity plate did not load")
	_check(StringName(music.call("current_id")) == &"gacha_lunaris_vessel", "five-star cinematic mix did not start")
	screen.call("_finish_reveal")
	await process_frame
	_check(not reveal_layer.visible, "skipped reveal layer remained visible")
	_check(not pull.disabled and not back.disabled, "skip did not restore navigation input")
	_check(cinematic_video != null and cinematic_video.stream == null, "skip did not release the video stream")
	_check(
		StringName(music.call("current_id")) == &"lunaris_staging_archive_command",
		"skip did not resume Company Command audio",
	)
	var status := screen.find_child("PullStatusLabel", true, false) as Label
	_check(status != null and status.text.contains("5-STAR SIGNAL"), "skip did not apply final result copy")

	screen.set("reduced_motion", true)
	var four_star := _sample_pull(4, false)
	screen.call("_begin_reveal", four_star)
	await process_frame
	var portrait := screen.find_child("RevealPortrait", true, false) as TextureRect
	_check(reveal_layer.visible, "reduced-motion reveal did not open")
	_check(screen.call("flow_state_name") == &"REVEAL", "reduced-motion reveal did not enter REVEAL")
	_check(portrait != null and is_equal_approx(portrait.modulate.a, 1.0), "reduced motion did not settle instantly")
	_check(final_plate != null and final_plate.visible and final_plate.texture != null, "reduced motion did not show the final identity plate")
	_check(cinematic_video != null and cinematic_video.stream == null, "reduced motion loaded a video stream")
	_check(
		StringName(music.call("current_id")) == &"lunaris_staging_archive_command",
		"reduced motion replaced Company Command audio",
	)
	var reveal_cancel := InputEventAction.new()
	reveal_cancel.action = &"ui_cancel"
	reveal_cancel.pressed = true
	screen.call("_unhandled_input", reveal_cancel)
	await process_frame
	_check(not reveal_layer.visible, "reduced-motion reveal cancel did not finalize")
	_check(screen.call("flow_state_name") == &"BROWSE", "reduced-motion reveal cancel did not return to BROWSE")

	pull.disabled = true
	back.disabled = false
	screen.call("_restore_pull_focus")
	await process_frame
	_check(root.gui_get_focus_owner() == back, "disabled Pull did not fall back to Back focus")

	var navigation_projection: Dictionary = game.get("campaign").runtime_projection()
	var idle_cancel := InputEventAction.new()
	idle_cancel.action = &"ui_cancel"
	idle_cancel.pressed = true
	screen.call("_unhandled_input", idle_cancel)
	for _frame: int in range(4):
		await process_frame
	var content := game.get("content") as Node
	_check(content != null and content.get_script().resource_path == "res://scripts/ui/staging.gd", "idle ui_cancel did not return to Company Command")
	_check(game.get("campaign").runtime_projection() == navigation_projection, "idle ui_cancel changed campaign projection")
	game.set("content", null)
	if content != null and is_instance_valid(content):
		var parent := content.get_parent()
		if parent != null:
			parent.remove_child(content)
		content.free()
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


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


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PREMIUM_GACHA_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
