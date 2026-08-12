class_name EnvironmentTheme
extends Resource

const TILE_ROLES: Array[StringName] = [
	&"void", &"ground", &"road", &"elevated", &"spawn", &"base", &"blocked", &"backdrop",
]

@export var schema_version: int = 1
@export var theme_id: StringName = &""
@export var tile_asset_ids: Dictionary = {}
@export var edge_asset_ids: Dictionary = {}
@export var prop_pool_asset_ids: Array[StringName] = []
@export var backdrop_asset_id: StringName = &""
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.35)
@export var ambient_emission_scale: float = 1.0


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	if theme_id == &"":
		errors.append("theme_id: required")
	if backdrop_asset_id == &"":
		errors.append("backdrop_asset_id: required")
	_validate_tile_roles(errors)
	_validate_id_map(edge_asset_ids, "edge_asset_ids", errors)
	_validate_id_array(prop_pool_asset_ids, "prop_pool_asset_ids", errors)
	for value: float in [shadow_color.r, shadow_color.g, shadow_color.b, shadow_color.a]:
		if not is_finite(value) or value < 0.0 or value > 1.0:
			errors.append("shadow_color: components must be finite in [0,1]")
			break
	if not is_finite(ambient_emission_scale) or ambient_emission_scale < 0.0 \
		or ambient_emission_scale > 1.0:
		errors.append("ambient_emission_scale: expected finite [0,1]")
	return errors


func _validate_tile_roles(errors: PackedStringArray) -> void:
	if tile_asset_ids.size() != TILE_ROLES.size():
		errors.append("tile_asset_ids: expected exact eight roles")
	for role: StringName in TILE_ROLES:
		if not tile_asset_ids.has(role):
			errors.append("tile_asset_ids: missing %s" % role)
			continue
		var value: Variant = tile_asset_ids[role]
		if typeof(value) != TYPE_STRING_NAME or value == &"":
			errors.append("tile_asset_ids.%s: expected nonempty StringName" % role)
	for raw_key: Variant in tile_asset_ids:
		if typeof(raw_key) != TYPE_STRING_NAME or not TILE_ROLES.has(raw_key):
			errors.append("tile_asset_ids: unexpected key %s" % raw_key)


func _validate_id_map(values: Dictionary, label: String, errors: PackedStringArray) -> void:
	for raw_key: Variant in values:
		var value: Variant = values[raw_key]
		if typeof(raw_key) != TYPE_STRING_NAME or raw_key == &"":
			errors.append("%s: expected nonempty StringName key" % label)
		if typeof(value) != TYPE_STRING_NAME or value == &"":
			errors.append("%s.%s: expected nonempty StringName" % [label, raw_key])


func _validate_id_array(
	values: Array[StringName], label: String, errors: PackedStringArray
) -> void:
	var seen: Dictionary = {}
	for value: StringName in values:
		if value == &"":
			errors.append("%s: empty id" % label)
		elif seen.has(value):
			errors.append("%s: duplicate %s" % [label, value])
		seen[value] = true
