# AUI-11 QA Package

This directory binds the seven runtime-unbound AUI-11 production packets to deterministic checks, independent semantic oracles, provenance validation, Git-scope enforcement, and visual review.

| Artifact | Purpose |
| --- | --- |
| `verify_staged_packets.py` | 1,464-check repository-staged verifier that rebuilds all 28 backend runs and validates exact claim scope and provenance |
| `staged-verification.json` | Stable current staged-byte receipt |
| `verify_dual_backend_packets.py` | Fresh two-run Python/Godot builder and cryptographic differential |
| `dual-backend-bound-receipt.json` | Per-run files/RGBA/semantic hashes, source/spec hashes, and final manifest binding |
| `attack-hit-transform-v1-contract.json` | Frozen compression, closure, densification, and token-remap transform |
| `attack-hit-pretransform/` | Eight immutable pre-compression directional source frames |
| `verify_attack_hit_transform.py` | Independent final-source reconstruction oracle |
| `attack-hit-transform-receipt.json` | Eight-input/eight-output attack transformation hash chain |
| `charm-grunt-v1-contract.json` | Frozen geometry-preserving Charm transform |
| `charm_expected_oracle.py` | Independent expected-hash generator |
| `build_charm_sources.py` | Production Charm transformer checked against the expected oracle |
| `verify_charm_semantics.py` | Independent binding/tab/knot/alpha/grayscale cue oracle |
| `charm-semantic-verification.json` | Per-frame redundant-cue measurements and artifact bindings |
| `final-packet-visual-review.md` | Seven-packet visual verdict summary |
| `visual-review-items/06-attack_hit.md` | Preserved first attack-hit red verdict |
| `visual-review-items/06-attack_hit-r2.md` | Corrected directional-slash pass |
| `generation-ledger.md` | Generation, rejection, extraction, and runtime-boundary provenance |

Run from repository root:

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B staging/qa/character-vfx/aui-11/verify_staged_packets.py \
  --project . \
  --report /tmp/aui11-staged-verification.json
```

A pass reports exactly 1,464 checks. The tracked receipt is evidence for these exact staged bytes, not for a later runtime union. Runtime binding and human-final art remain unset.
