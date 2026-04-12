import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/crm_stats.dart';
import '../../domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final SupabaseClient _client;

  const StatisticsRepositoryImpl(this._client);

  @override
  Future<CrmStats> getStats() async {
    try {
      final results = await Future.wait([
        _client
            .from('crm_statistics_view')
            .select()
            .limit(1)
            .maybeSingle(),
        _client
            .from('crm_followup_statistics_view')
            .select()
            .limit(1)
            .maybeSingle(),
      ]);

      final leadMap = results[0] != null
          ? Map<String, dynamic>.from(results[0] as Map)
          : <String, dynamic>{};
      final followUpMap = results[1] != null
          ? Map<String, dynamic>.from(results[1] as Map)
          : <String, dynamic>{};

      return CrmStats.fromMaps(leadMap, followUpMap);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
