//==========================================
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:csv/csv.dart';
import 'package:flowercenterdb/user_role_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'container_processor_screen.dart';
import 'core/constants/app_constants.dart';
import 'quotation_details_screen.dart';
import 'quotation_list_screen.dart';
import 'scanner.dart';

class _PriceOptionMeta {
  final String key;
  final String label;

  const _PriceOptionMeta(this.key, this.label);
}

const List<_PriceOptionMeta> _priceOptions = [
  _PriceOptionMeta('price_ee', 'EE'),
  _PriceOptionMeta('price_aa', 'AA'),
  _PriceOptionMeta('price_a', 'A'),
  _PriceOptionMeta('price_rr', 'RR'),
  _PriceOptionMeta('price_r', 'R'),
  _PriceOptionMeta('price_art', 'ART'),
];

class _SelectedQuoteItem {
  final int itemId;
  final String productName;
  final String priceKey;
  final String priceLabel;
  final double unitPrice;
  final int quantity;
  final Map<String, dynamic> item;

  const _SelectedQuoteItem({
    required this.itemId,
    required this.productName,
    required this.priceKey,
    required this.priceLabel,
    required this.unitPrice,
    required this.quantity,
    required this.item,
  });

  _SelectedQuoteItem copyWith({
    String? priceKey,
    String? priceLabel,
    double? unitPrice,
    int? quantity,
  }) {
    return _SelectedQuoteItem(
      itemId: itemId,
      productName: productName,
      priceKey: priceKey ?? this.priceKey,
      priceLabel: priceLabel ?? this.priceLabel,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      item: item,
    );
  }

  double get lineTotal => unitPrice * quantity;
}

class _QuotationDraft {
  final String customerName;
  final String companyName;
  final String customerTrn;
  final String customerPhone;
  final String salespersonName;
  final String salespersonContact;
  final String salespersonPhone;
  final String notes;
  final double deliveryFee;
  final double installationFee;
  final double additionalDetailsFee;
  final double vatPercent;

  const _QuotationDraft({
    required this.customerName,
    required this.companyName,
    required this.customerTrn,
    required this.customerPhone,
    required this.salespersonName,
    required this.salespersonContact,
    required this.salespersonPhone,
    required this.notes,
    required this.deliveryFee,
    required this.installationFee,
    required this.additionalDetailsFee,
    required this.vatPercent,
  });
}

int? _safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double _safeDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0;
}

class PriceListScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;

  const PriceListScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  // bool get _isAdmin => (widget.profile['role'] ?? '') == 'admin';

  String get _role => (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isAccountant => _role == 'accountant';
  bool get _isViewer => _role == 'viewer';

  bool get _canCreateQuotation => _isSales || _isAdmin;
  bool get _canViewQuotations => _isSales || _isAdmin;
  bool get _canManagePricePermissions => _isAdmin || _isAccountant;
  bool get _canAddItems => _isAdmin || _isAccountant;
  bool get _canManageUsers => _isAdmin;
  bool get _canUseContainerProcessor => _isAdmin || _isAccountant;
  bool get _canUsePriceChipsForQuotation => _isAdmin || _isSales;

  Timer? _debounce;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _categories = [];

  String _searchQuery = '';
  String? _selectedCategory;

  Map<String, bool> _pricePermissions = {
    for (final option in _priceOptions) option.key: true,
  };

  final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    Future.wait([
      _loadItems(),
      _loadPricePermissions(),
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
        _applyFilters();
      });
    });
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('price_list_api')
          .select()
          .order('category_ar', ascending: true)
          .order('product_name', ascending: true);

      final items = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final categories = items
          .map((e) => (e['category_ar'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allItems = items;
        _categories = categories;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final search = _searchQuery.toLowerCase();

    _filteredItems = _allItems.where((item) {
      final category = (item['category_ar'] ?? '').toString().trim();
      final description = (item['description'] ?? '').toString().trim();
      final productName = (item['product_name'] ?? '').toString().trim();
      final itemCode = (item['item_code'] ?? '').toString().trim();
      final displayPrice = (item['display_price'] ?? '').toString().trim();
      final barcode = (item['barcode'] ?? '').toString().trim();

      final matchesCategory =
          _selectedCategory == null || category == _selectedCategory;

      final haystack = [
        category,
        description,
        productName,
        itemCode,
        displayPrice,
        barcode,
      ].join(' ').toLowerCase();

      final matchesSearch = search.isEmpty || haystack.contains(search);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _startBarcodeScan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (!mounted || code == null || code.trim().isEmpty) return;

    setState(() {
      _searchController.text = code.trim();
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
      _searchQuery = code.trim();
      _applyFilters();
    });
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatPrice(dynamic value) {
    final number = _toDouble(value);
    if (number == null) return '-';
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  Future<void> _loadPricePermissions() async {
    try {
      final response = await _supabase.rpc('get_my_price_permissions');

      final map = {
        for (final option in _priceOptions) option.key: true,
      };

      if (response is List) {
        for (final row in response) {
          final data = Map<String, dynamic>.from(row as Map);
          final key = (data['price_key'] ?? '').toString();
          final allowed = data['is_allowed'] == true;
          if (map.containsKey(key)) {
            map[key] = allowed;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _pricePermissions = map;
        _isLoadingPermissions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pricePermissions = {
          for (final option in _priceOptions) option.key: true,
        };
        _isLoadingPermissions = false;
      });
    }
  }

  double? _priceValueForKey(Map<String, dynamic> item, String priceKey) {
    return _toDouble(item[priceKey]);
  }

  bool _isPriceAllowedForItem(Map<String, dynamic> item, String priceKey) {
    final globallyAllowed = _pricePermissions[priceKey] ?? true;
    final value = _priceValueForKey(item, priceKey);
    return globallyAllowed && value != null;
  }

  String? _selectedPriceKeyForItem(Map<String, dynamic> item) {
    final itemId = _safeInt(item['id']);
    if (itemId == null) return null;
    return _selectedQuoteItems[itemId]?.priceKey;
  }

  void _toggleItemPriceSelection(
      Map<String, dynamic> item,
      String priceKey,
      String priceLabel,
      ) {
    if (!_canUsePriceChipsForQuotation) return;
    if (!_isPriceAllowedForItem(item, priceKey)) return;

    final itemId = _safeInt(item['id']);
    if (itemId == null) return;

    final priceValue = _priceValueForKey(item, priceKey);
    if (priceValue == null) return;

    final current = _selectedQuoteItems[itemId];

    setState(() {
      if (current != null && current.priceKey == priceKey) {
        _selectedQuoteItems.remove(itemId);
        return;
      }

      _selectedQuoteItems[itemId] = _SelectedQuoteItem(
        itemId: itemId,
        productName: (item['product_name'] ?? '').toString().trim(),
        priceKey: priceKey,
        priceLabel: priceLabel,
        unitPrice: priceValue,
        quantity: current?.quantity ?? 1,
        item: item,
      );
    });
  }

  // void _toggleItemPriceSelection(
  //     Map<String, dynamic> item,
  //     String priceKey,
  //     String priceLabel,
  //     ) {
  //   if (!_isPriceAllowedForItem(item, priceKey)) return;
  //
  //   final itemId = _safeInt(item['id']);
  //   if (itemId == null) return;
  //
  //   final priceValue = _priceValueForKey(item, priceKey);
  //   if (priceValue == null) return;
  //
  //   final current = _selectedQuoteItems[itemId];
  //
  //   setState(() {
  //     if (current != null && current.priceKey == priceKey) {
  //       _selectedQuoteItems.remove(itemId);
  //       return;
  //     }
  //
  //     _selectedQuoteItems[itemId] = _SelectedQuoteItem(
  //       itemId: itemId,
  //       productName: (item['product_name'] ?? '').toString().trim(),
  //       priceKey: priceKey,
  //       priceLabel: priceLabel,
  //       unitPrice: priceValue,
  //       quantity: current?.quantity ?? 1,
  //       item: item,
  //     );
  //   });
  // }

  void _changeSelectedItemQuantity(int itemId, int delta) {
    final current = _selectedQuoteItems[itemId];
    if (current == null) return;

    final nextQty = current.quantity + delta;
    setState(() {
      if (nextQty <= 0) {
        _selectedQuoteItems.remove(itemId);
      } else {
        _selectedQuoteItems[itemId] = current.copyWith(quantity: nextQty);
      }
    });
  }

  double get _selectedGrandTotal {
    return _selectedQuoteItems.values.fold(
      0,
          (sum, item) => sum + item.lineTotal,
    );
  }

  Future<void> _openCreateQuotationSheet() async {
    if (_selectedQuoteItems.isEmpty) return;

    final draft = await showModalBottomSheet<_QuotationDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CreateQuotationSheet(
        subtotal: _selectedGrandTotal,
        formatPrice: _formatPrice,
        profile: widget.profile,
      ),
    );

    if (!mounted || draft == null) return;
    await _saveQuotation(draft);
  }

  // Future<void> _saveQuotation(_QuotationDraft draft) async {
  //   final subtotal = _selectedGrandTotal;
  //   final taxableTotal = subtotal +
  //       draft.deliveryFee +
  //       draft.installationFee +
  //       draft.additionalDetailsFee;
  //   final vatAmount = taxableTotal * (draft.vatPercent / 100);
  //   final netTotal = taxableTotal + vatAmount;
  //
  //   final quoteNo = 'QT-${DateTime.now().microsecondsSinceEpoch}';
  //
  //   final quotationPayload = {
  //     'quote_no': quoteNo,
  //     'quote_date': DateTime.now().toIso8601String().split('T').first,
  //     'customer_name': draft.customerName.isEmpty ? null : draft.customerName,
  //     'company_name': draft.companyName.isEmpty ? null : draft.companyName,
  //     'customer_trn': draft.customerTrn.isEmpty ? null : draft.customerTrn,
  //     'customer_phone':
  //     draft.customerPhone.isEmpty ? null : draft.customerPhone,
  //     'salesperson_name':
  //     draft.salespersonName.isEmpty ? null : draft.salespersonName,
  //     'salesperson_contact': draft.salespersonContact.isEmpty
  //         ? null
  //         : draft.salespersonContact,
  //     'salesperson_phone': draft.salespersonPhone.isEmpty
  //         ? null
  //         : draft.salespersonPhone,
  //     'notes': draft.notes.isEmpty ? null : draft.notes,
  //     'status': 'draft',
  //     'subtotal': subtotal,
  //     'delivery_fee': draft.deliveryFee,
  //     'installation_fee': draft.installationFee,
  //     'additional_details_fee': draft.additionalDetailsFee,
  //     'taxable_total': taxableTotal,
  //     'vat_percent': draft.vatPercent,
  //     'vat_amount': vatAmount,
  //     'net_total': netTotal,
  //   };
  //
  //   try {
  //     final insertedQuotation = await _supabase
  //         .from('quotations')
  //         .insert(quotationPayload)
  //         .select('id, quote_no')
  //         .single();
  //
  //     final quotationId = _safeInt(insertedQuotation['id']);
  //     if (quotationId == null) {
  //       throw Exception('Failed to resolve quotation id.');
  //     }
  //
  //     final itemRows = _selectedQuoteItems.values.map((selected) {
  //       final item = selected.item;
  //       final itemCode = (item['item_code'] ?? '').toString().trim();
  //       final description = (item['description'] ?? '').toString().trim();
  //       final imagePath = (item['image_path'] ?? '').toString().trim();
  //       final productName = selected.productName.trim().isEmpty
  //           ? 'Unnamed Product'
  //           : selected.productName.trim();
  //
  //       final rawLength = item['length']?.toString().trim();
  //       final rawWidth = item['width']?.toString().trim();
  //       final rawProductionTime = item['production_time']?.toString().trim();
  //
  //       return {
  //         'quotation_id': quotationId,
  //         'product_id': selected.itemId,
  //         'item_code': itemCode.isEmpty ? null : itemCode,
  //         'product_name': productName,
  //         'description': description.isEmpty ? null : description,
  //         'image_path': imagePath.isEmpty ? null : imagePath,
  //         'length': (rawLength == null || rawLength.isEmpty)
  //             ? null
  //             : item['length'].toString().trim(),
  //         'width': (rawWidth == null || rawWidth.isEmpty)
  //             ? null
  //             : item['width'].toString().trim(),
  //         'production_time':
  //         (rawProductionTime == null || rawProductionTime.isEmpty)
  //             ? null
  //             : item['production_time'].toString().trim(),
  //         'price_key': selected.priceKey,
  //         'price_label': selected.priceLabel,
  //         'unit_price': selected.unitPrice,
  //         'quantity': selected.quantity,
  //         'line_total': selected.lineTotal,
  //         'snapshot': {
  //           'category_ar': item['category_ar'],
  //           'description': item['description'],
  //           'product_name': item['product_name'],
  //           'item_code': item['item_code'],
  //           'price_ee': item['price_ee'],
  //           'price_aa': item['price_aa'],
  //           'price_a': item['price_a'],
  //           'price_rr': item['price_rr'],
  //           'price_r': item['price_r'],
  //           'price_art': item['price_art'],
  //           'pot_item_no': item['pot_item_no'],
  //           'pot_price': item['pot_price'],
  //           'additions': item['additions'],
  //           'total_price': item['total_price'],
  //           'display_price': item['display_price'],
  //           'image_path': item['image_path'],
  //           'length': item['length'],
  //           'width': item['width'],
  //           'production_time': item['production_time'],
  //         },
  //       };
  //     }).toList();
  //
  //     await _supabase.from('quotation_items').insert(itemRows);
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       _selectedQuoteItems.clear();
  //     });
  //
  //     final quoteNumber = (insertedQuotation['quote_no'] ?? '').toString();
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Quotation $quoteNumber created successfully.'),
  //       ),
  //     );
  //
  //     await Navigator.of(context).push(
  //       MaterialPageRoute(
  //         builder: (_) => QuotationDetailsScreen(
  //           quotationId: quotationId,
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to create quotation: $e')),
  //     );
  //   }
  // }
  Future<void> _saveQuotation(_QuotationDraft draft) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in user found.')),
      );
      return;
    }

    final subtotal = _selectedGrandTotal;
    final taxableTotal = subtotal +
        draft.deliveryFee +
        draft.installationFee +
        draft.additionalDetailsFee;
    final vatAmount = taxableTotal * (draft.vatPercent / 100);
    final netTotal = taxableTotal + vatAmount;

    final quoteNo = 'QT-${DateTime.now().microsecondsSinceEpoch}';

    final quotationPayload = {
      'quote_no': quoteNo,
      'quote_date': DateTime.now().toIso8601String().split('T').first,
      'customer_name': draft.customerName.isEmpty ? null : draft.customerName,
      'company_name': draft.companyName.isEmpty ? null : draft.companyName,
      'customer_trn': draft.customerTrn.isEmpty ? null : draft.customerTrn,
      'customer_phone': draft.customerPhone.isEmpty ? null : draft.customerPhone,
      'salesperson_name':
      draft.salespersonName.isEmpty ? null : draft.salespersonName,
      'salesperson_contact':
      draft.salespersonContact.isEmpty ? null : draft.salespersonContact,
      'salesperson_phone': widget.profile['phone'],
      'notes': draft.notes.isEmpty ? null : draft.notes,
      'status': 'draft',
      'subtotal': subtotal,
      'delivery_fee': draft.deliveryFee,
      'installation_fee': draft.installationFee,
      'additional_details_fee': draft.additionalDetailsFee,
      'taxable_total': taxableTotal,
      'vat_percent': draft.vatPercent,
      'vat_amount': vatAmount,
      'net_total': netTotal,
      'created_by': user.id,
      'updated_by': user.id,
    };

    try {
      final insertedQuotation = await _supabase
          .from('quotations')
          .insert(quotationPayload)
          .select('id, quote_no, created_by')
          .single();

      final quotationId = _safeInt(insertedQuotation['id']);
      if (quotationId == null) {
        throw Exception('Failed to resolve quotation id.');
      }

      final itemRows = _selectedQuoteItems.values.map((selected) {
        final item = selected.item;
        final itemCode = (item['item_code'] ?? '').toString().trim();
        final description = (item['description'] ?? '').toString().trim();
        final imagePath = (item['image_path'] ?? '').toString().trim();
        final productName = selected.productName.trim().isEmpty
            ? 'Unnamed Product'
            : selected.productName.trim();

        final rawLength = item['length']?.toString().trim();
        final rawWidth = item['width']?.toString().trim();
        final rawProductionTime = item['production_time']?.toString().trim();

        return {
          'quotation_id': quotationId,
          'product_id': selected.itemId,
          'item_code': itemCode.isEmpty ? null : itemCode,
          'product_name': productName,
          'description': description.isEmpty ? null : description,
          'image_path': imagePath.isEmpty ? null : imagePath,
          'length': (rawLength == null || rawLength.isEmpty)
              ? null
              : item['length'].toString().trim(),
          'width': (rawWidth == null || rawWidth.isEmpty)
              ? null
              : item['width'].toString().trim(),
          'production_time': (rawProductionTime == null || rawProductionTime.isEmpty)
              ? null
              : item['production_time'].toString().trim(),
          'price_key': selected.priceKey,
          'price_label': selected.priceLabel,
          'unit_price': selected.unitPrice,
          'quantity': selected.quantity,
          'line_total': selected.lineTotal,
          'snapshot': {
            'category_ar': item['category_ar'],
            'description': item['description'],
            'product_name': item['product_name'],
            'item_code': item['item_code'],
            'price_ee': item['price_ee'],
            'price_aa': item['price_aa'],
            'price_a': item['price_a'],
            'price_rr': item['price_rr'],
            'price_r': item['price_r'],
            'price_art': item['price_art'],
            'pot_item_no': item['pot_item_no'],
            'pot_price': item['pot_price'],
            'additions': item['additions'],
            'total_price': item['total_price'],
            'display_price': item['display_price'],
            'image_path': item['image_path'],
            'length': item['length'],
            'width': item['width'],
            'production_time': item['production_time'],
          },
        };
      }).toList();

      await _supabase.from('quotation_items').insert(itemRows);

      if (!mounted) return;

      setState(() {
        _selectedQuoteItems.clear();
      });

      final quoteNumber = (insertedQuotation['quote_no'] ?? '').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quotation $quoteNumber created successfully.'),
        ),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuotationDetailsScreen(
            quotationId: quotationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create quotation: $e')),
      );
    }
  }
  // void _openSelectedItemsSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     useSafeArea: true,
  //     isScrollControlled: true,
  //     backgroundColor: const Color(0xFF121212),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  //     ),
  //     builder: (_) {
  //       final selectedItems = _selectedQuoteItems.values.toList();
  //
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return Padding(
  //             padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 IconButton(onPressed: (){
  //                   print(widget.profile['phone']);
  //                 }, icon: Icon(Icons.ads_click)),
  //                 Text(
  //                   'Selected Items',
  //                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                     fontWeight: FontWeight.w900,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 if (selectedItems.isEmpty)
  //                   const Padding(
  //                     padding: EdgeInsets.symmetric(vertical: 24),
  //                     child: Text('No items selected yet.'),
  //                   )
  //                 else
  //                   Flexible(
  //                     child: ListView.separated(
  //                       shrinkWrap: true,
  //                       itemCount: selectedItems.length,
  //                       separatorBuilder: (_, __) => const Divider(height: 20),
  //                       itemBuilder: (context, index) {
  //                         final selected = selectedItems[index];
  //                         return Row(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Expanded(
  //                               child: Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Text(
  //                                     selected.productName.isEmpty
  //                                         ? 'Unnamed Product'
  //                                         : selected.productName,
  //                                     style: const TextStyle(
  //                                       fontWeight: FontWeight.w800,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 4),
  //                                   Text(
  //                                     '${selected.priceLabel} • ${_formatPrice(selected.unitPrice)}',
  //                                     style: const TextStyle(
  //                                       color: AppConstants.primaryColor,
  //                                       fontWeight: FontWeight.w700,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 4),
  //                                   Text(
  //                                     'Line total: ${_formatPrice(selected.lineTotal)}',
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                             Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 IconButton(
  //                                   onPressed: () {
  //                                     _changeSelectedItemQuantity(
  //                                       selected.itemId,
  //                                       -1,
  //                                     );
  //                                     setModalState(() {});
  //                                   },
  //                                   icon:
  //                                   const Icon(Icons.remove_circle_outline),
  //                                 ),
  //                                 Text(
  //                                   '${_selectedQuoteItems[selected.itemId]?.quantity ?? selected.quantity}',
  //                                   style: const TextStyle(
  //                                     fontWeight: FontWeight.w800,
  //                                   ),
  //                                 ),
  //                                 IconButton(
  //                                   onPressed: () {
  //                                     _changeSelectedItemQuantity(
  //                                       selected.itemId,
  //                                       1,
  //                                     );
  //                                     setModalState(() {});
  //                                   },
  //                                   icon: const Icon(Icons.add_circle_outline),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 const SizedBox(height: 16),
  //                 if (_selectedQuoteItems.isNotEmpty) ...[
  //                   Row(
  //                     children: [
  //                       const Expanded(
  //                         child: Text(
  //                           'Grand Total',
  //                           style: TextStyle(fontWeight: FontWeight.w800),
  //                         ),
  //                       ),
  //                       Text(
  //                         _formatPrice(_selectedGrandTotal),
  //                         style: const TextStyle(
  //                           color: Color(0xFFFFD95E),
  //                           fontWeight: FontWeight.w900,
  //                           fontSize: 18,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 16),
  //                   SizedBox(
  //                     width: double.infinity,
  //                     child: FilledButton.icon(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         _openCreateQuotationSheet();
  //                       },
  //                       icon: const Icon(Icons.description_outlined),
  //                       label: const Text('Create Quotation'),
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
  void _openSelectedItemsSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedItems = _selectedQuoteItems.values.toList();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      Text(
                        'Selected Items',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: selectedItems.isEmpty
                            ? const Center(
                          child: Text('No items selected yet.'),
                        )
                            : ListView.separated(
                          itemCount: selectedItems.length,
                          separatorBuilder: (_, __) =>
                          const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final selected = selectedItems[index];

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected.productName.isEmpty
                                            ? 'Unnamed Product'
                                            : selected.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${selected.priceLabel} • ${_formatPrice(selected.unitPrice)}',
                                        style: const TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Line total: ${_formatPrice(selected.lineTotal)}',
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _changeSelectedItemQuantity(
                                          selected.itemId,
                                          -1,
                                        );
                                        setModalState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedQuoteItems[selected.itemId]?.quantity ?? selected.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _changeSelectedItemQuantity(
                                          selected.itemId,
                                          1,
                                        );
                                        setModalState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (_selectedQuoteItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Grand Total',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              _formatPrice(_selectedGrandTotal),
                              style: const TextStyle(
                                color: Color(0xFFFFD95E),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openCreateQuotationSheet();
                            },
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Create Quotation'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  int _gridCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  void _openDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProductDetailsSheet(
        item: item,
        formatPrice: _formatPrice,
      ),
    );
  }

  Future<void> _openAddItemSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddItemSheet(),
    );

    if (created == true) {
      await _loadItems();
    }
  }

  Future<void> _openBulkAddItemsSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _BulkAddItemsSheet(),
    );

    if (created == true) {
      await _loadItems();
    }
  }

  // Future<void> _openFabActions() async {
  //   if (!_isAdmin) {
  //     await _startBarcodeScan();
  //     return;
  //   }
  //
  //   if (!mounted) return;
  //
  //   await showModalBottomSheet(
  //     context: context,
  //     backgroundColor: const Color(0xFF121212),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  //     ),
  //     builder: (context) {
  //       return SafeArea(
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               ListTile(
  //                 leading: const Icon(Icons.add_box_outlined),
  //                 title: const Text('Add Item'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _openAddItemSheet();
  //                 },
  //               ),
  //               ListTile(
  //                 leading: const Icon(Icons.manage_accounts_outlined),
  //                 title: const Text('Manage User Roles'),
  //                 subtitle: const Text('Change roles for other users'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.of(context).push(
  //                     MaterialPageRoute(
  //                       builder: (_) => UserRoleManagementScreen(
  //                         currentUserId: (widget.profile['id'] ?? '').toString(),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //               ListTile(
  //                 leading:
  //                 const Icon(Icons.playlist_add_check_circle_outlined),
  //                 title: const Text('Add Bulk Items'),
  //                 subtitle: const Text('Paste CSV, TSV, or JSON rows'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _openBulkAddItemsSheet();
  //                 },
  //               ),
  //               ListTile(
  //                 leading: const Icon(Icons.description_outlined),
  //                 title: const Text('View Quotations'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.of(context).push(
  //                     MaterialPageRoute(
  //                       builder: (_) => const QuotationListScreen(),
  //                     ),
  //                   );
  //                 },
  //               ),
  //               ListTile(
  //                 leading: const Icon(Icons.lock_person_outlined),
  //                 title: const Text('Price Permissions'),
  //                 subtitle:
  //                 const Text('Global and per-user price restrictions'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.of(context).push(
  //                     MaterialPageRoute(
  //                       builder: (_) => const PricePermissionsScreen(),
  //                     ),
  //                   );
  //                 },
  //               ),
  //               ListTile(
  //                 leading: const Icon(Icons.qr_code_scanner_rounded),
  //                 title: const Text('Scan Barcode'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _startBarcodeScan();
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  Future<void> _openFabActions() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_canUseContainerProcessor) ...[
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Container Processor'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ContainerProcessorScreen(),
                        ),
                      );
                    },
                  ),],
        if (_canAddItems) ...[
                  ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: const Text('Add Item'),
                    onTap: () {
                      Navigator.pop(context);
                      _openAddItemSheet();
                    },
                  ),
                  if(_canManageUsers)
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Manage User Roles'),
                    subtitle: const Text('Change roles for other users'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserRoleManagementScreen(
                            currentUserId: (widget.profile['id'] ?? '').toString(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_check_circle_outlined),
                    title: const Text('Add Bulk Items'),
                    subtitle: const Text('Paste CSV, TSV, or JSON rows'),
                    onTap: () {
                      Navigator.pop(context);
                      _openBulkAddItemsSheet();
                    },
                  ),
                ],
                if(_canViewQuotations || _canCreateQuotation)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_isAdmin ? 'View Quotations' : _isSales? 'My Quotations':""),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuotationListScreen(
                          role: _role,
                          currentUserId:
                          (widget.profile['id'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                ),
                if (_canManagePricePermissions)
                  ListTile(
                    leading: const Icon(Icons.lock_person_outlined),
                    title: const Text('Price Permissions'),
                    subtitle:
                    const Text('Global and per-user price restrictions'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PricePermissionsScreen(),
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: const Text('Scan Barcode'),
                  onTap: () {
                    Navigator.pop(context);
                    _startBarcodeScan();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFabActions,
        icon: Icon(
          _isAdmin
              ? Icons.admin_panel_settings_rounded
              : Icons.apps,
        ),
        label: Text( 'Actions'),
      ),
      bottomNavigationBar: _selectedQuoteItems.isEmpty
          ? null
          : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(
              top: BorderSide(color: Color(0xFF3A2F0B)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedQuoteItems.length} item(s) • Total: ${_formatPrice(_selectedGrandTotal)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _openSelectedItemsSheet,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(
              searchController: _searchController,
              selectedCategory: _selectedCategory,
              categories: _categories,
              visibleCount: _filteredItems.length,
              totalCount: _allItems.length,
              onClearFilters: _clearFilters,
              onCategorySelected: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters();
                });
              },
              profile: widget.profile,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4A3B12)),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load data',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loadItems,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Center(
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF4A3B12)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 52,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try changing the search text or category filter.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _gridCount(constraints.maxWidth);

        if (crossAxisCount == 1) {
          return RefreshIndicator(
            onRefresh: _loadItems,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _LuxuryProductCard(
                  item: _filteredItems[index],
                  formatPrice: _formatPrice,
                  onTap: () => _openDetails(_filteredItems[index]),
                  pricePermissions: _pricePermissions,
                  selectedPriceKey:
                  _selectedPriceKeyForItem(_filteredItems[index]),
                  onSelectPrice: (priceKey, priceLabel) {
                    _toggleItemPriceSelection(
                      _filteredItems[index],
                      priceKey,
                      priceLabel,
                    );
                  },
                  isLoadingPermissions: _isLoadingPermissions, canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadItems,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: _filteredItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              return _LuxuryProductCard(
                item: _filteredItems[index],
                formatPrice: _formatPrice,
                onTap: () => _openDetails(_filteredItems[index]),
                pricePermissions: _pricePermissions,
                selectedPriceKey:
                _selectedPriceKeyForItem(_filteredItems[index]),
                onSelectPrice: (priceKey, priceLabel) {
                  _toggleItemPriceSelection(
                    _filteredItems[index],
                    priceKey,
                    priceLabel,
                  );
                },
                isLoadingPermissions: _isLoadingPermissions, canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
              );
            },
          ),
        );
      },
    );
  }
}

Map<String, dynamic> _buildPriceListItemPayload(Map<String, dynamic> source) {
  double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  String? toText(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    return raw.isEmpty ? null : raw;
  }

  String? displayPrice = toText(source['display_price']);
  final totalPrice = toDouble(source['total_price']);

  if ((displayPrice == null || displayPrice.isEmpty) && totalPrice != null) {
    displayPrice = totalPrice == totalPrice.roundToDouble()
        ? totalPrice.toInt().toString()
        : totalPrice.toStringAsFixed(2);
  }

  return {
    'category_ar': toText(source['category_ar']),
    'description': toText(source['description']),
    'product_name': toText(source['product_name']),
    'item_code': toText(source['item_code']),
    'price_ee': toDouble(source['price_ee']),
    'price_aa': toDouble(source['price_aa']),
    'price_a': toDouble(source['price_a']),
    'price_rr': toDouble(source['price_rr']),
    'price_r': toDouble(source['price_r']),
    'price_art': toDouble(source['price_art']),
    'pot_item_no': toText(source['pot_item_no']),
    'pot_price': toDouble(source['pot_price']),
    'additions': toText(source['additions']),
    'total_price': totalPrice,
    'display_price': displayPrice,
    'image_path': toText(source['image_path']),
    'length': toText(source['length']),
    'width': toText(source['width']),
    'production_time': toText(source['production_time']),
    'is_active': source['is_active'] == null
        ? true
        : source['is_active'] == true ||
        source['is_active'].toString().toLowerCase() == 'true' ||
        source['is_active'].toString() == '1',
  }..removeWhere((key, value) => value == null);
}

class _HeaderSection extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedCategory;
  final List<String> categories;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onClearFilters;
  final ValueChanged<String?> onCategorySelected;
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;

  const _HeaderSection({
    required this.searchController,
    required this.selectedCategory,
    required this.categories,
    required this.visibleCount,
    required this.totalCount,
    required this.onClearFilters,
    required this.onCategorySelected,
    required this.onLogout,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters =
        selectedCategory != null || searchController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF3A2F0B)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          AppConstants.primaryColor,
                          Color(0xFF8C6B16),
                        ],
                      ),
                    ),
                    child: Image.asset('assets/icons/logo_black.png'),
                  ),
                  const SizedBox(width: 12),

                    FittedBox(
                      child: Text(
                        'Price List',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                  children:[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ((profile['full_name'] ?? '').toString().trim().isNotEmpty
                                  ? profile['full_name']
                                  : profile['email'])
                                  .toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            (profile['role']).toString().toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await onLogout();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Logout'),
                        ),
                      ],
                      icon: const Icon(Icons.account_circle_outlined),
                    ),
                    if (hasFilters)
                      TextButton.icon(
                        onPressed: onClearFilters,
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Clear'),
                      ),
                  ]
              )

            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4A3B12)),
              color: const Color(0xFF161616),
            ),
            child: TextField(
              controller: searchController,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Color(0xFFF5E7B2)),
              decoration: InputDecoration(
                hintText: 'Search by name, code, description, or barcode',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.trim().isNotEmpty
                    ? IconButton(
                  onPressed: () => searchController.clear(),
                  icon: const Icon(Icons.close_rounded),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: const Text('All'),    
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategorySelected(null),
                  ),
                ),
                ...categories.map(
                      (category) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) {
                        onCategorySelected(
                          selectedCategory == category ? null : category,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '$visibleCount / $totalCount items',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LuxuryProductCard extends StatelessWidget {
  final bool canSelectPricesForQuotation;
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;
  final VoidCallback onTap;
  final Map<String, bool> pricePermissions;
  final String? selectedPriceKey;
  final void Function(String priceKey, String priceLabel) onSelectPrice;
  final bool isLoadingPermissions;

  const _LuxuryProductCard({
    required this.item,
    required this.formatPrice,
    required this.onTap,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
  });

  String? _imageUrlFromItem(Map<String, dynamic> item) {
    final imagePath = (item['image_path'] ?? '').toString().trim();
    if (imagePath.isEmpty) return null;

    return Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(imagePath);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productName = (item['product_name'] ?? '').toString().trim();
    final category = (item['category_ar'] ?? '').toString().trim();
    final description = (item['description'] ?? '').toString().trim();
    final itemCode = (item['item_code'] ?? '').toString().trim();
    final potItemNo = (item['pot_item_no'] ?? '').toString().trim();
    final additions = (item['additions'] ?? '').toString().trim();
    final imageUrl = _imageUrlFromItem(item);

    final effectivePrice = item['effective_price'];
    final totalPrice = item['total_price'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF3A2F0B)),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _ImagePlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(
                        text: category.isEmpty ? 'Uncategorized' : category,
                        background: const Color(0xFF3A2F0B),
                        foreground: const Color(0xFFF5E7B2),
                      ),
                      if (itemCode.isNotEmpty)
                        _TagChip(
                          text: itemCode,
                          background: const Color(0xFF1C1C1C),
                          foreground: AppConstants.primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    productName.isEmpty ? 'Unnamed Product' : productName,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty ? '—' : description,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE0CF90),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3A2F0B),
                          Color(0xFF1C1C1C),
                        ],
                      ),
                      border: Border.all(color: const Color(0xFF5B4916)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sell_rounded,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Effective Price',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          formatPrice(effectivePrice),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: const Color(0xFFFFD95E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose selling price',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color:  AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoadingPermissions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _priceOptions.map((option) {
                        final rawValue = item[option.key];
                        final numericValue = _toDouble(rawValue);
                        final exists = numericValue != null;
                        // final allowed =
                        //     (pricePermissions[option.key] ?? true) && exists;
                        final allowed =
                            canSelectPricesForQuotation &&
                                (pricePermissions[option.key] ?? true) &&
                                exists;
                        final selected = selectedPriceKey == option.key;
            
                        return FilterChip(
                          label: Text(
                            '${option.label} ${exists ? formatPrice(rawValue) : '-'}',
                          ),
                          selected: selected,
                          onSelected: allowed
                              ? (_) => onSelectPrice(option.key, option.label)
                              : null,
                          disabledColor: const Color(0xFF232323),
            
                          labelStyle: TextStyle(
                            color: allowed
                                ? (selected
                                ? const Color(0xFF0A0A0A)
                                : const Color(0xFFF5E7B2))
                                : const Color(0xFF7A7A7A),
                            fontWeight: FontWeight.w700,
                          ),
                          selectedColor: AppConstants.primaryColor,
                          backgroundColor: const Color(0xFF1A1A1A),
                          side: BorderSide(
                            color: selected
                                ? AppConstants.primaryColor
                                : const Color(0xFF2F2A18),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallPriceBox(
                        label: 'TOTAL',
                        value: formatPrice(totalPrice),
                      ),
                      if (potItemNo.isNotEmpty)
                        _SmallInfoBox(label: 'POT', value: potItemNo),
                      if (additions.isNotEmpty)
                        _SmallInfoBox(label: 'ADD', value: additions),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;

  const _ProductDetailsSheet({
    required this.item,
    required this.formatPrice,
  });

  String? _imageUrlFromItem(Map<String, dynamic> item) {
    final imagePath = (item['image_path'] ?? '').toString().trim();
    if (imagePath.isEmpty) return null;

    return Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productName = (item['product_name'] ?? '').toString().trim();
    final category = (item['category_ar'] ?? '').toString().trim();
    final description = (item['description'] ?? '').toString().trim();
    final itemCode = (item['item_code'] ?? '').toString().trim();
    final potItemNo = (item['pot_item_no'] ?? '').toString().trim();
    final additions = (item['additions'] ?? '').toString().trim();
    final imageUrl = _imageUrlFromItem(item);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => _ImagePlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              productName.isEmpty ? 'Unnamed Product' : productName,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3A2F0B),
                    Color(0xFF1B1B1B),
                  ],
                ),
                border: Border.all(color: const Color(0xFF5B4916)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Effective Price',
                      style: TextStyle(
                        color: Color(0xFFF5E7B2),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(item['effective_price']),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFFD95E),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DetailsSection(
              title: 'Basic Information',
              children: [
                _InfoRow(label: 'Category', value: category, rtl: true),
                _InfoRow(label: 'Description', value: description, rtl: true),
                _InfoRow(label: 'Item Code', value: itemCode),
                _InfoRow(label: 'Pot Item No', value: potItemNo),
                _InfoRow(label: 'Additions', value: additions, rtl: true),
                _InfoRow(
                  label: 'Display Price',
                  value: (item['display_price'] ?? '').toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailsSection(
              title: 'Prices',
              children: [
                _PriceRow(label: 'EE', value: formatPrice(item['price_ee'])),
                _PriceRow(label: 'AA', value: formatPrice(item['price_aa'])),
                _PriceRow(label: 'A', value: formatPrice(item['price_a'])),
                _PriceRow(label: 'RR', value: formatPrice(item['price_rr'])),
                _PriceRow(label: 'R', value: formatPrice(item['price_r'])),
                _PriceRow(label: 'ART', value: formatPrice(item['price_art'])),
                _PriceRow(
                  label: 'Pot Price',
                  value: formatPrice(item['pot_price']),
                ),
                _PriceRow(
                  label: 'Total Price',
                  value: formatPrice(item['total_price']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _priceEeController = TextEditingController();
  final _priceAaController = TextEditingController();
  final _priceAController = TextEditingController();
  final _priceRrController = TextEditingController();
  final _priceRController = TextEditingController();
  final _priceArtController = TextEditingController();
  final _potItemNoController = TextEditingController();
  final _potPriceController = TextEditingController();
  final _additionsController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _displayPriceController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _productionTimeController = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _itemCodeController.dispose();
    _priceEeController.dispose();
    _priceAaController.dispose();
    _priceAController.dispose();
    _priceRrController.dispose();
    _priceRController.dispose();
    _priceArtController.dispose();
    _potItemNoController.dispose();
    _potPriceController.dispose();
    _additionsController.dispose();
    _totalPriceController.dispose();
    _displayPriceController.dispose();
    _imagePathController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _productionTimeController.dispose();
    super.dispose();
  }

  double? _toDouble(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPriceListItemPayload({
      'category_ar': _categoryController.text,
      'description': _descriptionController.text,
      'product_name': _productNameController.text,
      'item_code': _itemCodeController.text,
      'price_ee': _priceEeController.text,
      'price_aa': _priceAaController.text,
      'price_a': _priceAController.text,
      'price_rr': _priceRrController.text,
      'price_r': _priceRController.text,
      'price_art': _priceArtController.text,
      'pot_item_no': _potItemNoController.text,
      'pot_price': _potPriceController.text,
      'additions': _additionsController.text,
      'total_price': _totalPriceController.text,
      'display_price': _displayPriceController.text,
      'image_path': _imagePathController.text,
      'length': _lengthController.text,
      'width': _widthController.text,
      'production_time': _productionTimeController.text,
      'is_active': _isActive,
    });

    setState(() {
      _isSaving = true;
    });

    try {
      await Supabase.instance.client.from('price_list_items').insert(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        bool required = false,
        bool isNumeric = false,
        TextInputType? keyboardType,
        int maxLines = 1,
        String? hint,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        if (isNumeric &&
            value != null &&
            value.trim().isNotEmpty &&
            _toDouble(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _field('Product Name', _productNameController, required: true),
              const SizedBox(height: 12),
              _field('Category (Arabic)', _categoryController, required: true),
              const SizedBox(height: 12),
              _field('Item Code', _itemCodeController),
              const SizedBox(height: 12),
              _field('Description', _descriptionController, maxLines: 3),
              const SizedBox(height: 12),
              Wrap(
                runSpacing: 12,
                spacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price EE',
                      _priceEeController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price AA',
                      _priceAaController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price A',
                      _priceAController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price RR',
                      _priceRrController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price R',
                      _priceRController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Price ART',
                      _priceArtController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Pot Price',
                      _potPriceController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      'Total Price',
                      _totalPriceController,
                      isNumeric: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field('Pot Item No', _potItemNoController),
              const SizedBox(height: 12),
              _field('Additions', _additionsController, maxLines: 2),
              const SizedBox(height: 12),
              _field('Length', _lengthController),
              const SizedBox(height: 12),
              _field('Width', _widthController),
              const SizedBox(height: 12),
              _field('Production Time', _productionTimeController),
              const SizedBox(height: 12),
              _field('Display Price', _displayPriceController),
              const SizedBox(height: 12),
              _field(
                'Image Path',
                _imagePathController,
                hint: 'Bucket path, e.g. flowers/item-1.jpg',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged:
                _isSaving ? null : (value) => setState(() => _isActive = value),
                title: const Text('Active'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Create Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkAddItemsSheet extends StatefulWidget {
  const _BulkAddItemsSheet();

  @override
  State<_BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
}

class _BulkAddItemsSheetState extends State<_BulkAddItemsSheet> {
  final _inputController = TextEditingController();
  bool _isSaving = false;
  int _previewCount = 0;
  String? _previewError;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseRows(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      throw const FormatException('Paste at least one row.');
    }

    if (input.startsWith('[')) {
      final decoded = jsonDecode(input);
      if (decoded is! List) {
        throw const FormatException('JSON input must be an array of objects.');
      }

      final rows = decoded
          .map(
            (e) => _buildPriceListItemPayload(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .where((e) => e.isNotEmpty)
          .toList();

      for (final row in rows) {
        if ((row['product_name'] ?? '').toString().trim().isEmpty) {
          throw const FormatException('Each row must include product_name.');
        }
        if ((row['category_ar'] ?? '').toString().trim().isEmpty) {
          throw const FormatException('Each row must include category_ar.');
        }
      }

      return rows;
    }

    List<List<dynamic>> table;

    try {
      table = const CsvDecoder(
        dynamicTyping: false,
      ).convert(input);
    } catch (_) {
      try {
        table = const CsvDecoder(
          fieldDelimiter: '\t',
          dynamicTyping: false,
        ).convert(input);
      } catch (e) {
        throw FormatException('Invalid CSV/TSV format: $e');
      }
    }

    if (table.length < 2) {
      throw const FormatException(
        'Provide a header row and at least one data row.',
      );
    }

    final headers = table.first
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    if (headers.isEmpty) {
      throw const FormatException('Header row is empty.');
    }

    final rows = <Map<String, dynamic>>[];

    for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final values = table[rowIndex];

      final rawRow = <String, dynamic>{};
      for (var col = 0; col < headers.length; col++) {
        rawRow[headers[col]] = col < values.length ? values[col] : null;
      }

      final payload = _buildPriceListItemPayload(rawRow);

      if ((payload['product_name'] ?? '').toString().trim().isEmpty) {
        throw FormatException(
          'Row ${rowIndex + 1}: product_name is required.',
        );
      }

      if ((payload['category_ar'] ?? '').toString().trim().isEmpty) {
        throw FormatException(
          'Row ${rowIndex + 1}: category_ar is required.',
        );
      }

      rows.add(payload);
    }

    if (rows.isEmpty) {
      throw const FormatException('No valid rows found.');
    }

    return rows;
  }

  void _updatePreview() {
    final raw = _inputController.text;

    if (raw.trim().isEmpty) {
      setState(() {
        _previewCount = 0;
        _previewError = null;
      });
      return;
    }

    try {
      final rows = _parseRows(raw);
      setState(() {
        _previewCount = rows.length;
        _previewError = null;
      });
    } catch (e) {
      setState(() {
        _previewCount = 0;
        _previewError = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    List<Map<String, dynamic>> rows;
    try {
      rows = _parseRows(_inputController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid bulk input: $e')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Supabase.instance.client.from('price_list_items').insert(rows);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${rows.length} items added successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk insert failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Bulk Items',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste CSV, TSV, or JSON rows. CSV parsing supports quoted values properly. Required columns: product_name, category_ar.',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3A2F0B)),
              ),
              child: const SelectableText(
                'Example CSV\n'
                    'product_name,category_ar,item_code,total_price,is_active\n'
                    '"Rose Box, Large",ورد,RB-100,125,true\n\n'
                    'Example JSON\n'
                    '[{"product_name":"Rose Box","category_ar":"ورد","item_code":"RB-100","total_price":125}]',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              onChanged: (_) => _updatePreview(),
              minLines: 10,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: 'Bulk rows',
                alignLabelWithHint: true,
                hintText: 'Paste CSV / TSV / JSON here',
              ),
            ),
            const SizedBox(height: 12),
            if (_previewError != null)
              Text(
                _previewError!,
                style: const TextStyle(color: Color(0xFFFFC7CE)),
              )
            else if (_previewCount > 0)
              Text(
                'Ready to insert $_previewCount item(s).',
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                (_isSaving || _previewCount == 0 || _previewError != null)
                    ? null
                    : _submit,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.playlist_add_check_circle_outlined),
                label: Text(_isSaving ? 'Importing...' : 'Insert Bulk Items'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateQuotationSheet extends StatefulWidget {
  final double subtotal;
  final String Function(dynamic value) formatPrice;
  final Map<String, dynamic> profile;

  const _CreateQuotationSheet({
    required this.subtotal,
    required this.formatPrice,
    required this.profile,
  });

  @override
  State<_CreateQuotationSheet> createState() => _CreateQuotationSheetState();
}

class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _customerTrnController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _salespersonNameController = TextEditingController();
  final _salespersonContactController = TextEditingController();
  final _notesController = TextEditingController();

  final _deliveryFeeController = TextEditingController(text: '0');
  final _installationFeeController = TextEditingController(text: '0');
  final _additionalDetailsFeeController = TextEditingController(text: '0');
  final _vatPercentController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    final fullName = (widget.profile['full_name'] ?? '').toString().trim();
    final email = (widget.profile['email'] ?? '').toString().trim();
    _salespersonNameController.text = fullName;
    _salespersonContactController.text = email;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _customerTrnController.dispose();
    _customerPhoneController.dispose();
    _salespersonNameController.dispose();
    _salespersonContactController.dispose();
    _notesController.dispose();
    _deliveryFeeController.dispose();
    _installationFeeController.dispose();
    _additionalDetailsFeeController.dispose();
    _vatPercentController.dispose();
    super.dispose();
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get _deliveryFee => _parseNumber(_deliveryFeeController.text);
  double get _installationFee => _parseNumber(_installationFeeController.text);
  double get _additionalDetailsFee =>
      _parseNumber(_additionalDetailsFeeController.text);
  double get _vatPercent => _parseNumber(_vatPercentController.text);

  double get _taxableTotal =>
      widget.subtotal + _deliveryFee + _installationFee + _additionalDetailsFee;

  double get _vatAmount => _taxableTotal * (_vatPercent / 100);

  double get _netTotal => _taxableTotal + _vatAmount;

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (double.tryParse(value.trim()) == null) return 'Invalid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Quotation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerTrnController,
                    decoration: const InputDecoration(
                      labelText: 'Customer TRN',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: false,
                    controller: _salespersonNameController,
                    decoration: const InputDecoration(
                      labelText: 'Salesperson Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                      enabled: false,
                    controller: _salespersonContactController,
                    decoration: const InputDecoration(
                      labelText: 'Salesperson Contact',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryFeeController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Delivery Fee',
                    ),
                    validator: _validateNumber,
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _installationFeeController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Installation Fee',
                    ),
                    validator: _validateNumber,
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _additionalDetailsFeeController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Additional Details Fee',
                    ),
                    validator: _validateNumber,
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vatPercentController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'VAT Percent',
                    ),
                    validator: _validateNumber,
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3A2F0B)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Subtotal')),
                            Text(widget.formatPrice(widget.subtotal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Taxable Total')),
                            Text(widget.formatPrice(_taxableTotal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'VAT (${widget.formatPrice(_vatPercent)}%)',
                              ),
                            ),
                            Text(widget.formatPrice(_vatAmount)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Net Total',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Text(
                              widget.formatPrice(_netTotal),
                              style: const TextStyle(
                                color: Color(0xFFFFD95E),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        Navigator.pop(
                          context,
                          _QuotationDraft(
                            customerName: _customerNameController.text.trim(),
                            companyName: _companyNameController.text.trim(),
                            customerTrn: _customerTrnController.text.trim(),
                            customerPhone: _customerPhoneController.text.trim(),
                            salespersonName:
                            _salespersonNameController.text.trim(),
                            salespersonContact:
                            _salespersonContactController.text.trim(),
                            notes: _notesController.text.trim(),
                            deliveryFee: _deliveryFee,
                            installationFee: _installationFee,
                            additionalDetailsFee: _additionalDetailsFee,
                            vatPercent: _vatPercent,
                            salespersonPhone: widget.profile["phone"],
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Quotation'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool rtl;

  const _InfoRow({
    required this.label,
    required this.value,
    this.rtl = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(
                color: Color(0xFFF5E7B2),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == '-' || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F2A18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5E7B2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _TagChip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5B4916)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SmallPriceBox extends StatelessWidget {
  final String label;
  final String value;

  const _SmallPriceBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == '-') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F2A18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5E7B2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F2A18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Color(0xFFF5E7B2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PricePermissionsScreen extends StatefulWidget {
  const PricePermissionsScreen({super.key});

  @override
  State<PricePermissionsScreen> createState() =>
      _PricePermissionsScreenState();
}

class _PricePermissionsScreenState extends State<PricePermissionsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSavingGlobal = false;
  String? _error;

  bool _globalBlockAll = false;
  final Set<String> _globalBlockedKeys = {};

  List<Map<String, dynamic>> _users = [];
  Map<String, bool> _userBlockAll = {};
  Map<String, Set<String>> _userBlockedKeys = {};

  final TextEditingController _userSearchController = TextEditingController();
  final Set<String> _savingUserIds = {};
  bool _isSavingAllUsers = false;
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _userSearchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _userSearchQuery = _userSearchController.text.trim().toLowerCase();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final settingsResponse = await _supabase
          .from('price_permission_settings')
          .select('id, block_all_prices')
          .eq('id', 1)
          .maybeSingle();

      final globalBlockedResponse = await _supabase
          .from('global_blocked_price_keys')
          .select('price_key');

      final usersResponse = await _supabase
          .from('profiles')
          .select('id, email, full_name, role, is_active')
          .order('full_name', ascending: true);

      final profileAccessResponse = await _supabase
          .from('profile_price_access')
          .select('profile_id, block_all_prices');

      final profileBlockedResponse = await _supabase
          .from('profile_blocked_price_keys')
          .select('profile_id, price_key');

      final users = (usersResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => (e['role'] ?? '').toString() == 'sales')
          .toList();

      final globalBlocked = <String>{};
      for (final row in (globalBlockedResponse as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final key = (map['price_key'] ?? '').toString();
        if (key.isNotEmpty) globalBlocked.add(key);
      }

      final userBlockAll = <String, bool>{};
      for (final row in (profileAccessResponse as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final profileId = (map['profile_id'] ?? '').toString();
        if (profileId.isEmpty) continue;
        userBlockAll[profileId] = map['block_all_prices'] == true;
      }

      final userBlockedKeys = <String, Set<String>>{};
      for (final row in (profileBlockedResponse as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final profileId = (map['profile_id'] ?? '').toString();
        final key = (map['price_key'] ?? '').toString();
        if (profileId.isEmpty || key.isEmpty) continue;
        userBlockedKeys.putIfAbsent(profileId, () => <String>{}).add(key);
      }

      for (final user in users) {
        final id = (user['id'] ?? '').toString();
        userBlockAll.putIfAbsent(id, () => false);
        userBlockedKeys.putIfAbsent(id, () => <String>{});
      }

      if (!mounted) return;
      setState(() {
        _globalBlockAll = (settingsResponse?['block_all_prices'] == true);
        _globalBlockedKeys
          ..clear()
          ..addAll(globalBlocked);
        _users = users;
        _userBlockAll = userBlockAll;
        _userBlockedKeys = userBlockedKeys;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGlobalSettings() async {
    if (_isSavingGlobal) return;

    setState(() {
      _isSavingGlobal = true;
    });

    try {
      await _supabase.from('price_permission_settings').upsert({
        'id': 1,
        'block_all_prices': _globalBlockAll,
      });

      await _supabase.from('global_blocked_price_keys').delete().neq('id', 0);

      if (_globalBlockedKeys.isNotEmpty) {
        await _supabase.from('global_blocked_price_keys').insert(
          _globalBlockedKeys.map((key) => {'price_key': key}).toList(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Global price permissions saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save global settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingGlobal = false;
        });
      }
    }
  }

  Future<void> _saveUserPermissions(String profileId) async {
    if (_savingUserIds.contains(profileId)) return;

    setState(() {
      _savingUserIds.add(profileId);
    });

    try {
      await _supabase.from('profile_price_access').upsert({
        'profile_id': profileId,
        'block_all_prices': _userBlockAll[profileId] ?? false,
      });

      await _supabase
          .from('profile_blocked_price_keys')
          .delete()
          .eq('profile_id', profileId);

      final blocked = _userBlockedKeys[profileId] ?? <String>{};
      if (blocked.isNotEmpty) {
        await _supabase.from('profile_blocked_price_keys').insert(
          blocked
              .map(
                (key) => {
              'profile_id': profileId,
              'price_key': key,
            },
          )
              .toList(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User price permissions saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user permissions: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingUserIds.remove(profileId);
        });
      }
    }
  }

  String _userDisplayName(Map<String, dynamic> user) {
    final fullName = (user['full_name'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return 'Unknown User';
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;

    return _users.where((user) {
      final name = _userDisplayName(user).toLowerCase();
      final email = (user['email'] ?? '').toString().trim().toLowerCase();
      return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
    }).toList();
  }

  Future<void> _saveAllUserPermissions() async {
    if (_isSavingAllUsers) return;

    setState(() {
      _isSavingAllUsers = true;
    });

    try {
      for (final user in _filteredUsers) {
        final profileId = (user['id'] ?? '').toString();
        if (profileId.isEmpty) continue;

        setState(() {
          _savingUserIds.add(profileId);
        });

        await _supabase.from('profile_price_access').upsert({
          'profile_id': profileId,
          'block_all_prices': _userBlockAll[profileId] ?? false,
        });

        await _supabase
            .from('profile_blocked_price_keys')
            .delete()
            .eq('profile_id', profileId);

        final blocked = _userBlockedKeys[profileId] ?? <String>{};
        if (blocked.isNotEmpty) {
          await _supabase.from('profile_blocked_price_keys').insert(
            blocked
                .map(
                  (key) => {
                'profile_id': profileId,
                'price_key': key,
              },
            )
                .toList(),
          );
        }

        if (mounted) {
          setState(() {
            _savingUserIds.remove(profileId);
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${_filteredUsers.length} user permission set(s).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save all user settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAllUsers = false;
          _savingUserIds.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Price Permissions'),
        backgroundColor: const Color(0xFF111111),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3A2F0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Controls',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title:
                    const Text('Block all prices for all users'),
                    value: _globalBlockAll,
                    onChanged: (value) {
                      setState(() {
                        _globalBlockAll = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Blocked price keys for all users',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _priceOptions.map((option) {
                      final blocked =
                      _globalBlockedKeys.contains(option.key);

                      return FilterChip(
                        label: Text(option.label),
                        selected: blocked,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _globalBlockedKeys.add(option.key);
                            } else {
                              _globalBlockedKeys.remove(option.key);
                            }
                          });
                        },
                        selectedColor: AppConstants.primaryColor,
                        backgroundColor: const Color(0xFF1A1A1A),
                        labelStyle: TextStyle(
                          color: blocked
                              ? const Color(0xFF0A0A0A)
                              : const Color(0xFFF5E7B2),
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                      _isSavingGlobal ? null : _saveGlobalSettings,
                      icon: _isSavingGlobal
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSavingGlobal
                            ? 'Saving...'
                            : 'Save Global Settings',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Per-User Controls',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(
                labelText: 'Search users',
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredUsers.length} user(s)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                  (_isSavingAllUsers || _filteredUsers.isEmpty)
                      ? null
                      : _saveAllUserPermissions,
                  icon: _isSavingAllUsers
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSavingAllUsers
                      ? 'Saving...'
                      : 'Save All Visible Users'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._filteredUsers.map((user) {
              final profileId = (user['id'] ?? '').toString();
              final blockedKeys =
                  _userBlockedKeys[profileId] ?? <String>{};
              final blockAll = _userBlockAll[profileId] ?? false;
              final isActive = user['is_active'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3A2F0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userDisplayName(user),
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (user['email'] ?? '').toString(),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF1F3A1F)
                                : const Color(0xFF3A1F1F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Block all prices for this user'),
                      value: blockAll,
                      onChanged: (value) {
                        setState(() {
                          _userBlockAll[profileId] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Blocked price keys for this user',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _priceOptions.map((option) {
                        final blocked =
                        blockedKeys.contains(option.key);

                        return FilterChip(
                          label: Text(option.label),
                          selected: blocked,
                          onSelected: (selected) {
                            setState(() {
                              final set =
                              _userBlockedKeys.putIfAbsent(
                                profileId,
                                    () => <String>{},
                              );
                              if (selected) {
                                set.add(option.key);
                              } else {
                                set.remove(option.key);
                              }
                            });
                          },
                          selectedColor: AppConstants.primaryColor,
                          backgroundColor: const Color(0xFF1A1A1A),
                          labelStyle: TextStyle(
                            color: blocked
                                ? const Color(0xFF0A0A0A)
                                : const Color(0xFFF5E7B2),
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _savingUserIds.contains(profileId)
                            ? null
                            : () => _saveUserPermissions(profileId),
                        icon: _savingUserIds.contains(profileId)
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _savingUserIds.contains(profileId)
                              ? 'Saving...'
                              : 'Save User Settings',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppConstants.primaryColor,
        size: 34,
      ),
    );
  }
}