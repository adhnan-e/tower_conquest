import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/tower_conquest_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tower Conquest targets phones (GDD §1) and every level is laid out
  // vertically, so lock the orientation and reclaim the system bars. Both calls
  // are no-ops on platforms that do not support them.
  await Flame.device.fullScreen();
  await Flame.device.setPortrait();

  runApp(const TowerConquestApp());
}

class TowerConquestApp extends StatelessWidget {
  const TowerConquestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Conquest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D8CFF),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Held across rebuilds so the widget tree never restarts the match.
  late final TowerConquestGame _game = TowerConquestGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The result overlay registers itself in TowerConquestGame.onLoad, so it
      // needs no overlayBuilderMap here.
      body: GameWidget(game: _game),
    );
  }
}
