import '../entities/price_item.dart';

abstract interface class PriceListRepository {
  /// Fetch all products, optionally filtered by [category].
  Future<List<PriceItem>> getItems({String? category});

  /// All distinct category values.
  Future<List<String>> getCategories();

  /// The price keys that are globally blocked for everyone.
  Future<List<String>> getGloballyBlockedPriceKeys();

  /// The price keys that the given profile is allowed to see
  /// (respects both global blocks and per-profile overrides).
  Future<List<String>> getVisiblePriceKeys(String profileId);
}
