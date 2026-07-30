import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

/// End-to-end checks that the game starts, its components mount, and a send
/// runs its full course.
///
/// This suite exists because testing each component in isolation missed a real
/// failure: `SpriteComponent` asserts `sprite != null` when it mounts, so with
/// the art not yet produced the nodes silently failed to mount. Release builds
/// strip asserts, which made it look fine in a release web build while being
/// broken in debug. Only booting the whole game caught it.
/// Runs the Flame loop for [seconds] at 60 fps, the way the real game does.
void _advance(TowerConquestGame game, double seconds) {
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    game.updateTree(dt);
  }
}

void main() {
  group('Boot', () {
    testWithGame<TowerConquestGame>(
        'mounts both nodes and the route between them', TowerConquestGame.new,
        (game) async {
      expect(game.world.children.contains(game.playerBase), isTrue);
      expect(game.world.children.contains(game.enemyBase), isTrue);
      expect(game.paths, hasLength(1));
      expect(game.world.children.contains(game.paths.first), isTrue);
    });

    testWithGame<TowerConquestGame>(
        'the route joins the two nodes', TowerConquestGame.new, (game) async {
      expect(
        game.linkBetween(game.playerBase, game.enemyBase),
        same(game.paths.first),
      );
    });

    testWithGame<TowerConquestGame>(
        'nodes start with units and generate more', TowerConquestGame.new,
        (game) async {
      final before = game.playerBase.unitsInside;
      expect(before, greaterThan(0));

      _advance(game, 3.0);

      // 1.0 units/s (balance §1.1).
      expect(game.playerBase.unitsInside, before + 3);
    });
  });

  group('Sending a unit', () {
    testWithGame<TowerConquestGame>(
        'spends a unit and lights up the route', TowerConquestGame.new,
        (game) async {
      final before = game.playerBase.unitsInside;

      final unit = game.sendUnit(from: game.playerBase, to: game.enemyBase);

      expect(unit, isNotNull);
      expect(game.playerBase.unitsInside, before - 1);
      expect(game.paths.first.isActive, isTrue);
    });

    testWithGame<TowerConquestGame>(
        'the unit travels toward its target', TowerConquestGame.new,
        (game) async {
      final unit = game.sendUnit(from: game.playerBase, to: game.enemyBase)!;
      // Let the unit finish mounting before stepping the loop.
      await game.ready();
      final startDistance = unit.position.distanceTo(unit.targetPosition);

      _advance(game, 1.0);

      expect(
        unit.position.distanceTo(unit.targetPosition),
        lessThan(startDistance),
      );
    });

    testWithGame<TowerConquestGame>(
        'the route goes idle once the unit arrives', TowerConquestGame.new,
        (game) async {
      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      expect(game.paths.first.isActive, isTrue);

      // The nodes are 440 world units apart and Infantry moves at 100 px/s, so
      // 6 seconds is comfortably past arrival.
      _advance(game, 6.0);

      expect(game.paths.first.isActive, isFalse);
    });

    testWithGame<TowerConquestGame>(
        'an empty node cannot send', TowerConquestGame.new, (game) async {
      game.playerBase.takeUnits(game.playerBase.unitsInside);

      final unit = game.sendUnit(from: game.playerBase, to: game.enemyBase);

      expect(unit, isNull);
      expect(game.paths.first.isActive, isFalse);
    });
  });
}
