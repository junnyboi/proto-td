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
const OP_CLASS_COLORS := {
	OperatorDef.OpClass.VANGUARD: Color("38b764"),
	OperatorDef.OpClass.GUARD: Color("a7f070"),
	OperatorDef.OpClass.DEFENDER: Color("257179"),
	OperatorDef.OpClass.SNIPER: Color("ffcd75"),
	OperatorDef.OpClass.CASTER: Color("5d275d"),
}
const CHEVRON_COLOR := Color("f4f4f4")

var model: BattleModel = null
var ticks_per_frame_scale: float = 1.0

var _grid_root: Node2D = null
var _enemy_rects: Dictionary = {}
var _unit_nodes: Dictionary = {}
var _tracer_lines: Dictionary = {}
var _tracer_seen_tick: Dictionary = {}
var _tracer_frames_left: Dictionary = {}
var _op_defs: Dictionary = {}
var _hud: Label = null
var _tick_accum: float = 0.0
var _pushed: Dictionary = {
	"enemies_spawned": "spawned",
	"enemies_leaked": "leaked",
	"enemies_killed": "killed",
	"deploys": "deploys",
	"retreats": "retreated",
	"dp_spent": "dp_spent",
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
	model = BattleModel.create(stage, Game.default_squad, Game.run_seed, config, defs, _op_defs)
	Game.current_battle = model
	Game.content = self
	_build_grid(stage)
	_build_hud()
	var bar := DeployBar.new()
	bar.name = "DeployBar"
	add_child(bar)
	bar.setup(model, self, _op_defs)


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
			_update_hp_bar(rect, rect.size.x, e.hp, e.hp_max)
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
	Telemetry.sample("base_hp", float(model.base_hp))
	Telemetry.sample("dp", float(model.dp))
	if model.result != BattleModel.Result.RUNNING and not _result_reported:
		_result_reported = true
		Telemetry.event("result", {"result": model.result, "stars": model.stars})
