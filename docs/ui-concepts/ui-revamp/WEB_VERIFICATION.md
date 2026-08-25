# Web Export Verification

**Candidate:** `ed0a3aa9292a0393a6fbd48c09fbc5e97e7657dc`  
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`  
**Transport:** `http://127.0.0.1:8123/index.html`

The release export contains non-empty `index.html`, `index.js`, `index.wasm`, and `index.pck` artifacts with SHA-256 checksums. The managed browser loaded the bundle over HTTP, initialized Godot 4.7.2 using WebGL 2.0 and the single-threaded Emscripten 4.0.20 target, and reported no loader, MIME, resource, or runtime errors.

Resource timing confirmed complete transfer of `index.png` (5,632,731 decoded bytes), `index.js` (279,815 bytes), `index.wasm` (39,514,754 bytes), and `index.pck` (98,209,520 bytes). The document reached `readyState=complete`; the canvas rendered at its full dynamic client size. Pointer focus followed by Enter navigated from the title screen to Company Command, proving representative Web input and authoritative scene transition behavior.

The post-navigation console remained clean: only the expected Godot engine, WebGL renderer, and Emscripten build-identification messages were present. Canvas focus remained active after the transition, and no JavaScript exceptions, failed resource fetches, Godot script errors, or WebGL faults appeared.
