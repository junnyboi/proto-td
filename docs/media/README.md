# Collaboration Media Policy

This directory stores only small, durable collaboration evidence or references that materially help another agent reproduce a decision. Generated game assets belong in their existing manifest-driven asset pipeline, and large runtime artifacts remain outside Git unless a plan explicitly requires a compact baseline.

Rules:

- Evidence must identify the candidate commit, command, run date, and originating scenario or gate.
- Screenshots must come from the run just executed; never reuse or hand-craft evidence.
- Prefer links from handoffs to `artifacts/` run outputs or committed baselines instead of duplicating files.
- Do not commit credentials, private tokens, signed URLs, local caches, `.godot/`, or unrelated binary output.
- Record source, license, generation prompt, transformations, placeholder/final state, and human contribution for any player-facing media that is intentionally committed.
- Delete superseded scratch media rather than accumulating ambiguous evidence; preserve historical decisions through Git and decision records.
