import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/components/units/unit.dart';
import 'package:tower_conquest/game/constants/asset_paths.dart';
import 'package:tower_conquest/game/constants/colors.dart';
import 'package:tower_conquest/game/managers/asset_manager.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

// Targeted checks for the Phase 1 sprite-integration contract: every asset
// resolves, bases tint with modulate, details never carry a colour filter,
// and nothing falls back to placeholder geometry once art is loaded.

const _size = 64;

Future<Uint8List> _renderBuilding(Building building) async {
  final recorder = ui.PictureRecorder();
  building.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size, _size);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

/// Alpha at ([x], [y]) in an RGBA byte buffer of width [_size].
int _alphaAt(Uint8List bytes, int x, int y) => bytes[(y * _size + x) * 4 + 3];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. All 14 asset paths resolve through AssetManager', () {
    setUpAll(() async {
      AssetManager().reset();
      await AssetManager().preload(AssetPaths.phase1Sprites());
    });

    test('the manifest lists exactly 14 paths', () {
      expect(AssetPaths.phase1Sprites(), hasLength(14));
    });

    test('every listed path resolves to a decoded sprite', () {
      for (final path in AssetPaths.phase1Sprites()) {
        expect(
          AssetManager().sprite(path),
          isNotNull,
          reason: '$path did not resolve',
        );
      }
    });
  });

  group('2. Base layers tint with BlendMode.modulate', () {
    test("a Building's tint paint uses modulate, not multiply", () {
      final building = Building(
        type: 'barracks',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(96),
      );

      final filter = building.tintPaint.colorFilter;
      expect(
        filter,
        ui.ColorFilter.mode(
          FactionColors.getColor('player'),
          ui.BlendMode.modulate,
        ),
      );
      expect(
        filter,
        isNot(
          ui.ColorFilter.mode(
            FactionColors.getColor('player'),
            ui.BlendMode.multiply,
          ),
        ),
      );
    });

    test("a Unit's tint paint uses modulate, not multiply", () {
      final unit = Unit(
        type: 'infantry',
        tier: 1,
        faction: 'enemy',
        position: Vector2.zero(),
        size: Vector2.all(20),
        targetPosition: Vector2.zero(),
      );

      expect(
        unit.tintPaint.colorFilter,
        ui.ColorFilter.mode(
          FactionColors.getColor('enemy'),
          ui.BlendMode.modulate,
        ),
      );
    });

    test('switching faction keeps the modulate blend mode', () {
      final building = Building(
        type: 'barracks',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(96),
      )..changeFaction('enemy');

      expect(
        building.tintPaint.colorFilter,
        ui.ColorFilter.mode(
          FactionColors.getColor('enemy'),
          ui.BlendMode.modulate,
        ),
      );
    });
  });

  group('3. Detail layers render without a colour filter', () {
    setUpAll(() async {
      AssetManager().reset();
      await AssetManager().preload(AssetPaths.phase1Sprites());
    });

    test('a building detail sprite carries no colour filter', () {
      final sprite = AssetManager()
          .sprite(AssetPaths.getBuildingDetailPath('barracks', 1))!;

      // Building.render calls `detailSprite?.render(canvas, size: size)` with
      // no overridePaint, so whatever the Sprite's own `paint` field holds is
      // what actually draws (Sprite.render uses `overridePaint ?? paint`). It
      // must carry no tint.
      expect(sprite.paint.colorFilter, isNull);
    });

    test('a unit detail sprite carries no colour filter', () {
      final sprite =
          AssetManager().sprite(AssetPaths.getUnitDetailPath('infantry', 1))!;

      expect(sprite.paint.colorFilter, isNull);
    });

    test('base and detail sprites for the same type are distinct objects', () {
      // Guards against a copy/paste bug that points detail at the base path
      // (which would tint it, defeating the point of a fixed-colour layer).
      final base =
          AssetManager().sprite(AssetPaths.getBuildingBasePath('tower', 1));
      final detail =
          AssetManager().sprite(AssetPaths.getBuildingDetailPath('tower', 1));

      expect(base, isNot(same(detail)));
    });
  });

  group('4. No placeholder fallback once assets are loaded', () {
    setUpAll(() async {
      AssetManager().reset();
      await AssetManager().preload(AssetPaths.phase1Sprites());
    });

    test('every Phase 1 building type gets a real sprite attached on load',
        () async {
      for (final type in AssetPaths.buildingTypes) {
        final building = Building(
          type: type,
          tier: 1,
          faction: 'player',
          position: Vector2.zero(),
          size: Vector2.all(96),
        );
        await building.onLoad();

        expect(building.baseSprite, isNotNull, reason: '$type base missing');
        expect(
          building.detailSprite,
          isNotNull,
          reason: '$type detail missing',
        );
      }
    });

    test('every Phase 1 unit class gets a real sprite attached on load',
        () async {
      for (final type in AssetPaths.unitTypes) {
        final unit = Unit(
          type: type,
          tier: 1,
          faction: 'enemy',
          position: Vector2.zero(),
          size: Vector2.all(20),
          targetPosition: Vector2.zero(),
        );
        await unit.onLoad();

        expect(unit.baseSprite, isNotNull, reason: '$type base missing');
      }
    });

    test('with no sprite attached, the body layer draws nothing at all',
        () async {
      // Proves there is no procedural fallback left: an art-less node must
      // render zero body pixels, not a placeholder rectangle or circle. The
      // old placeholder shapes filled the full bounds including every corner,
      // so the corners are exactly where a reintroduced fallback would show
      // up. The unit counter text draws too, but only near the centre
      // (_renderUnitCounter anchors at size.y * 0.66), so it never reaches
      // these four points.
      final building = Building(
        type: 'barracks',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(_size.toDouble()),
      );
      // baseSprite/detailSprite intentionally left null — onLoad not called.

      final bytes = await _renderBuilding(building);

      for (final corner in [
        (0, 0),
        (_size - 1, 0),
        (0, _size - 1),
        (_size - 1, _size - 1),
      ]) {
        expect(
          _alphaAt(bytes, corner.$1, corner.$2),
          0,
          reason: 'opaque pixel at ${corner.$1},${corner.$2} — a placeholder '
              'shape would fill the full bounds and show up here',
        );
      }
    });
  });

  group('5. The game boots and renders a representative node and unit', () {
    testWithGame<TowerConquestGame>(
        'both starting buildings mount with real sprites, no exceptions',
        TowerConquestGame.new, (game) async {
      expect(game.playerBase.baseSprite, isNotNull);
      expect(game.playerBase.detailSprite, isNotNull);
      expect(game.enemyBase.baseSprite, isNotNull);
      expect(game.enemyBase.detailSprite, isNotNull);
    });

    testWithGame<TowerConquestGame>(
        'a spawned unit mounts with its real sprite, no exceptions',
        TowerConquestGame.new, (game) async {
      final unit = game.sendUnit(from: game.playerBase, to: game.enemyBase)!;
      await game.ready();

      expect(unit.baseSprite, isNotNull);
      expect(unit.detailSprite, isNotNull);
    });
  });
}
