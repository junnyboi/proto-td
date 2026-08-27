class_name PremiumPortraitEntrance
extends RefCounted

## Presentation-only entrance motion for premium identity portraits.
## The portrait drifts independently inside its static UI frame, creating a
## restrained parallax cue without changing layout, campaign state, or crop scale.

const DURATION_SECONDS := 0.42
const STAGGER_SECONDS := 0.055
const MAX_STAGGER_INDEX := 5
const VERTICAL_OFFSET := 14.0
const HORIZONTAL_OFFSET := 8.0
const PREMIUM_ASSET_IDS: Array[StringName] = [
	&"portrait_archive_caster",
	&"portrait_lunaris_vessel",
	&"portrait_reliquary_duelist",
	&"portrait_archive_caster_fullsize",
	&"portrait_lunaris_vessel_fullsize",
	&"portrait_reliquary_duelist_fullsize",
]
const MOTION_META_KEYS: Array[StringName] = [
	&"premium_portrait_entrance",
	&"premium_portrait_entrance_index",
	&"premium_portrait_entrance_delay",
	&"premium_portrait_entrance_duration",
	&"premium_portrait_entrance_start",
	&"premium_portrait_entrance_reduced",
	&"premium_portrait_entrance_active",
	&"premium_portrait_entrance_tween",
	&"premium_portrait_entrance_pending",
	&"premium_portrait_entrance_pending_callable",
	&"premium_portrait_entrance_generation",
]


static func is_premium_asset(asset_id: StringName) -> bool:
	return asset_id in PREMIUM_ASSET_IDS


static func apply(
		portrait: TextureRect,
		asset_id: StringName,
		order_index: int = 0,
		reduced_motion: bool = false,
	) -> Tween:
	if portrait == null or not is_instance_valid(portrait):
		return null

	var owned_state := _has_owned_state(portrait)
	var generation := _next_generation(portrait)
	_cancel_pending(portrait)
	_kill_active(portrait)
	if not is_premium_asset(asset_id):
		if owned_state:
			_reset_visual_state(portrait)
		_clear_motion_metadata(portrait)
		return null

	if not portrait.is_inside_tree():
		portrait.set_meta(&"premium_portrait_entrance_pending", {
			"asset_id": asset_id,
			"order_index": order_index,
			"reduced_motion": reduced_motion,
			"generation": generation,
		})
		var callback := _apply_pending.bind(weakref(portrait), generation)
		portrait.set_meta(&"premium_portrait_entrance_pending_callable", callback)
		portrait.tree_entered.connect(callback, CONNECT_ONE_SHOT)
		return null

	return _start(portrait, asset_id, order_index, reduced_motion, generation)


static func settle(portrait: TextureRect) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	_next_generation(portrait)
	_cancel_pending(portrait)
	_kill_active(portrait)
	_reset_visual_state(portrait)
	_clear_motion_metadata(portrait)


static func _start(
		portrait: TextureRect,
		asset_id: StringName,
		order_index: int,
		reduced_motion: bool,
		generation: int,
	) -> Tween:
	if not is_premium_asset(asset_id) or generation != _generation(portrait):
		return null
	var delay := float(clampi(order_index, 0, MAX_STAGGER_INDEX)) * STAGGER_SECONDS
	var direction := -1.0 if order_index % 2 == 0 else 1.0
	var start_offset := Vector2(direction * HORIZONTAL_OFFSET, VERTICAL_OFFSET)
	portrait.set_meta(&"premium_portrait_entrance", true)
	portrait.set_meta(&"premium_portrait_entrance_index", order_index)
	portrait.set_meta(&"premium_portrait_entrance_delay", delay)
	portrait.set_meta(&"premium_portrait_entrance_duration", DURATION_SECONDS)
	portrait.set_meta(&"premium_portrait_entrance_start", start_offset)
	portrait.set_meta(&"premium_portrait_entrance_reduced", reduced_motion)
	portrait.set_meta(&"premium_portrait_entrance_active", false)

	if reduced_motion:
		_reset_visual_state(portrait)
		return null

	portrait.offset_transform_position = start_offset
	portrait.modulate.a = 0.0
	portrait.set_meta(&"premium_portrait_entrance_active", true)
	var tween := portrait.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		portrait, "offset_transform_position", Vector2.ZERO, DURATION_SECONDS,
	).set_delay(delay)
	tween.tween_property(portrait, "modulate:a", 1.0, DURATION_SECONDS * 0.72).set_delay(delay)
	portrait.set_meta(&"premium_portrait_entrance_tween", tween)
	tween.finished.connect(_finish.bind(weakref(portrait), generation), CONNECT_ONE_SHOT)
	return tween


static func _apply_pending(portrait_ref: WeakRef, generation: int) -> void:
	var portrait := portrait_ref.get_ref() as TextureRect
	if portrait == null or not is_instance_valid(portrait) or generation != _generation(portrait):
		return
	var pending := {}
	if portrait.has_meta(&"premium_portrait_entrance_pending"):
		pending = portrait.get_meta(&"premium_portrait_entrance_pending") as Dictionary
	_cancel_pending(portrait)
	if pending.is_empty() or int(pending.get("generation", -1)) != generation:
		return
	_start(
		portrait,
		StringName(pending.get("asset_id", &"")),
		int(pending.get("order_index", 0)),
		bool(pending.get("reduced_motion", false)),
		generation,
	)


static func _finish(portrait_ref: WeakRef, generation: int) -> void:
	var portrait := portrait_ref.get_ref() as TextureRect
	if portrait == null or not is_instance_valid(portrait) or generation != _generation(portrait):
		return
	_reset_visual_state(portrait)
	portrait.set_meta(&"premium_portrait_entrance_active", false)
	_remove_meta_if_present(portrait, &"premium_portrait_entrance_tween")


static func _cancel_pending(portrait: TextureRect) -> void:
	if portrait.has_meta(&"premium_portrait_entrance_pending_callable"):
		var callback := portrait.get_meta(&"premium_portrait_entrance_pending_callable") as Callable
		if portrait.tree_entered.is_connected(callback):
			portrait.tree_entered.disconnect(callback)
	_remove_meta_if_present(portrait, &"premium_portrait_entrance_pending_callable")
	_remove_meta_if_present(portrait, &"premium_portrait_entrance_pending")


static func _kill_active(portrait: TextureRect) -> void:
	if not portrait.has_meta(&"premium_portrait_entrance_tween"):
		return
	var active: Variant = portrait.get_meta(&"premium_portrait_entrance_tween")
	if active is Tween and (active as Tween).is_valid():
		(active as Tween).kill()
	portrait.remove_meta(&"premium_portrait_entrance_tween")


static func _next_generation(portrait: TextureRect) -> int:
	var generation := _generation(portrait) + 1
	portrait.set_meta(&"premium_portrait_entrance_generation", generation)
	return generation


static func _generation(portrait: TextureRect) -> int:
	return int(portrait.get_meta(&"premium_portrait_entrance_generation", 0))


static func _has_owned_state(portrait: TextureRect) -> bool:
	for key: StringName in MOTION_META_KEYS:
		if key != &"premium_portrait_entrance_generation" and portrait.has_meta(key):
			return true
	return false


static func _reset_visual_state(portrait: TextureRect) -> void:
	portrait.offset_transform_position = Vector2.ZERO
	portrait.modulate.a = 1.0


static func _clear_motion_metadata(portrait: TextureRect) -> void:
	for key: StringName in MOTION_META_KEYS:
		_remove_meta_if_present(portrait, key)


static func _remove_meta_if_present(portrait: TextureRect, key: StringName) -> void:
	if portrait.has_meta(key):
		portrait.remove_meta(key)
