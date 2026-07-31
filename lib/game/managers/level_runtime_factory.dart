import 'package:flame/components.dart';

import '../components/buildings/building.dart';
import '../components/map/path_link.dart';
import '../constants/balance.dart';
import '../models/level_data.dart';

/// Converts a validated [LevelData] into live [Building] and [PathLink]
/// components.
///
/// Kept separate from [Building] itself rather than teaching `Building` about
/// JSON or node IDs: `Building` has no `id` field (see
/// `orchestrator/PHASE3_DEVELOPER_PROMPT.md` §6), so authored node IDs exist
/// only here, in a loader-local map, purely to resolve [LinkData] into the
/// [Building] pair a [PathLink] needs.
class LevelRuntimeFactory {
  LevelRuntimeFactory._();

  /// Builds one [Building] from [node], using [BuildingBalance.baseStatsFor]
  /// to supply the type-correct `generationRate`, `maxCapacity`, and
  /// `defenseMultiplier` — the three stats [Building]'s constructor defaults
  /// to Barracks-like values for, which would silently misconfigure every
  /// other building type if left unset.
  ///
  /// [size] is the on-screen node size (the game's existing constant, not
  /// part of the level schema — Stage 1 does not author per-node sizes).
  /// [onTapped] is wired exactly as the current hard-coded level does.
  ///
  /// [node.type] is guaranteed valid by [LevelData]'s own validation, so a
  /// missing [BuildingBalance] entry here would mean the validation and the
  /// balance table have drifted apart — a bug worth failing loudly on rather
  /// than silently defaulting.
  static Building buildingFor(
    NodeData node, {
    required Vector2 size,
    required void Function(Building building)? onTapped,
  }) {
    final stats = BuildingBalance.baseStatsFor(node.type);
    if (stats == null) {
      throw StateError(
        'BuildingBalance has no base stats for validated type '
        '${node.type} — validation and the balance table have drifted '
        'apart.',
      );
    }

    return Building(
      type: node.type,
      tier: node.tier,
      faction: node.faction,
      position: node.position,
      size: size,
      unitsInside: node.unitsInside,
      generationRate: stats.genRate,
      maxCapacity: stats.capacity,
      defenseMultiplier: stats.defense,
    )..onTapped = onTapped;
  }

  /// Resolves every [LevelData.links] entry into a [PathLink] joining the
  /// already-built [Building]s in [buildingsByNodeId].
  ///
  /// Safe to assume every ID resolves: [LevelData] validation already
  /// rejected any link referencing an undeclared node before this runs.
  static List<PathLink> linksFor(
    LevelData level,
    Map<String, Building> buildingsByNodeId,
  ) {
    return [
      for (final link in level.links)
        PathLink(
          a: buildingsByNodeId[link.from]!,
          b: buildingsByNodeId[link.to]!,
        ),
    ];
  }
}
