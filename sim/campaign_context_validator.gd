class_name CampaignContextValidator
extends RefCounted

const CampaignProgressionScript := preload("res://sim/campaign_progression.gd")
const PromotionRulesResource := preload("res://data/progression/mage_advanced_v1.tres")

const KEYS := [
	"operator_ids", "trap_ids", "spell_ids", "stage_order", "stage_rewards",
	"stage_recovery_rosters", "offers", "starting_traps", "starting_spells",
	"promotion_rules", "combat_rules_sha256",
]


static func valid(context: Dictionary) -> bool:
	if not _exact_keys(context):
		return false
	var normalized := CampaignProgressionScript.normalize_promotion_rules(
		PromotionRulesResource,
		(context["operator_ids"] as Dictionary).keys(),
	)
	return (
		normalized["accepted"]
		and context["promotion_rules"] == normalized["value"]
		and _is_hex_sha256(String(context["combat_rules_sha256"]))
	)


static func _exact_keys(value: Dictionary) -> bool:
	if value.size() != KEYS.size():
		return false
	for key: String in KEYS:
		if not value.has(key):
			return false
	return true


static func _is_hex_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for character: String in value:
		if character not in "0123456789abcdef":
			return false
	return true
