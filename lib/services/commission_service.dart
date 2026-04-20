import 'package:supabase_flutter/supabase_flutter.dart';

class CommissionService {
  static final CommissionService _instance = CommissionService._();
  factory CommissionService() => _instance;
  CommissionService._();

  // profileId → {priceKey → rate%}
  final Map<String, Map<String, double>> _cache = {};

  Future<Map<String, double>> getRatesForUser(
      SupabaseClient supabase, String profileId) async {
    if (_cache.containsKey(profileId)) return _cache[profileId]!;
    try {
      final rows = await supabase
          .from('commission_rates')
          .select('price_key, rate')
          .eq('profile_id', profileId);
      final rates = <String, double>{};
      for (final row in rows as List) {
        final key = row['price_key']?.toString() ?? '';
        final rate = double.tryParse(row['rate']?.toString() ?? '0') ?? 0;
        if (key.isNotEmpty) rates[key] = rate;
      }
      _cache[profileId] = rates;
      return rates;
    } catch (_) {
      return {};
    }
  }

  Future<void> setRate(
    SupabaseClient supabase,
    String profileId,
    String priceKey,
    double rate,
  ) async {
    await supabase.from('commission_rates').upsert({
      'profile_id': profileId,
      'price_key': priceKey,
      'rate': rate,
    });
    _cache.remove(profileId);
  }

  double calculateLineCommission(
      double lineTotal, String priceKey, Map<String, double> rates) {
    final rate = rates[priceKey] ?? 0;
    return lineTotal * rate / 100;
  }

  double calculateTotalCommission(
    List<({String priceKey, double lineTotal})> lines,
    Map<String, double> rates,
  ) {
    return lines.fold(
        0, (sum, l) => sum + calculateLineCommission(l.lineTotal, l.priceKey, rates));
  }

  void invalidate(String profileId) => _cache.remove(profileId);
  void clearAll() => _cache.clear();
}
