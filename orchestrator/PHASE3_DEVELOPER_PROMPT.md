# Phase 3 Developer Prompt — Stage 1: Level Definition and Loading

**Project:** Tower Conquest
**Milestone:** Phase 3 — Level Design and Campaign Structure
**Implementation increment:** Stage 1 only
**Authoritative baseline:** `main` after commit `739297f`
**Scope owner:** Developer implements code. Orchestrator owns design, level content, asset planning, and review.

---

## 1. Purpose and Scope

Stage 1 replaces the current hard-coded two-node map with a **data-driven level-loading foundation**. It must support declarative map metadata, node placement, ownership, starting garrisons, and explicit links between nodes. It must also preserve the current playable two-node match as the default loaded level.

This is deliberately a foundation increment. It does **not** implement the full 30-level campaign, campaign-selection UI, persistent currency, research UI, obstacle collisions, hazards, new artwork, or difficulty-specific AI behavior. Those features depend on a trusted level schema and will be specified in later Phase 3 stages.

> **Source-of-truth rule:** Existing Dart APIs and passing tests take precedence over older pseudocode. Do not copy earlier constructor examples verbatim if they conflict with the codebase.

---

## 2. Verified Current Architecture

The following statements have been checked against current `main` and are constraints for this work.

| Area | Current architecture | Stage 1 implication |
|---|---|---|
| Building type | `String` values such as `barracks`, `tower`, `factory`, and `command_center` | Keep strings; do **not** introduce a `BuildingType` enum. |
| Faction | `String` values such as `player`, `enemy`, and `neutral` | Keep strings; do **not** introduce a `Faction` enum. |
| Building identity | `Building` has no `id` constructor parameter or `id` field | Keep authored node IDs in `NodeData`; use a loader-local `Map<String, Building>` when resolving links. |
| Building size | Inherited `PositionComponent.size` is a required `Vector2` constructor argument | Supply the existing game node size or a level-defined `Vector2`; do not use a `double`. |
| Building stats | `unitsInside`, `generationRate`, `maxCapacity`, and `defenseMultiplier` are optional constructor parameters with Barracks-like defaults | Override the three balance-dependent stats for **every** node type using the existing public balance lookup. |
| Balance lookup | `BuildingBalance.baseStatsFor(String type)` is already public | Call it directly; do not change its visibility. |
| AI harness | `EnemyCommander({this.faction = 'enemy', AIStrategy? strategy}) : strategy = strategy ?? NormalAIStrategy();` | Keep this contract. Stage 1 must not add `difficulty` or `targetNodes` parameters. |
| Normal AI | `NormalAIStrategy` presently has no configurable constructor | Do not imply an existing aggressiveness knob. Difficulty behavior is deferred to a later stage. |
| Starting tiers | `Building.upgrade()` spends garrison units and recalculates from stored Tier 1 base values | Stage 1 authored nodes must use `tier: 1`. Do not simulate paid upgrades while loading a level. |

The current quality baseline is **204 visible test cases plus 16 hidden suite-loading events, for 220 successful test events**. Do not describe this as 220 visible test cases.

---

## 3. Stage 1 Deliverables

The Stage 1 pull request must contain the following deliverables.

| Deliverable | Requirement |
|---|---|
| Typed level data model | A Dart model for level metadata, nodes, links, rewards, and the parsing/validation result. |
| Level asset structure | A stable location under `assets/levels/`, registered in `pubspec.yaml` using directory inclusion. |
| Level loader | An asynchronous loader that reads a named JSON level asset, parses it, validates it, and caches immutable `LevelData`. |
| Runtime factory | A narrow adapter that converts valid `NodeData` into correctly configured `Building` instances and resolves authored link IDs into `PathLink` instances. |
| Default playable level | A JSON version of the current two-node Barracks match, used by default after the integration. |
| Defensive fallback | A separately testable fallback level for unreadable/missing requested content. Schema errors must remain observable rather than silently being treated as valid content. |
| Tests | Focused unit/integration tests for parsing, validation, balance wiring, link resolution, fallback behavior, and preservation of the baseline match. |

No new asset generation is part of this Stage 1 request.

---

## 4. Canonical Level Schema for Stage 1

Store level JSON under `assets/levels/`. The first canonical sample should be `assets/levels/campaign_1_level_1.json` and should recreate the current 1v1 Barracks map.

```json
{
  "id": "campaign_1_level_1",
  "name": "First Contact",
  "campaign": 1,
  "levelNumber": 1,
  "description": "Capture the opposing command position in a simple two-node match.",
  "difficulty": "normal",
  "width": 800,
  "height": 600,
  "nodes": [
    {
      "id": "player_base",
      "type": "barracks",
      "faction": "player",
      "position": { "x": 0, "y": 220 },
      "tier": 1,
      "unitsInside": 10
    },
    {
      "id": "enemy_base",
      "type": "barracks",
      "faction": "enemy",
      "position": { "x": 0, "y": -220 },
      "tier": 1,
      "unitsInside": 10
    }
  ],
  "links": [
    { "from": "player_base", "to": "enemy_base" }
  ],
  "winCondition": "capture_all_enemy_nodes",
  "timeLimitSeconds": null,
  "rewards": { "gold": 0, "gems": 0, "experience": 0 }
}
```

### 4.1 Supported Stage 1 Fields

| Field | Type | Validation rule |
|---|---|---|
| `id` | non-empty string | Must be unique within the level catalog. |
| `name` | non-empty string | Required. |
| `campaign` | positive integer | Required; supports later campaign organization. |
| `levelNumber` | positive integer | Required; unique within a campaign. |
| `description` | string | Required; may be empty only if product direction later permits it. |
| `difficulty` | `easy`, `normal`, or `hard` | Parse and validate as metadata only in Stage 1. |
| `width`, `height` | positive number | Must define a positive canvas. |
| `nodes` | non-empty list | Must contain at least one player node and one enemy node. |
| `nodes[].id` | non-empty string | Unique within the level; stays in data, not on `Building`. |
| `nodes[].type` | string | One of `barracks`, `tower`, `factory`, `command_center`. |
| `nodes[].faction` | string | One of `player`, `enemy`, `neutral`. |
| `nodes[].position` | `{x, y}` number pair | Must lie inside declared map bounds. |
| `nodes[].tier` | integer | Must be `1` in Stage 1. |
| `nodes[].unitsInside` | non-negative integer | Must not exceed the node type's Tier 1 capacity. |
| `links` | list | Each end must reference a declared node; no self-links or duplicate unordered pairs. |
| `winCondition` | string | Stage 1 supports `capture_all_enemy_nodes`. Reject or clearly mark other values unsupported. |
| `timeLimitSeconds` | positive integer or null | Parse and validate only; no countdown implementation in Stage 1. |
| `rewards` | object | Parse as immutable data; do not add persistence in Stage 1. |

`obstacles`, `hazards`, dynamic node sizes, higher starting tiers, and runtime map modifiers are intentionally out of scope. Add them only through a subsequent reviewed schema revision.

---

## 5. Data Model Requirements

Use typed, immutable data objects. Exact class filenames and directory names may follow existing project conventions, but the model must preserve all supported JSON fields and allow deterministic validation.

`NodeData.type` and `NodeData.faction` must be `String`, not invented enums. Keep `NodeData.id` so that authored links can be validated and resolved. `LinkData` should retain `from` and `to` node IDs as strings. `LevelData` should expose immutable node and link collections after validation.

Validation should occur before game-world mutation. A malformed selected level must produce a meaningful `FormatException` or domain-specific validation error that identifies the affected field. A separate `loadOrFallback` path may substitute the known-safe two-node level for unreadable or missing content, but it must not hide authoring errors during test or development workflows.

---

## 6. Authoritative Runtime Construction Pattern

The actual `Building` constructor has this relevant shape:

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

There is no `id` argument. `size` is a `Vector2`. The defaults represent Barracks-like Tier 1 values, so using defaults for every type would silently misconfigure Towers, Factories, and Command Centers.

The runtime factory must therefore follow this sequence for every authored node:

1. Retrieve `final stats = BuildingBalance.baseStatsFor(node.type)`.
2. Reject the node if `stats` is `null`; schema validation should normally prevent this.
3. Build a `Building` with `tier: 1`, the authored faction and position, the existing game node `Vector2` size, authored `unitsInside`, and these exact balance values:
   - `generationRate: stats.genRate`
   - `maxCapacity: stats.capacity`
   - `defenseMultiplier: stats.defense`
4. Preserve the authored node ID in a loader-local map, for example `Map<String, Building> buildingsByNodeId`, solely to resolve `LinkData` into `PathLink` instances.
5. Apply the existing tap callback exactly as the current hard-coded `_buildLevel()` does.

Do not change `Building` simply to add an ID. Do not make the optional constructor fields required. Do not call `upgrade()` while loading, because that charges the garrison and represents in-match progression rather than authored initial state.

---

## 7. Game Integration Rules

Replace the hard-coded map construction only after the loader and runtime factory are independently tested. The integrated default path must load the JSON equivalent of the current Barracks-vs-Barracks match and preserve current selection, unit sending, pathing, capture, and match-outcome behavior.

`TowerConquestGame` may retain compatibility fields such as `playerBase` and `enemyBase` while the game remains dependent on them, but the authoritative collection of map nodes must continue to be the existing `nodes` list. The developer may use the node-ID map only during initialization; it must not become a second mutable world model.

Stage 1 must continue to create the AI using the existing constructor contract:

```dart
enemyCommander = EnemyCommander();
```

The parsed `difficulty` value is level metadata in this increment. It must not be passed as an invented `EnemyCommander` argument. No new `NormalAIStrategy(aggressiveness: ...)` call belongs in Stage 1 because that constructor does not yet exist.

---

## 8. Deferred Decisions for Later Phase 3 Stages

| Deferred item | Reason for deferral | Future direction |
|---|---|---|
| Difficulty-specific AI | No configurable Normal AI constructor exists today. | Add explicit strategy classes or reviewed strategy parameters in a dedicated stage, then map `difficulty` through the existing `AIStrategy` injection seam. |
| Higher authored starting tiers | Current `upgrade()` spends garrison units. | Design a non-spending, balance-safe initialization API before allowing `tier > 1` in level JSON. |
| Campaign catalog and 30+ levels | Needs trusted schema and playtest loop. | Build content after Stage 1 is merged and level validation is stable. |
| Meta-progression and research | Persistent effects must not mutate accumulators. | Store unlocked IDs and recompute modifiers from immutable base values. |
| Obstacles, hazards, and terrain art | They require gameplay collision rules and confirmed level themes. | Scope after the level foundation and request original assets only when needed. |
| Level-editor tooling | Editor validation should reuse the production schema. | Implement after the loader validation API is stable. |

---

## 9. Required Tests and Acceptance Criteria

The PR must pass the existing project quality gate and include focused coverage for the new foundation.

| Area | Required evidence |
|---|---|
| JSON parsing | A valid two-node level parses to immutable typed data. |
| String validation | Invalid building types and factions are rejected with a meaningful error. |
| Structural validation | Duplicate node IDs, invalid links, self-links, duplicate links, missing player/enemy nodes, out-of-bounds positions, invalid starting units, and non-Tier-1 authored nodes are rejected. |
| Balance integration | A runtime node factory supplies the correct `generationRate`, `maxCapacity`, and `defenseMultiplier` for all four building types. |
| Link resolution | Valid authored link IDs resolve to the intended `PathLink` endpoints. |
| Fallback | A missing/unreadable requested level can use the explicit safe fallback path; malformed content remains observable. |
| Regression | The default loaded level has two Barracks nodes, one link, starting garrisons of 10, and preserves the current game loop. |
| Quality | `dart format --set-exit-if-changed lib test`, `flutter analyze lib test`, `flutter test`, and `flutter build web --release` all pass. |

The test report must distinguish **visible test cases** from hidden suite-loading events. The baseline before this work is 204 visible cases, 16 loading events, and 220 successful total events; the PR should report its updated count using the same distinction.

---

## 10. Non-Negotiable Guardrails

1. Do not introduce `BuildingType` or `Faction` enums in Stage 1.
2. Do not add a `Building.id` field or constructor parameter merely to match JSON node IDs.
3. Do not alter the `Building` constructor defaults or claim they are required arguments.
4. Do not change `BuildingBalance.baseStatsFor()` visibility; it is already public.
5. Do not add `difficulty` or `targetNodes` arguments to `EnemyCommander`.
6. Do not add a nonexistent `NormalAIStrategy(aggressiveness: ...)` API without a separate reviewed difficulty-design stage.
7. Do not implement research, persistent progression, new assets, obstacle mechanics, hazards, or campaign UI in this PR.
8. Do not use mutable research-effect closures in later stages; modifiers must be recomputed from base values and the set of unlocked research IDs.
9. Do not weaken existing game-loop behavior or remove established test coverage.

---

## 11. Pull Request Handoff Format

Open a focused PR titled:

> `Phase 3 Stage 1: data-driven level definition and loading`

The PR description must state the level schema, default-level migration behavior, validation behavior, test-count breakdown, quality-gate output, and any deliberately deferred fields. It must explicitly confirm that the implementation preserves String-based type/faction values and uses the existing `AIStrategy` injection seam without adding unreviewed difficulty behavior.

Once the PR is opened, stop implementation work and request orchestrator review. Do not begin Stage 2 content production, research, obstacles, or asset generation until the Stage 1 PR is approved and merged.

---

## References

- `lib/game/components/buildings/building.dart`
- `lib/game/constants/balance.dart`
- `lib/game/managers/enemy_commander.dart`
- `lib/game/managers/normal_ai_strategy.dart`
- `lib/game/tower_conquest_game.dart`
- `orchestrator/PHASE3_ARCHITECTURE_AUDIT.md`
- `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md`
