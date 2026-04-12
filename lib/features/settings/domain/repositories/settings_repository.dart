import '../entities/price_permission.dart';
import '../../../../features/auth/domain/entities/user_profile.dart';

abstract interface class SettingsRepository {
  // ── User role management ─────────────────────────────────────────────────

  /// Fetch all user profiles (admin only).
  Future<List<UserProfile>> getAllUsers();

  /// Update a user's role.
  Future<void> updateUserRole({
    required String profileId,
    required String newRole,
  });

  // ── Price permission management ───────────────────────────────────────────

  /// Fetch global price permission settings.
  Future<GlobalPriceSettings> getGlobalPriceSettings();

  /// Toggle the global block-all switch.
  Future<void> setGlobalBlockAll(bool block);

  /// Toggle a global blocked price key.
  Future<void> toggleGlobalBlockedKey(String priceKey, bool blocked);

  /// Fetch per-user price permissions for all users.
  Future<Map<String, PricePermission>> getUserPricePermissions();

  /// Toggle a user's block-all override.
  Future<void> setUserBlockAll({
    required String profileId,
    required bool block,
  });

  /// Toggle a per-user blocked price key.
  Future<void> toggleUserBlockedKey({
    required String profileId,
    required String priceKey,
    required bool blocked,
  });
}
