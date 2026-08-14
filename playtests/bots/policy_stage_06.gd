class_name Stage06ConditionalPolicy
extends ConditionalPolicy

## Stable evaluator order: Charm, lane-holder deploy, trap, then ready skill.

const CHARM_PRIORITY := 4_000_000
const DEPLOY_PRIORITY := 3_000_000
const TRAP_PRIORITY := 2_000_000
const SKILL_PRIORITY := 1_000_000

const HOLDERS: Array[Dictionary] = [
	{"op_id": "vanguard_1", "path_idx": 1, "cell": {"x": 4, "y": 4}, "facing": 0},
	{"op_id": "guard_1", "path_idx": 1, "cell": {"x": 5, "y": 4}, "facing": 0},
	{"op_id": "guard_2", "path_idx": 1, "cell": {"x": 6, "y": 4}, "facing": 0},
]
const TRAP := {
	"trap_id": "spike_plate", "path_idx": 1, "cell": {"x": 3, "y": 4}, "mass": 5,
}
const SKILL_DENSITY := 2

var _capabilities: Array[String] = []


func _init(capabilities: Array[String] = ["charm", "deploy", "trap", "skill"]) -> void:
	_capabilities = capabilities.duplicate()
	_capabilities.sort()


func capabilities() -> Array[String]:
	return _capabilities.duplicate()


func decide(observation: Dictionary) -> Dictionary:
	var considered: Array = []
	_consider_charm(observation, considered)
	_consider_deploy(observation, considered)
	_consider_trap(observation, considered)
	_consider_skill(observation, considered)
	considered.sort_custom(_candidate_before)
	if considered.is_empty():
		return {"action": [], "reason": "idle", "considered_candidates": []}
	var winner := considered[0] as Dictionary
	return {
		"action": (winner["action"] as Array).duplicate(true),
		"reason": String(winner["reason"]),
		"considered_candidates": considered.duplicate(true),
	}


func _consider_charm(observation: Dictionary, out: Array) -> void:
	if not _capabilities.has("charm") or not _ready(observation, "spells", "spell_id", "charm"):
		return
	for value: Variant in observation.get("enemies", []):
		var enemy := value as Dictionary
		if not bool(enemy.get("charm_eligible", false)) or String(enemy["enemy_id"]) != "heavy":
			continue
		out.append({
			"priority": CHARM_PRIORITY + int(enemy["threat"]),
			"progress": int(enemy["progress_units"]),
			"stable_id": "%010d" % int(enemy["id"]),
			"reason": "charm_highest_threat_heavy",
			"action": ["cast", "charm", int(enemy["id"])],
			"threat": int(enemy["threat"]),
		})


func _consider_deploy(observation: Dictionary, out: Array) -> void:
	if not _capabilities.has("deploy"):
		return
	for index: int in HOLDERS.size():
		var holder := HOLDERS[index]
		if _operator_alive(observation, String(holder["op_id"])):
			continue
		var lane := _lane(observation, int(holder["path_idx"]))
		if lane.is_empty() or not _lane_pressured(lane):
			return
		if not _ready(observation, "deployability", "op_id", String(holder["op_id"])):
			return
		var cell := holder["cell"] as Dictionary
		out.append({
			"priority": DEPLOY_PRIORITY + int(lane["pressure"]),
			"progress": int(lane["pressure"]),
			"stable_id": String(holder["op_id"]),
			"reason": "deploy_lane_holder_%d" % index,
			"action": [
				"deploy",
				String(holder["op_id"]),
				{"x": int(cell["x"]), "y": int(cell["y"])},
				int(holder["facing"]),
			],
		})
		return


func _consider_trap(observation: Dictionary, out: Array) -> void:
	if not _capabilities.has("trap"):
		return
	if int(observation.get("traps_placed_total", 0)) > 0:
		return
	if not _ready(observation, "trap_readiness", "trap_id", String(TRAP["trap_id"])):
		return
	var lane := _lane(observation, int(TRAP["path_idx"]))
	if lane.is_empty() or int(lane["upcoming_mass"]) < int(TRAP["mass"]):
		return
	var cell := TRAP["cell"] as Dictionary
	out.append({
		"priority": TRAP_PRIORITY + int(lane["upcoming_mass"]),
		"progress": int(lane["upcoming_mass"]),
		"stable_id": String(TRAP["trap_id"]),
		"reason": "trap_upcoming_mass",
		"action": [
			"place_trap",
			String(TRAP["trap_id"]),
			{"x": int(cell["x"]), "y": int(cell["y"])},
		],
	})


func _consider_skill(observation: Dictionary, out: Array) -> void:
	if not _capabilities.has("skill"):
		return
	for value: Variant in observation.get("operators", []):
		var unit := value as Dictionary
		if not bool(unit["alive"]) or not bool(unit["skill_ready"]):
			continue
		var lane := _lane(observation, int(unit["path_idx"]))
		if lane.is_empty() or int(lane["active_count"]) < SKILL_DENSITY:
			continue
		out.append({
			"priority": SKILL_PRIORITY + int(lane["active_count"]),
			"progress": int(lane["active_count"]),
			"stable_id": "%010d" % int(unit["id"]),
			"reason": "skill_density",
			"action": ["trigger_skill", int(unit["id"])],
		})


func _lane_pressured(lane: Dictionary) -> bool:
	return int(lane["active_count"]) > 0 or int(lane["upcoming_count"]) > 0


func _operator_alive(observation: Dictionary, op_id: String) -> bool:
	for value: Variant in observation.get("operators", []):
		var unit := value as Dictionary
		if String(unit["op_id"]) == op_id and bool(unit["alive"]):
			return true
	return false


func _ready(observation: Dictionary, rows_key: String, id_key: String, text_id: String) -> bool:
	for value: Variant in observation.get(rows_key, []):
		var row := value as Dictionary
		if String(row[id_key]) == text_id:
			return bool(row["ready"])
	return false


func _lane(observation: Dictionary, path_idx: int) -> Dictionary:
	for value: Variant in observation.get("paths", []):
		var lane := value as Dictionary
		if int(lane["path_idx"]) == path_idx:
			return lane
	return {}


func _candidate_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a["priority"]) != int(b["priority"]):
		return int(a["priority"]) > int(b["priority"])
	if int(a["progress"]) != int(b["progress"]):
		return int(a["progress"]) > int(b["progress"])
	return String(a["stable_id"]) < String(b["stable_id"])
