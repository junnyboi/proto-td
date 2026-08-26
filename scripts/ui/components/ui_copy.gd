class_name UiCopy
extends RefCounted

const STATIC_FALLBACKS := {
	&"ui.game_title": "Protos",
	&"ui.title.full_title": "Protos Defense",
	&"ui.title.synopsis": "PROTOS saved the planet by declaring humanity its final extinction event. Command the champions of Company 33 and prove an imperfect species still deserves a future.",
	&"ui.title.start": "Start",
	&"ui.title.settings": "Settings",
	&"ui.title.settings_save_failed": "Settings could not be saved. Review the draft and try again.",
	&"ui.title.audio": "Audio",
	&"ui.title.graphics": "Graphics",
	&"ui.title.master_volume": "Master Volume  //  {value}%",
	&"ui.title.music_volume": "Music Volume  //  {value}%",
	&"ui.title.sfx_volume": "SFX Volume  //  {value}%",
	&"ui.title.music_state": "Music  //  {state}",
	&"ui.title.frame_limit": "Frame Limit",
	&"ui.title.frame_unlimited": "Unlimited",
	&"ui.title.frame_value": "{value} FPS",
	&"ui.title.motion_state": "Animated Background  //  {state}",
	&"ui.title.seed": "seed {seed}",
	&"ui.common.on": "On",
	&"ui.common.off": "Off",
	&"ui.common.cancel": "Cancel",
	&"ui.common.apply": "Apply",
	&"ui.gacha.back": "← COMMAND DECK",
	&"ui.gacha.eyebrow": "LUNARIS RELIQUARY",
	&"ui.gacha.title": "Premium Resonance",
	&"ui.gacha.intro": "Every resonance grants one life. Premium heroes keep fixed elite kits and cannot be trained. 5-star base rate: 5% • guaranteed within ten pulls.",
	&"ui.gacha.guarantee": "5-STAR GUARANTEE",
	&"ui.gacha.ready": "The pool is ready.",
	&"ui.gacha.confirm_title": "CONFIRM RESONANCE",
	&"ui.gacha.confirm_intro": "Align one signal through the random premium pool.",
	&"ui.gacha.resonate": "RESONATE",
	&"ui.gacha.skip_reveal": "SKIP REVEAL",
	&"ui.gacha.signal_lock": "SIGNAL LOCK",
	&"ui.gacha.reveal_title": "RESONANCE",
	&"ui.gacha.signal_acquired": "SIGNAL ACQUIRED",
	&"ui.gacha.one_life_ready": "1 LIFE READY",
	&"ui.gacha.guarantee_default": "5-star guaranteed within 10 pulls",
	&"ui.gacha.campaign_offline": "CAMPAIGN OFFLINE",
	&"ui.gacha.pull_unavailable": "PULL UNAVAILABLE",
	&"ui.gacha.campaign_required": "Start or continue a campaign to access premium resonance.",
	&"ui.gacha.marks": "{count} MARKS",
	&"ui.gacha.pull_action": "RESONATE • {cost} MARKS",
	&"ui.gacha.pull_again": "PULL AGAIN • {cost} MARKS",
	&"ui.gacha.guarantee_in": "5-STAR GUARANTEED IN {count} {unit}",
	&"ui.gacha.confirm_body": "One random signal • {cost} Marks\nBalance  {before} → {after} Marks\n5-star guarantee in {count} {unit}. Every accepted resonance grants exactly one life.",
	&"ui.gacha.attempt_pending": "Resolve the active operation before using premium resonance.",
	&"ui.gacha.marks_needed": "Earn {count} more Marks for another resonance pull.",
	&"ui.gacha.rarity": "{rarity}-STAR PREMIUM",
	&"ui.gacha.rarity_short": "{rarity}-STAR",
	&"ui.gacha.unacquired": "UNACQUIRED",
	&"ui.gacha.pull_to_recruit": "Pull to recruit • Fixed elite kit",
	&"ui.gacha.lives": "{count} {unit}",
	&"ui.gacha.total_copies": "{count} total copies • Fixed elite kit",
	&"ui.gacha.locked_lives": "LOCKED • 0 LIVES",
	&"ui.gacha.restore_hint": "Pull this hero again to restore deployment",
	&"ui.gacha.aligning_short": "ALIGNING…",
	&"ui.gacha.aligning": "Aligning the reliquary signal…",
	&"ui.gacha.guarantee_fulfilled": "GUARANTEE FULFILLED",
	&"ui.gacha.resonance_rarity": "{rarity}-STAR RESONANCE",
	&"ui.gacha.lives_ready": "{count} {unit} READY",
	&"ui.gacha.next_guarantee": "Next 5-star guaranteed in {count} {unit}",
	&"ui.gacha.result_new": "NEW HERO",
	&"ui.gacha.result_revived": "REVIVED",
	&"ui.gacha.result_life": "LIFE +1",
	&"ui.gacha.receipt_new": "{rarity} SIGNAL — {callsign} joins with 1 life. Next 5-star in {guarantee} pulls.",
	&"ui.gacha.receipt_restored": "{rarity} RESTORED — {callsign} returns with 1 life. Next 5-star in {guarantee} pulls.",
	&"ui.gacha.receipt_duplicate": "{rarity} DUPLICATE — {callsign} gains +1 life ({lives} total). Next 5-star in {guarantee} pulls.",
	&"ui.gacha.pull_singular": "pull",
	&"ui.gacha.pull_plural": "pulls",
	&"ui.gacha.life_singular": "LIFE",
	&"ui.gacha.life_plural": "LIVES",
	&"ui.gacha.error.insufficient_marks": "Not enough Marks for another resonance pull.",
	&"ui.gacha.error.attempt_pending": "Resolve the active operation before using the reliquary.",
	&"ui.gacha.error.life_cap": "This hero has reached the maximum stored-life count.",
	&"ui.gacha.error.campaign_inactive": "No active campaign is available.",
	&"ui.gacha.error.unknown": "The resonance failed safely ({code}). Please try again.",
	&"ui.battle.pause": "PAUSE",
	&"ui.battle.resume": "RESUME",
	&"ui.battle.paused": "PAUSED",
	&"ui.battle.resign": "RESIGN",
	&"ui.battle.withdraw_title": "WITHDRAW FROM OPERATION?",
	&"ui.battle.withdraw_body": "Withdrawal immediately seals this attempt as a defeat. Current deployment progress is not preserved.",
	&"ui.battle.confirm_defeat": "CONFIRM DEFEAT",
	&"ui.battle.return": "RETURN TO BATTLE",
	&"ui.battle.withdrawing": "WITHDRAWING…",
	&"ui.battle.state_active": "ACTIVE",
	&"ui.battle.state_clear": "CLEAR",
	&"ui.battle.state_defeat": "DEFEAT",
	&"ui.battle.hud_compact": "CORE {core}   DP {dp}\nELIMS {eliminations}   {state}",
	&"ui.battle.hud_wide": "CORE  {core}    DP  {dp}    ELIMINATIONS  {eliminations}    {state}",
	&"ui.battle.continue_debrief": "CONTINUE TO DEBRIEF",
	&"ui.battle.retreat": "Retreat",
	&"ui.spell.cooldown": "CD {seconds}s",
	&"ui.spell.field_duration": "FIELD {seconds}s",
	&"ui.spell.ready": "READY",
	&"ui.spell.wave": "1 / WAVE",
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
	&"ui.tutorial.slow_field.brief.action": "Select Slow Field",
	&"ui.tutorial.slow_field.brief.body": (
		"Slow Field covers a 3×3 ground area, halves ground movement for 8 seconds, "
		+ "and recharges in 20 seconds. Air units ignore it."
	),
	&"ui.tutorial.slow_field.brief.step": "1 / 2  SLOW FIELD",
	&"ui.tutorial.slow_field.brief.title": "Control the convergence",
	&"ui.tutorial.slow_field.cancelled": (
		"Targeting cancelled. Select Slow Field and cast on the shared lane."
	),
	&"ui.tutorial.slow_field.invalid": "That cast was rejected. Aim inside the battlefield.",
	&"ui.tutorial.slow_field.live.body": (
		"Cyan tracks remaining field duration. Gold tracks the 20-second cooldown. "
		+ "The spell can be cast again when READY returns."
	),
	&"ui.tutorial.slow_field.live.step": "FIELD ACTIVE",
	&"ui.tutorial.slow_field.live.title": "Watch both timers",
	&"ui.tutorial.slow_field.target.body": (
		"Cast on the cyan marker where all three routes converge. Duration and cooldown "
		+ "timers will remain on the spell card."
	),
	&"ui.tutorial.slow_field.target.step": "2 / 2  CAST",
	&"ui.tutorial.slow_field.target.title": "Cast on the shared lane",
	&"ui.tutorial.slow_field.unavailable": "Slow Field is not ready yet.",
	&"ui.map_navigation.hint_title": "DRAG TO PAN",
	&"ui.map_navigation.hint_body": "Explore the full battlefield on every open axis.",
	&"ui.map_navigation.recenter": "CENTER",
	&"ui.map_navigation.recenter_tooltip": "Reset the battlefield view (R)",
	&"ui.locale.label": "Language",
	&"ui.locale.en_us": "EN",
	&"ui.locale.zh_cn": "中文",
	&"ui.staging.heading": "STAGING",
	&"ui.staging.command_heading": "COMPANY 33 COMMAND",
	&"ui.staging.command_body": (
		"PROTOS saved the biosphere by declaring human choice its final extinction event. "
		+ "Company 33 now defends Hearthcross and the right of an imperfect species to "
		+ "remain alive, free, and unfinished."
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
	&"ui.staging.vahalla": "Vahalla",
	&"ui.staging.vahalla_short": "Vahalla",
	&"ui.staging.archive": "Mercy Archive",
	&"ui.staging.archive_short": "Archive",
	&"ui.archive.eyebrow": "LUNARIS RELIQUARY · RESTRICTED HISTORY",
	&"ui.archive.title": "Mercy Archive",
	&"ui.archive.intro": "Recovered records explain why PROTOS calls extinction mercy. Clear operations to decrypt the complete history.",
	&"ui.archive.back": "Return to Company Command",
	&"ui.archive.records": "{unlocked} / {total} RECORDS DECRYPTED",
	&"ui.archive.locked": "ENCRYPTED RECORD",
	&"ui.archive.unlock_requirement": "CLEAR OPERATION {index} TO DECRYPT",
	&"ui.roster.tab.active": "Active",
	&"ui.roster.tab.fallen": "Fallen",
	&"ui.roster.filter.all": "All",
	&"ui.roster.filter.all_factions": "All factions",
	&"ui.roster.empty": "No soldiers match the selected roster filters.",
	&"ui.rename.current_identity": "CURRENT IDENTITY",
	&"ui.rename.new_identity": "NEW IDENTITY",
	&"ui.rename.reversible_note": "This cosmetic identity can be changed again outside active operations.",
	&"ui.rename.selected_operator": "SELECTED OPERATOR",
	&"ui.rename.committing": "RENAMING…",
	&"ui.vahalla.back": "← Company Command",
	&"ui.vahalla.eyebrow": "LUNARIS RELIQUARY • HALL OF THE FALLEN",
	&"ui.vahalla.title": "Vahalla",
	&"ui.vahalla.intro": "Those recorded here are no longer deployable. Their service remains part of Company 33.",
	&"ui.vahalla.fallen_count": "FALLEN",
	&"ui.vahalla.empty": "No fallen soldiers are recorded for this faction.",
	&"ui.vahalla.honor": "Honor",
	&"ui.vahalla.honored": "Honored",
	&"ui.vahalla.record": "FELL AT {stage} • {reason} • TICK {tick}",
	&"ui.vahalla.record_unknown": "SERVICE RECORD SEALED",
	&"ui.vahalla.no_selection": "NO MEMORIAL RECORD SELECTED",
	&"ui.vahalla.terminal_record": "TERMINAL SERVICE RECORD",
	&"ui.vahalla.permanence": "Identity sealed by stable hero record. Ordinary loss remains permanent.",
	&"ui.common.back_to_title": "Back to Title",
	&"ui.common.exit": "Exit",
	&"ui.common.back": "Back",
	&"ui.campaign.heading": "Campaign",
	&"ui.campaign.row": "{index}. {title}{status}",
	&"ui.campaign.locked_suffix": "  LOCKED",
	&"ui.campaign.cleared_suffix": "  {stars}",
	&"ui.campaign.back_to_staging": "Back to Staging",
	&"ui.campaign.objective": "OBJECTIVE — {text}",
	&"ui.campaign.threat": "THREAT — {text}",
	&"ui.campaign.first_clear_reward": "FIRST CLEAR — {rewards}",
	&"ui.campaign.record_only": "RECORD ONLY",
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
	&"ui.results.eyebrow": "AFTER-ACTION RELIQUARY",
	&"ui.results.yield": "MISSION YIELD",
	&"ui.results.no_rewards": "NO NEW MATERIAL REWARDS",
	&"ui.results.record_preserved": "Operation record preserved.",
	&"ui.results.marks_reward": "+{count} MARKS",
	&"ui.results.premium_fund": "Premium Resonance fund",
	&"ui.results.unlocked_kind": "UNLOCKED · {kind}",
	&"ui.results.training_path_unlocked": "ADVANCED TRAINING PATH UNLOCKED",
	&"ui.results.xp_reward": "+{count} XP",
	&"ui.results.fallen_record": "FALLEN · MEMORIAL RECORD SEALED",
	&"ui.results.reserve_life_spent": "1 RESERVE LIFE SPENT · {count} REMAINING",
	&"ui.results.final_life_spent": "FINAL LIFE SPENT · LOCKED UNTIL SAME IDENTITY IS PULLED AGAIN",
	&"ui.results.company_intact": "COMPANY INTACT",
	&"ui.results.no_losses": "No terminal losses recorded.",
	&"ui.results.tally": "kills {kills}   leaks {leaks}",
	&"ui.results.reward": "Unlocked: {name}",
	&"ui.results.retry": "Retry",
	&"ui.results.consequence": "Consequence",
	&"ui.results.transmission": "CLEAR TRANSMISSION",
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
	&"ui.gacha.marks": {&"count": &"int"},
	&"ui.gacha.pull_action": {&"cost": &"int"},
	&"ui.gacha.pull_again": {&"cost": &"int"},
	&"ui.gacha.guarantee_in": {&"count": &"int", &"unit": &"String"},
	&"ui.gacha.confirm_body": {
		&"cost": &"int", &"before": &"int", &"after": &"int",
		&"count": &"int", &"unit": &"String",
	},
	&"ui.gacha.marks_needed": {&"count": &"int"},
	&"ui.gacha.rarity": {&"rarity": &"int"},
	&"ui.gacha.rarity_short": {&"rarity": &"int"},
	&"ui.gacha.lives": {&"count": &"int", &"unit": &"String"},
	&"ui.gacha.total_copies": {&"count": &"int"},
	&"ui.gacha.resonance_rarity": {&"rarity": &"int"},
	&"ui.gacha.lives_ready": {&"count": &"int", &"unit": &"String"},
	&"ui.gacha.next_guarantee": {&"count": &"int", &"unit": &"String"},
	&"ui.gacha.receipt_new": {&"rarity": &"String", &"callsign": &"String", &"guarantee": &"int"},
	&"ui.gacha.receipt_restored": {&"rarity": &"String", &"callsign": &"String", &"guarantee": &"int"},
	&"ui.gacha.receipt_duplicate": {&"rarity": &"String", &"callsign": &"String", &"lives": &"int", &"guarantee": &"int"},
	&"ui.gacha.error.unknown": {&"code": &"String"},
	&"ui.battle.hud_compact": {&"core": &"int", &"dp": &"int", &"eliminations": &"int", &"state": &"String"},
	&"ui.battle.hud_wide": {&"core": &"int", &"dp": &"int", &"eliminations": &"int", &"state": &"String"},
	&"ui.results.marks_reward": {&"count": &"int"},
	&"ui.results.unlocked_kind": {&"kind": &"String"},
	&"ui.results.xp_reward": {&"count": &"int"},
	&"ui.results.reserve_life_spent": {&"count": &"int"},
	&"ui.spell.cooldown": {&"seconds": &"String"},
	&"ui.spell.field_duration": {&"seconds": &"String"},
	&"ui.title.music_state": {&"state": &"String"},
	&"ui.title.motion_state": {&"state": &"String"},
	&"ui.title.master_volume": {&"value": &"int"},
	&"ui.title.music_volume": {&"value": &"int"},
	&"ui.title.sfx_volume": {&"value": &"int"},
	&"ui.title.frame_value": {&"value": &"int"},
	&"ui.staging.campaign_summary": {&"cleared": &"int", &"total": &"int"},
	&"ui.staging.next_detail": {&"index": &"int", &"title": &"String"},
	&"ui.staging.next_operation_title": {&"index": &"int", &"title": &"String"},
	&"ui.archive.records": {&"unlocked": &"int", &"total": &"int"},
	&"ui.archive.unlock_requirement": {&"index": &"int"},
	&"ui.vahalla.record": {&"stage": &"String", &"reason": &"String", &"tick": &"int"},
	&"ui.campaign.objective": {&"text": &"String"},
	&"ui.campaign.threat": {&"text": &"String"},
	&"ui.campaign.first_clear_reward": {&"rewards": &"String"},
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
	&"ui.identity_filter.summary": {&"shown": &"int", &"total": &"int"},
	&"ui.rename.confirm_body": {&"current": &"String", &"next": &"String"},
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
