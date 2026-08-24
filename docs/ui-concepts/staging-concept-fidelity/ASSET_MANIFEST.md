# Staging Concept-Fidelity Asset Manifest

**Generated:** 2026-08-24

**Image model:** GPT Image 2

**Quality:** High

**Primary references:** the approved 2048×1152 desktop staging concept, the approved 1152×2048 portrait staging concept, and the generated Lunaris seal master

**Runtime target:** Godot 4.7.2

All assets were generated as standalone source images with a shared description of antique brass, champagne highlights, moon-cyan crystals, black-blue glass, clipped celestial geometry, restrained emission, and mature dark sci-fantasy gacha presentation. The model outputs were deterministically alpha-cleaned and downsampled for runtime efficiency; native UI labels and values are not baked into any generated image.

| Runtime file | Type | Role |
|---|---|---|
| `assets/ui/staging/icons/lunaris_seal.png` | 512×512 RGBA | Faction identity and campaign crest |
| `assets/ui/staging/icons/mission.png` | 512×512 RGBA | Mission card and primary action |
| `assets/ui/staging/icons/barracks.png` | 512×512 RGBA | Barracks destination |
| `assets/ui/staging/icons/recruit.png` | 512×512 RGBA | Recruit destination |
| `assets/ui/staging/icons/armory.png` | 512×512 RGBA | Armory destination |
| `assets/ui/staging/icons/memorial.png` | 512×512 RGBA | Memorial destination |
| `assets/ui/staging/icons/training.png` | 512×512 RGBA | Training destination |
| `assets/ui/staging/icons/resource_aether.png` | 512×512 RGBA | Aether mock currency |
| `assets/ui/staging/icons/resource_sigil.png` | 512×512 RGBA | Astral Sigil mock currency |
| `assets/ui/staging/icons/resource_stamina.png` | 512×512 RGBA | Stamina mock resource |
| `assets/ui/staging/icons/exit.png` | 512×512 RGBA | Exit navigation symbol |
| `assets/ui/staging/icons/message.png` | 512×512 RGBA | Nonfunctional message ornament |
| `assets/ui/staging/icons/settings.png` | 512×512 RGBA | Nonfunctional settings ornament |
| `assets/ui/staging/icons/status_diamond.png` | 512×512 RGBA | Status and progress milestone accent |
| `assets/ui/staging/frames/navbar.png` | 1536×176 RGBA | Adaptive top navigation background |
| `assets/ui/staging/frames/command_deck.png` | 1024×762 RGBA | Landscape deck and portrait sheet |
| `assets/ui/staging/frames/mission_card.png` | 1024×509 RGBA | Mission preview container |
| `assets/ui/staging/frames/primary_button.png` | 1024×248 RGBA | Mission Control action |
| `assets/ui/staging/frames/operation_tile.png` | 1024×318 RGBA | Secondary destination buttons |
| `assets/ui/staging/frames/resource_chip.png` | 768×173 RGBA | Mock-resource and campaign chips |

The generated review sheets are stored beside this manifest. `icon-review-sheet.png` shows every final icon on a checkerboard inspection background. `frame-review-sheet.png` shows the principal generated frame family. `font-comparison.png` records the deterministic Cinzel, Marcellus, and Cormorant Garamond comparison that led to the font selection. `SHA256SUMS` records every runtime image and the selected font binary.

## Font provenance

`assets/fonts/Cinzel-Variable.ttf` is the unmodified Google Fonts Cinzel variable binary by Natanael Gama and the Cinzel Project Authors. Google Fonts metadata lists it as an OFL serif with a 400–900 weight axis.[1] The full license is distributed as `assets/fonts/Cinzel-OFL.txt`, and the repository notice is updated in `THIRD_PARTY_NOTICES.md`.[2]

## References

[1]: https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/METADATA.pb "Google Fonts Cinzel metadata"
[2]: https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/OFL.txt "Cinzel SIL Open Font License 1.1"
