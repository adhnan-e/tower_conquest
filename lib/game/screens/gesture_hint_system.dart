import 'dart:async';

import 'package:flutter/material.dart';

import '../managers/gesture_hint_controller.dart';
import '../tower_conquest_game.dart';

/// Onboarding text prompts guiding a first-time player through tower
/// selection, sending units, and the win condition — see
/// [GestureHintController] for the underlying state machine.
///
/// Only ever shown on Campaign 1, Level 1, per the brief: a player replaying
/// or on a later level already knows the controls.
class GestureHintSystem extends StatefulWidget {
  static const String id = 'gestureHints';

  final TowerConquestGame game;

  const GestureHintSystem({required this.game, super.key});

  @override
  State<GestureHintSystem> createState() => _GestureHintSystemState();
}

class _GestureHintSystemState extends State<GestureHintSystem> {
  final GestureHintController _controller = GestureHintController();
  Timer? _ticker;

  bool get _appliesToThisLevel {
    final level = widget.game.currentLevel;
    return level.campaign == 1 && level.levelNumber == 1;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _controller.tick(
          hasSelection: widget.game.selectedBuilding != null,
          hasActivePath: widget.game.paths.any((p) => p.isActive),
        );
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _appliesToThisLevel ? _controller.text : null;
    if (text == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 96, left: 32, right: 32),
            child: AnimatedOpacity(
              opacity: _controller.isVisible ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xCC1B2430),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
