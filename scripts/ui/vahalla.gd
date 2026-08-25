class_name VahallaScreen
extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const RosterFilterType := preload("res://scripts/ui/components/roster_filter.gd")
const RosterFilterBarType := preload("res://scripts/ui/components/roster_filter_bar.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")

var _screen_margin: MarginContainer
var _header_grid: GridContainer
var _memorial_grid: GridContainer
var _filter_bar: RosterFilterBarType
var _status_label: Label
var _fallen_rows: Array[Dictionary] = []
var _memorial_by_hero := {}
var _honored := {}


func _ready() -> void:
	Game.content = self
	Style.add_backdrop(self)
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
	content.add_theme_constant_override(&"separation", 16)
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
	back.pressed.connect(_on_back_pressed)
	Style.apply_button(back, &"quiet")
	_header_grid.add_child(back)
	var identity := HBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	identity.add_child(FactionHeraldryType.make_symbol(
		FactionHeraldryType.ACTIVE_FACTION, 52.0,
	))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_label(
		UiCopyType.text(&"ui.vahalla.eyebrow", "LUNARIS RELIQUARY • HALL OF THE FALLEN"),
		&"eyebrow",
	))
	titles.add_child(_label(UiCopyType.text(&"ui.vahalla.title", "Vahalla"), &"title"))
	identity.add_child(titles)
	_header_grid.add_child(identity)
	_status_label = _label("", &"metric")
	_status_label.name = "FallenCount"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_status_label)

	var intro := PanelContainer.new()
	Style.apply_panel(intro, &"quiet")
	content.add_child(intro)
	var intro_text := _label(
		UiCopyType.text(
			&"ui.vahalla.intro",
			"Those recorded here are no longer deployable. Their service remains part of Company 33.",
		),
		&"body",
	)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_child(intro_text)

	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(
		_fallen_rows, false, RosterFilterType.STATUS_FALLEN, RosterFilterType.FACTION_ALL,
	)
	_filter_bar.filters_changed.connect(_on_filters_changed)
	content.add_child(_filter_bar)

	var scroll := ScrollContainer.new()
	scroll.name = "VahallaMemorialScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_memorial_grid = GridContainer.new()
	_memorial_grid.name = "VahallaMemorialGrid"
	_memorial_grid.columns = 2
	_memorial_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_memorial_grid.add_theme_constant_override(&"h_separation", 14)
	_memorial_grid.add_theme_constant_override(&"v_separation", 14)
	scroll.add_child(_memorial_grid)
	_rebuild_memorial()


func _rebuild_memorial() -> void:
	for child: Node in _memorial_grid.get_children():
		_memorial_grid.remove_child(child)
		child.queue_free()
	var visible := RosterFilterType.filter_rows(
		_fallen_rows, RosterFilterType.STATUS_FALLEN, _filter_bar.faction_id,
	)
	_status_label.text = "%d %s" % [
		visible.size(),
		UiCopyType.text(&"ui.vahalla.fallen_count", "FALLEN"),
	]
	if visible.is_empty():
		var empty := _label(
			UiCopyType.text(
				&"ui.vahalla.empty",
				"No fallen soldiers are recorded for this faction.",
			),
			&"body",
		)
		empty.name = "VahallaEmptyState"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_memorial_grid.add_child(empty)
		return
	for hero: Dictionary in visible:
		_memorial_grid.add_child(_memorial_card(hero))


func _memorial_card(hero: Dictionary) -> PanelContainer:
	var hero_id := String(hero["hero_id"])
	var card := PanelContainer.new()
	card.name = "Memorial_%s" % hero_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(420.0, 230.0)
	Style.apply_panel(card, &"danger")
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	card.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = Art.texture(StringName(hero["portrait_asset_id"]))
	portrait.custom_minimum_size = Vector2(150.0, 205.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override(&"separation", 7)
	row.add_child(details)
	var faction_id := StringName(hero["faction_id"])
	var faction_row := HBoxContainer.new()
	faction_row.add_theme_constant_override(&"separation", 8)
	faction_row.add_child(FactionHeraldryType.make_symbol(faction_id, 34.0))
	var faction := _label(FactionHeraldryType.display_name(faction_id), &"eyebrow")
	faction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	faction_row.add_child(faction)
	details.add_child(faction_row)
	details.add_child(_label(TrainingSupportType.callsign(hero).to_upper(), &"heading"))
	details.add_child(_label(_class_name(String(hero["current_class_id"])).to_upper(), &"detail"))
	details.add_child(_label(_death_record(hero), &"detail"))
	var honor := Button.new()
	honor.name = "Honor_%s" % hero_id
	honor.text = (
		UiCopyType.text(&"ui.vahalla.honored", "HONORED")
		if _honored.has(hero_id)
		else UiCopyType.text(&"ui.vahalla.honor", "HONOR")
	).to_upper()
	honor.disabled = _honored.has(hero_id)
	honor.pressed.connect(_on_honor_pressed.bind(hero_id))
	Style.apply_button(honor, &"selected" if honor.disabled else &"gold")
	details.add_child(honor)
	return card


func _death_record(hero: Dictionary) -> String:
	var hero_id := String(hero["hero_id"])
	var memorial: Dictionary = _memorial_by_hero.get(hero_id, {})
	var death: Dictionary = memorial.get("death", hero.get("death", {}))
	if death.is_empty():
		return UiCopyType.text(&"ui.vahalla.record_unknown", "SERVICE RECORD SEALED")
	var stage_id := String(death.get("stage_id", "unknown")).to_upper()
	var reason := String(death.get("terminal_reason", "fallen")).replace("_", " ").to_upper()
	return UiCopyType.format_text(
		&"ui.vahalla.record",
		"FELL AT {stage} • {reason} • TICK {tick}",
		{
			&"stage": stage_id,
			&"reason": reason,
			&"tick": int(death.get("terminal_tick", 0)),
		},
	)


func _class_name(class_id: String) -> String:
	var definition := TrainingSupportType.class_definition(class_id)
	return definition.name if definition != null else class_id.replace("_", " ").capitalize()


func _on_filters_changed(_status: StringName, _faction_id: StringName) -> void:
	_rebuild_memorial()


func _on_honor_pressed(hero_id: String) -> void:
	_honored[hero_id] = true
	Sfx.play("ui_click")
	_rebuild_memorial()


func _on_back_pressed() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _apply_responsive_layout() -> void:
	var portrait := get_viewport_rect().size.x < 900.0
	_header_grid.columns = 1 if portrait else 3
	_memorial_grid.columns = 1 if portrait else 2
	_filter_bar.set_compact(portrait)
	var margin := 18 if portrait else 38
	_screen_margin.add_theme_constant_override(&"margin_left", margin)
	_screen_margin.add_theme_constant_override(&"margin_top", margin)
	_screen_margin.add_theme_constant_override(&"margin_right", margin)
	_screen_margin.add_theme_constant_override(&"margin_bottom", margin)
	_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	)


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_label(label, role)
	return label
