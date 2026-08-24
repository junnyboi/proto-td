# Premium Hero and Gacha System

## Purpose

The campaign currently treats every recruited person as a trainable procedural recruit with permanent death. This implementation adds a distinct **premium hero** lifecycle without weakening the existing recruit rules. Premium heroes are fixed named identities drawn from a deterministic gacha pool. They cannot gain XP or enter the training/promotion graph. Every successful pull grants exactly one usable life to the selected premium hero; a duplicate pull adds another life to the same persistent hero rather than creating a second roster entry.

> A premium life is a deployable reserve for one battle fall. When a premium hero falls, exactly one life is consumed. The hero remains ready while at least one life remains. At zero lives, the hero is locked out and enters the memorial until another pull restores one life.

The first production pool is the three-character **Lunaris Reliquary** launch ensemble. The art and character contracts live in [`lunaris-reliquary/`](lunaris-reliquary/).

## Player-facing rules

| Rule | Contract |
|---|---|
| Pull cost | One pull costs **40 Marks**. Pulling is disabled while a battle attempt is unresolved or when the campaign has fewer than 40 Marks. |
| Pull outcome | Every accepted pull awards one life to exactly one hero from the three-entry Lunaris pool. There are no empty or non-hero results. |
| First copy | The first pull creates one persistent premium roster hero with one life and its fixed class, combat kit, portrait, callsign, and weapon identity. |
| Duplicate | A later pull of the same premium identity increments that hero's remaining lives and pull count. It never creates a duplicate roster row. |
| Revival | Pulling a zero-life premium hero grants one life, changes the hero back to `ready`, clears the terminal death record, and removes the memorial entry. |
| Battle fall | A premium fall consumes one life. If lives remain, the hero returns ready after resolution. If the consumed life was the last one, the hero becomes `dead`, is added to the memorial, and cannot deploy. |
| Training | Premium heroes never gain campaign XP and cannot be promoted. Training UI may show them for context but must explicitly label them `PREMIUM / FIXED KIT`. |
| Deployment | Only heroes with `life_status == ready` may enter a battle ticket. For premium heroes, normalization additionally requires `premium_lives > 0` whenever ready. |
| Ordinary recruits | Existing recruitment, XP, promotion, death, replacement, recovery, memorial, and save behavior remains unchanged. |

## Launch pool

The first pool reuses proven combat kits and sprite families while assigning unique premium identities and portraits. This avoids altering the deterministic battle engine while the character-specific animation pipeline is still in production.

| Premium ID | Display callsign | Fixed class | Battle operator | Visual identity |
|---|---|---|---|---|
| `lunaris_vessel` | **Lunaris Vessel** | `sorcerer` | `caster_2` | Champagne-blond flagship heroine with Crescent Reliquary |
| `reliquary_duelist` | **Reliquary Duelist** | `sword_saint` | `guard_2` | Black-ponytail spellblade hero with Jade Meridian |
| `archive_caster` | **Archive Caster** | `mage_apprentice` | `caster_1` | Silver-lilac ritual caster with Archive Astrolabe |

The persistent premium identity is not inferred from the reusable battle operator. `premium_id` is the stable collectible key; `operator_def_id` remains the deterministic battle projection.

## Canonical data model

Every hero row gains four append-only fields so the schema remains uniform and easy to validate.

| Field | Ordinary recruit | Premium hero |
|---|---:|---:|
| `hero_kind` | `recruit` | `premium` |
| `premium_id` | `null` | Stable pool ID |
| `premium_lives` | `0` | Integer from `0` through `999` |
| `premium_pull_count` | `0` | Integer from `1` through `999` |

The campaign core gains `next_premium_pull_index`. Fresh and migrated campaigns start at `0`; each accepted pull increments it exactly once. The index is part of the strategic hash, making the draw stream replayable and independent of engine-global random state.

The campaign definition gains `premium_pull_cost` and `premium_hero_rows`. Each authored pool row contains `premium_id`, `class_id`, `operator_def_id`, `portrait_asset_id`, `callsign`, and `weight`. Version one uses equal weights of `1` for all three heroes, but weighted validation is present from the beginning.

## Deterministic draw algorithm

The draw does not call Godot's global RNG. It derives a 64-bit value by applying the existing SplitMix64 helper to the campaign seed, generation, pull index, and a dedicated premium-pull domain constant. The non-negative unsigned remainder selects a weighted pool slot. Given the same canonical pre-state and command payload, command-history replay always produces the same hero.

The command verb is `pull_premium_hero` with an empty canonical payload. Its persisted receipt contains the pull index, premium ID, persistent hero ID, whether this was the first copy, lives before and after, pull count after, Marks before and after, and save revision. Duplicate command IDs remain idempotent through the existing command ledger.

## Resolution semantics

Battle resolution adds `premium_life_losses`, sorted by hero ID. Each row records `hero_id`, `premium_id`, `lives_before`, `lives_after`, and `locked_out`. `dead_hero_ids` and `memorial_ids` remain reserved for terminal lockouts and ordinary permanent deaths. This distinction lets the Results UI communicate a consumed reserve without falsely presenting every premium fall as permanent death.

The resolution-history validator proves that ordinary heroes follow the unchanged `ready -> dead` transition, while premium heroes follow exactly one of two legal transitions: `ready / N -> ready / N-1` when `N-1 > 0`, or `ready / 1 -> dead / 0` with a matching death record and memorial entry. Premium XP remains unchanged and no premium hero appears in `xp_awards`.

## Migration strategy

Current version-3 campaign files use the older data and hero key sets. The decoder recognizes those exact canonical key shapes, verifies their original checksum, and upgrades them deterministically by adding `next_premium_pull_index = 0` plus recruit defaults for the four new hero fields. It upgrades resolution anchors and the last resolution by adding an empty `premium_life_losses` list. Existing command receipts are preserved and continue to replay against a fresh state whose ordinary starter rows carry the same default premium fields.

No existing recruit is converted into a premium hero. Existing marks, progression, deaths, memorials, tickets, offers, and identities remain unchanged.

## UI flow

The existing locked **Recruit** operation on Company Command becomes the enabled **Premium Resonance** entry. The dedicated screen uses the current Lunaris premium UI language and provides:

| Region | Content |
|---|---|
| Header | Pool title, current Marks, 40-Mark pull cost, and return-to-command action |
| Hero gallery | Three adult Lunaris cards with portrait, fixed class, owned/unowned state, lives, and pull count |
| Pull stage | A prominent `RESONATE • 40 MARKS` action, deterministic result reveal, and explicit `SIGNAL ACQUIRED`, `DUPLICATE RESONANCE`, or `RESONANCE RESTORED` outcome |
| Rule panel | `PREMIUM HEROES DO NOT TRAIN` and `A FALL CONSUMES 1 LIFE` reminders |
| Locked state | Insufficient Marks and pending-battle states disable the pull action with an exact reason |

Squad selection adds a compact premium life marker to premium hero cards. Training projections expose premium status and remaining lives, but promotion eligibility returns `premium_hero_untrainable`; premium heroes never increase the eligible training count.

## Implementation sequence

| Order | Work package | Completion gate |
|---:|---|---|
| 1 | Extend campaign definition, state keys, hero grammar, fresh state, and legacy-v3 migration. | Fresh and old-shape saves normalize to the same canonical premium-aware schema. |
| 2 | Add deterministic pull selection, first-copy creation, duplicate life increment, zero-life revival, receipt normalization, and command replay. | Pulls are idempotent, cost exactly 40 Marks, and replay to byte-identical state. |
| 3 | Extend battle resolution, history proof, result projection, and event reporting for life loss versus terminal lockout. | Multiple-life falls stay ready; last-life falls enter memorial; ordinary deaths are unchanged. |
| 4 | Enforce non-trainability and exclude premium heroes from XP. | Premium promotion attempts reject authoritatively and UI eligibility excludes them. |
| 5 | Add runtime projections, gacha screen, Company Command route, squad life badges, result copy, and localization entries. | Pull, duplicate, revival, and lockout are understandable in desktop and portrait layouts. |
| 6 | Move all Lunaris hero concept assets into `docs/lunaris-reliquary/` and repair links/checksums. | No canonical generated Lunaris hero sheet remains under the old path. |
| 7 | Add deterministic model tests plus migration, command-history, death, deployment, training, and UI smoke coverage. | Focused suite, headless import, bounded boot, and windowed navigation all pass. |
| 8 | Re-fetch `origin/master`, reconcile concurrent work semantically, rerun the full validation pipeline, push directly to `master`, and refresh the existing Web preview. | Remote master and playable preview contain the same validated implementation. |

## Acceptance criteria

A fresh campaign can pull each premium hero, and every accepted pull changes exactly one premium hero by exactly one life while charging exactly 40 Marks. Pulling an owned hero does not increase roster size. Pulling a locked hero revives that same persistent hero. A premium hero with two lives survives one fall with one life; a premium hero with one life locks at zero, cannot deploy, and appears in the memorial; a later duplicate pull revives the hero and removes that memorial. Premium heroes gain no XP and all promotion paths reject them. Existing recruits still train, gain XP, die permanently, and use recovery/replacement rules unchanged. Existing canonical v3 saves migrate without loss. All state, receipt, hash, and command-history validators accept the resulting documents.

## Implemented result

The implementation sequence above is complete. The production campaign now contains the three-entry Lunaris pool, a 40-Mark deterministic pull command, persistent premium identities, stored lives, fixed non-trainable kits, premium-aware resolution receipts, zero-life deployment lockout, memorial integration, and duplicate-pull revival. Company Command routes the enabled **Premium Resonance** tile to the dedicated gacha scene, while squad, training, and results screens project premium state without becoming gameplay authorities.

| Validation gate | Final result |
|---|---|
| Legacy v3 migration | Passed with original checksum verification and premium defaults |
| Deterministic pull and command replay | Passed, including duplicate-command idempotency |
| Multi-life fall and terminal lockout | Passed |
| XP and training exclusion | Passed |
| Memorial creation and repeat-pull revival | Passed |
| Active-campaign gacha UI smoke | Passed with three cards and three runtime portraits |
| Native visual QA | Passed at 1280×720 and 720×1280 |
| Godot import and bounded 120-frame boot | Passed with Godot `4.7.2.stable.official.ed1daf0bf` |
| Concurrent master integration | Passed together with staging-fidelity, title-audio, and isometric-map changes |

The permanent focused regressions are `tests/premium_hero_system_test.gd` and `tests/premium_gacha_ui_test.gd`. All generated Lunaris full-figure and chibi concepts are stored under [`docs/lunaris-reliquary/`](lunaris-reliquary/), while the optimized runtime portraits live under `assets/portraits/` and are registered as non-placeholder assets.
