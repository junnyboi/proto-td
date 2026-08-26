class_name BattleDialoguePresenter
extends PanelContainer

## Presentation-only mission dialogue. The battle model remains the sole source of
## simulation truth; this view observes mission start and authored wave boundaries.

const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const ViewPreferencesType := preload("res://scripts/view/view_preferences.gd")

const ENTER_SECONDS := 0.18
const EXIT_SECONDS := 0.42
const MIN_HOLD_SECONDS := 5.5
const MAX_HOLD_SECONDS := 9.5

var _record: StageNarrativeDefType = null
var _sequence: Label = null
var _speaker: Label = null
var _line: Label = null
var _active_tween: Tween = null
var _viewport := Vector2(1280.0, 720.0)
var _mission_start_seen := false
var _mid_wave_seen := false
var _show_count := 0
var _current_kind := &""
var _i18n: Node = null


func setup(record: StageNarrativeDefType, viewport: Vector2) -> void:
	_record = record
	name = "BattleDialogue"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 75
	Style.apply_panel(self, &"transmission")
	_build_content()
	relayout(viewport)
	visible = false
	modulate.a = 0.0
	_i18n = get_node_or_null("/root/I18n")
	if _i18n != null and not _i18n.is_connected(&"locale_changed", _on_locale_changed):
		_i18n.connect(&"locale_changed", _on_locale_changed)


func _build_content() -> void:
	var column := VBoxContainer.new()
	column.name = "BattleDialogueContent"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 4)
	add_child(column)

	_sequence = _label("DialogueSequence", &"dense_detail")
	_sequence.add_theme_color_override(&"font_color", Style.CYAN)
	column.add_child(_sequence)

	_speaker = _label("DialogueSpeaker", &"heading")
	_speaker.add_theme_color_override(&"font_color", Style.GOLD)
	column.add_child(_speaker)

	_line = _label("DialogueLine", &"body")
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.add_theme_color_override(&"font_color", Style.IVORY)
	column.add_child(_line)


func _label(node_name: String, role: StringName) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_label(label, role)
	return label


func show_mission_start() -> bool:
	if _record == null or _mission_start_seen:
		return false
	_mission_start_seen = true
	_current_kind = &"mission_start"
	_show(
		UiCopyType.text(&"ui.battle.dialogue.mission_start", "MISSION START // LIVE TRANSMISSION"),
		UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.BATTLE_START_SPEAKER),
		UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.BATTLE_START),
	)
	return true


func show_mid_wave(wave_number: int) -> bool:
	if (
		_record == null
		or _mid_wave_seen
		or wave_number != _record.mid_wave_number
	):
		return false
	_mid_wave_seen = true
	_current_kind = &"mid_wave"
	_show(
		UiCopyType.format_text(
			&"ui.battle.dialogue.wave",
			"WAVE {wave} // LIVE TRANSMISSION",
			{&"wave": wave_number},
		),
		UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.MID_WAVE_SPEAKER),
		UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.MID_WAVE),
	)
	return true


func _show(sequence_text: String, speaker_text: String, line_text: String) -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	_active_tween = null
	_sequence.text = sequence_text
	_speaker.text = speaker_text.to_upper()
	_line.text = line_text
	_show_count += 1
	visible = true
	relayout(_viewport)
	var hold_seconds := clampf(MIN_HOLD_SECONDS + float(line_text.length()) / 90.0, MIN_HOLD_SECONDS, MAX_HOLD_SECONDS)
	if ViewPreferencesType.reduced_motion():
		modulate.a = 1.0
		_active_tween = create_tween()
		_active_tween.tween_interval(hold_seconds)
		_active_tween.tween_callback(_hide_now)
		return
	modulate.a = 0.0
	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(self, "modulate:a", 1.0, ENTER_SECONDS)
	_active_tween.tween_interval(hold_seconds)
	_active_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(self, "modulate:a", 0.0, EXIT_SECONDS)
	_active_tween.tween_callback(_hide_now)


func _hide_now() -> void:
	visible = false
	modulate.a = 0.0
	_active_tween = null


func dismiss() -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	_hide_now()


func relayout(viewport: Vector2) -> void:
	_viewport = viewport
	var portrait := viewport.y > viewport.x
	var width := minf(viewport.x - 24.0, 660.0 if portrait else 760.0)
	custom_minimum_size = Vector2(maxf(width, 280.0), 0.0)
	size = Vector2(custom_minimum_size.x, 0.0)
	reset_size()
	size = Vector2(custom_minimum_size.x, get_combined_minimum_size().y)
	position = Vector2(
		(viewport.x - size.x) * 0.5,
		148.0 if portrait else 82.0,
	)
	call_deferred("_settle_position")


func _settle_position() -> void:
	if not is_inside_tree():
		return
	size.y = get_combined_minimum_size().y
	position.x = (_viewport.x - size.x) * 0.5


func _on_locale_changed(_locale_id: StringName) -> void:
	if _record == null or not visible:
		return
	if _current_kind == &"mission_start":
		_sequence.text = UiCopyType.text(&"ui.battle.dialogue.mission_start", "MISSION START // LIVE TRANSMISSION")
		_speaker.text = UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.BATTLE_START_SPEAKER).to_upper()
		_line.text = UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.BATTLE_START)
	elif _current_kind == &"mid_wave":
		_sequence.text = UiCopyType.format_text(
			&"ui.battle.dialogue.wave", "WAVE {wave} // LIVE TRANSMISSION",
			{&"wave": _record.mid_wave_number},
		)
		_speaker.text = UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.MID_WAVE_SPEAKER).to_upper()
		_line.text = UiCopyType.stage_narrative_text(_record, StageNarrativeDefType.Field.MID_WAVE)
	relayout(_viewport)


func current_kind() -> StringName:
	return _current_kind


func current_speaker() -> String:
	return _speaker.text if _speaker != null else ""


func current_line() -> String:
	return _line.text if _line != null else ""


func show_count() -> int:
	return _show_count


func _exit_tree() -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	if _i18n != null and _i18n.is_connected(&"locale_changed", _on_locale_changed):
		_i18n.disconnect(&"locale_changed", _on_locale_changed)
