import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/price_permission.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SupabaseClient _client;

  const SettingsRepositoryImpl(this._client);

  // ── User role management ─────────────────────────────────────────────────

  @override
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('full_name', ascending: true);
      return (response as List)
          .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserRole({
    required String profileId,
    required String newRole,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', profileId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Price permission management ───────────────────────────────────────────

  @override
  Future<GlobalPriceSettings> getGlobalPriceSettings() async {
    try {
      final settingsRow = await _client
          .from('price_permission_settings')
          .select('block_all_prices')
          .limit(1)
          .maybeSingle();

      final blockedRows = await _client
          .from('global_blocked_price_keys')
          .select('price_key');
      // final results = await Future.wait([
      //   _client
      //       .from('price_permission_settings')
      //       .select('block_all_prices')
      //       .limit(1)
      //       .maybeSingle(),
      //   _client
      //       .from('global_blocked_price_keys')
      //       .select('price_key'),
      // ]);

      // final settingsRow = results[0] as Map<String, dynamic>?;
      // final blockedRows = results[1] as List;

      return GlobalPriceSettings(
        blockAllPrices: settingsRow?['block_all_prices'] == true,
        blockedKeys: blockedRows
            .map((e) => (e as Map)['price_key']?.toString() ?? '')
            .where((k) => k.isNotEmpty)
            .toList(),
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setGlobalBlockAll(bool block) async {
    try {
      await _client
          .from('price_permission_settings')
          .upsert({'id': 1, 'block_all_prices': block});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleGlobalBlockedKey(String priceKey, bool blocked) async {
    try {
      if (blocked) {
        await _client
            .from('global_blocked_price_keys')
            .upsert({'price_key': priceKey});
      } else {
        await _client
            .from('global_blocked_price_keys')
            .delete()
            .eq('price_key', priceKey);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, PricePermission>> getUserPricePermissions() async {
    try {
      final results = await Future.wait([
        _client.from('profile_price_access').select('profile_id, block_all_prices'),
        _client.from('profile_blocked_price_keys').select('profile_id, price_key'),
      ]);

      final accessRows = results[0] as List;
      final blockedRows = results[1] as List;

      // Build blocked keys map per profile
      final blockedMap = <String, List<String>>{};
      for (final row in blockedRows) {
        final pid = (row as Map)['profile_id']?.toString() ?? '';
        final key = row['price_key']?.toString() ?? '';
        if (pid.isNotEmpty && key.isNotEmpty) {
          blockedMap.putIfAbsent(pid, () => []).add(key);
        }
      }

      final result = <String, PricePermission>{};
      for (final row in accessRows) {
        final pid = (row as Map)['profile_id']?.toString() ?? '';
        if (pid.isEmpty) continue;
        result[pid] = PricePermission(
          profileId: pid,
          blockAll: row['block_all_prices'] == true,
          blockedKeys: blockedMap[pid] ?? [],
        );
      }
      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setUserBlockAll({
    required String profileId,
    required bool block,
  }) async {
    try {
      await _client.from('profile_price_access').upsert({
        'profile_id': profileId,
        'block_all_prices': block,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleUserBlockedKey({
    required String profileId,
    required String priceKey,
    required bool blocked,
  }) async {
    try {
      if (blocked) {
        await _client.from('profile_blocked_price_keys').upsert({
          'profile_id': profileId,
          'price_key': priceKey,
        });
      } else {
        await _client
            .from('profile_blocked_price_keys')
            .delete()
            .eq('profile_id', profileId)
            .eq('price_key', priceKey);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
