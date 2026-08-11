class_name BattleSnapshot
extends RefCounted

## Debug/telemetry projection of BattleModel counters (views read this; the
## hash does not). Extracted from battle_model.gd at the P14 file-size
## budget — same concern seam precedent as BattleHash at Phase 7.


static func of(m: BattleModel) -> Dictionary:
	return {
		"tick": m.tick,
		"base_hp": m.base_hp,
		"result": m.result,
		"stars": m.stars,
		"spawned": m.spawned,
		"leaked": m.leaked,
		"killed": m.killed,
		"alive": m.alive_enemy_count(),
		"dp": m.dp,
		"deployed": m.deployed_count(),
		"deploys": m.units.size(),
		"retreated": m.retreated,
		"dp_spent": m.dp_spent,
		"skills_fired": m.skills_fired,
		"traps_placed": m._next_trap_id,
		"trap_triggers": m.traps_triggered,
		"charmed": m.charmed,
		"charmed_alive": m.alive_charmed_count(),
		"charmed_dead": m.charmed_dead,
		"charmed_exited": m.charmed_exited,
		"spells_cast": m.spell_book.total_casts(),
	}
