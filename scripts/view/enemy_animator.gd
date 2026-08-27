class_name EnemyAnimator
extends RefCounted

## Presentation policy and view adapter for the generated grunt animation
## family. It reads authoritative path/counter facts but never mutates the
## battle model.

const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

const FRAME_COUNT := 25
const LOOP_FRAME_COUNT := FRAME_COUNT - 1
const WALK_FPS := 12.0
const BLEND_FRAMES := 6
const BODY_PX := 64.0
const EXPERIMENTAL_BODY_PX := 48.0
const EXPERIMENTAL_PREFIX := "experimental_salvage_"
const VARIANT_BODY_PX := 64.0
const VARIANT_AERIAL_PX := 56.0
const VARIANT_PREFIX := "enemy_variant_"
const LEGACY_ENEMY_PX := 40.0
const LEGACY_AERIAL_PX := 24.0
const LEGACY_SPRITE_SCALE := 2
const LEGACY_BOB_FRAMES := 24
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const SHADOW_FACE_SCALE := 0.3125
const AERIAL_SHADOW_DROP := 10.0
const FALLBACK_COLOR := Color("ef7d57")
const CHARMED_COLOR := Color("41a6f6")
const CHARMED_VARIANT_TINT := Color("7fd7ff")
const DAMAGE_FLASH_SHADER_SOURCE := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	vec3 flashed = mix(pixel.rgb, flash_color.rgb, flash_strength);
	COLOR = vec4(flashed, COLOR.a);
}
"""
const TYPE_COLORS := {
	&"grunt": Color("ef7d57"),
	&"runner": Color("f4d35e"),
	&"shieldbearer": Color("c98f65"),
	&"breacher": Color("c66b5d"),
	&"heavy": Color("b13e53"),
	&"drone": Color("73eff7"),
	&"interceptor": Color("69b9d0"),
	&"spellcaster": Color("c964cf"),
	&"mini_boss": Color("94216a"),
}
const BASIC_ENEMIES: Array[StringName] = [
	&"grunt",
	&"runner",
	&"shieldbearer",
	&"breacher",
	&"heavy",
	&"drone",
	&"interceptor",
	&"spellcaster",
]
const DIRECTIONAL_ENEMIES: Array[StringName] = [
	&"grunt",
	&"runner",
	&"shieldbearer",
	&"breacher",
	&"heavy",
	&"drone",
	&"interceptor",
	&"spellcaster",
	&"mini_boss",
]
const VARIANT_ENEMIES: Array[StringName] = [
	&"shieldbearer",
	&"breacher",
	&"interceptor",
]

static var _damage_flash_shader: Shader = null


static func uses_grunt(def_id: StringName) -> bool:
	return BASIC_ENEMIES.has(def_id)


static func uses_directional_animation(def_id: StringName) -> bool:
	return DIRECTIONAL_ENEMIES.has(def_id)


static func uses_experimental_state(def_id: StringName, state: StringName) -> bool:
	return uses_directional_animation(def_id) and (def_id != &"grunt" or state == &"attack")


static func direction_from_tangent(tangent: Vector2i, reverse := false) -> StringName:
	if reverse:
		tangent = -tangent
	if tangent == Vector2i.ZERO:
		return &"se"
	var screen := IsoProjection.project(Vector2(tangent))
	if screen.y < 0.0:
		return &"ne" if screen.x >= 0.0 else &"nw"
	return &"se" if screen.x >= 0.0 else &"sw"


static func direction_for_path(
	path: Array[Vector2i], progress_units: int, reverse := false
) -> StringName:
	if path.size() < 2:
		return &"se"
	var clamped_progress := clampi(progress_units, 0, Pathing.length_units(path) - 1)
	@warning_ignore("integer_division")
	var segment := clamped_progress / Pathing.PROGRESS_SCALE
	if reverse and clamped_progress > 0 and clamped_progress % Pathing.PROGRESS_SCALE == 0:
		segment -= 1
	segment = mini(segment, path.size() - 2)
	return direction_from_tangent(path[segment + 1] - path[segment], reverse)


static func walk_frame(
	animation_seconds: float,
	fps := WALK_FPS,
	frame_count := FRAME_COUNT,
	phase_offset := 0,
) -> int:
	var cycle_frames := maxi(1, frame_count - 1)
	var elapsed_frames := floori(maxf(animation_seconds, 0.0) * fps) + phase_offset
	return posmod(elapsed_frames, cycle_frames)


static func attack_frame(
	atk_counter: int, atk_interval_ticks: int, frame_count := FRAME_COUNT
) -> int:
	if atk_interval_ticks <= 1 or frame_count <= 1:
		return 0
	var last_counter := atk_interval_ticks - 1
	var elapsed := last_counter - clampi(atk_counter, 0, last_counter)
	return roundi(float(elapsed) * float(frame_count - 1) / float(last_counter))


static func timed_attack_frame(
	atk_counter: int,
	atk_interval_ticks: int,
	frame_count: int,
	fps: float,
	ticks_per_second := 30.0,
) -> int:
	if atk_interval_ticks <= 1 or frame_count <= 1 or fps <= 0.0 or ticks_per_second <= 0.0:
		return 0
	var last_counter := atk_interval_ticks - 1
	var elapsed_ticks := last_counter - clampi(atk_counter, 0, last_counter)
	return clampi(floori(float(elapsed_ticks) * fps / ticks_per_second), 0, frame_count - 1)


static func animation_id(state: StringName, direction: StringName, charmed := false) -> StringName:
	var suffix := "_charmed" if charmed else ""
	return StringName("grunt_anim_%s_%s%s" % [state, direction, suffix])


static func experimental_animation_id(
	def_id: StringName, state: StringName, direction: StringName
) -> StringName:
	return StringName("%s%s_%s_%s" % [EXPERIMENTAL_PREFIX, def_id, state, direction])


static func variant_animation_id(
	def_id: StringName, state: StringName, direction: StringName
) -> StringName:
	return StringName("%s%s_%s_%s" % [VARIANT_PREFIX, def_id, state, direction])


static func is_experimental_id(animation: StringName) -> bool:
	return String(animation).begins_with(EXPERIMENTAL_PREFIX)


static func is_variant_id(animation: StringName) -> bool:
	return String(animation).begins_with(VARIANT_PREFIX)


static func faction_palette_changed(old_id: StringName, new_id: StringName) -> bool:
	return String(old_id).ends_with("_charmed") != String(new_id).ends_with("_charmed")


## Returns (old_alpha, new_alpha) for the current frames-left value.
static func blend_alpha(frames_left: int, total_frames := BLEND_FRAMES) -> Vector2:
	if total_frames <= 0:
		return Vector2(0.0, 1.0)
	var left := clampi(frames_left, 0, total_frames)
	var old_alpha := float(left) / float(total_frames)
	return Vector2(old_alpha, 1.0 - old_alpha)


static func damage_flash_color(
	frames_left: int, total_frames: int, white: Color, red: Color
) -> Color:
	if frames_left <= 0 or total_frames <= 0:
		return Color.WHITE
	return white if frames_left * 2 > total_frames else red


static func apply_damage_flash(
	body: ColorRect, frames_left: int, total_frames: int, white: Color, red: Color
) -> void:
	var color := damage_flash_color(frames_left, total_frames, white, red)
	for layer_name: String in ["Sprite", "BlendSprite"]:
		var layer := body.get_node_or_null(layer_name) as TextureRect
		if layer != null:
			var shader_material := layer.material as ShaderMaterial
			if shader_material != null:
				shader_material.set_shader_parameter("flash_color", color)
				shader_material.set_shader_parameter(
					"flash_strength", 1.0 if frames_left > 0 else 0.0
				)


static func _shared_damage_flash_shader() -> Shader:
	if _damage_flash_shader == null:
		_damage_flash_shader = Shader.new()
		_damage_flash_shader.code = DAMAGE_FLASH_SHADER_SOURCE
	return _damage_flash_shader


static func animation_id_for(enemy: EnemyState, battle: BattleModel) -> StringName:
	var charmed := enemy.faction == EnemyState.Faction.CHARMED
	var direction := direction_for_path(
		battle.path_for(enemy.path_idx), enemy.progress_units, charmed
	)
	var state := &"attack" if is_attacking(enemy) else &"walk"
	if VARIANT_ENEMIES.has(enemy.def_id):
		return variant_animation_id(enemy.def_id, state, direction)
	if not charmed:
		if uses_experimental_state(enemy.def_id, state):
			return experimental_animation_id(enemy.def_id, state, direction)
	return animation_id(state, direction, charmed)


static func legacy_sprite_id(enemy: EnemyState, definitions: Dictionary) -> StringName:
	var definition: EnemyDef = definitions.get(enemy.def_id)
	var sprite_id := definition.sprite_id if definition != null else enemy.def_id
	if enemy.faction == EnemyState.Faction.CHARMED:
		return StringName("%s_charmed" % sprite_id)
	return sprite_id


static func make_body(enemy: EnemyState, battle: BattleModel, definitions: Dictionary) -> ColorRect:
	var body := ColorRect.new()
	body.name = "Enemy%d" % enemy.id
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.accessibility_name = UiCopyType.enemy_name(enemy.def_id)
	var directional := uses_directional_animation(enemy.def_id)
	var sprite_id := (
		animation_id_for(enemy, battle) if directional else legacy_sprite_id(enemy, definitions)
	)
	var texture := Art.texture(sprite_id, 0)
	var body_px := LEGACY_AERIAL_PX if enemy.aerial else LEGACY_ENEMY_PX
	if texture != null:
		body.color = Color(0.0, 0.0, 0.0, 0.0)
		var uses_variant := VARIANT_ENEMIES.has(enemy.def_id)
		if uses_variant:
			body_px = VARIANT_AERIAL_PX if enemy.aerial else VARIANT_BODY_PX
		elif directional:
			body_px = EXPERIMENTAL_BODY_PX
		else:
			body_px = float(texture.get_width() * LEGACY_SPRITE_SCALE)
		body.size = Vector2.ONE * body_px
		var sprite := _texture_rect("Sprite", texture, body.size)
		if uses_variant:
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.add_child(sprite)
		if directional:
			var blend := _texture_rect("BlendSprite", null, body.size)
			if uses_variant:
				blend.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			blend.visible = false
			body.add_child(blend)
	else:
		body.color = TYPE_COLORS.get(enemy.def_id, FALLBACK_COLOR)
		body.size = Vector2.ONE * body_px
	add_shadow(body, enemy.aerial)
	return body


static func _texture_rect(
	sprite_name: String, sprite_texture: Texture2D, sprite_size: Vector2
) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = sprite_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = sprite_texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.size = sprite_size
	var shader_material := ShaderMaterial.new()
	shader_material.shader = _shared_damage_flash_shader()
	sprite.material = shader_material
	return sprite


static func add_shadow(body: ColorRect, aerial: bool) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = SHADOW_COLOR
	shadow.polygon = IsoProjection.face_polygon(SHADOW_FACE_SCALE)
	shadow.position = Vector2(
		body.size.x * 0.5, body.size.y + (AERIAL_SHADOW_DROP if aerial else 0.0)
	)
	shadow.show_behind_parent = true
	body.add_child(shadow)


static func is_attacking(enemy: EnemyState) -> bool:
	if enemy.atk_counter <= 0:
		return false
	return enemy.engaged_with >= 0 or enemy.blocked_by >= 0 or enemy.atk_range_cells > 0


static func frame_for(enemy: EnemyState, sprite_id: StringName, seconds: float) -> int:
	var frame_count := Art.frame_count(sprite_id)
	if String(sprite_id).contains("_attack_"):
		if is_variant_id(sprite_id):
			return timed_attack_frame(
				enemy.atk_counter,
				enemy.atk_interval_ticks,
				frame_count,
				Art.fps(sprite_id),
			)
		return attack_frame(enemy.atk_counter, enemy.atk_interval_ticks, frame_count)
	var animation_fps := Art.fps(sprite_id)
	if animation_fps <= 0.0:
		animation_fps = WALK_FPS
	if is_experimental_id(sprite_id) or is_variant_id(sprite_id):
		return posmod(floori(maxf(seconds, 0.0) * animation_fps) + enemy.id, maxi(1, frame_count))
	return walk_frame(seconds, animation_fps, frame_count, enemy.id)


static func refresh(
	enemy: EnemyState,
	battle: BattleModel,
	body: ColorRect,
	seconds: float,
	keys: Dictionary,
	blend_frames: Dictionary,
	definitions: Dictionary,
) -> void:
	var sprite := body.get_node_or_null("Sprite") as TextureRect
	if sprite == null:
		if enemy.faction == EnemyState.Faction.CHARMED:
			body.color = CHARMED_COLOR
		return
	if not uses_directional_animation(enemy.def_id):
		var legacy_id := legacy_sprite_id(enemy, definitions)
		var legacy_frame := 0
		if Art.frame_count(legacy_id) > 1:
			@warning_ignore("integer_division")
			legacy_frame = (Engine.get_process_frames() / LEGACY_BOB_FRAMES + enemy.id) % 2
		var legacy_texture := Art.texture(legacy_id, legacy_frame)
		if legacy_texture != null and sprite.texture != legacy_texture:
			sprite.texture = legacy_texture
		return
	var sprite_id := animation_id_for(enemy, battle)
	var texture := Art.texture(sprite_id, frame_for(enemy, sprite_id, seconds))
	if texture == null:
		return
	var faction_tint := (
		CHARMED_VARIANT_TINT
		if enemy.faction == EnemyState.Faction.CHARMED and VARIANT_ENEMIES.has(enemy.def_id)
		else Color.WHITE
	)
	sprite.modulate = faction_tint
	var blend := body.get_node_or_null("BlendSprite") as TextureRect
	if blend != null:
		blend.modulate = faction_tint
	var old_key: StringName = keys.get(enemy.id, &"")
	if old_key != sprite_id:
		var immediate := old_key != &"" and faction_palette_changed(old_key, sprite_id)
		if old_key != &"" and not immediate and blend != null and sprite.texture != null:
			blend.texture = sprite.texture
			blend.visible = true
			blend_frames[enemy.id] = BLEND_FRAMES
			apply_blend(body, BLEND_FRAMES)
		elif immediate:
			blend_frames.erase(enemy.id)
			apply_blend(body, 0)
		keys[enemy.id] = sprite_id
	if sprite.texture != texture:
		sprite.texture = texture


static func apply_blend(body: ColorRect, frames_left: int) -> void:
	var sprite := body.get_node_or_null("Sprite") as TextureRect
	var blend := body.get_node_or_null("BlendSprite") as TextureRect
	if sprite == null or blend == null:
		return
	var alpha := blend_alpha(frames_left)
	blend.modulate = Color(blend.modulate.r, blend.modulate.g, blend.modulate.b, alpha.x)
	sprite.modulate = Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, alpha.y)
	if frames_left <= 0:
		blend.visible = false
		blend.texture = null
