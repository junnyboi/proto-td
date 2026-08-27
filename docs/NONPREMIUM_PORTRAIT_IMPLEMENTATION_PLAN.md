# Non-Premium Recruit and Specialization Portrait Regeneration — Implementation Plan

> **Historical technical evidence — not narrative canon.** This document preserves superseded production, localization, visual, screenshot, and regression evidence. Any historical story text, labels, prompts, or approval language shown here is rejected as current lore and must not be used as narrative authority. The sole current narrative authority is [The Anima War canon](NARRATIVE_CANON.md).


**Author:** Manus AI

**Source repository:** `https://github.com/junnyboi/proto-td`

**Planning baseline:** `662e71c7964027a566bc40b9721bfffd2f10a54b`

**Engine:** Godot `4.7.2.stable`

**Generation model:** **GPT Image 2**

**Scope:** Basic Recruit identity portraits and every non-premium specialization kit portrait, with male and female variants

## 1. Objective

This implementation replaces the inconsistent legacy 128×128 non-premium portrait set with a coherent collection of mature, role-readable Company Manus operators. The collection must follow the approved Protos faction concepts and painterly anime-realism pipeline while remaining deliberately less ornate than the three Premium Resonance heroes.[1] [2]

The release will ship **30 generated portrait sources**: eight identity portraits for the repeatable basic Recruit pool and twenty-two specialization-kit portraits covering both male and female variants of all eleven authored non-recruit classes. The runtime will preserve campaign authority, hero identity, promotion legality, receipts, hashes, save compatibility, and premium assets. Portrait selection remains presentation-only.

> **Non-premium art rule:** practical service uniforms, readable class equipment, restrained faction materials, and controlled energy accents. No divine halos, elaborate environment, rarity spectacle, excessive filigree, or five-star banner staging.

## 2. Audited baseline and gaps

The V3 campaign already allocates eight stable Recruit portrait IDs, but all eight are placeholder aliases to unrelated class portraits. Ten legacy class images exist at 128×128, yet they do not provide systematic male/female coverage, and the current Witch Doctor asset is an unrelated neon pixel avatar. Promotion path cards load one operator-level portrait per class, so their visual does not follow the selected operator's gender presentation.[3] [4]

Promotion retains the recruit's stable identity portrait in canonical campaign state so the person and gender source never change. Presentation surfaces now resolve that identity together with `current_class_id`: Recruit operators show their identity portrait, while promoted operators show the gender-matched **specialization portrait** for their current class. The path chooser previews the same asset that Training, Field Team, and Valhalla display after confirmation, preserving the “same person, new duty” contract without rewriting saves or receipts.[5]

## 3. Frozen asset matrix

### 3.1 Basic Recruit identity pool

The existing stable IDs remain unchanged to protect save and receipt compatibility. They will map to one male/female service pair per approved faction concept. Faction styling is visual lineage only; roster faction filtering remains governed by its existing presentation projection.

| Stable asset ID | Runtime file | Variant | Visual lineage | Restraint contract |
|---|---|---|---|---|
| `portrait_recruit_00` | `assets/portraits/recruits/solcrest_female.png` | Female | Solcrest Accord | White-gold civic lamellar, black underlayer, deep-teal sash, compact service shield |
| `portrait_recruit_01` | `assets/portraits/recruits/solcrest_male.png` | Male | Solcrest Accord | Matching practical kit with mature masculine tailoring |
| `portrait_recruit_02` | `assets/portraits/recruits/vesper_female.png` | Female | Vesper Circuit | Midnight technical uniform, cyan signal seam, wine-red lens, compact sensor tool |
| `portrait_recruit_03` | `assets/portraits/recruits/vesper_male.png` | Male | Vesper Circuit | Matching relay kit with distinct mature face and hair silhouette |
| `portrait_recruit_04` | `assets/portraits/recruits/lunaris_female.png` | Female | Lunaris Reliquary | Ivory/violet-black service uniform, brushed-gold fasteners, modest crescent focus |
| `portrait_recruit_05` | `assets/portraits/recruits/lunaris_male.png` | Male | Lunaris Reliquary | Matching ceremonial service kit without prestige-hero ornament |
| `portrait_recruit_06` | `assets/portraits/recruits/crimson_female.png` | Female | Crimson Aegis | Blackened field plate, scarlet scarf, forest webbing, compact breach tool |
| `portrait_recruit_07` | `assets/portraits/recruits/crimson_male.png` | Male | Crimson Aegis | Matching practical assault kit with distinct mature face and hair silhouette |

### 3.2 Specialization kit portrait matrix

Each class receives two explicit presentation assets. Stage 1 paths use practical upgraded uniforms; Stage 2 paths add stronger role equipment and one additional material or energy cue, but remain visibly below Premium Resonance rarity.

| Class | Stage | Female asset ID | Male asset ID | Required portrait read |
|---|---:|---|---|---|
| Defender | 1 | `portrait_specialization_defender_female` | `portrait_specialization_defender_male` | Broad practical shield, reinforced shoulder, lane-anchor authority |
| Immovable | 2 | `portrait_specialization_immovable_female` | `portrait_specialization_immovable_male` | Fortress gorget, heavier shield frame, restrained ward node |
| Gunner | 1 | `portrait_specialization_gunner_female` | `portrait_specialization_gunner_male` | Service rifle/crossbow stock and compact targeting lens |
| Sniper | 2 | `portrait_specialization_sniper_female` | `portrait_specialization_sniper_male` | Long precision weapon profile and advanced optic |
| Mage Apprentice | 1 | `portrait_specialization_mage_apprentice_female` | `portrait_specialization_mage_apprentice_male` | Small geometric casting focus and disciplined apprentice coat |
| Sorcerer | 2 | `portrait_specialization_sorcerer_female` | `portrait_specialization_sorcerer_male` | Expanded concentric focus and controlled area-casting energy |
| Witch Doctor | 2 | `portrait_specialization_witch_doctor_female` | `portrait_specialization_witch_doctor_male` | Combat-medic reliquary, medicine glass, practical field wraps |
| Shock Trooper | 1 | `portrait_specialization_shock_trooper_female` | `portrait_specialization_shock_trooper_male` | Light impact plate, scarlet scarf, compact shock weapon |
| Banner Guard | 2 | `portrait_specialization_banner_guard_female` | `portrait_specialization_banner_guard_male` | Command cloth and folded standard/banner-spear finial |
| Swordmaster | 1 | `portrait_specialization_swordmaster_female` | `portrait_specialization_swordmaster_male` | Practical service spellblade and fitted dueling armor |
| Sword Saint | 2 | `portrait_specialization_sword_saint_female` | `portrait_specialization_sword_saint_male` | Refined long reliquary blade and stronger controlled energy edge |

## 4. Generation specification

GPT Image 2 will generate every source as a **1:1 PNG** using the recorded repository production references. Each prompt will request one clearly adult operator, age 21 or older, in a chest-up three-quarter portrait with direct or near-direct eye line, complete visible shoulders, coherent role equipment, and a clean transparent background. The visual renderer must preserve high-end painterly anime realism, mature facial structure, believable anatomy, clear material separation, and restrained controlled lighting.[1]

The generation pass will use the four faction concept images, the Lunaris production sheets, and the Recruit Training UI concept as references. Female and male variants share class equipment language but remain distinct people rather than gender-swapped duplicates. Runtime derivatives are 512×512 RGBA PNGs; the highest-resolution generated sources remain in `docs/portraits/nonpremium/sources/`, which is excluded from Godot import by `docs/.gdignore`.

The derivative and manifest build is reproducible with:

```bash
pip3 install -r tools/requirements-portraits.txt
python3 tools/build_nonpremium_portraits.py
python3 tools/update_nonpremium_portrait_manifest.py
```

### 4.1 Rejection criteria

An image is rejected if it has ambiguous age, juvenile facial proportions, sexualized framing, malformed hands or equipment, cropped head or shoulders, illegible class equipment, generic modern clothing, inconsistent faction materials, premium-hero spectacle, text, watermark, elaborate scenery, excessive bloom, or opaque background residue. Pair-level review also rejects near-duplicate faces, uneven gender polish, and class variants that cannot be distinguished at 128px.

## 5. Runtime integration architecture

A presentation-only `OperatorPortraitCatalog` will map stable identity portraits to a male/female variant and resolve `class_id + variant` into a specialization-kit asset ID. No gender field will be added to campaign state, codecs, hashes, receipts, or hero rows. This keeps old saves byte-compatible and derives presentation deterministically from the already-persisted identity portrait ID.

`TrainingSupport` exposes the resolved specialization preview ID as derived choice metadata. `PromotionPathCard` consumes that explicit ID instead of reconstructing a legacy operator portrait name. A shared presentation resolver keeps `hero.portrait_asset_id` as the persisted Recruit identity and derives the visible portrait from `current_class_id + identity gender`; Training dossiers and rows, Field Team cards, and Valhalla dossiers therefore advance through first- and second-stage class portraits immediately after promotion. Premium portraits retain priority. Existing legacy operator portrait IDs remain registered as compatibility aliases to the new kit art for any older view or test that still requests them.

## 6. Work packages

| Work package | Implementation | Regression gate |
|---|---|---|
| **A — Contract and generation matrix** | Freeze this plan, prompt ledger, 30-file matrix, reference set, naming, crop, and rejection criteria. | Repository diff check; plan/matrix consistency script. |
| **B — GPT Image 2 production and deterministic derivatives** | Generate all 30 high-resolution sources in batches, review contact sheets, regenerate failed entries, create 512×512 RGBA runtime derivatives, and record SHA-256 checksums. | Dimension/alpha/bounds/uniqueness script; visual review of recruit and specialization contact sheets. |
| **C — Manifest and Training integration** | Register all assets, clear Recruit placeholder flags, add compatibility aliases, introduce the presentation catalog, bind gender-matched class-kit art, and remove TEMP ART semantics from the card copy. | Focused portrait-catalog, manifest, Training path-card, localization, and save-compatibility tests. |
| **D — Native release verification** | Direct import, bounded boot, full standalone suite, error scans, and Xvfb captures for male/female Recruit dossiers plus stage-1/stage-2 path cards in landscape and portrait. | Full Godot 4.7.2 baseline and clean visual logs. |
| **E — Forward reconciliation and deployment** | Fetch and merge shared `master`, rerun touched gates, push to `master`, export the exact final source, verify HTML/JS/WASM/PCK over HTTP, layer only the new PCK onto the newest `proto-td-web`, run type/build/browser checks, and save/publish the checkpoint. | Exact source/PCK hash, managed network/console/geometry checks, final WebDev checkpoint. |

## 7. Automated acceptance contracts

The implementation will add focused coverage for the following conditions:

1. All eight Recruit IDs resolve to non-placeholder 512×512 runtime images and form four female/male pairs.
2. All eleven non-premium classes resolve both female and male specialization asset IDs.
3. Every generated source and runtime derivative is unique by SHA-256, square, non-empty, readable through `Art.texture`, and has verified alpha with no retained chroma background.
4. Training uses the persisted identity portrait to preserve gender; after promotion, Training, Field Team, and Valhalla display the current specialization portrait while canonical campaign identity remains unchanged.
5. Promotion legality, selected target, command payload, receipts, save revision, and restored campaign bytes are unchanged by portrait resolution.
6. Legacy IDs such as `portrait_caster_1`, `portrait_defender_2`, and `portrait_witch_doctor_1` continue to resolve without placeholders.
7. Landscape and portrait path cards contain the new portrait without overflow, clipped face, missing texture, focus regression, or inaccessible controls.
8. Premium portraits and cinematic mappings are unchanged.

## 8. Completion record

| Work package | Status | Evidence |
|---|---|---|
| A — Contract and generation matrix | **Complete** | Baseline audit complete; 30-portrait matrix and prompt ledger frozen. |
| B — GPT Image 2 production | **Complete** | 30 unique 1920×1920 GPT Image 2 sources, 30 reviewed 512×512 RGBA derivatives, SHA-256 ledger, and accepted 128px contact sheet. |
| C — Runtime integration | **Complete** | Eight stable Recruit IDs, twenty-two specialization IDs, eleven compatibility aliases, presentation resolver, Training card binding, and bilingual TEMP ART removal. |
| D — Native verification | **Complete** | Godot 4.7.2 direct import, bounded boot, all 57 standalone tests/harness smokes, aggregate error scan, and female-landscape/male-portrait Xvfb captures pass. |
| E — Reconciliation and deployment | **Complete** | Portrait release `1ee9082` was independently reviewed, pushed, and forward-reconciled into source revision `d5881ff`; exact 197,017,352-byte PCK `411e6c18…9f30` is mapped by WebDev checkpoint `6a813c18` after type/build, HTTP, desktop/portrait geometry, native input, lazy-media, and console acceptance. |
| F — Promoted portrait continuity | **Complete** | Presentation-only routing resolves the current specialization from canonical class identity while deriving female/male selection from the unchanged Recruit portrait. Training, Field Team, and Valhalla consume the shared result. The 11-class × two-gender matrix, second-stage continuity, idempotency, premium precedence, real promotion/save restoration/receipt schema, Field Team texture binding, fallen-operator projection, focused gates, full Godot 4.7.2 baseline, and landscape/portrait Xvfb captures pass. Source `16e8586` exports as the exact 231,526,672-byte core; local and managed HTTP, WebGL 2, responsive geometry, native input, and clean-console gates pass on the forward-only `proto-td-web` host. |

## References

[1]: ART_DIRECTION.md "Protos Visual Art Direction"
[2]: LUNARIS_CHARACTER_DESIGNS.md "Lunaris Reliquary Launch Character Designs"
[3]: ../assets/manifest.tres "Runtime asset manifest"
[4]: ../data/campaigns/p16_v3.tres "V3 campaign portrait pool"
[5]: ui-concepts/ui-revamp/audits/03-training.md "Roster, Training, Promotion, and Naming audit"
[6]: ui-concepts/assets/GPT%20Image%202%20-%20Recruit%20Training.webp "Approved Recruit Training visual concept"
