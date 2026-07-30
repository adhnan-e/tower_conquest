import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors, FontWeight, TextStyle;

import '../../constants/asset_paths.dart';
import '../../constants/colors.dart';
import '../../managers/asset_manager.dart';

/// A node on the map: generates units over time, holds them up to a capacity,
/// and displays its faction through runtime colour tinting.
///
/// Base stats default to a Tier 1 Barracks from
/// `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` §1.1
/// (capacity 50, generation 1.0 units/s).
///
/// Rendering has two interchangeable sources. When the grayscale PNGs exist it
/// draws them with the faction tint; until then it draws a placeholder shape
/// through the *same* faction paint, so the colour pipeline is identical either
/// way and dropping the art in later needs no code change.
///
/// **Why not `SpriteComponent`?** `02_DEVELOPMENT_PROMPT.md` asks for one, but
/// `SpriteComponent` asserts `sprite != null` when it mounts. With the art not
/// yet produced that assert fails and the node never mounts — a blank screen in
/// debug, and a latent trap in release where asserts are stripped. Extending
/// [PositionComponent] and drawing the sprite here does exactly what
/// `SpriteComponent` does internally (`Sprite.render` with an override paint)
/// while tolerating a missing sprite. Once the PNGs ship, switching back is a
/// one-line change — but there is no reason to.
class Building extends PositionComponent with TapCallbacks {
  /// Building archetype: `barracks`, `tower`, `factory`, `command_center`.
  final String type;

  /// Upgrade tier 1-5. Mutable because upgrading swaps in higher-tier art;
  /// the MVP never changes it (upgrades land in Milestone 2).
  int tier;

  /// Owning faction. Not final — capture reassigns it, which is why the guide's
  /// `final String faction` could never compile alongside `changeFaction()`.
  String faction;

  /// Tintable grayscale layer. Null while the art has not been produced.
  Sprite? baseSprite;

  /// Fixed-colour layer (emblems, doorways). Never tinted, always optional.
  Sprite? detailSprite;

  /// Shared, cached tint paint. Treated as read-only — see [FactionManager].
  ui.Paint tintPaint;

  int unitsInside;
  double generationRate;
  int maxCapacity;

  /// True while this node is the selected source for a unit send.
  bool isSelected = false;

  /// Invoked on tap so the game can drive selection without the component
  /// needing a reference back to the game.
  void Function(Building building)? onTapped;

  /// Fractional units carried between frames.
  ///
  /// The guide's `unitsInside += (generationRate * dt).toInt()` is silently
  /// broken: at 60 fps `1.0 * 0.0167` truncates to 0 every single frame, so no
  /// building ever produces anything. Accumulating in a double and only
  /// transferring whole units fixes it and keeps generation frame-rate
  /// independent.
  double _genAccumulator = 0;

  static final _counterTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  );

  Building({
    required this.type,
    required this.tier,
    required String faction,
    required super.position,
    required super.size,
    this.unitsInside = 0,
    this.generationRate = 1.0,
    this.maxCapacity = 50,
    super.anchor = Anchor.center,
  })  : faction = faction,
        tintPaint = FactionManager().getPaint(faction);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final assets = AssetManager();
    baseSprite = await assets.tryLoadSprite(
      AssetPaths.getBuildingBasePath(type, tier),
    );
    detailSprite = await assets.tryLoadSprite(
      AssetPaths.getBuildingDetailPath(type, tier),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (unitsInside >= maxCapacity) {
      // At capacity, generation pauses (balance §1.3). Drop the partial unit so
      // a full one does not pop out the instant a single unit is sent away.
      _genAccumulator = 0;
      return;
    }

    _genAccumulator += generationRate * dt;

    final produced = _genAccumulator.floor();
    if (produced > 0) {
      _genAccumulator -= produced;
      unitsInside = (unitsInside + produced).clamp(0, maxCapacity);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final base = baseSprite;
    if (base != null) {
      // Production path: the grayscale sprite through the faction ColorFilter.
      base.render(canvas, size: size, overridePaint: tintPaint);
    } else {
      _renderPlaceholder(canvas);
    }

    // Detail layer is deliberately untinted — it carries fixed-colour identity.
    detailSprite?.render(canvas, size: size);

    _renderUnitCounter(canvas);

    if (isSelected) {
      _renderSelectionRing(canvas);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTapped?.call(this);
  }

  /// Removes [count] units, returning how many were actually available.
  int takeUnits(int count) {
    final taken = count.clamp(0, unitsInside);
    unitsInside -= taken;
    return taken;
  }

  /// Switches ownership and refreshes the cached tint. Used on capture.
  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }

  /// Defence value = units inside × the building's defence multiplier
  /// (balance §1.3). The MVP has no capture, so the multiplier is a flat 1.0x
  /// Barracks value; per-type multipliers arrive with Milestone 2.
  double get defenseValue => unitsInside * 1.0;

  /// Draws a stand-in for `<type>_tier<N>_base.png`.
  ///
  /// Everything is drawn in grayscale through the faction shade paints, exactly
  /// as a real grayscale PNG would be: white reads as the full faction colour,
  /// mid-gray as a shaded version of it.
  void _renderPlaceholder(ui.Canvas canvas) {
    final manager = FactionManager();
    final body = manager.getShadePaint(faction, 0xFF);
    final shade = manager.getShadePaint(faction, 0x88);

    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final radius = ui.Radius.circular(size.x * 0.18);

    switch (type) {
      case 'tower':
        // Defensive tower: narrow and tall.
        final tall = ui.Rect.fromLTWH(size.x * 0.22, 0, size.x * 0.56, size.y);
        canvas.drawRRect(ui.RRect.fromRectAndRadius(tall, radius), body);
        canvas.drawRect(
          ui.Rect.fromLTWH(size.x * 0.22, 0, size.x * 0.56, size.y * 0.2),
          shade,
        );
      case 'factory':
        // Heavy spawner: wide and squat.
        final wide = ui.Rect.fromLTWH(0, size.y * 0.22, size.x, size.y * 0.56);
        canvas.drawRRect(ui.RRect.fromRectAndRadius(wide, radius), body);
        canvas.drawRect(
          ui.Rect.fromLTWH(0, size.y * 0.22, size.x, size.y * 0.14),
          shade,
        );
      case 'command_center':
        // Primary hub: rounded square with a shaded core block.
        canvas.drawRRect(ui.RRect.fromRectAndRadius(rect, radius), body);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(
              size.x * 0.25,
              size.y * 0.25,
              size.x * 0.5,
              size.y * 0.5,
            ),
            ui.Radius.circular(size.x * 0.1),
          ),
          shade,
        );
      default:
        // Barracks: rounded square with a shaded roof band.
        canvas.drawRRect(ui.RRect.fromRectAndRadius(rect, radius), body);
        canvas.drawRect(
          ui.Rect.fromLTWH(0, size.y * 0.12, size.x, size.y * 0.16),
          shade,
        );
    }
  }

  void _renderUnitCounter(ui.Canvas canvas) {
    _counterTextPaint.render(
      canvas,
      '$unitsInside',
      Vector2(size.x / 2, size.y * 0.66),
      anchor: Anchor.center,
    );
  }

  void _renderSelectionRing(ui.Canvas canvas) {
    // Drawn untinted so the selection reads clearly against any faction colour.
    final ring = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const ui.Color(0xFFFFFFFF);

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12),
        ui.Radius.circular(size.x * 0.22),
      ),
      ring,
    );
  }
}
