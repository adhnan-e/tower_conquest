import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'constants/asset_paths.dart';
import 'components/buildings/building.dart';
import 'components/map/path_feedback_layer.dart';
import 'components/map/path_link.dart';
import 'components/units/unit.dart';
import 'managers/asset_manager.dart';
import 'managers/enemy_commander.dart';
import 'managers/level_manager.dart';
import 'managers/level_runtime_factory.dart';
import 'models/level_data.dart';
import 'screens/building_info_panel.dart';
import 'screens/gesture_hint_system.dart';
import 'screens/level_progress_banner.dart';
import 'screens/restart_button.dart';
import 'screens/result_overlay.dart';
import 'screens/win_condition_overlay.dart';

/// How a match ended, or that it is still running.
enum GameStatus { playing, victory, defeat }

/// The game: one player node, one enemy node, a visible route between them,
/// the full core loop from GDD §2 — generate, deploy, travel, engage, capture
/// — building upgrades (Tiers 1-5), a tactical AI opponent, and a
/// data-driven level loaded through [LevelManager].
///
/// Still ahead: a campaign catalog beyond the single default level, and the
/// meta-progression, obstacle, and hazard systems Phase 3 defers to later
/// stages.
class TowerConquestGame extends FlameGame with HasCollisionDetection {
  static final Vector2 _buildingSize = Vector2.all(96);
  static final Vector2 _unitSize = Vector2.all(20);

  late Building playerBase;
  late Building enemyBase;

  /// The level currently loaded — set by [_loadLevel]. Read by the Stage 2
  /// presentation overlays (name/campaign/level number, win condition, the
  /// gesture hints' first-level gate); nothing here mutates it.
  late LevelData currentLevel;

  /// Every node on the map, player-owned or not.
  final List<Building> nodes = [];

  /// Every route on the map, resolved from the loaded level's [LinkData] by
  /// [LevelRuntimeFactory.linksFor].
  final List<PathLink> paths = [];

  /// The tactical opponent, driving [nodes] it owns via an [AIStrategy] —
  /// see [EnemyCommander]. Overridable so tests that aren't about the AI can
  /// swap in an inert one instead of fighting a live opponent for control of
  /// `enemyBase`.
  final EnemyCommander enemyCommander;

  /// The node currently selected as the source of a send, if any.
  Building? selectedBuilding;

  GameStatus status = GameStatus.playing;

  /// Seconds of match time elapsed, reset on [restart]. Feeds the AI
  /// strategy's upgrade cooldown via [EnemyCommander.update].
  double elapsedTime = 0;

  TowerConquestGame({EnemyCommander? enemyCommander})
      : enemyCommander = enemyCommander ?? EnemyCommander();

  bool get isMatchOver => status != GameStatus.playing;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF1B2430);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2.zero();

    // Decode the whole art pack before anything mounts. Units spawn mid-match
    // and have no placeholder to fall back on, so a first-use decode would
    // leave them invisible for a frame or two. Phase 2 sprites (Tiers 2-5)
    // don't exist yet — AssetManager.preload silently skips anything the
    // asset manifest doesn't list — so this line needs no further edits once
    // the orchestrator delivers that art; it just starts preloading.
    await AssetManager().preload([
      ...AssetPaths.phase1Sprites(),
      ...AssetPaths.phase2Sprites(),
    ]);

    // The game registers its own result screen rather than relying on the
    // GameWidget to supply it, so the match can end correctly whether or not
    // there is a widget tree — which is exactly the case under test.
    overlays.addEntry(
      ResultOverlay.id,
      (_, __) => ResultOverlay(game: this),
    );

    // Shown for as long as a building stays selected — see [_select].
    overlays.addEntry(
      BuildingInfoPanel.id,
      (_, __) => BuildingInfoPanel(game: this),
    );

    // Stage 2 presentation overlays: added for the duration of a live match
    // in [_loadLevel], removed alongside each other in [_endMatch].
    overlays.addEntry(
      LevelProgressBanner.id,
      (_, __) => LevelProgressBanner(game: this),
    );
    overlays.addEntry(
      WinConditionOverlay.id,
      (_, __) => WinConditionOverlay(game: this),
    );
    overlays.addEntry(
      GestureHintSystem.id,
      (_, __) => GestureHintSystem(game: this),
    );
    overlays.addEntry(
      RestartButton.id,
      (_, __) => RestartButton(game: this),
    );

    // Driven by a component rather than an `update` override: a root FlameGame
    // never calls its own `update` (FlameGame.updateTree skips it when
    // `parent == null`), so an override here would silently never run.
    await add(_FrameDriver(_onFrame));

    await _buildLevel();
  }

  /// Advances match time and runs the opponent's decisions once per frame.
  void _onFrame(double dt) {
    if (isMatchOver) return;

    elapsedTime += dt;

    enemyCommander.update(
      nodes: nodes,
      gameTime: elapsedTime,
      hostileUnits: world.children
          .whereType<Unit>()
          .where((u) => u.faction != enemyCommander.faction)
          .toList(),
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

    overlays.remove(LevelProgressBanner.id);
    overlays.remove(WinConditionOverlay.id);
    overlays.remove(GestureHintSystem.id);
    overlays.remove(RestartButton.id);
    overlays.add(ResultOverlay.id);
  }

  /// Tears the match down and rebuilds it from the starting layout.
  void restart() {
    overlays.remove(ResultOverlay.id);
    status = GameStatus.playing;
    selectedBuilding = null;
    elapsedTime = 0;

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

  /// Loads the default level and builds it into the world. A malformed or
  /// missing level asset falls back to [LevelManager.defaultLevel] rather
  /// than taking the game down — see [LevelManager.loadOrFallback].
  Future<void> _buildLevel() async {
    final level =
        await LevelManager().loadOrFallback(LevelManager.defaultLevelId);
    await _loadLevel(level);
  }

  /// Instantiates every node and route [level] declares, via
  /// [LevelRuntimeFactory], and mounts them into the world.
  ///
  /// [playerBase]/[enemyBase] stay as the first node found for each faction —
  /// existing code and tests depend on these two fields, and Stage 1's
  /// default level still has exactly one of each, so this preserves current
  /// behaviour exactly. A level with more than one node per faction is not
  /// yet supported by anything that reads these two fields.
  Future<void> _loadLevel(LevelData level) async {
    currentLevel = level;

    final buildingsByNodeId = <String, Building>{};

    for (final node in level.nodes) {
      final building = LevelRuntimeFactory.buildingFor(
        node,
        size: _buildingSize,
        onTapped: _onBuildingTapped,
      );
      buildingsByNodeId[node.id] = building;
      nodes.add(building);
    }

    paths.addAll(LevelRuntimeFactory.linksFor(level, buildingsByNodeId));

    playerBase = nodes.firstWhere((n) => n.faction == 'player');
    enemyBase = nodes.firstWhere((n) => n.faction == 'enemy');

    await world.addAll([...paths, ...nodes, PathFeedbackLayer(paths)]);

    overlays.add(LevelProgressBanner.id);
    overlays.add(WinConditionOverlay.id);
    overlays.add(GestureHintSystem.id);
    overlays.add(RestartButton.id);
  }

  /// Clears the current selection, exactly as tapping the selected node again
  /// would. The [BuildingInfoPanel]'s close button goes through this rather
  /// than reaching into [selectedBuilding] directly, so both paths to closing
  /// it (tapping the map, tapping the panel) stay in sync.
  void deselect() => _select(null);

  void _select(Building? building) {
    selectedBuilding?.isSelected = false;
    selectedBuilding = building;
    building?.isSelected = true;

    // Highlight every route leading out of the selected node, so the player can
    // see where units can actually be sent.
    for (final path in paths) {
      path.isHighlighted = building != null && path.touches(building);
    }

    // The info panel tracks selection one-for-one: up while a node is
    // selected, gone the instant it isn't (deselect, a send, or match end).
    if (building != null) {
      overlays.add(BuildingInfoPanel.id);
    } else {
      overlays.remove(BuildingInfoPanel.id);
    }
  }
}

/// Calls [_tick] once per frame from inside the component tree, passing the
/// frame's delta time.
class _FrameDriver extends Component {
  final void Function(double dt) _tick;

  _FrameDriver(this._tick);

  @override
  void update(double dt) {
    super.update(dt);
    _tick(dt);
  }
}
