import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';

const _size = 96;

Building _barracks({
  String faction = 'player',
  String type = 'barracks',
  int unitsInside = 0,
  bool isSelected = false,
}) {
  return Building(
    type: type,
    tier: 1,
    faction: faction,
    position: Vector2.zero(),
    size: Vector2.all(_size.toDouble()),
    unitsInside: unitsInside,
  )..isSelected = isSelected;
}

/// Renders [building] to raw RGBA bytes.
///
/// No sprite is loaded (the art has not been produced yet), so this exercises
/// the placeholder path — the same faction `Paint` the real sprites will use.
Future<Uint8List> _render(Building building) async {
  final recorder = ui.PictureRecorder();
  building.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size, _size);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

/// RGBA of the pixel at ([x], [y]).
({int r, int g, int b, int a}) _pixel(Uint8List bytes, int x, int y) {
  final i = (y * _size + x) * 4;
  return (r: bytes[i], g: bytes[i + 1], b: bytes[i + 2], a: bytes[i + 3]);
}

int _diffCount(Uint8List a, Uint8List b) {
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) diff++;
  }
  return diff;
}

void main() {
  group('Building placeholder rendering', () {
    test('draws a visible body when no sprite is available', () async {
      final bytes = await _render(_barracks());

      // Centre of the body must be opaque, not an empty canvas.
      expect(_pixel(bytes, 48, 48).a, 255);
    });

    test('tints the player body blue through the multiply filter', () async {
      final bytes = await _render(_barracks(faction: 'player'));
      final px = _pixel(bytes, 48, 48);

      // White body x #2D8CFF should come out as that blue.
      expect(px.b, greaterThan(px.g));
      expect(px.g, greaterThan(px.r));
    });

    test('tints the enemy body red through the multiply filter', () async {
      final bytes = await _render(_barracks(faction: 'enemy'));
      final px = _pixel(bytes, 48, 48);

      // White body x #E74C3C should come out as that red.
      expect(px.r, greaterThan(px.g));
      expect(px.r, greaterThan(px.b));
    });

    test('player and enemy nodes render differently', () async {
      final player = await _render(_barracks(faction: 'player'));
      final enemy = await _render(_barracks(faction: 'enemy'));

      expect(_diffCount(player, enemy), greaterThan(0));
    });

    test('the mid-gray band renders as a shade of the faction colour',
        () async {
      final bytes = await _render(_barracks(faction: 'player'));
      final band = _pixel(bytes, 48, 18); // inside the roof band
      final body = _pixel(bytes, 48, 48);

      // 0x88 gray multiplied by the faction colour is the same hue, darker.
      expect(band.b, lessThan(body.b));
      expect(band.b, greaterThan(band.r));
    });

    test('building types produce distinct silhouettes', () async {
      final barracks = await _render(_barracks(type: 'barracks'));
      final tower = await _render(_barracks(type: 'tower'));
      final factory = await _render(_barracks(type: 'factory'));

      expect(_diffCount(barracks, tower), greaterThan(0));
      expect(_diffCount(barracks, factory), greaterThan(0));
      expect(_diffCount(tower, factory), greaterThan(0));
    });
  });

  group('Building overlays', () {
    test('the unit counter is actually drawn', () async {
      final empty = await _render(_barracks(unitsInside: 0));
      final full = await _render(_barracks(unitsInside: 88));

      // Different counter values must change the output; if the text silently
      // failed to draw these would be byte-identical.
      expect(_diffCount(empty, full), greaterThan(0));
    });

    test('the selection ring is actually drawn', () async {
      final plain = await _render(_barracks());
      final selected = await _render(_barracks(isSelected: true));

      expect(_diffCount(plain, selected), greaterThan(0));
    });
  });
}
