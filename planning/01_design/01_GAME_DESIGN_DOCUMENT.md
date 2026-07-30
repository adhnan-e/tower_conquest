# Tower Conquest: Complete Game Design Document

## Executive Summary

**Tower Conquest** is a fast-paced, 2D tactical tower-conquest strategy game designed for mobile platforms (iOS/Android) using Flutter with the Flame game engine. The game emphasizes quick decision-making, strategic node management, and overwhelming opponents through intelligent unit routing and tower upgrades.

**Target Audience:** Mobile gamers aged 13+, casual to mid-core strategy game enthusiasts  
**Platform:** iOS, Android (Flutter + Flame)  
**Visual Style:** Cute Tactical—minimalist geometry, soft rounded edges, flat shading, high-contrast faction colors via runtime tinting  
**Core Loop Duration:** 2-5 minutes per match (perfect for mobile play sessions)

---

## 1. Project Vision & Orchestration

### 1.1 Orchestration Model

This project follows a **producer-developer split model**:

- **Orchestrator Role (Manus AI):** Defines gameplay systems, maintains the asset production pipeline, generates original 2D game assets tailored for Flutter/Flame, and structures level progression and content pacing.
- **Developer Role (User):** Implements the codebase in Flutter/Flame, handling architecture, performance optimization, and production deployment.

This separation ensures clean design documentation, scalable asset workflows, and maintainable code architecture.

### 1.2 Game Concept

Players command "cute but tactical" armies to capture neutral and enemy nodes (towers/buildings) across a grid-based or free-form 2D map. The core loop revolves around resource generation (units), strategic deployment, and conquest through overwhelming opponents.

The game draws inspiration from the tactical tower-defense genre (e.g., Tower War - Tactical Conquest) but with an original design, gameplay balance, and asset aesthetic.

---

## 2. Core Gameplay Loop

The fundamental loop of Tower Conquest revolves around five repeating phases:

### 2.1 Generate Phase
Controlled buildings passively generate units over time based on their tier and building type. The generation rate is the primary resource flow in the game.

### 2.2 Deploy Phase
The player swipes, taps, or drags to select a source building and target building (neutral or enemy). Units begin traveling from the source to the target along a predefined path or calculated route.

### 2.3 Travel Phase
Units move along paths connecting nodes. If units from opposing factions meet on a path, they engage in automatic combat, eliminating each other based on their combat power values.

### 2.4 Engage Phase
When units reach an enemy or neutral building, they reduce its defense value by their combined combat power. If the building's defense reaches zero, the attacking faction captures it.

### 2.5 Capture Phase
Once captured, the building immediately switches faction ownership and begins generating units for the new owner. The building's defense resets to zero.

**Win Condition:** Capture the enemy's Command Center or all enemy-controlled buildings.  
**Loss Condition:** Lose all player-controlled buildings or the Command Center.

---

## 3. Game Mechanics & Systems

### 3.1 Node (Building) Mechanics

Buildings act as both defensive strongholds and unit spawners. Each building has the following attributes:

**Capacity:** The maximum number of units a building can hold. Excess units are sent to nearby allied buildings or wait in a queue.

**Generation Rate:** How many units the building produces per second. Measured in units/second (e.g., 1.0 = 1 unit per second).

**Defense Value:** The "health" of the building. Equals the number of units inside it, multiplied by the building's Defense Multiplier (based on tier and type).

**Tier Level:** Buildings can be upgraded from Tier 1 to Tier 5, increasing capacity, generation rate, and defense multiplier.

**Building Types:**
- **Barracks** – Balanced spawner. Moderate capacity and generation rate.
- **Tower** – Defense-focused. Lower capacity but high defense multiplier.
- **Factory** – Heavy spawner. Produces heavy units at a slower rate.
- **Command Center** – Primary hub. Highest capacity and generation rate. Must be protected.

### 3.2 Unit Mechanics

Units are the primary resource and combat element. Each unit has the following attributes:

**Movement Speed:** How fast units travel between nodes (pixels per second). Affects how quickly units can reach distant targets.

**Combat Power:** The unit's effectiveness in combat. When units collide on a path, they eliminate each other based on combat power. Example: 1 Heavy Soldier (combat power 2) defeats 2 Infantry (combat power 1 each).

**Unit Classes:**
- **Infantry** – Standard unit. Combat power 1. Balanced speed and cost.
- **Heavy Soldier** – Armored unit. Combat power 2. Slower but more durable.
- **Scout** – Fast unit. Combat power 0.5. Very fast but weak. Useful for quick captures.

### 3.3 Combat Resolution

When units collide on a path or at a node:

1. **Calculate Total Combat Power:** Sum the combat power of all units from each faction.
2. **Eliminate Units:** Units are eliminated proportionally based on combat power. The faction with higher total combat power loses fewer units.
3. **Continue Movement:** Surviving units continue toward their destination.

**Example:** 10 Player Infantry (total power 10) meet 5 Enemy Heavy Soldiers (total power 10). All units are eliminated. 0 units reach the destination.

**Example:** 10 Player Infantry (total power 10) meet 4 Enemy Infantry (total power 4). 4 of each are eliminated. 6 Player Infantry continue toward the target.

### 3.4 Upgrade System

Players can upgrade buildings in-match by spending accumulated units. Upgrading increases capacity, generation rate, and defense multiplier.

| Tier | Upgrade Cost (Units) | Capacity Bonus | Gen Rate Bonus | Defense Bonus |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 | N/A (Base) | +0 | +0% | +0% |
| Tier 2 | 20 | +10 | +10% | +10% |
| Tier 3 | 40 | +25 | +25% | +25% |
| Tier 4 | 70 | +45 | +40% | +40% |
| Tier 5 | 100 | +70 | +60% | +60% |

Upgrading is a core tactical decision: spend units now for long-term advantage, or keep units for immediate attack?

---

## 4. Economy & Progression

### 4.1 In-Match Economy

Units act as the primary resource. The player must decide:
- **Defend:** Keep units in towers to increase defense.
- **Attack:** Send units to enemy towers to capture them.
- **Upgrade:** Spend units to upgrade buildings for better generation rates.

This creates a dynamic tension between offense, defense, and infrastructure investment.

### 4.2 Meta-Progression

Completing levels awards persistent currency used to unlock permanent upgrades:

**Gold (Soft Currency):** Earned by completing levels. Used for basic permanent upgrades (e.g., +5% unit speed).

**Gems (Hard Currency):** Earned via achievements or in-app purchase. Used for premium cosmetic skins or instant unlocks.

**Research Tree:** Players spend Gold to unlock permanent buffs:
- **Logistics:** +5% unit movement speed.
- **Fortification:** +0.1x defense multiplier for all towers.
- **Recruitment:** -5% building upgrade cost.

---

## 5. Level Progression & Content Pacing

### 5.1 Level Structure

Each level presents a unique map layout with:
- **Player Starting Nodes:** 1-3 initial towers controlled by the player.
- **Enemy Starting Nodes:** 1-3 initial towers controlled by the AI opponent.
- **Neutral Nodes:** 0-5 uncontrolled towers available for capture.
- **Obstacles:** Walls, rocks, or terrain features that block unit paths.
- **Hazards:** Mines, spikes, or environmental damage zones.

### 5.2 Difficulty Progression

Levels are structured in campaigns, each introducing new mechanics and increasing difficulty:

**Campaign 1 (Levels 1-5):** Tutorial and basics. Single player tower vs. single enemy tower. Introduce unit movement and capture mechanics.

**Campaign 2 (Levels 6-15):** Multi-node maps. Introduce neutral nodes, upgrades, and unit classes.

**Campaign 3 (Levels 16-30):** Advanced tactics. Introduce obstacles, hazards, and multiple enemy factions.

**Campaign 4+ (Levels 31+):** Endgame content. Complex maps, multiple simultaneous threats, and high-difficulty AI.

---

## 6. AI & Opponent Behavior

The AI opponent uses a simple but effective decision tree:

1. **Assess Threat:** Identify the nearest player tower and its threat level.
2. **Generate Units:** Continuously spawn units from all controlled towers.
3. **Route Units:** Send units toward the nearest player tower or toward neutral towers to expand territory.
4. **Upgrade Strategically:** Upgrade towers when they have excess units and are not under immediate threat.
5. **Adapt:** Increase aggression if winning, increase defense if losing.

AI difficulty scales with level progression:
- **Easy:** Slower unit generation, less frequent upgrades.
- **Normal:** Balanced generation and upgrade frequency.
- **Hard:** Faster generation, more aggressive routing, strategic upgrades.

---

## 7. Visual Design & Art Direction

### 7.1 Aesthetic

**Style:** Cute Tactical—minimalist geometry, soft rounded edges, flat shading with subtle highlights.

**Color Palette:** High-contrast faction colors applied via runtime tinting in Flame:
- **Player:** Bright Blue (#2D8CFF)
- **Enemy:** Bright Red (#E74C3C)
- **Ally:** Green (#37C978)
- **Neutral:** Light Gray (#B7BDC8)

### 7.2 Asset Architecture

All tintable assets use a **base/detail layer system**:
- **Base Layer:** Neutral grayscale sprite (tinted at runtime).
- **Detail Layer:** Fixed-color emblems, insignia, or symbols (never tinted).

This reduces asset count by 65% compared to full-color variants while enabling unlimited faction colors and cosmetic skins.

---

## 8. User Interface (UI) & User Experience (UX)

### 8.1 Screen Flow

1. **Main Menu:** Play, Settings, Achievements, Shop.
2. **Level Select:** Campaign overview, level difficulty, rewards preview.
3. **Gameplay Screen:** Game board, HUD (resources, timers), unit/building controls.
4. **Victory Screen:** Rewards, next level button, replay option.
5. **Defeat Screen:** Retry, level select, or main menu.
6. **Pause Menu:** Resume, settings, quit.

### 8.2 HUD Elements

- **Resource Counter:** Displays total units available.
- **Timer:** Shows remaining time (if applicable).
- **Building Info Panel:** Displays selected building's stats (capacity, generation rate, tier).
- **Unit Info Panel:** Displays selected unit class's stats (speed, combat power).
- **Upgrade Button:** Allows in-match building upgrades.

---

## 9. Monetization & Live Ops

### 9.1 Monetization Model

**Free-to-Play with optional cosmetics:**
- All gameplay content is free.
- Cosmetic skins, building themes, and unit appearances are purchasable with Gems (hard currency).
- No pay-to-win mechanics.

### 9.2 Live Ops Framework

**Events:** Limited-time events with unique maps, special unit types, or themed cosmetics (e.g., Terminator crossover event).

**Seasonal Passes:** Optional cosmetic bundles tied to seasonal themes.

**Leaderboards:** Global and friend leaderboards for competitive play.

---

## 10. Technical Architecture Overview

### 10.1 Engine & Framework

- **Engine:** Flame (2D game engine built on Flutter).
- **Language:** Dart.
- **Target Platforms:** iOS, Android (web support optional).

### 10.2 Core Systems

- **Game Loop:** Flame's built-in update/render cycle.
- **Component System:** Flame's component-based architecture for buildings, units, effects.
- **Asset Management:** Centralized asset loading and caching via `AssetManager`.
- **Faction Tinting:** Runtime color tinting via Flame's `Paint` and `ColorFilter` system.
- **Pathfinding:** Simple vector-based movement or A* pathfinding for complex maps.
- **Physics:** Optional Forge2D for collision detection and physics (if needed).

---

## 11. Milestones & Production Roadmap

### Milestone 1: Core Mechanics Prototype (MVP)
- **Duration:** 4-6 weeks
- **Deliverables:** Basic node capture, unit spawning, movement, and combat.
- **Assets:** 4 grayscale sprites (1 building base/detail, 1 unit base/detail).

### Milestone 2: Advanced Structures & Combat
- **Duration:** 4-6 weeks
- **Deliverables:** Multiple building types, unit classes, upgrades, and AI.
- **Assets:** 16 grayscale sprites (4 building types × 2 layers, 4 unit classes × 2 layers).

### Milestone 3: Level Design & Progression
- **Duration:** 4-8 weeks
- **Deliverables:** 30+ levels, campaign structure, meta-progression.
- **Assets:** Terrain, obstacles, hazards, UI elements.

### Milestone 4: Polish & Launch
- **Duration:** 2-4 weeks
- **Deliverables:** Visual effects, audio, performance optimization, app store submission.
- **Assets:** Particle effects, achievement icons, cosmetic skins.

---

## 12. Success Metrics

- **Core Loop:** Players complete a full game loop (generate → deploy → engage → capture → win/lose) within 2-5 minutes.
- **Engagement:** Players return to play multiple levels in a single session.
- **Retention:** 30-day retention rate above 25%.
- **Performance:** Game runs at 60 FPS on mid-range devices (e.g., iPhone 11, Samsung Galaxy A50).
- **Balance:** Win rate between player and AI is approximately 50/50 on Normal difficulty.

---

## 13. References & Inspiration

This game is inspired by the tactical tower-defense genre, particularly games like:
- Tower War - Tactical Conquest (tower capture mechanics)
- Clash of Clans (base building, unit deployment)
- Polytopia (turn-based strategy, faction colors)

However, Tower Conquest is an **original design** with unique gameplay mechanics, balance, and visual aesthetic.
