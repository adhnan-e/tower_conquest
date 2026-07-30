import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors, FontWeight, TextStyle;

import '../../constants/balance.dart';
import '../../constants/colors.dart';
import '../../managers/asset_manager.dart';

/// A node on the map: generates units over time, holds them up to a capacity,
/// and displays its faction through runtime colour tinting.
///
/// Base stats default to a Tier 1 Barracks from
/// `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` §1.1
/// (capacity 50, generation 1.0 units/s).
///
/// Rendered from the Phase 1 art pack: a grayscale base layer drawn through the
/// faction `ColorFilter`, then an untinted detail layer on top. Native art is
/// 256x256 and is scaled to whatever [size] the level gives the node.
///
/// **Why not `SpriteComponent`?** `02_DEVELOPMENT_PROMPT.md` asks for one, but
/// `SpriteComponent` asserts `sprite != null` when it mounts. Sprites are
/// resolved asynchronously in [onLoad], so that assert fires before the art
/// arrives and the node never mounts — a blank screen in debug, and a latent
/// trap in release where asserts are stripped. Extending [PositionComponent]
/// and drawing the sprite here does exactly what `SpriteComponent` does
/// internally (`Sprite.render` with an override paint) without that trap. It
/// also keeps tiers whose art has not shipped yet from taking the game down.
class Building extends PositionComponent with TapCallbacks {
  /// Building archetype: `barracks`, `tower`, `factory`, `command_center`.
  final String type;

  /// Upgrade tier, 1-5. Mutated by [upgrade]. Buildings are always constructed
  /// at Tier 1; see [_baseCapacity] for why constructing directly at a higher
  /// tier is not supported.
  int tier;

  /// Owning faction. Not final — capture reassigns it, which is why the guide's
  /// `final String faction` could never compile alongside `changeFaction()`.
  String faction;

  /// Tintable grayscale layer. Null if this tier's art has not shipped yet.
  Sprite? baseSprite;

  /// Fixed-colour layer (emblems, doorways). Never tinted, always optional.
  Sprite? detailSprite;

  /// Shared, cached tint paint. Treated as read-only — see [FactionManager].
  ui.Paint tintPaint;

  int unitsInside;
  double generationRate;
  int maxCapacity;

  /// Multiplies units inside into defence value (balance §1.1): Barracks
  /// 1.0x, Tower 1.5x, Factory 1.2x, Command Center 2.0x at Tier 1, scaling
  /// with [tier] via [upgrade] — see [BuildingBalance].
  double defenseMultiplier;

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

  /// Partial defence damage carried between hits.
  ///
  /// Defence is `unitsInside * defenseMultiplier`, so an attack rarely removes
  /// a whole number of units — against a 1.5x Tower, 10 combat power clears
  /// 6.67 units. Carrying the remainder here keeps the unit count an honest
  /// integer without silently discarding or inventing fractions of a unit.
  double _defenseFraction = 0;

  /// Tier 1 stats this building was constructed with. [upgrade] recomputes
  /// [maxCapacity], [generationRate] and [defenseMultiplier] from these every
  /// time, rather than compounding the previous tier's already-adjusted
  /// values — see the note on [BuildingBalance] for why that distinction
  /// matters. Buildings are always constructed at Tier 1 with these as their
  /// base stats; [upgrade] is the only supported way to move up from there.
  final int _baseCapacity;
  final double _baseGenerationRate;
  final double _baseDefenseMultiplier;

  static final _counterTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  );

  static final _tierTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
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
    this.defenseMultiplier = 1.0,
    super.anchor = Anchor.center,
  })  : faction = faction,
        tintPaint = FactionManager().getPaint(faction),
        _baseCapacity = maxCapacity,
        _baseGenerationRate = generationRate,
        _baseDefenseMultiplier = defenseMultiplier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSpritesForTier();
  }

  /// (Re)loads the sprite pair for the current [tier], falling back to Tier 1
  /// art if this tier's has not been generated yet — see
  /// [AssetManager.buildingBaseSprite].
  Future<void> _loadSpritesForTier() async {
    final assets = AssetManager();
    baseSprite = await assets.buildingBaseSprite(type, tier);
    detailSprite = await assets.buildingDetailSprite(type, tier);
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
    // Grayscale silhouette through the faction ColorFilter, scaled from its
    // 256x256 native size down to whatever [size] the level gives this node.
    baseSprite?.render(canvas, size: size, overridePaint: tintPaint);

    // Detail layer is deliberately untinted — it carries the fixed-colour
    // identity (charcoal openings, gold insignia) that survives every recolour.
    detailSprite?.render(canvas, size: size);

    _renderUnitCounter(canvas);
    _renderTierIndicator(canvas);

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

  /// Adds units from a friendly arrival, clamped to capacity.
  ///
  /// Returns how many were actually absorbed — a full node turns reinforcements
  /// away rather than exceeding [maxCapacity].
  int reinforce(int count) {
    final absorbed = count.clamp(0, maxCapacity - unitsInside);
    unitsInside += absorbed;
    return absorbed;
  }

  /// Applies [power] combat power from [attackerFaction] against this node.
  ///
  /// Follows balance §3.2: damage reduces [defenseValue], and the node is
  /// captured the moment its defence reaches zero. Returns whether that
  /// happened. Attacking a node that already belongs to [attackerFaction] does
  /// nothing — that case is a reinforcement, see [reinforce].
  bool applyAttack(double power, String attackerFaction) {
    if (attackerFaction == faction || power <= 0) return false;

    // Work in defence points, then convert back to whole units.
    final remainingDefense = defenseValue - power;

    if (remainingDefense <= 0) {
      _capture(attackerFaction);
      return true;
    }

    final unitsRemaining = remainingDefense / defenseMultiplier;
    unitsInside = unitsRemaining.floor();
    _defenseFraction = unitsRemaining - unitsInside;
    return false;
  }

  /// Cost to upgrade to the next tier, or 0 if this building cannot upgrade
  /// further (already at [BuildingBalance.maxTier], or [type] is not an
  /// upgradeable archetype — see [BuildingBalance.isUpgradeable]).
  int get upgradeCost {
    if (tier >= BuildingBalance.maxTier) return 0;
    if (!BuildingBalance.isUpgradeable(type)) return 0;
    return BuildingBalance.upgradeCostForTier(tier + 1);
  }

  /// Whether [upgrade] would currently succeed: not already at max tier, an
  /// upgradeable archetype, and enough units on hand to pay [upgradeCost].
  bool canUpgrade() {
    final cost = upgradeCost;
    return cost > 0 && unitsInside >= cost;
  }

  /// Upgrades to the next tier, deducting [upgradeCost] from [unitsInside] and
  /// recalculating [maxCapacity], [generationRate] and [defenseMultiplier]
  /// from the Tier 1 base — see [BuildingBalance] for why recalculating from
  /// base, rather than compounding the previous tier's stats, is required for
  /// correctness. Swaps in this tier's sprites once loaded.
  ///
  /// Returns whether the upgrade happened. A no-op (returns false) at max
  /// tier, on a non-upgradeable archetype, or with insufficient units — the
  /// same three conditions [canUpgrade] checks.
  bool upgrade() {
    if (!canUpgrade()) return false;

    unitsInside -= upgradeCost;
    tier += 1;
    _recalculateStats();

    // Fire-and-forget: the current tier's sprites keep rendering (or the
    // placeholder-free "nothing" if none exist yet) until this resolves.
    unawaited(_loadSpritesForTier());

    return true;
  }

  /// Recomputes [maxCapacity], [generationRate] and [defenseMultiplier] for
  /// the current [tier] from the stored Tier 1 base stats.
  void _recalculateStats() {
    maxCapacity = _baseCapacity + BuildingBalance.capacityBonusForTier(tier);
    generationRate =
        _baseGenerationRate * BuildingBalance.genRateMultiplierForTier(tier);
    defenseMultiplier = _baseDefenseMultiplier *
        BuildingBalance.defenseMultiplierBonusForTier(tier);
  }

  /// Switches ownership and refreshes the cached tint. Used on capture.
  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }

  /// Defence value = units inside × the building's defence multiplier
  /// (balance §1.3), including any partial unit left over from a previous hit.
  double get defenseValue =>
      (unitsInside + _defenseFraction) * defenseMultiplier;

  /// Balance §3.2: the node flips faction, resets to zero units, and starts
  /// generating for its new owner.
  void _capture(String newFaction) {
    changeFaction(newFaction);
    unitsInside = 0;
    _defenseFraction = 0;
    _genAccumulator = 0;
  }

  void _renderUnitCounter(ui.Canvas canvas) {
    _counterTextPaint.render(
      canvas,
      '$unitsInside',
      Vector2(size.x / 2, size.y * 0.66),
      anchor: Anchor.center,
    );
  }

  /// A small "T<n>" badge in the top-left corner, visible at every tier so a
  /// glance at the map shows what has and hasn't been upgraded yet.
  void _renderTierIndicator(ui.Canvas canvas) {
    final badgeRadius = size.x * 0.12;
    final centre = ui.Offset(badgeRadius + 4, badgeRadius + 4);

    canvas.drawCircle(
      centre,
      badgeRadius,
      ui.Paint()..color = const ui.Color(0xCC000000),
    );

    _tierTextPaint.render(
      canvas,
      'T$tier',
      Vector2(centre.dx, centre.dy),
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
