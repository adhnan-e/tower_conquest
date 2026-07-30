# Tower Conquest: Flutter & Flame Implementation Guide

## 1. Project Setup & Architecture

### 1.1 Flutter Project Initialization

```bash
flutter create tower_conquest
cd tower_conquest
```

### 1.2 pubspec.yaml Dependencies

```yaml
name: tower_conquest
description: A tactical tower-conquest strategy game built with Flutter and Flame.
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flame: ^1.10.0
  flame_audio: ^2.1.0
  provider: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/buildings/
    - assets/images/units/
    - assets/images/environment/
    - assets/images/effects/
    - assets/images/ui/
    - assets/images/progression/
    - assets/audio/sfx/
    - assets/audio/music/
    - assets/data/
```

### 1.3 Project Directory Structure

```
tower_conquest/
├── lib/
│   ├── main.dart
│   ├── game/
│   │   ├── tower_conquest_game.dart
│   │   ├── constants/
│   │   │   ├── colors.dart
│   │   │   ├── asset_paths.dart
│   │   │   └── game_config.dart
│   │   ├── components/
│   │   │   ├── buildings/
│   │   │   │   ├── building.dart
│   │   │   │   ├── barracks.dart
│   │   │   │   ├── tower.dart
│   │   │   │   ├── factory.dart
│   │   │   │   └── command_center.dart
│   │   │   ├── units/
│   │   │   │   ├── unit.dart
│   │   │   │   ├── infantry.dart
│   │   │   │   ├── heavy_soldier.dart
│   │   │   │   └── scout.dart
│   │   │   ├── effects/
│   │   │   │   ├── explosion.dart
│   │   │   │   ├── hit_effect.dart
│   │   │   │   └── particle_effect.dart
│   │   │   ├── ui/
│   │   │   │   ├── hud.dart
│   │   │   │   ├── button.dart
│   │   │   │   └── health_bar.dart
│   │   │   └── map/
│   │   │       ├── game_map.dart
│   │   │       └── tile.dart
│   │   ├── managers/
│   │   │   ├── faction_manager.dart
│   │   │   ├── asset_manager.dart
│   │   │   ├── unit_manager.dart
│   │   │   ├── building_manager.dart
│   │   │   └── level_manager.dart
│   │   └── screens/
│   │       ├── main_menu.dart
│   │       ├── game_screen.dart
│   │       ├── pause_menu.dart
│   │       └── level_select.dart
│   └── models/
│       ├── building_data.dart
│       ├── unit_data.dart
│       ├── level_data.dart
│       └── faction.dart
├── assets/
│   ├── images/
│   │   ├── buildings/
│   │   ├── units/
│   │   ├── environment/
│   │   ├── effects/
│   │   ├── ui/
│   │   └── progression/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── data/
│       ├── levels.json
│       ├── buildings.json
│       └── units.json
└── pubspec.yaml
```

---

## 2. Core Flame Concepts

### 2.1 Game Class

The main game class extends `FlameGame` and manages the game loop, components, and camera.

```dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';

class TowerConquestGame extends FlameGame {
  late FactionManager factionManager;
  late LevelManager levelManager;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize managers
    factionManager = FactionManager();
    levelManager = LevelManager();
    
    // Set camera
    camera.viewfinder.position = size / 2;
    camera.viewfinder.anchor = Anchor.center;
    
    // Load initial level
    await levelManager.loadLevel(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Game logic updates happen here
  }

  @override
  void onDetach() {
    super.onDetach();
    factionManager.clearCache();
  }
}
```

### 2.2 Component System

Components are the building blocks of the game. Each building, unit, and effect is a component.

```dart
import 'package:flame/components.dart';

class GameComponent extends Component {
  Vector2 position;
  Vector2 size;

  GameComponent({
    required this.position,
    required this.size,
  });

  @override
  Future<void> onLoad() async {
    // Load resources
  }

  @override
  void update(double dt) {
    // Update logic
  }

  @override
  void render(Canvas canvas) {
    // Render logic
  }
}
```

### 2.3 Runtime Tinting with Paint

Flame uses `Paint` objects to apply color filters to sprites.

```dart
import 'dart:ui' as ui;

final paint = ui.Paint()
  ..colorFilter = ui.ColorFilter.mode(
    ui.Color(0xFF2D8CFF),  // Player blue
    ui.BlendMode.multiply,  // Blend mode
  );

sprite.render(canvas, overridePaint: paint);
```

---

## 3. Faction Color Management

### 3.1 Color Constants

Create `lib/game/constants/colors.dart`:

```dart
import 'dart:ui' as ui;

class FactionColors {
  static const Map<String, ui.Color> colors = {
    'player': ui.Color(0xFF2D8CFF),   // Bright Blue
    'enemy': ui.Color(0xFFE74C3C),    // Bright Red
    'ally1': ui.Color(0xFF37C978),    // Green
    'ally2': ui.Color(0xFFF39C12),    // Orange
    'neutral': ui.Color(0xFFB7BDC8),  // Light Gray
    'spectral': ui.Color(0xFF9B59B6), // Purple
  };

  static const Map<String, ui.BlendMode> blendModes = {
    'multiply': ui.BlendMode.multiply,
    'screen': ui.BlendMode.screen,
    'overlay': ui.BlendMode.overlay,
  };

  static ui.Color getColor(String faction) {
    return colors[faction] ?? colors['neutral']!;
  }

  static ui.BlendMode getBlendMode(String blendMode) {
    return blendModes[blendMode] ?? blendModes['multiply']!;
  }
}
```

### 3.2 Faction Manager

Create `lib/game/managers/faction_manager.dart`:

```dart
import 'dart:ui' as ui;
import '../constants/colors.dart';

class FactionManager {
  static final FactionManager _instance = FactionManager._internal();

  factory FactionManager() {
    return _instance;
  }

  FactionManager._internal();

  final Map<String, ui.Paint> _paintCache = {};

  ui.Paint getPaint(String faction, {String blendMode = 'multiply'}) {
    final key = '$faction:$blendMode';
    
    if (_paintCache.containsKey(key)) {
      return _paintCache[key]!;
    }

    final paint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(
        FactionColors.getColor(faction),
        FactionColors.getBlendMode(blendMode),
      );

    _paintCache[key] = paint;
    return paint;
  }

  void clearCache() {
    _paintCache.clear();
  }
}
```

---

## 4. Base Building Component

Create `lib/game/components/buildings/building.dart`:

```dart
import 'package:flame/components.dart';
import 'dart:ui' as ui;
import '../../managers/faction_manager.dart';
import '../../constants/asset_paths.dart';

class Building extends SpriteComponent {
  final String type;
  final int tier;
  final String faction;
  
  late Sprite baseSprite;
  late Sprite? detailSprite;
  late ui.Paint tintPaint;

  int unitsInside = 0;
  double generationRate = 1.0;
  int maxCapacity = 50;

  Building({
    required this.type,
    required this.tier,
    required this.faction,
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load base sprite (tintable)
    final basePath = AssetPaths.getBuildingBasePath(type, tier);
    baseSprite = await Sprite.load(basePath);

    // Load detail sprite (fixed colors)
    final detailPath = AssetPaths.getBuildingDetailPath(type, tier);
    try {
      detailSprite = await Sprite.load(detailPath);
    } catch (e) {
      detailSprite = null;
    }

    // Get tint paint for this faction
    tintPaint = FactionManager().getPaint(faction);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Generate units
    if (unitsInside < maxCapacity) {
      unitsInside += (generationRate * dt).toInt();
      if (unitsInside > maxCapacity) {
        unitsInside = maxCapacity;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Render base sprite with faction tint
    baseSprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
      overridePaint: tintPaint,
    );

    // Render detail sprite without tint
    if (detailSprite != null) {
      detailSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    }
  }

  Future<void> upgrade() async {
    if (tier < 5) {
      // Reload sprites for new tier
      final newBasePath = AssetPaths.getBuildingBasePath(type, tier + 1);
      baseSprite = await Sprite.load(newBasePath);

      final newDetailPath = AssetPaths.getBuildingDetailPath(type, tier + 1);
      try {
        detailSprite = await Sprite.load(newDetailPath);
      } catch (e) {
        detailSprite = null;
      }
    }
  }

  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }

  int getDefenseValue() {
    return (unitsInside * 1.0).toInt(); // Simplified: 1.0 is defense multiplier
  }
}
```

---

## 5. Base Unit Component

Create `lib/game/components/units/unit.dart`:

```dart
import 'package:flame/components.dart';
import 'dart:ui' as ui;
import '../../managers/faction_manager.dart';
import '../../constants/asset_paths.dart';

class Unit extends SpriteComponent {
  final String type;
  final int tier;
  final String faction;
  
  late Sprite baseSprite;
  late Sprite? detailSprite;
  late ui.Paint tintPaint;

  Vector2 targetPosition = Vector2.zero();
  double speed = 100.0;
  double combatPower = 1.0;

  Unit({
    required this.type,
    required this.tier,
    required this.faction,
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load base sprite (tintable)
    final basePath = AssetPaths.getUnitBasePath(type, tier);
    baseSprite = await Sprite.load(basePath);

    // Load detail sprite (fixed colors)
    final detailPath = AssetPaths.getUnitDetailPath(type, tier);
    try {
      detailSprite = await Sprite.load(detailPath);
    } catch (e) {
      detailSprite = null;
    }

    // Get tint paint for this faction
    tintPaint = FactionManager().getPaint(faction);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move towards target
    if (position != targetPosition) {
      final direction = (targetPosition - position).normalized();
      position += direction * speed * dt;

      // Stop if reached target
      if (position.distanceTo(targetPosition) < speed * dt) {
        position = targetPosition;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Render base sprite with faction tint
    baseSprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
      overridePaint: tintPaint,
    );

    // Render detail sprite without tint
    if (detailSprite != null) {
      detailSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    }
  }

  void moveTo(Vector2 target) {
    targetPosition = target;
  }

  void changeFaction(String newFaction) {
    faction = newFaction;
    tintPaint = FactionManager().getPaint(faction);
  }
}
```

---

## 6. Asset Paths Manager

Create `lib/game/constants/asset_paths.dart`:

```dart
class AssetPaths {
  static const String buildingsDir = 'assets/images/buildings/';
  static const String unitsDir = 'assets/images/units/';
  static const String environmentDir = 'assets/images/environment/';
  static const String effectsDir = 'assets/images/effects/';
  static const String uiDir = 'assets/images/ui/';
  static const String progressionDir = 'assets/images/progression/';

  static String getBuildingBasePath(String type, int tier) {
    return '${buildingsDir}${type}_tier${tier}_base.png';
  }

  static String getBuildingDetailPath(String type, int tier) {
    return '${buildingsDir}${type}_tier${tier}_detail.png';
  }

  static String getUnitBasePath(String type, int tier) {
    return '${unitsDir}${type}_tier${tier}_base.png';
  }

  static String getUnitDetailPath(String type, int tier) {
    return '${unitsDir}${type}_tier${tier}_detail.png';
  }

  static String getTerrainPath(String terrainType) {
    return '${environmentDir}terrain_${terrainType}.png';
  }

  static String getEffectPath(String effectType) {
    return '${effectsDir}effect_${effectType}.png';
  }

  static String getUIButtonBasePath(String buttonType) {
    return '${uiDir}ui_button_${buttonType}_base.png';
  }

  static String getUIButtonDetailPath(String buttonType) {
    return '${uiDir}ui_button_${buttonType}_detail.png';
  }
}
```

---

## 7. Main Entry Point

Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/tower_conquest_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Conquest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Conquest'),
      ),
      body: GameWidget(
        game: TowerConquestGame(),
      ),
    );
  }
}
```

---

## 8. Performance Optimization Tips

### 8.1 Asset Caching

Flame automatically caches loaded sprites. The `FactionManager` also caches `Paint` objects to avoid recreating them every frame.

### 8.2 Sprite Pooling

For units that are frequently spawned/destroyed, implement object pooling to reduce garbage collection pressure.

### 8.3 Batch Rendering

Group sprites by faction to reduce draw calls. Render all player units together, then all enemy units.

### 8.4 Efficient Pathfinding

Use simple vector-based movement for early prototypes. Implement A* pathfinding only if performance becomes an issue.

---

## 9. Development Workflow

### 9.1 Iterative Development

1. **Implement Core Loop:** Get basic building spawning and unit movement working.
2. **Add Combat:** Implement unit collision and combat resolution.
3. **Add UI:** Build HUD elements and menus.
4. **Add Levels:** Create level layouts and progression.
5. **Polish:** Add effects, audio, and visual improvements.

### 9.2 Testing

- Test on multiple devices (emulator, physical devices).
- Profile performance using Flame's built-in profiler.
- Playtest balance regularly to ensure fun and fair gameplay.

### 9.3 Debugging

Use Flame's debug mode to visualize components, collisions, and performance metrics:

```dart
debugMode = true; // In TowerConquestGame.onLoad()
```

---

## 10. Next Steps

1. Set up the Flutter project with the directory structure above.
2. Implement the `FactionManager` and base `Building`/`Unit` components.
3. Create a simple test level with 2 buildings and basic unit spawning.
4. Test runtime tinting with different faction colors.
5. Iterate on gameplay mechanics and balance.

This guide provides the foundation for building Tower Conquest in Flutter with Flame. Refer to the Flame documentation for advanced topics like physics, animations, and particle systems.
