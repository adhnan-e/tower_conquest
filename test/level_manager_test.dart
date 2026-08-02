import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/managers/level_manager.dart';

void main() {
  // loadLevel reads the bundled asset via rootBundle, which needs a live
  // ServicesBinding — never initialized by plain `test()` on its own, unlike
  // `testWidgets()`. Same pattern as phase1_render_contract_test.dart.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LevelManager().reset);

  group('LevelManager.loadLevel', () {
    test('loads and parses the bundled default level asset', () async {
      final level = await LevelManager().loadLevel(LevelManager.defaultLevelId);

      expect(level.id, LevelManager.defaultLevelId);
      expect(level.nodes, hasLength(2));
      expect(level.nodes.any((n) => n.faction == 'player'), isTrue);
      expect(level.nodes.any((n) => n.faction == 'enemy'), isTrue);
      expect(level.links, hasLength(1));
    });

    test('caches the parsed level: a second load returns the same instance',
        () async {
      final first = await LevelManager().loadLevel(LevelManager.defaultLevelId);
      final second =
          await LevelManager().loadLevel(LevelManager.defaultLevelId);

      expect(identical(first, second), isTrue);
    });

    test('reset() clears the cache so the next load re-parses', () async {
      final first = await LevelManager().loadLevel(LevelManager.defaultLevelId);

      LevelManager().reset();

      final second =
          await LevelManager().loadLevel(LevelManager.defaultLevelId);

      expect(identical(first, second), isFalse);
      expect(second.id, first.id, reason: 'same content, different instance');
    });

    test('a missing level asset throws rather than silently substituting',
        () async {
      expect(
        () => LevelManager().loadLevel('does_not_exist'),
        throwsA(anything),
      );
    });
  });

  group('LevelManager.loadOrFallback', () {
    test('loads the requested level when it exists', () async {
      final level =
          await LevelManager().loadOrFallback(LevelManager.defaultLevelId);

      expect(level.id, LevelManager.defaultLevelId);
    });

    test('falls back to the safe default level when the asset is missing',
        () async {
      final level = await LevelManager().loadOrFallback('does_not_exist');

      expect(level.id, LevelManager.defaultLevelId);
      expect(level.nodes, hasLength(2));
    });
  });

  group('LevelManager.defaultLevel', () {
    test('is itself a valid, schema-passing level', () {
      final level = LevelManager().defaultLevel();

      expect(level.nodes, hasLength(2));
      expect(level.links, hasLength(1));
      expect(level.winCondition, 'capture_all_enemy_nodes');
    });

    test('matches the pre-Phase-3 hard-coded two-node Barracks match', () {
      final level = LevelManager().defaultLevel();
      final player = level.nodes.firstWhere((n) => n.faction == 'player');
      final enemy = level.nodes.firstWhere((n) => n.faction == 'enemy');

      expect(player.type, 'barracks');
      expect(player.unitsInside, 10);
      expect(player.position.y, 220);
      expect(enemy.type, 'barracks');
      expect(enemy.unitsInside, 10);
      expect(enemy.position.y, -220);
      expect(level.links.single.from, player.id);
      expect(level.links.single.to, enemy.id);
    });
  });
}
