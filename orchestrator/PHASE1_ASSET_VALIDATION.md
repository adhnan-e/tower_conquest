# Phase 1 Asset Validation Notes

**Date:** 2026-07-30  
**Status:** Passed after deterministic cleanup and normalization.

## Findings

The generated source PNGs arrived at 1920×1920 pixels and some retained residual chroma-key/background pixels. The asset-preparation process removed border-connected generated backgrounds, normalized all base layers to grayscale for runtime tinting, preserved untinted detail colors, and resized the assets to the agreed Flame targets.

| Asset group | File count | Target size | Transparency | Result |
|---|---:|---:|---|---|
| Buildings | 8 | 256×256 px | RGBA with zero-alpha background | Passed |
| Units | 6 | 64×64 px | RGBA with zero-alpha background | Passed |
| Total | 14 | — | PNG-32 | Passed |

A visual inspection of `command_center_tier1_base.png` confirmed a clean, centered grayscale building silhouette on transparency, with no visible green chroma background. The asset retains clear shape definition at its target 256×256 size and is suitable for faction tinting.

## Processing Notes

- Base layers were converted to grayscale using perceptual luminance so their value shading remains visible under faction tinting.
- Detail layers retain their authored charcoal and gold accents and remain untinted at runtime.
- Fully transparent pixels were assigned neutral RGB values to prevent green key-color halos during rendering.
- The final asset count is exactly 14 files, matching `orchestrator/REQUIRED_PNGS.md`.

## Verification Command

```bash
python3 tools/validate_phase1_assets.py
```

The script confirms expected dimensions, RGBA mode, and both transparent and opaque alpha values for every required asset.
