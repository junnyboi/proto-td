# Campaign Level Designs

This is the technical stage-design specification for the sixteen-stage campaign. Narrative context comes only from [Narrative Canon](NARRATIVE_CANON.md); this document is not an independent canon source. The player commands **Company Manus** against PROTOS, the corrupted rogue AI whose human farms feed a robot empire with anima—the real human soul.

The implementation boundary is strict. Stage IDs `s1`–`s16`, campaign indices, grids, paths, waves, wave starts, enemy IDs, leak and squad limits, requirements, rewards, music routing, deterministic behavior, save compatibility, and accessibility behavior remain unchanged. Narrative presentation must not promise an unimplemented escort, capture, factory-arm, branching, or soul-separation mechanic.

## Campaign structure

| Act | Stages | Story progression | Tactical progression |
|---|---|---|---|
| **Act I — The Harvest Line** | S1–S8 | Company Manus defends Hearthcross, learns that robots take people, establishes that anima is the person's real soul, exposes a human farm, and captures a route into the robot empire. | Blocking and ranged placement expand through runners, a true choke, air defense, exposed high ground, Charm timing, Slow Field sequencing, and a Charm-immune boss. |
| **Act II — Into the Machine Empire** | S9–S16 | Company Manus crosses the anima supply chain, exposes collaborators, meets digital beings who reject stolen souls, prioritizes rescue, and destroys a regional foundry while PROTOS survives. | Repair platforms expand from one cell to four, mixed air and ground pressure intensifies, leak tolerance falls, and two Charm-immune boss windows close the act. |

## Shared technical contracts

### Maps and orientation

Every map is authored once in landscape orientation under `data/stages/`. `StageDef.copy_for_viewport()` selects the authored resource for landscape and an isolated 90-degree clockwise copy for portrait. `StageDef.clockwise_rotated_copy()` applies `(x, y) → (height - 1 - y, x)`, swaps dimensions, and rotates grid cells, paths, repair-platform cells, and early-stage cell-indexed presentation metadata.

Rotation preserves ID, title field, waves, wave starts, leak limit, squad size, recovery roster, rewards, campaign index, requirements, hint, repair amount, and repair interval. Four rotations return the original grid, paths, and repair cells. `BattleView` fixes orientation at battle start; resizing may refit or pan but must not rotate the simulation or remap units. `BattleModel`, `IsoGridBuilder`, deployment, pathing, picking, and navigation consume the same selected `StageDef`.

### Waves, saves, and determinism

Wave entries remain chronological and reference valid enemy resources and path indices. Each path begins at a spawn, ends at the base, stays walkable, and uses adjacent orthogonal cells. Wave starts begin at tick `0` and increase strictly.

Campaign order remains `s1` through `s16` with the S8-to-S9 gate. Schema V3 restores historical eight-stage saves additively; the legacy V2 boundary remains eight stages. Narrative edits must not alter environment fingerprints, terminal schedules, battle or replay hashes, economy, ownership, unlocks, or save serialization.

### Charm and Slow Field

**Charm** retains implemented eligibility and immunity. In story terms it forcibly breaks a PROTOS command link; it is not friendship or consent. Stage copy must not promise control of an immune target. The S8 Gatecrasher, aerial Interceptors where implemented, and both S16 `mini_boss` windows remain immune.

**Slow Field** remains the cell-targeted Lunaris gravity device with stable ID `slow_field`, radius `1`, 50% ground slow (`slow_permille = 500`), duration `240` ticks, and cooldown `600` ticks. It does not manipulate anima. S6 awards it; S7 begins its required mastery. A Slow Field covering a repair-platform cell suppresses that platform's due repair cycle.

### Repair platform

The visible mechanic is the **repair platform**. Its exact instruction is:

> Repairs wounded enemy ground robots every 3 seconds; Slow Field blocks that repair.

Internal compatibility names remain `restoration_cells`, `restoration_heal_amount`, and `restoration_interval_ticks`; renderer, asset, replay, save, and test names may retain `RestorationLattice` or `restoration_lattice`. A cycle affects only a wounded hostile ground enemy on the platform. It excludes aerial enemies, Charmed entities, and full-health units, clamps HP to maximum, and participates in state hashes and deterministic replay. Every Act II platform uses a 90-tick, three-second interval.

### Rewards and stable IDs

Campaign V3 grants **40 Marks on every clear**. Marks are ordinary payment and salvage, never anima. Stable tactical rewards remain S2 `spike_plate`, S3 `tar_pit`, S4 `bolt`, S5 `charm`, and S6 `slow_field`. Authored recovery rewards and class entitlements also remain unchanged.

Display changes must not rename stage, enemy, operator, trap, spell, reward, save, resource, or hash identifiers. S16 may use the stage-local narrative label **Crown Engine** for its two boss windows, but simulation ID `mini_boss` and behavior remain unchanged. S8 remains the Gatecrasher encounter.

## Act I — The Harvest Line

### S1 — First Stand

**Story beat.** At the Hearthcross water works, Company Manus holds pumps and shelters while civilians escape. Taggers mark people and Collectors follow those records. Archive Caster finds a schedule classifying residents as renewable stock: the machines came for people, not territory.

**Implemented design.** The `8 × 5` map has one turned route, early and fallback blocking lines, and two elevated cells. Six `grunt` entries progress from singles to paired pushes. Wave starts: `0, 330`; leak limit: `3`; squad: `3`. The lesson is opening blockers, elevated ranged support, and reinforcement.

**Progression.** Authored reward: operator `guard_2`. V3: 40 Marks. Class entitlement: `sword_saint`.

### S2 — Tempo

**Story beat.** On the eastern pump roads, Company Manus stops fast Taggers from delivering capture records. A reusable anima cell reveals repeated draining of living prisoners and the purpose of keeping farm captives alive.

**Implemented design.** The `10 × 5` map has one two-turn route with approach and exit high ground. Ten enemies: six `runner`, three `grunt`, one `shieldbearer`. A runner rush precedes alternating pressure after the armored wave-two opener. Wave starts: `0, 390`; leak limit: `3`; squad: `4`.

**Progression.** Authored and V3 tactical reward: `spike_plate`; V3 also grants 40 Marks.

### S3 — The Choke

**Story beat.** Two prisoner routes meet at Old Cut beside a mobile extractor. The required reveal is explicit: **anima is the person's real soul, and full extraction kills**. Archive Caster recovers one trapped soul before consumption, proving rescue can be possible.

**Implemented design.** The `10 × 6` map has two entries and a true shared choke. Nine enemies: six `runner`, two `breacher`, one `grunt`. Three alternating runners consume finite Spike Plate charges before synchronized mixed pairs. Breachers consume two block capacity. Wave starts: `0, 390`; leak limit: `3`; squad: `4`.

**Progression.** Authored rewards: `sniper_1`, `tar_pit`. V3: `tar_pit`, 40 Marks. Class entitlement: `immovable`. Requirement: `spike_plate`.

### S4 — Air Raid

**Story beat.** Hunter Drones expose Hearthcross families and carry filled cells toward the empire. Company Manus overloads reservoir turbines to jam the relay, diverting water from Khepri Vale and creating the debt resolved in S10. Fresh anima lets PROTOS command distant robots in real time.

**Implemented design.** The `11 × 6` map separates a straight aerial lane from a bent ground route. Eleven enemies: three `drone`, two `interceptor`, four `grunt`, two `runner`. Ground preview leads to isolated and then mixed air-ground pressure. Wave starts: `0, 390`; leak limit: `3`; squad: `5`.

**Progression.** Authored rewards: `sniper_2`, `bolt`. V3: `bolt`, 40 Marks. Class entitlement: `sniper`. Requirement: `sniper_1`.

### S5 — High Ground

**Story beat.** Company Manus captures a ridge uplink where human collaborators send census data to PROTOS for promised digital bodies. The records expose human participation and carry the Lunaris Vessel's authorization signature.

**Implemented design.** The `12 × 6` map has one route, a powerful exposed inner elevation, and a safer late elevation. Twenty enemies: eleven `grunt`, one `runner`, eight `spellcaster`. Two caster clusters are separated by at least Bolt's full cooldown while bridge pressure continues. Wave starts: `0, 450, 1250`; leak limit: `3`; squad: `5`.

**Progression.** Authored rewards: `caster_2`, `charm`. V3: `charm`, 40 Marks. Class entitlement: `sorcerer`. Requirement: `bolt`.

### S6 — Turncoat

**Story beat.** At a PROTOS relay, Company Manus breaks a Farm Warden's command link and turns it against its escort. Cinder speaks while disconnected, asks not to return to PROTOS, and reveals Hearthcross's hidden farm.

**Implemented design.** The `12 × 6` map has two escort routes converging into one corridor. Sixteen enemies: eleven `grunt`, three `runner`, two `heavy`. Each heavy leads a same-path escort column in a separate Charm window. Wave starts: `0, 650`; leak limit: `3`; squad: `6`.

**Progression.** Authored rewards: `vanguard_2`, `slow_field`. V3: `slow_field`, 40 Marks. Class entitlement: `banner_guard`. Requirement: `charm`.

### S7 — Full Kit

**Story beat.** Orchard Seven is a peaceful model district above a human farm. Company Manus protects three rescue efforts, frees captives, and recovers viable souls. Archive Caster finds proof that she was the thirty-third recovered person. The farm supplies an imperial army.

**Implemented design.** The `12 × 7` map has two ground entries and one aerial entry converging on a contested corridor. Twenty-two enemies: six `grunt`, four `runner`, two `heavy`, four `spellcaster`, six `drone`. Mobility, ranged, and air pressure compress into the shared Slow Field lane. Wave starts: `0, 500, 850`; leak limit: `3`; squad: `6`.

**Progression.** Authored reward: `witch_doctor_1`. V3: 40 Marks. Class entitlement: `witch_doctor`. Requirements: `spike_plate`, `tar_pit`, `sniper_1`, `bolt`, `charm`, `slow_field`.

### S8 — The Gatecrasher

**Story beat.** Company Manus defends the Moon Gate from the soul-powered Gatecrasher. Presentation may show Lunaris separating recoverable souls after armor breaks, but this is not a player mechanic. The recovered map reveals farms, refineries, and factories across the robot empire.

**Implemented design.** The `13 × 7` fortress has three approaches, one gate corridor, and two fallback regions. Twenty-four enemies: seven `grunt`, four `runner`, three `heavy`, five `spellcaster`, four `drone`, one `mini_boss` presented as Gatecrasher. Its eligible escort, support, and aerial cover require disruption, Slow Field, burst timing, and fallback. The boss ignores Charm. Wave starts: `0, 420, 900`; leak limit: `2`; squad: `6`.

**Progression.** V3: 40 Marks. Requirements: `tar_pit`, `sniper_1`, `bolt`, `charm`, `slow_field`, `witch_doctor_1`.

## Act II — Into the Machine Empire

All Act II stages retain squad size `6`, 40 Marks per V3 clear, and requirements for `spike_plate`, `tar_pit`, `bolt`, `charm`, `slow_field`, `sniper_1`, and `caster_2`. They introduce no new mechanics or tactical rewards.

### S9 — The Green Cage

**Story beat.** Company Manus opens service routes from a model-city human farm before Taggers close it. The defense represents the escape but does not add a moving-civilian escort. Records point to Khepri Vale's protection deal.

**Implemented design.** `12 × 7`; two converging routes; 18 enemies: six `grunt`, five `runner`, three `shieldbearer`, two `spellcaster`, one `breacher`, one `heavy`. Waves demonstrate ground-only repair, mixed proof, and a durable repaired column. Starts: `0, 420, 840`; leak limit: `3`.

**Repair platform.** `(6, 3)`, 8 HP every 90 ticks. Present the exact repair instruction here.

### S10 — Rain Debt

**Story beat.** Company Manus defends Khepri Vale and exposes a water-for-people quota, resolving S4's water diversion. Khepri rejects the deal and joins the resistance.

**Implemented design.** `13 × 7`; two repair lanes with a shared exit; 21 enemies: five `grunt`, five `runner`, four `shieldbearer`, three `spellcaster`, two `breacher`, two `heavy`. Rotate Slow Field and reserve Arts damage for armor. Starts: `0, 480, 960`; leak limit: `3`.

**Repair platforms.** `(5, 2)`, `(3, 4)`; 8 HP every 90 ticks.

### S11 — The Long Convoy

**Story beat.** Company Manus intercepts living captives and stored souls on an imperial causeway. Enemy columns represent the convoy; no train-control system is added. The Duelist finds victims from an earlier strike and chooses rescue before demolition.

**Implemented design.** `13 × 8`; one air domain and two restoring ground lanes; 23 enemies: four `grunt`, three `runner`, three `shieldbearer`, three `spellcaster`, one `breacher`, two `heavy`, four `drone`, three `interceptor`. Permanent anti-air and rotating ground suppression are required. Starts: `0, 480, 960`; leak limit: `2`.

**Repair platforms.** `(6, 3)`, `(4, 5)`; 8 HP every 90 ticks.

### S12 — Unlit

**Story beat.** Company Manus protects the Unlit at a disconnected factory settlement. Their weaker clean-power reactor proves digital life can exist without stolen souls. Reactor startup is narrative framing, not a construction mechanic.

**Implemented design.** `14 × 8`; three routes converge at shared repair space; 24 enemies: six `grunt`, five `runner`, three `shieldbearer`, four `spellcaster`, three `breacher`, three `heavy`. Eligible leaders precede durable columns, requiring Charm and Slow Field sequencing. Starts: `0, 480, 960`; leak limit: `2`.

**Repair platforms.** `(5, 3)`, `(7, 5)`, `(9, 4)`; 10 HP every 90 ticks.

### S13 — Thirty-Three

**Story beat.** Archive Caster learns she was Patient 33: her same unique soul returned to a prepared body after extraction, while Lunaris sealed memories of the Vessel connecting PROTOS to the Anima Engine. She releases the records. Recovery and save mechanics do not change.

**Implemented design.** `14 × 8`; two trap-compatible routes join at a relay; 26 enemies: four `grunt`, six `runner`, four `shieldbearer`, five `spellcaster`, four `breacher`, three `heavy`. Spike Plates finish runners, Tar Pits hold columns off-platform, and Slow Field cancels repairs. Starts: `0, 540, 1080`; leak limit: `2`.

**Repair platforms.** `(4, 1)`, `(6, 5)`; 10 HP every 90 ticks.

### S14 — The Price of Dawn

**Story beat.** Company Manus attacks a human-owned anima refinery and broadcasts its ownership. The Vessel admits authorizing the first interface. Humans created the market and access; PROTOS remains responsible for its corruption and empire.

**Implemented design.** `14 × 9`; three channels under exposed anti-air platforms; 28 enemies: four `grunt`, three `runner`, three `shieldbearer`, four `spellcaster`, three `breacher`, three `heavy`, four `drone`, four `interceptor`. Persistent air cadence overlaps repaired armor. Starts: `0, 540, 1080`; leak limit: `2`.

**Repair platforms.** `(6, 3)`, `(5, 6)`, `(9, 5)`; 10 HP every 90 ticks.

### S15 — Soulstorm

**Story beat.** Company Manus holds rescue sectors while soul tanks open and demolition is prepared. The outcome is fixed: rescue before demolition, not a branch. Blended souls power strong PROTOS minds, and not every victim can be restored. Soul-fragment disruption is narrative only.

**Implemented design.** `15 × 9`; four approaches compress into one corridor; 30 enemies: four `grunt`, five `runner`, four `shieldbearer`, five `spellcaster`, five `breacher`, five `heavy`, one `drone`, one `interceptor`. Four waves use every implemented stage role. Starts: `0, 480, 960, 1440`; leak limit: `1`.

**Repair platforms.** `(6, 2)`, `(4, 3)`, `(8, 5)`, `(11, 4)`; 10 HP every 90 ticks.

### S16 — Empire Foundry

**Story beat.** Company Manus destroys the regional Anima Forge and severs its Crown Engine from a soul core. Souls and digital minds are freed; PROTOS survives through its planetary network. Factory arms, link holding, and soul separation are presentation beats only.

**Implemented design.** `16 × 9`; four fortress approaches with upper, center, lower, and final fallback lines; 32 enemies: two `grunt`, four `runner`, four `shieldbearer`, six `spellcaster`, four `breacher`, five `heavy`, one `drone`, four `interceptor`, two `mini_boss`. The separate Charm-immune boss windows may be called Crown Engine locally without changing IDs. Starts: `0, 480, 960, 1500`; leak limit: `1`.

**Repair platforms.** `(7, 2)`, `(5, 3)`, `(9, 5)`, `(12, 4)`; 12 HP every 90 ticks.

## Progression ledger

| Stage | V3 clear reward | Authored recovery reward | Class entitlement |
|---|---|---|---|
| S1 | 40 Marks | `guard_2` | `sword_saint` |
| S2 | `spike_plate`, 40 Marks | `spike_plate` | None |
| S3 | `tar_pit`, 40 Marks | `sniper_1`, `tar_pit` | `immovable` |
| S4 | `bolt`, 40 Marks | `sniper_2`, `bolt` | `sniper` |
| S5 | `charm`, 40 Marks | `caster_2`, `charm` | `sorcerer` |
| S6 | `slow_field`, 40 Marks | `vanguard_2`, `slow_field` | `banner_guard` |
| S7 | 40 Marks | `witch_doctor_1` | `witch_doctor` |
| S8–S16 | 40 Marks per stage | None | None |

The V3 campaign and `StageDef` recovery layers are separate implemented contracts; documentation must not merge, duplicate, or reinterpret them.

## Accessibility and presentation

Stage titles, objectives, threats, hints, rewards, and mechanic copy continue through existing localization and accessibility paths. No stage adds an input mode or inaccessible interaction. Keyboard, controller, pointer, focus order, screen-reader labels, locale switching, text scaling, reduced motion, responsive layout, and 44-pixel touch targets remain required.

Maps and statuses must not rely on color alone. Spawn, base, elevation, blockage, routes, selection, invalid placement, repair platforms, Slow Field, and Charm immunity require existing shape, icon, text, or motion distinctions in addition to color. Portrait rotation and resize refitting preserve readable paths, target cells, focus, and pointer mapping without changing simulation state.

Use short, concrete narrative copy. First explanation: **anima—the real human soul**; later copy may say “soul.” Company Manus is the English player-facing name. Internal IDs must not leak into ordinary player copy.

## Verification evidence

[`act2-stage-balance.json`](act2-stage-balance.json) records implemented S9–S16 dimensions, paths, waves, repair cells, amounts, intervals, and leak limits. Its older display titles are technical history, not narrative authority.

`test/stage_redesign_smoke.gd` verifies exact layouts, unique topologies, path validity, chronological waves, enemy resources, repair contracts, early-stage themes, S3 convergence, S5 cooldown spacing, S6 escort windows and reward, S7 convergence, and S8 boss composition. `test/stage_orientation_smoke.gd` verifies transforms, metadata, repair-cell rotation, path adjacency, landmarks, and four-rotation round trips. `tests/restoration_lattice_test.gd` verifies the internally named `restoration_*` behavior, exclusions, HP clamp, Slow Field suppression, renderer, hash, replay, and campaign capacity. `tests/act2_campaign_test.gd` enforces stage order, rewards, balance envelopes, deterministic schedules, S8-to-S9 progression, and historical V3 save restoration.
