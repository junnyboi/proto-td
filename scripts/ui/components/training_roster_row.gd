class_name TrainingRosterRow
extends "res://scripts/ui/components/aetheria_button.gd"

const TrainingLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const ArtType := preload("res://scripts/view/art.gd")
const LunarisOpsType := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const PremiumPortraitEntranceType := preload("res://scripts/ui/components/premium_portrait_entrance.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ROW_HORIZONTAL_PADDING := 48
const ROW_VERTICAL_PADDING := 24
const ROW_DEFAULT_WIDTH := 560.0

var hero_id := ""
var can_promote := false
var _portrait: TextureRect
var _callsign: TrainingLabelType
var _title_tag: TrainingLabelType
var _class_name: TrainingLabelType
var _status: TrainingLabelType
var _xp: TrainingLabelType
var _reason: TrainingLabelType
var _progress: ProgressBar
var _body: BoxContainer
var _status_line: BoxContainer


func _init() -> void:
	toggle_mode = true
	custom_minimum_size.x = ROW_DEFAULT_WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	set_presentation_text(
		UiCopyType.text(&"ui.training.roster_row_accessibility_name", "Training recruit"),
		" ",
	)
	_build_content()


func configure(
		summary: Dictionary,
		class_label: String,
		status_text: String,
		xp_text: String,
		reason_text: String,
		detail_tooltip: String = "",
		entrance_index: int = 0,
	) -> void:
	hero_id = String(summary["hero_id"])
	can_promote = bool(summary["can_promote"])
	_callsign.text = String(summary["callsign"])
	_title_tag.text = String(
		summary.get("custom_title", "") if summary.get("custom_title") != null else "",
	)
	_title_tag.visible = not _title_tag.text.is_empty()
	_class_name.text = class_label
	_status.text = status_text
	_xp.text = xp_text
	_reason.text = reason_text
	_progress.max_value = int(summary["xp_required"])
	_progress.value = mini(int(summary["xp"]), int(summary["xp_required"]))
	var portrait_asset_id := StringName(summary["portrait_asset_id"])
	_portrait.texture = ArtType.texture(portrait_asset_id)
	PremiumPortraitEntranceType.apply(
		_portrait,
		portrait_asset_id,
		entrance_index,
		bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)),
	)
	var identity := _callsign.text
	if not _title_tag.text.is_empty():
		identity += " — %s" % _title_tag.text
	text = "%s — %s — %s — %s — %s" % [
		identity, _class_name.text, _status.text, _xp.text, _reason.text,
	]
	tooltip_text = detail_tooltip if not detail_tooltip.is_empty() else text


func set_selected(value: bool) -> void:
	button_pressed = value
	LunarisOpsType.apply_button(self, &"selected" if value else &"secondary")


func set_compact(value: bool, fixed_width: float = ROW_DEFAULT_WIDTH) -> void:
	_portrait.custom_minimum_size = Vector2(82.0, 108.0) if value else Vector2(96.0, 116.0)
	custom_minimum_size.x = fixed_width
	var narrow := fixed_width < 500.0
	if _body != null:
		_body.vertical = narrow
		_body.alignment = BoxContainer.ALIGNMENT_CENTER if narrow else BoxContainer.ALIGNMENT_BEGIN
	if _status_line != null:
		_status_line.vertical = narrow
	fit_to_content()


func fit_to_content() -> void:
	var callsign_height := _fit_label(_callsign)
	var title_height := _fit_label(_title_tag) if _title_tag.visible else 0.0
	var class_height := _fit_label(_class_name)
	var status_height := (
		_fit_label(_status) + _fit_label(_xp)
		if _status_line != null and _status_line.vertical
		else maxf(_fit_label(_status), _fit_label(_xp))
	)
	var reason_height := _fit_label(_reason)
	var details_height := (
		callsign_height + title_height + class_height + status_height
		+ _progress.custom_minimum_size.y + reason_height
	)
	var content_height := (
		_portrait.custom_minimum_size.y + 14.0 + details_height
		if _body != null and _body.vertical
		else maxf(details_height, _portrait.custom_minimum_size.y)
	)
	custom_minimum_size.y = ceilf(content_height + ROW_VERTICAL_PADDING * 2.0)
	update_minimum_size()


func _build_content() -> void:
	var presentation := get_node("PresentationLabel") as Label
	presentation.text = " "
	var margin := MarginContainer.new()
	margin.name = "RosterRowMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", ROW_HORIZONTAL_PADDING)
	margin.add_theme_constant_override(&"margin_top", ROW_VERTICAL_PADDING)
	margin.add_theme_constant_override(&"margin_right", ROW_HORIZONTAL_PADDING)
	margin.add_theme_constant_override(&"margin_bottom", ROW_VERTICAL_PADDING)
	add_child(margin)
	_body = BoxContainer.new()
	_body.name = "RosterRowContent"
	_body.add_theme_constant_override(&"separation", 14)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_body)
	_portrait = TextureRect.new()
	_portrait.name = "IdentityPortrait"
	_portrait.custom_minimum_size = Vector2(96.0, 104.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_portrait)
	var details := VBoxContainer.new()
	details.name = "RosterDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override(&"separation", 2)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(details)
	_callsign = _label("Callsign", &"dense_body")
	_title_tag = _label("CustomTitle", &"eyebrow")
	_title_tag.visible = false
	_class_name = _label("CurrentClass", &"dense_detail")
	_status_line = BoxContainer.new()
	_status_line.name = "StatusLine"
	_status_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status = _label("LifeStatus", &"dense_detail")
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.size_flags_stretch_ratio = 0.7
	_xp = _label("XpProgress", &"dense_detail")
	_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp.size_flags_stretch_ratio = 1.3
	_status_line.add_child(_status)
	_status_line.add_child(_xp)
	_progress = ProgressBar.new()
	_progress.name = "XpBar"
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 8.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	LunarisOpsType.apply_progress(_progress)
	_reason = _label("EligibilityReason", &"dense_detail")
	for control: Control in [
		_callsign, _title_tag, _class_name, _status_line, _progress, _reason,
	]:
		details.add_child(control)


func _label(node_name: String, role: StringName) -> TrainingLabelType:
	var label := TrainingLabelType.new()
	label.name = node_name
	label.apply_role(role)
	match role:
		&"dense_body":
			LunarisOpsType.apply_label(label, &"body")
			label.add_theme_font_size_override(&"font_size", 29)
		&"dense_detail":
			LunarisOpsType.apply_label(label, &"detail")
			label.add_theme_font_size_override(&"font_size", 24)
		&"eyebrow":
			LunarisOpsType.apply_label(label, &"eyebrow")
			label.add_theme_font_size_override(&"font_size", 23)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _fit_label(label: Label) -> float:
	var font_size := label.get_theme_font_size(&"font_size")
	var line_height := ceilf(label.get_theme_font(&"font").get_height(font_size))
	label.custom_minimum_size.y = line_height
	return line_height
