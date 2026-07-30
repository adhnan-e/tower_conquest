# Required PNGs — Milestone 1 (MVP)

Asset request from the developer side to the orchestrator. These are the **four**
sprites the current MVP build needs, matching the "4 grayscale sprites (1
building base/detail, 1 unit base/detail)" line item for Milestone 1 in
`planning/01_design/01_GAME_DESIGN_DOCUMENT.md` §11.

The game **already runs without them.** Every entity currently draws a
procedural placeholder shape through the exact same faction `Paint` the sprites
will use, so nothing about the colour pipeline changes when the art lands — see
[Drop-in procedure](#drop-in-procedure).

---

## 1. The four files

| # | Filename | Destination | Layer | Size | Replaces placeholder |
| :- | :-- | :-- | :-- | :-- | :-- |
| 1 | `barracks_tier1_base.png` | `assets/images/buildings/` | Base (tintable) | 96 × 96 | Rounded square, white body |
| 2 | `barracks_tier1_detail.png` | `assets/images/buildings/` | Detail (never tinted) | 96 × 96 | Mid-gray roof band |
| 3 | `infantry_tier1_base.png` | `assets/images/units/` | Base (tintable) | 20 × 20 | White disc |
| 4 | `infantry_tier1_detail.png` | `assets/images/units/` | Detail (never tinted) | 20 × 20 | Mid-gray core dot |

Filenames follow the catalog convention in
`planning/03_assets/01_ASSET_CATALOG_PRODUCTION.md` §1.1 —
`<type>_tier<N>_base.png` and `<type>_tier<N>_detail.png`. The code builds these
paths in `lib/game/constants/asset_paths.dart`; **the names must match exactly**,
lower-case, no spaces.

Detail layers are optional. If a detail PNG is not supplied the base still
renders correctly on its own.

### Sizing note

The dimensions above are the on-screen logical sizes used by
`lib/game/tower_conquest_game.dart`. Supplying them at **2× or 3×**
(192 × 192 and 40 × 40, or 288 × 288 and 60 × 60) is preferred — Flame scales
sprites down to the component size, so higher-resolution source art looks
correct on high-DPI phones. Keep them square.

---

## 2. Grayscale specification for base layers

This is the part that matters most. Base layers are tinted at runtime with:

```dart
ColorFilter.mode(factionColour, BlendMode.multiply)
```

Multiply means **the output is the source pixel multiplied by the faction
colour**. Consequences the art must respect:

| Source gray | Result when tinted `#2D8CFF` (player blue) | Use for |
| :-- | :-- | :-- |
| `#FFFFFF` white | full, saturated faction blue | main body / the colour the faction should read as |
| `#B0B0B0` light gray | slightly muted blue | soft shading, subtle panels |
| `#888888` mid gray | half-strength blue, clearly darker | shadowed faces, recessed bands |
| `#404040` dark gray | very dark blue, nearly black | deep shadow, outlines |
| `#000000` black | **black regardless of faction** | avoid unless a hard black outline is intended |

Rules:

1. **Paint the body pure white.** Anything less permanently desaturates the
   faction colour. If the building reads as gray in-game, the base was drawn too
   dark.
2. **Use gray only for shading**, and stay above `#404040` for anything that
   should still read as coloured.
3. **No colour at all** in a base layer — it multiplies into muddy hues. Colour
   belongs in the detail layer.
4. **Transparent background.** 32-bit RGBA PNG, alpha `0` outside the silhouette.
   Do not ship a white background — it would tint into a full faction-colour
   square.
5. **Anti-aliased edges are fine**; partial alpha tints correctly.

Quick self-check: open the base PNG, desaturate-check it — if the brightest
pixel of the main body is not near-white, it needs lightening.

## 3. Specification for detail layers

Detail layers are rendered on top **without any filter**, so they appear exactly
as authored. They carry the fixed visual identity that survives every faction
recolour — doorways, emblems, insignia, glass, glow.

- Full colour, authored as final.
- Transparent everywhere the base should show through — this layer is mostly
  empty.
- Same pixel dimensions as its base layer, same alignment, so the two stack with
  no offset.
- Must read against **both** blue `#2D8CFF` and red `#E74C3C` backing. Mid-tone
  golds, dark charcoals and off-whites work; saturated blues and reds do not.

Per the catalog's own example: `barracks_tier1_detail.png` = dark gray doorway
plus a golden shield emblem.

---

## 4. Drop-in procedure

1. Copy the files into `assets/images/buildings/` and `assets/images/units/`.
2. Run `flutter pub get`.
3. Run the app.

That is the whole procedure. **No code change and no `pubspec.yaml` change is
required** — both directories are already declared in `pubspec.yaml`, and
`Building`/`Unit` attempt `Sprite.load` on every start, falling back to the
placeholder shape only when the file is absent. The moment a PNG exists it takes
over.

### Verifying the handoff

- [ ] Player barracks renders blue `#2D8CFF`, enemy barracks red `#E74C3C`, from the *same* PNG.
- [ ] Neither building looks washed-out or gray — if it does, the base layer is too dark (§2 rule 1).
- [ ] The detail layer's colours are identical on the blue and the red building.
- [ ] No opaque rectangle behind either sprite — that means a non-transparent background (§2 rule 4).
- [ ] The unit counter is still legible over the building body.
- [ ] `flutter test` still passes.

---

## 5. Not needed yet

The catalog lists 200+ assets. Everything below is **out of scope for this
handoff** and should not be produced until the matching code lands:

- Tiers 2-5 of any building — the upgrade system is Milestone 2.
- `tower`, `factory`, `command_center` — placeholder silhouettes exist in code
  and the types are unused by the MVP level.
- `heavy_soldier`, `scout` — unit classes are Milestone 2.
- Terrain, effects, UI, progression and cosmetic assets.
- Anything for the routes between nodes — `PathLink` draws them procedurally as
  faction-coloured bands and needs no art.

When Milestone 2 begins, this document will be superseded by a second request
covering the four building types × the tiers actually implemented.
