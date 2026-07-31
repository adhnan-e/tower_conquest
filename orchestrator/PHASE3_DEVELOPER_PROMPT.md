# Phase 3 Developer Prompt: Level Design & Campaign Structure

**Milestone:** Phase 3 – Level Design & Campaign Progression  
**Duration:** 4–8 weeks  
**Scope:** 30+ playable levels organized into 4 campaigns with progressive difficulty, meta-progression system, and level editor infrastructure.

---

## Overview

Phase 3 transforms Tower Conquest from a single-match game into a full campaign experience. This phase introduces:

1. **Level Definition System** – A declarative format for defining map layouts, node positions, building types, obstacles, and difficulty parameters.
2. **Campaign Structure** – Four campaigns (30+ levels) with increasing complexity and difficulty.
3. **Meta-Progression** – Persistent currency (Gold), research trees, and permanent upgrades earned across levels.
4. **Level Editor Infrastructure** – Tools for orchestrator to design and validate levels without modifying code.
5. **Difficulty Scaling** – AI difficulty, unit generation rates, and map complexity scale with campaign progression.

---

## Phase 2 Recap: Current State

Before starting Phase 3, understand what Phase 2 delivered:

- **Building Upgrade System:** Tier 1–5 progression with cost/bonus tables.
- **Tier-Aware Sprites:** 32 PNG assets (Tier 2–5 variants) with automatic fallback.
- **Tactical AI:** NormalAIStrategy with target selection, unit allocation, and threat assessment.
- **Building Info Panel:** In-match UI for tier display, garrison count, and upgrades.
- **Test Coverage:** 220 passing tests, all quality gates clean.

**Current Limitation:** The game runs on a single hard-coded 2-node map (Player Command Center vs. Enemy Command Center). Phase 3 removes this limitation.

---

## System 1: Level Definition & Loading

### 1.1 Level Data Format

Levels are defined in a declarative JSON format stored in `assets/levels/` directory. Each level file follows this structure:

```json
{
  "id": "campaign_1_level_1",
  "name": "First Contact",
  "campaign": 1,
  "levelNumber": 1,
  "description": "Capture the enemy's command center in this simple 1v1 matchup.",
  "difficulty": "easy",
  "width": 800,
  "height": 600,
  "nodes": [
    {
      "id": "player_cc",
      "type": "command_center",
      "faction": "player",
      "position": { "x": 100, "y": 300 },
      "tier": 1
    },
    {
      "id": "enemy_cc",
      "type": "command_center",
      "faction": "enemy",
      "position": { "x": 700, "y": 300 },
      "tier": 1
    }
  ],
  "obstacles": [],
  "hazards": [],
  "winCondition": "capture_all_enemy_nodes",
  "timeLimit": null,
  "rewards": {
    "gold": 100,
    "gems": 0,
    "experience": 50
  }
}
```

### 1.2 Level Loader Implementation

Create a `LevelManager` class that:

- Loads level JSON files from `assets/levels/`
- Parses node definitions and instantiates Building components
- Validates level integrity (no duplicate node IDs, valid factions, etc.)
- Caches loaded levels in memory
- Provides fallback to a default 2-node map if a level fails to load

```dart
class LevelManager {
  static final LevelManager _instance = LevelManager._internal();
  
  factory LevelManager() => _instance;
  LevelManager._internal();
  
  final Map<String, LevelData> _levelCache = {};
  
  Future<LevelData> loadLevel(String levelId) async {
    if (_levelCache.containsKey(levelId)) {
      return _levelCache[levelId]!;
    }
    
    final jsonString = await Flame.bundle.loadString('assets/levels/$levelId.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final level = LevelData.fromJson(json);
    
    _validateLevel(level);
    _levelCache[levelId] = level;
    return level;
  }
  
  void _validateLevel(LevelData level) {
    // Validate node IDs are unique
    final nodeIds = level.nodes.map((n) => n.id).toSet();
    if (nodeIds.length != level.nodes.length) {
      throw Exception('Duplicate node IDs in level ${level.id}');
    }
    
    // Validate at least one player and one enemy node
    final playerNodes = level.nodes.where((n) => n.faction == Faction.player).length;
    final enemyNodes = level.nodes.where((n) => n.faction == Faction.enemy).length;
    if (playerNodes == 0 || enemyNodes == 0) {
      throw Exception('Level must have at least one player and one enemy node');
    }
  }
  
  LevelData getDefaultLevel() {
    // Return a 2-node fallback map
    return LevelData(
      id: 'default',
      name: 'Default Match',
      campaign: 0,
      levelNumber: 0,
      description: 'A simple 1v1 match',
      difficulty: 'normal',
      width: 800,
      height: 600,
      nodes: [
        NodeData(id: 'player_cc', type: BuildingType.commandCenter, faction: Faction.player, position: Vector2(100, 300), tier: 1),
        NodeData(id: 'enemy_cc', type: BuildingType.commandCenter, faction: Faction.enemy, position: Vector2(700, 300), tier: 1),
      ],
      obstacles: [],
      hazards: [],
      winCondition: 'capture_all_enemy_nodes',
      timeLimit: null,
      rewards: LevelRewards(gold: 0, gems: 0, experience: 0),
    );
  }
}
```

### 1.3 Level Data Classes

Define the following data classes in `lib/game/models/level_data.dart`:

```dart
class LevelData {
  final String id;
  final String name;
  final int campaign;
  final int levelNumber;
  final String description;
  final String difficulty; // 'easy', 'normal', 'hard'
  final double width;
  final double height;
  final List<NodeData> nodes;
  final List<ObstacleData> obstacles;
  final List<HazardData> hazards;
  final String winCondition;
  final int? timeLimit; // in seconds, null if no limit
  final LevelRewards rewards;
  
  LevelData({
    required this.id,
    required this.name,
    required this.campaign,
    required this.levelNumber,
    required this.description,
    required this.difficulty,
    required this.width,
    required this.height,
    required this.nodes,
    required this.obstacles,
    required this.hazards,
    required this.winCondition,
    required this.timeLimit,
    required this.rewards,
  });
  
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
      nodes: (json['nodes'] as List).map((n) => NodeData.fromJson(n as Map<String, dynamic>)).toList(),
      obstacles: (json['obstacles'] as List?)?.map((o) => ObstacleData.fromJson(o as Map<String, dynamic>)).toList() ?? [],
      hazards: (json['hazards'] as List?)?.map((h) => HazardData.fromJson(h as Map<String, dynamic>)).toList() ?? [],
      winCondition: json['winCondition'] as String,
      timeLimit: json['timeLimit'] as int?,
      rewards: LevelRewards.fromJson(json['rewards'] as Map<String, dynamic>),
    );
  }
}

class NodeData {
  final String id;
  final BuildingType type;
  final Faction faction;
  final Vector2 position;
  final int tier;
  
  NodeData({
    required this.id,
    required this.type,
    required this.faction,
    required this.position,
    required this.tier,
  });
  
  factory NodeData.fromJson(Map<String, dynamic> json) {
    return NodeData(
      id: json['id'] as String,
      type: BuildingType.values.byName(json['type'] as String),
      faction: Faction.values.byName(json['faction'] as String),
      position: Vector2((json['position']['x'] as num).toDouble(), (json['position']['y'] as num).toDouble()),
      tier: json['tier'] as int? ?? 1,
    );
  }
}

class LevelRewards {
  final int gold;
  final int gems;
  final int experience;
  
  LevelRewards({
    required this.gold,
    required this.gems,
    required this.experience,
  });
  
  factory LevelRewards.fromJson(Map<String, dynamic> json) {
    return LevelRewards(
      gold: json['gold'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      experience: json['experience'] as int? ?? 0,
    );
  }
}

// Placeholder classes for Phase 3 expansion
class ObstacleData {
  final String id;
  final String type; // 'wall', 'rock', etc.
  final Vector2 position;
  final double width;
  final double height;
  
  ObstacleData({
    required this.id,
    required this.type,
    required this.position,
    required this.width,
    required this.height,
  });
  
  factory ObstacleData.fromJson(Map<String, dynamic> json) {
    return ObstacleData(
      id: json['id'] as String,
      type: json['type'] as String,
      position: Vector2((json['position']['x'] as num).toDouble(), (json['position']['y'] as num).toDouble()),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}

class HazardData {
  final String id;
  final String type; // 'mine', 'spike', etc.
  final Vector2 position;
  final double radius;
  final int damage;
  
  HazardData({
    required this.id,
    required this.type,
    required this.position,
    required this.radius,
    required this.damage,
  });
  
  factory HazardData.fromJson(Map<String, dynamic> json) {
    return HazardData(
      id: json['id'] as String,
      type: json['type'] as String,
      position: Vector2((json['position']['x'] as num).toDouble(), (json['position']['y'] as num).toDouble()),
      radius: (json['radius'] as num).toDouble(),
      damage: json['damage'] as int? ?? 0,
    );
  }
}
```

---

## System 2: Campaign & Level Progression

### 2.1 Campaign Structure

Organize levels into four campaigns with increasing difficulty:

| Campaign | Levels | Focus | Difficulty |
| :--- | :--- | :--- | :--- |
| **Campaign 1: Basics** | 1–5 | Tutorial, 1v1 matches, unit movement | Easy |
| **Campaign 2: Multi-Node** | 6–15 | 2–3 node maps, neutral nodes, upgrades | Normal |
| **Campaign 3: Advanced** | 16–25 | 4–5 node maps, obstacles, hazards | Hard |
| **Campaign 4: Endgame** | 26–30 | Complex 6+ node maps, multiple threats | Very Hard |

### 2.2 Campaign Manager

Create a `CampaignManager` class that tracks player progress:

```dart
class CampaignManager {
  static final CampaignManager _instance = CampaignManager._internal();
  
  factory CampaignManager() => _instance;
  CampaignManager._internal();
  
  final List<CampaignData> campaigns = [];
  int currentCampaign = 1;
  int currentLevel = 1;
  
  Future<void> initialize() async {
    // Load all level definitions
    campaigns.add(CampaignData(
      id: 1,
      name: 'Basics',
      description: 'Learn the fundamentals of Tower Conquest',
      levels: ['campaign_1_level_1', 'campaign_1_level_2', 'campaign_1_level_3', 'campaign_1_level_4', 'campaign_1_level_5'],
    ));
    // ... load other campaigns
  }
  
  Future<LevelData> getCurrentLevel() async {
    final levelId = campaigns[currentCampaign - 1].levels[currentLevel - 1];
    return LevelManager().loadLevel(levelId);
  }
  
  void completeLevel(LevelRewards rewards) {
    // Award gold, gems, experience
    // Unlock next level
    // Save progress to persistent storage
  }
}

class CampaignData {
  final int id;
  final String name;
  final String description;
  final List<String> levels;
  
  CampaignData({
    required this.id,
    required this.name,
    required this.description,
    required this.levels,
  });
}
```

---

## System 3: Meta-Progression

### 3.1 Player Progress Tracking

Create a `PlayerProgress` class that persists across sessions:

```dart
class PlayerProgress {
  int totalGold = 0;
  int totalGems = 0;
  int totalExperience = 0;
  
  int currentCampaign = 1;
  int currentLevel = 1;
  
  Map<String, bool> completedLevels = {}; // levelId -> completed
  Map<String, int> levelBestTime = {}; // levelId -> time in seconds
  
  // Research tree unlocks
  Set<String> unlockedResearch = {};
  
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalGold', totalGold);
    await prefs.setInt('totalGems', totalGems);
    await prefs.setInt('totalExperience', totalExperience);
    // ... save other fields
  }
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    totalGold = prefs.getInt('totalGold') ?? 0;
    totalGems = prefs.getInt('totalGems') ?? 0;
    totalExperience = prefs.getInt('totalExperience') ?? 0;
    // ... load other fields
  }
}
```

### 3.2 Research Tree

Define permanent upgrades that players can unlock with Gold:

```dart
class ResearchTree {
  static final Map<String, ResearchNode> nodes = {
    'logistics': ResearchNode(
      id: 'logistics',
      name: 'Logistics',
      description: '+5% unit movement speed',
      cost: 100,
      effect: () => gameState.unitSpeedMultiplier *= 1.05,
    ),
    'fortification': ResearchNode(
      id: 'fortification',
      name: 'Fortification',
      description: '+0.1x defense multiplier for all towers',
      cost: 150,
      effect: () => gameState.defenseMultiplier += 0.1,
    ),
    'recruitment': ResearchNode(
      id: 'recruitment',
      name: 'Recruitment',
      description: '-5% building upgrade cost',
      cost: 200,
      effect: () => gameState.upgradeCostMultiplier *= 0.95,
    ),
  };
  
  static void unlockResearch(String researchId) {
    final node = nodes[researchId];
    if (node != null && node.cost <= playerProgress.totalGold) {
      playerProgress.totalGold -= node.cost;
      playerProgress.unlockedResearch.add(researchId);
      node.effect();
    }
  }
}

class ResearchNode {
  final String id;
  final String name;
  final String description;
  final int cost;
  final Function() effect;
  
  ResearchNode({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effect,
  });
}
```

---

## System 4: Game Initialization with Levels

### 4.1 Modify TowerConquestGame to Load Levels

Update the `TowerConquestGame` class to load levels instead of hard-coding the 2-node map:

```dart
class TowerConquestGame extends FlameGame with HasCollisionDetection {
  late LevelData currentLevel;
  late LevelManager levelManager;
  late CampaignManager campaignManager;
  late PlayerProgress playerProgress;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize managers
    levelManager = LevelManager();
    campaignManager = CampaignManager();
    playerProgress = PlayerProgress();
    
    await playerProgress.load();
    await campaignManager.initialize();
    
    // Load the current level
    currentLevel = await campaignManager.getCurrentLevel();
    
    // Create buildings from level data
    for (final nodeData in currentLevel.nodes) {
      final building = Building(
        id: nodeData.id,
        type: nodeData.type,
        faction: nodeData.faction,
        position: nodeData.position,
        tier: nodeData.tier,
      );
      add(building);
    }
    
    // Initialize AI with the current level
    enemyCommander = EnemyCommander(
      difficulty: currentLevel.difficulty,
      targetNodes: currentLevel.nodes.where((n) => n.faction == Faction.player).toList(),
    );
  }
  
  void completeLevel(bool victory) {
    if (victory) {
      final rewards = currentLevel.rewards;
      playerProgress.totalGold += rewards.gold;
      playerProgress.totalGems += rewards.gems;
      playerProgress.totalExperience += rewards.experience;
      playerProgress.completedLevels[currentLevel.id] = true;
      playerProgress.save();
      
      // Show victory screen with rewards
      showVictoryScreen(rewards);
    } else {
      // Show defeat screen with retry option
      showDefeatScreen();
    }
  }
}
```

---

## System 5: Level Editor Infrastructure

### 5.1 Level Editor Workflow

The orchestrator (you) will use a simple JSON editor to create levels. The developer provides:

1. **Level JSON Template** – A starter template with all required fields.
2. **Level Validator** – A command-line tool to validate level JSON files.
3. **Level Preview Tool** – A simple debug screen that renders a level without playing it.

### 5.2 Level Validator

Create a `tools/validate_level.dart` script:

```dart
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart validate_level.dart <level_file.json>');
    exit(1);
  }
  
  final file = File(args[0]);
  if (!file.existsSync()) {
    print('Error: File not found: ${args[0]}');
    exit(1);
  }
  
  try {
    final json = jsonDecode(file.readAsStringSync());
    
    // Validate required fields
    final requiredFields = ['id', 'name', 'campaign', 'levelNumber', 'nodes', 'rewards'];
    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        print('Error: Missing required field: $field');
        exit(1);
      }
    }
    
    // Validate nodes
    final nodes = json['nodes'] as List;
    if (nodes.isEmpty) {
      print('Error: Level must have at least one node');
      exit(1);
    }
    
    final nodeIds = <String>{};
    for (final node in nodes) {
      if (nodeIds.contains(node['id'])) {
        print('Error: Duplicate node ID: ${node['id']}');
        exit(1);
      }
      nodeIds.add(node['id'] as String);
    }
    
    print('✓ Level validation passed: ${json['id']}');
  } catch (e) {
    print('Error: Invalid JSON: $e');
    exit(1);
  }
}
```

---

## Implementation Stages

### Stage 1: Level Definition & Loading (Week 1–2)

- Implement `LevelData`, `NodeData`, and related classes.
- Implement `LevelManager` with JSON loading and validation.
- Create 5 Campaign 1 level JSON files.
- Update `TowerConquestGame` to load levels dynamically.
- Add tests for level loading and validation.

**Acceptance Criteria:**
- ✅ `LevelManager.loadLevel()` successfully loads and parses JSON files.
- ✅ Level validation catches duplicate node IDs and missing factions.
- ✅ Game boots with Campaign 1 Level 1 loaded.
- ✅ All 5 Campaign 1 levels load without errors.

### Stage 2: Campaign & Meta-Progression (Week 2–3)

- Implement `CampaignManager` and `PlayerProgress`.
- Implement persistent storage via `SharedPreferences`.
- Implement `ResearchTree` and research unlocks.
- Create Campaign 2–4 level JSON files (25 total).
- Add level completion tracking and reward distribution.

**Acceptance Criteria:**
- ✅ `CampaignManager` tracks current campaign and level.
- ✅ Completing a level awards Gold, Gems, and Experience.
- ✅ Research unlocks persist across app restarts.
- ✅ All 30 levels load without errors.

### Stage 3: Level Editor Infrastructure & Testing (Week 3–4)

- Create level JSON template and validator tool.
- Add level preview debug screen (optional).
- Write 20+ tests covering level loading, validation, and progression.
- Ensure all quality gates pass (format, analysis, tests, release build).

**Acceptance Criteria:**
- ✅ `tools/validate_level.dart` validates all 30 level JSON files.
- ✅ 40–50 new tests cover level loading, campaign progression, and meta-progression.
- ✅ All 220+ existing tests still pass.
- ✅ `dart format`, `flutter analyze`, `flutter test`, `flutter build web --release` all pass.

---

## Testing Strategy

### Unit Tests

- Test `LevelManager.loadLevel()` with valid and invalid JSON.
- Test `LevelData.fromJson()` with edge cases (missing fields, invalid types).
- Test `CampaignManager` level progression and campaign transitions.
- Test `PlayerProgress` save/load with `SharedPreferences`.
- Test `ResearchTree` unlock logic and cost deduction.

### Integration Tests

- Test loading a full level and instantiating all buildings.
- Test completing a level and verifying reward distribution.
- Test meta-progression persistence across game restarts.
- Test campaign progression from Campaign 1 Level 1 to Campaign 4 Level 30.

### Contract Tests

- Verify that all 30 level JSON files conform to the schema.
- Verify that each level has at least one player and one enemy node.
- Verify that node positions are within map bounds.

---

## File Structure

```
tower_conquest_repo/
├── lib/
│   ├── game/
│   │   ├── managers/
│   │   │   ├── level_manager.dart (NEW)
│   │   │   ├── campaign_manager.dart (NEW)
│   │   │   └── player_progress.dart (NEW)
│   │   ├── models/
│   │   │   └── level_data.dart (NEW)
│   │   ├── systems/
│   │   │   └── research_tree.dart (NEW)
│   │   └── tower_conquest_game.dart (MODIFIED)
├── assets/
│   └── levels/ (NEW)
│       ├── campaign_1_level_1.json
│       ├── campaign_1_level_2.json
│       ├── ... (30 total)
│       └── campaign_4_level_30.json
├── tools/
│   └── validate_level.dart (NEW)
└── test/
    ├── level_manager_test.dart (NEW)
    ├── campaign_manager_test.dart (NEW)
    ├── player_progress_test.dart (NEW)
    └── ... (40–50 new tests)
```

---

## Acceptance Criteria Checklist

Phase 3 is complete when:

- ✅ All 30 level JSON files are created and validated.
- ✅ `LevelManager` loads and parses levels dynamically.
- ✅ `CampaignManager` tracks campaign and level progression.
- ✅ `PlayerProgress` persists Gold, Gems, and Experience across sessions.
- ✅ `ResearchTree` allows players to unlock permanent upgrades.
- ✅ Game boots with Campaign 1 Level 1 and progresses through all 30 levels.
- ✅ Completing a level awards rewards and unlocks the next level.
- ✅ All 123 existing Phase 1 tests still pass.
- ✅ All 220 existing Phase 2 tests still pass.
- ✅ 40–50 new tests cover level loading, campaign progression, and meta-progression.
- ✅ Total test count: 280–310 tests, all passing.
- ✅ `dart format`, `flutter analyze`, `flutter test`, `flutter build web --release` all pass.
- ✅ No performance regressions (60 FPS maintained).

---

## Q&A

**Q: How do I add obstacles and hazards to levels?**  
A: Phase 3 includes placeholder classes (`ObstacleData`, `HazardData`) for future expansion. For now, obstacles and hazards are not rendered or functional—focus on node-based level design.

**Q: Can I create levels with more than 6 nodes?**  
A: Yes, the level system supports arbitrary node counts. However, keep in mind that more nodes increase complexity and AI computation time. Test performance with large maps.

**Q: How do I adjust AI difficulty per level?**  
A: Set the `difficulty` field in the level JSON to `'easy'`, `'normal'`, or `'hard'`. The `EnemyCommander` will adjust unit generation rates and upgrade frequency accordingly.

**Q: Can I create time-limited levels?**  
A: Yes, set the `timeLimit` field in the level JSON (in seconds). The game will display a countdown timer and end the level when time expires.

**Q: How do I test a new level without playing through the entire campaign?**  
A: Use the `LevelManager.loadLevel()` method directly in a test or debug screen to load and preview a specific level.

---

## References

- **Game Design Document:** `planning/01_design/01_GAME_DESIGN_DOCUMENT.md`
- **Phase 2 Implementation Plan:** `planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md`
- **Phase 2 Developer Prompt:** `orchestrator/PHASE2_DEVELOPER_PROMPT.md`
- **Flame Documentation:** https://flame-engine.org/
- **Flutter SharedPreferences:** https://pub.dev/packages/shared_preferences
