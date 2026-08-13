class_name OperatorAnimator
extends RefCounted

## View-only projection for admitted directional operator art. It reads UnitState
## and model tick but never mutates either object.

const OperatorAnimationDefType := preload("res://data/presentation/operator_animation_def.gd")
const NORMALIZED_SUBJECT_HEIGHT := 168.0
const SOURCE_CELL_PX := 192.0
const ATTACK_WINDOW_TICKS := 30
const ATTACK_FRAMES := 13
const IDLE_FRAMES := 24


static func direction_for_facing(facing: int) -> StringName:
	match facing:
		UnitState.Facing.RIGHT:
			return &"se"
		UnitState.Facing.DOWN:
			return &"sw"
		UnitState.Facing.LEFT:
			return &"nw"
		UnitState.Facing.UP:
			return &"ne"
		_:
			return &"se"


static func attack_age(model_tick: int, last_attack_tick: int) -> int:
	return model_tick - last_attack_tick if last_attack_tick >= 0 else ATTACK_WINDOW_TICKS


static func attack_active(age_ticks: int) -> bool:
	return age_ticks >= 1 and age_ticks < ATTACK_WINDOW_TICKS


static func attack_frame(age_ticks: int) -> int:
	if age_ticks <= 0:
		return 0
	return clampi(((age_ticks - 1) * ATTACK_FRAMES) / 29, 0, ATTACK_FRAMES - 1)


static func idle_frame(idle_seconds: float) -> int:
	return floori(maxf(idle_seconds, 0.0) * 12.0) % IDLE_FRAMES


static func selection(
	u: UnitState, model_tick: int, idle_seconds: float, animation: OperatorAnimationDefType
) -> Dictionary:
	var direction := direction_for_facing(u.facing)
	var age := attack_age(model_tick, u.last_attack_tick)
	if attack_active(age):
		return {
			&"state": &"attack",
			&"direction": direction,
			&"frame": attack_frame(age),
			&"logical_id": StringName(animation.attack_by_direction.get(direction, &"")),
		}
	return {
		&"state": &"idle",
		&"direction": direction,
		&"frame": idle_frame(idle_seconds),
		&"logical_id": StringName(animation.idle_by_direction.get(direction, &"")),
	}


static func body_size(animation: OperatorAnimationDefType) -> Vector2:
	var scale := float(animation.display_height_px) / NORMALIZED_SUBJECT_HEIGHT
	return Vector2.ONE * SOURCE_CELL_PX * scale


static func apply(
	u: UnitState,
	model_tick: int,
	idle_seconds: float,
	sprite: TextureRect,
	animation: OperatorAnimationDefType,
) -> bool:
	if sprite == null or animation == null or not animation.validate_contract().is_empty():
		return false
	var selected := selection(u, model_tick, idle_seconds, animation)
	var logical_id := StringName(selected[&"logical_id"])
	var frame := int(selected[&"frame"])
	var texture := Art.texture(logical_id, frame)
	if texture == null:
		return false
	if sprite.texture != texture:
		sprite.texture = texture
	sprite.flip_h = false
	sprite.set_meta(&"operator_animation_state", selected[&"state"])
	sprite.set_meta(&"operator_animation_direction", selected[&"direction"])
	sprite.set_meta(&"operator_animation_frame", frame)
	sprite.set_meta(&"operator_animation_id", logical_id)
	return true
