import 'quotation_item.dart';

/// Typed entity for a saved quotation.
class Quotation {
  final String id;
  final String? customerName;
  final String? customerPhone;
  final String? customerCompany;
  final String? customerId; // linked lead id, if any
  final List<QuotationItem> items;
  final double totalAmount;
  final String status; // 'draft' | 'sent' | 'accepted' | 'rejected'
  final DateTime? createdAt;
  final String? createdById;
  final String? pdfPath;

  const Quotation({
    required this.id,
    this.customerName,
    this.customerPhone,
    this.customerCompany,
    this.customerId,
    required this.items,
    required this.totalAmount,
    this.status = 'draft',
    this.createdAt,
    this.createdById,
    this.pdfPath,
  });

  factory Quotation.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];
    return Quotation(
      id: (map['id'] ?? '').toString(),
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      customerCompany: map['customer_company']?.toString(),
      customerId: map['customer_id']?.toString(),
      items: rawItems
          .map((e) => QuotationItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalAmount: _toDouble(map['total_amount']),
      status: (map['status'] ?? 'draft').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      createdById: map['created_by']?.toString(),
      pdfPath: map['pdf_path']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}
