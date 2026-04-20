import 'package:supabase_flutter/supabase_flutter.dart';

class PriceTier {
  final String key;
  final String label;
  final double price;
  final bool enabled;

  const PriceTier({
    required this.key,
    required this.label,
    required this.price,
    required this.enabled,
  });
}

class TierResult {
  final String priceKey;
  final String priceLabel;
  final bool isBlocked;

  const TierResult({
    required this.priceKey,
    required this.priceLabel,
    required this.isBlocked,
  });
}

class PriceTierService {
  static final PriceTierService _instance = PriceTierService._();
  factory PriceTierService() => _instance;
  PriceTierService._();

  static const tierOrder = [
    ('price_ee', 'EE'),
    ('price_aa', 'AA'),
    ('price_a', 'A'),
    ('price_rr', 'RR'),
    ('price_r', 'R'),
    ('price_art', 'ART'),
  ];

  double _artMultiplier = 1.3;

  double get artMultiplier => _artMultiplier;

  Future<void> loadSettings(SupabaseClient supabase) async {
    try {
      final row = await supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'art_multiplier')
          .single();
      _artMultiplier =
          double.tryParse(row['value']?.toString() ?? '1.3') ?? 1.3;
    } catch (_) {}
  }

  Future<void> saveArtMultiplier(SupabaseClient supabase, double value) async {
    await supabase.from('app_settings').upsert({
      'key': 'art_multiplier',
      'value': value.toString(),
    });
    _artMultiplier = value;
  }

  double? computeArtPrice(Map<String, dynamic> item) {
    final r = _toDouble(item['price_r']);
    if (r == null || r == 0) return null;
    return r * _artMultiplier;
  }

  double? getPriceForKey(Map<String, dynamic> item, String key) {
    if (key == 'price_art') return computeArtPrice(item);
    return _toDouble(item[key]);
  }

  List<PriceTier> getSortedTiers(
    Map<String, dynamic> item,
    Map<String, bool> permissions,
  ) {
    final tiers = <PriceTier>[];
    for (final (key, label) in tierOrder) {
      final price = getPriceForKey(item, key);
      if (price == null || price == 0) continue;
      final enabled = permissions[key] ?? true;
      tiers.add(
          PriceTier(key: key, label: label, price: price, enabled: enabled));
    }
    tiers.sort((a, b) => a.price.compareTo(b.price));
    return tiers;
  }

  // Detect which tier a typed price falls into.
  // Returns null priceKey if below the base tier floor (not allowed).
  TierResult detectTier(
    double typedPrice,
    Map<String, dynamic> item,
    Map<String, bool> permissions,
    String basePriceKey,
  ) {
    final tiers = getSortedTiers(item, permissions);
    if (tiers.isEmpty) {
      return TierResult(
          priceKey: basePriceKey, priceLabel: basePriceKey, isBlocked: false);
    }

    // Find the raw tier (highest tier whose price <= typedPrice)
    PriceTier? rawTier;
    for (final tier in tiers) {
      if (tier.price <= typedPrice + 0.001) rawTier = tier;
    }

    if (rawTier == null) {
      // Below all tiers - treat as blocked
      return TierResult(
          priceKey: basePriceKey, priceLabel: basePriceKey, isBlocked: true);
    }

    if (!rawTier.enabled) {
      return TierResult(
          priceKey: rawTier.key, priceLabel: rawTier.label, isBlocked: true);
    }

    return TierResult(
        priceKey: rawTier.key, priceLabel: rawTier.label, isBlocked: false);
  }

  // Returns the floor price for a selected tier key.
  double? getFloorPrice(Map<String, dynamic> item, String basePriceKey) {
    return getPriceForKey(item, basePriceKey);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v == 0 ? null : v.toDouble();
    final parsed = double.tryParse(v.toString());
    return (parsed == null || parsed == 0) ? null : parsed;
  }
}
