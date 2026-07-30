import '../components/buildings/building.dart';
import 'ai_strategy.dart';

/// The "Normal" difficulty tactical AI from
/// `planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md` §"System 3":
/// assess threat, attack weak nearby targets, expand into undefended neutrals,
/// and upgrade its economy when it can afford to. Easy/Hard are noted in the
/// plan as future difficulty tiers built on the same heuristics with
/// different constants; only Normal is implemented here.
///
/// Corrects three bugs present in the reference pseudocode in
/// `orchestrator/PHASE2_DEVELOPER_PROMPT.md`:
///
/// 1. **Target selection** there blends distance and defence into one linear
///    score (`distance + defense * 100`). Distance is a squared pixel value
///    (tens of thousands) and defence*100 is at most a few thousand, so the
///    blend is really just "nearest", with the defence tiebreak silently
///    inert except at exact distance ties. This picks the nearest target
///    first and only *then* breaks ties on defence, matching the heuristic's
///    own wording ("nearest... if equidistant, lowest defense").
/// 2. **Threat assessment** there checks whether any *building* — not a unit
///    — is within range, using `playerBuilding.unitsInside > 0` as a proxy
///    for "a unit is inbound". Adjacent buildings would then read as a
///    permanent, unit-independent threat to each other. This checks actual
///    in-flight units and their real remaining travel time.
/// 3. **Upgrade priority** there is `if (type == 'factory' || ...) return
///    true; return true;` — both branches return the same thing, so the
///    "prioritize high-generation buildings" comment describes nothing the
///    code does. This sorts eligible buildings by generation rate and
///    upgrades the highest first, which is what the comment says.
class NormalAIStrategy implements AIStrategy {
  /// Don't upgrade more than once every this many seconds of game time.
  static const double upgradeCooldownSeconds = 20.0;

  /// A unit closer than this many seconds of travel time counts as an
  /// immediate threat to whatever it's heading for.
  static const double threatThresholdSeconds = 2.0;

  /// Fraction of capacity a building must reach before it's upgrade-ready.
  static const double capacityThresholdForUpgrade = 0.7;

  /// Minimum garrison an owned building keeps before it will spare units to
  /// expand into a neutral building.
  static const int minGarrisonToExpand = 5;

  /// Flat number of units committed to an expansion.
  static const int expansionUnitCount = 5;

  /// Defence below which a target counts as weak enough to send everything.
  static const double weakTargetDefense = 20.0;

  /// Defence below which a target is moderate rather than heavily defended.
  static const double moderateTargetDefense = 50.0;

  double _lastUpgradeTime = -upgradeCooldownSeconds;

  @override
  List<AIAction> decideActions(AIDecisionContext context) {
    final actions = <AIAction>[];

    for (final building in context.ownedBuildings) {
      if (building.unitsInside < 1) continue;

      final target = _selectTarget(building, context.playerBuildings);
      if (target == null) continue;

      final unitCount = _allocateUnitsForAttack(building, target);
      if (unitCount > 0) {
        actions.add(
          AIAction(source: building, target: target, unitCount: unitCount),
        );
      }
    }

    for (final building in context.ownedBuildings) {
      if (building.unitsInside < minGarrisonToExpand) continue;

      final target = _selectTarget(building, context.neutralBuildings);
      if (target == null) continue;

      actions.add(
        AIAction(
          source: building,
          target: target,
          unitCount: expansionUnitCount,
        ),
      );
    }

    _considerUpgrading(context);

    return actions;
  }

  /// One upgrade per decision cycle, on the eligible building with the
  /// highest generation rate — see the class doc for why this replaces the
  /// reference's non-functional priority check.
  void _considerUpgrading(AIDecisionContext context) {
    if (context.gameTime - _lastUpgradeTime < upgradeCooldownSeconds) return;

    final eligible = context.ownedBuildings
        .where(
          (b) =>
              b.unitsInside >= b.maxCapacity * capacityThresholdForUpgrade &&
              b.canUpgrade() &&
              !_isUnderThreat(b, context),
        )
        .toList()
      ..sort((a, b) => b.generationRate.compareTo(a.generationRate));

    if (eligible.isEmpty) return;

    eligible.first.upgrade();
    _lastUpgradeTime = context.gameTime;
  }

  /// Nearest candidate to [from]; ties broken by lowest defence. Null if
  /// [candidates] is empty.
  Building? _selectTarget(Building from, List<Building> candidates) {
    Building? best;
    var bestDistance = double.infinity;
    var bestDefense = double.infinity;

    for (final candidate in candidates) {
      final distance = distanceBetween(from.position, candidate.position);
      final defense = candidate.defenseValue;

      final closer = distance < bestDistance;
      final tiedButWeaker = distance == bestDistance && defense < bestDefense;

      if (best == null || closer || tiedButWeaker) {
        best = candidate;
        bestDistance = distance;
        bestDefense = defense;
      }
    }

    return best;
  }

  /// All available units against a weak target (defence below
  /// [weakTargetDefense]), half against a moderate one, a quarter against a
  /// heavily defended one.
  int _allocateUnitsForAttack(Building from, Building target) {
    final defense = target.defenseValue;

    if (defense < weakTargetDefense) return from.unitsInside;
    if (defense < moderateTargetDefense) {
      return (from.unitsInside * 0.5).toInt();
    }
    return (from.unitsInside * 0.25).toInt();
  }

  /// Whether a hostile unit is close enough to [building], in real travel
  /// time, to count as an immediate threat — see the class doc for why this
  /// checks actual in-flight units rather than building proximity.
  bool _isUnderThreat(Building building, AIDecisionContext context) {
    for (final unit in context.hostileUnits) {
      // Match by destination: `targetPosition` is set from the target
      // building's own position when a unit is sent (see
      // TowerConquestGame.sendUnit), and buildings don't move, so this
      // reliably identifies which building a unit is actually heading for.
      final headingHere =
          unit.targetPosition.distanceToSquared(building.position) < 1.0;
      if (!headingHere) continue;

      final remaining = travelTimeSeconds(
        unit.position.distanceTo(unit.targetPosition),
        unit.speed,
      );
      if (remaining <= threatThresholdSeconds) return true;
    }
    return false;
  }
}
