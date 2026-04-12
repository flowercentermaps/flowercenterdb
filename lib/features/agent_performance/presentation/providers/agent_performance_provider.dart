import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/agent_performance_repository_impl.dart';
import '../../domain/entities/agent_stats.dart';
import '../../domain/repositories/agent_performance_repository.dart';

final agentPerformanceRepositoryProvider =
    Provider<AgentPerformanceRepository>((ref) {
  return AgentPerformanceRepositoryImpl(ref.watch(supabaseClientProvider));
});

final agentPerformanceProvider = FutureProvider<List<AgentStats>>((ref) async {
  return ref.read(agentPerformanceRepositoryProvider).getAgentStats();
});
