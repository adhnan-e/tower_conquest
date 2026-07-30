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

    test('falls back to multiply for an unknown blend mode', () {
      expect(FactionColors.getBlendMode('not_a_mode'), ui.BlendMode.multiply);
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

    test('keys shade paints by gray level as well as faction', () {
      final white = FactionManager().getShadePaint('player', 0xFF);
      final shade = FactionManager().getShadePaint('player', 0x88);

      expect(white, isNot(same(shade)));
      expect(white, same(FactionManager().getShadePaint('player', 0xFF)));
      // Compared as packed ARGB: Color holds floating-point components, so two
      // Colors that describe the same pixel are not necessarily ==.
      expect(white.color.toARGB32(), 0xFFFFFFFF);
      expect(shade.color.toARGB32(), 0xFF888888);
    });

    test('shade paints carry the faction colour filter', () {
      // A drawn shape takes its source colour from paint.color, so without an
      // explicit gray the default opaque black would multiply down to black.
      final paint = FactionManager().getShadePaint('enemy', 0xFF);

      expect(paint.colorFilter, isNotNull);
      expect(paint.color.toARGB32(), 0xFFFFFFFF);
    });

    test('clearCache drops cached instances', () {
      final before = FactionManager().getPaint('player');
      FactionManager().clearCache();
      final after = FactionManager().getPaint('player');

      expect(before, isNot(same(after)));
    });
  });
}
