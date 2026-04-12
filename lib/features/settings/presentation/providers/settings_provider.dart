import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/price_permission.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── All users list ────────────────────────────────────────────────────────

class UsersNotifier extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() =>
      ref.read(settingsRepositoryProvider).getAllUsers();

  Future<void> updateRole({
    required String profileId,
    required String newRole,
  }) async {
    await ref.read(settingsRepositoryProvider).updateUserRole(
          profileId: profileId,
          newRole: newRole,
        );
    state = state.whenData((list) => list
        .map((u) => u.id == profileId ? u.copyWith(role: newRole) : u)
        .toList());
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UserProfile>>(UsersNotifier.new);

// ── Global price settings ─────────────────────────────────────────────────

final globalPriceSettingsProvider =
    FutureProvider<GlobalPriceSettings>((ref) async {
  return ref.read(settingsRepositoryProvider).getGlobalPriceSettings();
});

// ── Per-user price permissions ────────────────────────────────────────────

final userPricePermissionsProvider =
    FutureProvider<Map<String, PricePermission>>((ref) async {
  return ref.read(settingsRepositoryProvider).getUserPricePermissions();
});
