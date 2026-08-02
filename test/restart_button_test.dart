import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/screens/restart_button.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

void main() {
  testWidgets('renders a visible restart icon', (tester) async {
    final game = TowerConquestGame();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RestartButton(game: game))),
    );

    expect(find.byIcon(Icons.replay), findsOneWidget);
  });

  testWidgets('is anchored to the top-left corner, not spanning the screen',
      (tester) async {
    final game = TowerConquestGame();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RestartButton(game: game))),
    );

    // A geometric check rather than digging through the widget tree for a
    // specific Align: MaterialApp/Scaffold add their own internally, so
    // asserting "there is exactly one Align" would be fragile. The actual
    // acceptance criterion is where the button ends up on screen.
    final topLeft = tester.getTopLeft(find.byIcon(Icons.replay));
    expect(topLeft.dx, lessThan(100));
    expect(topLeft.dy, lessThan(100));
  });

  testWidgets('tapping the button restarts the match', (tester) async {
    // Goes through a real boot (see result_overlay_test.dart for why
    // runAsync is required): restart() reloads a real level.
    final game = await tester.runAsync(
      () => initializeGame(TowerConquestGame.new),
    );
    game!.status = GameStatus.victory;
    game.elapsedTime = 42;

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RestartButton(game: game))),
    );
    await tester.tap(find.byIcon(Icons.replay));
    await tester.pump();

    // These fields are reset synchronously inside restart(), before it
    // kicks off the (fire-and-forget) async level reload.
    expect(game.status, GameStatus.playing);
    expect(game.elapsedTime, 0);
    expect(game.selectedBuilding, isNull);

    // Let the reload's real asset/JSON I/O actually finish before the test
    // ends, so nothing is left pending.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  });
}
