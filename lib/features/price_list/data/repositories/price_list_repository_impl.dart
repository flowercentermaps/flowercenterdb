import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/price_item.dart';
import '../../domain/repositories/price_list_repository.dart';

class PriceListRepositoryImpl implements PriceListRepository {
  final SupabaseClient _client;

  const PriceListRepositoryImpl(this._client);

  @override
  Future<List<PriceItem>> getItems({String? category}) async {
    try {
      var query = _client
          .from('products')
          .select()
          .order('category', ascending: true)
          .order('name', ascending: true);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category) as dynamic;
      }
      final response = await query;
      return (response as List)
          .map((e) => PriceItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('products')
          .select('category')
          .order('category', ascending: true);
      final cats = (response as List)
          .map((e) => (e as Map)['category']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      return cats;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getGloballyBlockedPriceKeys() async {
    try {
      final settings = await _client
          .from('price_permission_settings')
          .select('block_all_prices')
          .limit(1)
          .maybeSingle();

      if (settings != null && settings['block_all_prices'] == true) {
        return List<String>.from(kAllPriceKeys);
      }

      final blocked = await _client
          .from('global_blocked_price_keys')
          .select('price_key');

      return (blocked as List)
          .map((e) => (e as Map)['price_key']?.toString() ?? '')
          .where((k) => k.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getVisiblePriceKeys(String profileId) async {
    try {
      // 1. Check profile-level block_all
      final profileAccess = await _client
          .from('profile_price_access')
          .select('block_all_prices')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (profileAccess != null && profileAccess['block_all_prices'] == true) {
        return [];
      }

      // 2. Get globally blocked keys
      final globalBlocked = await getGloballyBlockedPriceKeys();

      // 3. Get per-profile blocked keys
      final profileBlocked = await _client
          .from('profile_blocked_price_keys')
          .select('price_key')
          .eq('profile_id', profileId);

      final userBlockedKeys = (profileBlocked as List)
          .map((e) => (e as Map)['price_key']?.toString() ?? '')
          .where((k) => k.isNotEmpty)
          .toSet();

      return kAllPriceKeys
          .where((k) =>
              !globalBlocked.contains(k) && !userBlockedKeys.contains(k))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
