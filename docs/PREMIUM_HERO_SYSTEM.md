# Premium Hero and Gacha System

## Scope

This document records the implemented Premium Resonance mechanics and production contracts. It is not an independent narrative authority. The sole narrative canon is [`NARRATIVE_CANON.md`](NARRATIVE_CANON.md).

Premium heroes are fixed, named adults who serve with Company Manus. They retain persistent identities, fixed combat kits, unique portraits, and deterministic acquisition histories. They gain no campaign XP and do not enter the training or promotion graph. Ordinary procedural recruits retain their existing recruitment, training, recovery, replacement, death, memorial, and save behavior.

## One soul and prepared lives

Anima is one person's real and unique human soul. It is not a memory file and cannot be copied. Premium Resonance never creates a person, spare soul, or alternate version of a hero.

**Resonance Shards are clean Lunaris crystals.** They contain no human soul and are not harvested anima. Lunaris uses them to locate a known hero's **Soul Anchor**, reconnect that hero's one continuing soul to the Reliquary network, and prepare a compatible recovery body.

A first pull reconnects the known soul and prepares one body. A later pull for the same `premium_id` prepares one additional recovery body and anchor capacity. It does not create another roster identity or soul. Only the original soul can occupy a prepared body.

| Implemented state | Narrative meaning |
|---|---|
| `ready` with lives | The hero's one soul occupies an available body and the hero may deploy. |
| Fall with lives remaining | One prepared body is lost. The Soul Anchor recovers the same soul into another prepared body after resolution. Exactly one life is consumed. |
| `dead` with zero lives | This is a technical deployment lockout, not proof of permanent soul death. The soul remains recoverable in its anchor, but no safe body is available. |
| Pull at zero lives | One compatible body is prepared. The same soul returns to `ready`; the terminal record and Valhalla entry are cleared. |
| Missing | The soul's location is unknown. This differs from zero lives and permanent loss. |
| Captured | A hostile system holds the soul beyond Company Manus's reach. Captivity is not preservation and is not automatically permanent. |
| Permanently lost | The soul was consumed, blended, or shattered beyond recovery. No pull can copy or replace it. |

Player copy must preserve these distinctions. Internal `dead`, memorial, and life fields remain stable for save compatibility, but prose must not call a stored life a spare soul or claim that a zero-life hero is permanently lost.

## Player-facing rules

| Rule | Contract |
|---|---|
| Cost | One accepted pull costs exactly **40 Resonance Shards**. The transaction retains the existing serialized Marks balance and receipt fields for compatibility. Neither Marks nor Resonance Shards are anima. |
| Availability | Pulling is disabled during an unresolved battle attempt, below 40 Resonance Shards, at roster capacity for a first acquisition, or at protected counter and life caps. |
| Result | Every accepted pull awards exactly one prepared life to one identity in the three-entry Lunaris pool. There are no empty results. |
| First acquisition | Creates one persistent roster row with one life, fixed class and kit, portrait, callsign, and weapon identity. |
| Duplicate | Increments `premium_lives` and `premium_pull_count` by one. Roster size does not change. This is another prepared body, never another soul. |
| Revival | A zero-life result grants one life, returns the same hero to `ready`, clears the terminal death record, and removes the Valhalla entry. |
| Battle fall | Consumes exactly one life. Remaining lives return the hero ready; the last life causes zero-life lockout and a Valhalla entry. |
| Training | Premium heroes gain no campaign XP and cannot be promoted. Training surfaces label them `PREMIUM / FIXED KIT`. |
| Deployment | A battle ticket requires `life_status == ready`; premium normalization additionally requires `premium_lives > 0`. |
| Ordinary recruits | Existing progression, death, replacement, recovery, memorial, and saves remain unchanged. |

## Launch pool and fixed kits

The launch pool retains the three Lunaris Reliquary identities and established battle operators. Combat behavior remains deterministic.

| Premium ID | Callsign | Rarity | Weight | Fixed class | Battle operator | Portrait ID | Visual identity |
|---|---|---:|---:|---|---|---|---|
| `archive_caster` | **Archive Caster** | 4 | 19 | `mage_apprentice` | `caster_1` | `portrait_archive_caster` | Silver-lilac ritual caster with Archive Astrolabe |
| `lunaris_vessel` | **Lunaris Vessel** | 5 | 2 | `sorcerer` | `caster_2` | `portrait_lunaris_vessel` | Champagne-blond flagship heroine with Crescent Reliquary |
| `reliquary_duelist` | **Reliquary Duelist** | 4 | 19 | `sword_saint` | `guard_2` | `portrait_reliquary_duelist` | Black-ponytail spellblade hero with Jade Meridian |

The total weight remains 40. Lunaris Vessel is the sole five-star result at weight 2; each four-star result has weight 19. `premium_id` is the stable collectible identity and is not inferred from `operator_def_id`. Character silhouettes, adult design, portraits, and animation routing are specified in [`LUNARIS_CHARACTER_DESIGNS.md`](LUNARIS_CHARACTER_DESIGNS.md).

## Pity and deterministic selection

The draw never uses Godot's global random-number generator. It applies the existing SplitMix64 helper to campaign seed, generation, `next_premium_pull_index`, and domain constant `605702925438635313`. The weighted remainder selects the pool row. The same accepted command from the same pre-state therefore produces the same result during replay.

| Pity rule | Contract |
|---|---|
| Base five-star rate | Weight `2/40`; Lunaris Vessel is the only five-star row. |
| Miss tracking | Each pity-eligible non-five-star increments `premium_pity_streak`. |
| Hard pity | After nine eligible misses, the tenth eligible pull is forced to a five-star row. |
| Reset | Any natural or forced five-star resets the streak to zero and reports ten pulls to the next guarantee. |
| Pre-pity migration | Existing pulls remain valid but do not retroactively build pity. `premium_pity_started_at_pull` opens a fresh window with streak zero. |

## Data, receipts, and saves

Every hero row retains these append-only fields:

| Field | Ordinary recruit | Premium hero |
|---|---:|---:|
| `hero_kind` | `recruit` | `premium` |
| `premium_id` | `null` | Stable pool ID |
| `premium_lives` | `0` | Integer `0` through `999` |
| `premium_pull_count` | `0` | Integer `1` through `999` |

Campaign state retains `next_premium_pull_index`, `premium_pity_started_at_pull`, and `premium_pity_streak`. Every accepted pull increments the pull index exactly once. These values participate in normalized state and strategic hashes.

The command verb remains `pull_premium_hero` with an empty normalized payload. Duplicate command IDs remain idempotent. Each persisted receipt retains:

- `premium_id`, `hero_id`, and `pull_index`;
- `new_hero` and `revived`;
- `lives_before`, `lives_after`, and `pull_count_after`;
- stable `marks_before` and `marks_after` economy fields;
- `rarity`, `five_star`, and `pity_eligible`;
- `pity_before`, `pity_after`, `pity_forced`, and `guarantee_in_after`;
- `save_revision`.

Receipt wording may explain Soul Anchors and prepared bodies, but keys, values, replay order, codecs, hashes, and storage formats must not change for narrative reasons.

Version-3 migration recognizes exact older key shapes, verifies the original checksum, and upgrades deterministically. It adds required premium and pity defaults and an empty `premium_life_losses` list where required without rewriting earlier outcomes. Existing currency, progression, roster identities, deaths, memorial records, tickets, offers, receipts, save bytes, and unrelated fields remain intact. No recruit becomes a premium hero.

## Battle resolution

Resolution records `premium_life_losses` sorted by `hero_id`. Each row retains `hero_id`, `premium_id`, `lives_before`, `lives_after`, and `locked_out`. `dead_hero_ids` and memorial IDs remain reserved for terminal lockouts and ordinary permanent deaths.

The validator permits `ready / N -> ready / N-1` when lives remain, or `ready / 1 -> dead / 0` with a matching record and Valhalla entry. Premium XP does not change and premium heroes never appear in `xp_awards`. Ordinary hero transitions remain unchanged.

## Interface and accessibility

Company Command routes Premium Resonance to the dedicated screen.

| Surface | Contract |
|---|---|
| Header | Shows balance, clean Resonance Shard explanation, cost 40 Resonance Shards, ten-segment pity telemetry, and return action. Tooltips and accessibility descriptions state that shards contain no soul. |
| Gallery | Shows three adult cards with stable portraits, localized callsigns and classes, ownership, lives, and pull count. Desktop uses three columns, compact landscape two, and portrait one. |
| Pull | Exposes cost in visible and accessible text, gives an exact disabled reason, dispatches once, and locks input while committing. |
| Result | Uses the persisted receipt for first acquisition, duplicate prepared life, or zero-life restoration. It never describes a duplicate person. |
| History | Projects committed receipts without parallel state. The drawer traps focus and restores it to its opener. |
| Reveal | Preserves rarity, unique portrait or cinematic, skip behavior, controller and pointer input, and safe framing. Reduced Motion uses the final plate and removes drift, pulse, and entrance motion. |
| Other screens | Squad, Training, Results, and Valhalla preserve life state, fixed-kit labeling, deployment lockout, localization, and the distinction between body loss and permanent soul loss. |

Keyboard, pointer, controller, focus, screen-reader, locale switching, text scaling, responsive layout, Reduced Motion, and touch-target support remain required. Layouts must not overflow at 390×844 or 720×1280. No result may rely on motion, color, or audio alone.

## Production evidence and acceptance

The implementation retains the three-entry pool, fixed cost, deterministic weights, hard pity, persistent identities, stored lives, fixed kits, receipts, zero-life lockout, Valhalla integration, unique portraits, and stationary animation routing. Focused regressions include `tests/premium_hero_system_test.gd`, `tests/premium_gacha_ui_test.gd`, `tests/premium_gacha_history_projection_test.gd`, and `tests/premium_gacha_pity_economy_test.gd`. These are technical evidence, not narrative authority.

An accepted pull must charge exactly 40 and change exactly one premium identity by one prepared life. Duplicates must not add roster rows. A zero-life result must restore the same hero. Hard pity must occur no later than the tenth eligible pull and reset on any five-star. Premium heroes must gain no XP or promotion. Existing recruits and saves must remain valid. State, receipts, pity, codecs, hashes, replay, portraits, accessibility, and deterministic combat must remain unchanged. All explanation must describe one non-copyable soul, clean Resonance Shards, Soul Anchors, and prepared recovery bodies.
