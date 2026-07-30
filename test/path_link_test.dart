import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/components/map/path_link.dart';

const _canvas = 200;

Building _node(String faction, Vector2 position) {
  return Building(
    type: 'barracks',
    tier: 1,
    faction: faction,
    position: position,
    size: Vector2.all(40),
  );
}

/// Two nodes far enough apart to leave a visible band between them.
({Building a, Building b, PathLink link}) _route() {
  final a = _node('player', Vector2(100, 180));
  final b = _node('enemy', Vector2(100, 20));
  return (a: a, b: b, link: PathLink(a: a, b: b));
}

Future<Uint8List> _render(PathLink link) async {
  final recorder = ui.PictureRecorder();
  link.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_canvas, _canvas);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

int _opaquePixels(Uint8List bytes) {
  var count = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) count++;
  }
  return count;
}

int _diffCount(Uint8List a, Uint8List b) {
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) diff++;
  }
  return diff;
}

void main() {
  group('PathLink rendering', () {
    test('draws a band between the two nodes', () async {
      final route = _route();

      expect(_opaquePixels(await _render(route.link)), greaterThan(0));
    });

    test('renders beneath the nodes', () {
      final route = _route();

      expect(route.link.priority, lessThan(0));
    });

    test('draws nothing when the nodes sit on top of each other', () async {
      final a = _node('player', Vector2(100, 100));
      final b = _node('enemy', Vector2(100, 100));

      expect(_opaquePixels(await _render(PathLink(a: a, b: b))), 0);
    });

    test('highlighting changes how the route is drawn', () async {
      final route = _route();
      final idle = await _render(route.link);

      route.link.isHighlighted = true;
      final highlighted = await _render(route.link);

      expect(_diffCount(idle, highlighted), greaterThan(0));
    });

    test('an active route is drawn in the flowing faction colour', () async {
      final route = _route();
      final idle = await _render(route.link);

      route.link.beginFlow(route.a);
      final active = await _render(route.link);

      expect(_diffCount(idle, active), greaterThan(0));
    });

    test('the route takes the colour of whichever end is sending', () async {
      final route = _route();

      route.link.beginFlow(route.a); // player end
      final fromPlayer = await _render(route.link);
      route.link.endFlow(route.a);

      route.link.beginFlow(route.b); // enemy end
      final fromEnemy = await _render(route.link);

      expect(_diffCount(fromPlayer, fromEnemy), greaterThan(0));
    });
  });

  group('PathLink flow tracking', () {
    test('is idle until a unit sets out', () {
      final route = _route();

      expect(route.link.isActive, isFalse);
    });

    test('becomes active while a unit is travelling', () {
      final route = _route();

      route.link.beginFlow(route.a);
      expect(route.link.isActive, isTrue);

      route.link.endFlow(route.a);
      expect(route.link.isActive, isFalse);
    });

    test('tracks the two directions separately', () {
      final route = _route();

      route.link.beginFlow(route.a);
      route.link.beginFlow(route.b);
      expect(route.link.isActive, isTrue);

      // Clearing one direction must not clear the other.
      route.link.endFlow(route.a);
      expect(route.link.isActive, isTrue);

      route.link.endFlow(route.b);
      expect(route.link.isActive, isFalse);
    });

    test('never drops below idle on an unbalanced end', () {
      final route = _route();

      route.link.endFlow(route.a);
      route.link.endFlow(route.a);
      route.link.beginFlow(route.a);

      expect(route.link.isActive, isTrue);

      route.link.endFlow(route.a);
      expect(route.link.isActive, isFalse);
    });

    test('ignores a node that is not an endpoint', () {
      final route = _route();
      final stranger = _node('player', Vector2(500, 500));

      route.link.beginFlow(stranger);

      expect(route.link.isActive, isFalse);
    });
  });

  group('PathLink topology', () {
    test('connects its endpoints in either order', () {
      final route = _route();

      expect(route.link.connects(route.a, route.b), isTrue);
      expect(route.link.connects(route.b, route.a), isTrue);
    });

    test('does not connect an unrelated node', () {
      final route = _route();
      final stranger = _node('player', Vector2(500, 500));

      expect(route.link.connects(route.a, stranger), isFalse);
    });

    test('reports which nodes it touches', () {
      final route = _route();
      final stranger = _node('player', Vector2(500, 500));

      expect(route.link.touches(route.a), isTrue);
      expect(route.link.touches(route.b), isTrue);
      expect(route.link.touches(stranger), isFalse);
    });
  });
}
