extends GutTest

const POLICY_DIR := "res://data/target_policies"
const OPERATOR_DIR := "res://data/operators"
const ENEMY_DIR := "res://data/enemies"

const OPERATOR_ASSIGNMENTS := {
	"recruit": "operator_blocked_assignment_order",
	"vanguard_1": "operator_blocked_assignment_order",
	"vanguard_2": "operator_blocked_assignment_order",
	"guard_1": "operator_blocked_assignment_order",
	"guard_2": "operator_blocked_assignment_order",
	"defender_1": "operator_blocked_assignment_order",
	"defender_2": "operator_blocked_assignment_order",
	"sniper_1": "operator_aerial_first_frontmost",
	"sniper_2": "operator_aerial_first_frontmost",
	"caster_1": "operator_ground_only_frontmost",
	"caster_2": "operator_ground_only_frontmost",
	"witch_doctor_1": "no_automatic_target",
}
const ENEMY_ASSIGNMENTS := {
	"drone": "enemy_blocker_only",
	"grunt": "enemy_blocker_only",
	"heavy": "enemy_blocker_only",
	"mini_boss": "enemy_blocker_only",
	"runner": "enemy_blocker_only",
	"spellcaster": "enemy_blocker_then_nearest",
}


func _resource_paths(directory: String, exclude_test_only: bool = false) -> Array[String]:
	var names: Array[String] = []
	for filename: String in DirAccess.open(directory).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			if exclude_test_only and source.begins_with("test_"):
				continue
			names.append(source)
	names.sort()
	var paths: Array[String] = []
	for filename: String in names:
		paths.append("%s/%s" % [directory, filename])
	return paths


func test_policy_catalog_is_closed_unique_and_valid() -> void:
	var paths := _resource_paths(POLICY_DIR)
	assert_eq(paths.size(), 6, "exactly the six shipping policies exist")
	var seen: Dictionary = {}
	for path: String in paths:
		var policy := load(path) as TargetPolicyDef
		assert_not_null(policy, "%s loads" % path)
		if policy == null:
			continue
		var policy_id := String(policy.id)
		assert_false(seen.has(policy_id), "policy IDs are unique: %s" % policy_id)
		seen[policy_id] = true
		assert_eq(
			Targeting.validation_reason(policy, int(policy.owner_kind)),
			"",
			"%s validates" % policy_id,
		)
		assert_true(
			BattleObservation.recursive_primitive_only(
				Targeting.compile(policy, int(policy.owner_kind))
			),
			"%s compiles to primitives" % policy_id,
		)
	assert_true(seen.has("no_automatic_target"))
	assert_true(seen.has("operator_blocked_assignment_order"))
	assert_true(seen.has("operator_aerial_first_frontmost"))
	assert_true(seen.has("operator_ground_only_frontmost"))
	assert_true(seen.has("enemy_blocker_only"))
	assert_true(seen.has("enemy_blocker_then_nearest"))


func test_every_canonical_operator_has_exact_explicit_policy() -> void:
	var paths := _resource_paths(OPERATOR_DIR)
	assert_eq(paths.size(), OPERATOR_ASSIGNMENTS.size())
	for path: String in paths:
		var definition := load(path) as OperatorDef
		assert_not_null(definition, "%s loads" % path)
		if definition == null:
			continue
		var actor_id := String(definition.id)
		assert_true(OPERATOR_ASSIGNMENTS.has(actor_id), "%s is catalogued" % actor_id)
		assert_not_null(definition.target_policy, "%s policy is explicit" % actor_id)
		if definition.target_policy == null:
			continue
		assert_eq(
			String(definition.target_policy.id),
			String(OPERATOR_ASSIGNMENTS[actor_id]),
			"%s assignment" % actor_id,
		)
		assert_eq(
			Targeting.validation_reason(
				definition.target_policy, TargetPolicyDef.OwnerKind.OPERATOR
			),
			"",
			"%s policy validates for operators" % actor_id,
		)


func test_every_canonical_enemy_has_exact_explicit_policy() -> void:
	var paths := _resource_paths(ENEMY_DIR, true)
	assert_eq(paths.size(), ENEMY_ASSIGNMENTS.size())
	for path: String in paths:
		var definition := load(path) as EnemyDef
		assert_not_null(definition, "%s loads" % path)
		if definition == null:
			continue
		var actor_id := String(definition.id)
		assert_true(ENEMY_ASSIGNMENTS.has(actor_id), "%s is catalogued" % actor_id)
		assert_not_null(definition.target_policy, "%s policy is explicit" % actor_id)
		if definition.target_policy == null:
			continue
		assert_eq(
			String(definition.target_policy.id),
			String(ENEMY_ASSIGNMENTS[actor_id]),
			"%s assignment" % actor_id,
		)
		assert_eq(
			Targeting.validation_reason(
				definition.target_policy, TargetPolicyDef.OwnerKind.ENEMY
			),
			"",
			"%s policy validates for enemies" % actor_id,
		)


func test_unknown_ordinals_and_missing_tie_break_fail_closed() -> void:
	var base := load(
		"%s/operator_ground_only_frontmost.tres" % POLICY_DIR
	) as TargetPolicyDef
	var bad_domain := base.duplicate(true) as TargetPolicyDef
	bad_domain.set("candidate_domain", 999)
	assert_eq(
		Targeting.validation_reason(bad_domain, TargetPolicyDef.OwnerKind.OPERATOR),
		"unknown_candidate_domain",
	)
	var bad_rank := base.duplicate(true) as TargetPolicyDef
	bad_rank.set("primary_rank", 999)
	assert_eq(
		Targeting.validation_reason(bad_rank, TargetPolicyDef.OwnerKind.OPERATOR),
		"unsupported_rank_key",
	)
	var missing_tie := base.duplicate(true) as TargetPolicyDef
	missing_tie.stable_entity_id_tie_break = false
	assert_eq(
		Targeting.validation_reason(missing_tie, TargetPolicyDef.OwnerKind.OPERATOR),
		"missing_stable_tie_break",
	)
