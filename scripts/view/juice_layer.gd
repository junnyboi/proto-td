class_name JuiceLayer
extends Node2D

## Placeholder-VFX effects layer (Phase 9, td-phase-9.md §2.2 — rects and
## polygons until Lane A's manifest swap). Pure view: spawns and ages
## transients, never reads or writes the model (rule 6); battle_view owns
## all model-edge detection and calls in. Ages in _process so transient
## lifetimes count the SAME render frames the harness's frames(n) awaits —
## that alignment is what makes the two-probe decay checks deterministic
## (§2.1.9). All magnitudes come from JuiceConfig (rule 4); every Control
## sets MOUSE_FILTER_IGNORE (J1).

# sand-tinted so pixel probes never collide with the f4f4f4 chevron/tracer
const DUST_COLOR := Color("efe1a7")
const SPARK_COLOR := Color("ffcd75")
const VIGNETTE_COLOR := Color(0.9, 0.1, 0.1, 1.0)
const VIGNETTE_THICKNESS := 10.0
const KNOCK_COLOR := Color(1.0, 0.3, 0.3)
const BANNER_BACK := Color("1a1c2c")
const BANNER_TEXT_SIZE := 48
const STAMP_TEXT_SIZE := 64
const STAR_COLOR := Color("f4b41b")
const SPRUNG_COLOR := Color("f4f4f4")
const HEART_COLOR := Color("ef7d57")
const SWIRL_COLOR := Color("41a6f6")

var cfg: JuiceConfig = null

var _grid_root: Node2D = null
var _grid_base_pos := Vector2.ZERO
var _transients: Array[Dictionary] = []
var _spark_live := 0
var _vignette_rects: Array[ColorRect] = []
var _vignette_frames_left := 0
var _knock_target: CanvasItem = null
var _knock_frames_left := 0
var _banner: Label = null
var _banner_frames_left := 0
var _stamp: Control = null
var _stamp_stars: Node2D = null
var _stamp_stars_pending := 0
var _stamp_stagger_left := 0
var _shake_frames_left := 0
var _shake_total := 0
var _shake_amplitude := 0.0


func setup(juice_config: JuiceConfig, grid_root: Node2D) -> void:
	cfg = juice_config
	_grid_root = grid_root
	_grid_base_pos = grid_root.position


func _process(_delta: float) -> void:
	_age_transients()
	_age_vignette()
	_age_knock()
	_age_banner()
	_age_stamp()
	_age_shake()


## item 1: dust ring at the landing cell (6 rects radiating outward)
func dust(center: Vector2) -> void:
	for i: int in 6:
		var rect := _make_rect(DUST_COLOR, Vector2(6, 6))
		rect.position = center - Vector2(3, 3)
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 6.0)
		_transients.append({
			"node": rect, "left": cfg.deploy_dust_frames, "total": cfg.deploy_dust_frames,
			"velocity": dir * 4.0, "kind": "dust",
		})


## item 1: landing crouch — Y-squash on the unit node, restored linearly
func crouch(unit_node: Node2D) -> void:
	unit_node.scale = Vector2(1.15, 0.7)
	_transients.append({
		"node": unit_node, "left": cfg.deploy_crouch_frames,
		"total": cfg.deploy_crouch_frames, "kind": "crouch",
	})


## item 2: radial burst ring at the triggering unit's cell
func skill_burst(center: Vector2) -> void:
	for i: int in 8:
		var rect := _make_rect(SPARK_COLOR, Vector2(5, 5))
		rect.position = center - Vector2(2.5, 2.5)
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
		_transients.append({
			"node": rect, "left": cfg.skill_burst_frames, "total": cfg.skill_burst_frames,
			"velocity": dir * 7.0, "kind": "dust",
		})


## item 3: expanding spark at a corpse; capped concurrent instances
func spark(center: Vector2) -> void:
	if _spark_live >= cfg.kill_spark_cap:
		return
	_spark_live += 1
	for i: int in 4:
		var rect := _make_rect(SPARK_COLOR, Vector2(5, 5))
		rect.position = center - Vector2(2.5, 2.5)
		var dir := Vector2.RIGHT.rotated(TAU * (0.125 + float(i) / 4.0))
		var owner_flag := i == 0
		_transients.append({
			"node": rect, "left": cfg.kill_spark_frames, "total": cfg.kill_spark_frames,
			"velocity": dir * 6.0, "kind": "spark_owner" if owner_flag else "dust",
		})


func spark_count() -> int:
	return _spark_live


## item 4: screen-edge red vignette
func vignette() -> void:
	if _vignette_rects.is_empty():
		var view_size := get_viewport_rect().size
		var specs := [
			Rect2(0, 0, view_size.x, VIGNETTE_THICKNESS),
			Rect2(0, view_size.y - VIGNETTE_THICKNESS, view_size.x, VIGNETTE_THICKNESS),
			Rect2(0, 0, VIGNETTE_THICKNESS, view_size.y),
			Rect2(view_size.x - VIGNETTE_THICKNESS, 0, VIGNETTE_THICKNESS, view_size.y),
		]
		for spec: Rect2 in specs:
			var rect := _make_rect(VIGNETTE_COLOR, spec.size)
			rect.position = spec.position
			rect.visible = false
			_vignette_rects.append(rect)
	for rect: ColorRect in _vignette_rects:
		rect.visible = true
	_vignette_frames_left = cfg.leak_vignette_frames


## item 4: base-HP knock — red tint on the HUD while the vignette shows
func knock(target: CanvasItem) -> void:
	_knock_target = target
	target.modulate = KNOCK_COLOR
	_knock_frames_left = cfg.leak_vignette_frames


## item 5: wave banner — centered strip, slides through over its lifetime
func banner(text: String) -> void:
	if _banner == null:
		var view_size := get_viewport_rect().size
		var back := _make_rect(BANNER_BACK, Vector2(view_size.x, 72))
		back.name = "WaveBannerBack"
		back.position = Vector2(0, view_size.y * 0.32)
		_banner = Label.new()
		_banner.name = "WaveBanner"
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_banner.add_theme_font_size_override("font_size", BANNER_TEXT_SIZE)
		_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.size = back.size
		back.add_child(_banner)
	_banner.text = text
	(_banner.get_parent() as ColorRect).visible = true
	_banner_frames_left = cfg.wave_banner_frames


func banner_visible() -> bool:
	return _banner != null and (_banner.get_parent() as ColorRect).visible


## item 5: terminal stamp — CLEAR/DEFEAT + one star per model star,
## revealed in sequence (star_burst_stagger_frames apart)
func stamp(result_text: String, stars: int) -> void:
	if _stamp != null:
		return
	var view_size := get_viewport_rect().size
	_stamp = _make_rect(BANNER_BACK, Vector2(view_size.x, 200))
	_stamp.name = "ResultStamp"
	_stamp.position = Vector2(0, (view_size.y - 200.0) * 0.5)
	var label := Label.new()
	label.name = "ResultStampLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = result_text
	label.add_theme_font_size_override("font_size", STAMP_TEXT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(view_size.x, 90)
	_stamp.add_child(label)
	_stamp_stars = Node2D.new()
	_stamp_stars.name = "StampStars"
	_stamp_stars.position = Vector2(view_size.x * 0.5, 150)
	_stamp.add_child(_stamp_stars)
	_stamp_stars_pending = stars
	_stamp_stagger_left = 1


## item 6: sprung frame on a spike rect. adopt = true hands the rect's
## lifetime to the juice layer (the final-charge trap already left the
## model, so the view must not free it until the frames run out — J11)
func sprung(trap_rect: ColorRect, adopt: bool) -> void:
	var core := trap_rect.get_child(0) as ColorRect
	if core != null:
		core.color = SPRUNG_COLOR
	trap_rect.color = SPRUNG_COLOR.darkened(0.25)
	_transients.append({
		"node": trap_rect, "left": cfg.trap_sprung_frames, "total": cfg.trap_sprung_frames,
		"kind": "sprung_adopted" if adopt else "sprung",
	})
	# the triggering enemy's 40px rect draws over the 24px plate at exactly
	# the trigger moment — flash an overlay in this layer (above enemies) so
	# the sprung frame is actually visible (and probe-able)
	var flash := _make_rect(SPRUNG_COLOR, Vector2(28, 28))
	flash.position = trap_rect.get_global_rect().get_center() - Vector2(14, 14)
	_transients.append({
		"node": flash, "left": cfg.trap_sprung_frames, "total": cfg.trap_sprung_frames,
		"kind": "dust",
	})


## item 6: tar shimmer phase — half-period square wave over render frames
func shimmer_on() -> bool:
	var period := maxi(cfg.tar_shimmer_period_frames, 2)
	@warning_ignore("integer_division")
	var half := period / 2
	return (Engine.get_process_frames() / half) % 2 == 0


## item 7: conversion swirl — rotating quads + heart pixels above the rect
func swirl(center: Vector2) -> void:
	for i: int in 4:
		var rect := _make_rect(SWIRL_COLOR, Vector2(7, 7))
		rect.position = center - Vector2(3.5, 3.5)
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 4.0)
		_transients.append({
			"node": rect, "left": cfg.charm_swirl_frames, "total": cfg.charm_swirl_frames,
			"velocity": dir * 3.0, "orbit": true, "kind": "dust",
		})
	for i: int in 3:
		var heart := _make_rect(HEART_COLOR, Vector2(4, 4))
		heart.position = center + Vector2(-8.0 + 8.0 * i, -34.0)
		_transients.append({
			"node": heart, "left": cfg.charm_swirl_frames, "total": cfg.charm_swirl_frames,
			"kind": "dust",
		})


## shake through the config whitelist ONLY (parent plan: boss hits, leaks,
## charm beat). Deterministic decay, no RNG: alternating-sign X offset.
func shake(event: String, amplitude_px: float, frames: int) -> void:
	if not cfg.shake_events.has(event) or amplitude_px <= 0.0 or frames <= 0:
		return
	_shake_amplitude = amplitude_px
	_shake_frames_left = frames
	_shake_total = frames


func _make_rect(color: Color, rect_size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color
	rect.size = rect_size
	add_child(rect)
	return rect


func _age_transients() -> void:
	var kept: Array[Dictionary] = []
	for tr: Dictionary in _transients:
		tr["left"] = int(tr["left"]) - 1
		var kind := String(tr["kind"])
		if not is_instance_valid(tr["node"]):
			# host node freed externally (unit died mid-crouch, scene swap)
			if kind == "spark_owner":
				_spark_live -= 1
			continue
		if int(tr["left"]) <= 0:
			_expire_transient(tr, kind)
			continue
		if tr.has("velocity"):
			var rect := tr["node"] as ColorRect
			var vel: Vector2 = tr["velocity"]
			if tr.get("orbit", false):
				vel = vel.rotated(0.35)
				tr["velocity"] = vel
			rect.position += vel
		if kind == "crouch":
			var node := tr["node"] as Node2D
			var t := 1.0 - float(tr["left"]) / float(tr["total"])
			node.scale = Vector2(1.15, 0.7).lerp(Vector2.ONE, t)
		kept.append(tr)
	_transients = kept


func _expire_transient(tr: Dictionary, kind: String) -> void:
	match kind:
		"crouch":
			(tr["node"] as Node2D).scale = Vector2.ONE
		"spark_owner":
			_spark_live -= 1
			(tr["node"] as CanvasItem).queue_free()
		"sprung_adopted":
			(tr["node"] as CanvasItem).queue_free()
		"sprung":
			var rect := tr["node"] as ColorRect
			if is_instance_valid(rect):
				rect.color = Color("f4b41b")
				var core := rect.get_child(0) as ColorRect
				if core != null:
					core.color = Color("1a1c2c")
		_:
			(tr["node"] as CanvasItem).queue_free()


func _age_vignette() -> void:
	if _vignette_frames_left <= 0:
		return
	_vignette_frames_left -= 1
	if _vignette_frames_left == 0:
		for rect: ColorRect in _vignette_rects:
			rect.visible = false


func _age_knock() -> void:
	if _knock_frames_left <= 0:
		return
	_knock_frames_left -= 1
	if _knock_frames_left == 0 and _knock_target != null and is_instance_valid(_knock_target):
		_knock_target.modulate = Color.WHITE


func _age_banner() -> void:
	if _banner_frames_left <= 0:
		return
	_banner_frames_left -= 1
	var back := _banner.get_parent() as ColorRect
	var t := 1.0 - float(_banner_frames_left) / float(maxi(cfg.wave_banner_frames, 1))
	back.position.x = lerpf(-60.0, 60.0, t)
	if _banner_frames_left == 0:
		back.visible = false


func _age_stamp() -> void:
	if _stamp_stars_pending <= 0:
		return
	_stamp_stagger_left -= 1
	if _stamp_stagger_left > 0:
		return
	_stamp_stagger_left = cfg.star_burst_stagger_frames
	_stamp_stars_pending -= 1
	var idx := _stamp_stars.get_child_count()
	var star := Polygon2D.new()
	star.name = "Star%d" % idx
	star.color = STAR_COLOR
	star.polygon = _star_points(16.0)
	star.position = Vector2(-52.0 + 52.0 * idx, 0)
	_stamp_stars.add_child(star)


static func _star_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(Vector2.UP.rotated(TAU * float(i) / 10.0) * r)
	return points


func _age_shake() -> void:
	if _shake_frames_left <= 0:
		return
	_shake_frames_left -= 1
	if _shake_frames_left == 0:
		_grid_root.position = _grid_base_pos
		return
	var sign_flip := 1.0 if _shake_frames_left % 2 == 0 else -1.0
	var decay := float(_shake_frames_left) / float(maxi(_shake_total, 1))
	_grid_root.position = _grid_base_pos + Vector2(_shake_amplitude * decay * sign_flip, 0)
