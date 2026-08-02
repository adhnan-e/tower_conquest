import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/managers/gesture_hint_controller.dart';
import 'package:tower_conquest/game/models/level_data.dart';
import 'package:tower_conquest/game/screens/gesture_hint_system.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

DateTime _t(int seconds) =>
    DateTime(2026, 1, 1).add(Duration(seconds: seconds));

LevelData _level({int campaign = 1, int levelNumber = 1}) {
  return LevelData(
    id: 'l',
    name: 'l',
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
        id: 'e',
        type: 'barracks',
        faction: 'enemy',
        position: Vector2(0, -220),
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

void main() {
  group('GestureHintController state transitions', () {
    test('starts in the initial state, visible, with the first hint', () {
      final controller = GestureHintController(now: _t(0));

      expect(controller.state, GestureHintState.initial);
      expect(controller.isVisible, isTrue);
      expect(controller.text, 'Tap a tower to select it');
    });

    test('does not advance without a selection', () {
      final controller = GestureHintController(now: _t(0));

      controller.tick(hasSelection: false, hasActivePath: false, now: _t(1));

      expect(controller.state, GestureHintState.initial);
    });

    test('a selection advances initial to selected', () {
      final controller = GestureHintController(now: _t(0));

      controller.tick(hasSelection: true, hasActivePath: false, now: _t(1));

      expect(controller.state, GestureHintState.selected);
      expect(controller.text, 'Tap another tower to send units');
      expect(controller.isVisible, isTrue);
    });

    test('an active path while still initial does not skip to pathCreated', () {
      final controller = GestureHintController(now: _t(0));

      // hasActivePath alone, with no selection yet, must not fast-forward
      // past the "select a tower" step.
      controller.tick(hasSelection: false, hasActivePath: true, now: _t(1));

      expect(controller.state, GestureHintState.initial);
    });

    test('an active path advances selected to pathCreated', () {
      final controller = GestureHintController(now: _t(0));
      controller.tick(hasSelection: true, hasActivePath: false, now: _t(1));

      controller.tick(hasSelection: true, hasActivePath: true, now: _t(2));

      expect(controller.state, GestureHintState.pathCreated);
      expect(controller.text, 'Capture every enemy tower to win');
    });

    test('repeated ticks with the same trigger do not re-advance', () {
      final controller = GestureHintController(now: _t(0));
      controller.tick(hasSelection: true, hasActivePath: false, now: _t(1));

      controller.tick(hasSelection: true, hasActivePath: false, now: _t(2));
      controller.tick(hasSelection: true, hasActivePath: false, now: _t(3));

      expect(controller.state, GestureHintState.selected);
    });

    test('losing the selection afterwards does not regress the state', () {
      final controller = GestureHintController(now: _t(0));
      controller.tick(hasSelection: true, hasActivePath: false, now: _t(1));

      controller.tick(hasSelection: false, hasActivePath: false, now: _t(2));

      expect(controller.state, GestureHintState.selected);
    });
  });

  group('GestureHintController fade and reshow timing', () {
    test('the initial hint fades after its 8 second duration', () {
      final controller = GestureHintController(now: _t(0));

      controller.tick(hasSelection: false, hasActivePath: false, now: _t(8));

      expect(controller.isVisible, isFalse);
      expect(controller.text, isNull);
      expect(controller.state, GestureHintState.initial,
          reason: 'fading out is not the same as completing the step');
    });

    test('a faded hint reappears after 15 more seconds of inactivity', () {
      final controller = GestureHintController(now: _t(0));
      controller.tick(hasSelection: false, hasActivePath: false, now: _t(8));
      expect(controller.isVisible, isFalse);

      controller.tick(hasSelection: false, hasActivePath: false, now: _t(23));

      expect(controller.isVisible, isTrue);
      expect(controller.text, 'Tap a tower to select it');
    });

    test('the last hint (pathCreated) fades to done without reshowing', () {
      final controller = GestureHintController(now: _t(0));
      controller.tick(hasSelection: true, hasActivePath: false, now: _t(1));
      controller.tick(hasSelection: true, hasActivePath: true, now: _t(2));

      // pathCreated's own fade duration is 10s from when it was entered (t=2).
      controller.tick(hasSelection: true, hasActivePath: true, now: _t(13));

      expect(controller.state, GestureHintState.done);
      expect(controller.text, isNull);

      // Even much later, done stays done and produces no hint.
      controller.tick(hasSelection: true, hasActivePath: true, now: _t(60));
      expect(controller.state, GestureHintState.done);
      expect(controller.text, isNull);
    });
  });

  group('GestureHintSystem widget', () {
    testWidgets('shows nothing on any level other than Campaign 1 Level 1',
        (tester) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(campaign: 1, levelNumber: 2);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GestureHintSystem(game: game))),
      );

      expect(find.text('Tap a tower to select it'), findsNothing);
    });

    testWidgets('shows the initial hint on Campaign 1 Level 1', (tester) async {
      final game = TowerConquestGame()
        ..currentLevel = _level(campaign: 1, levelNumber: 1);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GestureHintSystem(game: game))),
      );

      expect(find.text('Tap a tower to select it'), findsOneWidget);
    });
  });
}
