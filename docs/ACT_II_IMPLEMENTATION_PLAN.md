# Act II Implementation Plan — The Garden Veto

**Canonical repository:** `https://github.com/junnyboi/proto-td`
**Godot compatibility:** 4.7.2 stable, existing project format and matching Web templates
**Deployment mapping:** `proto-td` → existing WebDev project `proto-td-web`
**Proposal:** [`ACT_II_PROPOSAL.md`](ACT_II_PROPOSAL.md)

## Delivery strategy

Implementation is divided into three source work packages and one release package. Each source package ends with targeted regressions, a repository-wide risk review, a source checkpoint commit, a fresh upstream reconciliation, and a push to shared `master`. The release package re-fetches the latest source, runs the complete native and Web gates, layers the newest PCK onto the newest `proto-td-web` host, and saves a WebDev checkpoint.

## Work package status

| Package | Scope | Status | Exit gate |
|---|---|---|---|
| **WP1 — Restoration foundation** | Stage schema, portrait rotation, deterministic lattice healing/suppression, 600px GPT Image 2 seal, renderer, campaign-context capacity, unit tests | Complete | Mechanic determinism, hash stability, rotation, stage-domain validation, import/boot, focused regression pass, master push |
| **WP2 — Eight-stage campaign content** | S9–S16 layouts, paths, waves, balance, rewards, 16-stage runtime order, save compatibility, stage-design tests | Complete | All stage lint/design/orientation/navigation tests, campaign fresh/restore/unlock tests, deterministic terminal simulations, master push |
| **WP3 — Narrative and campaign presentation** | Six-layer S9–S16 narrative, EN/zh-CN localization, Act II chapter labels, canon revision, concept integration, updated design docs | Complete | Narrative catalog, localization completeness, UI layout in landscape/portrait, screenshots, master push |
| **WP4 — Release and deployment** | Full test suite, Xvfb representative input, Web export, HTTP/browser runtime, forward-only WebDev reconciliation, build/check, checkpoint | Complete | Required HTML/JS/WASM/PCK files, clean logs/console/network, exact managed PCK, fullscreen host, saved checkpoint |

## WP1 — Restoration foundation

1. Extend `StageDef` with `restoration_cells`, `restoration_heal_amount`, and `restoration_interval_ticks`.
2. Rotate restoration cells in `clockwise_rotated_copy()` and preserve all non-spatial fields.
3. Apply due restoration after movement/traps and before combat. Repair only alive, hostile, non-aerial enemies on authored lattice cells, clamp at `hp_max`, and suppress a cycle when any active Slow Field covers the cell.
4. Keep authoritative state minimal: restoration changes existing enemy HP, already covered by snapshots and battle hashes; no redundant mutable ledger is introduced.
5. Render authored lattice seals below dynamic entities using the 600×556 lossless WebP derivative. Use linear mipmap filtering and tile-scale display sizing.
6. Generalize V3 campaign validation from exactly eight to the authoritative stage count while retaining sequential IDs and one 40-Shard first-clear row per stage.
7. Add focused tests for interval timing, HP clamping, aerial/charmed exclusions, Slow Field suppression, portrait rotation, invalid lattice domains, and 600px source/display contracts.

## WP2 — Eight-stage campaign content

1. Author unique rectangular S9–S16 landscape grids with adjacent SPAWN→BASE paths and restoration cells located only on walkable ground path cells.
2. Author 18–32 enemy schedules using existing enemy definitions, three or four wave windows, and controlled escalation from S8.
3. Preserve teach-before-use requirements: all Act II stages require the relevant Act I systems; no new content reward appears without a preceding lesson.
4. Add S9–S16 reward rows to `p16_v3.tres`, each granting 40 Resonance Shards.
5. Expand `CampaignRuntimeContext` and V3 stage order to sixteen stages. Recompute and update the canonical environment SHA-256 only after the final content manifest passes.
6. Update stage redesign, orientation, map navigation, campaign codec, strategic unlock, fresh campaign, save restore, and replay tests.
7. Add deterministic balance simulations for every Act II stage with authored representative action policies and bounded terminal ticks. Tune schedules rather than enemy definitions.

## WP3 — Narrative and campaign presentation

1. Revise the canon bible to version 2.0 with the binding Act II table, clear transmissions, mechanic meaning, and future-boundary language.
2. Add eight complete `StageNarrativeDef` resources and extend the catalog to S1–S16.
3. Add every stage title, hint, dossier field, debrief, speaker, and transmission key to English and Simplified Chinese catalogs.
4. Add Act I/Act II chapter identity to Mission Control rows and dossiers without breaking scroll, keyboard, or portrait behavior.
5. Integrate the four GPT Image 2 concept boards into durable proposal/canon documentation; keep concept art out of runtime payload unless explicitly used by a shipped screen.
6. Update `LEVEL_DESIGNS.md`, README campaign scope, task ledger, and implementation plan status.
7. Capture Mission Control and representative S9/S12/S16 battles at landscape and portrait sizes with dummy audio and representative input.

## WP4 — Release and deployment

1. Re-fetch and forward-reconcile shared `master`; run import, bounded headless boot, all standalone regressions, all repository smokes, and strict error scans.
2. Export the exact reconciled source with the existing `Web` preset and matching 4.7.2 templates. Require `.html`, `.js`, `.wasm`, and `.pck` artifacts.
3. Serve the bundle over HTTP. Verify WebGL startup, resource status/length, clean console/network logs, Act II Mission Control navigation, S9 launch, lattice rendering, and suppression behavior.
4. Force-sync the existing `proto-td-web` host. Preserve all newer compatible host work and replace only the managed PCK mapping plus release records.
5. Run `pnpm check`, `pnpm build`, exact-resource/stale-reference checks, restart the preview, and verify the borderless zero-margin fullscreen iframe in desktop and portrait layouts.
6. Save the final WebDev checkpoint and record the exact version link.

## Risk controls

| Risk | Control |
|---|---|
| Existing V3 saves reject the expanded environment | Decode/restore fixtures containing only S1–S8 progress against the 16-stage context; keep save schema version unchanged because stage rows are additive |
| Wide stage grids clip or become unplayable in portrait | Rotate restoration cells with paths, run all sixteen stages through the five-viewport navigator matrix, and visually inspect representative extremes |
| Restoration creates infinite heavy stalls | Clamp repair, use discrete intervals, cap authored heal amounts, and simulate each stage to terminal under bounded representative policies |
| Slow Field interaction is ambiguous | Suppress due restoration cycles only while its authoritative area covers the lattice; explain in S9 hint/transmission and show a distinct seal beneath the field |
| Campaign UI becomes too dense | Retain one scrollable route column, add compact chapter separators/labels, and test keyboard focus plus 720×1280 portrait containment |
| Concurrent source or host advances | Stash/protect local work, fetch, fast-forward or merge constructively, preserve both features, rerun focused gates, and push forward without rewriting shared history |

## Completion record

Runtime source `f2ffcc65aae0170f26448a65f55aa78bb11e8807` is pushed to shared `master`. The sixteen-stage V3 catalog uses environment fingerprint `94368da5ab8df24620f9987229a3448385226755d36dc9950faebd66ccab8e1e`; historical eight-stage V3 saves restore additively and the V2 boundary remains unchanged.

Godot 4.7.2 direct import and bounded boot pass. All current standalone regressions and repository smokes pass, including sixteen-stage campaign, topology, orientation, navigation, deterministic terminal, restoration, narrative, localization, and Mission Control coverage. Strict localization audit reports 925/925 English/Simplified Chinese entries with zero missing/extra keys, placeholder drift, missing production keys, or hard-coded visible candidates. Landscape and portrait Xvfb captures accept Mission Control and S9 lattice presentation.

The final Web export contains HTML, JavaScript, WASM, and a **197,110,152-byte** PCK with SHA-256 `177d545d3df4ae816658f558109f3b39132db44b46b94a842cf742eb05db88fd`. Local and managed HTTP/browser checks verify one exact PCK, zero eager OGV streams, real input, all sixteen route rows, borderless fullscreen geometry, portrait containment, and clean runtime logs. The existing `proto-td-web` host is saved at checkpoint `7da5e373`.
