class_name FactionHeraldry
extends RefCounted

const ORDER: Array[StringName] = [
	&"solcrest_accord",
	&"vesper_circuit",
	&"lunaris_reliquary",
	&"crimson_aegis",
]
const ACTIVE_FACTION: StringName = &"lunaris_reliquary"

const SYMBOLS := {
	&"solcrest_accord": preload("res://assets/ui/factions/solcrest_accord_symbol.webp"),
	&"vesper_circuit": preload("res://assets/ui/factions/vesper_circuit_symbol.webp"),
	&"lunaris_reliquary": preload("res://assets/ui/factions/lunaris_reliquary_symbol.png"),
	&"crimson_aegis": preload("res://assets/ui/factions/crimson_aegis_symbol.webp"),
}
const BANNERS := {
	&"solcrest_accord": preload("res://assets/ui/factions/solcrest_accord_banner.webp"),
	&"vesper_circuit": preload("res://assets/ui/factions/vesper_circuit_banner.webp"),
	&"lunaris_reliquary": preload("res://assets/ui/factions/lunaris_reliquary_banner.webp"),
	&"crimson_aegis": preload("res://assets/ui/factions/crimson_aegis_banner.webp"),
}
const NAMES := {
	&"solcrest_accord": "SOLCREST ACCORD",
	&"vesper_circuit": "VESPER CIRCUIT",
	&"lunaris_reliquary": "LUNARIS RELIQUARY",
	&"crimson_aegis": "CRIMSON AEGIS",
}
const SUBTITLES := {
	&"solcrest_accord": "DAWN PHALANX",
	&"vesper_circuit": "MIDNIGHT RELAY",
	&"lunaris_reliquary": "SACRED ARCHIVE",
	&"crimson_aegis": "BREACH CARAVAN",
}
const SPECIALIZATIONS := {
	&"solcrest_accord": (
		"Formation defense, linked wards, rally commands, interception, and coordinated counterattacks."
	),
	&"vesper_circuit": (
		"Stealth deployment, marks, decoys, signal hijacking, rerouting, traps, and precision execution."
	),
	&"lunaris_reliquary": (
		"Memory, gravity, ritual geometry, prestige casters, and duelists."
	),
	&"crimson_aegis": (
		"Mobility, displacement, armor fracture, breach chains, and forward deployment."
	),
}
const ACCENTS := {
	&"solcrest_accord": Color("d8b978"),
	&"vesper_circuit": Color("5dd6e8"),
	&"lunaris_reliquary": Color("86cbd4"),
	&"crimson_aegis": Color("d9584d"),
}

static func symbol(faction_id: StringName) -> Texture2D:
	return SYMBOLS.get(faction_id, SYMBOLS[ACTIVE_FACTION]) as Texture2D


static func banner(faction_id: StringName) -> Texture2D:
	return BANNERS.get(faction_id, BANNERS[ACTIVE_FACTION]) as Texture2D


static func display_name(faction_id: StringName) -> String:
	return String(NAMES.get(faction_id, NAMES[ACTIVE_FACTION]))


static func subtitle(faction_id: StringName) -> String:
	return String(SUBTITLES.get(faction_id, SUBTITLES[ACTIVE_FACTION]))


static func specialization(faction_id: StringName) -> String:
	return String(SPECIALIZATIONS.get(faction_id, SPECIALIZATIONS[ACTIVE_FACTION]))


static func accent(faction_id: StringName) -> Color:
	return ACCENTS.get(faction_id, ACCENTS[ACTIVE_FACTION]) as Color


static func make_symbol(faction_id: StringName, edge: float = 44.0) -> TextureRect:
	var mark := TextureRect.new()
	mark.name = "%sSymbol" % String(faction_id).to_pascal_case()
	mark.texture = symbol(faction_id)
	mark.custom_minimum_size = Vector2(edge, edge)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.tooltip_text = "%s — %s" % [display_name(faction_id), specialization(faction_id)]
	return mark
