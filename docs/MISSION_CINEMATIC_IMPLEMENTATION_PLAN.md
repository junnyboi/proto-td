# Mission Intro Cinematics Implementation Plan

**Status:** In progress  
**Canonical repository:** `https://github.com/junnyboi/proto-td`  
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`  
**WebDev mapping:** `proto-td` → `proto-td-web`

## Scope and invariants

The implementation adds a presentation gate between an unlocked Mission Control row and the existing Field Team route. It does not alter stage data, enemy waves, campaign unlocks, squad rules, battle tickets, rewards, save schemas, deterministic hashes, or the Start Battle authority. Every mission click, including replays, presents its mission film. The source video is 16:9; the runtime cover crop is portrait-safe. The Title starts background prefetch immediately, but navigation never waits on media.

## Phase plan

| Phase | Work | Verification | Delivery |
|---|---|---|---|
| 1 — Design contract | Adopt proposal, reference review, and sixteen-stage production manifest. | JSON parse, 16 unique stage IDs, forbidden-copy scan, source-link check. | Commit and push to `master`. |
| 2 — GPT Image 2 anchors | Generate 16 identity-locked 1920×1080 opening plates; preserve originals and WebP runtime fallbacks. | Inspect every plate for hero identity, signature device, adult anatomy, color semantics, text, crop, and Skip reserve. | Commit and push to `master`. |
| 3 — Veo 3.1 carriers | Generate 16 maximum-eight-second image-conditioned carriers with native ambience; extract OGG audio and transcode silent OGV video. | `ffprobe` duration/codec/audio checks, frame-contact sheets, semantic video review, file hashes. | Commit and push to `master`. |
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
- [ ] Sixteen Veo 3.1 carriers generated and accepted.
- [ ] Audio extracted; runtime OGG and silent OGV assets verified and hashed.
- [ ] Runtime player, prefetch, mission gate, localization, export staging, and tests implemented.
- [ ] Native complete suite and bilingual visual matrix passed.
- [ ] Web export, HTTP verification, forward-only WebDev integration, restart, and checkpoint completed.
- [ ] Published, or exact verified checkpoint handed to the Publish control when no publish tool exists.
