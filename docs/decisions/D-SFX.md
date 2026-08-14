# D-SFX — Accepted generated SFX are active

| Field | Decision |
|---|---|
| Original decision | 2026-08-11 deliberate audio silence |
| Music supersession | 2026-08-12 six-cue score and TD-017 runtime music |
| SFX supersession | 2026-08-14 Poseidon accepted all ten Batch 01 candidates and ordered game integration |
| Owner | Poseidon |
| Current status | Active; the SFX silence waiver is closed |

The original decision made the game intentionally silent: no SFX, no music, and therefore no silence defect. Music was reopened and independently integrated on 2026-08-12. On 2026-08-14 Poseidon explicitly accepted all ten exact Batch 01 SFX candidates, including their previously reported subjective warnings, then ordered runtime integration. That human decision is authoritative for sound quality and supersedes the remaining SFX waiver without reviving the discarded synthesized placeholders.

`Sfx` is the sole runtime sound-effect owner. Every logical `play(raw_id)` call still emits exactly one raw `sfx_played` telemetry event, including unknown or same-frame-deduped requests. Playback resolves a closed catalog/alias map, starts at most one instance of a semantic cue per render frame, and reuses exactly eight `AudioStreamPlayer` voices. Unknown IDs remain telemetry-only and cause zero playback-controller state change. `Music` remains the separate one-player music owner.

The active accepted set is `operator_select`, `ability_ready`, `action_reject`, `ui_click`, `placement_ready`, `base_breach`, `victory`, `defeat`, `deploy`, and `trap_trigger`. Existing raw combat events resolve `leak→base_breach` and `trap_snap→trap_trigger`; existing direct `deploy`, `victory`, and `defeat` calls remain unchanged. The deploy adapter owns operator selection, valid placement, and rejection feedback, while `BattleView` owns the unavailable-to-ready ability edge. No audio state enters simulation, hash, save, or replay.

The accepted 48 kHz stereo 24-bit PCM files are preserved byte-for-byte under `assets/sfx/sources/`. Godot 4.7.1 rejected that WAV container, so deterministic 48 kHz stereo 16-bit PCM runtime derivatives are separately hash-bound and imported uncompressed. This is a format adaptation, not a regeneration or subjective edit. Provider terms must still be re-verified before shipping.

Authoritative references are `FEATURES.json` entry `SFX-1`, `assets/sfx/catalog.tres`, `assets/sfx/human-acceptance.json`, `assets/sfx/provenance.json`, `docs/handoffs/TD-037-agent-4-sfx-integration.md`, and the external Batch 01 carrier/extraction evidence. The historical synthetic restoration command remains a rollback reference only and must not be used for production SFX.
