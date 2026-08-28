# Advanced Operator Sprite V2 Release Record

| Metadata | Value |
|---|---|
| Author | Manus AI |
| Canonical repository | `junnyboi/proto-td` [1] |
| Runtime integration commit | `9b423c46df0274332448600fdedee63df014ae49` |
| Engine | Godot `4.7.2.stable.official.ed1daf0bf` [2] |

## Release summary

The V2 production replaces every recruit-derived advanced-specialization animation with a newly generated, gender-matched sprite family. Eleven classes now each provide adult female and male identities, subtle idle motion, class-specific attacks, generated `NE` and `SE` isometric facings, and deterministic `NW` and `SW` mirrors. The runtime remains presentation-only: no campaign, command, receipt, economy, battle-hash, or save-state authority changed.

| Contract | Final result |
|---|---:|
| Advanced classes | 11 |
| Gendered character variants | 22 |
| GPT Image 2 neutral keyframes | 44 |
| Silent four-second source carriers | 88 |
| Runtime atlases | 176 |
| Idle frames per atlas | 24 |
| Attack frames per atlas | 13 |
| Atlas cell size | 640 × 640 px |
| Visible subject edge | 560–640 px |
| Live-quality Xvfb captures | 77 |

## Art and motion acceptance

The character family follows the existing tactical adult-chibi rendering language while maintaining a lower ornament and effect ceiling than premium heroes. Equipment silhouettes remain class-specific: Signal Railbow, training ring-staff, Oath-Pike Standard, Concord Ward Censer, Meridian Longblade, and the other approved specialization weapons remain visible through their attacks. Root positions are stationary, cameras remain orthographic and isometric, and west-facing assets are deterministic mirrors rather than independent generative interpretations.

Independent class-level review and a parent visual review rejected only material defects. Fifteen attack carriers were regenerated to remove oversized beams, unstable scale, missing equipment, and unreadable action beats. The two Mage Apprentice `SE` attacks use a tested deterministic final-neutral stabilization: generated frames 1–11 are retained, while frame 12 reuses the approved frame-0 neutral cell to guarantee facing recovery.

## Provenance and source custody

High-resolution reference boards, raw and normalized GPT Image 2 keyframes, generated carriers, per-sequence validation records, prompt ledgers, contact sheets, and SHA-256 manifests are stored in the Manus project-file archive `advanced-operator-sprites-v2`. The canonical `source_manifest.json` records 22 references, 44 keyframes, 88 carriers, and 176 runtime sequences. Its carrier ledger records 21 Gemini Omni Flash Preview, 32 Veo 3.1, and 35 Veo 3.1 Fast generations. Rejected attempts are retained in the sibling project-file archive `advanced-operator-sprites-v2-rejected` and are excluded from production validation.

## Verification evidence

| Gate | Result |
|---|---|
| Direct Godot import and parser scan | Passed with no script, parser, resource, or fatal diagnostics |
| Bounded main-scene boot | Passed |
| Advanced schema and runtime animation contracts | Passed |
| Batch carrier/atlas validator | 88 carriers and 176 outputs passed |
| Web import policy | All 176 atlases use Q92 lossy import, mipmaps, and no destructive size limit |
| Compression quality | 176/176 passed; minimum PSNR 36.466 dB, maximum RGB MAE 0.008134, zero alpha MAE, worst edge ratio 0.9811 |
| Close-up Xvfb class matrices | 11/11 passed |
| Live landscape and portrait Xvfb matrix | 66/66 passed |
| Repository-wide native suite | 82 Godot/import/smoke gates passed with zero diagnostics; the Python processor suite passed independently in 126 seconds after the aggregate runner’s transient timeout |
| Python processor suite | 12/12 tests passed, including final-neutral stabilization and source immutability |

## Web release implications

The browser build keeps advanced classes in eleven deferred Godot content packs rather than inflating the base pack. Runtime source `b608116677fba89088bfdf664579c93b533d26b6` produced a 236,443,592-byte core and eleven class packs totaling 353,463,580 bytes. Direct and managed HTTP length, MIME, byte-range, and SHA-256 checks passed. The newest forward-only `proto-td-web` host retained its loader architecture, predictive prefetch, sixteen mission films, six character films, zero-chrome fullscreen iframe, and concurrent improvements; the verified result was saved as WebDev checkpoint `74499b92`.

## References

[1]: https://github.com/junnyboi/proto-td "PROTO TD canonical source repository"
[2]: https://docs.godotengine.org/en/latest/ "Godot Engine documentation"
