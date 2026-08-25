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

## Web export and soundtrack scope

The runtime preserves the approved loading/title theme, **Astra Memoriam**, and ships the faction-led Lunaris launch score across Company Command, S1–S8 battle states, the Gatecrasher boss, and results. `AudioCue` and `MusicProfile` resources drive presentation-only routing; `MusicDirector` requests bar-quantized low/medium/high transitions without entering deterministic battle state. The persisted music toggle governs every music surface.

The UI interaction suite uses generated moon-glass click, back, confirm, menu-open, and menu-close cues. Production masters, carrier media, runtime checksums, routing, and reproduction instructions live in [`docs/audio/LUNARIS_GAMEPLAY_SCORE.md`](docs/audio/LUNARIS_GAMEPLAY_SCORE.md). Rebuild the runtime derivatives with:

```bash
tools/audio/process_lunaris_score.sh
```

Export the complete bundle with:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

The implemented redesign contract and future-faction boundary live in [`docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md`](docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md).

## Architecture

Authoritative battle state lives under `sim/` and advances deterministically in ticks. Runtime nodes and scenes project that state for the player. Views should not become an independent source of battle truth.

## Visual direction

All character concepts, portraits, UI illustrations, chibi units, and animated sprite references follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md). The canonical launch-faction trio and their full-figure/chibi production sheets are documented in [`docs/LUNARIS_CHARACTER_DESIGNS.md`](docs/LUNARIS_CHARACTER_DESIGNS.md) and stored together under [`docs/lunaris-reliquary/`](docs/lunaris-reliquary/).

The deterministic premium gacha lifecycle, save migration, fixed-kit rule, stored-life economy, death behavior, and validation contract are documented in [`docs/PREMIUM_HERO_SYSTEM.md`](docs/PREMIUM_HERO_SYSTEM.md).

## Contributions

Use ordinary Git branches and commit messages. Validate once on the final candidate tree. Revalidate after conflict resolution only when the resolved code changes behavior. Never rewrite `master`; `--force-with-lease` is acceptable on a contributor-owned feature branch.
