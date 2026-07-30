import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/managers/enemy_commander.dart';

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

/// Records the sends a commander asks for.
class _Recorder {
  final sends = <({Building from, Building to})>[];

  bool call(Building from, Building to) {
    sends.add((from: from, to: to));
    from.takeUnits(1);
    return true;
  }
}

void main() {
  group('EnemyCommander', () {
    test('holds fire below capacity', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();
      final nodes = [_node('enemy', unitsInside: 49), _node('player')];

      commander.update(nodes: nodes, send: recorder.call);

      expect(recorder.sends, isEmpty);
    });

    test('attacks once its node is full', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();
      final enemy = _node('enemy', unitsInside: 50);
      final player = _node('player');

      commander.update(nodes: [enemy, player], send: recorder.call);

      expect(recorder.sends, hasLength(1));
      expect(recorder.sends.single.from, same(enemy));
      expect(recorder.sends.single.to, same(player));
    });

    test('targets the nearest node it does not own', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();
      final enemy = _node('enemy', unitsInside: 50, x: 0);
      final near = _node('player', x: 100);
      final far = _node('player', x: 900);

      commander.update(nodes: [enemy, far, near], send: recorder.call);

      expect(recorder.sends.single.to, same(near));
    });

    test('does nothing when it owns no nodes', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();

      commander.update(
        nodes: [_node('player', unitsInside: 50)],
        send: recorder.call,
      );

      expect(recorder.sends, isEmpty);
    });

    test('does nothing when there is nothing left to attack', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();

      commander.update(
        nodes: [_node('enemy', unitsInside: 50)],
        send: recorder.call,
      );

      expect(recorder.sends, isEmpty);
    });

    test('every full node it owns attacks', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();
      final nodes = [
        _node('enemy', unitsInside: 50, x: 0),
        _node('enemy', unitsInside: 50, x: 200),
        _node('player', x: 400),
      ];

      commander.update(nodes: nodes, send: recorder.call);

      expect(recorder.sends, hasLength(2));
    });

    test('the threshold is tunable', () {
      final commander = EnemyCommander(attackThreshold: 0.5);
      final recorder = _Recorder();
      final nodes = [_node('enemy', unitsInside: 25), _node('player')];

      commander.update(nodes: nodes, send: recorder.call);

      expect(recorder.sends, hasLength(1));
    });

    test('a captured node switches sides and starts attacking for it', () {
      final commander = EnemyCommander();
      final recorder = _Recorder();
      final flipped = _node('player', unitsInside: 50, x: 0);
      final target = _node('enemy', unitsInside: 10, x: 200);

      // Nothing to do while the full node belongs to the player.
      commander.update(nodes: [flipped, target], send: recorder.call);
      expect(recorder.sends, isEmpty);

      flipped.changeFaction('enemy');
      target.changeFaction('player');
      commander.update(nodes: [flipped, target], send: recorder.call);

      expect(recorder.sends, hasLength(1));
      expect(recorder.sends.single.from, same(flipped));
    });
  });
}
