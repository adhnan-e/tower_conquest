import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/asset_paths.dart';
import 'package:tower_conquest/game/managers/asset_manager.dart';

// Phase 2's tier-aware sprite contract: a building's rendered art follows its
// tier when that tier's PNGs exist, and falls back to Tier 1 when they don't
// (which is the case for every tier above 1 until the orchestrator generates
// them — see AssetPaths.phase2Sprites).

const _size = 96;

Building _barracks({int tier = 1, int unitsInside = 0}) {
  return Building(
    type: 'barracks',
    tier: tier,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(_size.toDouble()),
    unitsInside: unitsInside,
    generationRate: 1.0,
    maxCapacity: 50,
    defenseMultiplier: 1.0,
  );
}

Future<Uint8List> _render(Building building) async {
  final recorder = ui.PictureRecorder();
  building.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size, _size);
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

int _diffCount(Uint8List a, Uint8List b) {
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) diff++;
  }
  return diff;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AssetManager().reset();
  });

  group('AssetManager.phase2Sprites()', () {
    test('lists Tiers 2-5 for every building type, no units', () {
      final paths = AssetPaths.phase2Sprites();

      expect(paths, hasLength(4 * 4 * 2)); // 4 types x tiers 2-5 x 2 layers
      expect(
        paths,
        contains('buildings/barracks_tier2_base.png'),
      );
      expect(
        paths,
        contains('buildings/command_center_tier5_detail.png'),
      );
      expect(paths.any((p) => p.startsWith('units/')), isFalse);
    });
  });

  group('AssetManager.buildingBaseSprite / buildingDetailSprite', () {
    setUp(() async {
      await AssetManager().preload(AssetPaths.phase1Sprites());
    });

    test('returns the Tier 1 sprite when asked for Tier 1', () async {
      final sprite = await AssetManager().buildingBaseSprite('barracks', 1);
      expect(sprite, isNotNull);
    });

    test('falls back to Tier 1 when the requested tier has no art yet',
        () async {
      // Tier 2 barracks art does not exist in this test's asset bundle.
      final tier1 = await AssetManager().buildingBaseSprite('barracks', 1);
      final tier2 = await AssetManager().buildingBaseSprite('barracks', 2);

      expect(tier2, isNotNull);
      expect(tier2, same(tier1));
    });

    test('the detail layer falls back the same way', () async {
      final tier1 = await AssetManager().buildingDetailSprite('barracks', 1);
      final tier2 = await AssetManager().buildingDetailSprite('barracks', 2);

      expect(tier2, isNotNull);
      expect(tier2, same(tier1));
    });

    test('an out-of-range tier clamps into 1-5 rather than throwing', () async {
      final sprite = await AssetManager().buildingBaseSprite('barracks', 99);
      expect(sprite, isNotNull);
    });

    test('an unknown building type resolves to null at every tier', () async {
      expect(
        await AssetManager().buildingBaseSprite('castle', 1),
        isNull,
      );
      expect(
        await AssetManager().buildingBaseSprite('castle', 3),
        isNull,
      );
    });

    test('every Phase 1 building type resolves at every tier 1-5', () async {
      for (final type in AssetPaths.buildingTypes) {
        for (var tier = 1; tier <= 5; tier++) {
          expect(
            await AssetManager().buildingBaseSprite(type, tier),
            isNotNull,
            reason: '$type tier $tier base',
          );
          expect(
            await AssetManager().buildingDetailSprite(type, tier),
            isNotNull,
            reason: '$type tier $tier detail',
          );
        }
      }
    });
  });

  group('Building renders through the tier-aware lookup', () {
    setUp(() async {
      await AssetManager().preload(AssetPaths.phase1Sprites());
    });

    test('a building constructed at Tier 1 has real sprites after onLoad',
        () async {
      final building = _barracks();
      await building.onLoad();

      expect(building.baseSprite, isNotNull);
      expect(building.detailSprite, isNotNull);
    });

    test('upgrading swaps in this tier\'s sprites (Tier 1 fallback today)',
        () async {
      final building = _barracks(unitsInside: 50);
      await building.onLoad();

      final spriteBefore = building.baseSprite;
      expect(building.upgrade(), isTrue);

      // Building.upgrade() reloads sprites without awaiting (fire-and-forget,
      // documented on upgrade()); flush the microtask queue so the async
      // swap actually lands before we inspect it.
      await Future<void>.delayed(Duration.zero);

      expect(building.tier, 2);
      // No Tier 2 art exists yet, so this must be the *same* Tier 1 sprite
      // object AssetManager already cached — not null, and not some
      // half-loaded placeholder state.
      expect(building.baseSprite, isNotNull);
      expect(building.baseSprite, same(spriteBefore));
    });

    test('rendering an unrecognised building type draws nothing crash-free',
        () async {
      final building = Building(
        type: 'castle',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(_size.toDouble()),
      );
      await building.onLoad();

      expect(building.baseSprite, isNull);
      expect(building.detailSprite, isNull);

      // Must not throw — render() null-checks both sprites before drawing.
      final bytes = await _render(building);
      expect(bytes, isNotNull);
    });

    test('every building type still renders distinctly from every other',
        () async {
      // Regression guard: tier-aware lookup must not accidentally collapse
      // every type onto the same (Tier 1 barracks) sprite.
      final rendered = <String, Uint8List>{};
      for (final type in AssetPaths.buildingTypes) {
        final building = _barracks(); // reuse ctor for size/faction only
        final typed = Building(
          type: type,
          tier: 1,
          faction: 'player',
          position: Vector2.zero(),
          size: building.size,
        );
        await typed.onLoad();
        rendered[type] = await _render(typed);
      }

      const types = AssetPaths.buildingTypes;
      for (var i = 0; i < types.length; i++) {
        for (var j = i + 1; j < types.length; j++) {
          expect(
            _diffCount(rendered[types[i]]!, rendered[types[j]]!),
            greaterThan(0),
            reason: '${types[i]} vs ${types[j]}',
          );
        }
      }
    });
  });
}
