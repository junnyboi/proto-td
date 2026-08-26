extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null and i18n != null, "confirmation fixture autoloads missing")
	if game == null or i18n == null:
		_finish()
		return
	game.call("set_run_seed", 4702)
	_check(bool(game.call("start_campaign", false, true)), "confirmation campaign fixture failed")
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	root.size = Vector2i(1280, 720)
	var screen := load("res://scenes/gacha.tscn").instantiate() as Control
	root.add_child(screen)
	await _frames(4)
	screen.call("_build_pull_confirmation")
	var campaign: Variant = game.get("campaign")
	screen.set("_confirmation_projection", campaign.runtime_projection())
	screen.call("_refresh_confirmation_copy")
	screen.call("_refresh_confirmation_accessibility")
	var layer := screen.find_child("PremiumPullConfirmationLayer", true, false) as Control
	layer.visible = true
	layer.modulate = Color.WHITE
	screen.call("_apply_confirmation_layout", Vector2(root.size))
	await _frames(4)
	_verify_layout(screen, false)

	root.size = Vector2i(720, 1280)
	await _frames(4)
	screen.call("_apply_confirmation_layout", Vector2(root.size))
	await _frames(4)
	_verify_layout(screen, true)

	game.set("content", null)
	_dispose(screen)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	root.size = Vector2i(1280, 720)
	i18n.call("set_locale", &"en-US")
	await _frames(3)
	_finish()


func _verify_layout(screen: Control, portrait: bool) -> void:
	var context_panel := screen.find_child("ConfirmationContextPanel", true, false) as PanelContainer
	var transaction_panel := screen.find_child("ConfirmationTransactionPanel", true, false) as PanelContainer
	var context_copy := screen.find_child("ConfirmationContextCopy", true, false) as Label
	var transaction_copy := screen.find_child("ConfirmationTransactionCopy", true, false) as Label
	var context_eyebrow := screen.find_child("ConfirmationContextEyebrow", true, false) as Label
	var review_eyebrow := screen.find_child("ConfirmationReviewEyebrow", true, false) as Label
	var actions := screen.find_child("ConfirmationActions", true, false) as GridContainer
	var cancel := screen.find_child("CancelPremiumPullDock", true, false) as Button
	var confirm := screen.find_child("ConfirmPremiumPull", true, false) as Button
	_check(context_panel != null and transaction_panel != null, "confirmation cards missing")
	_check(context_copy != null and transaction_copy != null, "confirmation copy missing")
	_check(context_eyebrow != null and not context_eyebrow.visible, "redundant reliquary eyebrow remains")
	_check(review_eyebrow != null and not review_eyebrow.visible, "redundant guarantee eyebrow remains")
	for panel: PanelContainer in [context_panel, transaction_panel]:
		if panel == null:
			continue
		var style := panel.get_theme_stylebox(&"panel")
		_check(panel.custom_minimum_size.y >= 264.0, "%s is too short for doubled Chinese copy" % panel.name)
		_check(style.content_margin_bottom >= 36.0, "%s lacks safe bottom padding" % panel.name)
	for pair: Array in [[context_panel, context_copy], [transaction_panel, transaction_copy]]:
		var panel := pair[0] as PanelContainer
		var label := pair[1] as Label
		if panel != null and label != null:
			var panel_style := panel.get_theme_stylebox(&"panel")
			_check(
				label.get_global_rect().end.y <= panel.get_global_rect().end.y - panel_style.content_margin_bottom + 1.0,
				"%s enters its lower frame ornament" % label.name,
			)
			_check(label.get_visible_line_count() == label.get_line_count(), "%s clips wrapped Chinese lines" % label.name)
	_check(cancel != null and confirm != null and actions != null, "confirmation action dock incomplete")
	if cancel != null and confirm != null:
		_check(cancel.custom_minimum_size == Vector2(280, 92), "Cancel lost standard action size")
		_check(confirm.custom_minimum_size == Vector2(280, 92), "Start Resonance lost standard action size")
		_check(not cancel.clip_text and not confirm.clip_text, "confirmation action clips translated text")
		_check(cancel.get_theme_stylebox(&"normal") is StyleBoxFlat, "Cancel restored ornate texture")
		_check(confirm.get_theme_stylebox(&"normal") is StyleBoxFlat, "Start Resonance restored ornate texture")
	if actions != null:
		_check(actions.columns == (1 if portrait else 2), "confirmation action breakpoint is wrong")
		_check(actions.size_flags_horizontal == Control.SIZE_SHRINK_END, "confirmation actions are not right aligned")


func _frames(count: int) -> void:
	for _frame: int in count:
		await process_frame


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
	if _failures.is_empty():
		print("CHINESE_CONFIRMATION_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
