import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/models/level_data.dart';

/// A valid two-node level as a raw JSON map, mutated per test to exercise one
/// validation rule at a time. Mirrors the canonical schema from
/// `orchestrator/PHASE3_DEVELOPER_PROMPT.md` §4.
Map<String, dynamic> _validLevelJson() => {
      'id': 'campaign_1_level_1',
      'name': 'First Contact',
      'campaign': 1,
      'levelNumber': 1,
      'description': 'A simple two-node match.',
      'difficulty': 'normal',
      'width': 800,
      'height': 600,
      'nodes': [
        {
          'id': 'player_base',
          'type': 'barracks',
          'faction': 'player',
          'position': {'x': 0, 'y': 220},
          'tier': 1,
          'unitsInside': 10,
        },
        {
          'id': 'enemy_base',
          'type': 'barracks',
          'faction': 'enemy',
          'position': {'x': 0, 'y': -220},
          'tier': 1,
          'unitsInside': 10,
        },
      ],
      'links': [
        {'from': 'player_base', 'to': 'enemy_base'},
      ],
      'winCondition': 'capture_all_enemy_nodes',
      'timeLimitSeconds': null,
      'rewards': {'gold': 100, 'gems': 5, 'experience': 50},
    };

void main() {
  group('LevelData.fromJson parsing', () {
    test('a valid two-node level parses to immutable typed data', () {
      final level = LevelData.fromJson(_validLevelJson());

      expect(level.id, 'campaign_1_level_1');
      expect(level.name, 'First Contact');
      expect(level.campaign, 1);
      expect(level.levelNumber, 1);
      expect(level.difficulty, 'normal');
      expect(level.width, 800);
      expect(level.height, 600);
      expect(level.nodes, hasLength(2));
      expect(level.links, hasLength(1));
      expect(level.winCondition, 'capture_all_enemy_nodes');
      expect(level.timeLimitSeconds, isNull);
      expect(level.rewards.gold, 100);
      expect(level.rewards.gems, 5);
      expect(level.rewards.experience, 50);

      expect(() => level.nodes.add(level.nodes.first), throwsUnsupportedError,
          reason: 'nodes must be immutable once parsed');
      expect(() => level.links.add(level.links.first), throwsUnsupportedError,
          reason: 'links must be immutable once parsed');
    });

    test(
        'a node carries its authored id, type, faction, position, and '
        'garrison', () {
      final level = LevelData.fromJson(_validLevelJson());
      final playerNode = level.nodes.firstWhere((n) => n.id == 'player_base');

      expect(playerNode.type, 'barracks');
      expect(playerNode.faction, 'player');
      expect(playerNode.position.x, 0);
      expect(playerNode.position.y, 220);
      expect(playerNode.tier, 1);
      expect(playerNode.unitsInside, 10);
    });

    test('rewards default to zero when omitted', () {
      final json = _validLevelJson()..remove('rewards');
      final level = LevelData.fromJson(json);

      expect(level.rewards.gold, 0);
      expect(level.rewards.gems, 0);
      expect(level.rewards.experience, 0);
    });

    test('links default to empty when omitted', () {
      final json = _validLevelJson()..remove('links');
      final level = LevelData.fromJson(json);

      expect(level.links, isEmpty);
    });

    test('a positive timeLimitSeconds parses through unchanged', () {
      final json = _validLevelJson()..['timeLimitSeconds'] = 120;
      final level = LevelData.fromJson(json);

      expect(level.timeLimitSeconds, 120);
    });
  });

  group('Top-level field validation', () {
    test('an empty id is rejected', () {
      final json = _validLevelJson()..['id'] = '';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('an empty name is rejected', () {
      final json = _validLevelJson()..['name'] = '';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a non-positive campaign is rejected', () {
      final json = _validLevelJson()..['campaign'] = 0;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a non-positive levelNumber is rejected', () {
      final json = _validLevelJson()..['levelNumber'] = -1;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('an unknown difficulty is rejected', () {
      final json = _validLevelJson()..['difficulty'] = 'nightmare';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('easy and hard are both accepted difficulties', () {
      expect(
        LevelData.fromJson(_validLevelJson()..['difficulty'] = 'easy')
            .difficulty,
        'easy',
      );
      expect(
        LevelData.fromJson(_validLevelJson()..['difficulty'] = 'hard')
            .difficulty,
        'hard',
      );
    });

    test('a non-positive width is rejected', () {
      final json = _validLevelJson()..['width'] = 0;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a non-positive height is rejected', () {
      final json = _validLevelJson()..['height'] = -100;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('an unsupported winCondition is rejected', () {
      final json = _validLevelJson()..['winCondition'] = 'survive_5_minutes';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a zero or negative timeLimitSeconds is rejected', () {
      final json = _validLevelJson()..['timeLimitSeconds'] = 0;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });
  });

  group('Node validation', () {
    test('an empty nodes list is rejected', () {
      final json = _validLevelJson()..['nodes'] = <dynamic>[];
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('duplicate node ids are rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[1]['id'] = 'player_base';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('an unknown building type is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['type'] = 'castle';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('every Phase 1 building type is accepted', () {
      for (final type in ['barracks', 'tower', 'factory', 'command_center']) {
        final json = _validLevelJson();
        (json['nodes'] as List)[0]['type'] = type;
        // Keep the garrison within whatever this type's capacity is.
        (json['nodes'] as List)[0]['unitsInside'] = 0;
        expect(
          LevelData.fromJson(json).nodes.first.type,
          type,
          reason: type,
        );
      }
    });

    test('an unknown faction is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['faction'] = 'rebel';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a neutral faction node is accepted alongside player and enemy', () {
      final json = _validLevelJson();
      (json['nodes'] as List).add({
        'id': 'neutral_outpost',
        'type': 'tower',
        'faction': 'neutral',
        'position': {'x': 100, 'y': 0},
        'tier': 1,
        'unitsInside': 0,
      });
      final level = LevelData.fromJson(json);
      expect(level.nodes, hasLength(3));
    });

    test('missing a player node is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['faction'] = 'neutral';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('missing an enemy node is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[1]['faction'] = 'neutral';
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a position outside the declared map bounds is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['position'] = {'x': 0, 'y': 1000};
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a position exactly on the map boundary is accepted', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['position'] = {'x': 400, 'y': 300};
      expect(() => LevelData.fromJson(json), returnsNormally);
    });

    test('a non-Tier-1 node is rejected in Stage 1', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['tier'] = 2;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('negative unitsInside is rejected', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['unitsInside'] = -5;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('unitsInside beyond the type\'s Tier 1 capacity is rejected', () {
      final json = _validLevelJson();
      // Barracks Tier 1 capacity is 50 (balance §1.1).
      (json['nodes'] as List)[0]['unitsInside'] = 51;
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('unitsInside exactly at capacity is accepted', () {
      final json = _validLevelJson();
      (json['nodes'] as List)[0]['unitsInside'] = 50;
      expect(() => LevelData.fromJson(json), returnsNormally);
    });
  });

  group('Link validation', () {
    test('a link referencing an unknown node is rejected', () {
      final json = _validLevelJson();
      (json['links'] as List)[0] = {'from': 'player_base', 'to': 'nowhere'};
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a self-link is rejected', () {
      final json = _validLevelJson();
      (json['links'] as List)[0] = {
        'from': 'player_base',
        'to': 'player_base',
      };
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a duplicate link in the same order is rejected', () {
      final json = _validLevelJson();
      (json['links'] as List).add({'from': 'player_base', 'to': 'enemy_base'});
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });

    test('a duplicate link in reverse order is rejected', () {
      final json = _validLevelJson();
      (json['links'] as List).add({'from': 'enemy_base', 'to': 'player_base'});
      expect(() => LevelData.fromJson(json),
          throwsA(isA<LevelValidationException>()));
    });
  });

  group('The LevelData.new factory', () {
    test('validates directly-constructed levels the same way fromJson does',
        () {
      expect(
        () => LevelData(
          id: '',
          name: 'Broken',
          campaign: 1,
          levelNumber: 1,
          description: '',
          difficulty: 'normal',
          width: 800,
          height: 600,
          nodes: [
            NodeData(
              id: 'a',
              type: 'barracks',
              faction: 'player',
              position: Vector2(0, 0),
              tier: 1,
              unitsInside: 0,
            ),
          ],
          links: const [],
          winCondition: 'capture_all_enemy_nodes',
          timeLimitSeconds: null,
          rewards: const LevelRewards(),
        ),
        throwsA(isA<LevelValidationException>()),
      );
    });
  });
}
