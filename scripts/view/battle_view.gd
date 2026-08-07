extends Node2D

## Disposable projection of BattleModel (architecture rules 1 + 6: view
## reads, never writes). Consumes model ticks in _physics_process via an
## accumulator; ticks_per_frame_scale is the Phase 8 speed-control seam
## (pause/2x/4x = ticks consumed per frame — speed can never change
## outcomes). Phase 1 renders ColorRect placeholders; Lane A sprites replace
## them via the asset manifest without touching this flow.

const TILE_PX := 64.0
const ENEMY_PX := 40.0
const HUD_FONT_SIZE := 32

const TILE_COLORS := {
	StageDef.Tile.VOID: Color("1a1c2c"),
	StageDef.Tile.GROUND: Color("566c86"),
	StageDef.Tile.ELEVATED: Color("94b0c2"),
	StageDef.Tile.SPAWN: Color("b13e53"),
	StageDef.Tile.BASE: Color("3b5dc9"),
	StageDef.Tile.BLOCKED: Color("333c57"),
}
const ENEMY_COLOR := Color("ef7d57")
const ENEMY_TYPE_COLORS := {
	&"grunt": Color("ef7d57"),
	&"runner": Color("f4d35e"),
	&"heavy": Color("b13e53"),
	&"drone": Color("73eff7"),
	&"spellcaster": Color("c964cf"),
	&"mini_boss": Color("94216a"),
}
const AERIAL_PX := 24.0
const AERIAL_SHADOW_OFFSET := Vector2(2.0, 2.0)
const AERIAL_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.45)
const TRACER_COLOR := Color("f4f4f4")
const TRACER_FRAMES := 4
const UNIT_PX := 44.0
const HP_BAR_HEIGHT := 5.0
const HP_BAR_BG := Color("3a2026")
const HP_BAR_FILL := Color("a7f070")
const SP_BAR_BG := Color("20263a")
const SP_BAR_FILL := Color("f4b41b")
const SP_FULL_FLASH := Color("f4f4f4")
const PORTRAIT_FLASH_PX := 96.0
const PORTRAIT_FLASH_FRAMES := 24
const OP_CLASS_COLORS := {
	OperatorDef.OpClass.VANGUARD: Color("38b764"),
	OperatorDef.OpClass.GUARD: Color("a7f070"),
	OperatorDef.OpClass.DEFENDER: Color("257179"),
	OperatorDef.OpClass.SNIPER: Color("ffcd75"),
	OperatorDef.OpClass.CASTER: Color("5d275d"),
}
const CHEVRON_COLOR := Color("f4f4f4")
const CHARMED_COLOR := Color("41a6f6")
const TRAP_SPIKE_COLOR := Color("f4b41b")
const TRAP_SPIKE_CORE := Color("1a1c2c")
const TRAP_SPIKE_PX := 24.0
const TAR_OVERLAY_COLOR := Color(0.08, 0.05, 0.14, 0.6)

var model: BattleModel = null
var ticks_per_frame_scale: float = 1.0

var _grid_root: Node2D = null
var _enemy_rects: Dictionary = {}
var _unit_nodes: Dictionary = {}
var _tracer_lines: Dictionary = {}
var _tracer_seen_tick: Dictionary = {}
var _tracer_frames_left: Dictionary = {}
var _skill_seen_tick: Dictionary = {}
var _portrait_flash: ColorRect = null
var _portrait_flash_frames := 0
var _op_defs: Dictionary = {}
var _trap_defs: Dictionary = {}
var _spell_defs: Dictionary = {}
var _trap_rects: Dictionary = {}
var _spell_casts_last: Dictionary = {}
var _charm_events_last: Dictionary = {}
var _hud: Label = null
var _tick_accum: float = 0.0
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


func _ready() -> void:
	var stage := Game.pending_stage
	if stage == null:
		push_error("battle_view: no pending stage")
		return
	var config := load("res://data/config/game.tres") as GameConfig
	var defs := _load_enemy_defs(stage)
	_op_defs = _load_operator_defs(Game.default_squad)
	_trap_defs = _load_catalog("res://data/traps", "TrapDef")
	_spell_defs = _load_catalog("res://data/spells", "SpellDef")
	model = BattleModel.create(
		stage, Game.default_squad, Game.run_seed, config, defs, _op_defs, _trap_defs, _spell_defs
	)
	Game.current_battle = model
	Game.content = self
	_build_grid(stage)
	_build_hud()
	_portrait_flash = ColorRect.new()
	_portrait_flash.name = "PortraitFlash"
	_portrait_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_flash.size = Vector2.ONE * PORTRAIT_FLASH_PX
	_portrait_flash.position = Vector2(
		(get_viewport_rect().size.x - PORTRAIT_FLASH_PX) * 0.5, 56.0
	)
	_portrait_flash.visible = false
	add_child(_portrait_flash)
	var bar := DeployBar.new()
	bar.name = "DeployBar"
	add_child(bar)
	bar.setup(model, self, _op_defs, _trap_defs)
	var spells := SpellBar.new()
	spells.name = "SpellBar"
	add_child(spells)
	spells.setup(model, self)


## Screen-space center of a grid cell (no camera: world == screen). The
## deploy adapter and scenarios use these instead of assuming a zero origin.
func cell_center(cell: Vector2i) -> Vector2:
	return _grid_root.position + (Vector2(cell) + Vector2.ONE * 0.5) * TILE_PX


func cell_at(screen_pos: Vector2) -> Vector2i:
	return Vector2i(((screen_pos - _grid_root.position) / TILE_PX).floor())


func _physics_process(delta: float) -> void:
	if model == null:
		return
	_tick_accum += delta * model.config.ticks_per_second * ticks_per_frame_scale
	while _tick_accum >= 1.0:
		_tick_accum -= 1.0
		model.step()
		_push_telemetry()
	_project()


func _load_enemy_defs(stage: StageDef) -> Dictionary:
	var defs: Dictionary = {}
	for w: Dictionary in stage.waves:
		var enemy_id: StringName = w["enemy_id"]
		if not defs.has(enemy_id):
			defs[enemy_id] = load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
	return defs


## Full catalogs by directory scan — the model validates against the
## catalog, not a loadout (td-phase-6-7.md §2.1); Phase 10 gates loadouts
## in the UI.
func _load_catalog(dir_path: String, script_class: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return defs
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			if def != null and def.get_script() != null \
					and (def.get_script() as Script).get_global_name() == StringName(script_class):
				defs[def.get("id")] = def
	return defs


func _load_operator_defs(squad: Array[StringName]) -> Dictionary:
	var defs: Dictionary = {}
	for op_id: StringName in squad:
		var path := "res://data/operators/%s.tres" % op_id
		if ResourceLoader.exists(path):
			defs[op_id] = load(path) as OperatorDef
	return defs


func _build_grid(stage: StageDef) -> void:
	_grid_root = Node2D.new()
	_grid_root.name = "GridRoot"
	var size := stage.grid_size()
	var viewport := get_viewport_rect().size
	_grid_root.position = (viewport - Vector2(size) * TILE_PX) * 0.5
	add_child(_grid_root)
	for y: int in size.y:
		for x: int in size.x:
			var tile := stage.tile_at(Vector2i(x, y))
			var rect := ColorRect.new()
			# projection only: never intercept GUI input meant for the grid
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.color = TILE_COLORS[tile]
			rect.position = Vector2(x, y) * TILE_PX + Vector2.ONE
			rect.size = Vector2(TILE_PX, TILE_PX) - Vector2.ONE * 2.0
			_grid_root.add_child(rect)


func _build_hud() -> void:
	_hud = Label.new()
	_hud.name = "BattleHud"
	_hud.position = Vector2(16, 8)
	_hud.add_theme_font_size_override("font_size", HUD_FONT_SIZE)
	add_child(_hud)


func _project() -> void:
	for e: EnemyState in model.enemies:
		if e.alive and not _enemy_rects.has(e.id):
			_enemy_rects[e.id] = _make_enemy_rect(e)
		elif not e.alive and _enemy_rects.has(e.id):
			_enemy_rects[e.id].queue_free()
			_enemy_rects.erase(e.id)
		if e.alive:
			var pos := Pathing.position_of(model.path_for(e.path_idx), e.progress_units)
			var rect: ColorRect = _enemy_rects[e.id]
			rect.position = (pos + Vector2.ONE * 0.5) * TILE_PX - rect.size * 0.5
			if e.faction == EnemyState.Faction.CHARMED:
				rect.color = CHARMED_COLOR
			_update_hp_bar(rect, rect.size.x, e.hp, e.hp_max)
	_project_traps()
	_project_units()
	_project_tracers()
	var s := model.snapshot()
	var result_text: String = ["RUNNING", "CLEAR", "DEFEAT"][int(s["result"])]
	_hud.text = "Base HP %d   DP %d   kills %d   tick %d   %s" % [
		s["base_hp"], s["dp"], s["killed"], s["tick"], result_text,
	]
	if int(s["result"]) == BattleModel.Result.CLEAR:
		_hud.text += "  %d*" % int(s["stars"])


## Enemy rects are colored per type; aerial enemies render smaller with an
## offset shadow behind the body so they read as airborne over a blocker.
func _make_enemy_rect(e: EnemyState) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = ENEMY_TYPE_COLORS.get(e.def_id, ENEMY_COLOR)
	var body_px := AERIAL_PX if e.aerial else ENEMY_PX
	rect.size = Vector2(body_px, body_px)
	if e.aerial:
		var shadow := ColorRect.new()
		shadow.name = "AerialShadow"
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.color = AERIAL_SHADOW_COLOR
		shadow.size = rect.size
		shadow.position = AERIAL_SHADOW_OFFSET
		shadow.show_behind_parent = true
		rect.add_child(shadow)
	_add_hp_bar(rect, body_px)
	_grid_root.add_child(rect)
	return rect


## Traps project as cell glyphs: armed spike = amber plate with a dark core
## (visibly distinct from 44px units and full tiles), tar = dark translucent
## overlay covering the cell. A trap removed from the model (exhausted
## charges) drops its node the same frame.
func _project_traps() -> void:
	var live: Dictionary = {}
	for t: TrapState in model.traps:
		live[t.id] = true
		if not _trap_rects.has(t.id):
			_trap_rects[t.id] = _make_trap_rect(t)
	for trap_id: int in _trap_rects.keys():
		if not live.has(trap_id):
			(_trap_rects[trap_id] as ColorRect).queue_free()
			_trap_rects.erase(trap_id)


func _make_trap_rect(t: TrapState) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cell_origin := Vector2(t.cell) * TILE_PX
	if t.trigger == TrapDef.Trigger.CELL_AURA:
		rect.color = TAR_OVERLAY_COLOR
		rect.size = Vector2.ONE * (TILE_PX - 2.0)
		rect.position = cell_origin + Vector2.ONE
	else:
		rect.color = TRAP_SPIKE_COLOR
		rect.size = Vector2.ONE * TRAP_SPIKE_PX
		rect.position = cell_origin + Vector2.ONE * ((TILE_PX - TRAP_SPIKE_PX) * 0.5)
		var core := ColorRect.new()
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		core.color = TRAP_SPIKE_CORE
		core.size = Vector2.ONE * (TRAP_SPIKE_PX * 0.35)
		core.position = (rect.size - core.size) * 0.5
		rect.add_child(core)
	_grid_root.add_child(rect)
	return rect


## Ranged attacks leave a short-lived tracer line unit -> target cell (a
## checkable pixel for "the sniper shot the drone").
func _project_tracers() -> void:
	for u: UnitState in model.units:
		var is_ranged := (
			u.op_class == OperatorDef.OpClass.SNIPER or u.op_class == OperatorDef.OpClass.CASTER
		)
		if not is_ranged:
			continue
		if u.alive and u.last_attack_tick >= 0 \
				and u.last_attack_tick != int(_tracer_seen_tick.get(u.id, -1)):
			_tracer_seen_tick[u.id] = u.last_attack_tick
			_tracer_frames_left[u.id] = TRACER_FRAMES
			var line: Line2D = _tracer_lines.get(u.id)
			if line == null:
				line = Line2D.new()
				line.width = 3.0
				line.default_color = TRACER_COLOR
				_grid_root.add_child(line)
				_tracer_lines[u.id] = line
			line.points = PackedVector2Array([
				(Vector2(u.cell) + Vector2.ONE * 0.5) * TILE_PX,
				(Vector2(u.last_attack_cell) + Vector2.ONE * 0.5) * TILE_PX,
			])
		var frames_left := int(_tracer_frames_left.get(u.id, 0))
		if _tracer_lines.has(u.id):
			(_tracer_lines[u.id] as Line2D).visible = frames_left > 0
		if frames_left > 0:
			_tracer_frames_left[u.id] = frames_left - 1


func _project_units() -> void:
	for u: UnitState in model.units:
		if u.alive and not _unit_nodes.has(u.id):
			_unit_nodes[u.id] = _make_unit_node(u)
		elif not u.alive and _unit_nodes.has(u.id):
			_unit_nodes[u.id].queue_free()
			_unit_nodes.erase(u.id)
		if u.alive:
			var body := (_unit_nodes[u.id] as Node2D).get_node("Body") as ColorRect
			_update_hp_bar(body, UNIT_PX, u.hp, u.hp_max)
			_update_sp_bar(body, u)
		_detect_skill_trigger(u)
	if _portrait_flash_frames > 0:
		_portrait_flash_frames -= 1
		if _portrait_flash_frames == 0 and _portrait_flash != null:
			_portrait_flash.visible = false


## SP pip under the unit: fills toward sp_cost, flashes while full (the
## trigger-ready state is a checkable pixel).
func _update_sp_bar(body: ColorRect, u: UnitState) -> void:
	if u.sp_cost <= 0:
		return
	var fill := body.get_node("SpBarBg/SpBarFill") as ColorRect
	fill.size.x = UNIT_PX * clampf(float(u.sp) / float(u.sp_cost), 0.0, 1.0)
	if u.sp == u.sp_cost:
		var blink := (Engine.get_process_frames() / 8) % 2 == 0
		fill.color = SP_FULL_FLASH if blink else SP_BAR_FILL
	else:
		fill.color = SP_BAR_FILL


## A trigger flashes a portrait-placeholder quad (class-colored, top center)
## and emits the sfx_played wiring event (audible SFX is Phase 9 / Lane A).
func _detect_skill_trigger(u: UnitState) -> void:
	var seen := int(_skill_seen_tick.get(u.id, -1))
	if u.skill_triggered_tick <= seen:
		return
	_skill_seen_tick[u.id] = u.skill_triggered_tick
	Telemetry.event("sfx_played", {"id": String(u.skill_id)})
	var def: OperatorDef = _op_defs.get(u.op_id)
	var op_class := def.op_class if def != null else OperatorDef.OpClass.GUARD
	_portrait_flash.color = OP_CLASS_COLORS[op_class]
	_portrait_flash.visible = true
	_portrait_flash_frames = PORTRAIT_FLASH_FRAMES


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
	bg.size = Vector2(UNIT_PX, HP_BAR_HEIGHT)
	bg.position = Vector2(0, UNIT_PX + 3.0)
	body.add_child(bg)
	var fill := ColorRect.new()
	fill.name = "SpBarFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = SP_BAR_FILL
	fill.size = Vector2(0, HP_BAR_HEIGHT)
	bg.add_child(fill)


func _make_unit_node(u: UnitState) -> Node2D:
	var node := Node2D.new()
	node.position = (Vector2(u.cell) + Vector2.ONE * 0.5) * TILE_PX
	var rect := ColorRect.new()
	rect.name = "Body"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var def: OperatorDef = _op_defs.get(u.op_id)
	var op_class := def.op_class if def != null else OperatorDef.OpClass.GUARD
	rect.color = OP_CLASS_COLORS[op_class]
	rect.size = Vector2(UNIT_PX, UNIT_PX)
	rect.position = -rect.size * 0.5
	_add_hp_bar(rect, UNIT_PX)
	if u.sp_cost > 0:
		_add_sp_bar(rect)
	node.add_child(rect)
	var chevron := Polygon2D.new()
	chevron.color = CHEVRON_COLOR
	chevron.polygon = PackedVector2Array([Vector2(-5, -7), Vector2(-5, 7), Vector2(7, 0)])
	chevron.position = Vector2.RIGHT.rotated(u.facing * PI * 0.5) * (UNIT_PX * 0.5 + 6.0)
	chevron.rotation = u.facing * PI * 0.5
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


## Per-spell cast counters + the Phase 9 wiring events: sfx_played fires at
## each cast, and each charm lifecycle transition emits its own event.
func _push_spell_telemetry() -> void:
	for spell_id: StringName in model.spell_book.ids:
		var casts := model.spell_book.casts(spell_id)
		var delta := casts - int(_spell_casts_last.get(spell_id, 0))
		if delta > 0:
			_spell_casts_last[spell_id] = casts
			Telemetry.count("spells_cast_%s" % spell_id, delta)
			Telemetry.event("sfx_played", {"id": String(spell_id)})
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
