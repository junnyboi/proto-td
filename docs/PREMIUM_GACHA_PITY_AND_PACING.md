# Premium Resonance: Five-Star Pity, Reveal, and Marks Pacing

**Status:** implemented
**Author:** Manus AI
**Applies to:** campaign save v3, Premium Resonance, Company Command, mission resolution

## Product contract

Premium Resonance uses a three-hero Lunaris pool. **Lunaris Vessel is the pool’s 5-star hero**; Archive Caster and Reliquary Duelist are 4-star heroes. Each pull still grants exactly one life to the selected hero, including the first copy. Rarity changes selection odds and reveal treatment, not the existing life, death, revival, or fixed-kit rules.[1]

| Hero | Rarity | Natural weight | Natural probability |
|---|---:|---:|---:|
| Lunaris Vessel | 5-star | 2 | 5.0% |
| Archive Caster | 4-star | 19 | 47.5% |
| Reliquary Duelist | 4-star | 19 | 47.5% |

Every pull that does not produce a 5-star increments `premium_pity_streak`. Any 5-star pull resets the streak to `0`. When the streak is `9`, the next pull is **forced to the 5-star sub-pool**, guaranteeing at least one 5-star within every ten pity-eligible pulls. The forced pull uses the same deterministic seed path as an ordinary pull and does not consume an additional random draw.

With a 5% natural rate and hard pity at pull 10, the mean interval is approximately **8.03 pulls per 5-star**. The tenth-pull outcome contains the probability mass for all runs that missed the first nine natural checks; the guarantee therefore remains meaningful while early acquisition remains possible.

## Save and replay model

The canonical core gains `premium_pity_streak` and `premium_pity_started_at_pull`. Fresh campaigns initialize both to `0`. Existing premium-aware saves migrate with `premium_pity_started_at_pull = next_premium_pull_index` and `premium_pity_streak = 0`, so they receive a full ten-pull guarantee window after upgrade without retroactively changing already committed pulls.

`premium_pity_started_at_pull` is immutable after migration. Command-history validation seeds its fresh replay baseline from the candidate save, so pre-upgrade pulls remain outside pity eligibility and replay byte-for-byte. Legacy pre-premium saves migrate with both values at `0`.

| Receipt field | Meaning |
|---|---|
| `rarity` | Selected hero rarity, currently `4` or `5` |
| `five_star` | Convenience boolean derived from rarity |
| `pity_before` | Consecutive eligible non-5-star pulls before this pull |
| `pity_after` | `0` after a 5-star, otherwise `pity_before + 1` |
| `pity_forced` | Whether the hard guarantee constrained this pull to the 5-star sub-pool |
| `guarantee_in_after` | Pulls remaining until the hard guarantee, from `1` to `10` |

Duplicate-command reconstruction, canonical receipts, events, projections, and command-history replay must expose the same values. UI animation reads committed receipt data and never decides rarity or pity locally.[2]

## Marks pacing

The pull price remains **40 Marks** and starting funds remain **120 Marks**, preserving three opening pulls. Every campaign stage grants **40 Marks on first clear only**. Existing first-clear gating prevents reward farming on replay.[3]

| Progress | Lifetime Marks available | Lifetime pulls funded | Pacing purpose |
|---|---:|---:|---|
| Campaign start | 120 | 3 | Establish the premium roster immediately |
| After Stage 1 | 160 | 4 | First post-mission reinforcement |
| After Stage 4 | 280 | 7 | Sustain mid-campaign losses without trivializing them |
| After Stage 7 | 400 | 10 | Guarantee a 5-star before the final operation if all earned Marks are spent |
| After Stage 8 | 440 | 11 | Provide one post-campaign reserve life |

Currency rewards use `{ "kind": "currency", "id": "marks", "amount": 40 }` in `v3_stage_rewards`. Resolution receipts continue to record `marks_before` and `marks_after`; history validation proves that their delta equals the first-clear currency rewards and remains zero on repeat clears.

## Reveal sequence

The reveal is a skippable presentation state that begins only after the pull command commits successfully. The screen locks Back and Pull input until the final state is applied, while one explicit **SKIP** action remains available. Scene exit kills all active tweens safely.

| Beat | Duration | Presentation |
|---|---:|---|
| Signal lock | 0.18 s | Existing content dims; cyan reticle and circular filaments converge |
| Rarity charge | 0.38 s | Four cyan stars ignite; a fifth gold star ignites only for a 5-star |
| Hero reveal | 0.32 s | Selected portrait rises from 96% scale with light sweep and rarity frame |
| Result settle | 0.24 s | Callsign, `NEW HERO` / `LIFE +1` / `REVIVED`, lives, and pity result settle into place |

Four-star reveals use cyan, indigo, and silver. Five-star reveals use gold-white, a stronger bloom, five-point starburst lines, and a distinct `5-STAR RESONANCE` title. Forced pity adds a compact `GUARANTEE FULFILLED` badge. No flashing cadence exceeds three changes per second, motion uses opacity and transform, and the final information remains readable without color.

The reveal can be skipped by the visible button, confirm/cancel input, or a second pull action. Reduced-motion mode bypasses rotation, scale overshoot, and filament motion, using a short opacity transition before the same final result. Skipping never changes committed gameplay state and always restores focus to the Pull button.

## Player-facing information

The gacha screen displays `5-star base rate 5% • guaranteed within 10 pulls`, a ten-segment pity meter, and `5-star guaranteed in N pulls`. Premium cards show their rarity above the fixed class. After a pull, the final reveal displays the updated guarantee distance. Campaign and results UI display first-clear Marks awards alongside existing unlocks.

## Acceptance gates

The implementation is complete only when deterministic tests prove natural 5-star reset, forced tenth-pull selection, migration activation boundaries, command replay, duplicate-command idempotency, exactly 40 first-clear Marks per stage, zero Marks on repeat clear, reveal input locking, skip finalization, and reduced-motion finalization. Native visual checks must pass at 1280×720 and 720×1280, followed by a matching Godot 4.7.2 Web export with clean browser network and console logs.

## Implementation record

The delivered simulation extends the canonical campaign core, save migration, strategic hash compatibility, command receipt grammar, command replay, premium selection, battle resolution, and presentation projection. `premium_marks_started_at_resolution` activates the new first-clear currency rewards at the migration boundary so historical resolutions remain byte-compatible while all future first clears receive the tuned payout.

| Validation | Result |
|---|---|
| Godot engine | `4.7.2.stable.official.ed1daf0bf` |
| Headless import | Pass |
| Premium lifecycle regression | Pass |
| Pity, migration, and economy regression | Pass |
| Gacha reveal UI regression | Pass |
| Bounded 120-frame boot | Pass |
| Desktop native QA | Pass at 1280×720 |
| Portrait native QA | Pass at 720×1280 |
| Godot Web export | Pass from final master commit `0eeece4` |
| Live Web pull | Pass: 40 Marks consumed, hero/life granted, pity advanced |
| Web console/network | Pass: final PCK and WASM HTTP 200; no post-load console errors |
| Published preview | Checkpoint `ab19a0a3` |

The automated pity suite verifies the authored 2/40 five-star weight, a forced five-star on the tenth eligible pull after nine misses, natural five-star reset, pre-pity migration activation, 320 total first-clear Marks, 440 lifetime Marks including starting funds, exactly 11 funded pulls, and zero repeat-clear currency rewards. The reveal suite verifies the ten-segment meter, rarity cards, input lock, visible skip action, final result copy, and reduced-motion final state.

## References

[1]: ../sim/campaign_v3_gacha.gd "Current premium pull and life-grant authority"
[2]: ../sim/campaign_v3_command_codec.gd "Canonical command receipt contract"
[3]: ../sim/campaign_v3_attempts.gd "First-clear reward authority and replay-farming prevention"
