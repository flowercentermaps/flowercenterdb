import '../entities/crm_stats.dart';

abstract interface class StatisticsRepository {
  /// Fetch the combined CRM + follow-up stats snapshot.
  Future<CrmStats> getStats();
}
