import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Notifications state ───────────────────────────────────────────────────

class _NotificationsState {
  final List<NotificationItem> overdue;
  final List<NotificationItem> today;
  final List<NotificationItem> tomorrow;
  final List<NotificationItem> assignments;

  const _NotificationsState({
    this.overdue = const [],
    this.today = const [],
    this.tomorrow = const [],
    this.assignments = const [],
  });
}

class NotificationsNotifier
    extends AsyncNotifier<_NotificationsState> {
  @override
  Future<_NotificationsState> build() async => _load();

  Future<_NotificationsState> _load() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final results = await Future.wait([
      repo.getOverdue(),
      repo.getDueToday(),
      repo.getDueTomorrow(),
      repo.getRecentAssignments(),
    ]);
    return _NotificationsState(
      overdue: results[0],
      today: results[1],
      tomorrow: results[2],
      assignments: results[3],
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> dismiss(String id) async {
    await ref.read(notificationsRepositoryProvider).dismiss(id);
    state = state.whenData((s) => _NotificationsState(
          overdue: s.overdue,
          today: s.today,
          tomorrow: s.tomorrow,
          assignments:
              s.assignments.where((n) => n.id != id).toList(),
        ));
  }

  Future<void> clearSection(NotificationKind kind) async {
    await ref.read(notificationsRepositoryProvider).clearSection(kind);
    await refresh();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, _NotificationsState>(
        NotificationsNotifier.new);

// ── Badge count ───────────────────────────────────────────────────────────

final notificationsBadgeCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref
      .read(notificationsRepositoryProvider)
      .getBadgeCount(userId);
});
