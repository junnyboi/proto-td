extends SceneTree

const ENEMIES: Array[StringName] = [&"shieldbearer", &"breacher", &"interceptor"]
const ACTIONS: Array[StringName] = [&"walk", &"attack"]
const DIRECTIONS: Array[StringName] = [&"ne", &"nw", &"se", &"sw"]

var _failures := PackedStringArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Art._reset_manifests_for_test()
	var seen_patterns: Dictionary = {}
	for enemy_id: StringName in ENEMIES:
		_check(EnemyAnimator.VARIANT_ENEMIES.has(enemy_id), "%s must use production variant routing" % enemy_id)
		for action: StringName in ACTIONS:
			for direction: StringName in DIRECTIONS:
				_validate_sequence(enemy_id, action, direction, seen_patterns)
	_validate_mirror_contracts()
	_validate_portable_provenance()
	_validate_timed_attack_frames()
	_validate_projection_policy()
	if _failures.is_empty():
		print("EARLY_ENEMY_VARIANT_ART_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _validate_sequence(
	enemy_id: StringName,
	action: StringName,
	direction: StringName,
	seen_patterns: Dictionary,
) -> void:
	var asset_id := EnemyAnimator.variant_animation_id(enemy_id, action, direction)
	var expected_id := StringName("enemy_variant_%s_%s_%s" % [enemy_id, action, direction])
	_check(asset_id == expected_id, "%s route must resolve to %s" % [asset_id, expected_id])
	var metadata := Art.metadata(asset_id)
	_check(not metadata.is_empty(), "%s metadata must load" % asset_id)
	if metadata.is_empty():
		return
	_check(int(metadata.get("frames", 0)) == 8, "%s must expose eight frames" % asset_id)
	_check(int(metadata.get("columns", 0)) == 4, "%s must use a WebGL-safe four-column sheet" % asset_id)
	_check(not bool(metadata.get("placeholder", true)), "%s must be a production asset" % asset_id)
	var size := Art.size(asset_id)
	_check(maxi(size.x, size.y) >= 560 and maxi(size.x, size.y) <= 640, "%s longest edge must remain 560-640px" % asset_id)
	_check(mini(size.x, size.y) >= 256, "%s cell must preserve readable subject detail" % asset_id)
	var pattern := String(metadata.get("pattern", ""))
	_check(pattern.ends_with(".webp"), "%s must use lossless WebP" % asset_id)
	_check(not seen_patterns.has(pattern), "%s must not reuse another sequence sheet" % asset_id)
	seen_patterns[pattern] = true
	for frame_index: int in [0, 3, 7]:
		var texture := Art.texture(asset_id, frame_index) as AtlasTexture
		_check(texture != null, "%s frame %d must load as an atlas texture" % [asset_id, frame_index])
		if texture != null:
			_check(texture.region.size == Vector2(size), "%s frame %d region must match manifest size" % [asset_id, frame_index])
			_check(maxi(texture.atlas.get_width(), texture.atlas.get_height()) <= 4096, "%s atlas exceeds the 4096px WebGL ceiling" % asset_id)
	var animation_names := Art.animation_names(asset_id)
	_check(animation_names == [&"default"], "%s must expose one default sequence" % asset_id)
	_check(is_equal_approx(Art.fps(asset_id), 8.0), "%s must play at 8 FPS" % asset_id)


func _validate_mirror_contracts() -> void:
	for enemy_id: StringName in [&"breacher", &"interceptor"]:
		for action: StringName in ACTIONS:
			var nw := _runtime_metadata(enemy_id, action, &"nw")
			var sw := _runtime_metadata(enemy_id, action, &"sw")
			_check(String(nw.get("mirrored_from", "")) == "NE", "%s %s NW must derive from NE" % [enemy_id, action])
			_check(String(sw.get("mirrored_from", "")) == "SE", "%s %s SW must derive from SE" % [enemy_id, action])
	for action: StringName in ACTIONS:
		for direction: StringName in DIRECTIONS:
			var shield := _runtime_metadata(&"shieldbearer", action, direction)
			_check(shield.get("mirrored_from") == null, "Shieldbearer %s %s must be authored, not mirrored" % [action, direction])


func _validate_portable_provenance() -> void:
	for enemy_id: StringName in ENEMIES:
		for action: StringName in ACTIONS:
			for direction: StringName in DIRECTIONS:
				var metadata := _runtime_metadata(enemy_id, action, direction)
				var source_video := String(metadata.get("source_video", ""))
				_check(not source_video.begins_with("/"), "%s %s %s source path must be repository-relative" % [enemy_id, action, direction])
				_check(FileAccess.file_exists("res://%s" % source_video), "%s %s %s source carrier must exist" % [enemy_id, action, direction])


func _validate_timed_attack_frames() -> void:
	_check(EnemyAnimator.timed_attack_frame(35, 36, 8, 8.0) == 0, "variant attack must start on frame zero")
	_check(EnemyAnimator.timed_attack_frame(31, 36, 8, 8.0) == 1, "variant attack must advance at eight FPS")
	_check(EnemyAnimator.timed_attack_frame(8, 36, 8, 8.0) == 7, "variant attack must reach its final authored frame")
	_check(EnemyAnimator.timed_attack_frame(0, 36, 8, 8.0) == 7, "variant attack must hold its final non-looping frame")


func _validate_projection_policy() -> void:
	var stage := load("res://data/stages/s4.tres") as StageDef
	var config := load("res://data/config/game.tres") as GameConfig
	var enemy_defs := _load_catalog("res://data/enemies")
	var operator_defs := _load_catalog("res://data/operators")
	var model := BattleModel.create(stage, [], 4104, config, enemy_defs, operator_defs)
	_check(model != null, "variant projection fixture must create")
	if model == null:
		return
	for enemy_id: StringName in ENEMIES:
		model._spawn({"enemy_id": enemy_id, "path_idx": 0})
		var enemy := model.enemies[-1] as EnemyState
		var body := EnemyAnimator.make_body(enemy, model, enemy_defs)
		var expected_size := (
			EnemyAnimator.VARIANT_AERIAL_PX
			if enemy.aerial
			else EnemyAnimator.VARIANT_BODY_PX
		)
		_check(body.size == Vector2.ONE * expected_size, "%s must use its fixed battle footprint" % enemy_id)
		var sprite := body.get_node_or_null("Sprite") as TextureRect
		var blend := body.get_node_or_null("BlendSprite") as TextureRect
		_check(sprite != null and sprite.texture != null, "%s body must load a production texture" % enemy_id)
		_check(sprite != null and sprite.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s must preserve source aspect ratio" % enemy_id)
		_check(blend != null and blend.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s blend frame must preserve source aspect ratio" % enemy_id)
		enemy.faction = EnemyState.Faction.CHARMED
		var charmed_id := EnemyAnimator.animation_id_for(enemy, model)
		_check(EnemyAnimator.is_variant_id(charmed_id), "%s must retain its production identity while charmed" % enemy_id)
		EnemyAnimator.refresh(enemy, model, body, 0.25, {}, {}, enemy_defs)
		_check(sprite != null and sprite.modulate.r < sprite.modulate.b, "%s charmed presentation must be visibly blue-tinted" % enemy_id)
		body.free()
	Art._reset_manifests_for_test()
	EnemyAnimator._damage_flash_shader = null


func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	for filename: String in DirAccess.get_files_at(path):
		if not filename.ends_with(".tres"):
			continue
		var resource := load("%s/%s" % [path, filename])
		if resource != null and "id" in resource:
			result[resource.id] = resource
	return result


func _runtime_metadata(
	enemy_id: StringName, action: StringName, direction: StringName
) -> Dictionary:
	var path := "res://assets/enemy-variants/%s_%s_%s.json" % [enemy_id, action, direction]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("runtime metadata missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		_failures.append("runtime metadata invalid: %s" % path)
		return {}
	return parsed


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
