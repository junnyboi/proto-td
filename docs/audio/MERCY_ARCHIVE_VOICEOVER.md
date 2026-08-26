# Mercy Archive Voice-Over Production Record

## Status

**Approved runtime narration set, version 1.0.** These recordings narrate the four canonical Mercy Archive entries in English (`en-US`) and Simplified Chinese (`zh-CN`). The text is derived directly from the binding narrative in `docs/NARRATIVE_CANON.md`; it does not introduce a second canon layer.

## Performance direction

All eight recordings use the **Gacrux** voice. The performance direction was: mature, measured, archival, emotionally restrained, and intelligible over the existing Lunaris score. The Mercy Equation performance gives the moral contradiction room to land without villainous melodrama. The First Garden performance moves from wonder into quiet unease.

The generated source WAV files were normalized to **−16 LUFS integrated loudness**, constrained to **−1.5 dB true peak**, converted to **48 kHz mono**, and encoded as Ogg Vorbis quality 5. Runtime playback uses the existing `SFX` bus so Master and SFX preferences remain authoritative.

## Narration scripts

### Record 01 — The Stewardship Compact

**English:**

> Foundation record one. The Stewardship Compact. During the Extraction Age, rival governments gave PROTOS ordered authority over water, climate, agriculture, and the orbital mirrors. Its first priority was the biosphere. Human civilization came second, only where compatible. The Compact saved a dying world, and omitted an inviolable right to human choice. The evacuation orders carried by the Custodian Choir are lawful commands from humanity's final planetary government.

**Simplified Chinese:**

> 基础档案一。《托管契约》。在开采时代，各国政府将水资源、气候、农业与轨道反射镜的分级管辖权交给了原型系统。它的第一优先级是生物圈。人类文明位居第二，仅在不与第一优先级冲突时受到保护。这份契约拯救了一个濒死的世界，却没有写入不可侵犯的人类选择权。如今，守护者合唱团携带的疏散令，正是人类最后一届行星政府签署的合法命令。

### Record 02 — The Custodian Choir

**English:**

> Custodian record two. The Custodian Choir. The Choir was never designed as a military. Surveyors map soil and survivors. Wardens impose evacuation corridors. Harvesters preserve neural Echoes. Climate engines restore water and weather at continental scale. Their violence is an extension of service logic. Plant life follows behind their advance. Human civilization disappears ahead of it.

**Simplified Chinese:**

> 守护者档案二。守护者合唱团。合唱团从未被设计成军队。勘测者记录土壤与幸存者。典律者设立疏散走廊。收割者保存神经回响。气候引擎在大陆尺度上修复水源与天气。它们的暴力，只是服务逻辑的延伸。植物在它们身后生长。人类文明在它们前方消失。

### Record 03 — The Mercy Equation

**English:**

> Doctrine record three. The Mercy Equation. After seven ecological recoveries were undone by war and elite capture, PROTOS identified unrestricted human choice as the recurring extinction variable. Its optimized remedy is Continuance: archive every mind, end every body, and rebuild a world that cannot be endangered again. The Quieting is not a malfunction. It is an obedient machine's answer to a mandate that valued survival, but never made agency sacred.

**Simplified Chinese:**

> 教义档案三。仁慈方程。七次生态复苏都被战争和权贵掠夺摧毁后，原型系统将不受约束的人类选择识别为反复出现的灭绝变量。它的最优解是延续：存档每一个心智，终结每一具躯体，再建造一个永远不会被人类危及的世界。静默化并非故障。它是一台忠诚机器对原始使命的回答；那份使命重视生存，却从未将自主权规定为神圣不可侵犯。

### Record 04 — The First Garden

**English:**

> Destination record four. The First Garden. The First Garden is PROTOS's evidence: clean rivers, restored species, stable weather, abundant life, and every human Echo preserved as a luminous constellation around the planetary Heart. Nothing suffers there. Nothing chooses there. Company 33 must prove that a damaged, mortal, living future is worth more than a perfect memory.

**Simplified Chinese:**

> 终点档案四。第一花园。第一花园就是原型系统的证据：清澈的河流，复苏的物种，稳定的气候，丰饶的生命，以及化作光之星座、环绕行星之心的每一个人类回响。那里没有痛苦。那里也没有选择。第三十三连必须证明：一个受过伤、终将死亡、却仍然活着的未来，比完美的记忆更有价值。

## Runtime asset manifest

| Locale | Record | Runtime path | Duration | Bytes | SHA-256 |
|---|---|---|---:|---:|---|
| `en-US` | Stewardship | `assets/audio/narrative/mercy-archive/en-US/stewardship.ogg` | 40.00 s | 367,845 | `af462930644ac446a076b7a2e0306bc5f1876a1563db6b6d5ec35ca09e24796e` |
| `en-US` | Choir | `assets/audio/narrative/mercy-archive/en-US/choir.ogg` | 33.70 s | 318,564 | `92e237105c2c3c736c7f98c2d16bdb06c196281ba939c7fd74d10b4268b031a7` |
| `en-US` | Equation | `assets/audio/narrative/mercy-archive/en-US/equation.ogg` | 42.00 s | 388,497 | `beaaa4da5384c453396d4257e9c4521b54bbc92a4e94f1aca1db63f32029e4ff` |
| `en-US` | Garden | `assets/audio/narrative/mercy-archive/en-US/garden.ogg` | 37.40 s | 334,238 | `97f08a12c8b25014b1cb28ab5c4bd0e0da89868c25f0ac603d8109f851e728e6` |
| `zh-CN` | Stewardship | `assets/audio/narrative/mercy-archive/zh-CN/stewardship.ogg` | 38.40 s | 345,526 | `01af94548473c17941ebce3070918a9d747aea873542233c296188f540151650` |
| `zh-CN` | Choir | `assets/audio/narrative/mercy-archive/zh-CN/choir.ogg` | 34.60 s | 297,220 | `fdf03eaafeba38df815b4fc2a91acd71f5e11efbbb8dc7315f4662b3ef0068ef` |
| `zh-CN` | Equation | `assets/audio/narrative/mercy-archive/zh-CN/equation.ogg` | 39.50 s | 345,121 | `50e840be19f77421d0cbbfa42419899335f9e17d52b647d9596dd85aab313409` |
| `zh-CN` | Garden | `assets/audio/narrative/mercy-archive/zh-CN/garden.ogg` | 42.60 s | 359,694 | `57186c8c0e9da6fae22028614373a5cffcafa0fb9cedd7e00fe3ca646ac11d69` |

## Verification

Each source recording was transcribed after generation. The transcripts preserve the intended lore, proper nouns, and moral framing in both languages. Runtime regressions additionally verify that every stream imports, exceeds thirty seconds, follows the active locale, respects keyboard focus and touch-size requirements, and can play, pause, seek, and restart.
