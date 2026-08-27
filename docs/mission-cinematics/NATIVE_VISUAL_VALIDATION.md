# Mission Cinematic Native Visual Validation

**Status:** In progress

The first Xvfb pass uses the real Godot `VideoStreamTheora` runtime with Dummy audio, both supported orientations, and the maximum 150% text scale.

## English S1 and S16 playback

The **S1 landscape gate** passes. Archive Caster, the cyan-and-gold casting device, the rain-darkened machine-city environment, and the threatened civilians remain legible during live playback. The gold-framed **Skip** action is fully contained in the upper-right safe area and receives focus. The localized playback status remains readable without covering the hero's face or the Skip target.

The **S1 portrait gate** passes its cover crop. Archive Caster and her signature device stay centered, while the top-right Skip target and bottom status panel remain fully visible at 150% text scale. The crop deliberately sacrifices peripheral machine and civilian silhouettes rather than the protagonist.

The **S16 landscape player** passes. Archive Caster and the Crown Engine read as the climax, purple anima energy remains visually distinct from Company Manus cyan, and the top-right Skip control stays isolated from the focal action. The exact S16 OGV is visibly playing rather than showing only its fallback poster.

## Chinese portrait and terminal routing

The **S16 Chinese portrait player** passes. The localized `跳过` label stays centered inside the same upper-right action at 150% scale, the Crown Engine remains recognizable, and Archive Caster's full silhouette survives the portrait cover crop. The status `正在播放任务开场影像` remains legible and contained.

The **real Skip path** passes in both orientations and locales. The harness activates the same focused button shown to the player; Stage Select receives one `skip` terminal signal and routes the unchanged stage ID to Field Team. The campaign save revision, strategic hash, and core hash remain unchanged, as enforced by `mission_cinematic_stage_select_test.gd`. The post-Skip frames are routing evidence rather than a new Field Team layout acceptance pass.

## Matrix result

The **Chinese S1 landscape gate** passes with `跳过` and `正在播放任务开场影像` fully contained at 150% scale. The localized controls do not cover the protagonist, device, or rescue target. The portrait post-Skip capture confirms the same button routes to the localized Field Team screen.

The final matrix contains **12 PNG captures**: English and Simplified Chinese; 1280×720 landscape and 720×1280 portrait; S1 Stage Select playback, S16 direct playback, and S1 real-button Skip routing. All capture logs are free of parse, runtime, missing-resource, renderer, resource-retention, and ObjectDB-leak errors.

**Verdict:** accepted for the native release gate.
