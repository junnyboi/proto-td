# Battle Pause and Speed Cycle — Verification

The final candidate was captured with Godot 4.7.2 under Xvfb and the dummy audio driver after dismissing the First Stand tutorial. The speed selector was cycled through **1× → 2× → 4× → paused**, then allowed to settle before each capture.

The **1280×720** landscape frame shows **RESUME**, **0×**, **RESIGN**, and **PAUSED** fully contained in the top-right Lunaris command deck. The tactical HUD, deployment deck, spell deck, map, and wave presentation remain unobstructed.

The **720×1280** portrait frame preserves the same state in the responsive two-column command deck. All four labels remain legible and contained without horizontal overflow, clipped frame edges, or state-label collisions.

Native regression coverage additionally dispatches a physical Space key event while the Speed button owns keyboard focus. Space toggles pause and resume without activating the focused button. The same regression locks the complete selector cycle and its visible `0×` paused state. The authoritative resignation policy regression proves that surviving deployed recruits receive no XP for `terminal_reason = "resign"`, while an ordinary leak defeat still awards and applies **+100 XP**.
