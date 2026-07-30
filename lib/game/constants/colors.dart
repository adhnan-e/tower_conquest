import 'dart:ui' as ui;

/// Faction colour definitions and the runtime tinting manager.
///
/// The whole visual architecture of Tower Conquest rests on one idea: every
/// tintable sprite ships as a *grayscale* PNG, and the faction colour is
/// applied at runtime with `ColorFilter.mode(factionColour, BlendMode.modulate)`
/// — see [FactionColors.defaultBlendMode] for why not `multiply`.
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
    'modulate': ui.BlendMode.modulate,
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
    return blendModes[blendMode] ?? blendModes[defaultBlendMode]!;
  }

  /// The blend mode used to tint sprites.
  ///
  /// **Not `multiply`, despite what the planning docs say.** Both produce the
  /// same colour on the sprite body — a grayscale pixel times the faction
  /// colour — but they differ on transparent pixels, and the Phase 1 art is
  /// roughly half transparent.
  ///
  /// Skia's `multiply` is a separable blend that composites the filter colour
  /// against the source: a fully transparent pixel comes out **fully opaque**
  /// in the faction colour, so the sprite renders as a solid coloured square.
  /// Measured on `barracks_tier1_base.png` at 96x96:
  ///
  /// | mode | transparent corner | body |
  /// | :-- | :-- | :-- |
  /// | `multiply` | `(45,140,255)` **opaque** | `(38,119,217)` |
  /// | `modulate` | `(0,0,0)` alpha 0 | `(38,119,217)` |
  ///
  /// `modulate` is a straight component-wise multiply including alpha, so
  /// transparency survives and antialiased edges keep their partial alpha.
  /// Identical tint, no halo.
  static const String defaultBlendMode = 'modulate';
}

/// Caches the `Paint` objects used for runtime faction tinting.
///
/// Building a `Paint` with a `ColorFilter` every frame for every component
/// would churn the allocator, so they are cached by key and reused. **The returned `Paint` instances are shared** — callers must treat
/// them as read-only and never mutate colour, opacity or filter on them.
class FactionManager {
  static final FactionManager _instance = FactionManager._internal();

  factory FactionManager() => _instance;

  FactionManager._internal();

  final Map<String, ui.Paint> _paintCache = {};

  /// Tint paint for **sprites**. The sprite's own grayscale pixels supply the
  /// source colour, so this paint only needs to carry the colour filter.
  ui.Paint getPaint(
    String faction, {
    String blendMode = FactionColors.defaultBlendMode,
  }) {
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

  void clearCache() {
    _paintCache.clear();
  }
}
