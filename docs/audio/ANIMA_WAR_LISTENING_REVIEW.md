# Anima War Visual and Score Alignment Review

**Status:** Accepted for the current release  
**Narrative authority:** [`docs/NARRATIVE_CANON.md`](../NARRATIVE_CANON.md)  
**Technical sources:** [`LUNARIS_GAMEPLAY_SCORE.md`](LUNARIS_GAMEPLAY_SCORE.md), [`ACT_II_SCORE.md`](ACT_II_SCORE.md), and [`TITLE_ANIMATION.md`](../TITLE_ANIMATION.md)

## Decision

The existing title art, title music, adaptive Act I score, stage-specific Act II score, and result cues remain in place. They support the revised Anima War without softening PROTOS or treating harvested human souls as replaceable data. No runtime audio or title artwork was replaced in this phase.

The visual and musical material works because it presents **Company Manus as disciplined, human, and mournful**, while later combat cues become increasingly rigid, urgent, and machine-like. The score therefore supports the campaign's plain-language progression: discover the human-harvesting system, rescue people, attack the farms and refineries, and assault Empire Foundry.

## Visual review

The approved title composition remains compatible with the new canon. The three adult Lunaris figures read as a resistance command group rather than servants of PROTOS. The monumental ring, suspended machines, and cold city architecture can now be understood as infrastructure built under the rogue AI's rule. The image contains no caretaker, garden, or peaceful-machine claim that would contradict the binding canon.

The title animation remains a locked-camera character tableau with restrained movement. Its existing technical contract, identity preservation, 16:9 cover behavior, reduced-motion fallback, and title-to-Company-Command transition remain valid.[1] The new Anima Archive concept set supplies the explicit corruption, human-farm, robot-caste, and Empire Foundry imagery where the title deliberately stays faction-focused.[2]

## Representative listening review

A 108-second montage sampled nine representative runtime cues for twelve seconds each, beginning eight seconds into each source. The review covered the protected title theme, Company Command, both ends of the early Act I adaptive range, the S8 boss, and four Act II milestones.

| Campaign surface | Narrative function heard in the cue | Alignment result |
|---|---|---|
| Title — *Astra Memoriam* | Grand, melancholic orchestration establishes loss and high stakes without presenting PROTOS as safe or merciful. | **Keep** |
| Company Command | Steady, somber strings communicate organized resistance planning and human resolve. | **Keep** |
| Act I early — low | Cautious plucked figures and low colors support investigation and the gradual discovery of the harvesting system. | **Keep** |
| Act I early — high | Faster percussion and strings support the shift from discovery to active rescue under pressure. | **Keep** |
| S8 boss | Heavy rhythm and dark brass communicate a large, unfeeling PROTOS enforcer or system node. | **Keep** |
| S9 — The Green Cage | Tragic, ethereal material communicates human loss inside a controlled artificial habitat. | **Keep** |
| S13 — Thirty-Three | Fast, desperate motion supports the widening assault on PROTOS infrastructure. | **Keep** |
| S15 — Soulstorm | Dense, unstable orchestration conveys processed anima under extreme pressure and a battle approaching systemic collapse. | **Keep** |
| S16 — Empire Foundry | Relentless, marching force gives the final operation industrial and imperial scale. | **Keep** |

The suite is primarily orchestral rather than overtly electronic. That is acceptable: the human melodic material keeps Company Manus emotionally legible, while the later ostinatos, repeated pulses, and heavy mechanical pacing provide the robot empire's pressure. None of the sampled cues romanticized the harvesting system or weakened the revised conflict.

## Technical verification

All **29 repository-owned runtime soundtrack and UI-audio files** matched the pinned SHA-256 manifests. The external lossless production archives named in historical reproduction notes were not mounted in this sandbox, so this review validates the checked-in runtime derivatives rather than claiming to revalidate unavailable source masters.

Godot 4.7.2 passed the music redesign, Act II music transition, title music scope, title UI scale, and title onboarding navigation regressions. The existing cue IDs, loop points, BPM metadata, transition anchors, loudness hierarchy, and saved music preferences remain unchanged.[3]

## Release guardrails

Future music replacement is unnecessary unless a human listening review requests a different emotional identity. Any later replacement must preserve stable cue IDs and routing, distinguish a single free human soul from processed anima, keep PROTOS calm but predatory, and avoid masking gameplay alerts. Internal filenames may retain older working slugs because they are not displayed to players and are protected by runtime references and checksums.[4]

## References

[1]: [`TITLE_ANIMATION.md`](../TITLE_ANIMATION.md)  
[2]: [`NARRATIVE_CANON.md`](../NARRATIVE_CANON.md#concept-designs)  
[3]: [`LUNARIS_GAMEPLAY_SCORE.md`](LUNARIS_GAMEPLAY_SCORE.md)  
[4]: [`ACT_II_SCORE.md`](ACT_II_SCORE.md#runtime-catalog)
