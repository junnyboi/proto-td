# High-Threat Wave Warning System

**Scope:** S9, S12, and S16 after the Act II balance pass

**Engine:** Godot 4.7.2

**Status:** Implemented and native-verified

## Purpose

The high-threat warning system marks the escalation windows where each newly balanced stage changes from its opening formation into a materially more dangerous assault. The feature is **presentation-only**: it reads authored wave boundaries but does not alter wave schedules, enemy stats, deterministic battle decisions, campaign hashes, saves, tickets, or snapshots.

## Authored escalation boundaries

| Stage | Warning identity | High-threat waves | HUD treatment | Spawn treatment |
|---|---|---:|---|---|
| **S9 — The Green Cage** | `green_cage` | 2 and 3 | Neon-green **CONTAINMENT SURGE** frame with botanical containment emblem | Green spore/lattice clusters and expanding containment emblems at both portals |
| **S12 — Unlit** | `unlit` | 2 and 3 | Icy-blue **BLACKOUT BREACH** frame with fractured-eclipse emblem | Blue-violet void shards and expanding eclipse emblems at all three portals |
| **S16 — Empire Foundry** | `empire_foundry` | 2, 3, and 4 | Molten-orange **FOUNDRY OVERDRIVE** frame with crowned reactor-spear emblem | White-hot sparks, forged fragments, and expanding foundry emblems at all four portals |

Wave indices are stored as zero-based `high_threat_wave_indices` on `StageDef`; player-facing copy remains one-based. Validation requires ascending, unique, in-range indices and a non-empty warning identity.

## Asset contract

Each warning style uses a dedicated **GPT Image 2** emblem and a separate GPT Image 2 particle-cluster texture. The untouched 1920×1920 masters are retained outside the repository in `/home/ubuntu/webdev-static-assets/proto-td-wave-warnings/source/`. Runtime derivatives are transparent 600×600 WebP files in `assets/vfx/high_threat/`, satisfying the project rule that in-game sprite sources remain approximately 600px on their longest edge.

Godot imports use high-quality compressed 2D storage (`compress/mode=2`, quality `0.92`) with mipmaps. Runtime controls use mipmapped linear filtering and control visual footprint through display size rather than destructive source reduction.

## Runtime sequencing

`BattleView._detect_wave()` uses the same deterministic wave boundary as the existing wave banner and Charm logic. Ordinary waves retain the existing banner. Authored high-threat waves instead invoke `JuiceLayer.high_threat_warning()`, which creates:

1. a centered, responsive HUD panel with localized heading and wave detail;
2. one expanding emblem pulse at every unique hostile path origin; and
3. four traveling particle clusters per origin under normal motion settings.

The existing mid-wave transmission is dismissed before the warning and deferred until the 96-frame warning window closes. This prevents panel collisions while preserving all authored narrative transmissions. Result stamps clear an active warning immediately.

## Accessibility and responsive behavior

With reduced motion enabled, the HUD warning and one static spawn pulse per portal remain visible, while traveling particle clusters and panel pulsing are suppressed. At 720×1280, the warning panel retains 18px side clearance and unwrapped heading/detail text. Map-local effects follow pan and zoom through `MapTransientRoot` and never intercept input.

## Verification

The permanent `high_threat_wave_warning_test.gd` regression covers all sixteen stage contracts, exact S9/S12/S16 boundaries, portrait-copy preservation, six 600px manifest assets, mipmapped HUD filtering, stage-specific warning identity, normal particle counts, and reduced-motion suppression. `stage_redesign_smoke.gd` now runs `high_threat_contract_errors()` for every stage.

Native Xvfb acceptance captured S9, S12, and S16 at 1280×720 plus S16 reduced motion at 720×1280. The accepted frames confirm unique palettes and silhouettes, readable copy, visible portal-local effects, unobstructed route cells, warning-first transmission sequencing, and portrait containment.
