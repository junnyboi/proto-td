# AUI-10 — Agent D S1 World Handoff

**State:** independent ART lane implemented; runtime integration intentionally unbound
**Agent:** AGENT D
**Branch:** `agent-d/aui-10-s1-world`
**Base:** `master` at `975261e8e00a20a0b25fe17e7976d743d509c14b`
**Implementation commit:** `817408afd31ce8020678f2fb9837cf96870d212f`
**Implementation tree:** `89208d693517051bbf95e47254b6845984be10fd`

## Delivered by Agent D

Agent D staged eight deterministic native S1 world assets, a GPT Image 2 source ledger, exact generation prompts, palette/geometry contracts, one-to-one provenance, a fail-closed presentation payload, contact-sheet/value/mask evidence, and portable normalizer/validator tools. No runtime manifest, view, scene, model, stage, harness, test, threshold, localization, or feature-ledger surface was changed.

## Agent F integration seam

Agent F may bind this lane only after verifying `staging/presentation/world/s1/stage-presentation.json` against the receiving commit. Integration must preserve the authoritative S1 geometry and stage hash; copy the accepted eight PNGs from non-importable `staging/` into Agent F's runtime manifest-owned asset path; resolve the eight logical IDs through the shared manifest; apply Spawn/Core as mouse-ignoring presentation owners with the declared pivots/offsets; instantiate route cadence only at the three declared cells; and leave `world.s1.rain_measure` unplaced until a validated non-protected anchor exists. Never remove `staging/.gdignore` or bind `res://staging/**` directly.

The shared manifest/view binding is a serial integration surface. If Agent F's contract uses different schema or logical-ID conventions, reconcile mechanism to the landed convention without changing Agent D's approved visual semantics. Do not infer final-art acceptance: every sidecar remains `human_acceptance.final_art=false`.

## Required integration evidence

Run the receiving commit's routed STANDARD-or-higher union gate. Because the change becomes player-facing only when bound, the integration commit needs fresh impacted windowed PNGs and probes for S1 terrain material separation, Spawn/Core recognition, route direction, elevated clearance, picking/input pass-through, overlays, viewport fit/pan, and absence of false-playable backdrop affordances. Parent/lane green does not prove the merged union.

## Local Agent D commands

```bash
python3 tools/art_pipeline/world/normalize_s1_world.py
python3 tools/art_pipeline/world/validate_s1_world.py
```

Both commands are deterministic after generation. The lane's runtime-binding status must remain `UNBOUND_AGENT_F_SEAM` until the integration commit and its fresh evidence exist.

## Frozen feature evidence

At the implementation commit above, `tools/art_pipeline/world/validate_s1_world.py` passed before and after an uninterrupted `scripts/verify.sh --full`; the repository full gate ended `[verify] ALL GREEN`, and the worktree remained clean at the same commit/tree. External evidence digests: AUI-10 gate `5992dbcf27ea4b5432606d29d60b511321ae29ecd975a10508b81a2ec94d4379`, full log `adce1a1b8ce2193f254714a9a2ccd47714027f8b70f9f2117cb3f0c5c2e3c852`, and `verify.json` `b2fb2a7b4196bda0b4c07886021823f9e20166218d36d577cdb75687b327b05d`.
