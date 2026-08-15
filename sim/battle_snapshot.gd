class_name BattleSnapshot
extends RefCounted

## Debug/telemetry projection of BattleModel counters (views read this; the
## hash does not). Extracted from battle_model.gd at the P14 file-size
## budget — same concern seam precedent as BattleHash at Phase 7.

const DamageRulesScript := preload("res://sim/damage_rules.gd")


static func of(m: BattleModel) -> Dictionary:
	var snapshot := {
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
		"damage_rules_version": DamageRulesScript.VERSION,
		"mitigation": _mitigation(m),
	}
	if m._is_ticketed():
		snapshot["ticket_hash"] = String(m.ticket["ticket_hash"])
		snapshot["battle_rows"] = m.battle_records.duplicate(true)
	return snapshot


static func _mitigation(m: BattleModel) -> Dictionary:
	var units: Array[Dictionary] = []
	for u: UnitState in m.units:
		var row := {
			"id": u.id,
			"defense": u.defense,
			"resistance_permille": u.resistance_permille,
			"attack_damage_kind": u.attack_damage_kind,
		}
		if not u.battle_id.is_empty():
			row["battle_id"] = String(u.battle_id)
			row["hero_id"] = String(u.hero_id)
		units.append(row)
	var enemies: Array[Dictionary] = []
	for e: EnemyState in m.enemies:
		enemies.append({
			"id": e.id,
			"defense": e.defense,
			"resistance_permille": e.resistance_permille,
			"attack_damage_kind": e.attack_damage_kind,
		})
	var traps: Array[Dictionary] = []
	for t: TrapState in m.traps:
		traps.append({"id": t.id, "damage_kind": t.damage_kind})
	var spells: Array[Dictionary] = []
	for spell_id: StringName in m.spell_book.ids:
		spells.append({
			"id": String(spell_id),
			"damage_kind": m.spell_book.damage_kind(spell_id),
		})
	return {
		"units": units,
		"enemies": enemies,
		"traps": traps,
		"spells": spells,
	}
