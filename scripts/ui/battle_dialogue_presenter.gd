class_name BattleDialoguePresenter
extends PanelContainer

signal layout_changed

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
const CONTROL_GAP := 64.0
const EDGE_MARGIN := 16.0
const LANDSCAPE_WIDTH := 620.0
const PORTRAIT_WIDTH := 660.0
const MAX_HEIGHT := 320.0
const SPEAKER_PORTRAIT_SIZE := Vector2(112.0, 112.0)
const NARROW_SPEAKER_PORTRAIT_SIZE := Vector2(88.0, 88.0)
const SPEAKER_PORTRAIT_IDS := {
	"ARCHIVE CASTER": &"portrait_archive_caster",
	"LUNARIS VESSEL": &"portrait_lunaris_vessel",
	"RELIQUARY DUELIST": &"portrait_reliquary_duelist",
	"CINDER": &"enemy_static_heavy",
	"PROTOS": &"enemy_static_mini_boss",
	"COMMANDANT": &"portrait_recruit_05",
	"SOLCREST ENVOY": &"portrait_recruit_00",
	"UNLIT FOREMAN": &"enemy_static_drone",
	"REFINERY DIRECTOR": &"portrait_recruit_03",
}

var _record: StageNarrativeDefType = null
var _sequence: Label = null
var _speaker: Label = null
var _line: Label = null
var _portrait: TextureRect = null
var _portrait_frame: PanelContainer = null
var _active_tween: Tween = null
var _viewport := Vector2(1280.0, 720.0)
var _controls_rect := Rect2()
var _deployment_rect := Rect2()
var _mission_start_seen := false
var _mid_wave_seen := false
var _show_count := 0
var _current_kind := &""
var _i18n: Node = null
var _enforcing_compact_size := false
var _published_rect := Rect2()
var _presentation_active := false
var _layout_suppressed := false


func setup(record: StageNarrativeDefType, viewport: Vector2, controls_rect := Rect2(), deployment_rect := Rect2()) -> void:
	_record = record
	_controls_rect = controls_rect
	_deployment_rect = deployment_rect
	name = "BattleDialogue"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 75
	Style.apply_panel(self, &"transmission")
	_build_content()
	resized.connect(_enforce_compact_size)
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
	column.add_theme_constant_override(&"separation", 0)
	add_child(column)

	_sequence = _label("DialogueSequence", &"dense_detail")
	_sequence.add_theme_color_override(&"font_color", Style.CYAN)
	var header_inset := MarginContainer.new()
	header_inset.name = "DialogueHeaderInset"
	header_inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_inset.add_theme_constant_override(&"margin_bottom", 12)
	header_inset.add_child(_sequence)
	column.add_child(header_inset)

	var row := HBoxContainer.new()
	row.name = "DialogueBodyRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 16)
	column.add_child(row)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.name = "DialoguePortraitFrame"
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Style.apply_panel(_portrait_frame, &"selected")
	_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.name = "DialoguePortrait"
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.custom_minimum_size = SPEAKER_PORTRAIT_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_frame.add_child(_portrait)

	var copy := VBoxContainer.new()
	copy.name = "DialogueCopy"
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override(&"separation", 4)
	row.add_child(copy)

	_speaker = _label("DialogueSpeaker", &"heading")
	_speaker.add_theme_color_override(&"font_color", Style.GOLD)
	copy.add_child(_speaker)

	_line = _label("DialogueLine", &"body")
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.max_lines_visible = 3
	_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_line.add_theme_color_override(&"font_color", Style.IVORY)
	copy.add_child(_line)


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
		_record.battle_start_speaker,
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
			_record.mid_wave_speaker,
		)
	return true


func _show(
	sequence_text: String,
	speaker_text: String,
	line_text: String,
	canonical_speaker: String,
) -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	_active_tween = null
	_sequence.text = sequence_text
	_speaker.text = speaker_text.to_upper()
	_line.text = line_text
	_apply_speaker_portrait(canonical_speaker)
	_show_count += 1
	_presentation_active = true
	_layout_suppressed = false
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
	_presentation_active = false
	_layout_suppressed = false
	visible = false
	modulate.a = 0.0
	_active_tween = null
	layout_changed.emit()


func dismiss() -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	_hide_now()


func relayout(viewport: Vector2, controls_rect := Rect2(), deployment_rect := Rect2()) -> void:
	_viewport = viewport
	if controls_rect.has_area():
		_controls_rect = controls_rect
	if deployment_rect.has_area():
		_deployment_rect = deployment_rect
	var portrait := viewport.y > viewport.x
	var width := minf(viewport.x - EDGE_MARGIN * 2.0, PORTRAIT_WIDTH if portrait else LANDSCAPE_WIDTH)
	custom_minimum_size = Vector2(maxf(width, 280.0), 0.0)
	if _portrait != null:
		_portrait.custom_minimum_size = NARROW_SPEAKER_PORTRAIT_SIZE if viewport.x < 600.0 else SPEAKER_PORTRAIT_SIZE
	_enforce_compact_size()
	call_deferred("_settle_position")


func _settle_position() -> void:
	if not is_inside_tree():
		return
	_enforce_compact_size()
	_position_below_controls()
	_publish_layout_if_changed()


func _position_below_controls() -> void:
	var target_height := minf(get_combined_minimum_size().y, MAX_HEIGHT)
	var right := _controls_rect.end.x if _controls_rect.has_area() else _viewport.x - EDGE_MARGIN
	var gap := CONTROL_GAP
	var top := _controls_rect.end.y + gap if _controls_rect.has_area() else 288.0
	if _deployment_rect.has_area():
		var lane_bottom := _deployment_rect.position.y - EDGE_MARGIN
		if top + target_height > lane_bottom:
			_set_layout_suppressed(true)
			return
	_set_layout_suppressed(false)
	var max_top := maxf(EDGE_MARGIN, _viewport.y - target_height - EDGE_MARGIN)
	position = Vector2(
		clampf(right - size.x, EDGE_MARGIN, maxf(EDGE_MARGIN, _viewport.x - size.x - EDGE_MARGIN)),
		minf(top, max_top),
	)


func _set_layout_suppressed(suppressed: bool) -> void:
	if _layout_suppressed == suppressed:
		return
	_layout_suppressed = suppressed
	visible = _presentation_active and not _layout_suppressed
	layout_changed.emit()


func _apply_speaker_portrait(canonical_speaker: String) -> void:
	if _portrait == null or _portrait_frame == null:
		return
	var normalized := canonical_speaker.strip_edges().to_upper()
	var asset_id := StringName(SPEAKER_PORTRAIT_IDS.get(normalized, &""))
	var texture := Art.texture(asset_id) if asset_id != &"" else null
	if texture == null and _record != null:
		var poster_path := "res://assets/cinematics/missions/posters/%s.webp" % _record.id
		if ResourceLoader.exists(poster_path):
			texture = load(poster_path) as Texture2D
	_portrait.texture = texture
	_portrait_frame.visible = texture != null
	_portrait_frame.set_meta(&"speaker_portrait_asset_id", asset_id)
	_portrait.accessibility_name = _speaker.text


func _enforce_compact_size() -> void:
	if _enforcing_compact_size:
		return
	var target := Vector2(custom_minimum_size.x, minf(get_combined_minimum_size().y, MAX_HEIGHT))
	if target.y <= 0.0 or size.is_equal_approx(target):
		return
	_enforcing_compact_size = true
	size = target
	_enforcing_compact_size = false


func _process(_delta: float) -> void:
	if visible:
		_enforce_compact_size()
		_position_below_controls()
		_publish_layout_if_changed()


func _publish_layout_if_changed() -> void:
	var current_rect := get_global_rect()
	if current_rect.is_equal_approx(_published_rect):
		return
	_published_rect = current_rect
	layout_changed.emit()


func _on_locale_changed(_locale_id: StringName) -> void:
	if _record == null or not _presentation_active:
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
	if _portrait != null:
		_portrait.accessibility_name = _speaker.text
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
