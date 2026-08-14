extends GutTest


func _observation() -> Dictionary:
	return {
		"dp": 99,
		"spells": [{"spell_id": "charm", "ready": true}],
		"deployability": [{"op_id": "vanguard_1", "ready": true}],
		"trap_readiness": [{"trap_id": "spike_plate", "ready": true}],
		"traps_placed_total": 0,
		"operators": [],
		"enemies": [
			{
				"id": 9, "enemy_id": "heavy", "charm_eligible": true,
				"progress_units": 100, "threat": 4000,
			},
			{
				"id": 2, "enemy_id": "heavy", "charm_eligible": true,
				"progress_units": 200, "threat": 3000,
			},
		],
		"paths": [
			{
				"path_idx": 0, "active_count": 2, "upcoming_count": 0,
				"pressure": 50, "upcoming_mass": 0,
			},
			{
				"path_idx": 1, "active_count": 1, "upcoming_count": 2,
				"pressure": 100, "upcoming_mass": 9,
			},
		],
	}


func test_charm_priority_progress_ranking_and_one_action() -> void:
	var policy := Stage06ConditionalPolicy.new()
	var decision := policy.decide(_observation())
	assert_eq(decision["reason"], "charm_highest_threat_heavy")
	assert_eq(decision["action"], ["cast", "charm", 9])
	assert_eq((decision["action"] as Array).size(), 3)
	assert_gt((decision["considered_candidates"] as Array).size(), 1)


func test_source_permutation_and_immutable_input() -> void:
	var policy := Stage06ConditionalPolicy.new()
	var a := _observation()
	var b := a.duplicate(true)
	(b["enemies"] as Array).reverse()
	(b["paths"] as Array).reverse()
	var before := CanonicalJson.sha256_hex(a)
	assert_eq(policy.decide(a), policy.decide(b))
	assert_eq(CanonicalJson.sha256_hex(a), before)


func test_ablation_removes_only_charm_and_reuses_policy() -> void:
	var full := Stage06ConditionalPolicy.new()
	var no_charm_caps := full.capabilities()
	no_charm_caps.erase("charm")
	var ablated := Stage06ConditionalPolicy.new(no_charm_caps)
	assert_eq(full.capabilities(), ["charm", "deploy", "skill", "trap"])
	assert_eq(ablated.capabilities(), ["deploy", "skill", "trap"])
	var decision := ablated.decide(_observation())
	assert_eq(decision["reason"], "deploy_lane_holder_0")
	assert_eq(decision["action"][0], "deploy")
