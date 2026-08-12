# Collaboration Media Policy

Store only small, durable collaboration evidence or references that materially help another agent reproduce a decision. Generated game assets belong in the manifest-driven asset pipeline; large images, audio, video, Web bundles, and transient runtime artifacts remain outside Git unless a plan explicitly requires a compact baseline.

- Evidence identifies the candidate commit, command, run date, and originating scenario or gate.
- Screenshots come from the run just executed; never reuse or hand-craft evidence.
- Prefer handoff links to `artifacts/` outputs or committed baselines instead of duplicating files.
- Never commit credentials, tokens, signed URLs, local caches, `.godot/`, or unrelated binary output.
- For intentionally committed player-facing media, record source, license, generation prompt, transformations, placeholder/final state, and human contribution.
- Delete superseded scratch media; preserve historical decisions through Git and decision records.
