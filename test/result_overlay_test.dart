import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/screens/result_overlay.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

/// Pumps the overlay for a game already in [outcome].
///
/// The status is set directly rather than played out: what the overlay does
/// with a finished match is this file's concern, and *reaching* victory or
/// defeat through capture is already covered in `game_boot_test.dart`.
Future<TowerConquestGame> _pumpOverlay(
  WidgetTester tester,
  GameStatus outcome,
) async {
  final game = TowerConquestGame()..status = outcome;

  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ResultOverlay(game: game))),
  );

  return game;
}

void main() {
  testWidgets('announces a win', (tester) async {
    await _pumpOverlay(tester, GameStatus.victory);

    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('DEFEAT'), findsNothing);
    expect(find.text('You captured the enemy base.'), findsOneWidget);
  });

  testWidgets('announces a loss', (tester) async {
    await _pumpOverlay(tester, GameStatus.defeat);

    expect(find.text('DEFEAT'), findsOneWidget);
    expect(find.text('VICTORY'), findsNothing);
    expect(find.text('Your last base has fallen.'), findsOneWidget);
  });

  testWidgets('offers a way to play again either way', (tester) async {
    await _pumpOverlay(tester, GameStatus.victory);
    expect(find.text('Play Again'), findsOneWidget);

    await _pumpOverlay(tester, GameStatus.defeat);
    expect(find.text('Play Again'), findsOneWidget);
  });

  testWidgets('Play Again puts the match back to playing', (tester) async {
    final game = await _pumpOverlay(tester, GameStatus.victory);

    await tester.tap(find.text('Play Again'));
    await tester.pump();

    expect(game.status, GameStatus.playing);
    expect(game.playerBase.faction, 'player');
    expect(game.enemyBase.faction, 'enemy');
    expect(game.nodes, hasLength(2));
  });
}
