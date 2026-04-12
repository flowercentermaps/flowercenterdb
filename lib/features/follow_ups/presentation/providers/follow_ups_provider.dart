import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/follow_ups_repository_impl.dart';
import '../../domain/entities/follow_up.dart';
import '../../domain/repositories/follow_ups_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────

final followUpsRepositoryProvider = Provider<FollowUpsRepository>((ref) {
  return FollowUpsRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Follow-ups list ───────────────────────────────────────────────────────

class FollowUpsNotifier extends AsyncNotifier<List<FollowUp>> {
  @override
  Future<List<FollowUp>> build() =>
      ref.read(followUpsRepositoryProvider).getFollowUps();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(followUpsRepositoryProvider).getFollowUps(),
    );
  }

  Future<void> createFollowUp(FollowUp followUp) async {
    final inserted =
        await ref.read(followUpsRepositoryProvider).createFollowUp(followUp);
    state = state.whenData((list) => [...list, inserted]);
  }

  Future<void> updateFollowUp(FollowUp followUp) async {
    await ref.read(followUpsRepositoryProvider).updateFollowUp(followUp);
    state = state.whenData((list) =>
        list.map((f) => f.id == followUp.id ? followUp : f).toList());
  }

  Future<void> markDone(String followUpId) async {
    await ref.read(followUpsRepositoryProvider).markDone(followUpId);
    state = state.whenData((list) => list
        .map((f) => f.id == followUpId
            ? FollowUp(
                id: f.id,
                leadId: f.leadId,
                leadName: f.leadName,
                leadPhone: f.leadPhone,
                assignedToId: f.assignedToId,
                assignedToName: f.assignedToName,
                status: 'done',
                notes: f.notes,
                dueAt: f.dueAt,
                completedAt: DateTime.now(),
                createdAt: f.createdAt,
              )
            : f)
        .toList());
  }
}

final followUpsProvider =
    AsyncNotifierProvider<FollowUpsNotifier, List<FollowUp>>(
        FollowUpsNotifier.new);

// ── Badge counts ──────────────────────────────────────────────────────────

final followUpPendingCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(followUpsRepositoryProvider).getPendingCount(userId);
});
