# Tower Conquest: Development Prompt

*Copy and paste the following prompt into your preferred AI coding assistant (like Cursor, Copilot, or ChatGPT) to begin implementation.*

***

**Context:**
I am building a 2D tactical tower-conquest mobile game using Flutter and the Flame game engine. The game is called "Tower Conquest". I have a complete Game Design Document, Asset Catalog, and Implementation Architecture already planned out. 

**Game Mechanics Summary:**
- Gridless 2D map.
- Buildings (nodes) generate units over time.
- Players swipe from a source building to a target building to send units.
- Units travel along paths. If opposing units meet, they destroy each other based on combat power.
- When units reach an enemy building, they reduce its defense. If defense hits 0, the building is captured.
- Buildings can be upgraded (Tiers 1-5) to increase capacity and generation rate.
- **Crucial Visual Architecture:** We are using a runtime color-tinting system. Sprites are grayscale PNGs. We use Flame's `Paint` and `ColorFilter` with `BlendMode.multiply` to color the sprites dynamically based on faction (Player = Blue, Enemy = Red, Neutral = Gray).

**Your Task:**
Act as an expert Flutter and Flame game developer. I want to build the Minimum Viable Product (MVP) of this game based on my architecture. 

Please provide the complete Dart code for the following files, ensuring they follow Flame best practices (using `FlameGame`, `SpriteComponent`, and the component lifecycle):

1. **`lib/game/constants/colors.dart`**: Define the faction colors (player, enemy, neutral) and a `FactionManager` singleton that caches and returns Flame `Paint` objects with the correct `ColorFilter`.
2. **`lib/game/components/buildings/building.dart`**: A `SpriteComponent` that represents a node. It needs to:
   - Load a grayscale sprite.
   - Apply the faction tint using the `FactionManager`.
   - Have an `update` loop that increments an internal `unitsInside` counter based on a `generationRate`.
   - Have a `render` method that draws the tinted sprite, and draws a simple text counter showing `unitsInside`.
3. **`lib/game/components/units/unit.dart`**: A `SpriteComponent` that represents a moving soldier. It needs to:
   - Load a grayscale sprite.
   - Apply the faction tint.
   - Move toward a `targetPosition` at a defined `speed` in its `update` loop.
   - Remove itself from the game when it reaches the target.
4. **`lib/game/tower_conquest_game.dart`**: The main `FlameGame` class that:
   - Spawns 1 Player Building and 1 Enemy Building.
   - Implements simple input handling (e.g., Flame's `TapCallbacks` or `DragCallbacks`) to allow the user to tap the Player Building, then tap the Enemy Building, which spawns a `Unit` component that travels between them.

Please write clean, well-commented code. Assume I have already run `flutter create` and added `flame: ^1.10.0` to my pubspec.yaml.
