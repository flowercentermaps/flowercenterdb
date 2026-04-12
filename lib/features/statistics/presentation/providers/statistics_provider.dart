import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/crm_stats.dart';
import '../../domain/repositories/statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepositoryImpl(ref.watch(supabaseClientProvider));
});

final statisticsProvider = FutureProvider<CrmStats>((ref) async {
  return ref.read(statisticsRepositoryProvider).getStats();
});
