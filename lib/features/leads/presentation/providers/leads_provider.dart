import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/leads_repository_impl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/leads_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Leads list ────────────────────────────────────────────────────────────

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() => ref.read(leadsRepositoryProvider).getLeads();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(leadsRepositoryProvider).getLeads(),
    );
  }

  Future<void> createLead(Lead lead) async {
    final repo = ref.read(leadsRepositoryProvider);
    final inserted = await repo.createLead(lead);
    state = state.whenData((list) => [inserted, ...list]);
  }

  Future<void> updateLead(Lead lead) async {
    final repo = ref.read(leadsRepositoryProvider);
    await repo.updateLead(lead);
    state = state.whenData((list) =>
        list.map((l) => l.id == lead.id ? lead : l).toList());
  }

  Future<void> deleteLead(String leadId) async {
    final repo = ref.read(leadsRepositoryProvider);
    await repo.deleteLead(leadId);
    state = state.whenData(
        (list) => list.where((l) => l.id != leadId).toList());
  }

  Future<void> assignLead({
    required String leadId,
    required String newOwnerId,
    required String assignedById,
  }) async {
    await ref.read(leadsRepositoryProvider).assignLead(
          leadId: leadId,
          newOwnerId: newOwnerId,
          assignedById: assignedById,
        );
    await refresh();
  }
}

final leadsProvider =
    AsyncNotifierProvider<LeadsNotifier, List<Lead>>(LeadsNotifier.new);

// ── Profiles (for owner picker) ───────────────────────────────────────────

final profilesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(leadsRepositoryProvider).getProfiles();
});

// ── Lead search for quote picker ──────────────────────────────────────────

final leadSearchQueryProvider = StateProvider<String>((ref) => '');

final leadSearchResultsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(leadSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.read(leadsRepositoryProvider).searchLeadsForQuote(query);
});
