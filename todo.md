# Unified 21+ Anime-Gacha UI Revamp

- [x] Synchronize clean `master` with `origin/master` and verify Godot 4.7.2 compatibility.
- [x] Audit all 79 non-title UI and dialog states across staging, campaign, roster/training, gacha, Vahalla, battle, and results.
- [x] Generate eight desktop/portrait concept designs with GPT Image 2 using canonical adult Lunaris references.
- [x] Document the unified visual system, preserved-feature ledger, responsive contract, and phased implementation plan.
- [x] Phase 0: commit and push the audit, concepts, contract freeze, and accepted pre-change regression baseline.
- [x] Phase 1: implement shared Lunaris materials, typography, full-safe-area shell behavior, modal focus/veil helpers, and tests.
- [x] Phase 2: revamp Stage Select, Training/roster surfaces, Premium Resonance, Vahalla, and Results while preserving all authority boundaries.
- [x] Phase 3: revamp battle HUD, pause/resign, deployment/spell/tutorial/navigation presentation, and result ceremony without changing battle semantics.
- [ ] Phase 4: run full import/boot/focused regressions, English/Chinese parity checks, landscape/portrait visual verification, and error scans.
- [ ] Export the Godot 4.7.2 Web bundle and require HTML, JavaScript, WASM, and PCK artifacts with checksums.
- [ ] Serve and test the bundle over HTTP; verify browser console, network, canvas, input, and responsive behavior.
- [ ] Update the existing `proto-td-web` fullscreen host, run type/build checks, checkpoint, publish, and record completion in the implementation plan.
