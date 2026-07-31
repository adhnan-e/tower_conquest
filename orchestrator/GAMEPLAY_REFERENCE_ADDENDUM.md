# Tower Conquest Gameplay Reference Addendum

**Purpose:** Map the supplied basic-gameplay tutorial frames to Tower Conquest architecture and identify UI/UX refinements for Phase 3 and beyond.

**Status:** Reference document. Does not change Phase 3 Stage 1 scope.

**Source:** Supplied gameplay screenshots (Level 1 and Level 2 tutorial sequences) and current Tower Conquest codebase.

---

## 1. Observed Tutorial Mechanics

The supplied frames show a multi-level tutorial progression with the following observable elements:

### Level 1 Tutorial Sequence

The Level 1 frames demonstrate the core interaction loop:

1. **Initial state:** Player-owned tower (red, 5 units) and two neutral towers (grey, 0 and 22 units) arranged in a triangle. Neutral towers are surrounded by a white circular range indicator.
2. **Path creation:** Player taps the red tower to select it, then taps a neutral tower to create a path and send a unit.
3. **Continuous flow:** Once a path exists, units flow continuously from the source tower along the path toward the destination.
4. **Path severance:** Player swipes across an active path to cut it, halting the unit flow.
5. **Arrival and capture:** When the neutral tower's unit count reaches zero, it changes color to the attacker's faction.
6. **Multi-target control:** Player can create multiple simultaneous paths from a single tower, directing units to different targets.

### Level 2 Tutorial Sequence

The Level 2 frames show a more complex scenario:

1. **Three-way conflict:** Red player tower (9 units), blue player tower (14 units), and a grey neutral tower (5 units) arranged in a line.
2. **Simultaneous sends:** Player sends units from both towers toward the neutral tower.
3. **Path interaction:** Active paths are highlighted in the faction color of the sending tower.
4. **Capture progression:** The neutral tower's count decreases as units arrive from both sources.

### Observable UI Elements

- **Level indicator:** Top-of-screen banner showing "LEVEL 1" or "LEVEL 2" with a progress bar (blue-to-red gradient).
- **Win condition text:** Overlaid on the game area, e.g., "Conquer all buildings to win" or "Capture the tower".
- **Unit counter:** Numerical display on each tower showing current garrison size.
- **Range indicator:** White circular outline around neutral towers (appears to indicate capture range or visibility).
- **Path visualization:** Thick colored band connecting towers, taking the faction color of the active sender.
- **Undo button:** Top-left corner (white arrow icon) for restarting the level.
- **Gesture hints:** On-screen text prompts like "Swipe to cut the path" when the mechanic is first introduced.

---

## 2. Mapping to Tower Conquest Architecture

### Already Implemented (Phase 2)

The core mechanics shown in the tutorial are fully implemented in Tower Conquest:

| Tutorial mechanic | Tower Conquest implementation | Status |
|---|---|---|
| Tower selection and tapping | `Building.onTapped` callback and `_onBuildingTapped` handler | ✅ Complete |
| Path creation between towers | `PathLink` component connecting two `Building` instances | ✅ Complete |
| Continuous unit spawning | `Building.generationRate` and `Unit` spawning loop | ✅ Complete |
| Unit movement along paths | `Unit.update()` with `targetPosition` and constant `speed` | ✅ Complete |
| Path severance via swipe | Tap-based path removal (implementation details TBD) | ⚠️ Partial |
| Arrival combat | `Unit.onArrived` callback and `_resolveArrival` handler | ✅ Complete |
| Capture on zero units | `Building.applyAttack` with faction change | ✅ Complete |
| Intersecting-lane collision | `Unit.onCollisionStart` with opposing-faction clash logic | ✅ Complete |
| Multi-path support | `PathLink` list and bidirectional routing | ✅ Complete |

### Deferred or Incomplete (Phase 3+)

The following UI/UX elements and refinements are not yet implemented:

| Tutorial element | Current status | Expected phase |
|---|---|---|
| **Level indicator banner** | Hard-coded level name only; no progress bar | Phase 3 Stage 2 (UI) |
| **Win condition overlay** | Result screen after match end; no mid-game prompt | Phase 3 Stage 2 (UI) |
| **Range indicators** | No visual range rings around towers | Phase 3 Stage 3 (optional) |
| **Gesture hints and prompts** | No tutorial text or hint system | Phase 3 Stage 2 (onboarding) |
| **Undo/restart button** | Restart is via result screen; no in-game undo | Phase 3 Stage 2 (UI) |
| **Path swipe interaction** | Tap-based path removal exists; swipe gesture not yet implemented | Phase 3 Stage 3 (input) |
| **Smooth path highlighting** | Paths highlight when selected; no animated transition | Phase 3 Stage 3 (polish) |

---

## 3. Phase 3 Stage 1 Scope Confirmation

**Stage 1 does not implement any of the deferred UI/UX elements listed above.** Stage 1 focuses exclusively on data-driven level loading and does not add onboarding, tutorial prompts, gesture refinement, or UI polish.

The core gameplay loop (selection, path creation, unit flow, capture) is already complete and will work identically with Stage 1's data-driven levels as it does with the current hard-coded two-node map.

---

## 4. Recommended UI/UX Refinements for Phase 3 Stage 2

When Phase 3 Stage 2 (Campaign Structure and UI) is scoped, the following refinements should be considered:

### Onboarding and Tutorial System

A dedicated tutorial system should introduce mechanics progressively. The first few levels should guide the player through:

1. **Level 1:** Basic selection and path creation (single source, single target)
2. **Level 2:** Multi-target sends (one source, multiple targets)
3. **Level 3:** Neutral capture and faction change
4. **Level 4:** Intersecting lanes and unit collision
5. **Level 5:** Path severance and tactical lane management

Each level should display a single, focused instruction at the start and hide it once the mechanic is demonstrated.

### UI Elements

The following UI elements should be added to improve clarity and usability:

- **Level progress banner:** Shows current level number, campaign, and a progress bar toward the win condition
- **Win condition prompt:** Displays the current objective (e.g., "Capture all enemy towers") as a persistent overlay
- **Gesture hints:** Context-sensitive text prompts that appear when a mechanic is first available (e.g., "Tap a tower to select it")
- **In-game restart button:** Allows quick level restart without navigating through a result screen
- **Path interaction feedback:** Visual or audio cue when a path is created or severed

### Input Refinement

The current tap-based path removal should be enhanced to support swipe gestures:

- **Swipe to create path:** Drag from source tower across the screen to destination tower
- **Swipe to sever path:** Drag across an active path to cut it
- **Tap fallback:** Maintain tap-based interaction for accessibility

---

## 5. Deferred Decisions

The following design questions remain open for Stage 2 and beyond:

1. **Tutorial progression:** How many tutorial levels are needed? Should they be mandatory or skippable?
2. **Difficulty curve:** How should level complexity scale across the campaign?
3. **Gesture design:** Should swipe gestures be required or optional alongside tap-based interaction?
4. **Visual polish:** Should range indicators, animated transitions, or particle effects be added?
5. **Accessibility:** What accessibility features are needed for different input modalities?

---

## 6. References

- **Supplied gameplay frames:** Basic tutorial sequence showing Level 1 and Level 2 gameplay
- **Tower Conquest Phase 2 implementation:** `lib/game/` (current main)
- **Phase 3 design roadmap:** `orchestrator/TOWER_CONQUEST_DESIGN_ROADMAP.md`
- **Phase 3 Stage 1 specification:** `orchestrator/PHASE3_DEVELOPER_PROMPT.md`
