import '../entities/agent_stats.dart';

abstract interface class AgentPerformanceRepository {
  /// Fetch per-agent stats rows from `crm_agent_performance_view`.
  Future<List<AgentStats>> getAgentStats();
}
