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

The current runtime intentionally ships only the approved Lunaris loading/title theme, **Astra Memoriam**. Staging, campaign, and battle surfaces remain silent while their faction-led soundtrack is redesigned. Export the complete title-only bundle with:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

Do not add temporary replacement tracks. The approved redesign contract and phased implementation plan live in [`docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md`](docs/FACTION_MUSIC_REDESIGN_PROPOSAL.md).

## Architecture

Authoritative battle state lives under `sim/` and advances deterministically in ticks. Runtime nodes and scenes project that state for the player. Views should not become an independent source of battle truth.

## Visual direction

All character concepts, portraits, UI illustrations, chibi units, and animated sprite references follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md). The canonical launch-faction trio and their full-figure/chibi production sheets are documented in [`docs/LUNARIS_CHARACTER_DESIGNS.md`](docs/LUNARIS_CHARACTER_DESIGNS.md) and stored together under [`docs/lunaris-reliquary/`](docs/lunaris-reliquary/).

The deterministic premium gacha lifecycle, save migration, fixed-kit rule, stored-life economy, death behavior, and validation contract are documented in [`docs/PREMIUM_HERO_SYSTEM.md`](docs/PREMIUM_HERO_SYSTEM.md).

## Contributions

Use ordinary Git branches and commit messages. Validate once on the final candidate tree. Revalidate after conflict resolution only when the resolved code changes behavior. Never rewrite `master`; `--force-with-lease` is acceptable on a contributor-owned feature branch.
