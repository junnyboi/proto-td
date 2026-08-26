class_name RosterFilterBar
extends VBoxContainer

signal filters_changed(status: StringName, faction_id: StringName)

const FilterType := preload("res://scripts/ui/components/roster_filter.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

var status: StringName = FilterType.STATUS_ACTIVE
var faction_id: StringName = FilterType.FACTION_ALL
var _rows: Array[Dictionary] = []
var _show_status_tabs := true
var _show_promotion_ready_tab := false
var _compact := false
var _roomy := false
var _dense_inline := false
var _inline := false
var _generous_spacing := false
var _narrow := false
var _controls: BoxContainer
var _status_row: HFlowContainer
var _faction_row: HFlowContainer
var _auxiliary_row: BoxContainer = null
var _status_buttons := {}
var _faction_buttons := {}


func _init() -> void:
	name = "RosterFilters"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 8)
	_build_controls()


func configure(
	rows: Array,
	show_status_tabs: bool = true,
	initial_status: StringName = FilterType.STATUS_ACTIVE,
	initial_faction: StringName = FilterType.FACTION_ALL,
	show_promotion_ready_tab: bool = false,
) -> void:
	_rows = FilterType.annotate_all(rows)
	_show_status_tabs = show_status_tabs
	_show_promotion_ready_tab = show_promotion_ready_tab
	status = (
		initial_status
		if initial_status in [
			FilterType.STATUS_ACTIVE,
			FilterType.STATUS_FALLEN,
			FilterType.STATUS_PROMOTION_READY,
		]
		else FilterType.STATUS_ACTIVE
	)
	faction_id = (
		initial_faction
		if initial_faction == FilterType.FACTION_ALL or FactionHeraldryType.ORDER.has(initial_faction)
		else FilterType.FACTION_ALL
	)
	_status_row.visible = _show_status_tabs
	var promotion_button := _status_buttons.get(FilterType.STATUS_PROMOTION_READY) as Button
	if promotion_button != null:
		promotion_button.visible = _show_promotion_ready_tab
	_refresh_controls()


func set_rows(rows: Array) -> void:
	_rows = FilterType.annotate_all(rows)
	_refresh_controls()


func set_compact(value: bool) -> void:
	_compact = value
	if _status_row != null and _inline:
		_status_row.custom_minimum_size.x = _inline_status_width()
	_refresh_controls()


func set_generous_spacing(value: bool) -> void:
	_generous_spacing = value
	if _status_row != null and _inline:
		_status_row.custom_minimum_size.x = _inline_status_width()
	_refresh_controls()


func set_narrow(value: bool) -> void:
	_narrow = value
	_refresh_controls()


func set_roomy(value: bool) -> void:
	_roomy = value
	_refresh_controls()


func set_dense_inline(value: bool) -> void:
	_dense_inline = value
	if _status_row != null and _inline:
		_status_row.custom_minimum_size.x = _inline_status_width()
	if _faction_row != null:
		_faction_row.add_theme_constant_override(&"h_separation", 4 if _dense_inline else 8)
	_refresh_controls()


func set_inline(value: bool) -> void:
	_inline = value
	if _controls != null:
		_controls.vertical = not value
		_controls.add_theme_constant_override(&"separation", 12)
		_status_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if value else Control.SIZE_EXPAND_FILL
		_status_row.custom_minimum_size.x = (
			_inline_status_width() if value else 0.0
		)
		_faction_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_controls.queue_sort()
		queue_sort()


func attach_auxiliary_control(control: Control) -> void:
	if control == null or _controls == null or _faction_row == null:
		return
	if _auxiliary_row == null:
		_auxiliary_row = BoxContainer.new()
		_auxiliary_row.name = "RosterFilterLowerRail"
		_auxiliary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_auxiliary_row.add_theme_constant_override(&"separation", 12)
		_controls.remove_child(_faction_row)
		_controls.add_child(_auxiliary_row)
		_auxiliary_row.add_child(_faction_row)
		_faction_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if control.get_parent() != null:
		control.get_parent().remove_child(control)
	_auxiliary_row.add_child(control)


func set_auxiliary_stacked(value: bool) -> void:
	if _auxiliary_row != null:
		_auxiliary_row.vertical = value


func _build_controls() -> void:
	_controls = BoxContainer.new()
	_controls.name = "RosterFilterControls"
	_controls.vertical = not _inline
	_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls.add_theme_constant_override(&"separation", 12)
	add_child(_controls)
	_status_row = HFlowContainer.new()
	_status_row.name = "RosterStatusTabs"
	_status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_row.add_theme_constant_override(&"h_separation", 8)
	_status_row.add_theme_constant_override(&"v_separation", 8)
	_controls.add_child(_status_row)
	_add_status_button(FilterType.STATUS_ACTIVE)
	_add_status_button(FilterType.STATUS_FALLEN)
	_add_status_button(FilterType.STATUS_PROMOTION_READY)

	_faction_row = HFlowContainer.new()
	_faction_row.name = "RosterFactionFilters"
	_faction_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_faction_row.add_theme_constant_override(&"h_separation", 8)
	_faction_row.add_theme_constant_override(&"v_separation", 8)
	_controls.add_child(_faction_row)
	_add_faction_button(FilterType.FACTION_ALL)
	for item: StringName in FactionHeraldryType.ORDER:
		_add_faction_button(item)


func _add_status_button(value: StringName) -> void:
	var button := Button.new()
	button.name = "%sRosterTab" % String(value).to_pascal_case()
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_status_pressed.bind(value))
	_status_row.add_child(button)
	_status_buttons[value] = button


func _add_faction_button(value: StringName) -> void:
	var button := Button.new()
	button.name = "%sFactionFilter" % String(value).to_pascal_case()
	button.focus_mode = Control.FOCUS_ALL
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override(&"icon_separation", 14)
	if value != FilterType.FACTION_ALL:
		button.icon = FactionHeraldryType.symbol(value)
		button.tooltip_text = FactionHeraldryType.display_name(value)
	else:
		button.tooltip_text = UiCopyType.text(&"ui.roster.filter.all_factions", "All factions")
	button.pressed.connect(_on_faction_pressed.bind(value))
	_faction_row.add_child(button)
	_faction_buttons[value] = button


func _refresh_controls() -> void:
	for raw: Variant in _status_buttons:
		var value := StringName(raw)
		var button := _status_buttons[value] as Button
		var count := FilterType.count(_rows, value)
		var label := (
			UiCopyType.text(&"ui.roster.tab.fallen", "Fallen")
			if value == FilterType.STATUS_FALLEN
			else (
				UiCopyType.text(&"ui.roster.tab.promotion_ready", "Promotion Ready")
				if value == FilterType.STATUS_PROMOTION_READY
				else UiCopyType.text(&"ui.roster.tab.active", "Active")
			)
		)
		button.text = "%s  %d" % [label.to_upper(), count]
		button.autowrap_mode = (
			TextServer.AUTOWRAP_WORD_SMART if _narrow else TextServer.AUTOWRAP_OFF
		)
		button.clip_text = false
		if _generous_spacing:
			button.custom_minimum_size = (
			Vector2(
				(280.0 if _narrow else 310.0)
				if value == FilterType.STATUS_PROMOTION_READY
				else 170.0,
				72.0,
			)
			)
		else:
			var status_width := 176.0 if _dense_inline else (176.0 if _compact else 200.0)
			button.custom_minimum_size = Vector2(
				status_width * (2.0 if _roomy else 1.0),
				78.0 if _roomy else 54.0,
			)
		Style.apply_button(button, &"selected" if value == status else &"quiet")
		if _generous_spacing:
			_apply_button_insets(button, 22.0, 12.0)

	for raw: Variant in _faction_buttons:
		var value := StringName(raw)
		var button := _faction_buttons[value] as Button
		var count := FilterType.count(_rows, status, value)
		button.text = (
			"%s  %d" % [UiCopyType.text(&"ui.roster.filter.all", "All").to_upper(), count]
			if value == FilterType.FACTION_ALL
			else str(count)
		)
		var accessible_faction_name := (
			UiCopyType.text(&"ui.roster.filter.all_factions", "All factions")
			if value == FilterType.FACTION_ALL
			else FactionHeraldryType.display_name(value)
		)
		button.accessibility_name = "%s: %d" % [accessible_faction_name, count]
		button.accessibility_description = button.accessibility_name
		button.alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
			if value == FilterType.FACTION_ALL
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
		if _generous_spacing:
			button.custom_minimum_size = Vector2(
				120.0 if value == FilterType.FACTION_ALL else 98.0, 72.0,
			)
			button.add_theme_constant_override(&"icon_max_width", 44)
			button.add_theme_constant_override(&"icon_separation", 12)
		else:
			var faction_width := (
				(84.0 if value == FilterType.FACTION_ALL else 48.0)
				if _dense_inline
				else (108.0 if value == FilterType.FACTION_ALL else (72.0 if _compact else 84.0))
			)
			var faction_height := 54.0 if _compact else 66.0
			button.custom_minimum_size = Vector2(
				faction_width * (2.0 if _roomy else 1.0),
				78.0 if _roomy else faction_height,
			)
			button.add_theme_constant_override(
				&"icon_max_width", 28 if _dense_inline else (45 if _compact else 54),
			)
		Style.apply_button(button, &"selected" if value == faction_id else &"quiet")
		if _generous_spacing:
			_apply_button_insets(button, 18.0, 12.0)


func _apply_button_insets(button: Button, horizontal: float, vertical: float) -> void:
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var source := button.get_theme_stylebox(style_name)
		if source == null:
			continue
		var style := source.duplicate() as StyleBox
		style.content_margin_left = maxf(style.content_margin_left, horizontal)
		style.content_margin_right = maxf(style.content_margin_right, horizontal)
		style.content_margin_top = maxf(style.content_margin_top, vertical)
		style.content_margin_bottom = maxf(style.content_margin_bottom, vertical)
		button.add_theme_stylebox_override(style_name, style)


func _inline_status_width() -> float:
	if _generous_spacing:
		return 666.0 if _show_promotion_ready_tab else 348.0
	if _dense_inline:
		return 360.0
	return 360.0 if _compact else 408.0


func _on_status_pressed(value: StringName) -> void:
	if status == value:
		return
	status = value
	_refresh_controls()
	filters_changed.emit(status, faction_id)


func _on_faction_pressed(value: StringName) -> void:
	if faction_id == value:
		return
	faction_id = value
	_refresh_controls()
	filters_changed.emit(status, faction_id)
