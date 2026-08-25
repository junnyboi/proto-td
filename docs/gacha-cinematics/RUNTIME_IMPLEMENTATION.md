# Premium Resonance Cinematic Runtime Implementation

| Field | Value |
|---|---|
| **Phase** | 4 — Godot runtime integration |
| **Status** | Complete |
| **Engine** | Godot `4.7.2.stable.official.ed1daf0bf` |
| **Presentation duration** | 8.000 seconds |
| **Final identity lock** | 7.440 seconds |

## Implementation

The Premium Resonance screen now commits the authoritative pull exactly once, then opens a full-viewport character cinematic selected from the committed `premium_id` and current orientation. `GachaCinematicPlayer` owns landscape/portrait video selection, cover fitting, poster fallback, and the deterministic final-plate swap. The existing gacha controller retains all rarity, acquisition-kind, lives, pity, guarantee, Skip, focus, and campaign-state authority.

The result card is now a bottom cinematic dock rather than a centered portrait modal. It appears only after the motion phase and presents the existing code-drawn rarity stars, canonical portrait, hero name, `NEW HERO` / `LIFE +1` / `REVIVED`, lives, and updated pity copy. Landscape and portrait use distinct layouts and preserve a reachable upper-right Skip action.

Reduced-motion mode never loads a video stream or starts cinematic audio. It immediately shows the approved final plate and the same receipt-derived result. Skip and scene exit kill the active tween, stop and release the video stream, stop cinematic audio, clear the pending presentation state, restore navigation, and never mutate the already committed pull.

## Runtime assets

The repository contains six 24 fps Theora OGV streams, six compressed approved final plates, and three 48 kHz stereo Vorbis cinematic mixes. The installed runtime media is approximately 62.7 MB. Generated MP4 masters, identity anchors, source keyframes, carrier videos, raw music, and extracted WAV masters remain in shared project media rather than the source repository.

## Regression gate

Direct Godot import and a bounded headless boot completed with clean error scans. All sixteen focused tests passed with their success sentinels, including `GACHA_CINEMATIC_RESOURCES_TEST_OK`, `PREMIUM_GACHA_UI_TEST_OK`, `PREMIUM_GACHA_PITY_ECONOMY_TEST_OK`, and `PREMIUM_HERO_SYSTEM_TEST_OK`.

The cinematic resource test verifies all six streams, all six final plates, and all three audio mixes. The expanded gacha UI test verifies video start, final-plate availability, cinematic audio ownership, immediate Skip, stream/audio cleanup, final receipt copy, and reduced-motion behavior.

## Visual gate

Xvfb checks used dummy audio at 1280×720 and 720×1280. Captures covered Vessel and Duelist motion, Archive Caster motion/final settle, five-star and four-star results, reduced motion, both orientations, final-plate swaps, and Skip cleanup. Full-viewport media coverage, character-safe framing, rarity hierarchy, final copy, and button reachability passed. The first result-dock pass placed pity copy too close to the ornamental lower edge; increasing dock height and adding protected copy padding corrected the issue in both orientations.
