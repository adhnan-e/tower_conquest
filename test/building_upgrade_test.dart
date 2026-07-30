import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/balance.dart';

Building _barracks({int unitsInside = 0}) {
  return Building(
    type: 'barracks',
    tier: 1,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: 1.0,
    maxCapacity: 50,
    defenseMultiplier: 1.0,
  );
}

Building _tower({int unitsInside = 0}) {
  return Building(
    type: 'tower',
    tier: 1,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: 0.67,
    maxCapacity: 30,
    defenseMultiplier: 1.5,
  );
}

Building _commandCenter({int unitsInside = 0}) {
  return Building(
    type: 'command_center',
    tier: 1,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: 1.25,
    maxCapacity: 100,
    defenseMultiplier: 2.0,
  );
}

void main() {
  group('BuildingBalance tier progression table (balance §1.2)', () {
    test('upgrade cost per tier', () {
      expect(BuildingBalance.upgradeCostForTier(1), 0);
      expect(BuildingBalance.upgradeCostForTier(2), 20);
      expect(BuildingBalance.upgradeCostForTier(3), 40);
      expect(BuildingBalance.upgradeCostForTier(4), 70);
      expect(BuildingBalance.upgradeCostForTier(5), 100);
    });

    test('capacity bonus per tier', () {
      expect(BuildingBalance.capacityBonusForTier(1), 0);
      expect(BuildingBalance.capacityBonusForTier(2), 10);
      expect(BuildingBalance.capacityBonusForTier(3), 25);
      expect(BuildingBalance.capacityBonusForTier(4), 45);
      expect(BuildingBalance.capacityBonusForTier(5), 70);
    });

    test('generation rate multiplier per tier', () {
      expect(BuildingBalance.genRateMultiplierForTier(1), 1.0);
      expect(BuildingBalance.genRateMultiplierForTier(2), 1.10);
      expect(BuildingBalance.genRateMultiplierForTier(3), 1.25);
      expect(BuildingBalance.genRateMultiplierForTier(4), 1.40);
      expect(BuildingBalance.genRateMultiplierForTier(5), 1.60);
    });

    test('defence multiplier bonus per tier', () {
      expect(BuildingBalance.defenseMultiplierBonusForTier(1), 1.0);
      expect(BuildingBalance.defenseMultiplierBonusForTier(2), 1.10);
      expect(BuildingBalance.defenseMultiplierBonusForTier(3), 1.25);
      expect(BuildingBalance.defenseMultiplierBonusForTier(4), 1.40);
      expect(BuildingBalance.defenseMultiplierBonusForTier(5), 1.60);
    });

    test('an out-of-range tier degrades to the Tier 1 identity values', () {
      expect(BuildingBalance.upgradeCostForTier(0), 0);
      expect(BuildingBalance.upgradeCostForTier(6), 0);
      expect(BuildingBalance.capacityBonusForTier(99), 0);
      expect(BuildingBalance.genRateMultiplierForTier(99), 1.0);
      expect(BuildingBalance.defenseMultiplierBonusForTier(99), 1.0);
    });

    test('base stats per building type (balance §1.1)', () {
      expect(
        BuildingBalance.baseStatsFor('barracks'),
        (capacity: 50, genRate: 1.0, defense: 1.0, upgradeable: true),
      );
      expect(
        BuildingBalance.baseStatsFor('tower'),
        (capacity: 30, genRate: 0.67, defense: 1.5, upgradeable: true),
      );
      expect(
        BuildingBalance.baseStatsFor('factory'),
        (capacity: 40, genRate: 0.5, defense: 1.2, upgradeable: true),
      );
      expect(
        BuildingBalance.baseStatsFor('command_center'),
        (capacity: 100, genRate: 1.25, defense: 2.0, upgradeable: false),
      );
    });

    test('an unknown building type has no base stats', () {
      expect(BuildingBalance.baseStatsFor('castle'), isNull);
    });

    test('isUpgradeable reflects each type, false for unknown types', () {
      expect(BuildingBalance.isUpgradeable('barracks'), isTrue);
      expect(BuildingBalance.isUpgradeable('tower'), isTrue);
      expect(BuildingBalance.isUpgradeable('factory'), isTrue);
      expect(BuildingBalance.isUpgradeable('command_center'), isFalse);
      expect(BuildingBalance.isUpgradeable('castle'), isFalse);
    });
  });

  group('Building.upgradeCost', () {
    test('is the Tier 2 cost at Tier 1', () {
      expect(_barracks().upgradeCost, 20);
    });

    test('tracks the tier as the building climbs', () {
      final building = _barracks(unitsInside: 20)..upgrade();
      expect(building.tier, 2);
      expect(building.upgradeCost, 40); // cost to reach Tier 3
    });

    test('is zero at max tier', () {
      final building = _barracks(unitsInside: 1000);
      for (var i = 0; i < 4; i++) {
        building.upgrade();
      }
      expect(building.tier, 5);
      expect(building.upgradeCost, 0);
    });

    test('is zero for a non-upgradeable type regardless of units', () {
      expect(_commandCenter(unitsInside: 1000).upgradeCost, 0);
    });
  });

  group('Building.canUpgrade', () {
    test('false with fewer units than the cost', () {
      expect(_barracks(unitsInside: 10).canUpgrade(), isFalse);
    });

    test('true with exactly enough units', () {
      expect(_barracks(unitsInside: 20).canUpgrade(), isTrue);
    });

    test('true with more than enough units', () {
      expect(_barracks(unitsInside: 50).canUpgrade(), isTrue);
    });

    test('false at max tier no matter how many units', () {
      final building = _barracks(unitsInside: 1000);
      for (var i = 0; i < 4; i++) {
        building.upgrade();
      }
      expect(building.canUpgrade(), isFalse);
    });

    test('false for the Command Center no matter how many units', () {
      expect(_commandCenter(unitsInside: 1000).canUpgrade(), isFalse);
    });
  });

  group('Building.upgrade', () {
    test('does nothing and reports false when it cannot upgrade', () {
      final building = _barracks(unitsInside: 5);

      expect(building.upgrade(), isFalse);
      expect(building.tier, 1);
      expect(building.unitsInside, 5);
    });

    test('deducts the cost from unitsInside', () {
      final building = _barracks(unitsInside: 50);

      expect(building.upgrade(), isTrue);
      expect(building.unitsInside, 30); // 50 - 20
    });

    test('increments tier by exactly one', () {
      final building = _barracks(unitsInside: 20)..upgrade();
      expect(building.tier, 2);
    });

    test('the worked example from the implementation plan', () {
      // Tier 1 Barracks (capacity 50, gen 1.0, defense 1.0x) -> Tier 2:
      // costs 20, capacity 60, gen 1.1, defense 1.1x.
      final building = _barracks(unitsInside: 50);

      building.upgrade();

      expect(building.unitsInside, 30);
      expect(building.maxCapacity, 60);
      expect(building.generationRate, closeTo(1.1, 1e-9));
      expect(building.defenseMultiplier, closeTo(1.1, 1e-9));
    });

    test('cannot upgrade past Tier 5', () {
      final building = _barracks(unitsInside: 1000);

      for (var i = 0; i < 4; i++) {
        expect(building.upgrade(), isTrue);
      }
      expect(building.tier, 5);
      expect(building.upgrade(), isFalse);
      expect(building.tier, 5);
    });

    test('the Command Center never upgrades', () {
      final building = _commandCenter(unitsInside: 1000);

      expect(building.upgrade(), isFalse);
      expect(building.tier, 1);
      expect(building.maxCapacity, 100);
    });

    test(
        'stats recalculate from the Tier 1 base, not compounded from the '
        'previous tier', () {
      // Reproduces the exact bug the plan's own first-draft upgrade() has:
      // `generationRate *= genRateMultiplierForTier(tier)` compounds each
      // tier's *cumulative* multiplier onto the last, over-applying every
      // earlier tier's bonus. If that bug were present, Tier 3's rate would
      // be 1.0 * 1.10 * 1.25 = 1.375 instead of the correct 1.0 * 1.25 = 1.25.
      final building = _barracks(unitsInside: 1000)
        ..upgrade() // Tier 2
        ..upgrade(); // Tier 3

      expect(building.tier, 3);
      expect(building.generationRate, closeTo(1.25, 1e-9));
      expect(building.defenseMultiplier, closeTo(1.25, 1e-9));
      expect(building.maxCapacity, 75); // 50 + 25, not 50 + 10 + 25
    });

    test('every tier for every upgradeable type matches the balance table', () {
      final expected = {
        2: (capacity: 10, genRate: 1.10, defense: 1.10),
        3: (capacity: 25, genRate: 1.25, defense: 1.25),
        4: (capacity: 45, genRate: 1.40, defense: 1.40),
        5: (capacity: 70, genRate: 1.60, defense: 1.60),
      };

      for (final build in [_barracks, _tower, _commandCenter]) {
        final building = build(unitsInside: 1000);
        final base = (
          capacity: building.maxCapacity,
          genRate: building.generationRate,
          defense: building.defenseMultiplier,
        );

        if (!building.canUpgrade()) {
          continue; // Command Center: nothing to check
        }

        for (var tier = 2; tier <= 5; tier++) {
          building.upgrade();
          final bonus = expected[tier]!;
          expect(building.maxCapacity, base.capacity + bonus.capacity,
              reason: '${building.type} tier $tier capacity');
          expect(
            building.generationRate,
            closeTo(base.genRate * bonus.genRate, 1e-9),
            reason: '${building.type} tier $tier gen rate',
          );
          expect(
            building.defenseMultiplier,
            closeTo(base.defense * bonus.defense, 1e-9),
            reason: '${building.type} tier $tier defence',
          );
        }
      }
    });

    test('a spent upgrade can be reversed only by playing on, not undone', () {
      // No undo mechanic exists or is planned; this just documents that the
      // spent units are gone even if the very next call fails.
      final building = _barracks(unitsInside: 20);
      building.upgrade();
      final before = building.unitsInside;

      expect(building.upgrade(), isFalse); // needs 40, only has `before`
      expect(building.unitsInside, before);
    });
  });

  group('Upgrading interacts correctly with combat and capture', () {
    test('a higher tier raises defenceValue for the same unit count', () {
      // Isolates the multiplier's effect from the upgrade cost itself: paying
      // for the upgrade spends the very units providing defence, so
      // defenceValue right after an upgrade is usually *lower*, not higher —
      // "spend units now for long-term advantage... leaves it vulnerable"
      // (GDD §4.1). That is intentional, not a bug; this test holds the unit
      // count fixed to check the multiplier in isolation.
      final building = _barracks(unitsInside: 20);
      final before = building.defenseValue;

      building.upgrade();
      building.unitsInside = 20;

      expect(building.defenseValue, greaterThan(before));
    });

    test('upgrading trades defence for growth when it spends the garrison', () {
      final building = _barracks(unitsInside: 20);
      final before = building.defenseValue;

      building.upgrade(); // spends all 20 units on the Tier 2 upgrade cost

      expect(building.defenseValue, lessThan(before));
    });

    test('capture resets tier-scaled stats back to a fresh Tier 1 building',
        () {
      // Capture already resets unitsInside and the generation accumulator
      // (see Building._capture); it does NOT reset tier — a captured Tier 3
      // Tower stays a Tier 3 Tower under its new owner, matching "capacity,
      // generation rate... reset to 0 units and begins generating for the new
      // owner" (balance §3.2), which says nothing about rank being lost.
      final building = _barracks(unitsInside: 1000)..upgrade(); // Tier 2
      final tierBeforeCapture = building.tier;
      final capacityBeforeCapture = building.maxCapacity;

      building.applyAttack(9999, 'enemy');

      expect(building.faction, 'enemy');
      expect(building.unitsInside, 0);
      expect(building.tier, tierBeforeCapture);
      expect(building.maxCapacity, capacityBeforeCapture);
    });
  });
}
