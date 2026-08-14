# Protos sound effects

This directory contains the ten Batch 01 sound effects accepted by Poseidon on 2026-08-14. Every Poseidon-accepted stereo 48 kHz signed 24-bit PCM candidate is preserved byte-for-byte under `sources/*.wav.source`; deterministic 16-bit runtime WAV derivatives satisfy Godot 4.7.1's importer and are separately hash-bound in `catalog.tres` and `provenance.json`.

| Logical ID | Lane | Existing raw trigger |
|---|---|---|
| `operator_select` | UI | direct |
| `ability_ready` | UI | direct |
| `action_reject` | UI | direct |
| `ui_click` | UI | direct |
| `placement_ready` | UI | direct |
| `base_breach` | combat | alias from `leak` |
| `victory` | combat | direct |
| `defeat` | combat | direct |
| `deploy` | combat | direct |
| `trap_trigger` | combat | alias from `trap_snap` |

`Sfx` is the sole runtime owner. It emits raw `sfx_played` telemetry on every logical call, resolves the closed alias map only for playback, deduplicates one semantic cue per render frame, and reuses eight bounded voices. Unknown IDs remain telemetry-only and never mutate playback state. Music remains independently owned by `Music`.

The accepted source carrier videos and immutable PCM extraction evidence are retained outside the game tree; the in-repo source manifest, prompts, QA, and acceptance policy bind their hashes. Provider terms must be re-verified before shipping. No SFX volume/mute settings are implemented in TD-032.
