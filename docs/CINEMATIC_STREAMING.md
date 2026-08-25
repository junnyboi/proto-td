# Cinematic Streaming

## Purpose

The six Premium Resonance Ogg Theora videos are optional presentation media. Bundling them in the initial Web PCK added 61,520,154 bytes to every cold start, including sessions that never enter the Reliquary. The Web export now excludes only `assets/cinematics/gacha/video/*.ogv`; posters, cinematic audio, hero data, and all gameplay resources remain in the base PCK.

## Runtime behavior

`GachaCinematicPlayer` selects one stream from the revealed hero and current viewport orientation. Native and editor runs continue to load the repository-owned `res://` OGV file. Web deployments provide same-origin URLs through repeated `--cinematic-stream=<key>|<url>` engine arguments.

On a Web cache miss, the player immediately shows the final identity plate, downloads only the selected orientation, reports restrained transfer progress, verifies the exact byte length and SHA-256 digest, and stores the verified OGV under `user://cinematic-streams`. Playback uses `VideoStreamTheora.file` against that cached path. A later reveal reuses the cache without another request. If the request, persistence, or verification step fails, the reveal safely remains on the final plate; authoritative pull state and navigation are unaffected.

A cinematic that finishes downloading after the reveal reaches its final plate is cached but is not allowed to restart presentation underneath the result card. Reduced-motion mode never requests or plays cinematic video.

## Stream manifest

| Stream key | Bytes | SHA-256 |
|---|---:|---|
| `archive-caster-landscape` | 18,894,020 | `5eeeba0bd6a7fce74c80e07d5c23cb0e54007a9287a2878c8a6bf2042efa8cd0` |
| `archive-caster-portrait` | 9,298,910 | `5ac6f14efa7fc96782ad2978ac2f2d2103f5957416006333faabc0af27e0a5ec` |
| `lunaris-vessel-landscape` | 8,846,078 | `fb09e9d067bd1458bbc3d6a0b575281d248df8ea75b6c33e0bf2111209a8fb97` |
| `lunaris-vessel-portrait` | 8,498,953 | `87221b5164f157267963acf1bb7504b6220f66bd1fdb6e6c588d94a845c39c32` |
| `reliquary-duelist-landscape` | 7,485,451 | `186a0f063b900877513261e0ab2b7aefb0609de9d422f69ea65cd5e8d76a1e55` |
| `reliquary-duelist-portrait` | 8,496,742 | `09430cb2de8bdeb7c1d6c8db60a838a572f1c518aa2e474c04dbc4ffaea1a2f5` |

## Release procedure

Export the base and stage independently uploadable streams:

```bash
godot --headless --path . --export-release Web build/web/index.html
tools/stage_cinematic_streams.sh build/web/cinematics
```

Upload the six staged OGV files to the same WebDev project as the base PCK. Add one engine argument per object:

```text
--cinematic-stream=<stream-key>|/manus-storage/<uploaded-object>.ogv
```

The URL may be absolute HTTP(S) or a same-origin path resolved by the browser. The byte length and SHA-256 remain authoritative in source; a deployment mapping cannot silently substitute different media.

## Verification

`tests/cinematic_streaming_test.gd` covers argument validation, reduced-motion behavior, native fallback, cold HTTP download, integrity verification, persistent cache, `VideoStreamTheora` playback, and cleanup. Release QA additionally inventories the PCK to prove all six OGV entries are absent, serves the exported base over HTTP, exercises a real managed stream in the browser, and confirms that only the selected orientation is requested.
