import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/screens/building_info_panel.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

/// Pumps the panel for a game with [building] selected.
///
/// Neither the game nor the building is ever mounted into a Flame tree here:
/// everything the panel reads (`unitsInside`, `tier`, `canUpgrade()`, ...) is
/// a plain getter, so a standalone `Building` is enough — the same shortcut
/// `result_overlay_test.dart` takes with a raw, un-booted `TowerConquestGame`.
Future<TowerConquestGame> _pumpPanel(
  WidgetTester tester,
  Building building,
) async {
  final game = TowerConquestGame()..selectedBuilding = building;

  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: BuildingInfoPanel(game: game))),
  );

  return game;
}

Building _building({
  String type = 'barracks',
  int tier = 1,
  int unitsInside = 10,
  int maxCapacity = 50,
  double generationRate = 1.0,
  double defenseMultiplier = 1.0,
}) {
  return Building(
    type: type,
    tier: tier,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    maxCapacity: maxCapacity,
    generationRate: generationRate,
    defenseMultiplier: defenseMultiplier,
  );
}

void main() {
  testWidgets('shows the selected building\'s type, tier, and stats',
      (tester) async {
    await _pumpPanel(
      tester,
      _building(unitsInside: 5, maxCapacity: 50, generationRate: 1.0),
    );

    expect(find.text('Barracks — Tier 1'), findsOneWidget);
    expect(find.text('Units: 5 / 50'), findsOneWidget);
    expect(find.text('Generation: 1.00/s'), findsOneWidget);
    expect(find.text('Defence: 5.0'), findsOneWidget);
  });

  testWidgets('renders nothing when no building is selected', (tester) async {
    final game = TowerConquestGame();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BuildingInfoPanel(game: game))),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the Upgrade button is disabled with too few units',
      (tester) async {
    // Tier 2 costs 20 (balance §1.2).
    await _pumpPanel(tester, _building(tier: 1, unitsInside: 19));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Upgrade (20 units)'), findsOneWidget);
  });

  testWidgets('the Upgrade button is enabled with enough units',
      (tester) async {
    await _pumpPanel(tester, _building(tier: 1, unitsInside: 20));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping Upgrade spends the cost and advances the tier',
      (tester) async {
    final game = await _pumpPanel(tester, _building(tier: 1, unitsInside: 20));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final building = game.selectedBuilding!;
    expect(building.tier, 2);
    expect(building.unitsInside, 0);
    expect(find.text('Barracks — Tier 2'), findsOneWidget);
  });

  testWidgets('a Tier 5 building shows Max Tier and stays disabled',
      (tester) async {
    await _pumpPanel(tester, _building(tier: 5, unitsInside: 999));

    expect(find.text('Max Tier'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('the Command Center shows Cannot Upgrade and stays disabled',
      (tester) async {
    await _pumpPanel(
      tester,
      _building(type: 'command_center', unitsInside: 999),
    );

    expect(find.text('Command Center — Tier 1'), findsOneWidget);
    expect(find.text('Cannot Upgrade'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('the close button deselects through game.deselect()',
      (tester) async {
    final game = await _pumpPanel(tester, _building());
    expect(game.selectedBuilding, isNotNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(game.selectedBuilding, isNull);
  });
}
