extends RefCounted

const REQUIRED_CAMPAIGN_METHODS := [
	&"training_roster", &"promotion_options", &"promote_hero", &"campaign_uid",
	&"save_revision", &"strategic_hash",
]


static func supports_campaign(value: Variant) -> bool:
	if value == null:
		return false
	for method_name: StringName in REQUIRED_CAMPAIGN_METHODS:
		if not value.has_method(method_name):
			return false
	return true
