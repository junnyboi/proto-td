class_name StagingSkin
extends RefCounted

const StagingGlyphType := preload("res://scripts/ui/components/staging_glyph.gd")

const CINZEL := preload("res://assets/fonts/Cinzel-Variable.ttf")
const FALLBACK_THEME := preload("res://data/presentation/ui/threshold_theme.tres")

const LUNARIS_SEAL := preload("res://assets/ui/staging/icons/lunaris_seal.png")
const MISSION_ICON := preload("res://assets/ui/staging/icons/mission.png")
const BARRACKS_ICON := preload("res://assets/ui/staging/icons/barracks.png")
const RECRUIT_ICON := preload("res://assets/ui/staging/icons/recruit.png")
const ARMORY_ICON := preload("res://assets/ui/staging/icons/armory.png")
const MEMORIAL_ICON := preload("res://assets/ui/staging/icons/memorial.png")
const TRAINING_ICON := preload("res://assets/ui/staging/icons/training.png")
const EXIT_ICON := preload("res://assets/ui/staging/icons/exit.png")
const MESSAGE_ICON := preload("res://assets/ui/staging/icons/message.png")
const SETTINGS_ICON := preload("res://assets/ui/staging/icons/settings.png")
const STATUS_DIAMOND := preload("res://assets/ui/staging/icons/status_diamond.png")
const AETHER_ICON := preload("res://assets/ui/staging/icons/resource_aether.png")
const SIGIL_ICON := preload("res://assets/ui/staging/icons/resource_sigil.png")
const STAMINA_ICON := preload("res://assets/ui/staging/icons/resource_stamina.png")

const COMMAND_DECK_FRAME := preload("res://assets/ui/staging/frames/command_deck.png")
const MISSION_CARD_FRAME := preload("res://assets/ui/staging/frames/mission_card.png")
const OPERATION_TILE_FRAME := preload("res://assets/ui/staging/frames/operation_tile.png")
const PRIMARY_BUTTON_FRAME := preload("res://assets/ui/staging/frames/primary_button.png")
const RESOURCE_CHIP_FRAME := preload("res://assets/ui/staging/frames/resource_chip.png")
const NAVBAR_FRAME := preload("res://assets/ui/staging/frames/navbar.png")

const GOLD := Color("d9b96e")
const BRIGHT_GOLD := Color("f0d89a")
const MOON_CYAN := Color("91eaf1")
const IVORY := Color("f5efe1")
const MUTED := Color("aebfd0")
const INK := Color("07111c")

static var _display_font: FontVariation = null


static func display_font() -> FontVariation:
	if _display_font != null:
		return _display_font
	_display_font = FontVariation.new()
	_display_font.base_font = CINZEL
	if FALLBACK_THEME.default_font != null:
		_display_font.fallbacks = [FALLBACK_THEME.default_font]
	_display_font.variation_opentype = {&"wght": 520}
	_display_font.resource_name = "Cinzel with Protos CJK fallback"
	return _display_font


static func apply_display_type(
	control: Control,
	size: int,
	color: Color = IVORY,
	weight: int = 520,
) -> void:
	var font := FontVariation.new()
	font.base_font = CINZEL
	if FALLBACK_THEME.default_font != null:
		font.fallbacks = [FALLBACK_THEME.default_font]
	font.variation_opentype = {&"wght": weight}
	control.add_theme_font_override(&"font", font)
	control.add_theme_font_size_override(&"font_size", size)
	control.add_theme_color_override(&"font_color", color)


static func icon_for_glyph(kind: StagingGlyphType.Kind) -> Texture2D:
	match kind:
		StagingGlyphType.Kind.CREST:
			return LUNARIS_SEAL
		StagingGlyphType.Kind.BARRACKS:
			return BARRACKS_ICON
		StagingGlyphType.Kind.RECRUIT:
			return RECRUIT_ICON
		StagingGlyphType.Kind.ARMORY:
			return ARMORY_ICON
		StagingGlyphType.Kind.MEMORIAL:
			return MEMORIAL_ICON
		StagingGlyphType.Kind.TRAINING:
			return TRAINING_ICON
	return LUNARIS_SEAL


static func command_deck_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(COMMAND_DECK_FRAME, Vector4(68.0, 52.0, 68.0, 52.0), modulate)


static func mission_card_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(MISSION_CARD_FRAME, Vector4(62.0, 42.0, 62.0, 42.0), modulate)


static func operation_tile_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(OPERATION_TILE_FRAME, Vector4(56.0, 28.0, 56.0, 28.0), modulate)


static func primary_button_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(PRIMARY_BUTTON_FRAME, Vector4(58.0, 30.0, 58.0, 30.0), modulate)


static func clean_button_style(
	fill: Color,
	edge: Color,
	corner_radius: int = 4,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 24.0
	style.content_margin_top = 10.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


static func resource_chip_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(RESOURCE_CHIP_FRAME, Vector4(38.0, 24.0, 54.0, 24.0), modulate)


static func navbar_style(modulate: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(NAVBAR_FRAME, Vector4(68.0, 34.0, 68.0, 34.0), modulate)


static func transparent_focus_style(color: Color = MOON_CYAN) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.14)
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(4)
	style.expand_margin_left = 3.0
	style.expand_margin_top = 3.0
	style.expand_margin_right = 3.0
	style.expand_margin_bottom = 3.0
	return style


static func _texture_style(
	texture: Texture2D,
	margins: Vector4,
	modulate: Color,
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	style.modulate_color = modulate
	style.draw_center = true
	return style
