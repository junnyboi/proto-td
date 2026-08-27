extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0
const ArtType := preload("res://scripts/view/art.gd")
const CatalogType := preload("res://data/presentation/operator_portrait_catalog.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const PromotionPathCardType := preload("res://scripts/ui/components/promotion_path_card.gd")


class PromotedPortraitCampaign:
	extends RefCounted

	var _data := {
		"command_receipts": [],
		"heroes": [{
			"hero_id": "0000000000000042",
			"custom_callsign": "Vanguard Fixture",
			"name_version": 1,
			"recruitment_index": 0,
			"current_class_id": "shock_trooper",
			"operator_def_id": "vanguard_1",
			"portrait_asset_id": "portrait_recruit_01",
			"identity_portrait_id": "portrait_recruit_01",
			"life_status": "ready",
			"hero_kind": "recruit",
			"premium_id": null,
			"premium_lives": 0,
			"premium_pull_count": 0,
			"xp": 0,
		}],
	}

	func data_copy() -> Dictionary:
		return _data.duplicate(true)

	func promotion_options(_hero_id: Variant) -> Dictionary:
		return {"accepted": false, "error_code": &"insufficient_xp", "choices": []}

	func campaign_uid() -> String:
		return "promoted-portrait-fixture"

	func save_revision() -> int:
		return 1

	func strategic_hash() -> Dictionary:
		return {"accepted": true, "value": "promoted-portrait-fixture"}


const RECRUIT_PATHS := {
	&"portrait_recruit_00": "res://assets/portraits/recruits/solcrest_female.png",
	&"portrait_recruit_01": "res://assets/portraits/recruits/solcrest_male.png",
	&"portrait_recruit_02": "res://assets/portraits/recruits/vesper_female.png",
	&"portrait_recruit_03": "res://assets/portraits/recruits/vesper_male.png",
	&"portrait_recruit_04": "res://assets/portraits/recruits/lunaris_female.png",
	&"portrait_recruit_05": "res://assets/portraits/recruits/lunaris_male.png",
	&"portrait_recruit_06": "res://assets/portraits/recruits/crimson_female.png",
	&"portrait_recruit_07": "res://assets/portraits/recruits/crimson_male.png",
}

const LEGACY_IDS: Array[StringName] = [
	&"portrait_caster_1",
	&"portrait_caster_2",
	&"portrait_defender_1",
	&"portrait_defender_2",
	&"portrait_guard_1",
	&"portrait_guard_2",
	&"portrait_sniper_1",
	&"portrait_sniper_2",
	&"portrait_vanguard_1",
	&"portrait_vanguard_2",
	&"portrait_witch_doctor_1",
]

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var manifest := load("res://assets/manifest.tres")
	_check(manifest != null, "asset manifest did not load")
	if manifest != null:
		var diagnostics: PackedStringArray = manifest.call("validate_contract")
		_check(diagnostics.is_empty(), "asset manifest contract failed: %s" % diagnostics)

	var catalog_diagnostics := CatalogType.validate_contract()
	_check(
		catalog_diagnostics.is_empty(),
		"portrait catalog contract failed: %s" % catalog_diagnostics,
	)
	_check(CatalogType.specialization_asset_ids().size() == 22, "specialization matrix is not 11 male/female pairs")
	_check(
		CatalogType.presentation_asset_id(
			&"recruit", &"portrait_recruit_00",
		) == &"portrait_recruit_00",
		"unpromoted Recruit did not retain its identity portrait",
	)
	for class_id: StringName in CatalogType.SPECIALIZATION_CLASS_IDS:
		_check(
			CatalogType.presentation_asset_id(class_id, &"portrait_recruit_00")
			== StringName("portrait_specialization_%s_female" % class_id),
			"female promoted portrait resolved incorrectly for %s" % class_id,
		)
		_check(
			CatalogType.presentation_asset_id(class_id, &"portrait_recruit_01")
			== StringName("portrait_specialization_%s_male" % class_id),
			"male promoted portrait resolved incorrectly for %s" % class_id,
		)
	_check(
		CatalogType.presentation_asset_id(
			&"mage_apprentice", &"portrait_archive_caster", true,
		) == &"portrait_archive_caster",
		"premium portrait lost precedence over promoted-class art",
	)
	var promoted_male := {
		"current_class_id": "defender",
		"portrait_asset_id": "portrait_recruit_01",
		"hero_kind": "recruit",
	}
	_check(
		TrainingSupportType.presentation_portrait_asset_id(promoted_male)
		== &"portrait_specialization_defender_male",
		"Training presentation did not replace a promoted male Recruit portrait",
	)
	promoted_male["current_class_id"] = "immovable"
	_check(
		TrainingSupportType.presentation_portrait_asset_id(promoted_male)
		== &"portrait_specialization_immovable_male",
		"second-stage promotion did not preserve the male portrait variant",
	)
	promoted_male["identity_portrait_asset_id"] = "portrait_recruit_01"
	promoted_male["portrait_asset_id"] = "portrait_specialization_defender_male"
	_check(
		TrainingSupportType.presentation_portrait_asset_id(promoted_male)
		== &"portrait_specialization_immovable_male",
		"repeated presentation projection reinterpreted a male specialization portrait",
	)
	var promoted_rows := TrainingSupportType.roster(PromotedPortraitCampaign.new())
	_check(promoted_rows.size() == 1, "Training roster rejected promoted campaign fixture")
	if promoted_rows.size() == 1:
		_check(
			promoted_rows[0]["identity_portrait_asset_id"] == "portrait_recruit_01",
			"Training roster mutated the persisted male Recruit portrait",
		)
		_check(
			promoted_rows[0]["portrait_asset_id"]
			== "portrait_specialization_shock_trooper_male",
			"Training roster did not display the promoted male Fast Vanguard portrait",
		)

	for index: int in 8:
		var recruit_id := StringName("portrait_recruit_%02d" % index)
		_check(RECRUIT_PATHS.has(recruit_id), "missing Recruit path fixture for %s" % recruit_id)
		_check(
			CatalogType.identity_variant(recruit_id) == (
				CatalogType.FEMALE if index % 2 == 0 else CatalogType.MALE
			),
			"Recruit variant parity drifted for %s" % recruit_id,
		)
		_check_portrait(recruit_id, String(RECRUIT_PATHS.get(recruit_id, "")))

	for specialization_id: StringName in CatalogType.specialization_asset_ids():
		var metadata := ArtType.metadata(specialization_id)
		_check(
			String(metadata.get("pattern", "")).begins_with(
				"res://assets/portraits/specializations/"
			),
			"specialization path is outside generated directory for %s" % specialization_id,
		)
		_check_portrait(specialization_id, String(metadata.get("pattern", "")))

	for legacy_id: StringName in LEGACY_IDS:
		var metadata := ArtType.metadata(legacy_id)
		_check(metadata.get("placeholder", true) == false, "legacy alias stayed placeholder: %s" % legacy_id)
		_check(ArtType.size(legacy_id) == Vector2i(512, 512), "legacy alias size is not 512px: %s" % legacy_id)
		_check(ArtType.texture(legacy_id) != null, "legacy alias texture did not load: %s" % legacy_id)

	var raw_choices: Array = [{
		"from_class_id": "recruit",
		"to_class_id": "defender",
		"operator_def_id": "defender_1",
	}]
	var female := TrainingSupportType.enrich_choices(raw_choices, "portrait_recruit_00")
	var male := TrainingSupportType.enrich_choices(raw_choices, "portrait_recruit_01")
	_check(bool(female.get("accepted", false)), "female Training choice projection rejected")
	_check(bool(male.get("accepted", false)), "male Training choice projection rejected")
	if bool(female.get("accepted", false)) and bool(male.get("accepted", false)):
		var female_choice := (female["choices"] as Array)[0] as Dictionary
		var male_choice := (male["choices"] as Array)[0] as Dictionary
		_check(
			female_choice["specialization_portrait_asset_id"]
			== &"portrait_specialization_defender_female",
			"female Defender preview resolved incorrectly",
		)
		_check(
			male_choice["specialization_portrait_asset_id"]
			== &"portrait_specialization_defender_male",
			"male Defender preview resolved incorrectly",
		)
		var card := PromotionPathCardType.new()
		root.add_child(card)
		card.configure(
			male_choice,
			"DEFENDER",
			"LANE ANCHOR",
			"Blocks several enemies.",
			"HOLD THE LINE",
			"DP 16",
			"CLASS KIT",
			"FIELD KIT • AFTER CONFIRMATION",
		)
		var texture_rect := card.find_child("ClassKitPortrait", true, false) as TextureRect
		_check(
			card.portrait_asset_id == &"portrait_specialization_defender_male",
			"path card did not preserve explicit male preview ID",
		)
		_check(texture_rect != null and texture_rect.texture != null, "path card did not load generated male Defender texture")
		card.queue_free()
		await process_frame

	_finish()


func _check_portrait(asset_id: StringName, expected_path: String) -> void:
	var metadata := ArtType.metadata(asset_id)
	_check(not metadata.is_empty(), "manifest metadata missing for %s" % asset_id)
	_check(String(metadata.get("pattern", "")) == expected_path, "manifest path mismatch for %s" % asset_id)
	_check(metadata.get("placeholder", true) == false, "portrait stayed placeholder: %s" % asset_id)
	_check(ArtType.size(asset_id) == Vector2i(512, 512), "portrait size is not 512px: %s" % asset_id)
	_check(ArtType.texture(asset_id) != null, "portrait texture did not load: %s" % asset_id)
	_check(FileAccess.file_exists(expected_path), "portrait file missing: %s" % expected_path)
	if FileAccess.file_exists(expected_path):
		var image := Image.new()
		var load_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(expected_path))
		_check(load_error == OK and not image.is_empty(), "portrait image failed to decode: %s" % asset_id)
		if load_error == OK and not image.is_empty():
			_check(image.get_size() == Vector2i(512, 512), "decoded portrait is not 512px: %s" % asset_id)
			_check(image.detect_alpha() != Image.ALPHA_NONE, "decoded portrait has no alpha: %s" % asset_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _on_timeout() -> void:
	if _finished:
		return
	_failures.append("test timed out")
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("NONPREMIUM_PORTRAIT_CATALOG_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("nonpremium_portrait_catalog_test: %s" % failure)
	quit(1)
