# AUI-10R — Agent D S1 Runtime Integration Handoff

**Owner:** AGENT D
**Branch:** `agent-d/s1-world-runtime`
**Base:** `3936eeda3e25c5f45def229b168fd11c41a048d9`
**Assurance lane:** RELEASE
**Current state:** Core-C/Backdrop-B revision implemented; pre-verdict RELEASE/audit/replay green; Poseidon approved exact candidate `60b69a6004a9c843851d9f6c9aee84c88389cb1f`; post-verdict union verification is mandatory

## What changed

Twelve S1 world assets are runtime-backed under `world.s1.*`. The selected player-facing changes are:

- the rejected pressure-tank Core is replaced by the 32×32 **Cloud-Seal Orrery**, with open brass arcs, a suspended cloudstone, bottom-center pivot, and unchanged route clearance;
- the rejected repeated outside-map fragments are replaced in the live view by one 208×104 **Alpine Escarpment panorama**, derived from a dedicated GPT Image 2 environment-only source and normalized to a fixed no-dither palette;
- four modular foothill/ridge/peak/mist components remain manifest/provenance-backed as deterministic revision-source material, but S1 renders one continuous panorama rather than a tiled ring.

`StageArtTheme` fails closed if any required ID is unavailable. `IsoGridBuilder` places the panorama at z=-10—above BattleView's flat canvas at -20, below all terrain—and ignores input. Ground, route, elevation, three route notches, Spawn, Core, and rain-measure rules remain presentation-only. Other stages keep the generic terrain lane.

No simulation, StageDef geometry, save/hash/replay state, gameplay data, threshold, localization catalog, or verification entrypoint changed.

## Approval and provenance

The parent approval is `docs/media/AUI-DESIGN-D-approved-manifest.json`. Poseidon's exact revision selection and GPT Image 2 concept/production hashes are in `docs/media/AUI-DESIGN-D-REVISION-CORE-C-BACKDROP-B.json` under token `AUI-DESIGN-D-REVISION-2`.

The committed bounded panorama source is `art-src/world/s1/s1-alpine-escarpment-source.png`; its hash is pinned by the revision receipt and every panorama provenance sidecar. Runtime and staged final bytes must remain identical. Poseidon's exact-candidate final-art verdict is recorded at `docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json`; all twelve manifest placeholders are cleared and every sidecar binds that receipt, owner, timestamp, and accepted candidate.

## Verification contract

Before merge:

1. Run the canonical base generator, revision generator, and twelve-asset validator twice; all generated tracked bytes must be identical.
2. Freeze the exact candidate commit.
3. Run GUT, `s1_world_art` headless/windowed, existing `assets_floor` and `iso_projection_floor`, then uninterrupted `scripts/verify.sh --full`.
4. Delete generated artifacts/caches prescribed by the repository and run one fresh cache-bypassed clean-artifact RELEASE at the same frozen hash.
5. Obtain a non-implementer diff-vs-pins audit and localization-impact review.
6. Show Poseidon fresh unobscured in-game captures. Poseidon approved AUI-10R revision 2 at candidate `60b69a6004a9c843851d9f6c9aee84c88389cb1f` on 2026-08-13.
7. Because the verdict changes manifest/provenance/ledger bytes, freeze the post-verdict exact union with current master and repeat cache-cleared RELEASE, cross-process replay, independent diff-vs-pins audit, localization-impact review, and merged-master verification before pushing.

If visual feedback requests another change, modify presentation data/assets only, preserve every check and threshold, restart RELEASE assurance from rung one, and show new captures. The verification fleet remains unsentimental. Sensible machine.
