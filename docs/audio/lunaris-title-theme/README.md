# Astra Memoriam — Lunaris title theme archive

`Astra Memoriam` is the original title-screen theme generated for the Lunaris Reliquary visual identity. It combines symphonic strings and brass, piano, glass bells, East Asian plucked color, hybrid tactical percussion, celestial synths, and a distant wordless choir. No existing artist, song, album, or recognizable melody was referenced.

| Asset | Role | Technical properties |
|---|---|---|
| `astra-memoriam-generated-source.mp3` | Unmodified generated source | MP3, 44.1 kHz stereo, 58.096 s, 192 kb/s |
| `astra-memoriam-loop-master.flac` | Lossless forward-loop production master | FLAC, 48 kHz stereo, 52.500 s |
| `../../../assets/music/lunaris_astra_memoriam_title.ogg` | Godot runtime derivative | Ogg Vorbis, 48 kHz stereo, 52.500 s, 1,224,405 bytes |

## Loop construction

The generated source closes quietly after its central title statement. Production starts at source time 5.0 seconds, retains forward audio through 57.5 seconds, and equal-power crossfades its final five seconds into source time 0.0–5.0. The resulting boundary ends and begins at the same musical pickup near source time 5.0, so the loop continues forward without reversing, a hard cut, or a terminal cadence.

## Runtime mix

The encoded Godot stream measures **−16.3 LUFS integrated**, **9.6 LU LRA**, and **−2.1 dBFS true peak**. This leaves useful headroom for interface confirmation sounds while preserving an epic orchestral center. The runtime SHA-256 is `4753c28118bbceb4a1ebbd3319bf8ace47d65c2dc02370fb480f3d28a7b6d2b5`.

`SHA256SUMS` covers the immutable generated source and lossless production master. The title cue is registered through the authoritative Music catalog with import looping enabled.
