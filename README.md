# Protos

Protos is a tactical tower-defense game built with Godot 4.7.2.

## Run

Open the repository in Godot 4.7.2 or run:

```bash
godot --path .
```

The main scene is `res://scenes/title.tscn`.

## Gameplay and campaign features

The sixteen-operation campaign spans **Act I — The Harvest Line** and **Act II — Into the Machine Empire**. The player leads **Company Manus** against corrupted PROTOS, which drains anima—the real human soul—from captive people to power a robot empire. The campaign routes players from Company Command into Mission Control, squad selection, deterministic isometric battles, results, training, Premium Resonance, Valhalla, and the narrated Anima Archive. S9–S16 retain authored repair platforms that heal hostile ground robots on deterministic intervals unless an active Slow Field covers the platform. Mission Control displays the authoritative roster and Marks balance and offers a compact repeatable **basic Recruit contract for 5 Marks**; the Field Team workspace repeats the same authoritative contract beside the live roster. Premium Resonance remains a separate 40-Mark pull with pity, conversion history, and reserve-life rules; traps and spells are campaign unlocks rather than spendable currencies.

Battlefields use an endpoint-aware isometric projection with bounded portrait panning and a shared 0.92 tactical framing multiplier. Recruit animation definitions share a source ground line so male and female idle/attack sprites remain centered on their tile faces in every direction. Camera, placement, economy, persistence, keyboard focus, bilingual copy, and responsive Mission Control layouts are covered by standalone Godot regressions and Xvfb visual harnesses.

## Basic development check

For runtime changes, verify the final candidate with a direct import and bounded boot:

```bash
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . --quit-after 120
```

Documentation-only changes do not require an engine check. Run focused tests or manual previews when they are useful for the code being changed. Web export and browser checks are release-only.

## Slow Field balance telemetry

Run deterministic paired telemetry against the authored S7 and S8 waves with:

```bash
SLOW_FIELD_TELEMETRY_JSON=/tmp/slow-field-telemetry.json \
SLOW_FIELD_TELEMETRY_CSV=/tmp/slow-field-telemetry.csv \
godot --headless --path . --script tests/slow_field_balance_telemetry_test.gd
```

The baseline and Slow Field scenarios use identical authored waves with no combatants. Leak limits and base HP are raised only so every wave resolves. The Slow Field policy casts at the median shared-path cell when the spell is ready and at least two live ground enemies occupy its 3×3 footprint. This isolates route-control impact; it is not a player win-rate simulation.

## Web export and soundtrack scope

The runtime preserves the approved loading/title theme, **Astra Memoriam**, and ships the faction-led Lunaris score across Company Command, S1–S16, both Gatecrasher audit windows, and results. Act II gives S9–S16 one unique looped battle composition each, while cue-continuous intensity metadata avoids restarting or seeking those stage identities. Responsive repair-platform-seal entry and terminal transitions pause only local battle simulation, preserve audio/UI time, and collapse to a minimal reduced-motion path. `AudioCue` and `MusicProfile` resources keep routing presentation-only; Act I adaptive requests remain bar-quantized without entering deterministic battle state. The persisted music toggle governs every music surface.

The UI interaction suite uses generated moon-glass click, back, confirm, menu-open, and menu-close cues. Production masters, carrier media, runtime checksums, routing, and reproduction instructions live in [`docs/audio/LUNARIS_GAMEPLAY_SCORE.md`](docs/audio/LUNARIS_GAMEPLAY_SCORE.md). Rebuild the runtime derivatives with:

```bash
tools/audio/process_lunaris_score.sh
```

Export the complete bundle with:

```bash
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
tools/stage_mission_cinematic_streams.sh build/web/mission-cinematics
tools/stage_web_content_packs.sh build/web/content-packs
```

The Web base PCK excludes the six Premium Resonance Ogg Theora videos and all
sixteen mission-intro OGV streams, while mission fallback posters stay in core.
The retired historical enemy-variant atlases and eleven advanced operator class
atlas families also remain deferred. Every production non-grunt enemy now ships
as one core-resident 640×640 static sprite and receives deterministic Godot
transform animation; the Grunt alone remains frame-animated. The 176 deferred
advanced operator WebP atlases remain at authored resolution and are staged as
eleven class-scoped PCK resource packs; the host supplies their exact URL, byte
length, and SHA-256 through `--content-pack` arguments. `Art` requests an
advanced class pack only when its first resource is needed, then the verified
cache mounts with `replace_files = false` so downloaded content can add omitted
presentation resources but cannot replace core code or data. Failed or in-flight
packs preserve incumbent operator visuals and can never turn enemies into
fallback squares.

As soon as Title opens, the Premium Resonance service downloads all six cinematic
streams sequentially—current orientation first—and a dedicated mission service
queues configured S1–S16 prologues in campaign order. Both remain nonblocking;
selected missions are promoted and each finalized mapping verifies exact
size and SHA-256, and caches them under `user://`. A pull joins or prioritizes
the shared transfer instead of duplicating it, then plays the verified file
through `VideoStreamTheora`; the final identity plate remains a safe fallback. See
[`docs/CINEMATIC_STREAMING.md`](docs/CINEMATIC_STREAMING.md) for deployment
arguments, the stream manifest, and release checks.

The implemented redesign contract and future-faction boundary live in [`docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md`](docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md).

## Architecture

Authoritative battle state lives under `sim/` and advances deterministically in ticks. Runtime nodes and scenes project that state for the player. Views should not become an independent source of battle truth.

Campaign economy mutations follow the same rule: UI code calls the `Game` facade, V3 command handlers validate revision and source policy, canonical receipts authenticate Marks deltas, and `CampaignSaveStore` publishes state only after exact-byte save/restore verification. Retryable mutations are globally serialized so recruitment, premium pulls, renaming, promotion, mission launch, and resolution cannot race one another.

## Visual direction

All character concepts, portraits, UI illustrations, chibi units, and animated sprite references follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md). The canonical launch-faction trio and their full-figure/chibi production sheets are documented in [`docs/LUNARIS_CHARACTER_DESIGNS.md`](docs/LUNARIS_CHARACTER_DESIGNS.md) and stored together under [`docs/lunaris-reliquary/`](docs/lunaris-reliquary/).

All eleven recruit-derived specializations have regenerated adult male and female idle/attack sets in four isometric directions. The 22 resources resolve after premium portrait overrides and before legacy fallback; approved east facings and deterministic west mirrors use 640×640 source cells with a 560–640 px subject edge while Godot owns their runtime footprint. See [`docs/ADVANCED_OPERATOR_SPRITE_REGENERATION_V2_PLAN.md`](docs/ADVANCED_OPERATOR_SPRITE_REGENERATION_V2_PLAN.md), the historical [`docs/ADVANCED_OPERATOR_SPRITE_IMPLEMENTATION_PLAN.md`](docs/ADVANCED_OPERATOR_SPRITE_IMPLEMENTATION_PLAN.md), and `tools/operator_sprites/` for the complete GPT Image 2 → image-conditioned carrier → validated atlas pipeline and immutable provenance contract.

The PROTOS enemy roster now uses one lore-aligned GPT Image 2 static sprite for every non-grunt archetype. Immutable 1920×1920 concept masters, deterministic 640×640 runtime derivatives, checksums, the shared ivory/gold/black/anima visual language, and procedural locomotion/attack profiles are documented in [`docs/ENEMY_VISUAL_REDESIGN_PROPOSAL.md`](docs/ENEMY_VISUAL_REDESIGN_PROPOSAL.md) and [`docs/ENEMY_STATIC_SPRITE_IMPLEMENTATION_PLAN.md`](docs/ENEMY_STATIC_SPRITE_IMPLEMENTATION_PLAN.md). The Grunt remains the only frame-animated enemy.

The non-premium roster uses a coherent **GPT Image 2** portrait library: eight stable basic Recruit identities and male/female portraits for all eleven advanced classes. High-resolution 1920×1920 sources, deterministic 512×512 RGBA derivatives, prompt provenance, checksums, and the presentation-only identity-to-specialization routing contract are documented in [`docs/NONPREMIUM_PORTRAIT_IMPLEMENTATION_PLAN.md`](docs/NONPREMIUM_PORTRAIT_IMPLEMENTATION_PLAN.md) and [`docs/portraits/nonpremium/`](docs/portraits/nonpremium/). Recruit portraits remain the canonical identity and gender source; after each promotion, Training, Field Team, and Valhalla display the gender-matched portrait for the operator's current specialization without adding gender data to campaign state, command receipts, hashes, or save bytes.

The three premium heroes use dedicated **GPT Image 2** portraits derived from their canonical full-size Lunaris design sheets. Immutable 1920×1920 sources, deterministic 512×512 Field Team/Training assets, 640×800 compatibility derivatives, prompts, checksums, and runtime acceptance are documented in [`docs/PREMIUM_PORTRAIT_IMPLEMENTATION_PLAN.md`](docs/PREMIUM_PORTRAIT_IMPLEMENTATION_PLAN.md) and [`docs/portraits/premium/`](docs/portraits/premium/). The same identity IDs now drive Field Team, Training, Premium Resonance, and Moon Archive presentation without changing premium ownership, rarity, lives, fixed kits, command receipts, hashes, or save bytes. A shared portrait-only entrance adds a 14px vertical and alternating 8px horizontal parallax drift, a short opacity ramp, and a 55ms roster-order stagger; it animates only transform and opacity and resolves immediately under Reduced Motion.

The deterministic premium gacha lifecycle, save migration, fixed-kit rule, stored-life economy, death behavior, and validation contract are documented in [`docs/PREMIUM_HERO_SYSTEM.md`](docs/PREMIUM_HERO_SYSTEM.md).

## Narrative canon

The sole binding world history, anima rules, corrupted-PROTOS doctrine, Company Manus mission, Lunaris character truths, faction motives, two-act campaign, and change-control rules live in [`docs/NARRATIVE_CANON.md`](docs/NARRATIVE_CANON.md). Technical plans describe implementation but do not create independent canon.

## Contributions

Use ordinary Git branches and commit messages. Validate once on the final candidate tree. Revalidate after conflict resolution only when the resolved code changes behavior. Never rewrite `master`; `--force-with-lease` is acceptable on a contributor-owned feature branch.
