# Cinematic Streaming

## Purpose

The six Premium Resonance Ogg Theora videos are optional presentation media. The current full-HD landscape/portrait set totals **155,764,928 bytes**, so Web still excludes `assets/cinematics/gacha/video/*.ogv` from the initial PCK. Posters, cinematic audio, hero data, and gameplay resources remain in the base PCK.

## Runtime behavior

`CinematicPrefetch` starts as soon as the Title scene enters. It parses the six same-origin URLs from repeated `--cinematic-stream=<key>|<url>` engine arguments and uses the shared browser-derived `--network-profile` policy. Constrained/save-data and slow links queue no speculative films, standard links queue the current-orientation lead film, and fast links may queue all six. Transfers remain sequential and preserve current-orientation priority. Every file is verified by exact byte length and SHA-256 before promotion into `user://cinematic-streams`; valid cached files are skipped on later title entries.

`GachaCinematicPlayer` selects one stream from the revealed hero and current viewport orientation. Native and editor runs load the repository-owned `res://` OGV file. On Web, a pull uses a verified cached stream immediately. If its stream is still queued, the player promotes that item to the front; if the same stream is already downloading, it converts that transfer to foreground ownership, joins it, and displays its progress rather than issuing a duplicate request. Foreground pulls bypass adaptive speculative limits and the Background Downloads preference.

On a Web cache miss, the player immediately shows the matching identity plate while the shared prefetch service reports transfer progress. Playback uses `VideoStreamTheora.file` against the verified cached path. Result identity and rarity UI remain locked until the first complete eight-second cycle finishes. After that first cycle, a healthy video continues looping beneath the deterministic result UI until dismissal; it does not freeze onto the final plate.

Skip, reduced motion, transfer failure, integrity failure, decode failure, or watchdog fallback stops the motion layer and exposes the matching static identity plate. Authoritative pull state and navigation are unaffected. Reduced-motion mode never plays cinematic video. The separate Settings **Background Downloads** preference can cancel and clear speculative Resonance, mission-prologue, and operator-pack queues for metered connections; required selected media still downloads on demand.

## Stream manifest

| Stream key | Bytes | SHA-256 |
|---|---:|---|
| `archive-caster-landscape` | 39,223,400 | `94331bef149513a790fcfc2c8fc0440cbb413504d9185311672ef9c53a86653f` |
| `archive-caster-portrait` | 19,959,147 | `2289a2737bb354949fa19cbfae9c0f4cdfd997ec08eff3024a65007e0b6fbf4` |
| `lunaris-vessel-landscape` | 16,638,104 | `906011683d0abb8446db648b74ec13b79aea3e9c6234e8cae8fd2a4b1ae1db99` |
| `lunaris-vessel-portrait` | 23,555,321 | `32c6cab0847a8f9c1e5dbcde199ee57dbb301fba86135e505b482d7dade189f2` |
| `reliquary-duelist-landscape` | 29,259,884 | `b843467f29774c8679751ab274b2aa0a7d7a75293a0a1f7c4eade6fcc57c97fc` |
| `reliquary-duelist-portrait` | 27,129,072 | `2d2041a1be6c50b7e003ada11fa9da4a1f97114aa12d4f3d389abf54d80384cc` |

## Release procedure

Export the base and stage independently uploadable streams:

```bash
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
```

Upload the six staged OGV files to the same WebDev project as the base PCK. Add one engine argument per object:

```text
--cinematic-stream=<stream-key>|https://<deployment-origin>/manus-storage/<uploaded-object>.ogv
```

The runtime accepts absolute HTTP(S) URLs. A browser shell constructs them from `window.location.origin` plus the uploaded same-origin managed path so preview and published domains share one mapping. The source byte length and SHA-256 remain authoritative; a deployment mapping cannot silently substitute different media.

## Verification

`tests/cinematic_streaming_test.gd` covers argument validation, six-stream configuration, adaptive queue limits, metered cancellation, orientation-prioritized ordering, reduced-motion behavior, native fallback, first-cycle completion signalling, continued loop playback, shared cold HTTP download ownership, duplicate-request exclusion, integrity verification, persistent cache, `VideoStreamTheora` playback, and cleanup. `tests/title_settings_test.gd` covers preview, Cancel, Apply, persistence, and service policy propagation. Release QA additionally inventories the PCK to prove all six OGV entries are absent, serves the exported base over HTTP, opens Title against the managed stream manifest, and confirms the configured profile starts only its bounded background set while the title remains interactive.
