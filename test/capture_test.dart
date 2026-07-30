import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';

Building _node({
  String faction = 'enemy',
  String type = 'barracks',
  int unitsInside = 0,
  int maxCapacity = 50,
  double defenseMultiplier = 1.0,
}) {
  return Building(
    type: type,
    tier: 1,
    faction: faction,
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    maxCapacity: maxCapacity,
    defenseMultiplier: defenseMultiplier,
  );
}

void main() {
  group('Defence value', () {
    test('is units inside times the multiplier', () {
      expect(_node(unitsInside: 20).defenseValue, 20);
      // A Tier 1 Tower: 1.5x (balance §1.1).
      expect(
        _node(unitsInside: 20, defenseMultiplier: 1.5).defenseValue,
        30,
      );
    });

    test('an empty node has no defence', () {
      expect(_node().defenseValue, 0);
    });
  });

  group('Balance sheet §3.2 worked example', () {
    test('10 Infantry against a Tier 1 Tower holding 20 units', () {
      // Doc: "Tower has 20 units inside (defense = 20 x 1.5 = 30). Attacking
      // units reduce defense by 10 (30 - 10 = 20). Tower is not captured."
      final tower = _node(
        type: 'tower',
        unitsInside: 20,
        defenseMultiplier: 1.5,
      );

      final captured = tower.applyAttack(10, 'player');

      expect(captured, isFalse);
      expect(tower.defenseValue, closeTo(20, 0.0001));
      expect(tower.faction, 'enemy');
    });

    test('a third wave of 10 finally takes the Tower', () {
      // Doc: "a third attack would capture it."
      final tower = _node(
        type: 'tower',
        unitsInside: 20,
        defenseMultiplier: 1.5,
      );

      expect(tower.applyAttack(10, 'player'), isFalse);
      expect(tower.applyAttack(10, 'player'), isFalse);
      expect(tower.applyAttack(10, 'player'), isTrue);
    });
  });

  group('Attacking', () {
    test('reduces the unit count one-for-one at 1.0x', () {
      final node = _node(unitsInside: 10);

      node.applyAttack(4, 'player');

      expect(node.unitsInside, 6);
    });

    test('carries fractional damage instead of dropping it', () {
      final node = _node(unitsInside: 10, defenseMultiplier: 1.5);

      // Three hits of 5 = 15 defence, exactly the node's 10 x 1.5.
      expect(node.applyAttack(5, 'player'), isFalse);
      expect(node.applyAttack(5, 'player'), isFalse);
      expect(node.applyAttack(5, 'player'), isTrue);
    });

    test('an exactly-lethal hit captures', () {
      final node = _node(unitsInside: 10);

      expect(node.applyAttack(10, 'player'), isTrue);
    });

    test('overkill captures without going negative', () {
      final node = _node(unitsInside: 3);

      expect(node.applyAttack(99, 'player'), isTrue);
      expect(node.unitsInside, 0);
    });

    test('an empty enemy node falls to a single unit', () {
      final node = _node(unitsInside: 0);

      expect(node.applyAttack(1, 'player'), isTrue);
    });

    test('a friendly attack is ignored', () {
      final node = _node(faction: 'player', unitsInside: 10);

      expect(node.applyAttack(5, 'player'), isFalse);
      expect(node.unitsInside, 10);
    });

    test('zero power does nothing', () {
      final node = _node(unitsInside: 10);

      expect(node.applyAttack(0, 'player'), isFalse);
      expect(node.unitsInside, 10);
    });
  });

  group('Capture', () {
    test('flips faction and resets to zero units', () {
      final node = _node(unitsInside: 5);

      node.applyAttack(99, 'player');

      expect(node.faction, 'player');
      expect(node.unitsInside, 0);
      expect(node.defenseValue, 0);
    });

    test('refreshes the faction tint', () {
      final node = _node(unitsInside: 5);
      final before = node.tintPaint;

      node.applyAttack(99, 'player');

      expect(node.tintPaint, isNot(same(before)));
    });

    test('generates for its new owner from a clean slate', () {
      final node = _node(unitsInside: 5);
      node.applyAttack(99, 'player');

      // Half a second must not immediately yield a unit — the previous owner's
      // partial generation has to be discarded on capture.
      for (var i = 0; i < 30; i++) {
        node.update(1 / 60);
      }
      expect(node.unitsInside, 0);

      for (var i = 0; i < 30; i++) {
        node.update(1 / 60);
      }
      expect(node.unitsInside, 1);
    });
  });

  group('Reinforcement', () {
    test('adds units and reports how many landed', () {
      final node = _node(faction: 'player', unitsInside: 10);

      expect(node.reinforce(3), 3);
      expect(node.unitsInside, 13);
    });

    test('never exceeds capacity', () {
      final node = _node(faction: 'player', unitsInside: 49);

      expect(node.reinforce(5), 1);
      expect(node.unitsInside, 50);
    });

    test('a full node turns reinforcements away', () {
      final node = _node(faction: 'player', unitsInside: 50);

      expect(node.reinforce(1), 0);
      expect(node.unitsInside, 50);
    });
  });
}
