class_name CampaignSaveUpgrade
extends RefCounted

const PRE_PROMOTION_DATA_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
	"resolution_anchor", "last_resolution",
]
const PRE_PROMOTION_CORE_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
]
const PRE_PROOF_DATA_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
	"promotion_receipts", "resolution_anchor", "last_resolution",
]
const PRE_PROOF_CORE_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
	"promotion_receipts",
]
const CURRENT_DATA_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
	"promotion_receipts", "promotion_proofs", "resolution_anchor", "last_resolution",
]
const CURRENT_CORE_KEYS := [
	"campaign_uid", "campaign_seed", "campaign_generation", "save_revision",
	"next_recruitment_index", "next_attempt_id", "next_resolution_index", "marks",
	"stage_stars", "unlocked_traps", "unlocked_spells", "offers", "heroes",
	"promotion_receipts", "promotion_proofs",
]


static func is_pre_promotion_v2(value: Variant) -> bool:
	return typeof(value) == TYPE_DICTIONARY and (
		_exact_keys(value as Dictionary, PRE_PROMOTION_DATA_KEYS)
		or _exact_keys(value as Dictionary, PRE_PROOF_DATA_KEYS)
	)


static func upgrade(value: Dictionary) -> Dictionary:
	if not is_pre_promotion_v2(value):
		return {}
	if value.has("promotion_receipts") and not value["promotion_receipts"].is_empty():
		return {}
	var source: Dictionary = value.duplicate(true)
	if source["resolution_anchor"] != null:
		if typeof(source["resolution_anchor"]) != TYPE_DICTIONARY:
			return {}
		for key: String in ["before_core", "after_core"]:
			var prior: Variant = source["resolution_anchor"].get(key)
			if typeof(prior) != TYPE_DICTIONARY:
				return {}
			var upgraded_core := _upgrade_core(prior)
			if upgraded_core.is_empty():
				return {}
			source["resolution_anchor"][key] = upgraded_core
	var result := {}
	for key: String in CURRENT_DATA_KEYS:
		result[key] = [] if key in ["promotion_receipts", "promotion_proofs"] else source[key]
	return result


static func decode(
	parsed: Dictionary,
	source: String,
	context: Dictionary,
	encode_save: Callable,
) -> Dictionary:
	var source_version := int(parsed["version"])
	var legacy := source_version == 1
	var additive := source_version == 2 and is_pre_promotion_v2(parsed["data"])
	if not legacy and not additive:
		return {"handled": false}
	if CanonicalJson.text(parsed) != source:
		return {"handled": true, "result": _reject(&"noncanonical_save")}
	if CanonicalJson.sha256_hex(parsed["data"]) != String(parsed["checksum"]):
		return {"handled": true, "result": _reject(&"checksum_mismatch")}
	var data_result := (
		CampaignMigration.migrate_v1_data(parsed["data"], context)
		if legacy else {"accepted": true, "value": parsed["data"]}
	)
	if not data_result["accepted"]:
		return {"handled": true, "result": data_result}
	var encoded: Dictionary = encode_save.call(data_result["value"], context)
	if not encoded["accepted"]:
		return {"handled": true, "result": encoded}
	return {"handled": true, "result": {
		"accepted": true, "error_code": &"",
		"data": encoded["value"]["data"], "value": encoded["value"],
		"text": encoded["text"], "bytes": encoded["bytes"],
		"sha256": encoded["sha256"], "migrated_from_version": source_version,
	}}


static func _upgrade_core(value: Dictionary) -> Dictionary:
	if (
		not _exact_keys(value, PRE_PROMOTION_CORE_KEYS)
		and not _exact_keys(value, PRE_PROOF_CORE_KEYS)
	):
		return {}
	if value.has("promotion_receipts") and not value["promotion_receipts"].is_empty():
		return {}
	var result := {}
	for key: String in CURRENT_CORE_KEYS:
		result[key] = [] if key in ["promotion_receipts", "promotion_proofs"] else value[key]
	return result


static func _exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	var actual: Array = value.keys()
	for index: int in expected.size():
		if actual[index] != expected[index]:
			return false
	return true


static func _reject(error_code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": error_code}
