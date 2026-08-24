# Custom Loading Screen

The game now opens with the **Lunaris Reliquary** artwork before handing off to the existing title scene. The same image is configured as Godot’s engine boot splash and as the background of `scenes/loading.tscn`, producing a visually continuous startup instead of the default Godot brand screen.

## Visual contract

At native 1280×720, the boot stage shows the full faction composition without Godot branding. The custom scene then adds a thin gold top rule, faction and archive labels, the **PROTOS** wordmark, staged status copy, percentage, moon-cyan progress bar, and a dark lower information band. The central heroine and both supporting adults remain readable above the UI.

The early Xvfb capture confirms the custom boot artwork fills the window without distortion. The later capture confirms the custom overlay renders cleanly at 62% progress with readable contrast and no collision with faces or hands. An intermediate 100% frame confirms the synchronized state and fade begins cleanly; a separate 4.8-second capture confirms the existing title scene fully replaces the loader with no residual overlay. The first Xvfb run produced only the expected missing-ALSA-device warning and fell back to Godot’s dummy audio driver; the confirmation run used Godot’s dummy audio driver explicitly and reported no errors.

At 720×1280, the engine boot stage preserves the complete 16:9 artwork with dark letterboxing, matching the game preview’s aspect-preservation requirement. Once the custom scene is active, its cover treatment shifts to a dramatic centered portrait crop: the flagship heroine fills the vertical frame, the top faction labels remain inside safe margins, and the complete wordmark, status, percentage, progress bar, and detail line remain readable in the bottom band. No text or focal features clip at the tested portrait size.

## Web preview refresh

The release Web export contains non-empty HTML, JavaScript, WebAssembly, and PCK files. The repository’s documentation archive is protected by `docs/.gdignore`, so the four reusable faction concepts and refined reference image remain in Git without inflating the playable pack. After synchronizing with the latest master VFX changes, the existing fullscreen WebDev host uses the refined Lunaris artwork during the **69,157,760-byte** managed-pack download and then runs the same in-engine boot/loading sequence. Browser validation observed the managed artwork and network progress treatment first, followed by the existing playable title scene with focus intact; no landing page or marketing chrome was added.

The browser console remained empty after startup. Pressing **Enter** on the focused title control advanced into the campaign command/staging flow, confirming keyboard input, scene authority, and the refreshed managed pack remain functional after the loading-screen change.

Final WebDev screenshots confirm the complete custom loading overlay at 1280×720 and the existing title UI centered within the aspect-preserved game frame at 720×1280. Network logs show HTTP 200 responses with the expected `application/wasm` type and exact 39,514,754-byte engine size. The synchronized merged-final browser pass loaded the 69,157,760-byte PCK, displayed the refined managed artwork, completed the in-engine Lunaris sequence, and reached the focused title scene. No failed managed-asset requests were observed.

## Runtime files

| Purpose | Path |
|---|---|
| Production artwork | `res://assets/loading/lunaris_reliquary_loading.png` |
| Boot/loading scene | `res://scenes/loading.tscn` |
| Loading controller | `res://scripts/ui/loading.gd` |
| Engine boot configuration | `res://project.godot` |

The loading scene intentionally remains presentation-only. It prepares the existing title resource, assigns itself to `Game.content`, and exits through `Game.open_title()` so the established scene-swap authority remains unchanged.
