/// Represents the resolved price-access state for a single user.
class PricePermission {
  final String profileId;
  final bool blockAll;           // profile-level block_all_prices
  final List<String> blockedKeys; // profile-level blocked keys

  const PricePermission({
    required this.profileId,
    required this.blockAll,
    required this.blockedKeys,
  });

  bool canSee(String priceKey) {
    if (blockAll) return false;
    return !blockedKeys.contains(priceKey);
  }
}

/// Global price settings (applies to everyone unless overridden per-profile).
class GlobalPriceSettings {
  final bool blockAllPrices;
  final List<String> blockedKeys;

  const GlobalPriceSettings({
    required this.blockAllPrices,
    required this.blockedKeys,
  });
}
