import 'dart:ui' as ui;

/// Faction colour definitions and the runtime tinting manager.
///
/// The whole visual architecture of Tower Conquest rests on one idea: every
/// tintable sprite ships as a *grayscale* PNG, and the faction colour is
/// applied at runtime with `ColorFilter.mode(factionColour, BlendMode.multiply)`.
/// A single `barracks_tier1_base.png` therefore renders blue for the player and
/// red for the enemy with no extra art. See
/// `planning/03_assets/01_ASSET_CATALOG_PRODUCTION.md` §1.
///
/// Note on file layout: `02_DEVELOPMENT_PROMPT.md` asks for `FactionManager` to
/// live here in `colors.dart`, while `01_FLUTTER_FLAME_GUIDE.md` §3.2 puts it in
/// `managers/faction_manager.dart`. The MVP follows the prompt; splitting the
/// manager out is a Milestone-2 refactor.
class FactionColors {
  FactionColors._();

  /// Faction palette from the GDD §7.1 / implementation guide §3.1.
  static const Map<String, ui.Color> colors = {
    'player': ui.Color(0xFF2D8CFF), // Bright Blue
    'enemy': ui.Color(0xFFE74C3C), // Bright Red
    'ally1': ui.Color(0xFF37C978), // Green
    'ally2': ui.Color(0xFFF39C12), // Orange
    'neutral': ui.Color(0xFFB7BDC8), // Light Gray
    'spectral': ui.Color(0xFF9B59B6), // Purple
  };

  static const Map<String, ui.BlendMode> blendModes = {
    'multiply': ui.BlendMode.multiply,
    'screen': ui.BlendMode.screen,
    'overlay': ui.BlendMode.overlay,
  };

  /// Unknown factions fall back to neutral gray rather than throwing, so a typo
  /// in level data degrades to "uncontrolled" instead of crashing the match.
  static ui.Color getColor(String faction) {
    return colors[faction] ?? colors['neutral']!;
  }

  static ui.BlendMode getBlendMode(String blendMode) {
    return blendModes[blendMode] ?? blendModes['multiply']!;
  }
}

/// Caches the `Paint` objects used for runtime faction tinting.
///
/// Building a `Paint` with a `ColorFilter` every frame for every component
/// would churn the allocator, so both flavours below are cached by key and
/// reused. **The returned `Paint` instances are shared** — callers must treat
/// them as read-only and never mutate colour, opacity or filter on them.
class FactionManager {
  static final FactionManager _instance = FactionManager._internal();

  factory FactionManager() => _instance;

  FactionManager._internal();

  final Map<String, ui.Paint> _paintCache = {};
  final Map<String, ui.Paint> _shadePaintCache = {};

  /// Tint paint for **sprites**. The sprite's own grayscale pixels supply the
  /// source colour, so this paint only needs to carry the colour filter.
  ui.Paint getPaint(String faction, {String blendMode = 'multiply'}) {
    final key = '$faction:$blendMode';
    final cached = _paintCache[key];
    if (cached != null) return cached;

    final paint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(
        FactionColors.getColor(faction),
        FactionColors.getBlendMode(blendMode),
      );

    _paintCache[key] = paint;
    return paint;
  }

  /// Tint paint for **procedurally drawn placeholder shapes**.
  ///
  /// A canvas draw op takes its source colour from `paint.color`, not from a
  /// sprite, and the default is opaque black — which multiply would crush to
  /// black. Setting an explicit gray makes a drawn shape behave exactly like a
  /// grayscale pixel would: [gray] `0xFF` (white) yields the full faction
  /// colour, `0x80` yields a half-shade of it. That is what lets the shape
  /// placeholders rehearse the real sprite pipeline, so swapping in the PNGs
  /// later changes nothing about how colour is produced.
  ui.Paint getShadePaint(
    String faction,
    int gray, {
    String blendMode = 'multiply',
  }) {
    final key = '$faction:$blendMode:$gray';
    final cached = _shadePaintCache[key];
    if (cached != null) return cached;

    final paint = ui.Paint()
      ..color = ui.Color.fromARGB(0xFF, gray, gray, gray)
      ..colorFilter = ui.ColorFilter.mode(
        FactionColors.getColor(faction),
        FactionColors.getBlendMode(blendMode),
      );

    _shadePaintCache[key] = paint;
    return paint;
  }

  void clearCache() {
    _paintCache.clear();
    _shadePaintCache.clear();
  }
}
