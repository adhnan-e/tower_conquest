import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/components/units/unit.dart';
import 'package:tower_conquest/game/managers/ai_strategy.dart';
import 'package:tower_conquest/game/managers/enemy_commander.dart';
import 'package:tower_conquest/game/managers/normal_ai_strategy.dart';

// EnemyCommander is now a thin harness around an injected AIStrategy — see
// ai_strategy_test.dart for NormalAIStrategy's own heuristics. This file
// tests only what the harness itself is responsible for: building the board
// snapshot, calling the strategy, and executing whatever actions come back.

Building _node(String faction, {int unitsInside = 0, double x = 0}) {
  return Building(
    type: 'barracks',
    tier: 1,
    faction: faction,
    position: Vector2(x, 0),
    size: Vector2.all(96),
    unitsInside: unitsInside,
  );
}

/// Records the sends the commander asks for and always succeeds, unless
/// [failAfter] sends have already happened.
class _Recorder {
  final sends = <({Building from, Building to})>[];
  int? failAfter;

  bool call(Building from, Building to) {
    if (failAfter != null && sends.length >= failAfter!) return false;
    sends.add((from: from, to: to));
    from.takeUnits(1);
    return true;
  }
}

/// A strategy double that returns whatever actions the test hands it and
/// records the context it was called with, so the harness's plumbing can be
/// checked independently of any real heuristic.
class _FakeStrategy implements AIStrategy {
  List<AIAction> actionsToReturn = [];
  AIDecisionContext? lastContext;
  var callCount = 0;

  @override
  List<AIAction> decideActions(AIDecisionContext context) {
    lastContext = context;
    callCount++;
    return actionsToReturn;
  }
}

void main() {
  group('EnemyCommander board snapshot', () {
    test('does nothing when it owns no nodes, without calling the strategy',
        () {
      final strategy = _FakeStrategy();
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      commander.update(
        nodes: [_node('player', unitsInside: 50)],
        gameTime: 0,
        send: recorder.call,
      );

      expect(strategy.callCount, 0);
      expect(recorder.sends, isEmpty);
    });

    test('partitions nodes into owned, player, and neutral', () {
      final strategy = _FakeStrategy();
      final commander = EnemyCommander(strategy: strategy);
      final owned = _node('enemy', x: 0);
      final playerNode = _node('player', x: 100);
      final neutralNode = _node('neutral', x: 200);

      commander.update(
        nodes: [owned, playerNode, neutralNode],
        gameTime: 0,
        send: (_, __) => true,
      );

      final context = strategy.lastContext!;
      expect(context.ownedBuildings, [owned]);
      expect(context.playerBuildings, [playerNode]);
      expect(context.neutralBuildings, [neutralNode]);
    });

    test('passes gameTime straight through to the strategy', () {
      final strategy = _FakeStrategy();
      final commander = EnemyCommander(strategy: strategy);

      commander.update(
        nodes: [_node('enemy', unitsInside: 1)],
        gameTime: 42.5,
        send: (_, __) => true,
      );

      expect(strategy.lastContext!.gameTime, 42.5);
    });

    test('passes hostileUnits straight through, defaulting to empty', () {
      final strategy = _FakeStrategy();
      final commander = EnemyCommander(strategy: strategy);
      final unit = Unit(
        type: 'infantry',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(20),
        targetPosition: Vector2.zero(),
      );

      commander.update(
        nodes: [_node('enemy', unitsInside: 1)],
        gameTime: 0,
        hostileUnits: [unit],
        send: (_, __) => true,
      );
      expect(strategy.lastContext!.hostileUnits, [unit]);

      commander.update(
        nodes: [_node('enemy', unitsInside: 1)],
        gameTime: 0,
        send: (_, __) => true,
      );
      expect(strategy.lastContext!.hostileUnits, isEmpty);
    });
  });

  group('EnemyCommander action execution', () {
    // Dispatch is paced (see the class doc for why), so a multi-unit action
    // plays out across several `update()` calls, not all at once within one.
    // 0.2s comfortably clears the internal dispatch interval every time.
    const tick = 0.2;

    test('calls send once per unit in the action, one per update() call', () {
      final source = _node('enemy', unitsInside: 10);
      final target = _node('player');
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: source, target: target, unitCount: 3),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      for (var call = 0; call < 3; call++) {
        commander.update(
          nodes: [source, target],
          gameTime: call * tick,
          send: recorder.call,
        );
      }

      expect(recorder.sends, hasLength(3));
      expect(recorder.sends.every((s) => s.from == source && s.to == target),
          isTrue);
    });

    test('a single update() call never sends more than one unit', () {
      final source = _node('enemy', unitsInside: 10);
      final target = _node('player');
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: source, target: target, unitCount: 5),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      commander
          .update(nodes: [source, target], gameTime: 0, send: recorder.call);

      expect(recorder.sends, hasLength(1));
    });

    test('an action with zero units sends nothing', () {
      final source = _node('enemy', unitsInside: 10);
      final target = _node('player');
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: source, target: target, unitCount: 0),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      commander.update(
        nodes: [source, target],
        gameTime: 0,
        send: recorder.call,
      );

      expect(recorder.sends, isEmpty);
    });

    test('executes multiple actions in order across several update() calls',
        () {
      final a = _node('enemy', unitsInside: 10, x: 0);
      final b = _node('enemy', unitsInside: 10, x: 100);
      final target = _node('player', x: 200);
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: a, target: target, unitCount: 1),
          AIAction(source: b, target: target, unitCount: 2),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      for (var call = 0; call < 3; call++) {
        commander.update(
          nodes: [a, b, target],
          gameTime: call * tick,
          send: recorder.call,
        );
      }

      expect(recorder.sends, hasLength(3));
      expect(recorder.sends[0].from, a);
      expect(recorder.sends[1].from, b);
      expect(recorder.sends[2].from, b);
    });

    test('does not dispatch again before the pacing interval has elapsed', () {
      final source = _node('enemy', unitsInside: 10);
      final target = _node('player');
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: source, target: target, unitCount: 5),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder();

      commander
          .update(nodes: [source, target], gameTime: 0, send: recorder.call);
      // Barely any time has passed -- must not dispatch a second unit yet.
      commander.update(
        nodes: [source, target],
        gameTime: 0.001,
        send: recorder.call,
      );

      expect(recorder.sends, hasLength(1));
    });

    test('drops queued sends once they start failing, one attempt per call',
        () {
      final source = _node('enemy', unitsInside: 10);
      final target = _node('player');
      final strategy = _FakeStrategy()
        ..actionsToReturn = [
          AIAction(source: source, target: target, unitCount: 5),
        ];
      final commander = EnemyCommander(strategy: strategy);
      final recorder = _Recorder()..failAfter = 2;

      for (var call = 0; call < 5; call++) {
        commander.update(
          nodes: [source, target],
          gameTime: call * tick,
          send: recorder.call,
        );
      }

      expect(recorder.sends, hasLength(2));
    });
  });

  group('EnemyCommander construction', () {
    test('defaults to NormalAIStrategy', () {
      expect(EnemyCommander().strategy, isA<NormalAIStrategy>());
    });

    test('defaults to the enemy faction', () {
      expect(EnemyCommander().faction, 'enemy');
    });

    test('a custom faction only ever finds itself among matching nodes', () {
      final strategy = _FakeStrategy();
      final commander = EnemyCommander(faction: 'ally1', strategy: strategy);

      commander.update(
        nodes: [_node('enemy', unitsInside: 50), _node('player')],
        gameTime: 0,
        send: (_, __) => true,
      );

      expect(strategy.callCount, 0); // no 'ally1' nodes to own
    });
  });
}
