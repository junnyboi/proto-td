extends SceneTree

const CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const PresenterType := preload("res://scripts/ui/battle_dialogue_presenter.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var record := (CATALOG as StageNarrativeCatalogType).get_record(&"s1")
	_check(record != null, "S1 narrative record is missing")
	if record == null:
		_finish()
		return
	var presenter := PresenterType.new() as BattleDialoguePresenter
	root.add_child(presenter)
	presenter.setup(record, Vector2(root.size))
	await process_frame
	_check(presenter.show_mission_start(), "mission-start dialogue did not show")
	await process_frame
	_check(presenter.visible, "mission-start dialogue is not visible")
	_check(presenter.current_kind() == &"mission_start", "mission-start kind was not recorded")
	_check(presenter.current_speaker() == "ARCHIVE CASTER", "mission-start speaker is incorrect")
	_check(presenter.current_line().contains("humanity wrote"), "mission-start line is not canonical")
	_check(presenter.show_count() == 1, "mission-start show count is incorrect")
	_check(not presenter.show_mission_start(), "mission-start dialogue repeated")
	_check(not presenter.show_mid_wave(1), "mid-wave dialogue fired on wave one")
	_check(presenter.show_mid_wave(2), "mid-wave dialogue did not fire on its authored wave")
	_check(presenter.current_kind() == &"mid_wave", "mid-wave kind was not recorded")
	_check(presenter.current_speaker() == "LUNARIS VESSEL", "mid-wave speaker is incorrect")
	_check(presenter.current_line().contains("civilian column"), "mid-wave line is not canonical")
	_check(presenter.show_count() == 2, "mid-wave show count is incorrect")
	_check(not presenter.show_mid_wave(2), "mid-wave dialogue repeated")
	_check(_inside_viewport(presenter, Vector2(root.size)), "landscape dialogue exceeds the viewport")

	var i18n := root.get_node_or_null("I18n")
	_check(i18n != null and bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	await process_frame
	_check(presenter.current_speaker() == "月辉载体", "visible dialogue did not localize its speaker")
	_check(presenter.current_line().contains("平民纵队"), "visible dialogue did not localize its line")

	root.size = Vector2i(720, 1280)
	presenter.relayout(Vector2(root.size))
	await process_frame
	_check(_inside_viewport(presenter, Vector2(root.size)), "portrait dialogue exceeds the viewport")
	presenter.dismiss()
	_check(not presenter.visible, "dialogue dismiss did not hide the panel")
	if i18n != null:
		i18n.call("set_locale", &"en-US")
	_dispose(presenter)
	await create_timer(0.1).timeout
	_finish()


func _inside_viewport(control: Control, viewport: Vector2) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport.x + 1.0 and rect.end.y <= viewport.y + 1.0


func _dispose(node: Node) -> void:
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BATTLE_DIALOGUE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
