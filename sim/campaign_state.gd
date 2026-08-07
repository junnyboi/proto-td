class_name CampaignState
extends RefCounted

## Session campaign model (Phase 10, td-phase-10.md §2.2 — architecture
## rule 1: plain data, zero Node/autoload imports, GUT-testable without the
## Game wrapper). Holds the unlocked sets + per-stage best stars; rewards
## grant on FIRST clear only (idempotent), stars update best-of always,
## DEFEAT records nothing. Starting unlocks are DERIVED, never declared:
## full catalogs minus the union of all campaign rewards — the same static
## function feeds the runtime and the stage lint, so the two can't drift.

var unlocked_operators: Array[StringName] = []
var unlocked_traps: Array[StringName] = []
var unlocked_spells: Array[StringName] = []
var stage_stars: Dictionary = {}

var _campaign_order: Array[StringName] = []
var _stage_index: Dictionary = {}


## catalogs = {operators: [...ids], traps: [...], spells: [...]};
## stage_defs = every StageDef (non-campaign entries are ignored).
static func derive_starting_unlocks(catalogs: Dictionary, stage_defs: Array) -> Dictionary:
	var rewarded: Dictionary = {}
	for stage: StageDef in stage_defs:
		if stage.campaign_index < 1:
			continue
		for reward: Dictionary in stage.rewards:
			rewarded[reward["id"]] = true
	var out := {"operators": [], "traps": [], "spells": []}
	for kind: String in out:
		var starting: Array[StringName] = []
		for item_id: StringName in catalogs[kind]:
			if not rewarded.has(item_id):
				starting.append(item_id)
		starting.sort_custom(func(a: StringName, b: StringName) -> bool:
			return String(a) < String(b))
		out[kind] = starting
	return out


static func create(catalogs: Dictionary, stage_defs: Array) -> CampaignState:
	var state := CampaignState.new()
	var starting := derive_starting_unlocks(catalogs, stage_defs)
	state.unlocked_operators.assign(starting["operators"])
	state.unlocked_traps.assign(starting["traps"])
	state.unlocked_spells.assign(starting["spells"])
	var campaign: Array = []
	for stage: StageDef in stage_defs:
		if stage.campaign_index >= 1:
			campaign.append(stage)
	campaign.sort_custom(func(a: StageDef, b: StageDef) -> bool:
		return a.campaign_index < b.campaign_index)
	for stage: StageDef in campaign:
		state._campaign_order.append(stage.id)
		state._stage_index[stage.id] = stage.campaign_index
	return state


func campaign_stage_ids() -> Array[StringName]:
	return _campaign_order


## Linear campaign: stage k unlocked iff k == 1 or stage k-1 is cleared.
## Non-campaign stages are always "unlocked" (they're outside the campaign).
func is_stage_unlocked(stage_id: StringName) -> bool:
	if not _stage_index.has(stage_id):
		return true
	var index: int = _stage_index[stage_id]
	if index == 1:
		return true
	var prev := _campaign_order[index - 2]
	return stage_stars.has(prev)


## Returns the rewards newly granted by this result ([] on DEFEAT, on
## non-campaign stages, and on re-clears).
func record_result(stage: StageDef, result: int, stars: int) -> Array[Dictionary]:
	if result != BattleModel.Result.CLEAR or stage.campaign_index < 1:
		return []
	var first_clear := not stage_stars.has(stage.id)
	stage_stars[stage.id] = maxi(stars, int(stage_stars.get(stage.id, 0)))
	if not first_clear:
		return []
	var granted: Array[Dictionary] = []
	for reward: Dictionary in stage.rewards:
		var target := _set_for(reward["kind"])
		var item_id: StringName = reward["id"]
		if not target.has(item_id):
			target.append(item_id)
			granted.append(reward)
	return granted


func unlock_everything(catalogs: Dictionary) -> void:
	unlocked_operators.assign(catalogs["operators"])
	unlocked_traps.assign(catalogs["traps"])
	unlocked_spells.assign(catalogs["spells"])


func _set_for(kind: StringName) -> Array[StringName]:
	match kind:
		&"operator":
			return unlocked_operators
		&"trap":
			return unlocked_traps
		&"spell":
			return unlocked_spells
	return []
