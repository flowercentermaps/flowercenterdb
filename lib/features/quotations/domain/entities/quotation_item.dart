/// A single line-item inside a [Quotation].
class QuotationItem {
  final String productId;
  final String productName;
  final int quantity;
  final String priceKey; // one of kAllPriceKeys
  final double unitPrice;
  final double total;
  final String? imageUrl;

  const QuotationItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceKey,
    required this.unitPrice,
    required this.total,
    this.imageUrl,
  });

  factory QuotationItem.fromMap(Map<String, dynamic> map) => QuotationItem(
        productId: (map['product_id'] ?? '').toString(),
        productName: (map['product_name'] ?? '').toString(),
        quantity: _toInt(map['quantity']),
        priceKey: (map['price_key'] ?? 'price_retail').toString(),
        unitPrice: _toDouble(map['unit_price']),
        total: _toDouble(map['total']),
        imageUrl: map['image_url']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'price_key': priceKey,
        'unit_price': unitPrice,
        'total': total,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  QuotationItem copyWith({int? quantity, double? unitPrice}) => QuotationItem(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        priceKey: priceKey,
        unitPrice: unitPrice ?? this.unitPrice,
        total: (unitPrice ?? this.unitPrice) * (quantity ?? this.quantity),
        imageUrl: imageUrl,
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 1;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}
