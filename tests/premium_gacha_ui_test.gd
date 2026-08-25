extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
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
		for premium_id: String in ["archive_caster", "lunaris_vessel", "reliquary_duelist"]:
			var card := grid.get_node_or_null("Premium_%s" % premium_id)
			_check(card != null, "missing premium card %s" % premium_id)
			if card != null:
				var portrait := card.find_child("Portrait", true, false) as TextureRect
				_check(portrait != null and portrait.texture != null, "missing portrait %s" % premium_id)

	var before_cancel: Dictionary = game.get("campaign").runtime_projection()
	pull.pressed.emit()
	await process_frame
	var confirmation := screen.find_child("PullConfirmationLayer", true, false) as Control
	var confirm_pull := screen.find_child("ConfirmPremiumPull", true, false) as Button
	var cancel_pull := screen.find_child("CancelPremiumPull", true, false) as Button
	_check(confirmation != null and confirmation.visible, "pull confirmation did not open")
	_check(confirm_pull != null and cancel_pull != null, "pull confirmation actions are missing")
	_check(game.get("campaign").runtime_projection() == before_cancel, "opening confirmation mutated campaign state")
	if cancel_pull != null:
		cancel_pull.pressed.emit()
	await process_frame
	_check(confirmation != null and not confirmation.visible, "cancel did not close pull confirmation")
	_check(game.get("campaign").runtime_projection() == before_cancel, "cancel mutated campaign state")

	pull.pressed.emit()
	await process_frame
	_check(confirmation != null and confirmation.visible, "pull confirmation did not reopen after cancel")
	if confirm_pull != null:
		confirm_pull.pressed.emit()
	await process_frame
	var after_confirm: Dictionary = game.get("campaign").runtime_projection()
	_check(
		int(after_confirm["marks"]) == int(before_cancel["marks"]) - 40,
		"Confirm did not charge the authoritative pull cost; status=%s" % (screen.find_child("PullStatusLabel", true, false) as Label).text,
	)
	var committed_reveal := screen.find_child("PullRevealLayer", true, false) as Control
	_check(committed_reveal != null and committed_reveal.visible, "accepted Confirm did not begin receipt reveal")
	screen.call("_finish_reveal")
	await process_frame

	var five_star := _sample_pull(5, true)
	screen.call("_begin_reveal", five_star)
	await process_frame
	var reveal_layer := screen.find_child("PullRevealLayer", true, false) as Control
	var reveal_title := screen.find_child("RevealTitle", true, false) as Label
	var reveal_result := screen.find_child("RevealResult", true, false) as Label
	var skip := screen.find_child("SkipRevealButton", true, false) as Button
	_check(reveal_layer != null and reveal_layer.visible, "five-star reveal layer did not open")
	_check(pull.disabled and back.disabled, "reveal did not lock pull and back actions")
	_check(reveal_title != null and reveal_title.text == "5-STAR RESONANCE", "five-star title is incorrect")
	_check(reveal_result != null and reveal_result.text.contains("NEW HERO"), "reveal result kind is missing")
	_check(skip != null and skip.visible and not skip.disabled, "skip action is unavailable")
	screen.call("_finish_reveal")
	await process_frame
	_check(not reveal_layer.visible, "skipped reveal layer remained visible")
	_check(not pull.disabled and not back.disabled, "skip did not restore navigation input")
	var status := screen.find_child("PullStatusLabel", true, false) as Label
	_check(status != null and status.text.contains("5-STAR SIGNAL"), "skip did not apply final result copy")

	screen.set("reduced_motion", true)
	var four_star := _sample_pull(4, false)
	screen.call("_begin_reveal", four_star)
	await process_frame
	var portrait := screen.find_child("RevealPortrait", true, false) as TextureRect
	_check(reveal_layer.visible, "reduced-motion reveal did not open")
	_check(portrait != null and is_equal_approx(portrait.modulate.a, 1.0), "reduced motion did not settle instantly")
	screen.call("_finish_reveal")
	await process_frame
	_check(not reveal_layer.visible, "reduced-motion reveal did not finalize")

	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var parent := screen.get_parent()
	if parent != null:
		parent.remove_child(screen)
	screen.free()
	var music := root.get_node_or_null("Music")
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
