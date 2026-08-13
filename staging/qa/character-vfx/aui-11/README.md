# AUI-11 QA Package

This directory binds the seven runtime-unbound AUI-11 production packets to deterministic checks, independent semantic oracles, provenance validation, Git-scope enforcement, and visual review.

| Artifact | Purpose |
| --- | --- |
| `verify_staged_packets.py` | 1,854-check repository-staged verifier that rebuilds all 28 backend runs and validates exact claim scope and provenance |
| `staged-verification.json` | Stable current staged-byte receipt |
| `verify_dual_backend_packets.py` | Fresh two-run Python/Godot builder and cryptographic differential |
| `dual-backend-bound-receipt.json` | Per-run files/RGBA/semantic hashes, source/spec hashes, and final manifest binding |
| `attack-hit-transform-v2-contract.json` | Frozen target-lozenge dilation, compression, closure, and token-remap transform |
| `attack-hit-pretransform/` | Eight immutable pre-transform target-lozenge source frames |
| `verify_attack_hit_transform.py` | Independent generic final-source reconstruction oracle used by both VFX transforms |
| `attack-hit-transform-receipt.json` | Eight-input/eight-output attack transformation hash chain |
| `charm-vfx-transform-v1-contract.json` | Frozen Charm facet-fit, protected-center, frame-6 chip, and closure transform |
| `charm-vfx-pretransform/` | Eight immutable pre-transform Charm source frames |
| `charm-vfx-transform-receipt.json` | Eight-input/eight-output Charm VFX transformation hash chain |
| `attack-hit-v2-visual-audit.json` / `charm-vfx-r4-visual-audit.json` | Independent exact-candidate visual/numeric PASS records |
| `charm-grunt-v1-contract.json` | Frozen geometry-preserving Charm transform |
| `charm_expected_oracle.py` | Independent expected-hash generator |
| `build_charm_sources.py` | Production Charm transformer checked against the expected oracle |
| `verify_charm_semantics.py` | Independent binding/tab/knot/alpha/grayscale cue oracle |
| `charm-semantic-verification.json` | Per-frame redundant-cue measurements and artifact bindings |
| `grunt-loop-closure.json` | Preserved two-row recovery closure after the unchanged 0.92 loop floor rejected both predecessor rows |
| `grunt-base-highlight-reduction.json` | Geometry-preserving base-material cleanup that cleared the final 8/10 blind Charm-state gate |
| `named-review-verification.json` | Reproduced 10/10 Vanguard, 9/10 grunt, 8/10 Charm, and seven-packet originality receipt |
| `final-packet-visual-review.md` | Seven-packet visual verdict summary |
| `visual-review-items/06-attack_hit.md` | Preserved first attack-hit red verdict |
| `visual-review-items/06-attack_hit-r2.md` | Superseded directional-slash verdict retained in rejection history |
| `generation-ledger.md` | Generation, rejection, extraction, and runtime-boundary provenance |

Run from repository root:

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B staging/qa/character-vfx/aui-11/verify_staged_packets.py \
  --project . \
  --report /tmp/aui11-staged-verification.json
```

A pass reports exactly 1,854 checks. The tracked receipt is evidence for these exact staged bytes, not for a later runtime union. Its stable SHA-256 is `2f807bd34e193815d1efc85a6020213e5fe16c8ab0394708a06d5609a83d22d0`. Runtime binding and human-final art remain unset.
