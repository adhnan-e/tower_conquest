import 'package:flame/components.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

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

  /// Loads the sprite at [path], or returns null if it is not bundled.
  Future<Sprite?> tryLoadSprite(String path) async {
    await ensureManifestLoaded();
    if (!hasImage(path)) return null;

    try {
      return await Sprite.load(path);
    } catch (_) {
      // Listed but unreadable (truncated or corrupt file). Still no reason to
      // take the whole game down — fall back to the placeholder.
      return null;
    }
  }

  /// Drops the cached manifest. Intended for tests.
  void reset() {
    _bundledAssets = null;
    _loading = null;
  }
}
