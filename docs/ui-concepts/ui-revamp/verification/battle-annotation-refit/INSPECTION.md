# Annotated Battle UI Refit — Visual Verification

The final candidate was captured through Godot 4.7.2 under Xvfb with the X11 display driver, compatibility renderer, and dummy audio. Four states cover the First Stand tutorial and unobscured live battle at **1280×720** and **720×1280**.

The landscape and portrait tutorial captures confirm that the battle HUD uses a doubled container height with centered metrics and a 48px left content inset. The manual **CENTER** map control is absent. The First Stand tutorial is left-anchored to the 24px viewport margin, retains its Lunaris modal frame, displays the approved route wording without clipping, and contains compact **SKIP TUTORIAL** and **NEXT** actions with 12px internal padding.

The live captures confirm that pause, speed, resign, operator, and trap controls use smaller typography, compact target geometry, and rounded borders. Every control remains within its parent frame. In landscape, deployment and spell decks are separated; in portrait, the command deck starts below the expanded HUD and the two-column deployment deck remains inside the bottom viewport.

All capture logs passed strict scans for script, resource, renderer, and runtime errors. `SHA256SUMS` records the four optimized WebP evidence files.
