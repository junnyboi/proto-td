# Juice automation — interim verdict (acceptance #12)

Phase 9, 2026-08-08. One entry per item, written as the item closed. Final verdict lands after
the polish round (parent plan §7 Phase 9 / §9 row 12).

**Verdict so far:** spec-first juice automation is paying for itself. Writing the falsifiable
checklist before the implementation caught three real defects that eyeballing would have
shipped: the physics-vs-render frame aging mismatch (flash budget silently halved on 120 Hz
displays), the sprung frame being fully covered by the triggering enemy's rect (the effect was
*correct and invisible*), and a scenario abort masquerading as a pass when its remaining checks
were pixel-skips (now structurally impossible — completion sentinel). The machine gate proves
timing + wiring + visibility; it cannot judge *feel* — every "does the thump land" question is
deliberately left for L7. Cost: the pixel-probe infrastructure was ~1 session-hour once, reused
by all seven rows.

Durations are integer render frames (config `juice_config.tres`): visual lifetimes halve at
120 Hz vs 60 Hz. Accepted for v1; converting to seconds is a config-schema data edit reserved
for human-round verdicts (don't change numbers before diagnosing — learnings §6.2).

## Item 1 — Deployment ritual
- Specced before implementation: yes (`juice_deploy` checks, td-phase-9.md §2.2 written first)
- Machine-checkable: time-scale exact values during/after drag + cancel path; dust presence and
  decay by pixel probe; per-deploy SFX event == deploys counter. Not expressible: "the slowdown
  feels deliberate", thump weight.
- Escalations: none to Movie Maker. One deterministic-timing rework: the dust probes anchor to
  the seam deploy — `click_view`'s press/release holds consume most of a 10-frame window at
  120 Hz, so the raw-drag deploy proves the adapter and the seam deploy proves the pixels.
- Open for L7: drag slowdown magnitude (0.3×?), dust size/count, crouch readability.

## Item 2 — Skill activation
- Specced before implementation: yes (upgrade rows added to `skill_timing` first)
- Machine-checkable: flash pixels in the PortraitFlash rect ≤4 frames post-trigger, SP fill
  node read == 0, decay after `skill_flash_frames`. Found+fixed: flash aged in physics frames —
  on ProMotion the decay probe failed and exposed that the visual budget was refresh-dependent.
- Escalations: none.
- Open for L7: flash placement (top-center placeholder vs portrait), burst ring visibility.

## Item 3 — Kill feedback
- Specced before implementation: yes
- Machine-checkable: spark cap binds **exactly** (20 same-tick kills → live count == cap == 12);
  cap invariant polled through the decay; spark pixels at the corpse cell;
  `sfx_played:kill == killed` exactly (C1: the throttle gates audio, never the event — the
  parent's ≥0.9× band holds with slack). Not expressible: whether 12 concurrent sparks read as
  "a lot" or as noise.
- Escalations: none.
- Open for L7: spark size at 1×. (Kill-audio spam question **waived by D-SFX** — the 1/frame
  throttle and the `sfx_played` counts stay wired for the day audio returns.)

## Item 4 — Leak alarm
- Specced before implementation: yes
- Machine-checkable: vignette pixels at the screen edge on the leak tick, absent 20 frames
  later (the parent's own numbers); `GridRoot.position` restored exactly post-shake; one
  `sfx_played:leak` per leak. HUD knock shipped as a red tint for the vignette window (no scale
  pop — a 1-frame pop is unshottable and was cut; noted as a deliberate simplification).
- Escalations: none.
- Open for L7: shake amplitude (6 px?), whether the alarm reads as "my fault" urgency.

## Item 5 — Wave/clear punctuation
- Specced before implementation: yes
- Machine-checkable: banner node + text pixels at each wave crossing (incl. tick 0), gone after
  its budget; stamp star-child count == `model.stars` (node read) + star pixels; wave/victory/
  defeat SFX counts match crossings and terminals. Reinterpretation held: in-battle stamp, not
  the Phase 10 results screen (§2.1.10 deviation).
- Escalations: none.
- Open for L7: banner slide speed, star stagger rhythm, stamp typography.

## Item 6 — Trap trigger
- Specced before implementation: yes
- Machine-checkable: sprung pixels post-trigger **including the final charge** (the trap leaves
  the model that tick; the view rect is adopted by the juice layer and outlives it — J11);
  found+fixed: the triggering enemy's 40 px rect draws over the 24 px plate, so the sprung
  frame needed an overlay flash in the juice layer to be visible at all — a genuine
  "correct but invisible" defect the pixel probe caught. Tar shimmer: modulate node reads half
  a period apart differ while occupied, constant while empty. `sfx_played:trap_snap` ==
  `trap_triggers` exactly.
- Escalations: none.
- Open for L7: shimmer subtlety. (Snap-audio sharpness question **waived by D-SFX**.)

## Item 7 — Charm conversion
- Specced before implementation: yes
- Machine-checkable: ally-palette pixels present post-cast and absent pre-cast at the same
  model-derived rect (the parent's own formulation); beat time-scale exact on conversion and
  1.0 after `charm_beat_frames`; `sfx_played:charm` == `spells_cast_charm`. The CHARMED_COLOR
  recolor is the palette swap of record until Lane A's sprite.
- Escalations: none.
- Open for L7: swirl+hearts charm (pun intended), beat length. (Chime-warmth question
  **waived by D-SFX**.)

## Known holes (deliberate)
- **Bolt impact visual**: no gated checklist row (§2.1.11). Originally mitigated by SFX only
  (`bolt_zap`); that mitigation **no longer exists** — the SFX were removed and the silence
  recorded as deviation D-SFX, so the hole is now **fully unmitigated**: a Bolt cast has no
  dedicated impact feedback at all. If human rounds flag the cast as unreadable, a target-cell
  burst needs a cast-target model record.
- **Shake/hit-stop whitelist**: `boss_hit` entry unwired until a boss-attack record exists
  (Phase 10); hit-stop config defaults to 0 frames everywhere (wired, reserved).
- **Audio (SFX + music)**: silent by owner decision — deviation D-SFX (phase 14); the
  `sfx_played` telemetry seam stays wired.

## Post-P10 / final-audit status pass (2026-08-09, frozen at `218aaea`)

- `boss_hit` — **still a hole**: P10's mini-boss attacks through the ordinary enemy combat
  path with no boss-attack model record; the whitelist slot waits for the polish round.
- Item 5 addendum: the banner now runs on real campaign `wave_starts` data (2–3 windows per
  stage) — cadence unchanged mechanically; rhythm is an L7 question (PLAYTEST.md §3).
- Item 7 addendum: with Lane A landed, the conversion palette-swap is a real sprite swap
  (ally-blue ramp centered on the probed CHARMED_COLOR) — the recolor-of-record note below
  is superseded; the swirl/hearts remain juice-layer rects by scope.
- Items 1/3/4/6: unchanged by P10/Lane A; all pixel checks re-proven at the frozen hash with
  zero skips (FINAL_REPORT §3).
- The **final verdict slot stays open** for the polish round (acceptance #12).

## Phase 12 note (iso view conversion, 2026-08-11)

All juice anchors moved with the view's projection seam (kill spark, charm
swirl, deploy dust, skill burst now anchor via `cell_center`/`screen_of`;
the juice layer draws in its own z band above the grid). Magnitudes,
lifetimes, and every pinned frame count are UNCHANGED — the model-untouched
oracle (cross-process replay vs the merge-base baseline) is byte-identical.
Feel verdicts remain open for L7; the iso re-read adds one question: do the
leak shake (x-only) and the charm beat still land on the diamond grid?

## Phase 14 note — audio waived by owner decision (D-SFX, 2026-08-11)

The placeholder synth SFX were removed at `81ec642`; the owner then ruled the silence
deliberate: no SFX, no music, until real audio exists. Recorded as numbered deviation
**D-SFX** (FEATURES.json `deviations` + FINAL_REPORT.md §9). Consequences for this file:

- Every open audio question above (kill-audio spam, snap sharpness, chime warmth, and the
  audio halves of the item entries) is **closed as waived-by-decision**, not answered — the
  questions return verbatim when audio does.
- The `sfx_played` machine checks in items 1/3/4/5/6/7 remain **true and green**: `Sfx.play(id)`
  is a telemetry-only stub, so the counts still prove event wiring. They are wiring evidence,
  not audibility evidence.
- Restoration recipe: `git show 81ec642^:tools/gen_sfx.gd`.
