extends GutTest

const DamageRulesScript := preload("res://sim/damage_rules.gd")
const PHYSICAL := int(DamageRulesScript.Kind.PHYSICAL)
const ARTS := int(DamageRulesScript.Kind.ARTS)


func test_raw_zero_and_invalid_inputs_fail_closed() -> void:
	assert_eq(DamageRulesScript.resolve(0, PHYSICAL, 999, 999), 0)
	assert_eq(DamageRulesScript.resolve(-1, PHYSICAL, 0, 0), 0)
	assert_eq(DamageRulesScript.resolve(20, 99, 0, 0), 0)
	assert_eq(DamageRulesScript.resolve(20, PHYSICAL, -1, 0), 0)
	assert_eq(DamageRulesScript.resolve(20, ARTS, 0, -1), 0)
	assert_eq(DamageRulesScript.resolve(20, ARTS, 0, 1001), 0)
	assert_false(DamageRulesScript.authored_values_valid(99, 0, 0))
	assert_false(DamageRulesScript.authored_values_valid(PHYSICAL, -1, 0))
	assert_false(DamageRulesScript.authored_values_valid(ARTS, 0, 1001))


func test_physical_uses_flat_defense_with_five_percent_minimum() -> void:
	assert_eq(DamageRulesScript.resolve(10, PHYSICAL, 0, 0), 10)
	assert_eq(DamageRulesScript.resolve(10, PHYSICAL, 3, 0), 7)
	assert_eq(DamageRulesScript.resolve(10, PHYSICAL, 10, 0), 1)
	assert_eq(DamageRulesScript.resolve(10, PHYSICAL, 999, 0), 1)
	assert_eq(DamageRulesScript.resolve(20, PHYSICAL, 19, 0), 1)
	assert_eq(DamageRulesScript.resolve(21, PHYSICAL, 21, 0), 2)


func test_arts_uses_permille_resistance_with_one_floor() -> void:
	assert_eq(DamageRulesScript.resolve(10, ARTS, 0, 0), 10)
	assert_eq(DamageRulesScript.resolve(10, ARTS, 0, 500), 5)
	assert_eq(DamageRulesScript.resolve(10, ARTS, 0, 900), 1)
	assert_eq(DamageRulesScript.resolve(10, ARTS, 0, 1000), 1)
	assert_eq(DamageRulesScript.resolve(21, ARTS, 0, 500), 10)
	assert_eq(DamageRulesScript.resolve(21, ARTS, 0, 999), 2)


func test_physical_and_arts_are_monotone_and_bounded() -> void:
	for raw: int in range(1, 201):
		@warning_ignore("integer_division")
		var minimum := raw / 20 + (1 if raw % 20 != 0 else 0)
		var previous_physical := raw
		for defense: int in range(0, 251):
			var physical := DamageRulesScript.resolve(raw, PHYSICAL, defense, 0)
			assert_true(physical >= minimum and physical <= raw)
			assert_true(physical <= previous_physical)
			previous_physical = physical
		var previous_arts := raw
		for resistance: int in range(0, 1001):
			var arts := DamageRulesScript.resolve(raw, ARTS, 0, resistance)
			assert_true(arts >= minimum and arts <= raw)
			assert_true(arts <= previous_arts)
			previous_arts = arts


func test_large_integer_math_does_not_overflow() -> void:
	var huge := 9_000_000_000_000_000_000
	assert_eq(DamageRulesScript.resolve(huge, PHYSICAL, 1, 0), huge - 1)
	assert_eq(DamageRulesScript.resolve(huge, ARTS, 0, 500), 4_500_000_000_000_000_000)
	assert_eq(DamageRulesScript.resolve(huge, ARTS, 0, 1000), 450_000_000_000_000_000)
