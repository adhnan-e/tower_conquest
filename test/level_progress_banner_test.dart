import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/models/level_data.dart';
import 'package:tower_conquest/game/screens/level_progress_banner.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

Building _building(String faction) => Building(
      type: 'barracks',
      tier: 1,
      faction: faction,
      position: Vector2.zero(),
      size: Vector2.all(96),
    );

/// A level with one player node and two enemy nodes, so "N of 2 captured"
/// has somewhere to go.
LevelData _twoEnemyLevel({int campaign = 1, int levelNumber = 1}) {
  return LevelData(
    id: 'l',
    name: 'First Contact',
    campaign: campaign,
    levelNumber: levelNumber,
    description: '',
    difficulty: 'normal',
    width: 800,
    height: 600,
    nodes: [
      NodeData(
        id: 'p',
        type: 'barracks',
        faction: 'player',
        position: Vector2(0, 220),
        tier: 1,
        unitsInside: 10,
      ),
      NodeData(
        id: 'e1',
        type: 'barracks',
        faction: 'enemy',
        position: Vector2(-100, -220),
        tier: 1,
        unitsInside: 10,
      ),
      NodeData(
        id: 'e2',
        type: 'barracks',
        faction: 'enemy',
        position: Vector2(100, -220),
        tier: 1,
        unitsInside: 10,
      ),
    ],
    links: const [],
    winCondition: 'capture_all_enemy_nodes',
    timeLimitSeconds: null,
    rewards: const LevelRewards(),
  );
}

Future<TowerConquestGame> _pumpBanner(
  WidgetTester tester, {
  required LevelData level,
  required List<Building> nodes,
}) async {
  final game = TowerConquestGame()
    ..currentLevel = level
    ..nodes.addAll(nodes);

  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: LevelProgressBanner(game: game))),
  );

  return game;
}

void main() {
  testWidgets('displays the level name, campaign, and level number',
      (tester) async {
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(campaign: 1, levelNumber: 1),
      nodes: [_building('player'), _building('enemy'), _building('enemy')],
    );

    expect(find.text('Campaign 1, Level 1: First Contact'), findsOneWidget);
  });

  testWidgets('reflects a different campaign/level combination',
      (tester) async {
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(campaign: 2, levelNumber: 7),
      nodes: [_building('player'), _building('enemy'), _building('enemy')],
    );

    expect(find.text('Campaign 2, Level 7: First Contact'), findsOneWidget);
  });

  testWidgets('shows zero captured at the start of a match', (tester) async {
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(),
      nodes: [_building('player'), _building('enemy'), _building('enemy')],
    );

    expect(find.text('0 of 2 enemy towers captured'), findsOneWidget);
  });

  testWidgets('updates the progress text as an enemy node is captured',
      (tester) async {
    final capturedNode = _building('enemy');
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(),
      nodes: [_building('player'), capturedNode, _building('enemy')],
    );

    // Capture in place, exactly as Building._capture does: flip the faction
    // rather than replacing the component.
    capturedNode.changeFaction('player');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('1 of 2 enemy towers captured'), findsOneWidget);
  });

  testWidgets('shows every enemy node captured once all of them flip',
      (tester) async {
    final first = _building('enemy');
    final second = _building('enemy');
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(),
      nodes: [_building('player'), first, second],
    );

    first.changeFaction('player');
    second.changeFaction('player');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('2 of 2 enemy towers captured'), findsOneWidget);
  });

  testWidgets('shows a progress bar reflecting captured proportion',
      (tester) async {
    final capturedNode = _building('enemy');
    await _pumpBanner(
      tester,
      level: _twoEnemyLevel(),
      nodes: [_building('player'), capturedNode, _building('enemy')],
    );

    capturedNode.changeFaction('player');
    await tester.pump(const Duration(milliseconds: 250));

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.5);
  });
}
