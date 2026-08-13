class_name OperatorVisualCatalog
extends RefCounted

## Exact admitted-template catalog. Unknown or unapproved templates return null
## and BattleView preserves the incumbent legacy body projection.

const OperatorAnimationDefType := preload("res://data/presentation/operator_animation_def.gd")
const DEFINITIONS: Dictionary = {
	&"caster_1": preload("res://data/presentation/operator_visuals/caster_1.tres"),
	&"caster_2": preload("res://data/presentation/operator_visuals/caster_2.tres"),
	&"defender_1": preload("res://data/presentation/operator_visuals/defender_1.tres"),
	&"defender_2": preload("res://data/presentation/operator_visuals/defender_2.tres"),
	&"sniper_1": preload("res://data/presentation/operator_visuals/sniper_1.tres"),
	&"sniper_2": preload("res://data/presentation/operator_visuals/sniper_2.tres"),
	&"vanguard_2": preload("res://data/presentation/operator_visuals/vanguard_2.tres"),
}


static func get_animation(template_id: StringName) -> OperatorAnimationDefType:
	var value: Variant = DEFINITIONS.get(template_id)
	return value as OperatorAnimationDefType if value is OperatorAnimationDefType else null


static func template_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for raw_id: Variant in DEFINITIONS:
		if typeof(raw_id) == TYPE_STRING_NAME:
			result.append(raw_id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func validate_all() -> PackedStringArray:
	return validate_definitions(DEFINITIONS, true)


static func validate_definitions(
	definitions: Dictionary, check_manifest: bool
) -> PackedStringArray:
	var errors := PackedStringArray()
	var visual_ids: Dictionary = {}
	for raw_template_id: Variant in definitions:
		if typeof(raw_template_id) != TYPE_STRING_NAME or StringName(raw_template_id).is_empty():
			errors.append("catalog: expected nonempty StringName template id")
			continue
		var template_id := StringName(raw_template_id)
		var animation := definitions[template_id] as OperatorAnimationDefType
		if animation == null:
			errors.append("%s: expected OperatorAnimationDef" % template_id)
			continue
		for message: String in animation.validate_contract():
			errors.append("%s: %s" % [template_id, message])
		if visual_ids.has(animation.visual_id):
			errors.append("%s: duplicate visual_id %s" % [template_id, animation.visual_id])
		visual_ids[animation.visual_id] = true
		if check_manifest:
			_validate_manifest(template_id, animation, errors)
	return errors


static func _validate_manifest(
	template_id: StringName, animation: OperatorAnimationDefType, errors: PackedStringArray
) -> void:
	for family: StringName in [&"idle", &"attack"]:
		var mapping := animation.idle_by_direction if family == &"idle" else animation.attack_by_direction
		var expected_frames := (
			animation.idle_frame_count if family == &"idle" else animation.attack_frame_count
		)
		for direction: StringName in OperatorAnimationDefType.DIRECTIONS:
			if not mapping.has(direction):
				continue
			var logical_id := StringName(mapping[direction])
			if Art.frame_count(logical_id) != expected_frames:
				errors.append(
					"%s/%s/%s: manifest frame count mismatch" % [template_id, family, direction]
				)
			if Art.size(logical_id) != Vector2i(192, 192):
				errors.append("%s/%s/%s: manifest cell mismatch" % [template_id, family, direction])
			if not is_equal_approx(Art.fps(logical_id), animation.fps):
				errors.append("%s/%s/%s: manifest fps mismatch" % [template_id, family, direction])
			var metadata := Art.metadata(logical_id)
			if metadata.is_empty():
				errors.append("%s/%s/%s: missing manifest row" % [template_id, family, direction])
			else:
				var expected_placeholder := animation.is_placeholder(logical_id)
				if bool(metadata.get(&"placeholder", true)) != expected_placeholder:
					errors.append("%s/%s/%s: placeholder mismatch" % [template_id, family, direction])
			if Art.provenance_sha256(logical_id).length() != 64:
				errors.append(
					"%s/%s/%s: invalid manifest provenance" % [template_id, family, direction]
				)
