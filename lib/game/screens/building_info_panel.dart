import 'dart:async';

import 'package:flutter/material.dart';

import '../components/buildings/building.dart';
import '../constants/colors.dart';
import '../tower_conquest_game.dart';

/// Shown for as long as [TowerConquestGame.selectedBuilding] is non-null:
/// the node's tier, garrison, and — if it can still upgrade — a button to do
/// so (GDD acceptance criteria: upgrade button, disabled when ineligible).
///
/// [Building] is a live, mutating component rather than a `Listenable`, so
/// this polls it on a short timer instead of wiring up a notifier just for
/// a handful of read-only numbers — the same trade [ResultOverlay] doesn't
/// have to make only because its values freeze the instant the match ends.
class BuildingInfoPanel extends StatefulWidget {
  static const String id = 'buildingInfo';

  final TowerConquestGame game;

  const BuildingInfoPanel({required this.game, super.key});

  @override
  State<BuildingInfoPanel> createState() => _BuildingInfoPanelState();
}

class _BuildingInfoPanelState extends State<BuildingInfoPanel> {
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
    final building = widget.game.selectedBuilding;
    if (building == null) {
      // The overlay is removed the same frame selection clears (see
      // TowerConquestGame._select), so this is a defensive no-op, not a
      // state this widget expects to render.
      return const SizedBox.shrink();
    }

    final accent = Color(FactionColors.getColor(building.faction).toARGB32());
    final cost = building.upgradeCost;
    final canUpgrade = building.canUpgrade();
    final maxedOut = cost == 0 && building.tier >= 5;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xE61B2430),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_displayName(building.type)} — Tier ${building.tier}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: widget.game.deselect,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Units: ${building.unitsInside} / ${building.maxCapacity}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Generation: ${building.generationRate.toStringAsFixed(2)}/s',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Defence: ${building.defenseValue.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canUpgrade
                        ? () => setState(() => building.upgrade())
                        : null,
                    child: Text(
                      maxedOut
                          ? 'Max Tier'
                          : cost == 0
                              ? 'Cannot Upgrade'
                              : 'Upgrade ($cost units)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(String type) => switch (type) {
        'barracks' => 'Barracks',
        'tower' => 'Tower',
        'factory' => 'Factory',
        'command_center' => 'Command Center',
        _ => type,
      };
}
