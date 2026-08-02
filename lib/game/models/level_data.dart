import 'package:flame/components.dart';

import '../constants/balance.dart';

/// Building archetypes a level's nodes may declare.
///
/// Deliberately a `Set<String>`, not an enum — [Building.type] and
/// [Building.faction] are `String` throughout the codebase and all existing
/// tests, and introducing enums here would mean introducing them everywhere
/// (see `orchestrator/PHASE3_ARCHITECTURE_AUDIT.md`, Finding 1).
const Set<String> validBuildingTypes = {
  'barracks',
  'tower',
  'factory',
  'command_center',
};

/// Factions a level's nodes may declare.
const Set<String> validFactions = {'player', 'enemy', 'neutral'};

/// Win conditions Stage 1 knows how to run. Anything else is rejected at load
/// time rather than silently accepted and ignored.
const Set<String> supportedWinConditions = {'capture_all_enemy_nodes'};

/// Thrown when a level's JSON is well-formed but violates a schema rule —
/// a duplicate node ID, an unknown building type, an out-of-bounds position,
/// and so on. Kept distinct from [FormatException] (raised by `jsonDecode`
/// itself for malformed JSON) so callers can tell "not JSON" apart from
/// "valid JSON, invalid level" if they ever need to.
class LevelValidationException implements Exception {
  final String message;

  LevelValidationException(this.message);

  @override
  String toString() => 'LevelValidationException: $message';
}

/// One node authored in a level: a building's type, owner, starting position,
/// tier, and garrison.
///
/// Carries its own authored [id] because [Building] has none — see
/// `orchestrator/PHASE3_DEVELOPER_PROMPT.md` §6. The ID exists purely so a
/// level's [LinkData] entries can reference nodes by name; nothing downstream
/// of loading ever looks a node up by this ID again once its [Building] is
/// built.
class NodeData {
  final String id;
  final String type;
  final String faction;
  final Vector2 position;
  final int tier;
  final int unitsInside;

  NodeData({
    required this.id,
    required this.type,
    required this.faction,
    required this.position,
    required this.tier,
    required this.unitsInside,
  });

  factory NodeData.fromJson(Map<String, dynamic> json) {
    final positionJson = json['position'] as Map<String, dynamic>;
    return NodeData(
      id: json['id'] as String,
      type: json['type'] as String,
      faction: json['faction'] as String,
      position: Vector2(
        (positionJson['x'] as num).toDouble(),
        (positionJson['y'] as num).toDouble(),
      ),
      tier: json['tier'] as int,
      unitsInside: json['unitsInside'] as int,
    );
  }
}

/// An authored route between two nodes, referenced by [NodeData.id].
///
/// Resolved into a [PathLink] only after the whole level has validated —
/// see `LevelRuntimeFactory.linksFor`.
class LinkData {
  final String from;
  final String to;

  LinkData({required this.from, required this.to});

  factory LinkData.fromJson(Map<String, dynamic> json) {
    return LinkData(from: json['from'] as String, to: json['to'] as String);
  }

  /// The link's endpoints as an order-independent pair, so `A->B` and `B->A`
  /// compare equal for duplicate-link detection.
  Set<String> get _unorderedPair => {from, to};
}

/// A level's reward payout. Parsed and carried as plain data in Stage 1 —
/// nothing yet spends it into persistent currency (that is meta-progression,
/// deferred to a later Phase 3 stage).
class LevelRewards {
  final int gold;
  final int gems;
  final int experience;

  const LevelRewards({this.gold = 0, this.gems = 0, this.experience = 0});

  factory LevelRewards.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LevelRewards();
    return LevelRewards(
      gold: json['gold'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      experience: json['experience'] as int? ?? 0,
    );
  }
}

/// A fully parsed, validated, immutable level definition.
///
/// The only way to obtain one is through the [LevelData.new] factory or
/// [LevelData.fromJson], both of which run the same [_validate] pass — so a
/// `LevelData` in hand is always schema-valid, whether it came from a JSON
/// asset or was constructed directly (as [LevelManager.defaultLevel] does).
class LevelData {
  final String id;
  final String name;
  final int campaign;
  final int levelNumber;
  final String description;
  final String difficulty;
  final double width;
  final double height;
  final List<NodeData> nodes;
  final List<LinkData> links;
  final String winCondition;
  final int? timeLimitSeconds;
  final LevelRewards rewards;

  LevelData._({
    required this.id,
    required this.name,
    required this.campaign,
    required this.levelNumber,
    required this.description,
    required this.difficulty,
    required this.width,
    required this.height,
    required this.nodes,
    required this.links,
    required this.winCondition,
    required this.timeLimitSeconds,
    required this.rewards,
  });

  factory LevelData({
    required String id,
    required String name,
    required int campaign,
    required int levelNumber,
    required String description,
    required String difficulty,
    required double width,
    required double height,
    required List<NodeData> nodes,
    required List<LinkData> links,
    required String winCondition,
    required int? timeLimitSeconds,
    required LevelRewards rewards,
  }) {
    final level = LevelData._(
      id: id,
      name: name,
      campaign: campaign,
      levelNumber: levelNumber,
      description: description,
      difficulty: difficulty,
      width: width,
      height: height,
      nodes: List.unmodifiable(nodes),
      links: List.unmodifiable(links),
      winCondition: winCondition,
      timeLimitSeconds: timeLimitSeconds,
      rewards: rewards,
    );
    _validate(level);
    return level;
  }

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      id: json['id'] as String,
      name: json['name'] as String,
      campaign: json['campaign'] as int,
      levelNumber: json['levelNumber'] as int,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      nodes: (json['nodes'] as List)
          .map((n) => NodeData.fromJson(n as Map<String, dynamic>))
          .toList(),
      links: (json['links'] as List? ?? [])
          .map((l) => LinkData.fromJson(l as Map<String, dynamic>))
          .toList(),
      winCondition: json['winCondition'] as String,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      rewards: LevelRewards.fromJson(json['rewards'] as Map<String, dynamic>?),
    );
  }

  static void _validate(LevelData level) {
    Never fail(String message) => throw LevelValidationException(message);

    if (level.id.isEmpty) fail('id must not be empty');
    if (level.name.isEmpty) fail('name must not be empty');
    if (level.campaign <= 0) fail('campaign must be a positive integer');
    if (level.levelNumber <= 0) {
      fail('levelNumber must be a positive integer');
    }
    if (!{'easy', 'normal', 'hard'}.contains(level.difficulty)) {
      fail('difficulty must be one of easy, normal, hard: '
          '${level.difficulty}');
    }
    if (level.width <= 0) fail('width must be positive');
    if (level.height <= 0) fail('height must be positive');
    if (!supportedWinConditions.contains(level.winCondition)) {
      fail('unsupported winCondition: ${level.winCondition}');
    }
    if (level.timeLimitSeconds != null && level.timeLimitSeconds! <= 0) {
      fail('timeLimitSeconds must be a positive integer or null');
    }

    _validateNodes(level, fail);
    _validateLinks(level, fail);
  }

  static void _validateNodes(LevelData level, Never Function(String) fail) {
    if (level.nodes.isEmpty) fail('a level must declare at least one node');

    final seenIds = <String>{};
    for (final node in level.nodes) {
      if (!seenIds.add(node.id)) {
        fail('duplicate node id: ${node.id}');
      }
      if (!validBuildingTypes.contains(node.type)) {
        fail('unknown building type on node ${node.id}: ${node.type}');
      }
      if (!validFactions.contains(node.faction)) {
        fail('unknown faction on node ${node.id}: ${node.faction}');
      }
      if (node.position.x.abs() > level.width / 2 ||
          node.position.y.abs() > level.height / 2) {
        fail('node ${node.id} position lies outside the declared map bounds');
      }
      if (node.tier != 1) {
        fail('node ${node.id} must be tier 1 in Stage 1: ${node.tier}');
      }
      if (node.unitsInside < 0) {
        fail('node ${node.id} unitsInside must not be negative');
      }

      final stats = BuildingBalance.baseStatsFor(node.type);
      if (stats != null && node.unitsInside > stats.capacity) {
        fail('node ${node.id} unitsInside (${node.unitsInside}) exceeds its '
            'Tier 1 capacity (${stats.capacity})');
      }
    }

    final hasPlayer = level.nodes.any((n) => n.faction == 'player');
    final hasEnemy = level.nodes.any((n) => n.faction == 'enemy');
    if (!hasPlayer || !hasEnemy) {
      fail('a level must have at least one player and one enemy node');
    }
  }

  static void _validateLinks(LevelData level, Never Function(String) fail) {
    final nodeIds = level.nodes.map((n) => n.id).toSet();
    final seenPairs = <Set<String>>[];

    for (final link in level.links) {
      if (!nodeIds.contains(link.from)) {
        fail('link references unknown node: ${link.from}');
      }
      if (!nodeIds.contains(link.to)) {
        fail('link references unknown node: ${link.to}');
      }
      if (link.from == link.to) {
        fail('a node cannot link to itself: ${link.from}');
      }

      final pair = link._unorderedPair;
      if (seenPairs.any((seen) =>
          seen.difference(pair).isEmpty && pair.difference(seen).isEmpty)) {
        fail('duplicate link between ${link.from} and ${link.to}');
      }
      seenPairs.add(pair);
    }
  }
}
