# Tower Conquest: Asset Catalog & Production Roadmap

## 1. Asset Architecture Overview

All assets use a **tintable base/detail layer system** to enable runtime faction color tinting and reduce file count by 65%.

### 1.1 Layer System

**Base Layer (`*_base.png`):** Neutral grayscale sprite designed to be color-tinted at runtime. Contains the primary structure or unit body.

**Detail Layer (`*_detail.png`):** Fixed-color emblems, insignia, symbols, or highlights. Never tinted. Provides visual identity and breaks up the monotony of tinted sprites.

**Example:** A Barracks building consists of:
- `barracks_tier1_base.png` – White/gray building body (tinted blue for player, red for enemy).
- `barracks_tier1_detail.png` – Dark gray doorway and golden shield emblem (always visible, never tinted).

### 1.2 Tinting in Flame

In Flame (Flutter), tinting is applied via the `Paint` system:

```dart
final paint = Paint()
  ..colorFilter = ColorFilter.mode(
    Color(0xFF2D8CFF),  // Player blue
    BlendMode.multiply,  // Blend mode for tinting
  );

baseSprite.render(canvas, overridePaint: paint);
```

This allows a single `barracks_tier1_base.png` to be rendered in any faction color without creating separate PNGs.

---

## 2. Complete Asset List

### 2.1 Buildings (40 files)

**4 Building Types × 5 Tiers × 2 Layers (base + detail)**

#### Barracks (Balanced Spawner)
- `barracks_tier1_base.png` – Tier 1 base (tintable)
- `barracks_tier1_detail.png` – Tier 1 detail (fixed)
- `barracks_tier2_base.png` – Tier 2 base
- `barracks_tier2_detail.png` – Tier 2 detail
- `barracks_tier3_base.png` – Tier 3 base
- `barracks_tier3_detail.png` – Tier 3 detail
- `barracks_tier4_base.png` – Tier 4 base
- `barracks_tier4_detail.png` – Tier 4 detail
- `barracks_tier5_base.png` – Tier 5 base
- `barracks_tier5_detail.png` – Tier 5 detail

#### Tower (Defense Focus)
- `tower_tier1_base.png` – Tier 1 base
- `tower_tier1_detail.png` – Tier 1 detail
- `tower_tier2_base.png` – Tier 2 base
- `tower_tier2_detail.png` – Tier 2 detail
- `tower_tier3_base.png` – Tier 3 base
- `tower_tier3_detail.png` – Tier 3 detail
- `tower_tier4_base.png` – Tier 4 base
- `tower_tier4_detail.png` – Tier 4 detail
- `tower_tier5_base.png` – Tier 5 base
- `tower_tier5_detail.png` – Tier 5 detail

#### Factory (Heavy Spawner)
- `factory_tier1_base.png` – Tier 1 base
- `factory_tier1_detail.png` – Tier 1 detail
- `factory_tier2_base.png` – Tier 2 base
- `factory_tier2_detail.png` – Tier 2 detail
- `factory_tier3_base.png` – Tier 3 base
- `factory_tier3_detail.png` – Tier 3 detail
- `factory_tier4_base.png` – Tier 4 base
- `factory_tier4_detail.png` – Tier 4 detail
- `factory_tier5_base.png` – Tier 5 base
- `factory_tier5_detail.png` – Tier 5 detail

#### Command Center (Primary Hub)
- `command_center_tier1_base.png` – Tier 1 base
- `command_center_tier1_detail.png` – Tier 1 detail
- `command_center_tier2_base.png` – Tier 2 base
- `command_center_tier2_detail.png` – Tier 2 detail
- `command_center_tier3_base.png` – Tier 3 base
- `command_center_tier3_detail.png` – Tier 3 detail
- `command_center_tier4_base.png` – Tier 4 base
- `command_center_tier4_detail.png` – Tier 4 detail
- `command_center_tier5_base.png` – Tier 5 base
- `command_center_tier5_detail.png` – Tier 5 detail

### 2.2 Units (20 files)

**4 Unit Classes × 5 Tiers × 2 Layers (base + detail)**

#### Infantry (Standard Unit)
- `infantry_tier1_base.png` – Tier 1 base
- `infantry_tier1_detail.png` – Tier 1 detail
- `infantry_tier2_base.png` – Tier 2 base
- `infantry_tier2_detail.png` – Tier 2 detail
- `infantry_tier3_base.png` – Tier 3 base
- `infantry_tier3_detail.png` – Tier 3 detail
- `infantry_tier4_base.png` – Tier 4 base
- `infantry_tier4_detail.png` – Tier 4 detail
- `infantry_tier5_base.png` – Tier 5 base
- `infantry_tier5_detail.png` – Tier 5 detail

#### Heavy Soldier (Armored Unit)
- `heavy_soldier_tier1_base.png` – Tier 1 base
- `heavy_soldier_tier1_detail.png` – Tier 1 detail
- `heavy_soldier_tier2_base.png` – Tier 2 base
- `heavy_soldier_tier2_detail.png` – Tier 2 detail
- `heavy_soldier_tier3_base.png` – Tier 3 base
- `heavy_soldier_tier3_detail.png` – Tier 3 detail
- `heavy_soldier_tier4_base.png` – Tier 4 base
- `heavy_soldier_tier4_detail.png` – Tier 4 detail
- `heavy_soldier_tier5_base.png` – Tier 5 base
- `heavy_soldier_tier5_detail.png` – Tier 5 detail

#### Scout (Fast Unit)
- `scout_tier1_base.png` – Tier 1 base
- `scout_tier1_detail.png` – Tier 1 detail
- `scout_tier2_base.png` – Tier 2 base
- `scout_tier2_detail.png` – Tier 2 detail
- `scout_tier3_base.png` – Tier 3 base
- `scout_tier3_detail.png` – Tier 3 detail
- `scout_tier4_base.png` – Tier 4 base
- `scout_tier4_detail.png` – Tier 4 detail
- `scout_tier5_base.png` – Tier 5 base
- `scout_tier5_detail.png` – Tier 5 detail

#### Ranger (Ranged Unit - Future)
- `ranger_tier1_base.png` – Tier 1 base
- `ranger_tier1_detail.png` – Tier 1 detail
- (Additional tiers as needed)

### 2.3 Environment (30 files)

#### Terrain (12 types)
- `terrain_grass_plain.png` – Grassy plain (default)
- `terrain_grass_hill.png` – Grassy hill
- `terrain_desert_sand.png` – Desert sand
- `terrain_desert_rocky.png` – Rocky desert
- `terrain_snow_plain.png` – Snowy plain
- `terrain_snow_mountain.png` – Snowy mountain
- `terrain_volcanic_lava.png` – Volcanic lava
- `terrain_volcanic_ash.png` – Volcanic ash
- `terrain_water_shallow.png` – Shallow water
- `terrain_water_deep.png` – Deep water
- `terrain_forest_dense.png` – Dense forest
- `terrain_forest_sparse.png` – Sparse forest

#### Obstacles (9 types)
- `obstacle_rock_small.png` – Small rock
- `obstacle_rock_large.png` – Large rock
- `obstacle_tree_small.png` – Small tree
- `obstacle_tree_large.png` – Large tree
- `obstacle_wall_stone.png` – Stone wall
- `obstacle_wall_wooden.png` – Wooden wall
- `obstacle_bridge_stone.png` – Stone bridge
- `obstacle_bridge_wooden.png` – Wooden bridge
- `obstacle_cliff_edge.png` – Cliff edge

#### Hazards (8 types)
- `hazard_mine_active.png` – Active mine
- `hazard_mine_inactive.png` – Inactive mine
- `hazard_spikes_small.png` – Small spikes
- `hazard_spikes_large.png` – Large spikes
- `hazard_fire_pit.png` – Fire pit
- `hazard_ice_patch.png` – Ice patch
- `hazard_acid_pool.png` – Acid pool
- `hazard_void_zone.png` – Void zone

### 2.4 Effects (25 files)

#### Combat Effects (8 types)
- `effect_explosion_small.png` – Small explosion
- `effect_explosion_medium.png` – Medium explosion
- `effect_explosion_large.png` – Large explosion
- `effect_hit_physical.png` – Physical hit
- `effect_hit_energy.png` – Energy hit
- `effect_projectile_arrow.png` – Arrow projectile
- `effect_projectile_energy.png` – Energy projectile
- `effect_shield_hit.png` – Shield impact

#### Status Effects (8 types)
- `effect_status_burning.png` – Burning status
- `effect_status_frozen.png` – Frozen status
- `effect_status_poisoned.png` – Poisoned status
- `effect_status_stunned.png` – Stunned status
- `effect_status_buffed.png` – Buffed status
- `effect_status_debuffed.png` – Debuffed status
- `effect_status_shielded.png` – Shielded status
- `effect_status_invisible.png` – Invisible status

#### Environmental Effects (9 types)
- `effect_dust_cloud.png` – Dust cloud
- `effect_smoke_white.png` – White smoke
- `effect_smoke_black.png` – Black smoke
- `effect_rain_drops.png` – Rain drops
- `effect_snow_flakes.png` – Snow flakes
- `effect_lightning_bolt.png` – Lightning bolt
- `effect_wind_gust.png` – Wind gust
- `effect_sparkle_gold.png` – Gold sparkle
- `effect_sparkle_blue.png` – Blue sparkle

### 2.5 UI Elements (50 files)

#### Buttons (10 types × 2 layers)
- `ui_button_attack_base.png` – Attack button base
- `ui_button_attack_detail.png` – Attack button detail
- `ui_button_defend_base.png` – Defend button base
- `ui_button_defend_detail.png` – Defend button detail
- `ui_button_upgrade_base.png` – Upgrade button base
- `ui_button_upgrade_detail.png` – Upgrade button detail
- `ui_button_build_base.png` – Build button base
- `ui_button_build_detail.png` – Build button detail
- `ui_button_pause_base.png` – Pause button base
- `ui_button_pause_detail.png` – Pause button detail
- `ui_button_play_base.png` – Play button base
- `ui_button_play_detail.png` – Play button detail
- `ui_button_settings_base.png` – Settings button base
- `ui_button_settings_detail.png` – Settings button detail
- `ui_button_back_base.png` – Back button base
- `ui_button_back_detail.png` – Back button detail
- `ui_button_shop_base.png` – Shop button base
- `ui_button_shop_detail.png` – Shop button detail
- `ui_button_confirm_base.png` – Confirm button base
- `ui_button_confirm_detail.png` – Confirm button detail

#### Status Displays (7 types)
- `ui_health_bar_empty.png` – Empty health bar
- `ui_health_bar_full.png` – Full health bar
- `ui_mana_bar_empty.png` – Empty mana bar
- `ui_mana_bar_full.png` – Full mana bar
- `ui_experience_bar_empty.png` – Empty experience bar
- `ui_experience_bar_full.png` – Full experience bar
- `ui_timer_display.png` – Timer display

#### Icons (16 types)
- `ui_icon_building_barracks.png` – Barracks icon
- `ui_icon_building_tower.png` – Tower icon
- `ui_icon_building_factory.png` – Factory icon
- `ui_icon_building_command.png` – Command Center icon
- `ui_icon_unit_infantry.png` – Infantry icon
- `ui_icon_unit_heavy.png` – Heavy Soldier icon
- `ui_icon_unit_scout.png` – Scout icon
- `ui_icon_unit_ranger.png` – Ranger icon
- `ui_icon_resource_gold.png` – Gold icon
- `ui_icon_resource_gems.png` – Gems icon
- `ui_icon_resource_units.png` – Units icon
- `ui_icon_difficulty_easy.png` – Easy difficulty icon
- `ui_icon_difficulty_normal.png` – Normal difficulty icon
- `ui_icon_difficulty_hard.png` – Hard difficulty icon
- `ui_icon_faction_player.png` – Player faction icon
- `ui_icon_faction_enemy.png` – Enemy faction icon

#### Resource Counters (4 types)
- `ui_counter_gold.png` – Gold counter display
- `ui_counter_gems.png` – Gems counter display
- `ui_counter_units.png` – Units counter display
- `ui_counter_time.png` – Time counter display

#### Menu Panels (8 types)
- `ui_panel_main_menu.png` – Main menu panel
- `ui_panel_level_select.png` – Level select panel
- `ui_panel_settings.png` – Settings panel
- `ui_panel_inventory.png` – Inventory panel
- `ui_panel_shop.png` – Shop panel
- `ui_panel_achievements.png` – Achievements panel
- `ui_panel_leaderboard.png` – Leaderboard panel
- `ui_panel_pause.png` – Pause menu panel

#### Markers & Indicators (8 types)
- `ui_marker_spawn_point.png` – Spawn point marker
- `ui_marker_objective.png` – Objective marker
- `ui_marker_waypoint.png` – Waypoint marker
- `ui_marker_danger_zone.png` – Danger zone marker
- `ui_indicator_selected.png` – Selected indicator
- `ui_indicator_hovered.png` – Hovered indicator
- `ui_indicator_disabled.png` – Disabled indicator
- `ui_indicator_new.png` – New/notification indicator

### 2.6 Progression & Cosmetics (30 files)

#### Level Backgrounds (10 types)
- `level_bg_grassland.png` – Grassland level background
- `level_bg_desert.png` – Desert level background
- `level_bg_snow.png` – Snow level background
- `level_bg_volcanic.png` – Volcanic level background
- `level_bg_forest.png` – Forest level background
- `level_bg_underwater.png` – Underwater level background
- `level_bg_sky.png` – Sky level background
- `level_bg_night.png` – Night level background
- `level_bg_sunset.png` – Sunset level background
- `level_bg_abstract.png` – Abstract level background

#### Difficulty Indicators (5 types)
- `difficulty_indicator_tier1.png` – Tier 1 (easiest)
- `difficulty_indicator_tier2.png` – Tier 2
- `difficulty_indicator_tier3.png` – Tier 3 (medium)
- `difficulty_indicator_tier4.png` – Tier 4
- `difficulty_indicator_tier5.png` – Tier 5 (hardest)

#### Achievement Icons (10 types)
- `achievement_victory.png` – Victory achievement
- `achievement_speed_run.png` – Speed run achievement
- `achievement_no_damage.png` – No damage achievement
- `achievement_capture_all.png` – Capture all nodes achievement
- `achievement_upgrade_master.png` – Upgrade master achievement
- `achievement_unit_count.png` – Unit count achievement
- `achievement_gold_collector.png` – Gold collector achievement
- `achievement_gem_collector.png` – Gem collector achievement
- `achievement_level_complete.png` – Level complete achievement
- `achievement_campaign_complete.png` – Campaign complete achievement

#### Reward Chests (4 types)
- `reward_chest_common.png` – Common chest
- `reward_chest_uncommon.png` – Uncommon chest
- `reward_chest_rare.png` – Rare chest
- `reward_chest_epic.png` – Epic chest

---

## 3. Production Roadmap

### Phase 1: MVP Assets (80 files)
**Duration:** 2-3 weeks  
**Goal:** Provide enough assets to build a playable prototype.

**Deliverables:**
- All Tier 1 buildings (base + detail) – 8 files
- All Tier 1 units (base + detail) – 8 files
- Basic terrain (3 types) – 3 files
- Basic obstacles (3 types) – 3 files
- Essential UI buttons (5 types × 2 layers) – 10 files
- Status displays (3 types) – 3 files
- Basic icons (8 types) – 8 files
- Level backgrounds (2 types) – 2 files
- Combat effects (3 types) – 3 files
- Environmental effects (3 types) – 3 files

**Total: 52 files**

### Phase 2: Expansion (100 files)
**Duration:** 3-4 weeks  
**Goal:** Introduce building and unit tier variants, advanced terrain, and UI polish.

**Deliverables:**
- Tier 2-3 buildings (base + detail) – 24 files
- Tier 2-3 units (base + detail) – 24 files
- Advanced terrain (6 types) – 6 files
- Advanced obstacles (4 types) – 4 files
- Additional UI buttons (5 types × 2 layers) – 10 files
- Status effects (4 types) – 4 files
- Additional icons (8 types) – 8 files
- Additional level backgrounds (4 types) – 4 files
- Additional combat effects (4 types) – 4 files
- Hazards (4 types) – 4 files

**Total: 92 files**

### Phase 3: Polish (80 files)
**Duration:** 2-3 weeks  
**Goal:** Complete tier progression and add cosmetic variety.

**Deliverables:**
- Tier 4-5 buildings (base + detail) – 16 files
- Tier 4-5 units (base + detail) – 16 files
- Remaining terrain (3 types) – 3 files
- Remaining obstacles (2 types) – 2 files
- Remaining UI elements (10 types) – 10 files
- Remaining status effects (4 types) – 4 files
- Remaining icons (8 types) – 8 files
- Remaining level backgrounds (4 types) – 4 files
- Remaining combat effects (4 types) – 4 files
- Remaining hazards (4 types) – 4 files

**Total: 75 files**

### Phase 4: Content & Cosmetics (60 files)
**Duration:** 2-3 weeks  
**Goal:** Add cosmetic skins, achievements, and event-themed assets.

**Deliverables:**
- Cosmetic building skins (neon, steampunk, futuristic, ancient, nature, crystal) – 24 files
- Cosmetic unit skins – 12 files
- Achievement icons (10 types) – 10 files
- Reward chests (4 types) – 4 files
- Difficulty indicators (5 types) – 5 files
- Event-themed assets (holiday, crossover) – 5 files

**Total: 60 files**

---

## 4. Asset Specifications

### 4.1 Technical Specifications

**Format:** PNG with transparency  
**Resolution:** 512×512 pixels (for buildings/structures), 256×256 pixels (for units/effects)  
**Color Space:** sRGB  
**Compression:** Lossless PNG compression  
**Background:** Transparent (RGBA)

### 4.2 Design Guidelines

**Base Layer:**
- Use neutral white/gray color palette (RGB 200-255 for highlights, RGB 100-150 for shadows).
- Avoid pure black (use dark gray instead for better tinting).
- Ensure smooth gradients and soft edges for clean tinting results.

**Detail Layer:**
- Use fixed, thematic colors (e.g., golden emblems, dark doorways).
- Avoid colors that will be tinted (e.g., don't use white or gray).
- Keep details subtle to avoid visual clutter when layered over the base.

**Isometric Perspective:**
- All assets should use a consistent isometric angle (typically 45° or 30°).
- Maintain consistent lighting direction and shadow placement.

**Cute Tactical Aesthetic:**
- Use soft, rounded edges and minimalist geometry.
- Avoid overly complex details or realistic texturing.
- Maintain visual cohesion across all asset types.

---

## 5. Asset Naming Convention

All assets follow a consistent naming pattern:

```
[type]_[subtype]_tier[1-5]_[layer].png
```

**Examples:**
- `barracks_tier1_base.png` – Barracks Tier 1 base layer
- `infantry_tier2_detail.png` – Infantry Tier 2 detail layer
- `tower_tier3_base.png` – Tower Tier 3 base layer
- `ui_button_attack_base.png` – Attack button base layer
- `terrain_grass_plain.png` – Grassland terrain
- `effect_explosion_small.png` – Small explosion effect

---

## 6. Asset Integration Checklist

Before integrating assets into Flame:

- [ ] All assets are 512×512 or 256×256 pixels.
- [ ] All assets use PNG format with transparency.
- [ ] Base layers are neutral grayscale (no strong colors).
- [ ] Detail layers use fixed, thematic colors.
- [ ] All assets follow the naming convention.
- [ ] Isometric perspective is consistent across all assets.
- [ ] No assets exceed 500 KB file size.
- [ ] All assets have been visually reviewed for quality and consistency.

---

## 7. Future Asset Expansion

As the game grows, additional assets can be added:

- **Cosmetic Skins:** Themed building and unit appearances (neon, steampunk, futuristic, etc.).
- **Event Assets:** Limited-time event-themed buildings, units, and effects.
- **Animation Frames:** Multi-frame sprites for idle, attack, and death animations.
- **Particle Effects:** Advanced particle systems for explosions, magic, and environmental effects.
- **Audio Assets:** Sound effects and music (not covered in this document).

This asset catalog is a living document and will be updated as the project evolves.
