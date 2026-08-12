# TD-014 — Six-cue retro Japanese lo-fi score handoff

- Agent / branch: AGENT 4 / `agent-4/retro-lofi-score`
- Base: `master` at `3936eeda3e25c5f45def229b168fd11c41a048d9`
- Frozen implementation: `61eefbb9d0f2e7d897ffbcb25e0034121c0774bf`
- Frozen tree: `5eb757c7e5abcccd22e8bc38566c540c962d0b50`
- Primary owner / lane: `godot-2d-art-audio` / STANDARD

## Delivered

Replaced every MUSIC-1 candidate with an original mid-to-late-1990s Japanese 32-bit console-RPG lo-fi cue: one BGM and boss transformation for each act. The shared palette uses FM/Rhodes keys, warm centered mono bass, original 12-bit-style rhythm, ROMpler color, restrained cassette drift, sampler aliasing, and grainy early-digital space. Act I maps to warm cloisters/aqueducts/garden waystations; Act II maps to crystal aquifers/fragmented observatory archaeology and mounting threat; Act III maps to near-lightless obsidian vaults/chains/primordial mechanisms/lava pressure.

All logical IDs and import loop flags remain stable. Exact prompts, selected source bytes, raw empty speech-transcription records, shipping Ogg files, hashes, supersession lineage, catalog revision 4, and the reference-distance statement are preserved. Every cue remains `placeholder: true`. Runtime playback and SFX remain intentionally out of scope under `D-SFX`.

## Frozen evidence

- Candidate evidence: `docs/media/TD-014-verification.json` (`mgs.verification-evidence.v2`, PASS, fresh, STANDARD)
- Music structural gate: six unique 48 kHz stereo Ogg Vorbis cues, 160–180 seconds, approximately −18 LUFS, loop-enabled, exact prompt/source/transcription hash parity, zero long digital silence, all green
- Focused catalog GUT: 3/3 tests, 239 assertions
- Raw speech detection: six sources, zero segments, empty `full_text`
- Complete ladder: 65 passing rungs; 20 scenario reports, 554 checks, 67 screenshots, zero failed checks, zero pixel skips, all sentinels present; bot and quality gates green
- Source identity: clean start/end at the frozen implementation commit and tree above; evidence stored outside the worktree and sealed by manifest hash

## Deviations and limits

- `D-MUSIC-10`: the owner requested Lyria 3 Pro or the latest available music model. The current built-in `generate_music` interface exposes neither model selection nor backend identifier. It used its latest available backend; provenance records `not exposed by tool` instead of asserting an unverifiable Lyria version.
- All six first attempts met machine acceptance; no generation retry and no per-track EQ were used.
- Objective signal analysis confirms stronger spectral movement/brightness in each boss cue versus its paired BGM, but cannot judge retro character, location charm, instrument identity, originality, reference distance, fatigue, or loop feel.
- Integration renumber history: Agent 2 first integrated the Aetheria Tactics identity as TD-012 after this lane branched, so the score moved from TD-012 to TD-013 before its first union merge. A later mandatory reconciliation found Agent 2's new Proto Defense identity independently using TD-013; before the score reached master, this lane was moved again to collision-free TD-014. Candidate audio commit `61eefbb` and its frozen commit/tree evidence remain unchanged.

## Remaining human gate

TD-004 owns the mandatory listening verdict. Listen to every cue for at least ninety seconds, cross each loop boundary twice, apply the falsifiable matrix in `assets/music/README.md`, and review actual backend commercial terms. Do not clear placeholders or mark MUSIC-1 passing without that human-authored evidence.

## Released surfaces after integration

All TD-014 music, prompt, source, transcription, catalog, provenance, guide, plan, handoff, evidence, and serial-ledger reservations may be released after verified master integration. Runtime playback remains a separately scoped future seam.
