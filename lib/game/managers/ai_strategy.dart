import 'package:flame/components.dart' show Vector2;

import '../components/buildings/building.dart';
import '../components/units/unit.dart';

/// One send the AI wants performed: [unitCount] units from [source] to
/// [target]. `EnemyCommander` executes it by calling its injected `send`
/// callback [unitCount] times (each call moves one unit, matching how the
/// player's own taps work — see `TowerConquestGame.sendUnit`). A count of `0`
/// is a legitimate no-op rather than a special "send everything" sentinel:
/// the heuristics below always compute a concrete number to send, so there is
/// no ambiguous case that needs one.
class AIAction {
  final Building source;
  final Building target;
  final int unitCount;

  AIAction({required this.source, required this.target, this.unitCount = 0});
}

/// A snapshot of the board an [AIStrategy] decides against.
///
/// [hostileUnits] are every currently-travelling [Unit] *not* belonging to
/// the AI's own faction. It exists so threat assessment can check whether a
/// unit is actually inbound and how soon it lands, rather than approximating
/// "threat" from how close two buildings happen to sit — buildings don't
/// move, so a proximity-only check would flag the same pair of adjacent bases
/// as mutually threatening forever, attacking or not.
class AIDecisionContext {
  final List<Building> ownedBuildings;
  final List<Building> playerBuildings;
  final List<Building> neutralBuildings;
  final List<Unit> hostileUnits;
  final double gameTime;

  AIDecisionContext({
    required this.ownedBuildings,
    required this.playerBuildings,
    required this.neutralBuildings,
    this.hostileUnits = const [],
    required this.gameTime,
  });
}

/// Interface for AI decision-making strategies.
///
/// `EnemyCommander` owns *when* this runs (every frame) and *how* its actions
/// get carried out (via the `send` callback it was constructed with); the
/// strategy owns only *what* to do given a board snapshot. That split is what
/// let Phase 2 replace the entire Milestone 1 placeholder — a single
/// "attack when full" rule — without touching `EnemyCommander`'s public shape
/// at all.
abstract class AIStrategy {
  List<AIAction> decideActions(AIDecisionContext context);
}

/// Straight-line seconds until a unit travelling at [speed] covers
/// [distance]. Shared by any strategy that needs a travel-time estimate
/// (currently just threat assessment in [NormalAIStrategy]).
double travelTimeSeconds(double distance, double speed) =>
    speed > 0 ? distance / speed : double.infinity;

/// Euclidean distance between two points, exposed once here so strategies
/// aren't each rolling their own `sqrt(distanceToSquared(...))`.
double distanceBetween(Vector2 a, Vector2 b) => a.distanceTo(b);
