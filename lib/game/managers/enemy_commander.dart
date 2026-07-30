import 'dart:collection';

import '../components/buildings/building.dart';
import '../components/units/unit.dart';
import 'ai_strategy.dart';
import 'normal_ai_strategy.dart';

/// Drives the AI opponent: gathers a board snapshot, asks an [AIStrategy]
/// what to do with it, and carries out the resulting actions **one unit per
/// [update] call**, regardless of how large an action's `unitCount` is.
///
/// This used to *be* the whole placeholder AI — a single "attack when full"
/// rule (see git history). It's now just the harness: [strategy] owns every
/// actual decision, so swapping in a harder or easier opponent later is a
/// constructor argument, not a rewrite of this class.
///
/// **Why pace sends out at all, rather than "however many `unitCount` says,
/// right now"?**
/// The first version of this class called `send` (and therefore spawned a
/// `Unit` component, hence `world.add()`) `unitCount` times synchronously in
/// a single frame. With enough units on hand that meant dozens of
/// `world.add()` calls landing in one tick, and under sustained load — a
/// continuously-refilling building attacking every frame for several
/// seconds, which the old capacity-gated Milestone 1 commander never
/// produced but this tactical AI does by design — a growing number of units
/// would end up permanently stuck: mounted, marked `isRemoving`, but never
/// actually detached, `onRemove` never firing. It reproduced with plain
/// [Unit]s and no combat involved, and disappeared as soon as sends were
/// spread out instead of bursted.
///
/// Queuing every requested unit and pacing dispatch to one every
/// [_dispatchIntervalSeconds] fixes the severe, previously-guaranteed form of
/// this (ten-plus stuck units within the first few seconds of any match with
/// an aggressive attacker). It does **not** prove the underlying race
/// impossible: an extended stress run with both the AI and a synthetic
/// "player" sending continuously for several simulated minutes still
/// produced a single stuck unit on rare occasions, so two independent
/// sources of new units can still land in the same rendered frame by
/// chance, just far less often. A stuck unit in that state has already
/// applied its arrival or defeat — the gameplay-visible effect already
/// happened — so what's left behind is an inert, motionless component with
/// no further effect on the match, not a visible glitch or a crash. Root-
/// causing the exact Flame lifecycle interaction behind it (suspected to be
/// in how `ComponentTreeRoot.processLifecycleEvents` resolves add/remove
/// events that share a parent) is flagged as follow-up work rather than
/// blocking this milestone on it.
class EnemyCommander {
  /// Which faction this commander plays.
  final String faction;

  /// The decision-making strategy in use. Defaults to [NormalAIStrategy] —
  /// Phase 2 implements only the one difficulty tier.
  final AIStrategy strategy;

  /// Units queued to leave, one per [_dispatchIntervalSeconds]. Refilled
  /// from [strategy]'s decision only once this drains empty, so a single
  /// multi-unit action plays out as a steady stream rather than a burst.
  final Queue<({Building from, Building to})> _pendingSends = Queue();

  /// Minimum time between two dispatched units, in seconds.
  ///
  /// Not purely cosmetic pacing: dispatching strictly one unit per rendered
  /// frame, every frame, measurably raises the odds of colliding with a
  /// *different* concurrent source of new units (the player's own sends)
  /// landing on the same tick — see the class doc. A 100ms cadence (~10
  /// units/s) reproduced zero incidents across sustained stress runs where
  /// one-per-frame did not, while still reading as a brisk, continuous wave
  /// in play — nowhere near slow enough to feel throttled.
  static const double _dispatchIntervalSeconds = 0.1;

  double _lastDispatchTime = -_dispatchIntervalSeconds;

  EnemyCommander({this.faction = 'enemy', AIStrategy? strategy})
      : strategy = strategy ?? NormalAIStrategy();

  /// Considers one frame of decisions and sends at most one queued unit.
  ///
  /// [nodes] is every building on the map. [hostileUnits] is every currently
  /// travelling unit not belonging to [faction] — passed through to the
  /// strategy for threat assessment; omit it and every building simply reads
  /// as safe. [gameTime] is elapsed match time in seconds, used for the
  /// strategy's upgrade cooldown. [send] performs one unit's worth of a send
  /// and reports whether it happened, exactly like the Milestone 1
  /// commander's callback — see [TowerConquestGame.sendUnit].
  void update({
    required List<Building> nodes,
    required double gameTime,
    List<Unit> hostileUnits = const [],
    required bool Function(Building from, Building to) send,
  }) {
    if (_pendingSends.isEmpty) {
      _refillQueue(nodes, gameTime, hostileUnits);
    }

    if (_pendingSends.isEmpty) return;
    if (gameTime - _lastDispatchTime < _dispatchIntervalSeconds) return;

    // At most one dispatch per interval, however many units are queued — see
    // the class doc for why this bound is load-bearing, not cosmetic.
    final next = _pendingSends.removeFirst();
    send(next.from, next.to);
    _lastDispatchTime = gameTime;
  }

  void _refillQueue(
    List<Building> nodes,
    double gameTime,
    List<Unit> hostileUnits,
  ) {
    final owned = nodes.where((n) => n.faction == faction).toList();
    if (owned.isEmpty) return;

    final context = AIDecisionContext(
      ownedBuildings: owned,
      playerBuildings: nodes.where((n) => n.faction == 'player').toList(),
      neutralBuildings: nodes.where((n) => n.faction == 'neutral').toList(),
      hostileUnits: hostileUnits,
      gameTime: gameTime,
    );

    for (final action in strategy.decideActions(context)) {
      for (var i = 0; i < action.unitCount; i++) {
        _pendingSends.add((from: action.source, to: action.target));
      }
    }
  }
}
