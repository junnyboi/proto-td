# AUI-11 Round 5 Production Packets

## Status and scope

AUI-11 emits seven deterministic, runtime-unbound production packets from Poseidon's exact Round 5 Agent E concept approval. The canonical batch manifest is `staging/character-vfx/aui-11/batch-manifest.json`; its packet records bind every master, native frame, strict spec, atlas, contact sheet, metadata sidecar, and QA sidecar by SHA-256 and byte length. The package does not modify `assets/manifest.tres`, runtime sprites, scenes, views, simulation, save/replay state, localization, thresholds, or `FEATURES.json`.

The concept approval authorizes deterministic production work but does not grant player-facing final-art acceptance. Every packet therefore records `human_final_art = UNSET_HUMAN_ONLY` and `runtime_binding = UNBOUND_AGENT_F_SEAM`, matching `docs/decisions/AUI-DESIGN-APPROVALS.md` and the AUI-34 boundary in `docs/art/character-vfx/AUI-34-pipeline-contract.md`.

## Packet inventory

| Logical packet | Domain | Native source | Canonical atlas | Intended seam |
| --- | --- | --- | --- | --- |
| `vanguard_1` | Operator | Eight 192×192 transparent frames | 768×384 RGBA | Operator animation binding |
| `portrait_vanguard_1` | Portrait | Eight 192×192 transparent frames | 768×384 RGBA | Portrait presentation binding |
| `grunt` | Enemy | Eight 192×192 transparent frames | 768×384 RGBA | Enemy walk/action binding |
| `grunt_charmed` | Charm derivative | Eight geometry-identical 192×192 frames | 768×384 RGBA | Eligible grunt Charm binding |
| `deploy` | VFX | Eight 128×128 transparent frames | 768×384 RGBA | Deployment event binding |
| `attack_hit` | VFX | Eight 128×128 transparent frames | 768×384 RGBA | Attack-hit event binding |
| `charm_vfx` | VFX | Eight 128×128 transparent frames | 768×384 RGBA | Charm transition binding |

The canonical packet outputs live under `staging/character-vfx/aui-11/packets/<logical_id>/`. GPT Image 2 production masters are retained under `masters/`; normalized native inputs are retained under `sources/`; and strict AUI-34 input contracts are retained under `specs/`.

## Deterministic backends and QA

Python 3.12.3 with Pillow 12.3.0 is the canonical emitter. Godot 4.7.1 is the independent fallback. Each backend built all seven packets twice from the repository-staged specs and sources. `dual-backend-bound-receipt.json` records per-run file SHA-256, decoded atlas/contact RGBA hashes, semantic metadata/QA hashes, source/spec hashes, and the final batch-manifest hash. The staged verifier reproduces all 28 builds in a disposable root and requires the regenerated receipt to match exactly. Same-backend packet bytes were exact and cross-backend decoded/semantic results matched. The repository-copy verifier executes 1,464 independent scope, manifest, hash, oracle-rerun, complete run-A/run-B dual-backend, provenance, alpha, border, reserved-color, loop, Charm, geometry, and open-center checks.

The visual gate inspected every atlas and contact sheet. Six packets passed immediately. The first `attack_hit` packet was rejected because a centered bilateral silhouette read as a four-point star flare; the replacement uses compact lower-left-to-upper-right slash/comet-shard frames and passed direct plus independent focused review. The red verdict is retained beside the final pass in `staging/qa/character-vfx/aui-11/visual-review-items/`.

## Verification entrypoint

Run the tracked staged-byte verifier from the repository root:

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B staging/qa/character-vfx/aui-11/verify_staged_packets.py \
  --project . \
  --report /tmp/aui11-staged-verification.json
```

A pass must report 1,464 executed checks. Missing files, changed bytes, malformed JSON, out-of-claim Git paths, altered approval hashes, cleared runtime/final-art barriers, stale or structurally incomplete provenance, wrong evidence locators, unbound oracle artifacts, any dual-run mismatch, reserved probe colors, blank or clipped cells, exact adjacent duplicates, weak loop boundaries, Charm geometry/cue drift, out-of-range VFX geometry, closed deploy/Charm centers, or cross-backend hash drift is red.

To reproduce one canonical packet into a disposable directory, use the tracked AUI-34 CLI and the packet's staged spec/source pair:

```bash
python3 -B tools/art_pipeline/character_vfx/normalize.py build \
  --spec staging/character-vfx/aui-11/specs/vanguard_1.json \
  --input-root staging/character-vfx/aui-11/sources/vanguard_1 \
  --output /tmp/aui11-vanguard-1 \
  --clean
```

The equivalent Godot command and full backend contract remain documented in `docs/art/character-vfx/AUI-34-pipeline-contract.md`.

## Charm contract

`grunt_charmed` is derived only after the normalized base grunt atlas is accepted. `staging/qa/character-vfx/aui-11/charm-grunt-v1-contract.json` freezes the fixed palette and region transforms. `charm_expected_oracle.py` independently computes expected frame hashes; `build_charm_sources.py` must match those hashes. `verify_charm_semantics.py` separately requires both light and dark binding bands in shoulder and ankle regions, left/right tabs, a five-pixel knot, unchanged alpha, and pinned grayscale separations in every frame. The staged verifier reruns that oracle and reproduces `charm-semantic-verification.json` exactly.

## Attack-hit transformation chain

The pre-compression directional frames are retained under `staging/qa/character-vfx/aui-11/attack-hit-pretransform/`, not under the final source path. `attack-hit-transform-v1-contract.json` freezes vertical compression, loop closure, the frame-6 interior densification, and reserved-token remapping. `verify_attack_hit_transform.py` reconstructs all eight final sources independently and must reproduce the tracked final file and decoded-RGBA hashes recorded by `attack-hit-transform-receipt.json`.

## Provenance and legal state

Domain records are stored at `staging/provenance/characters/aui-11/batch-provenance.json` and `staging/provenance/vfx/aui-11/batch-provenance.json`. They bind the approved concepts, GPT Image 2 generation route, rembg model hashes, deterministic normalizer files, QA receipts, and project-owned license state. Provider generation IDs and stable seeds are unavailable and are represented as null rather than invented.

## Downstream integration boundary

Agent F remains the named serial integrator in the frozen AUI-11 contract. The terminal Agent E lane may be composed only as `B + terminal AUI-11 lane`, followed by one fresh exact-union RELEASE and non-implementer audit. Runtime ingestion must adapt these staged packets to manifest-v2 and event-binding contracts without changing visual semantics. Player-facing final-art acceptance must use fresh exact-candidate in-game frames; packet contact sheets alone cannot clear `human_final_art`.
