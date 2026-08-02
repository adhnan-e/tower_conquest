import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/balance.dart';
import 'package:tower_conquest/game/managers/level_runtime_factory.dart';
import 'package:tower_conquest/game/models/level_data.dart';

NodeData _node({
  String id = 'node',
  String type = 'barracks',
  String faction = 'player',
  int unitsInside = 10,
}) {
  return NodeData(
    id: id,
    type: type,
    faction: faction,
    position: Vector2(1, 2),
    tier: 1,
    unitsInside: unitsInside,
  );
}

void main() {
  group('LevelRuntimeFactory.buildingFor', () {
    test('carries the node\'s faction, position, tier, and garrison', () {
      final building = LevelRuntimeFactory.buildingFor(
        _node(faction: 'enemy', unitsInside: 7),
        size: Vector2.all(96),
        onTapped: null,
      );

      expect(building.faction, 'enemy');
      expect(building.position, Vector2(1, 2));
      expect(building.tier, 1);
      expect(building.unitsInside, 7);
      expect(building.size, Vector2.all(96));
    });

    test('wires the given onTapped callback', () {
      Building? tapped;
      final building = LevelRuntimeFactory.buildingFor(
        _node(),
        size: Vector2.all(96),
        onTapped: (b) => tapped = b,
      );

      building.onTapped?.call(building);

      expect(identical(tapped, building), isTrue);
    });

    for (final type in ['barracks', 'tower', 'factory', 'command_center']) {
      test('supplies $type\'s real balance stats, not Barracks defaults', () {
        final stats = BuildingBalance.baseStatsFor(type)!;
        final building = LevelRuntimeFactory.buildingFor(
          _node(type: type, unitsInside: 0),
          size: Vector2.all(96),
          onTapped: null,
        );

        expect(building.generationRate, stats.genRate);
        expect(building.maxCapacity, stats.capacity);
        expect(building.defenseMultiplier, stats.defense);
      });
    }
  });

  group('LevelRuntimeFactory.linksFor', () {
    test('resolves an authored link to the matching pair of Buildings', () {
      final a = LevelRuntimeFactory.buildingFor(
        _node(id: 'a', faction: 'player'),
        size: Vector2.all(96),
        onTapped: null,
      );
      final b = LevelRuntimeFactory.buildingFor(
        _node(id: 'b', faction: 'enemy'),
        size: Vector2.all(96),
        onTapped: null,
      );
      final level = LevelData(
        id: 'l',
        name: 'l',
        campaign: 1,
        levelNumber: 1,
        description: '',
        difficulty: 'normal',
        width: 800,
        height: 600,
        nodes: [
          _node(id: 'a', faction: 'player'),
          _node(id: 'b', faction: 'enemy'),
        ],
        links: [LinkData(from: 'a', to: 'b')],
        winCondition: 'capture_all_enemy_nodes',
        timeLimitSeconds: null,
        rewards: const LevelRewards(),
      );

      final links = LevelRuntimeFactory.linksFor(level, {'a': a, 'b': b});

      expect(links, hasLength(1));
      expect(identical(links.first.a, a), isTrue);
      expect(identical(links.first.b, b), isTrue);
    });

    test('produces no links for a level that declares none', () {
      final a = LevelRuntimeFactory.buildingFor(
        _node(id: 'a', faction: 'player'),
        size: Vector2.all(96),
        onTapped: null,
      );
      final b = LevelRuntimeFactory.buildingFor(
        _node(id: 'b', faction: 'enemy'),
        size: Vector2.all(96),
        onTapped: null,
      );
      final level = LevelData(
        id: 'l',
        name: 'l',
        campaign: 1,
        levelNumber: 1,
        description: '',
        difficulty: 'normal',
        width: 800,
        height: 600,
        nodes: [
          _node(id: 'a', faction: 'player'),
          _node(id: 'b', faction: 'enemy'),
        ],
        links: const [],
        winCondition: 'capture_all_enemy_nodes',
        timeLimitSeconds: null,
        rewards: const LevelRewards(),
      );

      expect(LevelRuntimeFactory.linksFor(level, {'a': a, 'b': b}), isEmpty);
    });
  });
}
