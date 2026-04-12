/// Typed entity for a row in the `leads` table.
class Lead {
  final String id;
  final String? name;
  final String? phone;
  final String? phone2;
  final String? email;
  final String? company;
  final String? trn;
  final String leadType; // 'INDIVIDUAL' | 'COMPANY'
  final String status;   // 'new' | 'contacted' | 'qualified' | 'won' | 'lost' | 'existing_client'
  final String? notes;
  final bool isImportant;
  final String? ownerId;
  final String? ownerName;
  final String? createdById;
  final String? assignedById;
  final String? businessType;
  final String? businessField;
  final String? country;
  final String? city;
  final String? address;
  final String? socialMediaId;
  final String? invoiceNo;
  final String? deliveryPlace;
  final DateTime? deliveryDatetime;
  final String? salesRep;
  final String? companyType;
  final String? accountCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Lead({
    required this.id,
    this.name,
    this.phone,
    this.phone2,
    this.email,
    this.company,
    this.trn,
    this.leadType = 'INDIVIDUAL',
    this.status = 'new',
    this.notes,
    this.isImportant = false,
    this.ownerId,
    this.ownerName,
    this.createdById,
    this.assignedById,
    this.businessType,
    this.businessField,
    this.country,
    this.city,
    this.address,
    this.socialMediaId,
    this.invoiceNo,
    this.deliveryPlace,
    this.deliveryDatetime,
    this.salesRep,
    this.companyType,
    this.accountCode,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => (name?.isNotEmpty == true ? name! : phone ?? 'Unnamed Lead');

  factory Lead.fromMap(Map<String, dynamic> map) {
    final ownerMap = map['owner'] as Map<String, dynamic>?;
    return Lead(
      id: (map['id'] ?? '').toString(),
      name: map['name']?.toString(),
      phone: map['phone']?.toString(),
      phone2: map['phone_2']?.toString(),
      email: map['email']?.toString(),
      company: map['company']?.toString(),
      trn: map['trn']?.toString(),
      leadType: (map['type'] ?? 'INDIVIDUAL').toString().toUpperCase(),
      status: (map['status'] ?? 'new').toString(),
      notes: map['notes']?.toString(),
      isImportant: map['is_important'] == true,
      ownerId: map['owner_id']?.toString(),
      ownerName: ownerMap?['full_name']?.toString() ?? ownerMap?['name']?.toString(),
      createdById: map['created_by']?.toString(),
      assignedById: map['assigned_by']?.toString(),
      businessType: map['business_type']?.toString(),
      businessField: map['business_field']?.toString(),
      country: map['country']?.toString(),
      city: map['city']?.toString(),
      address: map['address']?.toString(),
      socialMediaId: map['social_media_id']?.toString(),
      invoiceNo: map['invoice_no']?.toString(),
      deliveryPlace: map['delivery_place']?.toString(),
      deliveryDatetime: map['delivery_datetime'] != null
          ? DateTime.tryParse(map['delivery_datetime'].toString())
          : null,
      salesRep: map['sales_rep']?.toString(),
      companyType: map['company_type']?.toString(),
      accountCode: map['account_code']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (phone2 != null) 'phone_2': phone2,
        if (email != null) 'email': email,
        if (company != null) 'company': company,
        if (trn != null) 'trn': trn,
        'type': leadType,
        'status': status,
        if (notes != null) 'notes': notes,
        'is_important': isImportant,
        if (ownerId != null) 'owner_id': ownerId,
        if (businessType != null) 'business_type': businessType,
        if (businessField != null) 'business_field': businessField,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
        if (address != null) 'address': address,
        if (socialMediaId != null) 'social_media_id': socialMediaId,
        if (invoiceNo != null) 'invoice_no': invoiceNo,
        if (deliveryPlace != null) 'delivery_place': deliveryPlace,
        if (deliveryDatetime != null)
          'delivery_datetime': deliveryDatetime!.toIso8601String(),
        if (salesRep != null) 'sales_rep': salesRep,
        if (companyType != null) 'company_type': companyType,
        if (accountCode != null) 'account_code': accountCode,
      };

  // Keep raw map access for legacy screens during migration
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'phone_2': phone2,
        'email': email,
        'company': company,
        'trn': trn,
        'type': leadType,
        'status': status,
        'notes': notes,
        'is_important': isImportant,
        'owner_id': ownerId,
        'created_by': createdById,
        'assigned_by': assignedById,
        'business_type': businessType,
        'business_field': businessField,
        'country': country,
        'city': city,
        'address': address,
        'social_media_id': socialMediaId,
        'invoice_no': invoiceNo,
        'delivery_place': deliveryPlace,
        'delivery_datetime': deliveryDatetime?.toIso8601String(),
        'sales_rep': salesRep,
        'company_type': companyType,
        'account_code': accountCode,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        if (ownerName != null)
          'owner': {'full_name': ownerName},
      };
}
