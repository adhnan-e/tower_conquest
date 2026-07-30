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

  /// Every Tier 2-5 building sprite the Phase 2 upgrade system can display.
  ///
  /// None of these exist yet — the orchestrator generates them after this PR
  /// merges (`planning/04_implementation/02_PHASE2_IMPLEMENTATION_PLAN.md`
  /// §"Asset Readiness"). Preloading the list anyway is safe and intentional:
  /// [AssetManager.preload] only decodes paths the asset manifest actually
  /// lists, so every one of these is silently skipped today, and the moment a
  /// Tier 2 PNG is bundled, this list already names it and it starts
  /// preloading with no further code change — the same drop-in property
  /// [phase1Sprites] gave the Tier 1 art.
  ///
  /// Units are not listed: only buildings gain tiers in Phase 2 (units stay
  /// Tier 1 — see `02_PHASE2_IMPLEMENTATION_PLAN.md` System 2).
  static List<String> phase2Sprites() => [
        for (final type in buildingTypes)
          for (var tier = 2; tier <= 5; tier++) ...[
            getBuildingBasePath(type, tier),
            getBuildingDetailPath(type, tier),
          ],
      ];
}
