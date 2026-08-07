class_name SpellBook
extends RefCounted

## Per-battle spell availability (architecture rule 1: plain data, no Node).
## Holds no per-tick state (td-phase-6-7.md M1): readiness is arithmetic
## over the model tick. COOLDOWN: castable iff tick >= ready_at_tick (starts
## 0, so every spell is ready at tick 0). ONCE_PER_WAVE: castable iff the
## wave window containing tick is later than the one recorded at the last
## cast; wave windows are delimited by StageDef.wave_starts (empty = one
## window), and a cast on the wave-start tick itself is allowed. Catalog
## order is sorted by id so state_hash() iteration is stable.

var ids: Array[StringName] = []
var wave_starts: PackedInt32Array = []

var _defs: Dictionary = {}
var _ready_at: Dictionary = {}
var _used_in_wave: Dictionary = {}
var _casts: Dictionary = {}


static func create(spell_defs: Dictionary, stage_wave_starts: PackedInt32Array) -> SpellBook:
	var book := SpellBook.new()
	book._defs = spell_defs
	book.wave_starts = stage_wave_starts
	for key: StringName in spell_defs:
		book.ids.append(key)
	book.ids.sort()
	for spell_id: StringName in book.ids:
		book._ready_at[spell_id] = 0
		book._used_in_wave[spell_id] = -1
		book._casts[spell_id] = 0
	return book


func has_spell(spell_id: StringName) -> bool:
	return _defs.has(spell_id)


func def_of(spell_id: StringName) -> SpellDef:
	return _defs[spell_id]


## Index of the wave window containing tick t (count of boundaries <= t,
## minus one). An empty wave_starts reads as [0]: everything is window 0.
func wave_index_of(t: int) -> int:
	if wave_starts.is_empty():
		return 0
	var idx := -1
	for boundary: int in wave_starts:
		if boundary <= t:
			idx += 1
	return idx


func can_cast(spell_id: StringName, t: int) -> bool:
	if not _defs.has(spell_id):
		return false
	if t < int(_ready_at[spell_id]):
		return false
	var def: SpellDef = _defs[spell_id]
	if def.availability == SpellDef.Availability.ONCE_PER_WAVE:
		return wave_index_of(t) > int(_used_in_wave[spell_id])
	return true


func mark_cast(spell_id: StringName, t: int) -> void:
	var def: SpellDef = _defs[spell_id]
	_ready_at[spell_id] = t + def.cooldown_ticks
	if def.availability == SpellDef.Availability.ONCE_PER_WAVE:
		_used_in_wave[spell_id] = wave_index_of(t)
	_casts[spell_id] = int(_casts[spell_id]) + 1


## Debug re-arm (Phase 8, rule 5): castable immediately at tick t, and a
## ONCE_PER_WAVE spell becomes usable again within the wave containing t.
## Callers validate the id (BattleModel's debug_reset_spell verb).
func debug_reset(spell_id: StringName, t: int) -> void:
	_ready_at[spell_id] = t
	var def: SpellDef = _defs[spell_id]
	if def.availability == SpellDef.Availability.ONCE_PER_WAVE:
		_used_in_wave[spell_id] = wave_index_of(t) - 1


func ready_at(spell_id: StringName) -> int:
	return int(_ready_at[spell_id])


func used_in_wave(spell_id: StringName) -> int:
	return int(_used_in_wave[spell_id])


func casts(spell_id: StringName) -> int:
	return int(_casts[spell_id])


func total_casts() -> int:
	var n := 0
	for spell_id: StringName in ids:
		n += int(_casts[spell_id])
	return n
