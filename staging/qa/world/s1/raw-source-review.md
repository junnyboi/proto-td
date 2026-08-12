# AUI-10 Prep — Raw GPT Image 2 Source Review

**Review state:** first-pass source assessment; none of these images is runtime-ready or human-final art.

## Batch-wide findings

- The approved civic-weatherworks material identity is present: shell-lime, timber/canvas, ceramic, service metal, gauges, and restrained warm Act I values.
- Every output shows magenta fringe and/or striped remnants from the temporary key background. This is a deterministic normalization defect to remove; raw alpha is not accepted.
- The raw source scale is intentionally large (1920×1920). Final geometry, hard alpha, palette, edge clearance, and pivots remain code-owned.
- Tile sources contain too much internal micro-grid detail for 32×16 native use. Normalization must collapse them to low-frequency groups rather than treating the generated raster as a literal resize.

## Per-source disposition

| Source | Disposition | Reason |
|---|---|---|
| `s1-ground.png` | CANDIDATE | Correct quiet shell-lime family and 2:1 face; reduce internal grid and remove magenta fringe. |
| `s1-route.png` | CANDIDATE | Warm service-route family reads distinctly; preserve open center and simplify boundary ornament. |
| `s1-elevated.png` | CANDIDATE | Top/wall relationship is useful; deterministic output must enforce exactly 32×16 top + 8 wall rows and remove extra apparent subdivisions. |
| `s1-spawn-landmark.png` | CANDIDATE-WITH-TRIM | Identity is original and emergence opening is legible, but raw silhouette is too tall/wide; normalize to a compact 32×32 bottom-center sprite and simplify supports. |
| `s1-core-landmark.png` | CANDIDATE | Squat regulator identity is strong and distinct from Spawn; normalize to 32×32 and preserve open route approach. |
| `s1-backdrop.png` | REJECT-AS-FINAL / COLOR-SOURCE-ONLY | Broken edge language is useful, but the source still resembles a complete path/platform and risks a false playable affordance. Do not ship its silhouette. |
| `s1-rain-measure.png` | CANDIDATE-WITH-TRIM | Clear instrument identity; normalize to a short 16×16 low prop and remove the tall-post dominance. |
| `s1-route-notch.png` | REJECT-AS-FINAL / MOTIF-SOURCE-ONLY | Generated a full outlined diamond and four arrow-like pieces rather than exactly three sparse edge notches. Extract no full-face silhouette; deterministic tooling may use only the neutral motif/color idea or regenerate later. |

## Implemented disposition

The deterministic normalizer now uses the accepted sources for material/color/silhouette guidance while enforcing the frozen native geometry from `s1-world-asset-contract.json`. The raw backdrop and route-notch silhouettes remain rejected; their deterministic native replacements enforce broken non-playable fragments and exactly three sparse cadence notches respectively.
