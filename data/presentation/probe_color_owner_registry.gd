class_name ProbeColorOwnerRegistry
extends Resource

const ROW_KEYS: Array[String] = [
	"color_html", "owner_kind", "owner_id", "source_path", "symbol", "semantic",
	"status", "negative_owner_id", "differential_required",
]
const COLORS: Array[String] = ["f4f4f4", "41a6f6"]
const OWNER_KINDS: Array[StringName] = [&"asset", &"view_effect", &"ui_legacy_exception"]
const SEMANTICS: Array[StringName] = [
	&"trap_sprung_flash", &"charm_swirl", &"attack_tracer", &"skill_ready_flash",
	&"route_chevron", &"charmed_unit_tint", &"staging_text", &"charmed_variant_signal",
	&"spell_icon_highlight",
]
const STATUSES: Array[StringName] = [&"probe_owner", &"legacy_exception"]
const EXPECTED_ENTRIES: Array[Dictionary] = [
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"juice_layer.trap_sprung_flash",
		"owner_kind": &"view_effect",
		"semantic": &"trap_sprung_flash",
		"source_path": "res://scripts/view/juice_layer.gd",
		"status": &"probe_owner",
		"symbol": &"SPRUNG_COLOR",
	},
	{
		"color_html": "41a6f6",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"juice_layer.charm_swirl",
		"owner_kind": &"view_effect",
		"semantic": &"charm_swirl",
		"source_path": "res://scripts/view/juice_layer.gd",
		"status": &"probe_owner",
		"symbol": &"SWIRL_COLOR",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"battle_view.attack_tracer",
		"owner_kind": &"view_effect",
		"semantic": &"attack_tracer",
		"source_path": "res://scripts/view/battle_view.gd",
		"status": &"probe_owner",
		"symbol": &"TRACER_COLOR",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"battle_view.skill_ready_flash",
		"owner_kind": &"view_effect",
		"semantic": &"skill_ready_flash",
		"source_path": "res://scripts/view/battle_view.gd",
		"status": &"probe_owner",
		"symbol": &"SP_FULL_FLASH",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"battle_view.route_chevron",
		"owner_kind": &"view_effect",
		"semantic": &"route_chevron",
		"source_path": "res://scripts/view/battle_view.gd",
		"status": &"probe_owner",
		"symbol": &"CHEVRON_COLOR",
	},
	{
		"color_html": "41a6f6",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"battle_view.charmed_unit_tint",
		"owner_kind": &"view_effect",
		"semantic": &"charmed_unit_tint",
		"source_path": "res://scripts/view/battle_view.gd",
		"status": &"probe_owner",
		"symbol": &"CHARMED_COLOR",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"staging.text_color",
		"owner_kind": &"ui_legacy_exception",
		"semantic": &"staging_text",
		"source_path": "res://scripts/ui/staging.gd",
		"status": &"legacy_exception",
		"symbol": &"TEXT_COLOR",
	},
	{
		"color_html": "41a6f6",
		"differential_required": true,
		"negative_owner_id": &"grunt",
		"owner_id": &"grunt_charmed",
		"owner_kind": &"asset",
		"semantic": &"charmed_variant_signal",
		"source_path": "res://assets/sprites/grunt_charmed_%d.png",
		"status": &"probe_owner",
		"symbol": &"",
	},
	{
		"color_html": "41a6f6",
		"differential_required": true,
		"negative_owner_id": &"heavy",
		"owner_id": &"heavy_charmed",
		"owner_kind": &"asset",
		"semantic": &"charmed_variant_signal",
		"source_path": "res://assets/sprites/heavy_charmed_%d.png",
		"status": &"probe_owner",
		"symbol": &"",
	},
	{
		"color_html": "41a6f6",
		"differential_required": true,
		"negative_owner_id": &"runner",
		"owner_id": &"runner_charmed",
		"owner_kind": &"asset",
		"semantic": &"charmed_variant_signal",
		"source_path": "res://assets/sprites/runner_charmed_%d.png",
		"status": &"probe_owner",
		"symbol": &"",
	},
	{
		"color_html": "41a6f6",
		"differential_required": true,
		"negative_owner_id": &"spellcaster",
		"owner_id": &"spellcaster_charmed",
		"owner_kind": &"asset",
		"semantic": &"charmed_variant_signal",
		"source_path": "res://assets/sprites/spellcaster_charmed_%d.png",
		"status": &"probe_owner",
		"symbol": &"",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"icon_bolt",
		"owner_kind": &"asset",
		"semantic": &"spell_icon_highlight",
		"source_path": "res://assets/sprites/icon_bolt.png",
		"status": &"legacy_exception",
		"symbol": &"",
	},
	{
		"color_html": "f4f4f4",
		"differential_required": false,
		"negative_owner_id": &"",
		"owner_id": &"icon_charm",
		"owner_kind": &"asset",
		"semantic": &"spell_icon_highlight",
		"source_path": "res://assets/sprites/icon_charm.png",
		"status": &"legacy_exception",
		"symbol": &"",
	},
]

@export var schema_version: int = 1
@export var entries: Array[Dictionary] = []


static func expected_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in EXPECTED_ENTRIES:
		result.append(row.duplicate(true))
	return result


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	if entries.is_empty():
		errors.append("entries: required")
	var seen: Dictionary = {}
	for index: int in entries.size():
		var row: Dictionary = entries[index]
		_validate_row(index, row, errors)
		var identity := "%s|%s|%s|%s|%s" % [
			row.get(&"color_html", ""), row.get(&"owner_kind", &""),
			row.get(&"owner_id", &""), row.get(&"source_path", ""), row.get(&"symbol", &""),
		]
		if seen.has(identity):
			errors.append("entries.%d: duplicate identity" % index)
		seen[identity] = true
	if entries.size() != EXPECTED_ENTRIES.size():
		errors.append("entries: expected exact %d rows" % EXPECTED_ENTRIES.size())
	else:
		for index: int in EXPECTED_ENTRIES.size():
			if entries[index] != EXPECTED_ENTRIES[index]:
				errors.append("entries.%d: does not match frozen owner tuple" % index)
	return errors


func _validate_row(index: int, row: Dictionary, errors: PackedStringArray) -> void:
	if row.size() != ROW_KEYS.size():
		errors.append("entries.%d: expected exact nine fields" % index)
	for key: String in ROW_KEYS:
		if not row.has(key):
			errors.append("entries.%d: missing %s" % [index, key])
	for raw_key: Variant in row:
		if typeof(raw_key) not in [TYPE_STRING, TYPE_STRING_NAME] \
			or not ROW_KEYS.has(String(raw_key)):
			errors.append("entries.%d: unexpected key %s" % [index, raw_key])
	if typeof(row.get(&"color_html")) != TYPE_STRING \
		or not COLORS.has(String(row.get(&"color_html", ""))):
		errors.append("entries.%d.color_html: invalid" % index)
	_validate_enum(index, row, &"owner_kind", OWNER_KINDS, errors)
	_validate_enum(index, row, &"semantic", SEMANTICS, errors)
	_validate_enum(index, row, &"status", STATUSES, errors)
	for key: StringName in [&"owner_id", &"symbol", &"negative_owner_id"]:
		if typeof(row.get(key)) != TYPE_STRING_NAME:
			errors.append("entries.%d.%s: expected StringName" % [index, key])
	if row.get(&"owner_id", &"") == &"":
		errors.append("entries.%d.owner_id: required" % index)
	if typeof(row.get(&"source_path")) != TYPE_STRING \
		or not String(row.get(&"source_path", "")).begins_with("res://"):
		errors.append("entries.%d.source_path: expected res:// path" % index)
	if typeof(row.get(&"differential_required")) != TYPE_BOOL:
		errors.append("entries.%d.differential_required: expected bool" % index)
	var is_asset: bool = row.get(&"owner_kind", &"") == &"asset"
	if is_asset and row.get(&"symbol", &"") != &"":
		errors.append("entries.%d.symbol: assets require empty" % index)
	if not is_asset and row.get(&"symbol", &"") == &"":
		errors.append("entries.%d.symbol: runtime owner required" % index)
	var differential := bool(row.get(&"differential_required", false))
	if differential != (row.get(&"negative_owner_id", &"") != &""):
		errors.append("entries.%d.negative_owner_id: differential mismatch" % index)


func _validate_enum(
	index: int, row: Dictionary, key: StringName, allowed: Array[StringName],
	errors: PackedStringArray
) -> void:
	var value: Variant = row.get(key)
	if typeof(value) != TYPE_STRING_NAME or not allowed.has(value):
		errors.append("entries.%d.%s: invalid enum" % [index, key])
