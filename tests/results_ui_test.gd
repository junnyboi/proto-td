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
	var previous_reduced_motion: Variant = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false,
	)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	game.call("set_run_seed", 2026)
	_check(bool(game.call("start_campaign", false, true)), "results campaign fixture failed")
	var projection: Dictionary = game.call("campaign_projection")
	var ready_heroes: Array = projection.get("ready_heroes", [])
	var hero_id := String(ready_heroes[0].get("hero_id", ""))
	var second_hero_id := String(ready_heroes[1].get("hero_id", ""))
	game.set("last_result", {
		"stage_id": &"s1",
		"result": BattleModel.Result.CLEAR,
		"stars": 3,
		"kills": 14,
		"leaks": 0,
		"rewards_granted": [{"kind": "currency", "id": "marks", "amount": 40}],
		"class_entitlements_granted": [&"mage_apprentice"],
		"xp_awards": [
			{"hero_id": hero_id, "delta": 100},
			{"hero_id": second_hero_id, "delta": 100},
		],
		"dead_hero_ids": [],
		"premium_life_losses": [],
	})
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/results.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var shell := screen.find_child("ResultsShell", true, false)
	var ceremony := screen.find_child("OutcomeCeremony", true, false) as PanelContainer
	var headline := screen.find_child("Headline", true, false) as Label
	var outcome_summary := screen.find_child("OutcomeSummary", true, false) as BoxContainer
	var outcome_meta := screen.find_child("OutcomeMeta", true, false) as BoxContainer
	var eyebrow := screen.find_child("OutcomeEyebrow", true, false)
	var stage_title := screen.find_child("StageTitle", true, false)
	var stars := screen.find_child("ResultStars", true, false) as HBoxContainer
	var tally := screen.find_child("TallyLine", true, false) as Label
	var reward := screen.find_child("Reward0", true, false) as Control
	var entitlement := screen.find_child("Entitlement0", true, false) as Control
	var xp := screen.find_child("XpAward0", true, false) as Control
	var second_xp := screen.find_child("XpAward1", true, false) as Control
	var reward_count: Label = reward.find_child("Title", true, false) as Label if reward != null else null
	var reward_icon := reward.find_child("ResonanceShardIcon", true, false) as TextureRect if reward != null else null
	var reward_display := reward_icon.get_parent() as Control if reward_icon != null else null
	var xp_count: Label = xp.find_child("Detail", true, false) as Label if xp != null else null
	var second_xp_count: Label = second_xp.find_child("Detail", true, false) as Label if second_xp != null else null
	var no_casualties := screen.find_child("NoCasualties", true, false) as PanelContainer
	var transmission := screen.find_child("ClearTransmission", true, false) as PanelContainer
	var transmission_speaker := screen.find_child("TransmissionSpeaker", true, false) as Label
	var transmission_body := screen.find_child("TransmissionBody", true, false) as Label
	var rewards_panel := screen.find_child("RewardsPanel", true, false) as PanelContainer
	var consequence_panel := screen.find_child("ConsequencePanel", true, false) as PanelContainer
	var rewards_scroll := screen.find_child("RewardsScroll", true, false) as ScrollContainer
	var consequence_scroll := screen.find_child("ConsequenceScroll", true, false) as ScrollContainer
	var rewards_heading := screen.find_child("RewardsHeading", true, false) as Label
	var consequence_heading := screen.find_child("ConsequenceHeading", true, false) as Label
	var consequence_line := screen.find_child("ConsequenceLine", true, false) as Label
	var header := screen.find_child("ResultsHeader", true, false) as GridContainer
	var body := screen.find_child("ResultsBody", true, false) as GridContainer
	var actions := screen.find_child("ActionRow", true, false) as GridContainer
	var staging := screen.find_child("ReturnToStaging", true, false) as Button
	var title := screen.find_child("BackToTitle", true, false) as Button
	_check(shell != null and bool(shell.get("full_safe_area")), "Results did not opt into full-safe-area shell")
	_check(ceremony != null and ceremony.custom_minimum_size.y >= 132.0, "Results outcome ceremony is still claustrophobic")
	_check(headline != null and headline.text == "STAGE 1 CLEARED", "stage-number clear headline is incorrect")
	_check(headline != null and headline.get_theme_font_size(&"font_size") >= 40 and headline.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "Results outcome headline is not dominant or vertically centered")
	_check(eyebrow == null and stage_title == null, "obsolete result eyebrow or stage title remains")
	_check(outcome_summary != null and outcome_meta != null and headline.get_parent() == outcome_summary and outcome_meta.get_parent() == outcome_summary and stars.get_parent() == outcome_meta, "headline and result metadata are not grouped")
	_check(stars != null and stars.get_child_count() == 3 and stars.alignment == BoxContainer.ALIGNMENT_BEGIN, "native result stars are missing or not left flushed")
	_check(tally != null and tally.get_theme_font_size(&"font_size") >= 28 and tally.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "result tally is not enlarged and right aligned")
	_check(reward != null and entitlement != null and xp != null and second_xp != null, "typed result payload cards are incomplete")
	_check(reward is MarginContainer and entitlement is MarginContainer and xp is MarginContainer and second_xp is MarginContainer, "Mission Yield rows retained inner panel styling")
	_check(reward_count != null and reward_icon != null and reward_icon.texture != null and int(reward_count.get_meta(&"reward_reveal_count", -1)) == 40, "Shard reward was not registered with its icon for count reveal")
	_check(reward_display != null and reward_display.tooltip_text.contains("premium energy") and reward_display.accessibility_description.contains("Premium Resonance"), "Shard reward lacks its explanatory tooltip")
	_check(reward_count != null and int(reward_count.get_meta(&"reward_reveal_order", -1)) == 0, "Shard reward is not first in the reveal sequence")
	_check(xp_count != null and int(xp_count.get_meta(&"reward_reveal_count", -1)) == 100, "first survivor XP reward did not use the canonical delta")
	_check(xp_count != null and int(xp_count.get_meta(&"reward_reveal_order", -1)) == 1, "XP reward is not staggered after the shard reward")
	_check(second_xp_count != null and int(second_xp_count.get_meta(&"reward_reveal_count", -1)) == 100, "second survivor XP reward did not use the canonical delta")
	_check(second_xp_count != null and int(second_xp_count.get_meta(&"reward_reveal_order", -1)) == 2, "second survivor XP reward is not staggered after the first")
	_check(
		xp_count != null
		and float(xp_count.get_meta(&"reward_reveal_stagger_seconds", 0.0)) > float(reward_count.get_meta(&"reward_reveal_stagger_seconds", 0.0)),
		"Mission Yield counters do not have increasing stagger delays",
	)
	await create_timer(0.9).timeout
	_check(reward_count.text == "+40" and bool(reward_count.get_meta(&"reward_reveal_complete", false)), "Shard counter did not finish at its authoritative value")
	_check(xp_count.text == "+100 XP" and bool(xp_count.get_meta(&"reward_reveal_complete", false)), "first survivor XP counter did not finish at its authoritative value")
	_check(second_xp_count.text == "+100 XP" and bool(second_xp_count.get_meta(&"reward_reveal_complete", false)), "second survivor XP counter did not finish at its authoritative value")
	_check(reward_count.modulate.a == 1.0 and reward_count.scale == Vector2.ONE, "Shard reveal did not settle cleanly")
	_check(xp_count.modulate.a == 1.0 and xp_count.scale == Vector2.ONE, "XP reveal did not settle cleanly")
	for row: Control in [reward, entitlement, xp, second_xp]:
		if row != null:
			var row_title := row.find_child("Title", true, false) as Label
			var row_detail := row.find_child("Detail", true, false) as Label
			_check(row_title != null and row_title.get_theme_font_size(&"font_size") >= 24, "%s title was not enlarged" % row.name)
			_check(row_detail != null and row_detail.get_theme_font_size(&"font_size") >= 20, "%s detail was not enlarged" % row.name)
	_check(no_casualties != null, "no-casualty state is missing")
	_check(transmission != null, "clear result omitted its canon transmission")
	_check(transmission_speaker != null and transmission_speaker.text == "ARCHIVE CASTER", "clear transmission speaker is incorrect")
	_check(transmission_body != null and transmission_body.text.contains("PROTOS"), "clear transmission body is not canonical")
	_check(transmission_speaker != null and transmission_speaker.get_theme_font_size(&"font_size") >= 24, "clear transmission speaker was not enlarged")
	_check(transmission_body != null and transmission_body.get_theme_font_size(&"font_size") >= 20, "clear transmission body is below 20px")
	_check(rewards_heading != null and rewards_heading.get_theme_font_size(&"font_size") >= 30, "Mission Yield heading was not enlarged")
	_check(consequence_heading != null and consequence_heading.get_theme_font_size(&"font_size") >= 30, "Consequence heading was not enlarged")
	_check(consequence_line != null and consequence_line.get_theme_font_size(&"font_size") >= 20, "Consequence body was not enlarged")
	if rewards_panel != null:
		var rewards_style := rewards_panel.get_theme_stylebox(&"panel")
		_check(rewards_style.content_margin_left >= 30.0 and rewards_style.content_margin_top >= 26.0, "Mission Yield content margins are too small")
	if consequence_panel != null:
		var consequence_style := consequence_panel.get_theme_stylebox(&"panel")
		_check(consequence_style.content_margin_left >= 30.0 and consequence_style.content_margin_top >= 26.0 and consequence_style.content_margin_right >= 30.0, "Consequence content margins are too small")
	_check(rewards_scroll != null and consequence_scroll != null, "Results payload columns lack independent local scrolling")
	_check(rewards_scroll != null and rewards_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Rewards scroll is not flexible")
	_check(consequence_scroll != null and consequence_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Consequence scroll is not flexible")
	_check(actions != null and staging != null and title != null, "persistent Results actions are incomplete")
	_check(actions != null and not _has_scroll_ancestor(actions), "Results actions remain buried inside scroll content")
	if actions != null:
		for child: Node in actions.get_children():
			if child is Button:
				var action := child as Button
				var presentation := action.find_child("PresentationLabel", true, false) as Label
				_check(action.custom_minimum_size == Vector2(260, 96), "%s is not fixed at 260×96" % action.name)
				_check(action.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "%s still expands horizontally" % action.name)
				_check(action.get_theme_stylebox(&"normal") is StyleBoxFlat, "%s retained a struck texture frame" % action.name)
				_check(presentation != null and presentation.get_theme_font_size(&"font_size") >= 36, "%s typography was not doubled" % action.name)
				var action_style := action.get_theme_stylebox(&"normal")
				_check(action_style.content_margin_top >= 18.0 and action_style.content_margin_bottom >= 18.0, "%s lacks vertical inner padding" % action.name)

	_check(header != null and header.columns == 1 and body != null and body.columns == 2, "regular landscape Results hierarchy changed")
	root.size = Vector2i(1024, 576)
	await _frames(2)
	_check(header.columns == 1 and body.columns == 2 and actions.columns == 2, "compact landscape Results layout did not reflow")
	root.size = Vector2i(390, 844)
	await _frames(2)
	_check(header.columns == 1 and body.columns == 1 and actions.columns == 1, "portrait Results layout did not stack")
	_check(outcome_summary.vertical, "portrait outcome summary did not stack")
	_check(outcome_meta.vertical, "portrait stars and tally did not stack beneath the headline")
	for child: Node in actions.get_children():
		if child is Button:
			var bounds := (child as Button).get_global_rect()
			_check(bounds.position.x >= -0.5 and bounds.end.x <= 390.5, "%s overflows portrait width" % child.name)
	root.size = Vector2i(1280, 720)
	await _frames(2)
	root.remove_child(screen)
	screen.free()
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	game.set("last_result", {
		"stage_id": &"s1",
		"result": BattleModel.Result.DEFEAT,
		"stars": 0,
		"kills": 4,
		"leaks": 12,
		"rewards_granted": [{"kind": "currency", "id": "marks", "amount": 7}],
		"class_entitlements_granted": [],
		"xp_awards": [{"hero_id": hero_id, "delta": 100}],
		"dead_hero_ids": [],
		"premium_life_losses": [],
	})
	var defeat_screen: Node = load("res://scenes/results.tscn").instantiate()
	root.add_child(defeat_screen)
	await _frames(2)
	var defeat_ceremony := defeat_screen.find_child("OutcomeCeremony", true, false) as PanelContainer
	var defeat_headline := defeat_screen.find_child("Headline", true, false) as Label
	var defeat_summary := defeat_screen.find_child("OutcomeSummary", true, false) as BoxContainer
	var defeat_meta := defeat_screen.find_child("OutcomeMeta", true, false) as BoxContainer
	var defeat_stars := defeat_screen.find_child("ResultStars", true, false) as HBoxContainer
	var defeat_tally := defeat_screen.find_child("TallyLine", true, false) as Label
	var defeat_rewards := defeat_screen.find_child("RewardsPanel", true, false) as PanelContainer
	var defeat_consequence := defeat_screen.find_child("ConsequencePanel", true, false) as PanelContainer
	var defeat_reward := defeat_screen.find_child("Reward0", true, false) as Control
	var defeat_xp := defeat_screen.find_child("XpAward0", true, false) as Control
	var defeat_reward_count: Label = defeat_reward.find_child("Title", true, false) as Label if defeat_reward != null else null
	var defeat_xp_count: Label = defeat_xp.find_child("Detail", true, false) as Label if defeat_xp != null else null
	var defeat_rewards_heading := defeat_screen.find_child("RewardsHeading", true, false) as Label
	var defeat_consequence_heading := defeat_screen.find_child("ConsequenceHeading", true, false) as Label
	var defeat_consequence_line := defeat_screen.find_child("ConsequenceLine", true, false) as Label
	var defeat_actions := defeat_screen.find_child("ActionRow", true, false) as GridContainer
	var defeat_company_intact := defeat_screen.find_child("NoCasualties", true, false) as PanelContainer
	var defeat_command := defeat_screen.find_child("ReturnToStaging", true, false) as Button
	_check(defeat_ceremony != null and defeat_ceremony.custom_minimum_size.y >= 132.0, "defeat ceremony did not inherit the taller hierarchy")
	_check(defeat_ceremony != null and defeat_ceremony.get_theme_stylebox(&"panel") is StyleBoxEmpty, "defeat header parent retained a background or border")
	_check(defeat_headline != null and defeat_headline.text == "STAGE 1 DEFEATED", "stage-number defeat headline is incorrect")
	_check(defeat_headline.get_theme_font_size(&"font_size") >= 40 and defeat_headline.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "defeat headline is not dominant and centered")
	_check(defeat_summary != null and defeat_meta != null and defeat_headline.get_parent() == defeat_summary and defeat_meta.get_parent() == defeat_summary, "defeat headline and metadata do not match clear hierarchy")
	_check(defeat_stars != null and defeat_stars.get_parent() == defeat_meta and defeat_stars.alignment == BoxContainer.ALIGNMENT_BEGIN, "defeat stars are not adjacent and left flushed")
	for star: Node in defeat_stars.get_children():
		var art := star.find_child("AstralStarArt", true, false) as TextureRect
		_check(art != null and art.self_modulate.a <= 0.25, "%s is incorrectly lit on defeat" % star.name)
	_check(defeat_tally != null and defeat_tally.get_theme_font_size(&"font_size") >= 28 and defeat_tally.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "defeat tally does not match clear hierarchy")
	_check(defeat_rewards_heading != null and defeat_rewards_heading.get_theme_font_size(&"font_size") >= 30, "defeat Mission Yield heading is too small")
	_check(defeat_consequence_heading != null and defeat_consequence_heading.get_theme_font_size(&"font_size") >= 30, "defeat Consequence heading is too small")
	_check(defeat_consequence_line != null and defeat_consequence_line.get_theme_font_size(&"font_size") >= 20, "defeat consequence copy is too small")
	_check(defeat_rewards != null and defeat_rewards.get_theme_stylebox(&"panel") is StyleBoxTexture, "defeat Mission Yield did not inherit the clear result frame")
	_check(defeat_consequence != null and defeat_consequence.get_theme_stylebox(&"panel") is StyleBoxFlat, "defeat consequence surface is not danger styled")
	if defeat_rewards != null:
		var defeat_rewards_style := defeat_rewards.get_theme_stylebox(&"panel")
		_check(defeat_rewards_style.content_margin_left >= 48.0 and defeat_rewards_style.content_margin_right >= 48.0 and defeat_rewards_style.content_margin_top >= 24.0 and defeat_rewards_style.content_margin_bottom >= 24.0, "defeat Mission Yield lacks 48px horizontal / 24px vertical padding")
	_check(defeat_company_intact != null, "defeat Company Intact state is missing")
	if defeat_company_intact != null:
		var intact_style := defeat_company_intact.get_theme_stylebox(&"panel")
		_check(intact_style.content_margin_left >= 48.0 and intact_style.content_margin_right >= 48.0 and intact_style.content_margin_top >= 24.0 and intact_style.content_margin_bottom >= 24.0, "defeat Company Intact lacks 48px horizontal / 24px vertical padding")
	_check(defeat_reward is MarginContainer and defeat_xp is MarginContainer, "defeat Mission Yield rows regained inner frames")
	var defeat_reward_icon := defeat_reward.find_child("ResonanceShardIcon", true, false) as TextureRect if defeat_reward != null else null
	_check(defeat_reward_count.text == "+7" and defeat_reward_icon != null and bool(defeat_reward_count.get_meta(&"reward_reveal_complete", false)), "reduced motion did not complete defeat shard reward immediately")
	_check(defeat_xp_count.text == "+100 XP" and bool(defeat_xp_count.get_meta(&"reward_reveal_complete", false)), "reduced motion did not project the canonical defeat survivor XP immediately")
	_check(defeat_screen.find_child("ClearTransmission", true, false) == null, "defeat incorrectly presents a clear transmission")
	for child: Node in defeat_actions.get_children():
		if child is Button:
			var defeat_action := child as Button
			var presentation := defeat_action.find_child("PresentationLabel", true, false) as Label
			var expected_width := 400.0 if defeat_action.name == "ReturnToStaging" else 260.0
			_check(defeat_action.custom_minimum_size == Vector2(expected_width, 96), "%s lost fixed defeat sizing" % defeat_action.name)
			_check(defeat_action.get_theme_stylebox(&"normal") is StyleBoxFlat, "%s regained struck defeat styling" % defeat_action.name)
			_check(presentation != null and presentation.get_theme_font_size(&"font_size") >= 36, "%s defeat text is not doubled" % defeat_action.name)
	_check(defeat_command != null and defeat_command.get_combined_minimum_size().x <= defeat_command.size.x + 1.0, "defeat Command text overflows its wider action")
	_check(defeat_command != null and bool(defeat_command.get_meta(&"action_hover_feedback_wired", false)), "defeat Command lacks shared hover feedback")
	if defeat_command != null:
		var command_normal := defeat_command.get_theme_stylebox(&"normal") as StyleBoxFlat
		var command_hover := defeat_command.get_theme_stylebox(&"hover") as StyleBoxFlat
		_check(command_normal != null and command_hover != null and not command_normal.bg_color.is_equal_approx(command_hover.bg_color), "defeat Command lacks a distinct hover surface")
		ProjectSettings.set_setting("accessibility/reduced_motion", false)
		var command_idle_tint := defeat_command.modulate
		defeat_command.emit_signal(&"mouse_entered")
		await create_timer(0.22).timeout
		_check(defeat_command.scale.x >= 1.035 and defeat_command.scale.y >= 1.035, "defeat Command does not lift on hover")
		_check(not defeat_command.modulate.is_equal_approx(command_idle_tint), "defeat Command lacks hover luminance feedback")
		defeat_command.emit_signal(&"mouse_exited")
		await create_timer(0.22).timeout
		_check(defeat_command.scale.distance_to(Vector2.ONE) < 0.02, "defeat Command did not settle after hover")
		ProjectSettings.set_setting("accessibility/reduced_motion", true)
	root.size = Vector2i(390, 844)
	await _frames(2)
	_check(defeat_summary.vertical and defeat_meta.vertical and defeat_actions.columns == 1, "defeat hierarchy does not stack in portrait")
	var defeat_command_presentation := defeat_command.find_child("PresentationLabel", true, false) as Label
	_check(defeat_command.custom_minimum_size.x == 320.0, "defeat Command did not retain its wider portrait target")
	_check(defeat_command_presentation != null and defeat_command_presentation.autowrap_mode == TextServer.AUTOWRAP_OFF, "defeat Command still permits copy wrapping")
	_check(defeat_command_presentation != null and defeat_command_presentation.get_theme_font_size(&"font_size") >= 48, "defeat Command portrait typography was not fitted")
	for child: Node in defeat_actions.get_children():
		if child is Button:
			var bounds := (child as Button).get_global_rect()
			_check(bounds.position.x >= -0.5 and bounds.end.x <= 390.5, "%s overflows defeat portrait width" % child.name)
	root.size = Vector2i(1280, 720)
	await _frames(2)

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	defeat_screen.call("_unhandled_input", cancel)
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
	ProjectSettings.set_setting("accessibility/reduced_motion", previous_reduced_motion)
	await create_timer(0.25).timeout
	_finish()


func _has_scroll_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


func _frames(count: int) -> void:
	for _index: int in count:
		await process_frame


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
