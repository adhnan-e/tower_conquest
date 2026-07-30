# Tower Conquest: Level Design & Pacing

## 1. Level Design Philosophy

Levels in Tower Conquest are designed to teach mechanics implicitly, escalate challenge smoothly, and reward strategic thinking over rapid tapping.

**Core Principles:**
- **Readability:** The player should understand the map layout, chokepoints, and threats within 3 seconds of the level loading.
- **Pacing:** Matches should last 2-5 minutes.
- **Asymmetry:** Later levels give the AI starting advantages (more towers, higher tiers) that the player must overcome through superior tactics.

---

## 2. Campaign 1: The Basics (Levels 1-5)

**Goal:** Teach core mechanics (spawning, moving, capturing, upgrading) without overwhelming the player.

### Level 1: First Contact (Tutorial)
- **Layout:** 1 Player Barracks (Tier 1), 1 Enemy Barracks (Tier 1). Direct path between them.
- **Mechanic Introduced:** Swiping to send units.
- **AI Behavior:** Passive (does not attack, only defends).
- **Win Condition:** Capture the enemy Barracks.

### Level 2: The Neutral Zone
- **Layout:** 1 Player Barracks, 1 Neutral Barracks, 1 Enemy Barracks.
- **Mechanic Introduced:** Capturing neutral nodes for economic advantage.
- **AI Behavior:** Easy. Will attempt to capture the neutral node after 10 seconds.
- **Strategy:** Player learns that capturing the neutral node first gives them a 2v1 unit generation advantage.

### Level 3: Upward Mobility
- **Layout:** 1 Player Barracks, 2 Enemy Barracks.
- **Mechanic Introduced:** Building upgrades.
- **AI Behavior:** Easy.
- **Strategy:** Player starts at a disadvantage. They must upgrade their single Barracks to Tier 2 to match the generation rate of the two enemy Barracks before attacking.

### Level 4: The Chokepoint
- **Layout:** 2 Player Barracks, 2 Enemy Barracks, separated by a narrow path (visual chokepoint).
- **Mechanic Introduced:** Path collision and combat resolution.
- **Strategy:** Player learns that sending units in a steady stream is less effective than waiting and sending a massive wave to break through the enemy line.

### Level 5: Command & Conquer (Boss Level)
- **Layout:** 1 Player Command Center, 2 Enemy Barracks, 1 Enemy Command Center.
- **Mechanic Introduced:** Command Centers (high capacity/generation, must protect).
- **AI Behavior:** Normal. Will actively target the player's Command Center.
- **Strategy:** Player must balance defending their Command Center while systematically dismantling the enemy's forward Barracks.

---

## 3. Campaign 2: Advanced Tactics (Levels 6-15)

**Goal:** Introduce unit classes, building variants, and more complex map layouts.

### Level 6: Heavy Machinery
- **Layout:** 1 Player Barracks, 1 Neutral Factory, 1 Enemy Barracks.
- **Mechanic Introduced:** Factories and Heavy Soldiers.
- **Strategy:** Player must capture the Factory to gain access to Heavy Soldiers, which easily defeat standard Infantry.

### Level 7: The Fortress
- **Layout:** 2 Player Barracks, 1 Enemy Tower (Tier 2).
- **Mechanic Introduced:** Defensive Towers (high defense multiplier).
- **Strategy:** Player learns that attacking a Tower requires overwhelming numbers, encouraging them to save up units to max capacity before attacking.

### Level 8: The Flank
- **Layout:** Player base in bottom left, Enemy base in top right. Two paths connect them: a direct path and a longer flanking path.
- **Mechanic Introduced:** Multi-path routing.
- **Strategy:** Player can tie up enemy forces on the direct path while sending a sneak attack via the flanking path.

### Level 10: The Swarm (Mini-Boss)
- **Layout:** 1 Player Command Center, 4 Enemy Barracks (Tier 1).
- **AI Behavior:** Aggressive. All enemy Barracks constantly send small waves.
- **Strategy:** Player must upgrade their Command Center to survive the initial onslaught, then counter-attack when the enemy is depleted.

### Level 15: Combined Arms (Boss Level)
- **Layout:** Player has 1 Barracks, 1 Factory. Enemy has 1 Tower, 1 Barracks, 1 Factory.
- **Strategy:** A true test of balancing Infantry (fast generation) and Heavy Soldiers (combat power) against a fortified enemy position.

---

## 4. Campaign 3: Environmental Hazards (Levels 16-30)

**Goal:** Introduce obstacles, hazards, and dynamic map elements.

### Level 16: The Wall
- **Layout:** Player and Enemy separated by a Wall obstacle. Units must walk around it.
- **Mechanic Introduced:** Obstacles affecting travel time.
- **Strategy:** Player must account for the longer travel time when timing their attacks.

### Level 20: Minefield
- **Layout:** 3 Neutral nodes in the center, surrounded by active mines.
- **Mechanic Introduced:** Hazards (units take damage passing through).
- **Strategy:** Player must decide if the unit loss from the mines is worth capturing the neutral nodes.

### Level 30: The Gauntlet (Boss Level)
- **Layout:** Player starts at the bottom. Must push through 3 layers of Enemy Towers and hazards to reach the Enemy Command Center at the top.
- **Strategy:** A war of attrition requiring careful upgrading and wave management.

---

## 5. Map Generation Data Structure

Levels will be stored in JSON format for easy loading by the `LevelManager`.

```json
{
  "level_id": 1,
  "name": "First Contact",
  "background": "terrain_grass_plain",
  "difficulty": "easy",
  "nodes": [
    {
      "id": "node_1",
      "type": "barracks",
      "tier": 1,
      "faction": "player",
      "x": 100,
      "y": 500,
      "starting_units": 10
    },
    {
      "id": "node_2",
      "type": "barracks",
      "tier": 1,
      "faction": "enemy",
      "x": 100,
      "y": 100,
      "starting_units": 10
    }
  ],
  "paths": [
    {
      "from": "node_1",
      "to": "node_2",
      "type": "direct"
    }
  ],
  "obstacles": [],
  "hazards": []
}
```

This structure allows for rapid creation of new levels without changing code.
