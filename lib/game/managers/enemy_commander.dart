import '../components/buildings/building.dart';

/// A placeholder opponent: the smallest behaviour that makes defeat reachable.
///
/// `05_levels/01_LEVEL_DESIGN.md` gives Level 1 a passive enemy that "does not
/// attack, only defends". Taken literally that leaves the player unable to lose,
/// so this adds exactly one rule and nothing more: **a full enemy node sends a
/// unit at a player node.**
///
/// This is deliberately *not* the AI. The decision tree in balance §5.2 —
/// assess threat, expand to neutrals, upgrade when safe, adapt to who is
/// winning, and scale across Easy/Normal/Hard — belongs to the AI milestone.
/// Keeping this in its own file with a single entry point means that milestone
/// replaces the file wholesale instead of unpicking behaviour from the game
/// class.
class EnemyCommander {
  /// Which faction this commander plays.
  final String faction;

  /// Fraction of capacity a node must reach before it attacks. At 1.0 the node
  /// must be completely full, which is the intended "overwhelm a turtling
  /// enemy" pacing for Level 1. This is the one knob worth turning if the
  /// counter-attack lands too softly or too hard.
  final double attackThreshold;

  EnemyCommander({this.faction = 'enemy', this.attackThreshold = 1.0});

  /// Considers one turn of decisions.
  ///
  /// [nodes] is every node on the map; [send] performs a send and reports
  /// whether it happened. The commander owns no state, so it stays trivially
  /// testable and safe to call every frame.
  void update({
    required List<Building> nodes,
    required bool Function(Building from, Building to) send,
  }) {
    final owned = nodes.where((n) => n.faction == faction).toList();
    if (owned.isEmpty) return;

    final targets = nodes.where((n) => n.faction != faction).toList();
    if (targets.isEmpty) return;

    for (final node in owned) {
      if (node.unitsInside < node.maxCapacity * attackThreshold) continue;

      final target = _nearestTo(node, targets);
      if (target != null) {
        send(node, target);
      }
    }
  }

  /// Balance §5.2's one behaviour we do keep: go for the closest thing.
  Building? _nearestTo(Building from, List<Building> candidates) {
    Building? best;
    var bestDistance = double.infinity;

    for (final candidate in candidates) {
      final distance = from.position.distanceToSquared(candidate.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }

    return best;
  }
}
