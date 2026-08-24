extends Node

## Scene flow and crash-safe campaign state management.

const TITLE_SCENE_PATH := "res://scenes/title.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle.tscn"
const STAGING_SCENE_PATH := "res://scenes/staging.tscn"
const TRAINING_SCENE_PATH := "res://scenes/training.tscn"
const STAGE_SELECT_SCENE_PATH := "res://scenes/stage_select.tscn"
const SQUAD_SELECT_SCENE_PATH := "res://scenes/squad_select.tscn"
const RESULTS_SCENE_PATH := "res://scenes/results.tscn"
const LEGACY_CAMPAIGN_ADAPTER_SCRIPT := preload("res://sim/legacy_campaign_adapter.gd")
const CAMPAIGN_RUNTIME_CONTEXT_SCRIPT := preload("res://sim/campaign_runtime_context.gd")
const CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT := preload("res://sim/campaign_runtime_authority.gd")
const CANONICAL_JSON_SCRIPT := preload("res://sim/canonical_json.gd")
const TRAINING_SUPPORT_SCRIPT := preload("res://scripts/ui/components/training_support.gd")

var run_seed: int = 42
var default_stage_id: StringName = &"s1"
var default_squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
var pending_stage: StageDef = null
var current_battle: BattleModel = null
var content: Node = null

# Direct battles cannot submit outcomes to an active campaign.
var campaign: Variant = null
var campaign_store: Variant = null
var campaign_active: bool = false
var selected_stage_id: StringName = &""
var selected_squad: Array[StringName] = []
var last_result: Dictionary = {}
var last_campaign_error: StringName = &""
var training_return_path: StringName = &"staging"
var training_acknowledgement: Array[Dictionary] = []
var _campaign_context: Dictionary = {}
var _pending_battle_ticket: Dictionary = {}
var _pending_campaign_mutation: Variant = null
var _pending_promotion_mutation: Variant = null
var _campaign_battle_active := false


func set_run_seed(value: int) -> void:
	run_seed = value
	seed(value)


## Resume a valid durable campaign by default. Explicit fresh starts first
## restore/migrate the prior slot, then replace it through expected-preimage CAS.
func start_campaign(open_campaign_ui: bool = true, fresh: bool = false) -> bool:
	_campaign_context = CAMPAIGN_RUNTIME_CONTEXT_SCRIPT.build()
	var started: Dictionary = (
		CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.start_new(run_seed, _campaign_context)
		if fresh
		else CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.load_or_create(run_seed, _campaign_context)
	)
	if not started["accepted"]:
		push_error("Game.start_campaign: %s" % started["error_code"])
		return false
	campaign = started["state"]
	campaign_store = started["store"]
	campaign_active = true
	pending_stage = null
	current_battle = null
	selected_stage_id = &""
	selected_squad = []
	last_result = {}
	last_campaign_error = &""
	training_return_path = &"staging"
	training_acknowledgement.clear()
	_pending_battle_ticket = {}
	_pending_campaign_mutation = null
	_pending_promotion_mutation = null
	_campaign_battle_active = false
	_restore_pending_attempt()
	if open_campaign_ui:
		if _campaign_battle_active:
			_queue_battle(selected_stage_id)
		else:
			open_staging()
	return true


func _restore_pending_attempt() -> void:
	var data: Dictionary = campaign.data_copy()
	if int(data["next_attempt_id"]) != int(data["next_resolution_index"]) + 1:
		return
	var tickets: Array = data["tickets"]
	if tickets.is_empty():
		return
	var ticket: Dictionary = tickets[-1]
	if int(ticket["attempt_id"]) != int(data["next_resolution_index"]):
		return
	selected_stage_id = StringName(ticket["stage_id"])
	selected_squad = []
	for row: Dictionary in ticket["squad"]:
		selected_squad.append(StringName(row["hero_id"]))
	_pending_battle_ticket = ticket.duplicate(true)
	_campaign_battle_active = true


## Player campaign launch is an authoritative strategic command. Selection and
## scene state publish only after the BattleTicket is durably committed.
func start_stage(
	stage_id: StringName,
	squad: Array[StringName],
	open_battle: bool = true,
) -> Dictionary:
	if not campaign_active or campaign == null or campaign_store == null:
		selected_stage_id = stage_id
		selected_squad = squad.duplicate()
		start_battle(stage_id, open_battle)
		return {"accepted": true, "error_code": &"", "ticket": {}}
	var command_id := "runtime:begin:%s:%d" % [
		campaign.campaign_uid(), campaign.next_attempt_id(),
	]
	var command: Dictionary = campaign.begin_attempt(
		command_id, stage_id, squad, run_seed, campaign.save_revision(),
	)
	var committed: Dictionary = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.commit(
		command, campaign_store,
	)
	if not committed["accepted"]:
		return committed
	campaign = committed["state"]
	var ticket: Dictionary = committed["result"]["ticket"].duplicate(true)
	selected_stage_id = stage_id
	selected_squad = squad.duplicate()
	_pending_battle_ticket = ticket
	_campaign_battle_active = true
	if open_battle:
		_queue_battle(stage_id)
	return {"accepted": true, "error_code": &"", "ticket": ticket.duplicate(true)}


## The squad the next battle boots with: an explicit start_stage selection
## wins (campaign runs AND standalone per-stage bots — §2.2.6 lets bots run
## never set one and keep the default squad.
func _battle_squad() -> Array[StringName]:
	if not selected_squad.is_empty():
		return selected_squad.duplicate()
	return default_squad


func battle_launch() -> Dictionary:
	return {
		"input": (
			_pending_battle_ticket.duplicate(true)
			if _campaign_battle_active
			else _battle_squad()
		),
		"trusted_ticket_hashes": (
			[String(_pending_battle_ticket["ticket_hash"])]
			if _campaign_battle_active
			else []
		),
		"trap_ids": loadout_trap_ids() if _campaign_battle_active else _scan_ids(
			"res://data/traps"
		),
		"spell_ids": loadout_spell_ids() if _campaign_battle_active else _scan_ids(
			"res://data/spells"
		),
	}


func is_stage_unlocked(stage_id: StringName) -> bool:
	if campaign == null:
		return true
	var projection: Dictionary = campaign.runtime_projection()
	var position := (projection["stage_ids"] as Array).find(stage_id)
	return (
		position <= 0
		or (projection["stage_stars"] as Dictionary).has(
			projection["stage_ids"][position - 1]
		)
	)


func campaign_stage_ids() -> Array[StringName]:
	if campaign == null:
		return []
	return campaign.runtime_projection()["stage_ids"].duplicate()


func campaign_projection() -> Dictionary:
	if not campaign_active or campaign == null:
		return {}
	return campaign.runtime_projection()


## Loadout sets for the UI: unlocked sets during a campaign, full catalogs
## for direct battles.
func loadout_operator_ids() -> Array[StringName]:
	if campaign_active and campaign != null:
		return campaign.runtime_projection()["unlocked_operators"]
	return _scan_ids("res://data/operators")


func loadout_trap_ids() -> Array[StringName]:
	if campaign_active and campaign != null:
		return campaign.runtime_projection()["unlocked_traps"]
	return _scan_ids("res://data/traps")


func loadout_spell_ids() -> Array[StringName]:
	if campaign_active and campaign != null:
		return campaign.runtime_projection()["unlocked_spells"]
	return _scan_ids("res://data/spells")


## Commit the model-owned canonical BattleOutcome. The view supplies only the
## result edge; rewards, XP, deaths, stars, and Memorial facts come from the
## resolved strategic receipt.
func record_result(result: int, stars: int) -> bool:
	if current_battle == null:
		return false
	var stage := current_battle.stage
	if not _campaign_battle_active:
		last_result = {
			"stage_id": stage.id,
			"result": result,
			"stars": stars,
			"leaks": current_battle.leaked,
			"kills": current_battle.killed,
			"rewards_granted": [],
		}
		return true
	var artifacts := current_battle.snapshot()
	var outcome: Dictionary = artifacts.get("outcome", {})
	if outcome.is_empty():
		return false
	var committed: Dictionary
	if _pending_campaign_mutation != null:
		committed = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.retry(
			_pending_campaign_mutation, campaign_store,
		)
	else:
		var attempt_id := int(_pending_battle_ticket["attempt_id"])
		var command_id := "runtime:resolve:%s:%d" % [campaign.campaign_uid(), attempt_id]
		committed = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.commit(
			campaign.resolve_attempt(
				command_id,
				attempt_id,
				outcome,
				int(_pending_battle_ticket["expected_save_revision"]),
			),
			campaign_store,
		)
	if not committed["accepted"]:
		last_campaign_error = committed["error_code"]
		_pending_campaign_mutation = committed.get("mutation")
		return false
	last_campaign_error = &""
	_pending_campaign_mutation = null
	campaign = committed["state"]
	var resolution: Dictionary = committed["result"]["resolution"]
	var accepted_outcome: Dictionary = committed["result"]["outcome"]
	var canonical_result := (
		BattleModel.Result.CLEAR
		if String(accepted_outcome["result"]) == "clear"
		else BattleModel.Result.DEFEAT
	)
	last_result = {
		"stage_id": StringName(resolution["stage_id"]),
		"result": canonical_result,
		"stars": int(accepted_outcome["stars"]),
		"leaks": int(accepted_outcome["leaks"]),
		"kills": int(accepted_outcome["kills"]),
		"rewards_granted": resolution["rewards_granted"].duplicate(true),
		"class_entitlements_granted": (
			resolution["class_entitlements_granted"].duplicate()
		),
		"xp_awards": resolution["xp_awards"].duplicate(true),
		"dead_hero_ids": resolution["dead_hero_ids"].duplicate(),
	}
	_pending_battle_ticket = {}
	_campaign_battle_active = false
	return true


func commit_campaign_command(command: Dictionary) -> Dictionary:
	if not campaign_active or campaign_store == null:
		return {"accepted": false, "error_code": &"campaign_inactive"}
	var committed: Dictionary = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.commit(
		command, campaign_store,
	)
	if committed["accepted"]:
		campaign = committed["state"]
	return committed


func training_call(action: StringName, payload: Variant = null) -> Variant:
	var result: Variant = null
	match action:
		&"eligible_count":
			result = TRAINING_SUPPORT_SCRIPT.eligible_count(campaign) if campaign_active else 0
		&"commit":
			result = _commit_promotions(payload as Array)
		&"retry":
			result = _retry_promotions()
		&"retry_pending":
			result = _pending_promotion_mutation != null
		&"peek_acknowledgement":
			result = training_acknowledgement.duplicate(true)
		&"consume_acknowledgement":
			training_acknowledgement.clear()
			result = true
		&"open":
			_open_training(StringName(payload))
			result = true
		&"leave":
			_leave_training()
			result = true
	return result


## Build and durably commit one atomic, canonical promotion batch. The UI owns
## only its local draft; CampaignStateV3 remains the sole legality authority.
func _commit_promotions(choices: Array) -> Dictionary:
	if not campaign_active or campaign == null or campaign_store == null:
		return {"accepted": false, "error_code": &"campaign_inactive"}
	if _pending_promotion_mutation != null:
		return {"accepted": false, "error_code": &"promotion_retry_pending"}
	var canonical: Array[Dictionary] = []
	for raw: Variant in choices:
		if typeof(raw) != TYPE_DICTIONARY:
			return {"accepted": false, "error_code": &"invalid_promotion_choice"}
		var row := raw as Dictionary
		canonical.append(
			{
				"hero_id": String(row.get("hero_id", "")),
				"to_class_id": String(row.get("to_class_id", "")),
			}
		)
	canonical.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["hero_id"]) < String(b["hero_id"])
	)
	var revision: int = campaign.save_revision()
	var digest := CANONICAL_JSON_SCRIPT.sha256_hex(canonical).substr(0, 16)
	var command_id := "runtime:promote:%s:%d:%s" % [
		campaign.campaign_uid(), revision, digest,
	]
	var command: Dictionary = campaign.confirm_promotions(
		command_id, revision, canonical,
	)
	var committed: Dictionary = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.commit(
		command, campaign_store,
	)
	if not committed["accepted"]:
		if committed.get("retryable", false):
			_pending_promotion_mutation = committed.get("mutation")
		return committed
	_publish_promotion_commit(committed)
	return committed


func _retry_promotions() -> Dictionary:
	if _pending_promotion_mutation == null:
		return {"accepted": false, "error_code": &"no_promotion_retry"}
	var committed: Dictionary = CAMPAIGN_RUNTIME_AUTHORITY_SCRIPT.retry(
		_pending_promotion_mutation, campaign_store,
	)
	if not committed["accepted"]:
		if not committed.get("retryable", false):
			_pending_promotion_mutation = null
		return committed
	_pending_promotion_mutation = null
	_publish_promotion_commit(committed)
	return committed


func _publish_promotion_commit(committed: Dictionary) -> void:
	campaign = committed["state"]
	if not bool(committed["result"].get("fresh", true)):
		return
	training_acknowledgement.clear()
	for row: Dictionary in committed["result"]["promotion"]["choices"]:
		training_acknowledgement.append(row.duplicate(true))


## next Start always creates a fresh campaign with no stale selection.
func open_title() -> void:
	pending_stage = null
	current_battle = null
	campaign = null
	campaign_store = null
	campaign_active = false
	selected_stage_id = &""
	selected_squad = []
	last_result = {}
	training_return_path = &"staging"
	training_acknowledgement.clear()
	_campaign_context = {}
	_pending_battle_ticket = {}
	_pending_campaign_mutation = null
	_pending_promotion_mutation = null
	_campaign_battle_active = false
	_swap_content.call_deferred(TITLE_SCENE_PATH)


## Campaign-home projection. Returning here swaps presentation only; the current
## immutable CampaignStateV3 and durable store remain authoritative.
func open_staging() -> void:
	_swap_content.call_deferred(STAGING_SCENE_PATH)


func _open_training(return_path: StringName = &"staging") -> void:
	training_return_path = (
		return_path if return_path in [&"results", &"staging", &"mission"] else &"staging"
	)
	_swap_content.call_deferred(TRAINING_SCENE_PATH)


func _leave_training() -> void:
	if training_return_path == &"results":
		open_results()
	elif training_return_path == &"mission":
		open_squad_select()
	else:
		open_staging()


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


## list and the debug_reach sweep both read this scan, so Lane B stages
## appear in both with zero code changes.
func stage_ids() -> Array[StringName]:
	# sort as String: StringName's own ordering is interning-order, not text
	return _scan_ids("res://data/stages")


func start_battle(stage_id: StringName, open_battle: bool = true) -> void:
	_campaign_battle_active = false
	_pending_battle_ticket = {}
	if open_battle:
		_queue_battle(stage_id)


func _queue_battle(stage_id: StringName) -> void:
	var stage_path := "res://data/stages/%s.tres" % stage_id
	if not ResourceLoader.exists(stage_path):
		push_error("unknown stage: " + stage_path)
		return
	var previous_content := content
	var previous_pending := pending_stage
	var previous_battle := current_battle
	pending_stage = load(stage_path) as StageDef
	_swap_content.call_deferred(
		BATTLE_SCENE_PATH, previous_content, previous_pending, previous_battle
	)


func _swap_content(
	scene_path: String,
	previous_override: Node = null,
	previous_pending: StageDef = null,
	previous_battle: BattleModel = null,
) -> void:
	if scene_path != BATTLE_SCENE_PATH:
		_stop_music_if_available()
	# Incumbent UI scenes assign Game.content from _ready(). Capture the real
	# predecessor before add_child() runs that synchronous callback, then retire
	# exactly that node at the commit point.
	var previous := previous_override if scene_path == BATTLE_SCENE_PATH else content
	var packed: PackedScene = load(scene_path)
	var candidate: Node = packed.instantiate()
	get_tree().root.add_child(candidate)
	_accept_content_candidate(
		candidate,
		scene_path == BATTLE_SCENE_PATH,
		previous,
		previous_pending,
		previous_battle,
	)


## Commit point shared by the runtime swap and executable activation tests.
## Adding the candidate runs _ready synchronously, so the entire decision and
## prior-content retirement remain inside this one deferred swap call.
func _accept_content_candidate(
	candidate: Node,
	is_battle: bool,
	previous: Node = null,
	previous_pending: StageDef = null,
	previous_battle: BattleModel = null,
) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		if is_battle:
			pending_stage = previous_pending
			current_battle = previous_battle
		return false
	var candidate_battle: BattleModel = null
	if is_battle:
		candidate_battle = candidate.get("model") as BattleModel
		var startup_succeeded: Variant = candidate.get("startup_succeeded")
		if startup_succeeded != true or candidate_battle == null:
			candidate.queue_free()
			pending_stage = previous_pending
			current_battle = previous_battle
			return false
	if previous != null and is_instance_valid(previous) and previous != candidate:
		var previous_parent := previous.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(previous)
		previous.queue_free()
	content = candidate
	if is_battle:
		current_battle = candidate_battle
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
