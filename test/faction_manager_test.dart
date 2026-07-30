import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/constants/colors.dart';

void main() {
  setUp(FactionManager().clearCache);

  group('FactionColors', () {
    test('exposes the palette from the GDD', () {
      expect(FactionColors.getColor('player'), const ui.Color(0xFF2D8CFF));
      expect(FactionColors.getColor('enemy'), const ui.Color(0xFFE74C3C));
      expect(FactionColors.getColor('neutral'), const ui.Color(0xFFB7BDC8));
    });

    test('falls back to neutral for an unknown faction', () {
      expect(
        FactionColors.getColor('not_a_faction'),
        FactionColors.getColor('neutral'),
      );
    });

    test('falls back to the default for an unknown blend mode', () {
      expect(FactionColors.getBlendMode('not_a_mode'), ui.BlendMode.modulate);
    });
  });

  group('FactionManager', () {
    test('is a singleton', () {
      expect(FactionManager(), same(FactionManager()));
    });

    test('returns the same Paint instance for repeated lookups', () {
      final first = FactionManager().getPaint('player');
      final second = FactionManager().getPaint('player');

      expect(first, same(second));
    });

    test('returns distinct Paints per faction', () {
      final player = FactionManager().getPaint('player');
      final enemy = FactionManager().getPaint('enemy');

      expect(player, isNot(same(enemy)));
    });

    test('tints with modulate, which preserves transparency', () {
      // multiply turns transparent pixels into an opaque faction-coloured
      // square; modulate multiplies alpha too, so the sprite keeps its shape.
      // See FactionColors.defaultBlendMode.
      expect(FactionColors.defaultBlendMode, 'modulate');
      expect(
        FactionColors.getBlendMode(FactionColors.defaultBlendMode),
        ui.BlendMode.modulate,
      );
      expect(FactionManager().getPaint('player').colorFilter, isNotNull);
    });

    test('an explicit blend mode is honoured and cached separately', () {
      final byDefault = FactionManager().getPaint('player');
      final multiplied =
          FactionManager().getPaint('player', blendMode: 'multiply');

      expect(byDefault, isNot(same(multiplied)));
    });

    test('clearCache drops cached instances', () {
      final before = FactionManager().getPaint('player');
      FactionManager().clearCache();
      final after = FactionManager().getPaint('player');

      expect(before, isNot(same(after)));
    });
  });
}
