# AUI-20 Representative 192 px Fixture Authorization

- **Decision owner:** Poseidon
- **Effective:** 2026-08-13
- **State:** authorized for plan and exact-candidate review; runtime binding not yet approved
- **Effective base:** `f4827f6ec255b502a1d17ef4642eda295ac162c8`
- **Effective tree:** `e62040acfd7c9998c80edb0e318d2c5425688001`

## Decision

Independent AUI-20 plan preflight 01 returned FAIL because the claimed package had no available 192 px operator/enemy runtime packet and no legal source-fixture owner. Implementation remained blocked. Poseidon then explicitly authorized Agent F to create one narrow, representative 192 px operator/enemy packet for AUI-20.

The authorization grants ownership only of the additive AUI-20 fixture atlas, manifest, provenance, test, and decision paths enumerated in `docs/todo.md`. It does not transfer AUI-11, Agent E, approved Round-5, or production roster ownership.

## Source boundary

Current master contains the human-final Round-5 source/runtime binding accepted at `441cb80b079ee89195ef751dbc26e67b426600d0`. `docs/decisions/AUI-ROUND5-RUNTIME-BINDING.md` has SHA-256 `ea503dba5c14b9b966d18d3dda6e0325b0d1b28aed540401311bf23b89a04f4e`.

The representative packet must be newly named and additive. It may reference approved Round-5 source sheets and runtime identities by exact hash, but it may not modify or overwrite those bytes, their existing logical IDs, manifests, provenance, or acceptance state. The shared `docs/decisions/AUI-DESIGN-APPROVALS.md` is itself frozen as a Round-5 provenance source and must remain byte-identical.

## Human gate

Machine conformance is not human acceptance. Each 768x384 atlas and its contact sheet remain review-pending until Poseidon approves their exact hashes. Only after that approval and an independent plan-lint PASS may non-rewriting branch `agent-f/aui-20` bind the packet through the AUI-20-only fixture manifest.

## Required plan correction

The revised external package plan must close every preflight-01 finding, including exact current-master derivation, executable route and dense-state fixture contracts, fail-closed Web metrics, complete test/report/event/evidence schemas, and reproducible generation/provenance. A fresh independent PASS is mandatory before implementation.
