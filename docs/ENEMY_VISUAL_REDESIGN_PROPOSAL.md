# PROTOS Enemy Visual Redesign Proposal

## Executive summary

The current battle renderer deliberately degrades unresolved enemy textures to solid `ColorRect` faction colors. That defensive behavior prevents crashes, but it also explains the reported squares: every non-grunt is routed through a directional animation identifier, and a missing, excluded, unmounted, or Web-incompatible texture resolves to `null`; `EnemyAnimator` then leaves the colored body visible. The Grunt succeeds because its authored animation remains core-resident. The current native tree can resolve all present sources, but the deployed Web result proves the architecture is too dependent on variant atlases and content-pack timing.

The redesign removes that dependency. **The Grunt remains the only frame-animated enemy.** Every other enemy receives one core-resident, transparent, 1920×1920 GPT Image 2 concept source and one deterministic 640×640 runtime derivative whose subject occupies approximately 600 px on its longest edge. Godot controls footprint, facing, bob, hover, sway, squash, attack anticipation, impact recoil, damage flash, Charm tint, and reduced-motion behavior without mutating deterministic battle state.

## Shared faction language

The Machine Empire has appropriated Lunaris sacred geometry and turned it into harvesting infrastructure. Every redesigned enemy therefore combines **ivory ceramic armor**, **near-black mechanisms**, **brushed-gold broken crescents**, sparse **cyan control lights**, and tightly contained **violet-magenta anima conduits**. A ring is never pristine: it is broken, clamped, bridged, or forced into many-to-one compression. Processed anima is never shown as a free orb or rescued soul.

Silhouette, value, and motion—not color alone—carry gameplay recognition. Every attack cue combines a pose change, ordered geometry, and a brief luminance event. Reduced Motion suppresses rotation, lateral drift, and squash while preserving discrete telegraph states.

## Roster proposal

| Existing ID | Canonical presentation | Primary silhouette | Static procedural motion | Existing attack read |
|---|---|---|---|---|
| `runner` | **Tagger** pursuit machine | Long separated legs, forward broken scanner crescent, rear cell cradle | Fast 1 px bob, restrained roll, squash, travel lean | Scanner bracket closes, ticks fill rear-to-front, short hit squash |
| `drone` | **Hunter Drone** search relay | Compact inverted teardrop, downward eye, crescent crown | Vertical hover wave, subtle roll, path-change bank, shadow depth | Eye contracts to slit, crown tilts, three containment pulses |
| `shieldbearer` | Defensive prisoner-column escort | Huge broken moon-disc, three ribs, offset body and visible feet | Armored bob, low roll, brace, short shield thrust | Shield apertures fill outside-to-center before bash |
| `spellcaster` | **Channeler** anima router | Tall grounded body, offset crescent, forward fork | Foot-locked bob, sway, scale breath, target lean | Bands travel toward a closing diamond focus before release |
| `interceptor` | Armored aerial enforcer | Spearhead inside vertical crescent, rear V, fork muzzle | Hover wave, lateral drift, roll, attack dampening | Three conduit bands converge on a contracting reticle |
| `heavy` | **Farm Warden** prison overseer | Wide low biped, split yoke, barred torso, seal fist | Ponderous load cycle, low-point hold, blocked settle | Torso bars step on, body leans, seal fist flashes on impact |
| `breacher` | Shelter-opening siege caste | Low quadruped wedge, off-axis pile driver, counterweight | Hydraulic bob, counter-sway, restrained ram lunge | Ram clamps sequence, broken ring pulses, blunt impact arc |
| `mini_boss` | **Gatecrasher** portal-assault engine | Compact quadruped under tall shattered arch and centerline key | Slow siege gait, squat, recoil, centerline lunge | Arch closes, slits sequence, core compresses, key flashes |

## Concept designs

The preserved GPT Image 2 sources are stored under `docs/enemy-redesign/source/concepts/`:

| Enemy | Concept source |
|---|---|
| Runner / Tagger | [`runner.png`](enemy-redesign/source/concepts/runner.png) |
| Shieldbearer | [`shieldbearer.png`](enemy-redesign/source/concepts/shieldbearer.png) |
| Breacher | [`breacher.png`](enemy-redesign/source/concepts/breacher.png) |
| Heavy / Farm Warden | [`heavy.png`](enemy-redesign/source/concepts/heavy.png) |
| Drone / Hunter Drone | [`drone.png`](enemy-redesign/source/concepts/drone.png) |
| Interceptor | [`interceptor.png`](enemy-redesign/source/concepts/interceptor.png) |
| Spellcaster / Channeler | [`spellcaster.png`](enemy-redesign/source/concepts/spellcaster.png) |
| Mini Boss / Gatecrasher | [`mini_boss.png`](enemy-redesign/source/concepts/mini_boss.png) |

The 1920×1920 files are immutable concept masters. Runtime derivatives will preserve aspect ratio, remove the temporary chroma field, keep the subject within a 640×640 transparent canvas, and target an approximately 600 px maximum subject dimension.

## Runtime architecture decision

Non-grunt textures must ship in the signed core PCK. They must not depend on `enemy-variants` content-pack configuration, download order, cache state, import remaps, or frame-atlas availability. `EnemyAnimator` will resolve `enemy_static_<id>` for every non-grunt, use aspect-preserving texture layout, and apply deterministic presentation transforms to the sprite child while the authoritative enemy body, path position, collision semantics, stats, target policy, attack counter, and damage timing remain unchanged.

When a static resource is genuinely missing, production will continue to fail safely, but regression tests and release gates will reject any square fallback before export. The renderer will emit one bounded diagnostic for the missing ID rather than silently accepting a release candidate.

## Accessibility and motion policy

All silhouettes must remain identifiable in grayscale and at final in-game footprint. Ground enemies keep a fixed bottom-center anchor; aerial enemies preserve a separated shadow. Charm identity continues to use existing faction semantics and adds cyan modulation only as a supplemental cue. Damage flash remains shader-based. Reduced Motion disables continuous rotation, lateral drift, and squash while retaining a maximum 1 px vertical cue and discrete attack telegraphs.

## Acceptance criteria

A candidate is acceptable only when all nine enemy IDs render a non-null texture in native and Web builds; only the Grunt reports more than one animation frame; all non-grunt sources resolve from core PCK paths; no non-grunt body exposes a visible solid fallback; the roster remains readable at desktop, portrait, and short-landscape viewports; procedural transforms never alter battle snapshots; and browser logs contain no missing-resource, content-pack, texture-import, or shader errors.
