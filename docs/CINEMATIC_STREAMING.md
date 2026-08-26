# Cinematic Streaming

## Purpose

The six Premium Resonance Ogg Theora videos are optional presentation media. The current centered loop set totals **10,477,438 bytes**, so Web still excludes `assets/cinematics/gacha/video/*.ogv` from the initial PCK and transfers only the selected identity and orientation when needed. Posters, cinematic audio, hero data, and gameplay resources remain in the base PCK.

## Runtime behavior

`GachaCinematicPlayer` selects one stream from the revealed hero and current viewport orientation. Native and editor runs load the repository-owned `res://` OGV file. Web deployments provide same-origin URLs through repeated `--cinematic-stream=<key>|<url>` engine arguments.

On a Web cache miss, the player immediately shows the matching identity plate, downloads only the selected orientation, reports transfer progress, verifies the exact byte length and SHA-256 digest, and stores the verified OGV under `user://cinematic-streams`. Playback uses `VideoStreamTheora.file` against that cached path. Result identity and rarity UI remain locked until the first complete eight-second cycle finishes. After that first cycle, a healthy video continues looping beneath the deterministic result UI until dismissal; it does not freeze onto the final plate.

Skip, reduced motion, transfer failure, integrity failure, decode failure, or watchdog fallback stops the motion layer and exposes the matching static identity plate. Authoritative pull state and navigation are unaffected. Reduced-motion mode never requests or plays cinematic video.

## Stream manifest

| Stream key | Bytes | SHA-256 |
|---|---:|---|
| `archive-caster-landscape` | 778,793 | `bcb3251e11269027b49a332487964db64fb8e6fe83358c2bb1b78317558c55af` |
| `archive-caster-portrait` | 2,452,205 | `dd09537610bb5bc0ed7fd2ed6715e4d6b870dce521075b1defe77c6bc6ee0c0f` |
| `lunaris-vessel-landscape` | 1,257,821 | `38361f28ba7c40e8e95c5aa59919028b0d181d97bd6b7f58f01fd7a31deb59cd` |
| `lunaris-vessel-portrait` | 2,502,584 | `cd806d989623cbce1180df154efe892aaf8c2b047cee07906ec330f55c6fb6bb` |
| `reliquary-duelist-landscape` | 1,395,676 | `cfa5bdab1002b428347e4d2d46cd0517acfc876a3460693d7330c8abb0e90151` |
| `reliquary-duelist-portrait` | 2,090,359 | `ed78d0f92c19dc253a47454e13bb411fed64514f768c3db2157e5deb15b9026c` |

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

`tests/cinematic_streaming_test.gd` covers argument validation, reduced-motion behavior, native fallback, first-cycle completion signalling, continued loop playback, cold HTTP download, integrity verification, persistent cache, `VideoStreamTheora` playback, and cleanup. Release QA additionally inventories the PCK to prove all six OGV entries are absent, serves the exported base over HTTP, exercises a real managed stream in the browser, and confirms that only the selected orientation is requested.
