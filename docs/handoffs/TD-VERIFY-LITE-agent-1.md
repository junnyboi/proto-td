# TD-VERIFY-LITE — Agent 1 Handoff

## Outcome

The repository now uses `scripts/validate.sh` as its bounded, scope-aware validation entrypoint. The default path performs import, bounded boot, one focused GUT file, and one deterministic headless scenario. `--render` adds only the selected windowed scenario and fresh PNG requirement; `--web` adds only the release Web export plus required HTML, JavaScript, WASM, and PCK checksums.

## Policy matrix

| Change surface | Required baseline |
|---|---|
| Documentation or metadata | Default `scripts/validate.sh` plus `git diff --check` |
| Simulation, save, replay, or data | One focused GUT file, one affected scenario, and the relevant bounded domain helper |
| UI, input, layout, animation, or visual assets | Focused GUT and scenario with `--render`, followed by review of fresh PNGs |
| Web export or hosted browser runtime | Selected scenario with `--render --web`, then browser input and console/network checks |
| Audio | Focused catalog/player test, matching scenario, and the applicable audio verifier |

The full contract, failure conditions, engine resolution order, and integration rule are documented in `docs/validation.md` and linked from `CLAUDE.md` and `docs/README.md`.

## Reconciliation

Current policy, executable helpers, the AUI-34 Godot fallback backend, its differential verifier and version probe, the UI component engine metadata, and the Web baseline tool now target Godot `4.7.2.stable.official.ed1daf0bf`. Helper defaults use `~/.local/bin/godot`; the current Web preset writes to ignored `artifacts/web/index.html` rather than a user-specific external directory.

The final live-source audit found no `$HOME/bin/godot` default, no active 4.7.1 enforcement, and no active requirement to run the removed `verify.sh`. Exact old references remain in 51 files that record earlier verification evidence and in 189 files that record earlier engine provenance. Of the latter, 163 are immutable asset provenance sidecars. The remaining live provenance generator/schema mentions are explicitly labeled as the historical recipe identity required to validate those frozen v1 bytes.

## Validation evidence

| Check | Result |
|---|---|
| Shell syntax across `scripts/*.sh` | PASS |
| Changed Python compilation and JSON parsing | PASS |
| Default `scripts/validate.sh` | PASS in 16 seconds |
| Focused UI component validation | PASS — 11 tests |
| `scripts/validate.sh --render --web` | PASS in 47 seconds |
| Deterministic boot scenario | PASS — 24 checks, 3 fresh PNGs |
| Web bundle | PASS — nonempty HTML, JavaScript, WASM, and PCK with SHA-256 manifest |
| Native filesystem probe | PASS — 162 checks on Godot 4.7.2 |
| AUI-34 backend version probe | PASS — 40 checks |
| AUI-34 Python/Godot differential | PASS — 600 checks |
| Parser/resource/runtime error scan | PASS |

## Preserved history

Historical plans, handoffs, media manifests, `FEATURES.json`, `FINAL_REPORT.md`, asset provenance, staging provenance, and historical decision evidence were not rewritten. Their exact engine and command strings describe what ran at those commits and are now explicitly subordinate to the current authority map in `docs/README.md` and `docs/validation.md`.

## Implementation

The validated implementation is commit `5b18084603a1489763ac88d1e7b1ad48c87fd550` on `agent-1/lightweight-validation`.
