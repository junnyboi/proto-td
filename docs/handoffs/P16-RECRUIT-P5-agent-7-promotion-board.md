# P16 Recruit Progression Phase 5 — Results-to-Training Promotion Board

**Owner:** Agent 7 / Agent F  
**Status:** Complete  
**Runtime candidate and landed master:** `6f9839f1532a89137f3318a13d91b7a7c860e25f`  
**Baseline:** `0496104f9fd12a19c681f1236264d913a732c486`

## Outcome

The playable CampaignSave v3 campaign now routes eligible survivors from Results or Staging into the existing Company 33 Training terminal. The terminal projects persistent callsigns, portraits, current classes, XP, explicit eligibility reasons, and only model-returned legal destinations. A Recruit receives exactly the five standard choices. Every class card presents data-owned role, description, named skill, attack cadence, DP, placement, blocking, and range facts with a visible permanence warning.

Players may draft several hero-to-class mappings locally, inspect one Review plan, defer without a command, or submit one sorted atomic `confirm_promotions` batch. Game remains the only runtime authority coordinator: it constructs the deterministic command identity, commits through CampaignRuntimeAuthority and CampaignSaveStore, retains the exact opaque mutation after a retryable storage failure, and publishes a presentation-only acknowledgement only after restored durable state is accepted. A stale rejection refreshes legal options, retains still-legal draft rows, lists removed rows with reasons, and never mutates strategic state.

Results makes **Train Recruits** the unique primary action when model eligibility exists while keeping Return to Staging available. Staging keeps its mission action primary and exposes Training in visual focus order. Success returns to Staging with one compact callsign-to-class acknowledgement. Missing ClassDef or OperatorDef presentation data remains reachable as a focused localized error instead of silently hiding an otherwise model-eligible person.

## Presentation and Accessibility Closure

The accepted Training terminal now covers the complete route rather than a parallel promotion scene: Results, Personnel, five-choice class board, Review, durable error/retry, and Staging acknowledgement. Default, compact, portrait, zh-CN, 200%-text, and +35%-copy states are exercised at 1280×720, 960×720, and 720×1280.

Roster labels and card height derive from the active runtime font metrics. The scenarios require callsign, class, XP, and eligibility labels to meet the measured line height and remain enclosed. Production focus scrolling owns nested roster/path scrolling plus the outer page; tests no longer manually reveal the control they claim focus exposed. Training-active Results and Staging inventories preserve duplicate selectors, require exactly one visible match per selector, enforce exact totals and focus order, and include an explicit duplicate-selector rejection oracle.

## Verification Evidence

| Proof | Result |
|---|---|
| Frozen full STANDARD | `scripts/verify.sh --full` passed all 148 rungs in 1,586 seconds at `6f9839f` |
| Phase 5 reports | 13 fresh reports, 615 passing checks, 39 fresh PNGs, zero render skips |
| Core flow | Real S1 survivor XP → Results → two-person draft → one durable promotion batch → Staging acknowledgement |
| Failure authority | Standard/scaled/expanded save-failure scenarios preserve exact bytes, hash, revision, receipt ledger, hero rows, and pending mutation until retry |
| Responsive/accessibility | Standard, 200%-text, and +35%-copy states pass the three pinned viewports with measured row/card/label geometry and production focus scrolling |
| Exact inventories | Training-active Staging and Results pass standard/scaled/expanded exact inventory checks across all three viewports; duplicate selectors fail closed |
| Scenario integrity | `verify.sh` removes stale reports and requires process success, exactly one pass sentinel, matching scenario identity, nonempty checks, and a fresh passing report |
| Campaign determinism | Two independent S1–S8 campaign processes produced byte-identical normalized telemetry, SHA-256 `e43437c70083635fb7ead92cbfdaf09512a56111dad3cf300314a4caedc27eed` |
| Host-state isolation | Production save, host Web template hash/mode, inherited XDG sentinels, and temporary-root inventory were unchanged |
| Independent audit | Final source/pin audit and final evidence-integrity audit both returned PASS with no blockers |
| Durable evidence | `project-docs/Prototype TD/evidence/agent-7-recruit-p5/6f9839f` contains the full log, 148-rung manifest, 13 reports, 39 shots, two-process telemetry, provenance maps, and complete SHA-256 manifest |

The final evidence audit independently verified all 148 rung records, all 615 Phase 5 checks, all 39 screenshot mappings, preserved nanosecond source mtimes inside the recorded run window, complete checksums, and exact candidate identity.

## Scope Boundary and Next Phase

Phase 5 changes presentation and runtime command routing only. It does not change the promotion graph, thresholds, XP, class balance, CampaignSave schema, state hash, replay grammar, battle semantics, entitlements, reward semantics, approved atlas bytes, or final Recruit assets.

P16 remains `pending`. Phase 6 still owns Recruit art/audio and Memorial presentation; Phase 7 still owns the commit-bound Web playtest and Poseidon human kill gate. The next quest is therefore Phase 6, not a stealth balance patch wearing a UI hat.
