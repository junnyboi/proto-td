# Protos

Protos is a tactical tower-defense game built with Godot 4.7.2.

## Run

Open the repository in Godot 4.7.2 or run:

```bash
godot --path .
```

The main scene is `res://scenes/title.tscn`.

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

The runtime preserves the approved loading/title theme, **Astra Memoriam**, and ships the faction-led Lunaris launch score across Company Command, S1–S8 battle states, the Gatecrasher boss, and results. `AudioCue` and `MusicProfile` resources drive presentation-only routing; `MusicDirector` requests bar-quantized low/medium/high transitions without entering deterministic battle state. The persisted music toggle governs every music surface.

The UI interaction suite uses generated moon-glass click, back, confirm, menu-open, and menu-close cues. Production masters, carrier media, runtime checksums, routing, and reproduction instructions live in [`docs/audio/LUNARIS_GAMEPLAY_SCORE.md`](docs/audio/LUNARIS_GAMEPLAY_SCORE.md). Rebuild the runtime derivatives with:

```bash
tools/audio/process_lunaris_score.sh
```

Export the complete bundle with:

```bash
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
```

The Web base PCK excludes the six Premium Resonance Ogg Theora videos. The
selected hero/orientation stream is downloaded on demand, verified by exact
size and SHA-256, cached under `user://`, and played through
`VideoStreamTheora`; the final identity plate remains a safe fallback. See
[`docs/CINEMATIC_STREAMING.md`](docs/CINEMATIC_STREAMING.md) for deployment
arguments, the stream manifest, and release checks.

The implemented redesign contract and future-faction boundary live in [`docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md`](docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md).

## Architecture

Authoritative battle state lives under `sim/` and advances deterministically in ticks. Runtime nodes and scenes project that state for the player. Views should not become an independent source of battle truth.

## Visual direction

All character concepts, portraits, UI illustrations, chibi units, and animated sprite references follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md). The canonical launch-faction trio and their full-figure/chibi production sheets are documented in [`docs/LUNARIS_CHARACTER_DESIGNS.md`](docs/LUNARIS_CHARACTER_DESIGNS.md) and stored together under [`docs/lunaris-reliquary/`](docs/lunaris-reliquary/).

The deterministic premium gacha lifecycle, save migration, fixed-kit rule, stored-life economy, death behavior, and validation contract are documented in [`docs/PREMIUM_HERO_SYSTEM.md`](docs/PREMIUM_HERO_SYSTEM.md).

## Contributions

Use ordinary Git branches and commit messages. Validate once on the final candidate tree. Revalidate after conflict resolution only when the resolved code changes behavior. Never rewrite `master`; `--force-with-lease` is acceptable on a contributor-owned feature branch.
