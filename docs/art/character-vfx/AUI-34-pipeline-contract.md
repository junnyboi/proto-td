# AUI-34 Deterministic Character/VFX Pipeline Contract

**Owner:** Agent E / Agent 6

**Assurance route:** RELEASE

**State:** integrated by the containing aggregate commit after durable `AUI-00` closure; runtime binding remains unbound [1]

**Human final-art state:** `UNSET_HUMAN_ONLY`

## 1. Purpose and boundary

AUI-34 supplies an offline normalization and verification companion for future character and VFX production. It converts exactly eight ordered RGBA source frames into a fixed atlas, canonical metadata, measured QA, and a deterministic three-panel contact sheet. Python is the canonical PNG encoder; Godot is a content-equivalent fallback. Cross-backend equivalence is exact decoded RGBA plus normalized semantic metadata, not a false claim that two different PNG encoders must emit identical bytes.

AUI-34 produces **no approved Aetheria runtime art**. It does not install assets, alter the runtime manifest, bind presentation contracts, modify gameplay or simulation, flip final-art state, or claim player-facing acceptance. Those seams remain deferred to later explicitly claimed AUI packages.

## 2. Pinned environment

| Component | Required value |
|---|---|
| Python | 3.12.3 |
| Pillow | 12.3.0 |
| Godot | 4.7.1 stable regular build |
| GDScript lint | `gdlint` 4.5.0 |
| Network | unavailable and unnecessary during normalization and QA |
| Verification seed | 42; the pixel pipeline itself is seedless |

A version mismatch is an environment failure. Operators must not auto-install a different dependency, reinterpret output, or update expectations merely to make a run pass.

## 3. Immutable content contract

| Field | Pinned contract |
|---|---|
| Atlas | 768×384 RGBA8 |
| Grid | 4 columns × 2 rows |
| Cell | 192×192 |
| Row 0 | `rest_movement`, four frames, 5.5 fps, loop |
| Row 1 | `attack_skill`, four frames, 8 fps, loop |
| Pivot | normalized `[0.5,0.94]` |
| Foot row | source row 180, measured tolerance 179–181 |
| Horizontal anchor | opaque-bounds center x = 96 |
| Alpha | exactly 0 or 255 after normalization |
| Alpha threshold | values below 26 become 0; values at least 26 become 255 |
| Resize | integer nearest neighbor: `min(src_n-1,(dst_i×src_n)//dst_n)` |
| Palette | minimum squared RGB distance; first entry wins ties |
| Components | four-neighbor connectivity; remove only components smaller than the explicit threshold |
| Border | zero opaque pixels on every cell’s outermost ring |
| Reserved colors | exact `#F4F4F4` and `#41A6F6` absent from ordinary opaque art |
| Contact sheet | 1536×256; light, dark, grayscale panels in that order |

The contact sheet uses three 512×256 panels. Each panel contains a 4×2 grid of 128×128 review cells. The corresponding atlas cell is sampled to 72×72 with the pinned integer sampler and placed at local `(28,28)`. Light uses `#E8DFCF`; dark uses `#1B2230`; grayscale uses `#808080` and integer luma `(77R+150G+29B+128)//256`.

## 4. Strict input specification

The required `--input-root` CLI argument is trusted configuration and is never read from JSON. Frame paths in the spec must be non-empty POSIX-relative paths. Absolute paths, dot or dot-dot segments, empty path segments, doubled or trailing separators, backslashes, colons, NUL escapes, missing components, symlink loops, and realpath escapes fail closed.

Symlinks are permitted only when their complete relative or absolute chain resolves to a regular file strictly beneath the canonical input root. Sibling prefix collisions such as `root-evil` do not satisfy containment for `root`.

The JSON object has exact keys only: schema version, asset identity/class/state, eight frame records, atlas, animations, ordered palette, normalization, reserved colors, outputs, and provenance. Unknown keys, duplicate JSON members, duplicate cells, missing cells, bool/float integer lookalikes, malformed colors, altered approval hashes, or weakened geometry fail non-zero.

## 5. Output packet

| File | Required contents |
|---|---|
| `<asset>.png` | fixed 768×384 atlas |
| `<asset>.asset.json` | canonical contract, backend/version, run identity, source/spec/file/RGBA hashes, provenance, runtime and human state |
| `<asset>.qa.json` | non-zero measured checks and cell/contact diagnostics |
| `<asset>.contact.png` | fixed 1536×256 light/dark/grayscale review raster |

Canonical JSON is UTF-8, sorted, compact, and terminated by one LF. Python PNG bytes are pinned through Pillow settings. Godot PNG bytes are separately same-backend deterministic. Both emitted PNGs are decoded, canonicalized to RGBA8, and compared exactly across backends.

## 6. Operator commands

### Python build

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B tools/art_pipeline/character_vfx/normalize.py build \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-python --clean
```

### Python reopen validation

```bash
python3 -B tools/art_pipeline/character_vfx/normalize.py validate \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-python
```

### Godot build

```bash
export GODOT="${GODOT:-$HOME/bin/godot}"
timeout 60 "$GODOT" --headless --path . \
  -s res://tools/art_pipeline/character_vfx/godot/normalize.gd -- \
  build --backend godot \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-godot --clean
```

### Godot reopen validation

```bash
timeout 60 "$GODOT" --headless --path . \
  -s res://tools/art_pipeline/character_vfx/godot/normalize.gd -- \
  validate --backend godot \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-godot
```

### Differential gate

```bash
timeout 180 python3 -B staging/qa/character-vfx/verify_pipeline.py \
  --backend differential --clean --seed 42 \
  --input-root staging/qa/character-vfx/fixtures/source \
  --process-timeout-seconds 60 \
  --evidence-root /tmp/aui34-differential \
  --godot "$GODOT"
```

The evidence root must be outside the repository for a RELEASE run. Reusing a stale evidence root without `--clean`, allowing bytecode caches inside the worktree, or accepting a timed-out subprocess invalidates the run.

## 7. Verification coverage

The independent verifier does not derive expectations from production output. It pins source hashes, integer primitive cases, all eight anchor translations, per-cell opaque counts and bounds, semantic sample pixels, palette inventory, decoded RGBA hashes, contact-sheet samples, and Python canonical PNG hashes. [4] [5]

The current fixture matrix covers same-backend cross-process whole-directory byte identity, Python/Godot decoded-RGBA differential, canonical sidecars, malformed schema and path cases, empty and border-contact frames, emitted alpha/palette/dimension/hash corruption, unknown packet entries, PNG re-encoding, replacement preservation, late-candidate corruption, injected Python publication faults, Godot in-root symlink chains, escape/loop/prefix collision cases, root/child symlink cleanup, unreadable-backup retention, and complete salvage recovery after a forced Godot failure following partial rollback deletion. The independent salvage decoder also runs an explicit malformed-archive matrix covering duplicate JSON members, bool/float/string schema lookalikes, unknown/missing keys, scalar entries, duplicate/unsorted paths, wrong field types, invalid base64, and noncanonical pad-bit aliases. Valid file payloads must strict-decode and re-encode byte-identically to their submitted base64 token.

A pass requires a positive `checks_executed` value. A hang, timeout, missing summary, malformed report, stale packet, skip, or zero checks is red.

## 8. Publication and recovery semantics

Each backend writes to a sibling candidate directory, emits all files, reopens both PNGs, recomputes hashes and measured checks, validates the exact inventory, and publishes only after the immutable candidate passes.

When replacing an accepted output with `--clean`, the old packet moves to a unique rollback sibling before the candidate moves into place. Before any destructive rollback cleanup, each backend writes a canonical sibling salvage JSON that records every directory, exact file byte payload, and symlink target without following links; the file is atomically renamed and read back byte-for-byte. Godot compares `FileAccess.get_file_as_bytes()` directly with the canonical JSON `PackedByteArray`, and the direct contract probe exercises this path with a binary rollback payload. If salvage creation fails, the command returns non-zero and the complete rollback remains intact. After verified salvage, Godot preflights the entire rollback tree and deletes it without following links. If deletion fails after partial progress, the command returns non-zero, the new packet remains valid, and the complete prior packet remains independently recoverable from the salvage. Salvage is removed only after rollback cleanup succeeds; a salvage-removal failure is also red and deliberately leaves the complete archive.

Operators must treat any retained rollback or salvage as **failed publication cleanup**, not success. Validate the new packet, preserve both recovery forms, resolve the filesystem problem, and decode or restore the complete salvage deliberately. Never delete an unknown rollback or salvage blindly.

## 9. Troubleshooting

| Symptom | Meaning | Required action |
|---|---|---|
| `path-escape`, `symlink loop`, or canonical component error | Source containment failed | Correct the staged source layout; never widen containment |
| `lexical-type` or duplicate-key error | Spec token or exact-key contract failed | Fix the source spec; do not normalize it silently |
| `border-contact`, foot, center, alpha, palette, or reserved-color error | Measured pixel contract failed | Correct source art/normalization inputs; do not retune the gate |
| `canonical-bytes mismatch` | Sidecar or backend PNG was changed/re-encoded | Regenerate the complete packet through the same backend |
| `backup salvage failed` | New packet committed; complete old rollback retained before deletion | Treat run as red, validate new packet, recover deliberately |
| `backup cleanup failed` | New packet committed; rollback may be partial; complete verified salvage retained | Treat run as red, validate new packet, recover from salvage deliberately |
| `salvage cleanup failed` | New packet and complete salvage remain after rollback cleanup | Treat run as red and remove the verified salvage deliberately |
| Child process timeout | Missing proof | Investigate the hang; never extend a pinned threshold merely to pass |
| Python and Godot file hashes differ but RGBA matches | Expected encoder distinction | Require same-backend byte identity and cross-backend RGBA identity |

## 10. Integration result

AUI-00 is durably closed. The canonical repository decision records all six exact approved Round 5 hashes, and the owner appointed Agent 6 to receive the immutable Agent E terminal receipt. The aggregate preserves exact reserved colors `#F4F4F4` and `#41A6F6`, keeps these files as staging contracts rather than runtime provenance sidecars, and changes no production asset or final-art status. [1] [2]

The containing aggregate commit is publishable only when its external final-union record proves fresh differential and full repository RELEASE gates, fresh image review, and a non-implementer diff-vs-pins pass at that exact commit. Never infer this result from the lane receipt and never force-push.

## References

[1]: ../../plans/AUI-IMPLEMENTATION-STATUS.md "AUI implementation status and integration boundary"
[2]: ../../handoffs/AUI-34-agent-e-art-pipeline.md "Agent E AUI-34 handoff"
[3]: ../../../tools/art_pipeline/character_vfx/README.md "Character/VFX pipeline CLI summary"
[4]: ../../../staging/qa/character-vfx/fixtures/spec.json "Pinned synthetic fixture spec"
[5]: ../../../staging/qa/character-vfx/fixtures/expected.json "Independent fixture expectations"
