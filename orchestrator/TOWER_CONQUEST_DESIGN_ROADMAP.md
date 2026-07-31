# Tower Conquest Design Roadmap

**Purpose:** Reconcile the Tower War gameplay reference with the current Tower Conquest architecture and map mechanics to implementation phases.

**Status:** Design reference document. Does not change Phase 3 Stage 1 scope.

**Source:** Tower War gameplay analysis (YouTube: tQYsItaPDsg) and current Tower Conquest codebase.

---

## 1. Observed Tower War Mechanics

The following mechanics are directly observable in the Tower War reference video:

| Mechanic | Observable evidence | Tower Conquest status |
|---|---|---|
| **Path creation via swipe** | Player swipes from source to target tower; path appears and troops flow | ✅ Implemented (Phase 2) |
| **Continuous troop spawning** | Troops spawn at constant rate from source tower | ✅ Implemented (Phase 2) |
| **Troop movement along paths** | Troops travel at constant speed toward destination | ✅ Implemented (Phase 2) |
| **Path severance via swipe** | Swiping across path cancels it; troop flow stops | ✅ Implemented (Phase 2) |
| **Numerical tower state** | Each tower displays unit count | ✅ Implemented (Phase 2) |
| **Passive generation** | Tower count increases over time; "+1" animations visible | ✅ Implemented (Phase 2) |
| **Arrival combat (1-for-1)** | Arriving troops decrement tower count by 1 per unit | ✅ Implemented (Phase 2) |
| **Capture on zero** | Tower changes color when count reaches zero | ✅ Implemented (Phase 2) |
| **Intersecting-lane collision** | Opposing troops collide mid-path and eliminate each other | ✅ Implemented (Phase 2) |
| **Multiple simultaneous paths** | Single tower can send troops along multiple paths at once | ✅ Implemented (Phase 2) |
| **Neutral capture points** | Grey towers are capturable by any faction | ✅ Implemented (Phase 2) |
| **Level topology variation** | Different map layouts with obstacles and chokepoints | ⚠️ Partially ready (Phase 3 Stage 1 adds data; obstacles deferred) |
| **Special buildings** | Visually distinct structures (factories, command centers) | ✅ Implemented (Phase 1 art; Phase 2 balance) |

### Verified Current Implementation

The core gameplay loop is already complete. Tower Conquest implements all directly observable Tower War mechanics at the gameplay level. The current two-node Barracks-vs-Barracks match demonstrates the full combat, capture, and real-time strategy flow.

---

## 2. Tower Conquest Architecture vs. Tower War Reference

### What Tower Conquest Already Has

The following systems are production-ready and match Tower War design:

**Real-time unit flow (Phase 2):**
- `Unit` component spawns continuously from source `Building` at `generationRate`
- `Unit` travels along `PathLink` at constant speed
- On arrival, `Unit` decrements target building's `unitsInside`
- On zero units, building is captured and faction changes

**Path management (Phase 2):**
- `PathLink` connects two `Building` instances
- Tap callback allows path creation and severance
- Multiple paths from one building are supported

**Balance and progression (Phase 2):**
- `BuildingBalance` defines per-type base stats and tier multipliers
- `Building.upgrade()` increases stats and costs garrison units
- Defence value = `unitsInside * defenseMultiplier`

**AI opponent (Phase 2):**
- `EnemyCommander` drives AI decisions via injected `AIStrategy`
- `NormalAIStrategy` implements tactical heuristics (threat, target selection, expansion, upgrades)

### What Needs Data-Driven Levels (Phase 3 Stage 1)

The current implementation uses hard-coded two-node maps. To support multiple levels and campaigns:

**Level data model:**
- JSON schema for level metadata, node placement, ownership, starting garrisons, and links
- Immutable `LevelData` and `NodeData` types
- Validation and fallback behavior

**Level loader:**
- Asynchronous JSON parsing and validation
- Runtime factory that wires `BuildingBalance` to every node
- Link resolution from authored node IDs

**Default playable level:**
- JSON migration of the current two-node Barracks match
- Regression tests to confirm identical behavior

### What Remains Deferred (Phase 3 Stages 2–5)

The following features are not yet implemented and are outside Stage 1:

| Feature | Why deferred | Expected phase |
|---|---|---|
| **Campaign UI and level selection** | Requires confirmed level catalog and progression design | Phase 3 Stage 2 |
| **30+ campaign levels** | Requires playtest loop and balance validation | Phase 3 Stage 2–3 |
| **Obstacles and collision** | Requires pathfinding algorithm and level-theme confirmation | Phase 3 Stage 3 |
| **Hazards and special effects** | Requires gameplay design review and asset production | Phase 3 Stage 4 |
| **Research and meta-progression** | Requires immutable unlock state and derived-modifier design | Phase 3 Stage 4 |
| **Difficulty-specific AI** | Requires strategy parameterization and difficulty design | Phase 3 Stage 5 |
| **Terrain art and themes** | Requires level themes and original asset generation | Phase 3 Stage 2–3 |
| **Advanced buildings (Tier 2–5 units)** | Requires unit-tier progression design and art | Phase 3 Stage 5 |

---

## 3. Phase 3 Stage 1 Scope and Boundaries

### What Stage 1 Delivers

**Typed level data model** — Immutable Dart classes for level metadata, nodes, links, and validation results. The canonical JSON schema is defined in `PHASE3_DEVELOPER_PROMPT.md`.

**JSON asset loading** — Levels stored under `assets/levels/` with directory inclusion in `pubspec.yaml`. The loader must support asynchronous parsing, validation, and error reporting.

**Runtime factory** — Adapter that converts valid `NodeData` into correctly configured `Building` instances using `BuildingBalance.baseStatsFor()` for all type-specific stats. Link resolution uses a loader-local `Map<String, Building>` to convert authored node IDs to `PathLink` endpoints.

**Default playable level** — JSON version of the current two-node Barracks match at coordinates `(0, 220)` and `(0, -220)` with starting garrisons of 10 units each. Regression tests confirm identical behavior to the hard-coded version.

**Defensive fallback** — Separate testable fallback for unreadable or missing content. Schema errors must remain observable rather than silently being treated as valid.

**Focused tests** — Unit/integration coverage for parsing, validation, balance wiring, link resolution, fallback behavior, and regression.

### What Stage 1 Does NOT Include

- Campaign UI or level-selection screens
- Campaign content production (30+ levels)
- Obstacle collision or pathfinding
- Hazards, special effects, or environmental interactions
- Research, persistent progression, or meta-progression
- Difficulty-specific AI behavior or strategy parameterization
- New artwork or terrain themes
- Advanced buildings or higher-tier units

---

## 4. Implementation Sequencing for Phase 3

The following roadmap organizes Phase 3 into logical stages, each building on the previous:

| Stage | Scope | Deliverables | Dependencies |
|---|---|---|---|
| **Stage 1** | Data-driven level foundation | Level schema, loader, factory, default level, tests | None (builds on Phase 2) |
| **Stage 2** | Campaign structure and UI | Level catalog, selection UI, progression tracking, 10–15 levels | Stage 1 complete |
| **Stage 3** | Obstacles and level themes | Pathfinding, collision, terrain art, obstacle mechanics | Stage 2 complete, terrain assets |
| **Stage 4** | Research and meta-progression | Unlock state, derived modifiers, research UI, balance tuning | Stage 3 complete |
| **Stage 5** | Difficulty and advanced content | Strategy parameterization, Tier 2–5 units, hard/easy modes, 30+ levels | Stage 4 complete |

Each stage is independently reviewable and mergeable. Later stages do not block earlier ones.

---

## 5. Key Design Decisions

### String-Based Types and Factions

Tower Conquest uses `String` values for building types (`barracks`, `tower`, `factory`, `command_center`) and factions (`player`, `enemy`, `neutral`). This is intentional and matches Tower War's approach. Do not introduce enums in Stage 1 or later stages.

### No Building ID Field

`Building` has no `id` field or constructor parameter. Node IDs are level-data identifiers stored on `NodeData`. The runtime factory uses a loader-local map for link resolution only; it does not persist IDs on `Building`.

### Tier 1 Construction Only

Authored levels must use `tier: 1` for all nodes. The `Building.upgrade()` method consumes garrison units and is designed for in-match progression, not level initialization. A future stage may add a non-spending initialization API for higher starting tiers.

### Balance-Driven Stats

Every node type must have its stats populated from `BuildingBalance.baseStatsFor()`. The optional constructor defaults are appropriate only for Barracks-like Tier 1 values. Relying on them for Towers, Factories, or Command Centers would silently misconfigure the game.

### AI Injection Seam

Difficulty behavior is routed through the existing `AIStrategy` injection seam. Stage 1 uses the default `NormalAIStrategy()`. A later stage may add strategy parameterization or new strategy classes for difficulty tiers.

### Immutable Unlock State

Research and meta-progression must store only the set of unlocked IDs and derive modifiers from immutable base values on read. This prevents silent balance changes from repeated application or state reconstruction.

---

## 6. Deferred Decisions for Later Review

The following design questions are intentionally left open for later stages:

1. **Campaign structure:** How many levels per campaign? How are campaigns unlocked? What is the progression curve?
2. **Difficulty tiers:** What heuristic changes define Easy/Normal/Hard? Should they affect generation rates, defense multipliers, or AI strategy?
3. **Research catalog:** What unlocks are available? How are they balanced? Can they be reverted?
4. **Obstacle types:** What collision shapes are needed? How do they affect pathfinding?
5. **Terrain themes:** What visual themes are needed? How many unique tilesets?
6. **Advanced units:** What Tier 2–5 unit types exist? How do they differ from Tier 1?

These decisions will be made during Stage 2–5 design reviews, informed by playtest feedback and balance data from Stage 1 levels.

---

## 7. Guardrails for Implementation

The following constraints apply to all Phase 3 stages:

1. Do not weaken existing game-loop behavior or remove established test coverage.
2. Do not introduce mutable global state or side effects in level loading.
3. Do not add new constructor parameters to `Building` or `EnemyCommander` without orchestrator review.
4. Do not implement features listed as deferred without a dedicated design stage and approval.
5. Do not generate new assets without explicit orchestrator authorization.
6. Do not change the quality baseline (204 visible tests, 16 suite-loading events, 220 total successful events) without justification.

---

## 8. References

- **Tower War gameplay reference:** https://www.youtube.com/watch?v=tQYsItaPDsg
- **Tower Conquest Phase 2 implementation:** `lib/game/` (current main)
- **Phase 3 Stage 1 specification:** `orchestrator/PHASE3_DEVELOPER_PROMPT.md`
- **Phase 3 architecture audit:** `orchestrator/PHASE3_ARCHITECTURE_AUDIT.md`
