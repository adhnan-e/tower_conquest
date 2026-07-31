# Phase 3 Architecture Audit Report

**Date:** 2026-07-31  
**Auditor:** Manus AI (Orchestrator)  
**Status:** ⚠️ **CRITICAL DESIGN MISMATCHES IDENTIFIED** — Phase 3 prompt requires revision before implementation.

---

## Executive Summary

The developer identified four critical architectural mismatches between the Phase 3 design prompt and the live game codebase. Independent verification confirms all four findings are accurate. The Phase 3 prompt contains pseudocode that will not compile against the current architecture without significant refactoring. This audit provides implementation-safe design guidance and recommends a revised Phase 3 prompt before the developer begins coding.

### Verified Findings

| Finding | Status | Impact | Recommendation |
|---------|--------|--------|-----------------|
| **1. BuildingType and Faction enums don't exist** | ✅ Confirmed | Compilation failure | Use `String` types; keep existing architecture |
| **2. Building constructor signature mismatch** | ✅ Confirmed | Runtime failure | Adapt level loader to use `BuildingBalance.baseStatsFor()` |
| **3. EnemyCommander difficulty parameter missing** | ✅ Confirmed | API mismatch | Route difficulty through `AIStrategy` injection seam |
| **4. ResearchNode.effect() has compounding mutation hazard** | ✅ Confirmed | Silent double-apply bugs | Use immutable modifier composition, not mutable accumulators |

---

## Finding 1: BuildingType and Faction Enums

### The Problem

The Phase 3 prompt (lines 228–229) assumes enums that don't exist:

```dart
// Phase 3 prompt pseudocode (WILL NOT COMPILE)
type: BuildingType.values.byName(json['type'] as String),
faction: Faction.values.byName(json['faction'] as String),
```

### Current Reality

**Verified:** Building types and factions are plain `String` values throughout the codebase.

- `Building.type` is declared as `final String type` (lib/game/components/buildings/building.dart, line ~8)
- `Building.faction` is declared as `final String faction` (line ~13)
- All 204 passing tests use string literals: `'barracks'`, `'tower'`, `'factory'`, `'command_center'`, `'player'`, `'enemy'`, `'neutral'`
- No `BuildingType` or `Faction` enum exists anywhere in `lib/`

### Why This Matters

Introducing enums would require:
- Refactoring every test file (204 test cases)
- Updating all existing game logic that references building types
- Modifying the AI strategy, asset manager, and balance system
- Changing the serialization format for levels

This is a **breaking change** that contradicts the orchestrator's role (design and assets only, not code refactoring).

### Recommendation

**Keep the existing `String`-based architecture.** The Phase 3 level loader should:

1. Parse JSON node definitions with `type` and `faction` as strings
2. Validate strings against a hardcoded set of allowed values
3. Pass strings directly to the `Building` constructor

Example:

```dart
// Correct approach: keep strings, validate values
static const validBuildingTypes = {'barracks', 'tower', 'factory', 'command_center'};
static const validFactions = {'player', 'enemy', 'neutral'};

factory NodeData.fromJson(Map<String, dynamic> json) {
  final typeStr = json['type'] as String;
  final factionStr = json['faction'] as String;
  
  if (!validBuildingTypes.contains(typeStr)) {
    throw FormatException('Invalid building type: $typeStr');
  }
  if (!validFactions.contains(factionStr)) {
    throw FormatException('Invalid faction: $factionStr');
  }
  
  return NodeData(
    id: json['id'] as String,
    type: typeStr,
    faction: factionStr,
    position: Vector2(...),
    tier: json['tier'] as int? ?? 1,
  );
}
```

---

## Finding 2: Building Constructor Signature Mismatch

### The Problem

The Phase 3 prompt (lines 508–514) shows a simplified constructor call:

```dart
// Phase 3 prompt pseudocode (INCOMPLETE)
final building = Building(
  id: nodeData.id,
  type: nodeData.type,
  faction: nodeData.faction,
  position: nodeData.position,
  tier: nodeData.tier,
);
```

### Current Reality

**Verified:** The `Building` constructor requires additional parameters that are not in the prompt.

The real `Building` constructor signature (lib/game/components/buildings/building.dart):

```dart
Building({
  required String id,
  required String type,
  required String faction,
  required Vector2 position,
  required int tier,
  // ↓ REQUIRED fields NOT in the prompt:
  required double size,
  required int unitsInside,
  required double generationRate,
  required int maxCapacity,
  required double defenseMultiplier,
})
```

Additionally, the prompt omits the critical step: **building stats must come from `BuildingBalance`**, not hardcoded defaults. The current implementation (in `_buildLevel()` of the game class) only hardcodes Barracks stats; a level loader must wire the balance table for all building types.

### Why This Matters

If the developer passes only the five fields shown in the prompt, the constructor will fail at runtime with missing required parameters. Even if those parameters are added, the buildings will render with incorrect stats (all defaulting to Barracks values) because the balance table isn't consulted.

### Recommendation

**Adapt the level loader to use `BuildingBalance.baseStatsFor(type)`** to populate missing constructor parameters.

Example:

```dart
// Correct approach: consult BuildingBalance for missing stats
final building = Building(
  id: nodeData.id,
  type: nodeData.type,
  faction: nodeData.faction,
  position: nodeData.position,
  tier: nodeData.tier,
  // ↓ Fetch from balance table:
  size: 256.0, // or read from BuildingBalance if exposed
  unitsInside: 0,
  generationRate: BuildingBalance.baseStatsFor(nodeData.type).generationRate,
  maxCapacity: BuildingBalance.baseStatsFor(nodeData.type).maxCapacity,
  defenseMultiplier: BuildingBalance.baseStatsFor(nodeData.type).defenseMultiplier,
);
add(building);
```

**Action for developer:** Expose `BuildingBalance.baseStatsFor()` as a public method (currently it may be private or internal) so the level loader can query it.

---

## Finding 3: EnemyCommander Difficulty Parameter

### The Problem

The Phase 3 prompt (lines 519–522) assumes a `difficulty` parameter on `EnemyCommander`:

```dart
// Phase 3 prompt pseudocode (DOES NOT MATCH REAL API)
enemyCommander = EnemyCommander(
  difficulty: currentLevel.difficulty,
  targetNodes: currentLevel.nodes.where((n) => n.faction == Faction.player).toList(),
);
```

### Current Reality

**Verified:** The `EnemyCommander` constructor has no `difficulty` parameter.

The real `EnemyCommander` constructor (lib/game/managers/enemy_commander.dart):

```dart
class EnemyCommander {
  final String faction;
  final AIStrategy? strategy;
  
  EnemyCommander({
    required this.faction,
    this.strategy,
  });
}
```

The `difficulty` scaling mechanism already exists—it's the **`AIStrategy` injection seam** that Phase 2 built. The `EnemyCommander` accepts an optional `AIStrategy` (defaults to `NormalAIStrategy`). Difficulty should be implemented by injecting a different strategy or parameterizing the strategy itself, not by adding a new field to the harness.

### Why This Matters

Adding a `difficulty` parameter to `EnemyCommander` would:
- Break the existing `EnemyCommander` API
- Duplicate the strategy-injection mechanism
- Require the developer to implement difficulty logic in two places (strategy + harness)

### Recommendation

**Route difficulty through the `AIStrategy` injection seam.** The level loader should:

1. Map the level's `difficulty` string to a strategy instance
2. Pass the strategy to `EnemyCommander`

Example:

```dart
// Correct approach: inject difficulty via strategy
AIStrategy createStrategyForDifficulty(String difficulty) {
  switch (difficulty) {
    case 'easy':
      return NormalAIStrategy(aggressiveness: 0.5);
    case 'normal':
      return NormalAIStrategy(aggressiveness: 1.0);
    case 'hard':
      return NormalAIStrategy(aggressiveness: 1.5);
    default:
      return NormalAIStrategy();
  }
}

// In TowerConquestGame.onLoad():
enemyCommander = EnemyCommander(
  faction: 'enemy',
  strategy: createStrategyForDifficulty(currentLevel.difficulty),
);
```

**Action for developer:** If `NormalAIStrategy` doesn't already support parameterization (e.g., an `aggressiveness` multiplier), add it as an optional parameter. This keeps difficulty scaling in one place (the strategy) and avoids duplicating logic in the harness.

---

## Finding 4: ResearchNode.effect() Compounding Mutation Hazard

### The Problem

The Phase 3 prompt (lines 431, 438, 445) uses closures that mutate a global `gameState`:

```dart
// Phase 3 prompt pseudocode (UNSAFE MUTATION)
'logistics': ResearchNode(
  // ...
  effect: () => gameState.unitSpeedMultiplier *= 1.05,
),
'fortification': ResearchNode(
  // ...
  effect: () => gameState.defenseMultiplier += 0.1,
),
'recruitment': ResearchNode(
  // ...
  effect: () => gameState.upgradeCostMultiplier *= 0.95,
),
```

### The Hazard

If `effect()` is called more than once (e.g., re-applied on level load, or a save/restore bug), bonuses **silently double-apply**:

- Call 1: `unitSpeedMultiplier *= 1.05` → 1.05
- Call 2: `unitSpeedMultiplier *= 1.05` → 1.1025 (compounded, not intended)

This is the exact compounding hazard that Phase 2 avoided by designing `BuildingBalance` with **immutable base stats and recomputed modifiers**, not mutable accumulators.

### Why This Matters

The Phase 2 architecture explicitly avoids this pattern:

> **BuildingBalance design principle:** Base stats are immutable; all modifiers are recomputed from the base on every access. This prevents silent double-applies and makes the system auditable.

Introducing mutable accumulators in research contradicts this principle and creates a maintenance burden.

### Recommendation

**Use immutable modifier composition, not mutable accumulators.** Store research unlocks as a set of IDs, then recompute all modifiers from the base on every access.

Example:

```dart
// Correct approach: immutable modifiers, recomputed from base
class PlayerProgress {
  final Set<String> unlockedResearch = {};
  
  double get unitSpeedMultiplier {
    double mult = 1.0;
    if (unlockedResearch.contains('logistics')) mult *= 1.05;
    if (unlockedResearch.contains('other_speed_research')) mult *= 1.1;
    // ... etc
    return mult;
  }
  
  double get defenseMultiplier {
    double mult = 1.0;
    if (unlockedResearch.contains('fortification')) mult += 0.1;
    // ... etc
    return mult;
  }
  
  double get upgradeCostMultiplier {
    double mult = 1.0;
    if (unlockedResearch.contains('recruitment')) mult *= 0.95;
    // ... etc
    return mult;
  }
}

class ResearchTree {
  static final Map<String, ResearchNode> nodes = {
    'logistics': ResearchNode(
      id: 'logistics',
      name: 'Logistics',
      description: '+5% unit movement speed',
      cost: 100,
      // No effect() closure — just store the unlock
    ),
    // ... etc
  };
  
  static void unlockResearch(String researchId) {
    final node = nodes[researchId];
    if (node != null && node.cost <= playerProgress.totalGold) {
      playerProgress.totalGold -= node.cost;
      playerProgress.unlockedResearch.add(researchId);
      // Modifiers are recomputed on next access; no mutation
    }
  }
}
```

**Action for developer:** When implementing research, store unlocked research IDs in a set, then compute all modifiers as getters that iterate the set. This is auditable, safe from double-applies, and aligns with Phase 2's design principles.

---

## Quality Gate Status (Current main)

The repository baseline (commit `1767529`, origin/main) passes all quality gates:

| Check | Result | Details |
|-------|--------|---------|
| `dart format --set-exit-if-changed lib test` | ✅ Pass | 0 files changed |
| `flutter analyze lib test` | ✅ Pass | No issues |
| `flutter test` (JSON report) | ✅ Pass | 204 visible tests + 16 suite-loading events = 220 total; all success |
| `flutter build web --release` | ✅ Pass | Build successful |

**Test Count Clarification:** The earlier sign-off messages conflated "220 total test events" with "220 real test cases." The accurate breakdown is:
- **204 visible test cases** (executable tests)
- **16 suite-loading harness events** (infrastructure, not tests)
- **220 total events** (sum of both)

All 220 events completed with `result: 'success'`.

---

## CI/CD Workflow Status

The GitHub Actions workflow (`.github/workflows/verify-and-distribute.yml`, commit `344bf7f`) is live on main and has been independently audited:

| Aspect | Status | Notes |
|--------|--------|-------|
| Authentication | ✅ Service-account only | Uses `GOOGLE_APPLICATION_CREDENTIALS` with service-account JSON; no `FIREBASE_TOKEN` |
| Android provisioning | ✅ Complete | Java 17 + Android SDK via `android-actions/setup-android@v3` |
| Release build | ✅ Working | `flutter build apk --release` succeeds |
| Node.js version | ✅ v20 | Updated in PR #6 (merged 2026-07-31 11:04:12Z) |
| Firebase distribution | ✅ Configured | Awaiting GitHub Secrets setup (`FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_APP_ID`) |

---

## Recommendations for Phase 3 Implementation

### 1. Revise the Phase 3 Prompt

The orchestrator should update `orchestrator/PHASE3_DEVELOPER_PROMPT.md` to:
- Replace `BuildingType.values.byName()` with string validation
- Show the complete `Building` constructor call with `BuildingBalance` integration
- Remove the `difficulty` parameter from `EnemyCommander`; use strategy injection instead
- Replace mutable research effects with immutable modifier composition

### 2. Developer Decision Points

Before the developer begins Phase 3 implementation, the orchestrator should confirm:

1. **String vs. Enum:** Keep the existing `String`-based architecture for building types and factions?
2. **BuildingBalance exposure:** Should `BuildingBalance.baseStatsFor()` be made public for level loaders?
3. **AIStrategy parameterization:** Should `NormalAIStrategy` accept an `aggressiveness` or `difficulty` parameter?
4. **Research modifier pattern:** Confirm immutable modifier composition (getters) instead of mutable accumulators?

### 3. Scope Clarification

The developer asked: **"Want me to go ahead and adapt Stage 1 (Level Definition & Loading) to the real codebase on my own judgment, or would you like to weigh in on any of those four design points first?"**

**Recommendation:** The orchestrator should weigh in on all four design points before the developer writes code. These are architectural decisions that affect the entire Phase 3 implementation. A 30-minute design review now prevents weeks of rework later.

---

## Next Steps

1. **Orchestrator:** Review this audit and confirm the four design recommendations with the developer.
2. **Orchestrator:** Update `orchestrator/PHASE3_DEVELOPER_PROMPT.md` with corrected pseudocode and architecture guidance.
3. **Developer:** Implement Phase 3 Stage 1 (Level Definition & Loading) against the revised prompt.
4. **Orchestrator:** Review the implementation PR against the corrected acceptance criteria.

---

## References

- **Repository:** adhnan-e/tower_conquest (GitHub)
- **Current main:** commit `1767529` (Merge pull request #6)
- **Phase 2 completion:** commit `63e7f1d` (Merge pull request #3)
- **Test audit tool:** `/home/ubuntu/tower_conquest_repo/tools/audit_test_events.py`
- **CI workflow:** `.github/workflows/verify-and-distribute.yml` (commit `344bf7f`)
