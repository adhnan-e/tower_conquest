import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../constants/asset_paths.dart';
import '../../constants/colors.dart';
import '../../managers/asset_manager.dart';

/// A soldier travelling from a source node to a target node.
///
/// Base stats default to Infantry from
/// `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` §2.1
/// (100 px/s, combat power 1.0).
///
/// Like [Building] this extends [PositionComponent] rather than
/// `SpriteComponent`, because the latter asserts `sprite != null` on mount and
/// the art has not been produced yet. It renders its grayscale sprite through
/// the faction tint when one exists, and a placeholder shape through the same
/// faction paint until then.
class Unit extends PositionComponent {
  /// Unit class: `infantry`, `heavy_soldier`, `scout`.
  final String type;

  int tier;

  /// Owning faction. Not final — see the note in [Building.faction].
  String faction;

  /// Tintable grayscale layer. Null while the art has not been produced.
  Sprite? baseSprite;

  /// Fixed-colour layer. Never tinted, always optional.
  Sprite? detailSprite;

  /// Shared, cached tint paint. Treated as read-only — see [FactionManager].
  ui.Paint tintPaint;

  /// Where the unit is heading. Required — a unit with no destination has no
  /// meaning in this game.
  Vector2 targetPosition;

  /// Pixels per second.
  double speed;

  /// Contribution to combat resolution. Unused in the MVP (path combat and
  /// capture arrive in Milestone 2) but carried so the value has one home.
  double combatPower;

  /// Called once the unit reaches its destination, before it despawns. Lets the
  /// game clear the unit from its route without the unit knowing about routes.
  void Function(Unit unit)? onArrived;

  Unit({
    required this.type,
    required this.tier,
    required String faction,
    required super.position,
    required super.size,
    required this.targetPosition,
    this.speed = 100.0,
    this.combatPower = 1.0,
    super.anchor = Anchor.center,
  })  : faction = faction,
        tintPaint = FactionManager().getPaint(faction);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final assets = AssetManager();
    baseSprite = await assets.tryLoadSprite(
      AssetPaths.getUnitBasePath(type, tier),
    );
    detailSprite = await assets.tryLoadSprite(
      AssetPaths.getUnitDetailPath(type, tier),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    final toTarget = targetPosition - position;
    final distance = toTarget.length;
    final step = speed * dt;

    // Arrival is checked *before* moving. Stepping first and correcting after
    // (as the guide does) lets a fast unit overshoot and jitter around the
    // target on the frame it arrives.
    if (distance <= step || distance == 0) {
      position.setFrom(targetPosition);
      onReachedTarget();
      return;
    }

    position += toTarget * (step / distance);
  }

  @override
  void render(ui.Canvas canvas) {
    final base = baseSprite;
    if (base != null) {
      base.render(canvas, size: size, overridePaint: tintPaint);
    } else {
      _renderPlaceholder(canvas);
    }

    detailSprite?.render(canvas, size: size);
  }

  /// Called once the unit reaches [targetPosition].
  ///
  /// The MVP simply despawns; Milestone 2 replaces this with damage against the
  /// target node and the capture check.
  void onReachedTarget() {
    onArrived?.call(this);
    removeFromParent();
  }

  void moveTo(Vector2 target) {
    targetPosition = target.clone();
  }

  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }

  /// Draws a stand-in for `<type>_tier<N>_base.png`: a white disc with a
  /// mid-gray core, drawn through the faction shade paints so the multiply
  /// tint behaves exactly as it will with the real grayscale sprite.
  void _renderPlaceholder(ui.Canvas canvas) {
    final manager = FactionManager();
    final centre = ui.Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.drawCircle(centre, radius, manager.getShadePaint(faction, 0xFF));
    canvas.drawCircle(
      centre,
      radius * 0.45,
      manager.getShadePaint(faction, 0x88),
    );
  }
}
