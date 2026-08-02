import 'package:flutter/material.dart';

import '../tower_conquest_game.dart';

/// A persistent restart shortcut in the top-left corner, so the player does
/// not have to lose a match on purpose to try again — [ResultOverlay]'s
/// "Play Again" button remains the only way to restart once the match has
/// actually ended, since this button is removed the same moment that
/// overlay appears (see `TowerConquestGame._endMatch`).
class RestartButton extends StatelessWidget {
  static const String id = 'restartButton';

  final TowerConquestGame game;

  const RestartButton({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: 'Restart',
            child: IconButton(
              icon: const Icon(Icons.replay),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x991B2430),
              ),
              onPressed: game.restart,
            ),
          ),
        ),
      ),
    );
  }
}
