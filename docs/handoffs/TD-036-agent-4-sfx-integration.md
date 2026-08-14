# TD-036 — Accepted SFX runtime integration

| Field | Value |
|---|---|
| Owner | AGENT 4 |
| Branch | `agent-4/sfx-integration` |
| Base | `bec1f32600074d6a119ea184837659662546caaf` |
| SFX implementation | `7790e03ee2f1f28439fb6cd034c3c2f4225e89c6` |
| Stale-locale oracle remediation | `55cff6d9cb24aa56c3277239c8b7670d06246bf4` |
| Reallocated closure | `98e2fa65e2fd40852b38648a289fc3c324bcf7fc` |
| First reconciled union | `768ed59b549c5bfa56c8eb112b26713e8896c087` over remote master `7228f0300e6c75b69c377b252a4e140ce6150e41` |
| Final reconciled union | `458e6deac139380b4d1c662003636b54c4251ba3` over remote master `1db9986ead0f4d9de8726f015783dfde172679b2` |
| Cache-independent fixes | helper registry `8e3b1fe`; damage feedback preload `d953165`; scratch import hardening `85c6d33` |
| Canonical cache/operator union | `8c4e41836e9d9cd54124acc6250af55c2aa36db1` over remote master `f885e9b37a4f1e6c5601b7a69931feb48a4a4879` |
| Verified candidate | `8c4e41836e9d9cd54124acc6250af55c2aa36db1` |
| Human verdict | Poseidon ACCEPT, all ten exact Batch 01 source hashes, 2026-08-14 |
| Branch STANDARD | PASS, 107 rungs and 70 headless/windowed scenario runs |
| Union STANDARD | PASS, 121 rungs and 80 headless/windowed scenario runs |
| Final STANDARD | PASS, 124 rungs and 82 headless/windowed scenario runs |
| Evidence | External `td036-final-standard-8c4e41836e9d9cd54124acc6250af55c2aa36db1/` |

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
| Reconciled union targeted proof | Focused SFX GUT 9/9; `sfx_playback`, `juice_deploy`, and stronger bilingual/world stale-registry probe PASS |
| Fresh union STANDARD | 121/121 rungs; 40 headless + 40 windowed scenarios; Training, native Sky Hunter, Act I V3, observations, stale-registry, music cold boot, bots, and gates PASS on `768ed59` |
| Final-union targeted proof | Focused SFX GUT 9/9; `sfx_playback`, `skill_timing`, `enemy_damage_feedback`, `juice_deploy`, Web filesystem twice, and stale registry twice PASS |
| Fresh final STANDARD | 124/124 rungs; 41 headless + 41 windowed scenarios; all prior surfaces plus enemy damage and font cold-cache PASS on `85c6d33` |
| Canonical-union targeted proof | SFX GUT 9/9; four affected scenarios; Web 150 checks/17 cases; font fallback; dual UI/promotion stale-cache oracle PASS |
| Fresh canonical-union STANDARD | 124/124 rungs; 41 headless + 41 windowed scenarios; all prior surfaces plus remaining operator animations and canonical cache-bootstrap work PASS on `8c4e418` |
| Candidate identity | clean worktree at `8c4e41836e9d9cd54124acc6250af55c2aa36db1` |

## Preserved reds and deviations

The first STANDARD attempt on `7790e03` remains preserved as RED. Godot exited 132 with `SIGILL` while the stale-registry probe imported its scratch current worktree. The crash reproduced once, then cleared and exposed the underlying base-master defect: the probe still required exactly `en-US` after TD-031 had canonically shipped `en-US` plus `zh-CN`. Untouched base `bec1f32` failed identically. Commit `55cff6d` strengthens the oracle to require the exact current two-locale set; it does not weaken the check or alter runtime localization. A fresh STANDARD from empty artifacts then passed all 107 rungs.

The generation fallback used `generate_video(generate_audio=true)` because built-in Mirelo was unavailable in the live catalog. Carrier videos and immutable extracted PCM evidence remain external; the game tree retains their prompt, manifest, QA, and hash bindings. No regeneration was performed during integration.

The first full union STANDARD attempt is also preserved as RED: Godot crashed in a worker thread during the Web filesystem probe's copied-project fresh import after 12 earlier rungs passed. The unchanged exact union then passed that isolated Web rung with 150 checks across 17 cases. A second full run from empty artifacts passed all 121 rungs. No game code, asset, test, threshold, or environment variable changed between the red and green attempts.

After TD-034 enemy-damage and font-cache work landed, the second union exposed two more truths. First, `EnemyDamageFeedback` referenced the newly introduced `EnemyAnimator` only through the global class cache; commit `d953165` replaces that runtime dependency with an explicit preload. Second, Godot 4.7.1 repeatedly crashed after otherwise-complete full-worktree scratch imports. Commit `85c6d33` keeps ordinary R2 import unchanged but runs only disposable scratch imports in recovery mode with an isolated serial-import editor profile. Both crash-prone probes passed twice before the 124-rung final STANDARD. All crash attempts remain preserved as RED.

## Merge and rollback

Remote master allocated TD-032/TD-033 during branch verification, TD-034 after the first union, and TD-035 after the cache-bootstrap diagnosis. This SFX lane is therefore TD-036 without any source, asset, or acceptance rewrite. Candidate `8c4e418` prefers remote's canonical cache fixes, preserves the stricter dual-cache probe and remaining operator animations, retains complementary scratch-import stabilization, and passed the full gate. Never force-push.

Rollback is `git revert` of the TD-036 integration commits after stopping gameplay. Reverting `7790e03` restores the silent SFX seam and removes all SFX runtime assets and triggers. Cache/bootstrap fixes now have canonical remote ownership and should be preserved independently of an SFX rollback.
