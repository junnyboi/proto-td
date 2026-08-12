class_name TacticalCueConfig
extends Resource

const STATES: Array[StringName] = [
	&"legal", &"invalid", &"range", &"skill", &"route", &"warning", &"lethal",
]
const ROW_KEYS: Array[StringName] = [
	&"color", &"geometry", &"pattern", &"icon_asset_id", &"label_key",
	&"english_fallback", &"motion",
]
const GEOMETRIES: Array[StringName] = [
	&"solid_diamond", &"dashed_diamond", &"perimeter_ticks", &"reticle_ring",
	&"route_chevrons", &"warning_triangle", &"inward_chevrons",
]
const PATTERNS: Array[StringName] = [
	&"solid", &"dashed", &"hatched", &"ticked", &"ring", &"repeated", &"critical",
]
const MOTIONS: Array[StringName] = [&"none", &"pulse", &"inward"]

@export var schema_version: int = 1
@export var config_id: StringName = &""
@export var cues: Dictionary = {}
@export var reduced_motion: bool = false
@export var high_contrast: bool = false
@export var ambient_suppression: float = 0.25


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	if config_id == &"":
		errors.append("config_id: required")
	if cues.size() != STATES.size():
		errors.append("cues: expected exact seven states")
	for state: StringName in STATES:
		if not cues.has(state):
			errors.append("cues: missing %s" % state)
			continue
		var raw_row: Variant = cues[state]
		if typeof(raw_row) != TYPE_DICTIONARY:
			errors.append("cues.%s: expected Dictionary" % state)
			continue
		_validate_row(state, raw_row, errors)
	for raw_key: Variant in cues:
		if typeof(raw_key) != TYPE_STRING_NAME or not STATES.has(raw_key):
			errors.append("cues: unexpected key %s" % raw_key)
	if not is_finite(ambient_suppression) or ambient_suppression < 0.25 \
		or ambient_suppression > 0.40:
		errors.append("ambient_suppression: expected finite [0.25,0.40]")
	return errors


func _validate_row(state: StringName, row: Dictionary, errors: PackedStringArray) -> void:
	if row.size() != ROW_KEYS.size():
		errors.append("cues.%s: expected exact seven fields" % state)
	for key: StringName in ROW_KEYS:
		if not row.has(key):
			errors.append("cues.%s: missing %s" % [state, key])
	for raw_key: Variant in row:
		if typeof(raw_key) != TYPE_STRING_NAME or not ROW_KEYS.has(raw_key):
			errors.append("cues.%s: unexpected key %s" % [state, raw_key])
	var raw_color: Variant = row.get(&"color")
	if typeof(raw_color) != TYPE_COLOR:
		errors.append("cues.%s.color: expected Color" % state)
	else:
		var color: Color = raw_color
		if not is_finite(color.r) or not is_finite(color.g) \
			or not is_finite(color.b) or not is_finite(color.a) \
			or color.r < 0.0 or color.r > 1.0 \
			or color.g < 0.0 or color.g > 1.0 \
			or color.b < 0.0 or color.b > 1.0 \
			or color.a < 0.0 or color.a > 1.0:
			errors.append("cues.%s.color: expected finite normalized RGBA" % state)
	_validate_enum(row, state, &"geometry", GEOMETRIES, errors)
	_validate_enum(row, state, &"pattern", PATTERNS, errors)
	_validate_enum(row, state, &"motion", MOTIONS, errors)
	for key: StringName in [&"icon_asset_id", &"label_key"]:
		if typeof(row.get(key)) != TYPE_STRING_NAME:
			errors.append("cues.%s.%s: expected StringName" % [state, key])
	if row.get(&"label_key", &"") == &"":
		errors.append("cues.%s.label_key: required" % state)
	if typeof(row.get(&"english_fallback")) != TYPE_STRING \
		or String(row.get(&"english_fallback", "")).is_empty():
		errors.append("cues.%s.english_fallback: required String" % state)


func _validate_enum(
	row: Dictionary, state: StringName, key: StringName, allowed: Array[StringName],
	errors: PackedStringArray
) -> void:
	var value: Variant = row.get(key)
	if typeof(value) != TYPE_STRING_NAME or not allowed.has(value):
		errors.append("cues.%s.%s: invalid enum" % [state, key])
