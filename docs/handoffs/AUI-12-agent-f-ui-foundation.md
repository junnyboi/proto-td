# AUI-12 — Agent F UI Foundation Handoff

**State:** audited implementation complete; fresh RELEASE and human approval pending
**Owner:** AGENT F
**Branch:** `agent-f/aui-12-web-remediation`
**Successor base:** `9b834f54a218e3eeb77e89e014476300180dc33a` on current `master`
**Implementation commits:** `40bec07056508cbd8f9a12b8539516fb61631228`, `5441e27e47c6237541cb0a06dd3aeaaa02c3ddf9`
**Effective lane:** MGS v2 RELEASE

## Delivered contract

AUI-12 adds a script-backed Protos Theme and material Resource, reusable Button/Panel/Label/ScreenShell/locale-selector components, stable-key UiCopy, an atomic duplicate-safe en-US catalog, and compatible presentation shells for Title, Staging, Campaign, Squad, and Results. Existing route names and gameplay behavior remain intact. Locale is presentation-only and excluded from simulation, state hash, save/load, replay, telemetry, and gameplay payloads.

Normal body/button text is pinned at logical 44 after exact Theme-variation rendering measured 41 foreground rows; the protected minimum is 32. Every enabled target remains at least 44×44. The Theme owns twenty-three exact variations, the catalog owns seventy-two exact keys and named placeholder types, and all player-visible shells use English fallback at callsites.

The locale selector retains one logical ItemList row with `English (US)`, StringName metadata `en-US`, selected index 0, and ItemList focus identity. Its wrapped semantic overlay is mouse-ignored, clipped and enclosed by the ItemList, uses dark ink over selected cyan, and is verified at WCAG contrast >=4.5 in standard, true-200%-text, and +35%-expansion modes.

## Normative identities

| Artifact | SHA-256 |
|---|---|
| Final implementation plan | `55e7daf91097e476719242203a6d3943e5db4e7a979f129cda0e08f6f3ba608b` |
| Component contract | `70efb6f83b1c59d45d7a5a6cfb7e4cea4dd5058827b2f908fa290e7beaecab90` |
| Copy contract | `0061b4e08b7c27bd3ed38ceb88897da2d3032369cfbfbaf92ef543f8ffb70c83` |
| Scenario contract v2 | `692f7f492cb94ed28d8f8c8a44b738846ef9037d6c923841b72388d099505a01` |
| UI inventory | `177ee1e6c5e1e49357bb54263f0659c3bc50f213f4d544bfc1f6ef9f5fa50a2f` |
| Final independent plan preflight | `PASS`, zero findings >=80 confidence |
| D-WEB-1 approval manifest | `0c7530b9bfa54bf8581d42596393cedfe3e06b410230c5c8565fe0a97520c200` |
| External Poseidon owner decision | `d616bc95eee2aeb3c226f167c2b45c71152d6856285b169af99eeabe7c1e3f17` |
| Web differential oracle | `13f854775c671e7c508192e39d9adb55b3509a79a0d697a0b99fef41b5560b26` |
| Independent implementation audit 04 | `PASS`, zero findings >=80 confidence |

## Verification contract

Focused GUT proves exact Theme tokens/items/StyleBoxes, material roles, component structure and failure semantics, duplicate-safe canonical localization, named placeholder types, focus permutations, and inventory expansion. `ui_shell_floor` produces the exact 62-shot matrix over five screens, four viewports, and three modes plus two typography probes. It records exact source/runtime inventory parity, Theme owner replacement/restoration, all sixteen font-bearing variations, per-screen reflows, target and text geometry, rendered glyph height, logical locale identity, semantic overlay geometry, and contrast. A headless run passes 65 checks; a windowed run passes 142 checks with 62 fresh PNGs and zero skips.

Protected `boot`, `staging_flow`, `campaign_flow`, `resize_relayout`, battle-control, resign-modal, and localization journeys must remain unchanged. Final acceptance additionally requires a clean frozen candidate, cache-bypassed full RELEASE union, Web export/browser evidence, cross-process replay equality, independent non-implementer diff-vs-pins audit, and Poseidon’s commit-bound L7 review.

## D-WEB-1 successor

The original candidate `28b0391ab78b326772c11d040ad75f333183233b` remains immutable red history because AUI-12's approved dark Protos backdrop is mathematically incompatible with the inherited AUI-00 corner-luma visibility band. The successor does not weaken that legacy check: default invocation, signal equation, report fields, and pass/fail semantics remain unchanged.

Explicit manifest-bound contract mode adds a zero-tolerance native/Web categorical differential. A fresh challenge-bound windowed `ui_shell_floor` run supplies the native title reference; both images map every pixel to the nearest of eight approved palette tokens, reduce by deterministic 2×2 majority with lowest-index tie-breaking, and require exact equality across all 230400 reduced labels. Production generation writes a canonical challenge transcript. Independent `--verify-output` recomputes every binding from files, receipts, transcript, Git identity, exact scenario output set, report, and screenshots before it can emit `PASS_CONTENT_EQUIVALENT`.

The focused portable suite freezes thirty-eight ordered tests, one hundred five pairwise-disjoint negative fixtures with runtime-observed outcomes exactly equal to the approved oracle, one content-equivalence positive fixture, all singleton and complete-minus-one argument families, and all eighteen production failure codes. Byte-identical PNG copies may satisfy content equality, so the contract deliberately proves final-content consistency rather than image-origin identity.

## Known boundaries

This package consumes no Agent D or Agent E runtime bytes and does not touch battle HUD/world/VFX, simulation, hash/save/replay, thresholds, or `scripts/verify.sh`. AUI-34 and AUI-10R are now closed on master, but AUI-11 and AUI-20 remain separate successor packages and cannot enter this candidate. AUI-20 remains blocked on AUI-12 closure.

The candidate must not be fast-forwarded to master until Poseidon reviews the exact frozen Web build and fresh screenshots for route behavior, cyclic focus, cancel/back behavior, locale switching, compact landscape, portrait, true-200% text, +35% expansion, and en-US copy. Candidate movement invalidates that approval.
