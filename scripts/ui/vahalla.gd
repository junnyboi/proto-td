class_name VahallaScreen
extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const RosterFilterType := preload("res://scripts/ui/components/roster_filter.gd")
const RosterFilterBarType := preload("res://scripts/ui/components/roster_filter_bar.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")
const VAHALLA_THEME := preload("res://data/presentation/ui/threshold_theme.tres")

var _screen_margin: MarginContainer
var _header_grid: GridContainer
var _body_grid: GridContainer
var _roster_panel: PanelContainer
var _dossier_panel: PanelContainer
var _memorial_grid: GridContainer
var _memorial_scroll: ScrollContainer
var _filter_bar: RosterFilterBarType
var _status_label: Label
var _back_button: Button
var _eyebrow_label: Label
var _title_label: Label
var _intro_label: Label
var _roster_heading: Label
var _fallen_rows: Array[Dictionary] = []
var _visible_rows: Array[Dictionary] = []
var _memorial_by_hero := {}
var _honored := {}
var _selected_hero_id := ""


func _ready() -> void:
	theme = VAHALLA_THEME
	Game.content = self
	I18n.locale_changed.connect(_on_locale_changed)
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	_refresh_projection()
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _refresh_projection() -> void:
	_fallen_rows.clear()
	_memorial_by_hero.clear()
	var projection: Dictionary = Game.campaign_projection()
	if projection.is_empty():
		return
	_fallen_rows = RosterFilterType.annotate_all(projection.get("fallen_heroes", []))
	for record: Dictionary in projection.get("memorial", []):
		_memorial_by_hero[String(record.get("hero_id", ""))] = record.duplicate(true)


func _build_screen() -> void:
	_screen_margin = MarginContainer.new()
	_screen_margin.name = "VahallaScreenMargin"
	_screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_screen_margin)

	var shell := PanelContainer.new()
	shell.name = "VahallaShell"
	Style.apply_panel(shell, &"screen")
	_screen_margin.add_child(shell)

	var content := VBoxContainer.new()
	content.name = "VahallaContent"
	content.add_theme_constant_override(&"separation", 12)
	shell.add_child(content)

	_header_grid = GridContainer.new()
	_header_grid.name = "VahallaHeader"
	_header_grid.columns = 3
	_header_grid.add_theme_constant_override(&"h_separation", 16)
	_header_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_header_grid)
	_back_button = Button.new()
	_back_button.name = "BackToCommand"
	_back_button.text = UiCopyType.text(&"ui.vahalla.back", "Return to Company Command")
	_back_button.tooltip_text = _back_button.text
	_back_button.accessibility_name = _back_button.text
	_back_button.custom_minimum_size = Vector2(210, 56)
	_back_button.pressed.connect(_on_back_pressed)
	Style.apply_button(_back_button, &"quiet")
	_header_grid.add_child(_back_button)
	var identity := HBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	identity.add_child(FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 52.0))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eyebrow_label = _label(UiCopyType.text(&"ui.vahalla.eyebrow", "LUNARIS RELIQUARY • HALL OF THE FALLEN"), &"eyebrow")
	titles.add_child(_eyebrow_label)
	_title_label = _label(UiCopyType.text(&"ui.vahalla.title_display", "Valhalla").to_upper(), &"title")
	titles.add_child(_title_label)
	identity.add_child(titles)
	_header_grid.add_child(identity)
	_status_label = _label("", &"metric")
	_status_label.name = "FallenCount"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_status_label)

	_intro_label = _label(
		UiCopyType.text(&"ui.vahalla.intro", "Valhalla records Company Manus personnel whose souls are missing, captured, or permanently lost. Recoverable souls remain rescue targets; consumed or shattered souls cannot return."),
		&"detail",
	)
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_intro_label)

	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(_fallen_rows, false, RosterFilterType.STATUS_FALLEN, RosterFilterType.FACTION_ALL)
	_refresh_filter_accessibility()
	_filter_bar.set_compact(true)
	_filter_bar.filters_changed.connect(_on_filters_changed)
	content.add_child(_filter_bar)

	_body_grid = GridContainer.new()
	_body_grid.name = "MemorialBody"
	_body_grid.columns = 2
	_body_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_grid.add_theme_constant_override(&"h_separation", 14)
	_body_grid.add_theme_constant_override(&"v_separation", 14)
	content.add_child(_body_grid)

	_roster_panel = PanelContainer.new()
	_roster_panel.name = "MemorialRosterPanel"
	_roster_panel.custom_minimum_size.x = 320
	_roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_roster_panel, &"quiet")
	_ensure_panel_padding(_roster_panel, 18.0)
	_body_grid.add_child(_roster_panel)
	var roster_stack := VBoxContainer.new()
	roster_stack.add_theme_constant_override(&"separation", 10)
	_roster_panel.add_child(roster_stack)
	_roster_heading = _label(UiCopyType.text(&"ui.vahalla.roster_heading", "FALLEN COMPANY"), &"heading")
	roster_stack.add_child(_roster_heading)
	var scroll := ScrollContainer.new()
	scroll.name = "VahallaMemorialScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_memorial_scroll = scroll
	roster_stack.add_child(scroll)
	_memorial_grid = GridContainer.new()
	_memorial_grid.name = "VahallaMemorialGrid"
	_memorial_grid.columns = 1
	_memorial_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_memorial_grid.add_theme_constant_override(&"v_separation", 8)
	scroll.add_child(_memorial_grid)

	_dossier_panel = PanelContainer.new()
	_dossier_panel.name = "MemorialDossier"
	_dossier_panel.custom_minimum_size.x = 680
	_dossier_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dossier_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_dossier_panel, &"memorial")
	_ensure_panel_padding(_dossier_panel, 22.0)
	_body_grid.add_child(_dossier_panel)
	_rebuild_memorial()


func _rebuild_memorial() -> void:
	for child: Node in _memorial_grid.get_children():
		_memorial_grid.remove_child(child)
		child.queue_free()
	_visible_rows = RosterFilterType.filter_rows(_fallen_rows, RosterFilterType.STATUS_FALLEN, _filter_bar.faction_id)
	_status_label.text = UiCopyType.text(&"ui.vahalla.fallen_count_format", "{count} FALLEN").replace("{count}", str(_visible_rows.size()))
	_status_label.accessibility_name = _status_label.text
	if _visible_rows.is_empty():
		_selected_hero_id = ""
		var empty := _label(UiCopyType.text(&"ui.vahalla.empty", "No fallen soldiers are recorded for this faction."), &"body")
		empty.name = "VahallaEmptyState"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_memorial_grid.add_child(empty)
		_rebuild_dossier()
		return
	var selected_still_visible := false
	for hero: Dictionary in _visible_rows:
		if String(hero.get("hero_id", "")) == _selected_hero_id:
			selected_still_visible = true
	if not selected_still_visible:
		_selected_hero_id = String(_visible_rows[0]["hero_id"])
	for hero: Dictionary in _visible_rows:
		_memorial_grid.add_child(_memorial_row(hero))
	_rebuild_dossier()


func _memorial_row(hero: Dictionary) -> Button:
	var hero_id := String(hero["hero_id"])
	var row := Button.new()
	row.name = "Memorial_%s" % hero_id
	row.custom_minimum_size = Vector2(0, 104)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.text = "%s\n%s · %s" % [
		TrainingSupportType.callsign(hero).to_upper(),
		_class_name(String(hero["current_class_id"])).to_upper(),
		FactionHeraldryType.display_name(StringName(hero["faction_id"])).to_upper(),
	]
	row.tooltip_text = row.text
	row.accessibility_name = row.text
	row.accessibility_description = row.text
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.pressed.connect(_on_memorial_selected.bind(hero_id))
	Style.apply_button(row, &"selected" if hero_id == _selected_hero_id else &"quiet")
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		row.add_theme_color_override(color_name, Color.TRANSPARENT)
	var margin := MarginContainer.new()
	margin.name = "MemorialRowMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	row.add_child(margin)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override(&"separation", 4)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(copy)
	var callsign := _label(TrainingSupportType.callsign(hero).to_upper(), &"body")
	callsign.name = "MemorialRowCallsign"
	callsign.add_theme_font_size_override(&"font_size", 29)
	copy.add_child(callsign)
	var class_copy := _label(_class_name(String(hero["current_class_id"])).to_upper(), &"detail")
	class_copy.name = "MemorialRowClass"
	copy.add_child(class_copy)
	var faction_copy := _label(FactionHeraldryType.display_name(StringName(hero["faction_id"])).to_upper(), &"detail")
	faction_copy.name = "MemorialRowFaction"
	copy.add_child(faction_copy)
	return row


func _rebuild_dossier() -> void:
	for child: Node in _dossier_panel.get_children():
		_dossier_panel.remove_child(child)
		child.queue_free()
	if _selected_hero_id.is_empty():
		var empty := _label(UiCopyType.text(&"ui.vahalla.no_selection", "NO MEMORIAL RECORD SELECTED"), &"body")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_dossier_panel.add_child(empty)
		return
	var hero := _hero_for_id(_selected_hero_id)
	if hero.is_empty():
		return
	var layout := GridContainer.new()
	layout.name = "DossierLayout"
	layout.columns = 2
	layout.add_theme_constant_override(&"h_separation", 18)
	layout.add_theme_constant_override(&"v_separation", 12)
	_dossier_panel.add_child(layout)
	var portrait := TextureRect.new()
	portrait.name = "SelectedMemorialPortrait"
	portrait.texture = Art.texture(StringName(hero["portrait_asset_id"]))
	portrait.custom_minimum_size = Vector2(320, 420)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(portrait)
	var details := VBoxContainer.new()
	details.name = "SelectedMemorialDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override(&"separation", 10)
	layout.add_child(details)
	var faction_id := StringName(hero["faction_id"])
	var faction_row := HBoxContainer.new()
	faction_row.add_theme_constant_override(&"separation", 8)
	faction_row.add_child(FactionHeraldryType.make_symbol(faction_id, 38.0))
	var faction := _label(FactionHeraldryType.display_name(faction_id).to_upper(), &"eyebrow")
	faction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	faction_row.add_child(faction)
	details.add_child(faction_row)
	details.add_child(_label(TrainingSupportType.callsign(hero).to_upper(), &"title"))
	var title := String(hero.get("title", ""))
	if not title.is_empty():
		details.add_child(_label(title, &"heading"))
	details.add_child(_label(_class_name(String(hero["current_class_id"])).to_upper(), &"metric"))
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Style.CYAN, 0.5)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(rule)
	var service_ledger := PanelContainer.new()
	service_ledger.name = "ServiceLedger"
	service_ledger.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	service_ledger.custom_minimum_size.y = 160.0
	Style.apply_panel(service_ledger, &"quiet")
	_ensure_panel_padding(service_ledger, 18.0)
	details.add_child(service_ledger)
	var ledger_stack := VBoxContainer.new()
	ledger_stack.add_theme_constant_override(&"separation", 8)
	service_ledger.add_child(ledger_stack)
	var terminal := _label(UiCopyType.text(&"ui.vahalla.terminal_record", "SOUL STATUS AND FINAL SERVICE RECORD"), &"eyebrow")
	terminal.add_theme_color_override(&"font_color", Style.DANGER)
	ledger_stack.add_child(terminal)
	var record := _label(_death_record(hero), &"body")
	record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ledger_stack.add_child(record)
	var continuity := _label(UiCopyType.text(&"ui.vahalla.permanence", "Status follows the same unique soul: missing or captured may be recoverable; consumed or shattered is permanent."), &"detail")
	continuity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ledger_stack.add_child(continuity)
	var honor := Button.new()
	honor.name = "Honor_%s" % _selected_hero_id
	honor.text = (
		UiCopyType.text(&"ui.vahalla.honored", "Honored")
		if _honored.has(_selected_hero_id)
		else UiCopyType.text(&"ui.vahalla.honor", "Honor")
	).to_upper()
	honor.custom_minimum_size = Vector2(0, 58)
	honor.disabled = _honored.has(_selected_hero_id)
	honor.pressed.connect(_on_honor_pressed.bind(_selected_hero_id))
	Style.apply_button(honor, &"selected" if honor.disabled else &"gold")
	details.add_child(honor)
	if get_viewport_rect().size.y > get_viewport_rect().size.x:
		var narrow := get_viewport_rect().size.x < 600.0
		layout.columns = 1 if narrow else 2
		portrait.custom_minimum_size = Vector2(0 if narrow else 220, 220 if narrow else 280)


func _hero_for_id(hero_id: String) -> Dictionary:
	for hero: Dictionary in _fallen_rows:
		if String(hero.get("hero_id", "")) == hero_id:
			return hero
	return {}


func _death_record(hero: Dictionary) -> String:
	var hero_id := String(hero["hero_id"])
	var memorial: Dictionary = _memorial_by_hero.get(hero_id, {})
	var death: Dictionary = memorial.get("death", hero.get("death", {}))
	if death.is_empty():
		return UiCopyType.text(&"ui.vahalla.record_unknown", "SERVICE RECORD SEALED")
	var stage := _stage_name(StringName(death.get("stage_id", &"")))
	var reason := _terminal_reason(StringName(death.get("terminal_reason", &"")))
	return UiCopyType.format_text(&"ui.vahalla.record", "FELL AT {stage} • {reason} • TICK {tick}", {
		&"stage": stage,
		&"reason": reason,
		&"tick": int(death.get("terminal_tick", 0)),
	})


func _class_name(class_id: String) -> String:
	var definition := TrainingSupportType.class_definition(class_id)
	return UiCopyType.text(definition.name_key, definition.name) if definition != null else UiCopyType.text(&"ui.vahalla.class_unknown", "Unknown class")


func _stage_name(stage_id: StringName) -> String:
	var path := "res://data/stages/%s.tres" % stage_id
	return UiCopyType.stage_title(load(path) as StageDef) if ResourceLoader.exists(path) else UiCopyType.text(&"ui.vahalla.stage_unknown", "Unknown operation")


func _terminal_reason(reason: StringName) -> String:
	match reason:
		&"resign": return UiCopyType.text(&"ui.vahalla.reason.resign", "Voluntary withdrawal")
		&"base_defeat": return UiCopyType.text(&"ui.vahalla.reason.base_defeat", "Base lost")
		&"leak_defeat": return UiCopyType.text(&"ui.vahalla.reason.leak_defeat", "Leak limit exceeded")
		&"clear": return UiCopyType.text(&"ui.vahalla.reason.clear", "Operation cleared")
		&"fallen": return UiCopyType.text(&"ui.vahalla.reason.fallen", "Fallen in service")
		_: return UiCopyType.text(&"ui.vahalla.reason.unknown", "Unknown cause")


func _on_locale_changed(_locale_id: StringName) -> void:
	if _back_button == null:
		return
	_back_button.text = UiCopyType.text(&"ui.vahalla.back", "Return to Company Command")
	_back_button.tooltip_text = _back_button.text
	_back_button.accessibility_name = _back_button.text
	_eyebrow_label.text = UiCopyType.text(&"ui.vahalla.eyebrow", "LUNARIS RELIQUARY • HALL OF THE FALLEN")
	_title_label.text = UiCopyType.text(&"ui.vahalla.title_display", "Valhalla").to_upper()
	_intro_label.text = UiCopyType.text(&"ui.vahalla.intro", "Valhalla records Company Manus personnel whose souls are missing, captured, or permanently lost. Recoverable souls remain rescue targets; consumed or shattered souls cannot return.")
	_roster_heading.text = UiCopyType.text(&"ui.vahalla.roster_heading", "FALLEN COMPANY")
	_filter_bar.configure(_fallen_rows, false, RosterFilterType.STATUS_FALLEN, _filter_bar.faction_id)
	_refresh_filter_accessibility()
	_rebuild_memorial()


func _refresh_filter_accessibility() -> void:
	var all_button := _filter_bar.find_child("AllFactionFilter", true, false) as Button
	if all_button != null:
		all_button.tooltip_text = UiCopyType.text(&"ui.roster.filter.all_factions", "All factions")
		all_button.accessibility_name = all_button.tooltip_text
	for faction_id: StringName in FactionHeraldryType.ORDER:
		var button := _filter_bar.find_child("%sFactionFilter" % String(faction_id).to_pascal_case(), true, false) as Button
		if button != null:
			button.tooltip_text = FactionHeraldryType.display_name(faction_id)
			button.accessibility_name = button.tooltip_text
			button.accessibility_description = FactionHeraldryType.specialization(faction_id)


func _on_filters_changed(_status: StringName, _faction_id: StringName) -> void:
	_rebuild_memorial()


func _on_memorial_selected(hero_id: String) -> void:
	_selected_hero_id = hero_id
	Sfx.play("ui_click")
	_rebuild_memorial()


func _on_honor_pressed(hero_id: String) -> void:
	_honored[hero_id] = true
	Sfx.play("ui_click")
	_rebuild_dossier()


func _on_back_pressed() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _apply_responsive_layout() -> void:
	if _header_grid == null or _body_grid == null:
		return
	var portrait := get_viewport_rect().size.y > get_viewport_rect().size.x
	_header_grid.columns = 1 if portrait else 3
	_body_grid.columns = 1 if portrait else 2
	_filter_bar.set_compact(true)
	_filter_bar.set_inline(not portrait)
	var margin := 16 if portrait else 28
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		_screen_margin.add_theme_constant_override(side, margin)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	_roster_panel.custom_minimum_size = Vector2(0 if portrait else 320, 220 if portrait else 0)
	_dossier_panel.custom_minimum_size = Vector2(0 if portrait else 680, 360 if portrait else 0)
	_body_grid.move_child(_dossier_panel, 0 if portrait else 1)
	_rebuild_dossier()


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	Style.apply_label(label, role)
	return label


func _ensure_panel_padding(panel: PanelContainer, padding: float) -> void:
	var style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	style.content_margin_left = maxf(style.content_margin_left, padding)
	style.content_margin_top = maxf(style.content_margin_top, padding)
	style.content_margin_right = maxf(style.content_margin_right, padding)
	style.content_margin_bottom = maxf(style.content_margin_bottom, padding)
	panel.add_theme_stylebox_override(&"panel", style)
