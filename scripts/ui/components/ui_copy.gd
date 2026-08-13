class_name UiCopy
extends RefCounted

const STATIC_FALLBACKS := {
	&"ui.game_title": "Protos",
	&"ui.title.start": "Start",
	&"ui.title.seed": "seed {seed}",
	&"ui.locale.label": "Language",
	&"ui.locale.en_us": "English (US)",
	&"ui.staging.heading": "STAGING",
	&"ui.staging.campaign_summary": "{cleared}/{total} CLEARED",
	&"ui.staging.next_none": "NEXT: No active campaign",
	&"ui.staging.next_detail": "NEXT: {index}. {title}",
	&"ui.staging.next_complete": "NEXT: Campaign complete",
	&"ui.staging.operation_status": "OPERATIONS — UNAVAILABLE",
	&"ui.staging.mission_control": "Mission Control",
	&"ui.staging.barracks_unavailable": "Barracks — Unavailable",
	&"ui.staging.recruit_unavailable": "Recruit — Unavailable",
	&"ui.staging.training_unavailable": "Training — Unavailable",
	&"ui.staging.armory_unavailable": "Armory — Unavailable",
	&"ui.staging.memorial_unavailable": "Memorial — Unavailable",
	&"ui.common.back_to_title": "Back to Title",
	&"ui.common.back": "Back",
	&"ui.campaign.heading": "Campaign",
	&"ui.campaign.row": "{index}. {title}{status}",
	&"ui.campaign.locked_suffix": "  LOCKED",
	&"ui.campaign.cleared_suffix": "  {stars}",
	&"ui.campaign.back_to_staging": "Back to Staging",
	&"ui.squad.heading": "{stage} — pick your squad",
	&"ui.squad.operator_card": "{name}\n{cost} DP",
	&"ui.squad.selected_count": "{selected}/{limit} selected",
	&"ui.squad.loadout_none": "Loadout: nothing unlocked yet",
	&"ui.squad.loadout_available": "Loadout (always available): {items}",
	&"ui.squad.start_battle": "Start Battle",
	&"ui.results.clear": "CLEAR",
	&"ui.results.defeat": "DEFEAT",
	&"ui.results.tally": "kills {kills}   leaks {leaks}",
	&"ui.results.reward": "Unlocked: {name}",
	&"ui.results.retry": "Retry",
	&"ui.results.return_to_staging": "Return to Staging",
}

const PLACEHOLDER_TYPES := {
	&"ui.title.seed": {&"seed": &"int"},
	&"ui.staging.campaign_summary": {&"cleared": &"int", &"total": &"int"},
	&"ui.staging.next_detail": {&"index": &"int", &"title": &"String"},
	&"ui.campaign.row": {&"index": &"int", &"title": &"String", &"status": &"String"},
	&"ui.campaign.cleared_suffix": {&"stars": &"String"},
	&"ui.squad.heading": {&"stage": &"String"},
	&"ui.squad.operator_card": {&"name": &"String", &"cost": &"int"},
	&"ui.squad.selected_count": {&"selected": &"int", &"limit": &"int"},
	&"ui.squad.loadout_available": {&"items": &"String"},
	&"ui.results.tally": {&"kills": &"int", &"leaks": &"int"},
	&"ui.results.reward": {&"name": &"String"},
}


static func text(key: StringName, fallback: String) -> String:
	return I18n.t(key, fallback)


static func format_text(key: StringName, fallback: String, args: Dictionary) -> String:
	return I18n.format_text(key, fallback, args)


static func stage_title(stage: StageDef) -> String:
	if stage == null:
		push_error("UiCopy.stage_title: null stage")
		return ""
	return text(StringName("data.stage.%s.title" % stage.id), stage.title)


static func stage_hint(stage: StageDef) -> String:
	if stage == null:
		push_error("UiCopy.stage_hint: null stage")
		return ""
	return text(StringName("data.stage.%s.hint" % stage.id), stage.intro_hint)


static func operator_name(definition: OperatorDef) -> String:
	if definition == null:
		push_error("UiCopy.operator_name: null definition")
		return ""
	return text(
		StringName("data.operator.%s.name" % definition.id), definition.display_name,
	)


static func trap_name(definition: TrapDef) -> String:
	if definition == null:
		push_error("UiCopy.trap_name: null definition")
		return ""
	return text(StringName("data.trap.%s.name" % definition.id), definition.display_name)


static func spell_name(definition: SpellDef) -> String:
	if definition == null:
		push_error("UiCopy.spell_name: null definition")
		return ""
	return text(StringName("data.spell.%s.name" % definition.id), definition.display_name)


static func static_fallbacks() -> Dictionary:
	return STATIC_FALLBACKS.duplicate(true)


static func placeholder_types() -> Dictionary:
	return PLACEHOLDER_TYPES.duplicate(true)
