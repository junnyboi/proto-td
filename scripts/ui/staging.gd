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
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const LunarisBackdropType := preload(
	"res://scripts/ui/components/lunaris_animated_backdrop.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const STAGING_THEME := preload("res://data/presentation/ui/threshold_theme.tres")
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
const FOCUS_PULSE_SECONDS := 2.8
const FOCUS_PULSE_MIN_ALPHA := 0.12
const FOCUS_PULSE_MAX_ALPHA := 0.28
const TOP_HUD_HEIGHT := 128.0
const LANDSCAPE_GUTTER := 24.0
const LANDSCAPE_BOTTOM_GUTTER := 16.0
const LANDSCAPE_NAV_WIDTH := 440.0
const LANDSCAPE_DECK_MIN_WIDTH := 620.0
const LANDSCAPE_DECK_MAX_WIDTH := 700.0
const LANDSCAPE_DECK_MAX_HEIGHT := 760.0
const PORTRAIT_SHEET_MIN_HEIGHT := 760.0
const PORTRAIT_SHEET_MAX_HEIGHT := 860.0
const INTRA_GROUP_GAP := 12
const MAJOR_SECTION_GAP := 24

var _mission: AetheriaButtonType = null
var _recruit: StagingCommandTileType = null
var _vahalla: StagingCommandTileType = null
var _training: StagingCommandTileType = null
var _archive: StagingCommandTileType = null
var _back: Button = null
var _next_record: StageNarrativeDefType = null
var _next_stage: StageDef = null
var _narrative_missing := false
var _training_acknowledgement: Array[Dictionary] = []

var _landscape_layout: HBoxContainer = null
var _landscape_host: MarginContainer = null
var _landscape_deck: PanelContainer = null
var _landscape_command_stack: VBoxContainer = null
var _landscape_navigation: PanelContainer = null
var _landscape_navigation_host: MarginContainer = null
var _portrait_layout: VBoxContainer = null
var _portrait_host: MarginContainer = null
var _portrait_sheet: PanelContainer = null
var _portrait_spacer: Control = null
var _portrait_stack: VBoxContainer = null
var _command_content: VBoxContainer = null
var _navigation_content: VBoxContainer = null
var _mission_card: PanelContainer = null
var _mission_grid: GridContainer = null
var _mission_body_grid: GridContainer = null
var _mission_preview: TextureRect = null
var _operation_grid: GridContainer = null
var _operation_scroll: ScrollContainer = null
var _top_identity: Label = null
var _top_identity_plate: PanelContainer = null
var _top_status_chip: PanelContainer = null
var _top_summary: Label = null
var _top_bar: PanelContainer = null
var _top_bar_margin: MarginContainer = null
var _top_row: HBoxContainer = null
var _top_crest: TextureRect = null
var _exit_plate: PanelContainer = null
var _exit_label: Label = null
var _command_heading: Label = null
var _campaign_progress_text: Label = null
var _next_operation_label: Label = null
var _mission_title: Label = null
var _mission_objective: Label = null
var _mission_action_label: Label = null
var _operations_label: Label = null
var _backdrop: LunarisBackdropType = null
var _command_tiles: Array[StagingCommandTileType] = []
var _portrait := false
var _compact_landscape := false
var _reduced_motion := false
var _focus_pulse_elapsed := 0.0
var _focus_pulse_styles: Dictionary = {}
var _focus_pulse_colors: Dictionary = {}


func _ready() -> void:
	theme = STAGING_THEME
	_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	Game.content = self
	_training_acknowledgement = Game.training_call(&"peek_acknowledgement") as Array[Dictionary]
	_resolve_next_operation()
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	(_back if _mission.disabled else _mission).grab_focus.call_deferred()
	if not _training_acknowledgement.is_empty():
		Game.training_call(&"consume_acknowledgement")


func _process(delta: float) -> void:
	_focus_pulse_elapsed = fmod(_focus_pulse_elapsed + delta, FOCUS_PULSE_SECONDS)
	var pulse := 0.20
	if not _reduced_motion:
		var wave := (sin((_focus_pulse_elapsed / FOCUS_PULSE_SECONDS) * TAU) + 1.0) * 0.5
		pulse = lerpf(FOCUS_PULSE_MIN_ALPHA, FOCUS_PULSE_MAX_ALPHA, wave)
	for button in _focus_pulse_styles:
		var style: StyleBoxFlat = _focus_pulse_styles[button]
		var accent: Color = _focus_pulse_colors[button]
		style.bg_color = Color(accent, pulse)
		(button as Button).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_exit()


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
	_navigation_content = _build_navigation_content()
	_build_landscape_layout()
	_build_portrait_layout()


func _build_backdrop() -> void:
	_backdrop = LunarisBackdropType.new()
	_backdrop.name = "LunarisBackdrop"
	_backdrop.set_reduced_motion(_reduced_motion)
	add_child(_backdrop)

	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.002, 0.012, 0.025, 0.18)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)


func _build_top_bar() -> void:
	_top_bar = PanelContainer.new()
	_top_bar.name = "TopCommandBar"
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = TOP_HUD_HEIGHT
	_top_bar.add_theme_stylebox_override(
		&"panel", _panel_style(Color(VOID, 0.78), Color(GOLD, 0.18), 1, 0),
	)
	add_child(_top_bar)

	_top_bar_margin = MarginContainer.new()
	_top_bar_margin.name = "TopBarMargin"
	_top_bar_margin.add_theme_constant_override(&"margin_left", 16)
	_top_bar_margin.add_theme_constant_override(&"margin_top", 10)
	_top_bar_margin.add_theme_constant_override(&"margin_right", 16)
	_top_bar_margin.add_theme_constant_override(&"margin_bottom", 10)
	_top_bar.add_child(_top_bar_margin)

	_top_row = HBoxContainer.new()
	_top_row.name = "TopBarContent"
	_top_row.add_theme_constant_override(&"separation", 14)
	_top_bar_margin.add_child(_top_row)

	_top_identity_plate = PanelContainer.new()
	_top_identity_plate.name = "IdentityPlate"
	_top_identity_plate.custom_minimum_size = Vector2(360.0, 104.0)
	_top_identity_plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_top_identity_plate.add_theme_stylebox_override(
		&"panel", StagingSkinType.company_hud_plate_style(),
	)
	_top_row.add_child(_top_identity_plate)
	var identity_row := HBoxContainer.new()
	identity_row.name = "IdentityPlateContent"
	identity_row.add_theme_constant_override(&"separation", 14)
	_top_identity_plate.add_child(identity_row)

	_top_crest = FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 58.0)
	_top_crest.name = "FactionCrest"
	_top_crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity_row.add_child(_top_crest)

	_top_identity = _label("FactionIdentity", "LUNARIS RELIQUARY\nCOMPANY 33", GameTypographyType.STATUS, IVORY)
	_top_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_identity.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(_top_identity, 24, IVORY, 560)
	identity_row.add_child(_top_identity)

	_top_status_chip = PanelContainer.new()
	_top_status_chip.name = "CampaignStatusChip"
	_top_status_chip.custom_minimum_size = Vector2(236.0, 84.0)
	_top_status_chip.add_theme_stylebox_override(&"panel", StagingSkinType.resource_chip_style(Color(0.88, 0.88, 0.82, 0.9)))
	_top_status_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_top_row.add_child(_top_status_chip)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override(&"margin_left", 20)
	status_margin.add_theme_constant_override(&"margin_top", 12)
	status_margin.add_theme_constant_override(&"margin_right", 20)
	status_margin.add_theme_constant_override(&"margin_bottom", 12)
	_top_status_chip.add_child(status_margin)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override(&"separation", 12)
	status_margin.add_child(status_row)
	status_row.add_child(_texture_icon("CampaignSeal", StagingSkinType.MISSION_ICON, Vector2(40.0, 40.0)))
	_top_summary = _label("TopCampaignSummary", _campaign_summary_text(), GameTypographyType.STATUS, IVORY)
	_top_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_summary.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(_top_summary, 22, IVORY, 520)
	status_row.add_child(_top_summary)
	_exit_plate = PanelContainer.new()
	_exit_plate.name = "UtilityPlate"
	_exit_plate.custom_minimum_size = Vector2(152.0, 84.0)
	_exit_plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_exit_plate.add_theme_stylebox_override(&"panel", StagingSkinType.company_hud_plate_style())
	_top_row.add_child(_exit_plate)
	_back = Button.new()
	_back.name = "ExitButton"
	_back.text = UiCopyType.text(&"ui.common.exit", "Exit")
	_back.tooltip_text = _back.text
	_back.custom_minimum_size = Vector2(132.0, 64.0)
	_back.focus_mode = Control.FOCUS_ALL
	_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color", &"font_disabled_color",
	]:
		_back.add_theme_color_override(color_name, Color.TRANSPARENT)
	_back.add_theme_stylebox_override(&"normal", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	_back.add_theme_stylebox_override(&"hover", _panel_style(Color(GOLD, 0.10), Color(GOLD, 0.34), 1, 2))
	_back.add_theme_stylebox_override(&"pressed", _panel_style(Color(MOON_CYAN, 0.10), Color(MOON_CYAN, 0.48), 1, 2))
	_register_focus_pulse(_back, GOLD)
	var exit_margin := MarginContainer.new()
	exit_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_margin.add_theme_constant_override(&"margin_left", 14)
	exit_margin.add_theme_constant_override(&"margin_right", 14)
	exit_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.add_child(exit_margin)
	var exit_row := HBoxContainer.new()
	exit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	exit_row.add_theme_constant_override(&"separation", 8)
	exit_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exit_margin.add_child(exit_row)
	exit_row.add_child(_texture_icon("ExitGlyph", StagingSkinType.EXIT_ICON, Vector2(36.0, 36.0)))
	_exit_label = _label("ExitLabel", _back.text.to_upper(), GameTypographyType.DETAIL, MUTED)
	_exit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(_exit_label, 20, MUTED, 560)
	exit_row.add_child(_exit_label)
	_back.pressed.connect(_on_exit)
	_exit_plate.add_child(_back)


func _texture_icon(node_name: String, texture: Texture2D, minimum: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.custom_minimum_size = minimum
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _build_landscape_layout() -> void:
	_landscape_layout = HBoxContainer.new()
	_landscape_layout.name = "LandscapeLayout"
	_landscape_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_landscape_layout.offset_left = LANDSCAPE_GUTTER
	_landscape_layout.offset_top = TOP_HUD_HEIGHT + 16.0
	_landscape_layout.offset_right = -LANDSCAPE_GUTTER
	_landscape_layout.offset_bottom = -LANDSCAPE_BOTTOM_GUTTER
	_landscape_layout.add_theme_constant_override(&"separation", 16)
	add_child(_landscape_layout)

	_landscape_navigation = PanelContainer.new()
	_landscape_navigation.name = "NavigationRail"
	_landscape_navigation.custom_minimum_size.x = LANDSCAPE_NAV_WIDTH
	_landscape_navigation.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_landscape_navigation.size_flags_vertical = Control.SIZE_FILL
	_landscape_navigation.add_theme_stylebox_override(
		&"panel", StagingSkinType.company_navigation_rail_style(),
	)
	_landscape_layout.add_child(_landscape_navigation)
	_landscape_navigation_host = MarginContainer.new()
	_landscape_navigation_host.name = "NavigationRailHost"
	_landscape_navigation_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landscape_navigation_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_navigation.add_child(_landscape_navigation_host)

	var hero_region := MarginContainer.new()
	hero_region.name = "HeroRegion"
	hero_region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_region.size_flags_stretch_ratio = 1.0
	_landscape_layout.add_child(hero_region)

	_landscape_deck = PanelContainer.new()
	_landscape_deck.name = "CommandDeck"
	_landscape_deck.custom_minimum_size.x = 640.0
	_landscape_deck.size_flags_horizontal = Control.SIZE_SHRINK_END
	_landscape_deck.size_flags_vertical = Control.SIZE_FILL
	_landscape_deck.add_theme_stylebox_override(&"panel", StagingSkinType.command_deck_style())
	_landscape_layout.add_child(_landscape_deck)
	_landscape_host = _build_scroll_host(_landscape_deck, "LandscapeCommandScroll")


func _build_portrait_layout() -> void:
	_portrait_layout = VBoxContainer.new()
	_portrait_layout.name = "PortraitLayout"
	_portrait_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_layout.offset_left = 24.0
	_portrait_layout.offset_top = TOP_HUD_HEIGHT
	_portrait_layout.offset_right = -24.0
	_portrait_layout.offset_bottom = -16.0
	_portrait_layout.add_theme_constant_override(&"separation", 0)
	add_child(_portrait_layout)

	_portrait_spacer = Control.new()
	_portrait_spacer.name = "HeroStage"
	_portrait_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_layout.add_child(_portrait_spacer)

	_portrait_sheet = PanelContainer.new()
	_portrait_sheet.name = "CommandSheet"
	_portrait_sheet.custom_minimum_size.y = 800.0
	_portrait_sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_sheet.size_flags_vertical = Control.SIZE_SHRINK_END
	_portrait_sheet.add_theme_stylebox_override(&"panel", StagingSkinType.command_deck_style())
	_portrait_layout.add_child(_portrait_sheet)
	_portrait_host = _build_scroll_host(_portrait_sheet, "PortraitCommandScroll")


func _build_scroll_host(panel: PanelContainer, node_name: String) -> MarginContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.name = "%sMargin" % node_name
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	return margin


func _build_command_content() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.name = "CommandContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", INTRA_GROUP_GAP)

	var progress_row := HBoxContainer.new()
	progress_row.name = "CampaignProgressRow"
	progress_row.add_theme_constant_override(&"separation", 12)
	content.add_child(progress_row)
	var progress_glyph := FactionHeraldryType.make_symbol(
		FactionHeraldryType.ACTIVE_FACTION, 36.0,
	)
	progress_glyph.name = "CampaignGlyph"
	progress_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_row.add_child(progress_glyph)
	_command_heading = _label(
		"CommandHeading", UiCopyType.text(&"ui.staging.command_heading", "COMPANY 33 COMMAND"),
		24, GOLD,
	)
	_command_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_command_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_command_heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	_command_heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	StagingSkinType.apply_display_type(_command_heading, 24, GOLD, 560)
	progress_row.add_child(_command_heading)
	_campaign_progress_text = _label(
		"CampaignProgressText", _campaign_summary_text(), GameTypographyType.STATUS, IVORY,
	)
	_campaign_progress_text.custom_minimum_size.x = 144.0
	StagingSkinType.apply_display_type(_campaign_progress_text, 18, IVORY, 520)
	_campaign_progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_campaign_progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_campaign_progress_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_campaign_progress_text.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	progress_row.add_child(_campaign_progress_text)

	var progress := ProgressBar.new()
	progress.name = "CampaignProgress"
	progress.custom_minimum_size.y = 5.0
	progress.max_value = 1.0
	progress.value = _campaign_progress()
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override(&"background", _bar_style(Color(GOLD, 0.20)))
	progress.add_theme_stylebox_override(&"fill", _bar_style(MOON_CYAN))
	content.add_child(progress)
	content.add_child(_build_progress_milestones())

	_next_operation_label = _label(
		"NextOperationLabel", UiCopyType.text(&"ui.staging.next_label", "NEXT OPERATION"),
		18, GOLD,
	)
	StagingSkinType.apply_display_type(_next_operation_label, 18, GOLD, 520)
	content.add_child(_next_operation_label)
	content.add_child(_build_mission_card())

	_mission = _build_mission_button()
	_mission.pressed.connect(_on_mission_control)
	content.add_child(_mission)

	if not _training_acknowledgement.is_empty():
		content.add_child(_build_acknowledgement())
	return content


func _build_navigation_content() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.name = "NavigationContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", INTRA_GROUP_GAP)

	var operation_heading := HBoxContainer.new()
	operation_heading.name = "OperationsHeading"
	operation_heading.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(operation_heading)
	_operations_label = _label(
		"OperationsLabel", UiCopyType.text(&"ui.staging.operations", "OPERATIONS"),
		18, GOLD,
	)
	_operations_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operations_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StagingSkinType.apply_display_type(_operations_label, 18, GOLD, 560)
	operation_heading.add_child(_operations_label)

	_operation_grid = GridContainer.new()
	_operation_grid.name = "OperationGrid"
	_operation_grid.columns = 1
	_operation_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_grid.add_theme_constant_override(&"h_separation", 12)
	_operation_grid.add_theme_constant_override(&"v_separation", 10)
	_operation_scroll = ScrollContainer.new()
	_operation_scroll.name = "OperationsScroll"
	_operation_scroll.custom_minimum_size.y = 144.0
	_operation_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_operation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_operation_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(_operation_scroll)
	_operation_scroll.add_child(_operation_grid)

	_add_locked_operation(
		"BarracksButton", StagingGlyphType.Kind.BARRACKS,
		&"ui.staging.barracks_short", "Barracks",
		&"ui.staging.barracks_unavailable", "Barracks — Unavailable",
	)
	_recruit = StagingCommandTileType.new()
	_recruit.name = "RecruitButton"
	_recruit.configure(
		StagingGlyphType.Kind.RECRUIT,
		UiCopyType.text(&"ui.staging.recruit_short", "Resonance"),
		UiCopyType.text(&"ui.staging.recruit", "Premium Resonance"),
		true,
	)
	_recruit.pressed.connect(_on_recruit)
	_command_tiles.append(_recruit)
	_operation_grid.add_child(_recruit)
	_add_locked_operation(
		"ArmoryButton", StagingGlyphType.Kind.ARMORY,
		&"ui.staging.armory_short", "Armory",
		&"ui.staging.armory_unavailable", "Armory — Unavailable",
	)
	_vahalla = StagingCommandTileType.new()
	_vahalla.name = "VahallaButton"
	_vahalla.configure(
		StagingGlyphType.Kind.MEMORIAL,
		UiCopyType.text(&"ui.staging.vahalla_short", "Vahalla"),
		UiCopyType.text(&"ui.staging.vahalla", "Vahalla"),
		true,
	)
	_vahalla.pressed.connect(_on_vahalla)
	_command_tiles.append(_vahalla)
	_operation_grid.add_child(_vahalla)
	_archive = StagingCommandTileType.new()
	_archive.name = "MercyArchiveButton"
	_archive.configure(
		StagingGlyphType.Kind.ARCHIVE,
		UiCopyType.text(&"ui.staging.archive_short", "Archive"),
		UiCopyType.text(&"ui.staging.archive", "Mercy Archive"),
		true,
	)
	_archive.pressed.connect(_on_archive)
	_command_tiles.append(_archive)
	_operation_grid.add_child(_archive)

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
	_operation_grid.add_child(_training)
	return content


func _build_progress_milestones() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "CampaignMilestones"
	row.custom_minimum_size.y = 16.0
	row.add_theme_constant_override(&"separation", 0)
	var total := maxi(Game.campaign_stage_ids().size(), 1)
	var cleared := roundi(_campaign_progress() * float(total))
	for index: int in total:
		var marker := _texture_icon(
			"Milestone%02d" % (index + 1), StagingSkinType.STATUS_DIAMOND, Vector2(12.0, 12.0),
		)
		marker.modulate = Color.WHITE if index < cleared else Color(0.52, 0.48, 0.38, 0.42)
		row.add_child(marker)
		if index < total - 1:
			var line := ColorRect.new()
			line.name = "MilestoneLine%02d" % (index + 1)
			line.custom_minimum_size.y = 1.0
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.color = Color(GOLD, 0.24)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(line)
	return row


func _build_mission_card() -> PanelContainer:
	_mission_card = PanelContainer.new()
	_mission_card.name = "NextOperationCard"
	_mission_card.custom_minimum_size.y = 260.0
	_mission_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_card.add_theme_stylebox_override(&"panel", StagingSkinType.mission_card_style())

	var margin := MarginContainer.new()
	margin.name = "MissionCardMargin"
	_mission_card.add_child(margin)

	_mission_grid = GridContainer.new()
	_mission_grid.name = "MissionCardGrid"
	_mission_grid.columns = 1
	_mission_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_grid.add_theme_constant_override(&"v_separation", 12)
	margin.add_child(_mission_grid)

	var mission_heading := HBoxContainer.new()
	mission_heading.name = "MissionHeading"
	mission_heading.add_theme_constant_override(&"separation", 10)
	_mission_grid.add_child(mission_heading)
	mission_heading.add_child(_texture_icon(
		"MissionGlyph", StagingSkinType.MISSION_ICON, Vector2(40.0, 40.0),
	))
	_mission_title = _label(
		"NextOperationTitle", _next_operation_title(), 26, IVORY,
	)
	_mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_title.max_lines_visible = 2
	_mission_title.add_theme_constant_override(&"outline_size", 3)
	_mission_title.add_theme_color_override(&"font_outline_color", Color(VOID, 0.86))
	StagingSkinType.apply_display_type(_mission_title, 26, IVORY, 560)
	mission_heading.add_child(_mission_title)

	_mission_body_grid = GridContainer.new()
	_mission_body_grid.name = "MissionBodyGrid"
	_mission_body_grid.columns = 2
	_mission_body_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_body_grid.add_theme_constant_override(&"h_separation", 24)
	_mission_body_grid.add_theme_constant_override(&"v_separation", 12)
	_mission_grid.add_child(_mission_body_grid)

	_mission_preview = TextureRect.new()
	_mission_preview.name = "MissionPreview"
	_mission_preview.custom_minimum_size = Vector2(160.0, 128.0)
	_mission_preview.texture = MISSION_ART
	_mission_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mission_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_mission_preview.modulate = Color(0.70, 0.88, 0.95, 0.92)
	_mission_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_body_grid.add_child(_mission_preview)

	_mission_objective = _label(
		"NextOperationObjective", _next_operation_objective(), 20, MUTED,
	)
	_mission_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_objective.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mission_objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mission_objective.max_lines_visible = -1
	_mission_body_grid.add_child(_mission_objective)
	return _mission_card


func _build_mission_button() -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = "MissionControlButton"
	var full_text := UiCopyType.text(&"ui.staging.mission_control", "Mission Control")
	button.set_presentation_text(full_text, full_text.to_upper())
	button.tooltip_text = full_text
	button.disabled = _narrative_missing
	button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0.0, 72.0)
	_mission_action_label = button.get_node("PresentationLabel") as Label
	StagingSkinType.apply_display_type(
		_mission_action_label, 26,
		IVORY if not button.disabled else MUTED, 560,
	)
	_mission_action_label.add_theme_constant_override(&"outline_size", 4)
	_mission_action_label.add_theme_color_override(&"font_outline_color", Color(VOID, 0.92))
	button.add_theme_stylebox_override(
		&"normal",
		StagingSkinType.clean_button_style(
			Color(0.025, 0.08, 0.11, 0.96) if not button.disabled else Color(0.025, 0.035, 0.045, 0.78),
			Color(MOON_CYAN, 0.62) if not button.disabled else Color(MUTED, 0.26),
		),
	)
	button.add_theme_stylebox_override(
		&"hover",
		StagingSkinType.clean_button_style(Color(MOON_CYAN, 0.22), Color(MOON_CYAN, 0.90)),
	)
	button.add_theme_stylebox_override(
		&"pressed",
		StagingSkinType.clean_button_style(Color(MOON_CYAN, 0.32), MOON_CYAN),
	)
	button.add_theme_stylebox_override(
		&"disabled",
		StagingSkinType.clean_button_style(Color(0.025, 0.035, 0.045, 0.78), Color(MUTED, 0.26)),
	)
	_register_focus_pulse(button, MOON_CYAN)
	var mission_icon := _texture_icon("MissionActionGlyph", StagingSkinType.MISSION_ICON, Vector2(44.0, 44.0))
	mission_icon.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	mission_icon.offset_left = 20.0
	mission_icon.offset_top = -22.0
	mission_icon.offset_right = 64.0
	mission_icon.offset_bottom = 22.0
	button.add_child(mission_icon)
	return button


func _register_focus_pulse(button: Button, accent: Color) -> void:
	var style := StagingSkinType.transparent_focus_style(accent)
	button.add_theme_stylebox_override(&"focus", style)
	_focus_pulse_styles[button] = style
	_focus_pulse_colors[button] = accent


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
		18, MOON_CYAN,
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
	if _recruit != null and not _recruit.disabled:
		actions.append(_recruit)
	if _vahalla != null and not _vahalla.disabled:
		actions.append(_vahalla)
	if _archive != null and not _archive.disabled:
		actions.append(_archive)
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
		if _operation_scroll != null and _operation_scroll.is_ancestor_of(current):
			current.focus_entered.connect(_operation_scroll.ensure_control_visible.bind(current))
func _apply_responsive_layout() -> void:
	if _landscape_layout == null or _portrait_layout == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_backdrop.fit_top_cover(viewport_size)
	var safe_insets := _display_safe_insets(viewport_size)
	var aspect := viewport_size.x / viewport_size.y
	_portrait = viewport_size.y > viewport_size.x
	_compact_landscape = not _portrait and (aspect < 1.45 or viewport_size.x < 1200.0)
	_landscape_layout.visible = not _portrait
	_portrait_layout.visible = _portrait
	_place_responsive_content()

	var landscape_left := maxf(LANDSCAPE_GUTTER, safe_insets.x)
	var landscape_right := maxf(LANDSCAPE_GUTTER, safe_insets.z)
	_landscape_layout.offset_left = landscape_left
	_landscape_layout.offset_right = -landscape_right
	_landscape_layout.offset_top = TOP_HUD_HEIGHT + maxf(0.0, safe_insets.y) + 16.0
	_landscape_layout.offset_bottom = -maxf(LANDSCAPE_BOTTOM_GUTTER, safe_insets.w)
	_landscape_navigation.visible = not _compact_landscape
	_landscape_navigation.custom_minimum_size.x = LANDSCAPE_NAV_WIDTH
	_landscape_navigation.custom_minimum_size.y = 0.0
	_landscape_navigation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_deck.custom_minimum_size.x = (
		clampf(viewport_size.x * 0.72, 680.0, 900.0)
		if _compact_landscape
		else clampf(viewport_size.x * 0.50, LANDSCAPE_DECK_MIN_WIDTH, LANDSCAPE_DECK_MAX_WIDTH)
	)
	_landscape_deck.custom_minimum_size.y = 0.0
	_landscape_deck.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var portrait_left := maxf(24.0, safe_insets.x)
	var portrait_right := maxf(24.0, safe_insets.z)
	_portrait_layout.offset_left = portrait_left
	_portrait_layout.offset_right = -portrait_right
	_portrait_layout.offset_top = TOP_HUD_HEIGHT + maxf(0.0, safe_insets.y - 8.0)
	_portrait_layout.offset_bottom = -maxf(16.0, safe_insets.w)
	var portrait_available := maxf(
		420.0,
		viewport_size.y - _portrait_layout.offset_top + _portrait_layout.offset_bottom,
	)
	_portrait_sheet.custom_minimum_size.y = minf(
		portrait_available, clampf(viewport_size.y * 0.68, 520.0, PORTRAIT_SHEET_MAX_HEIGHT),
	)

	_apply_top_hud_layout(viewport_size, safe_insets)
	_apply_command_geometry(viewport_size)
	_apply_company_typography()
	_connect_focus_cycle()


func _place_responsive_content() -> void:
	_command_content.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN if _portrait or _compact_landscape else Control.SIZE_EXPAND_FILL
	)
	_navigation_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _portrait:
		if _portrait_stack == null:
			_portrait_stack = VBoxContainer.new()
			_portrait_stack.name = "PortraitCommandStack"
			_portrait_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_portrait_stack.add_theme_constant_override(&"separation", MAJOR_SECTION_GAP)
			_portrait_host.add_child(_portrait_stack)
		_reparent_control(_command_content, _portrait_stack)
		_reparent_control(_navigation_content, _portrait_stack)
		return
	if _compact_landscape:
		if _landscape_command_stack == null:
			_landscape_command_stack = VBoxContainer.new()
			_landscape_command_stack.name = "CompactLandscapeCommandStack"
			_landscape_command_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_landscape_command_stack.add_theme_constant_override(&"separation", MAJOR_SECTION_GAP)
			_landscape_host.add_child(_landscape_command_stack)
		_reparent_control(_command_content, _landscape_command_stack)
		_reparent_control(_navigation_content, _landscape_command_stack)
		return
	_reparent_control(_command_content, _landscape_host)
	_reparent_control(_navigation_content, _landscape_navigation_host)


func _reparent_control(control: Control, target: Control) -> void:
	if control == null or target == null or control.get_parent() == target:
		return
	var previous := control.get_parent()
	if previous != null:
		previous.remove_child(control)
	target.add_child(control)


func _apply_top_hud_layout(viewport_size: Vector2, safe_insets: Vector4) -> void:
	_top_bar.offset_bottom = TOP_HUD_HEIGHT + maxf(0.0, safe_insets.y)
	_top_bar_margin.add_theme_constant_override(&"margin_left", maxi(16, roundi(safe_insets.x)))
	_top_bar_margin.add_theme_constant_override(&"margin_top", maxi(10, roundi(safe_insets.y)))
	_top_bar_margin.add_theme_constant_override(&"margin_right", maxi(16, roundi(safe_insets.z)))
	_top_bar_margin.add_theme_constant_override(&"margin_bottom", 10)
	var narrow := viewport_size.x < 620.0
	var compact := _portrait or _compact_landscape or viewport_size.x < 1180.0
	_top_status_chip.visible = not compact and viewport_size.x >= 1120.0
	_top_identity_plate.custom_minimum_size = (
		Vector2(220.0, 88.0) if narrow
		else (Vector2(276.0, 96.0) if compact else Vector2(360.0, 104.0))
	)
	_top_identity.text = "LUNARIS\nCOMPANY 33" if narrow else "LUNARIS RELIQUARY\nCOMPANY 33"
	_top_crest.custom_minimum_size = (
		Vector2(42.0, 42.0) if narrow else (Vector2(48.0, 48.0) if compact else Vector2(58.0, 58.0))
	)
	StagingSkinType.apply_display_type(_top_identity, 18 if narrow else (20 if compact else 24), IVORY, 560)
	StagingSkinType.apply_display_type(_top_summary, 18 if compact else 22, IVORY, 520)
	_back.text = UiCopyType.text(&"ui.common.exit", "Exit")
	_exit_label.text = _back.text.to_upper()
	_exit_label.visible = not narrow
	_back.custom_minimum_size = Vector2(68.0, 56.0) if narrow else Vector2(132.0, 64.0)
	_exit_plate.custom_minimum_size = Vector2(80.0, 72.0) if narrow else Vector2(152.0, 84.0)
	_top_status_chip.custom_minimum_size = Vector2(236.0, 84.0)
	StagingSkinType.apply_display_type(_exit_label, 18 if compact else 20, MUTED, 560)


func _apply_command_geometry(viewport_size: Vector2) -> void:
	var single_column := (_portrait and viewport_size.x < 680.0)
	_mission_body_grid.columns = 1 if single_column else 2
	_mission_card.custom_minimum_size.y = 320.0 if single_column else 260.0
	_mission_preview.custom_minimum_size = (
		Vector2(0.0, 112.0) if single_column else Vector2(160.0, 128.0)
	)
	_operation_grid.columns = 1 if (not _portrait and not _compact_landscape) or viewport_size.x < 620.0 else 2
	_operation_grid.add_theme_constant_override(
		&"v_separation", 8 if not _portrait and not _compact_landscape else 10,
	)
	for tile: StagingCommandTileType in _command_tiles:
		tile.set_rail_mode(not _portrait and not _compact_landscape)


func _apply_company_typography() -> void:
	var compact := _compact_landscape
	var rail_mode := not _portrait and not _compact_landscape
	StagingSkinType.apply_display_type(_command_heading, 22 if compact else 24, GOLD, 560)
	StagingSkinType.apply_display_type(_campaign_progress_text, 18, IVORY, 520)
	StagingSkinType.apply_display_type(_next_operation_label, 17 if compact else 18, GOLD, 520)
	StagingSkinType.apply_display_type(_mission_title, 24 if compact or _portrait else 26, IVORY, 560)
	_mission_objective.add_theme_font_size_override(&"font_size", 27 if compact else 30)
	StagingSkinType.apply_display_type(_mission_action_label, 24 if compact or _portrait else 26, IVORY, 560)
	StagingSkinType.apply_display_type(_operations_label, 36 if rail_mode else 18, GOLD, 560)


func _display_safe_insets(viewport_size: Vector2) -> Vector4:
	var safe_rect := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO
	var scale := Vector2(viewport_size.x / float(window_size.x), viewport_size.y / float(window_size.y))
	var left := maxf(0.0, float(safe_rect.position.x) * scale.x)
	var top := maxf(0.0, float(safe_rect.position.y) * scale.y)
	var right := maxf(0.0, float(window_size.x - safe_rect.end.x) * scale.x)
	var bottom := maxf(0.0, float(window_size.y - safe_rect.end.y) * scale.y)
	if left + right > viewport_size.x * 0.25 or top + bottom > viewport_size.y * 0.25:
		return Vector4.ZERO
	return Vector4(left, top, right, bottom)


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
			"PROTOS saved the biosphere by declaring human choice its final extinction event. Company 33 defends Hearthcross and humanity's right to remain free and unfinished.",
		)
	return UiCopyType.stage_narrative_text(_next_record, StageNarrativeDefType.Field.OBJECTIVE)


func _on_mission_control() -> void:
	if _narrative_missing:
		return
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_recruit() -> void:
	Sfx.play("ui_click")
	Game.open_gacha()


func _on_vahalla() -> void:
	Sfx.play("ui_click")
	Game.open_vahalla()


func _on_archive() -> void:
	Sfx.play("ui_click")
	Game.open_narrative_archive()


func _on_training() -> void:
	if not _training_available():
		return
	Sfx.play("ui_click")
	Game.training_call(&"open", &"staging")


func _on_exit() -> void:
	Sfx.play("ui_back")
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
