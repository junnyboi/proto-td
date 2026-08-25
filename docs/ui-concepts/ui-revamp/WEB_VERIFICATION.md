# Web Export Verification

**Final runtime source:** `07b87523670b194ebd2aab4d6a84af284207a6ec`
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`
**WebDev project:** `proto-td-web` (`SQTJrsLaB53KudBffRrZrS`)
**Final checkpoint:** `085f8e53`

The synchronized release combines the complete unified 21+ anime-gacha UI, exact 15% title/readability follow-up, and soundtrack-redesign Phase 0. Rejected staging/battle tracks, content-pack status, pack tests, pack tooling, and Web pack arguments are intentionally removed. Astra Memoriam remains scoped to loading/title with its persisted ON/OFF preference; staging and battle use silence fallback until approved faction-led adaptive suites are generated.

Godot 4.7.2 direct import, bounded boot, all 19 current focused tests, English/Chinese catalog and placeholder parity, CJK glyph coverage, and error scans pass with zero failures. Twenty accepted UI-revamp Xvfb captures cover campaign and battle families at `1280×720` and `720×1280`; title-specific landscape/portrait and input captures additionally verify the readability follow-up.

The final export contains non-empty `index.html`, `index.js`, `index.wasm`, and `index.pck` artifacts with SHA-256 records. The PCK is 98,181,684 bytes. The WebDev host uses a zero-margin, borderless, dynamic-viewport iframe and maps exact `/manus-storage/index_f499572a.pck`; `GODOT_CONFIG.args` is empty.

Managed-preview verification reached `readyState=complete`, loaded only the final PCK among inspected soundtrack resources, issued no obsolete `music-act-*` request, matched iframe and canvas at `1280×1100` with zero border, and rendered the scaled wordmark/actions without clipping. Pointer plus Enter navigated from title to Company Command; neither screen displayed pack status. The post-navigation console remained clean.

Checkpoint `085f8e53` is fully verified and ready for WebDev Publish-control promotion. The client session exposes checkpoint creation but no direct publish command.
