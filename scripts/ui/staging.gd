extends Control

## Premium responsive campaign command hub. Game remains authoritative; this
## screen only projects campaign, narrative, and training state into presentation.

const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload(
	"res://data/presentation/narrative/stage_narrative_catalog.gd"
)
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const StagingCommandTileType := preload(
	"res://scripts/ui/components/staging_command_tile.gd"
)
const StagingGlyphType := preload("res://scripts/ui/components/staging_glyph.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const STAGING_THEME := preload("res://data/presentation/ui/threshold_theme.tres")
const HERO_ART := preload("res://assets/loading/lunaris_reliquary_loading.png")
const MISSION_ART := preload("res://assets/world/act1/panorama.png")

const GOLD := Color("d8b978")
const BRIGHT_GOLD := Color("efcf8e")
const MOON_CYAN := Color("86cbd4")
const IVORY := Color("eee8dc")
const MUTED := Color("aebdc3")
const VOID := Color("071019")
const DEEP_NAVY := Color("0a1724")
const GLASS := Color(0.012, 0.03, 0.048, 0.94)
const CARD_GLASS := Color(0.018, 0.043, 0.065, 0.95)

var _mission: AetheriaButtonType = null
var _training: StagingCommandTileType = null
var _back: Button = null
var _next_record: StageNarrativeDefType = null
var _next_stage: StageDef = null
var _narrative_missing := false
var _training_acknowledgement: Array[Dictionary] = []

var _landscape_layout: HBoxContainer = null
var _landscape_host: MarginContainer = null
var _landscape_deck: PanelContainer = null
var _portrait_layout: VBoxContainer = null
var _portrait_host: MarginContainer = null
var _portrait_sheet: PanelContainer = null
var _portrait_spacer: Control = null
var _command_content: VBoxContainer = null
var _mission_grid: GridContainer = null
var _operation_grid: GridContainer = null
var _hero_identity: VBoxContainer = null
var _campaign_chip: Label = null
var _top_identity: Label = null
var _top_status_chip: PanelContainer = null
var _top_summary: Label = null
var _hero_art: TextureRect = null
var _command_tiles: Array[StagingCommandTileType] = []
var _portrait := false


func _ready() -> void:
	theme = STAGING_THEME
	Game.content = self
	_training_acknowledgement = Game.training_call(&"peek_acknowledgement") as Array[Dictionary]
	_resolve_next_operation()
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	(_back if _mission.disabled else _mission).grab_focus.call_deferred()
	if not _training_acknowledgement.is_empty():
		Game.training_call(&"consume_acknowledgement")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_title()


func _resolve_next_operation() -> void:
	if Game.campaign == null:
		return
	var stars := _stage_stars()
	for stage_id: StringName in Game.campaign_stage_ids():
		if Game.is_stage_unlocked(stage_id) and not stars.has(stage_id):
			_next_stage = load("res://data/stages/%s.tres" % stage_id) as StageDef
			_next_record = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
			_narrative_missing = _next_record == null
			return


func _build_screen() -> void:
	_build_backdrop()
	_build_top_bar()
	_command_content = _build_command_content()
	_build_landscape_layout()
	_build_portrait_layout()


func _build_backdrop() -> void:
	_hero_art = TextureRect.new()
	_hero_art.name = "LunarisHeroArt"
	_hero_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero_art.texture = HERO_ART
	_hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hero_art)

	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.002, 0.012, 0.025, 0.18)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)

	var bottom_shade := ColorRect.new()
	bottom_shade.name = "BottomShade"
	bottom_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -230.0
	bottom_shade.color = Color(VOID, 0.74)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.name = "TopCommandBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 72.0
	bar.add_theme_stylebox_override(&"panel", _panel_style(
		Color(0.004, 0.017, 0.029, 0.93), Color(MOON_CYAN, 0.28), 1, 0,
	))
	add_child(bar)

	var margin := MarginContainer.new()
	margin.name = "TopBarMargin"
	margin.add_theme_constant_override(&"margin_left", 28)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_right", 24)
	margin.add_theme_constant_override(&"margin_bottom", 10)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "TopBarContent"
	row.add_theme_constant_override(&"separation", 14)
	margin.add_child(row)

	var crest := StagingGlyphType.new()
	crest.name = "FactionCrest"
	crest.kind = StagingGlyphType.Kind.CREST
	crest.custom_minimum_size = Vector2(42.0, 42.0)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(crest)

	_top_identity = _label("FactionIdentity", "LUNARIS RELIQUARY\nCOMPANY 33", GameTypographyType.STATUS, IVORY)
	_top_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_top_identity)

	_top_status_chip = PanelContainer.new()
	_top_status_chip.name = "CampaignStatusChip"
	_top_status_chip.add_theme_stylebox_override(&"panel", _panel_style(
		Color(0.02, 0.055, 0.077, 0.86), Color(GOLD, 0.42), 1, 3,
	))
	_top_status_chip.custom_minimum_size = Vector2(126.0, 40.0)
	row.add_child(_top_status_chip)
	_top_summary = _label("TopCampaignSummary", _campaign_summary_text(), GameTypographyType.STATUS, IVORY)
	_top_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_status_chip.add_child(_top_summary)

	_back = Button.new()
	_back.name = "BackToTitleButton"
	_back.text = UiCopyType.text(&"ui.common.back_to_title", "Back to Title")
	_back.tooltip_text = _back.text
	_back.custom_minimum_size = Vector2(122.0, 44.0)
	_back.add_theme_font_size_override(&"font_size", GameTypographyType.DETAIL)
	_back.add_theme_color_override(&"font_color", MUTED)
	_back.add_theme_color_override(&"font_hover_color", IVORY)
	_back.add_theme_color_override(&"font_pressed_color", GOLD)
	_back.add_theme_color_override(&"font_focus_color", IVORY)
	_back.add_theme_stylebox_override(&"normal", _panel_style(Color(VOID, 0.18), Color(MUTED, 0.24), 1, 3))
	_back.add_theme_stylebox_override(&"hover", _panel_style(Color(DEEP_NAVY, 0.9), MOON_CYAN, 1, 3))
	_back.add_theme_stylebox_override(&"pressed", _panel_style(Color(DEEP_NAVY, 1.0), GOLD, 1, 3))
	_back.add_theme_stylebox_override(&"focus", _panel_style(Color(MOON_CYAN, 0.08), GOLD, 2, 3))
	_back.pressed.connect(_on_back_to_title)
	row.add_child(_back)

	var top_rule := ColorRect.new()
	top_rule.name = "TopGoldRule"
	top_rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_rule.offset_bottom = 2.0
	top_rule.color = Color(GOLD, 0.88)
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_rule)


func _build_landscape_layout() -> void:
	_landscape_layout = HBoxContainer.new()
	_landscape_layout.name = "LandscapeLayout"
	_landscape_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_landscape_layout.offset_left = 34.0
	_landscape_layout.offset_top = 94.0
	_landscape_layout.offset_right = -34.0
	_landscape_layout.offset_bottom = -28.0
	_landscape_layout.add_theme_constant_override(&"separation", 28)
	add_child(_landscape_layout)

	var hero_region := MarginContainer.new()
	hero_region.name = "HeroRegion"
	hero_region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_region.size_flags_stretch_ratio = 1.35
	hero_region.add_theme_constant_override(&"margin_left", 18)
	hero_region.add_theme_constant_override(&"margin_bottom", 16)
	_landscape_layout.add_child(hero_region)

	_hero_identity = VBoxContainer.new()
	_hero_identity.name = "HeroIdentity"
	_hero_identity.size_flags_vertical = Control.SIZE_SHRINK_END
	_hero_identity.add_theme_constant_override(&"separation", 2)
	hero_region.add_child(_hero_identity)

	var eyebrow := _label(
		"HeroEyebrow", UiCopyType.text(&"ui.staging.command_heading", "COMPANY 33 COMMAND"),
		GameTypographyType.STATUS, GOLD,
	)
	_hero_identity.add_child(eyebrow)
	var title := _label("HeroFactionTitle", "LUNARIS", 34, IVORY)
	title.add_theme_constant_override(&"outline_size", 8)
	title.add_theme_color_override(&"font_outline_color", Color(VOID, 0.82))
	_hero_identity.add_child(title)
	var subtitle := _label("HeroFactionSubtitle", "R E L I Q U A R Y", GameTypographyType.CAPTION, MUTED)
	_hero_identity.add_child(subtitle)
	_campaign_chip = _label("HeroCampaignProgress", _campaign_summary_text(), GameTypographyType.DETAIL, MOON_CYAN)
	_campaign_chip.add_theme_constant_override(&"outline_size", 6)
	_campaign_chip.add_theme_color_override(&"font_outline_color", Color(VOID, 0.88))
	_hero_identity.add_child(_campaign_chip)

	_landscape_deck = PanelContainer.new()
	_landscape_deck.name = "CommandDeck"
	_landscape_deck.custom_minimum_size.x = 470.0
	_landscape_deck.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landscape_deck.size_flags_stretch_ratio = 0.92
	_landscape_deck.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_deck.add_theme_stylebox_override(&"panel", _panel_style(
		GLASS, Color(GOLD, 0.58), 1, 4,
	))
	_landscape_layout.add_child(_landscape_deck)
	_landscape_host = _build_scroll_host(_landscape_deck, "LandscapeCommandScroll")


func _build_portrait_layout() -> void:
	_portrait_layout = VBoxContainer.new()
	_portrait_layout.name = "PortraitLayout"
	_portrait_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_layout.offset_left = 18.0
	_portrait_layout.offset_top = 76.0
	_portrait_layout.offset_right = -18.0
	_portrait_layout.offset_bottom = -12.0
	_portrait_layout.add_theme_constant_override(&"separation", 0)
	add_child(_portrait_layout)

	_portrait_spacer = Control.new()
	_portrait_spacer.name = "HeroStage"
	_portrait_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_layout.add_child(_portrait_spacer)

	_portrait_sheet = PanelContainer.new()
	_portrait_sheet.name = "CommandSheet"
	_portrait_sheet.custom_minimum_size.y = 650.0
	_portrait_sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_sheet.size_flags_vertical = Control.SIZE_SHRINK_END
	_portrait_sheet.add_theme_stylebox_override(&"panel", _panel_style(
		Color(GLASS, 0.975), Color(GOLD, 0.65), 1, 5,
	))
	_portrait_layout.add_child(_portrait_sheet)
	_portrait_host = _build_scroll_host(_portrait_sheet, "PortraitCommandScroll")


func _build_scroll_host(panel: PanelContainer, node_name: String) -> MarginContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.name = "%sMargin" % node_name
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override(&"margin_left", 22)
	margin.add_theme_constant_override(&"margin_top", 20)
	margin.add_theme_constant_override(&"margin_right", 22)
	margin.add_theme_constant_override(&"margin_bottom", 20)
	scroll.add_child(margin)
	return margin


func _build_command_content() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.name = "CommandContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", 10)

	var progress_row := HBoxContainer.new()
	progress_row.name = "CampaignProgressRow"
	progress_row.add_theme_constant_override(&"separation", 10)
	content.add_child(progress_row)
	var progress_glyph := StagingGlyphType.new()
	progress_glyph.name = "CampaignGlyph"
	progress_glyph.kind = StagingGlyphType.Kind.CREST
	progress_glyph.custom_minimum_size = Vector2(28.0, 28.0)
	progress_row.add_child(progress_glyph)
	var command_title := _label(
		"CommandHeading", UiCopyType.text(&"ui.staging.command_heading", "COMPANY 33 COMMAND"),
		GameTypographyType.STATUS, GOLD,
	)
	command_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	command_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	command_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_row.add_child(command_title)
	var progress_text := _label(
		"CampaignProgressText", _campaign_summary_text(), GameTypographyType.STATUS, IVORY,
	)
	progress_text.custom_minimum_size.x = 116.0
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_row.add_child(progress_text)

	var progress := ProgressBar.new()
	progress.name = "CampaignProgress"
	progress.custom_minimum_size.y = 4.0
	progress.max_value = 1.0
	progress.value = _campaign_progress()
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override(&"background", _bar_style(Color(MUTED, 0.18)))
	progress.add_theme_stylebox_override(&"fill", _bar_style(MOON_CYAN))
	content.add_child(progress)

	var next_label := _label(
		"NextOperationLabel", UiCopyType.text(&"ui.staging.next_label", "NEXT OPERATION"),
		GameTypographyType.BADGE, GOLD,
	)
	content.add_child(next_label)
	content.add_child(_build_mission_card())

	_mission = _build_mission_button()
	_mission.pressed.connect(_on_mission_control)
	content.add_child(_mission)

	if not _training_acknowledgement.is_empty():
		content.add_child(_build_acknowledgement())

	var operation_heading := HBoxContainer.new()
	operation_heading.name = "OperationsHeading"
	operation_heading.add_theme_constant_override(&"separation", 10)
	content.add_child(operation_heading)
	var operations_label := _label(
		"OperationsLabel", UiCopyType.text(&"ui.staging.operations", "OPERATIONS"),
		GameTypographyType.BADGE, GOLD,
	)
	operations_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operation_heading.add_child(operations_label)
	var operation_rule := ColorRect.new()
	operation_rule.name = "OperationsRule"
	operation_rule.custom_minimum_size = Vector2(80.0, 1.0)
	operation_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operation_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	operation_rule.color = Color(MOON_CYAN, 0.32)
	operation_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	operation_heading.add_child(operation_rule)

	_operation_grid = GridContainer.new()
	_operation_grid.name = "OperationGrid"
	_operation_grid.columns = 2
	_operation_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_grid.add_theme_constant_override(&"h_separation", 10)
	_operation_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_operation_grid)

	_add_locked_operation(
		"BarracksButton", StagingGlyphType.Kind.BARRACKS,
		&"ui.staging.barracks_short", "Barracks",
		&"ui.staging.barracks_unavailable", "Barracks — Unavailable",
	)
	_add_locked_operation(
		"RecruitButton", StagingGlyphType.Kind.RECRUIT,
		&"ui.staging.recruit_short", "Recruit",
		&"ui.staging.recruit_unavailable", "Recruit — Unavailable",
	)
	_add_locked_operation(
		"ArmoryButton", StagingGlyphType.Kind.ARMORY,
		&"ui.staging.armory_short", "Armory",
		&"ui.staging.armory_unavailable", "Armory — Unavailable",
	)
	_add_locked_operation(
		"MemorialButton", StagingGlyphType.Kind.MEMORIAL,
		&"ui.staging.memorial_short", "Memorial",
		&"ui.staging.memorial_unavailable", "Memorial — Unavailable",
	)

	var training_available := _training_available()
	_training = StagingCommandTileType.new()
	_training.name = "TrainingButton"
	_training.configure(
		StagingGlyphType.Kind.TRAINING,
		UiCopyType.text(&"ui.staging.training_short", "Training"),
		UiCopyType.text(
			&"ui.staging.training" if training_available else &"ui.staging.training_unavailable",
			"Training" if training_available else "Training — Unavailable",
		),
		training_available,
	)
	_training.pressed.connect(_on_training)
	_command_tiles.append(_training)
	content.add_child(_training)
	return content


func _build_mission_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "NextOperationCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(&"panel", _panel_style(
		CARD_GLASS, Color(MOON_CYAN, 0.34), 1, 3,
	))

	var margin := MarginContainer.new()
	margin.name = "MissionCardMargin"
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_bottom", 12)
	card.add_child(margin)

	_mission_grid = GridContainer.new()
	_mission_grid.name = "MissionCardGrid"
	_mission_grid.columns = 2
	_mission_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_grid.add_theme_constant_override(&"h_separation", 14)
	_mission_grid.add_theme_constant_override(&"v_separation", 8)
	margin.add_child(_mission_grid)

	var preview := TextureRect.new()
	preview.name = "MissionPreview"
	preview.custom_minimum_size = Vector2(168.0, 96.0)
	preview.texture = MISSION_ART
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.modulate = Color(0.70, 0.88, 0.95, 0.92)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_grid.add_child(preview)

	var details := VBoxContainer.new()
	details.name = "MissionDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override(&"separation", 5)
	_mission_grid.add_child(details)
	var mission_title := _label(
		"NextOperationTitle", _next_operation_title(), GameTypographyType.BODY, IVORY,
	)
	mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(mission_title)
	var objective := _label(
		"NextOperationObjective", _next_operation_objective(), GameTypographyType.DETAIL, MUTED,
	)
	objective.size_flags_vertical = Control.SIZE_EXPAND_FILL
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details.add_child(objective)
	return card


func _build_mission_button() -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = "MissionControlButton"
	var full_text := UiCopyType.text(&"ui.staging.mission_control", "Mission Control")
	button.set_presentation_text(full_text, full_text.to_upper())
	button.tooltip_text = full_text
	button.disabled = _narrative_missing
	button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0.0, 60.0)
	var label := button.get_node("PresentationLabel") as Label
	label.add_theme_font_size_override(&"font_size", GameTypographyType.ACTION)
	label.add_theme_color_override(&"font_color", VOID if not button.disabled else MUTED)
	button.add_theme_stylebox_override(&"normal", _panel_style(
		Color("c7a25c") if not button.disabled else Color(DEEP_NAVY, 0.78),
		BRIGHT_GOLD if not button.disabled else Color(MUTED, 0.32), 1, 3,
	))
	button.add_theme_stylebox_override(&"hover", _panel_style(Color("e0bd73"), IVORY, 2, 3))
	button.add_theme_stylebox_override(&"pressed", _panel_style(Color("8d6d38"), MOON_CYAN, 2, 3))
	button.add_theme_stylebox_override(&"disabled", _panel_style(
		Color(DEEP_NAVY, 0.78), Color(MUTED, 0.32), 1, 3,
	))
	button.add_theme_stylebox_override(&"focus", _panel_style(Color(GOLD, 0.18), MOON_CYAN, 2, 3))
	return button


func _build_acknowledgement() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "TrainingAcknowledgement"
	panel.add_theme_stylebox_override(&"panel", _panel_style(
		Color(MOON_CYAN, 0.08), Color(MOON_CYAN, 0.46), 1, 3,
	))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_bottom", 8)
	panel.add_child(margin)
	margin.add_child(_label(
		"TrainingAcknowledgementText", _training_acknowledgement_text(),
		GameTypographyType.DETAIL, MOON_CYAN,
	))
	return panel


func _add_locked_operation(
	node_name: String,
	glyph_kind: StagingGlyphType.Kind,
	short_key: StringName,
	short_fallback: String,
	full_key: StringName,
	full_fallback: String,
) -> void:
	var tile := StagingCommandTileType.new()
	tile.name = node_name
	tile.configure(
		glyph_kind,
		UiCopyType.text(short_key, short_fallback),
		UiCopyType.text(full_key, full_fallback),
		false,
	)
	_command_tiles.append(tile)
	_operation_grid.add_child(tile)


func _connect_focus_cycle() -> void:
	var actions: Array[Control] = [_mission, _back]
	if _training != null and not _training.disabled:
		actions.append(_training)
	for index: int in actions.size():
		var current := actions[index]
		var previous := actions[(index - 1 + actions.size()) % actions.size()]
		var following := actions[(index + 1) % actions.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_neighbor_right = current.get_path_to(following)


func _apply_responsive_layout() -> void:
	if _landscape_layout == null or _portrait_layout == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_portrait = viewport_size.y > viewport_size.x
	_landscape_layout.visible = not _portrait
	_portrait_layout.visible = _portrait
	_reparent_command_content(_portrait_host if _portrait else _landscape_host)

	var compact := viewport_size.x < 1120.0 or viewport_size.y < 700.0
	var gutter := 20.0 if compact else 34.0
	_landscape_layout.offset_left = gutter
	_landscape_layout.offset_right = -gutter
	_landscape_layout.offset_top = 86.0 if compact else 94.0
	_landscape_layout.offset_bottom = -20.0 if compact else -28.0
	_landscape_deck.custom_minimum_size.x = clampf(viewport_size.x * 0.41, 410.0, 520.0)
	_hero_identity.visible = viewport_size.x >= 1040.0

	_portrait_layout.offset_left = 12.0 if viewport_size.x < 620.0 else 18.0
	_portrait_layout.offset_right = -_portrait_layout.offset_left
	_portrait_sheet.custom_minimum_size.y = clampf(viewport_size.y * 0.55, 540.0, 710.0)
	_top_status_chip.visible = viewport_size.x >= 560.0
	_top_identity.text = "LUNARIS RELIQUARY\nCOMPANY 33" if viewport_size.x >= 560.0 else "LUNARIS\nCOMPANY 33"
	_back.text = (
		UiCopyType.text(&"ui.common.back", "Back")
		if _portrait or viewport_size.x < 920.0
		else UiCopyType.text(&"ui.common.back_to_title", "Back to Title")
	)
	_back.custom_minimum_size.x = 72.0 if _portrait else 122.0

	var narrow_command := _portrait and viewport_size.x < 560.0
	_mission_grid.columns = 1 if narrow_command else 2
	var preview := _mission_grid.get_node("MissionPreview") as TextureRect
	preview.custom_minimum_size = (
		Vector2(0.0, 96.0) if narrow_command else Vector2(168.0, 96.0)
	)
	for tile: StagingCommandTileType in _command_tiles:
		tile.set_compact(compact)
	_connect_focus_cycle()


func _reparent_command_content(target: MarginContainer) -> void:
	if _command_content == null or target == null or _command_content.get_parent() == target:
		return
	var previous := _command_content.get_parent()
	if previous != null:
		previous.remove_child(_command_content)
	target.add_child(_command_content)


func _campaign_summary_text() -> String:
	var stage_ids: Array[StringName] = Game.campaign_stage_ids()
	var cleared := 0
	if Game.campaign != null:
		var stars := _stage_stars()
		for stage_id: StringName in stage_ids:
			if stars.has(stage_id):
				cleared += 1
	return UiCopyType.format_text(
		&"ui.staging.campaign_summary", "{cleared}/{total} CLEARED",
		{&"cleared": cleared, &"total": stage_ids.size()},
	)


func _campaign_progress() -> float:
	var stage_ids := Game.campaign_stage_ids()
	if stage_ids.is_empty():
		return 0.0
	var cleared := 0
	var stars := _stage_stars()
	for stage_id: StringName in stage_ids:
		if stars.has(stage_id):
			cleared += 1
	return float(cleared) / float(stage_ids.size())


func _next_operation_title() -> String:
	if Game.campaign == null:
		return UiCopyType.text(&"ui.staging.next_none", "NEXT: No active campaign")
	if _next_stage == null:
		return UiCopyType.text(&"ui.staging.next_complete", "NEXT: Campaign complete")
	return UiCopyType.format_text(
		&"ui.staging.next_operation_title", "NEXT {index}: {title}",
		{
			&"index": _next_stage.campaign_index,
			&"title": UiCopyType.stage_title(_next_stage),
		},
	)


func _next_operation_objective() -> String:
	if _narrative_missing:
		return UiCopyType.text(
			&"ui.error.missing_stage_narrative",
			"Mission record unavailable. Return to Mission Control.",
		)
	if _next_record == null:
		return UiCopyType.text(
			&"ui.staging.command_body",
			"Commander, the Great Flare damaged connected systems and the evacuation remains unfinished.",
		)
	return UiCopyType.stage_narrative_text(_next_record, StageNarrativeDefType.Field.OBJECTIVE)


func _on_mission_control() -> void:
	if _narrative_missing:
		return
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_training() -> void:
	if not _training_available():
		return
	Sfx.play("ui_click")
	Game.training_call(&"open", &"staging")


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _training_available() -> bool:
	return int(Game.training_call(&"eligible_count")) > 0


func _training_acknowledgement_text() -> String:
	var entries: Array[String] = []
	for row: Dictionary in _training_acknowledgement:
		var summary := TrainingSupportType.summary_by_id(Game.campaign, String(row["hero_id"]))
		var definition := TrainingSupportType.class_definition(String(row["to_class_id"]))
		if summary.is_empty() or definition == null:
			continue
		entries.append(UiCopyType.format_text(
			&"ui.training.ack_entry", "{callsign} to {class_name}",
			{
				&"callsign": String(summary["callsign"]),
				&"class_name": UiCopyType.text(definition.name_key, definition.name),
			},
		))
	return UiCopyType.format_text(
		&"ui.training.acknowledgement", "Training complete: {assignments}",
		{&"assignments": ", ".join(entries)},
	)


func _stage_stars() -> Dictionary:
	if Game.campaign == null:
		return {}
	return Game.campaign_projection()["stage_stars"]


func _label(
	label_name: String,
	label_text: String,
	font_size: int,
	color: Color,
) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = label_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(
	fill: Color,
	border: Color,
	border_width: int,
	corner_radius: int,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style
