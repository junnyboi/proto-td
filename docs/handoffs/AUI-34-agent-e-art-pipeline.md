# AUI-34 Agent E Deterministic Art-Pipeline Handoff

**Owner:** Agent E / Agent 6

**Branch:** `agent-e/aui-34-art-pipeline`

**Base:** `3936eeda3e25c5f45def229b168fd11c41a048d9`

**Current state:** lane development complete; integrated by the later Agent 6 aggregate while runtime binding remains unbound [2]

**Shared-ledger projection:** Agent 6 for the owner-authorized AUI-34 aggregate only

## 1. Delivered capability

AUI-34 delivers a Python canonical backend, Godot `Image` fallback, strict spec/path contracts, deterministic synthetic fixtures, independent semantic expectations, same-backend cross-process byte checks, cross-backend decoded-RGBA differential checks, atomic packet publication, non-following cleanup, and non-destructive rollback retention.

It intentionally delivers no production Aetheria sprites, portraits, enemy sheets, Charm derivatives, VFX, runtime assets, manifest entries, presentation schema changes, gameplay changes, or human final-art state changes.

## 2. Checkpoints

| Package | Commit | Result |
|---|---|---|
| Python canonical pipeline and independent oracle | `f4fcd949b26b51e776b5a09a079b764b3ceab551` | pushed; 277 Python checks; unchanged repository gate green; independent findings closed |
| Godot fallback and differential | `f51a541467e5ab4860bb0a26731925de0979814b` | pushed; 468 fresh differential checks; exact decoded-RGBA parity; unchanged repository gate green; non-implementer audit pass |
| Contract, provenance, and handoff | containing commit | final exact-head receipt is external and must identify the immutable commit/tree |

The compact Package 2 receipt is tracked at `staging/qa/character-vfx/aui-34/package2-receipt.json`. Runtime evidence remains external by design. [3]

## 3. Approved design anchors

The pipeline records, but does not ingest, the exact approved Round 5 concept hashes:

| Domain | SHA-256 |
|---|---|
| Roster style board | `f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883` |
| Vanguard model sheet | `db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9` |
| Enemy character sheet | `f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8` |
| Portrait treatment sheet | `d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9` |
| Charm state sheet | `64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3` |
| VFX language sheet | `0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667` |

`human_final_art` remains `UNSET_HUMAN_ONLY`; `runtime_binding` remains `UNBOUND_AGENT_F_SEAM`. [4] [5]

## 4. Verification evidence

The Package 2 frozen tree `860759f785dd56c791c6c3a7d0ab84f41906c0e9` produced a fresh external differential summary with result `PASS`, 468 executed checks, seed 42, and summary SHA-256 `84614d549a212a7b07844ac1f0d3853051a6c2c368d114e3f600e4827fd03bde`.

The portable external evidence identifier is `package2-f51-release`. Relative files are `summary.json`, `hash-record.json`, `wall-seconds.txt`, `atlas-visual-review.md`, and `contact-sheet-visual-review.md`. The frozen command completed within the pinned outer watchdog in **55.279 seconds**:

```bash
export AUI34_EVIDENCE_ROOT="<external-evidence-root>/package2-f51-release"
timeout 180 python3 -B staging/qa/character-vfx/verify_pipeline.py \
  --backend differential --clean --seed 42 \
  --input-root staging/qa/character-vfx/fixtures/source \
  --process-timeout-seconds 60 \
  --evidence-root "$AUI34_EVIDENCE_ROOT" \
  --godot "$GODOT"
```

| Output | File SHA-256 | Decoded RGBA SHA-256 |
|---|---|---|
| Python atlas | `c91fafd7ff45b5fd535c0a672db8f851c68fb6e9978bc4ffb8c9fbc71343a1d8` | `f4deb08c4adac69e6f958a0e22846d7718cb5d5ea01413351f0ce44df581114a` |
| Godot atlas | `e842435994db496cd956807579adfe8b8902fb595923746bb470b31a45d40906` | `f4deb08c4adac69e6f958a0e22846d7718cb5d5ea01413351f0ce44df581114a` |
| Python contact | `6f9497337a17dd62b01377a7f1b91023023900392bd67f6242aebcb4bc76e508` | `c6d627ea3f9762a5921107d6f1e4970110aca1acb9cb5436904fa8d1442a3543` |
| Godot contact | `e7a8ceceee09f410bb68032e0b3f8987caa3fbc6bf8a38cced1ddf6eab8838ad` | `c6d627ea3f9762a5921107d6f1e4970110aca1acb9cb5436904fa8d1442a3543` |

The portable hash record SHA-256 is `e48f2297a7c6d36658182f1213bfbceb5d18d013026e755c388be1894e510b72`.

Both fresh backend atlases and both fresh contact sheets were separately inspected. The atlas checklist passed eight-cell order, non-empty inventory, anchor/foot alignment, border clearance, pose separation, and no blank/duplicate/clipped cells. The contact checklist passed 1536×256 geometry, light/dark/grayscale order, eight visible cells per panel, centered sampling, contrast change, grayscale hue removal, and no blank/duplicate/reordered cells. These are synthetic fixture checks, not final player-facing art approval.

The unchanged repository `scripts/verify.sh` passed after each standalone package. Final exact-head and later merged-union RELEASE receipts remain separate because a parent/lane green result never proves an untested union.

## 5. AUI-00 reconciliation matrix

| Assumption | Current state | Required integration action |
|---|---|---|
| A1 — AUI-00 durably closed on master | satisfied at `1a28721d23183bf9755ba6c90ba7c578cebc5850` | Preserve landed contracts |
| A2 — canonical decision contains all six Round 5 hashes | satisfied by the owner-authorized aggregate | Keep exact hashes, not prose-only approval |
| A3 — landed provenance schema represents every required fact | satisfied by separation | AUI-34 files remain staging pipeline contracts, not runtime provenance sidecars |
| A4 — reserved probe colors remain exact | satisfied | Fixture and contract match `#F4F4F4` / `#41A6F6` registry values |
| A5 — no runtime/shared file needed to prove AUI-34 | satisfied on disjoint branch | Reconfirm against landed claim |
| A6 — Python/Pillow versions available offline | verified | Stop on mismatch |
| A7 — Godot 4.7.1 fallback APIs | verified | Keep pinned engine |
| A8 — atlas/pivot/fps contract unchanged | verified against approved plan | Owner reconciliation required for any pin change |
| A9 — no staging path overlap | satisfied | Base-to-head changed-path intersection was empty; active AUI-12 excludes AUI-34 paths |
| A10 — repository gate unchanged | verified | Run it unchanged on reconciled branch and union |
| A11 — no final-art/placeholder flip | verified | Treat any integration diff as critical |
| A12 — shared closure owner | owner-overridden | Poseidon appointed Agent 6 to integrate and project only AUI-34 closure records |

## 6. Numbered deviations

**D5** was exercised as a concern-preserving Godot split. Strict lexical JSON, spec/path validation, integer pixels, packet publication, and CLI routing live in separate scripts rather than the three provisional filenames. No semantic pin or gate was weakened.

**D6** is the owner-authorized sequencing override: parallel development, verification, commit, and feature-branch push were allowed before AUI-00 closure; master integration and shared-contract mutation were not.

**D7** is the later owner-authorized recipient override: Poseidon appointed Agent 6 to authenticate the immutable receipt, form the exact AUI-34 aggregate, project its bounded shared records, and publish after fresh union assurance. The terminal receipt itself remains unchanged.

## 7. Aggregate publication sequence

1. Authenticate the exact terminal receipt, owner override, current master, and the no-overlap composition set.
2. Compose current master plus the terminal lane without committing or verifying a partial candidate.
3. Reconcile A1–A12 through bounded approval/status/staging-contract edits only; preserve every semantic pin and failing threshold.
4. Create one aggregate commit and one external `mgs.final-union.v1` identity.
5. Run fresh cache-bypassed Python/Godot differential and unchanged repository RELEASE gates on that exact aggregate.
6. Inspect fresh synthetic and repository screenshots, then obtain a non-implementer diff-vs-pins pass.
7. Fast-forward local master, push normally, and prove local/remote SHA equality. Never force-push.

Never force-push. Never infer union green from either parent. Never treat a timeout, missing summary, stale evidence, dirty worktree, or zero checks as proof.

## 8. Successor boundary

Production character and VFX generation remains deferred. `AUI-11` and later packages may use AUI-34 after the aggregate is published, but production packets and runtime/provenance binding still require separate claims and gates. Bulk operator production, enemies, Charm derivatives, and authoritative VFX remain outside this handoff.

## References

[1]: ../art/character-vfx/AUI-34-pipeline-contract.md "AUI-34 operator contract"
[2]: ../plans/AUI-IMPLEMENTATION-STATUS.md "Current AUI-00 status and locks"
[3]: ../../staging/qa/character-vfx/aui-34/package2-receipt.json "Compact Package 2 QA receipt"
[4]: ../../staging/provenance/characters/aui-34/pipeline-contract.json "Character staging provenance"
[5]: ../../staging/provenance/vfx/aui-34/pipeline-contract.json "VFX staging provenance"
