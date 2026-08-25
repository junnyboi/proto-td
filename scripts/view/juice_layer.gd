class_name JuiceLayer
extends Node2D

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")

## Manifest-backed presentation effects. Pure view: spawns and ages transients,
## never reads or writes the model; BattleView owns all model-edge detection and
## calls in. Effects age in _process, all magnitudes come from JuiceConfig, and
## every Control ignores mouse input.

const VFX_DEPLOY_DUST := &"vfx_deploy_dust"
const VFX_KILL_SPARK := &"vfx_kill_spark"
const VFX_LEAK_VIGNETTE := &"vfx_leak_vignette"
const VFX_CHARM_SWIRL := &"vfx_charm_swirl"
const VFX_WAVE_BANNER := &"vfx_wave_banner"
const VFX_RESULT_STAMP := &"vfx_result_stamp"
const KNOCK_COLOR := Color(1.0, 0.3, 0.3)
const BANNER_TEXT_SIZE := GameTypographyType.DISPLAY
const STAMP_TEXT_SIZE := GameTypographyType.RESULT_DISPLAY
const STAR_COLOR := Color("f4b41b")
const SPRUNG_COLOR := Color("f4f4f4")

var cfg: JuiceConfig = null

var _grid_root: Node2D = null
var _grid_base_pos := Vector2.ZERO
var _map_transient_root: Node2D = null
var _transients: Array[Dictionary] = []
var _spark_live := 0
var _vignette: NinePatchRect = null
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
var _last_placement_profile: StringName = &""


func setup(juice_config: JuiceConfig, grid_root: Node2D) -> void:
	cfg = juice_config
	_grid_root = grid_root
	_grid_base_pos = grid_root.position
	_map_transient_root = Node2D.new()
	_map_transient_root.name = "MapTransientRoot"
	add_child(_map_transient_root)
	_sync_map_transient_transform()


## P14/TD-008: re-anchor shake and every grid-local transient after map pan,
## zoom, or viewport resize.
func refresh_base() -> void:
	if _grid_root != null:
		_grid_base_pos = _grid_root.position
		_sync_map_transient_transform()


func relayout(view_size: Vector2) -> void:
	if _banner != null:
		var banner_back := _banner.get_parent() as NinePatchRect
		banner_back.size = Vector2(view_size.x, 72.0)
		banner_back.position.y = view_size.y * 0.48
		_banner.size = banner_back.size
	if _vignette != null:
		_vignette.position = Vector2.ZERO
		_vignette.size = view_size
	if _stamp != null:
		_stamp.size = Vector2(view_size.x, 200.0)
		_stamp.position = Vector2(0, (view_size.y - 200.0) * 0.5)
		var label := _stamp.get_node("ResultStampLabel") as Label
		label.size = Vector2(view_size.x, 90.0)
		_stamp_stars.position = Vector2(view_size.x * 0.5, 150.0)


func _process(_delta: float) -> void:
	_age_transients()
	_age_vignette()
	_age_knock()
	_age_banner()
	_age_stamp()
	_age_shake()


## Normal-ground placement: warm granular dust and grit burst radially across
## the diamond face. The generated deployment SFX provides the matching earthy
## thunk and amber lock-in accent.
func placement_ground(local_center: Vector2) -> void:
	_last_placement_profile = &"ground"
	for i: int in cfg.deploy_ground_particles:
		var sprite := _make_map_texture(
			VFX_DEPLOY_DUST,
			Vector2(12, 12),
			"PlacementGroundDust",
		)
		sprite.modulate = cfg.deploy_ground_color
		var angle := TAU * (float(i) + 0.5) / float(cfg.deploy_ground_particles)
		var dir := Vector2.RIGHT.rotated(angle)
		_transients.append({
			"node": sprite,
			"left": cfg.deploy_dust_frames,
			"total": cfg.deploy_dust_frames,
			"velocity_screen": dir * cfg.deploy_ground_speed_px,
			"map_anchor": local_center,
			"offset_screen": Vector2(-6, -6),
			"travel_screen": Vector2.ZERO,
			"kind": "placement_ground",
		})
		_position_map_transient(_transients.back())


## Elevated placement: crystalline shards launch upward/outward while a cyan
## ring expands across the top face and a brief energy column contracts upward.
func placement_elevated(local_center: Vector2) -> void:
	_last_placement_profile = &"elevated"
	for i: int in cfg.deploy_elevated_shards:
		var shard := _make_map_texture(
			VFX_KILL_SPARK,
			Vector2(10, 10),
			"PlacementElevatedShard",
		)
		shard.modulate = cfg.deploy_elevated_shard_color
		var spread := lerpf(-0.75, 0.75, float(i) / float(maxi(cfg.deploy_elevated_shards - 1, 1)))
		var dir := Vector2(spread, -1.0).normalized()
		_transients.append({
			"node": shard,
			"left": cfg.deploy_elevated_frames,
			"total": cfg.deploy_elevated_frames,
			"velocity_screen": dir * cfg.deploy_elevated_shard_speed_px,
			"map_anchor": local_center,
			"offset_screen": Vector2(-5, -5),
			"travel_screen": Vector2.ZERO,
			"spin": (-0.12 if i % 2 == 0 else 0.12),
			"kind": "placement_elevated_shard",
		})
		_position_map_transient(_transients.back())
	var ring := _make_placement_ring(cfg.deploy_elevated_ring_color)
	_transients.append({
		"node": ring,
		"left": cfg.deploy_elevated_frames,
		"total": cfg.deploy_elevated_frames,
		"map_anchor": local_center,
		"offset_screen": Vector2.ZERO,
		"travel_screen": Vector2.ZERO,
		"kind": "placement_elevated_ring",
	})
	_position_map_transient(_transients.back())
	var beam := _make_map_rect(
		cfg.deploy_elevated_beam_color,
		Vector2(8, 54),
		"PlacementElevatedBeam",
	)
	beam.pivot_offset = Vector2(4, 54)
	_transients.append({
		"node": beam,
		"left": cfg.deploy_elevated_frames,
		"total": cfg.deploy_elevated_frames,
		"map_anchor": local_center,
		"offset_screen": Vector2(-4, -54),
		"travel_screen": Vector2.ZERO,
		"kind": "placement_elevated_beam",
	})
	_position_map_transient(_transients.back())


## Backward-compatible generic dust entry for presentation callers that do not
## know the placement tile type.
func dust(local_center: Vector2) -> void:
	placement_ground(local_center)


func last_placement_profile() -> StringName:
	return _last_placement_profile


func placement_emitter_count() -> int:
	var count := 0
	for transient: Dictionary in _transients:
		if String(transient.get("kind", "")).begins_with("placement_"):
			count += 1
	return count


## item 1: landing crouch — Y-squash on the unit node, restored linearly
func crouch(unit_node: Node2D) -> void:
	unit_node.scale = Vector2(1.15, 0.7)
	_transients.append({
		"node": unit_node, "left": cfg.deploy_crouch_frames,
		"total": cfg.deploy_crouch_frames, "kind": "crouch",
	})


## item 2: manifest-backed radial burst at the triggering unit's grid-local cell
func skill_burst(local_center: Vector2) -> void:
	for i: int in 8:
		var sprite := _make_map_texture(VFX_KILL_SPARK, Vector2(12, 12), "MapTransientSkill")
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
		_transients.append({
			"node": sprite, "left": cfg.skill_burst_frames,
			"total": cfg.skill_burst_frames, "velocity_screen": dir * 7.0,
			"map_anchor": local_center, "offset_screen": Vector2(-6, -6),
			"travel_screen": Vector2.ZERO, "kind": "dust",
		})
		_position_map_transient(_transients.back())


## TD-021: target-side Mend ring. All visible magnitudes live in JuiceConfig;
func heal_burst(local_center: Vector2) -> void:
	var half := Vector2.ONE * cfg.heal_burst_size_px * 0.5
	for i: int in cfg.heal_burst_particles:
		var sprite := _make_map_texture(
			VFX_KILL_SPARK,
			Vector2.ONE * cfg.heal_burst_size_px,
			"MapTransientHeal",
		)
		sprite.modulate = cfg.heal_burst_color
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / float(cfg.heal_burst_particles))
		_transients.append({
			"node": sprite,
			"left": cfg.heal_burst_frames,
			"total": cfg.heal_burst_frames,
			"velocity_screen": dir * cfg.heal_burst_speed_px,
			"map_anchor": local_center,
			"offset_screen": -half,
			"travel_screen": Vector2.ZERO,
			"kind": "dust",
		})
		_position_map_transient(_transients.back())


## item 3: manifest-backed expanding spark at a corpse; capped instances
func spark(local_center: Vector2) -> void:
	if _spark_live >= cfg.kill_spark_cap:
		return
	_spark_live += 1
	for i: int in 4:
		var sprite := _make_map_texture(VFX_KILL_SPARK, Vector2(12, 12), "MapTransientSpark")
		var dir := Vector2.RIGHT.rotated(TAU * (0.125 + float(i) / 4.0))
		var owner_flag := i == 0
		_transients.append({
			"node": sprite, "left": cfg.kill_spark_frames, "total": cfg.kill_spark_frames,
			"velocity_screen": dir * 6.0,
			"map_anchor": local_center, "offset_screen": Vector2(-6, -6),
			"travel_screen": Vector2.ZERO,
			"kind": "spark_owner" if owner_flag else "dust",
		})
		_position_map_transient(_transients.back())


func spark_count() -> int:
	return _spark_live


## item 4: manifest-backed screen-edge red vignette
func vignette() -> void:
	if _vignette == null:
		_vignette = _make_nine_patch(
			VFX_LEAK_VIGNETTE,
			get_viewport_rect().size,
			Vector4i(18, 18, 18, 18),
		)
		_vignette.name = "LeakVignette"
		_vignette.visible = false
	_vignette.visible = true
	_vignette_frames_left = cfg.leak_vignette_frames


## item 4: base-HP knock — red tint on the HUD while the vignette shows
func knock(target: CanvasItem) -> void:
	_knock_target = target
	target.modulate = KNOCK_COLOR
	_knock_frames_left = cfg.leak_vignette_frames


## item 5: manifest-backed wave banner; slides through over its lifetime
func banner(text: String) -> void:
	if _banner == null:
		var view_size := get_viewport_rect().size
		var back := _make_nine_patch(
			VFX_WAVE_BANNER,
			Vector2(view_size.x, 72),
			Vector4i(24, 8, 24, 8),
		)
		back.name = "WaveBannerBack"
		back.position = Vector2(0, view_size.y * 0.48)
		_banner = Label.new()
		_banner.name = "WaveBanner"
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_banner.add_theme_font_size_override("font_size", BANNER_TEXT_SIZE)
		_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_banner.size = back.size
		back.add_child(_banner)
	_banner.text = text
	(_banner.get_parent() as NinePatchRect).visible = true
	_banner_frames_left = cfg.wave_banner_frames


func banner_visible() -> bool:
	return _banner != null and (_banner.get_parent() as NinePatchRect).visible


## item 5: terminal stamp — CLEAR/DEFEAT + one star per model star,
## revealed in sequence (star_burst_stagger_frames apart)
func stamp(result_text: String, stars: int) -> void:
	if _stamp != null:
		return
	var view_size := get_viewport_rect().size
	_stamp = _make_nine_patch(
		VFX_RESULT_STAMP,
		Vector2(view_size.x, 200),
		Vector4i(24, 16, 24, 16),
	)
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
	var flash := _make_map_rect(SPRUNG_COLOR, Vector2(28, 28), "MapTransientSprung")
	var local_center := _grid_root.to_local(trap_rect.get_global_rect().get_center())
	flash.position = local_center - Vector2(14, 14) / _grid_root.scale.x
	_transients.append({
		"node": flash, "left": cfg.trap_sprung_frames, "total": cfg.trap_sprung_frames,
		"map_anchor": local_center, "offset_screen": Vector2(-14, -14),
		"travel_screen": Vector2.ZERO, "kind": "dust",
	})


## item 6: tar shimmer phase — half-period square wave over render frames
func shimmer_on() -> bool:
	var period := maxi(cfg.tar_shimmer_period_frames, 2)
	@warning_ignore("integer_division")
	var half := period / 2
	return (Engine.get_process_frames() / half) % 2 == 0


## item 7: manifest-backed grid-local conversion swirl
func swirl(local_center: Vector2) -> void:
	var sprite := _make_map_texture(VFX_CHARM_SWIRL, Vector2(48, 48), "MapTransientSwirl")
	_transients.append({
		"node": sprite,
		"left": cfg.charm_swirl_frames,
		"total": cfg.charm_swirl_frames,
		"map_anchor": local_center,
		"offset_screen": Vector2(-24, -24),
		"travel_screen": Vector2.ZERO,
		"spin": 0.16,
		"kind": "dust",
	})
	_position_map_transient(_transients.back())


## shake through the config whitelist ONLY (parent plan: boss hits, leaks,
## charm beat). Deterministic decay, no RNG: alternating-sign X offset.
func shake(event: String, amplitude_px: float, frames: int) -> void:
	if not cfg.shake_events.has(event) or amplitude_px <= 0.0 or frames <= 0:
		return
	_shake_amplitude = amplitude_px
	_shake_frames_left = frames
	_shake_total = frames


func _make_nine_patch(
	asset_id: StringName, panel_size: Vector2, margins: Vector4i
) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = Art.texture(asset_id)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.draw_center = true
	panel.size = panel_size
	panel.set_patch_margin(SIDE_LEFT, margins.x)
	panel.set_patch_margin(SIDE_TOP, margins.y)
	panel.set_patch_margin(SIDE_RIGHT, margins.z)
	panel.set_patch_margin(SIDE_BOTTOM, margins.w)
	add_child(panel)
	return panel


func _make_map_texture(
	asset_id: StringName, rect_size: Vector2, node_name: String
) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = node_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = Art.texture(asset_id)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = rect_size
	sprite.scale = Vector2.ONE / _grid_root.scale.x
	_map_transient_root.add_child(sprite)
	return sprite


func _make_map_rect(color: Color, rect_size: Vector2, node_name: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color
	rect.size = rect_size
	rect.scale = Vector2.ONE / _grid_root.scale.x
	_map_transient_root.add_child(rect)
	return rect


func _make_placement_ring(color: Color) -> Line2D:
	var ring := Line2D.new()
	ring.name = "PlacementElevatedRing"
	ring.width = 2.0
	ring.default_color = color
	ring.antialiased = false
	var face := IsoProjection.face_polygon()
	var points := PackedVector2Array(face)
	points.append(face[0])
	ring.points = points
	ring.scale = Vector2.ONE / _grid_root.scale.x
	_map_transient_root.add_child(ring)
	return ring


func _sync_map_transient_transform() -> void:
	if _map_transient_root == null or _grid_root == null:
		return
	_map_transient_root.position = _grid_root.position
	_map_transient_root.scale = _grid_root.scale
	for tr: Dictionary in _transients:
		if tr.has("map_anchor") and is_instance_valid(tr["node"]):
			_position_map_transient(tr)


func _position_map_transient(tr: Dictionary) -> void:
	var screen_offset: Vector2 = tr["offset_screen"]
	var screen_travel: Vector2 = tr["travel_screen"]
	var target_position := tr["map_anchor"] as Vector2 \
		+ (screen_offset + screen_travel) / _grid_root.scale.x
	var control := tr["node"] as Control
	if control != null:
		control.scale = Vector2.ONE / _grid_root.scale.x
		control.position = target_position
		return
	var node_2d := tr["node"] as Node2D
	if node_2d != null:
		node_2d.scale = Vector2.ONE / _grid_root.scale.x
		node_2d.position = target_position


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
		if tr.has("velocity_screen"):
			var vel: Vector2 = tr["velocity_screen"]
			tr["travel_screen"] = (tr["travel_screen"] as Vector2) + vel
			_position_map_transient(tr)
		if tr.has("spin"):
			(tr["node"] as Control).rotation += float(tr["spin"])
		var progress := 1.0 - float(tr["left"]) / float(tr["total"])
		if kind == "placement_ground" or kind == "placement_elevated_shard":
			var particle := tr["node"] as CanvasItem
			var particle_modulate := particle.modulate
			particle_modulate.a = clampf((1.0 - progress) * 1.75, 0.0, 1.0)
			particle.modulate = particle_modulate
		elif kind == "placement_elevated_ring":
			var ring := tr["node"] as Line2D
			var ring_scale := lerpf(0.55, 1.55, progress) / _grid_root.scale.x
			ring.scale = Vector2.ONE * ring_scale
			ring.modulate.a = 1.0 - progress
		elif kind == "placement_elevated_beam":
			var beam := tr["node"] as ColorRect
			var inverse_grid_scale := 1.0 / _grid_root.scale.x
			beam.scale = Vector2(
				lerpf(1.0, 0.35, progress),
				lerpf(1.0, 0.08, progress),
			) * inverse_grid_scale
			beam.modulate.a = 1.0 - progress
		if kind == "crouch":
			var node := tr["node"] as Node2D
			node.scale = Vector2(1.15, 0.7).lerp(Vector2.ONE, progress)
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
	if _vignette_frames_left == 0 and _vignette != null:
		_vignette.visible = false


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
	var back := _banner.get_parent() as NinePatchRect
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
		_sync_map_transient_transform()
		return
	var sign_flip := 1.0 if _shake_frames_left % 2 == 0 else -1.0
	var decay := float(_shake_frames_left) / float(maxi(_shake_total, 1))
	_grid_root.position = _grid_base_pos + Vector2(_shake_amplitude * decay * sign_flip, 0)
	_sync_map_transient_transform()
