import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/price_list_repository_impl.dart';
import '../../domain/entities/price_item.dart';
import '../../domain/repositories/price_list_repository.dart';

final priceListRepositoryProvider = Provider<PriceListRepository>((ref) {
  return PriceListRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Selected category filter ──────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ── Products list ─────────────────────────────────────────────────────────

final priceItemsProvider = FutureProvider<List<PriceItem>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  return ref.read(priceListRepositoryProvider).getItems(category: category);
});

// ── Categories ────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(priceListRepositoryProvider).getCategories();
});

// ── Visible price keys for a specific profile ─────────────────────────────

final visiblePriceKeysProvider =
    FutureProvider.family<List<String>, String>((ref, profileId) async {
  return ref
      .read(priceListRepositoryProvider)
      .getVisiblePriceKeys(profileId);
});
