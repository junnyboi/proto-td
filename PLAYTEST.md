# Prototype TD — Human Playtest Protocol (L7, rounds 1–2)

You are the first human to play this build. Machines have proven it *correct*; only you can
say whether it is *fun*. Trust your gut, write everything down, and don't be polite about it.

## 1. Setup

- Launch: `~/bin/godot --path ~/Projects/prototype-td` (a 1280×720 window opens on the title).
- **Progress is session-only.** Closing the window resets the campaign — by design.
- F12 opens a debug overlay. Rounds 1–2 are played **without** it: debug is for reproducing a
  verdict afterwards, never for forming one.
- Build under test: **`master` ≥ `f08ee08`** (TD-007 campaign-only Start candidate — includes
  the P12 iso view, P13 battle controls, phase-14 remediation, P15 Staging hub, and the single
  Start → campaign route). The original `poc-v1-audit` tag and two-flow P15 build are
  superseded; do not playtest an older build.
- **The build is silent by design** (owner decision 2026-08-11, deviation D-SFX): no SFX, no
  music. Every audio question in this script is N/A — judge visuals only, and do not log the
  silence as a defect.

## 2. The run

Title → **Start** → **Staging Area** → **Mission Control** → play S1→S8 in order. Start is the
prototype's only game flow; there is no separate quick battle. Expect to
lose sometimes — note when a loss felt fair vs cheap. Per stage, three passes:

**Watch for** (does the lesson land?)

| Stage | The lesson that should land | Juice moments to notice |
|---|---|---|
| S1 First Stand | blocking is the game — melee ON the road stops them | deploy ritual (drag slowdown, landing dust), wave banners, kill sparks |
| S2 Tempo | you feel DP-poor; opening with the Vanguard matters | leak alarm (red frame + shake) when the rush gets through |
| S3 The Choke | the 1-wide choke begs for a Spike Plate | trap snap on trigger |
| S4 Air Raid | drones sail over your blockers — Snipers or lose | tracer fire; drone kill cadence |
| S5 High Ground | spellcasters cluster; one Bolt erases a cluster | bolt burst; elevated Casters |
| S6 Turncoat | **the charm moment**: charm the lead heavy, watch it turn and fight its own wave | conversion swirl + hearts + slow-beat |
| S7 Full Kit | everything at once; spend every tool on time | overlapping juice under pressure |
| S8 The Gatecrasher | the boss is charm-immune — try to charm it anyway and watch it refuse; mastery, not the panic button | victory stamp + stars on the final clear |

**Exercise** (do these deliberately at least once)

- S3: **tar + spike combo** — tar first, spike behind it: "hold them on the tar".
- S4: squad select without a Sniper once — feel the forcing function.
- S5: hold Bolt too long once; see what the cluster does.
- S6: charm the lead heavy at mid-path (the designed moment). Also try a no-charm attempt.
- S8: charm the escort heavy (legal) after the boss rejects.
- Screens: can you read cost/class from the squad cards at a glance? Does the loadout strip
  make sense? Stage stars? The reward reveal after a clear?
- Staging: does the `0/8` campaign summary and next mission read immediately? Are Barracks,
  Recruit, Training, Armory, and Memorial unmistakably unavailable without feeling broken?
  Confirm Mission Control opens the stage list, Back to Staging preserves progress, and both
  campaign CLEAR and DEFEAT results offer Return to Staging.
- Retreat a unit; retry a stage from the results screen.

**Judge** (the acceptance questions — answer per stage or at the end)

1. Fun? Where exactly did it spike or sag? (#6)
2. Did any stage force you to change your squad composition? Which, and did that feel like
   learning or like a tax? (#7)
3. Do deploys and skill triggers feel responsive — is the game acknowledging your inputs? (#8)
4. After S8: do you replay anything without being asked? (Observed, not asked — leave the
   player alone at the results screen and see. #9)

## 3. Juice questionnaire (from JUICE_VERDICT.md's open items)

- Deploy: is the 0.3× drag slowdown deliberate or annoying? Dust/crouch readable?
- Skill flash: placement/read? Does the burst ring register?
- Kill sparks: readable at 1×? Too much at 12 concurrent?
- Leak alarm: does it read as "my fault, fix the hole" urgency? Shake amplitude ok?
- Banner rhythm: does WAVE N landing feel like a beat? Star stagger on the stamp?
- Trap snap: sharp enough? Tar shimmer visible without being noisy?
- Charm beat: is the 0.5× beat + swirl a *moment*?
- Audio (deploy thump, kill ticks, leak alarm sound, trap snap, charm chime, wave/victory
  stings): **N/A by design** — the build is deliberately silent (deviation D-SFX). Skip every
  audio judgment; the original questions return with the audio.
- Art v2: does the warm road read as "their lane"? Do operators vs enemies separate cleanly
  in a messy fight (flagged from the audit's shot review)? Portrait cards charming?

## 4. Verdict ledger (acceptance #10 — fill AS YOU PLAY, classify at capture time)

| # | Where | Verdict | Severity (blocker/major/minor/polish) | Classification (data-edit / code-change / prompt-change) | Action |
|---|---|---|---|---|---|
| 1 | | | | | |

Classification rule (learnings §6.3): a *feel* verdict that can only be fixed by a **code
change means a system is missing** — flag those loudly; they are the expensive ones. Numbers
(costs, HP, waves, juice timings, star bands) are all data — expect most rows to be data-edit.

Running total: data-edit rows ___ / total rows ___ (target ≥ 80%).

## 5. Post-round steps

**After round 1** (agent session, small): implement the tier-2 evaluator in `quality_gate.sh`;
transcribe the bands your verdicts imply (they are YOUR lines — the agent only types);
commit first baselines; apply the data edits row by row; re-run the full ladder; update the
#10 arithmetic; fold anything the round taught into the plan/prompt docs.

**Round 2**: same protocol against the fixed build; confirm or reopen each round-1 row;
close the #10 numerator/denominator. The POC review packet = FINAL_REPORT.md + this ledger +
JUICE_VERDICT.md.

## Phase 12 note (iso view conversion, 2026-08-11)

The battle renders in 2:1 isometric from P12 on (included in the §1 build pin): shot
references in the
round script now correspond to the iso baselines under `artifacts/`
(diamond terrain, lifted ELEVATED tiles with cliff walls, feet-anchored
sprites, diamond footprint overlays). The grid auto-fits the window and
relayouts live on resize; the playfield sits on a backdrop ring (no bare
canvas). Two added L7 questions: (1) does high ground read at a glance
(lift + walls + cast shade), and (2) does the wall-band click behavior
(cliff selects the high ground) ever surprise you during deploys?
