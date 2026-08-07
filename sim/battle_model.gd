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
## test format. Phase 2 verbs: deploy(op_id, cell, facing), retreat(unit_id).
##
## DP ledger (td-phase-2-3.md D4/D5): regen/generation/refunds accrue gross;
## points that would exceed dp_cap land in dp_lost_to_cap, so at every tick
## dp == dp_start + regen + vanguard + refunded - spent - lost_to_cap exactly.
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

var dp: int = 0
var dp_regen_counter: int = 0
var dp_regen_accrued: int = 0
var dp_vanguard_generated: int = 0
var dp_refunded: int = 0
var dp_spent: int = 0
var dp_lost_to_cap: int = 0
var retreated: int = 0
var units: Array[UnitState] = []

var _defs: Dictionary = {}
var _op_defs: Dictionary = {}
var _paths: Array = []
var _path_lengths: Array[int] = []
var _next_enemy_id: int = 0
var _next_unit_id: int = 0


static func create(
	stage_def: StageDef,
	squad_ids: Array[StringName],
	seed_value: int,
	game_config: GameConfig,
	enemy_defs: Dictionary,
	operator_defs: Dictionary = {},
) -> BattleModel:
	var model := BattleModel.new()
	model.stage = stage_def
	model.squad = squad_ids.duplicate()
	model.run_seed = seed_value
	model.config = game_config
	model.base_hp = game_config.base_hp_start
	model.dp = game_config.dp_start
	model._defs = enemy_defs
	model._op_defs = operator_defs
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


## Verb dispatcher (architecture rule 3). Every rejection path returns false
## before any mutation; any verb after a terminal state rejects. trigger_skill/
## place_trap/cast arrive in Phases 5-7.
func apply_action(action: Array) -> bool:
	if action.is_empty() or result != Result.RUNNING:
		return false
	var verb: StringName = action[0]
	if verb == &"deploy" and action.size() == 4:
		return _apply_deploy(action[1], action[2], int(action[3]))
	if verb == &"retreat" and action.size() == 2:
		return _apply_retreat(int(action[1]))
	if verb != &"deploy" and verb != &"retreat":
		push_warning("apply_action: unknown verb '%s'" % [verb])
	return false


## An operator can be deployed iff it is in the squad, has a def, is not
## already on the field, the battle is running, and DP covers its cost.
## The deploy bar's enabled state reads exactly this (single source of truth).
func is_deployable(op_id: StringName) -> bool:
	if result != Result.RUNNING:
		return false
	if not squad.has(op_id) or not _op_defs.has(op_id):
		return false
	for u: UnitState in units:
		if u.alive and u.op_id == op_id:
			return false
	var def: OperatorDef = _op_defs[op_id]
	return dp >= def.dp_cost


## Full deploy validation (the highlight query IS the verb's validation —
## never a copy). GROUND ops deploy on GROUND only, ELEVATED on ELEVATED;
## SPAWN/BASE/VOID/BLOCKED are never deployable; one alive unit per cell.
func can_deploy_at(op_id: StringName, cell: Vector2i) -> bool:
	if not is_deployable(op_id):
		return false
	var def: OperatorDef = _op_defs[op_id]
	var tile := stage.tile_at(cell)
	if def.placement == OperatorDef.Placement.GROUND and tile != StageDef.Tile.GROUND:
		return false
	if def.placement == OperatorDef.Placement.ELEVATED and tile != StageDef.Tile.ELEVATED:
		return false
	return alive_unit_at(cell) == null


func unit_by_id(unit_id: int) -> UnitState:
	for u: UnitState in units:
		if u.id == unit_id:
			return u
	return null


func alive_unit_at(cell: Vector2i) -> UnitState:
	for u: UnitState in units:
		if u.alive and u.cell == cell:
			return u
	return null


func deployed_count() -> int:
	var n := 0
	for u: UnitState in units:
		if u.alive:
			n += 1
	return n


func _apply_deploy(op_id: StringName, cell: Vector2i, facing: int) -> bool:
	if facing < UnitState.Facing.RIGHT or facing > UnitState.Facing.UP:
		return false
	if not can_deploy_at(op_id, cell):
		return false
	var def: OperatorDef = _op_defs[op_id]
	var u := UnitState.new()
	u.id = _next_unit_id
	_next_unit_id += 1
	u.op_id = def.id
	u.cell = cell
	u.facing = facing as UnitState.Facing
	u.hp = def.hp
	u.block = def.block
	u.dp_cost = def.dp_cost
	u.atk = def.atk
	u.atk_interval_ticks = def.atk_interval_ticks
	u.dp_generation_interval_ticks = def.dp_generation_interval_ticks
	units.append(u)
	dp -= def.dp_cost
	dp_spent += def.dp_cost
	return true


func _apply_retreat(unit_id: int) -> bool:
	var u := unit_by_id(unit_id)
	if u == null or not u.alive:
		return false
	u.alive = false
	retreated += 1
	var refund := floori(u.dp_cost * config.retreat_refund_percent / 100.0)
	dp_refunded += refund
	_grant_dp(refund)
	return true


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
	_append_int(bytes, dp)
	_append_int(bytes, dp_regen_counter)
	_append_int(bytes, dp_regen_accrued)
	_append_int(bytes, dp_vanguard_generated)
	_append_int(bytes, dp_refunded)
	_append_int(bytes, dp_spent)
	_append_int(bytes, dp_lost_to_cap)
	_append_int(bytes, retreated)
	for u: UnitState in units:
		_append_int(bytes, u.id)
		_append_int(bytes, u.op_id.hash())
		_append_int(bytes, u.cell.x)
		_append_int(bytes, u.cell.y)
		_append_int(bytes, u.facing)
		_append_int(bytes, u.hp)
		_append_int(bytes, 1 if u.alive else 0)
		_append_int(bytes, u.atk_counter)
		_append_int(bytes, u.dp_generation_counter)
		_append_int(bytes, u.blocked_ids.size())
		for bid: int in u.blocked_ids:
			_append_int(bytes, bid)
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
		"dp": dp,
		"deployed": deployed_count(),
		"deploys": units.size(),
		"retreated": retreated,
		"dp_spent": dp_spent,
	}


## Sub-step order pinned in td-phase-2-3.md D9: (1) DP regen + vanguard
## generation, (2) advance enemies + leaks, (3) combat (Phase 3), (4) spawn,
## (5) terminal check. Later phases append sub-steps, never reorder.
func _step_one() -> void:
	if result != Result.RUNNING:
		return
	_tick_dp()
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


func _tick_dp() -> void:
	dp_regen_counter += 1
	if dp_regen_counter >= config.dp_regen_interval_ticks:
		dp_regen_counter = 0
		dp_regen_accrued += 1
		_grant_dp(1)
	for u: UnitState in units:
		if not u.alive or u.dp_generation_interval_ticks <= 0:
			continue
		u.dp_generation_counter += 1
		if u.dp_generation_counter >= u.dp_generation_interval_ticks:
			u.dp_generation_counter = 0
			dp_vanguard_generated += 1
			_grant_dp(1)


## Single cap-clamp point (D4): callers bump their gross ledger bucket, then
## grant through here; the overage lands in dp_lost_to_cap.
func _grant_dp(amount: int) -> void:
	var granted := mini(amount, config.dp_cap - dp)
	dp += granted
	dp_lost_to_cap += amount - granted


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
