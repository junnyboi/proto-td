extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var required_by_file := {
		"res://scripts/ui/stage_select.gd": [
			"ui.campaign.eyebrow", "ui.campaign.progress", "ui.campaign.route_heading",
			"ui.campaign.facts", "ui.campaign.row_locked",
		],
		"res://scripts/ui/squad_select.gd": [
			"ui.squad.mission_identity", "ui.squad.card_ready", "ui.squad.card_premium",
			"ui.squad.card_fallen", "ui.error.missing_stage_narrative",
			"ui.squad.awaiting_selection", "ui.campaign.basic_hire_title",
			"ui.campaign.basic_hire_success", "ui.campaign.basic_hire_insufficient_tooltip",
		],
		"res://scripts/ui/spell_bar.gd": ["ui.spell.slow_field.tooltip"],
		"res://scripts/view/battle_view.gd": ["ui.battle.wave", "ui.battle.stamp_clear", "ui.battle.stamp_defeat"],
		"res://scripts/ui/battle_controls.gd": ["ui.battle.withdraw_rejected", "ui.battle.confirm_defeat_description", "ui.battle.return_description"],
		"res://scripts/ui/components/lunaris_dialog_sheet.gd": ["ui.dialog.scrollable_details", "ui.dialog.close_without_confirming"],
	}
	for path: String in required_by_file:
		var text := FileAccess.get_file_as_string(path)
		for key: String in required_by_file[path]:
			_check(text.contains(key), "%s does not consume %s" % [path, key])
	var campaign_source := FileAccess.get_file_as_string("res://scripts/ui/stage_select.gd")
	for forbidden: String in ["FIRST STAND · OPERATION ROUTE", "SELECTED OPERATION", "WAVE WINDOWS", "LEAK LIMIT"]:
		_check(not campaign_source.contains(forbidden), "Campaign retained English literal: %s" % forbidden)
	var squad_source := FileAccess.get_file_as_string("res://scripts/ui/squad_select.gd")
	for forbidden: String in ["MISSION 01 / OLD CUT", "FIELD TEAM // %s", "Field team // Awaiting selection", "NOTHING UNLOCKED", "FALLEN • VAHALLA"]:
		_check(not squad_source.contains(forbidden), "Squad retained English literal: %s" % forbidden)
	var map_source := FileAccess.get_file_as_string("res://scripts/ui/map_navigation_overlay.gd")
	_check(not map_source.contains("↔") and not map_source.contains("↕"), "Map navigation still depends on text arrow glyphs")
	var slow_field := load("res://data/spells/slow_field.tres")
	_check(slow_field != null, "Slow Field resource failed to load")
	if slow_field != null:
		_check(StringName(slow_field.get_meta(&"name_key", &"")) == &"data.spell.slow_field.name", "Slow Field name_key metadata is missing")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CHINESE_PRIMARY_FLOW_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
