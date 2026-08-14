extends Node2D

## Read-only BattleModel projection; speed changes ticks/frame, never outcomes.

const MAP_NAVIGATOR_SCRIPT: GDScript = preload("res://scripts/view/map_navigator.gd")
const BATTLE_HUD_PRESENTER := preload("res://scripts/view/battle_hud_presenter.gd")
const BattlePalette := preload("res://scripts/view/battle_palette.gd")
const EnemyAnimator := preload("res://scripts/view/enemy_animator.gd")
const OPERATOR_ANIMATOR_SCRIPT := preload("res://scripts/view/operator_animator.gd")
const OPERATOR_VISUAL_CATALOG_SCRIPT := preload(
	"res://data/presentation/operator_visual_catalog.gd"
)
const StageArtThemeType := preload("res://data/presentation/stage_art_theme.gd")

const HUD_FONT_SIZE := 32
const SPRITE_SCALE := 2  # 32px art on the 64px grid (pinned 2x integer)
const IDLE_BOB_FRAMES := 24
const ATTACK_POSE_FRAMES := 8

## Pinned z bands: grid 0-40, overlays 50, juice 60, HUD/flash/continue 70.
const UI_OVERLAY_Z := 50
const JUICE_Z := 60
const HUD_Z := 70
## Full-canvas background behind IsoGridBuilder terrain and backdrop.
const BACKDROP_COLOR := Color("11131f")
const ENEMY_COLOR := Color("ef7d57")
const AERIAL_PX := 24.0
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
## Ground shadow is a 20x10 face diamond; aerial shadow drops 10px.
const SHADOW_FACE_SCALE := 0.3125
const AERIAL_SHADOW_DROP := 10.0
const TRACER_COLOR := Color("f4f4f4")
const UNIT_PX := 64.0  # 32px art at the pinned 2x scale
const HP_BAR_HEIGHT := 5.0
const HP_BAR_BG := Color("3a2026")
const HP_BAR_FILL := Color("a7f070")
const SP_BAR_BG := Color("20263a")
const SP_BAR_FILL := Color("f4b41b")
const SP_FULL_FLASH := Color("f4f4f4")
const PORTRAIT_FLASH_PX := 96.0
const CHEVRON_COLOR := Color("f4f4f4")
const TRAP_SPIKE_COLOR := Color("f4b41b")
const TRAP_SPIKE_CORE := Color("1a1c2c")
const TRAP_SPIKE_PX := 24.0
const TAR_OVERLAY_COLOR := Color(0.08, 0.05, 0.14, 0.6)

var model: BattleModel = null
var startup_succeeded: bool = false
var theme_resolver: Callable = Callable()
var model_factory: Callable = Callable()
var ticks_per_frame_scale: float = 1.0
var cfg: JuiceConfig = null

var _grid_root: Node2D = null
var _grid_scale := 1.0
var _map_nav: RefCounted = MAP_NAVIGATOR_SCRIPT.new()
var _backdrop: ColorRect = null
var _stage: StageDef = null
var _stage_theme: Resource = null
var _enemy_rects: Dictionary = {}
var _unit_nodes: Dictionary = {}
var _tracer_lines: Dictionary = {}
var _tracer_seen_tick: Dictionary = {}
var _tracer_frames_left: Dictionary = {}
var _skill_seen_tick: Dictionary = {}
var _portrait_flash: ColorRect = null
var _portrait_flash_frames := 0
var _continue_btn: Button = null
var _deploy_bar: DeployBar = null
var _spell_bar: SpellBar = null
var _controls: BattleControls = null
var _op_defs: Dictionary = {}
var _trap_defs: Dictionary = {}
var _spell_defs: Dictionary = {}
var _trap_rects: Dictionary = {}
var _trap_kinds: Dictionary = {}
var _spell_casts_last: Dictionary = {}
var _charm_events_last: Dictionary = {}
var _hud: Label = null
var _tick_accum: float = 0.0
var _juice: JuiceLayer = null
var _time_tags: Dictionary = {}
var _beat_frames_left := 0
var _hit_stop_frames := 0
var _deploy_seen: Dictionary = {}
var _spark_seen: Dictionary = {}
var _leaked_seen := 0
var _banner_seen_wave := -1
var _stamp_shown := false
var _snaps_seen := 0
var _trap_trigger_seen: Dictionary = {}
var _charm_seen: Dictionary = {}
var _pushed: Dictionary = {
	"enemies_spawned": "spawned",
	"enemies_leaked": "leaked",
	"enemies_killed": "killed",
	"deploys": "deploys",
	"retreats": "retreated",
	"dp_spent": "dp_spent",
	"skills_fired": "skills_fired",
	"traps_placed": "traps_placed",
	"trap_triggers": "trap_triggers",
	"enemies_charmed": "charmed",
	"charmed_dead": "charmed_dead",
	"charmed_exited": "charmed_exited",
	"spells_cast": "spells_cast",
}
var _pushed_last: Dictionary = {}
var _result_reported := false
var _enemy_defs: Dictionary = {}
var _enemy_anim_keys: Dictionary = {}
var _enemy_blend_frames: Dictionary = {}
var _enemy_anim_seconds := 0.0
var _attack_pose_left: Dictionary = {}
var _unit_attack_seen: Dictionary = {}


func _init() -> void:
	theme_resolver = Callable(self, "_resolve_stage_theme")
	model_factory = Callable(self, "_create_battle_model")


func _ready() -> void:
	var stage := Game.pending_stage
	if stage == null:
		push_error("battle_view: no pending stage")
		return
	# Required world presentation is preflighted before any catalog or model load.
	# Keep this explicit preload-backed call: stale global-class registries must not
	# be able to bypass Act II activation.
	var theme_result: Dictionary = theme_resolver.call(stage)
	var theme_error := String(theme_result["error"])
	if not theme_error.is_empty():
		push_error("battle_view: stage art preflight failed: %s" % theme_error)
		return
	_stage_theme = theme_result["theme"] as Resource
	var config := load("res://data/config/game.tres") as GameConfig
	var defs := _load_enemy_defs(stage)
	_enemy_defs = defs
	# operators load as a full catalog too (squad stays the model's loadout
	# filter) so debug grants can resolve any operator on disk (Phase 8)
	_op_defs = _load_catalog("res://data/operators", "OperatorDef")
	_trap_defs = _load_catalog("res://data/traps", "TrapDef")
	_spell_defs = _load_catalog("res://data/spells", "SpellDef")
	var candidate_model: BattleModel = model_factory.call(
		stage, Game.battle_squad(), Game.run_seed, config, defs, _op_defs, _trap_defs, _spell_defs
	)
	if candidate_model == null:
		push_error("battle_view: model factory failed")
		return
	_stage = stage
	if not _build_grid(stage):
		return
	cfg = load("res://data/juice_config.tres") as JuiceConfig
	_juice = JuiceLayer.new()
	_juice.name = "JuiceLayer"
	_juice.z_index = JUICE_Z
	add_child(_juice)
	_juice.setup(cfg, _grid_root)
	_build_hud()
	_portrait_flash = ColorRect.new()
	_portrait_flash.name = "PortraitFlash"
	_portrait_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_flash.size = Vector2.ONE * PORTRAIT_FLASH_PX
	_portrait_flash.position = Vector2((get_viewport_rect().size.x - PORTRAIT_FLASH_PX) * 0.5, 56.0)
	_portrait_flash.visible = false
	_portrait_flash.z_index = HUD_Z
	add_child(_portrait_flash)
	# loadout gating is UI-only (td-phase-6-7 §2.1): the bars see the
	# unlocked sets while a campaign runs, the full catalogs otherwise —
	# the model stays catalog-validated either way
	var bar_traps: Dictionary = {}
	for trap_id: StringName in Game.loadout_trap_ids():
		if _trap_defs.has(trap_id):
			bar_traps[trap_id] = _trap_defs[trap_id]
	_deploy_bar = DeployBar.new()
	_deploy_bar.name = "DeployBar"
	_deploy_bar.z_index = UI_OVERLAY_Z
	add_child(_deploy_bar)
	_deploy_bar.setup(candidate_model, self, _op_defs, bar_traps)
	_spell_bar = SpellBar.new()
	_spell_bar.name = "SpellBar"
	_spell_bar.z_index = UI_OVERLAY_Z
	add_child(_spell_bar)
	_spell_bar.setup(candidate_model, self, Game.loadout_spell_ids())
	_controls = BattleControls.new()
	_controls.name = "BattleControls"
	_controls.z_index = UI_OVERLAY_Z
	add_child(_controls)
	_controls.setup(candidate_model, self)
	# the view is the ONE resize owner: it recomputes the grid scale first,
	# then drives the bars (self-owned listeners raced the recompute — P14)
	get_viewport().size_changed.connect(_relayout)
	model = candidate_model
	startup_succeeded = true


func _resolve_stage_theme(stage: Resource) -> Dictionary:
	return StageArtThemeType.resolve_for(stage)


func _create_battle_model(
	stage: StageDef,
	squad: Array[StringName],
	seed_value: int,
	config: GameConfig,
	enemy_defs: Dictionary,
	op_defs: Dictionary,
	trap_defs: Dictionary,
	spell_defs: Dictionary
) -> BattleModel:
	return BattleModel.create(
		stage, squad, seed_value, config, enemy_defs, op_defs, trap_defs, spell_defs
	)


## Screen center of a cell's visible face; elevated cells include their lift.
func cell_center(cell: Vector2i) -> Vector2:
	var local := IsoProjection.face_center(cell, _is_lifted_cell(cell))
	return _grid_root.position + local * _grid_scale


func cell_at(screen_pos: Vector2) -> Vector2i:
	var local := (screen_pos - _grid_root.position) / _grid_scale
	return IsoProjection.pick(local, _is_lifted_cell)


## Screen point for continuous flat cell-space positions and VFX anchors.
func screen_of(p: Vector2) -> Vector2:
	return _grid_root.position + IsoProjection.project(p) * _grid_scale


## Current uniform grid scale used by screen-owned overlay footprints.
func grid_scale() -> float:
	return _grid_scale


func map_screen_rect() -> Rect2:
	var box := IsoProjection.terrain_box(_stage)
	return Rect2(_grid_root.position + box.position * _grid_scale, box.size * _grid_scale)


func map_content_rect() -> Rect2:
	return _map_nav.content_screen_rect()


func map_pan() -> Vector2:
	return _map_nav.pan


func map_pan_bounds() -> Rect2:
	return _map_nav.bounds


func map_dragging() -> bool:
	return _map_nav.is_dragging()


func _input(event: InputEvent) -> void:
	_map_nav.recover_missed_release(event)


func _unhandled_input(event: InputEvent) -> void:
	if _grid_root == null or _map_navigation_blocked():
		return
	if _map_nav.handle_input(event):
		_apply_map_transform()
		get_viewport().set_input_as_handled()


func _map_navigation_blocked() -> bool:
	var deploy_cursor := find_child("CursorRect", true, false) as CanvasItem
	var spell_cursor := find_child("SpellCursor", true, false) as CanvasItem
	var deploy_bar := find_child("DeployBar", true, false) as DeployBar
	return (
		(deploy_cursor != null and deploy_cursor.visible)
		or (spell_cursor != null and spell_cursor.visible)
		or (deploy_bar != null and deploy_bar.is_mend_targeting())
	)


func _is_lifted_cell(cell: Vector2i) -> bool:
	return _stage != null and _stage.tile_at(cell) == StageDef.Tile.ELEVATED


func _physics_process(delta: float) -> void:
	if model == null:
		return
	# hit-stop: suspend tick consumption only — outcome-safe by rule 6
	if _hit_stop_frames > 0:
		_hit_stop_frames -= 1
		_project()
		return
	_tick_accum += delta * model.config.ticks_per_second * ticks_per_frame_scale
	while _tick_accum >= 1.0:
		_tick_accum -= 1.0
		model.step()
		_push_telemetry()
	_project()


## Juice detection and harness decay share render-frame timing and cfg magnitudes.
func _process(delta: float) -> void:
	if model == null or _juice == null:
		return
	_enemy_anim_seconds += delta
	_detect_deploys()
	_detect_kills()
	_detect_leaks()
	_detect_wave()
	_detect_result_stamp()
	_detect_trap_juice()
	_detect_charms()
	if _beat_frames_left > 0:
		_beat_frames_left -= 1
		if _beat_frames_left == 0:
			juice_time_pop(&"charm_beat")
	# flash ages here, not in the physics-paced projection: juice lifetimes
	# count the same render frames the harness's frames(n) awaits (§2.1.2 —
	# physics-frame aging halves the visual budget on 120 Hz displays and
	# breaks the decay probes)
	if _portrait_flash_frames > 0:
		_portrait_flash_frames -= 1
		if _portrait_flash_frames == 0 and _portrait_flash != null:
			_portrait_flash.visible = false
	_age_view_transients()


## Tracer and attack-pose countdowns age in render frames, including hit-stop.
func _age_view_transients() -> void:
	for uid: int in _tracer_frames_left.keys():
		var left := int(_tracer_frames_left[uid])
		if left > 0:
			_tracer_frames_left[uid] = left - 1
	for uid: int in _attack_pose_left.keys():
		var left := int(_attack_pose_left[uid])
		if left > 0:
			_attack_pose_left[uid] = left - 1
	for enemy_id: int in _enemy_blend_frames.keys():
		if not _enemy_rects.has(enemy_id):
			_enemy_blend_frames.erase(enemy_id)
			continue
		var left := int(_enemy_blend_frames[enemy_id])
		EnemyAnimator.apply_blend(_enemy_rects[enemy_id], left)
		if left > 0:
			_enemy_blend_frames[enemy_id] = left - 1
		else:
			_enemy_blend_frames.erase(enemy_id)


## Single time-scale owner: strongest slowdown wins; empty stack restores 1.0.
func juice_time_push(tag: StringName, value: float) -> void:
	_time_tags[tag] = value
	_apply_time_scale()


func juice_time_pop(tag: StringName) -> void:
	_time_tags.erase(tag)
	_apply_time_scale()


func _apply_time_scale() -> void:
	var time_scale := 1.0
	for tag: StringName in _time_tags:
		time_scale = minf(time_scale, float(_time_tags[tag]))
	Engine.time_scale = time_scale


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## item 1 drag hooks — called by the DeployBar adapter
func deploy_drag_started() -> void:
	juice_time_push(&"deploy_drag", cfg.deploy_drag_time_scale)


func deploy_drag_ended() -> void:
	juice_time_pop(&"deploy_drag")


## item 1: landing juice keys off new unit ids (fires for seam deploys too)
func _detect_deploys() -> void:
	for u: UnitState in model.units:
		var crouch_left := int(_deploy_seen.get(u.id, -1))
		if crouch_left == 0:
			continue
		var node: Node2D = _unit_nodes.get(u.id)
		if node == null:
			continue
		var local_center := IsoProjection.face_center(u.cell, _is_lifted_cell(u.cell))
		if crouch_left < 0:
			crouch_left = cfg.deploy_crouch_frames
			_juice.dust(local_center)
			_juice.crouch(node)
			Sfx.play("deploy")
		var next_left := maxi(crouch_left - 1, 0)
		_deploy_seen[u.id] = next_left
		var t := 1.0 - float(next_left) / float(cfg.deploy_crouch_frames)
		var presentation_scale := Vector2(1.0, 0.7).lerp(Vector2.ONE, t)
		var body := node.get_node("Body") as ColorRect
		var unit_rect := Rect2(
			node.position + body.position * presentation_scale,
			body.size * presentation_scale,
		)
		for bar_path: NodePath in [^"HpBarBg", ^"SpBarBg"]:
			var bar := body.get_node_or_null(bar_path) as ColorRect
			if bar != null:
				unit_rect = unit_rect.merge(Rect2(
				node.position + (body.position + bar.position) * presentation_scale,
				bar.size * presentation_scale,
			))
		if _map_nav.ensure_local_rect_visible(unit_rect):
			_apply_map_transform()


## item 3: sparks key off died_at_tick — kill paths only, either faction
func _detect_kills() -> void:
	for e: EnemyState in model.enemies:
		if e.died_at_tick < 0 or _spark_seen.has(e.id):
			continue
		_spark_seen[e.id] = true
		var pos := Pathing.position_of(model.path_for(e.path_idx), e.progress_units)
		_juice.spark(IsoProjection.project(pos + Vector2.ONE * 0.5))
		Sfx.play("kill")


## item 4: vignette + HUD knock + whitelisted shake key off the leak counter
func _detect_leaks() -> void:
	if model.leaked <= _leaked_seen:
		return
	for _i: int in model.leaked - _leaked_seen:
		Sfx.play("leak")
	_leaked_seen = model.leaked
	_juice.vignette()
	if _hud != null:
		_juice.knock(_hud)
	_juice.shake("leak", cfg.leak_shake_amplitude_px, cfg.leak_shake_frames)
	if cfg.leak_hit_stop_frames > 0:
		_hit_stop_frames = cfg.leak_hit_stop_frames


## Wave banner keys off the same boundary used by Charm's once-per-wave rule.
func _detect_wave() -> void:
	var wave := model.spell_book.wave_index_of(model.tick)
	if wave <= _banner_seen_wave:
		return
	_banner_seen_wave = wave
	_juice.banner("WAVE %d" % (wave + 1))
	Sfx.play("wave")


## Terminal stamp is one-shot on result flip, shared with campaign unlock flow.
func _detect_result_stamp() -> void:
	if _stamp_shown or model.result == BattleModel.Result.RUNNING:
		return
	_stamp_shown = true
	Game.record_result(model.result, model.stars)
	if model.result == BattleModel.Result.CLEAR:
		_juice.stamp("CLEAR", model.stars)
		Sfx.play("victory")
	else:
		_juice.stamp("DEFEAT", 0)
		Sfx.play("defeat")
	# a real Button (the juice layer is MOUSE_FILTER_IGNORE territory) under
	# the stamp band; no auto-swap — scenarios and bots must be able to
	# inspect the terminal state (td-phase-10.md §2.6). Every terminal gets
	# one (Phase 13): quick battles used to dead-end on the stamp.
	var next := Button.new()
	next.name = "ContinueButton"
	_continue_btn = next
	next.text = "Continue"
	# Phase 13b prominence: the largest button on screen, focused so Enter
	# (and Space, once terminal) also proceeds — the "what do I click now"
	# fix from the playtest screenshot. HUD z band so it never sinks under
	# the iso grid (td-phase-12).
	next.custom_minimum_size = Vector2(260.0, 64.0)
	next.add_theme_font_size_override("font_size", 40)
	next.z_index = HUD_Z
	add_child(next)
	var viewport := get_viewport_rect().size
	next.position = Vector2(
		(viewport.x - next.get_combined_minimum_size().x) * 0.5, viewport.y * 0.5 + 120.0
	)
	next.pressed.connect(_on_continue_pressed)
	next.grab_focus()


func _on_continue_pressed() -> void:
	Sfx.play("ui_click")
	Game.open_results()


## Trap snap keys off trigger count; final-charge removal uses the adoption path.
func _detect_trap_juice() -> void:
	if model.traps_triggered > _snaps_seen:
		for _i: int in model.traps_triggered - _snaps_seen:
			Sfx.play("trap_snap")
		_snaps_seen = model.traps_triggered
	for t: TrapState in model.traps:
		if (
			t.trigger == TrapDef.Trigger.ON_ENTER
			and t.last_trigger_tick > int(_trap_trigger_seen.get(t.id, -1))
		):
			_trap_trigger_seen[t.id] = t.last_trigger_tick
			var rect: ColorRect = _trap_rects.get(t.id)
			if rect != null:
				_juice.sprung(rect, false)
		elif t.trigger == TrapDef.Trigger.CELL_AURA:
			_shimmer_tar(t)


## item 6: tar shimmer while occupied by a walking ENEMY, static otherwise
func _shimmer_tar(t: TrapState) -> void:
	var rect: ColorRect = _trap_rects.get(t.id)
	if rect == null:
		return
	var occupied := false
	for e: EnemyState in model.enemies:
		if not e.alive or e.aerial or e.faction != EnemyState.Faction.ENEMY:
			continue
		if Pathing.cell_of(model.path_for(e.path_idx), e.progress_units) == t.cell:
			occupied = true
			break
	if occupied:
		rect.modulate = Color(1, 1, 1, 0.55) if _juice.shimmer_on() else Color.WHITE
	else:
		rect.modulate = Color.WHITE


## Charm swirl and ally-blue art both key off the authoritative faction flip.
func _detect_charms() -> void:
	for e: EnemyState in model.enemies:
		if e.faction != EnemyState.Faction.CHARMED or _charm_seen.has(e.id):
			continue
		_charm_seen[e.id] = true
		var pos := Pathing.position_of(model.path_for(e.path_idx), e.progress_units)
		_juice.swirl(IsoProjection.project(pos + Vector2.ONE * 0.5))
		juice_time_push(&"charm_beat", cfg.charm_beat_time_scale)
		_beat_frames_left = cfg.charm_beat_frames
		_juice.shake("charm_beat", cfg.charm_shake_amplitude_px, cfg.charm_shake_frames)
		if cfg.charm_hit_stop_frames > 0:
			_hit_stop_frames = cfg.charm_hit_stop_frames


func _load_enemy_defs(stage: StageDef) -> Dictionary:
	var defs: Dictionary = {}
	for w: Dictionary in stage.waves:
		var enemy_id: StringName = w["enemy_id"]
		if not defs.has(enemy_id):
			defs[enemy_id] = load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
	return defs


## Model validation uses full catalogs; loadout restrictions remain UI-owned.
func _load_catalog(dir_path: String, script_class: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return defs
	for file: String in dir.get_files():
		# exported builds list "<name>.tres.remap" (text->binary conversion);
		# loading by the original .tres path resolves through the remap
		var res_name := file.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + res_name)
			if (
				def != null
				and def.get_script() != null
				and (def.get_script() as Script).get_global_name() == StringName(script_class)
			):
				defs[def.get("id")] = def
	return defs


func _build_grid(stage: StageDef) -> bool:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.color = BACKDROP_COLOR
	_backdrop.z_index = -20
	_backdrop.size = get_viewport_rect().size
	add_child(_backdrop)
	_grid_root = Node2D.new()
	_grid_root.name = "GridRoot"
	var viewport := get_viewport_rect().size
	_map_nav.relayout(stage, viewport)
	_apply_map_transform()
	add_child(_grid_root)
	if not IsoGridBuilder.build_stage_with_theme(_grid_root, stage, _stage_theme):
		return false
	return true


func _apply_map_transform() -> void:
	_grid_scale = _map_nav.scale
	_grid_root.scale = Vector2.ONE * _grid_scale
	_grid_root.position = _map_nav.root_position()
	if _juice != null:
		_juice.refresh_base()


## Refit to the live viewport, clamp pan, then relayout screen-owned UI.
func _relayout() -> void:
	if _stage == null or _grid_root == null:
		return
	var viewport := get_viewport_rect().size
	_map_nav.relayout(_stage, viewport)
	_apply_map_transform()
	if _backdrop != null:
		_backdrop.size = viewport
	BATTLE_HUD_PRESENTER.relayout(_hud, viewport)
	if _portrait_flash != null:
		_portrait_flash.position = Vector2((viewport.x - PORTRAIT_FLASH_PX) * 0.5, 56.0)
	if _continue_btn != null and is_instance_valid(_continue_btn):
		_continue_btn.position = Vector2(
			(viewport.x - _continue_btn.get_combined_minimum_size().x) * 0.5,
			viewport.y * 0.5 + 120.0
		)
	if _deploy_bar != null:
		_deploy_bar.relayout()
	if _spell_bar != null:
		_spell_bar.relayout()
	if _controls != null:
		_controls.relayout()
	if _juice != null:
		_juice.relayout(viewport)


func _build_hud() -> void:
	_hud = BATTLE_HUD_PRESENTER.create(HUD_FONT_SIZE, HUD_Z, get_viewport_rect().size)
	add_child(_hud)


func _project() -> void:
	for e: EnemyState in model.enemies:
		if e.alive and not _enemy_rects.has(e.id):
			_enemy_rects[e.id] = _make_enemy_rect(e)
		elif not e.alive and _enemy_rects.has(e.id):
			_enemy_rects[e.id].queue_free()
			_enemy_rects.erase(e.id)
			_enemy_anim_keys.erase(e.id)
			_enemy_blend_frames.erase(e.id)
		if e.alive:
			var pos := Pathing.position_of(model.path_for(e.path_idx), e.progress_units)
			var center_p := pos + Vector2.ONE * 0.5
			var rect: ColorRect = _enemy_rects[e.id]
			# feet on the face: bottom-center anchored at the projected point
			rect.position = (
				IsoProjection.project(center_p)
				+ Vector2(-rect.size.x * 0.5, IsoProjection.FEET_OFFSET - rect.size.y)
			)
			rect.z_index = IsoProjection.entity_z(center_p)
			EnemyAnimator.refresh(
				e,
				model,
				rect,
				_enemy_anim_seconds,
				_enemy_anim_keys,
				_enemy_blend_frames,
				_enemy_defs
			)
			_update_hp_bar(rect, rect.size.x, e.hp, e.hp_max)
	_project_traps()
	_project_units()
	_project_tracers()
	var s := model.snapshot()
	_hud.text = BATTLE_HUD_PRESENTER.text_for(s, get_viewport_rect().size)
	if int(s["result"]) == BattleModel.Result.CLEAR:
		_hud.text += "  %d*" % int(s["stars"])


## EnemyAnimator owns body art/state/direction/shadow; this view owns HP bars.
func _make_enemy_rect(e: EnemyState) -> ColorRect:
	var rect := EnemyAnimator.make_body(e, model, _enemy_defs)
	_add_hp_bar(rect, rect.size.x)
	_grid_root.add_child(rect)
	return rect


## Traps use distinct cell glyphs and disappear with their model record.
func _project_traps() -> void:
	var live: Dictionary = {}
	for t: TrapState in model.traps:
		live[t.id] = true
		if not _trap_rects.has(t.id):
			_trap_rects[t.id] = _make_trap_rect(t)
	for trap_id: int in _trap_rects.keys():
		if not live.has(trap_id):
			var rect := _trap_rects[trap_id] as ColorRect
			# an ON_ENTER trap only leaves the model by exhausting its final
			# charge — the sprung frame must outlive the model entry (J11),
			# so the juice layer adopts the rect and frees it after
			if int(_trap_kinds.get(trap_id, -1)) == TrapDef.Trigger.ON_ENTER and _juice != null:
				var sprite := rect.get_node_or_null("Sprite") as TextureRect
				var sprung_tex := Art.texture(&"trap_spike_sprung")
				if sprite != null and sprung_tex != null:
					sprite.texture = sprung_tex
				_juice.sprung(rect, true)
			else:
				rect.queue_free()
			_trap_rects.erase(trap_id)


func _make_trap_rect(t: TrapState) -> ColorRect:
	_trap_kinds[t.id] = t.trigger
	var rect := ColorRect.new()
	rect.name = "Trap%d" % t.id
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# traps sit on GROUND path cells only — never lifted
	var face := IsoProjection.face_center(t.cell)
	var art_id := &"trap_tar" if t.trigger == TrapDef.Trigger.CELL_AURA else &"trap_spike_armed"
	var tex := Art.texture(art_id)
	if tex != null:
		rect.color = Color(0, 0, 0, 0)
		var art_size := Art.size(art_id)
		if art_size == Vector2i.ZERO:
			art_size = Vector2i(tex.get_width(), tex.get_height())
		rect.size = Vector2(art_size) * SPRITE_SCALE
		rect.position = face - rect.size * 0.5
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture = tex
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.size = rect.size
		rect.add_child(sprite)
	elif t.trigger == TrapDef.Trigger.CELL_AURA:
		rect.color = TAR_OVERLAY_COLOR
		rect.size = Vector2(IsoProjection.TILE_W - 2.0, IsoProjection.TILE_H - 2.0)
		rect.position = face - rect.size * 0.5
	else:
		rect.color = TRAP_SPIKE_COLOR
		rect.size = Vector2.ONE * TRAP_SPIKE_PX
		rect.position = face - rect.size * 0.5
		var core := ColorRect.new()
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		core.color = TRAP_SPIKE_CORE
		core.size = Vector2.ONE * (TRAP_SPIKE_PX * 0.35)
		core.position = (rect.size - core.size) * 0.5
		rect.add_child(core)
	rect.z_index = IsoProjection.tile_z(t.cell) + 1
	_grid_root.add_child(rect)
	return rect


## Ranged attacks leave a short-lived unit-to-target tracer.
func _project_tracers() -> void:
	for u: UnitState in model.units:
		var is_ranged := (
			u.op_class == OperatorDef.OpClass.SNIPER or u.op_class == OperatorDef.OpClass.CASTER
		)
		if not is_ranged:
			continue
		if (
			u.alive
			and u.last_attack_tick >= 0
			and u.last_attack_tick != int(_tracer_seen_tick.get(u.id, -1))
		):
			_tracer_seen_tick[u.id] = u.last_attack_tick
			_tracer_frames_left[u.id] = cfg.tracer_frames
			var line: Line2D = _tracer_lines.get(u.id)
			if line == null:
				line = Line2D.new()
				line.width = 3.0
				line.default_color = TRACER_COLOR
				_grid_root.add_child(line)
				_tracer_lines[u.id] = line
			# depth from the shooter's cell (td-phase-12 pin)
			line.z_index = IsoProjection.entity_z(Vector2(u.cell) + Vector2.ONE * 0.5)
			line.points = PackedVector2Array(
				[
					IsoProjection.face_center(u.cell, _is_lifted_cell(u.cell)),
					IsoProjection.face_center(u.last_attack_cell),
				]
			)
		# aging happens in _process (rule 10, P14) — here we only project
		if _tracer_lines.has(u.id):
			(_tracer_lines[u.id] as Line2D).visible = int(_tracer_frames_left.get(u.id, 0)) > 0


func _project_units() -> void:
	for u: UnitState in model.units:
		if u.alive and not _unit_nodes.has(u.id):
			_unit_nodes[u.id] = _make_unit_node(u)
		elif not u.alive and _unit_nodes.has(u.id):
			_unit_nodes[u.id].queue_free()
			_unit_nodes.erase(u.id)
		if u.alive:
			var body := (_unit_nodes[u.id] as Node2D).get_node("Body") as ColorRect
			_refresh_unit_sprite(u, body)
			_update_hp_bar(body, body.size.x, u.hp, u.hp_max)
			_update_sp_bar(body, u)
		_detect_skill_trigger(u)


## Admitted templates animate; legacy sprites retain pinned bob/attack frames.
func _refresh_unit_sprite(u: UnitState, body: ColorRect) -> void:
	var sprite := body.get_node_or_null("Sprite") as TextureRect
	if sprite == null:
		return
	var animation := OPERATOR_VISUAL_CATALOG_SCRIPT.get_animation(u.op_id)
	var animated := (
		animation != null
		and OPERATOR_ANIMATOR_SCRIPT.apply(u, model.tick, _enemy_anim_seconds, sprite, animation)
	)
	if animated:
		return
	var def: OperatorDef = _op_defs.get(u.op_id)
	if def == null:
		return
	if u.last_attack_tick >= 0 and u.last_attack_tick != int(_unit_attack_seen.get(u.id, -1)):
		_unit_attack_seen[u.id] = u.last_attack_tick
		_attack_pose_left[u.id] = ATTACK_POSE_FRAMES
	# aging happens in _process (rule 10, P14) — here we only pick the frame
	var frame := 0
	if int(_attack_pose_left.get(u.id, 0)) > 0:
		frame = 2
	else:
		frame = (Engine.get_process_frames() / IDLE_BOB_FRAMES + u.id) % 2
	var tex := Art.texture(def.sprite_id, frame)
	if tex != null and sprite.texture != tex:
		sprite.texture = tex


## SP pip fills toward cost and flashes while ready.
func _update_sp_bar(body: ColorRect, u: UnitState) -> void:
	if u.sp_cost <= 0:
		return
	var fill := body.get_node("SpBarBg/SpBarFill") as ColorRect
	fill.size.x = body.size.x * clampf(float(u.sp) / float(u.sp_cost), 0.0, 1.0)
	# readiness from the verb's own validator (rule 7, P14)
	if u.is_skill_ready():
		var blink := (Engine.get_process_frames() / 8) % 2 == 0
		fill.color = SP_FULL_FLASH if blink else SP_BAR_FILL
	else:
		fill.color = SP_BAR_FILL


## Skill trigger flashes the portrait, bursts at the unit, and plays its sting.
func _detect_skill_trigger(u: UnitState) -> void:
	var seen := int(_skill_seen_tick.get(u.id, -1))
	if u.skill_triggered_tick <= seen:
		return
	_skill_seen_tick[u.id] = u.skill_triggered_tick
	Sfx.play(String(u.skill_id))
	if _juice != null:
		if u.skill_effect == SkillDef.Effect.HEAL_TARGET and u.skill_target_unit_id >= 0:
			var target := model.unit_by_id(u.skill_target_unit_id)
			if target != null:
				_juice.heal_burst(
					IsoProjection.face_center(target.cell, _is_lifted_cell(target.cell))
				)
		else:
			_juice.skill_burst(IsoProjection.face_center(u.cell, _is_lifted_cell(u.cell)))
	var def: OperatorDef = _op_defs.get(u.op_id)
	var op_class := def.op_class if def != null else OperatorDef.OpClass.GUARD
	_portrait_flash.color = BattlePalette.OPERATOR_CLASS[op_class]
	_portrait_flash.visible = true
	_portrait_flash_frames = cfg.skill_flash_frames


func _add_hp_bar(body: ColorRect, width: float) -> void:
	var bg := ColorRect.new()
	bg.name = "HpBarBg"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = HP_BAR_BG
	bg.size = Vector2(width, HP_BAR_HEIGHT)
	bg.position = Vector2(0, -HP_BAR_HEIGHT - 3.0)
	body.add_child(bg)
	var fill := ColorRect.new()
	fill.name = "HpBarFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = HP_BAR_FILL
	fill.size = Vector2(width, HP_BAR_HEIGHT)
	bg.add_child(fill)


func _update_hp_bar(body: ColorRect, width: float, hp: int, hp_max: int) -> void:
	var fill := body.get_node("HpBarBg/HpBarFill") as ColorRect
	fill.size.x = width * clampf(float(hp) / float(maxi(hp_max, 1)), 0.0, 1.0)


func _add_sp_bar(body: ColorRect) -> void:
	var bg := ColorRect.new()
	bg.name = "SpBarBg"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = SP_BAR_BG
	bg.size = Vector2(body.size.x, HP_BAR_HEIGHT)
	bg.position = Vector2(0, body.size.y + 3.0)
	body.add_child(bg)
	var fill := ColorRect.new()
	fill.name = "SpBarFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = SP_BAR_FILL
	fill.size = Vector2(0, HP_BAR_HEIGHT)
	bg.add_child(fill)


func _make_unit_node(u: UnitState) -> Node2D:
	var node := Node2D.new()
	node.position = IsoProjection.face_center(u.cell, _is_lifted_cell(u.cell))
	node.z_index = IsoProjection.entity_z(Vector2(u.cell) + Vector2.ONE * 0.5)
	var rect := ColorRect.new()
	rect.name = "Body"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var def: OperatorDef = _op_defs.get(u.op_id)
	var op_class := def.op_class if def != null else OperatorDef.OpClass.GUARD
	var animation := OPERATOR_VISUAL_CATALOG_SCRIPT.get_animation(u.op_id)
	var direction := OPERATOR_ANIMATOR_SCRIPT.direction_for_facing(u.facing)
	var animation_id := (
		StringName(animation.idle_by_direction.get(direction, &"")) if animation != null else &""
	)
	var tex := Art.texture(animation_id, 0) if not animation_id.is_empty() else null
	var animated := tex != null and animation != null
	if not animated:
		tex = Art.texture(def.sprite_id, 0) if def != null else null
	if tex != null:
		rect.color = Color(0, 0, 0, 0)
		rect.size = (
			OPERATOR_ANIMATOR_SCRIPT.body_size(animation)
			if animated
			else Vector2.ONE * (tex.get_width() * SPRITE_SCALE)
		)
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture = tex
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.size = rect.size
		sprite.flip_h = false if animated else u.facing == UnitState.Facing.LEFT
		rect.add_child(sprite)
		if animated:
			rect.set_meta(&"operator_animation", true)
			rect.set_meta(&"operator_template_id", u.op_id)
	else:
		rect.color = BattlePalette.OPERATOR_CLASS[op_class]
		rect.size = Vector2(UNIT_PX, UNIT_PX)
	# feet on the face: admitted animation cells carry a normalized 0.94 pivot;
	# legacy sprites remain bottom-center anchored exactly as before.
	var pivot_y := animation.pivot.y if animated else 1.0
	rect.position = Vector2(-rect.size.x * 0.5, IsoProjection.FEET_OFFSET - rect.size.y * pivot_y)
	EnemyAnimator.add_shadow(rect, false)
	_add_hp_bar(rect, rect.size.x)
	if u.sp_cost > 0:
		_add_sp_bar(rect)
	node.add_child(rect)
	var chevron := Polygon2D.new()
	chevron.color = CHEVRON_COLOR
	chevron.polygon = PackedVector2Array([Vector2(-5, -7), Vector2(-5, 7), Vector2(7, 0)])
	# grid-cardinal facing projected into iso screen space: the arrow points
	# along the grid axis, not the screen axis (td-phase-12 pin)
	var dir := IsoProjection.project(Vector2.RIGHT.rotated(u.facing * PI * 0.5)).normalized()
	chevron.position = dir * (maxf(UNIT_PX, rect.size.x) * 0.5 + 6.0)
	chevron.rotation = dir.angle()
	node.add_child(chevron)
	_grid_root.add_child(node)
	return node


func _push_telemetry() -> void:
	Telemetry.current_tick = model.tick
	var s := model.snapshot()
	for counter_name: String in _pushed:
		var value := int(s[_pushed[counter_name]])
		var delta := value - int(_pushed_last.get(counter_name, 0))
		if delta > 0:
			Telemetry.count(counter_name, delta)
			_pushed_last[counter_name] = value
	_push_spell_telemetry()
	Telemetry.sample("base_hp", float(model.base_hp))
	Telemetry.sample("dp", float(model.dp))
	if model.result != BattleModel.Result.RUNNING and not _result_reported:
		_result_reported = true
		Telemetry.event("result", {"result": model.result, "stars": model.stars})


## Spell counters/SFX and charm lifecycle events are projected per cast.
func _push_spell_telemetry() -> void:
	for spell_id: StringName in model.spell_book.ids:
		var casts := model.spell_book.casts(spell_id)
		var delta := casts - int(_spell_casts_last.get(spell_id, 0))
		if delta > 0:
			_spell_casts_last[spell_id] = casts
			Telemetry.count("spells_cast_%s" % spell_id, delta)
			Sfx.play(String(spell_id))
	var transitions := {
		"charm_convert": model.charmed,
		"charm_dead": model.charmed_dead,
		"charm_exit": model.charmed_exited,
	}
	for event_name: String in transitions:
		var value := int(transitions[event_name])
		if value > int(_charm_events_last.get(event_name, 0)):
			_charm_events_last[event_name] = value
			Telemetry.event(event_name, {"count": value})
