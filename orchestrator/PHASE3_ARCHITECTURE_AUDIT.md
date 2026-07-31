# Phase 3 Architecture Audit

**Project:** Tower Conquest
**Audit revision:** Corrected source-verified edition
**Status:** Design decisions confirmed; Stage 1 may proceed only against the revised developer prompt.
**Authoritative source:** Current `main` at the time of audit, with APIs verified directly from source files.

---

## Correction Notice

An earlier edition of this audit reached the correct high-level conclusions but incorrectly reproduced selected Dart signatures. The developer identified those discrepancies before implementation began. This revision supersedes the earlier edition and is the only version that should be used as Phase 3 implementation guidance.

> **Documentation rule:** Existing source code and tests are authoritative. Architectural documentation must be corrected when it disagrees with the live codebase; it must never force the codebase to conform to invented pseudocode.

---

## Executive Summary

The original broad Phase 3 prompt introduced references to APIs that do not exist. The four underlying design decisions remain correct and are now precisely specified.

| Decision | Confirmed direction | Stage 1 consequence |
|---|---|---|
| Type and faction representation | Retain existing `String` values. | Do not add `BuildingType` or `Faction` enums. |
| Runtime building construction | Resolve all type-specific base stats through `BuildingBalance.baseStatsFor`. | Create every runtime building with its actual type's capacity, generation, and defence values. |
| Difficulty behavior | Preserve the existing `AIStrategy` injection seam. | Parse difficulty as metadata only; do not add unsupported `EnemyCommander` parameters. |
| Research effects | Use immutable unlock state and derived modifiers. | Defer research implementation; do not add mutable, compounding effect closures. |

The corrected, implementation-ready reference is now `orchestrator/PHASE3_DEVELOPER_PROMPT.md`.

---

## 1. Type and Faction Representation

### Verified current state

The codebase uses strings for both building archetypes and factions. Valid current building type values are `barracks`, `tower`, `factory`, and `command_center`. Valid faction values are `player`, `enemy`, and `neutral`.

No `BuildingType` enum or `Faction` enum exists under `lib/`. This is intentional current architecture, not a missing implementation requirement.

### Correct implementation direction

`NodeData.type` and `NodeData.faction` must remain `String` values. JSON parsing must validate those strings against explicit supported-value sets and report a meaningful format error for invalid input. The Stage 1 PR must not introduce enums or refactor existing string-based game APIs.

```dart
static const validBuildingTypes = {
  'barracks',
  'tower',
  'factory',
  'command_center',
};

static const validFactions = {'player', 'enemy', 'neutral'};
```

---

## 2. Runtime Building Construction

### Verified current constructor

The `Building` constructor has **no** `id` field or constructor parameter. Its relevant live declaration is:

```dart
Building({
  required this.type,
  required this.tier,
  required String faction,
  required super.position,
  required super.size,
  this.unitsInside = 0,
  this.generationRate = 1.0,
  this.maxCapacity = 50,
  this.defenseMultiplier = 1.0,
  super.anchor = Anchor.center,
})
```

`super.position` and `super.size` are inherited `PositionComponent` inputs; the level loader must provide `Vector2` objects for both. The optional stat parameters have defaults and are **not** required arguments. Their defaults are appropriate only for the current Tier 1 Barracks-like baseline, so relying on them for every archetype would silently misconfigure non-Barracks nodes.

### Verified balance API

`BuildingBalance.baseStatsFor(String type)` is already public. It returns either `null` for an unknown type or a record with these fields:

```dart
({int capacity, double genRate, double defense, bool upgradeable})?
```

There is no `generationRate`, `maxCapacity`, or `defenseMultiplier` member on that record. Correct field names are `genRate`, `capacity`, and `defense`.

### Correct implementation direction

Node IDs are level-data identifiers. Keep them on `NodeData`, then use a loader-local `Map<String, Building>` to resolve link endpoints. Do **not** add an ID to `Building` merely to mirror JSON.

Every runtime node factory must use the public balance API, with values mapped to the real constructor names:

```dart
final stats = BuildingBalance.baseStatsFor(node.type);
if (stats == null) {
  throw FormatException('Unsupported building type: ${node.type}');
}

final building = Building(
  type: node.type,
  tier: 1,
  faction: node.faction,
  position: node.position,
  size: gameNodeSize,
  unitsInside: node.unitsInside,
  generationRate: stats.genRate,
  maxCapacity: stats.capacity,
  defenseMultiplier: stats.defense,
);
```

The `gameNodeSize` value must be a `Vector2` consistent with the existing game layout. `tier: 1` is deliberate: the current `Building.upgrade()` consumes garrison units and recalculates stat values from stored Tier 1 base values. Stage 1 must reject authored tiers other than 1 rather than simulating paid upgrades during map loading.

---

## 3. EnemyCommander and Difficulty

### Verified current constructor

The live `EnemyCommander` contract is:

```dart
class EnemyCommander {
  final String faction;
  final AIStrategy strategy;

  EnemyCommander({this.faction = 'enemy', AIStrategy? strategy})
      : strategy = strategy ?? NormalAIStrategy();
}
```

The constructor parameter `strategy` is nullable only at the call boundary. The stored `strategy` field is non-nullable because the initializer supplies `NormalAIStrategy()` whenever no strategy is passed. The `faction` parameter is optional and defaults to `'enemy'`.

`EnemyCommander` has no `difficulty` or `targetNodes` argument. `NormalAIStrategy` currently has no explicit configurable constructor, so an `aggressiveness` parameter does not exist today.

### Correct implementation direction

Stage 1 should parse and validate the level difficulty string as content metadata only. It must keep the current AI initialization contract and must not add unreviewed parameters to `EnemyCommander`.

```dart
enemyCommander = EnemyCommander();
```

A later, dedicated difficulty stage may add explicit strategy classes or reviewed configurable strategy parameters. When that work is scoped, difficulty must be mapped through the existing `AIStrategy` injection seam rather than duplicated in the commander harness.

---

## 4. Research and Modifier Safety

### Problem identified in prior pseudocode

The old prompt proposed research effects such as:

```dart
effect: () => gameState.unitSpeedMultiplier *= 1.05
```

This is unsafe because any repeated application silently compounds a permanent modifier. Reapplying the same research during load, save restoration, or state reconstruction changes game balance without changing the unlock state.

### Correct implementation direction

Research is outside Stage 1. When it is implemented later, store only the set of unlocked research IDs and derive each modifier from immutable base values whenever it is read. This follows the same non-compounding design principle used by building tier balance.

```dart
class PlayerProgress {
  final Set<String> unlockedResearch;

  double get unitSpeedMultiplier {
    var value = 1.0;
    if (unlockedResearch.contains('logistics')) value *= 1.05;
    return value;
  }
}
```

No research node should mutate a global multiplier through an executable effect closure.

---

## 5. Quality Baseline

The verified baseline must be reported accurately.

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | Pass; 0 files changed. |
| `flutter analyze lib test` | Pass; no issues. |
| `flutter test` | 204 visible test cases and 16 hidden suite-loading events; 220 successful total events. |
| `flutter build web --release` | Pass. |

The compact test reporter's count and JSON event total must not be described as 220 visible test cases. Future PR summaries should distinguish visible tests, hidden suite-loading events, and total successful test events.

---

## 6. Stage 1 Authorization Boundary

The developer is authorized to start **only** Phase 3 Stage 1: data-driven level definition and loading, using the revised `PHASE3_DEVELOPER_PROMPT.md`.

The PR must include typed immutable level data, JSON asset loading, validation, a runtime factory wired to `BuildingBalance.baseStatsFor`, link resolution, a JSON migration of the current two-node map, explicit fallback behavior, and focused tests. Campaign UI, campaign content production, obstacles, hazards, higher starting tiers, AI difficulty changes, persistent progression, research, and new game assets are deferred.

---

## 7. Source References

| Source file | Verified subject |
|---|---|
| `lib/game/components/buildings/building.dart` | `Building` constructor, type/faction strings, Tier 1 construction behavior, upgrade semantics. |
| `lib/game/constants/balance.dart` | Public `BuildingBalance.baseStatsFor` API and record field names. |
| `lib/game/managers/enemy_commander.dart` | Default enemy faction and non-nullable stored strategy. |
| `lib/game/managers/normal_ai_strategy.dart` | Current unparameterized Normal AI implementation. |
| `lib/game/tower_conquest_game.dart` | Existing hard-coded two-node map, node size use, and current AI initialization. |
| `orchestrator/PHASE3_DEVELOPER_PROMPT.md` | Corrected Stage 1 implementation specification. |
