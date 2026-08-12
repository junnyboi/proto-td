# TD-017 — Runtime music handoff

- **Agent / branch:** AGENT 4 / `agent-4/runtime-music`
- **Base:** `709781b596c0a3f21494a1be91713952f99d94e3`
- **Implementation:** `49a79d7e79388cdb167b400ca9e9930a11ee4bfc`
- **Corrected frozen candidate:** `bb5c384739311af54f3045832239451a34c5eb3c`
- **Candidate tree:** `c994c538b1c6ef425b6e670d08b7fc33b3f42a6f`
- **Authenticated RELEASE manifest:** `68c57f506755649a15229b072943689941d7206ba3e07aeb7a6669ff893b88cd`
- **Evidence:** `docs/media/TD-017-verification.json`

## Delivered behavior

`Music` is the sole runtime owner and creates exactly one `AudioStreamPlayer`. Logical catalog IDs are validated before state mutation. Re-requesting the current logical ID is a successful no-op; changing IDs stops and clears the old stream before reusing the same player; invalid requests change no observable state; `stop()` is idempotent. Every non-battle content swap stops music.

Stage data owns routing: S1–S4 use Act I, S5–S8 use Act II, S4 enters its boss cue at wave index 1/tick 290, and S8 at wave index 2/tick 800. `music_act = 3` already resolves the approved future Act III pair. No BattleModel, simulation, hash, save, replay, persistence, non-music balance, threshold, or SFX implementation changed.

Poseidon approved the six current cues and required exactly one non-layered, non-restarting player. Catalog and provenance placeholders are cleared; synthesized SFX remains deliberately silent.

## Verification

The authenticated cache-bypassed RELEASE root is external, content-addressed by the SHA-256 of its 300-entry artifact manifest, and fully read-only. It records contemporaneous start/end commit, tree, clean status, environment, policy/gate/impact hashes, safe command digests, and artifact hashes.

- full GUT: **150 tests, 22,841 assertions**
- scenarios: **21 headless + 21 windowed**, all pass
- required render skips: **0**
- fresh screenshots: **67**, human non-audio review pass
- bots/quality gates: **11 distinct pairs**, every verdict GO
- music structural/integrity gate: **ALL GREEN**
- aggregate `scripts/verify.sh --full`: **ALL GREEN**
- third independent diff/evidence audit: **PASS, zero findings**

Two earlier independent audits are deliberately retained as red history. The first rejected missing positive GUT/per-rung proof and one stale scenario comment; the second rejected missing contemporaneous provenance and read-only content addressing. Nothing was waived: both failures were corrected with fresh complete reruns.

## Residual risk

The sandbox fell back to Godot's dummy audio driver after ALSA initialization failed. Ownership, routing, replacement, counters, and non-layering are proven; audible output on a real OS/audio device remains a platform smoke test. The generation backend still did not expose an attestable Lyria model/version, and the commercial-model limitation remains documented.

## Integration instructions

Fetch current master, inspect hot-file overlap and active leases, merge master into this branch on conflict, resolve semantically, then run a fresh exact-union RELEASE ladder and non-implementer audit before the normal non-force branch/master pushes. Candidate-only evidence never proves the merged union.
