# Premium Resonance Cinematic Media Generation

| Field | Value |
|---|---|
| **Phase** | 3 — cinematic video, music, and carrier-derived SFX |
| **Status** | Complete |
| **Visual output** | Six silent eight-second MP4 masters and six 24 fps Theora OGV runtime streams |
| **Audio output** | Three eight-second music/SFX runtime mixes, 48 kHz stereo Vorbis |
| **Runtime media size** | Approximately 60 MB combined |

## Generation route

Veo 3.1 first-and-last-keyframe generation was attempted first for every film. The Archive Caster landscape master completed successfully at 1920×1080. Repeated primary and Fast-tier capacity failures prevented the remaining five endpoint-controlled calls from starting. Those five motion masters were generated with Gemini Omni at 720p from the approved opening keyframes.

Godot deterministically replaces or freezes the motion layer onto the approved GPT Image 2 final plate at 7.440 seconds. Final identity, weapon geometry, exposure, composition, and UI-safe space therefore remain locked to the separately approved endpoint even for the five first-frame-only motion masters.

## Runtime streams

| Stream | Resolution | Duration | Codec | Bytes | SHA-256 |
|---|---:|---:|---|---:|---|
| `archive-caster-landscape.ogv` | 1280×720 | 8.000 s | Theora | 18,894,020 | `5eeeba0bd6a7fce74c80e07d5c23cb0e54007a9287a2878c8a6bf2042efa8cd0` |
| `archive-caster-portrait.ogv` | 720×1280 | 8.000 s | Theora | 9,298,910 | `5ac6f14efa7fc96782ad2978ac2f2d2103f5957416006333faabc0af27e0a5ec` |
| `lunaris-vessel-landscape.ogv` | 1280×720 | 8.000 s | Theora | 8,846,078 | `fb09e9d067bd1458bbc3d6a0b575281d248df8ea75b6c33e0bf2111209a8fb97` |
| `lunaris-vessel-portrait.ogv` | 720×1280 | 8.000 s | Theora | 8,498,953 | `87221b5164f157267963acf1bb7504b6220f66bd1fdb6e6c588d94a845c39c32` |
| `reliquary-duelist-landscape.ogv` | 1280×720 | 8.000 s | Theora | 7,485,451 | `186a0f063b900877513261e0ab2b7aefb0609de9d422f69ea65cd5e8d76a1e55` |
| `reliquary-duelist-portrait.ogv` | 720×1280 | 8.000 s | Theora | 8,496,742 | `09430cb2de8bdeb7c1d6c8db60a838a572f1c518aa2e474c04dbc4ffaea1a2f5` |

## Runtime audio

The three musical stings were generated as instrumental-only Lunaris cues, conformed to exactly eight seconds, and mixed with separately generated carrier-video SFX. Each carrier began from the approved landscape opening plate; its audio was extracted to 48 kHz stereo WAV and combined with the corresponding sting.

| Runtime mix | Duration | Codec | Bytes | SHA-256 |
|---|---:|---|---:|---|
| `archive-caster-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 152,083 | `99bb81f92f42e07611783cc36a07139f35e0a4bfd1793c57ef57bb7d0c854973` |
| `lunaris-vessel-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 149,924 | `e867ec288dc79cad217585aaaabe2fd4c81fb06910068f5f94f38df488a20386` |
| `reliquary-duelist-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 144,450 | `8021aa36b17997e2c3c9e6852a556d43fb32cc29fa10b94a2f0915824c184a2c` |

All runtime media passed technical integrity checks for duration, codec, dimensions, frame rate, sample rate, channel count, nonzero size, and checksum generation. Artistic acceptance is performed through the actual Godot presentation rather than automated frame analysis.
