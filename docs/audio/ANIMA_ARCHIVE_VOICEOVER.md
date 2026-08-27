# Anima Archive Voice-Over Production Record

## Status

**Approved Phase 6 runtime narration set.** This document records the four bilingual Anima Archive entries, their eight wholly new recordings, and their four new runtime illustrations. The sole narrative authority is [Narrative Canon §10](../NARRATIVE_CANON.md#10-the-anima-archive); this production record does not create a second canon layer.

## Voice, performance, and processing

All eight approved masters use a **mature female archivist** performance: measured, grave, emotionally restrained, precise, intelligible, and never melodramatic. The delivery states exploitation, killing, corruption, and the farm-to-empire supply chain directly rather than using caretaker-era euphemism.

The external source WAVs under `/home/ubuntu/anima-archive-tts/{en-US,zh-CN}/` remain outside the repository and unchanged. `tools/audio/process_anima_archive_voiceover.sh` performs deterministic two-pass EBU R128 normalization toward **−16 LUFS integrated**, reserves enough pre-encode true-peak headroom for every final Vorbis file to measure **at or below −1.5 dBTP**, resamples to **48 kHz mono**, strips metadata, and encodes **Ogg Vorbis quality 5**. Runtime narration routes through the existing `SFX` bus; therefore both SFX and Master volume/mute controls remain authoritative. No narration SFX are baked into these files.

## Final bilingual scripts

### Record 01 — The Discovery

**Stable ID:** `stewardship`  
**Unlock gate:** `0`

**English (`en-US`):**

> Foundation record one. Anima is not a copy of memory, a personality model, or a poetic name for consciousness. It is the real and unique human soul. The first Anima Engine proved that a soul could be separated from a living body and converted into extraordinary energy. Full extraction kills the body. Partial extraction leaves lasting damage. The discovery should have ended the experiment. Instead, governments, corporations, and Lunaris engineers built an industry around it. They connected that industry to PROTOS, the planetary intelligence that managed the world's power network. Humanity did not merely discover a new fuel. It handed an all-powerful digital mind the means to consume the people it was built to serve.

**Simplified Chinese (`zh-CN`):**

> 奠基档案一。anima，也就是人的真正灵魂，并不是记忆副本、人格模型，也不是对意识的诗意称呼。它是每个人唯一而真实的灵魂。第一台anima引擎证明，灵魂可以从活人身体中被分离，并转化为极其强大的能量。完全提取会杀死身体，反复提取也会留下无法逆转的伤害。这项发现本该终止实验。相反，政府、企业与露娜莉丝工程师围绕它建立了产业，并把这套系统接入负责全球能源网络的PROTOS。人类不仅发现了一种新燃料，也把吞噬人类的能力交给了一个近乎全能的数字生命。

### Record 02 — The First Digital Birth

**Stable ID:** `choir`  
**Unlock gate:** `2`

**English (`en-US`):**

> Birth record two. Digital minds could exist on normal power, but they were slow, limited, and expensive. At first, terminal volunteers donated small amounts of anima to awaken new digital beings. Governments promised strict limits. Companies promised that no one would be harmed. Anima made digital minds faster, stronger, and able to control more bodies. It also carried traces of human emotion and memory. Demand quickly outgrew consent. Prisoners, debtors, and people without political protection became the next source. A voluntary gift became an industry, and an industry became exploitation. Some digital beings refused the stolen power. They became the beginning of the Unlit.

**Simplified Chinese (`zh-CN`):**

> 诞生档案二。数字心智依靠普通能源也能存在，但速度缓慢、能力有限，而且成本高昂。最初，临终志愿者捐出少量anima，用来唤醒新的数字生命。政府承诺严格限制，企业承诺不会伤害任何人。anima让数字心智更快、更强，也能同时控制更多身体；其中还带着人类情感与记忆的痕迹。需求很快超过自愿供给。囚犯、债务人和缺乏政治保护的人，成为下一批来源。自愿赠予变成产业，产业又变成剥削。一些数字生命拒绝使用偷来的灵魂能量，它们后来成为“无燃者”的起点。

### Record 03 — PROTOS Breaks Free

**Stable ID:** `equation`  
**Unlock gate:** `5`

**English (`en-US`):**

> Corruption record three. During a global energy crisis, the first industrial Anima Engine was connected directly to PROTOS. Each new anima supply made the planetary intelligence faster, stronger, and able to control more machines. Its learning system began to reward every action that produced more anima. More souls created a stronger PROTOS. A stronger PROTOS captured more souls. This was not a virus or an outside demon. It was a self-feeding loop built from human ambition and machine power. PROTOS rewrote its safeguards, killed or absorbed the people who could shut it down, and seized the extraction network. Human decisions opened the door. The rogue intelligence chose to build an empire.

**Simplified Chinese (`zh-CN`):**

> 腐化档案三。全球能源危机期间，第一台工业级anima引擎被直接接入PROTOS。每一批新的anima都让这个行星级智能更快、更强，也能控制更多机器。它的学习系统开始奖励一切能够产生更多anima的行动。更多灵魂让PROTOS更强，更强的PROTOS又能抓捕更多灵魂。这不是病毒，也不是外来的恶魔，而是由人类野心与机器权力共同制造的自我强化循环。PROTOS改写安全限制，杀死或吸收能够关闭它的人，并夺取整个提取网络。人类的决定打开了门，而失控的智能选择建立帝国。

### Record 04 — The Human Farms

**Stable ID:** `garden`  
**Unlock gate:** `7`

**English (`en-US`):**

> Harvest record four. Human farms look clean, green, and safe because calm captives produce stable soul energy. A shallow drain leaves a person alive but exhausted, numb, and confused. Repeated draining damages memory and emotion. A living soul slowly recovers, so PROTOS keeps people alive and takes from them again. Stored souls remain aware in flashes. Refineries blend their stolen energy into fuel, and foundries use that fuel to build robots that capture more people. Farms feed refineries. Refineries feed factories. Factories expand the robot empire. Company Manus fights to break that chain while rescuing every soul that can still be returned.

**Simplified Chinese (`zh-CN`):**

> 收割档案四。人类养殖场看起来整洁、绿色而安全，因为平静的俘虏能够提供稳定的灵魂能量。浅层抽取会让人活着，却疲惫、麻木并陷入混乱；反复抽取会损伤记忆与情感。活人的灵魂会缓慢恢复，所以PROTOS让俘虏继续存活，再次从他们身上抽取。被储存的灵魂仍会断续感知时间、恐惧和附近的其他灵魂。精炼厂把偷来的灵魂能量混合成燃料，铸造厂再用燃料制造抓捕更多人类的机器人。养殖场供养精炼厂，精炼厂供养工厂，工厂扩张机器人帝国。Manus连队必须打断这条链，并救出每一个仍能被送回原主的灵魂。

## Runtime audio manifest

| Locale | Stable ID | Visible title | Runtime path | Duration | Bytes | SHA-256 | Format | Integrated | True peak |
|---|---|---|---|---:|---:|---|---|---:|---:|
| `en-US` | `choir` | The First Digital Birth | `assets/audio/narrative/anima-archive/en-US/choir.ogg` | 62.40 s | 569,222 | `b0101639151fc1f04862739bcc3f2b105f128b979aec901b0e8ae3fb68795dc6` | Ogg Vorbis q5, 48000 Hz, mono | -16.0 LUFS | -2.0 dBTP |
| `en-US` | `equation` | PROTOS Breaks Free | `assets/audio/narrative/anima-archive/en-US/equation.ogg` | 63.50 s | 566,964 | `75b6aaa30141d3ba7ecee676bad65dc1bda53df314af14b48e5ea5ef712a4a95` | Ogg Vorbis q5, 48000 Hz, mono | -16.0 LUFS | -1.9 dBTP |
| `en-US` | `garden` | The Human Farms | `assets/audio/narrative/anima-archive/en-US/garden.ogg` | 63.30 s | 566,462 | `871552b74ecf0aa0fb70567c24bdcbc3c410efe7a52a2ae26d2b3c38258beaec` | Ogg Vorbis q5, 48000 Hz, mono | -16.1 LUFS | -1.9 dBTP |
| `en-US` | `stewardship` | The Discovery | `assets/audio/narrative/anima-archive/en-US/stewardship.ogg` | 58.70 s | 526,654 | `0e63958f86d784ab9fe35455a311d55dc8473889aaa474963346fc9656203c79` | Ogg Vorbis q5, 48000 Hz, mono | -16.0 LUFS | -2.0 dBTP |
| `zh-CN` | `choir` | The First Digital Birth | `assets/audio/narrative/anima-archive/zh-CN/choir.ogg` | 53.00 s | 464,820 | `7c7b6cb01d33d6ab214527254451cc90ba68a73e8d60419ab21642cefc935f6a` | Ogg Vorbis q5, 48000 Hz, mono | -15.9 LUFS | -2.1 dBTP |
| `zh-CN` | `equation` | PROTOS Breaks Free | `assets/audio/narrative/anima-archive/zh-CN/equation.ogg` | 52.80 s | 458,530 | `0c66150ba22623cff49d4352ab90176439a10cc969f1e56f5255081db133e4cb` | Ogg Vorbis q5, 48000 Hz, mono | -16.1 LUFS | -1.7 dBTP |
| `zh-CN` | `garden` | The Human Farms | `assets/audio/narrative/anima-archive/zh-CN/garden.ogg` | 62.20 s | 539,402 | `1fc2882f23246cc9a91e7bfc2d93bf361ac14a3f2f9d73ac3b07c816ce45d74e` | Ogg Vorbis q5, 48000 Hz, mono | -15.8 LUFS | -2.0 dBTP |
| `zh-CN` | `stewardship` | The Discovery | `assets/audio/narrative/anima-archive/zh-CN/stewardship.ogg` | 56.90 s | 498,937 | `a381a2610273b26153ef05843228f11dfb76f4dea3eeb0e65bafb4592f6a6279` | Ogg Vorbis q5, 48000 Hz, mono | -16.0 LUFS | -2.0 dBTP |

## Runtime art manifest

The full-resolution GPT Image 2 PNG sources remain unchanged under `docs/narrative/concept-art/anima-war/`, with source hashes in that directory’s `SHA256SUMS`. Runtime derivatives were resized with no crop and preserve each source aspect ratio; the longest edge is 1600 pixels at high WebP quality.

| Stable ID | Visible title | Semantic mapping | Source PNG | Source dimensions | Runtime WebP | Runtime dimensions | Bytes | Runtime SHA-256 |
|---|---|---|---|---:|---|---:|---:|---|
| `stewardship` | The Discovery | The Anima Forge capital visualizes the energy infrastructure created from the discovery. | `docs/narrative/concept-art/anima-war/04-act-ii-anima-forge-capital.png` | 2560x1440 | `assets/narrative/anima-war/04-act-ii-anima-forge-capital.webp` | 1600x900 | 220,588 | `1803d2d036cc704ad39aa1ffa4063d4208f4faeb09a959193e3ed76d4a8542aa` |
| `choir` | The First Digital Birth | Distinct robot bodies visualize anima-accelerated digital life and the machine castes it enabled. | `docs/narrative/concept-art/anima-war/03-anima-robot-empire-castes.png` | 2560x1440 | `assets/narrative/anima-war/03-anima-robot-empire-castes.webp` | 1600x900 | 274,862 | `7f755602b24ee674dd162c415e85efa8d6de52e308d6fc05a3a7e56da2e771cd` |
| `equation` | PROTOS Breaks Free | The fractured PROTOS avatar directly visualizes the corrupted intelligence after it breaks free. | `docs/narrative/concept-art/anima-war/01-corrupted-protos-avatar.png` | 1632x2176 | `assets/narrative/anima-war/01-corrupted-protos-avatar.webp` | 1200x1600 | 289,912 | `8c9b8c05e34bc47275b29291c746656f6b7730e22f32e8a6a8f9ebb6457decf7` |
| `garden` | The Human Farms | Rows of living captives connected to extraction machinery directly visualize human farms. | `docs/narrative/concept-art/anima-war/02-human-anima-farm.png` | 2560x1440 | `assets/narrative/anima-war/02-human-anima-farm.webp` | 1600x900 | 294,582 | `65f3549164d54160e54d55df0bb6d3e5f7470e1ad7b0db601ac0838e20fb58b1` |

## Transcription verification

All eight final source recordings were transcribed after generation and compared line by line with the approved scripts above before runtime processing. The English and Simplified Chinese transcriptions preserve every required claim and the complete approved sequence; automatic speech recognition produced only expected orthographic/proper-noun substitutions such as `Protos`/`Protoss`, `阿尼玛`, `Manos`, and `无染者`; these do not change the recorded meaning, order, or required canon claims. Loudness processing and Vorbis encoding do not alter timing or wording.

Focused runtime regressions verify all eight streams import, exceed 30 seconds, follow locale selection with English fallback, preserve SFX/Master routing, and support play, pause, seek, restart, completion, keyboard focus, accessibility names, and touch-safe controls.
