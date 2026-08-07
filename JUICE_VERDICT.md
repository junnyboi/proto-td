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
- Open for L7: spark size at 1×, audio spam feel at high kill rates (audio throttle is 1/frame).

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
- Open for L7: shimmer subtlety, snap audio sharpness.

## Item 7 — Charm conversion
- Specced before implementation: yes
- Machine-checkable: ally-palette pixels present post-cast and absent pre-cast at the same
  model-derived rect (the parent's own formulation); beat time-scale exact on conversion and
  1.0 after `charm_beat_frames`; `sfx_played:charm` == `spells_cast_charm`. The CHARMED_COLOR
  recolor is the palette swap of record until Lane A's sprite.
- Escalations: none.
- Open for L7: swirl+hearts charm (pun intended), beat length, chime warmth.

## Known holes (deliberate)
- **Bolt impact visual**: no gated checklist row (§2.1.11) — SFX only (`bolt_zap`). If human
  rounds flag the cast as unreadable, a target-cell burst needs a cast-target model record.
- **Shake/hit-stop whitelist**: `boss_hit` entry unwired until a boss-attack record exists
  (Phase 10); hit-stop config defaults to 0 frames everywhere (wired, reserved).
- **Music**: silent by design (Lane A / polish).
