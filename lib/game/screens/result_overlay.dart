import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../tower_conquest_game.dart';

/// The Victory / Defeat screens from GDD §8.1.
///
/// Deliberately minimal: the outcome and a way to play again. Match statistics
/// and performance ratings are a later concern — the Gold reward curve they
/// would feed is not specified in the planning documents yet.
class ResultOverlay extends StatelessWidget {
  /// Identifier registered with the game's overlay map.
  static const String id = 'result';

  final TowerConquestGame game;

  const ResultOverlay({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    final won = game.status == GameStatus.victory;
    final accent = Color(
      FactionColors.getColor(won ? 'player' : 'enemy').toARGB32(),
    );

    return Container(
      color: const Color(0xCC1B2430),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'VICTORY' : 'DEFEAT',
            style: TextStyle(
              color: accent,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            won ? 'You captured the enemy base.' : 'Your last base has fallen.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: game.restart,
            child: const Text('Play Again', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
