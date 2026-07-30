# Phase 1: MVP Assets (14 files)

This manifest lists the exact PNG files required for the Tower Conquest MVP. All files must be placed in `assets/images/buildings/` and `assets/images/units/`.

## Format Requirements
- **Size:** Buildings 256×256 px; Units 64×64 px
- **Transparency:** PNG-32 RGBA, alpha 0 outside silhouette (no white background)
- **Style:** Top-down orthographic, minimalist geometric, flat shading, soft rounded edges
- **Base Layers (`*_base.png`):** Pure grayscale, biased bright (#FFFFFF main body, #B0B0B0 soft panels, #888888 shaded faces). No hue.
- **Detail Layers (`*_detail.png`):** Untinted fixed colors. Mid-tone colors (golds, dark charcoals, off-whites) that read clearly against both #2D8CFF (blue) and #E74C3C (red). No faction emblems.

## 1. Buildings (8 files)
Directory: `assets/images/buildings/`

| Filename | Purpose | Description |
| :--- | :--- | :--- |
| `barracks_tier1_base.png` | Standard spawner body | Rounded square, bright grayscale |
| `barracks_tier1_detail.png` | Standard spawner details | Dark charcoal doorway, gold crossed-swords insignia |
| `tower_tier1_base.png` | Defensive structure body | Tall narrow square/circle, bright grayscale |
| `tower_tier1_detail.png` | Defensive structure details | Dark charcoal windows, gold shield insignia |
| `factory_tier1_base.png` | Heavy spawner body | Wide squat rectangle, bright grayscale |
| `factory_tier1_detail.png` | Heavy spawner details | Dark charcoal wide garage door, gold gear insignia |
| `command_center_tier1_base.png` | Primary hub body | Large rounded square with core block, bright grayscale |
| `command_center_tier1_detail.png` | Primary hub details | Dark charcoal main entrance, gold star insignia, glowing core |

## 2. Units (6 files)
Directory: `assets/images/units/`

| Filename | Purpose | Description |
| :--- | :--- | :--- |
| `infantry_tier1_base.png` | Standard unit body | Small circle/helmet, bright grayscale |
| `infantry_tier1_detail.png` | Standard unit details | Dark charcoal visor, subtle highlight |
| `heavy_soldier_tier1_base.png` | Armored unit body | Larger rounded square/armor, bright grayscale |
| `heavy_soldier_tier1_detail.png` | Armored unit details | Dark charcoal heavy visor, gold chevron |
| `scout_tier1_base.png` | Fast unit body | Small triangle/sleek shape, bright grayscale |
| `scout_tier1_detail.png` | Fast unit details | Dark charcoal narrow visor, sleek highlight |
