class_name StagingMockWallet
extends RefCounted

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

## Presentation scaffolding only. These values are not authoritative, persistent,
## spendable, purchasable, or connected to campaign progression.
const AETHER := 12_450
const ASTRAL_SIGILS := 1_240
const STAMINA := 88
const STAMINA_CAPACITY := 120


static func resources() -> Array[Dictionary]:
	return [
		{
			&"id": &"aether",
			&"name_key": &"ui.staging.resource_aether",
			&"name_fallback": "Aether",
			&"value": AETHER,
			&"capacity": -1,
			&"icon": StagingSkinType.AETHER_ICON,
			&"show_plus": true,
		},
		{
			&"id": &"astral_sigils",
			&"name_key": &"ui.staging.resource_sigils",
			&"name_fallback": "Astral Sigils",
			&"value": ASTRAL_SIGILS,
			&"capacity": -1,
			&"icon": StagingSkinType.SIGIL_ICON,
			&"show_plus": true,
		},
		{
			&"id": &"stamina",
			&"name_key": &"ui.staging.resource_stamina",
			&"name_fallback": "Stamina",
			&"value": STAMINA,
			&"capacity": STAMINA_CAPACITY,
			&"icon": StagingSkinType.STAMINA_ICON,
			&"show_plus": true,
		},
	]


static func formatted_value(row: Dictionary) -> String:
	var value := int(row.get(&"value", 0))
	var capacity := int(row.get(&"capacity", -1))
	if capacity > 0:
		return "%s / %s" % [_with_grouping(value), _with_grouping(capacity)]
	return _with_grouping(value)


static func _with_grouping(value: int) -> String:
	var digits := str(absi(value))
	var chunks: Array[String] = []
	while digits.length() > 3:
		chunks.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	chunks.push_front(digits)
	return ("-" if value < 0 else "") + ",".join(chunks)
