class_name StagePresentationDef
extends Resource

@export var schema_version: int = 1
@export var stage_id: StringName = &""
@export var environment_theme_id: StringName = &""
@export var backdrop_asset_id: StringName = &""
@export var objective_asset_id: StringName = &""
@export var spawn_asset_id: StringName = &""
@export var landmark_scene_paths: Array[String] = []
@export var prop_mask_id: StringName = &""
@export var prop_layout_id: StringName = &""
@export var ui_material_tier_id: StringName = &""
@export var light_profile_id: StringName = &""


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	for item: Array in [
		["stage_id", stage_id],
		["environment_theme_id", environment_theme_id],
		["ui_material_tier_id", ui_material_tier_id],
	]:
		if item[1] == &"":
			errors.append("%s: required" % item[0])
	for item: Array in [
		["prop_mask_id", prop_mask_id],
		["prop_layout_id", prop_layout_id],
		["light_profile_id", light_profile_id],
	]:
		if item[1] != &"":
			errors.append("%s: reserved_in_schema_v1" % item[0])
	var seen: Dictionary = {}
	for path: String in landmark_scene_paths:
		if path.is_empty() or not path.begins_with("res://"):
			errors.append("landmark_scene_paths: invalid res path %s" % path)
			continue
		if seen.has(path):
			errors.append("landmark_scene_paths: duplicate %s" % path)
			continue
		seen[path] = true
		if not ResourceLoader.exists(path, "PackedScene"):
			errors.append("landmark_scene_paths: missing PackedScene %s" % path)
	return errors
