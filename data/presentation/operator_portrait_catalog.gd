class_name OperatorPortraitCatalog
extends RefCounted

## Presentation-only gender variant routing for non-premium portrait art.
##
## Campaign identity, command payloads, receipts, save bytes, and promotion
## authority stay unchanged. The already-persisted identity portrait selects a
## deterministic visual variant for class-kit previews in Training.

const FEMALE: StringName = &"female"
const MALE: StringName = &"male"

const IDENTITY_VARIANT_BY_PORTRAIT := {
	&"portrait_recruit_00": FEMALE,
	&"portrait_recruit_01": MALE,
	&"portrait_recruit_02": FEMALE,
	&"portrait_recruit_03": MALE,
	&"portrait_recruit_04": FEMALE,
	&"portrait_recruit_05": MALE,
	&"portrait_recruit_06": FEMALE,
	&"portrait_recruit_07": MALE,
}

const SPECIALIZATION_CLASS_IDS: Array[StringName] = [
	&"banner_guard",
	&"defender",
	&"gunner",
	&"immovable",
	&"mage_apprentice",
	&"shock_trooper",
	&"sniper",
	&"sorcerer",
	&"sword_saint",
	&"swordmaster",
	&"witch_doctor",
]


static func identity_variant(portrait_asset_id: StringName) -> StringName:
	return StringName(IDENTITY_VARIANT_BY_PORTRAIT.get(portrait_asset_id, FEMALE))


static func specialization_asset_id(
	class_id: StringName,
	identity_portrait_asset_id: StringName,
) -> StringName:
	if not SPECIALIZATION_CLASS_IDS.has(class_id):
		return &""
	return StringName(
		"portrait_specialization_%s_%s" % [
			class_id,
			identity_variant(identity_portrait_asset_id),
		]
	)


static func specialization_asset_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for class_id: StringName in SPECIALIZATION_CLASS_IDS:
		for variant: StringName in [FEMALE, MALE]:
			result.append(StringName(
				"portrait_specialization_%s_%s" % [class_id, variant]
			))
	return result


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if IDENTITY_VARIANT_BY_PORTRAIT.size() != 8:
		errors.append("identity variants: expected exactly eight Recruit portraits")
	for index: int in 8:
		var asset_id := StringName("portrait_recruit_%02d" % index)
		if not IDENTITY_VARIANT_BY_PORTRAIT.has(asset_id):
			errors.append("identity variants: missing %s" % asset_id)
			continue
		var expected := FEMALE if index % 2 == 0 else MALE
		if IDENTITY_VARIANT_BY_PORTRAIT[asset_id] != expected:
			errors.append("identity variants: %s expected %s" % [asset_id, expected])
	if SPECIALIZATION_CLASS_IDS.size() != 11:
		errors.append("specializations: expected exactly eleven classes")
	var unique := {}
	for asset_id: StringName in specialization_asset_ids():
		if unique.has(asset_id):
			errors.append("specializations: duplicate %s" % asset_id)
		unique[asset_id] = true
	return errors
