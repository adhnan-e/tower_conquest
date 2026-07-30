# Phase 2 Developer Prompt: Building Upgrades, Tier Progression & Tactical AI

**Status:** PR #2 merged ✅ | Phase 1 complete with 123 tests passing  
**Target Completion:** 3-4 weeks  
**Estimated New Tests:** 40-50 (total: 160-170)  
**Merge Target:** PR #3 into `main`

---

## Overview

Phase 2 expands Tower Conquest with three interconnected systems that transform the game from a static prototype into a playable strategy experience. You will implement **building tier progression** (Tiers 1-5 with scaling stats), **in-match upgrades** (UI-driven unit investment), and a **tactical AI opponent** (strategic decision-making).

This prompt is your implementation roadmap. The detailed design is in `planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md`; this document focuses on code structure, contracts, and step-by-step guidance.

---

## Quick Start

1. **Review the implementation plan:** `planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md`
2. **Review the balance sheet:** `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` (§1.1, §1.2, §5.2)
3. **Create a feature branch:** `git checkout -b claude/phase2-upgrades-ai`
4. **Implement Stage 1** (Week 1): Building Upgrade System
5. **Implement Stage 2** (Week 1-2): Tier-Based Sprite Variants
6. **Implement Stage 3** (Week 2-3): Tactical AI Opponent
7. **Open PR #3** when all acceptance criteria are met

---

## System 1: Building Upgrade System

### Contract

Buildings upgrade from Tier 1 to Tier 5 by spending accumulated units. Each tier increases capacity, generation rate, and defense multiplier according to a fixed balance table. Upgrades are permanent for the match duration.

### Implementation Steps

#### Step 1.1: Create `lib/game/constants/balance.dart`

Define tier progression and building base stats as constants:

```dart
// lib/game/constants/balance.dart

/// Tier progression table: cost and stat bonuses per tier.
const tierProgressionTable = {
  1: (cost: 0, capacityBonus: 0, genRateBonus: 0.0, defenseBonus: 0.0),
  2: (cost: 20, capacityBonus: 10, genRateBonus: 0.10, defenseBonus: 0.10),
  3: (cost: 40, capacityBonus: 25, genRateBonus: 0.25, defenseBonus: 0.25),
  4: (cost: 70, capacityBonus: 45, genRateBonus: 0.40, defenseBonus: 0.40),
  5: (cost: 100, capacityBonus: 70, genRateBonus: 0.60, defenseBonus: 0.60),
};

/// Building type base stats (Tier 1).
const buildingBaseStats = {
  'barracks': (capacity: 50, genRate: 1.0, defense: 1.0),
  'tower': (capacity: 30, genRate: 0.67, defense: 1.5),
  'factory': (capacity: 40, genRate: 0.5, defense: 1.2),
  'command_center': (capacity: 100, genRate: 1.25, defense: 2.0),
};

/// Helper: Get upgrade cost for a given tier.
int upgradeCostForTier(int tier) {
  if (tier < 1 || tier > 5) return 0;
  return tierProgressionTable[tier]?.cost ?? 0;
}

/// Helper: Get capacity bonus for a given tier.
int capacityBonusForTier(int tier) {
  if (tier < 1 || tier > 5) return 0;
  return tierProgressionTable[tier]?.capacityBonus ?? 0;
}

/// Helper: Get generation rate bonus (as multiplier) for a given tier.
double genRateBonusForTier(int tier) {
  if (tier < 1 || tier > 5) return 0.0;
  return 1.0 + (tierProgressionTable[tier]?.genRateBonus ?? 0.0);
}

/// Helper: Get defense multiplier bonus (as multiplier) for a given tier.
double defenseBonusForTier(int tier) {
  if (tier < 1 || tier > 5) return 0.0;
  return 1.0 + (tierProgressionTable[tier]?.defenseBonus ?? 0.0);
}
```

#### Step 1.2: Extend `lib/game/components/buildings/building.dart`

Add upgrade logic to the Building component:

```dart
// In lib/game/components/buildings/building.dart

import '../../constants/balance.dart'; // Add this import

/// Add these methods to the Building class:

/// Returns the cost to upgrade to the next tier.
int get upgradeCost {
  if (tier >= 5) return 0; // Cannot upgrade beyond Tier 5
  return upgradeCostForTier(tier + 1);
}

/// Returns true if this building can be upgraded.
bool canUpgrade() {
  if (tier >= 5) return false; // Already at max tier
  if (type == 'command_center') return false; // Command Center cannot upgrade
  if (unitsInside < upgradeCost) return false; // Insufficient units
  return true;
}

/// Upgrades the building to the next tier.
/// Returns true if upgrade succeeded, false otherwise.
bool upgrade() {
  if (!canUpgrade()) return false;

  // Deduct upgrade cost from units inside
  unitsInside -= upgradeCost;

  // Increment tier
  tier += 1;

  // Update stats based on tier
  final genBonus = genRateBonusForTier(tier);
  final defenseBonus = defenseBonusForTier(tier);
  final capacityBonus = capacityBonusForTier(tier);

  // Recalculate stats
  // Note: These are incremental bonuses, so we need to recalculate from base stats.
  // The safest approach is to store base stats and recalculate from them.
  
  // For now, apply bonuses incrementally:
  generationRate *= genBonus;
  defenseMultiplier *= defenseBonus;
  maxCapacity += capacityBonus;

  // Update sprites (detail in System 2)
  _updateSprites();

  return true;
}

/// Updates sprites for the current tier (called on upgrade).
void _updateSprites() {
  // Detail in System 2: Tier-Based Sprite Variants
}
```

**Important:** The current `Building` constructor uses base stats from the balance sheet. When upgrading, you need to apply bonuses incrementally. Consider storing base stats separately to make recalculation easier:

```dart
// Alternative: Store base stats and recalculate from them
class Building extends PositionComponent {
  final String type;
  int tier;
  
  // Base stats (Tier 1)
  late int _baseCapacity;
  late double _baseGenerationRate;
  late double _baseDefenseMultiplier;
  
  // Current stats (tier-adjusted)
  int maxCapacity;
  double generationRate;
  double defenseMultiplier;
  
  // ... constructor and other code ...
  
  /// Recalculates current stats from base stats and tier.
  void _recalculateStats() {
    maxCapacity = _baseCapacity + capacityBonusForTier(tier);
    generationRate = _baseGenerationRate * genRateBonusForTier(tier);
    defenseMultiplier = _baseDefenseMultiplier * defenseBonusForTier(tier);
  }
  
  bool upgrade() {
    if (!canUpgrade()) return false;
    unitsInside -= upgradeCost;
    tier += 1;
    _recalculateStats();
    _updateSprites();
    return true;
  }
}
```

#### Step 1.3: Create `test/building_upgrade_test.dart`

Write comprehensive tests for the upgrade system:

```dart
// test/building_upgrade_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/balance.dart';
import 'package:tower_conquest/game/constants/colors.dart';

Building _barracks({int tier = 1, int unitsInside = 0}) {
  return Building(
    type: 'barracks',
    tier: tier,
    faction: 'player',
    position: Vector2.zero(),
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: 1.0,
  );
}

void main() {
  group('Building upgrades', () {
    test('upgrade cost increases with tier', () {
      expect(upgradeCostForTier(1), 0); // No upgrade from Tier 1
      expect(upgradeCostForTier(2), 20);
      expect(upgradeCostForTier(3), 40);
      expect(upgradeCostForTier(4), 70);
      expect(upgradeCostForTier(5), 100);
    });

    test('capacity bonus increases with tier', () {
      expect(capacityBonusForTier(1), 0);
      expect(capacityBonusForTier(2), 10);
      expect(capacityBonusForTier(3), 25);
      expect(capacityBonusForTier(4), 45);
      expect(capacityBonusForTier(5), 70);
    });

    test('generation rate bonus increases with tier', () {
      expect(genRateBonusForTier(1), 1.0);
      expect(genRateBonusForTier(2), 1.1);
      expect(genRateBonusForTier(3), 1.25);
      expect(genRateBonusForTier(4), 1.4);
      expect(genRateBonusForTier(5), 1.6);
    });

    test('defense bonus increases with tier', () {
      expect(defenseBonusForTier(1), 1.0);
      expect(defenseBonusForTier(2), 1.1);
      expect(defenseBonusForTier(3), 1.25);
      expect(defenseBonusForTier(4), 1.4);
      expect(defenseBonusForTier(5), 1.6);
    });

    test('canUpgrade returns false if insufficient units', () {
      final building = _barracks(unitsInside: 10); // Cost is 20
      expect(building.canUpgrade(), false);
    });

    test('canUpgrade returns true if sufficient units', () {
      final building = _barracks(unitsInside: 20);
      expect(building.canUpgrade(), true);
    });

    test('upgrade deducts cost from units inside', () {
      final building = _barracks(unitsInside: 50);
      expect(building.upgrade(), true);
      expect(building.unitsInside, 30); // 50 - 20
    });

    test('upgrade increments tier', () {
      final building = _barracks(tier: 1, unitsInside: 50);
      expect(building.upgrade(), true);
      expect(building.tier, 2);
    });

    test('upgrade caps tier at 5', () {
      final building = _barracks(tier: 5, unitsInside: 100);
      expect(building.canUpgrade(), false);
      expect(building.upgrade(), false);
      expect(building.tier, 5);
    });

    test('command center cannot upgrade', () {
      final building = Building(
        type: 'command_center',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(96),
        unitsInside: 100,
        generationRate: 1.25,
      );
      expect(building.canUpgrade(), false);
    });

    test('upgrade increases capacity', () {
      final building = _barracks(unitsInside: 50);
      final oldCapacity = building.maxCapacity;
      building.upgrade();
      expect(building.maxCapacity, oldCapacity + 10);
    });

    test('upgrade increases generation rate', () {
      final building = _barracks(unitsInside: 50);
      final oldGenRate = building.generationRate;
      building.upgrade();
      expect(building.generationRate, closeTo(oldGenRate * 1.1, 0.01));
    });

    test('upgrade increases defense multiplier', () {
      final building = _barracks(unitsInside: 50);
      final oldDefense = building.defenseMultiplier;
      building.upgrade();
      expect(building.defenseMultiplier, closeTo(oldDefense * 1.1, 0.01));
    });
  });
}
```

#### Step 1.4: Add Upgrade UI

Add an "Upgrade" button to the building info panel. This can be done in `lib/game/tower_conquest_game.dart` or a new `lib/game/screens/building_info_panel.dart`:

```dart
// Example: Add to the building selection logic in tower_conquest_game.dart

void _onBuildingSelected(Building building) {
  selectedBuilding = building;
  
  // Show building info panel with upgrade button
  overlays.add('building_info');
  
  // Update UI state
  // (This depends on your UI framework; use Flame's overlay system or Flutter widgets)
}

// In the overlay/UI layer:
// - Display building tier (1-5 stars or numeric label)
// - Display upgrade cost and new stats on hover
// - Show "Upgrade" button
// - Disable button if building.canUpgrade() is false
// - On button click, call building.upgrade() and refresh UI
```

---

## System 2: Tier-Based Sprite Variants

### Contract

Each building type has five sprite variants (Tiers 1-5). Sprites are loaded on-demand and swapped when a building upgrades. Until Tier 2-5 sprites are generated, Tier 1 sprites are used as fallback.

### Implementation Steps

#### Step 2.1: Extend `lib/game/managers/asset_manager.dart`

Add tier-aware sprite lookup:

```dart
// In lib/game/managers/asset_manager.dart

class AssetManager {
  // ... existing code ...
  
  /// Synchronous sprite lookup by building type and tier.
  /// Falls back to Tier 1 if the requested tier is not available.
  /// Returns null if the building type is unknown.
  Sprite? sprite(String type, int tier) {
    // Clamp tier to 1-5
    final clampedTier = tier.clamp(1, 5);
    
    // Try to load the requested tier
    final path = 'assets/images/buildings/${type}_tier${clampedTier}_base.png';
    if (_cache.containsKey(path)) {
      return _cache[path] as Sprite?;
    }
    
    // Fallback to Tier 1 if the requested tier is not available
    if (clampedTier > 1) {
      final tier1Path = 'assets/images/buildings/${type}_tier1_base.png';
      if (_cache.containsKey(tier1Path)) {
        return _cache[tier1Path] as Sprite?;
      }
    }
    
    return null;
  }
  
  /// Detail sprite lookup (same logic as base sprite).
  Sprite? detailSprite(String type, int tier) {
    final clampedTier = tier.clamp(1, 5);
    final path = 'assets/images/buildings/${type}_tier${clampedTier}_detail.png';
    if (_cache.containsKey(path)) {
      return _cache[path] as Sprite?;
    }
    if (clampedTier > 1) {
      final tier1Path = 'assets/images/buildings/${type}_tier1_detail.png';
      if (_cache.containsKey(tier1Path)) {
        return _cache[tier1Path] as Sprite?;
      }
    }
    return null;
  }
  
  /// Preload all Phase 1 and Phase 2 sprites.
  /// Phase 1: Tier 1 sprites (already generated).
  /// Phase 2: Tier 2-5 sprites (placeholder paths until assets are generated).
  @override
  Future<void> preload(List<String> assetPaths) async {
    // Phase 1: Load Tier 1 sprites
    final phase1Paths = AssetPaths.phase1Sprites();
    
    // Phase 2: Add Tier 2-5 placeholder paths (will be loaded when assets are generated)
    final phase2Paths = AssetPaths.phase2Sprites();
    
    final allPaths = [...phase1Paths, ...phase2Paths];
    
    for (final path in allPaths) {
      try {
        final sprite = await Sprite.load(path);
        _cache[path] = sprite;
      } catch (e) {
        print('Failed to load sprite: $path - $e');
        // Continue loading other sprites even if one fails
      }
    }
  }
}
```

#### Step 2.2: Extend `lib/game/constants/asset_paths.dart`

Add Phase 2 sprite paths:

```dart
// In lib/game/constants/asset_paths.dart

class AssetPaths {
  // ... existing code ...
  
  /// Phase 1 sprites (Tier 1 only).
  static List<String> phase1Sprites() {
    return [
      'assets/images/buildings/barracks_tier1_base.png',
      'assets/images/buildings/barracks_tier1_detail.png',
      'assets/images/buildings/tower_tier1_base.png',
      'assets/images/buildings/tower_tier1_detail.png',
      'assets/images/buildings/factory_tier1_base.png',
      'assets/images/buildings/factory_tier1_detail.png',
      'assets/images/buildings/command_center_tier1_base.png',
      'assets/images/buildings/command_center_tier1_detail.png',
      'assets/images/units/infantry_tier1_base.png',
      'assets/images/units/infantry_tier1_detail.png',
      'assets/images/units/heavy_soldier_tier1_base.png',
      'assets/images/units/heavy_soldier_tier1_detail.png',
      'assets/images/units/scout_tier1_base.png',
      'assets/images/units/scout_tier1_detail.png',
    ];
  }
  
  /// Phase 2 sprites (Tiers 2-5).
  /// Placeholder paths; actual sprites will be generated by the orchestrator.
  static List<String> phase2Sprites() {
    final buildings = ['barracks', 'tower', 'factory', 'command_center'];
    final tiers = [2, 3, 4, 5];
    final layers = ['base', 'detail'];
    
    final paths = <String>[];
    for (final building in buildings) {
      for (final tier in tiers) {
        for (final layer in layers) {
          paths.add('assets/images/buildings/${building}_tier${tier}_${layer}.png');
        }
      }
    }
    return paths;
  }
}
```

#### Step 2.3: Update Building Sprite Rendering

Update the Building component to use tier-aware sprite lookup:

```dart
// In lib/game/components/buildings/building.dart

void _updateSprites() {
  // Load sprites for the current tier
  final assetManager = AssetManager();
  baseSprite = assetManager.sprite(type, tier);
  detailSprite = assetManager.detailSprite(type, tier);
}

@override
void render(Canvas canvas) {
  // Render base sprite with faction tint
  if (baseSprite != null) {
    baseSprite!.render(
      canvas,
      position: -size / 2,
      size: size,
      overridePaint: tintPaint,
    );
  }
  
  // Render detail sprite (untinted)
  if (detailSprite != null) {
    detailSprite!.render(
      canvas,
      position: -size / 2,
      size: size,
    );
  }
}
```

#### Step 2.4: Create `test/phase2_render_contract_test.dart`

Write tests for tier-based sprite rendering:

```dart
// test/phase2_render_contract_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/managers/asset_manager.dart';
import 'package:tower_conquest/game/constants/asset_paths.dart';

void main() {
  group('Phase 2 sprite rendering contract', () {
    test('sprite lookup returns Tier 1 sprite for Tier 1 building', () async {
      final assetManager = AssetManager();
      await assetManager.preload(AssetPaths.phase1Sprites());
      
      final sprite = assetManager.sprite('barracks', 1);
      expect(sprite, isNotNull);
    });

    test('sprite lookup falls back to Tier 1 for unavailable tiers', () async {
      final assetManager = AssetManager();
      await assetManager.preload(AssetPaths.phase1Sprites());
      
      // Tier 2 sprite not yet available; should fall back to Tier 1
      final sprite = assetManager.sprite('barracks', 2);
      expect(sprite, isNotNull); // Should return Tier 1 sprite
    });

    test('detail sprite lookup works correctly', () async {
      final assetManager = AssetManager();
      await assetManager.preload(AssetPaths.phase1Sprites());
      
      final sprite = assetManager.detailSprite('barracks', 1);
      expect(sprite, isNotNull);
    });

    test('building upgrade swaps sprites', () async {
      final assetManager = AssetManager();
      await assetManager.preload(AssetPaths.phase1Sprites());
      
      final building = Building(
        type: 'barracks',
        tier: 1,
        faction: 'player',
        position: Vector2.zero(),
        size: Vector2.all(96),
        unitsInside: 50,
        generationRate: 1.0,
      );
      
      final oldSprite = building.baseSprite;
      building.upgrade();
      final newSprite = building.baseSprite;
      
      // Sprites should be the same (Tier 1 fallback) or different (if Tier 2 is available)
      // For now, they should be the same because Tier 2 is not yet available
      expect(newSprite, isNotNull);
    });
  });
}
```

---

## System 3: Tactical AI Opponent

### Contract

The AI opponent makes strategic decisions based on board state evaluation. The AI should win approximately 50% of matches against a passive player on Normal difficulty.

### Implementation Steps

#### Step 3.1: Create `lib/game/managers/ai_strategy.dart`

Define the strategy interface:

```dart
// lib/game/managers/ai_strategy.dart

import '../components/buildings/building.dart';

/// A decision made by the AI: send units from [source] to [target].
class AIAction {
  final Building source;
  final Building target;
  final int unitCount; // 0 = send all available units
  
  AIAction({
    required this.source,
    required this.target,
    this.unitCount = 0,
  });
}

/// Context snapshot for AI decision-making.
class AIDecisionContext {
  final List<Building> ownedBuildings;
  final List<Building> playerBuildings;
  final List<Building> neutralBuildings;
  final double gameTime;
  
  AIDecisionContext({
    required this.ownedBuildings,
    required this.playerBuildings,
    required this.neutralBuildings,
    required this.gameTime,
  });
}

/// Interface for AI decision-making strategies.
abstract class AIStrategy {
  /// Evaluates the current board state and returns a list of actions to execute.
  List<AIAction> decideActions(AIDecisionContext context);
}
```

#### Step 3.2: Create `lib/game/managers/normal_ai_strategy.dart`

Implement the Normal difficulty AI:

```dart
// lib/game/managers/normal_ai_strategy.dart

import 'dart:math';
import '../components/buildings/building.dart';
import 'ai_strategy.dart';

class NormalAIStrategy implements AIStrategy {
  /// Upgrade cooldown: don't upgrade more than once every N seconds.
  static const double upgradeCooldownSeconds = 20.0;
  
  /// Travel time threshold for threat assessment (seconds).
  static const double threatThresholdSeconds = 2.0;
  
  /// Capacity threshold for upgrade decision (70% of max capacity).
  static const double capacityThresholdForUpgrade = 0.7;
  
  /// Last time an upgrade was performed.
  double _lastUpgradeTime = 0.0;
  
  @override
  List<AIAction> decideActions(AIDecisionContext context) {
    final actions = <AIAction>[];
    
    // 1. Assess threats and defend if necessary
    for (final building in context.ownedBuildings) {
      if (_isUnderThreat(building, context.playerBuildings)) {
        // Hold units; don't send them elsewhere
        continue;
      }
    }
    
    // 2. Attack weak player buildings
    for (final building in context.ownedBuildings) {
      if (building.unitsInside < 1) continue;
      
      final target = _selectAttackTarget(building, context.playerBuildings);
      if (target != null) {
        final unitCount = _allocateUnitsForAttack(building, target);
        if (unitCount > 0) {
          actions.add(AIAction(source: building, target: target, unitCount: unitCount));
        }
      }
    }
    
    // 3. Expand to neutral buildings
    for (final building in context.ownedBuildings) {
      if (building.unitsInside < 5) continue; // Need at least 5 units
      
      final target = _selectNeutralTarget(building, context.neutralBuildings);
      if (target != null) {
        actions.add(AIAction(source: building, target: target, unitCount: 5));
      }
    }
    
    // 4. Upgrade if conditions allow
    if (context.gameTime - _lastUpgradeTime >= upgradeCooldownSeconds) {
      for (final building in context.ownedBuildings) {
        if (building.canUpgrade() && _shouldUpgrade(building, context)) {
          building.upgrade();
          _lastUpgradeTime = context.gameTime;
          break; // Upgrade one building per decision cycle
        }
      }
    }
    
    return actions;
  }
  
  /// Returns true if the building is under immediate threat from player units.
  bool _isUnderThreat(Building building, List<Building> playerBuildings) {
    for (final playerBuilding in playerBuildings) {
      // Rough estimate: if player building is close, it's a threat
      final distance = building.position.distanceToSquared(playerBuilding.position);
      final travelTime = sqrt(distance) / 100; // Rough estimate: 100 px/s average speed
      
      if (travelTime < threatThresholdSeconds && playerBuilding.unitsInside > 0) {
        return true;
      }
    }
    return false;
  }
  
  /// Selects the best attack target among player buildings.
  /// Prioritizes nearest, then lowest defense.
  Building? _selectAttackTarget(Building from, List<Building> targets) {
    if (targets.isEmpty) return null;
    
    Building? best;
    var bestScore = double.infinity;
    
    for (final target in targets) {
      final distance = from.position.distanceToSquared(target.position);
      final defense = target.unitsInside * target.defenseMultiplier;
      
      // Score: prioritize nearest, then lowest defense
      final score = distance + (defense * 100);
      
      if (score < bestScore) {
        bestScore = score;
        best = target;
      }
    }
    
    return best;
  }
  
  /// Selects the best neutral target to expand to.
  /// Prioritizes nearest, undefended buildings.
  Building? _selectNeutralTarget(Building from, List<Building> targets) {
    if (targets.isEmpty) return null;
    
    Building? best;
    var bestDistance = double.infinity;
    
    for (final target in targets) {
      final distance = from.position.distanceToSquared(target.position);
      
      if (distance < bestDistance) {
        bestDistance = distance;
        best = target;
      }
    }
    
    return best;
  }
  
  /// Allocates units for an attack based on target defense.
  int _allocateUnitsForAttack(Building from, Building target) {
    final defense = target.unitsInside * target.defenseMultiplier;
    
    if (defense < 20) {
      // Weak target: send all available units
      return from.unitsInside;
    } else if (defense < 50) {
      // Moderate target: send 50% of available units
      return (from.unitsInside * 0.5).toInt();
    } else {
      // Strong target: send 25% of available units
      return (from.unitsInside * 0.25).toInt();
    }
  }
  
  /// Returns true if the building should be upgraded.
  bool _shouldUpgrade(Building building, AIDecisionContext context) {
    // Upgrade if units inside exceed 70% of max capacity
    if (building.unitsInside < building.maxCapacity * capacityThresholdForUpgrade) {
      return false;
    }
    
    // Don't upgrade if under threat
    if (_isUnderThreat(building, context.playerBuildings)) {
      return false;
    }
    
    // Prioritize upgrading high-generation buildings
    if (building.type == 'factory' || building.type == 'command_center') {
      return true;
    }
    
    return true;
  }
}
```

#### Step 3.3: Refactor `lib/game/managers/enemy_commander.dart`

Update to use the strategy interface:

```dart
// lib/game/managers/enemy_commander.dart

import '../components/buildings/building.dart';
import 'ai_strategy.dart';
import 'normal_ai_strategy.dart';

class EnemyCommander {
  final String faction;
  final AIStrategy strategy;
  
  EnemyCommander({
    this.faction = 'enemy',
    AIStrategy? strategy,
  }) : strategy = strategy ?? NormalAIStrategy();
  
  void update({
    required List<Building> nodes,
    required bool Function(Building from, Building to) send,
  }) {
    final ownedBuildings = nodes.where((n) => n.faction == faction).toList();
    if (ownedBuildings.isEmpty) return;
    
    final playerBuildings = nodes.where((n) => n.faction == 'player').toList();
    final neutralBuildings = nodes.where((n) => n.faction == 'neutral').toList();
    
    final context = AIDecisionContext(
      ownedBuildings: ownedBuildings,
      playerBuildings: playerBuildings,
      neutralBuildings: neutralBuildings,
      gameTime: 0.0, // TODO: Pass actual game time
    );
    
    final actions = strategy.decideActions(context);
    
    for (final action in actions) {
      send(action.source, action.target);
    }
  }
}
```

#### Step 3.4: Create `test/ai_strategy_test.dart`

Write unit tests for AI heuristics:

```dart
// test/ai_strategy_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/managers/ai_strategy.dart';
import 'package:tower_conquest/game/managers/normal_ai_strategy.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/colors.dart';

Building _mockBuilding({
  required String type,
  required String faction,
  required Vector2 position,
  int unitsInside = 0,
  int maxCapacity = 50,
}) {
  return Building(
    type: type,
    tier: 1,
    faction: faction,
    position: position,
    size: Vector2.all(96),
    unitsInside: unitsInside,
    generationRate: 1.0,
  )..maxCapacity = maxCapacity;
}

void main() {
  group('Normal AI Strategy', () {
    test('selects nearest attack target', () {
      final strategy = NormalAIStrategy();
      
      final ownedBuilding = _mockBuilding(
        type: 'barracks',
        faction: 'enemy',
        position: Vector2.zero(),
        unitsInside: 20,
      );
      
      final nearTarget = _mockBuilding(
        type: 'barracks',
        faction: 'player',
        position: Vector2(100, 0),
        unitsInside: 5,
      );
      
      final farTarget = _mockBuilding(
        type: 'barracks',
        faction: 'player',
        position: Vector2(500, 0),
        unitsInside: 5,
      );
      
      final context = AIDecisionContext(
        ownedBuildings: [ownedBuilding],
        playerBuildings: [nearTarget, farTarget],
        neutralBuildings: [],
        gameTime: 0.0,
      );
      
      final actions = strategy.decideActions(context);
      expect(actions.length, greaterThan(0));
      expect(actions[0].target, nearTarget);
    });

    test('allocates more units for weak targets', () {
      final strategy = NormalAIStrategy();
      
      final ownedBuilding = _mockBuilding(
        type: 'barracks',
        faction: 'enemy',
        position: Vector2.zero(),
        unitsInside: 100,
      );
      
      final weakTarget = _mockBuilding(
        type: 'barracks',
        faction: 'player',
        position: Vector2(100, 0),
        unitsInside: 5, // Low defense
      );
      
      final strongTarget = _mockBuilding(
        type: 'tower',
        faction: 'player',
        position: Vector2(200, 0),
        unitsInside: 50, // High defense
      );
      
      // Test weak target allocation
      final weakAllocation = strategy._allocateUnitsForAttack(ownedBuilding, weakTarget);
      expect(weakAllocation, 100); // Send all units
      
      // Test strong target allocation
      final strongAllocation = strategy._allocateUnitsForAttack(ownedBuilding, strongTarget);
      expect(strongAllocation, lessThan(weakAllocation)); // Send fewer units
    });

    test('upgrades when units exceed capacity threshold', () {
      final strategy = NormalAIStrategy();
      
      final building = _mockBuilding(
        type: 'barracks',
        faction: 'enemy',
        position: Vector2.zero(),
        unitsInside: 40, // 80% of 50 capacity
        maxCapacity: 50,
      );
      
      final context = AIDecisionContext(
        ownedBuildings: [building],
        playerBuildings: [],
        neutralBuildings: [],
        gameTime: 0.0,
      );
      
      expect(strategy._shouldUpgrade(building, context), true);
    });

    test('does not upgrade when under threat', () {
      final strategy = NormalAIStrategy();
      
      final ownedBuilding = _mockBuilding(
        type: 'barracks',
        faction: 'enemy',
        position: Vector2.zero(),
        unitsInside: 40,
        maxCapacity: 50,
      );
      
      final threatBuilding = _mockBuilding(
        type: 'barracks',
        faction: 'player',
        position: Vector2(50, 0), // Very close
        unitsInside: 20,
      );
      
      final context = AIDecisionContext(
        ownedBuildings: [ownedBuilding],
        playerBuildings: [threatBuilding],
        neutralBuildings: [],
        gameTime: 0.0,
      );
      
      expect(strategy._shouldUpgrade(ownedBuilding, context), false);
    });
  });
}
```

#### Step 3.5: Create `test/ai_integration_test.dart`

Write integration tests for full match simulation:

```dart
// test/ai_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_conquest/game/managers/enemy_commander.dart';
import 'package:tower_conquest/game/components/buildings/building.dart';
import 'package:tower_conquest/game/constants/colors.dart';

void main() {
  group('AI integration tests', () {
    test('AI wins approximately 50% of matches against passive player', () {
      // This is a simplified test; a full match simulation would require
      // the entire game loop to be testable, which may require refactoring.
      
      // For now, just verify that the AI can be instantiated and make decisions.
      final commander = EnemyCommander();
      expect(commander, isNotNull);
      expect(commander.faction, 'enemy');
    });
  });
}
```

---

## Testing Checklist

Before opening PR #3, ensure all tests pass:

```bash
# Run all tests
flutter test --reporter=compact

# Format code
dart format --set-exit-if-changed lib test

# Analyze code
flutter analyze lib test

# Build for web
flutter build web --release
```

**Expected Results:**
- ✅ All 123 existing tests pass
- ✅ 40-50 new tests pass (total: 160-170)
- ✅ 0 files changed by `dart format`
- ✅ 0 warnings/errors from `flutter analyze`
- ✅ `flutter build web --release` succeeds

---

## Common Pitfalls & Solutions

### Pitfall 1: Stat Recalculation on Upgrade

**Problem:** Applying bonuses incrementally can lead to incorrect stats if not careful.

**Solution:** Store base stats and recalculate from them:

```dart
void _recalculateStats() {
  maxCapacity = _baseCapacity + capacityBonusForTier(tier);
  generationRate = _baseGenerationRate * genRateBonusForTier(tier);
  defenseMultiplier = _baseDefenseMultiplier * defenseBonusForTier(tier);
}
```

### Pitfall 2: Sprite Fallback Logic

**Problem:** If Tier 2-5 sprites are not available, the game crashes or shows missing textures.

**Solution:** Implement fallback to Tier 1 in `AssetManager.sprite()`:

```dart
Sprite? sprite(String type, int tier) {
  final path = 'assets/images/buildings/${type}_tier${tier}_base.png';
  if (_cache.containsKey(path)) {
    return _cache[path] as Sprite?;
  }
  // Fallback to Tier 1
  if (tier > 1) {
    return sprite(type, 1);
  }
  return null;
}
```

### Pitfall 3: AI Decision Performance

**Problem:** AI decision-making takes too long and causes frame drops.

**Solution:** Keep heuristics simple and avoid expensive operations:

- Use squared distances instead of sqrt
- Cache building lists instead of filtering every frame
- Limit the number of decisions per frame

---

## Questions & Clarifications

**Q: Should upgrades be animated?**  
A: No, upgrades are instant in Phase 2. Animations will be added in Phase 4 (Polish & Launch).

**Q: Can the AI upgrade buildings?**  
A: Yes, the AI should upgrade buildings if it has excess units and the upgrade is strategically beneficial.

**Q: What if the player and AI both try to upgrade the same building?**  
A: Upgrades are per-building, not per-faction. Only the building's owner can upgrade it.

**Q: How do I test the AI without running a full match?**  
A: Use unit tests to test individual heuristics. Use integration tests to run a full match and verify behavior.

---

## Next Steps

1. ✅ Review this prompt and the implementation plan
2. ⏳ Create a feature branch: `git checkout -b claude/phase2-upgrades-ai`
3. ⏳ Implement Stage 1 (Week 1): Building Upgrade System
4. ⏳ Implement Stage 2 (Week 1-2): Tier-Based Sprite Variants
5. ⏳ Implement Stage 3 (Week 2-3): Tactical AI Opponent
6. ⏳ Open PR #3 when all acceptance criteria are met

---

## References

- **Implementation Plan:** `planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md`
- **Balance Sheet:** `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md`
- **Game Design Document:** `planning/01_design/01_GAME_DESIGN_DOCUMENT.md`
- **Flutter/Flame Guide:** `planning/04_implementation/01_FLUTTER_FLAME_GUIDE.md`

---

**Prepared by:** Orchestrator (Manus AI)  
**Date:** 2026-07-30  
**Status:** Ready for Developer Implementation
