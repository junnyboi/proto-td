extends SceneTree

const TEST_TIMEOUT_SECONDS := 25.0

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null and i18n != null, "Training Chinese fixture autoloads are missing")
	if game == null or i18n == null:
		_finish()
		return
	game.call("set_run_seed", 4702)
	_check(bool(game.call("start_campaign", false, true)), "Training Chinese fixture failed")
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame

	_check(String(screen.accessibility_name) == "训练工作区", "Training root name did not resolve to Chinese")
	_check(String(screen.accessibility_description) == "管理干员身份和进阶训练路线。", "Training root description did not resolve to Chinese")
	var workspace := screen.find_child("TrainingWorkspace", true, false) as Control
	var header := screen.find_child("TrainingPersistentHeader", true, false) as Control
	var dock := screen.find_child("TrainingActionDock", true, false) as Control
	_check(workspace != null and String(workspace.accessibility_name) == "训练内容", "Training workspace landmark is not Chinese")
	_check(header != null and String(header.accessibility_name) == "训练标题", "Training header landmark is not Chinese")
	_check(dock != null and String(dock.accessibility_name) == "训练操作", "Training action landmark is not Chinese")

	var promotion_tab := screen.find_child("PromotionReadyRosterTab", true, false) as Button
	var edit_identity := screen.find_child("EditIdentity", true, false) as Button
	var initial_callsign := screen.find_child("RenameUnitInput", true, false) as LineEdit
	_check(promotion_tab != null and promotion_tab.text.contains("可晋升"), "Promotion Ready filter is not Chinese")
	_check(String(screen.call("_t", &"ui.training.choose_promotion", "Choose Promotion")) == "选择晋升", "Choose Promotion copy is not Chinese")
	_check(String(screen.call("_t", &"ui.training.promote", "Promote")) == "晋升", "immediate Promote copy is not Chinese")
	_check(screen.find_child("ViewPaths", true, false) == null, "obsolete View Paths action remains in Chinese Training")
	_check(screen.find_child("ReviewPlan", true, false) == null, "removed Review Plan action remains in Chinese Training")
	_check(edit_identity != null and edit_identity.text == "编辑", "Edit Identity action is not Chinese")
	_check(initial_callsign != null and not initial_callsign.is_visible_in_tree(), "Chinese identity editor is visible before Edit Identity")
	if edit_identity != null:
		edit_identity.pressed.emit()
		await process_frame
		await process_frame
	var callsign := screen.find_child("RenameUnitInput", true, false) as LineEdit
	var title := screen.find_child("RenameTitleInput", true, false) as LineEdit
	_check(callsign != null and callsign.is_visible_in_tree(), "Chinese Edit Identity did not reveal the inputs")
	_check(callsign != null and callsign.max_length == 20, "callsign input constraint changed")
	_check(title != null and title.max_length == 24, "title input constraint changed")
	_check(callsign != null and String(callsign.accessibility_description) == "输入1至20个字符的唯一代号。", "callsign guidance is not Chinese")
	_check(title != null and String(title.accessibility_description) == "称号可选，最多24个字符。", "title guidance is not Chinese")
	if callsign != null:
		callsign.grab_focus()
		await process_frame
		_check(callsign.has_focus(), "callsign focus fixture failed")
		_check(bool(i18n.call("set_locale", &"en-US")), "English locale switch failed")
		await process_frame
		callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
		_check(callsign != null and callsign.has_focus(), "locale refresh did not preserve rename focus")
		_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale restoration failed")
		await process_frame
		callsign = screen.find_child("RenameUnitInput", true, false) as LineEdit
		_check(callsign != null and String(callsign.accessibility_description) == "输入1至20个字符的唯一代号。", "dynamic callsign metadata did not refresh")

	var row := screen.find_child("Recruit_*", true, false) as Control
	var inspector := screen.find_child("TrainingInspector", true, false) as Control
	_check(row != null and _localized_tooltip(row.tooltip_text), "Chinese roster tooltip is not fully localized")
	_check(inspector != null and _localized_tooltip(inspector.tooltip_text), "Chinese inspector tooltip is not fully localized")
	var permanence := screen.find_child("PermanenceNote", true, false) as Label
	_check(permanence != null and permanence.text == "此训练选择无法更改。", "inspector permanence guidance is not localized")

	var premium := {
		"life_status": "ready", "is_premium": true, "premium_lives": 2,
	}
	_check(String(screen.call("_status_text", premium)) == "高级英雄就绪", "premium ready status is not localized")
	_check(String(screen.call("_progress_text", premium)) == "固定配置 • 2具准备好的身体", "premium progress does not explain prepared recovery bodies in Chinese")

	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	var body := screen.find_child("TrainingRosterBody", true, false) as BoxContainer
	_check(body != null and body.vertical, "Chinese portrait Training did not retain responsive stacking")
	for node: Node in screen.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.visible and label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			_check(label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "%s may trim wrapped Chinese copy" % label.name)

	_dispose(screen)
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	root.size = Vector2i(1280, 720)
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale cleanup failed")
	await process_frame
	_finish()


func _localized_tooltip(value: String) -> bool:
	return (
		value.contains("生命 ")
		and value.contains("攻击 ")
		and value.contains("防御 ")
		and value.contains("部署点")
		and value.contains("阻挡 ")
		and value.contains("技能：")
		and not value.contains("HP ")
		and not value.contains("ATK ")
		and not value.contains("Skill:")
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
		print("CHINESE_TRAINING_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("Chinese Training UI test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
