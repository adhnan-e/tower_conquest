/// Centralised sprite path construction.
///
/// Paths are **relative to `assets/images/`**, not to the project root. Flame's
/// `Sprite.load` prepends `assets/images/` itself, so including that prefix here
/// (as `01_FLUTTER_FLAME_GUIDE.md` §6 does) produces
/// `assets/images/assets/images/...` and the load always fails.
///
/// Naming follows the catalog convention in
/// `planning/03_assets/01_ASSET_CATALOG_PRODUCTION.md` §1.1:
/// `<type>_tier<N>_base.png` for the tintable grayscale layer and
/// `<type>_tier<N>_detail.png` for the fixed-colour layer.
class AssetPaths {
  AssetPaths._();

  static const String buildingsDir = 'buildings/';
  static const String unitsDir = 'units/';
  static const String environmentDir = 'environment/';
  static const String effectsDir = 'effects/';
  static const String uiDir = 'ui/';
  static const String progressionDir = 'progression/';

  static String getBuildingBasePath(String type, int tier) =>
      '$buildingsDir${type}_tier${tier}_base.png';

  static String getBuildingDetailPath(String type, int tier) =>
      '$buildingsDir${type}_tier${tier}_detail.png';

  static String getUnitBasePath(String type, int tier) =>
      '$unitsDir${type}_tier${tier}_base.png';

  static String getUnitDetailPath(String type, int tier) =>
      '$unitsDir${type}_tier${tier}_detail.png';

  static String getTerrainPath(String terrainType) =>
      '${environmentDir}terrain_$terrainType.png';

  static String getEffectPath(String effectType) =>
      '${effectsDir}effect_$effectType.png';

  static String getUIButtonBasePath(String buttonType) =>
      '${uiDir}ui_button_${buttonType}_base.png';

  static String getUIButtonDetailPath(String buttonType) =>
      '${uiDir}ui_button_${buttonType}_detail.png';

  /// Building archetypes with Phase 1 art (balance §1.1).
  static const List<String> buildingTypes = [
    'barracks',
    'tower',
    'factory',
    'command_center',
  ];

  /// Unit classes with Phase 1 art (balance §2.1).
  static const List<String> unitTypes = [
    'infantry',
    'heavy_soldier',
    'scout',
  ];

  /// Every sprite delivered in the Phase 1 art pack: the four building types
  /// and three unit classes, base and detail layers, all at Tier 1.
  ///
  /// Preloaded at start-up so components never wait on a decode mid-match —
  /// see [AssetManager.preload].
  static List<String> phase1Sprites() => [
        for (final type in buildingTypes) ...[
          getBuildingBasePath(type, 1),
          getBuildingDetailPath(type, 1),
        ],
        for (final type in unitTypes) ...[
          getUnitBasePath(type, 1),
          getUnitDetailPath(type, 1),
        ],
      ];
}
