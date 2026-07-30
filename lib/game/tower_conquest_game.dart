import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'constants/asset_paths.dart';
import 'components/buildings/building.dart';
import 'components/map/path_link.dart';
import 'components/units/unit.dart';
import 'managers/asset_manager.dart';
import 'managers/enemy_commander.dart';
import 'screens/result_overlay.dart';

/// How a match ended, or that it is still running.
enum GameStatus { playing, victory, defeat }

/// The MVP game: one player node, one enemy node, a visible route between them,
/// and the full core loop from GDD §2 — generate, deploy, travel, engage,
/// capture.
///
/// Still Milestone 2+: building types and tiers, in-match upgrades, level
/// loading from JSON, and the real AI opponent.
class TowerConquestGame extends FlameGame with HasCollisionDetection {
  /// World-space offset of each node from the centre of the screen. Positions
  /// are relative to the origin rather than to `size`, so the layout stays
  /// centred on any screen without a resize handler.
  static const double _nodeOffsetY = 220;

  static final Vector2 _buildingSize = Vector2.all(96);
  static final Vector2 _unitSize = Vector2.all(20);

  late Building playerBase;
  late Building enemyBase;

  /// Every node on the map, player-owned or not.
  final List<Building> nodes = [];

  /// Every route on the map. In Milestone 2 this is built from the level's
  /// `paths` array (`05_levels/01_LEVEL_DESIGN.md` §5) rather than hard-coded.
  final List<PathLink> paths = [];

  /// The stand-in opponent — see [EnemyCommander] for why it is not the AI.
  final EnemyCommander enemyCommander = EnemyCommander();

  /// The node currently selected as the source of a send, if any.
  Building? selectedBuilding;

  GameStatus status = GameStatus.playing;

  bool get isMatchOver => status != GameStatus.playing;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF1B2430);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2.zero();

    // Decode the whole Phase 1 art pack before anything mounts. Units spawn
    // mid-match and have no placeholder to fall back on, so a first-use decode
    // would leave them invisible for a frame or two.
    await AssetManager().preload(AssetPaths.phase1Sprites());

    // The game registers its own result screen rather than relying on the
    // GameWidget to supply it, so the match can end correctly whether or not
    // there is a widget tree — which is exactly the case under test.
    overlays.addEntry(
      ResultOverlay.id,
      (_, __) => ResultOverlay(game: this),
    );

    // Driven by a component rather than an `update` override: a root FlameGame
    // never calls its own `update` (FlameGame.updateTree skips it when
    // `parent == null`), so an override here would silently never run.
    await add(_FrameDriver(_runEnemyCommander));

    await _buildLevel();
  }

  /// Runs the opponent's decisions once per frame.
  void _runEnemyCommander() {
    if (isMatchOver) return;

    enemyCommander.update(
      nodes: nodes,
      send: (from, to) => sendUnit(from: from, to: to) != null,
    );
  }

  /// Tap the player node to select it, then tap the enemy node to send a unit.
  /// Tapping the selected node again clears the selection.
  void _onBuildingTapped(Building building) {
    if (isMatchOver) return;

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
  /// spare and the two are connected. Returns the unit, or null if the send
  /// could not happen.
  Unit? sendUnit({required Building from, required Building to}) {
    if (isMatchOver) return null;

    final route = linkBetween(from, to);
    if (route == null) return null;
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

    // Light up the route for as long as this unit is on it. onDespawn fires
    // however the unit leaves, so a unit killed on the path clears the route
    // just as an arriving one does.
    route.beginFlow(from);
    unit.onDespawn = (_) => route.endFlow(from);
    unit.onArrived = (arrived) => _resolveArrival(arrived, to);

    world.add(unit);
    return unit;
  }

  /// A unit reached [target]: friendly arrivals reinforce it, hostile ones
  /// attack it (balance §3.2).
  void _resolveArrival(Unit unit, Building target) {
    if (unit.faction == target.faction) {
      target.reinforce(1);
      return;
    }

    final captured = target.applyAttack(unit.remainingPower, unit.faction);
    if (captured) {
      _evaluateOutcome();
    }
  }

  /// Win by owning every node, lose by owning none (GDD §2.5). Expressed over
  /// [nodes] rather than the two fields, so it still holds once levels add
  /// neutral and multi-node maps.
  void _evaluateOutcome() {
    if (isMatchOver) return;

    final playerNodes = nodes.where((n) => n.faction == 'player').length;

    if (playerNodes == nodes.length) {
      _endMatch(GameStatus.victory);
    } else if (playerNodes == 0) {
      _endMatch(GameStatus.defeat);
    }
  }

  void _endMatch(GameStatus outcome) {
    status = outcome;
    _select(null);
    overlays.add(ResultOverlay.id);
  }

  /// Tears the match down and rebuilds it from the starting layout.
  void restart() {
    overlays.remove(ResultOverlay.id);
    status = GameStatus.playing;
    selectedBuilding = null;

    world.removeAll(world.children.toList());
    nodes.clear();
    paths.clear();

    _buildLevel();
  }

  /// The route joining [from] and [to], or null if the two are not connected.
  PathLink? linkBetween(Building from, Building to) {
    for (final path in paths) {
      if (path.connects(from, to)) return path;
    }
    return null;
  }

  Future<void> _buildLevel() async {
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

    nodes.addAll([playerBase, enemyBase]);
    paths.add(PathLink(a: playerBase, b: enemyBase));

    await world.addAll([...paths, ...nodes]);
  }

  void _select(Building? building) {
    selectedBuilding?.isSelected = false;
    selectedBuilding = building;
    building?.isSelected = true;

    // Highlight every route leading out of the selected node, so the player can
    // see where units can actually be sent.
    for (final path in paths) {
      path.isHighlighted = building != null && path.touches(building);
    }
  }
}

/// Calls [_tick] once per frame from inside the component tree.
class _FrameDriver extends Component {
  final void Function() _tick;

  _FrameDriver(this._tick);

  @override
  void update(double dt) {
    super.update(dt);
    _tick();
  }
}
