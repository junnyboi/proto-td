# Proto-TD Loading-Screen Concept Brief

## Current visual identity

The runtime target is **1280×720 (16:9)**. The current title screen uses a near-black navy field, a muted blue-slate panel, warm gold as the primary action color, cool cyan as the secondary interactive accent, and a centered title/menu hierarchy. Loading-screen art should therefore preserve a calm central or lower-center safe region for the **Protos** wordmark, progress indicator, status text, or future login controls.

The established character treatment depicts original, visibly adult heroes aged roughly 31–35, primarily East Asian with some European characters. Existing costumes combine sleeveless martial tailoring, high collars, asymmetrical wraps, dark plum/teal/navy textiles, gold piping, leather straps, and restrained weapon silhouettes. Hair design currently favors elegant layered cuts, braids, ponytails, and dark jewel colors.

## Concept-art escalation

The loading-screen concepts should retain the tactical-fantasy DNA while escalating from portrait-sheet restraint to **premium banner-key-art spectacle**. Every character must be clearly adult (21+), exceptionally attractive, glamorous, and non-explicit. “Sexy” should come from confident posture, refined facial beauty, athletic physiques, elegant exposure, couture tailoring, dramatic hair, and charismatic eye contact—not nudity or juvenile-coded styling.

## Composition constraints

Each final concept should be a standalone **16:9 image with no rendered text**. Use 3–5 adult heroes, strong foreground silhouettes, cinematic depth, controlled particle effects, and a deliberately quieter text-safe region. Avoid logos, UI, watermarks, school uniforms, childlike proportions, generic medieval armor, copied franchise characters, mascot clutter, and over-dense full-frame action that leaves no loading UI space.

## World motifs to retain

The live battle view uses floating isometric stone platforms over a dark void, gray-blue masonry, moss-green specks, narrow ochre routes, crystalline cyan deployment markers, and compact tactical silhouettes. The enemy faction is a faceless ivory-ceramic machine civilization with smoked mineral cores, oxidized brass hardware, warm amber or cold moon-blue energy, monumental reliquary geometry, and grounded quadruped or hovering lozenge forms.

Concept backgrounds should therefore imply a **ruined luminous tactical world** rather than a generic fantasy city. Strong options include suspended basalt/stone terraces, tilted isometric causeways, monolithic reliquary machines, ceramic drones, gold-versus-cyan energy, drifting mineral dust, and distant battle-grid geometry. These motifs should stay subordinate to the glamorous adult hero ensemble.

## Current implementation boundary

`project.godot`, `export_presets.cfg`, `scenes/`, and `scripts/` contain no custom boot-splash or loading-screen setting or runtime loading scene. The default Godot splash is therefore expected. This concept lane intentionally stops before implementation; after a concept is selected, a separate lane should decide whether the winner becomes the engine boot splash, a dedicated pre-title loading scene, or both. Production implementation should keep the native **1280×720** framing, provide a deterministic progress/status treatment, and validate desktop plus portrait Web scaling.
