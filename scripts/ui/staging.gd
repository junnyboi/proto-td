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
const CommandCenterTutorialType := preload(
	"res://scripts/ui/components/command_center_tutorial.gd"
)
const StagingButtonSparklesType := preload(
	"res://scripts/ui/components/staging_button_sparkles.gd"
)
const ViewPreferencesType := preload("res://scripts/view/view_preferences.gd")
const STAGING_THEME := preload("res://data/presentation/ui/threshold_theme.tres")
const MISSION_ART := preload("res://assets/world/act1/panorama.png")
const MISSION_CONTROL_PLATE := preload(
	"res://assets/ui/staging/frames/mission_control_plate.png"
)
const REWARD_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}

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
const FOCUS_PULSE_MIN_ALPHA := 0.10
const FOCUS_PULSE_MAX_ALPHA := 0.16
const TOP_HUD_HEIGHT := 156.0
const LANDSCAPE_GUTTER := 24.0
const LANDSCAPE_BOTTOM_GUTTER := 16.0
const LANDSCAPE_NAV_WIDTH := 660.0
const LANDSCAPE_DECK_MIN_WIDTH := 620.0
const LANDSCAPE_DECK_MAX_WIDTH := 700.0
const LANDSCAPE_DECK_MAX_HEIGHT := 760.0
const PORTRAIT_SHEET_MIN_HEIGHT := 760.0
const PORTRAIT_SHEET_MAX_HEIGHT := 860.0
const INTRA_GROUP_GAP := 12
const MAJOR_SECTION_GAP := 24
const OPERATION_LIST_SIDE_MARGIN := 20
const NEXT_MISSION_CARD_MIN_HEIGHT := 260.0
const MISSION_ACTION_VERTICAL_PADDING := 12
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

enum ScreenState { COMMAND, SETTINGS, COMMITTING }

var _mission: AetheriaButtonType = null
var _recruit: StagingCommandTileType = null
var _vahalla: StagingCommandTileType = null
var _training: StagingCommandTileType = null
var _archive: StagingCommandTileType = null
var _back: Button = null
var _settings_button: Button = null
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
var _next_operation_action: Button = null
var _mission_grid: GridContainer = null
var _mission_body_grid: GridContainer = null
var _mission_preview: TextureRect = null
var _mission_operation_block: VBoxContainer = null
var _mission_details_panel: PanelContainer = null
var _mission_details_grid: GridContainer = null
var _mission_brief_heading: Label = null
var _mission_description: Label = null
var _mission_difficulty: Label = null
var _mission_reward: Label = null
var _mission_threat: Label = null
var _mission_facts: Label = null
var _operation_grid: GridContainer = null
var _operation_scroll: ScrollContainer = null
var _operation_list_margin: MarginContainer = null
var _top_identity: Label = null
var _top_identity_plate: PanelContainer = null
var _top_status_chip: PanelContainer = null
var _top_summary: Label = null
var _top_bar: PanelContainer = null
var _top_bar_margin: MarginContainer = null
var _top_row: HBoxContainer = null
var _utility_actions: HBoxContainer = null
var _top_crest: TextureRect = null
var _exit_plate: PanelContainer = null
var _exit_label: Label = null
var _exit_icon: TextureRect = null
var _settings_plate: PanelContainer = null
var _settings_label: Label = null
var _settings_icon: TextureRect = null
var _command_heading: Label = null
var _campaign_progress_text: Label = null
var _campaign_milestones: HBoxContainer = null
var _next_operation_label: Label = null
var _mission_title: Label = null
var _mission_objective: Label = null
var _mission_action_label: Label = null
var _mission_plate: TextureRect = null
var _operations_label: Label = null
var _backdrop: LunarisBackdropType = null
var _command_tiles: Array[StagingCommandTileType] = []
var _portrait := false
var _compact_landscape := false
var _reduced_motion := false
var _mission_hovered := false
var _mission_hover_tween: Tween = null
var _focus_pulse_elapsed := 0.0
var _focus_pulse_styles: Dictionary = {}
var _mission_sparkles: StagingButtonSparklesType = null
var _resonance_sparkles: StagingButtonSparklesType = null
var _tutorial: CommandCenterTutorialType = null
var _preferences_path := ViewPreferencesType.DEFAULT_PATH
var _preferences_path_explicit := false
var _screen_state := ScreenState.COMMAND
var _settings_snapshot: Dictionary = {}
var _music_enabled := true
var _master_volume := 1.0
var _master_muted := false
var _music_volume := 1.0
var _sfx_volume := 1.0
var _frame_limit := 0
var _text_scale := 1.0
var _background_downloads_enabled := true

@onready var _settings_state: TitleSettings = $TitleSettings


func _ready() -> void:
	theme = STAGING_THEME
	if not _preferences_path_explicit:
		_preferences_path = Game.view_preferences_path()
	_load_preferences()
	I18n.set_locale(ViewPreferencesType.locale(_preferences_path))
	_apply_audio_settings()
	_apply_graphics_settings()
	_apply_background_download_policy()
	Music.set_enabled(_music_enabled)
	Game.content = self
	_training_acknowledgement = Game.training_call(&"peek_acknowledgement") as Array[Dictionary]
	_resolve_next_operation()
	_build_screen()
	move_child(_settings_state, get_child_count() - 1)
	_settings_state.cancel_requested.connect(_cancel_settings)
	_settings_state.apply_requested.connect(_apply_settings)
	_settings_state.preview_requested.connect(_preview_settings)
	_settings_state.close_completed.connect(_on_settings_close_completed)
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null and not content_packs.background_policy_changed.is_connected(
		_on_content_background_policy_changed,
	):
		content_packs.background_policy_changed.connect(_on_content_background_policy_changed)
	I18n.locale_changed.connect(_on_locale_changed)
	TextScale.scale_changed.connect(_on_text_scale_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	var tutorial_mounted := _maybe_mount_command_tutorial()
	if not tutorial_mounted:
		tutorial_mounted = _maybe_mount_post_mission_tutorial()
	if not tutorial_mounted:
		(_back if _mission.disabled else _mission).grab_focus.call_deferred()
	if not _training_acknowledgement.is_empty():
		Game.training_call(&"consume_acknowledgement")


func _process(delta: float) -> void:
	_focus_pulse_elapsed = fmod(_focus_pulse_elapsed + delta, FOCUS_PULSE_SECONDS)
	var pulse := StagingSkinType.FOCUS_TINT_ALPHA
	if not _reduced_motion:
		var wave := (sin((_focus_pulse_elapsed / FOCUS_PULSE_SECONDS) * TAU) + 1.0) * 0.5
		pulse = lerpf(FOCUS_PULSE_MIN_ALPHA, FOCUS_PULSE_MAX_ALPHA, wave)
	for button in _focus_pulse_styles:
		var style: StyleBoxFlat = _focus_pulse_styles[button]
		style.bg_color = Color(GOLD, pulse)
		(button as Button).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _screen_state != ScreenState.COMMAND:
		return
	if event.is_action_pressed("ui_cancel"):
		if _tutorial != null and is_instance_valid(_tutorial) and _tutorial.is_active():
			return
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
	_top_identity_plate.custom_minimum_size = Vector2(420.0, 112.0)
	_top_identity_plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_top_identity_plate.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_top_row.add_child(_top_identity_plate)
	var identity_row := HBoxContainer.new()
	identity_row.name = "IdentityPlateContent"
	identity_row.add_theme_constant_override(&"separation", 14)
	_top_identity_plate.add_child(identity_row)

	_top_crest = FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 58.0)
	_top_crest.name = "FactionCrest"
	_top_crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity_row.add_child(_top_crest)

	_top_identity = _label("FactionIdentity", _company_identity(false), GameTypographyType.STATUS, IVORY)
	_top_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_identity.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(_top_identity, 28, IVORY, 620)
	identity_row.add_child(_top_identity)

	_top_status_chip = PanelContainer.new()
	_top_status_chip.name = "CampaignStatusChip"
	_top_status_chip.custom_minimum_size = Vector2(354.0, 112.0)
	_top_status_chip.add_theme_stylebox_override(&"panel", StagingSkinType.resource_chip_style(Color(0.88, 0.88, 0.82, 0.9)))
	_top_status_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_top_row.add_child(_top_status_chip)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override(&"margin_left", 28)
	status_margin.add_theme_constant_override(&"margin_top", 18)
	status_margin.add_theme_constant_override(&"margin_right", 28)
	status_margin.add_theme_constant_override(&"margin_bottom", 18)
	_top_status_chip.add_child(status_margin)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override(&"separation", 12)
	status_margin.add_child(status_row)
	status_row.add_child(_texture_icon("CampaignSeal", StagingSkinType.MISSION_ICON, Vector2(48.0, 48.0)))
	_top_summary = _label("TopCampaignSummary", _campaign_summary_text(), GameTypographyType.STATUS, IVORY)
	_top_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_summary.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(_top_summary, 24, IVORY, 560)
	status_row.add_child(_top_summary)
	var exit_alignment_spacer := Control.new()
	exit_alignment_spacer.name = "ExitAlignmentSpacer"
	exit_alignment_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_alignment_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_row.add_child(exit_alignment_spacer)
	_utility_actions = HBoxContainer.new()
	_utility_actions.name = "UtilityActions"
	_utility_actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_utility_actions.add_theme_constant_override(&"separation", 10)
	_top_row.add_child(_utility_actions)
	var settings_parts := _build_top_utility_action(
		_utility_actions,
		"SettingsUtilityPlate",
		"CommandSettingsButton",
		"SettingsGlyph",
		"SettingsLabel",
		StagingSkinType.SETTINGS_ICON,
		UiCopyType.text(&"ui.title.settings", "Settings"),
		Callable(self, "_open_settings"),
	)
	_settings_plate = settings_parts[&"plate"] as PanelContainer
	_settings_button = settings_parts[&"button"] as Button
	_settings_label = settings_parts[&"label"] as Label
	_settings_icon = settings_parts[&"icon"] as TextureRect
	var exit_parts := _build_top_utility_action(
		_utility_actions,
		"UtilityPlate",
		"ExitButton",
		"ExitGlyph",
		"ExitLabel",
		StagingSkinType.EXIT_ICON,
		UiCopyType.text(&"ui.common.exit", "Exit"),
		Callable(self, "_on_exit"),
	)
	_exit_plate = exit_parts[&"plate"] as PanelContainer
	_back = exit_parts[&"button"] as Button
	_exit_label = exit_parts[&"label"] as Label
	_exit_icon = exit_parts[&"icon"] as TextureRect


func _build_top_utility_action(
	parent: Container,
	plate_name: String,
	button_name: String,
	glyph_name: String,
	label_name: String,
	icon: Texture2D,
	copy: String,
	pressed_callback: Callable,
) -> Dictionary:
	var plate := PanelContainer.new()
	plate.name = plate_name
	plate.custom_minimum_size = Vector2(228.0, 112.0)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.add_theme_stylebox_override(&"panel", StagingSkinType.company_hud_plate_style())
	parent.add_child(plate)
	var button := Button.new()
	button.name = button_name
	button.text = copy
	button.tooltip_text = copy
	button.accessibility_name = copy
	button.custom_minimum_size = Vector2(196.0, 88.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color", &"font_disabled_color",
	]:
		button.add_theme_color_override(color_name, Color.TRANSPARENT)
	button.add_theme_stylebox_override(&"normal", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	button.add_theme_stylebox_override(&"hover", _panel_style(Color(GOLD, 0.10), Color(GOLD, 0.34), 1, 2))
	button.add_theme_stylebox_override(&"pressed", _panel_style(Color(MOON_CYAN, 0.10), Color(MOON_CYAN, 0.48), 1, 2))
	_register_focus_pulse(button, GOLD)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 22)
	margin.add_theme_constant_override(&"margin_right", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var glyph := _texture_icon(glyph_name, icon, Vector2(44.0, 44.0))
	row.add_child(glyph)
	var label := _label(label_name, copy.to_upper(), GameTypographyType.DETAIL, MUTED)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	StagingSkinType.apply_display_type(label, 22, MUTED, 600)
	row.add_child(label)
	button.pressed.connect(pressed_callback)
	plate.add_child(button)
	return {&"plate": plate, &"button": button, &"label": label, &"icon": glyph}


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
	_landscape_layout.offset_top = TOP_HUD_HEIGHT + 8.0
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
		"CommandHeading", UiCopyType.text(&"ui.staging.command_heading", "COMPANY COMMAND"),
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
	_campaign_milestones = _build_progress_milestones()
	content.add_child(_campaign_milestones)

	_next_operation_label = _label(
		"NextOperationLabel", UiCopyType.text(&"ui.staging.next_label", "NEXT OPERATION"),
		18, GOLD,
	)
	StagingSkinType.apply_display_type(_next_operation_label, 18, GOLD, 520)
	content.add_child(_next_operation_label)
	_mission_operation_block = VBoxContainer.new()
	_mission_operation_block.name = "MissionOperationBlock"
	_mission_operation_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_operation_block.add_theme_constant_override(&"separation", 24)
	_mission_operation_block.add_child(_build_mission_card())
	_mission_operation_block.add_child(_build_mission_details())
	content.add_child(_mission_operation_block)

	if not _training_acknowledgement.is_empty():
		content.add_child(_build_acknowledgement())

	var action_spacer := Control.new()
	action_spacer.name = "MissionActionSpacer"
	action_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(action_spacer)
	_mission = _build_mission_button()
	_mission.pressed.connect(_on_mission_control)
	content.add_child(_mission)
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
	_operation_list_margin = MarginContainer.new()
	_operation_list_margin.name = "OperationListMargin"
	_operation_list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_list_margin.add_theme_constant_override(&"margin_left", OPERATION_LIST_SIDE_MARGIN)
	_operation_list_margin.add_theme_constant_override(&"margin_right", OPERATION_LIST_SIDE_MARGIN)
	_operation_scroll.add_child(_operation_list_margin)
	_operation_list_margin.add_child(_operation_grid)

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
	_resonance_sparkles = _mount_button_sparkles(
		_recruit, "ResonanceSparkles", 0.41,
	)
	_recruit.move_child(_resonance_sparkles, 0)
	_add_locked_operation(
		"ArmoryButton", StagingGlyphType.Kind.ARMORY,
		&"ui.staging.armory_short", "Armory",
		&"ui.staging.armory_unavailable", "Armory — Unavailable",
	)
	_vahalla = StagingCommandTileType.new()
	_vahalla.name = "VahallaButton"
	_vahalla.configure(
		StagingGlyphType.Kind.MEMORIAL,
		UiCopyType.text(&"ui.staging.valhalla_short", "Valhalla"),
		UiCopyType.text(&"ui.staging.valhalla", "Valhalla"),
		true,
	)
	_vahalla.pressed.connect(_on_vahalla)
	_command_tiles.append(_vahalla)
	_operation_grid.add_child(_vahalla)
	_archive = StagingCommandTileType.new()
	_archive.name = "AnimaArchiveButton"
	_archive.configure(
		StagingGlyphType.Kind.ARCHIVE,
		UiCopyType.text(&"ui.staging.archive_short", "Archive"),
		UiCopyType.text(&"ui.staging.archive", "Anima Archive"),
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
	_mission_card.custom_minimum_size.y = NEXT_MISSION_CARD_MIN_HEIGHT
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

	_next_operation_action = Button.new()
	_next_operation_action.name = "NextOperationAction"
	_next_operation_action.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_next_operation_action.focus_mode = Control.FOCUS_ALL
	_next_operation_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_next_operation_action.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	_next_operation_action.add_theme_stylebox_override(
		&"hover", _panel_style(Color(GOLD, 0.07), Color(GOLD, 0.24), 1, 4),
	)
	_next_operation_action.add_theme_stylebox_override(
		&"pressed", _panel_style(Color(GOLD, 0.12), Color(BRIGHT_GOLD, 0.42), 1, 4),
	)
	_register_focus_pulse(_next_operation_action, GOLD)
	_next_operation_action.pressed.connect(_on_next_operation)
	_mission_card.add_child(_next_operation_action)
	_refresh_next_operation_action()
	return _mission_card


func _build_mission_details() -> PanelContainer:
	_mission_details_panel = PanelContainer.new()
	_mission_details_panel.name = "MissionDetails"
	_mission_details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var details_style := _panel_style(
		Color(DEEP_NAVY, 0.78), Color(GOLD, 0.26), 1, 4,
	)
	details_style.content_margin_left = 18.0
	details_style.content_margin_top = 12.0
	details_style.content_margin_right = 18.0
	details_style.content_margin_bottom = 12.0
	_mission_details_panel.add_theme_stylebox_override(&"panel", details_style)

	var stack := VBoxContainer.new()
	stack.name = "MissionDetailsContent"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override(&"separation", 8)
	_mission_details_panel.add_child(stack)

	_mission_brief_heading = _label(
		"MissionBriefHeading",
		UiCopyType.text(&"ui.staging.mission_brief", "MISSION BRIEF"),
		16,
		GOLD,
	)
	StagingSkinType.apply_display_type(_mission_brief_heading, 16, GOLD, 600)
	stack.add_child(_mission_brief_heading)

	_mission_description = _label(
		"MissionDescription", _next_operation_description(), 17, IVORY,
	)
	_mission_description.max_lines_visible = -1
	StagingSkinType.apply_body_type(_mission_description, 17, IVORY)
	stack.add_child(_mission_description)

	_mission_details_grid = GridContainer.new()
	_mission_details_grid.name = "MissionMetadataGrid"
	_mission_details_grid.columns = 1
	_mission_details_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_details_grid.add_theme_constant_override(&"h_separation", 20)
	_mission_details_grid.add_theme_constant_override(&"v_separation", 6)
	stack.add_child(_mission_details_grid)

	_mission_difficulty = _label(
		"MissionDifficulty", _next_operation_difficulty_text(), 24, GOLD,
	)
	_mission_difficulty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	StagingSkinType.apply_display_type(_mission_difficulty, 24, GOLD, 580)
	_mission_details_grid.add_child(_mission_difficulty)

	_mission_reward = _label(
		"MissionReward", _next_operation_reward_text(), 24, GOLD,
	)
	_mission_reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	StagingSkinType.apply_display_type(_mission_reward, 24, GOLD, 580)
	_mission_details_grid.add_child(_mission_reward)

	_mission_threat = _label(
		"MissionThreat", _next_operation_threat_text(), 16, MUTED,
	)
	_mission_threat.max_lines_visible = -1
	StagingSkinType.apply_body_type(_mission_threat, 16, MUTED)
	stack.add_child(_mission_threat)

	_mission_facts = _label(
		"MissionFacts", _next_operation_facts_text(), 23, MUTED,
	)
	_mission_facts.max_lines_visible = -1
	StagingSkinType.apply_display_type(_mission_facts, 23, MUTED, 520)
	_mission_facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_details_grid.add_child(_mission_facts)
	_mission_details_panel.visible = _next_stage != null
	return _mission_details_panel


func _build_mission_button() -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = "MissionControlButton"
	var full_text := UiCopyType.text(&"ui.staging.mission_control", "Mission Control")
	var display_text := UiCopyType.text(
		&"ui.staging.mission_control_display", "MISSION\nCONTROL",
	)
	button.set_presentation_text(full_text, display_text.to_upper())
	button.tooltip_text = full_text
	button.disabled = _narrative_missing
	button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0.0, 200.0)
	_mission_action_label = button.get_node("PresentationLabel") as Label
	_mission_action_label.offset_left = 132.0
	_mission_action_label.offset_top = MISSION_ACTION_VERTICAL_PADDING
	_mission_action_label.offset_right = -132.0
	_mission_action_label.offset_bottom = -MISSION_ACTION_VERTICAL_PADDING
	_mission_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_action_label.max_lines_visible = 2
	StagingSkinType.apply_display_type(
		_mission_action_label, 42,
		IVORY if not button.disabled else MUTED, 560,
	)
	_mission_action_label.add_theme_constant_override(&"outline_size", 6)
	_mission_action_label.add_theme_color_override(&"font_outline_color", Color(VOID, 0.92))
	_mission_action_label.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	_mission_action_label.add_theme_constant_override(&"shadow_outline_size", 0)
	_mission_action_label.add_theme_constant_override(&"shadow_offset_x", 0)
	_mission_action_label.add_theme_constant_override(&"shadow_offset_y", 0)
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_mission_plate = TextureRect.new()
	_mission_plate.name = "MissionControlPlate"
	_mission_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mission_plate.texture = MISSION_CONTROL_PLATE
	_mission_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mission_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_mission_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_plate.modulate = Color(0.48, 0.52, 0.56, 0.78) if button.disabled else Color.WHITE
	button.add_child(_mission_plate)
	button.move_child(_mission_plate, 0)
	_mission_sparkles = _mount_button_sparkles(
		button, "MissionControlSparkles", 0.07,
	)
	button.move_child(_mission_sparkles, 1)
	_register_focus_pulse(button, GOLD)
	button.mouse_entered.connect(_on_mission_hover_changed.bind(true))
	button.mouse_exited.connect(_on_mission_hover_changed.bind(false))
	button.focus_entered.connect(_update_mission_plate_state)
	button.focus_exited.connect(_update_mission_plate_state)
	return button


func _mount_button_sparkles(
	button: Button,
	node_name: String,
	phase_offset: float,
) -> StagingButtonSparklesType:
	var sparkles := StagingButtonSparklesType.new()
	sparkles.name = node_name
	sparkles.configure(phase_offset)
	button.add_child(sparkles)
	sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sparkles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sparkles


func _on_mission_hover_changed(hovered: bool) -> void:
	_mission_hovered = hovered
	_update_mission_plate_state()


func _update_mission_plate_state() -> void:
	if _mission_plate == null or _mission == null:
		return
	if _mission_hover_tween != null and _mission_hover_tween.is_valid():
		_mission_hover_tween.kill()
	_mission_plate.pivot_offset = _mission_plate.size * 0.5
	_mission_action_label.pivot_offset = _mission_action_label.size * 0.5
	if _mission.disabled:
		_mission_plate.modulate = Color(0.48, 0.52, 0.56, 0.78)
		_mission_plate.scale = Vector2.ONE
		_mission_action_label.modulate = Color.WHITE
		_mission_action_label.scale = Vector2.ONE
		_mission_action_label.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
		return
	var active := _mission_hovered
	var plate_color := Color(1.10, 1.16, 1.24, 1.0) if active else Color.WHITE
	var plate_scale := Vector2(1.012, 1.025) if active else Vector2.ONE
	var label_color := Color(1.04, 1.10, 1.16, 1.0) if active else Color.WHITE
	var label_scale := Vector2(1.02, 1.02) if active else Vector2.ONE
	_mission_action_label.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	if _reduced_motion:
		_mission_plate.modulate = plate_color
		_mission_plate.scale = plate_scale
		_mission_action_label.modulate = label_color
		_mission_action_label.scale = label_scale
		return
	_mission_hover_tween = create_tween().set_parallel(true)
	_mission_hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_mission_hover_tween.tween_property(_mission_plate, ^"modulate", plate_color, 0.18)
	_mission_hover_tween.tween_property(_mission_plate, ^"scale", plate_scale, 0.18)
	_mission_hover_tween.tween_property(_mission_action_label, ^"modulate", label_color, 0.16)
	_mission_hover_tween.tween_property(_mission_action_label, ^"scale", label_scale, 0.16)


func _register_focus_pulse(button: Button, accent: Color) -> void:
	var style := StagingSkinType.golden_focus_tint_style()
	style.bg_color = Color(accent, StagingSkinType.FOCUS_TINT_ALPHA)
	button.add_theme_stylebox_override(&"focus", style)
	_focus_pulse_styles[button] = style


func _build_acknowledgement() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "TrainingAcknowledgement"
	panel.add_theme_stylebox_override(&"panel", _panel_style(
		Color(MOON_CYAN, 0.08), Color(MOON_CYAN, 0.46), 1, 3,
	))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 24)
	margin.add_theme_constant_override(&"margin_top", 24)
	margin.add_theme_constant_override(&"margin_right", 24)
	margin.add_theme_constant_override(&"margin_bottom", 24)
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
	var actions: Array[Control] = [_mission]
	if _next_operation_action != null and not _next_operation_action.disabled:
		actions.append(_next_operation_action)
	if _recruit != null and not _recruit.disabled:
		actions.append(_recruit)
	if _vahalla != null and not _vahalla.disabled:
		actions.append(_vahalla)
	if _archive != null and not _archive.disabled:
		actions.append(_archive)
	if _training != null and not _training.disabled:
		actions.append(_training)
	actions.append(_settings_button)
	actions.append(_back)
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
		if not bool(current.get_meta(&"_staging_focus_visibility_connected", false)):
			current.focus_entered.connect(_ensure_action_visible.bind(current))
			current.set_meta(&"_staging_focus_visibility_connected", true)


func _ensure_action_visible(control: Control) -> void:
	for scroll_name: String in ["LandscapeCommandScroll", "PortraitCommandScroll", "OperationsScroll"]:
		var scroll := find_child(scroll_name, true, false) as ScrollContainer
		if scroll != null and scroll.is_ancestor_of(control):
			scroll.ensure_control_visible.call_deferred(control)


func _load_preferences() -> void:
	_reduced_motion = ViewPreferencesType.reduced_motion(_preferences_path)
	_music_enabled = ViewPreferencesType.title_music_enabled(_preferences_path)
	_master_volume = ViewPreferencesType.master_volume(_preferences_path)
	_master_muted = ViewPreferencesType.master_muted(_preferences_path)
	_music_volume = ViewPreferencesType.music_volume(_preferences_path)
	_sfx_volume = ViewPreferencesType.sfx_volume(_preferences_path)
	_frame_limit = ViewPreferencesType.frame_limit(_preferences_path)
	_text_scale = ViewPreferencesType.text_scale(_preferences_path)
	_background_downloads_enabled = ViewPreferencesType.background_downloads_enabled(_preferences_path)


func _open_settings() -> void:
	if _screen_state != ScreenState.COMMAND:
		return
	if _tutorial != null and is_instance_valid(_tutorial) and _tutorial.is_active():
		return
	_settings_snapshot = _current_preferences()
	_settings_snapshot[&"return_focus"] = _settings_button
	_screen_state = ScreenState.SETTINGS
	Sfx.play("menu_open")
	_set_command_interaction_enabled(false)
	_settings_state.open(_settings_snapshot)


func _cancel_settings() -> void:
	if _screen_state != ScreenState.SETTINGS or _settings_state.transition_state_name() != &"ACTIVE":
		return
	var snapshot := _settings_snapshot.duplicate(true)
	_settings_snapshot[&"closing_return_focus"] = snapshot.get(&"return_focus") as Control
	if not _settings_state.close():
		return
	_apply_preference_values(snapshot)
	Sfx.play("menu_close")


func _apply_settings(draft: Dictionary) -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	_screen_state = ScreenState.COMMITTING
	_settings_state.set_committing(true)
	if not ViewPreferencesType.save_batch(draft, _preferences_path):
		_screen_state = ScreenState.SETTINGS
		_settings_state.show_save_failure()
		return
	_apply_preference_values(draft)
	Sfx.play("ui_confirm")
	_settings_snapshot[&"closing_return_focus"] = _settings_snapshot.get(&"return_focus") as Control
	_screen_state = ScreenState.SETTINGS
	_settings_state.close()


func _preview_settings(draft: Dictionary) -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	_apply_preference_values(draft, false)


func _on_settings_close_completed() -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	var return_focus := _settings_snapshot.get(&"closing_return_focus") as Control
	_settings_snapshot = {}
	_screen_state = ScreenState.COMMAND
	_set_command_interaction_enabled(true)
	var target := return_focus
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		target = _settings_button
	target.grab_focus()


func _current_preferences() -> Dictionary:
	return {
		&"locale": I18n.locale(),
		&"title_music_enabled": _music_enabled,
		&"master_volume": _master_volume,
		&"master_muted": _master_muted,
		&"music_volume": _music_volume,
		&"sfx_volume": _sfx_volume,
		&"frame_limit": _frame_limit,
		&"reduced_motion": _reduced_motion,
		&"text_scale": _text_scale,
		&"background_downloads_enabled": _background_downloads_enabled,
	}


func _apply_preference_values(values: Dictionary, apply_background_policy := true) -> void:
	var locale_id := StringName(values.get(&"locale", I18n.locale()))
	if I18n.locale() != locale_id:
		I18n.set_locale(locale_id)
	_reduced_motion = bool(values.get(&"reduced_motion", _reduced_motion))
	_frame_limit = int(values.get(&"frame_limit", _frame_limit))
	_master_volume = float(values.get(&"master_volume", _master_volume))
	_master_muted = bool(values.get(&"master_muted", _master_muted))
	_music_volume = float(values.get(&"music_volume", _music_volume))
	_sfx_volume = float(values.get(&"sfx_volume", _sfx_volume))
	_text_scale = float(values.get(&"text_scale", _text_scale))
	var previous_background_downloads := _background_downloads_enabled
	if apply_background_policy:
		_background_downloads_enabled = bool(
			values.get(&"background_downloads_enabled", _background_downloads_enabled),
		)
	var previous_music_enabled := _music_enabled
	_music_enabled = bool(values.get(&"title_music_enabled", _music_enabled))
	_apply_audio_settings()
	_apply_graphics_settings()
	_backdrop.set_reduced_motion(_reduced_motion)
	_settings_state.set_reduced_motion(_reduced_motion)
	if _mission_sparkles != null:
		_mission_sparkles.set_reduced_motion(_reduced_motion)
	if _resonance_sparkles != null:
		_resonance_sparkles.set_reduced_motion(_reduced_motion)
	if apply_background_policy:
		_apply_background_download_policy()
		if _background_downloads_enabled and not previous_background_downloads:
			_resume_background_prefetch()
	Music.set_enabled(_music_enabled)
	if _music_enabled and (not previous_music_enabled or Music.current_id().is_empty()):
		Music.play_staging(&"lunaris")
	_refresh_locale_copy()
	_apply_responsive_layout()
	_settings_state.call_deferred("_apply_responsive_layout")


func _apply_background_download_policy() -> void:
	var limits := {&"classes": 2, &"resonance": 1, &"missions": 2}
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.call(
			"set_background_downloads_enabled", _background_downloads_enabled,
		)
		limits = content_packs.call("adaptive_prefetch_limits") as Dictionary
	var cinematic_prefetch := get_node_or_null("/root/CinematicPrefetch")
	if cinematic_prefetch != null:
		cinematic_prefetch.call(
			"set_background_download_policy",
			_background_downloads_enabled,
			int(limits.get(&"resonance", 0)),
		)
	var mission_prefetch := get_node_or_null("/root/MissionCinematicPrefetch")
	if mission_prefetch != null:
		mission_prefetch.call(
			"set_background_download_policy",
			_background_downloads_enabled,
			int(limits.get(&"missions", 0)),
		)


func _resume_background_prefetch() -> void:
	var cinematic_prefetch := get_node_or_null("/root/CinematicPrefetch")
	if cinematic_prefetch != null:
		cinematic_prefetch.call("prefetch_from_title", get_viewport_rect().size)
	var mission_prefetch := get_node_or_null("/root/MissionCinematicPrefetch")
	if mission_prefetch != null:
		mission_prefetch.call("prefetch_from_title")
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null and Game.campaign_active:
		content_packs.call(
			"prefetch_roster",
			Game.campaign_projection().get("ready_heroes", []),
			Game.selected_squad,
		)


func _on_content_background_policy_changed(
		_enabled: bool,
		_network_profile: StringName,
		_class_limit: int,
	) -> void:
	_apply_background_download_policy()
	if _background_downloads_enabled:
		_resume_background_prefetch()


func _set_command_interaction_enabled(enabled: bool) -> void:
	var actions: Array[BaseButton] = [
		_mission, _next_operation_action, _recruit, _vahalla, _archive,
		_training, _settings_button, _back,
	]
	for action: BaseButton in actions:
		if action == null:
			continue
		action.focus_mode = (
			Control.FOCUS_ALL if enabled and not action.disabled else Control.FOCUS_NONE
		)
	if enabled:
		_connect_focus_cycle()


func _apply_audio_settings() -> void:
	_set_bus_volume(MASTER_BUS, _master_volume, _master_muted)
	_set_bus_volume(MUSIC_BUS, _music_volume)
	_set_bus_volume(SFX_BUS, _sfx_volume)


func _set_bus_volume(bus_name: StringName, value: float, force_mute := false) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, force_mute or value <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))


func _apply_graphics_settings() -> void:
	Engine.max_fps = _frame_limit
	ProjectSettings.set_setting("accessibility/reduced_motion", _reduced_motion)
	TextScale.set_scale(_text_scale)


func settings_screen_state() -> StringName:
	match _screen_state:
		ScreenState.SETTINGS:
			return &"SETTINGS"
		ScreenState.COMMITTING:
			return &"COMMITTING"
		_:
			return &"COMMAND"


func _apply_responsive_layout() -> void:
	if _landscape_layout == null or _portrait_layout == null:
		return
	var canvas_size := get_viewport_rect().size
	var viewport_size := canvas_size
	var physical_size := Vector2(DisplayServer.window_get_size())
	if physical_size.x > 0.0 and physical_size.y > 0.0:
		viewport_size = Vector2(
			minf(canvas_size.x, physical_size.x),
			minf(canvas_size.y, physical_size.y),
		)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var hidden_extent := Vector2(
		maxf(0.0, canvas_size.x - viewport_size.x),
		maxf(0.0, canvas_size.y - viewport_size.y),
	)
	_backdrop.fit_top_cover(viewport_size)
	var safe_insets := _display_safe_insets(viewport_size)
	var aspect := viewport_size.x / viewport_size.y
	_portrait = viewport_size.y > viewport_size.x
	_compact_landscape = not _portrait and (aspect < 1.45 or viewport_size.x < 1700.0)
	var large_text := float(TextScale.value()) >= 1.20
	var landscape_scroll := _landscape_deck.get_node_or_null("LandscapeCommandScroll") as ScrollContainer
	var portrait_scroll := _portrait_sheet.get_node_or_null("PortraitCommandScroll") as ScrollContainer
	var constrained_rail := not _portrait and not _compact_landscape and viewport_size.y < 1000.0
	for document_scroll: ScrollContainer in [landscape_scroll, portrait_scroll]:
		if document_scroll != null:
			var constrained_portrait := (
				document_scroll == portrait_scroll
				and (viewport_size.x < 620.0 or viewport_size.y < 1000.0)
			)
			document_scroll.vertical_scroll_mode = (
				ScrollContainer.SCROLL_MODE_AUTO
				if large_text
				or document_scroll == portrait_scroll
				or (document_scroll == landscape_scroll and _compact_landscape)
				or (document_scroll == landscape_scroll and constrained_rail)
				or constrained_portrait
				else ScrollContainer.SCROLL_MODE_DISABLED
			)
	_landscape_layout.visible = not _portrait
	_portrait_layout.visible = _portrait
	_place_responsive_content()

	var landscape_left := maxf(LANDSCAPE_GUTTER, safe_insets.x)
	var landscape_right := maxf(LANDSCAPE_GUTTER, safe_insets.z)
	_landscape_layout.offset_left = landscape_left
	_landscape_layout.offset_right = -(landscape_right + hidden_extent.x)
	_landscape_layout.offset_top = TOP_HUD_HEIGHT + maxf(0.0, safe_insets.y) + 8.0
	_landscape_layout.offset_bottom = -(
		maxf(LANDSCAPE_BOTTOM_GUTTER, safe_insets.w) + hidden_extent.y
	)
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
	var deck_style := StagingSkinType.command_deck_style()
	if _compact_landscape:
		deck_style.content_margin_top = 24.0
		deck_style.content_margin_bottom = 24.0
	elif viewport_size.y < 850.0:
		deck_style.content_margin_top = 24.0
		deck_style.content_margin_bottom = 24.0
	_landscape_deck.add_theme_stylebox_override(&"panel", deck_style)

	var portrait_gutter := 12.0 if viewport_size.x < 480.0 else 24.0
	var portrait_left := maxf(portrait_gutter, safe_insets.x)
	var portrait_right := maxf(portrait_gutter, safe_insets.z)
	_portrait_layout.offset_left = portrait_left
	_portrait_layout.offset_right = -(portrait_right + hidden_extent.x)
	_portrait_layout.offset_top = TOP_HUD_HEIGHT + maxf(0.0, safe_insets.y - 8.0)
	_portrait_layout.offset_bottom = -(maxf(16.0, safe_insets.w) + hidden_extent.y)
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
	if _tutorial != null and is_instance_valid(_tutorial):
		_tutorial.relayout.call_deferred()


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
	var active_text_scale := float(TextScale.value())
	var narrow := viewport_size.x < 620.0 or (active_text_scale >= 1.20 and viewport_size.x < 850.0)
	var ultra_narrow := viewport_size.x < 480.0 or (active_text_scale >= 1.45 and viewport_size.x < 850.0)
	var compact := _portrait or _compact_landscape or viewport_size.x < 1180.0
	_top_row.add_theme_constant_override(&"separation", 4 if ultra_narrow else (6 if narrow else 14))
	_utility_actions.add_theme_constant_override(&"separation", 2 if ultra_narrow else (4 if narrow else 10))
	_top_bar_margin.add_theme_constant_override(&"margin_left", maxi(4 if ultra_narrow else (8 if narrow else 16), roundi(safe_insets.x)))
	_top_bar_margin.add_theme_constant_override(&"margin_right", maxi(4 if ultra_narrow else (8 if narrow else 16), roundi(safe_insets.z)))
	_top_status_chip.visible = not compact and viewport_size.x >= 1120.0
	_top_identity_plate.custom_minimum_size = (
		Vector2(44.0, 88.0) if ultra_narrow
		else Vector2(150.0, 92.0) if narrow
		else (Vector2(300.0, 104.0) if compact else Vector2(420.0, 112.0))
	)
	_top_identity.text = _company_identity(narrow)
	_top_identity.visible = not ultra_narrow
	_top_crest.custom_minimum_size = (
		Vector2(28.0, 28.0) if ultra_narrow
		else Vector2(32.0, 32.0) if narrow
		else (Vector2(44.0, 44.0) if compact else Vector2(58.0, 58.0))
	)
	StagingSkinType.apply_display_type(_top_identity, 16 if narrow else (22 if compact else 28), IVORY, 620)
	StagingSkinType.apply_display_type(_top_summary, 20 if compact else 24, IVORY, 560)
	_back.text = UiCopyType.text(&"ui.common.exit", "Exit")
	_exit_label.text = _back.text.to_upper()
	_settings_button.text = UiCopyType.text(&"ui.title.settings", "Settings")
	_settings_button.tooltip_text = _settings_button.text
	_settings_button.accessibility_name = _settings_button.text
	_settings_label.text = _settings_button.text.to_upper()
	_exit_label.visible = not narrow
	_settings_label.visible = not narrow
	var utility_button_size := Vector2(54.0, 62.0) if ultra_narrow else (Vector2(68.0, 68.0) if narrow else (Vector2(154.0, 80.0) if compact else Vector2(196.0, 88.0)))
	var utility_plate_size := Vector2(64.0, 82.0) if ultra_narrow else (Vector2(80.0, 88.0) if narrow else (Vector2(180.0, 104.0) if compact else Vector2(228.0, 112.0)))
	_back.custom_minimum_size = utility_button_size
	_settings_button.custom_minimum_size = utility_button_size
	_exit_plate.custom_minimum_size = utility_plate_size
	_settings_plate.custom_minimum_size = utility_plate_size
	var utility_plate_style: StyleBox = (
		StyleBoxEmpty.new() if ultra_narrow else StagingSkinType.company_hud_plate_style()
	)
	_settings_plate.add_theme_stylebox_override(&"panel", utility_plate_style)
	_exit_plate.add_theme_stylebox_override(
		&"panel", StyleBoxEmpty.new() if ultra_narrow else StagingSkinType.company_hud_plate_style(),
	)
	_settings_icon.custom_minimum_size = Vector2(26.0, 26.0) if ultra_narrow else (Vector2(32.0, 32.0) if narrow else (Vector2(36.0, 36.0) if compact else Vector2(44.0, 44.0)))
	_exit_icon.custom_minimum_size = _settings_icon.custom_minimum_size
	for utility_button: Button in [_settings_button, _back]:
		var utility_margin := utility_button.get_child(0) as MarginContainer
		utility_margin.add_theme_constant_override(&"margin_left", 6 if ultra_narrow else (8 if narrow else (10 if compact else 22)))
		utility_margin.add_theme_constant_override(&"margin_right", 6 if ultra_narrow else (8 if narrow else (10 if compact else 22)))
	_top_status_chip.custom_minimum_size = Vector2(300.0, 104.0) if compact else Vector2(354.0, 112.0)
	StagingSkinType.apply_display_type(_exit_label, 16 if compact else 22, MUTED, 600)
	StagingSkinType.apply_display_type(_settings_label, 16 if compact else 22, MUTED, 600)


func _apply_command_geometry(viewport_size: Vector2) -> void:
	var single_column := (_portrait and viewport_size.x < 620.0)
	var ultra_narrow := viewport_size.x < 480.0
	var hide_preview := _compact_landscape
	var short_wide := not _portrait and not _compact_landscape and viewport_size.y < 850.0
	var concise_details := not _portrait
	var low_landscape := not _portrait and viewport_size.y < 1000.0
	_command_content.add_theme_constant_override(&"separation", 8 if short_wide else INTRA_GROUP_GAP)
	_campaign_milestones.visible = not low_landscape
	_mission_preview.visible = not hide_preview
	_mission_body_grid.columns = 1 if single_column or hide_preview else 2
	_mission_details_grid.columns = 1
	_mission_brief_heading.visible = not concise_details
	_mission_description.visible = not concise_details
	_mission_threat.visible = not concise_details
	_mission_facts.visible = true
	_mission_grid.add_theme_constant_override(&"v_separation", 8 if short_wide else 12)
	_mission_body_grid.add_theme_constant_override(&"h_separation", 20 if short_wide else 24)
	_campaign_progress_text.visible = not ultra_narrow
	var deck_style := StagingSkinType.command_deck_style()
	if ultra_narrow:
		deck_style.content_margin_left = 24.0
		deck_style.content_margin_right = 24.0
	_portrait_sheet.add_theme_stylebox_override(&"panel", deck_style)
	var mission_style := StagingSkinType.mission_card_style()
	_mission_card.add_theme_stylebox_override(&"panel", mission_style)
	_mission_card.custom_minimum_size.y = (
		320.0 if single_column
		else 0.0 if hide_preview
		else 0.0 if short_wide
		else 220.0 if low_landscape
		else NEXT_MISSION_CARD_MIN_HEIGHT
	)
	var details_style := _mission_details_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	if details_style != null:
		details_style.content_margin_top = 8.0 if short_wide else 12.0
		details_style.content_margin_bottom = 8.0 if short_wide else 12.0
	_mission_preview.custom_minimum_size = (
		Vector2(0.0, 112.0) if single_column
		else (Vector2(144.0, 84.0) if short_wide else Vector2(160.0, 128.0))
	)
	_operation_grid.columns = 1 if (not _portrait and not _compact_landscape) or viewport_size.x < 760.0 else 2
	_operation_grid.add_theme_constant_override(
		&"v_separation", 6 if not _portrait and not _compact_landscape else 10,
	)
	_mission.custom_minimum_size.y = (
		150.0 if _compact_landscape
		else (164.0 if single_column or _portrait else (168.0 if short_wide else 180.0))
	)
	_mission_action_label.offset_left = 30.0 if ultra_narrow else (56.0 if single_column else (96.0 if _portrait or _compact_landscape else 132.0))
	_mission_action_label.offset_right = -_mission_action_label.offset_left
	_mission_action_label.offset_top = MISSION_ACTION_VERTICAL_PADDING
	_mission_action_label.offset_bottom = -_mission_action_label.offset_top
	for tile: StagingCommandTileType in _command_tiles:
		tile.set_rail_mode(not _portrait and not _compact_landscape)
		if short_wide:
			tile.set_short_rail_mode()


func _apply_company_typography() -> void:
	var compact := _compact_landscape
	var rail_mode := not _portrait and not _compact_landscape
	var short_wide := rail_mode and get_viewport_rect().size.y < 850.0
	var ultra_narrow := get_viewport_rect().size.x < 480.0
	StagingSkinType.apply_display_type(_command_heading, 20 if ultra_narrow else (22 if compact else 24), GOLD, 560)
	StagingSkinType.apply_display_type(_campaign_progress_text, 18, IVORY, 520)
	StagingSkinType.apply_display_type(_next_operation_label, 17 if compact else 18, GOLD, 520)
	StagingSkinType.apply_display_type(_mission_title, 20 if ultra_narrow else (24 if compact or _portrait or short_wide else 26), IVORY, 560)
	_mission_objective.add_theme_font_size_override(&"font_size", 18 if ultra_narrow else (22 if compact or short_wide else 24))
	StagingSkinType.apply_display_type(_mission_brief_heading, 15 if ultra_narrow else 16, GOLD, 600)
	StagingSkinType.apply_body_type(_mission_description, 16 if ultra_narrow else 17, IVORY)
	StagingSkinType.apply_display_type(_mission_difficulty, 24, GOLD, 580)
	StagingSkinType.apply_display_type(_mission_reward, 24, GOLD, 580)
	StagingSkinType.apply_body_type(_mission_threat, 15 if ultra_narrow else 16, MUTED)
	StagingSkinType.apply_display_type(_mission_facts, 23, MUTED, 520)
	StagingSkinType.apply_display_type(_mission_action_label, 30 if ultra_narrow else (36 if compact or _portrait else 42), IVORY, 620)
	StagingSkinType.apply_display_type(_operations_label, 32 if rail_mode else 18, GOLD, 560)


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


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_locale_copy()
	_apply_responsive_layout()


func _on_text_scale_changed(_value: float) -> void:
	_apply_responsive_layout.call_deferred()


func _refresh_locale_copy() -> void:
	if _top_identity == null:
		return
	_top_identity.text = _company_identity(get_viewport_rect().size.x < 620.0)
	_top_summary.text = _campaign_summary_text()
	_campaign_progress_text.text = _campaign_summary_text()
	_back.text = UiCopyType.text(&"ui.common.exit", "Exit")
	_exit_label.text = _back.text.to_upper()
	_settings_button.text = UiCopyType.text(&"ui.title.settings", "Settings")
	_settings_button.tooltip_text = _settings_button.text
	_settings_button.accessibility_name = _settings_button.text
	_settings_label.text = _settings_button.text.to_upper()
	_command_heading.text = UiCopyType.text(&"ui.staging.command_heading", "COMPANY COMMAND")
	_next_operation_label.text = UiCopyType.text(&"ui.staging.next_label", "NEXT OPERATION")
	_mission_title.text = _next_operation_title()
	_mission_objective.text = _next_operation_objective()
	_mission_brief_heading.text = UiCopyType.text(
		&"ui.staging.mission_brief", "MISSION BRIEF",
	)
	_mission_description.text = _next_operation_description()
	_mission_difficulty.text = _next_operation_difficulty_text()
	_mission_reward.text = _next_operation_reward_text()
	_mission_threat.text = _next_operation_threat_text()
	_mission_facts.text = _next_operation_facts_text()
	_refresh_next_operation_action()
	_operations_label.text = UiCopyType.text(&"ui.staging.operations", "OPERATIONS")
	var mission_copy := UiCopyType.text(&"ui.staging.mission_control", "Mission Control")
	var mission_display := UiCopyType.text(
		&"ui.staging.mission_control_display", "MISSION\nCONTROL",
	)
	_mission.set_presentation_text(mission_copy, mission_display.to_upper())
	_mission.tooltip_text = mission_copy
	_recruit.configure(StagingGlyphType.Kind.RECRUIT, UiCopyType.text(&"ui.staging.recruit_short", "Resonance"), UiCopyType.text(&"ui.staging.recruit", "Premium Resonance"), true)
	_vahalla.configure(StagingGlyphType.Kind.MEMORIAL, UiCopyType.text(&"ui.staging.valhalla_short", "Valhalla"), UiCopyType.text(&"ui.staging.valhalla", "Valhalla"), true)
	_archive.configure(StagingGlyphType.Kind.ARCHIVE, UiCopyType.text(&"ui.staging.archive_short", "Archive"), UiCopyType.text(&"ui.staging.archive", "Anima Archive"), true)
	var training_available := _training_available()
	_training.configure(StagingGlyphType.Kind.TRAINING, UiCopyType.text(&"ui.staging.training_short", "Training"), UiCopyType.text(&"ui.staging.training" if training_available else &"ui.staging.training_unavailable", "Training" if training_available else "Training — Unavailable"), training_available)
	var barracks := find_child("BarracksButton", true, false) as StagingCommandTileType
	if barracks != null:
		barracks.configure(StagingGlyphType.Kind.BARRACKS, UiCopyType.text(&"ui.staging.barracks_short", "Barracks"), UiCopyType.text(&"ui.staging.barracks_unavailable", "Barracks — Unavailable"), false)
	var armory := find_child("ArmoryButton", true, false) as StagingCommandTileType
	if armory != null:
		armory.configure(StagingGlyphType.Kind.ARMORY, UiCopyType.text(&"ui.staging.armory_short", "Armory"), UiCopyType.text(&"ui.staging.armory_unavailable", "Armory — Unavailable"), false)


func _company_identity(_compact: bool) -> String:
	return UiCopyType.text(&"ui.title.full_title", "Protos Defense").to_upper()


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
			"PROTOS drains living captives in human farms and uses their souls to power a robot empire. Company Manus defends Hearthcross, rescues people and souls, and breaks the harvesting network.",
		)
	return UiCopyType.stage_narrative_text(_next_record, StageNarrativeDefType.Field.OBJECTIVE)


func _next_operation_description() -> String:
	if _next_record == null:
		return UiCopyType.text(
			&"ui.error.missing_stage_narrative",
			"Mission record unavailable. Return to Mission Control.",
		)
	return UiCopyType.stage_narrative_text(
		_next_record, StageNarrativeDefType.Field.HUMAN_REASON,
	)


func _next_operation_threat_text() -> String:
	var threat := UiCopyType.text(
		&"ui.error.missing_stage_narrative",
		"Mission record unavailable. Return to Mission Control.",
	)
	if _next_record != null:
		threat = UiCopyType.stage_narrative_text(
			_next_record, StageNarrativeDefType.Field.THREAT,
		)
	return UiCopyType.format_text(
		&"ui.campaign.threat", "THREAT — {text}", {&"text": threat},
	)


func _next_operation_difficulty_text() -> String:
	var rank := 0
	if _next_stage != null:
		var total := maxi(Game.campaign_stage_ids().size(), _next_stage.campaign_index)
		rank = clampi(ceili(float(_next_stage.campaign_index) * 5.0 / float(total)), 1, 5)
	return UiCopyType.format_text(
		&"ui.staging.difficulty", "DIFFICULTY — {rank}/5", {&"rank": rank},
	)


func _next_operation_reward_text() -> String:
	var reward_names: Array[String] = []
	if _next_stage != null:
		for reward: Dictionary in _next_stage.rewards:
			reward_names.append(_reward_name(reward))
	var reward_copy := (
		_localized_list(reward_names)
		if not reward_names.is_empty()
		else UiCopyType.text(&"ui.campaign.record_only", "RECORD ONLY")
	)
	return UiCopyType.format_text(
		&"ui.campaign.first_clear_reward",
		"FIRST CLEAR — {rewards}",
		{&"rewards": reward_copy},
	)


func _next_operation_facts_text() -> String:
	if _next_stage == null:
		return ""
	return UiCopyType.format_text(
		&"ui.staging.mission_facts",
		"SQUAD {squad} · WAVE WINDOWS {waves} · LEAK LIMIT {leak_limit}",
		{
			&"squad": _next_stage.squad_size,
			&"waves": _next_stage.wave_starts.size(),
			&"leak_limit": _next_stage.leak_limit,
		},
	)


func _reward_name(reward: Dictionary) -> String:
	var kind := StringName(reward.get("kind", &""))
	var identifier := StringName(reward.get("id", &""))
	if kind == &"currency" and identifier == &"marks":
		return str(int(reward.get("amount", 0)))
	if not REWARD_DIRS.has(kind):
		return String(identifier).replace("_", " ").capitalize()
	var definition: Resource = load("%s/%s.tres" % [REWARD_DIRS[kind], identifier])
	if definition is OperatorDef:
		return UiCopyType.operator_name(definition)
	if definition is TrapDef:
		return UiCopyType.trap_name(definition)
	if definition is SpellDef:
		return UiCopyType.spell_name(definition)
	return String(identifier).replace("_", " ").capitalize()


func _localized_list(values: Array[String]) -> String:
	return ("、" if I18n.locale() == &"zh-CN" else ", ").join(values)


func _refresh_next_operation_action() -> void:
	if _next_operation_action == null:
		return
	var available := _next_stage != null and not _narrative_missing
	_next_operation_action.disabled = not available
	_next_operation_action.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	_next_operation_action.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	)
	var stage_title := UiCopyType.stage_title(_next_stage) if _next_stage != null else ""
	var action_copy := UiCopyType.format_text(
		&"ui.staging.next_operation_action",
		"Review {stage} in Mission Control",
		{&"stage": stage_title},
	) if available else ""
	_next_operation_action.tooltip_text = action_copy
	_next_operation_action.accessibility_name = action_copy
	_next_operation_action.accessibility_description = UiCopyType.text(
		&"ui.staging.next_operation_description",
		"Open Mission Control with this operation ready for selection.",
	) if available else ""


func _on_next_operation() -> void:
	if _next_stage == null or _narrative_missing:
		return
	Sfx.play("ui_click")
	Game.open_stage_select()


func set_preferences_path(path: String) -> void:
	if is_node_ready() or path.is_empty():
		return
	_preferences_path = path
	_preferences_path_explicit = true


func _maybe_mount_command_tutorial() -> bool:
	if not Game.consume_command_tutorial_request():
		return false
	if ViewPreferencesType.has_seen_command_tutorial(_preferences_path):
		return false
	var tutorial := CommandCenterTutorialType.new()
	add_child(tutorial)
	if not tutorial.setup(_mission, _recruit, _preferences_path, _reduced_motion):
		tutorial.queue_free()
		return false
	_tutorial = tutorial
	_tutorial.finished.connect(_on_command_tutorial_finished)
	return true


func _on_command_tutorial_finished(_skipped: bool, persisted: bool) -> void:
	_tutorial = null
	if not persisted:
		push_warning("Command Center tutorial completion could not be persisted")
	if _maybe_mount_post_mission_tutorial():
		return
	(_back if _mission.disabled else _mission).grab_focus.call_deferred()


func _maybe_mount_post_mission_tutorial() -> bool:
	var requested := Game.consume_post_mission_tutorial_request()
	if not requested and not _first_mission_completed():
		return false
	if ViewPreferencesType.has_seen_post_mission_tutorial(_preferences_path):
		return false
	var targets: Array[Control] = [_training, _vahalla]
	var steps: Array[Dictionary] = [
		{
			"id": &"training",
			"avoid_target": true,
			"step_key": &"ui.onboarding.post_mission.training.step",
			"step_fallback": "1 / 2  TRAINING",
			"title_key": &"ui.onboarding.post_mission.training.title",
			"title_fallback": "Promote experienced soldiers",
			"body_key": &"ui.onboarding.post_mission.training.body",
			"body_fallback": "Soldiers gain XP in missions. When they have enough, use Training to promote them into new specializations.",
			"action_key": &"ui.onboarding.command.next",
			"action_fallback": "NEXT",
		},
		{
			"id": &"valhalla",
			"avoid_target": true,
			"step_key": &"ui.onboarding.post_mission.valhalla.step",
			"step_fallback": "2 / 2  VALHALLA",
			"title_key": &"ui.onboarding.post_mission.valhalla.title",
			"title_fallback": "Honor the fallen",
			"body_key": &"ui.onboarding.post_mission.valhalla.body",
			"body_fallback": "Death is permanent. Soldiers who have fallen can be remembered and honored in Valhalla.",
			"action_key": &"ui.onboarding.command.done",
			"action_fallback": "DONE",
		},
	]
	var tutorial := CommandCenterTutorialType.new()
	add_child(tutorial)
	if not tutorial.setup_custom(
		"PostMissionTutorial",
		targets,
		steps,
		StringName(ViewPreferencesType.POST_MISSION_TUTORIAL_KEY),
		&"ui.onboarding.post_mission.a11y",
		"Post-mission tutorial",
		_preferences_path,
		_reduced_motion,
	):
		tutorial.queue_free()
		return false
	_tutorial = tutorial
	_tutorial.finished.connect(_on_post_mission_tutorial_finished)
	return true


func _first_mission_completed() -> bool:
	if Game.campaign == null:
		return false
	var stage_order := Game.campaign_stage_ids()
	return (
		not stage_order.is_empty()
		and int(_stage_stars().get(stage_order[0], 0)) > 0
	)


func _on_post_mission_tutorial_finished(_skipped: bool, persisted: bool) -> void:
	_tutorial = null
	if not persisted:
		push_warning("Post-mission tutorial completion could not be persisted")
	(_back if _mission.disabled else _mission).grab_focus.call_deferred()


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
