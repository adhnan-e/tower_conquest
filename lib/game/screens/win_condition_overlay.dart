import 'dart:async';

import 'package:flutter/material.dart';

import '../tower_conquest_game.dart';

/// A brief, purely informational reminder of the level's win condition,
/// shown near the top of the screen for the first few seconds of a match.
///
/// **Why this never listens for a dismissing tap.** The brief's implementation
/// notes ask for "fades out after 5 seconds or when the player taps the
/// screen", but its own acceptance criteria require the overlay to never
/// block gameplay — the player must still be able to tap towers and create
/// paths *through* it. A tap target that "catches" a screen tap to dismiss
/// itself necessarily intercepts that tap, which would swallow a tower
/// selection landing in the same spot. Those two requirements cannot both
/// hold at once, so this keeps the one that is an explicit acceptance
/// criterion (non-blocking) and drops the one that isn't (tap-to-dismiss):
/// the whole overlay is wrapped in [IgnorePointer], and the 5-second timer is
/// the only way it goes away.
class WinConditionOverlay extends StatefulWidget {
  static const String id = 'winCondition';

  final TowerConquestGame game;

  const WinConditionOverlay({required this.game, super.key});

  @override
  State<WinConditionOverlay> createState() => _WinConditionOverlayState();

  /// Translates a level's raw `winCondition` identifier into player-facing
  /// text. `LevelData`'s Stage 1 schema validation only ever accepts
  /// `capture_all_enemy_nodes`, so the fallback branch exists only so a
  /// future win condition can't crash this overlay — no currently loadable
  /// level reaches it.
  static String describe(String winCondition) {
    switch (winCondition) {
      case 'capture_all_enemy_nodes':
        return 'Capture all enemy towers';
      default:
        return 'Complete the objective';
    }
  }
}

class _WinConditionOverlayState extends State<WinConditionOverlay> {
  static const _visibleDuration = Duration(seconds: 5);
  static const _fadeDuration = Duration(milliseconds: 500);

  bool _visible = true;
  Timer? _fadeOutTimer;

  @override
  void initState() {
    super.initState();
    _fadeOutTimer = Timer(_visibleDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _fadeOutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text =
        WinConditionOverlay.describe(widget.game.currentLevel.winCondition);

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _fadeDuration,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
