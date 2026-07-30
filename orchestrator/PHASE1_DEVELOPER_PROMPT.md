# Developer Prompt: Phase 1 Asset Integration

> **Correction — use `BlendMode.modulate`, not `multiply`.**
> Skia's `multiply` composites the filter colour against the source, so a fully
> transparent pixel comes out *fully opaque* in the faction colour and the
> sprite renders as a solid coloured square. Measured on
> `barracks_tier1_base.png`: transparent corner `(45,140,255)` opaque under
> `multiply` versus alpha 0 under `modulate`, with an identical body colour of
> `(38,119,217)`. `modulate` multiplies alpha too, so transparency and
> antialiased edges survive. The art needs no change — see
> `FactionColors.defaultBlendMode` in `lib/game/constants/colors.dart`.


**Context:**
The Phase 1 asset pack (14 original PNGs) has been generated, processed, and pushed to the repository. The `assets/images/buildings/` and `assets/images/units/` directories are populated, and the assets are declared in `pubspec.yaml`.

The assets use a **runtime-tinting architecture**:
1. `*_base.png`: A grayscale silhouette that must be tinted with the faction color using `BlendMode.multiply`.
2. `*_detail.png`: A fixed-color overlay (charcoal and gold) that must be rendered *without* tinting.

**Your Task:**
Update the Flame component rendering logic in the Tower Conquest MVP to consume these new assets instead of the placeholder colored rectangles.

**Implementation Requirements:**

1. **Asset Loading (`AssetManager`):**
   - Update `AssetManager` to load the 14 new base and detail sprites.
   - Example keys: `buildings/barracks_tier1_base.png`, `buildings/barracks_tier1_detail.png`.

2. **Building Rendering (`building.dart`):**
   - Remove the fallback `Paint` rectangles.
   - Render the base sprite tinted with the node's `factionColor` using `ColorFilter.mode(factionColor, BlendMode.multiply)`.
   - Render the detail sprite directly over the base sprite without any color filter.
   - Ensure the sprites scale correctly to the building's hitbox/size (256x256 native).

3. **Unit Rendering (`unit.dart`):**
   - Remove the fallback `Paint` circles.
   - Render the base sprite tinted with the unit's `factionColor` using `ColorFilter.mode(factionColor, BlendMode.multiply)`.
   - Render the detail sprite directly over the base sprite without any color filter.
   - Ensure the sprites scale correctly to the unit's hitbox/size (64x64 native).

4. **Visual Verification:**
   - Run the game and verify that Player (Blue) and Enemy (Red) buildings and units are clearly distinguishable.
   - Verify that the gold and charcoal details are visible and untinted.
   - Verify that the transparent backgrounds do not show any green or black artifacts.

**Reference Code:**
```dart
// Example Flame render method for runtime tinting
@override
void render(Canvas canvas) {
  // 1. Render tinted base
  final basePaint = Paint()
    ..colorFilter = ColorFilter.mode(factionColor, BlendMode.multiply);
  baseSprite.render(
    canvas,
    position: Vector2.zero(),
    size: size,
    paint: basePaint,
  );

  // 2. Render untinted detail overlay
  detailSprite.render(
    canvas,
    position: Vector2.zero(),
    size: size,
  );
}
```
