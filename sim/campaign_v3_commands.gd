class_name CampaignV3Commands
extends RefCounted

const U63_MAX := 9_223_372_036_854_775_807


static func prepare(
	state: CampaignStateV3,
	command_id_value: Variant,
	expected_revision_value: Variant,
	verb: String,
	payload_value: Variant,
) -> Dictionary:
	if (
		state == null
		or typeof(command_id_value) not in [TYPE_STRING, TYPE_STRING_NAME]
		or typeof(expected_revision_value) != TYPE_INT
	):
		return _reject(&"malformed_command")
	var command_id := String(command_id_value)
	var expected_revision := int(expected_revision_value)
	if (
		not _ascii(command_id)
		or command_id.length() > 160
		or expected_revision < 1
		or expected_revision >= U63_MAX
	):
		return _reject(&"malformed_command")
	var payload := (
		CampaignV3CommandCodec
		. normalize_payload(
			verb,
			payload_value,
			state._data,
		)
	)
	if not payload["accepted"]:
		return _reject(payload["error_code"])
	var stored := state._command_record(command_id)
	if not stored.is_empty():
		if (
			stored["verb"] != verb
			or stored["expected_save_revision"] != expected_revision
			or stored["payload"] != payload["value"]
		):
			return _reject(&"command_id_conflict")
		return {
			"accepted": true,
			"error_code": &"",
			"duplicate": true,
			"result": duplicate_result(stored),
		}
	for promotion: Dictionary in state._data["promotion_receipts"]:
		if promotion["command_id"] == command_id:
			return _reject(&"command_id_conflict")
	if not CampaignV3CommandHistory.can_append(state._data, state._context_ref()):
		return _reject(&"command_history_unavailable")
	if expected_revision != state.save_revision():
		return _reject(&"stale_revision")
	return {
		"accepted": true,
		"error_code": &"",
		"duplicate": false,
		"command_id": command_id,
		"expected_save_revision": expected_revision,
		"payload": payload["value"],
	}


static func mutation(
	state: CampaignStateV3,
	verb: String,
	prospective: CampaignStateV3,
	record_row: Dictionary,
	events: Array[Dictionary],
	extra_result: Dictionary = {},
) -> Dictionary:
	var result := {
		"fresh": true,
		"receipt": record_row["receipt"].duplicate(true),
		"receipt_bytes": CampaignV3CommandCodec.canonical_bytes(record_row),
	}
	for key: String in extra_result:
		result[key] = extra_result[key]
	var created := (
		CampaignMutation
		. _create(
			StringName(verb),
			state,
			prospective,
			events,
			result,
		)
	)
	if not created["accepted"]:
		return _reject(created["error_code"])
	return {
		"accepted": true,
		"error_code": &"",
		"events": [],
		"payload": {"mutation": created["value"]},
	}


static func duplicate_result(record_row: Dictionary) -> Dictionary:
	return {
		"accepted": true,
		"error_code": &"",
		"events":
		[
			_event(
				&"strategic_command_duplicate",
				{
					"command_id": record_row["command_id"],
					"verb": record_row["verb"],
					"save_revision": record_row["save_revision"],
				}
			)
		],
		"payload":
		{
			"fresh": false,
			"receipt": record_row["receipt"].duplicate(true),
			"receipt_bytes": CampaignV3CommandCodec.canonical_bytes(record_row),
		},
	}


static func rejected(code: StringName) -> Dictionary:
	return _reject(code)


static func _event(name: StringName, data: Dictionary) -> Dictionary:
	return {"name": name, "data": data}


static func _ascii(value: String) -> bool:
	if value.is_empty():
		return false
	for character: String in value:
		if character.unicode_at(0) > 127:
			return false
	return true


static func _reject(code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": code, "events": [], "payload": {}}
