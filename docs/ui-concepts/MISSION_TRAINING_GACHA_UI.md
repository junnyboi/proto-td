# Mission and Training UI Concept — Astral Operations

## Design intent

**Astral Operations** translates the Lunaris Reliquary faction art into a sophisticated adult gacha command interface. The screens should feel like a luxury tactical console suspended over moonlit machinery: attractive operator portraits are the emotional focus, while mission facts, progression, and actions stay immediately readable. The interface avoids the current centered retro dialog, uniform rounded cards, tiny type, and large unused margins.

The palette uses near-black lunar ink (`#07111C`), translucent navy glass (`#0B1827E8`), ivory (`#F5EFE1`), moon-cyan (`#91EAF1`), restrained reliquary gold (`#D9B96E`), and muted violet (`#66577F`). Surfaces use thin gold/cyan rules, angular corner cuts, subtle constellation geometry, soft black depth, and no glow-heavy cyberpunk treatment. Corners remain tight—zero to six pixels—so the result feels editorial and engineered rather than toy-like.

Typography follows a clear three-level hierarchy: large ivory screen titles, gold uppercase operational labels, and high-contrast ivory/cyan detail text. Buttons use full-width label treatments with short verbs and strong selected states. All depicted characters are visibly adult (21+), original, glamorous, powerful, and non-explicit.

## Responsive structure

Landscape screens occupy nearly the full safe viewport instead of a fixed centered plate. A narrow operational header sits above a flexible body and a compact bottom action dock. Mission uses a two-column briefing/roster layout at wide sizes and a one-column stacked layout in portrait. Training uses roster, selected-operator dossier, and progression inspector columns at wide sizes; portrait changes to a horizontally scrollable roster followed by dossier and action sections. Content determines height, scroll appears only where needed, and action buttons never fall below the visible safe area.

## Mission screen

The screen opens with `MISSION 01 / OLD CUT` and the large title `THE CHOKE`, followed by compact objective, threat, human consequence, and field-note chips rather than long centered paragraphs. The main visual area is a roster deck with large operator portraits, callsign, role, DP, readiness, and an obvious selected state. A right-side tactical panel shows `SQUAD 3 / 4`, selected operator summaries, and `SPIKE PLATE / READY`. The bottom dock contains `BACK`, `TRAIN OPERATORS`, and the primary `DEPLOY SQUAD` action. Training must feel like a useful pre-deployment step, not a hidden staging option.

## Training screen

The screen opens with `RELIQUARY ATELIER` and `OPERATOR ADVANCEMENT`, a compact `2 PROMOTION READY` metric, and—only when entered from Mission—a top-right `↗ RETURN TO MISSION` control. A left recruit rail shows portrait, callsign, class, XP, and eligibility. The selected operator gets a larger dossier panel with portrait, class seal, readiness, and continuity messaging. The right progression inspector shows XP, promotion readiness, class-path preview, and permanent-choice warning. The live implementation uses `RETURN` and contextual `CHOOSE PROMOTION`; selecting a specialization card promotes that operator immediately, without staging or reviewing a bulk plan.

## GPT Image 2 prompt — Mission

Create a high-fidelity 16:9 visual mockup for the **Mission squad-selection screen** of an original premium adult anime gacha tactical game called **PROTOS**. The interface is inspired by the approved Lunaris Reliquary faction identity: moon-powered sacred machinery, elegant ivory/black/gold/violet costumes, cyan constellation geometry, near-black lunar glass panels, and expensive editorial game UI. Show only visibly adult 21+ attractive operators; non-explicit.

Composition: full-screen responsive game UI, no browser frame, almost no outer dead space. Asymmetric landscape layout. Top operational header with exact text `MISSION 01 / OLD CUT`, large title `THE CHOKE`, and compact information labels `OBJECTIVE`, `THREAT`, `WHY IT MATTERS`, `FIELD NOTE`. Left/main area contains three large character-forward operator cards using original adult anime heroes: a glamorous auburn female gunner, a handsome blue-haired European swordsman, and an elegant dark-haired East Asian female recruit. Each card visibly includes callsign, role, DP cost, and selection state. Right tactical dossier shows `SQUAD 3 / 4`, compact selected roster, `LOADOUT`, and `SPIKE PLATE / READY`. Bottom action dock contains exact labels `BACK`, `TRAIN OPERATORS`, and primary `DEPLOY SQUAD`.

Style: sophisticated 2026 gacha interface, high readability, tight angular panel cuts, restrained 6px corners, thin reliquary-gold rules, cyan selected accents, ivory text, dark translucent materials over a subtle moon-machine environment. Strong typographic hierarchy and dense but breathable information. Avoid retro terminal styling, giant centered bordered dialog, flat grey boxes, neon cyberpunk glow, excessive rounded cards, tiny text, wasted empty space, mobile phone frame, logos from existing games, and unreadable labels.

## GPT Image 2 prompt — Training

Create a high-fidelity 16:9 visual mockup for the **Recruit Training / Operator Advancement screen** of an original premium adult anime gacha tactical game called **PROTOS**. The interface belongs to the **Lunaris Reliquary**, custodians of memory, gravity, and ritual geometry. Show only visibly adult 21+ attractive operators; non-explicit.

Composition: full-screen responsive game UI with no browser frame and minimal outer dead space. Top header exact text `RELIQUARY ATELIER`, large title `OPERATOR ADVANCEMENT`, metric `2 PROMOTION READY`, and a refined top-right arrow control labeled `RETURN TO MISSION`. Three-column landscape layout: left recruit rail with three compact portrait rows, callsign, class, XP and ready state; center selected-operator dossier featuring a glamorous adult auburn-haired female recruit in elegant tactical fashion with a larger portrait, name `DARA LARK`, class `RECRUIT`, and exact copy `SAME PERSON. NEW DUTY.`; right progression inspector with `FIELD RECORD`, `XP 100 / 100`, `PROMOTION READY`, two class-path preview seals, and a restrained permanent-choice warning. The current dock exposes `RETURN` on the roster and `BACK` on the specialization screen.

Style: luxury anime-gacha command console, moon-cyan and reliquary-gold accents, ivory typography, near-black glass, subtle violet depth, constellation arcs and mechanical halo diagrams behind the dossier, angular editorial composition, large readable text, clear selected state, compact data density. Avoid retro desktop dialog styling, generic admin dashboard cards, wide empty margins, uniform grey rounded rectangles, garish neon, tiny text, illegible fantasy glyphs, juvenile characters, and logos from existing games.

## Native visual validation log

The first 1280×720 Mission capture exposed a fatal header-wrap defect: `RELIQUARY THREAT` collapsed to one character per line and expanded the header until the body moved below the viewport, recreating the very dead-space problem the redesign intends to remove. The correction must reserve a fixed metric width and disable wrapping for short operational labels while retaining wrapping only for descriptive mission copy.

The first 1280×720 Training capture proved the new roster/dossier split and contextual top-right return action are structurally sound, but the base Aetheria button text remained visible beneath custom roster content and over the return presentation label. The correction must make custom-content controls presentation-only, reserve the top-right action width, and reduce the selected dossier portrait so all action controls stay visible without excessive scrolling.

The corrected desktop pass removes both label defects and establishes the intended premium hierarchy: Mission now presents operator portraits beside readable intelligence; Training presents a clean recruit rail, selected dossier, and prominent contextual return action. One remaining acceptance issue is shared by both screens: large child minimum sizes still push the bottom action dock below the first 720px viewport. The final structure must keep the header and action dock visible while confining long rosters and dossiers to internal scroll regions.

Internal scrolling resolves the Training screen: its roster, selected dossier, contextual return arrow, and complete three-action dock are simultaneously visible at 1280×720. Mission now also exposes its dock, but the last visual pass shows the lower edge and long labels clipped by roughly one line. Reducing the Mission body by thirty pixels and using a slightly smaller dock label size is required before desktop acceptance.

The final 1280×720 Mission capture passes: the header, three character-forward cards, intelligence column, internal scroll affordances, pre-deployment guidance, `BACK`, `TRAIN OPERATORS`, and `DEPLOY SQUAD` are all visible together with no outer dead zone. The final Training desktop composition also passes with its recruit rail, selected dossier, internal dossier scrolling, complete action dock, and contextual top-right Mission return control visible together.

The first final portrait pass confirms Training correctly stacks its roster and selected dossier while keeping the contextual return control prominent, but a 520px roster minimum leaves only the first bottom action visible. Mission still uses its 660px landscape preferred height in portrait, creating large top and bottom dead zones. Portrait acceptance therefore requires a 680×1180 Mission shell and a 300px Training roster region so all stacked actions fit without sacrificing scrollable content.

The corrected Training portrait passes with the return control, roster, dossier, and all three actions visible together. Mission now uses the full portrait safe area and exposes its intelligence plus pre-deployment dock, but `DEPLOY SQUAD` remains partially below the first view. The final adjustment is limited to smaller portrait-only internal roster/intelligence windows; their content remains reachable through local scrolling while all three strategic actions stay visible.

The final portrait Mission capture passes: it uses the full 720×1280 safe area, keeps roster and intelligence content locally scrollable, and shows `BACK`, `TRAIN OPERATORS`, and `DEPLOY SQUAD` together. Training likewise passes with its contextual Mission return control, recruit rail, selected dossier, and all three actions in the first responsive view. Desktop and portrait visual gates are complete.

## GPT Image 2 concept review

Both 1920×1080 generated concepts pass the lightweight visual gate. The Mission concept establishes large adult operator art, an asymmetric three-card deployment deck, compact intelligence at the top, a right-side squad/loadout inspector, and a decisive full-width deployment dock. The implementation adopts its character-first card scale, dark editorial material, cyan selection, gold operational labels, and explicit `TRAIN OPERATORS` pre-deployment route while using live game portraits and canonical data.

The Training concept establishes the strongest target for future polish: an adult selected operator occupies the visual center, the recruit rail remains compact, promotion data stays visible on the right, and the Mission return control is visually separate at top-right. The implementation adopts the same roster/dossier/inspector hierarchy within available live portrait assets and responsive Godot controls rather than embedding the generated mockup as a static screen.

## Web validation

The redesigned 74,811,804-byte managed PCK returns successfully through `?from_webdev=1`, the Lunaris browser loader completes, and the animated Godot title renders before campaign entry. No startup failure is visible; Mission and Training interaction plus scoped console/network checks follow on this same refreshed pack.

Keyboard interaction on the refreshed pack enters Company Command and opens the campaign stage selector with `First Stand` focused. The next step uses direct canvas interaction to avoid confusing repeated-key automation warnings while exercising the redesigned Mission screen and its new Training shortcut.

Activating `First Stand` renders the redesigned Mission screen correctly in Web: the dense operator deck, live mission intelligence, local scroll regions, and three-action dock all match the accepted native composition. A first generic canvas click selected the third operator rather than the Training action, proving selection remains interactive; exact canvas-coordinate event dispatch is used next for the contextual route.

Exact canvas-coordinate dispatch activates `TRAIN OPERATORS` and renders the redesigned Training screen with the live recruit rail, selected dossier, complete action dock, and contextual top-right return control. The diagonal Unicode arrow is absent from the bundled font and appears as a replacement glyph in Web, so the final control uses the equivalent ASCII `<-` arrow to guarantee readable intent across native and browser runtimes.

The final 74,811,820-byte arrow-corrected managed PCK returns successfully, completes the Lunaris browser and Godot loading sequence, and reaches the animated title. Final route and console checks now target this exact managed asset.

On the final managed PCK, keyboard input again enters Company Command and opens the campaign selector with `First Stand` focused. This confirms the synchronized pack preserves the title and campaign-navigation path before the redesigned screen pair is rechecked.

The final pack renders the accepted Mission composition and exact canvas activation of `TRAIN OPERATORS` succeeds. The next view verifies the arrow-corrected Training render and exercises its contextual return on this same build.

The final Training render passes with a readable `<- RETURN TO MISSION` control, complete recruit/dossier layout, and visible three-action dock. Exact canvas activation of the top-right control is accepted; the following view confirms return to Mission and the final console/network audit closes the Web gate.

The first automated return pointer landed above the top-right control because the browser canvas is CSS-offset inside the preview. A corrected dispatch uses the measured 1280×720 canvas rectangle and the button’s 19% vertical position; the next view verifies the actual return result rather than treating pointer dispatch alone as acceptance.

The corrected top-right activation returns to the same Mission screen with stage state intact. The browser console contains only the intentional coordinate-dispatch echoes and no Godot script, compile, null-child, navigation, or runtime error. The final Web route gate passes.
