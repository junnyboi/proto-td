# TD-040 — Agent 1 Loading-Screen Concepts Handoff

## Outcome

Four original 1920×1080 loading-screen concepts were generated with GPT Image 2 and reviewed against Proto-TD’s current title screen, adult allied portrait language, enemy-machine faction, live battlefield palette, and future loading-UI needs. Every character is visibly adult, highly attractive, non-explicit, and designed with premium anime-gacha banner appeal.

| Concept | Managed asset | SHA-256 of reviewed WebP delivery copy | Verdict |
|---|---|---|---|
| A — Goldfall Vanguard | `/manus-storage/proto-td-loading-concept-a-goldfall-vanguard_79503359.png` | `e3b23c067a3786617556aff93ef04e705817a7d37a2b70771a667e85305414b1` | PASS; safest all-purpose world-and-roster introduction |
| B — Velvet Siege | `/manus-storage/proto-td-loading-concept-b-velvet-siege_63534533.png` | `806993f738f28d13e701f38e3d7f2cd4b381b4c3635cee1f629aea9c6ef5bd15` | PASS; strongest fashion and character-marketing appeal |
| C — Moonlit Reliquary | `/manus-storage/proto-td-loading-concept-c-moonlit-reliquary_923f3174.png` | `94218c75f1bea45511eebc150f807606873f5192e4e440f4a54483241313410b` | PASS; strongest permanent loading-screen recommendation |
| D — Scarlet Causeway | `/manus-storage/proto-td-loading-concept-d-scarlet-causeway_212fed5a.png` | `dffc03dace62ce0141875813a4b5e4f288d7faf0e8b7ee8c2dab1f2cc34074b3` | PASS; strongest action/event loading-screen direction |

## Evidence

The production brief is `docs/media/loading-screen-concepts/concept-brief.md`. Full generation prompts are preserved in `gpt-image-2-prompts.md`; the comparative positioning and managed URLs are in `concept-index.md`; the direct visual pass/fail findings are in `visual-review.md`.

Godot `4.7.2.stable.official.ed1daf0bf` was confirmed before work. `scripts/validate.sh` passed import, bounded boot, focused GUT, and deterministic headless boot scenario after the documentation changes. All four reviewed delivery copies are 1920×1080 WebP images; no generated binary is committed to Git.

## Recommendation and next action

Concept **C — Moonlit Reliquary** is recommended for refinement because it has the clearest centered lower loading-UI plane, the strongest permanent flagship aura, and the most distinctive silhouette at startup. Concept **B — Velvet Siege** should be retained as the alternate if the owner prioritizes fashion-forward character thirst and acquisition marketing.

The next lane should begin only after the owner selects one direction. It should refine that single image, define the exact **Protos** wordmark/loading treatment, implement either `application/boot_splash` or a dedicated pre-title loading scene, refresh the Web export, and validate desktop plus portrait behavior. This lane intentionally changes no runtime or preview code.

## Implementation

The validated concept documentation is commit `74b8ee1caab725e1ee485d4ab2d7953686f955a2` on `agent-1/loading-screen-concepts`.
