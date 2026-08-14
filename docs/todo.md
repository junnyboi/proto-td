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

## TD-038 — Remap Witch Doctor portrait and deployment icon to Mage Apprentice

- Status: in_progress
- Owner: AGENT 8
- Branch: `agent-8/td-038-witch-doctor-ui-visuals`
- Base: `master` at `a9a986c0cafc08322d53aa31a04d8a47c0ad990f`
- Dependencies: TD-036 Witch Doctor battle-body alias; Mage Apprentice manifest assets
- Owned files: `data/operators/witch_doctor_1.tres`, `assets/manifest.tres`, `assets/provenance/{witch_doctor_1,portrait_witch_doctor_1}.provenance.json`, `test/test_witch_doctor.gd`, `selftest/scenarios/{witch_doctor_heal,witch_doctor_ui_visuals}.gd`, and TD-038 claim/closure edits in `docs/todo.md` / `docs/completed.md`
- Do not touch: Witch Doctor mechanics/name/operator ID/skill/balance, Mage Apprentice or Witch Doctor image bytes, animation resources, simulation/hash/save/replay/economy state, verification thresholds, or unrelated UI/presentation files
- Acceptance: Witch Doctor retains `id=witch_doctor_1` and all gameplay values while `sprite_id` and `portrait_id` resolve to `caster_1`; the live deployment slot icon equals Mage Apprentice frame 0, the live squad portrait equals `portrait_caster_1`, neither uses the procedural Witch Doctor fallback, and all model/campaign hashes remain unchanged
- Required evidence: focused Witch Doctor and provenance GUT contracts, fresh headless/windowed `witch_doctor_heal`, fresh headless/windowed `witch_doctor_ui_visuals`, model-promotion/replay hash checks, and one clean STANDARD gate on the final union
- Last update: 2026-08-14

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
