# Phase 1 Detail-Layer Refinement

**Status:** Approved after quantitative alpha-coverage and visual validation.

The previous `tower_tier1_detail.png` and `heavy_soldier_tier1_detail.png` assets covered too much of their grayscale bases, which reduced faction-color readability after runtime tinting. The candidate replacements intentionally contain only small independent fixed-color overlays:

| Asset | Included fixed details | Intended base visibility |
|---|---|---|
| `tower_tier1_detail.png` | Gold crest and three narrow charcoal window slits | The tower base remains visually dominant and tintable |
| `heavy_soldier_tier1_detail.png` | Compact charcoal visor and small gold chevron | The body and armor base remain visually dominant and tintable |

Visual inspection and quantitative validation confirm that each final layer contains isolated foreground detail only, retains full transparency outside its artwork, and preserves most of the tintable base silhouette.

| Asset | Final dimensions | Detail coverage of base | Detail-on-base overlap | Result |
|---|---:|---:|---:|---|
| `tower_tier1_detail.png` | 256 × 256 px | 27.7% | 94.7% | Pass |
| `heavy_soldier_tier1_detail.png` | 64 × 64 px | 26.5% | 100.0% | Pass |

Both results fall within the approved 20–55% coverage range and should preserve clear blue-versus-red faction readability at runtime.
