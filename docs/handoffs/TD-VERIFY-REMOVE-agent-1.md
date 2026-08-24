# TD-VERIFY-REMOVE — Agent 1 Handoff

## Requested change

The user explicitly requested removal of the repository’s slow canonical aggregate verification workflow. On branch `agent-1/remove-verify-sh`, `scripts/verify.sh` has been deleted. No gameplay code, tests, balance data, thresholds, or other verification helpers were changed.

## Fast validation retained for this task

| Check | Command surface | Result |
|---|---|---|
| Engine | `/home/ubuntu/.local/bin/godot --version` | PASS — `4.7.2.stable.official.ed1daf0bf` |
| Project import | Direct headless `--import` | PASS; no parser, resource, or autoload failures in the error scan |
| Bounded game boot | Direct headless `--fixed-fps 60 --quit-after 120` | PASS |
| Deterministic gameplay | Direct `selftest/harness.gd --scenario=boot --seed=42` | PASS — 24 checks |
| Windowed rendering | Direct windowed `boot` scenario at 1280×720 | PASS — three fresh PNGs |
| Web export | Direct `--export-release Web` with matching 4.7.2 templates | PASS — HTML, JavaScript, WASM, and PCK present and hashed |
| Browser runtime | Chromium load plus keyboard transition from title into campaign staging | PASS; no console/runtime errors observed |

## Repository rules and artifacts flagged for owner review

| Location | Finding | Consequence after this change |
|---|---|---|
| `CLAUDE.md` | Declares `scripts/verify.sh` mandatory before every commit and `verify.sh --full` mandatory before completion. | This standing rule directly conflicts with the user-authorized deletion and is now stale. It was intentionally left unchanged so the owner can choose a replacement policy. |
| `CLAUDE.md` | Pins Godot 4.7.1 at `~/bin/godot`. | The Manus Game Studio project bootstrap is authoritative and pins Godot 4.7.2 at `~/.local/bin/godot`; this task used 4.7.2. |
| `scripts/probe_filesystem.sh` | Hard-fails unless the engine string matches `4.7.1.stable.official.*`. | The probe rejects the project-mandated 4.7.2 engine even though import, boot, scenario, export, and browser checks pass on 4.7.2. |
| Verification helper scripts | Multiple helpers default to `$HOME/bin/godot`. | They do not naturally discover the project-standard `~/.local/bin/godot`; callers must pass `GODOT` or the helpers should be normalized later. |
| `export_presets.cfg` | The preset’s default output is `../MGS docs/Prototype TD/prototype-td-web/index.html`. | This is a machine-specific legacy path. This task overrode the output path explicitly. |
| Repository-wide docs | 52 tracked files contain 104 references to `verify.sh`; 49 of those files are under `docs/`. | Those references are now historical or stale. Bulk rewriting was not performed because it would exceed the requested deletion and alter archived evidence. |
| Root process artifacts | `.claude/`, `.mcp.json`, `FEATURES.json`, `FINAL_REPORT.md`, `JUICE_VERDICT.md`, `PAINPOINTS.md`, and `PLAYTEST.md` are present. | These are agent/process governance and audit artifacts rather than runtime game files. They may be intentional, but they materially increase onboarding policy surface. |
| Historical documentation | `docs/plans` is about 176 KB, `docs/handoffs` about 232 KB, and `docs/media` about 444 KB. | The retained history is useful for audits but contains obsolete engine pins and verification commands that new agents may treat as current unless authority boundaries stay explicit. |

## Recommended follow-up decision

The owner should choose a replacement verification policy rather than silently letting the deleted script’s references persist as requirements. A lightweight option is to keep direct import, bounded boot, one deterministic scenario, and a Web browser smoke check as the normal loop, with focused GUT or bot checks selected only for affected systems. If that policy is accepted, update `CLAUDE.md`, `docs/README.md`, `docs/todo.md`, and active plan files in one dedicated cleanup lane while preserving historical handoffs and evidence verbatim.

