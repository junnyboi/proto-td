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
const UNIT_PX := 44.0
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
			var rect := ColorRect.new()
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.color = ENEMY_COLOR
			rect.size = Vector2(ENEMY_PX, ENEMY_PX)
			_grid_root.add_child(rect)
			_enemy_rects[e.id] = rect
		elif not e.alive and _enemy_rects.has(e.id):
			_enemy_rects[e.id].queue_free()
			_enemy_rects.erase(e.id)
		if e.alive:
			var pos := Pathing.position_of(model.path_for(e.path_idx), e.progress_units)
			var rect: ColorRect = _enemy_rects[e.id]
			rect.position = (pos + Vector2.ONE * 0.5) * TILE_PX - rect.size * 0.5
	_project_units()
	var s := model.snapshot()
	var result_text: String = ["RUNNING", "CLEAR", "DEFEAT"][int(s["result"])]
	_hud.text = "Base HP %d   DP %d   tick %d   %s" % [
		s["base_hp"], s["dp"], s["tick"], result_text,
	]
	if int(s["result"]) == BattleModel.Result.CLEAR:
		_hud.text += "  %d*" % int(s["stars"])


func _project_units() -> void:
	for u: UnitState in model.units:
		if u.alive and not _unit_nodes.has(u.id):
			_unit_nodes[u.id] = _make_unit_node(u)
		elif not u.alive and _unit_nodes.has(u.id):
			_unit_nodes[u.id].queue_free()
			_unit_nodes.erase(u.id)


func _make_unit_node(u: UnitState) -> Node2D:
	var node := Node2D.new()
	node.position = (Vector2(u.cell) + Vector2.ONE * 0.5) * TILE_PX
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var def: OperatorDef = _op_defs.get(u.op_id)
	var op_class := def.op_class if def != null else OperatorDef.OpClass.GUARD
	rect.color = OP_CLASS_COLORS[op_class]
	rect.size = Vector2(UNIT_PX, UNIT_PX)
	rect.position = -rect.size * 0.5
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
