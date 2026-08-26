extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "Training readability fixture failed")
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame

	var outer := screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	var page := screen.find_child("TrainingPage", true, false) as VBoxContainer
	var body := screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	var roster_scroll := screen.find_child("TrainingRosterScroll", true, false) as ScrollContainer
	var inspector := screen.find_child("TrainingInspector", true, false) as PanelContainer
	var inspector_scroll := screen.find_child("TrainingInspectorScroll", true, false) as ScrollContainer
	var roster_controls := screen.find_child("TrainingRosterControls", true, false) as BoxContainer
	var filters := screen.find_child("RosterFilterControls", true, false) as BoxContainer
	var filter_summary := screen.find_child("TrainingFilterSummary", true, false) as Label
	var ready := screen.find_child("PromotionReadyCount", true, false) as Label
	_check(outer != null and page != null and body != null, "Training workspace is incomplete")
	_check(roster_scroll != null and inspector != null and inspector_scroll != null, "Training local panels are incomplete")
	_check(roster_controls != null and filters != null and ready != null, "Training header/filter composition is incomplete")
	if outer != null:
		_check(outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "desktop Training still uses document scrolling")
	if page != null and outer != null:
		_check(page.size.y >= outer.size.y - 12.0, "Training page does not fill the available document viewport")
	if body != null:
		_check(not body.vertical, "desktop Training roster/inspector should remain side by side")
		_check(body.size.y >= 260.0, "desktop Training left dead space instead of expanding the roster/inspector")
		_check(_contained(body.get_global_rect(), page.get_global_rect(), 1.0), "desktop Training body overflows its page")
	if roster_scroll != null and inspector != null:
		_check(roster_scroll.size.y >= 260.0 and inspector.size.y >= 260.0, "Training panels did not consume recovered vertical space")
		_check(roster_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Training roster can scroll horizontally")
	if inspector_scroll != null:
		_check(inspector_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Training inspector does not expand vertically")
	if filters != null:
		_check(not filters.vertical and filters.size.y <= 64.0, "desktop Training filters still consume two rows")
	if roster_controls != null:
		_check(not roster_controls.vertical and roster_controls.size.y <= 64.0, "desktop Training filters and identity tools are not consolidated")
	_check(filter_summary != null and not filter_summary.visible, "redundant desktop shown-count still consumes toolbar width")
	if ready != null:
		_check(ready.get_parent() != null and String(ready.get_parent().name).ends_with("Top"), "promotion-ready metric still occupies a separate desktop band")
		_check(ready.autowrap_mode == TextServer.AUTOWRAP_OFF, "promotion-ready metric can wrap vertically")

	_check(_font(screen, "TrainingTitleHeading") >= 40, "Training title is below 40px")
	_check(_font(screen, "TrainingTitleSubtitle") >= 17, "Training subtitle is below 17px")
	_check(_font(screen, "PromotionReadyCount") >= 22, "Training ready metric is below 22px")
	_check(_font(screen, "Callsign") >= 19, "Training roster callsign is below 19px")
	_check(_font(screen, "CurrentClass") >= 16, "Training roster class is below 16px")
	_check(_font(screen, "RenameUnitHeading") >= 24, "Training inspector heading is below 24px")
	_check(_font(screen, "RenameUnitGuidance") >= 16, "Training guidance is below 16px")
	_check(_font(screen, "CallsignFieldLabel") >= 16, "Training field label is below 16px")
	var rename := screen.find_child("RenameUnitInput", true, false) as LineEdit
	_check(rename != null and rename.get_theme_font_size("font_size") >= 20, "Training identity input is below 20px")
	var row_margin := screen.find_child("RosterRowMargin", true, false) as MarginContainer
	_check(row_margin != null and row_margin.get_theme_constant("margin_left") >= 16, "Training roster row padding is under 16px")
	if inspector != null:
		var style: StyleBox = inspector.get_theme_stylebox("panel")
		_check(style.content_margin_left >= 22.0 and style.content_margin_right >= 22.0, "Training inspector horizontal padding is under 22px")
		_check(style.content_margin_top >= 22.0 and style.content_margin_bottom >= 22.0, "Training inspector vertical padding is under 22px")
	var roster_detail := screen.find_child("EligibilityReason", true, false) as Label
	_check(roster_detail != null and roster_detail.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "Training roster metadata can be clipped with ellipsis")
	var roster_row := screen.find_child("Recruit_*", true, false) as Control
	_check(roster_row != null, "Training roster did not render a hoverable operator row")
	if roster_row != null:
		_check(_has_detailed_stats(roster_row.tooltip_text), "Training roster tooltip omits detailed combat statistics")
	if inspector != null:
		_check(_has_detailed_stats(inspector.tooltip_text), "Training inspector tooltip omits detailed combat statistics")

	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	await process_frame
	outer = screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
	page = screen.find_child("TrainingPage", true, false) as VBoxContainer
	body = screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	filters = screen.find_child("RosterFilterControls", true, false) as BoxContainer
	roster_controls = screen.find_child("TrainingRosterControls", true, false) as BoxContainer
	filter_summary = screen.find_child("TrainingFilterSummary", true, false) as Label
	var dock := screen.find_child("TrainingActionDock", true, false) as VBoxContainer
	var actions := screen.find_child("RosterActions", true, false) as BoxContainer
	_check(outer != null and outer.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "standard portrait Training still uses document scrolling")
	_check(body != null and body.vertical, "portrait Training roster/inspector did not stack")
	_check(filters != null and filters.vertical, "portrait Training filters did not stack")
	_check(roster_controls != null and roster_controls.vertical, "portrait Training control groups did not stack")
	_check(filter_summary != null and filter_summary.visible, "portrait Training shown-count is missing")
	_check(dock != null and actions != null and actions.vertical, "portrait Training actions did not stack in the fixed dock")
	if page != null and outer != null:
		_check(_contained(page.get_global_rect(), outer.get_global_rect(), 1.0), "portrait Training page overflows the fixed document viewport")
	if dock != null:
		_check(dock.get_global_rect().end.y <= 1280.0, "portrait Training action dock overflows the viewport")

	_dispose(screen)
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	root.size = Vector2i(1280, 720)
	await create_timer(0.1).timeout
	_finish()


func _font(screen: Node, node_name: String) -> int:
	var label := screen.find_child(node_name, true, false) as Label
	return label.get_theme_font_size("font_size") if label != null else 0


func _contained(inner: Rect2, outer: Rect2, tolerance: float) -> bool:
	return (
		inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance
	)


func _has_detailed_stats(value: String) -> bool:
	return (
		value.contains("HP ")
		and value.contains("ATK ")
		and value.contains("DEF ")
		and value.contains(" DP ")
		and value.contains("Block ")
		and value.contains("Skill:")
	)


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
		print("TRAINING_READABILITY_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("Training readability test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
