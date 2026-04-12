import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/agent_stats.dart';
import '../../domain/repositories/agent_performance_repository.dart';

class AgentPerformanceRepositoryImpl implements AgentPerformanceRepository {
  final SupabaseClient _client;

  const AgentPerformanceRepositoryImpl(this._client);

  @override
  Future<List<AgentStats>> getAgentStats() async {
    try {
      final response = await _client
          .from('crm_agent_performance_view')
          .select()
          .order('full_name', ascending: true);
      return (response as List)
          .map((e) =>
              AgentStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
