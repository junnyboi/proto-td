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
	var i18n: Node = root.get_node_or_null("I18n")
	var music: Node = root.get_node_or_null("Music")
	var sfx: Node = root.get_node_or_null("Sfx")
	_check(game != null and i18n != null and music != null and sfx != null, "required autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 99)
	_check(bool(game.call("start_campaign", false, true)), "campaign fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	root.size = Vector2i(1920, 880)
	var screen: Node = load("res://scenes/gacha.tscn").instantiate()
	root.add_child(screen)
	await _frames(2)
	var grid := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
	var pull := screen.find_child("PremiumPullButton", true, false) as Button
	var back := screen.find_child("BackButton", true, false) as Button
	var marks := screen.find_child("MarksLabel", true, false) as Label
	var balance_icon := screen.find_child("ResonanceShardIcon", true, false) as TextureRect
	var marks_display := marks.get_parent() as Control if marks != null else null
	var pity_label := screen.find_child("PityLabel", true, false) as Label
	var pity_segments := screen.find_child("PitySegments", true, false) as HBoxContainer
	var hero_scroll := screen.find_child("PremiumHeroScroll", true, false) as ScrollContainer
	var browse_safe := screen.find_child("PremiumBrowseSafeFrame", true, false) as MarginContainer
	var browse_content := screen.find_child("PremiumBrowseContent", true, false) as VBoxContainer
	var browse_header := screen.find_child("PremiumBrowseHeader", true, false) as GridContainer
	var browse_title := screen.find_child("PremiumBrowseTitle", true, false) as Label
	var title_center := screen.find_child("PremiumTitleCenter", true, false) as VBoxContainer
	var marks_safe := screen.find_child("MarksSafeMargin", true, false) as MarginContainer
	var guarantee := screen.find_child("GuaranteeTelemetry", true, false) as BoxContainer
	var browse_actions := screen.find_child("PremiumBrowseActions", true, false) as GridContainer
	var browse_status := screen.find_child("PullStatusLabel", true, false) as Label
	var pull_action_label := screen.find_child("PremiumPullActionLabel", true, false) as Label
	var pull_cost_label := screen.find_child("PremiumPullCostLabel", true, false) as Label
	var browse_backdrop := screen.find_child("AstralBackdropArt", true, false) as TextureRect
	var history_button := screen.find_child("PullHistoryButton", true, false) as Button
	var history_layer := screen.find_child("PremiumPullHistoryLayer", true, false) as Control
	var history_drawer := screen.find_child("MoonArchiveDrawer", true, false) as PanelContainer
	var history_close := screen.find_child("ClosePullHistoryButton", true, false) as Button
	var history_rows := screen.find_child("PullHistoryRows", true, false) as VBoxContainer
	var history_empty := screen.find_child("PullHistoryEmptyState", true, false) as VBoxContainer
	_check(grid != null and grid.get_child_count() == 3, "premium pool did not render")
	_check(marks.text == "120" and balance_icon != null and balance_icon.texture != null and pity_label.text.contains("10 PULLS"), "initial shard economy projection changed")
	_check(marks_display != null and marks_display.tooltip_text.contains("clean Lunaris crystal") and marks_display.tooltip_text.contains("no soul inside") and marks_display.accessibility_description.contains("recovery body"), "shard balance lacks its clean soul-free recovery explanation")
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
	_check(browse_header.columns == 2 and not guarantee.vertical and browse_actions.columns == 3, "wide browse hierarchy changed")
	_check(back.text == "RETURN" and back.icon == null and back.get_parent() == browse_actions, "Return action did not move to the footer")
	_check(back.custom_minimum_size.x >= 300.0 and back.custom_minimum_size.y >= 76.0, "Return action is not comfortably sized")
	_check(back.autowrap_mode == TextServer.AUTOWRAP_OFF and not back.clip_text, "Return single-line contract regressed")
	var back_presentation := back.get_node_or_null("PresentationLabel") as Label
	var back_style := back.get_theme_stylebox(&"normal")
	_check(back_presentation != null and back_presentation.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Return copy is not independently centered")
	_check(back_style != null and is_zero_approx(back_style.content_margin_left) and back_style.content_margin_top == 12.0 and is_zero_approx(back_style.content_margin_right) and back_style.content_margin_bottom == 12.0, "Return does not use zero horizontal and 12px vertical padding")
	_check(title_center != null and title_center.alignment == BoxContainer.ALIGNMENT_CENTER, "Premium title is not vertically centered")
	_check(browse_title.get_global_rect().position.y < back.get_global_rect().position.y, "Premium title did not remain in the header above Return")
	_check(browse_title.get_theme_font_size(&"font_size") == marks.get_theme_font_size(&"font_size"), "Shard balance does not match title size")
	_check(marks.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Shard balance is not gold")
	_check(marks.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and browse_safe.get_theme_constant(&"margin_right") >= 64, "Premium content lacks its 64px right safe inset")
	_check(browse_safe.get_theme_constant(&"margin_left") >= 64, "Premium content lacks its 64px left safe inset")
	_check(pity_label.get_theme_font_size(&"font_size") == 30 and pity_label.autowrap_mode == TextServer.AUTOWRAP_OFF, "guarantee telemetry is not reduced to one line")
	for segment: ColorRect in pity_segments.get_children():
		_check(segment.custom_minimum_size.x <= 58.0 and segment.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "guarantee bar remained excessively wide")
	_check(not browse_status.visible and browse_status.text.is_empty(), "unnecessary ready copy remains visible")
	_check(is_equal_approx(pull.custom_minimum_size.x, 800.0) and pull.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "Resonate action is not 2.5× wide and centered")
	_check(pull.get_theme_stylebox(&"normal") is StyleBoxFlat, "Resonate action retained a textured or struck surface")
	_check(pull_action_label != null and pull_action_label.text == "RESONATE" and pull_action_label.get_theme_font_size(&"font_size") == 48, "Resonate primary label hierarchy changed")
	_check(pull_cost_label != null and pull_cost_label.text == "40" and pull_cost_label.get_theme_font_size(&"font_size") < pull_action_label.get_theme_font_size(&"font_size"), "Resonate shard cost is not a smaller second line")
	_check(pull.accessibility_name.contains("40 Resonance Shards") and not pull.text.contains("MARKS"), "Resonate accessibility or symbol-first copy regressed")
	_check(pull.tooltip_text.contains("RESONATE") and pull.tooltip_text.contains("one known soul") and pull.tooltip_text.contains("recovery body"), "Resonate action lacks its unique-soul recovery explanation")
	_check(pull_cost_label.get_parent().mouse_filter == Control.MOUSE_FILTER_IGNORE, "Resonate shard cost can intercept parent button input")
	var pull_normal := pull.get_theme_stylebox(&"normal") as StyleBoxFlat
	var pull_hover := pull.get_theme_stylebox(&"hover") as StyleBoxFlat
	_check(pull_normal != null and pull_hover != null and not pull_normal.bg_color.is_equal_approx(pull_hover.bg_color), "Resonate action lacks a distinct hover surface")
	_check(not _tree_text(browse_content).contains("LUNARIS RELIQUARY"), "browse eyebrow copy remains")
	_check(not _tree_text(browse_content).contains("FIXED ELITE KIT") and not _tree_text(browse_content).contains("PULL TO RECRUIT"), "obsolete recruitment detail copy remains")
	for card_index: int in grid.get_child_count():
		var premium_id := String((grid.get_child(card_index) as Control).name).trim_prefix("Premium_")
		var card := grid.get_node_or_null("Premium_%s" % premium_id) as PanelContainer
		var portrait_frame := card.find_child("PortraitFrame", true, false) as Control if card != null else null
		var portrait := card.find_child("Portrait", true, false) as TextureRect if card != null else null
		var card_style := card.get_theme_stylebox(&"panel") if card != null else null
		_check(card != null and portrait != null and portrait.texture != null, "missing portrait %s" % premium_id)
		_check(card.custom_minimum_size == Vector2(480, 645), "card did not increase by 50%% for %s" % premium_id)
		_check(portrait_frame != null and portrait_frame.custom_minimum_size == Vector2(432, 420), "portrait frame did not scale with %s" % premium_id)
		_check(portrait.scale.is_equal_approx(Vector2(1.03, 1.03)) and is_zero_approx(portrait.pivot_offset.y) and portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "custom premium portrait is not using the top-safe square crop for %s" % premium_id)
		_check(bool(portrait.get_meta(&"premium_portrait_entrance", false)), "premium portrait entrance is missing for %s" % premium_id)
		_check(int(portrait.get_meta(&"premium_portrait_entrance_index", -1)) == card_index, "premium portrait stagger order drifted for %s" % premium_id)
		_check(float(portrait.get_meta(&"premium_portrait_entrance_duration", 0.0)) <= 0.45, "premium portrait entrance is no longer subtle for %s" % premium_id)
		_check(card.find_child("RarityLabel", true, false) == null and card.find_child("HeroDetail", true, false) == null, "rarity/detail labels remain on %s" % premium_id)
		_check(card_style != null and card_style.content_margin_left >= 24.0 and card_style.content_margin_top >= 24.0 and card_style.content_margin_right >= 24.0 and card_style.content_margin_bottom >= 24.0, "premium card padding is below 24px for %s" % premium_id)
		_check((card.find_child("HeroName", true, false) as Label).get_theme_font_size(&"font_size") == 48, "hero content did not scale with %s" % premium_id)
		_check(Art.size(StringName("portrait_%s" % premium_id)) == Vector2i(512, 512), "custom identity portrait changed for %s" % premium_id)
		_check(Art.size(StringName("portrait_%s_fullsize" % premium_id)) == Vector2i(640, 800), "full-size portrait changed for %s" % premium_id)
	_check(Art.size(&"ui_gacha_return") == Vector2i(512, 512), "generated Return glyph is absent from the art manifest")
	_check(Art.size(&"ui_resonance_shard") == Vector2i(512, 512), "GPT Image 2 Resonance Shard is absent from the art manifest")
	_check(history_button != null and history_button.icon == null and history_button.text == "HISTORY" and history_button.get_parent() == browse_actions, "Moon Archive action did not move to the footer")
	var history_presentation := history_button.get_node_or_null("PresentationLabel") as Label
	var history_style := history_button.get_theme_stylebox(&"normal")
	_check(history_button.custom_minimum_size.x == 230.0 and history_presentation != null and history_presentation.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "History width or centered copy regressed")
	_check(history_style != null and is_zero_approx(history_style.content_margin_left) and history_style.content_margin_top == 12.0 and is_zero_approx(history_style.content_margin_right) and history_style.content_margin_bottom == 12.0, "History does not use zero horizontal and 12px vertical padding")
	_check(back.get_global_rect().position.x < pull.get_global_rect().position.x and pull.get_global_rect().position.x < history_button.get_global_rect().position.x, "footer controls are not ordered left, center, right")
	_check(not _tree_text(browse_content).contains("MARKS"), "retired Marks copy remains in Premium Resonance")
	_check(history_layer != null and history_drawer != null and history_close != null, "Moon Archive drawer did not mount")
	if history_drawer != null:
		var drawer_style := history_drawer.get_theme_stylebox(&"panel")
		_check(
			drawer_style.content_margin_left >= 24.0
			and drawer_style.content_margin_top >= 24.0
			and drawer_style.content_margin_right >= 24.0
			and drawer_style.content_margin_bottom >= 24.0,
			"Moon Archive custom frame padding is below 24px",
		)
	_check(not history_layer.visible and history_rows != null and history_empty != null, "Moon Archive did not initialize hidden")
	_check(Art.size(&"ui_gacha_moon_archive") == Vector2i(512, 512), "GPT Image 2 Moon Archive glyph is absent")
	_check(Art.size(&"ui_gacha_reserve_life") == Vector2i(512, 512), "GPT Image 2 reserve-life sigil is absent")
	history_button.grab_focus()
	history_button.pressed.emit()
	await _seconds(0.32)
	_check(history_layer.visible and bool(history_layer.call("is_open")), "Moon Archive did not open")
	_check(history_empty.visible and history_rows.get_child_count() == 1, "empty campaign history did not show its authored empty state")
	_check(root.gui_get_focus_owner() == history_close, "Moon Archive did not trap focus on its close action")
	_check(pull.disabled and back.disabled and history_button.disabled, "browse actions remained available behind Moon Archive")
	await _action(&"ui_cancel")
	await _seconds(0.24)
	_check(not history_layer.visible and root.gui_get_focus_owner() == history_button, "Moon Archive cancel did not close and restore its opener")
	root.size = Vector2i(2048, 825)
	await _frames(2)
	_check(browse_backdrop != null and is_zero_approx(browse_backdrop.position.y), "browse background is not top aligned")
	_check(browse_backdrop != null and browse_backdrop.size.y > 825.0, "browse background did not retain cover crop")
	_check(browse_backdrop != null and is_zero_approx(browse_backdrop.pivot_offset.y), "browse background pivot is not top anchored")
	var short_wide_portrait := grid.get_child(0).find_child("Portrait", true, false) as TextureRect
	var short_wide_frame := grid.get_child(0).find_child("PortraitFrame", true, false) as Control
	var short_wide_zoom := maxf(
		1.03,
		short_wide_frame.custom_minimum_size.x / short_wide_frame.custom_minimum_size.y,
	)
	_check(
		short_wide_portrait != null
		and short_wide_portrait.scale.is_equal_approx(Vector2.ONE * short_wide_zoom),
		"short-wide card did not retain its responsive custom-portrait crop",
	)

	# Source localization must refresh existing cards and accessibility metadata in place.
	_check(i18n.call("set_locale", &"zh-CN"), "zh-CN locale could not activate")
	await _frames(2)
	var ui_copy := load("res://scripts/ui/components/ui_copy.gd") as Script
	_check(ui_copy.call("premium_name", "archive_caster", "Archive Caster") == "档案术师", "Archive Caster stable key changed")
	_check(ui_copy.call("premium_name", "lunaris_vessel", "Lunaris Vessel") == "月辉载体", "Lunaris Vessel stable key changed")
	_check(ui_copy.call("premium_name", "reliquary_duelist", "Reliquary Duelist") == "圣物决斗者", "Reliquary Duelist stable key changed")
	var localized_tree_text := _tree_text(grid)
	_check(localized_tree_text.contains("月辉载体"), "Lunaris Vessel name did not refresh to natural Chinese")
	for expected_class: String in ["见习法师", "术士", "剑圣"]:
		_check(localized_tree_text.contains(expected_class), "%s class did not refresh through name_key" % expected_class)
	for card: PanelContainer in grid.get_children():
		var role := card.find_child("HeroClass", true, false) as Label
		var metric := card.find_child("OwnershipMetric", true, false) as Label
		var card_style := card.get_theme_stylebox(&"panel")
		_check(role != null and metric != null, "%s translated footer is incomplete" % card.name)
		if role != null and metric != null:
			_check(
				metric.get_global_rect().end.y <= card.get_global_rect().end.y - card_style.content_margin_bottom + 1.0,
				"%s translated footer enters its lower ornament" % card.name,
			)
	_check(browse_status.accessibility_name == "高级共鸣状态", "gacha status metadata did not refresh")
	_check(history_button.text == "共鸣记录", "Moon Archive action did not refresh to Chinese")
	_check(marks_display.tooltip_text.contains("不含灵魂") and marks_display.tooltip_text.contains("恢复用身体"), "clean-shard tooltip did not refresh to Chinese")
	var localized_history_text := _tree_text(history_drawer)
	_check(localized_history_text.contains("共鸣记录"), "Resonance History title did not refresh to Chinese")
	_check(localized_history_text.contains("暂无共鸣记录"), "Moon Archive empty state did not refresh to Chinese")
	_check(screen.call("_callsign_for", "missing_signal") == "未知灵魂锚", "unknown Soul Anchor fallback did not localize")
	var locked_card := screen.call("_hero_card", {
		"premium_id": "archive_caster", "callsign": "Archive Caster", "class_id": "mage_apprentice",
	}, {"premium_lives": 0, "life_status": "dead"}) as PanelContainer
	var locked_metric := locked_card.find_child("OwnershipMetric", true, false) as Label
	_check(locked_metric.get_theme_color(&"font_color").is_equal_approx(Style.DANGER), "localized locked state lost danger color")
	locked_card.free()
	_check(i18n.call("set_locale", &"en-US"), "en-US locale could not restore")
	await _frames(2)

	var confirmation_layer := screen.find_child("PremiumPullConfirmationLayer", true, false)
	var reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(confirmation_layer == null, "obsolete pull confirmation screen is still mounted")
	root.size = Vector2i(1024, 576)
	await _frames(2)
	_check(grid.columns == 2 and browse_header.columns == 2 and browse_actions.columns == 1 and not guarantee.vertical, "compact landscape browse did not stack the fixed footer actions")
	for card: Control in grid.get_children():
		var compact_bounds := card.get_global_rect()
		_check(compact_bounds.position.x >= -0.5 and compact_bounds.end.x <= 1024.5, "%s overflows compact landscape width" % card.name)
	root.size = Vector2i(390, 844)
	await _frames(2)
	_check(grid.columns == 1 and browse_header.columns == 1 and guarantee.vertical, "portrait browse did not stack")
	_check(back.custom_minimum_size.x <= 366.0 and pull.custom_minimum_size.x <= 366.0, "portrait browse action exceeds its safe width")
	_check(history_button.custom_minimum_size.x <= 342.0, "portrait History action exceeds its safe width")
	for card: Control in grid.get_children():
		var portrait_bounds := card.get_global_rect()
		_check(portrait_bounds.position.x >= -0.5 and portrait_bounds.end.x <= 390.5, "%s overflows portrait width" % card.name)
	history_button.grab_focus()
	history_button.pressed.emit()
	await _seconds(0.32)
	var drawer_bounds := history_drawer.get_global_rect()
	_check(
		drawer_bounds.position.x >= -0.5 and drawer_bounds.end.x <= 390.5,
		"portrait Moon Archive drawer overflows the viewport: %s" % drawer_bounds,
	)
	await _action(&"ui_cancel")
	await _seconds(0.24)
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
	history_button.grab_focus()
	history_button.pressed.emit()
	await _seconds(0.32)
	var committed_history_rows := 0
	for history_child: Node in history_rows.get_children():
		if String(history_child.name).begins_with("HistoryPull_"):
			committed_history_rows += 1
	_check(committed_history_rows == 1 and not history_empty.visible, "committed pull did not enter the Moon Archive")
	var history_portrait := history_drawer.find_child("HistoryPortrait", true, false) as TextureRect
	_check(history_portrait != null and bool(history_portrait.get_meta(&"premium_portrait_entrance", false)), "Moon Archive premium portrait lacks its entrance motion")
	_check(_tree_text(history_drawer).contains("1 COMPLETED RESONANCES"), "Resonance History total did not match the canonical receipt count")
	await _action(&"ui_cancel")
	await _seconds(0.24)

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
	var conversion_panel := screen.find_child("DuplicateConversionFeedback", true, false) as PanelContainer
	var conversion_icon := screen.find_child("ReserveLifeSigil", true, false) as TextureRect
	var conversion_title := screen.find_child("DuplicateConversionTitle", true, false) as Label
	var conversion_outcome := screen.find_child("DuplicateConversionOutcome", true, false) as Label
	var conversion_detail := screen.find_child("DuplicateConversionDetail", true, false) as Label
	var pull_again := screen.find_child("PullAgainButton", true, false) as Button
	var skip := screen.find_child("SkipRevealButton", true, false) as Button
	var cinematic := screen.find_child("GachaCinematicPlayer", true, false) as Control
	var video := screen.find_child("CinematicVideo", true, false) as VideoStreamPlayer
	var plate := screen.find_child("CinematicFinalPlate", true, false) as TextureRect
	root.size = Vector2i(2048, 825)
	await _frames(2)
	_check(screen.find_child("SignalFilaments", true, false) == null, "circular signal-filament web returned")
	_check(reveal.visible and pull.disabled and back.disabled, "five-star reveal did not lock browse")
	_check(reveal_title.text == "LUNARIS VESSEL" and not reveal_stack.visible, "identity appeared before cinematic completion")
	_check(pull_again != null and not pull_again.visible, "Pull Again appeared before the final reveal")
	_check(stars.get_child_count() == 5 and video.stream != null and video.is_playing(), "five-star cinematic resources did not start")
	_check(is_zero_approx(video.position.y) and video.size.y > 825.0, "landscape cinematic is not top-aligned cover")
	_check(is_zero_approx(video.pivot_offset.y), "landscape cinematic hover pivot is not top anchored")
	_check(reveal_title.get_theme_font_size(&"font_size") == 156, "landscape reveal title typography is not 1.5×")
	_check(reveal_hint != null and reveal_hint.get_theme_font_size(&"font_size") == 42, "reveal continuation typography is not 1.5×")
	_check(skip != null and skip.get_theme_font_size(&"font_size") == 54, "Skip Reveal typography is not 1.5×")
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
	_check(conversion_panel != null and conversion_icon != null and not conversion_panel.visible, "first acquisition showed duplicate conversion feedback")
	_check(pull_again.visible and not pull_again.disabled, "Pull Again is unavailable on the settled reveal")
	_check(pull_again.text == "PULL AGAIN • 40" and pull_again.icon != null and pull_again.accessibility_name.contains("40 Resonance Shards"), "Pull Again does not expose the icon-backed authoritative cost")
	_check(pull_again.tooltip_text.contains("PULL AGAIN") and pull_again.tooltip_text.contains("one known soul") and pull_again.tooltip_text.contains("recovery body"), "Pull Again lacks its unique-soul recovery explanation")
	_check(pull_again.custom_minimum_size.x >= 400.0 and pull_again.get_theme_font_size(&"font_size") >= 54, "Pull Again is not comfortably sized")
	_check(root.gui_get_focus_owner() == pull_again, "settled reveal did not focus Pull Again")
	var hover_surface := cinematic.call("hover_surface") as Control
	_check(hover_surface == video, "looping character film is not the active hover surface")
	_check(video.mouse_filter == Control.MOUSE_FILTER_PASS and plate.mouse_filter == Control.MOUSE_FILTER_PASS, "character reveal surfaces cannot receive hover input")
	cinematic.call("_on_final_plate_mouse_entered")
	var portrait_motion := InputEventMouseMotion.new()
	portrait_motion.position = hover_surface.size * Vector2(0.78, 0.36)
	cinematic.call("_on_final_plate_gui_input", portrait_motion)
	await _frames(8)
	_check(bool(cinematic.call("final_plate_hovered")), "final character plate did not enter hover state")
	_check(hover_surface.scale.x > 1.0 and hover_surface.scale.y > 1.0, "active character reveal did not gain hover depth")
	_check(hover_surface.offset_transform_position.length() > 0.1, "active character reveal did not respond to pointer position")
	_check(is_zero_approx(hover_surface.offset_transform_position.y), "hover motion shifted the top-aligned reveal vertically")
	_check(hover_surface.modulate.r > 1.0, "active character reveal did not gain hover luminance")
	cinematic.call("_on_final_plate_mouse_exited")
	await _frames(12)
	_check(not bool(cinematic.call("final_plate_hovered")), "final character plate hover state did not clear")
	_check(hover_surface.scale.distance_to(Vector2.ONE) < 0.02, "active character reveal did not settle after hover")
	var repeat_receipts := int((game.get("campaign").data_copy()["command_receipts"] as Array).size())
	var repeat_marks := int(game.get("campaign").runtime_projection()["marks"])
	await _action(&"ui_accept")
	await _frames(4)
	_check(screen.call("flow_state_name") == &"REVEAL" and reveal.visible, "Pull Again did not start the next reveal")
	_check(int((game.get("campaign").data_copy()["command_receipts"] as Array).size()) == repeat_receipts + 1, "Pull Again did not dispatch exactly once")
	_check(int(game.get("campaign").runtime_projection()["marks"]) == repeat_marks - 40, "Pull Again charged the wrong amount")
	_check(not screen.get("_pending_pull").is_empty(), "Pull Again lost the authoritative receipt")
	_check(not pull_again.visible, "Pull Again remained visible during the next cinematic")
	screen.call("_finish_reveal")
	await _frames(2)
	_check(not reveal.visible and video.stream == null and not pull.disabled and not back.disabled, "Pull Again follow-up reveal did not finalize cleanly")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "Pull Again follow-up did not restore music")

	root.size = Vector2i(720, 1280)
	await _frames(2)
	screen.set("reduced_motion", true)
	var reduced_audio_starts := int(sfx.call("audible_start_count"))
	var duplicate_pull := _sample_pull(4, false)
	duplicate_pull["new_hero"] = false
	duplicate_pull["lives_before"] = 1
	duplicate_pull["lives_after"] = 2
	duplicate_pull["pull_count_after"] = 2
	screen.call("_begin_reveal", duplicate_pull)
	await _frames(1)
	root.size = Vector2i(720, 1000)
	await _frames(2)
	_check(reveal.visible and reveal_stack.visible and reveal_title.text == "ARCHIVE CASTER", "reduced reveal did not settle identity")
	_check(reveal_stack.custom_minimum_size.x >= 672.0, "portrait identity stack collapsed horizontally")
	_check(reveal_title.get_theme_font_size(&"font_size") <= 108, "portrait identity title did not scale down")
	_check(reveal_title.get_theme_color(&"font_color").is_equal_approx(Style.GOLD), "Archive Caster title is not gold")
	_check(plate.visible and plate.texture != null and video.stream == null, "reduced reveal loaded video instead of final plate")
	_check(conversion_panel.visible and conversion_icon.texture != null, "duplicate reveal omitted generated conversion feedback")
	_check(conversion_title.text == "SAME SOUL · NEW RECOVERY BODY", "duplicate conversion lost the same-soul recovery-body explanation")
	_check(conversion_outcome.text == "ANOTHER BODY + SOUL ANCHOR" and conversion_detail.text == "PREPARED BODIES 1 → 2", "duplicate prepared-body conversion copy is not receipt-accurate")
	_check(conversion_icon.scale.is_equal_approx(Vector2.ONE), "reduced motion still pulsed the reserve-life sigil")
	_check(not reveal_hint.visible, "duplicate reveal retained redundant click-anywhere copy below conversion feedback")
	_check(is_zero_approx(plate.position.y) and plate.size.y > 1000.0, "portrait final plate is not top-aligned cover")
	_check(is_zero_approx(plate.pivot_offset.y), "portrait final plate hover pivot is not top anchored")
	for index: int in 5:
		var star := stars.get_child(index) as ResonanceStar
		_check(star.visible == (index < 4), "reduced reveal star count changed")
		if index < 4:
			var star_accent: Color = star.get("_accent")
			_check(star_accent.is_equal_approx(Style.GOLD), "Archive Caster star %d is not gold" % (index + 1))
			_check(bool(star.call("uses_generated_art")), "Archive Caster star %d is not using generated art" % (index + 1))
	_check(int(sfx.call("audible_start_count")) == reduced_audio_starts + 2, "reduced reveal did not play its identity and star cues")
	_check(StringName(music.call("current_id")) == &"lunaris_staging_archive_command", "reduced reveal did not preserve staging BGM")
	var revival_pull := duplicate_pull.duplicate(true)
	revival_pull["revived"] = true
	revival_pull["lives_before"] = 0
	revival_pull["lives_after"] = 1
	screen.set("_pending_pull", revival_pull)
	screen.call("_refresh_conversion_copy")
	_check(conversion_outcome.text == "RECOVERY BODY READY" and conversion_detail.text == "PREPARED BODIES 0 → 1", "recovery-body restoration feedback is not receipt-accurate")
	cinematic.call("_on_final_plate_mouse_entered")
	await _frames(4)
	_check(plate.scale.is_equal_approx(Vector2.ONE) and plate.offset_transform_position.is_zero_approx(), "reduced motion still transformed the final plate")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen.call("_on_reveal_gui_input", click)
	await _frames(1)
	_check(not reveal.visible and screen.call("flow_state_name") == &"BROWSE", "reduced reveal click did not finalize")
	for reduced_card: PanelContainer in grid.get_children():
		var reduced_portrait := reduced_card.find_child("Portrait", true, false) as TextureRect
		_check(reduced_portrait != null and bool(reduced_portrait.get_meta(&"premium_portrait_entrance_reduced", false)), "%s ignored Reduced Motion for its portrait entrance" % reduced_card.name)
		_check(reduced_portrait != null and reduced_portrait.offset_transform_position.is_zero_approx() and is_equal_approx(reduced_portrait.modulate.a, 1.0), "%s retained portrait drift or fade under Reduced Motion" % reduced_card.name)
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
