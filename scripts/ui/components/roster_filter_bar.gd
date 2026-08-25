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
var _compact := false
var _status_row: HFlowContainer
var _faction_row: HFlowContainer
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
) -> void:
	_rows = FilterType.annotate_all(rows)
	_show_status_tabs = show_status_tabs
	status = (
		initial_status
		if initial_status in [FilterType.STATUS_ACTIVE, FilterType.STATUS_FALLEN]
		else FilterType.STATUS_ACTIVE
	)
	faction_id = (
		initial_faction
		if initial_faction == FilterType.FACTION_ALL or FactionHeraldryType.ORDER.has(initial_faction)
		else FilterType.FACTION_ALL
	)
	_status_row.visible = _show_status_tabs
	_refresh_controls()


func set_rows(rows: Array) -> void:
	_rows = FilterType.annotate_all(rows)
	_refresh_controls()


func set_compact(value: bool) -> void:
	_compact = value
	_refresh_controls()


func _build_controls() -> void:
	_status_row = HFlowContainer.new()
	_status_row.name = "RosterStatusTabs"
	_status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_row.add_theme_constant_override(&"h_separation", 8)
	_status_row.add_theme_constant_override(&"v_separation", 8)
	add_child(_status_row)
	_add_status_button(FilterType.STATUS_ACTIVE)
	_add_status_button(FilterType.STATUS_FALLEN)

	_faction_row = HFlowContainer.new()
	_faction_row.name = "RosterFactionFilters"
	_faction_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_faction_row.add_theme_constant_override(&"h_separation", 8)
	_faction_row.add_theme_constant_override(&"v_separation", 8)
	add_child(_faction_row)
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
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
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
			else UiCopyType.text(&"ui.roster.tab.active", "Active")
		)
		button.text = "%s  %d" % [label.to_upper(), count]
		button.custom_minimum_size = Vector2(126.0 if _compact else 156.0, 44.0)
		Style.apply_button(button, &"selected" if value == status else &"quiet")

	for raw: Variant in _faction_buttons:
		var value := StringName(raw)
		var button := _faction_buttons[value] as Button
		var count := FilterType.count(_rows, status, value)
		button.text = (
			"%s  %d" % [UiCopyType.text(&"ui.roster.filter.all", "All").to_upper(), count]
			if value == FilterType.FACTION_ALL
			else str(count)
		)
		button.custom_minimum_size = Vector2(
			82.0 if value == FilterType.FACTION_ALL else (58.0 if _compact else 68.0),
			48.0 if _compact else 56.0,
		)
		button.add_theme_constant_override(&"icon_max_width", 30 if _compact else 36)
		Style.apply_button(button, &"selected" if value == faction_id else &"quiet")


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
