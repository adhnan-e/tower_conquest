import 'dart:async';

import 'package:flutter/material.dart';

import '../tower_conquest_game.dart';

/// A persistent top-of-screen banner naming the current level and showing
/// how close the match is to its capture-all-enemy-nodes win condition.
///
/// Polls on a short timer for the same reason `BuildingInfoPanel` does:
/// [TowerConquestGame.nodes] is a list of live, mutating components rather
/// than a `Listenable`, so there is nothing else to rebuild this on.
class LevelProgressBanner extends StatefulWidget {
  static const String id = 'levelProgressBanner';

  final TowerConquestGame game;

  const LevelProgressBanner({required this.game, super.key});

  @override
  State<LevelProgressBanner> createState() => _LevelProgressBannerState();
}

class _LevelProgressBannerState extends State<LevelProgressBanner> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.game.currentLevel;

    // Nodes are captured in place, never removed (Building._capture flips
    // faction rather than replacing the component), so counting live
    // enemy-faction nodes against the level's authored total is enough —
    // no separate id-based tracking needed.
    final totalEnemy = level.nodes.where((n) => n.faction == 'enemy').length;
    final remainingEnemy =
        widget.game.nodes.where((n) => n.faction == 'enemy').length;
    final captured = (totalEnemy - remainingEnemy).clamp(0, totalEnemy);
    final progress = totalEnemy == 0 ? 1.0 : captured / totalEnemy;

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE61B2430),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Campaign ${level.campaign}, Level ${level.levelNumber}: '
                  '${level.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE23B3B)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$captured of $totalEnemy enemy towers captured',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
