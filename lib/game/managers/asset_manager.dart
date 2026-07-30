import 'package:flame/components.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../constants/asset_paths.dart';
import '../constants/balance.dart';

/// Loads sprites, tolerating art that has not been produced yet.
///
/// The obvious approach — call `Sprite.load` and catch the failure — has two
/// problems while the asset directories are still empty:
///
/// 1. A missing asset raises `FlutterError`, which extends `Error`, not
///    `Exception`. An `on Exception` catch does not stop it.
/// 2. Even with a correct catch, the rejected future surfaces as an unhandled
///    async error and logs a stack trace for every missing file on every start.
///
/// So instead of guessing, this consults the bundled asset manifest once and
/// only attempts loads that can actually succeed. A sprite that is not in the
/// bundle returns null immediately and the caller draws its placeholder.
///
/// This is what makes the handoff in `orchestrator/REQUIRED_PNGS.md` a pure
/// drop-in: the moment a PNG is bundled, the manifest lists it and the sprite
/// path takes over with no code change.
class AssetManager {
  static final AssetManager _instance = AssetManager._internal();

  factory AssetManager() => _instance;

  AssetManager._internal();

  /// Flame resolves sprite paths relative to this prefix.
  static const String imagePrefix = 'assets/images/';

  Set<String>? _bundledAssets;
  Future<void>? _loading;

  /// Sprites already decoded, keyed by their path relative to `assets/images/`.
  final Map<String, Sprite> _sprites = {};

  /// Reads the asset manifest once and caches the result.
  Future<void> ensureManifestLoaded() {
    return _loading ??= _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _bundledAssets = manifest.listAssets().toSet();
    } catch (_) {
      // No manifest at all (some test harnesses). Treat every asset as absent
      // and fall back to placeholders rather than failing to start.
      _bundledAssets = const {};
    }
  }

  /// Whether [path] — relative to `assets/images/` — is in the bundle.
  bool hasImage(String path) {
    return _bundledAssets?.contains('$imagePrefix$path') ?? false;
  }

  /// Decodes [paths] up front and holds them for synchronous lookup.
  ///
  /// Called once at start-up with [AssetPaths.phase1Sprites]. Without it the
  /// first unit of each class would decode its PNG mid-match, and — now that
  /// there is no placeholder to draw in the meantime — would be invisible for
  /// those frames.
  Future<void> preload(Iterable<String> paths) async {
    await ensureManifestLoaded();

    for (final path in paths) {
      if (_sprites.containsKey(path)) continue;
      final sprite = await tryLoadSprite(path);
      if (sprite != null) {
        _sprites[path] = sprite;
      }
    }
  }

  /// The already-decoded sprite at [path], or null if it was never preloaded
  /// or is not bundled.
  Sprite? sprite(String path) => _sprites[path];

  /// Loads the sprite at [path], or returns null if it is not bundled.
  ///
  /// Prefer [sprite] after [preload]; this remains for paths outside the
  /// preloaded set, such as the Tier 2-5 art that Phase 2 will deliver.
  Future<Sprite?> tryLoadSprite(String path) async {
    await ensureManifestLoaded();
    if (!hasImage(path)) return null;

    final cached = _sprites[path];
    if (cached != null) return cached;

    try {
      final sprite = await Sprite.load(path);
      _sprites[path] = sprite;
      return sprite;
    } catch (_) {
      // Listed but unreadable (truncated or corrupt file). Still no reason to
      // take the whole game down.
      return null;
    }
  }

  /// The base (tintable) sprite for [type] at [tier], falling back to Tier 1
  /// art if this tier has not been generated yet (Phase 2 ships buildings
  /// only at Tier 1; Tiers 2-5 art lands after this PR merges — see
  /// `orchestrator/PHASE2_DEVELOPER_PROMPT.md`).
  ///
  /// Deliberately a distinct method from [sprite], not an overload of it:
  /// [sprite] is keyed by a full asset path and is already used throughout
  /// the codebase and its tests, so giving a *different* method the type/tier
  /// signature avoids colliding with that established, working contract.
  Future<Sprite?> buildingBaseSprite(String type, int tier) {
    return _tierAwareSprite(AssetPaths.getBuildingBasePath, type, tier);
  }

  /// The detail (untinted) sprite for [type] at [tier]. Same Tier 1 fallback
  /// as [buildingBaseSprite].
  Future<Sprite?> buildingDetailSprite(String type, int tier) {
    return _tierAwareSprite(AssetPaths.getBuildingDetailPath, type, tier);
  }

  Future<Sprite?> _tierAwareSprite(
    String Function(String type, int tier) pathFor,
    String type,
    int tier,
  ) async {
    final clampedTier =
        tier.clamp(BuildingBalance.minTier, BuildingBalance.maxTier);

    final requested = await tryLoadSprite(pathFor(type, clampedTier));
    if (requested != null) return requested;

    if (clampedTier == BuildingBalance.minTier) return null;
    return tryLoadSprite(pathFor(type, BuildingBalance.minTier));
  }

  /// Drops the cached manifest and sprites. Intended for tests.
  void reset() {
    _bundledAssets = null;
    _loading = null;
    _sprites.clear();
  }
}
