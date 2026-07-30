# Tower Conquest: Gameplay Systems & Balance

## 1. Building Systems & Balance

Buildings are the primary nodes in the game. They generate units, hold capacity, and act as defensive structures.

### 1.1 Building Types & Base Stats (Tier 1)

| Building Type | Role | Max Capacity | Gen Rate (units/s) | Defense Multiplier | Upgrade Cost | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Barracks** | Balanced Spawner | 50 | 1.0 | 1.0x | 20 | Standard node. Reliable generation. |
| **Tower** | Defense Focus | 30 | 0.67 | 1.5x | 20 | Lower capacity, but units count more for defense. |
| **Factory** | Heavy Spawner | 40 | 0.5 | 1.2x | 20 | Spawns heavy units. Slower generation. |
| **Command Center** | Primary Hub | 100 | 1.25 | 2.0x | N/A | Must be protected. Highest capacity and speed. |

### 1.2 Upgrade Progression (Tiers 1-5)

Upgrading a building costs accumulated units from that building. Upgrades increase capacity, generation rate, and defense multiplier.

| Tier | Upgrade Cost | Capacity Bonus | Gen Rate Bonus | Defense Bonus | Visual Change |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | N/A (Base) | +0 | +0% | +0% | Basic structure. |
| **Tier 2** | 20 | +10 | +10% | +10% | Added fortifications. |
| **Tier 3** | 40 | +25 | +25% | +25% | Larger footprint, more details. |
| **Tier 4** | 70 | +45 | +40% | +40% | Heavy armor plating. |
| **Tier 5** | 100 | +70 | +60% | +60% | Epic scale, glowing elements. |

**Example:** A Tier 1 Barracks has 50 capacity and 1.0 gen rate. When upgraded to Tier 2, it gains +10 capacity (60 total) and +10% gen rate (1.1 units/s).

### 1.3 Building Mechanics

**Unit Generation:** Buildings generate units continuously at their generation rate. When a building reaches capacity, generation pauses until units are sent elsewhere.

**Defense Value:** A building's defense equals `(Units Inside × Building Defense Multiplier)`. When units attack a building, they reduce its defense by their combined combat power.

**Capture:** When a building's defense reaches zero, it is captured by the attacking faction. The building immediately resets to 0 units and begins generating for the new owner.

**Faction Ownership:** Buildings display their faction color via runtime tinting. A player-owned Barracks is tinted blue; an enemy-owned Barracks is tinted red.

---

## 2. Unit Systems & Balance

Units are the primary resource and combat element. Each unit has movement speed and combat power.

### 2.1 Unit Classes

| Unit Class | Speed (px/s) | Combat Power | Spawns From | Cost (units) | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Infantry** | 100 | 1.0 | Barracks, Command | 1 | Standard unit. Balanced speed and power. |
| **Heavy Soldier** | 60 | 2.0 | Factory | 1 | Slow but strong. Takes 2 Infantry to defeat 1 Heavy. |
| **Scout** | 150 | 0.5 | Barracks (Tier 3+) | 1 | Very fast but weak. Useful for quick captures. |

### 2.2 Unit Spawning

Buildings spawn units of their designated type. Barracks spawn Infantry. Factories spawn Heavy Soldiers. Scouts are unlocked at Tier 3 Barracks.

When a building reaches capacity, new units wait in a queue. Once units are sent elsewhere, queued units are spawned immediately.

### 2.3 Unit Movement

Units travel from a source building to a target building along a predefined path or calculated route. Movement is continuous, and units move at their speed value (pixels per second).

**Pathfinding:** In early versions, use simple straight-line movement. In advanced versions, implement A* pathfinding to navigate around obstacles.

**Collision:** When units from opposing factions meet on a path, they engage in combat (see Combat Resolution below).

---

## 3. Combat & Capture Resolution

### 3.1 Path Combat

When units from opposing factions meet on a path between nodes:

1. **Calculate Total Combat Power:** Sum the combat power of all units from each faction.
2. **Eliminate Units Proportionally:** Units are eliminated based on the ratio of combat power.
3. **Continue Movement:** Surviving units continue toward their destination.

**Formula:**
```
Player Total Power = Sum of (Unit Combat Power) for all player units
Enemy Total Power = Sum of (Unit Combat Power) for all enemy units

If Player Total Power > Enemy Total Power:
  Player Units Eliminated = (Enemy Total Power / Player Total Power) × Player Unit Count
  Enemy Units Eliminated = All Enemy Units
Else:
  Player Units Eliminated = All Player Units
  Enemy Units Eliminated = (Player Total Power / Enemy Total Power) × Enemy Unit Count
```

**Example 1:** 10 Player Infantry (total power 10) meet 5 Enemy Heavy Soldiers (total power 10).
- Both sides have equal power.
- All units are eliminated.
- 0 units reach the destination.

**Example 2:** 10 Player Infantry (total power 10) meet 4 Enemy Infantry (total power 4).
- Player power (10) > Enemy power (4).
- Enemy units eliminated: All 4.
- Player units eliminated: (4 / 10) × 10 = 4.
- 6 Player Infantry continue toward the target.

### 3.2 Node Capture

When a unit reaches an enemy or neutral node:

1. **Check Building Defense:** Defense = (Units Inside × Defense Multiplier).
2. **Apply Damage:** Attacking units reduce defense by their combined combat power.
3. **Capture Trigger:** If defense ≤ 0, the attacking faction captures the node.
4. **Post-Capture:** The node resets to 0 units and begins generating for the new owner.

**Example:** 10 Player Infantry (total power 10) reach an Enemy Tower (Tier 1).
- Tower has 20 units inside (defense = 20 × 1.5 = 30).
- Attacking units reduce defense by 10 (30 - 10 = 20).
- Tower is not captured. 0 units remain.
- On the next attack, 10 more units could reduce defense to 10, and a third attack would capture it.

---

## 4. Meta-Progression & Economy

### 4.1 In-Match Economy

Units act as the primary resource. The player must decide:

**Defend:** Keep units in towers to increase defense. More units = higher defense = harder to capture.

**Attack:** Send units to enemy towers to reduce their defense and capture them.

**Upgrade:** Spend units to upgrade buildings for better generation rates and capacity.

This creates a dynamic tension. For example, a player might upgrade a tower to increase its generation rate, but this leaves it vulnerable to attack because fewer units are defending it.

### 4.2 Persistent Currency

**Gold (Soft Currency):** Earned by completing levels. Used for basic permanent upgrades.
- Earned: 10-50 Gold per level (based on difficulty and performance).
- Used for: Research tree upgrades, cosmetic themes.

**Gems (Hard Currency):** Earned via achievements or in-app purchase.
- Earned: 5-20 Gems per achievement, or purchased via IAP.
- Used for: Premium cosmetic skins, instant building upgrades, battle pass.

### 4.3 Research Tree (Permanent Upgrades)

Players spend Gold to unlock permanent buffs that apply to all future matches:

| Upgrade | Cost (Gold) | Effect | Notes |
| :--- | :--- | :--- | :--- |
| **Logistics I** | 50 | +5% unit movement speed | Stacks with other Logistics upgrades. |
| **Logistics II** | 100 | +5% unit movement speed | Total: +10%. |
| **Fortification I** | 50 | +0.1x defense multiplier for all towers | Stacks. |
| **Fortification II** | 100 | +0.1x defense multiplier for all towers | Total: +0.2x. |
| **Recruitment I** | 50 | -5% building upgrade cost | Reduces cost of in-match upgrades. |
| **Recruitment II** | 100 | -5% building upgrade cost | Total: -10%. |
| **Efficiency** | 75 | +5% unit generation rate | All buildings generate 5% faster. |

---

## 5. Difficulty & AI Behavior

### 5.1 Difficulty Levels

**Easy:** AI opponent is passive and slow.
- Unit generation rate: 80% of normal.
- Upgrade frequency: Every 30 seconds (if conditions allow).
- Aggression: Targets nearest player tower only.

**Normal:** AI opponent is balanced.
- Unit generation rate: 100% of normal.
- Upgrade frequency: Every 20 seconds.
- Aggression: Targets nearest player tower and expands to neutral towers.

**Hard:** AI opponent is aggressive and strategic.
- Unit generation rate: 120% of normal.
- Upgrade frequency: Every 15 seconds.
- Aggression: Targets multiple player towers, upgrades strategically, expands aggressively.

### 5.2 AI Decision Tree

The AI opponent uses a simple but effective decision tree:

1. **Assess Threat:** Identify the nearest player tower and its threat level (units inside).
2. **Generate Units:** Continuously spawn units from all controlled towers.
3. **Route Units:** Send units toward the nearest player tower or toward neutral towers to expand territory.
4. **Upgrade Strategically:** If a tower has excess units (> capacity × 0.7) and is not under immediate threat, upgrade it.
5. **Adapt:** Increase aggression if winning (more units than player), increase defense if losing.

---

## 6. Balance Tuning & Playtesting

### 6.1 Key Balance Metrics

**Win Rate:** On Normal difficulty, the player should win approximately 50% of matches. On Easy, 70%+. On Hard, 30%.

**Game Duration:** Matches should last 2-5 minutes on average. Too short (< 1 min) feels rushed. Too long (> 10 min) feels grindy.

**Upgrade Frequency:** Players should upgrade buildings 2-4 times per match. Too frequent feels mandatory; too rare feels pointless.

**Unit Diversity:** Players should use multiple unit classes. If one unit type dominates, rebalance combat power or generation rates.

### 6.2 Tuning Variables

If playtesting reveals imbalance, adjust these variables:

- **Generation Rate:** Increase/decrease to make matches faster or slower.
- **Combat Power:** Adjust unit combat power to favor certain strategies.
- **Defense Multiplier:** Increase/decrease to make buildings harder/easier to capture.
- **Upgrade Cost:** Increase/decrease to make upgrades more/less frequent.
- **AI Aggression:** Tune AI difficulty by adjusting generation rate and upgrade frequency.

---

## 7. Special Mechanics & Advanced Features

### 7.1 Neutral Nodes

Neutral nodes are uncontrolled towers available for capture by either player. They generate units slowly (0.5 units/s) and have no faction color (gray tint).

Capturing neutral nodes is a strategic decision: they provide additional unit generation but also give the opponent an opportunity to capture them.

### 7.2 Obstacles & Hazards

**Obstacles:** Walls, rocks, or terrain features that block unit paths. Units must navigate around them.

**Hazards:** Mines, spikes, or environmental damage zones. Units passing through hazards take damage (reduce unit count).

These add tactical depth by forcing players to plan routes carefully.

### 7.3 Special Abilities (Future)

Future updates could introduce special abilities:
- **Freeze:** Temporarily stop enemy units.
- **Boost:** Temporarily increase unit generation rate.
- **Nuke:** Deal massive damage to a single tower.

Abilities would be earned via upgrades or special events.

---

## 8. Balance Testing Checklist

Before each release, test the following:

- [ ] Win rate on Easy is 70%+.
- [ ] Win rate on Normal is 50%.
- [ ] Win rate on Hard is 30%.
- [ ] Average match duration is 2-5 minutes.
- [ ] Players upgrade buildings 2-4 times per match.
- [ ] No single unit type dominates all scenarios.
- [ ] Neutral nodes are captured in most matches.
- [ ] AI does not exploit obvious bugs or imbalances.
- [ ] Game runs at 60 FPS on mid-range devices.
- [ ] No obvious dominant strategies (e.g., "always upgrade first tower").

---

## 9. Economy Spreadsheet

### 9.1 Resource Flow

| Phase | Resource In | Resource Out | Net |
| :--- | :--- | :--- | :--- |
| **Generation** | Building generates units | — | +1-1.25 units/s per building |
| **Upgrade** | — | 20-100 units | -20-100 units |
| **Attack** | — | Units sent to enemy tower | -X units (may return as survivors) |
| **Capture** | Neutral/Enemy tower | — | +tower generation rate |

### 9.2 Example Economy (5-Minute Match)

**Player:**
- Start: 1 Barracks (Tier 1, 50 capacity, 1.0 gen rate).
- Minute 1: 60 units generated. 30 sent to neutral tower. 30 remain.
- Minute 2: Neutral tower captured. Now have 2 towers. 80 units generated. 40 sent to enemy tower.
- Minute 3: Upgrade Barracks to Tier 2 (cost 20 units). 70 units generated. 50 sent to enemy tower.
- Minute 4: 80 units generated. 60 sent to enemy tower.
- Minute 5: Enemy tower captured. Victory.

**Total units generated:** ~300 units over 5 minutes.  
**Total units spent:** ~150 units on attacks, 20 units on upgrade.  
**Remaining:** ~130 units in towers.

---

## 10. References

- Tower War - Tactical Conquest (gameplay inspiration)
- Clash of Clans (base building mechanics)
- Polytopia (faction colors, turn-based strategy)

This balance sheet is a living document and will be updated as playtesting reveals imbalances.
