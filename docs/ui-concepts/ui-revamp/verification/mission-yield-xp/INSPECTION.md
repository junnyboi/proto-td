# Mission Yield XP Projection — Verification

The authoritative campaign receipt stores survivor experience awards as `{ "hero_id": ..., "delta": 100 }`. The Results projection previously queried legacy `xp`/`amount` keys, causing its reveal target to become zero even though the campaign state and Training screen correctly contained 100 XP.

The corrected Results projection reads `delta` directly. Godot 4.7.2 Xvfb captures at **1280×720** and **720×1280** show the settled Mission Yield survivor row as **+100 XP**. The reward remains inside the existing local scroll surface in both orientations. Focused Results regression coverage now uses the canonical receipt schema, verifies two survivor rows, checks reveal ordering, and requires both counters to settle at `+100 XP`.
