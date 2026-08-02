import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/level_data.dart';

/// Loads level JSON from `assets/levels/`, validates it, and caches the
/// result.
///
/// Mirrors `AssetManager`'s shape (a lazily-initialised singleton with a
/// small in-memory cache) rather than inventing a new pattern for the same
/// kind of problem.
class LevelManager {
  static final LevelManager _instance = LevelManager._internal();

  factory LevelManager() => _instance;

  LevelManager._internal();

  /// The level Stage 1 loads by default — the JSON equivalent of the
  /// pre-Phase-3 hard-coded two-node Barracks match.
  static const String defaultLevelId = 'campaign_1_level_1';

  final Map<String, LevelData> _cache = {};

  /// Loads and validates the level asset named [levelId], from
  /// `assets/levels/$levelId.json`. Throws [FormatException] for malformed
  /// JSON (via `jsonDecode`) or [LevelValidationException] for well-formed
  /// JSON that violates the level schema — neither is swallowed here, so
  /// authoring mistakes stay visible. See [loadOrFallback] for a path that
  /// tolerates failure.
  Future<LevelData> loadLevel(String levelId) async {
    final cached = _cache[levelId];
    if (cached != null) return cached;

    final jsonString =
        await rootBundle.loadString('assets/levels/$levelId.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final level = LevelData.fromJson(json);

    _cache[levelId] = level;
    return level;
  }

  /// [loadLevel], but falls back to [defaultLevel] for any failure —
  /// missing asset, malformed JSON, or a schema violation. Intended for the
  /// game's actual boot path, where a bad level must not take the whole game
  /// down; use [loadLevel] directly wherever an authoring error should
  /// surface instead (tests, a future level-editor tool).
  Future<LevelData> loadOrFallback(String levelId) async {
    try {
      return await loadLevel(levelId);
    } catch (_) {
      return defaultLevel();
    }
  }

  /// A known-safe, hard-coded two-node Barracks match — the same layout the
  /// pre-Phase-3 game built directly. Constructed in Dart rather than read
  /// from `assets/levels/`, so it stays available even if that asset is
  /// missing or corrupted; it still runs through [LevelData]'s own
  /// validation (via the [LevelData.new] factory), so it is held to the same
  /// schema as any authored level.
  LevelData defaultLevel() {
    return LevelData(
      id: defaultLevelId,
      name: 'First Contact',
      campaign: 1,
      levelNumber: 1,
      description:
          'Capture the opposing command position in a simple two-node match.',
      difficulty: 'normal',
      width: 800,
      height: 600,
      nodes: [
        NodeData(
          id: 'player_base',
          type: 'barracks',
          faction: 'player',
          position: Vector2(0, 220),
          tier: 1,
          unitsInside: 10,
        ),
        NodeData(
          id: 'enemy_base',
          type: 'barracks',
          faction: 'enemy',
          position: Vector2(0, -220),
          tier: 1,
          unitsInside: 10,
        ),
      ],
      links: [LinkData(from: 'player_base', to: 'enemy_base')],
      winCondition: 'capture_all_enemy_nodes',
      timeLimitSeconds: null,
      rewards: const LevelRewards(),
    );
  }

  /// Drops every cached level. Intended for tests.
  void reset() => _cache.clear();
}
