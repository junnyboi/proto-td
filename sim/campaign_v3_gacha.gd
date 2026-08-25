class_name CampaignV3Gacha
extends RefCounted

const CommandsScript := preload("res://sim/campaign_v3_commands.gd")
const CommandCodecScript := preload("res://sim/campaign_v3_command_codec.gd")
const HeroIdentityScript := preload("res://sim/hero_identity.gd")
const HeroNamesScript := preload("res://sim/hero_names.gd")
const ClassDefScript := preload("res://data/class_def.gd")
const StateCodecScript := preload("res://sim/campaign_v3_state_codec.gd")

const D_PREMIUM_PULL := 605702925438635313
const FIVE_STAR_RARITY := 5
const HARD_PITY_STREAK := 9
const HARD_PITY_WINDOW := 10


static func execute(
	state: Variant,
	command_id: Variant,
	expected_revision: Variant,
) -> Dictionary:
	var prepared := CommandsScript.prepare(
		state,
		command_id,
		expected_revision,
		"pull_premium_hero",
		{},
	)
	if not prepared["accepted"]:
		return prepared
	if prepared["duplicate"]:
		return prepared["result"]
	var derived := _derive(state._data, state._context_ref())
	if not derived["accepted"]:
		return CommandsScript.rejected(derived["error_code"])
	var working: Dictionary = derived["data"]
	working["save_revision"] = state.save_revision() + 1
	var receipt: Dictionary = derived["receipt"]
	receipt["save_revision"] = working["save_revision"]
	var record := CommandCodecScript.record(
		prepared["command_id"],
		"pull_premium_hero",
		prepared["expected_save_revision"],
		prepared["payload"],
		{"premium_pull": receipt},
	)
	working["command_receipts"] = (working["command_receipts"] as Array).duplicate(true)
	working["command_receipts"].append(record)
	var prospective: Dictionary = state._prospective_state(working)
	if not prospective["accepted"]:
		return CommandsScript.rejected(prospective["error_code"])
	return CommandsScript.mutation(
		state,
		"pull_premium_hero",
		prospective["value"],
		record,
		[
			{
				"name": &"premium_hero_pulled",
				"data": {
					"premium_id": receipt["premium_id"],
					"hero_id": receipt["hero_id"],
					"new_hero": receipt["new_hero"],
					"revived": receipt["revived"],
					"lives_after": receipt["lives_after"],
					"rarity": receipt["rarity"],
					"five_star": receipt["five_star"],
					"pity_forced": receipt["pity_forced"],
					"guarantee_in_after": receipt["guarantee_in_after"],
					"save_revision": working["save_revision"],
				},
			},
		],
		{"premium_pull": receipt.duplicate(true)},
	)


static func _derive(data: Dictionary, context: Dictionary) -> Dictionary:
	if int(data["next_attempt_id"]) != int(data["next_resolution_index"]):
		return _reject(&"attempt_pending")
	var cost := int(context["campaign"]["premium_pull_cost"])
	if int(data["marks"]) < cost:
		return _reject(&"insufficient_marks")
	var pull_index := int(data["next_premium_pull_index"])
	if pull_index >= StateCodecScript.U63_MAX:
		return _reject(&"premium_pull_counter_exhausted")
	var pity_eligible := pull_index >= int(data["premium_pity_started_at_pull"])
	var pity_before := int(data["premium_pity_streak"]) if pity_eligible else 0
	var pity_forced := pity_eligible and pity_before >= HARD_PITY_STREAK
	var selected := _select_row(
		context["campaign"]["premium_hero_rows"],
		int(data["campaign_seed"]),
		int(data["campaign_generation"]),
		pull_index,
		FIVE_STAR_RARITY if pity_forced else 0,
		not pity_eligible,
	)
	if selected.is_empty():
		return _reject(&"missing_premium_pool")
	var working: Dictionary = data.duplicate(true)
	working["heroes"] = (working["heroes"] as Array).duplicate(true)
	working["memorial"] = (working["memorial"] as Array).duplicate(true)
	var premium_id := String(selected["premium_id"])
	var rarity := int(selected["rarity"])
	var five_star := rarity == FIVE_STAR_RARITY
	var hero := _premium_hero_by_id(working["heroes"], premium_id)
	var new_hero := hero.is_empty()
	var revived := false
	var lives_before := 0
	if new_hero:
		if (working["heroes"] as Array).size() >= StateCodecScript.MAX_ROSTER:
			return _reject(&"roster_limit")
		var index := int(working["next_recruitment_index"])
		var allocated := HeroIdentityScript.allocate_hero_id(
			int(data["campaign_seed"]),
			int(data["campaign_generation"]),
			index,
			func(candidate: String) -> bool:
				for row: Dictionary in data["heroes"]:
					if row["hero_id"] == candidate:
						return true
				return false,
		)
		if not allocated["accepted"]:
			return _reject(allocated["error_code"])
		hero = _fresh_premium_hero(
			String(allocated["hero_id"]),
			index,
			selected,
			int(data["next_resolution_index"]) - 1,
			context,
		)
		working["heroes"].append(hero)
		working["next_recruitment_index"] = index + 1
	else:
		lives_before = int(hero["premium_lives"])
		if int(hero["premium_pull_count"]) >= StateCodecScript.PREMIUM_LIVES_MAX:
			return _reject(&"premium_life_cap")
		revived = hero["life_status"] == "dead"
		hero["premium_lives"] = lives_before + 1
		hero["premium_pull_count"] = int(hero["premium_pull_count"]) + 1
		if revived:
			hero["life_status"] = "ready"
			hero["death"] = null
			_remove_memorial(working["memorial"], String(hero["hero_id"]))
	working["marks"] = int(data["marks"]) - cost
	working["next_premium_pull_index"] = pull_index + 1
	var pity_after := 0
	if pity_eligible and not five_star:
		pity_after = pity_before + 1
	working["premium_pity_streak"] = pity_after
	return {
		"accepted": true,
		"error_code": &"",
		"data": working,
		"receipt": {
			"premium_id": premium_id,
			"hero_id": String(hero["hero_id"]),
			"pull_index": pull_index,
			"new_hero": new_hero,
			"revived": revived,
			"lives_before": lives_before,
			"lives_after": int(hero["premium_lives"]),
			"pull_count_after": int(hero["premium_pull_count"]),
			"marks_before": int(data["marks"]),
			"marks_after": int(working["marks"]),
			"rarity": rarity,
			"five_star": five_star,
			"pity_eligible": pity_eligible,
			"pity_before": pity_before,
			"pity_after": pity_after,
			"pity_forced": pity_forced,
			"guarantee_in_after": HARD_PITY_WINDOW - pity_after,
			"save_revision": 0,
		},
	}


static func _select_row(
	rows: Array,
	seed_value: int,
	generation: int,
	pull_index: int,
	required_rarity: int = 0,
	legacy_uniform: bool = false,
) -> Dictionary:
	var total_weight := 0
	for row: Dictionary in rows:
		if required_rarity > 0 and int(row["rarity"]) != required_rarity:
			continue
		total_weight += 1 if legacy_uniform else int(row["weight"])
	if total_weight <= 0:
		return {}
	var bits := HeroIdentityScript.splitmix64_bits(seed_value ^ D_PREMIUM_PULL)
	bits = HeroIdentityScript.splitmix64_bits(bits ^ generation)
	bits = HeroIdentityScript.splitmix64_bits(bits ^ pull_index)
	var hex := HeroIdentityScript.format_u64_hex(bits)
	var slot := 0
	for character: String in hex:
		slot = (slot * 16 + HeroIdentityScript.HEX.find(character)) % total_weight
	for row: Dictionary in rows:
		if required_rarity > 0 and int(row["rarity"]) != required_rarity:
			continue
		var weight := 1 if legacy_uniform else int(row["weight"])
		if slot < weight:
			return row.duplicate(true)
		slot -= weight
	return {}


static func _fresh_premium_hero(
	hero_id: String,
	index: int,
	catalog: Dictionary,
	recruited_after_resolution_index: int,
	context: Dictionary,
) -> Dictionary:
	var class_id := String(catalog["class_id"])
	var class_row: Dictionary = context["class_by_id"][class_id]
	var first_class_id := class_id
	var advanced_class_id: Variant = null
	if int(class_row["stage"]) == ClassDefScript.Stage.ADVANCED:
		first_class_id = String(class_row["promotion_from_class_id"])
		advanced_class_id = class_id
	var portrait_asset_id := String(catalog["portrait_asset_id"])
	return {
		"hero_id": hero_id,
		"acquisition_operator_def_id": String(catalog["operator_def_id"]),
		"operator_def_id": String(catalog["operator_def_id"]),
		"current_class_id": class_id,
		"first_class_id": first_class_id,
		"advanced_class_id": advanced_class_id,
		"progression_rules_version": ClassDefScript.RULES_VERSION,
		"xp": 0,
		"identity_portrait_id": portrait_asset_id,
		"portrait_instance_id": "portrait:%s" % hero_id,
		"portrait_asset_id": portrait_asset_id,
		"recruitment_index": index,
		"recruited_after_resolution_index": recruited_after_resolution_index,
		"recruit_source": "gacha",
		"source_id": String(catalog["premium_id"]),
		"name_version": HeroNamesScript.VERSION,
		"custom_callsign": String(catalog["callsign"]),
		"life_status": "ready",
		"death": null,
		"hero_kind": "premium",
		"premium_id": String(catalog["premium_id"]),
		"premium_lives": 1,
		"premium_pull_count": 1,
	}


static func _premium_hero_by_id(heroes: Array, premium_id: String) -> Dictionary:
	for hero: Dictionary in heroes:
		if hero["hero_kind"] == "premium" and hero["premium_id"] == premium_id:
			return hero
	return {}


static func _remove_memorial(memorial: Array, hero_id: String) -> void:
	for index: int in range(memorial.size() - 1, -1, -1):
		if memorial[index]["hero_id"] == hero_id:
			memorial.remove_at(index)


static func _reject(code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": code}
