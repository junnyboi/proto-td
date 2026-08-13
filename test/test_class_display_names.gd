extends GutTest

const EXPECTED_DISPLAY_NAMES := {
	&"vanguard_1": "Shock Trooper",
	&"vanguard_2": "Banner Guard",
	&"guard_1": "Swordmaster",
	&"guard_2": "Sword Saint",
	&"defender_1": "Defender",
	&"defender_2": "Immovable",
	&"sniper_1": "Gunner",
	&"sniper_2": "Sniper",
	&"caster_1": "Mage Apprentice",
	&"caster_2": "Sorcerer",
}
const OLD_DISPLAY_NAMES := [
	"Vanguard",
	"Bannerguard",
	"Swiftblade",
	"Brandmaster",
	"Aegiswall",
	"Longshot",
	"Falconeye",
	"Emberweaver",
	"Stormcaller",
]


func test_existing_template_ids_keep_exact_plain_display_names() -> void:
	for operator_id: StringName in EXPECTED_DISPLAY_NAMES:
		var path := "res://data/operators/%s.tres" % operator_id
		var operator := load(path) as OperatorDef
		assert_not_null(operator, path)
		assert_eq(operator.id, operator_id, "%s internal ID" % operator_id)
		assert_eq(
			operator.display_name,
			EXPECTED_DISPLAY_NAMES[operator_id],
			"%s display name" % operator_id,
		)
		assert_false(
			operator.display_name in OLD_DISPLAY_NAMES,
			"%s has no obsolete display name" % operator_id,
		)


func test_sorcerer_keeps_existing_caster_2_tempest_projection() -> void:
	var sorcerer := load("res://data/operators/caster_2.tres") as OperatorDef
	assert_not_null(sorcerer)
	assert_eq(sorcerer.id, &"caster_2")
	assert_not_null(sorcerer.skill)
	assert_eq(sorcerer.skill.id, &"tempest")


func test_s2_hint_uses_shock_trooper_name() -> void:
	var stage := load("res://data/stages/s2.tres") as StageDef
	assert_not_null(stage)
	assert_true(stage.intro_hint.contains("Shock Trooper"), stage.intro_hint)
	for old_name: String in OLD_DISPLAY_NAMES:
		assert_false(stage.intro_hint.contains(old_name), "S2 hint contains obsolete %s" % old_name)
