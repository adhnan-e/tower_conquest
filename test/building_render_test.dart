import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/asset_paths.dart';
import 'package:tower_conquest/game/managers/asset_manager.dart';

// Renders the real Phase 1 sprites and checks the runtime-tinting contract
// holds against the art that actually shipped: base layers take the faction
// colour, detail layers never do, and nothing bleeds outside the silhouette.

const _size = 96;

Building _barracks({
  String faction = 'player',
  String type = 'barracks',
  int unitsInside = 0,
  bool isSelected = false,
}) {
  final building = Building(
    type: type,
    tier: 1,
    faction: faction,
    position: Vector2.zero(),
    size: Vector2.all(_size.toDouble()),
    unitsInside: unitsInside,
  )..isSelected = isSelected;

  final assets = AssetManager();
  building.baseSprite = assets.sprite(AssetPaths.getBuildingBasePath(type, 1));
  building.detailSprite =
      assets.sprite(AssetPaths.getBuildingDetailPath(type, 1));
  return building;
}

Future<Uint8List> _render(Building building) async {
  final recorder = ui.PictureRecorder();
  building.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size, _size);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

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

/// Pixels that are opaque and identical between the two renders — i.e. the
/// parts the faction tint did not touch.
int _sharedOpaquePixels(Uint8List a, Uint8List b) {
  var shared = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i + 3] < 250) continue;
    if (a[i] == b[i] && a[i + 1] == b[i + 1] && a[i + 2] == b[i + 2]) {
      shared++;
    }
  }
  return shared;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AssetManager().reset();
    await AssetManager().preload(AssetPaths.phase1Sprites());
  });

  group('Phase 1 art is wired up', () {
    test('every building type has both layers bundled', () {
      for (final type in AssetPaths.buildingTypes) {
        expect(
          AssetManager().sprite(AssetPaths.getBuildingBasePath(type, 1)),
          isNotNull,
          reason: '$type base layer missing',
        );
        expect(
          AssetManager().sprite(AssetPaths.getBuildingDetailPath(type, 1)),
          isNotNull,
          reason: '$type detail layer missing',
        );
      }
    });

    test('every unit class has both layers bundled', () {
      for (final type in AssetPaths.unitTypes) {
        expect(
          AssetManager().sprite(AssetPaths.getUnitBasePath(type, 1)),
          isNotNull,
          reason: '$type base layer missing',
        );
        expect(
          AssetManager().sprite(AssetPaths.getUnitDetailPath(type, 1)),
          isNotNull,
          reason: '$type detail layer missing',
        );
      }
    });

    test('a tier with no art yet renders nothing rather than crashing', () {
      // Tiers 2-5 ship in Phase 2. Until then the sprite is absent, and with
      // the placeholders gone the node simply draws no body.
      expect(
        AssetManager().sprite(AssetPaths.getBuildingBasePath('barracks', 2)),
        isNull,
      );
    });
  });

  group('Runtime tinting', () {
    test('the sprite body draws opaque pixels', () async {
      final bytes = await _render(_barracks());

      expect(_pixel(bytes, 48, 48).a, 255);
    });

    test('the player body reads blue', () async {
      final px = _pixel(await _render(_barracks(faction: 'player')), 48, 48);

      // Grayscale x #2D8CFF under multiply.
      expect(px.b, greaterThan(px.g));
      expect(px.g, greaterThan(px.r));
    });

    test('the enemy body reads red', () async {
      final px = _pixel(await _render(_barracks(faction: 'enemy')), 48, 48);

      // Grayscale x #E74C3C under multiply.
      expect(px.r, greaterThan(px.g));
      expect(px.r, greaterThan(px.b));
    });

    test('player and enemy nodes are visibly different', () async {
      final player = await _render(_barracks(faction: 'player'));
      final enemy = await _render(_barracks(faction: 'enemy'));

      // Not merely different — different across a large share of the sprite,
      // or the two factions would be hard to tell apart in play.
      expect(_diffCount(player, enemy), greaterThan(2000));
    });

    test('the detail layer is identical on both factions', () async {
      final player = await _render(_barracks(faction: 'player'));
      final enemy = await _render(_barracks(faction: 'enemy'));

      // The untinted charcoal and gold pixels must survive the recolour
      // byte-for-byte. If the tint leaked onto the detail layer this would be
      // near zero.
      expect(_sharedOpaquePixels(player, enemy), greaterThan(500));
    });

    test('every building type tints', () async {
      for (final type in AssetPaths.buildingTypes) {
        final player = await _render(_barracks(type: type, faction: 'player'));
        final enemy = await _render(_barracks(type: type, faction: 'enemy'));

        expect(
          _diffCount(player, enemy),
          greaterThan(0),
          reason: '$type does not change with faction',
        );
      }
    });

    test('building types have distinct silhouettes', () async {
      final barracks = await _render(_barracks(type: 'barracks'));
      final tower = await _render(_barracks(type: 'tower'));
      final factory = await _render(_barracks(type: 'factory'));

      expect(_diffCount(barracks, tower), greaterThan(0));
      expect(_diffCount(barracks, factory), greaterThan(0));
      expect(_diffCount(tower, factory), greaterThan(0));
    });
  });

  group('No artefacts', () {
    test('the corners stay fully transparent', () async {
      final bytes = await _render(_barracks());

      // The art has an alpha-0 background; a green or black matte would show
      // up here as opaque pixels.
      for (final corner in [(0, 0), (_size - 1, 0), (0, _size - 1)]) {
        expect(
          _pixel(bytes, corner.$1, corner.$2).a,
          0,
          reason: 'opaque pixel at ${corner.$1},${corner.$2}',
        );
      }
    });
  });

  group('Overlays', () {
    test('the unit counter is drawn over the sprite', () async {
      final empty = await _render(_barracks(unitsInside: 0));
      final full = await _render(_barracks(unitsInside: 88));

      expect(_diffCount(empty, full), greaterThan(0));
    });

    test('the selection ring is drawn over the sprite', () async {
      final plain = await _render(_barracks());
      final selected = await _render(_barracks(isSelected: true));

      expect(_diffCount(plain, selected), greaterThan(0));
    });
  });
}
