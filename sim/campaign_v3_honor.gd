class_name CampaignV3Honor
extends RefCounted

## Honors one permanently fallen operator and grants the fixed memorial stipend.
## The command receipt is the durable one-time ledger; no presentation-local
## state can grant or revoke this reward.

const HONOR_MARKS := 5
const CommandsScript := preload("res://sim/campaign_v3_commands.gd")
const CommandCodecScript := preload("res://sim/campaign_v3_command_codec.gd")
const StateCodecScript := preload("res://sim/campaign_v3_state_codec.gd")


static func execute(
	state: Variant,
	command_id: Variant,
	expected_revision: Variant,
	hero_id_value: Variant,
) -> Dictionary:
	var prepared := CommandsScript.prepare(
		state,
		command_id,
		expected_revision,
		"honor_fallen",
		{"hero_id": hero_id_value},
	)
	if not prepared["accepted"]:
		return prepared
	if prepared["duplicate"]:
		return prepared["result"]
	var derived := _derive(state._data, prepared["payload"])
	if not derived["accepted"]:
		return CommandsScript.rejected(derived["error_code"])
	var working: Dictionary = derived["data"]
	working["save_revision"] = state.save_revision() + 1
	var receipt: Dictionary = derived["receipt"]
	receipt["save_revision"] = working["save_revision"]
	var record := CommandCodecScript.record(
		prepared["command_id"],
		"honor_fallen",
		prepared["expected_save_revision"],
		prepared["payload"],
		{"honor": receipt},
	)
	working["command_receipts"] = (working["command_receipts"] as Array).duplicate(true)
	working["command_receipts"].append(record)
	var prospective: Dictionary = state._prospective_state(working)
	if not prospective["accepted"]:
		return CommandsScript.rejected(prospective["error_code"])
	return CommandsScript.mutation(
		state,
		"honor_fallen",
		prospective["value"],
		record,
		[{
			"name": &"fallen_honored",
			"data": {
				"hero_id": receipt["hero_id"],
				"marks_awarded": HONOR_MARKS,
				"marks_after": receipt["marks_after"],
				"save_revision": receipt["save_revision"],
			},
		}],
		{"honor": receipt.duplicate(true)},
	)


static func honored_hero_ids(data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for record: Dictionary in data.get("command_receipts", []):
		if String(record.get("verb", "")) != "honor_fallen":
			continue
		var hero_id := String(record.get("payload", {}).get("hero_id", ""))
		if not hero_id.is_empty() and not result.has(hero_id):
			result.append(hero_id)
	return result


static func _derive(data: Dictionary, payload: Dictionary) -> Dictionary:
	if int(data["next_attempt_id"]) != int(data["next_resolution_index"]):
		return _reject(&"attempt_pending")
	var hero_id := String(payload["hero_id"])
	var target := _hero_by_id(data["heroes"], hero_id)
	if target.is_empty():
		return _reject(&"unknown_hero")
	if target["life_status"] != "dead":
		return _reject(&"hero_not_fallen")
	if honored_hero_ids(data).has(hero_id):
		return _reject(&"already_honored")
	var marks_before := int(data["marks"])
	if marks_before > StateCodecScript.MARKS_MAX - HONOR_MARKS:
		return _reject(&"marks_overflow")
	var working: Dictionary = data.duplicate(true)
	working["marks"] = marks_before + HONOR_MARKS
	return {
		"accepted": true,
		"error_code": &"",
		"data": working,
		"receipt": {
			"hero_id": hero_id,
			"marks_before": marks_before,
			"marks_after": marks_before + HONOR_MARKS,
			"save_revision": 0,
		},
	}


static func _hero_by_id(heroes: Array, hero_id: String) -> Dictionary:
	for hero: Dictionary in heroes:
		if String(hero.get("hero_id", "")) == hero_id:
			return hero
	return {}


static func _reject(code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": code}
