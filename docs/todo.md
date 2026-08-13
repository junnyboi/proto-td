# Active Work

This is the authoritative multi-agent coordination queue. It contains **incomplete work only**.

- `FEATURES.json` currently owns product acceptance, evidence references, and feature status; explicit evidence-class ownership begins after `PROC-FEATURE-EVIDENCE` closes.
- This file owns active work, exclusive lane/file claims, dependencies, and closure evidence.
- `docs/completed.md` owns compact history for work closed out of this queue.
- `PLAYTEST.md` owns human verdict capture; `FINAL_REPORT.md` is an audit record, not the queue.
- Before claiming an item, pull the default branch and confirm no other item owns the same files.
- Allowed statuses: `pending`, `blocked`, `in_progress`.
- Existing domain IDs remain valid; new general coordination items use `TD-###`.
- Completed items move to `docs/completed.md`; they never remain in both files.
- Preserve every valid concurrent entry during merges; never resolve a shared-ledger conflict by dropping the other lane wholesale.
- Shared hot files (`FEATURES.json`, these ledgers, `scripts/verify.sh`, tick semantics, thresholds) are serial integration surfaces.

## Claiming an item

Replace `unassigned` with the assigned agent identity, create `agent-N/<lane>`, add `Base: <default branch> at <full SHA>`, change the status to `in_progress`, and replace candidate paths with the exact exclusive file set before editing. Never claim a file already owned by another active item.

```markdown
## TD-### — Imperative work title
- Status: pending | blocked | in_progress
- Owner: AGENT N
- Branch: `agent-N/lane-name`
- Base: `<default branch>` at `<full SHA>`
- Dependencies: none | <stable ID>
- Owned files: exact paths or non-overlapping globs
- Do not touch: shared or externally owned paths
- Acceptance: falsifiable behavior and measurable exit conditions
- Required evidence: named tests, scenarios, screenshots, replay diffs, or documents
- Last update: YYYY-MM-DD
```

## AUI-20 — Integrated S1 slice and kill-gate verdict

- Status: in_progress
- Owner: AGENT F (Agent 7)
- Branch: landed claim `agent-f/aui-20-claim`; ownership amendment `agent-f/aui-20-fixture-amendment`; implementation `agent-f/aui-20` only after the amendment lands, the revised independent package plan passes preflight, and Poseidon approves the exact representative packet
- Base: current `master` at `f4827f6ec255b502a1d17ef4642eda295ac162c8` / tree `e62040acfd7c9998c80edb0e318d2c5425688001`
- Dependencies: AUI-12 closed at approved player candidate `aa856d71d5e533f8267bed3b63c8c85fc0acfc9d`; approved AUI-10R runtime union `ffc08098a1434ca9cb68cc7dd884c71d690a93a9` remains an ancestor with Poseidon receipt SHA-256 `a21755ce4e761b51f903d07861d154ae5c618cb4ccabf5b31f652dc8167f2c83`. Current master also contains the human-final Round-5 source/runtime binding accepted at `441cb80b079ee89195ef751dbc26e67b426600d0`; decision SHA-256 `ea503dba5c14b9b966d18d3dda6e0325b0d1b28aed540401311bf23b89a04f4e`. Preflight 01 correctly failed because no representative 192 px packet was owned or available; Poseidon authorized the narrow packet amendment on 2026-08-13. AUI-11 remains separate and no unlanded Agent E bytes may be consumed.
- Owned files: `docs/decisions/AUI-20-REPRESENTATIVE-FIXTURE-AUTHORIZATION.md`; `assets/sprites/aui20_fixture_vanguard_1.png`; `assets/sprites/aui20_fixture_grunt.png`; `assets/provenance/aui20_fixture_vanguard_1.provenance.json`; `assets/provenance/aui20_fixture_grunt.provenance.json`; `data/presentation/s1_slice_fixture_manifest.gd*`; `data/presentation/s1_slice_fixture_manifest.tres`; `test/test_presentation_s1_fixture.gd*`; `selftest/scenarios/aetheria_s1_slice.gd*`; `selftest/scenarios/aetheria_s1_slice.gd.contract.json`; `test/test_presentation_s1_slice.gd*`; `tools/presentation_qa/s1_slice_audit.py`; `tools/presentation_qa/test_s1_slice_audit.py`; `scripts/view/battle_view.gd*`; `scripts/view/iso_grid_builder.gd*`; `scripts/ui/battle_controls.gd*`; `scripts/ui/deploy_bar.gd*`; `scripts/ui/spell_bar.gd*`; `scenes/battle.tscn`; `data/presentation/s1_world_theme.tres`; `data/presentation/s1_slice_cues.tres`; `docs/handoffs/AUI-20-agent-f-s1-slice.md`. Shared ledgers are owned only by this amendment and later closure transactions.
- Do not touch: approved Round-5 source sheets, existing `assets/sprites/{vanguard_1,grunt}_*.png`, their manifest/provenance/approval bytes, `assets/world/s1/**`, AUI-12 UI shell/localization bytes, Agent D/E source or staging paths, any other production character/VFX runtime path, simulation/model/hash/save/load/replay/telemetry, `scripts/view/iso_projection.gd*`, gameplay content/balance, bots, audio, `scripts/verify.sh`, human thresholds, or unrelated tests/scenarios.
- Acceptance: freeze and independently preflight the revised package plan before implementation; bind exactly one representative operator/enemy pair as two 768x384 atlases with 4x2 192 px cells, bottom-center foot row 180, four rest/movement frames, four attack/skill frames, exact AUI-34 QA PASS, reserved-color exclusion, and 72 px displayed subjects. Poseidon must approve the exact atlas/contact-sheet hashes before runtime binding. Then run `aetheria_s1_slice` at seed 42 with exact `9000 + 180 = 9180` frame budget, `done()`, zero render skips, and `<30 s` windowed; preserve replay, grid, picking, and display-anchor semantics; pass frozen Act-I value, route/Core, role/facing, cue-edge, primary-action, and `<18%` HUD protocols; pass local Chromium title-to-S1 with empty error arrays and usable, nonzero frozen load/memory/export/p95/p99/light ceilings. Emit `PROCEED` only if every native/Web/full gate passes; `PIVOT` may alter only presentation scale, batching, materials, or cue data; after three distinct documented failed fixes against a hard ceiling, `KILL` only the 192 px source approach and never a check or threshold.
- Required evidence: revised plan-lint PASS closing all preflight-01 findings; exact fixture generation/provenance packet; Poseidon packet approval; focused fixture/GUT/Python suites; fresh headless/windowed `aetheria_s1_slice` reports and exact-candidate images; code-blind recognition ballots; local-browser performance report; unchanged `scripts/verify.sh --full`; two-process normalized replay equality; independent non-implementer diff-vs-pins/evidence audit; inline fresh exact-candidate review captures and Poseidon milestone verdict before landing; guarded exact-union landing and docs-only closure.
- Last update: 2026-08-13

## L7-R1 — Human playtest round 1

- Status: blocked
- Owner: human
- Branch: N/A
- Dependencies: published verified Web build
- Owned files: `PLAYTEST.md` verdict rows (human capture only)
- Do not touch: `playtests/thresholds.json`; tests and thresholds remain human-owned
- Acceptance: complete S1–S8 protocol; capture fun, composition, responsiveness, voluntary replay, and juice verdicts at play time
- Required evidence: populated `PLAYTEST.md` round-1 verdict ledger with severity and `data-edit|code-change|prompt-change` classification
- Last update: 2026-08-12

## L7-T2 — Tier-2 evaluator, bands, baselines, and round-1 fixes

- Status: blocked
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: `L7-R1`
- Owned files: none until claimed; candidate paths are `scripts/quality_gate.sh`, `playtests/thresholds.json`, data resources named by verdicts, and required tests
- Do not touch: human verdict wording; thresholds before `L7-R1`; unrelated model/view files
- Acceptance: transcribe human-owned bands, implement evaluator, commit first baselines, apply verdict-driven data edits, and preserve all tier-1 gates
- Required evidence: fresh `scripts/verify.sh --full`, tier-2 gate report, and updated verdict arithmetic
- Last update: 2026-08-12

## L7-R2 — Human playtest round 2 and acceptance closure

- Status: blocked
- Owner: human
- Branch: N/A
- Dependencies: `L7-T2`
- Owned files: `PLAYTEST.md` round-2 verdict rows (human capture only)
- Do not touch: machine evidence or thresholds during human capture
- Acceptance: confirm or reopen every round-1 verdict; close fun, composition, responsiveness, voluntary-replay, and ≥80% data-edit acceptance rows
- Required evidence: completed round-2 ledger and final numerator/denominator in `PLAYTEST.md`
- Last update: 2026-08-12

## POLISH-VFX — Replace rectangle placeholder effects

- Status: pending
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: none; coordinate with `POLISH-BOLT` if one presentation lane owns both
- Owned files: none until claimed; exact manifest, asset, view, and scenario paths must be pinned before work
- Do not touch: simulation core, `scripts/verify.sh`, thresholds, or unrelated shared hot files
- Acceptance: dust, sparks, vignette, swirl, banner, and stamp use manifest-backed final assets while preserving model semantics and probe reservations
- Required evidence: affected GUT/scenarios, fresh render-lane PNGs, falsifiable visual checklist, and `scripts/verify.sh --full`
- Last update: 2026-08-12

## POLISH-BOLT — Add a readable Bolt impact visual
- Status: pending; prior implementation checkpoint exists but final audit is incomplete
- Owner: unassigned
- Branch: N/A until claimed; prior unmerged checkpoints include `agent-7/polish-bolt` and `agent-10/bolt-impact` at `cf16ca2`
- Dependencies: coordinate with `POLISH-VFX`; audio remains waived by `D-SFX`; read `docs/handoffs/POLISH-BOLT-agent-10.md` before adopting or replacing the checkpoint
- Owned files: none until claimed; next owner must pin exact presentation, model-record, manifest, asset, test, and scenario paths before editing
- Do not touch: spell damage/cooldown/targeting semantics, audio policy, verification thresholds, or unrelated presentation lanes
- Acceptance: Bolt impact is visually identifiable at 1× without relying on audio or changing combat outcomes; any adopted deterministic event record must remain hash-covered and zero-state-change on rejection
- Required evidence: seeded Bolt scenario, present/absent pixel proof, fresh PNG review, cross-process campaign replay diff, independent adversarial review, and a fresh uninterrupted `scripts/verify.sh --full`
- Last release: 2026-08-12 — Poseidon reassigned AGENT 7 before integration. `agent-7/polish-bolt` remains intentionally unmerged and owns no active files or contracts.
- Last release: 2026-08-12 — Poseidon unassigned AGENT 10 during final audit. `agent-10/bolt-impact` remains intentionally unmerged and owns no active files or contracts; partial audit artifacts were deleted.
- Last update: 2026-08-12

## POLISH-BOSS-HIT — Wire the boss-hit presentation event

- Status: pending
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: observable event/seam contract before implementation
- Owned files: none until claimed; pin the event producer, view consumer, data resource, and scenario paths
- Do not touch: model outcomes, tick semantics, unrelated shake magnitudes, thresholds
- Acceptance: `boss_hit` drives the existing data-configured presentation slot through an observable deterministic seam
- Required evidence: seam test, seeded scenario, render proof, and `scripts/verify.sh --full`
- Last update: 2026-08-12

## POLISH-PORTRAIT — Decide and execute portrait fidelity beyond v2

- Status: blocked
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: `L7-R1` portrait-card verdict or explicit owner direction
- Owned files: none until claimed; pin exact manifest, palette, portrait asset, normalization, and `assets_floor` paths
- Do not touch: unrelated battle sprites, gameplay semantics, probe-color reservations, thresholds
- Acceptance: either record that v2 portrait fidelity is accepted, or upgrade only the human-identified portraits while preserving manifest contracts
- Required evidence: linked human verdict/decision; if changed, asset QA, contact sheet, `assets_floor`, and `scripts/verify.sh --full`
- Last update: 2026-08-12

## JUICE-FINAL — Close the final juice-automation verdict

- Status: blocked
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: `L7-R2` plus closure/decision for applicable polish items
- Owned files: none until claimed; candidate paths are `JUICE_VERDICT.md`, linked evidence, and only data/assets named by final verdicts
- Do not touch: historical verdict text, human-owned thresholds, or waived audio decision `D-SFX`
- Acceptance: record the final automation verdict against the post-playtest/post-polish build, with every open item closed, deferred, or linked to an active todo
- Required evidence: updated `JUICE_VERDICT.md`, linked final-run artifacts, and `scripts/verify.sh --full` for any build change
- Last update: 2026-08-12

## VERIFY-MOVIE — Decide and, if retained, re-prove Movie Maker lane

- Status: pending
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: explicit decision that the lane remains required
- Owned files: none until claimed; candidate paths are verification documentation and movie-lane scripts only
- Do not touch: human-owned thresholds; existing render-lane checks
- Acceptance: either record a decision that Xvfb screenshots supersede this lane, or execute a bounded Movie Maker proof against the current build
- Required evidence: `docs/decisions/` record and, if retained, reproducible command plus artifact
- Last update: 2026-08-12

## L7-DURATION — Judge frame-counted juice durations

- Status: blocked
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: `L7-R1`
- Owned files: none until claimed; candidate paths are presentation configuration/data and associated render checks
- Do not touch: model tick semantics, tests, thresholds
- Acceptance: human verdict determines whether current frame-counted lifetimes remain or migrate to a render-time data schema
- Required evidence: linked L7 verdict; if changed, multi-refresh render proof and `scripts/verify.sh --full`
- Last update: 2026-08-12

## L7-PALETTE — Judge operator/enemy palette separation

- Status: blocked
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: `L7-R1`
- Owned files: none until claimed; candidate paths are manifests, palettes, sprite assets, and `assets_floor` evidence
- Do not touch: gameplay semantics, unrelated art classes, probe-color reservations
- Acceptance: human verdict confirms current separation or identifies exact classes/states needing palette adjustment
- Required evidence: linked L7 verdict; if changed, asset QA, contact sheet, `assets_floor`, and `scripts/verify.sh --full`
- Last update: 2026-08-12

## PROC-FEATURE-EVIDENCE — Add explicit evidence classes to the feature ledger

- Status: pending
- Owner: unassigned
- Branch: N/A until claimed
- Dependencies: approved schema migration plan and evidence inventory
- Owned files: none until claimed; candidate paths are `FEATURES.json`, a ledger lint/test, and documentation
- Do not touch: historical acceptance meaning, passing statuses, tests, thresholds, or evidence artifacts
- Acceptance: each feature declares `logic|integration|visual|feel` evidence and names the required existing artifact; human-only rows cannot pass without a `PLAYTEST.md` verdict
- Required evidence: ledger lint over every row, adversarial mapping review, and unchanged gameplay verification
- Last update: 2026-08-12
