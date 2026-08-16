# P16 Recruit Progression Phase 4 — Runtime Cutover

**Owner:** Agent 7 / Agent F  
**Status:** Complete  
**Runtime candidate and landed master:** `934080f5f967b1b2301cc26e44955e0245762fd5`  
**Baseline:** `14a39df7dda43e2612700857fafb9f9d9ee68e88`

## Outcome

The playable campaign now uses authoritative CampaignSave v3 state from first launch through durable battle resolution. A fresh campaign starts with five persistent Recruit people. Squad selection and deployment preserve distinct hero and battle identities even when several people share the same Recruit template. Stage launches consume committed immutable tickets, terminal facts come from the BattleModel-owned canonical outcome, and Results projects only the exact outcome and resolution accepted by durable campaign authority.

Every new persistent nonlegacy person is created as a Recruit through an authoritative strategic command. Starter, paid-contract, recovery, and replacement paths share the same identity construction rules; specialist-person rewards are rejected. Existing specialist rewards were converted into standard availability or advanced class entitlements, including `immovable` at S3. Debug and replay-v1 compatibility remain explicitly isolated from campaign save bytes.

Legacy pre-ledger saves are validated through the compatibility codecs, then the playable runtime rolls them once into a fresh Recruit generation because their histories cannot authenticate append-only v3 commands. The generation counter and compare-and-swap preimage prevent repeated or ambiguous rollover. Unresolved durably begun attempts restore their exact frozen ticket after process restart and resume without soft-locking the save.

## Runtime and Authority Closure

The runtime coordinator independently reloads every successfully committed state before publication. Failed result saves retain the original mutation and canonical outcome for exact retry. Already-durable duplicate commands are reconstructed from the receipt ledger, compared against the complete result and event envelope, and published without another save; forged duplicate envelopes reject. `Game.record_result()` uses the ticket’s frozen expected revision and ignores caller-supplied result/stars or a subsequently altered live model snapshot.

Campaign and verification cold boots no longer depend on stale global class registrations along the CampaignSave v3 dependency closure. SaveStore, runtime context, state/command/history codecs, mutation, promotion, recruitment, and Results dependencies resolve through explicit preloads or cycle-safe path loads. The historical stale-class-registry probe passes against the old registry and the current registry with only `CampaignProgression` removed.

Verification processes now use one watchdog-owned disposable root. Every rung receives isolated XDG data, config, and cache directories; every helper nests scratch work beneath the parent rung root; standalone helpers retain their own disposable fallback. The Web gate copies only the SHA-256-pinned Godot 4.7.1 Web template as mode `0444` under read-only directories. Player save bytes, the host template, inherited XDG sentinels, and temporary-root inventory remained unchanged across the final full run.

## Verification Evidence

| Proof | Result |
|---|---|
| Frozen full STANDARD | `scripts/verify.sh --full` passed all 132 rungs in 1,509 seconds at `934080f` |
| Render evidence | 44 scenario reports, 225 fresh PNG files, zero render skips |
| Full campaign bot | Authoritative real-command campaign cleared S1–S8; R5 and R6 gate passed |
| Campaign determinism | Two separate OS processes produced byte-identical normalized telemetry, SHA-256 `e43437c70083635fb7ead92cbfdaf09512a56111dad3cf300314a4caedc27eed` |
| Strategic/save/replay proof | Focused runtime, recruitment, schema, command, replay v1/v2, filesystem, and strategic transcript gates passed; risk-selected suites were repeated in separate processes |
| Cold-cache proof | Historical stale-class-registry and Music cold-boot probes passed from clean candidate state |
| Host-state isolation | Production campaign save, host Web template hash/mode, inherited XDG data/config/cache sentinels, and verification-root inventory were unchanged |
| Independent audit | Final diff-vs-pins Half B returned PASS with no Critical, Warning, Suggestion, or pin-break findings at `934080f` |
| Visual judgment | Compact callsign plus stable ordinal, visible Recruit class, DP cost, portrait, and selection state accepted in the Phase 4 windowed evidence |

Earlier full-run attempts exposed and closed real gaps in restart recovery, cold-cache dependency resolution, result provenance, duplicate command publication, save/template/profile isolation, and harness cleanup. Two batch-only `experimental_salvage_enemies` windowed reds were routed as environment flakes because the exact scenario passed headless and immediately passed isolated windowed reruns without a code change; the final frozen full run subsequently passed the same scenario and the entire ladder.

## Scope Boundary and Next Phase

Phase 4 does not activate the polished post-battle Promotion Board, final Recruit art, or Memorial UX. Those remain Phase 5 and Phase 6 work. The P16 feature ledger therefore remains `pending`; this closure appends the Phase 4 runtime candidate while preserving the remaining visual and feel acceptance gates. The next implementation quest is Phase 5: Results-to-Training promotion UI over the now-authoritative runtime seam.
