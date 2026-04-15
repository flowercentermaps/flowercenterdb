import 'dart:async';
import 'dart:convert';
import 'package:FlowerCenterCrm/user_role_management_screen.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'container_processor_screen.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/domain/entities/user_profile.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'login_screen.dart';
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

const List<String> _specialPriceAllowedUsers = ['maher', 'hayan'];

bool _canSeeSpecialPrice(UserProfile profile) {
  final name = profile.name.trim().toLowerCase();
  return _specialPriceAllowedUsers.any((n) => name.contains(n));
}

List<_PriceOptionMeta> _visiblePriceOptions(UserProfile profile) {
  if (_canSeeSpecialPrice(profile)) return _priceOptions;
  return _priceOptions.where((o) => o.key != 'price_art').toList();
}
enum _ViewMode { list, grid }

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
    String? productName,
    String? priceKey,
    String? priceLabel,
    double? unitPrice,
    int? quantity,
    Map<String, dynamic>? item,
  }) {
    return _SelectedQuoteItem(
      itemId: itemId,
      productName: productName ?? this.productName,
      priceKey: priceKey ?? this.priceKey,
      priceLabel: priceLabel ?? this.priceLabel,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      item: item ?? this.item,
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

// double _safeDouble(dynamic value) {
//   if (value == null) return 0;
//   if (value is num) return value.toDouble();
//   return double.tryParse(value.toString().trim()) ?? 0;
// }

String? _safeTextOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class PriceListScreen extends ConsumerStatefulWidget {
  const PriceListScreen({super.key});

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _ViewMode _viewMode = _ViewMode.list;
  static const String _kViewModeKey = 'price_list_view_mode';

  Timer? _debounce;

  bool _isLoading = true;
  bool _isLoadingPermissions = true;
  bool _isSavingQuotation = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _categories = [];

  /// supplier_code → total quantity across all branches/stores
  Map<String, double> _stockTotals = {};

  String _searchQuery = '';
  String? _selectedCategory;
  String _productType = 'tree';
  bool _showOutOfStockOnly = false;

  bool _showFiltersOnMobile = false;

  final Map<String, bool> _pricePermissions = {
    for (final option in _priceOptions) option.key: true,
  };

  final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};

  UserProfile get _profile =>
      ref.read(profileProvider).value ??
      const UserProfile(id: '', email: '', name: '', role: '', isActive: false);

  String get _role => _profile.role.trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isAccountant => _role == 'accountant';
  // bool get _isViewer => _role == 'viewer';

  bool get _canCreateQuotation => _isSales || _isAdmin;
  bool get _canViewQuotations => _isSales || _isAdmin;
  bool get _canAddItems => _isAdmin || _isAccountant;
  bool get _canManageUsers => _isAdmin;
  bool get _canUseContainerProcessor => _isAdmin || _isAccountant;
  bool get _canUsePriceChipsForQuotation => _isAdmin || _isSales;

  // @override
  // void initState() {
  //   super.initState();
  //   _searchController.addListener(_onSearchChanged);
  //   _bootstrap();
  // }
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadViewMode();
    _bootstrap();
  }
  Future<void> _bootstrap() async {
    await Future.wait([
      _loadItems(),
      _loadPricePermissions(),
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
        _applyFilters();
      });
    });
  }


  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kViewModeKey);

    if (!mounted) return;

    setState(() {
      _viewMode = saved == 'grid' ? _ViewMode.grid : _ViewMode.list;
    });
  }
  // Widget _buildCompactList() {
  //   return RefreshIndicator(
  //     onRefresh: _loadItems,
  //     child: ListView.builder(
  //       controller: _scrollController,
  //       physics: const AlwaysScrollableScrollPhysics(),
  //       padding: const EdgeInsets.fromLTRB(10, 8, 10, 90),
  //       itemCount: _filteredItems.length,
  //       itemBuilder: (context, index) {
  //         final item = _filteredItems[index];
  //
  //         return _CompactListTile(
  //           item: item,
  //           formatPrice: _formatPrice,
  //           onTap: () => _openDetails(item),
  //           pricePermissions: _pricePermissions,
  //           selectedPriceKey: _selectedPriceKeyForItem(item),
  //           onSelectPrice: (priceKey, priceLabel) {
  //             _toggleItemPriceSelection(item, priceKey, priceLabel);
  //           },
  //           isLoadingPermissions: _isLoadingPermissions,
  //           canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
  //         );
  //       },
  //     ),
  //   );
  // }Widget _buildCompactList() {
  //   return RefreshIndicator(
  //     onRefresh: _loadItems,
  //     child: ListView.builder(
  //       controller: _scrollController,
  //       physics: const AlwaysScrollableScrollPhysics(),
  //       padding: const EdgeInsets.fromLTRB(10, 8, 10, 90),
  //       itemCount: _filteredItems.length,
  //       itemBuilder: (context, index) {
  //         final item = _filteredItems[index];
  //
  //         return _CompactListTile(
  //           item: item,
  //           formatPrice: _formatPrice,
  //           onTap: () => _openDetails(item),
  //           pricePermissions: _pricePermissions,
  //           selectedPriceKey: _selectedPriceKeyForItem(item),
  //           onSelectPrice: (priceKey, priceLabel) {
  //             _toggleItemPriceSelection(item, priceKey, priceLabel);
  //           },
  //           isLoadingPermissions: _isLoadingPermissions,
  //           canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
  //         );
  //       },
  //     ),
  //   );
  // }
  Future<void> _setViewMode(_ViewMode mode) async {
    if (_viewMode == mode) return;

    setState(() {
      _viewMode = mode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewModeKey,
      mode == _ViewMode.grid ? 'grid' : 'list',
    );
  }
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('price_list_api')
            .select()
            .order('category_ar', ascending: true)
            .order('product_name', ascending: true),
        _supabase
            .from('stock_quantities')
            .select('supplier_code, quantity'),
      ]);

      final items = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final categories = items
          .map((e) => (e['category_ar'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Aggregate stock totals per supplier_code
      final Map<String, double> stockTotals = {};
      for (final row in results[1] as List) {
        final sc = (row['supplier_code'] ?? '').toString().trim();
        if (sc.isEmpty) continue;
        final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
        stockTotals[sc] = (stockTotals[sc] ?? 0) + qty;
      }

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _categories = categories;
        _stockTotals = stockTotals;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
        _pricePermissions
          ..clear()
          ..addAll(map);
        _isLoadingPermissions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingPermissions = false;
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
      final supplierCode = (item['supplier_code'] ?? '').toString().trim();
      final productType = (item['product_type'] ?? 'tree').toString().trim();

      final matchesType = productType == _productType;
      final matchesCategory =
          _selectedCategory == null || category == _selectedCategory;

      final haystack = [
        category,
        description,
        productName,
        itemCode,
        displayPrice,
        barcode,
        supplierCode,
      ].join(' ').toLowerCase();

      final matchesSearch = search.isEmpty || haystack.contains(search);

      bool matchesStock = true;
      if (_showOutOfStockOnly) {
        final sc = supplierCode.toUpperCase();
        final stockTotal = sc.isNotEmpty ? _stockTotals[sc] : null;
        matchesStock = stockTotal != null && stockTotal <= 0;
      }

      return matchesType && matchesCategory && matchesSearch && matchesStock;
    }).toList();

    // Recompute categories for the current product type
    _categories = _allItems
        .where((item) =>
            (item['product_type'] ?? 'tree').toString().trim() == _productType)
        .map((e) => (e['category_ar'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
      _showOutOfStockOnly = false;
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
    return double.tryParse(value.toString().trim());
  }

  String _formatPrice(dynamic value) {
    final number = _toDouble(value);
    if (number == null) return '-';
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
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

  void _setSelectedItemQuantity(int itemId, int qty) {
    final current = _selectedQuoteItems[itemId];
    if (current == null) return;
    setState(() {
      if (qty <= 0) {
        _selectedQuoteItems.remove(itemId);
      } else {
        _selectedQuoteItems[itemId] = current.copyWith(quantity: qty);
      }
    });
  }

  double get _selectedGrandTotal {
    return _selectedQuoteItems.values.fold(
      0,
          (sum, item) => sum + item.lineTotal,
    );
  }

  Future<void> _openCreateQuotationSheet({required bool isHamasat}) async {
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
        profile: _profile,
        isHamasat: isHamasat,
      ),
    );

    if (!mounted || draft == null) return;
    await _saveQuotation(draft , isHamasat);
  }

  Future<void> _saveQuotation(_QuotationDraft draft ,bool isHamasat) async {
    // Guard against double-submission
    if (_isSavingQuotation) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in user found.')),
      );
      return;
    }

    setState(() => _isSavingQuotation = true);

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
      'customer_name': _safeTextOrNull(draft.customerName),
      'company_name': _safeTextOrNull(draft.companyName),
      'customer_trn': _safeTextOrNull(draft.customerTrn),
      'customer_phone': _safeTextOrNull(draft.customerPhone),
      'salesperson_name': _safeTextOrNull(draft.salespersonName),
      'salesperson_contact': _safeTextOrNull(draft.salespersonContact),
      'salesperson_phone': _safeTextOrNull(draft.salespersonPhone),
      'notes': _safeTextOrNull(draft.notes),
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
      'is_hamasat': isHamasat,
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
          'length':
          (rawLength == null || rawLength.isEmpty) ? null : rawLength,
          'width': (rawWidth == null || rawWidth.isEmpty) ? null : rawWidth,
          'production_time': (rawProductionTime == null ||
              rawProductionTime.isEmpty)
              ? null
              : rawProductionTime,
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

      // Insert items — if this fails, clean up the orphan header
      try {
        await _supabase.from('quotation_items').insert(itemRows);
      } catch (itemsError) {
        // Roll back the header so we don't leave a quotation with no items
        try {
          await _supabase
              .from('quotations')
              .delete()
              .eq('id', quotationId);
        } catch (_) {}
        throw Exception('Failed to save items: $itemsError');
      }

      if (!mounted) return;

      setState(() {
        _selectedQuoteItems.clear();
        _isSavingQuotation = false;
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
            isHamasat: isHamasat,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingQuotation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create quotation: $e')),
      );
    }
  }

  void _openSelectedItemsSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedItems = _selectedQuoteItems.values.toList();

          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, (MediaQuery.paddingOf(context).bottom + 16).clamp(24.0, double.infinity)),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Items',
                            style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${selectedItems.length}',
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final selected = selectedItems[index];
                          final liveSelected =
                          _selectedQuoteItems[selected.itemId];
                          final sc = (selected.item['supplier_code'] ?? '')
                              .toString().trim().toUpperCase();
                          final stockTotal =
                              sc.isNotEmpty ? _stockTotals[sc] : null;
                          final isOutOfStock =
                              stockTotal != null && stockTotal <= 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171717),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isOutOfStock
                                    ? const Color(0xFF7F1D1D)
                                    : const Color(0xFF2E2E2E),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${selected.priceLabel} • ${_formatPrice(selected.unitPrice)}',
                                        style: const TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Line total: ${_formatPrice(selected.lineTotal)}',
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: stockTotal == null
                                                  ? Colors.white24
                                                  : isOutOfStock
                                                      ? const Color(0xFFF87171)
                                                      : const Color(0xFF22c55e),
                                            ),
                                          ),
                                          Text(
                                            stockTotal == null
                                                ? 'Stock: —'
                                                : isOutOfStock
                                                    ? 'Out of Stock'
                                                    : 'Stock: ${stockTotal % 1 == 0 ? stockTotal.toInt() : stockTotal.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: stockTotal == null
                                                  ? Colors.white38
                                                  : isOutOfStock
                                                      ? const Color(0xFFF87171)
                                                      : Colors.white54,
                                              fontWeight: isOutOfStock
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF101010),
                                    borderRadius:
                                    BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF3A3A3A),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _changeSelectedItemQuantity(selected.itemId, -1);
                                          setModalState(() {});
                                        },
                                        icon: const Icon(Icons.remove_circle_outline),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final qty = liveSelected?.quantity ?? selected.quantity;
                                          final ctrl = TextEditingController(text: '$qty');
                                          final result = await showDialog<int>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Enter Quantity'),
                                              content: TextField(
                                                controller: ctrl,
                                                autofocus: true,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: const InputDecoration(labelText: 'Quantity'),
                                                onSubmitted: (v) => Navigator.pop(context, int.tryParse(v.trim())),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text.trim())),
                                                  child: const Text('Set'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (result != null) {
                                            _setSelectedItemQuantity(selected.itemId, result);
                                            setModalState(() {});
                                          }
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(minWidth: 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            '${liveSelected?.quantity ?? selected.quantity}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              decoration: TextDecoration.underline,
                                              decorationStyle: TextDecorationStyle.dotted,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _changeSelectedItemQuantity(selected.itemId, 1);
                                          setModalState(() {});
                                        },
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedQuoteItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // ── Out-of-stock warning ───────────────────────────────
                      Builder(builder: (_) {
                        final outOfStockNames = selectedItems.where((s) {
                          final sc = (s.item['supplier_code'] ?? '')
                              .toString().trim().toUpperCase();
                          final t = sc.isNotEmpty ? _stockTotals[sc] : null;
                          return t != null && t <= 0;
                        }).map((s) => s.productName.isEmpty
                            ? 'Unnamed Product'
                            : s.productName).toList();
                        if (outOfStockNames.isEmpty) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F1D1D).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFB91C1C).withOpacity(0.5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFF87171), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${outOfStockNames.length} item${outOfStockNames.length > 1 ? 's are' : ' is'} out of stock: ${outOfStockNames.join(', ')}',
                                  style: const TextStyle(
                                    color: Color(0xFFF87171),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3A2F0B),
                          ),
                        ),
                        child: Row(
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
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openCreateQuotationSheet(isHamasat: false);
                              },
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Create FC Quotation'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openCreateQuotationSheet(isHamasat: true);
                              },
                              style: ButtonStyle(
                                backgroundColor: const WidgetStatePropertyAll(Color(0xFF9B77BA)),
                                foregroundColor: const WidgetStatePropertyAll(Color(0xFF1A0A2E)),
                              ),
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Create Hamasat Quotation'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // int _mobileCrossAxisCount(double width) {
  //   if (width >= 650) return 3;
  //   if (width >= 420) return 2;
  //   return 2;
  // }
  int _mobileCrossAxisCount(double width) {
    if (width >= 560) return 3;
    return 2;
  }
  int _desktopCrossAxisCount(double width) {
    if (width >= 1700) return 6;
    if (width >= 1450) return 5;
    if (width >= 1180) return 4;
    if (width >= 900) return 3;
    return 2;
  }
  //
  // double _gridAspectRatio(double width, int count) {
  //   if (width < 700) {
  //     if (count >= 3) return 0.88;
  //     return 0.80;
  //   }
  //   if (width < 1000) return 0.84;
  //   if (width < 1400) return 0.86;
  //   return 0.90;
  // }

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
        priceOptions: _visiblePriceOptions(_profile),
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, (MediaQuery.paddingOf(context).bottom + 16).clamp(24.0, double.infinity)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canUseContainerProcessor)
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
                    ),
                  if (_canAddItems) ...[
                    ListTile(
                      leading: const Icon(Icons.add_box_outlined),
                      title: const Text('Add Item'),
                      onTap: () {
                        Navigator.pop(context);
                        _openAddItemSheet();
                      },
                    ),
                    if (_canManageUsers)
                      ListTile(
                        leading: const Icon(Icons.manage_accounts_outlined),
                        title: const Text('Manage User Roles'),
                        subtitle: const Text('Change roles for other users'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserRoleManagementScreen(
                                // currentUserId:
                                // (widget.profile['id'] ?? '').toString(),
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
                  if (_canViewQuotations || _canCreateQuotation)
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        _isAdmin
                            ? 'View Quotations'
                            : _isSales
                            ? 'My Quotations'
                            : 'Quotations',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuotationListScreen(
                              role: _role,
                              currentUserId: _profile.id,
                            ),
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
          ),
        );
      },
    );
  }

  // Widget _buildCompactGrid(ThemeData theme, BoxConstraints constraints) {
  //   final width = constraints.maxWidth;
  //   final isMobile = width < 700;
  //   final count =
  //   isMobile ? _mobileCrossAxisCount(width) : _desktopCrossAxisCount(width);
  //
  //   return RefreshIndicator(
  //     onRefresh: _loadItems,
  //     child: GridView.builder(
  //       controller: _scrollController,
  //       physics: const AlwaysScrollableScrollPhysics(),
  //       padding: EdgeInsets.fromLTRB(
  //         isMobile ? 12 : 16,
  //         8,
  //         isMobile ? 12 : 16,
  //         _selectedQuoteItems.isEmpty ? 24 : 100,
  //       ),
  //       itemCount: _filteredItems.length,
  //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: count,
  //         mainAxisSpacing: isMobile ? 10 : 14,
  //         crossAxisSpacing: isMobile ? 10 : 14,
  //         childAspectRatio: _gridAspectRatio(width, count),
  //       ),
  //       itemBuilder: (context, index) {
  //         final item = _filteredItems[index];
  //
  //         return _ResponsiveProductCard(
  //           item: item,
  //           formatPrice: _formatPrice,
  //           onTap: () => _openDetails(item),
  //           pricePermissions: _pricePermissions,
  //           selectedPriceKey: _selectedPriceKeyForItem(item),
  //           onSelectPrice: (priceKey, priceLabel) {
  //             _toggleItemPriceSelection(item, priceKey, priceLabel);
  //           },
  //           isLoadingPermissions: _isLoadingPermissions,
  //           canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
  //           isDense: isMobile,
  //         );
  //       },
  //     ),
  //   );
  // }
  Widget _buildCompactList() {
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 90),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _CompactListTile(
            item: item,
            formatPrice: _formatPrice,
            onTap: () => _openDetails(item),
            pricePermissions: _pricePermissions,
            selectedPriceKey: _selectedPriceKeyForItem(item),
            onSelectPrice: (priceKey, priceLabel) {
              _toggleItemPriceSelection(item, priceKey, priceLabel);
            },
            isLoadingPermissions: _isLoadingPermissions,
            canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
            priceOptions: _visiblePriceOptions(_profile),
          );
        },
      ),
    );
  }
  Widget _buildCompactGrid(ThemeData theme, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final isMobile = width < 700;
    final count =
    isMobile ? _mobileCrossAxisCount(width) : _desktopCrossAxisCount(width);

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 16,
          8,
          isMobile ? 12 : 16,
          _selectedQuoteItems.isEmpty ? 24 : 100,
        ),
        itemCount: _filteredItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: isMobile ? 10 : 14,
          crossAxisSpacing: isMobile ? 10 : 14,
          // mainAxisExtent: isMobile ? 250 : 320,
          mainAxisExtent: isMobile ? 330 : 340,
        ),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];

          final sc = (item['supplier_code'] ?? '').toString().trim();
          final stockTotal = sc.isNotEmpty ? _stockTotals[sc] : null;

          return _ResponsiveProductCard(
            item: item,
            formatPrice: _formatPrice,
            onTap: () => _openDetails(item),
            pricePermissions: _pricePermissions,
            selectedPriceKey: _selectedPriceKeyForItem(item),
            onSelectPrice: (priceKey, priceLabel) {
              _toggleItemPriceSelection(item, priceKey, priceLabel);
            },
            isLoadingPermissions: _isLoadingPermissions,
            canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
            isDense: isMobile,
            priceOptions: _visiblePriceOptions(_profile),
            stockTotal: stockTotal,
          );
        },
      ),
    );
  }
  // Widget _buildBody(ThemeData theme) {
  //   if (_isLoading) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //
  //   if (_errorMessage != null) {
  //     return Center(
  //       child: Padding(
  //         padding: const EdgeInsets.all(24),
  //         child: Container(
  //           constraints: const BoxConstraints(maxWidth: 520),
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF141414),
  //             borderRadius: BorderRadius.circular(24),
  //             border: Border.all(color: const Color(0xFF4A3B12)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: AppConstants.primaryColor.withOpacity(0.06),
  //                 blurRadius: 18,
  //                 offset: const Offset(0, 8),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Icon(
  //                 Icons.error_outline_rounded,
  //                 size: 48,
  //                 color: AppConstants.primaryColor,
  //               ),
  //               const SizedBox(height: 12),
  //               Text(
  //                 'Failed to load data',
  //                 style: theme.textTheme.titleLarge?.copyWith(
  //                   fontWeight: FontWeight.w800,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               Text(
  //                 _errorMessage!,
  //                 textAlign: TextAlign.center,
  //                 style: theme.textTheme.bodyMedium,
  //               ),
  //               const SizedBox(height: 18),
  //               FilledButton.icon(
  //                 onPressed: _loadItems,
  //                 icon: const Icon(Icons.refresh_rounded),
  //                 label: const Text('Retry'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   if (_filteredItems.isEmpty) {
  //     return RefreshIndicator(
  //       onRefresh: _loadItems,
  //       child: ListView(
  //         physics: const AlwaysScrollableScrollPhysics(),
  //         padding: const EdgeInsets.all(16),
  //         children: [
  //           const SizedBox(height: 120),
  //           Center(
  //             child: Container(
  //               width: 340,
  //               padding: const EdgeInsets.all(22),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF141414),
  //                 borderRadius: BorderRadius.circular(24),
  //                 border: Border.all(color: const Color(0xFF4A3B12)),
  //               ),
  //               child: Column(
  //                 children: [
  //                   const Icon(
  //                     Icons.search_off_rounded,
  //                     size: 52,
  //                     color: AppConstants.primaryColor,
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Text(
  //                     'No items found',
  //                     style: theme.textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.w800,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text(
  //                     'Try changing the search text or category filter.',
  //                     textAlign: TextAlign.center,
  //                     style: theme.textTheme.bodyMedium,
  //                   ),
  //                   const SizedBox(height: 16),
  //                   OutlinedButton(
  //                     onPressed: _clearFilters,
  //                     child: const Text('Clear Filters'),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       return _buildCompactGrid(theme, constraints);
  //     },
  //   );
  // }
  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 120),
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
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters'),
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
        if (_viewMode == _ViewMode.list) {
          return _buildCompactList();
        }
        return _buildCompactGrid(theme, constraints);
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    // Widget _buildViewSwitcher(BuildContext context) {
    //   return SegmentedButton<_ViewMode>(
    //     showSelectedIcon: false,
    //     segments: const [
    //       ButtonSegment<_ViewMode>(
    //         value: _ViewMode.list,
    //         icon: Icon(Icons.view_agenda_outlined, size: 18),
    //         label: Text('List'),
    //       ),
    //       ButtonSegment<_ViewMode>(
    //         value: _ViewMode.grid,
    //         icon: Icon(Icons.grid_view_rounded, size: 18),
    //         label: Text('Grid'),
    //       ),
    //     ],
    //     selected: <_ViewMode>{_viewMode},
    //     onSelectionChanged: (selection) {
    //       if (selection.isEmpty) return;
    //       onViewModeChanged(selection.first);
    //     },
    //   );
    // }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFabActions,
        icon: Icon(
          _isAdmin ? Icons.admin_panel_settings_rounded : Icons.apps,
        ),
        label: const Text('Actions'),
      ),
      body: SafeArea(
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ResponsiveHeaderSection(
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
                    showOutOfStockOnly: _showOutOfStockOnly,
                    onToggleOutOfStock: () {
                      setState(() {
                        _showOutOfStockOnly = !_showOutOfStockOnly;
                        _applyFilters();
                      });
                    },
                    profile: _profile,
                    onLogout: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    onScanBarcode: _startBarcodeScan,
                    showFiltersOnMobile: _showFiltersOnMobile,
                    onToggleMobileFilters: () {
                      setState(() {
                        _showFiltersOnMobile = !_showFiltersOnMobile;
                      });
                    },
                    viewMode: _viewMode,
                    onViewModeChanged: _setViewMode,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'tree',
                          label: Text('Trees'),
                          icon: Icon(Icons.park_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: 'flower',
                          label: Text('Flowers'),
                          icon: Icon(Icons.local_florist_outlined, size: 16),
                        ),
                      ],
                      selected: {_productType},
                      onSelectionChanged: (sel) {
                        if (sel.isEmpty) return;
                        setState(() {
                          _productType = sel.first;
                          _selectedCategory = null;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildBody(theme),
          ),
        ),
      ),
      bottomNavigationBar: _selectedQuoteItems.isEmpty
          ? null
          : SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16,
            10,
            isMobile ? 12 : 16,
            isMobile ? 12 : 14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(
              top: BorderSide(color: Color(0xFF3A2F0B)),
            ),
          ),
          child: isMobile
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedQuoteItems.length} item(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatPrice(_selectedGrandTotal),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openSelectedItemsSheet,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Review Selection'),
                ),
              ),
            ],
          )
              : Row(
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
    );
  }
}

class _ResponsiveHeaderSection extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedCategory;
  final List<String> categories;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onClearFilters;
  final ValueChanged<String?> onCategorySelected;
  final bool showOutOfStockOnly;
  final VoidCallback onToggleOutOfStock;
  final UserProfile profile;
  final Future<void> Function() onLogout;
  final VoidCallback onScanBarcode;
  final bool showFiltersOnMobile;
  final VoidCallback onToggleMobileFilters;
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewModeChanged;
  const _ResponsiveHeaderSection({
    required this.searchController,
    required this.selectedCategory,
    required this.categories,
    required this.visibleCount,
    required this.totalCount,
    required this.onClearFilters,
    required this.onCategorySelected,
    required this.showOutOfStockOnly,
    required this.onToggleOutOfStock,
    required this.profile,
    required this.onLogout,
    required this.onScanBarcode,
    required this.showFiltersOnMobile,
    required this.onToggleMobileFilters,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    final name = profile.name.isNotEmpty ? profile.name : 'User';
    final role = profile.role;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF111111),
            const Color(0xFF0B0B0B),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        12,
        isMobile ? 12 : 16,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HeaderIdentityCard(
                  name: name,
                  role: role,
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Scan Barcode',
                onPressed: onScanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: () => onLogout(),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, code, category, barcode...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleMobileFilters,
                  icon: Icon(
                    showFiltersOnMobile
                        ? Icons.filter_alt_off_rounded
                        : Icons.tune_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildViewSwitcher(context),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _HeaderFilters(
                  isMobile: true,
                  selectedCategory: selectedCategory,
                  categories: categories,
                  visibleCount: visibleCount,
                  totalCount: totalCount,
                  onClearFilters: onClearFilters,
                  onCategorySelected: onCategorySelected,
                  showOutOfStockOnly: showOutOfStockOnly,
                  onToggleOutOfStock: onToggleOutOfStock,
                ),
              ),
              crossFadeState: showFiltersOnMobile
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, code, category, barcode...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _HeaderFilters(
                    isMobile: false,
                    selectedCategory: selectedCategory,
                    categories: categories,
                    visibleCount: visibleCount,
                    totalCount: totalCount,
                    onClearFilters: onClearFilters,
                    onCategorySelected: onCategorySelected,
                    showOutOfStockOnly: showOutOfStockOnly,
                    onToggleOutOfStock: onToggleOutOfStock,
                  ),
                ),
                const SizedBox(width: 12),
                _buildViewSwitcher(context),
              ],
            ),
        ],
      ),
    );
  }

// Add this inside _ResponsiveHeaderSection (as a regular method, not inside build)
  Widget _buildViewSwitcher(BuildContext context) {
    return SegmentedButton<_ViewMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<_ViewMode>(
          value: _ViewMode.list,
          icon: Icon(Icons.view_agenda_outlined, size: 18),
          label: Text('List'),
        ),
        ButtonSegment<_ViewMode>(
          value: _ViewMode.grid,
          icon: Icon(Icons.grid_view_rounded, size: 18),
          label: Text('Grid'),
        ),
      ],
      selected: <_ViewMode>{viewMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onViewModeChanged(selection.first);
      },
    );
  }}

class _HeaderIdentityCard extends StatelessWidget {
  final String name;
  final String role;
  final bool isMobile;

  const _HeaderIdentityCard({
    required this.name,
    required this.role,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 20,
            backgroundColor: AppConstants.primaryColor.withOpacity(0.18),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price List',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 15 : 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$name • ${role.isEmpty ? 'user' : role}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 11.5 : 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderFilters extends StatelessWidget {
  final bool isMobile;
  final String? selectedCategory;
  final List<String> categories;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onClearFilters;
  final ValueChanged<String?> onCategorySelected;
  final bool showOutOfStockOnly;
  final VoidCallback onToggleOutOfStock;

  const _HeaderFilters({
    required this.isMobile,
    required this.selectedCategory,
    required this.categories,
    required this.visibleCount,
    required this.totalCount,
    required this.onClearFilters,
    required this.onCategorySelected,
    required this.showOutOfStockOnly,
    required this.onToggleOutOfStock,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          DropdownButtonFormField<String?>(
            value: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...categories.map(
                    (category) => DropdownMenuItem<String?>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onCategorySelected,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                label: const Text('Out of Stock'),
                avatar: const Icon(Icons.remove_shopping_cart_outlined, size: 15),
                selected: showOutOfStockOnly,
                onSelected: (_) => onToggleOutOfStock(),
                selectedColor: const Color(0xFF7F1D1D),
                checkmarkColor: const Color(0xFFF87171),
                labelStyle: TextStyle(
                  color: showOutOfStockOnly
                      ? const Color(0xFFF87171)
                      : Colors.white70,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: showOutOfStockOnly
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF3A3A3A),
                ),
                backgroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              const Spacer(),
              Text(
                '$visibleCount / $totalCount',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Clear filters',
                onPressed: onClearFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...categories.map(
                    (category) => DropdownMenuItem<String?>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onCategorySelected,
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Out of Stock'),
          avatar: const Icon(Icons.remove_shopping_cart_outlined, size: 15),
          selected: showOutOfStockOnly,
          onSelected: (_) => onToggleOutOfStock(),
          selectedColor: const Color(0xFF7F1D1D),
          checkmarkColor: const Color(0xFFF87171),
          labelStyle: TextStyle(
            color: showOutOfStockOnly
                ? const Color(0xFFF87171)
                : Colors.white70,
            fontSize: 12,
          ),
          side: BorderSide(
            color: showOutOfStockOnly
                ? const Color(0xFFB91C1C)
                : const Color(0xFF3A3A3A),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        const SizedBox(width: 8),
        Text(
          '$visibleCount / $totalCount',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Clear filters',
          onPressed: onClearFilters,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    );
  }
}
class _CompactListTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;
  final VoidCallback onTap;
  final Map<String, bool> pricePermissions;
  final String? selectedPriceKey;
  final void Function(String priceKey, String priceLabel) onSelectPrice;
  final bool isLoadingPermissions;
  final bool canSelectPricesForQuotation;
  final List<_PriceOptionMeta> priceOptions;

  const _CompactListTile({
    required this.item,
    required this.formatPrice,
    required this.onTap,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
    required this.priceOptions,
  });

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final productName =
    (item['product_name'] ?? 'Unnamed Product').toString().trim();
    final category = (item['category_ar'] ?? '').toString().trim();
    final itemCode = (item['item_code'] ?? '').toString().trim();
    final barcode = (item['barcode'] ?? '').toString().trim();
    final supplierCode = (item['supplier_code'] ?? '').toString().trim();
    // For flowers show barcode + supplier_code; for trees show item_code
    final displayCode = itemCode.isNotEmpty
        ? itemCode
        : supplierCode.isNotEmpty
            ? supplierCode
            : barcode;
    final totalPrice = _toDouble(item['total_price']) ??
        _toDouble(item['price_a']) ??
        _toDouble(item['price_aa']) ??
        _toDouble(item['price_ee']) ??
        0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: _ProductImage(
                      imagePath: (item['image_path'] ?? '').toString().trim(),
                      height: 68,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (category.isNotEmpty)
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          if (category.isNotEmpty && displayCode.isNotEmpty)
                            const Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 10.5,
                              ),
                            ),
                          if (displayCode.isNotEmpty)
                            Text(
                              displayCode,
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatPrice(totalPrice),
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isLoadingPermissions)
                      const SizedBox(
                        width: 40,
                        height: 3,
                        child: LinearProgressIndicator(),
                      )
                    else
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        alignment: WrapAlignment.end,
                        children: priceOptions.map((option) {
                          final rawValue = item[option.key];
                          final numericValue = _toDouble(rawValue);
                          final exists = numericValue != null;
                          final allowed = canSelectPricesForQuotation &&
                              (pricePermissions[option.key] ?? true) &&
                              exists;
                          final selected = selectedPriceKey == option.key;

                          if (!exists) return const SizedBox.shrink();

                          final effectiveLabel = option.key == 'price_art' &&
                                  item['product_type'] == 'flower'
                              ? 'Special'
                              : option.label;
                          return GestureDetector(
                            onTap: allowed
                                ? () => onSelectPrice(option.key, effectiveLabel)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppConstants.primaryColor
                                    : (allowed
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFF161616)),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: selected
                                      ? AppConstants.primaryColor
                                      : const Color(0xFF333333),
                                ),
                              ),
                              child: Text(
                                effectiveLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? const Color(0xFF0A0A0A)
                                      : (allowed
                                      ? const Color(0xFFCCAA44)
                                      : const Color(0xFF555555)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _CountBadge extends StatelessWidget {
  final String label;
  final String value;

  const _CountBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// class _ResponsiveProductCard extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final String Function(dynamic value) formatPrice;
//   final VoidCallback onTap;
//   final Map<String, bool> pricePermissions;
//   final String? selectedPriceKey;
//   final void Function(String priceKey, String priceLabel) onSelectPrice;
//   final bool isLoadingPermissions;
//   final bool canSelectPricesForQuotation;
//   final bool isDense;
//
//   const _ResponsiveProductCard({
//     required this.item,
//     required this.formatPrice,
//     required this.onTap,
//     required this.pricePermissions,
//     required this.selectedPriceKey,
//     required this.onSelectPrice,
//     required this.isLoadingPermissions,
//     required this.canSelectPricesForQuotation,
//     required this.isDense,
//   });
//
//   double? _toDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString().trim());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final productName =
//     (item['product_name'] ?? 'Unnamed Product').toString().trim();
//     final itemCode = (item['item_code'] ?? '').toString().trim();
//     final category = (item['category_ar'] ?? '').toString().trim();
//     final imagePath = (item['image_path'] ?? '').toString().trim();
//     final description = (item['description'] ?? '').toString().trim();
//     final totalPrice = _toDouble(item['total_price']);
//
//     final imageHeight = isDense ? 96.0 : 128.0;
//     final padding = isDense ? 10.0 : 14.0;
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(20),
//         child: Ink(
//           decoration: BoxDecoration(
//             color: const Color(0xFF151515),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: selectedPriceKey != null
//                   ? const Color(0xFF6C5622)
//                   : const Color(0xFF262626),
//               width: selectedPriceKey != null ? 1.4 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.22),
//                 blurRadius: 12,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _ProductImage(
//                 imagePath: imagePath,
//                 height: imageHeight,
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.all(padding),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (category.isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: AppConstants.primaryColor.withOpacity(0.10),
//                             borderRadius: BorderRadius.circular(999),
//                             border: Border.all(
//                               color:
//                               AppConstants.primaryColor.withOpacity(0.18),
//                             ),
//                           ),
//                           child: Text(
//                             category,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               color: AppConstants.primaryColor,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ),
//                       if (category.isNotEmpty) const SizedBox(height: 8),
//                       Text(
//                         productName.isEmpty ? 'Unnamed Product' : productName,
//                         maxLines: isDense ? 2 : 3,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: isDense ? 13.2 : 15,
//                           height: 1.15,
//                         ),
//                       ),
//                       if (itemCode.isNotEmpty) ...[
//                         const SizedBox(height: 6),
//                         Text(
//                           itemCode,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 11.5,
//                           ),
//                         ),
//                       ],
//                       if (!isDense && description.isNotEmpty) ...[
//                         const SizedBox(height: 6),
//                         Text(
//                           description,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                             height: 1.25,
//                           ),
//                         ),
//                       ],
//                       const Spacer(),
//                       if (totalPrice != null)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 8),
//                           child: Text(
//                             'Total: ${formatPrice(totalPrice)}',
//                             style: const TextStyle(
//                               color: AppConstants.primaryColor,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 12.5,
//                             ),
//                           ),
//                         ),
//                       _PriceChipWrap(
//                         item: item,
//                         formatPrice: formatPrice,
//                         pricePermissions: pricePermissions,
//                         selectedPriceKey: selectedPriceKey,
//                         onSelectPrice: onSelectPrice,
//                         isLoadingPermissions: isLoadingPermissions,
//                         canSelectPricesForQuotation: canSelectPricesForQuotation,
//                         compact: true,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
class _ResponsiveProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;
  final VoidCallback onTap;
  final Map<String, bool> pricePermissions;
  final String? selectedPriceKey;
  final void Function(String priceKey, String priceLabel) onSelectPrice;
  final bool isLoadingPermissions;
  final bool canSelectPricesForQuotation;
  final bool isDense;
  final List<_PriceOptionMeta> priceOptions;
  /// null = not yet synced / unknown; 0 or less = out of stock; > 0 = in stock
  final double? stockTotal;

  const _ResponsiveProductCard({
    required this.item,
    required this.formatPrice,
    required this.onTap,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
    required this.isDense,
    required this.priceOptions,
    this.stockTotal,
  });

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final productName =
    (item['product_name'] ?? 'Unnamed Product').toString().trim();
    final itemCode = (item['item_code'] ?? '').toString().trim();
    final barcode = (item['barcode'] ?? '').toString().trim();
    final supplierCode = (item['supplier_code'] ?? '').toString().trim();
    final displayCode = itemCode.isNotEmpty
        ? itemCode
        : supplierCode.isNotEmpty
            ? supplierCode
            : barcode;
    final category = (item['category_ar'] ?? '').toString().trim();
    final imagePath = (item['image_path'] ?? '').toString().trim();
    final sizeText = [
      (item['length'] ?? '').toString().trim(),
      (item['width'] ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty).join('*');

    final totalPrice = _toDouble(item['total_price']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selectedPriceKey != null
                  ? const Color(0xFF6C5622)
                  : const Color(0xFF262626),
              width: selectedPriceKey != null ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _ProductImage(
                    imagePath: imagePath,
                    height: isDense ? 110 : 145,
                  ),
                  if (stockTotal != null && stockTotal! <= 0)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB91C1C).withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Expanded(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         if (category.isNotEmpty)
              //           Container(
              //             padding: const EdgeInsets.symmetric(
              //               horizontal: 8,
              //               vertical: 4,
              //             ),
              //             decoration: BoxDecoration(
              //               color: AppConstants.primaryColor.withOpacity(0.10),
              //               borderRadius: BorderRadius.circular(999),
              //               border: Border.all(
              //                 color:
              //                 AppConstants.primaryColor.withOpacity(0.18),
              //               ),
              //             ),
              //             child: Text(
              //               category,
              //               maxLines: 1,
              //               overflow: TextOverflow.ellipsis,
              //               style: const TextStyle(
              //                 color: AppConstants.primaryColor,
              //                 fontWeight: FontWeight.w700,
              //                 fontSize: 10.5,
              //               ),
              //             ),
              //           ),
              //         if (category.isNotEmpty) const SizedBox(height: 8),
              //         Text(
              //           productName,
              //           maxLines: 2,
              //           overflow: TextOverflow.ellipsis,
              //           style: TextStyle(
              //             fontWeight: FontWeight.w800,
              //             fontSize: isDense ? 13.5 : 15,
              //             height: 1.15,
              //           ),
              //         ),
              //         if (itemCode.isNotEmpty) ...[
              //           const SizedBox(height: 4),
              //           Text(
              //             itemCode,
              //             maxLines: 1,
              //             overflow: TextOverflow.ellipsis,
              //             style: const TextStyle(
              //               color: Colors.white70,
              //               fontWeight: FontWeight.w600,
              //               fontSize: 11.5,
              //             ),
              //           ),
              //         ],
              //         if (sizeText.isNotEmpty) ...[
              //           const SizedBox(height: 4),
              //           Text(
              //             sizeText,
              //             maxLines: 1,
              //             overflow: TextOverflow.ellipsis,
              //             style: const TextStyle(
              //               color: Colors.white70,
              //               fontSize: 11.5,
              //             ),
              //           ),
              //         ],
              //         if (totalPrice != null) ...[
              //           const SizedBox(height: 8),
              //           Text(
              //             'Total: ${formatPrice(totalPrice)}',
              //             style: const TextStyle(
              //               color: AppConstants.primaryColor,
              //               fontWeight: FontWeight.w800,
              //               fontSize: 12,
              //             ),
              //           ),
              //         ],
              //         const SizedBox(height: 8),
              //         _PriceChipWrap(
              //           item: item,
              //           formatPrice: formatPrice,
              //           pricePermissions: pricePermissions,
              //           selectedPriceKey: selectedPriceKey,
              //           onSelectPrice: onSelectPrice,
              //           isLoadingPermissions: isLoadingPermissions,
              //           canSelectPricesForQuotation: canSelectPricesForQuotation,
              //           compact: true,
              //         ),
              //         // Expanded(
              //         //   child: SingleChildScrollView(
              //         //     scrollDirection: Axis.horizontal,
              //         //     child: _PriceChipWrap(
              //         //       item: item,
              //         //       formatPrice: formatPrice,
              //         //       pricePermissions: pricePermissions,
              //         //       selectedPriceKey: selectedPriceKey,
              //         //       onSelectPrice: onSelectPrice,
              //         //       isLoadingPermissions: isLoadingPermissions,
              //         //       canSelectPricesForQuotation:
              //         //       canSelectPricesForQuotation,
              //         //       compact: true,
              //         //     ),
              //         //   ),
              //         // ),
              //       ],
              //     ),
              //   ),
              // ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppConstants.primaryColor.withOpacity(0.18),
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              if (category.isNotEmpty) const SizedBox(height: 8),
                              Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: isDense ? 13.5 : 15,
                                  height: 1.15,
                                ),
                              ),
                              if (displayCode.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  displayCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                              if (sizeText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sizeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                              if (totalPrice != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Total: ${formatPrice(totalPrice)}',
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              _PriceChipWrap(
                                item: item,
                                formatPrice: formatPrice,
                                pricePermissions: pricePermissions,
                                selectedPriceKey: selectedPriceKey,
                                onSelectPrice: onSelectPrice,
                                isLoadingPermissions: isLoadingPermissions,
                                canSelectPricesForQuotation: canSelectPricesForQuotation,
                                compact: true,
                                priceOptions: priceOptions,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// class _ProductImage extends StatelessWidget {
//   final String imagePath;
//   final double height;
//
//   const _ProductImage({
//     required this.imagePath,
//     required this.height,
//   });
//
//   String? _resolveImageUrl(String imagePath) {
//     if (imagePath.isEmpty) return null;
//
//     if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
//       return imagePath;
//     }
//
//     try {
//       return Supabase.instance.client.storage
//           .from('price-list-images')
//           .getPublicUrl(imagePath);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final imageUrl = _resolveImageUrl(imagePath);
//
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       child: Container(
//         height: height,
//         width: double.infinity,
//         color: const Color(0xFF101010),
//         child: imageUrl == null
//             ? const Center(
//           child: Icon(
//             Icons.image_not_supported_outlined,
//             color: Colors.white24,
//             size: 32,
//           ),
//         )
//             : CachedNetworkImage(
//           imageUrl: imageUrl,
//           fit: BoxFit.cover,
//           fadeInDuration: const Duration(milliseconds: 150),
//           placeholder: (context, _) => const Center(
//             child: SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ),
//           errorWidget: (context, _, __) => const Center(
//             child: Icon(
//               Icons.broken_image_outlined,
//               color: Colors.white24,
//               size: 30,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _ProductImage extends StatelessWidget {
  final String imagePath;
  final double height;

  const _ProductImage({
    required this.imagePath,
    required this.height,
  });

  String? _resolveImageUrl(String imagePath) {
    final path = imagePath.trim();
    if (path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    try {
      final client = Supabase.instance.client;

      // CHANGE THIS BUCKET NAME IF YOUR REAL BUCKET IS DIFFERENT
      // return client.storage.from('price-list-images').getPublicUrl(path);
      return client.storage.from('product-images').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(imagePath);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF101010),
        child: imageUrl == null
            ? const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white24,
            size: 32,
          ),
        )
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  imagePath,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
class _PriceChipWrap extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;
  final Map<String, bool> pricePermissions;
  final String? selectedPriceKey;
  final void Function(String priceKey, String priceLabel) onSelectPrice;
  final bool isLoadingPermissions;
  final bool canSelectPricesForQuotation;
  final bool compact;
  final List<_PriceOptionMeta> priceOptions;

  const _PriceChipWrap({
    required this.item,
    required this.formatPrice,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
    required this.compact,
    required this.priceOptions,
  });

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingPermissions) {
      return const SizedBox(
        height: 30,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final chips = priceOptions.map((option) {
      final priceValue = _toDouble(item[option.key]);
      final hasValue = priceValue != null;
      final isAllowed = (pricePermissions[option.key] ?? true) && hasValue;
      final isSelected = selectedPriceKey == option.key;
      final effectiveLabel = option.key == 'price_art' &&
              item['product_type'] == 'flower'
          ? 'Special'
          : option.label;

      return FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        labelPadding:
        EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: 0),
        padding:
        EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: 0),
        selectedColor: AppConstants.primaryColor.withOpacity(0.18),
        backgroundColor: const Color(0xFF0F0F0F),
        side: BorderSide(
          color: isSelected
              ? AppConstants.primaryColor
              : isAllowed
              ? const Color(0xFF343434)
              : const Color(0xFF262626),
        ),
        label: Text(
          hasValue
              ? '$effectiveLabel ${formatPrice(priceValue)}'
              : '$effectiveLabel -',
          style: TextStyle(
            fontSize: compact ? 10.3 : 11.2,
            fontWeight: FontWeight.w700,
            color: !canSelectPricesForQuotation
                ? Colors.white54
                : isAllowed
                ? (isSelected
                ? AppConstants.primaryColor
                : Colors.white)
                : Colors.white38,
          ),
        ),
        selected: isSelected,
        onSelected: (!canSelectPricesForQuotation || !isAllowed)
            ? null
            : (_) => onSelectPrice(option.key, effectiveLabel),
      );
    }).toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }
}

class _ProductDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;
  final List<_PriceOptionMeta> priceOptions;

  const _ProductDetailsSheet({
    required this.item,
    required this.formatPrice,
    required this.priceOptions,
  });

  @override
  State<_ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<_ProductDetailsSheet> {
  List<Map<String, dynamic>> _stockRows = [];
  bool _stockLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    final supplierCode =
        (widget.item['supplier_code'] ?? '').toString().trim();
    if (supplierCode.isEmpty) {
      setState(() => _stockLoading = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('stock_quantities')
          .select('branch_name, store_name, quantity, branch_id, store_id')
          .eq('supplier_code', supplierCode)
          .order('branch_id')
          .order('store_id');
      if (mounted) {
        setState(() {
          _stockRows = List<Map<String, dynamic>>.from(res);
          _stockLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _stockLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName =
        (widget.item['product_name'] ?? 'Unnamed Product').toString().trim();
    final description = (widget.item['description'] ?? '').toString().trim();
    final itemCode = (widget.item['item_code'] ?? '').toString().trim();
    final category = (widget.item['category_ar'] ?? '').toString().trim();
    final width = (widget.item['width'] ?? '').toString().trim();
    final length = (widget.item['length'] ?? '').toString().trim();
    final productionTime =
        (widget.item['production_time'] ?? '').toString().trim();

    // Group stock rows by branch
    final Map<String, List<Map<String, dynamic>>> byBranch = {};
    for (final row in _stockRows) {
      final branch =
          (row['branch_name'] ?? row['branch_id'] ?? 'Unknown').toString().trim();
      byBranch.putIfAbsent(branch, () => []).add(row);
    }
    final totalQty = _stockRows.fold<double>(
        0, (sum, r) => sum + ((r['quantity'] as num?)?.toDouble() ?? 0));

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              (MediaQuery.paddingOf(context).bottom + 16)
                  .clamp(24.0, double.infinity)),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _ProductImage(
                      imagePath:
                          (widget.item['image_path'] ?? '').toString().trim(),
                      height: 240,
                    ),
                    const SizedBox(height: 16),
                    // ── Out of Stock banner ─────────────────────────────────
                    if (!_stockLoading && _stockRows.isNotEmpty && totalQty <= 0)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFB91C1C).withOpacity(0.50)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.remove_shopping_cart_outlined,
                                color: Color(0xFFF87171), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Color(0xFFF87171),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      productName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 8),
                    if (category.isNotEmpty)
                      _DetailRow(label: 'Category', value: category),
                    if (itemCode.isNotEmpty)
                      _DetailRow(label: 'Item Code', value: itemCode),
                    if (description.isNotEmpty)
                      _DetailRow(label: 'Description', value: description),
                    if (width.isNotEmpty)
                      _DetailRow(label: 'Width', value: width),
                    if (length.isNotEmpty)
                      _DetailRow(label: 'Length', value: length),
                    if (productionTime.isNotEmpty)
                      _DetailRow(
                        label: 'Production Time',
                        value: productionTime,
                      ),
                    const SizedBox(height: 14),

                    // ── Prices ──────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2B2B2B)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.priceOptions.map((option) {
                          final effectiveLabel = option.key == 'price_art' &&
                                  widget.item['product_type'] == 'flower'
                              ? 'Special'
                              : option.label;
                          return Chip(
                            backgroundColor: const Color(0xFF101010),
                            side:
                                const BorderSide(color: Color(0xFF303030)),
                            label: Text(
                              '$effectiveLabel: ${widget.formatPrice(widget.item[option.key])}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Stock Quantities ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d1f17),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF1a3a28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  color: Color(0xFF22c55e), size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Stock Quantities',
                                style: TextStyle(
                                  color: Color(0xFF22c55e),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              if (!_stockLoading && _stockRows.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF22c55e).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Total: ${_fmtQty(totalQty)}',
                                    style: const TextStyle(
                                      color: Color(0xFF22c55e),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_stockLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF22c55e),
                                  ),
                                ),
                              ),
                            )
                          else if (_stockRows.isEmpty)
                            const Text(
                              'No stock data — run a sync first',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            )
                          else
                            ...byBranch.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Branch header
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6, top: 2),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  // Store rows
                                  ...entry.value.map((row) {
                                    final storeName = (row['store_name'] ??
                                            row['store_id'] ??
                                            'Unknown Store')
                                        .toString()
                                        .trim();
                                    final qty = (row['quantity'] as num?)
                                            ?.toDouble() ??
                                        0;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(
                                                right: 8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: qty > 0
                                                  ? const Color(0xFF22c55e)
                                                  : Colors.white24,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              storeName,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            _fmtQty(qty),
                                            style: TextStyle(
                                              color: qty > 0
                                                  ? Colors.white
                                                  : Colors.white38,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (entry.value.length > 1)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Branch total: ${_fmtQty(entry.value.fold<double>(0, (s, r) => s + ((r['quantity'] as num?)?.toDouble() ?? 0)))}',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtQty(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(1);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
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
  final UserProfile profile;
  final bool isHamasat;

  const _CreateQuotationSheet({
    required this.subtotal,
    required this.formatPrice,
    required this.profile,
    required this.isHamasat,
  });

  @override
  State<_CreateQuotationSheet> createState() => _CreateQuotationSheetState();
}

class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
  // Hamasat palette — two colours mirror the FC golden scheme:
  //   _hamPrimary   → replaces AppConstants.primaryColor (bright gold)
  //   _hamSecondary → replaces every lighter golden shade
  static const Color _hamPrimary   = Color(0xFF9B77BA);
  static const Color _hamSecondary = Color(0xFFDED2E8);
  // Derived dark tints for borders (analogous to FC's dark-gold borders)
  static const Color _hamBorderDark = Color(0xFF3D2E52);
  static const Color _hamBorderMid  = Color(0xFF5C4A78);
  static const Color _hamFg         = Color(0xFF1A0A2E); // text on filled button

  Color get _accentColor =>
      widget.isHamasat ? _hamPrimary : AppConstants.primaryColor;

  ThemeData _hamTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _hamPrimary,
        onPrimary: _hamFg,
        onSurface: _hamSecondary,
        primaryContainer: _hamBorderDark,
        onPrimaryContainer: _hamSecondary,
      ),
      iconTheme: const IconThemeData(color: _hamPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161616),
        hintStyle: const TextStyle(color: _hamSecondary),
        prefixIconColor: _hamPrimary,
        suffixIconColor: _hamPrimary,
        labelStyle: const TextStyle(color: _hamSecondary),
        floatingLabelStyle: const TextStyle(color: _hamPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _hamBorderMid),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _hamBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _hamPrimary, width: 1.4),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          color: _hamPrimary,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: const TextStyle(color: _hamSecondary),
        bodyMedium: const TextStyle(color: _hamSecondary),
        labelMedium: const TextStyle(color: _hamSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _hamPrimary,
          foregroundColor: _hamFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _hamPrimary,
          side: const BorderSide(color: _hamPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _hamPrimary),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: _hamPrimary),
      dividerTheme: const DividerThemeData(
        color: _hamBorderDark,
        thickness: 1,
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _customerTrnController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _salespersonNameController = TextEditingController();
  final _salespersonContactController = TextEditingController();
  final _salespersonPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '0');
  final _installationFeeController = TextEditingController(text: '0');
  final _additionalDetailsFeeController = TextEditingController(text: '0');
  final _vatPercentController = TextEditingController(text: '5');

  // Auto-fill suggestion
  Map<String, dynamic>? _suggestedLead;
  Timer? _autoFillDebounce;
  bool _applyingAutoFill = false; // prevent listener re-entrant loops

  @override
  void initState() {
    super.initState();
    _salespersonNameController.text = widget.profile.name;
    _salespersonContactController.text = widget.profile.email;
    _salespersonPhoneController.text = '';

    _deliveryFeeController.addListener(_rebuild);
    _installationFeeController.addListener(_rebuild);
    _additionalDetailsFeeController.addListener(_rebuild);
    _vatPercentController.addListener(_rebuild);

    _customerPhoneController.addListener(() => _scheduleAutoFill('phone'));
    _customerNameController.addListener(() => _scheduleAutoFill('name'));
    _companyNameController.addListener(() => _scheduleAutoFill('company'));
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _scheduleAutoFill(String field) {
    if (_applyingAutoFill) return;
    _autoFillDebounce?.cancel();
    _autoFillDebounce = Timer(const Duration(milliseconds: 500), () => _lookupLead(field));
  }

  Future<void> _lookupLead(String field) async {
    String query = '';
    String column = '';
    switch (field) {
      case 'phone':
        query = _customerPhoneController.text.trim();
        column = 'phone';
      case 'name':
        query = _customerNameController.text.trim();
        column = 'name';
      case 'company':
        query = _companyNameController.text.trim();
        column = 'company_name';
    }
    if (query.length < 3) {
      if (mounted) setState(() => _suggestedLead = null);
      return;
    }
    try {
      final data = await _supabase
          .from('leads')
          .select('id, name, phone, company_name')
          .ilike(column, '%$query%')
          .limit(1)
          .maybeSingle();
      if (!mounted) return;
      final lead = data != null ? Map<String, dynamic>.from(data as Map) : null;
      setState(() => _suggestedLead = lead);
    } catch (_) {}
  }

  void _acceptSuggestion() {
    final lead = _suggestedLead;
    if (lead == null) return;
    _applyingAutoFill = true;
    setState(() {
      _customerNameController.text = (lead['name'] ?? '').toString().trim();
      _customerPhoneController.text = (lead['phone'] ?? '').toString().trim();
      _companyNameController.text = (lead['company_name'] ?? '').toString().trim();
      _suggestedLead = null;
    });
    _applyingAutoFill = false;
  }

  void _dismissSuggestion() => setState(() => _suggestedLead = null);

  @override
  void dispose() {
    _autoFillDebounce?.cancel();
    _customerNameController.dispose();
    _companyNameController.dispose();
    _customerTrnController.dispose();
    _customerPhoneController.dispose();
    _salespersonNameController.dispose();
    _salespersonContactController.dispose();
    _salespersonPhoneController.dispose();
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

  Future<void> _pickFromLead() async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LeadPickerDialog(supabase: _supabase),
    );
    if (picked == null) return;
    setState(() {
      _customerNameController.text = (picked['name'] ?? '').toString().trim();
      _customerPhoneController.text = (picked['phone'] ?? '').toString().trim();
      _companyNameController.text = (picked['company_name'] ?? '').toString().trim();
    });
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    Navigator.of(context).pop(
      _QuotationDraft(
        customerName: _customerNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        customerTrn: _customerTrnController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        salespersonName: _salespersonNameController.text.trim(),
        salespersonContact: _salespersonContactController.text.trim(),
        salespersonPhone: _salespersonPhoneController.text.trim(),
        notes: _notesController.text.trim(),
        deliveryFee: _deliveryFee,
        installationFee: _installationFee,
        additionalDetailsFee: _additionalDetailsFee,
        vatPercent: _vatPercent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    final sheet = SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, (MediaQuery.paddingOf(context).bottom + 16).clamp(24.0, double.infinity)),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create Quotation',
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    widget.formatPrice(_netTotal),
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Choose from existing lead
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: _pickFromLead,
                          icon: const Icon(Icons.person_search_rounded, size: 18),
                          label: const Text('Choose from Lead'),
                        ),
                      ),
                      // Auto-fill suggestion banner
                      if (_suggestedLead != null) ...[
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _accentColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_pin_rounded, size: 18, color: _accentColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lead found — fill in details?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: _accentColor,
                                      ),
                                    ),
                                    Text(
                                      [
                                        (_suggestedLead!['name'] ?? '').toString().trim(),
                                        (_suggestedLead!['phone'] ?? '').toString().trim(),
                                        (_suggestedLead!['company_name'] ?? '').toString().trim(),
                                      ].where((s) => s.isNotEmpty).join(' · '),
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _acceptSuggestion,
                                style: TextButton.styleFrom(
                                  foregroundColor: _accentColor,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Fill', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                              IconButton(
                                onPressed: _dismissSuggestion,
                                icon: const Icon(Icons.close_rounded, size: 16),
                                visualDensity: VisualDensity.compact,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Customer Name',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Customer Phone',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _customerTrnController,
                              decoration: const InputDecoration(
                                labelText: 'Customer TRN',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              enabled: false,

                              controller: _salespersonNameController,
                              decoration: const InputDecoration(
                                labelText: 'Salesperson Name',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              enabled: false,
                              controller: _salespersonContactController,
                              decoration: const InputDecoration(
                                labelText: 'Salesperson Contact',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _salespersonPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Salesperson Phone',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _deliveryFeeController,
                              validator: _validateNumber,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Fee',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _installationFeeController,
                              validator: _validateNumber,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Installation Fee',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _additionalDetailsFeeController,
                              validator: _validateNumber,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Additional Details Fee',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              enabled: false,
                              controller: _vatPercentController,
                              validator: _validateNumber,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'VAT %',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              controller: _notesController,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2B2B2B)),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Subtotal',
                              value: widget.formatPrice(widget.subtotal),
                            ),
                            _SummaryRow(
                              label: 'Taxable Total',
                              value: widget.formatPrice(_taxableTotal),
                            ),
                            _SummaryRow(
                              label: 'VAT Amount',
                              value: widget.formatPrice(_vatAmount),
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Net Total',
                              value: widget.formatPrice(_netTotal),
                              highlight: true,
                              highlightColor: _accentColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                      _isSubmitting ? 'Saving…' : 'Save Quotation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.isHamasat
        ? Theme(data: _hamTheme(context), child: sheet)
        : sheet;
  }
}

class _AdaptiveField extends StatelessWidget {
  final bool isMobile;
  final Widget child;

  const _AdaptiveField({
    required this.isMobile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) return child;
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 80) / 2,
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? (highlightColor ?? AppConstants.primaryColor)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _productionTimeController = TextEditingController();
  final _displayPriceController = TextEditingController();

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

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _itemCodeController.dispose();
    _imagePathController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _productionTimeController.dispose();
    _displayPriceController.dispose();
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
    super.dispose();
  }

  double? _parseNullableDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _supabase.from('price_list_api').insert({
        'category_ar': _safeTextOrNull(_categoryController.text),
        'description': _safeTextOrNull(_descriptionController.text),
        'product_name': _safeTextOrNull(_productNameController.text),
        'item_code': _safeTextOrNull(_itemCodeController.text),
        'image_path': _safeTextOrNull(_imagePathController.text),
        'length': _safeTextOrNull(_lengthController.text),
        'width': _safeTextOrNull(_widthController.text),
        'production_time': _safeTextOrNull(_productionTimeController.text),
        'display_price': _safeTextOrNull(_displayPriceController.text),
        'price_ee': _parseNullableDouble(_priceEeController.text),
        'price_aa': _parseNullableDouble(_priceAaController.text),
        'price_a': _parseNullableDouble(_priceAController.text),
        'price_rr': _parseNullableDouble(_priceRrController.text),
        'price_r': _parseNullableDouble(_priceRController.text),
        'price_art': _parseNullableDouble(_priceArtController.text),
        'pot_item_no': _safeTextOrNull(_potItemNoController.text),
        'pot_price': _parseNullableDouble(_potPriceController.text),
        'additions': _safeTextOrNull(_additionsController.text),
        'total_price': _parseNullableDouble(_totalPriceController.text),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, (MediaQuery.paddingOf(context).bottom + 16).clamp(24.0, double.infinity)),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Add Item',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _itemCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Item Code',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _displayPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Display Price',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceEeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price EE',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceAaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price AA',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceAController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price A',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceRrController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price RR',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceRController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price R',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _priceArtController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price ART',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _totalPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Price',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _potPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pot Price',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              controller: _descriptionController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _imagePathController,
                              decoration: const InputDecoration(
                                labelText: 'Image Path',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _lengthController,
                              decoration: const InputDecoration(
                                labelText: 'Length',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _widthController,
                              decoration: const InputDecoration(
                                labelText: 'Width',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _productionTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Production Time',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: _potItemNoController,
                              decoration: const InputDecoration(
                                labelText: 'Pot Item No',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              controller: _additionsController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Additions',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      : const Icon(Icons.add_box_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
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
  };
}

class _BulkAddItemsSheet extends StatefulWidget {
  const _BulkAddItemsSheet();

  @override
  State<_BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
}

class _BulkAddItemsSheetState extends State<_BulkAddItemsSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> _previewRows = [];
  String? _previewError;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _buildPreview() {
    final raw = _controller.text.trim();

    if (raw.isEmpty) {
      setState(() {
        _previewRows = [];
        _previewError = null;
      });
      return;
    }

    try {
      List<Map<String, dynamic>> rows = [];

      if (raw.startsWith('[') || raw.startsWith('{')) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          rows = decoded
              .map((e) => _buildPriceListItemPayload(Map<String, dynamic>.from(e)))
              .toList();
        } else if (decoded is Map) {
          rows = [_buildPriceListItemPayload(Map<String, dynamic>.from(decoded))];
        } else {
          throw Exception('Unsupported JSON payload.');
        }
      } else {
        final parsed =  Csv(
          lineDelimiter: '\n',
          dynamicTyping: false,
        ).decode(raw);

        if (parsed.isEmpty) {
          throw Exception('No rows found.');
        }

        final header = parsed.first.map((e) => e.toString().trim()).toList();
        rows = parsed.skip(1).where((row) => row.isNotEmpty).map((row) {
          final map = <String, dynamic>{};
          for (var i = 0; i < header.length && i < row.length; i++) {
            map[header[i]] = row[i];
          }
          return _buildPriceListItemPayload(map);
        }).toList();
      }

      setState(() {
        _previewRows = rows;
        _previewError = rows.isEmpty ? 'No valid rows found.' : null;
      });
    } catch (e) {
      setState(() {
        _previewRows = [];
        _previewError = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (_previewRows.isEmpty || _previewError != null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _supabase.from('price_list_api').insert(_previewRows);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import rows: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewCount = _previewRows.length;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, (MediaQuery.paddingOf(context).bottom + 16).clamp(24.0, double.infinity)),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Bulk Add Items',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste CSV, TSV-compatible CSV, or JSON array/object.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => _buildPreview(),
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Paste data here...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2B2B2B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview rows: $previewCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    if (_previewError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _previewError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                  (_isSaving || previewCount == 0 || _previewError != null)
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
      ),
    );
  }
}

// ── Lead Picker Dialog ────────────────────────────────────────────────────────

class _LeadPickerDialog extends StatefulWidget {
  final SupabaseClient supabase;
  const _LeadPickerDialog({required this.supabase});

  @override
  State<_LeadPickerDialog> createState() => _LeadPickerDialogState();
}

class _LeadPickerDialogState extends State<_LeadPickerDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _search(''); // load recent leads on open
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    _search(q);
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      dynamic req = widget.supabase
          .from('leads')
          .select('id, name, phone, company_name, owner_id, status');
      if (query.isNotEmpty) {
        req = req.or('name.ilike.%$query%,phone.ilike.%$query%,company_name.ilike.%$query%');
      }
      final data = await req.order('updated_at', ascending: false).limit(30);
      if (!mounted) return;
      setState(() {
        _results = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose from Lead',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or company...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty && !_isSearching
                  ? const Center(child: Text('No leads found', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final lead = _results[index];
                        final name = (lead['name'] ?? '').toString().trim();
                        final phone = (lead['phone'] ?? '').toString().trim();
                        final company = (lead['company_name'] ?? '').toString().trim();
                        final status = (lead['status'] ?? '').toString().trim();
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(name.isNotEmpty ? name : 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([
                            if (phone.isNotEmpty) phone,
                            if (company.isNotEmpty) company,
                          ].join(' · '), style: const TextStyle(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          onTap: () => Navigator.pop(context, lead),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}