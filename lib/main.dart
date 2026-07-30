import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/tower_conquest_game.dart';

void main() {
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

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: TowerConquestGame()),
    );
  }
}
