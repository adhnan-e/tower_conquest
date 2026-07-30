import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/units/unit.dart';

Unit _infantry({
  required Vector2 from,
  required Vector2 to,
  double speed = 100.0,
}) {
  return Unit(
    type: 'infantry',
    tier: 1,
    faction: 'player',
    position: from,
    size: Vector2.all(20),
    targetPosition: to,
    speed: speed,
  );
}

void _tick(Unit unit, double seconds) {
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    unit.update(dt);
  }
}

void main() {
  group('Unit movement', () {
    test('travels toward the target at its speed', () {
      final unit = _infantry(from: Vector2.zero(), to: Vector2(1000, 0));

      _tick(unit, 1.0);

      // 100 px/s for one second.
      expect(unit.position.x, closeTo(100, 0.001));
      expect(unit.position.y, closeTo(0, 0.001));
    });

    test('moves diagonally without exceeding its speed', () {
      final unit = _infantry(from: Vector2.zero(), to: Vector2(1000, 1000));

      _tick(unit, 1.0);

      expect(unit.position.length, closeTo(100, 0.001));
    });

    test('lands exactly on the target and does not overshoot', () {
      final unit = _infantry(from: Vector2.zero(), to: Vector2(50, 0));

      // Long enough to arrive; the arrival check must clamp rather than sail
      // past and oscillate.
      _tick(unit, 2.0);

      expect(unit.position.x, closeTo(50, 0.001));
      expect(unit.position.y, closeTo(0, 0.001));
    });

    test('respects a slower unit class', () {
      // Heavy Soldier speed from balance §2.1.
      final unit = _infantry(
        from: Vector2.zero(),
        to: Vector2(1000, 0),
        speed: 60,
      );

      _tick(unit, 1.0);

      expect(unit.position.x, closeTo(60, 0.001));
    });

    test('moveTo redirects an in-flight unit', () {
      final unit = _infantry(from: Vector2.zero(), to: Vector2(1000, 0));

      unit.moveTo(Vector2(0, 1000));
      _tick(unit, 1.0);

      expect(unit.position.x, closeTo(0, 0.001));
      expect(unit.position.y, closeTo(100, 0.001));
    });

    test('arrival fires once even if the unit is updated again', () {
      // removeFromParent only queues the removal, so a unit sitting on its
      // target keeps being updated for a frame or two. Without a guard it would
      // "arrive" repeatedly and land its hit on the node again each time.
      final unit = _infantry(from: Vector2.zero(), to: Vector2(10, 0));
      var arrivals = 0;
      unit.onArrived = (_) => arrivals++;

      _tick(unit, 3.0);

      expect(arrivals, 1);
    });

    test('a defeated unit never arrives', () {
      final unit = _infantry(from: Vector2.zero(), to: Vector2(10, 0));
      var arrivals = 0;
      unit.onArrived = (_) => arrivals++;

      unit.remainingPower = 0;
      _tick(unit, 3.0);

      expect(arrivals, 0);
      expect(unit.position, Vector2.zero(), reason: 'it should stop moving');
    });

    test('moveTo copies the vector rather than aliasing it', () {
      final target = Vector2(1000, 0);
      final unit = _infantry(from: Vector2.zero(), to: Vector2(500, 0));

      unit.moveTo(target);
      target.setValues(0, -1000);

      expect(unit.targetPosition, Vector2(1000, 0));
    });
  });
}
