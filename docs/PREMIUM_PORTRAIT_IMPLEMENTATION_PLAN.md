# Premium Hero Portrait Implementation Plan

## Objective

Regenerate the three canonical premium-gacha identities—**Lunaris Vessel**, **Reliquary Duelist**, and **Archive Caster**—as mature, custom UI portraits using **GPT Image 2**, then use those identities consistently in **Field Team**, **Training**, **Premium Resonance browse cards**, and the **Moon Archive** without changing campaign authority, hero identities, rarity, kit, pull receipts, or save data.

## Canonical inputs

The design authority is `docs/LUNARIS_CHARACTER_DESIGNS.md`, `docs/ART_DIRECTION.md`, and the three 1632×2176 full-size sheets under `docs/lunaris-reliquary/`. The Lunaris loading illustration may guide atmosphere and rendering finish, but the individual design sheet remains authoritative for face, hair, costume construction, palette, body type, and signature equipment.

## Asset matrix

| Hero | Immutable GPT Image 2 source | Field Team / Training | Premium Resonance / Moon Archive |
|---|---|---|---|
| Archive Caster | `docs/portraits/premium/sources/archive_caster.png` | 512×512 PNG | 640×800 lossless WebP |
| Lunaris Vessel | `docs/portraits/premium/sources/lunaris_vessel.png` | 512×512 PNG | 640×800 lossless WebP |
| Reliquary Duelist | `docs/portraits/premium/sources/reliquary_duelist.png` | 512×512 PNG | 640×800 lossless WebP |

Every source is 1920×1920. The runtime derivatives are generated deterministically by `tools/build_premium_portraits.py`; the manifest is refreshed by `tools/update_premium_portrait_manifest.py`. Hashes and dimensions are frozen in `docs/portraits/premium/ASSET_REPORT.json` and `docs/portraits/premium/SHA256SUMS`.

## Implementation phases

| Phase | Work | Exit criteria |
|---|---|---|
| A — Audit | Identify all three premium portrait IDs and consumers; inspect canonical sheets and current UI crops. | Field Team, Training, Resonance browse, and Moon Archive are mapped. |
| B — Generate | Generate one mature square portrait per hero using GPT Image 2 and each canonical full-size sheet. | Exact identity, costume, palette, adult age, signature equipment, safe crop, no text or frame. |
| C — Derive | Preserve 1920px sources; build 512px identity assets and top-biased 640×800 compatibility assets. | Deterministic rebuild is byte-stable; all files unique by SHA-256. |
| D — Integrate | Retarget the manifest to generated identity files and tune Premium Resonance framing for the custom compositions. | The same canonical portrait appears throughout roster and resonance surfaces without save-schema changes. |
| E — Verify | Run import, bounded boot, portrait catalog, Field Team, Training, gacha, localization, visual matrices, and the complete repository suite. | No parse, resource, runtime, layout, or log errors; desktop and portrait screenshots accepted. |
| F — Release | Reconcile latest `master`, push, Web export, HTTP runtime checks, forward-only WebDev overlay, type/build, managed preview, checkpoint, publish if available. | Exact pushed source and PCK are verified in the existing zero-chrome host. |

## Implementation status

| Phase | Status | Evidence |
|---|---|---|
| A — Audit | Complete | All three canonical design sheets, six manifest IDs, and Field Team, Training, Resonance, and Moon Archive consumers were traced. |
| B — Generate | Complete | Three unique 1920×1920 GPT Image 2 sources passed identity, maturity, costume, equipment, and safe-crop review. |
| C — Derive | Complete | The builder is byte-stable across consecutive runs; 512×512 and 640×800 derivatives, report, catalog, and SHA-256 ledger are present. |
| D — Integrate | Complete | Manifest IDs now resolve generated assets; all target UI surfaces consume the same square identity portraits; obsolete chibi premium files are removed. |
| E — Verify | Complete | Focused portrait/gacha/roster/localization tests, six responsive Xvfb captures plus hero-specific companion frames, and the complete Godot 4.7.2 baseline pass with no error signatures. |
| F — Release | In progress | Upstream reconciliation, push, exact-source export, managed-host overlay, and final checkpoint remain. |

## Deterministic rebuild

The supported release environment is Python 3.12.3 with `Pillow==12.3.0`, `numpy==2.5.1`, and Ubuntu `libwebp` 1.3.2. Python dependencies are pinned in the tracked [`tools/requirements-portraits.txt`](../tools/requirements-portraits.txt); PNG output is lossless and WebP compatibility derivatives use the pinned Pillow/libwebp encoder path.

```bash
python3 -m pip install -r tools/requirements-portraits.txt
python3 tools/build_premium_portraits.py
python3 tools/update_premium_portrait_manifest.py
sha256sum -c docs/portraits/premium/SHA256SUMS

# A second run must produce the same ledger and a clean working tree.
cp docs/portraits/premium/SHA256SUMS /tmp/premium-portraits.first
python3 tools/build_premium_portraits.py
python3 tools/update_premium_portrait_manifest.py
cmp /tmp/premium-portraits.first docs/portraits/premium/SHA256SUMS
git diff --exit-code -- assets/portraits docs/portraits/premium/ASSET_REPORT.json \
  docs/portraits/premium/CATALOG.png docs/portraits/premium/SHA256SUMS
```

## Acceptance rules

The source art must remain clearly adult (21+), premium painterly anime realism, mature but non-explicit, and faithful to the canonical sheet. Faces and signature equipment must remain legible at 128px. The Resonance crop must not cut the face, hand, core equipment silhouette, or produce cleavage-first framing. Runtime integration is presentation-only: premium ownership, fixed classes, stored lives, rarity, pull history, deterministic receipts, and save hashes remain untouched.
