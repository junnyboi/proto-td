class_name BattleHash
extends RefCounted

## FNV-1a 64-bit over BattleModel's canonical field order (ints only).
## EVERY mutable model field appears here — adding model state without
## extending this hash is a defect (CLAUDE.md ban list). Def-resolved
## constants (step_units, atk, aerial, charm_immune...) are pinned by
## def_id and stay out. Extracted from battle_model.gd at the Phase 7
## file-size budget; the field order is append-only.


static func of(m: BattleModel) -> int:
	var bytes := PackedByteArray()
	_append_int(bytes, m.tick)
	_append_int(bytes, m.base_hp)
	_append_int(bytes, m.result)
	_append_int(bytes, m.stars)
	_append_int(bytes, m.spawned)
	_append_int(bytes, m.leaked)
	_append_int(bytes, m.killed)
	_append_int(bytes, m.timeline.next_index)
	_append_int(bytes, m.dp)
	_append_int(bytes, m.dp_regen_counter)
	_append_int(bytes, m.dp_regen_accrued)
	_append_int(bytes, m.dp_vanguard_generated)
	_append_int(bytes, m.dp_refunded)
	_append_int(bytes, m.dp_spent)
	_append_int(bytes, m.dp_lost_to_cap)
	_append_int(bytes, m.dp_skill_granted)
	_append_int(bytes, m.retreated)
	_append_int(bytes, m.skills_fired)
	for u: UnitState in m.units:
		_append_unit(bytes, u)
	for e: EnemyState in m.enemies:
		_append_int(bytes, e.id)
		_append_int(bytes, e.def_id.hash())
		_append_int(bytes, e.path_idx)
		_append_int(bytes, e.progress_units)
		_append_int(bytes, e.hp)
		_append_int(bytes, e.atk_counter)
		_append_int(bytes, e.blocked_by)
		_append_int(bytes, e.stunned_until_tick)
		_append_int(bytes, 1 if e.alive else 0)
		_append_int(bytes, e.faction)
		_append_int(bytes, e.engaged_with)
	_append_int(bytes, m.traps_triggered)
	_append_int(bytes, m._next_trap_id)
	for t: TrapState in m.traps:
		_append_int(bytes, t.id)
		_append_int(bytes, t.def_id.hash())
		_append_int(bytes, t.cell.x)
		_append_int(bytes, t.cell.y)
		_append_int(bytes, t.charges_left)
	_append_int(bytes, m.charmed)
	_append_int(bytes, m.charmed_dead)
	_append_int(bytes, m.charmed_exited)
	for spell_id: StringName in m.spell_book.ids:
		_append_int(bytes, spell_id.hash())
		_append_int(bytes, m.spell_book.ready_at(spell_id))
		_append_int(bytes, m.spell_book.used_in_wave(spell_id))
		_append_int(bytes, m.spell_book.casts(spell_id))
	return _fnv1a64(bytes)


static func _append_unit(bytes: PackedByteArray, u: UnitState) -> void:
	_append_int(bytes, u.id)
	_append_int(bytes, u.op_id.hash())
	_append_int(bytes, u.cell.x)
	_append_int(bytes, u.cell.y)
	_append_int(bytes, u.facing)
	_append_int(bytes, u.hp)
	_append_int(bytes, 1 if u.alive else 0)
	_append_int(bytes, u.atk_counter)
	_append_int(bytes, u.dp_generation_counter)
	_append_int(bytes, u.last_attack_tick)
	_append_int(bytes, u.last_attack_cell.x)
	_append_int(bytes, u.last_attack_cell.y)
	_append_int(bytes, u.sp)
	_append_int(bytes, u.sp_progress)
	_append_int(bytes, u.skill_triggered_tick)
	_append_int(bytes, u.active_effects.size())
	for fx: Dictionary in u.active_effects:
		_append_int(bytes, int(fx["effect"]))
		_append_int(bytes, int(fx["expires_tick"]))
		var keys: Array = (fx["params"] as Dictionary).keys()
		keys.sort()
		for key: String in keys:
			_append_int(bytes, key.hash())
			_append_int(bytes, int(round(float(fx["params"][key]) * 1000.0)))
	_append_int(bytes, u.blocked_ids.size())
	for bid: int in u.blocked_ids:
		_append_int(bytes, bid)


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
