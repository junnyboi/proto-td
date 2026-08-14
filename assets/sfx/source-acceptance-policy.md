# Batch 01 acceptance policy

The user relaxed SFX quality gates on 2026-08-14 to prevent excessive rerolls and token waste.

## Blocking red

Only these conditions block delivery:

- missing or empty carrier/output;
- carrier has other than exactly one audio stream;
- carrier or audio does not fully decode;
- unsafe/reused path or attempted overwrite of immutable evidence;
- extracted master is not stereo 48 kHz PCM or is malformed;
- missing prompt/model/hash/provenance;
- clipping or corruption that makes the file technically unusable.

## Advisory warning

These do not trigger automatic regeneration:

- duration outside the target range;
- extra tail, low-level ambience, or suspected secondary event;
- tonal, material, intensity, spatial, or mix-fit mismatch;
- UI too prominent or combat insufficiently forceful;
- machine-estimated silence/onset anomalies.

Deliver technically valid candidates with warnings. Human listening is authoritative for subjective quality. Reroll only cues the user rejects.
