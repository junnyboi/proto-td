# Web Export Verification

**Final runtime source:** `a6f358e286fd62eadb729ecce93c86fb530ec5e9`
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`
**WebDev project:** `proto-td-web` (`SQTJrsLaB53KudBffRrZrS`)
**Final checkpoint:** `4f4e6ce6`

The synchronized release combines the complete unified 21+ anime-gacha UI, exact 15% title/readability follow-up, capped Company Command deck, soundtrack-redesign Phase 0, and the deterministic S6 Slow Field spell. Rejected staging/battle tracks, content-pack status, pack tests, pack tooling, and Web pack arguments are intentionally removed. Astra Memoriam remains scoped to loading/title with its persisted ON/OFF preference; staging and battle use silence fallback until approved faction-led adaptive suites are generated.

Godot 4.7.2 direct import, bounded boot, all 20 current focused tests, English/Chinese catalog and placeholder parity, CJK glyph coverage, and error scans pass with zero failures. Twenty accepted UI-revamp Xvfb captures cover campaign and battle families at `1280×720` and `720×1280`; title-specific captures verify readability and input. The Slow Field Xvfb harness additionally confirms readable cyan field VFX beneath enemies and health bars with unobstructed command HUD.

The final export contains non-empty `index.html`, `index.js`, `index.wasm`, and `index.pck` artifacts with SHA-256 records. The PCK is 98,202,864 bytes. The WebDev host uses a zero-margin, borderless, dynamic-viewport iframe and maps exact `/manus-storage/index_d545a204.pck`; `GODOT_CONFIG.args` is empty.

Managed-preview verification reached `readyState=complete`, loaded only the final PCK among inspected soundtrack resources, issued no obsolete `music-act-*` request, matched iframe and canvas at `1280×1100` with zero border, rendered the enlarged title without clipping, and showed the Company Command deck capped and vertically centered on a tall viewport. Pointer plus Enter navigated from title to Company Command; neither screen displayed pack status. The post-navigation console remained clean.

Checkpoint `4f4e6ce6` is publicly deployed at `https://protohost-sqtjrsla.manus.space/`. Public verification loaded exact `index_d545a204.pck`, rendered the scaled title and capped Company Command without clipping, accepted pointer plus Enter navigation, and produced a clean post-navigation console.
