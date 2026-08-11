# TORCHLIGHT & STEEL — style law for the reference set

Register: **fantasy dungeon-crawl × gacha anime** — D&D / Lord of the Rings material
gravitas (worn steel, leather, stone, torchlight) rendered with Mushoku Tensei / Genshin
Impact charm (expressive anime faces, dynamic poses, clean color logic, one strong accent
per character). Medium for this set: **high-resolution pixel illustration** (the strongest
procedural lane available; each character also carries an image-model prompt block in the
proposal for a future gpt-image pass).

## Hard rules (lint-enforced or judge-enforced)

1. **TD32 palette only** (`painter.PALETTE`). WHITE `f4f4f4` and SKY `41a6f6` are
   pixel-probe reserved — `painter.lint()` fails any art that touches them.
2. **One key light, top-left.** Shadows fall bottom-right. Optional cool rim light on the
   right/back edge (PALE on warm characters, CYAN never — too close to probe territory in
   spirit; use PALE or STEEL).
3. **Hue-shifted ramps only** — shade by stepping down a `painter.RAMPS` ramp, never by
   picking a darker gray. Shadows go cooler, highlights warmer.
4. **Two representations per character, one identity kit.** Hair silhouette + hair color,
   1–2 accent colors, one signature prop must survive both.

## Representation A — key art (full-body action pose)

- Canvas **128×224** native, transparent background, saved at 1× and 3×.
- Proportions: **5.5–6.5 heads** (anime illustration, NOT chibi). Head ≈ 34 px tall
  including hair. Eye line at ~55 % of head height. Legs are long: hips near y≈118.
- **Action pose, never a T-pose or static stand.** Weight on one leg, torso twist,
  diagonal weapon thrust, cloak/hair swept by motion, off-hand casting or braced.
  A diagonal composition axis beats a vertical one.
- Face: anime construction at this scale — 8–10 px eyes with lash line, iris color from
  the character's accent family, catchlight (PALE_GOLD or PALE), tiny nose, small mouth.
- Rendering: 3–4 tone cel ramps per material; selective interior linework (VOID) on
  jaw, hair partitions, armor plates; exterior `outline("VOID")` last.
- Detail budget: face and signature prop get the densest work; big cloth/armor masses
  stay as 2–3 flat tones so the eye rests where it should.

## Representation B — iso battle sprite

- Canvas **64×64** native, chibi **2.5–3 heads**, feet at bottom-center pivot **(32, 60)**,
  body within ≤ 56 px width so the sprite sits on a 64×32 iso diamond without lapping
  neighbors. Idle pose holding the signature prop; silhouette must read at 1×.
- Same identity kit and ramps as the key art. Exterior outline, hard alpha.

## Construction order (both)

silhouette blockout (single mid-tone) → big masses back-to-front (cape → legs → torso →
arms → head → hair → prop) → ramp shading (`shade_under` or explicit shadow shapes) →
face → highlights/rim → `outline()` → `lint()`.

## Iteration protocol (mandatory)

Render with `save(c, path, 3)`, **Read the PNG and look at it**, write down the three
worst defects, fix them in the generator script, re-render. Minimum 3 render-review
cycles; stop only when a review finds no structural defect (anatomy, pose readability,
face quality, tangents). `painter.lint()` must return "" before an asset is final.

## Output contract (per character `<id>`)

- `tools/artgen/gen_<id>.py` — the deterministic generator (both canvases, one file)
- `docs/art/reference/<id>_key.png` (1×) + `<id>_key@3x.png`
- `docs/art/reference/<id>_iso.png` (1×) + `<id>_iso@4x.png`
- `docs/art/reference/<id>.json` — provenance: {"generator": "tools/artgen/gen_<id>.py",
  "iterations": N, "lint": "clean", "spec_name": "<display name>"}
