import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

// End-to-end checks that the game starts, its components mount, and a match
// runs its full course.
//
// This suite exists because testing each component in isolation missed a real
// failure: `SpriteComponent` asserts `sprite != null` when it mounts, so with
// the art not yet produced the nodes silently failed to mount. Release builds
// strip asserts, which made it look fine in a release web build while being
// broken in debug. Only booting the whole game caught it.

/// Runs the Flame loop for [seconds] at 60 fps, the way the real game does.
///
/// Must go through `update`, not `updateTree`: collision detection lives in the
/// `HasCollisionDetection` mixin's `update` override, so stepping the tree
/// directly would silently skip all path combat.
void _advance(TowerConquestGame game, double seconds) {
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    game.update(dt);
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

  group('Arriving at a node', () {
    testWithGame<TowerConquestGame>(
        'a friendly unit reinforces it', TowerConquestGame.new, (game) async {
      // Hand the far node to the player so the arrival is a reinforcement, and
      // silence its generation so the only change is the unit that lands.
      game.enemyBase.changeFaction('player');
      game.enemyBase.generationRate = 0;
      final before = game.enemyBase.unitsInside;

      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 6.0);

      expect(game.enemyBase.unitsInside, before + 1);
    });

    testWithGame<TowerConquestGame>(
        'a hostile unit wears the node down', TowerConquestGame.new,
        (game) async {
      game.enemyBase.generationRate = 0;
      final before = game.enemyBase.unitsInside;

      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 6.0);

      expect(game.enemyBase.unitsInside, before - 1);
      expect(game.enemyBase.faction, 'enemy');
    });

    testWithGame<TowerConquestGame>(
        'a unit killed en route never lands a hit', TowerConquestGame.new,
        (game) async {
      game.enemyBase.generationRate = 0;
      final before = game.enemyBase.unitsInside;

      final unit = game.sendUnit(from: game.playerBase, to: game.enemyBase)!;
      await game.ready();

      // Kill it mid-flight, as path combat would.
      unit.remainingPower = 0;
      unit.onDefeated();
      _advance(game, 6.0);

      expect(game.enemyBase.unitsInside, before);
      expect(game.paths.first.isActive, isFalse,
          reason: 'a unit that dies en route must still clear its route');
    });
  });

  group('Path combat', () {
    testWithGame<TowerConquestGame>(
        'opposing units destroy each other before reaching either node',
        TowerConquestGame.new, (game) async {
      game.playerBase.generationRate = 0;
      game.enemyBase.generationRate = 0;
      final playerBefore = game.playerBase.unitsInside;
      final enemyBefore = game.enemyBase.unitsInside;

      // One each way; they meet head-on in the middle of the route.
      final attacker =
          game.sendUnit(from: game.playerBase, to: game.enemyBase)!;
      final defender =
          game.sendUnit(from: game.enemyBase, to: game.playerBase)!;
      await game.ready();

      _advance(game, 6.0);

      expect(attacker.isMounted, isFalse);
      expect(defender.isMounted, isFalse);
      expect(attacker.isDefeated, isTrue);
      expect(defender.isDefeated, isTrue);

      // Neither side landed a hit: both nodes are down only the unit they sent.
      expect(game.playerBase.unitsInside, playerBefore - 1);
      expect(game.enemyBase.unitsInside, enemyBefore - 1);
      expect(game.paths.first.isActive, isFalse);
    });

    testWithGame<TowerConquestGame>(
        'friendly units pass through each other', TowerConquestGame.new,
        (game) async {
      game.enemyBase.generationRate = 0;
      final target = game.enemyBase.unitsInside;

      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 0.5);
      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();

      _advance(game, 8.0);

      // Both arrived and hit; neither killed the other on the way.
      expect(game.enemyBase.unitsInside, target - 2);
    });
  });

  group('Match outcome', () {
    testWithGame<TowerConquestGame>(
        'capturing the last enemy node wins', TowerConquestGame.new,
        (game) async {
      game.enemyBase.takeUnits(game.enemyBase.unitsInside);
      game.enemyBase.generationRate = 0;

      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 6.0);

      expect(game.enemyBase.faction, 'player');
      expect(game.status, GameStatus.victory);
    });

    testWithGame<TowerConquestGame>(
        'losing the last player node loses', TowerConquestGame.new,
        (game) async {
      game.playerBase.takeUnits(game.playerBase.unitsInside);
      game.playerBase.generationRate = 0;

      game.sendUnit(from: game.enemyBase, to: game.playerBase);
      await game.ready();
      _advance(game, 6.0);

      expect(game.playerBase.faction, 'enemy');
      expect(game.status, GameStatus.defeat);
    });

    testWithGame<TowerConquestGame>(
        'the match starts out running', TowerConquestGame.new, (game) async {
      expect(game.status, GameStatus.playing);
      expect(game.isMatchOver, isFalse);
    });

    testWithGame<TowerConquestGame>(
        'no more sends once the match is over', TowerConquestGame.new,
        (game) async {
      game.enemyBase.takeUnits(game.enemyBase.unitsInside);
      game.enemyBase.generationRate = 0;
      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 6.0);
      expect(game.status, GameStatus.victory);

      expect(
        game.sendUnit(from: game.playerBase, to: game.enemyBase),
        isNull,
      );
    });

    testWithGame<TowerConquestGame>(
        'restart puts the match back to the start', TowerConquestGame.new,
        (game) async {
      game.enemyBase.takeUnits(game.enemyBase.unitsInside);
      game.enemyBase.generationRate = 0;
      game.sendUnit(from: game.playerBase, to: game.enemyBase);
      await game.ready();
      _advance(game, 6.0);
      expect(game.status, GameStatus.victory);

      game.restart();
      await game.ready();

      expect(game.status, GameStatus.playing);
      expect(game.nodes, hasLength(2));
      expect(game.paths, hasLength(1));
      expect(game.playerBase.faction, 'player');
      expect(game.enemyBase.faction, 'enemy');
      expect(game.enemyBase.unitsInside, 10);
      expect(game.selectedBuilding, isNull);
    });
  });

  group('The stand-in opponent', () {
    testWithGame<TowerConquestGame>(
        'attacks once its node fills up', TowerConquestGame.new, (game) async {
      final before = game.playerBase.unitsInside;
      game.enemyBase.reinforce(game.enemyBase.maxCapacity);

      // One frame is enough for the commander to act.
      _advance(game, 1 / 60);
      await game.ready();

      expect(game.paths.first.isActive, isTrue);

      _advance(game, 6.0);
      expect(game.playerBase.unitsInside, lessThan(before + 6));
    });

    testWithGame<TowerConquestGame>(
        'stays quiet while below capacity', TowerConquestGame.new,
        (game) async {
      _advance(game, 2.0);

      expect(game.paths.first.isActive, isFalse);
    });
  });
}
