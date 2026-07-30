import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/buildings/building.dart';
import 'components/units/unit.dart';

/// The MVP game: one player node, one enemy node, tap-to-send.
///
/// Scope is deliberately the Milestone 1 slice from
/// `planning/04_implementation/02_DEVELOPMENT_PROMPT.md` — generation, unit
/// travel and the faction tinting pipeline. Path combat, node capture,
/// upgrades, AI and level loading are Milestone 2+.
class TowerConquestGame extends FlameGame {
  /// World-space offset of each node from the centre of the screen. Positions
  /// are relative to the origin rather than to `size`, so the layout stays
  /// centred on any screen without a resize handler.
  static const double _nodeOffsetY = 220;

  static final Vector2 _buildingSize = Vector2.all(96);
  static final Vector2 _unitSize = Vector2.all(20);

  late final Building playerBase;
  late final Building enemyBase;

  /// The node currently selected as the source of a send, if any.
  Building? selectedBuilding;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF1B2430);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2.zero();

    // Tier 1 Barracks stats from balance §1.1: capacity 50, 1.0 units/s.
    playerBase = Building(
      type: 'barracks',
      tier: 1,
      faction: 'player',
      position: Vector2(0, _nodeOffsetY),
      size: _buildingSize,
      unitsInside: 10,
    )..onTapped = _onBuildingTapped;

    enemyBase = Building(
      type: 'barracks',
      tier: 1,
      faction: 'enemy',
      position: Vector2(0, -_nodeOffsetY),
      size: _buildingSize,
      unitsInside: 10,
    )..onTapped = _onBuildingTapped;

    await world.addAll([playerBase, enemyBase]);
  }

  /// Tap the player node to select it, then tap the enemy node to send a unit.
  /// Tapping the selected node again clears the selection.
  void _onBuildingTapped(Building building) {
    final source = selectedBuilding;

    if (source == null) {
      // Only player-owned nodes can be used as a source.
      if (building.faction == 'player') {
        _select(building);
      }
      return;
    }

    if (identical(building, source)) {
      _select(null);
      return;
    }

    sendUnit(from: source, to: building);
    _select(null);
  }

  /// Spawns a single unit travelling from [from] to [to], if [from] has one to
  /// spare. Returns the unit, or null when the source node is empty.
  Unit? sendUnit({required Building from, required Building to}) {
    if (from.takeUnits(1) == 0) return null;

    // Infantry stats from balance §2.1: 100 px/s, combat power 1.0.
    final unit = Unit(
      type: 'infantry',
      tier: 1,
      faction: from.faction,
      position: from.position.clone(),
      size: _unitSize,
      targetPosition: to.position.clone(),
    );

    world.add(unit);
    return unit;
  }

  void _select(Building? building) {
    selectedBuilding?.isSelected = false;
    selectedBuilding = building;
    building?.isSelected = true;
  }
}
