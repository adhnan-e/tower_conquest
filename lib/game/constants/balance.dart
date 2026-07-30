/// Tier progression and per-type base stats from
/// `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` §1.1-1.2.
///
/// Every bonus here is **cumulative from Tier 1**, not incremental per tier —
/// Tier 5's "+70% gen rate" means 70% above the Tier 1 base, not 70% above
/// Tier 4. `Building.upgrade()` relies on this: it recomputes each stat from
/// the building's stored Tier 1 base every time, rather than compounding a
/// multiplier onto the previous tier's value. Compounding would silently
/// double-apply every earlier tier's bonus — the exact bug in
/// `orchestrator/PHASE2_DEVELOPER_PROMPT.md`'s first-draft `upgrade()`, which
/// multiplies `generationRate *= genRateMultiplier(tier)` on every call.
class BuildingBalance {
  BuildingBalance._();

  static const int minTier = 1;
  static const int maxTier = 5;

  /// One row of the tier progression table.
  ///
  /// [upgradeCost] is what it costs to reach *this* tier from the previous
  /// one (so [minTier]'s cost is unused — you start there, you don't buy it).
  /// The other three fields are the cumulative multiplier/bonus versus the
  /// Tier 1 base.
  static const Map<
      int,
      ({
        int upgradeCost,
        int capacityBonus,
        double genRateMultiplier,
        double defenseMultiplierBonus
      })> _tiers = {
    1: (
      upgradeCost: 0,
      capacityBonus: 0,
      genRateMultiplier: 1.0,
      defenseMultiplierBonus: 1.0,
    ),
    2: (
      upgradeCost: 20,
      capacityBonus: 10,
      genRateMultiplier: 1.10,
      defenseMultiplierBonus: 1.10,
    ),
    3: (
      upgradeCost: 40,
      capacityBonus: 25,
      genRateMultiplier: 1.25,
      defenseMultiplierBonus: 1.25,
    ),
    4: (
      upgradeCost: 70,
      capacityBonus: 45,
      genRateMultiplier: 1.40,
      defenseMultiplierBonus: 1.40,
    ),
    5: (
      upgradeCost: 100,
      capacityBonus: 70,
      genRateMultiplier: 1.60,
      defenseMultiplierBonus: 1.60,
    ),
  };

  /// Cost to upgrade *into* [tier] from `tier - 1`. Zero for [minTier] (there
  /// is nothing to buy into it) and for anything outside 1-5.
  static int upgradeCostForTier(int tier) => _tiers[tier]?.upgradeCost ?? 0;

  /// Cumulative capacity bonus versus the Tier 1 base.
  static int capacityBonusForTier(int tier) => _tiers[tier]?.capacityBonus ?? 0;

  /// Cumulative generation-rate multiplier versus the Tier 1 base (e.g. `1.25`
  /// at Tier 3, meaning 125% of the base rate — not a 25% step from Tier 2).
  static double genRateMultiplierForTier(int tier) =>
      _tiers[tier]?.genRateMultiplier ?? 1.0;

  /// Cumulative defence-multiplier bonus versus the Tier 1 base, applied the
  /// same way as [genRateMultiplierForTier].
  static double defenseMultiplierBonusForTier(int tier) =>
      _tiers[tier]?.defenseMultiplierBonus ?? 1.0;

  /// Tier 1 base stats per building archetype (balance §1.1).
  static const Map<String,
          ({int capacity, double genRate, double defense, bool upgradeable})>
      _baseStats = {
    'barracks': (
      capacity: 50,
      genRate: 1.0,
      defense: 1.0,
      upgradeable: true,
    ),
    'tower': (
      capacity: 30,
      genRate: 0.67,
      defense: 1.5,
      upgradeable: true,
    ),
    'factory': (
      capacity: 40,
      genRate: 0.5,
      defense: 1.2,
      upgradeable: true,
    ),
    'command_center': (
      capacity: 100,
      genRate: 1.25,
      defense: 2.0,
      upgradeable: false,
    ),
  };

  /// Tier 1 base stats for [type], or null for an unrecognised archetype.
  static ({int capacity, double genRate, double defense, bool upgradeable})?
      baseStatsFor(String type) => _baseStats[type];

  /// Whether buildings of [type] can be upgraded at all. Unknown types default
  /// to false rather than throwing — the same "degrade gracefully" choice
  /// [FactionColors.getColor] makes for an unknown faction.
  static bool isUpgradeable(String type) =>
      _baseStats[type]?.upgradeable ?? false;
}
