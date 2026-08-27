extends SceneTree

const EntranceType := preload("res://scripts/ui/components/premium_portrait_entrance.gd")
const TIMEOUT_SECONDS := 5.0

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	root.add_child(stage)

	var live := TextureRect.new()
	stage.add_child(live)
	var live_tween := EntranceType.apply(live, &"portrait_archive_caster", 2, false)
	_check(live_tween != null, "premium portrait did not create an entrance tween")
	_check(bool(live.get_meta(&"premium_portrait_entrance", false)), "premium portrait lacks motion metadata")
	_check(int(live.get_meta(&"premium_portrait_entrance_index", -1)) == 2, "stagger order was not retained")
	_check(_near(float(live.get_meta(&"premium_portrait_entrance_delay", -1.0)), 0.11), "stagger delay changed")
	_check(live.offset_transform_position == Vector2(-8.0, 14.0), "premium parallax start offset changed")
	_check(is_zero_approx(live.modulate.a), "premium portrait did not begin transparent")
	_check(bool(live.get_meta(&"premium_portrait_entrance_active", false)), "premium motion was not marked active")

	var reduced := TextureRect.new()
	stage.add_child(reduced)
	var reduced_tween := EntranceType.apply(reduced, &"portrait_lunaris_vessel", 1, true)
	_check(reduced_tween == null, "Reduced Motion created a tween")
	_check(reduced.offset_transform_position == Vector2.ZERO, "Reduced Motion retained parallax displacement")
	_check(is_equal_approx(reduced.modulate.a, 1.0), "Reduced Motion retained a fade")
	_check(bool(reduced.get_meta(&"premium_portrait_entrance_reduced", false)), "Reduced Motion state was not recorded")

	var ordinary := TextureRect.new()
	stage.add_child(ordinary)
	var ordinary_tween := EntranceType.apply(ordinary, &"portrait_recruit_00", 0, false)
	_check(ordinary_tween == null, "non-premium portrait created a tween")
	_check(not ordinary.has_meta(&"premium_portrait_entrance"), "non-premium portrait received premium motion metadata")

	var pending := TextureRect.new()
	EntranceType.apply(pending, &"portrait_reliquary_duelist", 1, false)
	EntranceType.apply(pending, &"portrait_reliquary_duelist", 3, false)
	_check(pending.has_meta(&"premium_portrait_entrance_pending"), "pre-tree portrait did not retain pending entrance state")
	stage.add_child(pending)
	await process_frame
	_check(not pending.has_meta(&"premium_portrait_entrance_pending"), "pre-tree entrance did not activate on tree entry")
	_check(bool(pending.get_meta(&"premium_portrait_entrance", false)), "pre-tree premium portrait never received its entrance")
	_check(int(pending.get_meta(&"premium_portrait_entrance_index", -1)) == 3, "repeated pre-tree configuration did not keep the newest order")
	_check(pending.offset_transform_position == Vector2(8.0, 14.0), "alternating parallax direction changed")

	var recycled := TextureRect.new()
	stage.add_child(recycled)
	EntranceType.apply(recycled, &"portrait_archive_caster", 0, false)
	await create_timer(0.05).timeout
	EntranceType.apply(recycled, &"portrait_recruit_00", 0, false)
	_check(recycled.offset_transform_position == Vector2.ZERO, "premium-to-basic reuse retained parallax displacement")
	_check(is_equal_approx(recycled.modulate.a, 1.0), "premium-to-basic reuse retained portrait fade")
	_check_motion_cleared(recycled, "premium-to-basic reuse")

	var pending_basic := TextureRect.new()
	EntranceType.apply(pending_basic, &"portrait_lunaris_vessel", 4, false)
	EntranceType.apply(pending_basic, &"portrait_recruit_01", 0, false)
	_check_motion_cleared(pending_basic, "pending premium-to-basic reuse")
	stage.add_child(pending_basic)
	await process_frame
	_check_motion_cleared(pending_basic, "entered pending premium-to-basic reuse")

	var settled_pending := TextureRect.new()
	EntranceType.apply(settled_pending, &"portrait_reliquary_duelist", 5, false)
	EntranceType.settle(settled_pending)
	_check_motion_cleared(settled_pending, "settle-before-tree")
	stage.add_child(settled_pending)
	await process_frame
	_check_motion_cleared(settled_pending, "entered settle-before-tree")

	var superseded := TextureRect.new()
	stage.add_child(superseded)
	EntranceType.apply(superseded, &"portrait_archive_caster", 0, false)
	await create_timer(0.05).timeout
	EntranceType.apply(superseded, &"portrait_lunaris_vessel", 1, false)
	_check(int(superseded.get_meta(&"premium_portrait_entrance_index", -1)) == 1, "live supersession retained the old order")
	_check(superseded.offset_transform_position == Vector2(8.0, 14.0), "live supersession retained the old direction")

	var freed := TextureRect.new()
	stage.add_child(freed)
	EntranceType.apply(freed, &"portrait_archive_caster", 5, false)
	freed.free()
	await create_timer(0.1).timeout

	await create_timer(0.75).timeout
	for portrait: TextureRect in [live, pending, superseded]:
		_check(portrait.offset_transform_position.is_equal_approx(Vector2.ZERO), "%s did not settle at the authored crop" % portrait.name)
		_check(is_equal_approx(portrait.modulate.a, 1.0), "%s did not settle at full opacity" % portrait.name)
		_check(not bool(portrait.get_meta(&"premium_portrait_entrance_active", true)), "%s retained active motion metadata" % portrait.name)
	_check_motion_cleared(recycled, "settled premium-to-basic reuse")

	stage.queue_free()
	await process_frame
	_finish()


func _near(actual: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(actual - expected) <= tolerance


func _check_motion_cleared(portrait: TextureRect, context: String) -> void:
	for key: StringName in EntranceType.MOTION_META_KEYS:
		_check(not portrait.has_meta(key), "%s retained helper metadata %s" % [context, key])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _on_timeout() -> void:
	if _finished:
		return
	_failures.append("test timed out")
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("PREMIUM_PORTRAIT_ENTRANCE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("premium_portrait_entrance_test: %s" % failure)
	quit(1)
