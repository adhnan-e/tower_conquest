import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/colors.dart';

Building _barracks({int unitsInside = 0, double generationRate = 1.0}) {
  return Building(
    type: 'barracks',
    tier: 1,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: generationRate,
  );
}

/// Advances [building] by [seconds] in 60 fps steps, i.e. the small `dt` values
/// that broke the guide's integer-truncating generator.
void _tick(Building building, double seconds) {
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    building.update(dt);
  }
}

void main() {
  group('Building unit generation', () {
    test('accumulates whole units across small frame deltas', () {
      final building = _barracks();

      _tick(building, 1.0);

      // 1.0 units/s for one second. The guide's `(rate * dt).toInt()` would
      // truncate every frame and leave this at 0.
      expect(building.unitsInside, 1);
    });

    test('is frame-rate independent over a longer run', () {
      final building = _barracks();

      _tick(building, 10.0);

      expect(building.unitsInside, 10);
    });

    test('respects the generation rate', () {
      final building = _barracks(generationRate: 0.5);

      // 11s rather than exactly 10s: at 0.5 units/s the 10s mark lands exactly
      // on a unit boundary, where accumulated float error decides whether the
      // 5th unit appears on this frame or the next. That one-frame wobble is
      // inherent to float accumulation and invisible in play, so the test
      // deliberately asserts away from the boundary.
      _tick(building, 11.0);

      expect(building.unitsInside, 5);
    });

    test('does not produce a partial unit before its time', () {
      final building = _barracks();

      _tick(building, 0.5);

      expect(building.unitsInside, 0);
    });

    test('pauses at max capacity instead of overflowing', () {
      final building = _barracks(unitsInside: 49);

      _tick(building, 30.0);

      expect(building.unitsInside, 50);
    });
  });

  group('Building.takeUnits', () {
    test('removes the requested units and reports them', () {
      final building = _barracks(unitsInside: 10);

      expect(building.takeUnits(3), 3);
      expect(building.unitsInside, 7);
    });

    test('never takes more than are available', () {
      final building = _barracks(unitsInside: 2);

      expect(building.takeUnits(5), 2);
      expect(building.unitsInside, 0);
    });

    test('returns zero from an empty building', () {
      final building = _barracks();

      expect(building.takeUnits(1), 0);
      expect(building.unitsInside, 0);
    });
  });

  group('Building.changeFaction', () {
    test('switches ownership and swaps the cached tint', () {
      final building = _barracks(unitsInside: 5);

      building.changeFaction('enemy');

      expect(building.faction, 'enemy');
      expect(building.tintPaint, same(FactionManager().getPaint('enemy')));
    });
  });
}
