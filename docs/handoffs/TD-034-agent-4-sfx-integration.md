# TD-034 — Accepted SFX runtime integration

| Field | Value |
|---|---|
| Owner | AGENT 4 |
| Branch | `agent-4/sfx-integration` |
| Base | `bec1f32600074d6a119ea184837659662546caaf` |
| SFX implementation | `7790e03ee2f1f28439fb6cd034c3c2f4225e89c6` |
| Stale-locale oracle remediation | `55cff6d9cb24aa56c3277239c8b7670d06246bf4` |
| Verified candidate | `55cff6d9cb24aa56c3277239c8b7670d06246bf4` |
| Human verdict | Poseidon ACCEPT, all ten exact Batch 01 source hashes, 2026-08-14 |
| STANDARD | PASS, 107 rungs and 70 headless/windowed scenario runs |
| Evidence | External `td032-standard-55cff6d9cb24aa56c3277239c8b7670d06246bf4/` |

## Outcome

Protos now plays the ten accepted generated effects through the existing global `Sfx.play(raw_id)` seam. `Sfx` is the sole sound-effect owner, resolves a closed catalog and alias map, emits the raw `sfx_played` telemetry event on every logical call, deduplicates only the audio side effect to one semantic cue per render frame, and reuses exactly eight `AudioStreamPlayer` voices. Unknown IDs remain telemetry-only and cause zero controller-state change. Music ownership and one-player music behavior are unchanged.

The direct accepted UI cues are operator selection, ability ready, action rejection, general UI click, and placement ready. Existing presentation events map `leak→base_breach` and `trap_snap→trap_trigger`; `deploy`, `victory`, and `defeat` remain direct. The deploy adapter owns selection, valid placement, and rejected-action feedback. `BattleView` owns a false-to-true skill-readiness edge, so held ready state never repeats the cue. No simulation, hash, save, replay, balance, localization, or settings state changed.

## Asset and provenance contract

All ten Poseidon-accepted 48 kHz stereo 24-bit PCM candidates are immutable under `assets/sfx/sources/*.wav.source` and retain their exact source hashes in `human-acceptance.json`, `catalog.tres`, and `provenance.json`. Godot 4.7.1 rejected the 24-bit WAV container during a clean import. The deterministic `derive_runtime_wav.sh` therefore produces separate 48 kHz stereo 16-bit PCM WAVs without timing, gain, channel, or semantic edits. Runtime imports are pinned uncompressed, runtime hashes are distinct from accepted-source hashes, and the derivation is byte-idempotent. Provider terms remain a release-time verification obligation.

## Verification

| Check | Result |
|---|---|
| Clean pre-change baseline | `juice_deploy` PASS on `bec1f32` |
| Focused catalog/player GUT | 9/9 tests, 198 assertions PASS |
| Focused runtime scenario | `sfx_playback` PASS with completion sentinel |
| Existing deployment scenario | `juice_deploy` PASS after integration |
| Asset integrity | 10 immutable accepted masters, 10 runtime WAVs, 10 uncompressed imports, exact source/runtime hashes, idempotent derivation |
| FAST | 48/48 rungs, including 35 headless scenarios, PASS on implementation tree |
| Fresh STANDARD | 107/107 rungs; 35 headless + 35 windowed scenarios; stale-registry, music cold boot, bots, and gates PASS on `55cff6d` |
| Candidate identity | clean worktree at `55cff6d9cb24aa56c3277239c8b7670d06246bf4` |

## Preserved reds and deviations

The first STANDARD attempt on `7790e03` remains preserved as RED. Godot exited 132 with `SIGILL` while the stale-registry probe imported its scratch current worktree. The crash reproduced once, then cleared and exposed the underlying base-master defect: the probe still required exactly `en-US` after TD-031 had canonically shipped `en-US` plus `zh-CN`. Untouched base `bec1f32` failed identically. Commit `55cff6d` strengthens the oracle to require the exact current two-locale set; it does not weaken the check or alter runtime localization. A fresh STANDARD from empty artifacts then passed all 107 rungs.

The generation fallback used `generate_video(generate_audio=true)` because built-in Mirelo was unavailable in the live catalog. Carrier videos and immutable extracted PCM evidence remain external; the game tree retains their prompt, manifest, QA, and hash bindings. No regeneration was performed during integration.

## Merge and rollback

Remote master allocated TD-032 and TD-033 while this lane was verifying, so this completed lane was reallocated to TD-034 without changing code or acceptance. Merge `origin/master` into this branch, preserve concurrent Training, native Sky Hunter, observation, world-art, and stale-cache work, resolve shared ledgers semantically, run the exact union gate, and push normally. Never force-push. Fast-forward local and remote master only from the verified branch union, then run the final master gate.

Rollback is `git revert` of the TD-034 integration commits after stopping gameplay. Reverting `7790e03` restores the silent SFX seam and removes all SFX runtime assets and triggers. The locale oracle change in `55cff6d` was independently superseded by remote master commit `c7f65d0`; preserve the remote implementation unless the product locale set is intentionally rolled back.
