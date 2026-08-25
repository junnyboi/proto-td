# Web Export Verification

**Final runtime source:** `fff95c16242a59cdd63e8e4a69e6b80f49ad2c43`
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`
**Host:** existing WebDev project `proto-td-web` (`SQTJrsLaB53KudBffRrZrS`)
**Checkpoint:** `f74dd226`

The release export contains non-empty `index.html`, `index.js`, `index.wasm`, and `index.pck` artifacts with SHA-256 records. The definitive base PCK is 98,213,344 bytes. Direct HTTP testing established the Godot 4.7.2, WebGL 2.0, single-threaded Emscripten runtime contract; the final managed HTTPS preview then loaded the exact definitive PCK, patched loader, WASM, splash, worklets, and checksum-pinned Act I–III music-pack URLs.

Native release gates passed direct import, bounded boot, all 20 focused tests, English/Chinese catalog and placeholder parity, CJK glyph coverage, and error scans with zero failures. Twenty accepted Xvfb captures cover the redesigned campaign and battle families at `1280×720` and `720×1280`.

Managed-browser verification confirmed that outer viewport, iframe, and canvas share identical dimensions and origin with zero border, margin, or scroll. Pointer focus followed by Enter navigated from the title to Company Command. The console remained free of JavaScript, Godot, resource, MIME, and WebGL errors.

The verification pass exposed and corrected a Web-only lazy-pack persistence defect: the pack returned HTTP 200 with exact byte count and SHA-256, but `HTTPRequest.download_file` did not materialize the temporary file before validation. Runtime revision `fff95c1` writes the Web response body explicitly, flushes and verifies it, then promotes it through rename or a verified copy fallback before mount. After redeployment, the title and Company Command displayed no interrupted-download status, while current music-pack delivery, retry wiring, title-music continuity, and persisted ON/OFF preference remained integrated.

The final WebDev checkpoint is ready for publication. No separate direct publish tool is exposed in this session, so checkpoint `f74dd226` is the verified Publish-control handoff.
