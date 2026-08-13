extends Node

## Session state + scene flow (all in-memory; every launch starts fresh, no
## persistence — per the POC scope). start_battle() swaps the content scene
## manually so it works both under the normal main-scene boot and under the
## selftest harness (which parents the main scene to root itself).

const TITLE_SCENE_PATH := "res://scenes/title.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle.tscn"
const STAGING_SCENE_PATH := "res://scenes/staging.tscn"
const STAGE_SELECT_SCENE_PATH := "res://scenes/stage_select.tscn"
const SQUAD_SELECT_SCENE_PATH := "res://scenes/squad_select.tscn"
const RESULTS_SCENE_PATH := "res://scenes/results.tscn"
const LEGACY_CAMPAIGN_ADAPTER_SCRIPT := preload("res://sim/legacy_campaign_adapter.gd")

var run_seed: int = 42
var default_stage_id: StringName = &"test_lane"
var default_squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
var pending_stage: StageDef = null
var current_battle: BattleModel = null
var content: Node = null

# D16-08 runtime compatibility session. Canonical P16 CampaignState remains
# model-only until real ticket/outcome production permits the P16.3 cutover.
# campaign_active == false preserves full-catalog direct-battle seams.
var campaign: Variant = null
var campaign_active: bool = false
var selected_stage_id: StringName = &""
var selected_squad: Array[StringName] = []
var last_result: Dictionary = {}
var _debug_catalog_override: bool = false


func set_run_seed(value: int) -> void:
	run_seed = value
	seed(value)


## Fresh campaign run (always from scratch — no persistence by design).
## Bots pass open_campaign_ui = false and drive start_stage directly.
func start_campaign(open_campaign_ui: bool = true) -> void:
	_debug_catalog_override = false
	campaign = LEGACY_CAMPAIGN_ADAPTER_SCRIPT.create(_catalogs(), _all_stage_defs())
	campaign_active = true
	pending_stage = null
	current_battle = null
	selected_stage_id = &""
	selected_squad = []
	last_result = {}
	if open_campaign_ui:
		open_staging()


## Lock enforcement lives in the stage-select UI (and is asserted by the
## campaign bot/scenario) — the seam trusts its caller so per-stage bots
## can run standalone (§2.2.6).
func start_stage(stage_id: StringName, squad: Array[StringName]) -> void:
	selected_stage_id = stage_id
	selected_squad = squad.duplicate()
	start_battle(stage_id)


## The squad the next battle boots with: an explicit start_stage selection
## wins (campaign runs AND standalone per-stage bots — §2.2.6 lets bots run
## without clearing predecessors); start_battle-only harness/debug paths
## never set one and keep the default squad.
func battle_squad() -> Array[StringName]:
	if not selected_squad.is_empty():
		return selected_squad
	return default_squad


func is_stage_unlocked(stage_id: StringName) -> bool:
	if campaign == null:
		return true
	return campaign.is_stage_unlocked(stage_id)


func campaign_stage_ids() -> Array[StringName]:
	if campaign == null:
		return []
	return campaign.campaign_stage_ids()


## Loadout sets for the UI (model stays catalog-validated — td-phase-6-7
## §2.1): unlocked sets while a campaign runs, full catalogs for internal
## harness/debug direct-battle seams.
func loadout_operator_ids() -> Array[StringName]:
	if _debug_catalog_override:
		return _scan_ids("res://data/operators")
	if campaign_active and campaign != null:
		return campaign.unlocked_operators
	return _scan_ids("res://data/operators")


func loadout_trap_ids() -> Array[StringName]:
	if _debug_catalog_override:
		return _scan_ids("res://data/traps")
	if campaign_active and campaign != null:
		return campaign.unlocked_traps
	return _scan_ids("res://data/traps")


func loadout_spell_ids() -> Array[StringName]:
	if _debug_catalog_override:
		return _scan_ids("res://data/spells")
	if campaign_active and campaign != null:
		return campaign.unlocked_spells
	return _scan_ids("res://data/spells")


## Records a terminal battle result (called once per battle by the view's
## result edge); grants first-clear rewards and stores last_result for the
## results screen. Idempotent by LegacyCampaignAdapter construction.
func record_result(result: int, stars: int) -> void:
	if current_battle == null:
		return
	var stage := current_battle.stage
	var granted: Array[Dictionary] = []
	# campaign_active guard (Phase 13, Q4): a harness/debug direct battle
	# must never grant rewards through a stale compatibility campaign.
	if campaign != null and campaign_active:
		granted = campaign.record_result(stage, result, stars)
	last_result = {
		"stage_id": stage.id,
		"result": result,
		"stars": stars,
		"leaks": current_battle.leaked,
		"kills": current_battle.killed,
		"rewards_granted": granted,
	}


func debug_unlock_all() -> void:
	_debug_catalog_override = true


## Back to the starting menu (Phase 13). Resets the campaign session so the
## next Start always creates a fresh campaign with no stale selection.
func open_title() -> void:
	pending_stage = null
	current_battle = null
	campaign = null
	campaign_active = false
	selected_stage_id = &""
	selected_squad = []
	last_result = {}
	_debug_catalog_override = false
	_swap_content.call_deferred(TITLE_SCENE_PATH)


## P15 campaign-home seam. Returning here only swaps the projection; the
## existing LegacyCampaignAdapter remains authoritative and unchanged.
func open_staging() -> void:
	_swap_content.call_deferred(STAGING_SCENE_PATH)


func open_stage_select() -> void:
	_swap_content.call_deferred(STAGE_SELECT_SCENE_PATH)


func open_squad_select() -> void:
	_swap_content.call_deferred(SQUAD_SELECT_SCENE_PATH)


func open_results() -> void:
	_swap_content.call_deferred(RESULTS_SCENE_PATH)


func _catalogs() -> Dictionary:
	return {
		"operators": _scan_ids("res://data/operators"),
		"traps": _scan_ids("res://data/traps"),
		"spells": _scan_ids("res://data/spells"),
	}


func _all_stage_defs() -> Array:
	var defs: Array = []
	for stage_id: StringName in stage_ids():
		defs.append(load("res://data/stages/%s.tres" % stage_id) as StageDef)
	return defs


func _scan_ids(dir_path: String) -> Array[StringName]:
	var names: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return []
	for file: String in dir.get_files():
		# exported builds list "<name>.tres.remap" (text->binary conversion)
		var res_name := file.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			names.append(res_name.trim_suffix(".tres"))
	names.sort()
	var ids: Array[StringName] = []
	for item_name: String in names:
		ids.append(StringName(item_name))
	return ids


## Every stage id on disk, sorted (deterministic). The debug overlay's jump
## list and the debug_reach sweep both read this scan, so Lane B stages
## appear in both with zero code changes.
func stage_ids() -> Array[StringName]:
	# sort as String: StringName's own ordering is interning-order, not text
	return _scan_ids("res://data/stages")


func start_battle(stage_id: StringName) -> void:
	var stage_path := "res://data/stages/%s.tres" % stage_id
	if not ResourceLoader.exists(stage_path):
		push_error("unknown stage: " + stage_path)
		return
	current_battle = null
	pending_stage = load(stage_path) as StageDef
	_swap_content.call_deferred(BATTLE_SCENE_PATH)


func _swap_content(scene_path: String) -> void:
	if scene_path != BATTLE_SCENE_PATH:
		_stop_music_if_available()
	var packed: PackedScene = load(scene_path)
	var candidate: Node = packed.instantiate()
	get_tree().root.add_child(candidate)
	_accept_content_candidate(candidate, scene_path == BATTLE_SCENE_PATH)


## Commit point shared by the runtime swap and executable activation tests.
## Adding the candidate runs _ready synchronously, so the entire decision and
## prior-content retirement remain inside this one deferred swap call.
func _accept_content_candidate(candidate: Node, is_battle: bool) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		if is_battle:
			pending_stage = null
			current_battle = null
		return false
	if is_battle and not bool(candidate.get("startup_succeeded")):
		candidate.queue_free()
		pending_stage = null
		current_battle = null
		return false
	var previous := content
	if previous != null and is_instance_valid(previous) and previous != candidate:
		var previous_parent := previous.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(previous)
		previous.queue_free()
	content = candidate
	return true


## Music is presentation-only and must never block navigation. Resolve the
## optional autoload at call time because failed/partial project startup can
## leave the global singleton identifier as Nil on some runtime paths.
func _stop_music_if_available() -> bool:
	return _stop_music_node(get_node_or_null("/root/Music"))


func _stop_music_node(music: Node) -> bool:
	if music == null or not music.has_method("stop"):
		return false
	music.call("stop")
	return true
