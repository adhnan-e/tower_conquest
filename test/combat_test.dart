import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/units/unit.dart';

Unit _unit(String faction, {String type = 'infantry', double power = 1.0}) {
  return Unit(
    type: type,
    tier: 1,
    faction: faction,
    position: Vector2.zero(),
    size: Vector2.all(20),
    targetPosition: Vector2(0, -100),
    combatPower: power,
  );
}

Unit _infantry(String faction) => _unit(faction);

/// Heavy Soldier from balance §2.1: combat power 2.0.
Unit _heavy(String faction) =>
    _unit(faction, type: 'heavy_soldier', power: 2.0);

/// Runs two columns into each other, front unit against front unit, the way
/// they would meet travelling in opposite directions along a path.
///
/// Returns the survivors on each side.
({List<Unit> attackers, List<Unit> defenders}) _engage(
  List<Unit> attackers,
  List<Unit> defenders,
) {
  final a = [...attackers];
  final d = [...defenders];

  while (a.isNotEmpty && d.isNotEmpty) {
    a.first.clashWith(d.first);
    if (a.first.isDefeated) a.removeAt(0);
    if (d.isNotEmpty && d.first.isDefeated) d.removeAt(0);
  }

  return (attackers: a, defenders: d);
}

void main() {
  group('Balance sheet §3.1 worked examples', () {
    test('10 Infantry vs 5 Heavy Soldiers annihilates both sides', () {
      // Doc: "Both sides have equal power. All units are eliminated. 0 units
      // reach the destination."
      final result = _engage(
        List.generate(10, (_) => _infantry('player')),
        List.generate(5, (_) => _heavy('enemy')),
      );

      expect(result.attackers, isEmpty);
      expect(result.defenders, isEmpty);
    });

    test('10 Infantry vs 4 Infantry leaves 6 attackers', () {
      // Doc: "Enemy units eliminated: All 4. Player units eliminated: 4.
      // 6 Player Infantry continue toward the target."
      final result = _engage(
        List.generate(10, (_) => _infantry('player')),
        List.generate(4, (_) => _infantry('enemy')),
      );

      expect(result.attackers, hasLength(6));
      expect(result.defenders, isEmpty);
    });

    test('a Heavy Soldier survives one Infantry with power to spare', () {
      // "Takes 2 Infantry to defeat 1 Heavy" (§2.1).
      final heavy = _heavy('enemy');
      final infantry = _infantry('player');

      heavy.clashWith(infantry);

      expect(infantry.isDefeated, isTrue);
      expect(heavy.isDefeated, isFalse);
      expect(heavy.remainingPower, 1.0);
    });

    test('a wounded Heavy Soldier falls to the second Infantry', () {
      final heavy = _heavy('enemy');

      heavy.clashWith(_infantry('player'));
      heavy.clashWith(_infantry('player'));

      expect(heavy.isDefeated, isTrue);
    });
  });

  group('Clash resolution', () {
    test('equal-power units destroy each other', () {
      final a = _infantry('player');
      final b = _infantry('enemy');

      a.clashWith(b);

      expect(a.isDefeated, isTrue);
      expect(b.isDefeated, isTrue);
    });

    test('combatPower is the stat and is never consumed', () {
      final heavy = _heavy('enemy');

      heavy.clashWith(_infantry('player'));

      expect(heavy.combatPower, 2.0, reason: 'the class stat must not change');
      expect(heavy.remainingPower, 1.0);
    });

    test('resolving the same pair twice does not double-count', () {
      // Both units get onCollisionStart for one collision, so the second call
      // has to be a no-op.
      final heavy = _heavy('enemy');
      final infantry = _infantry('player');

      heavy.clashWith(infantry);
      heavy.clashWith(infantry);

      expect(heavy.remainingPower, 1.0);
    });

    test('a defeated unit cannot fight on', () {
      final spent = _infantry('player');
      final fresh = _infantry('enemy');
      spent.clashWith(_infantry('enemy'));

      spent.clashWith(fresh);

      expect(fresh.isDefeated, isFalse);
      expect(fresh.remainingPower, 1.0);
    });

    test('a Scout is worth half an Infantry', () {
      // Scout: combat power 0.5 (§2.1).
      final scout = _unit('player', type: 'scout', power: 0.5);
      final infantry = _infantry('enemy');

      scout.clashWith(infantry);

      expect(scout.isDefeated, isTrue);
      expect(infantry.remainingPower, 0.5);
    });
  });
}
