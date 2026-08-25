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

## Web export and optional music packs

The Web preset keeps the title theme in the initial PCK and excludes the six battle tracks. After importing the project, export the base bundle and build the three minimal act packs:

```bash
godot --headless --path . --export-release Web build/web/index.html
godot --headless --path . --script tools/build_music_packs.gd
```

The pack builder writes `build/web/packs/music-act-{1,2,3}.pck` and prints each exact byte count and SHA-256. The Web host must pass one `--music-pack=ACT|URL|SHA256|BYTES` argument per pack. `Music` downloads the requested act on first use, verifies and caches it, mounts it with `ProjectSettings.load_resource_pack()`, and remains silent rather than blocking gameplay if the transfer fails.

## Architecture

Authoritative battle state lives under `sim/` and advances deterministically in ticks. Runtime nodes and scenes project that state for the player. Views should not become an independent source of battle truth.

## Visual direction

All character concepts, portraits, UI illustrations, chibi units, and animated sprite references follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md). The canonical launch-faction trio and their full-figure/chibi production sheets are documented in [`docs/LUNARIS_CHARACTER_DESIGNS.md`](docs/LUNARIS_CHARACTER_DESIGNS.md) and stored together under [`docs/lunaris-reliquary/`](docs/lunaris-reliquary/).

The deterministic premium gacha lifecycle, save migration, fixed-kit rule, stored-life economy, death behavior, and validation contract are documented in [`docs/PREMIUM_HERO_SYSTEM.md`](docs/PREMIUM_HERO_SYSTEM.md).

## Contributions

Use ordinary Git branches and commit messages. Validate once on the final candidate tree. Revalidate after conflict resolution only when the resolved code changes behavior. Never rewrite `master`; `--force-with-lease` is acceptable on a contributor-owned feature branch.
