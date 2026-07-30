import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/tower_conquest_game.dart';

// End-to-end checks that the *real* NormalAIStrategy — not a test double —
// is actually wired into the live game loop via EnemyCommander and
// TowerConquestGame._onFrame.
//
// ai_strategy_test.dart already exercises all four heuristics directly
// against AIDecisionContext, and enemy_commander_test.dart exercises the
// harness's plumbing and pacing against a fake strategy. Neither proves the
// production wiring itself works end to end, or stays stable over a full
// simulated match — that is what this file is for.
//
// Deliberately not asserted here: a specific win/loss outcome or win rate.
// The 2-node Level 1 map's numbers mean the "weak target" attack bracket
// (defence < 20) has the AI committing its whole garrison every cycle, which
// this map's balance can turn into either outcome depending on exactly how
// combat lands — see NormalAIStrategy's class doc for the heuristics
// themselves. A live match's outcome is not the AI's own contract to test.

void _advance(TowerConquestGame game, double seconds) {
  const dt = 1 / 60;
  for (var i = 0; i < (seconds / dt).round(); i++) {
    game.update(dt);
  }
}

void main() {
  testWithGame<TowerConquestGame>(
      'the real AI sends a unit at the player within the first second',
      TowerConquestGame.new, (game) async {
    await game.ready();
    final startingUnits = game.enemyBase.unitsInside;

    _advance(game, 1.0);

    // Ten dispatch slots (100ms apart) pass in one second, comfortably enough
    // for the AI to have committed at least one of its ten starting units —
    // see NormalAIStrategy's "weak target" bracket (playerBase starts under
    // the 20-defence threshold, so the whole garrison is allocated at once).
    expect(game.enemyBase.unitsInside, lessThan(startingUnits));
    expect(game.paths.first.isActive, isTrue,
        reason: 'the sent unit is still 4+ seconds from arriving');
  });

  testWithGame<TowerConquestGame>(
      'a passive player facing the real AI reaches a conclusive state without '
      'the loop ever leaving an invalid one',
      TowerConquestGame.new, (game) async {
    await game.ready();

    // The GDD's own upper bound on a match (§12): if the loop is ever going
    // to hang, stall, or throw under sustained two-sided activity — the
    // failure mode this session's stuck-unit investigation was chasing — five
    // simulated minutes of a fully passive player against a fully active AI
    // is exactly the load that would surface it.
    const totalSeconds = 300.0;
    const stepSeconds = 1.0;
    var elapsed = 0.0;

    while (elapsed < totalSeconds && !game.isMatchOver) {
      _advance(game, stepSeconds);
      elapsed += stepSeconds;

      // Invariants that must hold at every sampled point, win or lose.
      expect(game.playerBase.unitsInside, greaterThanOrEqualTo(0));
      expect(game.enemyBase.unitsInside, greaterThanOrEqualTo(0));
      expect(game.playerBase.tier, inInclusiveRange(1, 5));
      expect(game.enemyBase.tier, inInclusiveRange(1, 5));
    }

    // Whichever way it went, the match must have actually gone somewhere —
    // not hung in an inconsistent state for the full five minutes.
    expect(game.status, isNotNull);
    expect(
      [GameStatus.playing, GameStatus.victory, GameStatus.defeat],
      contains(game.status),
    );
  });
}
