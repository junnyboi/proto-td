class_name EnemyDamageFeedback
extends RefCounted

## View-only damage feedback. Animation clocks and flashes age on render frames;
## authoritative movement pause remains EnemyState.damage_stagger_until_tick.

const EnemyAnimatorType := preload("res://scripts/view/enemy_animator.gd")

var _anim_paused_seconds: Dictionary = {}
var _seen_ticks: Dictionary = {}
var _flash_frames: Dictionary = {}


func register(enemy: EnemyState) -> void:
	_seen_ticks[enemy.id] = -1


func remove(enemy_id: int) -> void:
	_anim_paused_seconds.erase(enemy_id)
	_seen_ticks.erase(enemy_id)
	_flash_frames.erase(enemy_id)


func process(delta: float, model: BattleModel, rects: Dictionary, cfg: JuiceConfig) -> void:
	for enemy: EnemyState in model.enemies:
		if enemy.alive and is_staggered(model, enemy):
			_anim_paused_seconds[enemy.id] = (
				float(_anim_paused_seconds.get(enemy.id, 0.0)) + delta
			)
		if not rects.has(enemy.id):
			continue
		var seen := int(_seen_ticks.get(enemy.id, -1))
		if enemy.last_damage_tick <= seen:
			continue
		_seen_ticks[enemy.id] = enemy.last_damage_tick
		_flash_frames[enemy.id] = cfg.damage_flash_frames
		(
			EnemyAnimatorType
			. apply_damage_flash(
				rects[enemy.id],
				cfg.damage_flash_frames,
				cfg.damage_flash_frames,
				cfg.damage_flash_white,
				cfg.damage_flash_red,
			)
		)


func age(rects: Dictionary, cfg: JuiceConfig) -> void:
	for enemy_id: int in _flash_frames.keys():
		if not rects.has(enemy_id):
			_flash_frames.erase(enemy_id)
			continue
		var left := int(_flash_frames[enemy_id])
		(
			EnemyAnimatorType
			. apply_damage_flash(
				rects[enemy_id],
				left,
				cfg.damage_flash_frames,
				cfg.damage_flash_white,
				cfg.damage_flash_red,
			)
		)
		if left > 0:
			_flash_frames[enemy_id] = left - 1
		else:
			_flash_frames.erase(enemy_id)


func animation_seconds(global_seconds: float, enemy_id: int) -> float:
	return global_seconds - float(_anim_paused_seconds.get(enemy_id, 0.0))


func retain_dead(enemy: EnemyState) -> bool:
	return (
		enemy.last_damage_tick > int(_seen_ticks.get(enemy.id, -1)) or _flash_frames.has(enemy.id)
	)


func is_staggered(model: BattleModel, enemy: EnemyState) -> bool:
	return model.tick < enemy.damage_stagger_until_tick
