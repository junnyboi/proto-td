class_name BattleModel
extends RefCounted

## The battle is a database; the engine is a view (architecture rules 1-3).
## Authoritative state is plain integer data, stepped one tick at a time,
## engine-independent and RNG-free (v1) — entire battles run inside GUT.
##
## Tick order inside _step_one (pinned in td-phase-0-1.md §4.3): advance
## alive enemies + resolve leaks FIRST, then spawn due wave entries, then
## evaluate terminal state. An enemy spawned at tick T takes its first step
## at tick T+1, so its leak tick is exactly spawn_tick + ceil(len/step).
##
## A battle is fully described by (stage_id, squad, seed, [[tick, verb,
## args...]]) — that tuple is the replay format, the bot format, and the
## test format. Phase 1 has no verbs yet; apply_action reserves the seam.
##
## Adding a mutable field here without extending state_hash() is a defect
## (CLAUDE.md ban list).

enum Result { RUNNING, CLEAR, DEFEAT }

var stage: StageDef = null
var squad: Array[StringName] = []
var run_seed: int = 0
var config: GameConfig = null

var tick: int = 0
var base_hp: int = 0
var result: Result = Result.RUNNING
var stars: int = 0
var spawned: int = 0
var leaked: int = 0
var killed: int = 0
var enemies: Array[EnemyState] = []
var timeline: WaveTimeline = null

var _defs: Dictionary = {}
var _paths: Array = []
var _path_lengths: Array[int] = []
var _next_enemy_id: int = 0


static func create(
	stage_def: StageDef,
	squad_ids: Array[StringName],
	seed_value: int,
	game_config: GameConfig,
	enemy_defs: Dictionary,
) -> BattleModel:
	var model := BattleModel.new()
	model.stage = stage_def
	model.squad = squad_ids.duplicate()
	model.run_seed = seed_value
	model.config = game_config
	model.base_hp = game_config.base_hp_start
	model._defs = enemy_defs
	model.timeline = WaveTimeline.from_waves(stage_def.waves)
	for i: int in stage_def.paths.size():
		var cells := stage_def.path_cells(i)
		model._paths.append(cells)
		model._path_lengths.append(Pathing.length_units(cells))
	return model


func step(n: int = 1) -> void:
	for _i: int in n:
		_step_one()


## Runs a scripted action timeline (replay/bot/test format) up to until_tick.
func run_timeline(actions: Array, until_tick: int) -> void:
	var sorted := actions.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var idx := 0
	while tick < until_tick and result == Result.RUNNING:
		while idx < sorted.size() and int(sorted[idx][0]) == tick:
			var entry: Array = sorted[idx]
			apply_action(entry.slice(1))
			idx += 1
		step()


func run_to_terminal(max_ticks: int) -> void:
	while result == Result.RUNNING and tick < max_ticks:
		step()


## Verb dispatcher (architecture rule 3). Phase 1 knows zero verbs; deploy/
## retreat/trigger_skill/place_trap/cast arrive in Phases 2-7. Returns false
## (state untouched) for anything unknown.
func apply_action(action: Array) -> bool:
	if action.is_empty():
		return false
	push_warning("apply_action: unknown verb '%s'" % [action[0]])
	return false


func alive_count() -> int:
	var n := 0
	for e: EnemyState in enemies:
		if e.alive:
			n += 1
	return n


func path_for(path_idx: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = _paths[path_idx]
	return cells


## FNV-1a 64-bit over the canonical field order (ints only). Every mutable
## model field appears here.
func state_hash() -> int:
	var bytes := PackedByteArray()
	_append_int(bytes, tick)
	_append_int(bytes, base_hp)
	_append_int(bytes, result)
	_append_int(bytes, stars)
	_append_int(bytes, spawned)
	_append_int(bytes, leaked)
	_append_int(bytes, killed)
	_append_int(bytes, timeline.next_index)
	for e: EnemyState in enemies:
		_append_int(bytes, e.id)
		_append_int(bytes, e.def_id.hash())
		_append_int(bytes, e.path_idx)
		_append_int(bytes, e.progress_units)
		_append_int(bytes, e.hp)
		_append_int(bytes, 1 if e.alive else 0)
	return _fnv1a64(bytes)


## Debug/telemetry projection (views read this; the hash does not).
func snapshot() -> Dictionary:
	return {
		"tick": tick,
		"base_hp": base_hp,
		"result": result,
		"stars": stars,
		"spawned": spawned,
		"leaked": leaked,
		"killed": killed,
		"alive": alive_count(),
	}


func _step_one() -> void:
	if result != Result.RUNNING:
		return
	for e: EnemyState in enemies:
		if not e.alive:
			continue
		e.progress_units += e.step_units
		if e.progress_units >= _path_lengths[e.path_idx]:
			e.alive = false
			leaked += 1
			base_hp -= e.leak_damage
	for entry: Dictionary in timeline.due(tick):
		_spawn(entry)
	_check_terminal()
	tick += 1


func _spawn(entry: Dictionary) -> void:
	var def: EnemyDef = _defs[entry["enemy_id"]]
	var e := EnemyState.new()
	e.id = _next_enemy_id
	_next_enemy_id += 1
	e.def_id = def.id
	e.hp = def.hp
	e.path_idx = int(entry["path_idx"])
	e.progress_units = 0
	e.step_units = Pathing.step_units_for(def.speed_tiles_per_s, config.ticks_per_second)
	e.leak_damage = def.leak_damage
	enemies.append(e)
	spawned += 1


func _check_terminal() -> void:
	if leaked > stage.leak_limit or base_hp <= 0:
		result = Result.DEFEAT
		stars = 0
		return
	if timeline.exhausted() and alive_count() == 0:
		result = Result.CLEAR
		stars = StarCalc.star_for(leaked, stage.leak_limit)


static func _append_int(bytes: PackedByteArray, v: int) -> void:
	for i: int in 8:
		bytes.append((v >> (i * 8)) & 0xFF)


static func _fnv1a64(bytes: PackedByteArray) -> int:
	# FNV-1a 64-bit; offset basis 14695981039346656037 as a signed literal.
	var h := -3750763034362895579
	for b: int in bytes:
		h ^= b
		h *= 1099511628211
	return h
