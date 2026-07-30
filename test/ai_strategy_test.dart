import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/components/units/unit.dart';
import 'package:tower_conquest/game/managers/ai_strategy.dart';
import 'package:tower_conquest/game/managers/normal_ai_strategy.dart';

// NormalAIStrategy exposes its heuristics only through decideActions(), so
// every test here goes through that public surface rather than reaching into
// private methods — which a separate test library cannot do anyway; Dart's
// leading-underscore privacy is per-file, not per-class. (The reference
// pseudocode in orchestrator/PHASE2_DEVELOPER_PROMPT.md calls
// `strategy._allocateUnitsForAttack(...)` directly from its own test file,
// which does not compile — one more reason to test the public contract.)

Building _building(
  String faction, {
  int unitsInside = 0,
  double x = 0,
  double defenseMultiplier = 1.0,
  int maxCapacity = 50,
}) {
  return Building(
    type: 'barracks',
    tier: 1,
    faction: faction,
    position: Vector2(x, 0),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    maxCapacity: maxCapacity,
    defenseMultiplier: defenseMultiplier,
  );
}

Unit _unitHeadingTo(
  Building target, {
  required Vector2 from,
  double speed = 100,
}) {
  return Unit(
    type: 'infantry',
    tier: 1,
    faction: 'player',
    position: from,
    size: Vector2.all(20),
    targetPosition: target.position.clone(),
    speed: speed,
  );
}

AIDecisionContext _context({
  required List<Building> owned,
  List<Building> player = const [],
  List<Building> neutral = const [],
  List<Unit> hostileUnits = const [],
  double gameTime = 0,
}) {
  return AIDecisionContext(
    ownedBuildings: owned,
    playerBuildings: player,
    neutralBuildings: neutral,
    hostileUnits: hostileUnits,
    gameTime: gameTime,
  );
}

void main() {
  group('Heuristic 1: target selection', () {
    test('selects the nearest player building to attack', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 20, x: 0);
      final near = _building('player', unitsInside: 5, x: 100);
      final far = _building('player', unitsInside: 5, x: 900);

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [far, near]),
      );

      expect(actions, isNotEmpty);
      expect(actions.first.target, same(near));
    });

    test('breaks a distance tie on the lower-defence target', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 20, x: 0);
      // Both exactly 100 away; "weaker" has less defence.
      final weaker = _building('player', unitsInside: 5, x: 100);
      final stronger = _building('player', unitsInside: 5, x: -100)
        ..reinforce(20); // more units -> higher defenceValue

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [stronger, weaker]),
      );

      expect(actions.first.target, same(weaker));
    });

    test('prioritises player buildings; expansion looks at neutrals only', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 20, x: 0);
      final playerTarget = _building('player', unitsInside: 5, x: 100);
      final neutralTarget = _building('neutral', unitsInside: 0, x: 50);

      final actions = strategy.decideActions(
        _context(owned: [
          owned
        ], player: [
          playerTarget
        ], neutral: [
          neutralTarget,
        ]),
      );

      // One attack action against the player target, one expansion action
      // against the neutral — the two pools never cross.
      expect(actions, hasLength(2));
      expect(actions.any((a) => a.target == playerTarget), isTrue);
      expect(actions.any((a) => a.target == neutralTarget), isTrue);
    });

    test('no target, no action', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 20);

      final actions = strategy.decideActions(_context(owned: [owned]));

      expect(actions, isEmpty);
    });
  });

  group('Heuristic 2: unit allocation', () {
    test('sends everything at a weak target (defence < 20)', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40);
      final weak = _building('player', unitsInside: 5); // defence 5

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [weak]),
      );

      expect(actions.single.unitCount, 40);
    });

    test('sends half at a moderate target (20 <= defence < 50)', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40);
      final moderate = _building('player', unitsInside: 30); // defence 30

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [moderate]),
      );

      expect(actions.single.unitCount, 20); // 40 * 0.5
    });

    test('sends a quarter at a heavily defended target (defence >= 50)', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40);
      final strong = _building('player', unitsInside: 60); // defence 60

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [strong]),
      );

      expect(actions.single.unitCount, 10); // 40 * 0.25
    });

    test('a defence multiplier raises the target into a harder bracket', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40);
      // 15 units alone would be "weak" (defence 15); the 1.5x Tower
      // multiplier pushes it to 22.5, into the "moderate" bracket.
      final fortified = _building(
        'player',
        unitsInside: 15,
        defenseMultiplier: 1.5,
      );

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [fortified]),
      );

      expect(actions.single.unitCount, 20); // 40 * 0.5, not all 40
    });

    test('an empty owned building takes no action', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 0);
      final target = _building('player', unitsInside: 5);

      final actions = strategy.decideActions(
        _context(owned: [owned], player: [target]),
      );

      expect(actions, isEmpty);
    });
  });

  group('Heuristic 4: threat assessment', () {
    test('an owned building with no inbound units is never under threat', () {
      final strategy = NormalAIStrategy();
      // Full and eligible to upgrade, and nothing is threatening it, so the
      // upgrade should go through.
      final owned = _building('enemy', unitsInside: 40, maxCapacity: 50);

      strategy.decideActions(_context(owned: [owned], gameTime: 100));

      expect(owned.tier, 2);
    });

    test('an inbound unit under the threat threshold blocks the upgrade', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40, maxCapacity: 50);
      // 50px at 100px/s = 0.5s, well under the 2s threshold.
      final inbound = _unitHeadingTo(owned, from: Vector2(50, 0));

      strategy.decideActions(
        _context(owned: [owned], hostileUnits: [inbound], gameTime: 100),
      );

      expect(owned.tier, 1);
    });

    test('an inbound unit beyond the threat threshold does not block it', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40, maxCapacity: 50);
      // 1000px at 100px/s = 10s, well past the 2s threshold.
      final farAway = _unitHeadingTo(owned, from: Vector2(1000, 0));

      strategy.decideActions(
        _context(owned: [owned], hostileUnits: [farAway], gameTime: 100),
      );

      expect(owned.tier, 2);
    });

    test('a unit heading somewhere else is not a threat to this building', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40, maxCapacity: 50);
      final other = _building('enemy', unitsInside: 0, x: 500);
      // Close to `owned` in space, but its actual destination is `other`.
      final passingBy = _unitHeadingTo(other, from: Vector2(10, 0));

      strategy.decideActions(
        _context(
          owned: [owned, other],
          hostileUnits: [passingBy],
          gameTime: 100,
        ),
      );

      expect(owned.tier, 2);
    });
  });

  group('Heuristic 3: upgrade decision', () {
    test('upgrades a building past the 70% capacity threshold', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 40, maxCapacity: 50);

      strategy.decideActions(_context(owned: [owned], gameTime: 100));

      expect(owned.tier, 2);
    });

    test('does not upgrade below the 70% capacity threshold', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 30, maxCapacity: 50);

      strategy.decideActions(_context(owned: [owned], gameTime: 100));

      expect(owned.tier, 1);
    });

    test('does not upgrade before the cooldown has elapsed', () {
      final strategy = NormalAIStrategy();
      final first = _building('enemy', unitsInside: 40, maxCapacity: 50);

      strategy.decideActions(_context(owned: [first], gameTime: 0));
      expect(first.tier, 2, reason: 'first upgrade, no cooldown yet');

      final second = _building('enemy', unitsInside: 40, maxCapacity: 50);
      strategy.decideActions(_context(owned: [second], gameTime: 5));

      expect(second.tier, 1, reason: 'only 5s since the last upgrade');
    });

    test('upgrades again once the cooldown has elapsed', () {
      final strategy = NormalAIStrategy();
      final first = _building('enemy', unitsInside: 40, maxCapacity: 50);
      strategy.decideActions(_context(owned: [first], gameTime: 0));

      final second = _building('enemy', unitsInside: 40, maxCapacity: 50);
      strategy.decideActions(_context(owned: [second], gameTime: 25));

      expect(second.tier, 2);
    });

    test('prioritises the highest-generation-rate eligible building', () {
      final strategy = NormalAIStrategy();
      // Both eligible; factory has the base 0.5 gen rate, barracks 1.0 —
      // barracks must be the one chosen.
      final factory = Building(
        type: 'factory',
        tier: 1,
        faction: 'enemy',
        position: Vector2(0, 0),
        size: Vector2.all(96),
        unitsInside: 40,
        maxCapacity: 40,
        generationRate: 0.5,
      );
      final barracks = Building(
        type: 'barracks',
        tier: 1,
        faction: 'enemy',
        position: Vector2(200, 0),
        size: Vector2.all(96),
        unitsInside: 40,
        maxCapacity: 50,
        generationRate: 1.0,
      );

      strategy.decideActions(
        _context(owned: [factory, barracks], gameTime: 100),
      );

      expect(barracks.tier, 2);
      expect(factory.tier, 1, reason: 'only one upgrade per decision cycle');
    });

    test('never upgrades the Command Center', () {
      final strategy = NormalAIStrategy();
      final commandCenter = Building(
        type: 'command_center',
        tier: 1,
        faction: 'enemy',
        position: Vector2.zero(),
        size: Vector2.all(96),
        unitsInside: 1000,
        maxCapacity: 100,
        generationRate: 1.25,
      );

      strategy.decideActions(
        _context(owned: [commandCenter], gameTime: 100),
      );

      expect(commandCenter.tier, 1);
    });

    test('does not upgrade a building already at max tier', () {
      final strategy = NormalAIStrategy();
      final owned = _building('enemy', unitsInside: 1000, maxCapacity: 50);
      for (var i = 0; i < 4; i++) {
        owned.upgrade();
      }
      expect(owned.tier, 5);

      strategy.decideActions(_context(owned: [owned], gameTime: 1000));

      expect(owned.tier, 5); // still 5 — nothing to throw, nothing changes
    });
  });
}
