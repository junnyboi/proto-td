extends SceneTree

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const TIMEOUT := 35.0

var _failures: Array[String] = []
var _timed_out := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(TIMEOUT).timeout.connect(_on_timeout, CONNECT_ONE_SHOT)
	var game: Node = root.get_node_or_null("Game")
	var music: Node = root.get_node_or_null("Music")
	var sfx: Node = root.get_node_or_null("Sfx")
	_check(game != null and music != null and sfx != null, "required autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 99)
	_check(bool(game.call("start_campaign", false, true)), "campaign fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/gacha.tscn").instantiate()
	root.add_child(screen)
	await _frames(2)
	var grid := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
	var pull := screen.find_child("PremiumPullButton", true, false) as Button
	var back := screen.find_child("BackButton", true, false) as Button
	var marks := screen.find_child("MarksLabel", true, false) as Label
	var pity_label := screen.find_child("PityLabel", true, false) as Label
	var pity_segments := screen.find_child("PitySegments", true, false) as HBoxContainer
	var hero_scroll := screen.find_child("PremiumHeroScroll", true, false) as ScrollContainer
	var browse_safe := screen.find_child("PremiumBrowseSafeFrame", true, false) as MarginContainer
	var browse_content := screen.find_child("PremiumBrowseContent", true, false) as VBoxContainer
	var browse_header := screen.find_child("PremiumBrowseHeader", true, false) as GridContainer
	var browse_title := screen.find_child("PremiumBrowseTitle", true, false) as Label
	var marks_safe := screen.find_child("MarksSafeMargin", true, false) as MarginContainer
	var guarantee := screen.find_child("GuaranteeTelemetry", true, false) as BoxContainer
	var browse_actions := screen.find_child("PremiumBrowseActions", true, false) as GridContainer
	var browse_status := screen.find_child("PullStatusLabel", true, false) as Label
	_check(grid != null and grid.get_child_count() == 3, "premium pool did not render")
	_check(marks.text == "120 MARKS" and pity_label.text.contains("10 PULLS"), "initial economy projection changed")
	_check(not pull.disabled and not back.disabled, "browse actions unavailable")
	for premium_id: String in ["lunaris_vessel", "reliquary_duelist", "archive_caster"]:
		var hero_accent: Color = screen.call("_reveal_accent", {"premium_id": premium_id, "rarity": 4})
		_check(
			hero_accent.is_equal_approx(Style.GOLD),
			"%s does not use the shared gold reveal treatment" % premium_id,
		)
	_check(pity_segments != null and pity_segments.get_child_count() == 10, "pity meter is not ten segments")
	_check(hero_scroll != null and hero_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "premium roster does not own a bounded flexible scroll")
	_check(hero_scroll != null and hero_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "premium roster permits horizontal scrolling")
	_check(grid.columns == 3, "desktop premium roster does not use all three columns")
	_check(browse_safe != null and browse_content != null and browse_content.get_parent() == browse_safe, "browse content retained an outer panel shell")
	_check(screen.find_child("PremiumGachaShell", true, false) == null and screen.find_child("PremiumIntroPanel", true, false) == null, "obsolete browse containers remain")
	_check(browse_header.columns == 3 and not guarantee.vertical and browse_actions.columns == 1, "wide browse hierarchy changed")
	_check(back.custom_minimum_size.x >= 360.0 and back.custom_minimum_size.y >= 76.0, "Command Deck action is not comfortably extended")
	_check(back.get_theme_font_size(&"font_size") >= 26 and back.autowrap_mode != TextServer.AUTOWRAP_OFF and not back.clip_text, "Command Deck typography or wrapping regressed")
	_check(browse_title.get_theme_font_size(&"font_size") == marks.get_theme_font_size(&"font_size"), "Marks does not match title size")
	_check(marks.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Marks is not gold")
	_check(marks.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and marks_safe.get_theme_constant(&"margin_right") >= 30, "Marks lacks its right safe inset")
	_check(pity_label.get_theme_font_size(&"font_size") >= 30 and pity_label.custom_minimum_size.x >= 560.0, "guarantee telemetry is not doubled or landscape-contained")
	_check(not browse_status.visible and browse_status.text.is_empty(), "unnecessary ready copy remains visible")
	_check(is_equal_approx(pull.custom_minimum_size.x, 320.0) and pull.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "Resonate action is not fixed-width and centered")
	_check(pull.get_theme_stylebox(&"normal") is StyleBoxFlat and pull.get_theme_font_size(&"font_size") >= 24, "Resonate action retained the struck texture or undersized type")
	_check(not _tree_text(browse_content).contains("LUNARIS RELIQUARY"), "browse eyebrow copy remains")
	_check(not _tree_text(browse_content).contains("FIXED ELITE KIT") and not _tree_text(browse_content).contains("PULL TO RECRUIT"), "obsolete recruitment detail copy remains")
	for premium_id: String in ["archive_caster", "lunaris_vessel", "reliquary_duelist"]:
		var card := grid.get_node_or_null("Premium_%s" % premium_id) as PanelContainer
		var portrait := card.find_child("Portrait", true, false) as TextureRect if card != null else null
		var card_style := card.get_theme_stylebox(&"panel") if card != null else null
		_check(card != null and portrait != null and portrait.texture != null, "missing portrait %s" % premium_id)
		_check(card.custom_minimum_size == Vector2(320, 430), "unequal card size for %s" % premium_id)
		_check(portrait.custom_minimum_size == Vector2(300, 280), "unequal portrait size for %s" % premium_id)
		_check(card.find_child("RarityLabel", true, false) == null and card.find_child("HeroDetail", true, false) == null, "rarity/detail labels remain on %s" % premium_id)
		_check(card_style != null and card_style.content_margin_left >= 16.0 and card_style.content_margin_top >= 16.0, "premium card padding is below 16px for %s" % premium_id)
		_check(Art.size(StringName("portrait_%s_fullsize" % premium_id)) == Vector2i(640, 800), "full-size portrait changed for %s" % premium_id)

	var confirmation_layer := screen.find_child("PremiumPullConfirmationLayer", true, false)
	var reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(confirmation_layer == null, "obsolete pull confirmation screen is still mounted")
	root.size = Vector2i(1024, 576)
	await _frames(2)
	_check(grid.columns == 2 and browse_header.columns == 3 and not guarantee.vertical, "compact landscape browse did not use two card columns")
	for card: Control in grid.get_children():
		var compact_bounds := card.get_global_rect()
		_check(compact_bounds.position.x >= -0.5 and compact_bounds.end.x <= 1024.5, "%s overflows compact landscape width" % card.name)
	root.size = Vector2i(390, 844)
	await _frames(2)
	_check(grid.columns == 1 and browse_header.columns == 1 and guarantee.vertical, "portrait browse did not stack")
	_check(back.custom_minimum_size.x <= 366.0 and pull.custom_minimum_size.x <= 366.0, "portrait browse action exceeds its safe width")
	for card: Control in grid.get_children():
		var portrait_bounds := card.get_global_rect()
		_check(portrait_bounds.position.x >= -0.5 and portrait_bounds.end.x <= 390.5, "%s overflows portrait width" % card.name)
	root.size = Vector2i(1280, 720)
	await _frames(2)

	# Missing durable authority is rejected at preflight without opening any second-step UI.
	var before: Dictionary = game.get("campaign").runtime_projection()
	var durable_store: Variant = game.get("campaign_store")
	game.set("campaign_store", null)
	pull.grab_focus()
	pull.pressed.emit()
	await _frames(1)
	_check(screen.call("flow_state_name") == &"BROWSE" and not reveal.visible, "preflight rejection left browse or opened reveal")
	_check(game.get("campaign").runtime_projection() == before, "preflight rejection changed economy or pity")
	game.set("campaign_store", durable_store)

	# Accepted path: one primary press, observable lock, exactly one dispatch, immediate reveal handoff.
	root.size = Vector2i(1280, 720)
	await _frames(1)
	var data_before: Dictionary = game.get("campaign").data_copy()
	var receipt_count := int((data_before["command_receipts"] as Array).size())
	var projection_before: Dictionary = game.get("campaign").runtime_projection()
	pull.pressed.emit()
	_check(screen.call("flow_state_name") == &"COMMITTING" and game.get("campaign").runtime_projection() == projection_before, "direct lock was not observable before dispatch")
	pull.pressed.emit()
	await _action(&"ui_accept")
	await _action(&"ui_cancel")
	await _frames(2)
	var data_after: Dictionary = game.get("campaign").data_copy()
	var projection_after: Dictionary = game.get("campaign").runtime_projection()
	_check(data_after["command_receipts"].size() == receipt_count + 1, "direct pull did not dispatch exactly once")
	_check(int(projection_after["marks"]) == int(projection_before["marks"]) - 40, "accepted pull charged wrong amount")
	_check(int(projection_after["next_premium_pull_index"]) == int(projection_before["next_premium_pull_index"]) + 1, "accepted pull index changed more than once")
	_check(screen.call("flow_state_name") == &"REVEAL" and screen.call("transition_state_name") == &"NONE", "accepted receipt did not hand off coherently")
	_check(reveal.visible, "accepted direct pull did not begin reveal")
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
	root.size = Vector2i(1280, 720)
	await _frames(1)
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
	var reveal_audio_starts := int(sfx.call("audible_start_count"))
	cinematic.call("_on_video_finished")
	await _frames(1)
	_check(reveal_stack.visible, "cinematic completion did not reveal identity")
	_check(video.is_playing() and video.visible, "identity reveal did not preserve loop playback")
	_check(not plate.visible, "identity reveal froze onto the final plate instead of looping")
	_check(reveal_title.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Lunaris Vessel title is not gold")
	_check(sfx.call("last_resolved_id") == &"gacha_identity_reveal", "identity reveal sting did not fire")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "identity reveal did not hand BGM back to staging")
	_check(is_equal_approx(float(music.call("last_transition_fade_seconds")), 0.75), "identity reveal used the wrong BGM crossfade")
	await _seconds(4.0)
	_check(int(sfx.call("audible_start_count")) == reveal_audio_starts + 6, "five-star reveal did not play one identity sting plus five star blooms")
	_check(sfx.call("last_resolved_id") == &"gacha_star_bloom", "star pulse sequence did not end on the bloom cue")
	for index: int in 5:
		var star := stars.get_child(index) as ResonanceStar
		_check(star.visible and star.modulate.a > 0.99 and absf(star.rotation) < 0.01, "five-star item %d did not settle" % (index + 1))
		var star_accent: Color = star.get("_accent")
		_check(star_accent.is_equal_approx(Style.GOLD), "Lunaris Vessel star %d is not gold" % (index + 1))
		_check(bool(star.call("uses_generated_art")), "five-star item %d is not using GPT Image 2 art" % (index + 1))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen.call("_on_reveal_gui_input", click)
	await _frames(1)
	_check(not reveal.visible and video.stream == null and not pull.disabled and not back.disabled, "click skip did not finalize/release")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "click skip did not restore music")

	root.size = Vector2i(720, 1280)
	await _frames(2)
	screen.set("reduced_motion", true)
	var reduced_audio_starts := int(sfx.call("audible_start_count"))
	screen.call("_begin_reveal", _sample_pull(4, false))
	await _frames(1)
	_check(reveal.visible and reveal_stack.visible and reveal_title.text == "ARCHIVE CASTER", "reduced reveal did not settle identity")
	_check(reveal_stack.custom_minimum_size.x >= 672.0, "portrait identity stack collapsed horizontally")
	_check(reveal_title.get_theme_font_size(&"font_size") <= 72, "portrait identity title did not scale down")
	_check(reveal_title.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Archive Caster title is not gold")
	_check(plate.visible and plate.texture != null and video.stream == null, "reduced reveal loaded video instead of final plate")
	for index: int in 5:
		var star := stars.get_child(index) as ResonanceStar
		_check(star.visible == (index < 4), "reduced reveal star count changed")
		if index < 4:
			var star_accent: Color = star.get("_accent")
			_check(star_accent.is_equal_approx(Style.GOLD), "Archive Caster star %d is not gold" % (index + 1))
			_check(bool(star.call("uses_generated_art")), "Archive Caster star %d is not using generated art" % (index + 1))
	_check(int(sfx.call("audible_start_count")) == reduced_audio_starts + 2, "reduced reveal did not play its identity and star cues")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "reduced reveal did not preserve staging BGM")
	await _action(&"ui_cancel")
	_check(not reveal.visible and screen.call("flow_state_name") == &"BROWSE", "reduced reveal cancel did not finalize")
	root.size = Vector2i(1280, 720)
	await _frames(2)

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


func _tree_text(node: Node) -> String:
	if node == null:
		return ""
	var values: Array[String] = []
	if node is Label:
		values.append((node as Label).text.to_upper())
	elif node is Button:
		values.append((node as Button).text.to_upper())
	for child: Node in node.get_children():
		values.append(_tree_text(child))
	return " ".join(values)


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
