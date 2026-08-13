# TD-021 — Music stale-cache compile hardening

- **Agent / branch:** AGENT 4 / `agent-4/music-cold-cache-fix`
- **Frozen base:** `6a578856d1893030011c557716bbb930559fa681`
- **Audited implementation:** `234ae948d5afd589c76b3c8127e6e112373eb5c4`
- **Implementation tree:** `1163260daa351cabf55714d9dd5eb35419999daf`
- **Reconciled remote input:** `f84810578303d6599b4e5de89c407f9747d3812d`
- **Plan:** `docs/plans/TD-021-music-cold-cache-hardening.md`
- **Frozen RELEASE evidence:** external `session-state/agent4-td019/release-234ae948d5afd589c76b3c8127e6e112373eb5c4`
- **Independent audit:** external `session-state/agent4-td019/independent-audit.json` — PASS, zero findings, integrity verified

## Ticket reallocation

This lane began locally as TD-019. At final fetch, remote `master` already canonically contained TD-019 (AGENT 2 class display names) and TD-020 (AGENT D stale-class-registry startup repair). The integration owner preserved both stable histories and reallocated this complementary Music-specific hardening to TD-021.

## Delivered behavior

`Music` explicitly preloads `res://assets/music/music_catalog.gd`, stores the loaded catalog through built-in `Resource`, verifies exact script identity, requires a non-empty `Dictionary` of entries, and fails closed before controller mutation. No global `MusicCatalog` type/cast remains in the autoload.

The dedicated regression gate copies a valid imported cache, removes only the exact `MusicCatalog` registry block, proves an established `BattleModel` entry remains, launches the real project under a TERM/KILL watchdog, rejects timeout/nonzero exit/fatal parser-script-autoload text, and requires positive Music plus title-scene load proof. This closes Godot's exit-0-on-fatal-output trap.

All TD-017 runtime behavior remains unchanged: exactly one `AudioStreamPlayer`, duplicate logical ID as a successful no-op, hard replacement on ID change, invalid request with zero controller-state change, data-owned stage/boss routing, and stop on non-battle content.

## Reconciliation with TD-020

Remote TD-020 independently added a typed preload alias for Music and a broader stale-registry S1 probe covering both `MusicCatalog` and `StageArtTheme`. TD-021 preserves that probe and the StageArtTheme repair. On the overlapping Music seam, TD-021 retains the stricter audited implementation: explicit script resource identity, fail-closed entry validation, and a Music-only cache-deletion test that executes inside GUT.

## Frozen implementation evidence

- aggregate `scripts/verify.sh --full`: **76/76 rungs, ALL GREEN**
- GUT: **27 scripts, 192/192 tests, 25,153 assertions**
- stale-cache gate: **ALL GREEN**, no fatal parser/script/autoload text
- scenarios: **24 reports, 639 checks, zero failures, zero skips**
- fresh windowed evidence: **78 nonempty screenshots**
- music structural/integrity gate: **six cues, ALL GREEN**
- checksum manifest: **124/124 entries verified**
- independent non-implementer diff-vs-pins/evidence audit: **PASS, zero findings**

## Residual risks

1. Frozen execution evidence is from official Godot 4.7.1 on Linux rather than native macOS; the exact stale-registry condition from the report is exercised structurally.
2. A completely empty `.godot` cache still requires the established import-first bootstrap because unrelated older autoload classes remain registry-backed.
3. GUT emits three orphan and exit-time ObjectDB/resource-leak warnings, while all tests, assertions, and mandatory gates pass.

## Rollback

Revert the aggregate TD-021 integration commit. No music asset, catalog schema, stage data, save, replay, hash, or audio migration is required.
