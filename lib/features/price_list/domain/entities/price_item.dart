/// All supported price tier keys in order of display.
const List<String> kAllPriceKeys = [
  'price_retail',
  'price_wholesale',
  'price_premium',
  'price_platinum',
  'price_special',
  'price_art',
];

/// Users whose names contain these strings can see the ART price.
const List<String> kSpecialPriceAllowedNames = ['maher', 'hayan'];

/// Typed entity for a product row from the price-list table.
class PriceItem {
  final String id;
  final String name;
  final String? category;
  final String? imageUrl;
  final double? stock;
  final String? unit;
  final Map<String, double?> prices; // keyed by kAllPriceKeys values

  const PriceItem({
    required this.id,
    required this.name,
    this.category,
    this.imageUrl,
    this.stock,
    this.unit,
    required this.prices,
  });

  double? price(String key) => prices[key];

  factory PriceItem.fromMap(Map<String, dynamic> map) => PriceItem(
        id: (map['id'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        category: map['category']?.toString(),
        imageUrl: map['image_url']?.toString(),
        stock: _toDouble(map['stock']),
        unit: map['unit']?.toString(),
        prices: {
          for (final key in kAllPriceKeys)
            key: _toDouble(map[key]),
        },
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
