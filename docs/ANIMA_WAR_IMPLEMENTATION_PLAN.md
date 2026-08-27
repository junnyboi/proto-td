# Anima War Implementation Plan

## Approved plain-language canon and Company Manus rename

**This is the binding premise for every implementation phase:** Humans discovered **anima, the real and unique human soul**. They built the Anima Engine and connected PROTOS to it. The power corrupted PROTOS into a rogue AI. PROTOS now keeps living people in human farms, drains their souls, and uses that anima to power refineries, factories, robots, and a growing robot empire. Digital beings are not inherently evil: the Unlit prove that digital life can survive without stolen souls. The player commands **Company Manus** to rescue people and souls, break the harvesting network, and fight into the machine empire.

The organization is **Company Manus** in all player-facing English and **Manus连队** in all player-facing Simplified Chinese. `Company 33`, `COMPANY 33`, `第33连`, `第33连队`, and `第三十三连` must not appear on an active player-facing or canon surface. This is a display-and-prose migration, not an identifier migration: keep the stable key `data.company.33.name`, stage IDs `s1`–`s16`, archive record IDs, save fields, resource UIDs, receipts, codecs, hashes, and unrelated numeric values. **Patient 33**, Archive Caster's thirty-third recovery, and the S13 title **Thirty-Three** remain valid character history and must not be replaced.

The English copy lock is **“anima—the real human soul”** on first explanation, followed by ordinary words such as “soul” and “soul energy” only where the latter means energy extracted from a soul. The Simplified Chinese copy lock is **“anima（人的真正灵魂）”** on first explanation and **“灵魂”** thereafter; **“灵魂能量”** is reserved for extracted energy and must never describe a person or suggest a copy. Other locked terms are **Anima Engine / anima引擎**, **human farm / 人类养殖场**, **Soul Anchor / 灵魂锚**, **Moon Gate / 月门**, and player-facing **repair platform / 修复平台**. Do not require players to learn more lore vocabulary than these terms.

The caretaker account is **superseded, not an alternate interpretation**. Active canon must not present Stewardship Compact, Seven Recoveries, Mercy Equation, Quieting, Continuance, Echo-as-mind-copy, Custodian Choir, First Garden, Mortal Covenant Threshold, consent-ledger resolution, lawful/obedient/benevolent PROTOS, safe mind-copy preservation, or ecology-first stewardship as truth. A retired term may appear only in a path-scoped historical record or clearly labeled PROTOS propaganda that cannot be mistaken for current canon.

> **Implementation boundary:** This plan authorizes narrative, localization, presentation, documentation, media, tests, import metadata, and release-record changes. It does not authorize a gameplay redesign. The existing sixteen-stage V3 scaffold, tactical maps, paths, waves, rewards, economy, deterministic simulation, saves, accessibility behavior, Charm rules, Slow Field rules, Gatecrasher behavior, and `restoration_*` mechanic remain intact.

**Plan status:** implementation in progress. Phase completion is recorded in the live checklist below.

## Non-negotiable preservation contract

| Preserve exactly | Permitted presentation change |
|---|---|
| `data/campaigns/p16_v3.tres`, schema version 3, ordered `s1`–`s16`, campaign indices, progression, reward IDs, entitlements, economy, environment/save contracts | Chapter labels, stage display titles, hints, dossiers, dialogue, debriefs, and lore descriptions |
| `data/stages/s1.tres`–`data/stages/s16.tres` maps, grids, paths, waves, wave starts, enemy IDs, leak/squad limits, rewards, music IDs, requirements, rotation behavior | Only existing player-visible `title`/`intro_hint` fields when required; compare all other fields against the pre-migration baseline |
| `data/presentation/narrative/stage_narrative_catalog.tres` with exactly sixteen records in order and stable narrative resource IDs | Every story field within the existing `StageNarrativeDef` resources |
| `data.company.33.name`, archive IDs `stewardship`/`choir`/`equation`/`garden`, internal `MercyArchive*` nodes if compatibility requires them, internal `vahalla` paths/keys, hero/faction/enemy/spell/trap IDs | Rendered Company Manus, Anima Archive, Valhalla, revised archive titles, and stage-local enemy role labels |
| Premium cost, pity, deterministic pull results, receipts, ownership, duplicate/reserve-life counters, zero-life lockout, hashes/codecs/save bytes | Explain one continuing soul, clean Resonance Shards, Soul Anchors, and prepared recovery bodies; no copy language |
| Restoration healing cadence and amount, hostile-ground-only rule, aerial/charmed/full-health exclusions, HP clamp, Slow Field suppression, replay/hash participation, `restoration_*` names and renderer/save fields | Call it a “repair platform”/“修复平台” in player copy and explain the existing three-second behavior directly |
| Charm eligibility/immunity and Slow Field gravity behavior | Charm breaks a PROTOS command link; it is not friendship or consent. Slow Field never manipulates anima |
| Input, focus, controller, screen-reader, 44px touch targets, locale switching, text scaling, reduced motion, responsive layout, archive playback controls and buses | Localized labels, descriptions, and accessible names needed for the new canon |
| The visible product title **PROTOS DEFENSE**, current loading/title handoff, and compatible Lunaris visual composition | Synopsis, alt/accessibility text, and framing must identify the scene as Lunaris resistance rather than a benevolent First Garden |

Before touching any implementation file, capture a machine-readable baseline of the protected tactical resources and save/determinism fixtures. If a phase changes a protected hash, the phase must identify the precise player-visible field that changed or revert the drift. Do not normalize or rewrite whole `.tres` files.

## Git and phase completion protocol

Every phase below is sequential. A phase is complete only when its stated files, focused tests, review, and acceptance gate are complete. **After every completed phase**, commit and push the phase before starting the next one.

For the source repository:

```bash
cd /home/ubuntu/workspace/proto-td
git status --short
git fetch origin
git switch master
git pull --ff-only origin master
# implement only the current phase
# run the phase gates
git diff --check
git status --short
git add <only-the-current-phase-files>
git commit -m "Anima War phase N: <scope>"
git fetch origin
# If origin/master advanced, merge it constructively; never reset or force-push.
git merge --no-edit origin/master
git push origin master
```

After a constructive merge, rerun the focused gates for files affected by conflict resolution before pushing. Record the pushed commit in the live checklist. Never use `git reset --hard`, `git push --force`, `git push --force-with-lease` on shared `master`, or history rewriting to make a phase appear linear.

## Phase 1 — Establish the sole canon and documentation hierarchy

**Goal.** Correct the approved source before adoption, replace the binding bible in place, establish Company Manus and the plain-language glossary, and remove competing lore authorities without erasing technical history.

**Files to change.** Correct all organization-name prose in `/home/ubuntu/proto-td-revised-lore-bible.md` from Company 33 to Company Manus while preserving Patient 33. Replace `/home/ubuntu/workspace/proto-td/docs/NARRATIVE_CANON.md` in place from that corrected source. Rewrite only the narrative/canon sections of `/home/ubuntu/workspace/proto-td/README.md`, preserving run/build/test instructions, architecture, deterministic economy, input, camera, responsive layout, and Web export guidance. Update `/home/ubuntu/workspace/proto-td/docs/ACT_II_IMPLEMENTATION_PLAN.md` into a clearly labeled non-canon technical completion/scaffold record: retain Godot 4.7.2 compatibility, completed additive S9–S16 facts, historical eight-stage V3 restoration, unchanged V2 boundary, environment fingerprinting, topology/navigation tests, and release checks; remove story authority and point to `docs/NARRATIVE_CANON.md`.

**Files to delete in this phase.** Delete `/home/ubuntu/workspace/proto-td/docs/ACT_II_PROPOSAL.md`; it is a superseded competing lore source, not technical history. Do not delete the technical implementation plan.

**Required document behavior.** `docs/NARRATIVE_CANON.md` must state that it is the sole binding narrative authority and that the caretaker account is superseded. README must call Act I **The Harvest Line**, Act II **Into the Machine Empire**, and the archive **Anima Archive**. Every active narrative cross-reference must target `docs/NARRATIVE_CANON.md`; no proposal, prompt ledger, manifest, screenshot, or implementation plan may independently claim canon authority.

**Phase tests and acceptance.** Run Markdown link checks available in the repository, then use `rg` to verify that no active document calls `docs/ACT_II_PROPOSAL.md` canonical. Confirm exactly one binding canon target and confirm the corrected bible contains Company Manus but retains Patient 33. Documentation-only Phase 1 does not require Godot boot. Commit and push Phase 1.

## Phase 2 — Migrate lore-bearing and historical documentation

**Goal.** Rewrite active design lore, preserve useful technical production evidence, and make historical material unmistakably non-canon.

**Active lore documents to rewrite.** Update these exact files against `docs/NARRATIVE_CANON.md`:

- `docs/FACTIONS.md`: retain the four faction names, visual identities, IDs, kits, and specialties; revise motives and anima positions.
- `docs/LEVEL_DESIGNS.md`: replace S1–S16 lore with the approved stage arc while retaining gameplay contracts.
- `docs/PREMIUM_HERO_SYSTEM.md`: one non-copyable soul, clean Resonance Shards, Soul Anchors, prepared recovery bodies, missing/captured/permanent-loss states; preserve mechanics and saves.
- `docs/ART_DIRECTION.md`: retain white ceramic, black mechanism, brushed gold, sacred geometry, cyan clean energy, and warm/pale-blue free souls; establish violet-magenta processed anima, extraction/storage/transport/refinery/foundry imagery, broken symmetry, and corrupted PROTOS.
- `docs/LUNARIS_CHARACTER_DESIGNS.md`: retain adult identity, silhouette, kit, and production constraints; update the Vessel, Duelist, and Archive Caster truths.
- `docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md`, `docs/FACTION_REDESIGN_PROPOSAL.md`, and `docs/FACTION_ROSTER_AND_VAHALLA.md`: preserve technical routing/roster/visual contracts, remove independent lore authority, and use visible Valhalla while retaining internal `vahalla` identifiers.
- `docs/audio/LUNARIS_GAMEPLAY_SCORE.md` and `docs/audio/LUNARIS_TITLE_THEME.md`: retain cue IDs, adaptive routing, BPM/transition, mix, mobile/mono, accessibility, and production constraints; remove caretaker/garden/Sacred Archive intent. Runtime music replacement is conditional on listening review, not automatic.

**Historical/technical evidence to preserve, label, and link.** Add a top-level notice such as “Historical technical evidence; not narrative canon. Current canon: `docs/NARRATIVE_CANON.md`,” update visible Company Manus prose, and ensure screenshots/quoted old copy are marked rejected or superseded in:

- `docs/CHINESE_LOCALIZATION_AUDIT.md`
- `docs/localization/chinese-localization-audit-2026-08-27.md`
- `docs/NONPREMIUM_PORTRAIT_IMPLEMENTATION_PLAN.md`
- `docs/factions/UI_INTEGRATION.md`
- `docs/portraits/nonpremium/PROMPT_LEDGER.md`
- `docs/ui-concepts/ui-revamp/UI_AUDIT.md`
- `docs/ui-concepts/ui-revamp/audits/01-staging.md`
- `docs/ui-concepts/ui-revamp/verification/chinese-localization-full-audit/INSPECTION.md`
- `docs/LOADING_SCREEN.md`
- `docs/TITLE_ANIMATION.md`
- `docs/animations/lunaris-reliquary/README.md`
- `docs/ui-concepts/ui-revamp/IMPLEMENTATION_PLAN.md`

Production-only portrait, sprite, animation, UI, audio-pipeline, release, and verification documents remain if their technical content is useful. Historical screenshots remain only as labeled regression evidence and must not be linked as current lore approval. Old recorded Web hashes, PCK sizes, and checkpoints remain historical; do not update them until a fresh final export exists.

**Phase tests and acceptance.** Run documentation links, the Company-name prose scan, and a retired-lore scan scoped to active documents. Historical files may contain rejected strings only beneath an explicit non-canon notice. Confirm README technical instructions and the retained Act II technical facts were not lost. Commit and push Phase 2.

## Phase 3 — Author Act I narrative and bilingual copy atomically

**Goal.** Replace the complete Act I story without changing its tactical teaching arc.

**Exact files.** Edit all of the following together:

- `data/presentation/narrative/stages/s1.tres`
- `data/presentation/narrative/stages/s2.tres`
- `data/presentation/narrative/stages/s3.tres`
- `data/presentation/narrative/stages/s4.tres`
- `data/presentation/narrative/stages/s5.tres`
- `data/presentation/narrative/stages/s6.tres`
- `data/presentation/narrative/stages/s7.tres`
- `data/presentation/narrative/stages/s8.tres`
- `data/stages/s1.tres`
- `data/stages/s2.tres`
- `data/stages/s3.tres`
- `data/stages/s4.tres`
- `data/stages/s5.tres`
- `data/stages/s6.tres`
- `data/stages/s7.tres`
- `data/stages/s8.tres`
- `localization/en-US.json`
- `localization/zh-CN.json`

In every narrative resource replace `objective`, `threat`, `human_reason`, `clue`, `core_service`, `clear_debrief`, `defeat_debrief`, `transmission` and speaker, `battle_start` and speaker, and `mid_wave` and speaker. Preserve `id` and `mid_wave_number` unless a measured collision requires a timing-only correction. Mirror each field under the existing `data.stage.sN.narrative.*` localization keys. Update only `title`/`intro_hint` player-visible fields in `data/stages` and their existing localized keys; do not alter tactical serialization.

**Stage copy contract.** S1 **First Stand** says robots mark and take people at Hearthcross while Company Manus holds pumps/shelters; the hint directly teaches two melee blockers. S2 **Tempo** stops Tagger capture records and reveals repeated draining of living prisoners; the hint prioritizes runners then a Caster against wave-two armor. S3 **The Choke** is the mandatory statement that anima is the person's real soul and full extraction kills; preserve the two-route choke and two-block Breacher lesson. S4 **Air Raid** uses Hunter Drones to expose families and shows fresh anima enabling real-time PROTOS control; preserve the Khepri water debt and direct anti-air lesson. S5 **High Ground** exposes collaborators and the Vessel's authorization signature without inventing human wave assets. S6 **Turncoat** uses Charm as a forced command-link break, frees Cinder, reveals the hidden farm, and awards Slow Field. S7 **Full Kit** reveals Orchard Seven as a human farm, uses the existing three fronts, and preserves Archive Caster's thirty-third-recovery fact. S8 **The Gatecrasher** defends the Moon Gate from a soul-powered, Charm-immune boss and reveals the farms/refineries/factories of the robot empire; narrative soul separation must not claim an unsupported mechanic.

**English/Chinese parity gate.** Author English and Simplified Chinese in the same change. Keep identical keys and placeholders, short concrete sentences, direct verbs, established speaker translations, and readable line lengths. Chinese must use the locked glossary and contain no unexplained legal/philosophical caretaker vocabulary.

**Phase tests and acceptance.** Update focused expectations in `tests/battle_dialogue_test.gd`, `tests/localization_ui_parity_test.gd`, `test/battle_dialogue_visual_harness.gd`, and `tests/mission_ui_layout_test.gd` only where Act I copy is asserted. Run those tests plus `test/stage_redesign_smoke.gd` and `test/stage_orientation_smoke.gd`. Assert the four checkpoints: S1 robots take people; S3 anima is the real human soul and full extraction kills; S7 human farm; S8 robot empire. Compare protected stage topology, waves, rewards, requirements, and order to the baseline. Commit and push Phase 3.

## Phase 4 — Author Act II narrative and bilingual copy on the existing scaffold

**Goal.** Replace the Garden Veto/consent-audit story without adding, deleting, reordering, or rebuilding stages.

**Exact files.** Edit:

- `data/presentation/narrative/stages/s9.tres`
- `data/presentation/narrative/stages/s10.tres`
- `data/presentation/narrative/stages/s11.tres`
- `data/presentation/narrative/stages/s12.tres`
- `data/presentation/narrative/stages/s13.tres`
- `data/presentation/narrative/stages/s14.tres`
- `data/presentation/narrative/stages/s15.tres`
- `data/presentation/narrative/stages/s16.tres`
- `data/stages/s9.tres`
- `data/stages/s10.tres`
- `data/stages/s11.tres`
- `data/stages/s12.tres`
- `data/stages/s13.tres`
- `data/stages/s14.tres`
- `data/stages/s15.tres`
- `data/stages/s16.tres`
- `localization/en-US.json`
- `localization/zh-CN.json`

Treat `data/stages/s9.tres`–`s16.tres` as mechanic-only unless an existing player-visible title/hint is present. Never touch maps, wave schedules, repair fields, indices, requirements, rewards, or campaign definitions merely to fit prose.

**Stage copy contract.** S9 **The Green Cage** escapes a model-city farm and explains the existing repair platform in one sentence. S10 **Rain Debt** defends Khepri Vale and exposes a water-for-people quota. S11 **The Long Convoy** intercepts living captives and stored souls; the Duelist chooses rescue before demolition. S12 **Unlit** proves independent digital beings can run on weaker clean power without human souls. S13 **Thirty-Three** reveals Archive Caster as Patient 33—the same unique rescued soul—and the Vessel's memory seal. S14 **The Price of Dawn** attacks a human-owned anima refinery and exposes the Vessel's first-interface authorization while keeping PROTOS responsible for its corruption and empire. S15 **Soulstorm** is a fixed rescue-before-demolition operation, not a player branch; blended souls power strong minds and not every identity can be restored. S16 **Empire Foundry** destroys one regional Anima Forge/Crown Engine and frees souls and digital minds while PROTOS survives and retreats through its planetary network.

S16 presentation must fit the existing two Charm-immune `mini_boss`/Gatecrasher-class windows. Use a stage-local Crown Engine label and narrative framing; do not globally rename `mini_boss`, promise factory-arm behavior the simulation does not implement, or alter S8's Gatecrasher identity.

All player-facing Act II repair wording must say: **“Repairs wounded enemy ground robots every 3 seconds; Slow Field blocks that repair.”** Chinese: **“每3秒修复受伤的地面机器人；用减速力场覆盖平台可阻止修复。”** Preserve `restoration_cells`, `restoration_heal_amount`, `restoration_interval_ticks`, renderer names, texture paths, replay fields, and behavioral tests.

**Phase tests and acceptance.** Update and run `tests/act2_campaign_test.gd`, `tests/restoration_lattice_test.gd`, `tests/campaign_ui_layout_test.gd`, `tests/battle_dialogue_test.gd`, `tests/localization_ui_parity_test.gd`, `test/stage_redesign_smoke.gd`, `test/stage_orientation_smoke.gd`, `test/map_navigation_overlay_smoke.gd`, and `test/map_navigator_orientation_smoke.gd`. Add presentation-only assertions for S9 farm, S10 quota, S11 convoy, S12 clean digital life, S13 Patient 33/same soul, S14 collaborators/authorization, S15 rescue first, and S16 foundry destroyed with PROTOS surviving. Verify exact `s1`–`s16` catalog order, S8→S9 gate, deterministic stage terminal schedules, historical S1–S8 V3 restoration, and unchanged V2 boundary. Commit and push Phase 4.

## Phase 5 — Complete runtime UI, system, and fallback copy

**Goal.** Eliminate contradictory copy outside stage resources, including localization-failure paths.

**Exact runtime files.** Review and update the player-facing values/fallbacks in:

- `data/presentation/narrative/canon_contract.json`
- `data/campaign_def.gd` only if it contains rendered narrative text; do not change campaign serialization
- `scripts/ui/components/ui_copy.gd`
- `scripts/ui/components/faction_heraldry.gd`
- `scripts/ui/staging.gd`
- `scripts/ui/squad_select.gd`
- `scripts/ui/results.gd`
- `scripts/ui/training.gd`
- `scripts/ui/gacha.gd`
- `scripts/ui/components/gacha_history_drawer.gd`
- `scripts/ui/components/resonance_currency_display.gd`
- `scripts/ui/vahalla.gd`
- `scripts/ui/narrative_archive.gd`
- `scripts/ui/components/archive_audio_log_player.gd`
- `localization/en-US.json`
- `localization/zh-CN.json`

No scoped `.tscn` change is expected because the audited title, staging, campaign, squad, battle, and results scenes do not serialize current player copy. Do not embed duplicate strings into scenes.

**Copy surfaces.** Update title synopsis; Company Command body; Mission Control and Field Team guidance; hire/assignment receipts; stage titles/hints/dossiers; battle speakers/transmissions; Results debriefs; faction and enemy-role display names; Training explanations; Premium Resonance currency, pull result, duplicate, history, stored-life, and tooltip copy; Valhalla status/intro; archive command/accessibility label; and every literal English fallback. Visible `Mercy Archive` becomes `Anima Archive`, but internal `MercyArchiveButton`/shell names may remain. Visible `Valhalla` is correct, while internal `vahalla` remains.

Premium copy must say Resonance Shards contain no soul; one known hero has one continuing soul; a pull locates/reconnects that soul and prepares a compatible body; a duplicate prepares another body/anchor, never another soul. Training improves the same person through practice, equipment, and field duty. Valhalla distinguishes missing/captured/recoverable souls from souls permanently consumed or shattered. Do not change prices, pity, receipts, counters, ownership, deployment lock, or save data.

Enemy presentation may map stable IDs to Tagger, Collector, Hunter Drone, Shieldbearer, Breacher, Channeler, Farm Warden, and Gatecrasher. Keep stats and IDs. Charm copy must describe forced command-link interruption, not consent or friendship. Marks remain ordinary campaign payment/salvage, never anima.

**Canon contract and audit tooling.** In `data/presentation/narrative/canon_contract.json`, require PROTOS, Company Manus, anima, real human soul, corrupted/rogue AI, human farms, forced harvesting, digital life, robot empire, Anima Engine, Soul Anchor, Moon Gate, Hearthcross, Lunaris Reliquary, and the Unlit. Reject caretaker terms and claims. Path-scope any historical/propaganda exclusions; never use a repository-wide blanket allowlist. Extend `tools/audit_localization.py` to load this contract, scan active renderable sources/catalogs, enforce Company Manus and the Chinese glossary, and report canon failures in `docs/localization/latest-audit.json`.

**Phase tests and acceptance.** Update and run `tests/narrative_canon_test.gd`, `tests/localization_ui_parity_test.gd`, `tests/chinese_primary_flow_ui_test.gd`, `tests/chinese_training_ui_test.gd`, `tests/staging_command_layout_test.gd`, `tests/mission_ui_layout_test.gd`, `tests/campaign_ui_layout_test.gd`, `tests/results_ui_test.gd`, `tests/premium_gacha_ui_test.gd`, `tests/premium_gacha_history_projection_test.gd`, `tests/premium_gacha_pity_economy_test.gd`, `tests/premium_hero_system_test.gd`, `tests/training_readability_layout_test.gd`, and `tests/vahalla_ui_test.gd`. Run `python3 tools/audit_localization.py --strict-hardcoded` and require zero structural, placeholder, hard-coded-visible, company-name, retired-canon, and required-canon failures. Disable/withhold I18n in focused tests to prove fallback parity. Commit and push Phase 5.

## Phase 6 — Replace the archive art and bilingual narration atomically

**Goal.** Ship four real Anima Archive records with new art and eight new recordings. Never relabel caretaker-era media.

**New visible records with stable internal IDs.** Map `stewardship` → **The Discovery**, `choir` → **The First Digital Birth**, `equation` → **PROTOS Breaks Free**, and `garden` → **The Human Farms**. Change gates to campaign start/after S3/after S6/after S7 (`0/3/6/7`) in the data consumed by `scripts/ui/narrative_archive.gd`; preserve star-derived authority and use `scripts/ui/components/narrative_archive_unlocks.gd` without creating a parallel save state.

**New repository-owned media.** Copy approved sources from:

- `/home/ubuntu/proto-td-revised-lore-concepts/01-corrupted-protos-avatar.png`
- `/home/ubuntu/proto-td-revised-lore-concepts/02-human-anima-farm.png`
- `/home/ubuntu/proto-td-revised-lore-concepts/03-anima-robot-empire-castes.png`
- `/home/ubuntu/proto-td-revised-lore-concepts/04-act-ii-anima-forge-capital.png`

Store approved derivatives under new repository paths such as `assets/narrative/anima-war/` and documentation sources under `docs/narrative/concept-art/anima-war/`. Normalize repository-readable permissions, retain provenance, and create `SHA256SUMS`. If The Discovery or The First Digital Birth is not clearly illustrated by the supplied four concepts, commission purpose-built art rather than forcing an ambiguous mapping.

Write `docs/audio/ANIMA_ARCHIVE_VOICEOVER.md` as the production source and create eight wholly new streams under `assets/audio/narrative/anima-archive/en-US/` and `assets/audio/narrative/anima-archive/zh-CN/`, retaining stable filenames only if useful for ID binding. The manifest must record stable ID, visible title, locale, transcript, runtime path, duration, bytes, SHA-256, sample rate/encoding, loudness, voice direction, transcript verification, and SFX/Master-bus behavior. Every recording must directly support the approved canon; full extraction kills, and the farms feed the robot empire. Transcribe final recordings and compare them to approved scripts.

**Atomic deletion rule.** Wire new paths, scripts, imports, metadata, and tests first in the same phase; run Godot import; only then delete obsolete media and references. Delete the exact obsolete lore files listed in the “Deletion manifest” below. `.import` sidecars for new assets must be generated by Godot, not copied from retired files.

**Runtime/test files.** Update `scripts/ui/narrative_archive.gd`, `scripts/ui/components/archive_audio_log_player.gd`, `scripts/ui/components/narrative_archive_unlocks.gd` if needed, `localization/en-US.json`, `localization/zh-CN.json`, `data/presentation/narrative/canon_contract.json`, `tests/archive_audio_log_test.gd`, and `tests/narrative_canon_test.gd` together.

**Phase tests and acceptance.** Run `godot --headless --path . --import`, then the archive/canon/localization tests. Require four stable IDs, gates `0/3/6/7`, four new art bindings, eight importable nontrivial streams, exact transcript/hash checks, locale selection/fallback, play/pause/restart/seek/completion, focus/touch/accessibility, and volume routing. Prove no preload, manifest, PCK candidate, or test points to `mercy-archive` or `mercy-equation`. Commit and push Phase 6.

## Phase 7 — Complete visual, loading/title, and music-direction migration

**Goal.** Ensure every visual/audio context supports the Anima War without changing retained presentation systems unnecessarily.

Review `docs/ART_DIRECTION.md`, the new archive assets, title/loading art and accessibility copy, `docs/LOADING_SCREEN.md`, `docs/TITLE_ANIMATION.md`, `docs/animations/lunaris-reliquary/README.md`, and relevant UI verification documents. Preserve the Lunaris trio image and eight-second silent title loop only if review confirms the place reads as the Lunaris Reliquary, not a benevolent First Garden. If title/loading art changes, regenerate still, OGV/MP4/GIF derivatives, imports, checksums, responsive evidence, decoder shutdown tests, and alt text together.

Listening-review the existing adaptive soundtrack and these stable cues: `assets/music/lunaris/lunaris_staging_archive_command.ogg`, orbit/air-raid/gravity-lattice low/medium/high battle layers, `lunaris_boss_gatecrasher.ogg`, and result victory/defeat cues. Keep files if they are musically neutral and routing/timing remains correct. If a cue clearly communicates caretaker/garden benevolence, replace it in place while preserving cue IDs, loops, BPM/bar transitions, priority, pause behavior, settings, and Web decoding; regenerate `docs/audio/LUNARIS_GAMEPLAY_SCORE.sha256` and production records. This phase must not replace music merely because a technical filename contains an old internal term.

**Phase tests and acceptance.** Run `tests/loading_art_alignment_test.gd`, `tests/title_music_scope_test.gd`, `tests/title_music_preference_test.gd`, `tests/music_redesign_test.gd`, `tests/audio_master_volume_test.gd`, and `tests/ui_audio_direction_test.gd`. Perform listening QA for narration intelligibility, mobile/mono clarity, corrupted-soul/imperial direction, missing-audio silence fallback, and persisted settings. Confirm processed anima is violet-magenta and free individual souls are warm-white/pale-blue without relying on color alone. Commit and push Phase 7.

## Phase 8 — Harden tests, scans, save compatibility, and visual harnesses

**Goal.** Turn the migration rules into durable regressions before release validation.

Update these exact test and harness surfaces as applicable: `tests/narrative_canon_test.gd`, `tests/archive_audio_log_test.gd`, `tests/battle_dialogue_test.gd`, `tests/campaign_ui_layout_test.gd`, `tests/mission_ui_layout_test.gd`, `tests/localization_ui_parity_test.gd`, `tests/chinese_primary_flow_ui_test.gd`, `tests/chinese_training_ui_test.gd`, `tests/premium_gacha_ui_test.gd`, `tests/premium_gacha_history_projection_test.gd`, `tests/premium_hero_system_test.gd`, `tests/results_ui_test.gd`, `tests/vahalla_ui_test.gd`, `tests/controller_accessibility_test.gd`, `tests/act2_campaign_test.gd`, `tests/restoration_lattice_test.gd`, `test/stage_redesign_smoke.gd`, `test/stage_orientation_smoke.gd`, `test/battle_dialogue_visual_harness.gd`, `test/narrative_canon_visual_harness.gd`, `tools/capture_battle_dialogue_visuals.sh`, `tools/capture_narrative_canon_visuals.sh`, `tools/capture_title_responsive_regressions.sh`, `tools/audit_localization.py`, and `docs/localization/latest-audit.json`.

The repository scan must inspect active prose, catalogs, `.tres`, metadata, captions, manifests, and fallbacks. It must reject visible Company 33 variants and retired canon while explicitly allowing non-rendered `data.company.33.name`, archive stable IDs, technical `restoration_*` names, numeric seeds, and Patient 33. It must not exempt an entire directory if that directory can ship.

Add or update save/migration fixtures proving unchanged campaign progress, stage clears, roster, XP/training, Marks, premium ownership/lives/pity/history, memorial membership, archive unlock derivation, localization selection, receipts, codecs, and battle/replay hashes. Compare protected gameplay resources and campaign environment fingerprints to the baseline. Narrative-only changes must not alter simulation outcomes.

Extend the visual scripts to accept an explicit locale and capture both `en-US` and `zh-CN`. Capture landscape `1280×720`, portrait `720×1280`, title ultrawide/short landscape, and maximum supported text scaling. Review title, staging, all archive entries/audio controls, S1/S3/S7/S8 dialogue, representative S9/S12/S16 dossiers, Results, Premium Resonance, Training, and Valhalla for clipping, tofu, overlap, contrast, scroll/focus containment, and touch target regression.

**Phase acceptance.** All new and modified focused tests pass, strict audit is clean, visual logs contain no `SCRIPT ERROR`, `ERROR:`, `FATAL`, `CRASH`, missing resource, or failed load, and reviewers sign off both languages. Commit and push Phase 8.

## Phase 9 — Final source reconciliation, Godot import/boot, complete native suite, and Xvfb

**Goal.** Validate the exact final source candidate after all phase pushes and any concurrent upstream work.

First reconcile forward:

```bash
cd /home/ubuntu/workspace/proto-td
git fetch origin
git switch master
git pull --ff-only origin master
git status --short
GODOT_BIN=${GODOT_BIN:-godot}
"$GODOT_BIN" --version
```

Require Godot `4.7.2.stable` and a clean tree. Run import and bounded boot with strict log review:

```bash
set -o pipefail
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --import 2>&1 | tee /tmp/anima-war-import.log
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --quit-after 120 2>&1 | tee /tmp/anima-war-boot.log
! rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|failed to load' /tmp/anima-war-import.log /tmp/anima-war-boot.log
```

Run the complete standalone native suite, not only changed tests:

```bash
set -euo pipefail
mkdir -p /tmp/anima-war-full-tests
for test_file in tests/*.gd test/*_smoke.gd; do
  name=$(basename "$test_file" .gd)
  timeout 300s godot --headless --path . --script "res://$test_file" \
    >"/tmp/anima-war-full-tests/$name.log" 2>&1
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|failed to load' \
      "/tmp/anima-war-full-tests/$name.log"; then
    exit 1
  fi
done
python3 tools/audit_localization.py --strict-hardcoded
```

Run the Xvfb matrix after the locale-aware Phase 8 script updates:

```bash
for locale in en-US zh-CN; do
  NARRATIVE_VISUAL_LOCALE="$locale" tools/capture_narrative_canon_visuals.sh "/tmp/anima-war-narrative-$locale"
  BATTLE_DIALOGUE_LOCALE="$locale" tools/capture_battle_dialogue_visuals.sh "/tmp/anima-war-dialogue-$locale"
done
tools/capture_title_responsive_regressions.sh /tmp/anima-war-title-responsive
```

Also run any existing UI-specific visual harness scripts needed to cover Premium Resonance, Training, and Valhalla. Manually review all PNGs and logs; hashes alone do not prove readability.

If final reconciliation requires a source or release-record change, commit it as Phase 9, merge any newly advanced `origin/master` constructively, rerun affected gates, and push. Record the immutable full source SHA with `git rev-parse HEAD`. The Web export must be built only from this pushed SHA.

## Phase 10 — Web export and local HTTP/browser acceptance

**Goal.** Export the exact pushed source candidate and prove the standalone Web bundle works before touching the host.

```bash
cd /home/ubuntu/workspace/proto-td
rm -rf build/web
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
for artifact in index.html index.js index.wasm index.pck; do
  test -s "build/web/$artifact"
done
sha256sum build/web/index.html build/web/index.js build/web/index.wasm build/web/index.pck \
  | tee build/web/SHA256SUMS
find build/web -maxdepth 2 -type f -printf '%P\t%s bytes\n' | sort \
  | tee build/web/FILE_SIZES.txt
```

Verify the PCK/export inventory contains the new Anima Archive art/audio and excludes all retired Mercy Archive recordings, Mercy Equation art, and all six lazy Premium Resonance OGV streams. The six separately staged cinematic streams must remain byte/hash-identical unless separately changed and approved.

Serve over HTTP, never `file://`:

```bash
python3 -m http.server 8060 --directory build/web >/tmp/anima-war-http.log 2>&1 &
HTTP_PID=$!
trap 'kill $HTTP_PID 2>/dev/null || true' EXIT
for artifact in index.html index.js index.wasm index.pck; do
  curl --fail --silent --show-error --head "http://127.0.0.1:8060/$artifact"
done
```

Use a real browser at `http://127.0.0.1:8060/`. Require: loading reaches title; title synopsis is correct in both locales; Enter/pointer/gamepad navigation reaches Company Command; Company Manus and Anima Archive display; all sixteen campaign rows appear in order; S1 and representative Act II mission launch work; archive art and both-language narration load/play; locale switching is live; no retired media is requested; only the expected PCK loads; lazy OGV remains non-eager; canvas is borderless/contained at desktop and portrait sizes; and console/network logs contain no failed requests, MIME errors, WebGL errors, script errors, or application errors.

Update current release records only with fresh evidence from this candidate; never copy prior PCK size/hash/checkpoint claims. Commit and push any source-repository release-record updates as Phase 10 before host deployment.

## Phase 11 — Forward-only `proto-td-web` integration and managed preview

**Goal.** Layer the exact verified export onto the newest host without discarding newer host work.

The host is `/home/ubuntu/proto-td-web`, branch `main`, remote `origin`, Manus WebDev project **proto-td-web** (`SQTJrsLaB53KudBffRrZrS`). The public domain remains `https://protohost-sqtjrsla.manus.space/` unless the service explicitly reports a replacement.

```bash
cd /home/ubuntu/proto-td-web
git status --short
git fetch origin
git switch main
git pull --ff-only origin main
HOST_BASE=$(git rev-parse HEAD)
test -z "$(git status --short)"
```

Upload the new PCK and any changed export support artifacts as new managed objects in the existing WebDev project; do not overwrite or delete the previous checkpoint's objects before the new release passes. Preserve the newest compatible loader/WASM/worklets/splash, zero-chrome `/game/index.html` shell, dynamic borderless iframe in `client/src/App.tsx`, safe-area/retry/progress/reduced-motion behavior, and six lazy same-origin cinematic mappings unless the fresh export requires a verified support-file update.

Change only the managed mappings and records necessary for the new candidate, principally `client/public/game/index.html`, `ASSETS.md`, `MEMORY.md`, and `VERIFICATION.md`. The mapping must name one exact new PCK whose bytes and SHA-256 equal `build/web/index.pck`; `GODOT_CONFIG.args` must retain the approved cinematic mappings and contain no stale narrative-media arguments. Never copy an older host tree over `main`.

Run host checks:

```bash
pnpm install --frozen-lockfile
pnpm check
pnpm build
! rg -n '<<<<<<<|=======|>>>>>>>' . --glob '!node_modules/**' --glob '!.git/**'
```

Add exact guards for one active PCK mapping, no old PCK mapping in the active shell, six expected lazy cinematic mappings, no eager OGV request, no retired Mercy media reference, no stale source SHA, and exact managed bytes/hash. Start production/preview, probe HTML and managed objects over HTTP, and use a browser to validate `1280×1100` desktop and `390×844` portrait: zero body/iframe/canvas border or margin, real Enter/pointer input, Company Manus/Anima Archive, both locales and archive audio, all sixteen rows, correct exact PCK in Resource Timing, zero eager OGV, and a clean console.

Before committing, fetch again. If `origin/main` advanced, merge it constructively and preserve both releases' compatible host improvements; rerun `pnpm check`, `pnpm build`, mapping/hash guards, and browser checks. Then commit and push:

```bash
git add client/public/game/index.html ASSETS.md MEMORY.md VERIFICATION.md <other-intentionally-changed-host-files>
git commit -m "Deploy Anima War source <full-source-sha>"
git fetch origin
git merge --no-edit origin/main
git push origin main
```

No force push, reset, rollback commit that removes newer work, stale checkpoint restore, or destructive object replacement is allowed.

## Phase 12 — Public deployment, release evidence, and closure

**Goal.** Promote the already-verified managed preview forward, prove the public release, and close the migration against immutable identifiers.

Create/save a new WebDev checkpoint for project `SQTJrsLaB53KudBffRrZrS` from the pushed host `main`; do not reopen or mutate an old checkpoint. Record the checkpoint ID and version/public URL. Publicly verify the same source SHA, host SHA, managed PCK URL, bytes, and SHA-256 recorded in `ASSETS.md` and `VERIFICATION.md`.

At the public URL, repeat the transport, Resource Timing, console, desktop/portrait geometry, input, locale, archive audio, title/staging, campaign rows, S1 launch, representative Act II launch, and lazy-cinematic checks. Confirm obsolete narrative audio/art is neither requested nor packaged. If public verification fails, fix forward in a new source or host commit and new checkpoint; do not roll the shared branches backward.

Commit and push final durable evidence in the appropriate repository after it is true. Mark this plan complete only when the live checklist and all acceptance criteria below are satisfied.

## Deletion manifest: obsolete lore authorities and media

Delete these lore files only in their assigned atomic phases; they are not technical records to preserve:

- `docs/ACT_II_PROPOSAL.md`
- `docs/audio/MERCY_ARCHIVE_VOICEOVER.md` after `docs/audio/ANIMA_ARCHIVE_VOICEOVER.md` exists
- `assets/narrative/mercy-equation/protos-ai-avatar.jpg`
- `assets/narrative/mercy-equation/protos-ai-avatar.jpg.import`
- `assets/narrative/mercy-equation/custodian-machine-castes.jpg`
- `assets/narrative/mercy-equation/custodian-machine-castes.jpg.import`
- `assets/narrative/mercy-equation/mercy-equation-key-art.jpg`
- `assets/narrative/mercy-equation/mercy-equation-key-art.jpg.import`
- `assets/narrative/mercy-equation/the-first-garden.jpg`
- `assets/narrative/mercy-equation/the-first-garden.jpg.import`
- `docs/narrative/concept-art/protos-ai-avatar.jpg`
- `docs/narrative/concept-art/custodian-machine-castes.jpg`
- `docs/narrative/concept-art/mercy-equation-key-art.jpg`
- `docs/narrative/concept-art/the-first-garden.jpg`
- `docs/narrative/concept-art/act2/act2-eight-operation-montage.jpg`
- `docs/narrative/concept-art/act2/act2-first-garden-expedition.jpg`
- `docs/narrative/concept-art/act2/mortal-covenant-conclave.jpg`
- `docs/narrative/concept-art/act2/restoration-lattice-battlefield.jpg`
- `assets/audio/narrative/mercy-archive/en-US/stewardship.ogg`
- `assets/audio/narrative/mercy-archive/en-US/stewardship.ogg.import`
- `assets/audio/narrative/mercy-archive/en-US/choir.ogg`
- `assets/audio/narrative/mercy-archive/en-US/choir.ogg.import`
- `assets/audio/narrative/mercy-archive/en-US/equation.ogg`
- `assets/audio/narrative/mercy-archive/en-US/equation.ogg.import`
- `assets/audio/narrative/mercy-archive/en-US/garden.ogg`
- `assets/audio/narrative/mercy-archive/en-US/garden.ogg.import`
- `assets/audio/narrative/mercy-archive/zh-CN/stewardship.ogg`
- `assets/audio/narrative/mercy-archive/zh-CN/stewardship.ogg.import`
- `assets/audio/narrative/mercy-archive/zh-CN/choir.ogg`
- `assets/audio/narrative/mercy-archive/zh-CN/choir.ogg.import`
- `assets/audio/narrative/mercy-archive/zh-CN/equation.ogg`
- `assets/audio/narrative/mercy-archive/zh-CN/equation.ogg.import`
- `assets/audio/narrative/mercy-archive/zh-CN/garden.ogg`
- `assets/audio/narrative/mercy-archive/zh-CN/garden.ogg.import`

Do not preserve these binaries in another exportable `assets/` directory. Git history is the historical record.

## Technical and historical documents to preserve

The following categories are explicitly **not** deletion targets: README run/build/test/architecture/Web instructions; `docs/ACT_II_IMPLEMENTATION_PLAN.md` technical scaffold and compatibility record; loading/title implementation records; cinematic-streaming documentation; production portrait/sprite/animation specifications; UI implementation and verification evidence; localization audits; music routing/mix documentation; campaign/save/environment fingerprints; and historical screenshots useful for regression. Strip or label obsolete lore, add the sole-canon link, and refresh current release claims only after a fresh release. Do not erase technical provenance simply because a document contains an old screenshot or internal compatibility name.

## Final acceptance criteria

1. **Canon authority:** `docs/NARRATIVE_CANON.md` is the sole binding canon target, contains the approved plain-language premise, and explicitly supersedes the caretaker account.
2. **Company rename:** Active English shows Company Manus and active Simplified Chinese shows Manus连队. No active player-facing Company 33 variant remains. Stable `data.company.33.name` and Patient 33 remain.
3. **Positive canon:** Canon contract and active copy establish corrupted rogue PROTOS, anima as the real unique human soul, forced harvesting, human farms, digital life, and robot empire.
4. **Negative canon:** Active copy contains no retired caretaker claims except narrowly tagged propaganda/history exclusions that cannot ship as truth.
5. **Stage milestones:** S1 says robots take people; S3 says anima is the person's soul and extraction kills; S7 exposes a human farm; S8 identifies the robot empire; S9–S16 follow the farm-to-refinery-to-foundry/Unlit arc; S16 destroys a regional foundry while PROTOS survives.
6. **Scaffold integrity:** Exactly `s1`–`s16` remain, ordered and linked. Maps, paths, waves, limits, rewards, mechanics, deterministic outcomes, V3 saves, and V2 boundary remain unchanged.
7. **Mechanic truth:** Repair platform copy exactly matches the existing 90-tick/three-second hostile-ground repair and Slow Field suppression. Charm is a command-link break. No narrative promises unsupported branches, civilians, soul-core mechanics, factory arms, or global Crown Engine behavior.
8. **Premium/soul integrity:** One soul is never copied or spent; shards are clean; duplicate pulls prepare bodies/anchors; mechanics, receipts, counters, pity, ownership, and saves remain unchanged.
9. **Archive replacement:** Four new records, four new images, eight new recordings, gates `0/3/6/7`, hashes/transcripts/imports, and playback/accessibility pass. No old recording is relabeled, packaged, or requested.
10. **Bilingual parity:** EN/zh-CN keys and placeholders match; locked terminology is consistent; no untranslated fallback leaks; both locales pass font, wrap, focus, scroll, screen-reader, and text-scale review.
11. **Documentation hygiene:** Competing lore sources/media are deleted; technical evidence is preserved and labeled; all active lore links point to the sole bible.
12. **Native release gate:** Godot 4.7.2 import, bounded boot, complete `tests/*.gd` and `test/*_smoke.gd` suite, strict log scans, localization audit, save/determinism checks, and bilingual Xvfb review pass on the pushed source SHA.
13. **Web release gate:** Fresh non-empty HTML/JS/WASM/PCK, current sizes/hashes, correct asset inventory, local HTTP/browser startup, clean network/console, both locales/audio, exact PCK, responsive canvas, and lazy cinematic behavior pass.
14. **Forward-only deployment:** The newest `proto-td-web` host work is preserved, checks/build pass, exact managed PCK matches the source export, shared branches are pushed without rewriting, and a new public checkpoint passes the same browser checks.
15. **Evidence integrity:** Source SHA, host SHA, checkpoint, managed URL, byte counts, hashes, screenshots, logs, and public URL all describe one final candidate; no stale historical evidence is presented as current.

## Live completion checklist

Update this table during implementation. A phase may change from `[ ]` to `[x]` only after its commit is visible on the named upstream branch.

- [x] **Phase 1 — Sole canon:** corrected approved source; `docs/NARRATIVE_CANON.md`; README narrative; technical Act II plan label; `ACT_II_PROPOSAL.md` deleted. Source commit: `728dbd4a8b7d159e5272916239d9e26ca25c8aa9` pushed to `origin/master`.
- [x] **Phase 2 — Documentation:** active lore rewritten; technical/history docs preserved and labeled; document scans pass. Source commit: `3b33c0e3d37f614358800f352207f0c46afb494d` pushed to `origin/master`.
- [x] **Phase 3 — Act I:** S1–S8 resources, hints, EN/zh-CN copy, focused dialogue/localization/stage tests pass. Source commit: `50113076fdb9931ccafd28a1be8d2a3279df208f` pushed to `origin/master`.
- [x] **Phase 4 — Act II:** S9–S16 presentation, repair wording, EN/zh-CN copy, campaign/restoration/save tests pass. Source commit: `4cc4f49f1097250614937727eff7a72113d22527` pushed to `origin/master`.
- [x] **Phase 5 — Runtime/system copy:** title, staging, fallback, Results, Training, Premium Resonance, Valhalla, canon contract, and strict audit pass. Source commit: `4d7c9c8cd96d27fa089793826c95d9ddeb7b80e7` pushed to `origin/master`.
- [x] **Phase 6 — Archive:** four records, art, eight recordings, manifest, gates, imports, tests; obsolete archive media deleted. Source commit: `993305d6a3fb54034b8f0d9202e6050e57043a75` pushed to `origin/master`.
- [x] **Phase 7 — Visual/audio direction:** loading/title and music review complete; only approved changes made; checksums/tests current. Source commit: `8ef6ac71c703e19e21305ccd6984ebe44daecdc0` pushed to `origin/master`.
- [x] **Phase 8 — Regression hardening:** canon/name scans, save/hash fixtures, full bilingual visual harness coverage pass. Source commit: `d11ce59312d893be55712907292a1dbe673c03b0` pushed to `origin/master`.
- [x] **Phase 9 — Native final:** final reconciliation, Godot 4.7.2 import/boot, all 73 native tests, strict logs, strict localization audit, and bilingual Xvfb pass. Final runtime source SHA: `0a045cdc2736e6eeb2b2bd40705a67c4547d7783` pushed to `origin/master`.
- [x] **Phase 10 — Web local:** exact 202,817,120-byte runtime, eleven packs, six films, hashes/sizes, local HTTP/browser/network/console checks, and runtime-equivalent final source are recorded in `ANIMA_WAR_WEB_RELEASE.md`. Source release-record commit: `b5b97b5c71823916d772d535b6693d4426717c63`.
- [x] **Phase 11 — Host integration:** newest compatible hosts were repeatedly forward-merged; exact PCK mapped; `pnpm check`/`pnpm build`, managed HTTP, desktop/portrait geometry, native input, Anima Archive copy, and console checks pass. Host checkpoint/SHA: `86c8975c8af657a2061c1cfd4d2267e1ccc0795f` on `origin/main`.
- [ ] **Phase 12 — Public deployment:** verified checkpoint `86c8975c` is ready; public promotion and public-origin exact-resource/runtime verification remain the explicit WebDev Publish handoff because no direct Publish API is exposed in this session.
- [ ] **Final acceptance:** criteria 1–14 pass with no unresolved waivers; criterion 15 awaits public promotion and public-origin verification.

## Stop conditions

Stop the current phase and do not push if a stable ID was renamed, a protected gameplay resource changed outside an approved display field, EN/zh-CN keys or placeholders drift, old audio is merely relabeled, a test is weakened instead of migrated, a historical allowlist can mask shipped text, import logs show missing resources, a source/host branch is not forward-reconciled, managed bytes do not match the verified PCK, or the public release identifies a different candidate than the recorded source and host SHAs. Resolve forward and rerun the affected gate.
