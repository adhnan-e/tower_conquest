import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/models/level_data.dart';
import 'package:tower_conquest/game/screens/win_condition_overlay.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

LevelData _level({required String winCondition}) {
  return LevelData(
    id: 'l',
    name: 'l',
    campaign: 1,
    levelNumber: 1,
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
        id: 'e',
        type: 'barracks',
        faction: 'enemy',
        position: Vector2(0, -220),
        tier: 1,
        unitsInside: 10,
      ),
    ],
    links: const [],
    winCondition: winCondition,
    timeLimitSeconds: null,
    rewards: const LevelRewards(),
  );
}

void main() {
  group('WinConditionOverlay.describe', () {
    test('translates the one Stage 1 supports into plain language', () {
      expect(
        WinConditionOverlay.describe('capture_all_enemy_nodes'),
        'Capture all enemy towers',
      );
    });

    test('falls back gracefully for an unrecognised identifier', () {
      // LevelData's own schema validation would reject this before a real
      // level ever reached the overlay — this guards the describe() method
      // itself against ever crashing on a future win condition.
      expect(
        WinConditionOverlay.describe('escort_the_caravan'),
        'Complete the objective',
      );
    });
  });

  group('WinConditionOverlay widget', () {
    testWidgets('displays the current level\'s win condition', (
      tester,
    ) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(winCondition: 'capture_all_enemy_nodes');

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WinConditionOverlay(game: game))),
      );

      expect(find.text('Capture all enemy towers'), findsOneWidget);
    });

    testWidgets('is fully visible immediately after appearing', (
      tester,
    ) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(winCondition: 'capture_all_enemy_nodes');

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WinConditionOverlay(game: game))),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('fades out after 5 seconds', (tester) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(winCondition: 'capture_all_enemy_nodes');

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WinConditionOverlay(game: game))),
      );

      await tester.pump(const Duration(seconds: 5));

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });

    testWidgets(
        'never blocks gameplay: a tap where the overlay is drawn still '
        'reaches what is beneath it', (tester) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(winCondition: 'capture_all_enemy_nodes');
      var towerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Stands in for a tower directly beneath where the overlay
                // renders (top-centre) — the acceptance criterion this is
                // checking is that the overlay never intercepts this tap.
                Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => towerTapped = true,
                    child: const SizedBox(
                      key: Key('stand-in-tower'),
                      width: 96,
                      height: 96,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
                WinConditionOverlay(game: game),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('stand-in-tower')));
      await tester.pump();

      expect(towerTapped, isTrue);
    });

    testWidgets('renders readable white text over a dark background', (
      tester,
    ) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(winCondition: 'capture_all_enemy_nodes');

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WinConditionOverlay(game: game))),
      );

      final text = tester.widget<Text>(
        find.text('Capture all enemy towers'),
      );
      expect(text.style?.color, Colors.white);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });
}
