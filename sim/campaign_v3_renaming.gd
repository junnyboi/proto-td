class_name CampaignV3Renaming
extends RefCounted

const CommandsScript := preload("res://sim/campaign_v3_commands.gd")
const CommandCodecScript := preload("res://sim/campaign_v3_command_codec.gd")
const HeroCodecScript := preload("res://sim/campaign_hero_codec.gd")


static func execute(
	state: Variant,
	command_id: Variant,
	expected_revision: Variant,
	hero_id_value: Variant,
	callsign_value: Variant,
) -> Dictionary:
	var prepared := (
		CommandsScript
		. prepare(
			state,
			command_id,
			expected_revision,
			"rename_hero",
			{"hero_id": hero_id_value, "callsign": callsign_value},
		)
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
	var record := (
		CommandCodecScript
		. record(
			prepared["command_id"],
			"rename_hero",
			prepared["expected_save_revision"],
			prepared["payload"],
			{"rename": receipt},
		)
	)
	working["command_receipts"] = (working["command_receipts"] as Array).duplicate(true)
	working["command_receipts"].append(record)
	var prospective: Dictionary = state._prospective_state(working)
	if not prospective["accepted"]:
		return CommandsScript.rejected(prospective["error_code"])
	return (
		CommandsScript
		. mutation(
			state,
			"rename_hero",
			prospective["value"],
			record,
			[
				{
					"name": &"hero_renamed",
					"data":
					{
						"hero_id": receipt["hero_id"],
						"old_callsign": receipt["old_callsign"],
						"new_callsign": receipt["new_callsign"],
						"save_revision": receipt["save_revision"],
					},
				},
			],
			{"rename": receipt.duplicate(true)},
		)
	)


static func _derive(data: Dictionary, payload: Dictionary) -> Dictionary:
	if int(data["next_attempt_id"]) != int(data["next_resolution_index"]):
		return _reject(&"attempt_pending")
	var hero_id := String(payload["hero_id"])
	var callsign := String(payload["callsign"])
	var target_index := -1
	for index: int in (data["heroes"] as Array).size():
		if data["heroes"][index]["hero_id"] == hero_id:
			target_index = index
			break
	if target_index < 0:
		return _reject(&"unknown_hero")
	var target: Dictionary = data["heroes"][target_index]
	if target["hero_kind"] != "recruit":
		return _reject(&"premium_name_locked")
	if target["life_status"] != "ready":
		return _reject(&"hero_not_ready")
	if not HeroCodecScript.valid_callsign(callsign):
		return _reject(&"invalid_callsign")
	var previous := HeroCodecScript.display_callsign(target)
	if not previous["accepted"]:
		return _reject(&"invalid_campaign_state")
	if String(previous["value"]) == callsign:
		return _reject(&"callsign_unchanged")
	var folded := callsign.to_lower()
	for hero: Dictionary in data["heroes"]:
		if hero["hero_id"] == hero_id:
			continue
		var display := HeroCodecScript.display_callsign(hero)
		if not display["accepted"]:
			return _reject(&"invalid_campaign_state")
		if String(display["value"]).to_lower() == folded:
			return _reject(&"duplicate_callsign")
	var working: Dictionary = data.duplicate(true)
	working["heroes"] = (data["heroes"] as Array).duplicate(true)
	var changed: Dictionary = working["heroes"][target_index].duplicate(true)
	changed["custom_callsign"] = callsign
	working["heroes"][target_index] = changed
	return {
		"accepted": true,
		"error_code": &"",
		"data": working,
		"receipt":
		{
			"hero_id": hero_id,
			"old_callsign": String(previous["value"]),
			"new_callsign": callsign,
			"save_revision": 0,
		},
	}


static func _reject(code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": code}
