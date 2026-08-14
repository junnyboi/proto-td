extends GutTest

const POLICY_DIR := "res://data/target_policies"
const RIGHT := Targeting.FACING_RIGHT


func _policy(policy_id: String) -> TargetPolicyDef:
	return load("%s/%s.tres" % [POLICY_DIR, policy_id]) as TargetPolicyDef


func _compiled(policy_id: String, owner_kind: int) -> Dictionary:
	return Targeting.compile(_policy(policy_id), owner_kind)


func _enemy(
	id: int,
	progress: int,
	aerial: bool = false,
	in_range: bool = true,
	relation: String = Targeting.RELATION_NONE,
	engagement_order: int = -1,
) -> Dictionary:
	return {
		"id": id,
		"alive": true,
		"faction": Targeting.FACTION_ENEMY,
		"relation": relation,
		"in_range": in_range,
		"aerial": aerial,
		"progress_units": progress,
		"distance": -1,
		"engagement_order": engagement_order,
	}


func _unit(
	id: int,
	distance: int,
	relation: String = Targeting.RELATION_DEPLOYED_UNIT,
	in_range: bool = true,
) -> Dictionary:
	return {
		"id": id,
		"alive": true,
		"faction": Targeting.FACTION_OPERATOR,
		"relation": relation,
		"in_range": in_range,
		"aerial": false,
		"progress_units": 0,
		"distance": distance,
	}


func _row(decision: Dictionary, entity_id: int) -> Dictionary:
	for value: Variant in decision["considered"]:
		var candidate := value as Dictionary
		if int(candidate["id"]) == entity_id:
			return candidate
	return {}


func _forward_pattern(xs: Array[int]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x: int in xs:
		for y: int in [-1, 0, 1]:
			out.append(Vector2i(x, y))
	return out


func test_rotation_and_range_cells() -> void:
	var offset := Vector2i(2, -1)
	assert_eq(Targeting.rotate_offset(offset, Targeting.FACING_RIGHT), Vector2i(2, -1))
	assert_eq(Targeting.rotate_offset(offset, Targeting.FACING_DOWN), Vector2i(1, 2))
	assert_eq(Targeting.rotate_offset(offset, Targeting.FACING_LEFT), Vector2i(-2, 1))
	assert_eq(Targeting.rotate_offset(offset, Targeting.FACING_UP), Vector2i(-1, -2))
	var cells := Targeting.range_cells(
		Vector2i(5, 3),
		[Vector2i(1, 0), Vector2i(2, 1)] as Array[Vector2i],
		Targeting.FACING_UP,
	)
	assert_true(cells.has(Vector2i(5, 2)))
	assert_true(cells.has(Vector2i(6, 1)))
	assert_eq(cells.size(), 2)


func test_frontmost_policy_is_permutation_invariant() -> void:
	var policy := _compiled(
		"operator_ground_only_frontmost", TargetPolicyDef.OwnerKind.OPERATOR
	)
	var a := _enemy(7, 500)
	var b := _enemy(3, 900)
	var c := _enemy(5, 900)
	var permutations := [
		[a, b, c], [a, c, b], [b, a, c],
		[b, c, a], [c, a, b], [c, b, a],
	]
	var expected := ""
	for candidate_order: Array in permutations:
		var decision := Targeting.decide(policy, "operator", 12, candidate_order)
		assert_eq(int(decision["selected_id"]), 3)
		assert_true(BattleObservation.recursive_primitive_only(decision))
		var canonical := CanonicalJson.text(decision)
		if expected == "":
			expected = canonical
		assert_eq(canonical, expected, "input order cannot change diagnostics")
	var tied := Targeting.decide(policy, "operator", 12, [a, b, c])
	assert_eq(tied["tie_break_reason"], "entity_id_tie_break")
	assert_eq(_row(tied, 5)["rejection_reason"], "entity_id_tie_break")


func test_aerial_first_and_ground_fallback_reasons() -> void:
	var policy := _compiled(
		"operator_aerial_first_frontmost", TargetPolicyDef.OwnerKind.OPERATOR
	)
	var decision := Targeting.decide(
		policy,
		"operator",
		4,
		[_enemy(1, 5000), _enemy(2, 100, true), _enemy(3, 9000, true, false)],
	)
	assert_eq(int(decision["selected_id"]), 2)
	assert_eq(_row(decision, 1)["rejection_reason"], "aerial_bucket_lost")
	assert_eq(_row(decision, 3)["rejection_reason"], "out_of_range")
	var fallback := Targeting.decide(policy, "operator", 4, [_enemy(1, 5000)])
	assert_eq(int(fallback["selected_id"]), 1)


func test_ground_only_excludes_aerial_and_handles_empty() -> void:
	var policy := _compiled(
		"operator_ground_only_frontmost", TargetPolicyDef.OwnerKind.OPERATOR
	)
	var decision := Targeting.decide(
		policy, "operator", 8, [_enemy(1, 9000, true), _enemy(2, 100)]
	)
	assert_eq(int(decision["selected_id"]), 2)
	assert_eq(_row(decision, 1)["rejection_reason"], "aerial_excluded")
	var empty := Targeting.decide(policy, "operator", 8, [])
	assert_eq(int(empty["selected_id"]), Targeting.NO_TARGET)
	assert_eq(empty["selection_reason"], "no_candidates")


func test_blocked_policy_preserves_assignment_order() -> void:
	var policy := _compiled(
		"operator_blocked_assignment_order", TargetPolicyDef.OwnerKind.OPERATOR
	)
	var decision := Targeting.decide(
		policy,
		"operator",
		0,
		[
			_enemy(9, 100, false, true, Targeting.RELATION_BLOCKED, 0),
			_enemy(2, 10, false, true, Targeting.RELATION_BLOCKED, 1),
			_enemy(1, 999),
		],
	)
	assert_eq(int(decision["selected_id"]), 9)
	assert_eq(_row(decision, 1)["rejection_reason"], "not_blocked")
	assert_eq(_row(decision, 2)["rejection_reason"], "later_engagement")


func test_enemy_blocker_then_nearest_is_explicit_and_stable() -> void:
	var policy := _compiled(
		"enemy_blocker_then_nearest", TargetPolicyDef.OwnerKind.ENEMY
	)
	var tied := Targeting.decide(policy, "enemy", 3, [_unit(7, 1), _unit(2, 1)])
	assert_eq(int(tied["selected_id"]), 2)
	assert_eq(tied["tie_break_reason"], "entity_id_tie_break")
	var blocked := Targeting.decide(
		policy,
		"enemy",
		3,
		[
			_unit(7, 0, Targeting.RELATION_CURRENT_BLOCKER),
			_unit(2, 0, Targeting.RELATION_DEPLOYED_UNIT),
		],
	)
	assert_eq(int(blocked["selected_id"]), 7)
	assert_eq(_row(blocked, 2)["rejection_reason"], "blocker_preferred")


func test_invalid_and_disabled_policies_fail_closed() -> void:
	var null_policy := Targeting.compile(null, TargetPolicyDef.OwnerKind.OPERATOR)
	var invalid := Targeting.decide(null_policy, "operator", 0, [_enemy(1, 100)])
	assert_eq(int(invalid["selected_id"]), Targeting.NO_TARGET)
	assert_eq(invalid["selection_reason"], "invalid_policy")
	assert_eq(_row(invalid, 1)["rejection_reason"], "invalid_policy")

	var unknown := TargetPolicyDef.new()
	unknown.id = &"future_policy"
	unknown.stable_entity_id_tie_break = true
	assert_eq(
		Targeting.validation_reason(unknown, TargetPolicyDef.OwnerKind.OPERATOR),
		"unknown_policy_id",
	)
	var contradictory := _policy("operator_ground_only_frontmost").duplicate(true)
	contradictory.aerial_rule = TargetPolicyDef.AerialRule.PREFER
	assert_eq(
		Targeting.validation_reason(contradictory, TargetPolicyDef.OwnerKind.OPERATOR),
		"contradictory_policy_shape",
	)
	var unstable := _policy("enemy_blocker_only").duplicate(true)
	unstable.stable_entity_id_tie_break = false
	assert_eq(
		Targeting.validation_reason(unstable, TargetPolicyDef.OwnerKind.ENEMY),
		"missing_stable_tie_break",
	)
	assert_eq(
		Targeting.validation_reason(
			_policy("enemy_blocker_only"), TargetPolicyDef.OwnerKind.OPERATOR
		),
		"owner_kind_mismatch",
	)
	var disabled := Targeting.decide(
		_compiled("no_automatic_target", TargetPolicyDef.OwnerKind.OPERATOR),
		"operator",
		5,
		[_enemy(1, 100)],
	)
	assert_eq(int(disabled["selected_id"]), Targeting.NO_TARGET)
	assert_eq(disabled["selection_reason"], "automatic_target_disabled")


func test_range_edge_and_splash_exactness() -> void:
	var cells := Targeting.range_cells(Vector2i.ZERO, _forward_pattern([1, 2, 3, 4]), RIGHT)
	assert_true(cells.has(Vector2i(4, 1)))
	assert_false(cells.has(Vector2i(5, 0)))
	assert_false(cells.has(Vector2i(-1, 0)))
	var splash_three := Targeting.splash_cells(Vector2i(4, 4), 3)
	assert_eq(splash_three.size(), 9)
	assert_true(splash_three.has(Vector2i(3, 3)))
	assert_true(splash_three.has(Vector2i(5, 5)))
	assert_false(splash_three.has(Vector2i(2, 4)))
	var splash_five := Targeting.splash_cells(Vector2i(4, 4), 5)
	assert_eq(splash_five.size(), 25)
	assert_true(splash_five.has(Vector2i(2, 4)))
