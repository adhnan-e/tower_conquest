import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
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
/// Rendered from the Phase 1 art pack: a grayscale base layer drawn through the
/// faction `ColorFilter`, then an untinted detail layer on top. Native art is
/// 64x64 and is scaled to this unit's [size].
///
/// Extends [PositionComponent] rather than `SpriteComponent` for the reason
/// given on [Building].
class Unit extends PositionComponent with CollisionCallbacks {
  /// Unit class: `infantry`, `heavy_soldier`, `scout`.
  final String type;

  int tier;

  /// Owning faction. Not final — see the note in [Building.faction].
  String faction;

  /// Tintable grayscale layer. Null if this tier's art has not shipped yet.
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

  /// The unit class's combat power stat (balance §2.1). Never consumed — it is
  /// the value [remainingPower] starts from.
  double combatPower;

  /// Combat power this unit still has. Reduced by clashes on the path, and it
  /// is what actually lands on a node when the unit arrives.
  double remainingPower;

  /// Called when the unit reaches its destination — and only then, so a unit
  /// killed on the way never lands a hit on the target node.
  void Function(Unit unit)? onArrived;

  /// Called when the unit leaves the game for any reason, arrival or defeat.
  /// Lets the game clear it from its route without the unit knowing routes
  /// exist. Fires from Flame's own removal lifecycle, so it cannot be missed.
  void Function(Unit unit)? onDespawn;

  /// True once the unit has been resolved away by combat, so an already-dead
  /// unit cannot keep fighting during the same frame.
  bool get isDefeated => remainingPower <= 0;

  /// Guards against acting twice. `removeFromParent` only *queues* the removal,
  /// so without this a unit sitting on its target would re-arrive — and land
  /// its hit again — on every frame until the queue is processed.
  bool _isSpent = false;

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
        remainingPower = combatPower,
        tintPaint = FactionManager().getPaint(faction);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hitbox drives path combat. Flame's broadphase already handles the
    // pairing, and it keeps working once multi-node maps create crossing lanes.
    add(CircleHitbox(collisionType: CollisionType.active));

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

    if (_isSpent || isDefeated) return;

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
    // Grayscale silhouette through the faction ColorFilter, scaled from its
    // 64x64 native size down to this unit's [size].
    baseSprite?.render(canvas, size: size, overridePaint: tintPaint);

    // Detail layer is never tinted — charcoal visors and gold chevrons stay
    // the same colour on every faction.
    detailSprite?.render(canvas, size: size);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is! Unit || other.faction == faction) return;

    clashWith(other);
  }

  /// Resolves a clash with an opposing [other] on the path.
  ///
  /// Both units lose the lesser of their two remaining powers; whichever still
  /// has power left carries on. This discrete, pairwise rule reproduces the
  /// *group* formula in balance §3.1 exactly, without needing to gather units
  /// into groups first. Both worked examples from that section fall out of it:
  ///
  ///  - 10 Infantry (1.0) meet 5 Heavy Soldiers (2.0): each Heavy absorbs two
  ///    Infantry before dying, so all 15 units are lost and none arrive.
  ///  - 10 Infantry meet 4 Infantry: four mutual kills, and 6 continue on.
  ///
  /// Both units receive `onCollisionStart` for the same pair, so the defeated
  /// check makes the second call a no-op rather than double-resolving.
  void clashWith(Unit other) {
    if (isDefeated || other.isDefeated) return;

    final absorbed = math.min(remainingPower, other.remainingPower);
    remainingPower -= absorbed;
    other.remainingPower -= absorbed;

    if (isDefeated) {
      onDefeated();
    }
    if (other.isDefeated) {
      other.onDefeated();
    }
  }

  /// Called when the unit is destroyed in combat rather than arriving. It never
  /// reaches its target, so [onArrived] deliberately does not fire.
  void onDefeated() {
    if (_isSpent) return;
    _isSpent = true;
    removeFromParent();
  }

  /// Called once the unit reaches [targetPosition].
  void onReachedTarget() {
    if (_isSpent) return;
    _isSpent = true;
    onArrived?.call(this);
    removeFromParent();
  }

  @override
  void onRemove() {
    onDespawn?.call(this);
    super.onRemove();
  }

  void moveTo(Vector2 target) {
    targetPosition = target.clone();
  }

  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }
}
