# Mission Cinematic Native Release

**Status:** Passed

The final native candidate was tested on top of source `74e1757b37fb6d27185fe843541bf901c4a13a28` with the Phase 5 visual harness and teardown hardening applied in the working tree. The exact release commit is recorded in the implementation plan after the Phase 5 push.

## Runtime gates

Godot `4.7.2.stable.official.ed1daf0bf` completed a direct editor import and a bounded 120-frame headless boot with Dummy audio. All **78** standalone Godot tests and smoke scripts passed under isolated per-test user-data directories. The strict localization audit passed with zero structural, fallback, Company Manus, retired-canon, glossary, and hardcoded-copy failures. The mission stream staging regression accepted the complete S1–S16 media set and rejected missing and overlong fixtures.

Log scans found no parse errors, script errors, runtime errors, missing resources, crashes, retained resources, leaked ObjectDB instances, or orphan StringNames. Runtime media and manifests retain exact byte counts and SHA-256 digests for sixteen OGV/OGG pairs, each exactly eight seconds.

## Interaction and state safety

The Stage Select regression activates the actual focused **Skip** button rather than a test-only terminal hook. Locked rows cannot open a film. Unlocked mission selection creates one modal overlay, disables the route behind it, and does not select the stage until the overlay emits its terminal signal. Skip routes the exact stage to Field Team once.

Opening, playing, skipping, completing, failing, or tearing down a film does not change the campaign save revision, strategic hash, core hash, stage unlocks, rewards, squad rules, or Start Battle authority. A visual teardown test exposed and corrected an edge case where freeing Stage Select during an active film could interpret the child's exit signal as a mission selection; `scene_exit` is now treated as cancellation and cannot authorize Field Team.

## Visual acceptance

The Xvfb matrix contains **12** captures across English and Simplified Chinese, 1280×720 landscape and 720×1280 portrait, all at 150% text scale. It verifies live S1 playback through Stage Select, live S16 playback through the player, and real-button S1 Skip routing. Both `Skip` and `跳过` remain contained in the upper-right safe area, focused, and at least 160×64 logical pixels. Cover cropping preserves the premium protagonist and signature device in portrait. Full findings are recorded in [NATIVE_VISUAL_VALIDATION.md](NATIVE_VISUAL_VALIDATION.md).

**Native verdict:** accepted for Web export and managed-stream verification.
