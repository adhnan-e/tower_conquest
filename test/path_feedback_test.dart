import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/components/map/path_feedback_layer.dart';
import 'package:tower_conquest/game/components/map/path_link.dart';

Building _building(String faction, double x) => Building(
      type: 'barracks',
      tier: 1,
      faction: faction,
      position: Vector2(x, 0),
      size: Vector2.all(96),
    );

void main() {
  late Building a;
  late Building b;
  late PathLink path;
  late PathFeedbackLayer layer;

  setUp(() {
    a = _building('player', 0);
    b = _building('enemy', 300);
    path = PathLink(a: a, b: b);
    layer = PathFeedbackLayer([path]);
  });

  test('no flash before anything happens on the route', () {
    layer.update(0.016);

    expect(layer.hasActiveFlash(path), isFalse);
  });

  test('a route going idle-to-active triggers a creation flash', () {
    path.beginFlow(a);

    layer.update(0.016);

    expect(layer.hasActiveFlash(path), isTrue);
  });

  test('the creation flash clears itself after its 0.3s duration', () {
    path.beginFlow(a);
    layer.update(0.016);
    expect(layer.hasActiveFlash(path), isTrue);

    layer.update(0.3);

    expect(layer.hasActiveFlash(path), isFalse);
  });

  test('a route going active-to-idle triggers a severance flash', () {
    path.beginFlow(a);
    layer.update(0.016);
    // Let the creation flash itself expire before severing, so the two
    // effects are observed independently rather than one masking the other.
    layer.update(0.3);
    expect(layer.hasActiveFlash(path), isFalse);

    path.endFlow(a);
    layer.update(0.016);

    expect(layer.hasActiveFlash(path), isTrue);
  });

  test('the severance flash clears itself after its 0.2s duration', () {
    path.beginFlow(a);
    layer.update(0.016);
    layer.update(0.3);
    path.endFlow(a);
    layer.update(0.016);
    expect(layer.hasActiveFlash(path), isTrue);

    layer.update(0.2);

    expect(layer.hasActiveFlash(path), isFalse);
  });

  test('does not flash again while flow continues uninterrupted', () {
    path.beginFlow(a);
    layer.update(0.016);
    layer.update(0.3);
    expect(layer.hasActiveFlash(path), isFalse);

    // A second unit setting out on the same already-active route is not a
    // new creation — isActive was already true.
    path.beginFlow(a);
    layer.update(0.016);

    expect(layer.hasActiveFlash(path), isFalse);
  });
}
