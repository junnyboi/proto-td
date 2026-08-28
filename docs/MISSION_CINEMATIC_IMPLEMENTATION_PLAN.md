# Mission Intro Cinematics Implementation Plan

**Status:** Native accepted; Web release in progress
**Canonical repository:** `https://github.com/junnyboi/proto-td`  
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`  
**WebDev mapping:** `proto-td` → `proto-td-web`

## Scope and invariants

The implementation adds a presentation gate between an unlocked Mission Control row and the existing Field Team route. It does not alter stage data, enemy waves, campaign unlocks, squad rules, battle tickets, rewards, save schemas, deterministic hashes, or the Start Battle authority. Every mission click, including replays, presents its mission film. The Company Command next-operation shortcut opens Mission Control instead of bypassing the gate. The source video is 16:9; the runtime cover crop is portrait-safe. The Title starts background prefetch immediately, but navigation never waits on media.

## Phase plan

| Phase | Work | Verification | Delivery |
|---|---|---|---|
| 1 — Design contract | Adopt proposal, reference review, and sixteen-stage production manifest. | JSON parse, 16 unique stage IDs, forbidden-copy scan, source-link check. | Commit and push to `master`. |
| 2 — GPT Image 2 anchors | Generate 16 identity-locked 1920×1080 opening plates; preserve originals and WebP runtime fallbacks. | Inspect every plate for hero identity, signature device, adult anatomy, color semantics, text, crop, and Skip reserve. | Commit and push to `master`. |
| 3 — Advanced carriers | Generate 16 maximum-eight-second image-conditioned carriers with native ambience; prefer Veo 3.1 and use the strongest capacity-safe image-conditioned model when Veo is unavailable; extract OGG audio and transcode silent OGV video. | `ffprobe` duration/codec/audio checks, frame-contact sheets, semantic video review, speech scan, file hashes. | Commit and push to `master`. |
| 4 — Runtime | Add mission cinematic registry, dedicated background prefetch service, full-screen player, localized controls/status, Stage Select gate, Reduced Motion fallback, and export exclusions/staging. | Focused parser, locale, stream, Stage Select, save/hash, and prefetch tests. | Commit and push to `master`. |
| 5 — Native final | Import, bounded boot, complete suite, log scans, Xvfb interaction and landscape/portrait visual checks in EN/ZH. | No parse/runtime/resource/test errors; Skip and auto-complete route to Field Team; no strategic mutation. | Commit and push to `master`. |
| 6 — Web release | Export HTML/JS/WASM/PCK, stage sixteen streams, serve over HTTP, verify MIME/length/runtime logs, layer onto newest `proto-td-web`, build, restart, checkpoint, publish when available. | Exact managed mappings, nonblocking Title startup, mission-film network/runtime checks, clean console, fullscreen geometry. | WebDev checkpoint and Publish handoff if no publish tool is exposed. |

## Runtime architecture

`mission_cinematic_catalog.gd` owns the sixteen stable stage-to-media records, byte sizes, digests, poster paths, audio paths, and durations. `MissionCinematicPrefetch` is a dedicated autoload so existing Premium Resonance behavior remains isolated. It parses `--mission-cinematic-stream=<stage>|<url>` arguments, downloads one mission stream at a time, verifies size and SHA-256, caches by digest, and allows a selected stage to jump to the front of the queue.

`mission_cinematic_player.gd` is a modal full-screen Control instantiated by Stage Select. It renders a cover-cropped poster and video, a top-right Aetheria Skip/Continue action, a localized progress panel, and a separate synchronized OGG ambience player. The player emits exactly one terminal signal whether the film finishes, the user skips, Reduced Motion is active, or transport fails. Stage Select disables route input while the overlay owns focus and calls `Game.open_field_team_for_stage(stage_id)` only after that terminal signal.

The Web export omits `assets/cinematics/missions/video/*.ogv`. `tools/stage_mission_cinematic_streams.sh` validates and stages all sixteen streams plus a manifest. The WebDev shell maps the uploaded same-origin streams into Godot user arguments while preserving the newest core, operator packs, existing six Premium Resonance films, loader, cinematics, and host architecture.

## Copy and accessibility

New keys are added together to `en-US.json` and `zh-CN.json` for Skip, Continue, receiving progress, offline fallback, mission-cinematic accessibility name, and playback status. Skip remains at least 160×64 logical pixels, receives initial focus, and stays in the upper-right safe margin at all viewports and 150% text scale. The overlay is modal, announces state changes politely, and restores no stale Stage Select focus because routing immediately proceeds to Field Team.

## Final checklist

- [x] Canon, character sheets, stage flow, existing stream architecture, export, and WebDev host audited.
- [x] Detailed proposal, reference review, and production manifest written.
- [x] Sixteen GPT Image 2 anchors generated and accepted at 2560×1440; runtime 1920×1080 WebP plates and SHA-256 manifests created.
- [x] Sixteen carriers generated and accepted: Veo 3.1 Quality for S1–S2 and Seedance 2.5 1080p high-bitrate omni-reference for S3–S16 after Veo capacity rejection.
- [x] Audio extracted; sixteen runtime OGG and silent OGV pairs verified, speech-scanned, duration-clamped to exact 8.000 seconds, and hashed.
- [x] Runtime player, prefetch, mission gate, localization, export staging, and focused tests implemented.
- [x] Native complete suite passed: Godot 4.7.2 import/boot, 78/78 tests, strict localization and staging gates, and a 12-capture bilingual landscape/portrait matrix at 150% text scale.
- [ ] Web export, HTTP verification, forward-only WebDev integration, restart, and checkpoint completed.
- [ ] Published, or exact verified checkpoint handed to the Publish control when no publish tool exists.

## Phase 4 runtime implementation

Phase 4 adds a typed sixteen-record catalog under `data/presentation/cinematics/`, the independent `MissionCinematicPrefetch` autoload, and a full-screen poster-first `MissionCinematicPlayer`. Title starts configured mission downloads without awaiting them. Mission Control disables route input while the player owns focus and invokes the unchanged Field Team facade exactly once after the player's terminal signal. Reduced Motion, transport failure, user skip, completion, and scene exit all resolve through the same terminal-once edge.

The Web base export excludes `assets/cinematics/missions/video/*.ogv`; fallback posters remain core-resident. `tools/stage_mission_cinematic_streams.sh` requires exactly `s1.ogv` through `s16.ogv`, validates every duration at no more than 8.05 seconds, optionally stages same-name OGG ambience, honors the `core` or `stage` poster policy, and emits JSON plus TSV manifests. The existing Premium Resonance staging script and service are unchanged.

The catalog's OGV/OGG byte sizes and SHA-256 fields are pinned to the accepted `assets/cinematics/missions/media-manifest.json` outputs. Nonzero byte fields and nonempty digests are independently enforced by runtime verification, and no generated MP4 is loaded at runtime.

## Adaptive background transfer extension

The 2026-08 network extension preserves the Phase 4 foreground mission gate while bounding speculative work from Title. The Web host supplies `--network-profile=constrained|slow|standard|fast` from the browser Network Information API. Constrained/save-data and slow profiles queue no mission films, standard queues S1–S2, and fast may queue S1–S6. A selected stage always promotes or starts its required film regardless of that background horizon.

Title Settings now persists a **Background Downloads** preference outside campaign state. The draft is staged until Apply so Cancel cannot discard partial cache progress; applying Off cancels an active speculative mission transfer and clears the speculative queue. Foreground selected-stage requests remain eligible. `MissionCinematicPrefetch` publishes allow-listed stage IDs and byte progress through a Web-only presentation bridge so the zero-chrome loader can show a pointer-transparent current-asset chip without exposing URLs, cache paths, or campaign data.

The extension is covered by mission runtime, Title Settings, localization, responsive-layout, and complete native regression suites. Web export, managed runtime inspection, checkpointing, and publishing remain part of Phase 6.

## Phase delivery record

Phases 1–2 established the proposal and sixteen GPT Image 2 anchors. Phase 3 was pushed in `b64301cbda53a9b01f38d87758565a99e6e7ac2f` after reconciling concurrent advanced-operator work. Phase 4 was pushed in `74e1757b37fb6d27185fe843541bf901c4a13a28` after preserving concurrent balance, enemy-effect, and retreat-cooldown work.

Phase 5 passed a direct import, bounded boot, all 78 standalone native tests, strict localization and stream-staging checks, and the bilingual 12-capture Xvfb matrix. The final interaction regression presses the same focused Skip button exposed to the player and verifies exact one-time routing without campaign, save, or hash mutation. [NATIVE_RELEASE.md](mission-cinematics/NATIVE_RELEASE.md) is the durable gate record.
