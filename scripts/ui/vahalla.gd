class_name VahallaScreen
extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const RosterFilterType := preload("res://scripts/ui/components/roster_filter.gd")
const RosterFilterBarType := preload("res://scripts/ui/components/roster_filter_bar.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

var _screen_margin: MarginContainer
var _header_grid: GridContainer
var _body_grid: GridContainer
var _roster_panel: PanelContainer
var _dossier_panel: PanelContainer
var _memorial_grid: GridContainer
var _filter_bar: RosterFilterBarType
var _status_label: Label
var _fallen_rows: Array[Dictionary] = []
var _visible_rows: Array[Dictionary] = []
var _memorial_by_hero := {}
var _honored := {}
var _selected_hero_id := ""


func _ready() -> void:
	Game.content = self
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
	var back := Button.new()
	back.name = "BackToCommand"
	back.text = UiCopyType.text(&"ui.vahalla.back", "← COMPANY COMMAND")
	back.custom_minimum_size = Vector2(210, 56)
	back.pressed.connect(_on_back_pressed)
	Style.apply_button(back, &"quiet")
	_header_grid.add_child(back)
	var identity := HBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	identity.add_child(FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 52.0))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_label(UiCopyType.text(&"ui.vahalla.eyebrow", "LUNARIS RELIQUARY • HALL OF THE FALLEN"), &"eyebrow"))
	titles.add_child(_label(UiCopyType.text(&"ui.vahalla.title", "Vahalla").to_upper(), &"title"))
	identity.add_child(titles)
	_header_grid.add_child(identity)
	_status_label = _label("", &"metric")
	_status_label.name = "FallenCount"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_status_label)

	var intro_text := _label(
		UiCopyType.text(&"ui.vahalla.intro", "Those recorded here are no longer deployable. Their service remains part of Company 33."),
		&"detail",
	)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro_text)

	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(_fallen_rows, false, RosterFilterType.STATUS_FALLEN, RosterFilterType.FACTION_ALL)
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
	_roster_panel.custom_minimum_size.x = 360
	_roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_roster_panel, &"quiet")
	_body_grid.add_child(_roster_panel)
	var roster_stack := VBoxContainer.new()
	roster_stack.add_theme_constant_override(&"separation", 10)
	_roster_panel.add_child(roster_stack)
	var roster_heading := _label("FALLEN COMPANY", &"heading")
	roster_stack.add_child(roster_heading)
	var scroll := ScrollContainer.new()
	scroll.name = "VahallaMemorialScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_stack.add_child(scroll)
	_memorial_grid = GridContainer.new()
	_memorial_grid.name = "VahallaMemorialGrid"
	_memorial_grid.columns = 1
	_memorial_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_memorial_grid.add_theme_constant_override(&"v_separation", 8)
	scroll.add_child(_memorial_grid)

	_dossier_panel = PanelContainer.new()
	_dossier_panel.name = "MemorialDossier"
	_dossier_panel.custom_minimum_size.x = 620
	_dossier_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dossier_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_dossier_panel, &"memorial")
	_body_grid.add_child(_dossier_panel)
	_rebuild_memorial()


func _rebuild_memorial() -> void:
	for child: Node in _memorial_grid.get_children():
		_memorial_grid.remove_child(child)
		child.queue_free()
	_visible_rows = RosterFilterType.filter_rows(_fallen_rows, RosterFilterType.STATUS_FALLEN, _filter_bar.faction_id)
	_status_label.text = "%d %s" % [_visible_rows.size(), UiCopyType.text(&"ui.vahalla.fallen_count", "FALLEN")]
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
	row.custom_minimum_size = Vector2(0, 82)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.text = "%s\n%s · %s" % [
		TrainingSupportType.callsign(hero).to_upper(),
		_class_name(String(hero["current_class_id"])).to_upper(),
		FactionHeraldryType.display_name(StringName(hero["faction_id"])).to_upper(),
	]
	row.tooltip_text = row.text
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.pressed.connect(_on_memorial_selected.bind(hero_id))
	Style.apply_button(row, &"selected" if hero_id == _selected_hero_id else &"quiet")
	return row


func _rebuild_dossier() -> void:
	for child: Node in _dossier_panel.get_children():
		_dossier_panel.remove_child(child)
		child.queue_free()
	if _selected_hero_id.is_empty():
		var empty := _label("NO MEMORIAL RECORD SELECTED", &"body")
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
	portrait.custom_minimum_size = Vector2(260, 360)
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
	var terminal := _label("TERMINAL SERVICE RECORD", &"eyebrow")
	terminal.add_theme_color_override(&"font_color", Style.DANGER)
	details.add_child(terminal)
	var record := _label(_death_record(hero), &"body")
	record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(record)
	var continuity := _label("Identity sealed by stable hero record. Ordinary loss remains permanent.", &"detail")
	continuity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(continuity)
	var honor := Button.new()
	honor.name = "Honor_%s" % _selected_hero_id
	honor.text = (
		UiCopyType.text(&"ui.vahalla.honored", "HONORED")
		if _honored.has(_selected_hero_id)
		else UiCopyType.text(&"ui.vahalla.honor", "HONOR MEMORY")
	).to_upper()
	honor.custom_minimum_size = Vector2(0, 58)
	honor.disabled = _honored.has(_selected_hero_id)
	honor.pressed.connect(_on_honor_pressed.bind(_selected_hero_id))
	Style.apply_button(honor, &"selected" if honor.disabled else &"gold")
	details.add_child(honor)
	if get_viewport_rect().size.y > get_viewport_rect().size.x:
		layout.columns = 1
		portrait.custom_minimum_size = Vector2(0, 300)


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
	var stage_id := String(death.get("stage_id", "unknown")).to_upper()
	var reason := String(death.get("terminal_reason", "fallen")).replace("_", " ").to_upper()
	return UiCopyType.format_text(&"ui.vahalla.record", "FELL AT {stage} • {reason} • TICK {tick}", {
		&"stage": stage_id,
		&"reason": reason,
		&"tick": int(death.get("terminal_tick", 0)),
	})


func _class_name(class_id: String) -> String:
	var definition := TrainingSupportType.class_definition(class_id)
	return definition.name if definition != null else class_id.replace("_", " ").capitalize()


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
	_filter_bar.set_compact(portrait)
	var margin := 16 if portrait else 28
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		_screen_margin.add_theme_constant_override(side, margin)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	_roster_panel.custom_minimum_size = Vector2(0 if portrait else 360, 230 if portrait else 0)
	_dossier_panel.custom_minimum_size = Vector2(0 if portrait else 620, 520 if portrait else 0)
	_body_grid.move_child(_dossier_panel, 0 if portrait else 1)
	_rebuild_dossier()


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_label(label, role)
	return label
