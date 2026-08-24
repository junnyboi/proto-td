class_name CharacterVisualDef
extends Resource

const ALIASES: Array[StringName] = [&"idle", &"move", &"attack", &"skill", &"deploy"]

@export var schema_version: int = 1
@export var visual_id: StringName = &""
@export var sprite_asset_id: StringName = &""
@export var portrait_asset_id: StringName = &""
@export var banner_asset_id: StringName = &""
@export var pivot: Vector2 = Vector2(0.5, 0.94)
@export var display_height_px: int = 72
@export var contour_px: float = 1.0
@export var animation_aliases: Dictionary = {}


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	for item: Array in [
		["visual_id", visual_id],
		["sprite_asset_id", sprite_asset_id],
		["portrait_asset_id", portrait_asset_id],
	]:
		if item[1] == &"":
			errors.append("%s: required" % item[0])
	if not is_finite(pivot.x) or not is_finite(pivot.y) or pivot.x < 0.0 or pivot.x > 1.0 \
		or pivot.y < 0.0 or pivot.y > 1.0:
		errors.append("pivot: expected finite normalized Vector2")
	if display_height_px <= 0:
		errors.append("display_height_px: expected positive")
	if not is_finite(contour_px) or contour_px < 0.0:
		errors.append("contour_px: expected finite nonnegative")
	if not animation_aliases.has(&"idle"):
		errors.append("animation_aliases: idle required")
	for raw_key: Variant in animation_aliases:
		var value: Variant = animation_aliases[raw_key]
		if typeof(raw_key) != TYPE_STRING_NAME or not ALIASES.has(raw_key):
			errors.append("animation_aliases: unexpected key %s" % raw_key)
		if typeof(value) != TYPE_STRING_NAME or value == &"":
			errors.append("animation_aliases.%s: expected nonempty StringName" % raw_key)
	return errors
