# Phase 2 Building Tier Asset Delivery

## Delivery Summary

This delivery adds the complete **Tier 2 through Tier 5 building sprite set** for Tower Conquest. It contains **32 original PNG layers**: four building types, four upgrade tiers, and the established two-layer rendering architecture. Each finished file is a 256×256 sRGB RGBA PNG, matching the dimensions and naming convention already used by the shipped Tier 1 building sprites.

The base layers are deliberately neutral grayscale so the game can apply faction tinting at runtime. Detail layers contain fixed gold and charcoal architectural accents, emblems, and entrances; they are intended to render untinted over the faction-colored base. All files have transparent backgrounds, use a consistent centered top-down tactical perspective, and have been visually reviewed as composited pairs.

| Building type | Tier range delivered | Base layers | Detail layers | Total files |
| :-- | :-- | --: | --: | --: |
| Barracks | 2–5 | 4 | 4 | 8 |
| Tower | 2–5 | 4 | 4 | 8 |
| Factory | 2–5 | 4 | 4 | 8 |
| Command Center | 2–5 | 4 | 4 | 8 |
| **Complete delivery** | **2–5** | **16** | **16** | **32** |

## File Contract

Every asset is stored in `assets/images/buildings/` and follows the pattern `<building_type>_tier<tier>_<layer>.png`. The `AssetManager` tier lookup introduced in Phase 2 can resolve these files directly, while preserving Tier 1 fallback behavior if an asset is unavailable in a future development branch.

| Layer | Runtime behavior | Validation result |
| :-- | :-- | :-- |
| `*_base.png` | Faction-tinted by the existing base-layer render path | 16 of 16 files are 256×256 RGBA and contain no visible hue leakage in their opaque pixels. |
| `*_detail.png` | Rendered unchanged above the base layer | 16 of 16 files are 256×256 RGBA, contain fixed-color detail art, and have no green-screen-like pixels. |

## Visual Progression

The Barracks evolves from reinforced training quarters to an ornate elite garrison. The Tower progresses through increasingly prominent gold defensive emblems. The Factory gains larger mechanical hubs, piping, and fortified production machinery. The Command Center grows from a compact command hub into a heavily layered headquarters with advanced communication structures. In each family, silhouette and decorative density rise with tier so upgrades are legible at a glance.

## Verification Record

A composited contact sheet was reviewed after export. Programmatic validation confirmed that all expected Tier 2–5 paths exist, all files use the expected 256×256 RGBA format, every base layer is neutral grayscale, and no exported layer contains residual green-background pixels. The source generation working files and local validation artifacts are intentionally excluded from version control; only the game-ready, losslessly compressed PNGs are part of this delivery.
