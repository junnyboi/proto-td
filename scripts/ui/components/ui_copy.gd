class_name UiCopy
extends RefCounted

const STATIC_FALLBACKS := {
	&"ui.game_title": "Protos",
	&"ui.title.start": "Start",
	&"ui.title.seed": "seed {seed}",
	&"ui.tutorial.block.action": "Start battle",
	&"ui.tutorial.block.body": (
		"A Recruit blocks 1 ground enemy and loses HP while fighting. "
		+ "Deploy another when DP refills."
	),
	&"ui.tutorial.block.step": "4 / 4  BLOCK",
	&"ui.tutorial.block.title": "Hold the line",
	&"ui.tutorial.deploy.body": (
		"DP pays for units. Drag a Recruit card onto any green path tile; "
		+ "the gold marker is a safe starting position."
	),
	&"ui.tutorial.deploy.cancelled": (
		"Placement cancelled. Drag a Recruit onto a green path tile when ready."
	),
	&"ui.tutorial.deploy.dragging": (
		"Green tiles are valid. Release on the gold marker or any green path tile."
	),
	&"ui.tutorial.deploy.invalid": (
		"That cell cannot hold this Recruit. Use a green path tile."
	),
	&"ui.tutorial.deploy.step": "2 / 4  DEPLOY",
	&"ui.tutorial.deploy.title": "Deploy a Recruit",
	&"ui.tutorial.dismiss": "Dismiss",
	&"ui.tutorial.facing.body": (
		"Facing rotates attack coverage. Aim toward the incoming route; "
		+ "any arrow deploys the unit."
	),
	&"ui.tutorial.facing.step": "3 / 4  FACING",
	&"ui.tutorial.facing.title": "Choose facing",
	&"ui.tutorial.live.body": (
		"Spend refilling DP, reinforce the route, and stop the 4th leak."
	),
	&"ui.tutorial.live.step": "FIELD REMINDER",
	&"ui.tutorial.live.title": "Defend the base",
	&"ui.tutorial.route.action": "Show deployment",
	&"ui.tutorial.route.body": (
		"Enemies enter at red and follow the lit path to your blue base. "
		+ "First Stand allows 3 leaks; the 4th ends the mission."
	),
	&"ui.tutorial.route.step": "1 / 4  ROUTE",
	&"ui.tutorial.route.title": "Read the route",
	&"ui.tutorial.skip": "Skip tutorial",
	&"ui.map_navigation.hint_title": "DRAG TO PAN",
	&"ui.map_navigation.hint_body": "Explore the full battlefield on every open axis.",
	&"ui.map_navigation.recenter": "CENTER",
	&"ui.map_navigation.recenter_tooltip": "Reset the battlefield view (R)",
	&"ui.locale.label": "Language",
	&"ui.locale.en_us": "EN",
	&"ui.locale.zh_cn": "中文",
	&"ui.staging.heading": "STAGING",
	&"ui.staging.command_heading": "COMPANY 33 COMMAND",
	&"ui.staging.faction_standards": "FACTION STANDARDS",
	&"ui.staging.command_body": (
		"Commander, the Great Flare was a massive solar flare that corrupted connected "
		+ "systems two centuries ago and caused the Fall. Custodians are still forcing "
		+ "Hearthcross through that unfinished evacuation."
	),
	&"ui.staging.next_operation_title": "NEXT {index}: {title}",
	&"ui.staging.campaign_summary": "{cleared}/{total} CLEARED",
	&"ui.staging.next_none": "NEXT: No active campaign",
	&"ui.staging.next_label": "NEXT OPERATION",
	&"ui.staging.next_detail": "NEXT: {index}. {title}",
	&"ui.staging.next_complete": "NEXT: Campaign complete",
	&"ui.staging.operation_status": "OPERATIONS — UNAVAILABLE",
	&"ui.staging.operations": "OPERATIONS",
	&"ui.staging.mission_control": "Mission Control",
	&"ui.staging.mission_control_short": "Mission",
	&"ui.staging.barracks_unavailable": "Barracks — Unavailable",
	&"ui.staging.barracks_short": "Barracks",
	&"ui.staging.recruit": "Premium Resonance",
	&"ui.staging.recruit_unavailable": "Premium Resonance — Unavailable",
	&"ui.staging.recruit_short": "Resonance",
	&"ui.staging.resource_aether": "Aether",
	&"ui.staging.resource_sigils": "Astral Sigils",
	&"ui.staging.resource_stamina": "Stamina",
	&"ui.staging.training": "Training",
	&"ui.staging.training_unavailable": "Training — Unavailable",
	&"ui.staging.training_short": "Training",
	&"ui.staging.armory_unavailable": "Armory — Unavailable",
	&"ui.staging.armory_short": "Armory",
	&"ui.staging.memorial_unavailable": "Memorial — Unavailable",
	&"ui.staging.memorial_short": "Memorial",
	&"ui.common.back_to_title": "Back to Title",
	&"ui.common.exit": "Exit",
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
	&"ui.squad.start_battle_short": "Start",
	&"ui.squad.briefing.objective": "Objective",
	&"ui.squad.briefing.threat": "Threat",
	&"ui.squad.briefing.human_reason": "Why it matters",
	&"ui.squad.briefing.clue": "Field note",
	&"ui.squad.tactical_hint": "Tactical hint — {hint}",
	&"ui.results.clear": "CLEAR",
	&"ui.results.defeat": "DEFEAT",
	&"ui.results.tally": "kills {kills}   leaks {leaks}",
	&"ui.results.reward": "Unlocked: {name}",
	&"ui.results.retry": "Retry",
	&"ui.results.consequence": "Consequence",
	&"ui.error.missing_stage_narrative": "Mission record unavailable. Return to Mission Control.",
	&"ui.results.return_to_staging": "Return to Staging",
	&"ui.results.training_available": "{count} recruits ready for training.",
	&"ui.results.train_recruits": "Train Recruits",
	&"ui.results.train_short": "Train",
	&"ui.training.assignment": "COMPANY 33\nTRAINING ASSIGNMENT\nNEW FIELD KIT",
	&"ui.training.cancel": "Cancel",
	&"ui.training.choose_advanced": "CHOOSE ADVANCED TRAINING",
	&"ui.training.choose_path": "Choose Path",
	&"ui.training.add_to_plan": "Add to Plan",
	&"ui.training.add_another": "Add Another",
	&"ui.training.review_plan": "Review Plan",
	&"ui.training.review_title": "REVIEW TRAINING PLAN",
	&"ui.training.review_entry": "{callsign} to {class_name}",
	&"ui.training.removed_heading": "REMOVED AFTER ROSTER REFRESH",
	&"ui.training.removed_entry": "{callsign} to {class_name}: {reason}",
	&"ui.training.not_now": "Not Now",
	&"ui.training.draft_choice": "Planned: {class_name}",
	&"ui.training.choose_recruit": "Choose a recruit to train.",
	&"ui.training.class.banner_guard": "Banner Guard",
	&"ui.training.class.defender": "Defender",
	&"ui.training.class.gunner": "Gunner",
	&"ui.training.class.immovable": "Immovable",
	&"ui.training.class.mage_apprentice": "Mage Apprentice",
	&"ui.training.class.recruit": "Recruit",
	&"ui.training.class.shock_trooper": "Shock Trooper",
	&"ui.training.class.sniper": "Sniper",
	&"ui.training.class.sorcerer": "Sorcerer",
	&"ui.training.class.sword_saint": "Sword Saint",
	&"ui.training.class.swordmaster": "Swordmaster",
	&"ui.training.class.witch_doctor": "Witch Doctor",
	&"ui.training.class_kit_placeholder": "CLASS KIT\nTEMP ART",
	&"ui.training.confirm_action": "Confirm Training",
	&"ui.training.confirm_permanent": "This training choice cannot be changed.",
	&"ui.training.confirm_title": "CONFIRM {class_name} TRAINING?",
	&"ui.training.error.already_promoted": "This recruit has already chosen an advanced path.",
	&"ui.training.error.command_conflict": "This training request conflicts with an earlier command.",
	&"ui.training.error.insufficient_xp": "This recruit needs more XP.",
	&"ui.training.error.invalid_choice": "That training path is not available.",
	&"ui.training.error.invalid_request": "Training request was invalid.",
	&"ui.training.error.no_path": "This class has no advanced path here.",
	&"ui.training.error.not_ready": "This recruit is not ready for training.",
	&"ui.training.error.progression_failed": "Training progression could not be applied.",
	&"ui.training.error.stale_state": "The roster changed. Review the recruit again.",
	&"ui.training.error.unknown_hero": "That recruit is no longer in the roster.",
	&"ui.training.error.dead_hero": "Dead recruits cannot train.",
	&"ui.training.error.premium_hero_untrainable": "Premium heroes use fixed elite kits and cannot train.",
	&"ui.training.error.locked_class": "This training path is not unlocked yet.",
	&"ui.training.error.already_promoted_class": "No further training path is available.",
	&"ui.training.error.illegal_class_edge": "That class is not a legal next duty.",
	&"ui.training.error.missing_catalog": "Training records are incomplete.",
	&"ui.training.error.attempt_pending": "Finish the active operation before training.",
	&"ui.training.error.store_write_failed": "The campaign could not be saved.",
	&"ui.training.error.campaign_inactive": "No active campaign is available.",
	&"ui.training.error.integrity": "Training records could not be authenticated.",
	&"ui.training.error.save_pending": "The previous save must be retried before leaving.",
	&"ui.training.field_record": "FIELD RECORD",
	&"ui.training.format.dp": "{value} DP",
	&"ui.training.combat_facts": (
		"{cost} DP • {placement} • Block {block} • Range {range} • ATK {cadence}T"
	),
	&"ui.training.skill_facts": "Skill: {skill}",
	&"ui.training.placement.ground": "Ground",
	&"ui.training.placement.elevated": "Elevated",
	&"ui.training.field_kit": "FIELD KIT • EQUIPMENT ISSUED AFTER CONFIRMATION",
	&"ui.training.hero_progress": "{callsign} — {class_name} — XP {current} / {required}",
	&"ui.training.identity_portrait_alt": "Identity portrait for {callsign}",
	&"ui.training.kit.sorcerer": "Kit: conductors, weather rods, control marks.",
	&"ui.training.kit.witch_doctor": "Kit: medicine, charge, repair tools.",
	&"ui.training.no_revive_warning": "Death remains permanent. Mend cannot revive the dead.",
	&"ui.training.permanent_warning": "THIS CHOICE IS PERMANENT.",
	&"ui.training.promotion_ready": "Promotion ready.",
	&"ui.training.promotion_ready_count": "{count} PROMOTION READY",
	&"ui.training.reason.already_promoted": "Advanced training complete.",
	&"ui.training.reason.dead": "Dead. Training unavailable.",
	&"ui.training.reason.premium": "Premium hero. Fixed elite kit; training unavailable.",
	&"ui.training.reason.no_path": "No advanced class path.",
	&"ui.training.role.damage_control": "Damage / Control",
	&"ui.training.role.healer_support": "Healer / Support",
	&"ui.training.same_identity": "SAME RECRUIT • SAME HERO ID • SAME CALLSIGN • SAME HISTORY",
	&"ui.training.same_recruit_new_job": "Same recruit. New job.",
	&"ui.training.skill.mend": "Mend — Heal one living ally for {amount} HP",
	&"ui.training.skill.tempest": "Tempest — Wide-range pressure attack",
	&"ui.training.state_after_confirmation": "State changes only after confirmation.",
	&"ui.training.status.dead": "DEAD",
	&"ui.training.status.ready": "READY",
	&"ui.training.success": "{callsign} is now a {class_name}.",
	&"ui.training.ack_entry": "{callsign} to {class_name}",
	&"ui.training.acknowledgement": "Training complete: {assignments}",
	&"ui.training.title": "TRAINING",
	&"ui.training.training_explainer": (
		"Advanced training changes equipment, duties, and field role. "
		+ "It does not replace the person."
	),
	&"ui.training.view_paths": "View Paths",
	&"ui.training.xp_needed": "Needs {remaining} XP.",
	&"ui.training.xp_progress": "XP {current} / {required}",
	&"ui.save.write_failed": "The campaign could not be saved.",
	&"ui.error.unknown": "Training failed. Review the roster and try again.",
}

const PLACEHOLDER_TYPES := {
	&"ui.title.seed": {&"seed": &"int"},
	&"ui.staging.campaign_summary": {&"cleared": &"int", &"total": &"int"},
	&"ui.staging.next_detail": {&"index": &"int", &"title": &"String"},
	&"ui.staging.next_operation_title": {&"index": &"int", &"title": &"String"},
	&"ui.campaign.row": {&"index": &"int", &"title": &"String", &"status": &"String"},
	&"ui.campaign.cleared_suffix": {&"stars": &"String"},
	&"ui.squad.heading": {&"stage": &"String"},
	&"ui.squad.operator_card": {&"name": &"String", &"cost": &"int"},
	&"ui.squad.selected_count": {&"selected": &"int", &"limit": &"int"},
	&"ui.squad.loadout_available": {&"items": &"String"},
	&"ui.squad.tactical_hint": {&"hint": &"String"},
	&"ui.results.tally": {&"kills": &"int", &"leaks": &"int"},
	&"ui.results.reward": {&"name": &"String"},
	&"ui.results.training_available": {&"count": &"int"},
	&"ui.training.confirm_title": {&"class_name": &"String"},
	&"ui.training.format.dp": {&"value": &"int"},
	&"ui.training.combat_facts": {
		&"cost": &"int", &"placement": &"String", &"block": &"int", &"range": &"int",
		&"cadence": &"int",
	},
	&"ui.training.skill_facts": {&"skill": &"String"},
	&"ui.training.draft_choice": {&"class_name": &"String"},
	&"ui.training.review_entry": {&"callsign": &"String", &"class_name": &"String"},
	&"ui.training.removed_entry": {
		&"callsign": &"String", &"class_name": &"String", &"reason": &"String",
	},
	&"ui.training.ack_entry": {&"callsign": &"String", &"class_name": &"String"},
	&"ui.training.acknowledgement": {&"assignments": &"String"},
	&"ui.training.hero_progress": {
		&"callsign": &"String", &"class_name": &"String",
		&"current": &"int", &"required": &"int",
	},
	&"ui.training.identity_portrait_alt": {&"callsign": &"String"},
	&"ui.training.promotion_ready_count": {&"count": &"int"},
	&"ui.training.skill.mend": {&"amount": &"int"},
	&"ui.training.success": {&"callsign": &"String", &"class_name": &"String"},
	&"ui.training.xp_needed": {&"remaining": &"int"},
	&"ui.training.xp_progress": {&"current": &"int", &"required": &"int"},
}


static func text(key: StringName, fallback: String) -> String:
	return I18n.t(key, fallback)


static func format_text(key: StringName, fallback: String, args: Dictionary) -> String:
	return I18n.format_text(key, fallback, args)


static func stage_narrative_text(record: Resource, field: int) -> String:
	if record == null or not record.has_method("fallback_for") or not record.has_method("field_slug"):
		push_error("UiCopy.stage_narrative_text: invalid record")
		return ""
	var record_id := StringName(record.get("id"))
	var slug := StringName(record.call("field_slug", field))
	var fallback := String(record.call("fallback_for", field))
	if String(record_id).is_empty() or String(slug).is_empty() or fallback.is_empty():
		push_error("UiCopy.stage_narrative_text: invalid record field")
		return ""
	return text(StringName("data.stage.%s.narrative.%s" % [record_id, slug]), fallback)


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
