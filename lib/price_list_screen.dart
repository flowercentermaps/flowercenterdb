// // // import 'dart:async';
// // // import 'dart:convert';
// // //
// // // import 'package:FlowerCenterCrm/user_role_management_screen.dart';
// // // import 'package:cached_network_image/cached_network_image.dart';
// // // import 'package:csv/csv.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // //
// // // import 'container_processor_screen.dart';
// // // import 'core/constants/app_constants.dart';
// // // import 'quotation_details_screen.dart';
// // // import 'quotation_list_screen.dart';
// // // import 'scanner.dart';
// // //
// // // class _PriceOptionMeta {
// // //   final String key;
// // //   final String label;
// // //
// // //   const _PriceOptionMeta(this.key, this.label);
// // // }
// // //
// // // const List<_PriceOptionMeta> _priceOptions = [
// // //   _PriceOptionMeta('price_ee', 'EE'),
// // //   _PriceOptionMeta('price_aa', 'AA'),
// // //   _PriceOptionMeta('price_a', 'A'),
// // //   _PriceOptionMeta('price_rr', 'RR'),
// // //   _PriceOptionMeta('price_r', 'R'),
// // //   _PriceOptionMeta('price_art', 'ART'),
// // // ];
// // //
// // // class _SelectedQuoteItem {
// // //   final int itemId;
// // //   final String productName;
// // //   final String priceKey;
// // //   final String priceLabel;
// // //   final double unitPrice;
// // //   final int quantity;
// // //   final Map<String, dynamic> item;
// // //
// // //   const _SelectedQuoteItem({
// // //     required this.itemId,
// // //     required this.productName,
// // //     required this.priceKey,
// // //     required this.priceLabel,
// // //     required this.unitPrice,
// // //     required this.quantity,
// // //     required this.item,
// // //   });
// // //
// // //   _SelectedQuoteItem copyWith({
// // //     String? priceKey,
// // //     String? priceLabel,
// // //     double? unitPrice,
// // //     int? quantity,
// // //   }) {
// // //     return _SelectedQuoteItem(
// // //       itemId: itemId,
// // //       productName: productName,
// // //       priceKey: priceKey ?? this.priceKey,
// // //       priceLabel: priceLabel ?? this.priceLabel,
// // //       unitPrice: unitPrice ?? this.unitPrice,
// // //       quantity: quantity ?? this.quantity,
// // //       item: item,
// // //     );
// // //   }
// // //
// // //   double get lineTotal => unitPrice * quantity;
// // // }
// // //
// // // class _QuotationDraft {
// // //   final String customerName;
// // //   final String companyName;
// // //   final String customerTrn;
// // //   final String customerPhone;
// // //   final String salespersonName;
// // //   final String salespersonContact;
// // //   final String salespersonPhone;
// // //   final String notes;
// // //   final double deliveryFee;
// // //   final double installationFee;
// // //   final double additionalDetailsFee;
// // //   final double vatPercent;
// // //
// // //   const _QuotationDraft({
// // //     required this.customerName,
// // //     required this.companyName,
// // //     required this.customerTrn,
// // //     required this.customerPhone,
// // //     required this.salespersonName,
// // //     required this.salespersonContact,
// // //     required this.salespersonPhone,
// // //     required this.notes,
// // //     required this.deliveryFee,
// // //     required this.installationFee,
// // //     required this.additionalDetailsFee,
// // //     required this.vatPercent,
// // //   });
// // // }
// // //
// // // int? _safeInt(dynamic value) {
// // //   if (value == null) return null;
// // //   if (value is int) return value;
// // //   if (value is num) return value.toInt();
// // //   return int.tryParse(value.toString().trim());
// // // }
// // //
// // // double _safeDouble(dynamic value) {
// // //   if (value == null) return 0;
// // //   if (value is num) return value.toDouble();
// // //   return double.tryParse(value.toString().trim()) ?? 0;
// // // }
// // //
// // // class PriceListScreen extends StatefulWidget {
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const PriceListScreen({
// // //     super.key,
// // //     required this.profile,
// // //     required this.onLogout,
// // //   });
// // //
// // //   @override
// // //   State<PriceListScreen> createState() => _PriceListScreenState();
// // // }
// // //
// // // class _PriceListScreenState extends State<PriceListScreen> {
// // //   final SupabaseClient _supabase = Supabase.instance.client;
// // //   final TextEditingController _searchController = TextEditingController();
// // //
// // //   // bool get _isAdmin => (widget.profile['role'] ?? '') == 'admin';
// // //
// // //   String get _role => (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// // //
// // //   bool get _isAdmin => _role == 'admin';
// // //   bool get _isSales => _role == 'sales';
// // //   bool get _isAccountant => _role == 'accountant';
// // //   bool get _isViewer => _role == 'viewer';
// // //
// // //   bool get _canCreateQuotation => _isSales || _isAdmin;
// // //   bool get _canViewQuotations => _isSales || _isAdmin;
// // //   bool get _canManagePricePermissions => _isAdmin || _isAccountant;
// // //   bool get _canAddItems => _isAdmin || _isAccountant;
// // //   bool get _canManageUsers => _isAdmin;
// // //   bool get _canUseContainerProcessor => _isAdmin || _isAccountant;
// // //   bool get _canUsePriceChipsForQuotation => _isAdmin || _isSales;
// // //
// // //   Timer? _debounce;
// // //
// // //   bool _isLoading = true;
// // //   String? _errorMessage;
// // //
// // //   List<Map<String, dynamic>> _allItems = [];
// // //   List<Map<String, dynamic>> _filteredItems = [];
// // //   List<String> _categories = [];
// // //
// // //   String _searchQuery = '';
// // //   String? _selectedCategory;
// // //
// // //   Map<String, bool> _pricePermissions = {
// // //     for (final option in _priceOptions) option.key: true,
// // //   };
// // //
// // //   final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};
// // //   bool _isLoadingPermissions = true;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _searchController.addListener(_onSearchChanged);
// // //     Future.wait([
// // //       _loadItems(),
// // //       _loadPricePermissions(),
// // //     ]);
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _debounce?.cancel();
// // //     _searchController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   void _onSearchChanged() {
// // //     _debounce?.cancel();
// // //     _debounce = Timer(const Duration(milliseconds: 300), () {
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _searchQuery = _searchController.text.trim();
// // //         _applyFilters();
// // //       });
// // //     });
// // //   }
// // //
// // //   Future<void> _loadItems() async {
// // //     setState(() {
// // //       _isLoading = true;
// // //       _errorMessage = null;
// // //     });
// // //
// // //     try {
// // //       final response = await _supabase
// // //           .from('price_list_api')
// // //           .select()
// // //           .order('category_ar', ascending: true)
// // //           .order('product_name', ascending: true);
// // //
// // //       final items = (response as List)
// // //           .map((item) => Map<String, dynamic>.from(item as Map))
// // //           .toList();
// // //
// // //       final categories = items
// // //           .map((e) => (e['category_ar'] ?? '').toString().trim())
// // //           .where((e) => e.isNotEmpty)
// // //           .toSet()
// // //           .toList()
// // //         ..sort();
// // //
// // //       setState(() {
// // //         _allItems = items;
// // //         _categories = categories;
// // //         _applyFilters();
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       setState(() {
// // //         _errorMessage = e.toString();
// // //         _isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   void _applyFilters() {
// // //     final search = _searchQuery.toLowerCase();
// // //
// // //     _filteredItems = _allItems.where((item) {
// // //       final category = (item['category_ar'] ?? '').toString().trim();
// // //       final description = (item['description'] ?? '').toString().trim();
// // //       final productName = (item['product_name'] ?? '').toString().trim();
// // //       final itemCode = (item['item_code'] ?? '').toString().trim();
// // //       final displayPrice = (item['display_price'] ?? '').toString().trim();
// // //       final barcode = (item['barcode'] ?? '').toString().trim();
// // //
// // //       final matchesCategory =
// // //           _selectedCategory == null || category == _selectedCategory;
// // //
// // //       final haystack = [
// // //         category,
// // //         description,
// // //         productName,
// // //         itemCode,
// // //         displayPrice,
// // //         barcode,
// // //       ].join(' ').toLowerCase();
// // //
// // //       final matchesSearch = search.isEmpty || haystack.contains(search);
// // //
// // //       return matchesCategory && matchesSearch;
// // //     }).toList();
// // //   }
// // //
// // //   void _clearFilters() {
// // //     setState(() {
// // //       _selectedCategory = null;
// // //       _searchQuery = '';
// // //       _searchController.clear();
// // //       _applyFilters();
// // //     });
// // //   }
// // //
// // //   Future<void> _startBarcodeScan() async {
// // //     final code = await Navigator.of(context).push<String>(
// // //       MaterialPageRoute(
// // //         builder: (_) => const BarcodeScannerScreen(),
// // //       ),
// // //     );
// // //
// // //     if (!mounted || code == null || code.trim().isEmpty) return;
// // //
// // //     setState(() {
// // //       _searchController.text = code.trim();
// // //       _searchController.selection = TextSelection.fromPosition(
// // //         TextPosition(offset: _searchController.text.length),
// // //       );
// // //       _searchQuery = code.trim();
// // //       _applyFilters();
// // //     });
// // //   }
// // //
// // //   double? _toDouble(dynamic value) {
// // //     if (value == null) return null;
// // //     if (value is num) return value.toDouble();
// // //     return double.tryParse(value.toString());
// // //   }
// // //
// // //   String _formatPrice(dynamic value) {
// // //     final number = _toDouble(value);
// // //     if (number == null) return '-';
// // //     if (number == number.roundToDouble()) {
// // //       return number.toInt().toString();
// // //     }
// // //     return number.toStringAsFixed(2);
// // //   }
// // //
// // //   Future<void> _loadPricePermissions() async {
// // //     try {
// // //       final response = await _supabase.rpc('get_my_price_permissions');
// // //
// // //       final map = {
// // //         for (final option in _priceOptions) option.key: true,
// // //       };
// // //
// // //       if (response is List) {
// // //         for (final row in response) {
// // //           final data = Map<String, dynamic>.from(row as Map);
// // //           final key = (data['price_key'] ?? '').toString();
// // //           final allowed = data['is_allowed'] == true;
// // //           if (map.containsKey(key)) {
// // //             map[key] = allowed;
// // //           }
// // //         }
// // //       }
// // //
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _pricePermissions = map;
// // //         _isLoadingPermissions = false;
// // //       });
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _pricePermissions = {
// // //           for (final option in _priceOptions) option.key: true,
// // //         };
// // //         _isLoadingPermissions = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   double? _priceValueForKey(Map<String, dynamic> item, String priceKey) {
// // //     return _toDouble(item[priceKey]);
// // //   }
// // //
// // //   bool _isPriceAllowedForItem(Map<String, dynamic> item, String priceKey) {
// // //     final globallyAllowed = _pricePermissions[priceKey] ?? true;
// // //     final value = _priceValueForKey(item, priceKey);
// // //     return globallyAllowed && value != null;
// // //   }
// // //
// // //   String? _selectedPriceKeyForItem(Map<String, dynamic> item) {
// // //     final itemId = _safeInt(item['id']);
// // //     if (itemId == null) return null;
// // //     return _selectedQuoteItems[itemId]?.priceKey;
// // //   }
// // //
// // //   void _toggleItemPriceSelection(
// // //       Map<String, dynamic> item,
// // //       String priceKey,
// // //       String priceLabel,
// // //       ) {
// // //     if (!_canUsePriceChipsForQuotation) return;
// // //     if (!_isPriceAllowedForItem(item, priceKey)) return;
// // //
// // //     final itemId = _safeInt(item['id']);
// // //     if (itemId == null) return;
// // //
// // //     final priceValue = _priceValueForKey(item, priceKey);
// // //     if (priceValue == null) return;
// // //
// // //     final current = _selectedQuoteItems[itemId];
// // //
// // //     setState(() {
// // //       if (current != null && current.priceKey == priceKey) {
// // //         _selectedQuoteItems.remove(itemId);
// // //         return;
// // //       }
// // //
// // //       _selectedQuoteItems[itemId] = _SelectedQuoteItem(
// // //         itemId: itemId,
// // //         productName: (item['product_name'] ?? '').toString().trim(),
// // //         priceKey: priceKey,
// // //         priceLabel: priceLabel,
// // //         unitPrice: priceValue,
// // //         quantity: current?.quantity ?? 1,
// // //         item: item,
// // //       );
// // //     });
// // //   }
// // //
// // //
// // //   void _changeSelectedItemQuantity(int itemId, int delta) {
// // //     final current = _selectedQuoteItems[itemId];
// // //     if (current == null) return;
// // //
// // //     final nextQty = current.quantity + delta;
// // //     setState(() {
// // //       if (nextQty <= 0) {
// // //         _selectedQuoteItems.remove(itemId);
// // //       } else {
// // //         _selectedQuoteItems[itemId] = current.copyWith(quantity: nextQty);
// // //       }
// // //     });
// // //   }
// // //
// // //   double get _selectedGrandTotal {
// // //     return _selectedQuoteItems.values.fold(
// // //       0,
// // //           (sum, item) => sum + item.lineTotal,
// // //     );
// // //   }
// // //
// // //   Future<void> _openCreateQuotationSheet() async {
// // //     if (_selectedQuoteItems.isEmpty) return;
// // //
// // //     final draft = await showModalBottomSheet<_QuotationDraft>(
// // //       context: context,
// // //       useSafeArea: true,
// // //       isScrollControlled: true,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (_) => _CreateQuotationSheet(
// // //         subtotal: _selectedGrandTotal,
// // //         formatPrice: _formatPrice,
// // //         profile: widget.profile,
// // //       ),
// // //     );
// // //
// // //     if (!mounted || draft == null) return;
// // //     await _saveQuotation(draft);
// // //   }
// // //
// // //
// // //   Future<void> _saveQuotation(_QuotationDraft draft) async {
// // //     final user = _supabase.auth.currentUser;
// // //     if (user == null) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('No logged in user found.')),
// // //       );
// // //       return;
// // //     }
// // //
// // //     final subtotal = _selectedGrandTotal;
// // //     final taxableTotal = subtotal +
// // //         draft.deliveryFee +
// // //         draft.installationFee +
// // //         draft.additionalDetailsFee;
// // //     final vatAmount = taxableTotal * (draft.vatPercent / 100);
// // //     final netTotal = taxableTotal + vatAmount;
// // //
// // //     final quoteNo = 'QT-${DateTime.now().microsecondsSinceEpoch}';
// // //
// // //     final quotationPayload = {
// // //       'quote_no': quoteNo,
// // //       'quote_date': DateTime.now().toIso8601String().split('T').first,
// // //       'customer_name': draft.customerName.isEmpty ? null : draft.customerName,
// // //       'company_name': draft.companyName.isEmpty ? null : draft.companyName,
// // //       'customer_trn': draft.customerTrn.isEmpty ? null : draft.customerTrn,
// // //       'customer_phone': draft.customerPhone.isEmpty ? null : draft.customerPhone,
// // //       'salesperson_name':
// // //       draft.salespersonName.isEmpty ? null : draft.salespersonName,
// // //       'salesperson_contact':
// // //       draft.salespersonContact.isEmpty ? null : draft.salespersonContact,
// // //       'salesperson_phone': widget.profile['phone'],
// // //       'notes': draft.notes.isEmpty ? null : draft.notes,
// // //       'status': 'draft',
// // //       'subtotal': subtotal,
// // //       'delivery_fee': draft.deliveryFee,
// // //       'installation_fee': draft.installationFee,
// // //       'additional_details_fee': draft.additionalDetailsFee,
// // //       'taxable_total': taxableTotal,
// // //       'vat_percent': draft.vatPercent,
// // //       'vat_amount': vatAmount,
// // //       'net_total': netTotal,
// // //       'created_by': user.id,
// // //       'updated_by': user.id,
// // //     };
// // //
// // //     try {
// // //       final insertedQuotation = await _supabase
// // //           .from('quotations')
// // //           .insert(quotationPayload)
// // //           .select('id, quote_no, created_by')
// // //           .single();
// // //
// // //       final quotationId = _safeInt(insertedQuotation['id']);
// // //       if (quotationId == null) {
// // //         throw Exception('Failed to resolve quotation id.');
// // //       }
// // //
// // //       final itemRows = _selectedQuoteItems.values.map((selected) {
// // //         final item = selected.item;
// // //         final itemCode = (item['item_code'] ?? '').toString().trim();
// // //         final description = (item['description'] ?? '').toString().trim();
// // //         final imagePath = (item['image_path'] ?? '').toString().trim();
// // //         final productName = selected.productName.trim().isEmpty
// // //             ? 'Unnamed Product'
// // //             : selected.productName.trim();
// // //
// // //         final rawLength = item['length']?.toString().trim();
// // //         final rawWidth = item['width']?.toString().trim();
// // //         final rawProductionTime = item['production_time']?.toString().trim();
// // //
// // //         return {
// // //           'quotation_id': quotationId,
// // //           'product_id': selected.itemId,
// // //           'item_code': itemCode.isEmpty ? null : itemCode,
// // //           'product_name': productName,
// // //           'description': description.isEmpty ? null : description,
// // //           'image_path': imagePath.isEmpty ? null : imagePath,
// // //           'length': (rawLength == null || rawLength.isEmpty)
// // //               ? null
// // //               : item['length'].toString().trim(),
// // //           'width': (rawWidth == null || rawWidth.isEmpty)
// // //               ? null
// // //               : item['width'].toString().trim(),
// // //           'production_time': (rawProductionTime == null || rawProductionTime.isEmpty)
// // //               ? null
// // //               : item['production_time'].toString().trim(),
// // //           'price_key': selected.priceKey,
// // //           'price_label': selected.priceLabel,
// // //           'unit_price': selected.unitPrice,
// // //           'quantity': selected.quantity,
// // //           'line_total': selected.lineTotal,
// // //           'snapshot': {
// // //             'category_ar': item['category_ar'],
// // //             'description': item['description'],
// // //             'product_name': item['product_name'],
// // //             'item_code': item['item_code'],
// // //             'price_ee': item['price_ee'],
// // //             'price_aa': item['price_aa'],
// // //             'price_a': item['price_a'],
// // //             'price_rr': item['price_rr'],
// // //             'price_r': item['price_r'],
// // //             'price_art': item['price_art'],
// // //             'pot_item_no': item['pot_item_no'],
// // //             'pot_price': item['pot_price'],
// // //             'additions': item['additions'],
// // //             'total_price': item['total_price'],
// // //             'display_price': item['display_price'],
// // //             'image_path': item['image_path'],
// // //             'length': item['length'],
// // //             'width': item['width'],
// // //             'production_time': item['production_time'],
// // //           },
// // //         };
// // //       }).toList();
// // //
// // //       await _supabase.from('quotation_items').insert(itemRows);
// // //
// // //       if (!mounted) return;
// // //
// // //       setState(() {
// // //         _selectedQuoteItems.clear();
// // //       });
// // //
// // //       final quoteNumber = (insertedQuotation['quote_no'] ?? '').toString();
// // //
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Quotation $quoteNumber created successfully.'),
// // //         ),
// // //       );
// // //
// // //       await Navigator.of(context).push(
// // //         MaterialPageRoute(
// // //           builder: (_) => QuotationDetailsScreen(
// // //             quotationId: quotationId,
// // //           ),
// // //         ),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to create quotation: $e')),
// // //       );
// // //     }
// // //   }
// // //
// // //   void _openSelectedItemsSheet() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       useSafeArea: true,
// // //       isScrollControlled: true,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (_) {
// // //         return StatefulBuilder(
// // //           builder: (context, setModalState) {
// // //             final selectedItems = _selectedQuoteItems.values.toList();
// // //
// // //             return SafeArea(
// // //               child: FractionallySizedBox(
// // //                 heightFactor: 0.9,
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
// // //                   child: Column(
// // //                     children: [
// // //                       Text(
// // //                         'Selected Items',
// // //                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                           fontWeight: FontWeight.w900,
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 16),
// // //                       Expanded(
// // //                         child: selectedItems.isEmpty
// // //                             ? const Center(
// // //                           child: Text('No items selected yet.'),
// // //                         )
// // //                             : ListView.separated(
// // //                           itemCount: selectedItems.length,
// // //                           separatorBuilder: (_, __) =>
// // //                           const Divider(height: 20),
// // //                           itemBuilder: (context, index) {
// // //                             final selected = selectedItems[index];
// // //
// // //                             return Row(
// // //                               crossAxisAlignment: CrossAxisAlignment.start,
// // //                               children: [
// // //                                 Expanded(
// // //                                   child: Column(
// // //                                     crossAxisAlignment:
// // //                                     CrossAxisAlignment.start,
// // //                                     children: [
// // //                                       Text(
// // //                                         selected.productName.isEmpty
// // //                                             ? 'Unnamed Product'
// // //                                             : selected.productName,
// // //                                         style: const TextStyle(
// // //                                           fontWeight: FontWeight.w800,
// // //                                         ),
// // //                                       ),
// // //                                       const SizedBox(height: 4),
// // //                                       Text(
// // //                                         '${selected.priceLabel} • ${_formatPrice(selected.unitPrice)}',
// // //                                         style: const TextStyle(
// // //                                           color: AppConstants.primaryColor,
// // //                                           fontWeight: FontWeight.w700,
// // //                                         ),
// // //                                       ),
// // //                                       const SizedBox(height: 4),
// // //                                       Text(
// // //                                         'Line total: ${_formatPrice(selected.lineTotal)}',
// // //                                       ),
// // //                                     ],
// // //                                   ),
// // //                                 ),
// // //                                 Row(
// // //                                   mainAxisSize: MainAxisSize.min,
// // //                                   children: [
// // //                                     IconButton(
// // //                                       onPressed: () {
// // //                                         _changeSelectedItemQuantity(
// // //                                           selected.itemId,
// // //                                           -1,
// // //                                         );
// // //                                         setModalState(() {});
// // //                                       },
// // //                                       icon: const Icon(
// // //                                         Icons.remove_circle_outline,
// // //                                       ),
// // //                                     ),
// // //                                     Text(
// // //                                       '${_selectedQuoteItems[selected.itemId]?.quantity ?? selected.quantity}',
// // //                                       style: const TextStyle(
// // //                                         fontWeight: FontWeight.w800,
// // //                                       ),
// // //                                     ),
// // //                                     IconButton(
// // //                                       onPressed: () {
// // //                                         _changeSelectedItemQuantity(
// // //                                           selected.itemId,
// // //                                           1,
// // //                                         );
// // //                                         setModalState(() {});
// // //                                       },
// // //                                       icon: const Icon(
// // //                                         Icons.add_circle_outline,
// // //                                       ),
// // //                                     ),
// // //                                   ],
// // //                                 ),
// // //                               ],
// // //                             );
// // //                           },
// // //                         ),
// // //                       ),
// // //                       if (_selectedQuoteItems.isNotEmpty) ...[
// // //                         const SizedBox(height: 16),
// // //                         Row(
// // //                           children: [
// // //                             const Expanded(
// // //                               child: Text(
// // //                                 'Grand Total',
// // //                                 style: TextStyle(fontWeight: FontWeight.w800),
// // //                               ),
// // //                             ),
// // //                             Text(
// // //                               _formatPrice(_selectedGrandTotal),
// // //                               style: const TextStyle(
// // //                                 color: Color(0xFFFFD95E),
// // //                                 fontWeight: FontWeight.w900,
// // //                                 fontSize: 18,
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                         const SizedBox(height: 16),
// // //                         SizedBox(
// // //                           width: double.infinity,
// // //                           child: FilledButton.icon(
// // //                             onPressed: () {
// // //                               Navigator.pop(context);
// // //                               _openCreateQuotationSheet();
// // //                             },
// // //                             icon: const Icon(Icons.description_outlined),
// // //                             label: const Text('Create Quotation'),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             );
// // //           },
// // //         );
// // //       },
// // //     );
// // //   }
// // //   int _gridCount(double width) {
// // //     if (width >= 1400) return 4;
// // //     if (width >= 1000) return 3;
// // //     if (width >= 700) return 2;
// // //     return 1;
// // //   }
// // //
// // //   void _openDetails(Map<String, dynamic> item) {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       useSafeArea: true,
// // //       isScrollControlled: true,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (_) => _ProductDetailsSheet(
// // //         item: item,
// // //         formatPrice: _formatPrice,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<void> _openAddItemSheet() async {
// // //     final created = await showModalBottomSheet<bool>(
// // //       context: context,
// // //       useSafeArea: true,
// // //       isScrollControlled: true,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (_) => const _AddItemSheet(),
// // //     );
// // //
// // //     if (created == true) {
// // //       await _loadItems();
// // //     }
// // //   }
// // //
// // //   Future<void> _openBulkAddItemsSheet() async {
// // //     final created = await showModalBottomSheet<bool>(
// // //       context: context,
// // //       useSafeArea: true,
// // //       isScrollControlled: true,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (_) => const _BulkAddItemsSheet(),
// // //     );
// // //
// // //     if (created == true) {
// // //       await _loadItems();
// // //     }
// // //   }
// // //
// // //
// // //   Future<void> _openFabActions() async {
// // //     if (!mounted) return;
// // //
// // //     await showModalBottomSheet(
// // //       context: context,
// // //       backgroundColor: const Color(0xFF121212),
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       builder: (context) {
// // //         return SafeArea(
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(16),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 if (_canUseContainerProcessor) ...[
// // //                   ListTile(
// // //                     leading: const Icon(Icons.inventory_2_outlined),
// // //                     title: const Text('Container Processor'),
// // //                     onTap: () {
// // //                       Navigator.pop(context);
// // //                       Navigator.of(context).push(
// // //                         MaterialPageRoute(
// // //                           builder: (_) => const ContainerProcessorScreen(),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),],
// // //         if (_canAddItems) ...[
// // //                   ListTile(
// // //                     leading: const Icon(Icons.add_box_outlined),
// // //                     title: const Text('Add Item'),
// // //                     onTap: () {
// // //                       Navigator.pop(context);
// // //                       _openAddItemSheet();
// // //                     },
// // //                   ),
// // //                   if(_canManageUsers)
// // //                   ListTile(
// // //                     leading: const Icon(Icons.manage_accounts_outlined),
// // //                     title: const Text('Manage User Roles'),
// // //                     subtitle: const Text('Change roles for other users'),
// // //                     onTap: () {
// // //                       Navigator.pop(context);
// // //                       Navigator.of(context).push(
// // //                         MaterialPageRoute(
// // //                           builder: (_) => UserRoleManagementScreen(
// // //                             currentUserId: (widget.profile['id'] ?? '').toString(),
// // //                           ),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                   ListTile(
// // //                     leading: const Icon(Icons.playlist_add_check_circle_outlined),
// // //                     title: const Text('Add Bulk Items'),
// // //                     subtitle: const Text('Paste CSV, TSV, or JSON rows'),
// // //                     onTap: () {
// // //                       Navigator.pop(context);
// // //                       _openBulkAddItemsSheet();
// // //                     },
// // //                   ),
// // //                 ],
// // //                 if(_canViewQuotations || _canCreateQuotation)
// // //                 ListTile(
// // //                   leading: const Icon(Icons.description_outlined),
// // //                   title: Text(_isAdmin ? 'View Quotations' : _isSales? 'My Quotations':""),
// // //                   onTap: () {
// // //                     Navigator.pop(context);
// // //                     Navigator.of(context).push(
// // //                       MaterialPageRoute(
// // //                         builder: (_) => QuotationListScreen(
// // //                           role: _role,
// // //                           currentUserId:
// // //                           (widget.profile['id'] ?? '').toString(),
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //                 if (_canManagePricePermissions)
// // //                   ListTile(
// // //                     leading: const Icon(Icons.lock_person_outlined),
// // //                     title: const Text('Price Permissions'),
// // //                     subtitle:
// // //                     const Text('Global and per-user price restrictions'),
// // //                     onTap: () {
// // //                       Navigator.pop(context);
// // //                       Navigator.of(context).push(
// // //                         MaterialPageRoute(
// // //                           builder: (_) => const PricePermissionsScreen(),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                 ListTile(
// // //                   leading: const Icon(Icons.qr_code_scanner_rounded),
// // //                   title: const Text('Scan Barcode'),
// // //                   onTap: () {
// // //                     Navigator.pop(context);
// // //                     _startBarcodeScan();
// // //                   },
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFF0A0A0A),
// // //       floatingActionButton: FloatingActionButton.extended(
// // //         onPressed: _openFabActions,
// // //         icon: Icon(
// // //           _isAdmin
// // //               ? Icons.admin_panel_settings_rounded
// // //               : Icons.apps,
// // //         ),
// // //         label: Text( 'Actions'),
// // //       ),
// // //       bottomNavigationBar: _selectedQuoteItems.isEmpty
// // //           ? null
// // //           : SafeArea(
// // //         top: false,
// // //         child: Container(
// // //           padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
// // //           decoration: const BoxDecoration(
// // //             color: Color(0xFF111111),
// // //             border: Border(
// // //               top: BorderSide(color: Color(0xFF3A2F0B)),
// // //             ),
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               Expanded(
// // //                 child: Text(
// // //                   '${_selectedQuoteItems.length} item(s) • Total: ${_formatPrice(_selectedGrandTotal)}',
// // //                   style: const TextStyle(
// // //                     fontWeight: FontWeight.w800,
// // //                   ),
// // //                 ),
// // //               ),
// // //               FilledButton.icon(
// // //                 onPressed: _openSelectedItemsSheet,
// // //                 icon: const Icon(Icons.shopping_bag_outlined),
// // //                 label: const Text('Review'),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //       body: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             _HeaderSection(
// // //               searchController: _searchController,
// // //               selectedCategory: _selectedCategory,
// // //               categories: _categories,
// // //               visibleCount: _filteredItems.length,
// // //               totalCount: _allItems.length,
// // //               onClearFilters: _clearFilters,
// // //               onCategorySelected: (value) {
// // //                 setState(() {
// // //                   _selectedCategory = value;
// // //                   _applyFilters();
// // //                 });
// // //               },
// // //               profile: widget.profile,
// // //               onLogout: widget.onLogout,
// // //             ),
// // //             Expanded(
// // //               child: AnimatedSwitcher(
// // //                 duration: const Duration(milliseconds: 250),
// // //                 child: _buildBody(theme),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildBody(ThemeData theme) {
// // //     if (_isLoading) {
// // //       return const Center(
// // //         child: CircularProgressIndicator(),
// // //       );
// // //     }
// // //
// // //     if (_errorMessage != null) {
// // //       return Center(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(24),
// // //           child: Container(
// // //             constraints: const BoxConstraints(maxWidth: 520),
// // //             padding: const EdgeInsets.all(20),
// // //             decoration: BoxDecoration(
// // //               color: const Color(0xFF141414),
// // //               borderRadius: BorderRadius.circular(24),
// // //               border: Border.all(color: const Color(0xFF4A3B12)),
// // //               boxShadow: [
// // //                 BoxShadow(
// // //                   color: AppConstants.primaryColor.withOpacity(0.06),
// // //                   blurRadius: 18,
// // //                   offset: const Offset(0, 8),
// // //                 ),
// // //               ],
// // //             ),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 const Icon(
// // //                   Icons.error_outline_rounded,
// // //                   size: 48,
// // //                   color: AppConstants.primaryColor,
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 Text(
// // //                   'Failed to load data',
// // //                   style: theme.textTheme.titleLarge?.copyWith(
// // //                     fontWeight: FontWeight.w800,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 10),
// // //                 Text(
// // //                   _errorMessage!,
// // //                   textAlign: TextAlign.center,
// // //                   style: theme.textTheme.bodyMedium,
// // //                 ),
// // //                 const SizedBox(height: 18),
// // //                 FilledButton.icon(
// // //                   onPressed: _loadItems,
// // //                   icon: const Icon(Icons.refresh_rounded),
// // //                   label: const Text('Retry'),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //
// // //     if (_filteredItems.isEmpty) {
// // //       return RefreshIndicator(
// // //         onRefresh: _loadItems,
// // //         child: ListView(
// // //           physics: const AlwaysScrollableScrollPhysics(),
// // //           children: [
// // //             const SizedBox(height: 140),
// // //             Center(
// // //               child: Container(
// // //                 width: 340,
// // //                 padding: const EdgeInsets.all(22),
// // //                 decoration: BoxDecoration(
// // //                   color: const Color(0xFF141414),
// // //                   borderRadius: BorderRadius.circular(24),
// // //                   border: Border.all(color: const Color(0xFF4A3B12)),
// // //                 ),
// // //                 child: Column(
// // //                   children: [
// // //                     const Icon(
// // //                       Icons.search_off_rounded,
// // //                       size: 52,
// // //                       color: AppConstants.primaryColor,
// // //                     ),
// // //                     const SizedBox(height: 12),
// // //                     Text(
// // //                       'No items found',
// // //                       style: theme.textTheme.titleMedium?.copyWith(
// // //                         fontWeight: FontWeight.w800,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 8),
// // //                     Text(
// // //                       'Try changing the search text or category filter.',
// // //                       textAlign: TextAlign.center,
// // //                       style: theme.textTheme.bodyMedium,
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     }
// // //
// // //     return LayoutBuilder(
// // //       builder: (context, constraints) {
// // //         final crossAxisCount = _gridCount(constraints.maxWidth);
// // //
// // //         if (crossAxisCount == 1) {
// // //           return RefreshIndicator(
// // //             onRefresh: _loadItems,
// // //             child: ListView.separated(
// // //               physics: const AlwaysScrollableScrollPhysics(),
// // //               padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
// // //               itemCount: _filteredItems.length,
// // //               separatorBuilder: (_, __) => const SizedBox(height: 14),
// // //               itemBuilder: (context, index) {
// // //                 return _LuxuryProductCard(
// // //                   item: _filteredItems[index],
// // //                   formatPrice: _formatPrice,
// // //                   onTap: () => _openDetails(_filteredItems[index]),
// // //                   pricePermissions: _pricePermissions,
// // //                   selectedPriceKey:
// // //                   _selectedPriceKeyForItem(_filteredItems[index]),
// // //                   onSelectPrice: (priceKey, priceLabel) {
// // //                     _toggleItemPriceSelection(
// // //                       _filteredItems[index],
// // //                       priceKey,
// // //                       priceLabel,
// // //                     );
// // //                   },
// // //                   isLoadingPermissions: _isLoadingPermissions, canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
// // //                 );
// // //               },
// // //             ),
// // //           );
// // //         }
// // //
// // //         return RefreshIndicator(
// // //           onRefresh: _loadItems,
// // //           child: GridView.builder(
// // //             physics: const AlwaysScrollableScrollPhysics(),
// // //             padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
// // //             itemCount: _filteredItems.length,
// // //             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// // //               crossAxisCount: crossAxisCount,
// // //               mainAxisSpacing: 14,
// // //               crossAxisSpacing: 14,
// // //               childAspectRatio: 0.68,
// // //             ),
// // //             itemBuilder: (context, index) {
// // //               return _LuxuryProductCard(
// // //                 item: _filteredItems[index],
// // //                 formatPrice: _formatPrice,
// // //                 onTap: () => _openDetails(_filteredItems[index]),
// // //                 pricePermissions: _pricePermissions,
// // //                 selectedPriceKey:
// // //                 _selectedPriceKeyForItem(_filteredItems[index]),
// // //                 onSelectPrice: (priceKey, priceLabel) {
// // //                   _toggleItemPriceSelection(
// // //                     _filteredItems[index],
// // //                     priceKey,
// // //                     priceLabel,
// // //                   );
// // //                 },
// // //                 isLoadingPermissions: _isLoadingPermissions, canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
// // //               );
// // //             },
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }
// // //
// // // Map<String, dynamic> _buildPriceListItemPayload(Map<String, dynamic> source) {
// // //   double? toDouble(dynamic value) {
// // //     if (value == null) return null;
// // //     if (value is num) return value.toDouble();
// // //     final raw = value.toString().trim();
// // //     if (raw.isEmpty) return null;
// // //     return double.tryParse(raw);
// // //   }
// // //
// // //   String? toText(dynamic value) {
// // //     if (value == null) return null;
// // //     final raw = value.toString().trim();
// // //     return raw.isEmpty ? null : raw;
// // //   }
// // //
// // //   String? displayPrice = toText(source['display_price']);
// // //   final totalPrice = toDouble(source['total_price']);
// // //
// // //   if ((displayPrice == null || displayPrice.isEmpty) && totalPrice != null) {
// // //     displayPrice = totalPrice == totalPrice.roundToDouble()
// // //         ? totalPrice.toInt().toString()
// // //         : totalPrice.toStringAsFixed(2);
// // //   }
// // //
// // //   return {
// // //     'category_ar': toText(source['category_ar']),
// // //     'description': toText(source['description']),
// // //     'product_name': toText(source['product_name']),
// // //     'item_code': toText(source['item_code']),
// // //     'price_ee': toDouble(source['price_ee']),
// // //     'price_aa': toDouble(source['price_aa']),
// // //     'price_a': toDouble(source['price_a']),
// // //     'price_rr': toDouble(source['price_rr']),
// // //     'price_r': toDouble(source['price_r']),
// // //     'price_art': toDouble(source['price_art']),
// // //     'pot_item_no': toText(source['pot_item_no']),
// // //     'pot_price': toDouble(source['pot_price']),
// // //     'additions': toText(source['additions']),
// // //     'total_price': totalPrice,
// // //     'display_price': displayPrice,
// // //     'image_path': toText(source['image_path']),
// // //     'length': toText(source['length']),
// // //     'width': toText(source['width']),
// // //     'production_time': toText(source['production_time']),
// // //     'is_active': source['is_active'] == null
// // //         ? true
// // //         : source['is_active'] == true ||
// // //         source['is_active'].toString().toLowerCase() == 'true' ||
// // //         source['is_active'].toString() == '1',
// // //   }..removeWhere((key, value) => value == null);
// // // }
// // //
// // // class _HeaderSection extends StatelessWidget {
// // //   final TextEditingController searchController;
// // //   final String? selectedCategory;
// // //   final List<String> categories;
// // //   final int visibleCount;
// // //   final int totalCount;
// // //   final VoidCallback onClearFilters;
// // //   final ValueChanged<String?> onCategorySelected;
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _HeaderSection({
// // //     required this.searchController,
// // //     required this.selectedCategory,
// // //     required this.categories,
// // //     required this.visibleCount,
// // //     required this.totalCount,
// // //     required this.onClearFilters,
// // //     required this.onCategorySelected,
// // //     required this.onLogout,
// // //     required this.profile,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //     final hasFilters =
// // //         selectedCategory != null || searchController.text.trim().isNotEmpty;
// // //
// // //     return Container(
// // //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF111111),
// // //         border: const Border(
// // //           bottom: BorderSide(color: Color(0xFF3A2F0B)),
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: AppConstants.primaryColor.withOpacity(0.05),
// // //             blurRadius: 16,
// // //             offset: const Offset(0, 5),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         children: [
// // //           Row(
// // //             mainAxisAlignment: .spaceBetween,
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   Container(
// // //                     padding: const EdgeInsets.all(3),
// // //                     width: 44,
// // //                     height: 44,
// // //                     decoration: BoxDecoration(
// // //                       borderRadius: BorderRadius.circular(14),
// // //                       gradient: const LinearGradient(
// // //                         colors: [
// // //                           AppConstants.primaryColor,
// // //                           Color(0xFF8C6B16),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     child: Image.asset('assets/icons/logo_black.png'),
// // //                   ),
// // //                   const SizedBox(width: 12),
// // //
// // //                     FittedBox(
// // //                       child: Text(
// // //                         'Price List',
// // //                         style: theme.textTheme.headlineSmall?.copyWith(
// // //                           fontWeight: FontWeight.w900,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                 ],
// // //               ),
// // //               Row(
// // //                   children:[
// // //                     FittedBox(
// // //                       fit: BoxFit.scaleDown,
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.end,
// // //                         children: [
// // //                           FittedBox(
// // //                             fit: BoxFit.scaleDown,
// // //                             child: Text(
// // //                               ((profile['full_name'] ?? '').toString().trim().isNotEmpty
// // //                                   ? profile['full_name']
// // //                                   : profile['email'])
// // //                                   .toString(),
// // //                               style: theme.textTheme.bodyMedium?.copyWith(
// // //                                 fontWeight: FontWeight.w700,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                           Text(
// // //                             (profile['role']).toString().toUpperCase(),
// // //                             style: theme.textTheme.bodySmall?.copyWith(
// // //                               color: AppConstants.primaryColor,
// // //                               fontWeight: FontWeight.w800,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     PopupMenuButton<String>(
// // //                       onSelected: (value) async {
// // //                         if (value == 'logout') {
// // //                           await onLogout();
// // //                         }
// // //                       },
// // //                       itemBuilder: (context) => const [
// // //                         PopupMenuItem<String>(
// // //                           value: 'logout',
// // //                           child: Text('Logout'),
// // //                         ),
// // //                       ],
// // //                       icon: const Icon(Icons.account_circle_outlined),
// // //                     ),
// // //                     if (hasFilters)
// // //                       TextButton.icon(
// // //                         onPressed: onClearFilters,
// // //                         icon: const Icon(Icons.clear_all_rounded),
// // //                         label: const Text('Clear'),
// // //                       ),
// // //                   ]
// // //               )
// // //
// // //             ],
// // //           ),
// // //           const SizedBox(height: 14),
// // //           Container(
// // //             decoration: BoxDecoration(
// // //               borderRadius: BorderRadius.circular(18),
// // //               border: Border.all(color: const Color(0xFF4A3B12)),
// // //               color: const Color(0xFF161616),
// // //             ),
// // //             child: TextField(
// // //               controller: searchController,
// // //               textDirection: TextDirection.rtl,
// // //               style: const TextStyle(color: Color(0xFFF5E7B2)),
// // //               decoration: InputDecoration(
// // //                 hintText: 'Search by name, code, description, or barcode',
// // //                 prefixIcon: const Icon(Icons.search_rounded),
// // //                 suffixIcon: searchController.text.trim().isNotEmpty
// // //                     ? IconButton(
// // //                   onPressed: () => searchController.clear(),
// // //                   icon: const Icon(Icons.close_rounded),
// // //                 )
// // //                     : null,
// // //                 border: InputBorder.none,
// // //                 contentPadding: const EdgeInsets.symmetric(
// // //                   horizontal: 16,
// // //                   vertical: 15,
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 14),
// // //           SizedBox(
// // //             height: 42,
// // //             child: ListView(
// // //               scrollDirection: Axis.horizontal,
// // //               children: [
// // //                 Padding(
// // //                   padding: const EdgeInsetsDirectional.only(end: 8),
// // //                   child: ChoiceChip(
// // //                     label: const Text('All'),
// // //                     selected: selectedCategory == null,
// // //                     onSelected: (_) => onCategorySelected(null),
// // //                   ),
// // //                 ),
// // //                 ...categories.map(
// // //                       (category) => Padding(
// // //                     padding: const EdgeInsetsDirectional.only(end: 8),
// // //                     child: ChoiceChip(
// // //                       label: Text(category),
// // //                       selected: selectedCategory == category,
// // //                       onSelected: (_) {
// // //                         onCategorySelected(
// // //                           selectedCategory == category ? null : category,
// // //                         );
// // //                       },
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           const SizedBox(height: 12),
// // //           Row(
// // //             children: [
// // //               const Icon(
// // //                 Icons.inventory_2_outlined,
// // //                 size: 18,
// // //                 color: AppConstants.primaryColor,
// // //               ),
// // //               const SizedBox(width: 8),
// // //               Text(
// // //                 '$visibleCount / $totalCount items',
// // //                 style: theme.textTheme.bodyMedium?.copyWith(
// // //                   fontWeight: FontWeight.w700,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _LuxuryProductCard extends StatelessWidget {
// // //   final bool canSelectPricesForQuotation;
// // //   final Map<String, dynamic> item;
// // //   final String Function(dynamic value) formatPrice;
// // //   final VoidCallback onTap;
// // //   final Map<String, bool> pricePermissions;
// // //   final String? selectedPriceKey;
// // //   final void Function(String priceKey, String priceLabel) onSelectPrice;
// // //   final bool isLoadingPermissions;
// // //
// // //   const _LuxuryProductCard({
// // //     required this.item,
// // //     required this.formatPrice,
// // //     required this.onTap,
// // //     required this.pricePermissions,
// // //     required this.selectedPriceKey,
// // //     required this.onSelectPrice,
// // //     required this.isLoadingPermissions,
// // //     required this.canSelectPricesForQuotation,
// // //   });
// // //
// // //   String? _imageUrlFromItem(Map<String, dynamic> item) {
// // //     final imagePath = (item['image_path'] ?? '').toString().trim();
// // //     if (imagePath.isEmpty) return null;
// // //
// // //     return Supabase.instance.client.storage
// // //         .from('product-images')
// // //         .getPublicUrl(imagePath);
// // //   }
// // //
// // //   double? _toDouble(dynamic value) {
// // //     if (value == null) return null;
// // //     if (value is num) return value.toDouble();
// // //     return double.tryParse(value.toString());
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //
// // //     final productName = (item['product_name'] ?? '').toString().trim();
// // //     final category = (item['category_ar'] ?? '').toString().trim();
// // //     final description = (item['description'] ?? '').toString().trim();
// // //     final itemCode = (item['item_code'] ?? '').toString().trim();
// // //     final potItemNo = (item['pot_item_no'] ?? '').toString().trim();
// // //     final additions = (item['additions'] ?? '').toString().trim();
// // //     final imageUrl = _imageUrlFromItem(item);
// // //
// // //     final effectivePrice = item['effective_price'];
// // //     final totalPrice = item['total_price'];
// // //
// // //     return Material(
// // //       color: Colors.transparent,
// // //       child: InkWell(
// // //         borderRadius: BorderRadius.circular(26),
// // //         onTap: onTap,
// // //         child: Ink(
// // //           decoration: BoxDecoration(
// // //             borderRadius: BorderRadius.circular(26),
// // //             color: const Color(0xFF141414),
// // //             border: Border.all(color: const Color(0xFF3A2F0B)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: AppConstants.primaryColor.withOpacity(0.06),
// // //                 blurRadius: 18,
// // //                 offset: const Offset(0, 8),
// // //               ),
// // //             ],
// // //           ),
// // //           child: SingleChildScrollView(
// // //             child: Padding(
// // //               padding: const EdgeInsets.all(16),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   if (imageUrl != null) ...[
// // //                     ClipRRect(
// // //                       borderRadius: BorderRadius.circular(18),
// // //                       child: AspectRatio(
// // //                         aspectRatio: 16 / 10,
// // //                         child: CachedNetworkImage(
// // //                           imageUrl: imageUrl,
// // //                           fit: BoxFit.cover,
// // //                           errorWidget: (_, __, ___) => _ImagePlaceholder(),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 14),
// // //                   ],
// // //                   Wrap(
// // //                     spacing: 8,
// // //                     runSpacing: 8,
// // //                     children: [
// // //                       _TagChip(
// // //                         text: category.isEmpty ? 'Uncategorized' : category,
// // //                         background: const Color(0xFF3A2F0B),
// // //                         foreground: const Color(0xFFF5E7B2),
// // //                       ),
// // //                       if (itemCode.isNotEmpty)
// // //                         _TagChip(
// // //                           text: itemCode,
// // //                           background: const Color(0xFF1C1C1C),
// // //                           foreground: AppConstants.primaryColor,
// // //                         ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 14),
// // //                   Text(
// // //                     productName.isEmpty ? 'Unnamed Product' : productName,
// // //                     textDirection: TextDirection.rtl,
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                     style: theme.textTheme.titleLarge?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                       height: 1.25,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   Text(
// // //                     description.isEmpty ? '—' : description,
// // //                     textDirection: TextDirection.rtl,
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                     style: theme.textTheme.bodyMedium?.copyWith(
// // //                       color: const Color(0xFFE0CF90),
// // //                       height: 1.4,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   Container(
// // //                     width: double.infinity,
// // //                     padding: const EdgeInsets.all(14),
// // //                     decoration: BoxDecoration(
// // //                       borderRadius: BorderRadius.circular(18),
// // //                       gradient: const LinearGradient(
// // //                         begin: Alignment.topLeft,
// // //                         end: Alignment.bottomRight,
// // //                         colors: [
// // //                           Color(0xFF3A2F0B),
// // //                           Color(0xFF1C1C1C),
// // //                         ],
// // //                       ),
// // //                       border: Border.all(color: const Color(0xFF5B4916)),
// // //                     ),
// // //                     child: Row(
// // //                       children: [
// // //                         const Icon(
// // //                           Icons.sell_rounded,
// // //                           color: AppConstants.primaryColor,
// // //                         ),
// // //                         const SizedBox(width: 10),
// // //                         Expanded(
// // //                           child: Text(
// // //                             'Effective Price',
// // //                             style: theme.textTheme.titleMedium?.copyWith(
// // //                               fontWeight: FontWeight.w800,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                         Text(
// // //                           formatPrice(effectivePrice),
// // //                           style: theme.textTheme.titleLarge?.copyWith(
// // //                             color: const Color(0xFFFFD95E),
// // //                             fontWeight: FontWeight.w900,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   Text(
// // //                     'Choose selling price',
// // //                     style: theme.textTheme.bodyMedium?.copyWith(
// // //                       fontWeight: FontWeight.w800,
// // //                       color:  AppConstants.primaryColor,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   if (isLoadingPermissions)
// // //                     const Padding(
// // //                       padding: EdgeInsets.symmetric(vertical: 6),
// // //                       child: LinearProgressIndicator(),
// // //                     )
// // //                   else
// // //                     Wrap(
// // //                       spacing: 8,
// // //                       runSpacing: 8,
// // //                       children: _priceOptions.map((option) {
// // //                         final rawValue = item[option.key];
// // //                         final numericValue = _toDouble(rawValue);
// // //                         final exists = numericValue != null;
// // //                         // final allowed =
// // //                         //     (pricePermissions[option.key] ?? true) && exists;
// // //                         final allowed =
// // //                             canSelectPricesForQuotation &&
// // //                                 (pricePermissions[option.key] ?? true) &&
// // //                                 exists;
// // //                         final selected = selectedPriceKey == option.key;
// // //
// // //                         return FilterChip(
// // //                           label: Text(
// // //                             '${option.label} ${exists ? formatPrice(rawValue) : '-'}',
// // //                           ),
// // //                           selected: selected,
// // //                           onSelected: allowed
// // //                               ? (_) => onSelectPrice(option.key, option.label)
// // //                               : null,
// // //                           disabledColor: const Color(0xFF232323),
// // //
// // //                           labelStyle: TextStyle(
// // //                             color: allowed
// // //                                 ? (selected
// // //                                 ? const Color(0xFF0A0A0A)
// // //                                 : const Color(0xFFF5E7B2))
// // //                                 : const Color(0xFF7A7A7A),
// // //                             fontWeight: FontWeight.w700,
// // //                           ),
// // //                           selectedColor: AppConstants.primaryColor,
// // //                           backgroundColor: const Color(0xFF1A1A1A),
// // //                           side: BorderSide(
// // //                             color: selected
// // //                                 ? AppConstants.primaryColor
// // //                                 : const Color(0xFF2F2A18),
// // //                           ),
// // //                         );
// // //                       }).toList(),
// // //                     ),
// // //                   const SizedBox(height: 12),
// // //                   Wrap(
// // //                     spacing: 8,
// // //                     runSpacing: 8,
// // //                     children: [
// // //                       _SmallPriceBox(
// // //                         label: 'TOTAL',
// // //                         value: formatPrice(totalPrice),
// // //                       ),
// // //                       if (potItemNo.isNotEmpty)
// // //                         _SmallInfoBox(label: 'POT', value: potItemNo),
// // //                       if (additions.isNotEmpty)
// // //                         _SmallInfoBox(label: 'ADD', value: additions),
// // //                     ],
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _ProductDetailsSheet extends StatelessWidget {
// // //   final Map<String, dynamic> item;
// // //   final String Function(dynamic value) formatPrice;
// // //
// // //   const _ProductDetailsSheet({
// // //     required this.item,
// // //     required this.formatPrice,
// // //   });
// // //
// // //   String? _imageUrlFromItem(Map<String, dynamic> item) {
// // //     final imagePath = (item['image_path'] ?? '').toString().trim();
// // //     if (imagePath.isEmpty) return null;
// // //
// // //     return Supabase.instance.client.storage
// // //         .from('product-images')
// // //         .getPublicUrl(imagePath);
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //
// // //     final productName = (item['product_name'] ?? '').toString().trim();
// // //     final category = (item['category_ar'] ?? '').toString().trim();
// // //     final description = (item['description'] ?? '').toString().trim();
// // //     final itemCode = (item['item_code'] ?? '').toString().trim();
// // //     final potItemNo = (item['pot_item_no'] ?? '').toString().trim();
// // //     final additions = (item['additions'] ?? '').toString().trim();
// // //     final imageUrl = _imageUrlFromItem(item);
// // //
// // //     return Container(
// // //       decoration: const BoxDecoration(
// // //         color: Color(0xFF121212),
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// // //       ),
// // //       child: SingleChildScrollView(
// // //         padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             if (imageUrl != null) ...[
// // //               ClipRRect(
// // //                 borderRadius: BorderRadius.circular(20),
// // //                 child: AspectRatio(
// // //                   aspectRatio: 16 / 10,
// // //                   child: CachedNetworkImage(
// // //                     imageUrl: imageUrl,
// // //                     fit: BoxFit.contain,
// // //                     errorWidget: (_, __, ___) => _ImagePlaceholder(),
// // //                   ),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 16),
// // //             ],
// // //             Text(
// // //               productName.isEmpty ? 'Unnamed Product' : productName,
// // //               textDirection: TextDirection.rtl,
// // //               style: theme.textTheme.headlineSmall?.copyWith(
// // //                 fontWeight: FontWeight.w900,
// // //                 height: 1.3,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 16),
// // //             Container(
// // //               width: double.infinity,
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 borderRadius: BorderRadius.circular(20),
// // //                 gradient: const LinearGradient(
// // //                   colors: [
// // //                     Color(0xFF3A2F0B),
// // //                     Color(0xFF1B1B1B),
// // //                   ],
// // //                 ),
// // //                 border: Border.all(color: const Color(0xFF5B4916)),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Image.asset(
// // //                     'assets/icons/logo.png',
// // //                     width: 28,
// // //                     height: 28,
// // //                     fit: BoxFit.contain,
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   const Expanded(
// // //                     child: Text(
// // //                       'Effective Price',
// // //                       style: TextStyle(
// // //                         color: Color(0xFFF5E7B2),
// // //                         fontWeight: FontWeight.w800,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   Text(
// // //                     formatPrice(item['effective_price']),
// // //                     style: theme.textTheme.headlineSmall?.copyWith(
// // //                       color: const Color(0xFFFFD95E),
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             const SizedBox(height: 18),
// // //             _DetailsSection(
// // //               title: 'Basic Information',
// // //               children: [
// // //                 _InfoRow(label: 'Category', value: category, rtl: true),
// // //                 _InfoRow(label: 'Description', value: description, rtl: true),
// // //                 _InfoRow(label: 'Item Code', value: itemCode),
// // //                 _InfoRow(label: 'Pot Item No', value: potItemNo),
// // //                 _InfoRow(label: 'Additions', value: additions, rtl: true),
// // //                 _InfoRow(
// // //                   label: 'Display Price',
// // //                   value: (item['display_price'] ?? '').toString(),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),
// // //             _DetailsSection(
// // //               title: 'Prices',
// // //               children: [
// // //                 _PriceRow(label: 'EE', value: formatPrice(item['price_ee'])),
// // //                 _PriceRow(label: 'AA', value: formatPrice(item['price_aa'])),
// // //                 _PriceRow(label: 'A', value: formatPrice(item['price_a'])),
// // //                 _PriceRow(label: 'RR', value: formatPrice(item['price_rr'])),
// // //                 _PriceRow(label: 'R', value: formatPrice(item['price_r'])),
// // //                 _PriceRow(label: 'ART', value: formatPrice(item['price_art'])),
// // //                 _PriceRow(
// // //                   label: 'Pot Price',
// // //                   value: formatPrice(item['pot_price']),
// // //                 ),
// // //                 _PriceRow(
// // //                   label: 'Total Price',
// // //                   value: formatPrice(item['total_price']),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _AddItemSheet extends StatefulWidget {
// // //   const _AddItemSheet();
// // //
// // //   @override
// // //   State<_AddItemSheet> createState() => _AddItemSheetState();
// // // }
// // //
// // // class _AddItemSheetState extends State<_AddItemSheet> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final _categoryController = TextEditingController();
// // //   final _descriptionController = TextEditingController();
// // //   final _productNameController = TextEditingController();
// // //   final _itemCodeController = TextEditingController();
// // //   final _priceEeController = TextEditingController();
// // //   final _priceAaController = TextEditingController();
// // //   final _priceAController = TextEditingController();
// // //   final _priceRrController = TextEditingController();
// // //   final _priceRController = TextEditingController();
// // //   final _priceArtController = TextEditingController();
// // //   final _potItemNoController = TextEditingController();
// // //   final _potPriceController = TextEditingController();
// // //   final _additionsController = TextEditingController();
// // //   final _totalPriceController = TextEditingController();
// // //   final _displayPriceController = TextEditingController();
// // //   final _imagePathController = TextEditingController();
// // //   final _lengthController = TextEditingController();
// // //   final _widthController = TextEditingController();
// // //   final _productionTimeController = TextEditingController();
// // //
// // //   bool _isActive = true;
// // //   bool _isSaving = false;
// // //
// // //   @override
// // //   void dispose() {
// // //     _categoryController.dispose();
// // //     _descriptionController.dispose();
// // //     _productNameController.dispose();
// // //     _itemCodeController.dispose();
// // //     _priceEeController.dispose();
// // //     _priceAaController.dispose();
// // //     _priceAController.dispose();
// // //     _priceRrController.dispose();
// // //     _priceRController.dispose();
// // //     _priceArtController.dispose();
// // //     _potItemNoController.dispose();
// // //     _potPriceController.dispose();
// // //     _additionsController.dispose();
// // //     _totalPriceController.dispose();
// // //     _displayPriceController.dispose();
// // //     _imagePathController.dispose();
// // //     _lengthController.dispose();
// // //     _widthController.dispose();
// // //     _productionTimeController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   double? _toDouble(String value) {
// // //     final raw = value.trim();
// // //     if (raw.isEmpty) return null;
// // //     return double.tryParse(raw);
// // //   }
// // //
// // //   Future<void> _submit() async {
// // //     if (_isSaving) return;
// // //     if (!_formKey.currentState!.validate()) return;
// // //
// // //     final payload = _buildPriceListItemPayload({
// // //       'category_ar': _categoryController.text,
// // //       'description': _descriptionController.text,
// // //       'product_name': _productNameController.text,
// // //       'item_code': _itemCodeController.text,
// // //       'price_ee': _priceEeController.text,
// // //       'price_aa': _priceAaController.text,
// // //       'price_a': _priceAController.text,
// // //       'price_rr': _priceRrController.text,
// // //       'price_r': _priceRController.text,
// // //       'price_art': _priceArtController.text,
// // //       'pot_item_no': _potItemNoController.text,
// // //       'pot_price': _potPriceController.text,
// // //       'additions': _additionsController.text,
// // //       'total_price': _totalPriceController.text,
// // //       'display_price': _displayPriceController.text,
// // //       'image_path': _imagePathController.text,
// // //       'length': _lengthController.text,
// // //       'width': _widthController.text,
// // //       'production_time': _productionTimeController.text,
// // //       'is_active': _isActive,
// // //     });
// // //
// // //     setState(() {
// // //       _isSaving = true;
// // //     });
// // //
// // //     try {
// // //       await Supabase.instance.client.from('price_list_items').insert(payload);
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Item added successfully.')),
// // //       );
// // //       Navigator.of(context).pop(true);
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to add item: $e')),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSaving = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   Widget _field(
// // //       String label,
// // //       TextEditingController controller, {
// // //         bool required = false,
// // //         bool isNumeric = false,
// // //         TextInputType? keyboardType,
// // //         int maxLines = 1,
// // //         String? hint,
// // //       }) {
// // //     return TextFormField(
// // //       controller: controller,
// // //       keyboardType: keyboardType,
// // //       maxLines: maxLines,
// // //       decoration: InputDecoration(
// // //         labelText: label,
// // //         hintText: hint,
// // //       ),
// // //       validator: (value) {
// // //         if (required && (value == null || value.trim().isEmpty)) {
// // //           return '$label is required';
// // //         }
// // //         if (isNumeric &&
// // //             value != null &&
// // //             value.trim().isNotEmpty &&
// // //             _toDouble(value) == null) {
// // //           return 'Invalid number';
// // //         }
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// // //
// // //     return Padding(
// // //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// // //       child: SingleChildScrollView(
// // //         child: Form(
// // //           key: _formKey,
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Text(
// // //                 'Add Item',
// // //                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                   fontWeight: FontWeight.w900,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 16),
// // //               _field('Product Name', _productNameController, required: true),
// // //               const SizedBox(height: 12),
// // //               _field('Category (Arabic)', _categoryController, required: true),
// // //               const SizedBox(height: 12),
// // //               _field('Item Code', _itemCodeController),
// // //               const SizedBox(height: 12),
// // //               _field('Description', _descriptionController, maxLines: 3),
// // //               const SizedBox(height: 12),
// // //               Wrap(
// // //                 runSpacing: 12,
// // //                 spacing: 12,
// // //                 children: [
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price EE',
// // //                       _priceEeController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price AA',
// // //                       _priceAaController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price A',
// // //                       _priceAController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price RR',
// // //                       _priceRrController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price R',
// // //                       _priceRController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Price ART',
// // //                       _priceArtController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Pot Price',
// // //                       _potPriceController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(
// // //                     width: 180,
// // //                     child: _field(
// // //                       'Total Price',
// // //                       _totalPriceController,
// // //                       isNumeric: true,
// // //                       keyboardType: const TextInputType.numberWithOptions(
// // //                         decimal: true,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 12),
// // //               _field('Pot Item No', _potItemNoController),
// // //               const SizedBox(height: 12),
// // //               _field('Additions', _additionsController, maxLines: 2),
// // //               const SizedBox(height: 12),
// // //               _field('Length', _lengthController),
// // //               const SizedBox(height: 12),
// // //               _field('Width', _widthController),
// // //               const SizedBox(height: 12),
// // //               _field('Production Time', _productionTimeController),
// // //               const SizedBox(height: 12),
// // //               _field('Display Price', _displayPriceController),
// // //               const SizedBox(height: 12),
// // //               _field(
// // //                 'Image Path',
// // //                 _imagePathController,
// // //                 hint: 'Bucket path, e.g. flowers/item-1.jpg',
// // //               ),
// // //               const SizedBox(height: 12),
// // //               SwitchListTile(
// // //                 contentPadding: EdgeInsets.zero,
// // //                 value: _isActive,
// // //                 onChanged:
// // //                 _isSaving ? null : (value) => setState(() => _isActive = value),
// // //                 title: const Text('Active'),
// // //               ),
// // //               const SizedBox(height: 16),
// // //               SizedBox(
// // //                 width: double.infinity,
// // //                 child: FilledButton.icon(
// // //                   onPressed: _isSaving ? null : _submit,
// // //                   icon: _isSaving
// // //                       ? const SizedBox(
// // //                     width: 18,
// // //                     height: 18,
// // //                     child: CircularProgressIndicator(strokeWidth: 2),
// // //                   )
// // //                       : const Icon(Icons.save_outlined),
// // //                   label: Text(_isSaving ? 'Saving...' : 'Create Item'),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _BulkAddItemsSheet extends StatefulWidget {
// // //   const _BulkAddItemsSheet();
// // //
// // //   @override
// // //   State<_BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
// // // }
// // //
// // // class _BulkAddItemsSheetState extends State<_BulkAddItemsSheet> {
// // //   final _inputController = TextEditingController();
// // //   bool _isSaving = false;
// // //   int _previewCount = 0;
// // //   String? _previewError;
// // //
// // //   @override
// // //   void dispose() {
// // //     _inputController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   List<Map<String, dynamic>> _parseRows(String raw) {
// // //     final input = raw.trim();
// // //     if (input.isEmpty) {
// // //       throw const FormatException('Paste at least one row.');
// // //     }
// // //
// // //     if (input.startsWith('[')) {
// // //       final decoded = jsonDecode(input);
// // //       if (decoded is! List) {
// // //         throw const FormatException('JSON input must be an array of objects.');
// // //       }
// // //
// // //       final rows = decoded
// // //           .map(
// // //             (e) => _buildPriceListItemPayload(
// // //           Map<String, dynamic>.from(e as Map),
// // //         ),
// // //       )
// // //           .where((e) => e.isNotEmpty)
// // //           .toList();
// // //
// // //       for (final row in rows) {
// // //         if ((row['product_name'] ?? '').toString().trim().isEmpty) {
// // //           throw const FormatException('Each row must include product_name.');
// // //         }
// // //         if ((row['category_ar'] ?? '').toString().trim().isEmpty) {
// // //           throw const FormatException('Each row must include category_ar.');
// // //         }
// // //       }
// // //
// // //       return rows;
// // //     }
// // //
// // //     List<List<dynamic>> table;
// // //
// // //     try {
// // //       table = const CsvDecoder(
// // //         dynamicTyping: false,
// // //       ).convert(input);
// // //     } catch (_) {
// // //       try {
// // //         table = const CsvDecoder(
// // //           fieldDelimiter: '\t',
// // //           dynamicTyping: false,
// // //         ).convert(input);
// // //       } catch (e) {
// // //         throw FormatException('Invalid CSV/TSV format: $e');
// // //       }
// // //     }
// // //
// // //     if (table.length < 2) {
// // //       throw const FormatException(
// // //         'Provide a header row and at least one data row.',
// // //       );
// // //     }
// // //
// // //     final headers = table.first
// // //         .map((e) => e?.toString().trim() ?? '')
// // //         .where((e) => e.isNotEmpty)
// // //         .toList();
// // //
// // //     if (headers.isEmpty) {
// // //       throw const FormatException('Header row is empty.');
// // //     }
// // //
// // //     final rows = <Map<String, dynamic>>[];
// // //
// // //     for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
// // //       final values = table[rowIndex];
// // //
// // //       final rawRow = <String, dynamic>{};
// // //       for (var col = 0; col < headers.length; col++) {
// // //         rawRow[headers[col]] = col < values.length ? values[col] : null;
// // //       }
// // //
// // //       final payload = _buildPriceListItemPayload(rawRow);
// // //
// // //       if ((payload['product_name'] ?? '').toString().trim().isEmpty) {
// // //         throw FormatException(
// // //           'Row ${rowIndex + 1}: product_name is required.',
// // //         );
// // //       }
// // //
// // //       if ((payload['category_ar'] ?? '').toString().trim().isEmpty) {
// // //         throw FormatException(
// // //           'Row ${rowIndex + 1}: category_ar is required.',
// // //         );
// // //       }
// // //
// // //       rows.add(payload);
// // //     }
// // //
// // //     if (rows.isEmpty) {
// // //       throw const FormatException('No valid rows found.');
// // //     }
// // //
// // //     return rows;
// // //   }
// // //
// // //   void _updatePreview() {
// // //     final raw = _inputController.text;
// // //
// // //     if (raw.trim().isEmpty) {
// // //       setState(() {
// // //         _previewCount = 0;
// // //         _previewError = null;
// // //       });
// // //       return;
// // //     }
// // //
// // //     try {
// // //       final rows = _parseRows(raw);
// // //       setState(() {
// // //         _previewCount = rows.length;
// // //         _previewError = null;
// // //       });
// // //     } catch (e) {
// // //       setState(() {
// // //         _previewCount = 0;
// // //         _previewError = e.toString();
// // //       });
// // //     }
// // //   }
// // //
// // //   Future<void> _submit() async {
// // //     if (_isSaving) return;
// // //
// // //     List<Map<String, dynamic>> rows;
// // //     try {
// // //       rows = _parseRows(_inputController.text);
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Invalid bulk input: $e')),
// // //       );
// // //       return;
// // //     }
// // //
// // //     setState(() {
// // //       _isSaving = true;
// // //     });
// // //
// // //     try {
// // //       await Supabase.instance.client.from('price_list_items').insert(rows);
// // //
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('${rows.length} items added successfully.')),
// // //       );
// // //       Navigator.of(context).pop(true);
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Bulk insert failed: $e')),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSaving = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// // //
// // //     return Padding(
// // //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// // //       child: SingleChildScrollView(
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text(
// // //               'Add Bulk Items',
// // //               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                 fontWeight: FontWeight.w900,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 8),
// // //             const Text(
// // //               'Paste CSV, TSV, or JSON rows. CSV parsing supports quoted values properly. Required columns: product_name, category_ar.',
// // //             ),
// // //             const SizedBox(height: 12),
// // //             Container(
// // //               width: double.infinity,
// // //               padding: const EdgeInsets.all(12),
// // //               decoration: BoxDecoration(
// // //                 color: const Color(0xFF171717),
// // //                 borderRadius: BorderRadius.circular(16),
// // //                 border: Border.all(color: const Color(0xFF3A2F0B)),
// // //               ),
// // //               child: const SelectableText(
// // //                 'Example CSV\n'
// // //                     'product_name,category_ar,item_code,total_price,is_active\n'
// // //                     '"Rose Box, Large",ورد,RB-100,125,true\n\n'
// // //                     'Example JSON\n'
// // //                     '[{"product_name":"Rose Box","category_ar":"ورد","item_code":"RB-100","total_price":125}]',
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             TextField(
// // //               controller: _inputController,
// // //               onChanged: (_) => _updatePreview(),
// // //               minLines: 10,
// // //               maxLines: 18,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Bulk rows',
// // //                 alignLabelWithHint: true,
// // //                 hintText: 'Paste CSV / TSV / JSON here',
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             if (_previewError != null)
// // //               Text(
// // //                 _previewError!,
// // //                 style: const TextStyle(color: Color(0xFFFFC7CE)),
// // //               )
// // //             else if (_previewCount > 0)
// // //               Text(
// // //                 'Ready to insert $_previewCount item(s).',
// // //                 style: const TextStyle(
// // //                   color: AppConstants.primaryColor,
// // //                   fontWeight: FontWeight.w700,
// // //                 ),
// // //               ),
// // //             const SizedBox(height: 16),
// // //             SizedBox(
// // //               width: double.infinity,
// // //               child: FilledButton.icon(
// // //                 onPressed:
// // //                 (_isSaving || _previewCount == 0 || _previewError != null)
// // //                     ? null
// // //                     : _submit,
// // //                 icon: _isSaving
// // //                     ? const SizedBox(
// // //                   width: 18,
// // //                   height: 18,
// // //                   child: CircularProgressIndicator(strokeWidth: 2),
// // //                 )
// // //                     : const Icon(Icons.playlist_add_check_circle_outlined),
// // //                 label: Text(_isSaving ? 'Importing...' : 'Insert Bulk Items'),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CreateQuotationSheet extends StatefulWidget {
// // //   final double subtotal;
// // //   final String Function(dynamic value) formatPrice;
// // //   final Map<String, dynamic> profile;
// // //
// // //   const _CreateQuotationSheet({
// // //     required this.subtotal,
// // //     required this.formatPrice,
// // //     required this.profile,
// // //   });
// // //
// // //   @override
// // //   State<_CreateQuotationSheet> createState() => _CreateQuotationSheetState();
// // // }
// // //
// // // class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
// // //   final _formKey = GlobalKey<FormState>();
// // //
// // //   final _customerNameController = TextEditingController();
// // //   final _companyNameController = TextEditingController();
// // //   final _customerTrnController = TextEditingController();
// // //   final _customerPhoneController = TextEditingController();
// // //   final _salespersonNameController = TextEditingController();
// // //   final _salespersonContactController = TextEditingController();
// // //   final _notesController = TextEditingController();
// // //
// // //   final _deliveryFeeController = TextEditingController(text: '0');
// // //   final _installationFeeController = TextEditingController(text: '0');
// // //   final _additionalDetailsFeeController = TextEditingController(text: '0');
// // //   final _vatPercentController = TextEditingController(text: '5');
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     final fullName = (widget.profile['full_name'] ?? '').toString().trim();
// // //     final email = (widget.profile['email'] ?? '').toString().trim();
// // //     _salespersonNameController.text = fullName;
// // //     _salespersonContactController.text = email;
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _customerNameController.dispose();
// // //     _companyNameController.dispose();
// // //     _customerTrnController.dispose();
// // //     _customerPhoneController.dispose();
// // //     _salespersonNameController.dispose();
// // //     _salespersonContactController.dispose();
// // //     _notesController.dispose();
// // //     _deliveryFeeController.dispose();
// // //     _installationFeeController.dispose();
// // //     _additionalDetailsFeeController.dispose();
// // //     _vatPercentController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   double _parseNumber(String value) {
// // //     return double.tryParse(value.trim()) ?? 0;
// // //   }
// // //
// // //   double get _deliveryFee => _parseNumber(_deliveryFeeController.text);
// // //   double get _installationFee => _parseNumber(_installationFeeController.text);
// // //   double get _additionalDetailsFee =>
// // //       _parseNumber(_additionalDetailsFeeController.text);
// // //   double get _vatPercent => _parseNumber(_vatPercentController.text);
// // //
// // //   double get _taxableTotal =>
// // //       widget.subtotal + _deliveryFee + _installationFee + _additionalDetailsFee;
// // //
// // //   double get _vatAmount => _taxableTotal * (_vatPercent / 100);
// // //
// // //   double get _netTotal => _taxableTotal + _vatAmount;
// // //
// // //   String? _validateNumber(String? value) {
// // //     if (value == null || value.trim().isEmpty) return null;
// // //     if (double.tryParse(value.trim()) == null) return 'Invalid number';
// // //     return null;
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// // //
// // //     return Padding(
// // //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// // //       child: SingleChildScrollView(
// // //         child: Form(
// // //           key: _formKey,
// // //           child: StatefulBuilder(
// // //             builder: (context, setLocalState) {
// // //               return Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     'Create Quotation',
// // //                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 16),
// // //                   TextFormField(
// // //                     controller: _customerNameController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Customer Name',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _companyNameController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Company Name',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _customerTrnController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Customer TRN',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _customerPhoneController,
// // //                     keyboardType: TextInputType.phone,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Customer Phone',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     enabled: false,
// // //                     controller: _salespersonNameController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Salesperson Name',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                       enabled: false,
// // //                     controller: _salespersonContactController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Salesperson Contact',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _deliveryFeeController,
// // //                     keyboardType:
// // //                     const TextInputType.numberWithOptions(decimal: true),
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Delivery Fee',
// // //                     ),
// // //                     validator: _validateNumber,
// // //                     onChanged: (_) => setLocalState(() {}),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _installationFeeController,
// // //                     keyboardType:
// // //                     const TextInputType.numberWithOptions(decimal: true),
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Installation Fee',
// // //                     ),
// // //                     validator: _validateNumber,
// // //                     onChanged: (_) => setLocalState(() {}),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _additionalDetailsFeeController,
// // //                     keyboardType:
// // //                     const TextInputType.numberWithOptions(decimal: true),
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Additional Details Fee',
// // //                     ),
// // //                     validator: _validateNumber,
// // //                     onChanged: (_) => setLocalState(() {}),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _vatPercentController,
// // //                     keyboardType:
// // //                     const TextInputType.numberWithOptions(decimal: true),
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'VAT Percent',
// // //                     ),
// // //                     validator: _validateNumber,
// // //                     onChanged: (_) => setLocalState(() {}),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   TextFormField(
// // //                     controller: _notesController,
// // //                     maxLines: 4,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Notes',
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 16),
// // //                   Container(
// // //                     width: double.infinity,
// // //                     padding: const EdgeInsets.all(16),
// // //                     decoration: BoxDecoration(
// // //                       color: const Color(0xFF171717),
// // //                       borderRadius: BorderRadius.circular(16),
// // //                       border: Border.all(color: const Color(0xFF3A2F0B)),
// // //                     ),
// // //                     child: Column(
// // //                       children: [
// // //                         Row(
// // //                           children: [
// // //                             const Expanded(child: Text('Subtotal')),
// // //                             Text(widget.formatPrice(widget.subtotal)),
// // //                           ],
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         Row(
// // //                           children: [
// // //                             const Expanded(child: Text('Taxable Total')),
// // //                             Text(widget.formatPrice(_taxableTotal)),
// // //                           ],
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         Row(
// // //                           children: [
// // //                             Expanded(
// // //                               child: Text(
// // //                                 'VAT (${widget.formatPrice(_vatPercent)}%)',
// // //                               ),
// // //                             ),
// // //                             Text(widget.formatPrice(_vatAmount)),
// // //                           ],
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         Row(
// // //                           children: [
// // //                             const Expanded(
// // //                               child: Text(
// // //                                 'Net Total',
// // //                                 style: TextStyle(fontWeight: FontWeight.w900),
// // //                               ),
// // //                             ),
// // //                             Text(
// // //                               widget.formatPrice(_netTotal),
// // //                               style: const TextStyle(
// // //                                 color: Color(0xFFFFD95E),
// // //                                 fontWeight: FontWeight.w900,
// // //                                 fontSize: 18,
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 16),
// // //                   SizedBox(
// // //                     width: double.infinity,
// // //                     child: FilledButton.icon(
// // //                       onPressed: () {
// // //                         if (!_formKey.currentState!.validate()) return;
// // //
// // //                         Navigator.pop(
// // //                           context,
// // //                           _QuotationDraft(
// // //                             customerName: _customerNameController.text.trim(),
// // //                             companyName: _companyNameController.text.trim(),
// // //                             customerTrn: _customerTrnController.text.trim(),
// // //                             customerPhone: _customerPhoneController.text.trim(),
// // //                             salespersonName:
// // //                             _salespersonNameController.text.trim(),
// // //                             salespersonContact:
// // //                             _salespersonContactController.text.trim(),
// // //                             notes: _notesController.text.trim(),
// // //                             deliveryFee: _deliveryFee,
// // //                             installationFee: _installationFee,
// // //                             additionalDetailsFee: _additionalDetailsFee,
// // //                             vatPercent: _vatPercent,
// // //                             salespersonPhone: widget.profile["phone"],
// // //                           ),
// // //                         );
// // //                       },
// // //                       icon: const Icon(Icons.save_outlined),
// // //                       label: const Text('Save Quotation'),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _DetailsSection extends StatelessWidget {
// // //   final String title;
// // //   final List<Widget> children;
// // //
// // //   const _DetailsSection({
// // //     required this.title,
// // //     required this.children,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF151515),
// // //         borderRadius: BorderRadius.circular(22),
// // //         border: Border.all(color: const Color(0xFF3A2F0B)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             title,
// // //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
// // //               color: AppConstants.primaryColor,
// // //               fontWeight: FontWeight.w900,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 12),
// // //           ...children,
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _InfoRow extends StatelessWidget {
// // //   final String label;
// // //   final String value;
// // //   final bool rtl;
// // //
// // //   const _InfoRow({
// // //     required this.label,
// // //     required this.value,
// // //     this.rtl = false,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (value.trim().isEmpty) return const SizedBox.shrink();
// // //
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 7),
// // //       child: Row(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           SizedBox(
// // //             width: 110,
// // //             child: Text(
// // //               label,
// // //               style: const TextStyle(
// // //                 color: AppConstants.primaryColor,
// // //                 fontWeight: FontWeight.w700,
// // //               ),
// // //             ),
// // //           ),
// // //           const SizedBox(width: 8),
// // //           Expanded(
// // //             child: Text(
// // //               value,
// // //               textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
// // //               style: const TextStyle(
// // //                 color: Color(0xFFF5E7B2),
// // //                 height: 1.35,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _PriceRow extends StatelessWidget {
// // //   final String label;
// // //   final String value;
// // //
// // //   const _PriceRow({
// // //     required this.label,
// // //     required this.value,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (value == '-' || value.trim().isEmpty) {
// // //       return const SizedBox.shrink();
// // //     }
// // //
// // //     return Container(
// // //       margin: const EdgeInsets.symmetric(vertical: 5),
// // //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF1A1A1A),
// // //         borderRadius: BorderRadius.circular(14),
// // //         border: Border.all(color: const Color(0xFF2F2A18)),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Expanded(
// // //             child: Text(
// // //               label,
// // //               style: const TextStyle(
// // //                 color: AppConstants.primaryColor,
// // //                 fontWeight: FontWeight.w800,
// // //               ),
// // //             ),
// // //           ),
// // //           Text(
// // //             value,
// // //             style: const TextStyle(
// // //               color: Color(0xFFF5E7B2),
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _TagChip extends StatelessWidget {
// // //   final String text;
// // //   final Color background;
// // //   final Color foreground;
// // //
// // //   const _TagChip({
// // //     required this.text,
// // //     required this.background,
// // //     required this.foreground,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
// // //       decoration: BoxDecoration(
// // //         color: background,
// // //         borderRadius: BorderRadius.circular(999),
// // //         border: Border.all(color: const Color(0xFF5B4916)),
// // //       ),
// // //       child: Text(
// // //         text,
// // //         style: TextStyle(
// // //           color: foreground,
// // //           fontWeight: FontWeight.w700,
// // //           fontSize: 12,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _SmallPriceBox extends StatelessWidget {
// // //   final String label;
// // //   final String value;
// // //
// // //   const _SmallPriceBox({
// // //     required this.label,
// // //     required this.value,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (value == '-') return const SizedBox.shrink();
// // //
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF1A1A1A),
// // //         borderRadius: BorderRadius.circular(14),
// // //         border: Border.all(color: const Color(0xFF2F2A18)),
// // //       ),
// // //       child: Column(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(
// // //               color: AppConstants.primaryColor,
// // //               fontWeight: FontWeight.w800,
// // //               fontSize: 11,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(
// // //             value,
// // //             style: const TextStyle(
// // //               color: Color(0xFFF5E7B2),
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _SmallInfoBox extends StatelessWidget {
// // //   final String label;
// // //   final String value;
// // //
// // //   const _SmallInfoBox({
// // //     required this.label,
// // //     required this.value,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (value.trim().isEmpty) return const SizedBox.shrink();
// // //
// // //     return Container(
// // //       constraints: const BoxConstraints(maxWidth: 160),
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF1A1A1A),
// // //         borderRadius: BorderRadius.circular(14),
// // //         border: Border.all(color: const Color(0xFF2F2A18)),
// // //       ),
// // //       child: Column(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(
// // //               color: AppConstants.primaryColor,
// // //               fontWeight: FontWeight.w800,
// // //               fontSize: 11,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(
// // //             value,
// // //             maxLines: 1,
// // //             overflow: TextOverflow.ellipsis,
// // //             textDirection: TextDirection.rtl,
// // //             style: const TextStyle(
// // //               color: Color(0xFFF5E7B2),
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class PricePermissionsScreen extends StatefulWidget {
// // //   const PricePermissionsScreen({super.key});
// // //
// // //   @override
// // //   State<PricePermissionsScreen> createState() =>
// // //       _PricePermissionsScreenState();
// // // }
// // //
// // // class _PricePermissionsScreenState extends State<PricePermissionsScreen> {
// // //   final SupabaseClient _supabase = Supabase.instance.client;
// // //
// // //   bool _isLoading = true;
// // //   bool _isSavingGlobal = false;
// // //   String? _error;
// // //
// // //   bool _globalBlockAll = false;
// // //   final Set<String> _globalBlockedKeys = {};
// // //
// // //   List<Map<String, dynamic>> _users = [];
// // //   Map<String, bool> _userBlockAll = {};
// // //   Map<String, Set<String>> _userBlockedKeys = {};
// // //
// // //   final TextEditingController _userSearchController = TextEditingController();
// // //   final Set<String> _savingUserIds = {};
// // //   bool _isSavingAllUsers = false;
// // //   String _userSearchQuery = '';
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _userSearchController.addListener(() {
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _userSearchQuery = _userSearchController.text.trim().toLowerCase();
// // //       });
// // //     });
// // //     _loadData();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _userSearchController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   Future<void> _loadData() async {
// // //     setState(() {
// // //       _isLoading = true;
// // //       _error = null;
// // //     });
// // //
// // //     try {
// // //       final settingsResponse = await _supabase
// // //           .from('price_permission_settings')
// // //           .select('id, block_all_prices')
// // //           .eq('id', 1)
// // //           .maybeSingle();
// // //
// // //       final globalBlockedResponse = await _supabase
// // //           .from('global_blocked_price_keys')
// // //           .select('price_key');
// // //
// // //       final usersResponse = await _supabase
// // //           .from('profiles')
// // //           .select('id, email, full_name, role, is_active')
// // //           .order('full_name', ascending: true);
// // //
// // //       final profileAccessResponse = await _supabase
// // //           .from('profile_price_access')
// // //           .select('profile_id, block_all_prices');
// // //
// // //       final profileBlockedResponse = await _supabase
// // //           .from('profile_blocked_price_keys')
// // //           .select('profile_id, price_key');
// // //
// // //       final users = (usersResponse as List)
// // //           .map((e) => Map<String, dynamic>.from(e as Map))
// // //           .where((e) => (e['role'] ?? '').toString() == 'sales')
// // //           .toList();
// // //
// // //       final globalBlocked = <String>{};
// // //       for (final row in (globalBlockedResponse as List)) {
// // //         final map = Map<String, dynamic>.from(row as Map);
// // //         final key = (map['price_key'] ?? '').toString();
// // //         if (key.isNotEmpty) globalBlocked.add(key);
// // //       }
// // //
// // //       final userBlockAll = <String, bool>{};
// // //       for (final row in (profileAccessResponse as List)) {
// // //         final map = Map<String, dynamic>.from(row as Map);
// // //         final profileId = (map['profile_id'] ?? '').toString();
// // //         if (profileId.isEmpty) continue;
// // //         userBlockAll[profileId] = map['block_all_prices'] == true;
// // //       }
// // //
// // //       final userBlockedKeys = <String, Set<String>>{};
// // //       for (final row in (profileBlockedResponse as List)) {
// // //         final map = Map<String, dynamic>.from(row as Map);
// // //         final profileId = (map['profile_id'] ?? '').toString();
// // //         final key = (map['price_key'] ?? '').toString();
// // //         if (profileId.isEmpty || key.isEmpty) continue;
// // //         userBlockedKeys.putIfAbsent(profileId, () => <String>{}).add(key);
// // //       }
// // //
// // //       for (final user in users) {
// // //         final id = (user['id'] ?? '').toString();
// // //         userBlockAll.putIfAbsent(id, () => false);
// // //         userBlockedKeys.putIfAbsent(id, () => <String>{});
// // //       }
// // //
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _globalBlockAll = (settingsResponse?['block_all_prices'] == true);
// // //         _globalBlockedKeys
// // //           ..clear()
// // //           ..addAll(globalBlocked);
// // //         _users = users;
// // //         _userBlockAll = userBlockAll;
// // //         _userBlockedKeys = userBlockedKeys;
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _error = e.toString();
// // //         _isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   Future<void> _saveGlobalSettings() async {
// // //     if (_isSavingGlobal) return;
// // //
// // //     setState(() {
// // //       _isSavingGlobal = true;
// // //     });
// // //
// // //     try {
// // //       await _supabase.from('price_permission_settings').upsert({
// // //         'id': 1,
// // //         'block_all_prices': _globalBlockAll,
// // //       });
// // //
// // //       await _supabase.from('global_blocked_price_keys').delete().neq('id', 0);
// // //
// // //       if (_globalBlockedKeys.isNotEmpty) {
// // //         await _supabase.from('global_blocked_price_keys').insert(
// // //           _globalBlockedKeys.map((key) => {'price_key': key}).toList(),
// // //         );
// // //       }
// // //
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Global price permissions saved.')),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to save global settings: $e')),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSavingGlobal = false;
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _saveUserPermissions(String profileId) async {
// // //     if (_savingUserIds.contains(profileId)) return;
// // //
// // //     setState(() {
// // //       _savingUserIds.add(profileId);
// // //     });
// // //
// // //     try {
// // //       await _supabase.from('profile_price_access').upsert({
// // //         'profile_id': profileId,
// // //         'block_all_prices': _userBlockAll[profileId] ?? false,
// // //       });
// // //
// // //       await _supabase
// // //           .from('profile_blocked_price_keys')
// // //           .delete()
// // //           .eq('profile_id', profileId);
// // //
// // //       final blocked = _userBlockedKeys[profileId] ?? <String>{};
// // //       if (blocked.isNotEmpty) {
// // //         await _supabase.from('profile_blocked_price_keys').insert(
// // //           blocked
// // //               .map(
// // //                 (key) => {
// // //               'profile_id': profileId,
// // //               'price_key': key,
// // //             },
// // //           )
// // //               .toList(),
// // //         );
// // //       }
// // //
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('User price permissions saved.')),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to save user permissions: $e')),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _savingUserIds.remove(profileId);
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   String _userDisplayName(Map<String, dynamic> user) {
// // //     final fullName = (user['full_name'] ?? '').toString().trim();
// // //     final email = (user['email'] ?? '').toString().trim();
// // //     if (fullName.isNotEmpty) return fullName;
// // //     if (email.isNotEmpty) return email;
// // //     return 'Unknown User';
// // //   }
// // //
// // //   List<Map<String, dynamic>> get _filteredUsers {
// // //     if (_userSearchQuery.isEmpty) return _users;
// // //
// // //     return _users.where((user) {
// // //       final name = _userDisplayName(user).toLowerCase();
// // //       final email = (user['email'] ?? '').toString().trim().toLowerCase();
// // //       return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
// // //     }).toList();
// // //   }
// // //
// // //   Future<void> _saveAllUserPermissions() async {
// // //     if (_isSavingAllUsers) return;
// // //
// // //     setState(() {
// // //       _isSavingAllUsers = true;
// // //     });
// // //
// // //     try {
// // //       for (final user in _filteredUsers) {
// // //         final profileId = (user['id'] ?? '').toString();
// // //         if (profileId.isEmpty) continue;
// // //
// // //         setState(() {
// // //           _savingUserIds.add(profileId);
// // //         });
// // //
// // //         await _supabase.from('profile_price_access').upsert({
// // //           'profile_id': profileId,
// // //           'block_all_prices': _userBlockAll[profileId] ?? false,
// // //         });
// // //
// // //         await _supabase
// // //             .from('profile_blocked_price_keys')
// // //             .delete()
// // //             .eq('profile_id', profileId);
// // //
// // //         final blocked = _userBlockedKeys[profileId] ?? <String>{};
// // //         if (blocked.isNotEmpty) {
// // //           await _supabase.from('profile_blocked_price_keys').insert(
// // //             blocked
// // //                 .map(
// // //                   (key) => {
// // //                 'profile_id': profileId,
// // //                 'price_key': key,
// // //               },
// // //             )
// // //                 .toList(),
// // //           );
// // //         }
// // //
// // //         if (mounted) {
// // //           setState(() {
// // //             _savingUserIds.remove(profileId);
// // //           });
// // //         }
// // //       }
// // //
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text(
// // //             'Saved ${_filteredUsers.length} user permission set(s).',
// // //           ),
// // //         ),
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to save all user settings: $e')),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSavingAllUsers = false;
// // //           _savingUserIds.clear();
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFF0A0A0A),
// // //       appBar: AppBar(
// // //         title: const Text('Price Permissions'),
// // //         backgroundColor: const Color(0xFF111111),
// // //       ),
// // //       body: _isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : _error != null
// // //           ? Center(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(24),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Text(
// // //                 _error!,
// // //                 textAlign: TextAlign.center,
// // //               ),
// // //               const SizedBox(height: 12),
// // //               FilledButton(
// // //                 onPressed: _loadData,
// // //                 child: const Text('Retry'),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       )
// // //           : RefreshIndicator(
// // //         onRefresh: _loadData,
// // //         child: ListView(
// // //           padding: const EdgeInsets.all(16),
// // //           children: [
// // //             Container(
// // //               padding: const EdgeInsets.all(16),
// // //               decoration: BoxDecoration(
// // //                 color: const Color(0xFF141414),
// // //                 borderRadius: BorderRadius.circular(20),
// // //                 border: Border.all(color: const Color(0xFF3A2F0B)),
// // //               ),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     'Global Controls',
// // //                     style: theme.textTheme.titleLarge?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 12),
// // //                   SwitchListTile(
// // //                     contentPadding: EdgeInsets.zero,
// // //                     title:
// // //                     const Text('Block all prices for all users'),
// // //                     value: _globalBlockAll,
// // //                     onChanged: (value) {
// // //                       setState(() {
// // //                         _globalBlockAll = value;
// // //                       });
// // //                     },
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   Text(
// // //                     'Blocked price keys for all users',
// // //                     style: theme.textTheme.titleMedium?.copyWith(
// // //                       fontWeight: FontWeight.w800,
// // //                       color: AppConstants.primaryColor,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 10),
// // //                   Wrap(
// // //                     spacing: 8,
// // //                     runSpacing: 8,
// // //                     children: _priceOptions.map((option) {
// // //                       final blocked =
// // //                       _globalBlockedKeys.contains(option.key);
// // //
// // //                       return FilterChip(
// // //                         label: Text(option.label),
// // //                         selected: blocked,
// // //                         onSelected: (selected) {
// // //                           setState(() {
// // //                             if (selected) {
// // //                               _globalBlockedKeys.add(option.key);
// // //                             } else {
// // //                               _globalBlockedKeys.remove(option.key);
// // //                             }
// // //                           });
// // //                         },
// // //                         selectedColor: AppConstants.primaryColor,
// // //                         backgroundColor: const Color(0xFF1A1A1A),
// // //                         labelStyle: TextStyle(
// // //                           color: blocked
// // //                               ? const Color(0xFF0A0A0A)
// // //                               : const Color(0xFFF5E7B2),
// // //                           fontWeight: FontWeight.w800,
// // //                         ),
// // //                       );
// // //                     }).toList(),
// // //                   ),
// // //                   const SizedBox(height: 16),
// // //                   SizedBox(
// // //                     width: double.infinity,
// // //                     child: FilledButton.icon(
// // //                       onPressed:
// // //                       _isSavingGlobal ? null : _saveGlobalSettings,
// // //                       icon: _isSavingGlobal
// // //                           ? const SizedBox(
// // //                         width: 18,
// // //                         height: 18,
// // //                         child: CircularProgressIndicator(
// // //                           strokeWidth: 2,
// // //                         ),
// // //                       )
// // //                           : const Icon(Icons.save_outlined),
// // //                       label: Text(
// // //                         _isSavingGlobal
// // //                             ? 'Saving...'
// // //                             : 'Save Global Settings',
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             const SizedBox(height: 18),
// // //             Text(
// // //               'Per-User Controls',
// // //               style: theme.textTheme.titleLarge?.copyWith(
// // //                 fontWeight: FontWeight.w900,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             TextField(
// // //               controller: _userSearchController,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Search users',
// // //                 hintText: 'Search by name or email',
// // //                 prefixIcon: Icon(Icons.search_rounded),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: Text(
// // //                     '${_filteredUsers.length} user(s)',
// // //                     style: theme.textTheme.bodyMedium?.copyWith(
// // //                       fontWeight: FontWeight.w700,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 FilledButton.icon(
// // //                   onPressed:
// // //                   (_isSavingAllUsers || _filteredUsers.isEmpty)
// // //                       ? null
// // //                       : _saveAllUserPermissions,
// // //                   icon: _isSavingAllUsers
// // //                       ? const SizedBox(
// // //                     width: 18,
// // //                     height: 18,
// // //                     child: CircularProgressIndicator(
// // //                         strokeWidth: 2),
// // //                   )
// // //                       : const Icon(Icons.save_outlined),
// // //                   label: Text(_isSavingAllUsers
// // //                       ? 'Saving...'
// // //                       : 'Save All Visible Users'),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 12),
// // //             ..._filteredUsers.map((user) {
// // //               final profileId = (user['id'] ?? '').toString();
// // //               final blockedKeys =
// // //                   _userBlockedKeys[profileId] ?? <String>{};
// // //               final blockAll = _userBlockAll[profileId] ?? false;
// // //               final isActive = user['is_active'] == true;
// // //
// // //               return Container(
// // //                 margin: const EdgeInsets.only(bottom: 14),
// // //                 padding: const EdgeInsets.all(16),
// // //                 decoration: BoxDecoration(
// // //                   color: const Color(0xFF141414),
// // //                   borderRadius: BorderRadius.circular(20),
// // //                   border: Border.all(color: const Color(0xFF3A2F0B)),
// // //                 ),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Row(
// // //                       children: [
// // //                         Expanded(
// // //                           child: Column(
// // //                             crossAxisAlignment:
// // //                             CrossAxisAlignment.start,
// // //                             children: [
// // //                               Text(
// // //                                 _userDisplayName(user),
// // //                                 style: theme.textTheme.titleMedium
// // //                                     ?.copyWith(
// // //                                   fontWeight: FontWeight.w900,
// // //                                 ),
// // //                               ),
// // //                               const SizedBox(height: 4),
// // //                               Text(
// // //                                 (user['email'] ?? '').toString(),
// // //                                 style: theme.textTheme.bodySmall,
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         Container(
// // //                           padding: const EdgeInsets.symmetric(
// // //                             horizontal: 10,
// // //                             vertical: 6,
// // //                           ),
// // //                           decoration: BoxDecoration(
// // //                             color: isActive
// // //                                 ? const Color(0xFF1F3A1F)
// // //                                 : const Color(0xFF3A1F1F),
// // //                             borderRadius: BorderRadius.circular(999),
// // //                           ),
// // //                           child: Text(
// // //                             isActive ? 'ACTIVE' : 'INACTIVE',
// // //                             style: const TextStyle(
// // //                               fontWeight: FontWeight.w800,
// // //                               fontSize: 11,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     const SizedBox(height: 12),
// // //                     SwitchListTile(
// // //                       contentPadding: EdgeInsets.zero,
// // //                       title: const Text(
// // //                           'Block all prices for this user'),
// // //                       value: blockAll,
// // //                       onChanged: (value) {
// // //                         setState(() {
// // //                           _userBlockAll[profileId] = value;
// // //                         });
// // //                       },
// // //                     ),
// // //                     const SizedBox(height: 8),
// // //                     Text(
// // //                       'Blocked price keys for this user',
// // //                       style: theme.textTheme.titleSmall?.copyWith(
// // //                         fontWeight: FontWeight.w800,
// // //                         color: AppConstants.primaryColor,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 10),
// // //                     Wrap(
// // //                       spacing: 8,
// // //                       runSpacing: 8,
// // //                       children: _priceOptions.map((option) {
// // //                         final blocked =
// // //                         blockedKeys.contains(option.key);
// // //
// // //                         return FilterChip(
// // //                           label: Text(option.label),
// // //                           selected: blocked,
// // //                           onSelected: (selected) {
// // //                             setState(() {
// // //                               final set =
// // //                               _userBlockedKeys.putIfAbsent(
// // //                                 profileId,
// // //                                     () => <String>{},
// // //                               );
// // //                               if (selected) {
// // //                                 set.add(option.key);
// // //                               } else {
// // //                                 set.remove(option.key);
// // //                               }
// // //                             });
// // //                           },
// // //                           selectedColor: AppConstants.primaryColor,
// // //                           backgroundColor: const Color(0xFF1A1A1A),
// // //                           labelStyle: TextStyle(
// // //                             color: blocked
// // //                                 ? const Color(0xFF0A0A0A)
// // //                                 : const Color(0xFFF5E7B2),
// // //                             fontWeight: FontWeight.w800,
// // //                           ),
// // //                         );
// // //                       }).toList(),
// // //                     ),
// // //                     const SizedBox(height: 16),
// // //                     SizedBox(
// // //                       width: double.infinity,
// // //                       child: OutlinedButton.icon(
// // //                         onPressed: _savingUserIds.contains(profileId)
// // //                             ? null
// // //                             : () => _saveUserPermissions(profileId),
// // //                         icon: _savingUserIds.contains(profileId)
// // //                             ? const SizedBox(
// // //                           width: 18,
// // //                           height: 18,
// // //                           child: CircularProgressIndicator(
// // //                               strokeWidth: 2),
// // //                         )
// // //                             : const Icon(Icons.save_outlined),
// // //                         label: Text(
// // //                           _savingUserIds.contains(profileId)
// // //                               ? 'Saving...'
// // //                               : 'Save User Settings',
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             }),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _ImagePlaceholder extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       color: const Color(0xFF1A1A1A),
// // //       alignment: Alignment.center,
// // //       child: const Icon(
// // //         Icons.image_not_supported_outlined,
// // //         color: AppConstants.primaryColor,
// // //         size: 34,
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// //
// //
// // //==========================================
// // import 'dart:async';
// // import 'dart:convert';
// //
// // import 'package:FlowerCenterCrm/user_role_management_screen.dart';
// // import 'package:cached_network_image/cached_network_image.dart';
// // import 'package:csv/csv.dart';
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // import 'container_processor_screen.dart';
// // import 'core/constants/app_constants.dart';
// // import 'quotation_details_screen.dart';
// // import 'quotation_list_screen.dart';
// // import 'scanner.dart';
// //
// // // ---------------------------------------------------------------------------
// // // Price option metadata
// // // ---------------------------------------------------------------------------
// //
// // class _PriceOptionMeta {
// //   final String key;
// //   final String label;
// //   const _PriceOptionMeta(this.key, this.label);
// // }
// //
// // const List<_PriceOptionMeta> _priceOptions = [
// //   _PriceOptionMeta('price_ee', 'EE'),
// //   _PriceOptionMeta('price_aa', 'AA'),
// //   _PriceOptionMeta('price_a', 'A'),
// //   _PriceOptionMeta('price_rr', 'RR'),
// //   _PriceOptionMeta('price_r', 'R'),
// //   _PriceOptionMeta('price_art', 'ART'),
// // ];
// //
// // // ---------------------------------------------------------------------------
// // // View mode enum
// // // ---------------------------------------------------------------------------
// //
// // enum _ViewMode { list, grid }
// //
// // // ---------------------------------------------------------------------------
// // // Quotation helpers
// // // ---------------------------------------------------------------------------
// //
// // class _SelectedQuoteItem {
// //   final int itemId;
// //   final String productName;
// //   final String priceKey;
// //   final String priceLabel;
// //   final double unitPrice;
// //   final int quantity;
// //   final Map<String, dynamic> item;
// //
// //   const _SelectedQuoteItem({
// //     required this.itemId,
// //     required this.productName,
// //     required this.priceKey,
// //     required this.priceLabel,
// //     required this.unitPrice,
// //     required this.quantity,
// //     required this.item,
// //   });
// //
// //   _SelectedQuoteItem copyWith({
// //     String? priceKey,
// //     String? priceLabel,
// //     double? unitPrice,
// //     int? quantity,
// //   }) {
// //     return _SelectedQuoteItem(
// //       itemId: itemId,
// //       productName: productName,
// //       priceKey: priceKey ?? this.priceKey,
// //       priceLabel: priceLabel ?? this.priceLabel,
// //       unitPrice: unitPrice ?? this.unitPrice,
// //       quantity: quantity ?? this.quantity,
// //       item: item,
// //     );
// //   }
// //
// //   double get lineTotal => unitPrice * quantity;
// // }
// //
// // class _QuotationDraft {
// //   final String customerName;
// //   final String companyName;
// //   final String customerTrn;
// //   final String customerPhone;
// //   final String salespersonName;
// //   final String salespersonContact;
// //   final String salespersonPhone;
// //   final String notes;
// //   final double deliveryFee;
// //   final double installationFee;
// //   final double additionalDetailsFee;
// //   final double vatPercent;
// //
// //   const _QuotationDraft({
// //     required this.customerName,
// //     required this.companyName,
// //     required this.customerTrn,
// //     required this.customerPhone,
// //     required this.salespersonName,
// //     required this.salespersonContact,
// //     required this.salespersonPhone,
// //     required this.notes,
// //     required this.deliveryFee,
// //     required this.installationFee,
// //     required this.additionalDetailsFee,
// //     required this.vatPercent,
// //   });
// // }
// //
// // // ---------------------------------------------------------------------------
// // // Helpers
// // // ---------------------------------------------------------------------------
// //
// // int? _safeInt(dynamic value) {
// //   if (value == null) return null;
// //   if (value is int) return value;
// //   if (value is num) return value.toInt();
// //   return int.tryParse(value.toString().trim());
// // }
// //
// // double _safeDouble(dynamic value) {
// //   if (value == null) return 0;
// //   if (value is num) return value.toDouble();
// //   return double.tryParse(value.toString().trim()) ?? 0;
// // }
// //
// // // ---------------------------------------------------------------------------
// // // PriceListScreen
// // // ---------------------------------------------------------------------------
// //
// // class PriceListScreen extends StatefulWidget {
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //
// //   const PriceListScreen({
// //     super.key,
// //     required this.profile,
// //     required this.onLogout,
// //   });
// //
// //   @override
// //   State<PriceListScreen> createState() => _PriceListScreenState();
// // }
// //
// // class _PriceListScreenState extends State<PriceListScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //   final TextEditingController _searchController = TextEditingController();
// //
// //   // --- Role helpers ---
// //   String get _role =>
// //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// //   bool get _isAdmin => _role == 'admin';
// //   bool get _isSales => _role == 'sales';
// //   bool get _isAccountant => _role == 'accountant';
// //
// //   bool get _canCreateQuotation => _isSales || _isAdmin;
// //   bool get _canViewQuotations => _isSales || _isAdmin;
// //   bool get _canManagePricePermissions => _isAdmin || _isAccountant;
// //   bool get _canAddItems => _isAdmin || _isAccountant;
// //   bool get _canManageUsers => _isAdmin;
// //   bool get _canUseContainerProcessor => _isAdmin || _isAccountant;
// //   bool get _canUsePriceChipsForQuotation => _isAdmin || _isSales;
// //
// //   // --- State ---
// //   Timer? _debounce;
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //
// //   List<Map<String, dynamic>> _allItems = [];
// //   List<Map<String, dynamic>> _filteredItems = [];
// //   List<String> _categories = [];
// //
// //   String _searchQuery = '';
// //   String? _selectedCategory;
// //
// //   Map<String, bool> _pricePermissions = {
// //     for (final o in _priceOptions) o.key: true,
// //   };
// //   bool _isLoadingPermissions = true;
// //
// //   final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};
// //
// //   // --- View mode (persisted) ---
// //   _ViewMode _viewMode = _ViewMode.list;
// //   static const _kViewModeKey = 'price_list_view_mode';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _searchController.addListener(_onSearchChanged);
// //     _loadViewMode();
// //     Future.wait([_loadItems(), _loadPricePermissions()]);
// //   }
// //
// //   @override
// //   void dispose() {
// //     _debounce?.cancel();
// //     _searchController.dispose();
// //     super.dispose();
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // View-mode persistence
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _loadViewMode() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final saved = prefs.getString(_kViewModeKey);
// //     if (!mounted) return;
// //     setState(() {
// //       _viewMode =
// //       saved == 'grid' ? _ViewMode.grid : _ViewMode.list;
// //     });
// //   }
// //
// //   Future<void> _setViewMode(_ViewMode mode) async {
// //     setState(() => _viewMode = mode);
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString(
// //         _kViewModeKey, mode == _ViewMode.grid ? 'grid' : 'list');
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Search
// //   // ---------------------------------------------------------------------------
// //
// //   void _onSearchChanged() {
// //     _debounce?.cancel();
// //     _debounce = Timer(const Duration(milliseconds: 300), () {
// //       if (!mounted) return;
// //       setState(() {
// //         _searchQuery = _searchController.text.trim();
// //         _applyFilters();
// //       });
// //     });
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Data loading
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _loadItems() async {
// //     setState(() {
// //       _isLoading = true;
// //       _errorMessage = null;
// //     });
// //
// //     try {
// //       final response = await _supabase
// //           .from('price_list_api')
// //           .select()
// //           .order('category_ar', ascending: true)
// //           .order('product_name', ascending: true);
// //
// //       final items = (response as List)
// //           .map((item) => Map<String, dynamic>.from(item as Map))
// //           .toList();
// //
// //       final categories = items
// //           .map((e) => (e['category_ar'] ?? '').toString().trim())
// //           .where((e) => e.isNotEmpty)
// //           .toSet()
// //           .toList()
// //         ..sort();
// //
// //       setState(() {
// //         _allItems = items;
// //         _categories = categories;
// //         _applyFilters();
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _errorMessage = e.toString();
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _applyFilters() {
// //     final search = _searchQuery.toLowerCase();
// //
// //     _filteredItems = _allItems.where((item) {
// //       final category = (item['category_ar'] ?? '').toString().trim();
// //       final description = (item['description'] ?? '').toString().trim();
// //       final productName = (item['product_name'] ?? '').toString().trim();
// //       final itemCode = (item['item_code'] ?? '').toString().trim();
// //       final displayPrice = (item['display_price'] ?? '').toString().trim();
// //       final barcode = (item['barcode'] ?? '').toString().trim();
// //
// //       final matchesCategory =
// //           _selectedCategory == null || category == _selectedCategory;
// //
// //       final haystack = [
// //         category,
// //         description,
// //         productName,
// //         itemCode,
// //         displayPrice,
// //         barcode,
// //       ].join(' ').toLowerCase();
// //
// //       final matchesSearch = search.isEmpty || haystack.contains(search);
// //       return matchesCategory && matchesSearch;
// //     }).toList();
// //   }
// //
// //   void _clearFilters() {
// //     setState(() {
// //       _selectedCategory = null;
// //       _searchQuery = '';
// //       _searchController.clear();
// //       _applyFilters();
// //     });
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Price permissions
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _loadPricePermissions() async {
// //     try {
// //       final response = await _supabase.rpc('get_my_price_permissions');
// //
// //       final map = {for (final o in _priceOptions) o.key: true};
// //
// //       if (response is List) {
// //         for (final row in response) {
// //           final data = Map<String, dynamic>.from(row as Map);
// //           final key = (data['price_key'] ?? '').toString();
// //           final allowed = data['is_allowed'] == true;
// //           if (map.containsKey(key)) map[key] = allowed;
// //         }
// //       }
// //
// //       if (!mounted) return;
// //       setState(() {
// //         _pricePermissions = map;
// //         _isLoadingPermissions = false;
// //       });
// //     } catch (_) {
// //       if (!mounted) return;
// //       setState(() {
// //         _pricePermissions = {for (final o in _priceOptions) o.key: true};
// //         _isLoadingPermissions = false;
// //       });
// //     }
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Barcode scan
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _startBarcodeScan() async {
// //     final code = await Navigator.of(context).push<String>(
// //       MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
// //     );
// //     if (!mounted || code == null || code.trim().isEmpty) return;
// //     setState(() {
// //       _searchController.text = code.trim();
// //       _searchController.selection = TextSelection.fromPosition(
// //         TextPosition(offset: _searchController.text.length),
// //       );
// //       _searchQuery = code.trim();
// //       _applyFilters();
// //     });
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Price formatting
// //   // ---------------------------------------------------------------------------
// //
// //   double? _toDouble(dynamic value) {
// //     if (value == null) return null;
// //     if (value is num) return value.toDouble();
// //     return double.tryParse(value.toString());
// //   }
// //
// //   String _formatPrice(dynamic value) {
// //     final number = _toDouble(value);
// //     if (number == null) return '-';
// //     if (number == number.roundToDouble()) return number.toInt().toString();
// //     return number.toStringAsFixed(2);
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Quotation selection
// //   // ---------------------------------------------------------------------------
// //
// //   double? _priceValueForKey(Map<String, dynamic> item, String priceKey) =>
// //       _toDouble(item[priceKey]);
// //
// //   bool _isPriceAllowedForItem(Map<String, dynamic> item, String priceKey) {
// //     final globallyAllowed = _pricePermissions[priceKey] ?? true;
// //     final value = _priceValueForKey(item, priceKey);
// //     return globallyAllowed && value != null;
// //   }
// //
// //   String? _selectedPriceKeyForItem(Map<String, dynamic> item) {
// //     final itemId = _safeInt(item['id']);
// //     if (itemId == null) return null;
// //     return _selectedQuoteItems[itemId]?.priceKey;
// //   }
// //
// //   void _toggleItemPriceSelection(
// //       Map<String, dynamic> item, String priceKey, String priceLabel) {
// //     if (!_canUsePriceChipsForQuotation) return;
// //     if (!_isPriceAllowedForItem(item, priceKey)) return;
// //
// //     final itemId = _safeInt(item['id']);
// //     if (itemId == null) return;
// //
// //     final priceValue = _priceValueForKey(item, priceKey);
// //     if (priceValue == null) return;
// //
// //     final current = _selectedQuoteItems[itemId];
// //
// //     setState(() {
// //       if (current != null && current.priceKey == priceKey) {
// //         _selectedQuoteItems.remove(itemId);
// //         return;
// //       }
// //       _selectedQuoteItems[itemId] = _SelectedQuoteItem(
// //         itemId: itemId,
// //         productName: (item['product_name'] ?? '').toString().trim(),
// //         priceKey: priceKey,
// //         priceLabel: priceLabel,
// //         unitPrice: priceValue,
// //         quantity: current?.quantity ?? 1,
// //         item: item,
// //       );
// //     });
// //   }
// //
// //   void _changeSelectedItemQuantity(int itemId, int delta) {
// //     final current = _selectedQuoteItems[itemId];
// //     if (current == null) return;
// //     final nextQty = current.quantity + delta;
// //     setState(() {
// //       if (nextQty <= 0) {
// //         _selectedQuoteItems.remove(itemId);
// //       } else {
// //         _selectedQuoteItems[itemId] = current.copyWith(quantity: nextQty);
// //       }
// //     });
// //   }
// //
// //   double get _selectedGrandTotal => _selectedQuoteItems.values
// //       .fold(0, (sum, item) => sum + item.lineTotal);
// //
// //   // ---------------------------------------------------------------------------
// //   // Sheets – Selected items & Quotation
// //   // ---------------------------------------------------------------------------
// //
// //   void _openSelectedItemsSheet() {
// //     showModalBottomSheet(
// //       context: context,
// //       useSafeArea: true,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (_) {
// //         return StatefulBuilder(
// //           builder: (context, setModalState) {
// //             final selectedItems = _selectedQuoteItems.values.toList();
// //             return SafeArea(
// //               child: FractionallySizedBox(
// //                 heightFactor: 0.9,
// //                 child: Padding(
// //                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
// //                   child: Column(
// //                     children: [
// //                       Text(
// //                         'Selected Items',
// //                         style: Theme.of(context)
// //                             .textTheme
// //                             .headlineSmall
// //                             ?.copyWith(fontWeight: FontWeight.w900),
// //                       ),
// //                       const SizedBox(height: 16),
// //                       Expanded(
// //                         child: selectedItems.isEmpty
// //                             ? const Center(child: Text('No items selected yet.'))
// //                             : ListView.separated(
// //                           itemCount: selectedItems.length,
// //                           separatorBuilder: (_, __) =>
// //                           const Divider(height: 20),
// //                           itemBuilder: (context, index) {
// //                             final selected = selectedItems[index];
// //                             return Row(
// //                               crossAxisAlignment:
// //                               CrossAxisAlignment.start,
// //                               children: [
// //                                 Expanded(
// //                                   child: Column(
// //                                     crossAxisAlignment:
// //                                     CrossAxisAlignment.start,
// //                                     children: [
// //                                       Text(
// //                                         selected.productName.isEmpty
// //                                             ? 'Unnamed Product'
// //                                             : selected.productName,
// //                                         style: const TextStyle(
// //                                             fontWeight: FontWeight.w800),
// //                                       ),
// //                                       const SizedBox(height: 4),
// //                                       Text(
// //                                         '${selected.priceLabel} • ${_formatPrice(selected.unitPrice)}',
// //                                         style: const TextStyle(
// //                                           color: AppConstants.primaryColor,
// //                                           fontWeight: FontWeight.w700,
// //                                         ),
// //                                       ),
// //                                       const SizedBox(height: 4),
// //                                       Text(
// //                                           'Line total: ${_formatPrice(selected.lineTotal)}'),
// //                                     ],
// //                                   ),
// //                                 ),
// //                                 Row(
// //                                   mainAxisSize: MainAxisSize.min,
// //                                   children: [
// //                                     IconButton(
// //                                       onPressed: () {
// //                                         _changeSelectedItemQuantity(
// //                                             selected.itemId, -1);
// //                                         setModalState(() {});
// //                                       },
// //                                       icon: const Icon(
// //                                           Icons.remove_circle_outline),
// //                                     ),
// //                                     Text(
// //                                       '${_selectedQuoteItems[selected.itemId]?.quantity ?? selected.quantity}',
// //                                       style: const TextStyle(
// //                                           fontWeight: FontWeight.w800),
// //                                     ),
// //                                     IconButton(
// //                                       onPressed: () {
// //                                         _changeSelectedItemQuantity(
// //                                             selected.itemId, 1);
// //                                         setModalState(() {});
// //                                       },
// //                                       icon: const Icon(
// //                                           Icons.add_circle_outline),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             );
// //                           },
// //                         ),
// //                       ),
// //                       if (_selectedQuoteItems.isNotEmpty) ...[
// //                         const SizedBox(height: 16),
// //                         Row(
// //                           children: [
// //                             const Expanded(
// //                               child: Text('Grand Total',
// //                                   style:
// //                                   TextStyle(fontWeight: FontWeight.w800)),
// //                             ),
// //                             Text(
// //                               _formatPrice(_selectedGrandTotal),
// //                               style: const TextStyle(
// //                                 color: Color(0xFFFFD95E),
// //                                 fontWeight: FontWeight.w900,
// //                                 fontSize: 18,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 16),
// //                         SizedBox(
// //                           width: double.infinity,
// //                           child: FilledButton.icon(
// //                             onPressed: () {
// //                               Navigator.pop(context);
// //                               _openCreateQuotationSheet();
// //                             },
// //                             icon: const Icon(Icons.description_outlined),
// //                             label: const Text('Create Quotation'),
// //                           ),
// //                         ),
// //                       ],
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Future<void> _openCreateQuotationSheet() async {
// //     if (_selectedQuoteItems.isEmpty) return;
// //
// //     final draft = await showModalBottomSheet<_QuotationDraft>(
// //       context: context,
// //       useSafeArea: true,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (_) => _CreateQuotationSheet(
// //         subtotal: _selectedGrandTotal,
// //         formatPrice: _formatPrice,
// //         profile: widget.profile,
// //       ),
// //     );
// //
// //     if (!mounted || draft == null) return;
// //     await _saveQuotation(draft);
// //   }
// //
// //   Future<void> _saveQuotation(_QuotationDraft draft) async {
// //     final user = _supabase.auth.currentUser;
// //     if (user == null) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No logged in user found.')));
// //       return;
// //     }
// //
// //     final subtotal = _selectedGrandTotal;
// //     final taxableTotal = subtotal +
// //         draft.deliveryFee +
// //         draft.installationFee +
// //         draft.additionalDetailsFee;
// //     final vatAmount = taxableTotal * (draft.vatPercent / 100);
// //     final netTotal = taxableTotal + vatAmount;
// //     final quoteNo = 'QT-${DateTime.now().microsecondsSinceEpoch}';
// //
// //     final quotationPayload = {
// //       'quote_no': quoteNo,
// //       'quote_date': DateTime.now().toIso8601String().split('T').first,
// //       'customer_name': draft.customerName.isEmpty ? null : draft.customerName,
// //       'company_name': draft.companyName.isEmpty ? null : draft.companyName,
// //       'customer_trn': draft.customerTrn.isEmpty ? null : draft.customerTrn,
// //       'customer_phone':
// //       draft.customerPhone.isEmpty ? null : draft.customerPhone,
// //       'salesperson_name':
// //       draft.salespersonName.isEmpty ? null : draft.salespersonName,
// //       'salesperson_contact': draft.salespersonContact.isEmpty
// //           ? null
// //           : draft.salespersonContact,
// //       'salesperson_phone': widget.profile['phone'],
// //       'notes': draft.notes.isEmpty ? null : draft.notes,
// //       'status': 'draft',
// //       'subtotal': subtotal,
// //       'delivery_fee': draft.deliveryFee,
// //       'installation_fee': draft.installationFee,
// //       'additional_details_fee': draft.additionalDetailsFee,
// //       'taxable_total': taxableTotal,
// //       'vat_percent': draft.vatPercent,
// //       'vat_amount': vatAmount,
// //       'net_total': netTotal,
// //       'created_by': user.id,
// //       'updated_by': user.id,
// //     };
// //
// //     try {
// //       final insertedQuotation = await _supabase
// //           .from('quotations')
// //           .insert(quotationPayload)
// //           .select('id, quote_no, created_by')
// //           .single();
// //
// //       final quotationId = _safeInt(insertedQuotation['id']);
// //       if (quotationId == null) throw Exception('Failed to resolve quotation id.');
// //
// //       final itemRows = _selectedQuoteItems.values.map((selected) {
// //         final item = selected.item;
// //         final itemCode = (item['item_code'] ?? '').toString().trim();
// //         final description = (item['description'] ?? '').toString().trim();
// //         final imagePath = (item['image_path'] ?? '').toString().trim();
// //         final productName = selected.productName.trim().isEmpty
// //             ? 'Unnamed Product'
// //             : selected.productName.trim();
// //         final rawLength = item['length']?.toString().trim();
// //         final rawWidth = item['width']?.toString().trim();
// //         final rawProductionTime = item['production_time']?.toString().trim();
// //
// //         return {
// //           'quotation_id': quotationId,
// //           'product_id': selected.itemId,
// //           'item_code': itemCode.isEmpty ? null : itemCode,
// //           'product_name': productName,
// //           'description': description.isEmpty ? null : description,
// //           'image_path': imagePath.isEmpty ? null : imagePath,
// //           'length': (rawLength == null || rawLength.isEmpty)
// //               ? null
// //               : item['length'].toString().trim(),
// //           'width': (rawWidth == null || rawWidth.isEmpty)
// //               ? null
// //               : item['width'].toString().trim(),
// //           'production_time':
// //           (rawProductionTime == null || rawProductionTime.isEmpty)
// //               ? null
// //               : item['production_time'].toString().trim(),
// //           'price_key': selected.priceKey,
// //           'price_label': selected.priceLabel,
// //           'unit_price': selected.unitPrice,
// //           'quantity': selected.quantity,
// //           'line_total': selected.lineTotal,
// //           'snapshot': {
// //             'category_ar': item['category_ar'],
// //             'description': item['description'],
// //             'product_name': item['product_name'],
// //             'item_code': item['item_code'],
// //             'price_ee': item['price_ee'],
// //             'price_aa': item['price_aa'],
// //             'price_a': item['price_a'],
// //             'price_rr': item['price_rr'],
// //             'price_r': item['price_r'],
// //             'price_art': item['price_art'],
// //             'pot_item_no': item['pot_item_no'],
// //             'pot_price': item['pot_price'],
// //             'additions': item['additions'],
// //             'total_price': item['total_price'],
// //             'display_price': item['display_price'],
// //             'image_path': item['image_path'],
// //             'length': item['length'],
// //             'width': item['width'],
// //             'production_time': item['production_time'],
// //           },
// //         };
// //       }).toList();
// //
// //       await _supabase.from('quotation_items').insert(itemRows);
// //
// //       if (!mounted) return;
// //       setState(() => _selectedQuoteItems.clear());
// //
// //       final quoteNumber = (insertedQuotation['quote_no'] ?? '').toString();
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Quotation $quoteNumber created successfully.')),
// //       );
// //
// //       await Navigator.of(context).push(
// //         MaterialPageRoute(
// //           builder: (_) =>
// //               QuotationDetailsScreen(quotationId: quotationId),
// //         ),
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to create quotation: $e')),
// //       );
// //     }
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Details sheet
// //   // ---------------------------------------------------------------------------
// //
// //   void _openDetails(Map<String, dynamic> item) {
// //     showModalBottomSheet(
// //       context: context,
// //       useSafeArea: true,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (_) =>
// //           _ProductDetailsSheet(item: item, formatPrice: _formatPrice),
// //     );
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Add / Bulk add sheets
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _openAddItemSheet() async {
// //     final created = await showModalBottomSheet<bool>(
// //       context: context,
// //       useSafeArea: true,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (_) => const _AddItemSheet(),
// //     );
// //     if (created == true) await _loadItems();
// //   }
// //
// //   Future<void> _openBulkAddItemsSheet() async {
// //     final created = await showModalBottomSheet<bool>(
// //       context: context,
// //       useSafeArea: true,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (_) => const _BulkAddItemsSheet(),
// //     );
// //     if (created == true) await _loadItems();
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // FAB actions
// //   // ---------------------------------------------------------------------------
// //
// //   Future<void> _openFabActions() async {
// //     if (!mounted) return;
// //     await showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF121212),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       builder: (context) {
// //         return SafeArea(
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 if (_canUseContainerProcessor)
// //                   ListTile(
// //                     leading: const Icon(Icons.inventory_2_outlined),
// //                     title: const Text('Container Processor'),
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.of(context).push(MaterialPageRoute(
// //                           builder: (_) => const ContainerProcessorScreen()));
// //                     },
// //                   ),
// //                 if (_canAddItems) ...[
// //                   ListTile(
// //                     leading: const Icon(Icons.add_box_outlined),
// //                     title: const Text('Add Item'),
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       _openAddItemSheet();
// //                     },
// //                   ),
// //                   if (_canManageUsers)
// //                     ListTile(
// //                       leading: const Icon(Icons.manage_accounts_outlined),
// //                       title: const Text('Manage User Roles'),
// //                       subtitle: const Text('Change roles for other users'),
// //                       onTap: () {
// //                         Navigator.pop(context);
// //                         Navigator.of(context).push(MaterialPageRoute(
// //                           builder: (_) => UserRoleManagementScreen(
// //                             currentUserId:
// //                             (widget.profile['id'] ?? '').toString(),
// //                           ),
// //                         ));
// //                       },
// //                     ),
// //                   ListTile(
// //                     leading:
// //                     const Icon(Icons.playlist_add_check_circle_outlined),
// //                     title: const Text('Add Bulk Items'),
// //                     subtitle: const Text('Paste CSV, TSV, or JSON rows'),
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       _openBulkAddItemsSheet();
// //                     },
// //                   ),
// //                 ],
// //                 if (_canViewQuotations || _canCreateQuotation)
// //                   ListTile(
// //                     leading: const Icon(Icons.description_outlined),
// //                     title: Text(_isAdmin
// //                         ? 'View Quotations'
// //                         : _isSales
// //                         ? 'My Quotations'
// //                         : ''),
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.of(context).push(MaterialPageRoute(
// //                         builder: (_) => QuotationListScreen(
// //                           role: _role,
// //                           currentUserId:
// //                           (widget.profile['id'] ?? '').toString(),
// //                         ),
// //                       ));
// //                     },
// //                   ),
// //                 if (_canManagePricePermissions)
// //                   ListTile(
// //                     leading: const Icon(Icons.lock_person_outlined),
// //                     title: const Text('Price Permissions'),
// //                     subtitle:
// //                     const Text('Global and per-user price restrictions'),
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.of(context).push(MaterialPageRoute(
// //                           builder: (_) => const PricePermissionsScreen()));
// //                     },
// //                   ),
// //                 ListTile(
// //                   leading: const Icon(Icons.qr_code_scanner_rounded),
// //                   title: const Text('Scan Barcode'),
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     _startBarcodeScan();
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Responsive grid column count (used only for grid mode)
// //   // ---------------------------------------------------------------------------
// //
// //   int _gridCount(double width) {
// //     if (width >= 1400) return 4;
// //     if (width >= 1000) return 3;
// //     return 2; // 700–999 OR phone when in grid mode
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Build
// //   // ---------------------------------------------------------------------------
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF0A0A0A),
// //       floatingActionButton: FloatingActionButton.extended(
// //         onPressed: _openFabActions,
// //         icon: Icon(_isAdmin
// //             ? Icons.admin_panel_settings_rounded
// //             : Icons.apps),
// //         label: const Text('Actions'),
// //       ),
// //       bottomNavigationBar: _selectedQuoteItems.isEmpty
// //           ? null
// //           : SafeArea(
// //         top: false,
// //         child: Container(
// //           padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
// //           decoration: const BoxDecoration(
// //             color: Color(0xFF111111),
// //             border: Border(top: BorderSide(color: Color(0xFF3A2F0B))),
// //           ),
// //           child: Row(
// //             children: [
// //               Expanded(
// //                 child: Text(
// //                   '${_selectedQuoteItems.length} item(s) • Total: ${_formatPrice(_selectedGrandTotal)}',
// //                   style: const TextStyle(fontWeight: FontWeight.w800),
// //                 ),
// //               ),
// //               FilledButton.icon(
// //                 onPressed: _openSelectedItemsSheet,
// //                 icon: const Icon(Icons.shopping_bag_outlined),
// //                 label: const Text('Review'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             _HeaderSection(
// //               searchController: _searchController,
// //               selectedCategory: _selectedCategory,
// //               categories: _categories,
// //               visibleCount: _filteredItems.length,
// //               totalCount: _allItems.length,
// //               onClearFilters: _clearFilters,
// //               onCategorySelected: (value) {
// //                 setState(() {
// //                   _selectedCategory = value;
// //                   _applyFilters();
// //                 });
// //               },
// //               profile: widget.profile,
// //               onLogout: widget.onLogout,
// //               viewMode: _viewMode,
// //               onViewModeChanged: _setViewMode,
// //             ),
// //             Expanded(
// //               child: AnimatedSwitcher(
// //                 duration: const Duration(milliseconds: 200),
// //                 child: _buildBody(theme),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Body builder
// //   // ---------------------------------------------------------------------------
// //
// //   Widget _buildBody(ThemeData theme) {
// //     if (_isLoading) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (_errorMessage != null) {
// //       return Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Container(
// //             constraints: const BoxConstraints(maxWidth: 520),
// //             padding: const EdgeInsets.all(20),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF141414),
// //               borderRadius: BorderRadius.circular(24),
// //               border: Border.all(color: const Color(0xFF4A3B12)),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: AppConstants.primaryColor.withOpacity(0.06),
// //                   blurRadius: 18,
// //                   offset: const Offset(0, 8),
// //                 ),
// //               ],
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 const Icon(Icons.error_outline_rounded,
// //                     size: 48, color: AppConstants.primaryColor),
// //                 const SizedBox(height: 12),
// //                 Text('Failed to load data',
// //                     style: theme.textTheme.titleLarge
// //                         ?.copyWith(fontWeight: FontWeight.w800)),
// //                 const SizedBox(height: 10),
// //                 Text(_errorMessage!,
// //                     textAlign: TextAlign.center,
// //                     style: theme.textTheme.bodyMedium),
// //                 const SizedBox(height: 18),
// //                 FilledButton.icon(
// //                   onPressed: _loadItems,
// //                   icon: const Icon(Icons.refresh_rounded),
// //                   label: const Text('Retry'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //
// //     if (_filteredItems.isEmpty) {
// //       return RefreshIndicator(
// //         onRefresh: _loadItems,
// //         child: ListView(
// //           physics: const AlwaysScrollableScrollPhysics(),
// //           children: [
// //             const SizedBox(height: 140),
// //             Center(
// //               child: Container(
// //                 width: 340,
// //                 padding: const EdgeInsets.all(22),
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF141414),
// //                   borderRadius: BorderRadius.circular(24),
// //                   border: Border.all(color: const Color(0xFF4A3B12)),
// //                 ),
// //                 child: Column(
// //                   children: [
// //                     const Icon(Icons.search_off_rounded,
// //                         size: 52, color: AppConstants.primaryColor),
// //                     const SizedBox(height: 12),
// //                     Text('No items found',
// //                         style: theme.textTheme.titleMedium
// //                             ?.copyWith(fontWeight: FontWeight.w800)),
// //                     const SizedBox(height: 8),
// //                     Text(
// //                       'Try changing the search text or category filter.',
// //                       textAlign: TextAlign.center,
// //                       style: theme.textTheme.bodyMedium,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final width = constraints.maxWidth;
// //         final isNarrow = width < 700; // phone
// //
// //         // On narrow screens, respect the user's view mode toggle.
// //         // On wide screens, always use grid (mode is irrelevant there).
// //         final useList = isNarrow && _viewMode == _ViewMode.list;
// //
// //         if (useList) {
// //           return _buildCompactList();
// //         } else {
// //           return _buildResponsiveGrid(width);
// //         }
// //       },
// //     );
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Compact list (phone default) — ~7-8 rows visible at once
// //   // ---------------------------------------------------------------------------
// //
// //   Widget _buildCompactList() {
// //     return RefreshIndicator(
// //       onRefresh: _loadItems,
// //       child: ListView.builder(
// //         physics: const AlwaysScrollableScrollPhysics(),
// //         padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
// //         itemCount: _filteredItems.length,
// //         itemBuilder: (context, index) {
// //           final item = _filteredItems[index];
// //           return _CompactListTile(
// //             item: item,
// //             formatPrice: _formatPrice,
// //             onTap: () => _openDetails(item),
// //             pricePermissions: _pricePermissions,
// //             selectedPriceKey: _selectedPriceKeyForItem(item),
// //             onSelectPrice: (priceKey, priceLabel) =>
// //                 _toggleItemPriceSelection(item, priceKey, priceLabel),
// //             isLoadingPermissions: _isLoadingPermissions,
// //             canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Responsive grid (phone grid mode + tablet/desktop)
// //   // ---------------------------------------------------------------------------
// //
// //   Widget _buildResponsiveGrid(double width) {
// //     final crossAxisCount = _gridCount(width);
// //     return RefreshIndicator(
// //       onRefresh: _loadItems,
// //       child: GridView.builder(
// //         physics: const AlwaysScrollableScrollPhysics(),
// //         padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
// //         itemCount: _filteredItems.length,
// //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //           crossAxisCount: crossAxisCount,
// //           mainAxisSpacing: 10,
// //           crossAxisSpacing: 10,
// //           childAspectRatio: crossAxisCount >= 3 ? 0.72 : 0.78,
// //         ),
// //         itemBuilder: (context, index) {
// //           final item = _filteredItems[index];
// //           return _GridProductCard(
// //             item: item,
// //             formatPrice: _formatPrice,
// //             onTap: () => _openDetails(item),
// //             pricePermissions: _pricePermissions,
// //             selectedPriceKey: _selectedPriceKeyForItem(item),
// //             onSelectPrice: (priceKey, priceLabel) =>
// //                 _toggleItemPriceSelection(item, priceKey, priceLabel),
// //             isLoadingPermissions: _isLoadingPermissions,
// //             canSelectPricesForQuotation: _canUsePriceChipsForQuotation,
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _HeaderSection
// // // ===========================================================================
// //
// // class _HeaderSection extends StatelessWidget {
// //   final TextEditingController searchController;
// //   final String? selectedCategory;
// //   final List<String> categories;
// //   final int visibleCount;
// //   final int totalCount;
// //   final VoidCallback onClearFilters;
// //   final ValueChanged<String?> onCategorySelected;
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final _ViewMode viewMode;
// //   final ValueChanged<_ViewMode> onViewModeChanged;
// //
// //   const _HeaderSection({
// //     required this.searchController,
// //     required this.selectedCategory,
// //     required this.categories,
// //     required this.visibleCount,
// //     required this.totalCount,
// //     required this.onClearFilters,
// //     required this.onCategorySelected,
// //     required this.onLogout,
// //     required this.profile,
// //     required this.viewMode,
// //     required this.onViewModeChanged,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final hasFilters =
// //         selectedCategory != null || searchController.text.trim().isNotEmpty;
// //
// //     return Container(
// //       padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF111111),
// //         border: const Border(bottom: BorderSide(color: Color(0xFF3A2F0B))),
// //         boxShadow: [
// //           BoxShadow(
// //             color: AppConstants.primaryColor.withOpacity(0.05),
// //             blurRadius: 16,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Top row: logo + title | user + menu
// //           Row(
// //             children: [
// //               Container(
// //                 width: 40,
// //                 height: 40,
// //                 padding: const EdgeInsets.all(3),
// //                 decoration: BoxDecoration(
// //                   borderRadius: BorderRadius.circular(12),
// //                   gradient: const LinearGradient(
// //                     colors: [AppConstants.primaryColor, Color(0xFF8C6B16)],
// //                   ),
// //                 ),
// //                 child: Image.asset('assets/icons/logo_black.png'),
// //               ),
// //               const SizedBox(width: 10),
// //               Text(
// //                 'Price List',
// //                 style: theme.textTheme.titleLarge
// //                     ?.copyWith(fontWeight: FontWeight.w900),
// //               ),
// //               const Spacer(),
// //               // User info
// //               Column(
// //                 crossAxisAlignment: CrossAxisAlignment.end,
// //                 children: [
// //                   Text(
// //                     ((profile['full_name'] ?? '').toString().trim().isNotEmpty
// //                         ? profile['full_name']
// //                         : profile['email'])
// //                         .toString(),
// //                     style: theme.textTheme.bodySmall
// //                         ?.copyWith(fontWeight: FontWeight.w700),
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                   Text(
// //                     (profile['role']).toString().toUpperCase(),
// //                     style: theme.textTheme.labelSmall?.copyWith(
// //                       color: AppConstants.primaryColor,
// //                       fontWeight: FontWeight.w800,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               PopupMenuButton<String>(
// //                 onSelected: (value) async {
// //                   if (value == 'logout') await onLogout();
// //                 },
// //                 itemBuilder: (context) => const [
// //                   PopupMenuItem<String>(
// //                       value: 'logout', child: Text('Logout')),
// //                 ],
// //                 icon: const Icon(Icons.account_circle_outlined),
// //                 padding: EdgeInsets.zero,
// //               ),
// //             ],
// //           ),
// //
// //           const SizedBox(height: 10),
// //
// //           // Search bar
// //           Container(
// //             decoration: BoxDecoration(
// //               borderRadius: BorderRadius.circular(14),
// //               border: Border.all(color: const Color(0xFF4A3B12)),
// //               color: const Color(0xFF161616),
// //             ),
// //             child: TextField(
// //               controller: searchController,
// //               textDirection: TextDirection.rtl,
// //               style: const TextStyle(color: Color(0xFFF5E7B2)),
// //               decoration: InputDecoration(
// //                 hintText: 'Search by name, code, description, or barcode',
// //                 prefixIcon: const Icon(Icons.search_rounded, size: 20),
// //                 suffixIcon: searchController.text.trim().isNotEmpty
// //                     ? IconButton(
// //                   onPressed: () => searchController.clear(),
// //                   icon: const Icon(Icons.close_rounded, size: 18),
// //                 )
// //                     : null,
// //                 border: InputBorder.none,
// //                 contentPadding:
// //                 const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// //                 hintStyle: const TextStyle(fontSize: 13),
// //               ),
// //             ),
// //           ),
// //
// //           const SizedBox(height: 10),
// //
// //           // Category chips
// //           SizedBox(
// //             height: 36,
// //             child: ListView(
// //               scrollDirection: Axis.horizontal,
// //               children: [
// //                 Padding(
// //                   padding: const EdgeInsetsDirectional.only(end: 6),
// //                   child: ChoiceChip(
// //                     label: const Text('All'),
// //                     selected: selectedCategory == null,
// //                     onSelected: (_) => onCategorySelected(null),
// //                     visualDensity: VisualDensity.compact,
// //                   ),
// //                 ),
// //                 ...categories.map(
// //                       (cat) => Padding(
// //                     padding: const EdgeInsetsDirectional.only(end: 6),
// //                     child: ChoiceChip(
// //                       label: Text(cat),
// //                       selected: selectedCategory == cat,
// //                       onSelected: (_) => onCategorySelected(
// //                           selectedCategory == cat ? null : cat),
// //                       visualDensity: VisualDensity.compact,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           const SizedBox(height: 8),
// //
// //           // Stats row + view toggle + clear
// //           Row(
// //             children: [
// //               const Icon(Icons.inventory_2_outlined,
// //                   size: 15, color: AppConstants.primaryColor),
// //               const SizedBox(width: 6),
// //               Text(
// //                 '$visibleCount / $totalCount items',
// //                 style: theme.textTheme.bodySmall
// //                     ?.copyWith(fontWeight: FontWeight.w700),
// //               ),
// //               const Spacer(),
// //               if (hasFilters)
// //                 TextButton.icon(
// //                   onPressed: onClearFilters,
// //                   icon: const Icon(Icons.clear_all_rounded, size: 16),
// //                   label: const Text('Clear'),
// //                   style: TextButton.styleFrom(
// //                     visualDensity: VisualDensity.compact,
// //                     padding: const EdgeInsets.symmetric(horizontal: 8),
// //                   ),
// //                 ),
// //               // View mode toggle — only shown on narrow screens
// //               LayoutBuilder(
// //                 builder: (context, _) {
// //                   return MediaQuery.of(context).size.width < 700
// //                       ? Row(
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       const SizedBox(width: 4),
// //                       _ViewToggleButton(
// //                         icon: Icons.view_list_rounded,
// //                         isActive: viewMode == _ViewMode.list,
// //                         onTap: () => onViewModeChanged(_ViewMode.list),
// //                         tooltip: 'List view',
// //                       ),
// //                       const SizedBox(width: 4),
// //                       _ViewToggleButton(
// //                         icon: Icons.grid_view_rounded,
// //                         isActive: viewMode == _ViewMode.grid,
// //                         onTap: () => onViewModeChanged(_ViewMode.grid),
// //                         tooltip: 'Grid view',
// //                       ),
// //                     ],
// //                   )
// //                       : const SizedBox.shrink();
// //                 },
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // ---------------------------------------------------------------------------
// // // View toggle button helper
// // // ---------------------------------------------------------------------------
// //
// // class _ViewToggleButton extends StatelessWidget {
// //   final IconData icon;
// //   final bool isActive;
// //   final VoidCallback onTap;
// //   final String tooltip;
// //
// //   const _ViewToggleButton({
// //     required this.icon,
// //     required this.isActive,
// //     required this.onTap,
// //     required this.tooltip,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Tooltip(
// //       message: tooltip,
// //       child: GestureDetector(
// //         onTap: onTap,
// //         child: AnimatedContainer(
// //           duration: const Duration(milliseconds: 180),
// //           width: 32,
// //           height: 32,
// //           decoration: BoxDecoration(
// //             color: isActive ? AppConstants.primaryColor : const Color(0xFF1A1A1A),
// //             borderRadius: BorderRadius.circular(8),
// //             border: Border.all(
// //               color: isActive
// //                   ? AppConstants.primaryColor
// //                   : const Color(0xFF3A3A3A),
// //             ),
// //           ),
// //           child: Icon(
// //             icon,
// //             size: 17,
// //             color: isActive ? const Color(0xFF0A0A0A) : const Color(0xFF888888),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _CompactListTile  — the new phone-optimised row widget
// // // Shows ~7-8 items at once. Thumbnail | Name + category | Price + chips
// // // ===========================================================================
// //
// // class _CompactListTile extends StatelessWidget {
// //   final Map<String, dynamic> item;
// //   final String Function(dynamic) formatPrice;
// //   final VoidCallback onTap;
// //   final Map<String, bool> pricePermissions;
// //   final String? selectedPriceKey;
// //   final void Function(String priceKey, String priceLabel) onSelectPrice;
// //   final bool isLoadingPermissions;
// //   final bool canSelectPricesForQuotation;
// //
// //   const _CompactListTile({
// //     required this.item,
// //     required this.formatPrice,
// //     required this.onTap,
// //     required this.pricePermissions,
// //     required this.selectedPriceKey,
// //     required this.onSelectPrice,
// //     required this.isLoadingPermissions,
// //     required this.canSelectPricesForQuotation,
// //   });
// //
// //   String? _imageUrl() {
// //     final path = (item['image_path'] ?? '').toString().trim();
// //     if (path.isEmpty) return null;
// //     return Supabase.instance.client.storage
// //         .from('product-images')
// //         .getPublicUrl(path);
// //   }
// //
// //   double? _toDouble(dynamic v) {
// //     if (v == null) return null;
// //     if (v is num) return v.toDouble();
// //     return double.tryParse(v.toString());
// //   }
// //
// //   bool _isSelected() => selectedPriceKey != null;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final productName = (item['product_name'] ?? '').toString().trim();
// //     final category = (item['category_ar'] ?? '').toString().trim();
// //     final itemCode = (item['item_code'] ?? '').toString().trim();
// //     final effectivePrice = item['effective_price'];
// //     final imageUrl = _imageUrl();
// //     final isSelected = _isSelected();
// //
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 4),
// //       child: Material(
// //         color: Colors.transparent,
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(14),
// //           onTap: onTap,
// //           child: Ink(
// //             decoration: BoxDecoration(
// //               color: isSelected
// //                   ? const Color(0xFF1A1500)
// //                   : const Color(0xFF141414),
// //               borderRadius: BorderRadius.circular(14),
// //               border: Border.all(
// //                 color: isSelected
// //                     ? AppConstants.primaryColor
// //                     : const Color(0xFF2A2A2A),
// //               ),
// //             ),
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// //               child: Row(
// //                 children: [
// //                   // --- Thumbnail ---
// //                   ClipRRect(
// //                     borderRadius: BorderRadius.circular(9),
// //                     child: SizedBox(
// //                       width: 42,
// //                       height: 42,
// //                       child: imageUrl != null
// //                           ? CachedNetworkImage(
// //                         imageUrl: imageUrl,
// //                         fit: BoxFit.cover,
// //                         errorWidget: (_, __, ___) =>
// //                             _CompactPlaceholder(),
// //                       )
// //                           : _CompactPlaceholder(),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 10),
// //
// //                   // --- Name / category / code ---
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Text(
// //                           productName.isEmpty ? 'Unnamed Product' : productName,
// //                           textDirection: TextDirection.rtl,
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                           style: const TextStyle(
// //                             color: Color(0xFFF5E7B2),
// //                             fontWeight: FontWeight.w700,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                         const SizedBox(height: 2),
// //                         Row(
// //                           children: [
// //                             if (category.isNotEmpty)
// //                               Text(
// //                                 category,
// //                                 style: const TextStyle(
// //                                     color: Color(0xFF888888), fontSize: 10),
// //                               ),
// //                             if (category.isNotEmpty && itemCode.isNotEmpty)
// //                               const Text(' · ',
// //                                   style: TextStyle(
// //                                       color: Color(0xFF555555), fontSize: 10)),
// //                             if (itemCode.isNotEmpty)
// //                               Text(
// //                                 itemCode,
// //                                 style: const TextStyle(
// //                                     color: AppConstants.primaryColor,
// //                                     fontSize: 10,
// //                                     fontWeight: FontWeight.w600),
// //                               ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(width: 8),
// //
// //                   // --- Price + chips ---
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.end,
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       Text(
// //                         formatPrice(effectivePrice),
// //                         style: const TextStyle(
// //                           color: Color(0xFFFFD95E),
// //                           fontWeight: FontWeight.w800,
// //                           fontSize: 14,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 4),
// //                       if (isLoadingPermissions)
// //                         const SizedBox(
// //                           width: 40,
// //                           height: 3,
// //                           child: LinearProgressIndicator(),
// //                         )
// //                       else
// //                         Wrap(
// //                           spacing: 3,
// //                           runSpacing: 3,
// //                           alignment: WrapAlignment.end,
// //                           children: _priceOptions.map((option) {
// //                             final rawValue = item[option.key];
// //                             final numericValue = _toDouble(rawValue);
// //                             final exists = numericValue != null;
// //                             final allowed = canSelectPricesForQuotation &&
// //                                 (pricePermissions[option.key] ?? true) &&
// //                                 exists;
// //                             final selected = selectedPriceKey == option.key;
// //
// //                             if (!exists) return const SizedBox.shrink();
// //
// //                             return GestureDetector(
// //                               onTap: allowed
// //                                   ? () =>
// //                                   onSelectPrice(option.key, option.label)
// //                                   : null,
// //                               child: AnimatedContainer(
// //                                 duration: const Duration(milliseconds: 150),
// //                                 padding: const EdgeInsets.symmetric(
// //                                     horizontal: 5, vertical: 2),
// //                                 decoration: BoxDecoration(
// //                                   color: selected
// //                                       ? AppConstants.primaryColor
// //                                       : (allowed
// //                                       ? const Color(0xFF1E1E1E)
// //                                       : const Color(0xFF161616)),
// //                                   borderRadius: BorderRadius.circular(5),
// //                                   border: Border.all(
// //                                     color: selected
// //                                         ? AppConstants.primaryColor
// //                                         : const Color(0xFF333333),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   option.label,
// //                                   style: TextStyle(
// //                                     fontSize: 9,
// //                                     fontWeight: FontWeight.w700,
// //                                     color: selected
// //                                         ? const Color(0xFF0A0A0A)
// //                                         : (allowed
// //                                         ? const Color(0xFFCCAA44)
// //                                         : const Color(0xFF555555)),
// //                                   ),
// //                                 ),
// //                               ),
// //                             );
// //                           }).toList(),
// //                         ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _CompactPlaceholder extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: const Color(0xFF1A1A1A),
// //       alignment: Alignment.center,
// //       child: const Icon(
// //         Icons.local_florist_outlined,
// //         color: Color(0xFF3A2F0B),
// //         size: 20,
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _GridProductCard — compact card for grid mode
// // // Replaces the old _LuxuryProductCard with a tighter layout
// // // ===========================================================================
// //
// // class _GridProductCard extends StatelessWidget {
// //   final Map<String, dynamic> item;
// //   final String Function(dynamic) formatPrice;
// //   final VoidCallback onTap;
// //   final Map<String, bool> pricePermissions;
// //   final String? selectedPriceKey;
// //   final void Function(String priceKey, String priceLabel) onSelectPrice;
// //   final bool isLoadingPermissions;
// //   final bool canSelectPricesForQuotation;
// //
// //   const _GridProductCard({
// //     required this.item,
// //     required this.formatPrice,
// //     required this.onTap,
// //     required this.pricePermissions,
// //     required this.selectedPriceKey,
// //     required this.onSelectPrice,
// //     required this.isLoadingPermissions,
// //     required this.canSelectPricesForQuotation,
// //   });
// //
// //   String? _imageUrl() {
// //     final path = (item['image_path'] ?? '').toString().trim();
// //     if (path.isEmpty) return null;
// //     return Supabase.instance.client.storage
// //         .from('product-images')
// //         .getPublicUrl(path);
// //   }
// //
// //   double? _toDouble(dynamic v) {
// //     if (v == null) return null;
// //     if (v is num) return v.toDouble();
// //     return double.tryParse(v.toString());
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final productName = (item['product_name'] ?? '').toString().trim();
// //     final category = (item['category_ar'] ?? '').toString().trim();
// //     final itemCode = (item['item_code'] ?? '').toString().trim();
// //     final effectivePrice = item['effective_price'];
// //     final imageUrl = _imageUrl();
// //     final isSelected = selectedPriceKey != null;
// //
// //     return Material(
// //       color: Colors.transparent,
// //       child: InkWell(
// //         borderRadius: BorderRadius.circular(18),
// //         onTap: onTap,
// //         child: Ink(
// //           decoration: BoxDecoration(
// //             borderRadius: BorderRadius.circular(18),
// //             color: isSelected
// //                 ? const Color(0xFF1A1500)
// //                 : const Color(0xFF141414),
// //             border: Border.all(
// //               color: isSelected
// //                   ? AppConstants.primaryColor
// //                   : const Color(0xFF2A2A2A),
// //             ),
// //           ),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               // Image
// //               ClipRRect(
// //                 borderRadius:
// //                 const BorderRadius.vertical(top: Radius.circular(18)),
// //                 child: AspectRatio(
// //                   aspectRatio: 16 / 9,
// //                   child: imageUrl != null
// //                       ? CachedNetworkImage(
// //                     imageUrl: imageUrl,
// //                     fit: BoxFit.cover,
// //                     errorWidget: (_, __, ___) => _GridPlaceholder(),
// //                   )
// //                       : _GridPlaceholder(),
// //                 ),
// //               ),
// //
// //               // Content
// //               Expanded(
// //                 child: Padding(
// //                   padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Category + code
// //                       Row(
// //                         children: [
// //                           if (category.isNotEmpty)
// //                             Flexible(
// //                               child: Text(
// //                                 category,
// //                                 style: const TextStyle(
// //                                     color: Color(0xFF888888), fontSize: 10),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                             ),
// //                           if (category.isNotEmpty && itemCode.isNotEmpty)
// //                             const Text(' · ',
// //                                 style: TextStyle(
// //                                     color: Color(0xFF555555), fontSize: 10)),
// //                           if (itemCode.isNotEmpty)
// //                             Flexible(
// //                               child: Text(
// //                                 itemCode,
// //                                 style: const TextStyle(
// //                                     color: AppConstants.primaryColor,
// //                                     fontSize: 10,
// //                                     fontWeight: FontWeight.w600),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                             ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 4),
// //
// //                       // Product name
// //                       Text(
// //                         productName.isEmpty ? 'Unnamed Product' : productName,
// //                         textDirection: TextDirection.rtl,
// //                         maxLines: 2,
// //                         overflow: TextOverflow.ellipsis,
// //                         style: theme.textTheme.bodyMedium?.copyWith(
// //                           fontWeight: FontWeight.w700,
// //                           color: const Color(0xFFF5E7B2),
// //                           height: 1.3,
// //                           fontSize: 12,
// //                         ),
// //                       ),
// //
// //                       const Spacer(),
// //
// //                       // Price
// //                       Text(
// //                         formatPrice(effectivePrice),
// //                         style: const TextStyle(
// //                           color: Color(0xFFFFD95E),
// //                           fontWeight: FontWeight.w900,
// //                           fontSize: 15,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 6),
// //
// //                       // Price chips
// //                       if (isLoadingPermissions)
// //                         const LinearProgressIndicator()
// //                       else
// //                         Wrap(
// //                           spacing: 3,
// //                           runSpacing: 3,
// //                           children: _priceOptions.map((option) {
// //                             final rawValue = item[option.key];
// //                             final numericValue = _toDouble(rawValue);
// //                             final exists = numericValue != null;
// //                             final allowed = canSelectPricesForQuotation &&
// //                                 (pricePermissions[option.key] ?? true) &&
// //                                 exists;
// //                             final selected = selectedPriceKey == option.key;
// //
// //                             if (!exists) return const SizedBox.shrink();
// //
// //                             return GestureDetector(
// //                               onTap: allowed
// //                                   ? () =>
// //                                   onSelectPrice(option.key, option.label)
// //                                   : null,
// //                               child: AnimatedContainer(
// //                                 duration: const Duration(milliseconds: 150),
// //                                 padding: const EdgeInsets.symmetric(
// //                                     horizontal: 6, vertical: 3),
// //                                 decoration: BoxDecoration(
// //                                   color: selected
// //                                       ? AppConstants.primaryColor
// //                                       : (allowed
// //                                       ? const Color(0xFF1E1E1E)
// //                                       : const Color(0xFF161616)),
// //                                   borderRadius: BorderRadius.circular(5),
// //                                   border: Border.all(
// //                                     color: selected
// //                                         ? AppConstants.primaryColor
// //                                         : const Color(0xFF333333),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   option.label,
// //                                   style: TextStyle(
// //                                     fontSize: 9,
// //                                     fontWeight: FontWeight.w700,
// //                                     color: selected
// //                                         ? const Color(0xFF0A0A0A)
// //                                         : (allowed
// //                                         ? const Color(0xFFCCAA44)
// //                                         : const Color(0xFF555555)),
// //                                   ),
// //                                 ),
// //                               ),
// //                             );
// //                           }).toList(),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _GridPlaceholder extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: const Color(0xFF1A1A1A),
// //       alignment: Alignment.center,
// //       child: const Icon(
// //         Icons.local_florist_outlined,
// //         color: Color(0xFF3A2F0B),
// //         size: 28,
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // Payload builder
// // // ===========================================================================
// //
// // Map<String, dynamic> _buildPriceListItemPayload(Map<String, dynamic> source) {
// //   double? toDouble(dynamic value) {
// //     if (value == null) return null;
// //     if (value is num) return value.toDouble();
// //     final raw = value.toString().trim();
// //     if (raw.isEmpty) return null;
// //     return double.tryParse(raw);
// //   }
// //
// //   String? toText(dynamic value) {
// //     if (value == null) return null;
// //     final raw = value.toString().trim();
// //     return raw.isEmpty ? null : raw;
// //   }
// //
// //   String? displayPrice = toText(source['display_price']);
// //   final totalPrice = toDouble(source['total_price']);
// //
// //   if ((displayPrice == null || displayPrice.isEmpty) && totalPrice != null) {
// //     displayPrice = totalPrice == totalPrice.roundToDouble()
// //         ? totalPrice.toInt().toString()
// //         : totalPrice.toStringAsFixed(2);
// //   }
// //
// //   return {
// //     'category_ar': toText(source['category_ar']),
// //     'description': toText(source['description']),
// //     'product_name': toText(source['product_name']),
// //     'item_code': toText(source['item_code']),
// //     'price_ee': toDouble(source['price_ee']),
// //     'price_aa': toDouble(source['price_aa']),
// //     'price_a': toDouble(source['price_a']),
// //     'price_rr': toDouble(source['price_rr']),
// //     'price_r': toDouble(source['price_r']),
// //     'price_art': toDouble(source['price_art']),
// //     'pot_item_no': toText(source['pot_item_no']),
// //     'pot_price': toDouble(source['pot_price']),
// //     'additions': toText(source['additions']),
// //     'total_price': totalPrice,
// //     'display_price': displayPrice,
// //     'image_path': toText(source['image_path']),
// //     'length': toText(source['length']),
// //     'width': toText(source['width']),
// //     'production_time': toText(source['production_time']),
// //     'is_active': source['is_active'] == null
// //         ? true
// //         : source['is_active'] == true ||
// //         source['is_active'].toString().toLowerCase() == 'true' ||
// //         source['is_active'].toString() == '1',
// //   }..removeWhere((key, value) => value == null);
// // }
// //
// // // ===========================================================================
// // // _ProductDetailsSheet  (unchanged from original)
// // // ===========================================================================
// //
// // class _ProductDetailsSheet extends StatelessWidget {
// //   final Map<String, dynamic> item;
// //   final String Function(dynamic value) formatPrice;
// //
// //   const _ProductDetailsSheet({
// //     required this.item,
// //     required this.formatPrice,
// //   });
// //
// //   String? _imageUrlFromItem(Map<String, dynamic> item) {
// //     final imagePath = (item['image_path'] ?? '').toString().trim();
// //     if (imagePath.isEmpty) return null;
// //     return Supabase.instance.client.storage
// //         .from('product-images')
// //         .getPublicUrl(imagePath);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final productName = (item['product_name'] ?? '').toString().trim();
// //     final category = (item['category_ar'] ?? '').toString().trim();
// //     final description = (item['description'] ?? '').toString().trim();
// //     final itemCode = (item['item_code'] ?? '').toString().trim();
// //     final potItemNo = (item['pot_item_no'] ?? '').toString().trim();
// //     final additions = (item['additions'] ?? '').toString().trim();
// //     final imageUrl = _imageUrlFromItem(item);
// //
// //     return Container(
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF121212),
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
// //       ),
// //       child: SingleChildScrollView(
// //         padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             if (imageUrl != null) ...[
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: AspectRatio(
// //                   aspectRatio: 16 / 10,
// //                   child: CachedNetworkImage(
// //                     imageUrl: imageUrl,
// //                     fit: BoxFit.contain,
// //                     errorWidget: (_, __, ___) => _GridPlaceholder(),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //             ],
// //             Text(
// //               productName.isEmpty ? 'Unnamed Product' : productName,
// //               textDirection: TextDirection.rtl,
// //               style: theme.textTheme.headlineSmall
// //                   ?.copyWith(fontWeight: FontWeight.w900, height: 1.3),
// //             ),
// //             const SizedBox(height: 16),
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(20),
// //                 gradient: const LinearGradient(
// //                   colors: [Color(0xFF3A2F0B), Color(0xFF1B1B1B)],
// //                 ),
// //                 border: Border.all(color: const Color(0xFF5B4916)),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Image.asset('assets/icons/logo.png',
// //                       width: 28, height: 28, fit: BoxFit.contain),
// //                   const SizedBox(width: 10),
// //                   const Expanded(
// //                     child: Text('Effective Price',
// //                         style: TextStyle(
// //                             color: Color(0xFFF5E7B2),
// //                             fontWeight: FontWeight.w800)),
// //                   ),
// //                   Text(
// //                     formatPrice(item['effective_price']),
// //                     style: theme.textTheme.headlineSmall?.copyWith(
// //                         color: const Color(0xFFFFD95E),
// //                         fontWeight: FontWeight.w900),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 18),
// //             _DetailsSection(
// //               title: 'Basic Information',
// //               children: [
// //                 _InfoRow(label: 'Category', value: category, rtl: true),
// //                 _InfoRow(label: 'Description', value: description, rtl: true),
// //                 _InfoRow(label: 'Item Code', value: itemCode),
// //                 _InfoRow(label: 'Pot Item No', value: potItemNo),
// //                 _InfoRow(label: 'Additions', value: additions, rtl: true),
// //                 _InfoRow(
// //                     label: 'Display Price',
// //                     value: (item['display_price'] ?? '').toString()),
// //               ],
// //             ),
// //             const SizedBox(height: 16),
// //             _DetailsSection(
// //               title: 'Prices',
// //               children: [
// //                 _PriceRow(label: 'EE', value: formatPrice(item['price_ee'])),
// //                 _PriceRow(label: 'AA', value: formatPrice(item['price_aa'])),
// //                 _PriceRow(label: 'A', value: formatPrice(item['price_a'])),
// //                 _PriceRow(label: 'RR', value: formatPrice(item['price_rr'])),
// //                 _PriceRow(label: 'R', value: formatPrice(item['price_r'])),
// //                 _PriceRow(
// //                     label: 'ART', value: formatPrice(item['price_art'])),
// //                 _PriceRow(
// //                     label: 'Pot Price',
// //                     value: formatPrice(item['pot_price'])),
// //                 _PriceRow(
// //                     label: 'Total Price',
// //                     value: formatPrice(item['total_price'])),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _AddItemSheet  (unchanged)
// // // ===========================================================================
// //
// // class _AddItemSheet extends StatefulWidget {
// //   const _AddItemSheet();
// //
// //   @override
// //   State<_AddItemSheet> createState() => _AddItemSheetState();
// // }
// //
// // class _AddItemSheetState extends State<_AddItemSheet> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _categoryController = TextEditingController();
// //   final _descriptionController = TextEditingController();
// //   final _productNameController = TextEditingController();
// //   final _itemCodeController = TextEditingController();
// //   final _priceEeController = TextEditingController();
// //   final _priceAaController = TextEditingController();
// //   final _priceAController = TextEditingController();
// //   final _priceRrController = TextEditingController();
// //   final _priceRController = TextEditingController();
// //   final _priceArtController = TextEditingController();
// //   final _potItemNoController = TextEditingController();
// //   final _potPriceController = TextEditingController();
// //   final _additionsController = TextEditingController();
// //   final _totalPriceController = TextEditingController();
// //   final _displayPriceController = TextEditingController();
// //   final _imagePathController = TextEditingController();
// //   final _lengthController = TextEditingController();
// //   final _widthController = TextEditingController();
// //   final _productionTimeController = TextEditingController();
// //
// //   bool _isActive = true;
// //   bool _isSaving = false;
// //
// //   @override
// //   void dispose() {
// //     _categoryController.dispose();
// //     _descriptionController.dispose();
// //     _productNameController.dispose();
// //     _itemCodeController.dispose();
// //     _priceEeController.dispose();
// //     _priceAaController.dispose();
// //     _priceAController.dispose();
// //     _priceRrController.dispose();
// //     _priceRController.dispose();
// //     _priceArtController.dispose();
// //     _potItemNoController.dispose();
// //     _potPriceController.dispose();
// //     _additionsController.dispose();
// //     _totalPriceController.dispose();
// //     _displayPriceController.dispose();
// //     _imagePathController.dispose();
// //     _lengthController.dispose();
// //     _widthController.dispose();
// //     _productionTimeController.dispose();
// //     super.dispose();
// //   }
// //
// //   double? _toDouble(String value) {
// //     final raw = value.trim();
// //     if (raw.isEmpty) return null;
// //     return double.tryParse(raw);
// //   }
// //
// //   Future<void> _submit() async {
// //     if (_isSaving) return;
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     final payload = _buildPriceListItemPayload({
// //       'category_ar': _categoryController.text,
// //       'description': _descriptionController.text,
// //       'product_name': _productNameController.text,
// //       'item_code': _itemCodeController.text,
// //       'price_ee': _priceEeController.text,
// //       'price_aa': _priceAaController.text,
// //       'price_a': _priceAController.text,
// //       'price_rr': _priceRrController.text,
// //       'price_r': _priceRController.text,
// //       'price_art': _priceArtController.text,
// //       'pot_item_no': _potItemNoController.text,
// //       'pot_price': _potPriceController.text,
// //       'additions': _additionsController.text,
// //       'total_price': _totalPriceController.text,
// //       'display_price': _displayPriceController.text,
// //       'image_path': _imagePathController.text,
// //       'length': _lengthController.text,
// //       'width': _widthController.text,
// //       'production_time': _productionTimeController.text,
// //       'is_active': _isActive,
// //     });
// //
// //     setState(() => _isSaving = true);
// //
// //     try {
// //       await Supabase.instance.client.from('price_list_items').insert(payload);
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Item added successfully.')));
// //       Navigator.of(context).pop(true);
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
// //     } finally {
// //       if (mounted) setState(() => _isSaving = false);
// //     }
// //   }
// //
// //   Widget _field(
// //       String label,
// //       TextEditingController controller, {
// //         bool required = false,
// //         bool isNumeric = false,
// //         TextInputType? keyboardType,
// //         int maxLines = 1,
// //         String? hint,
// //       }) {
// //     return TextFormField(
// //       controller: controller,
// //       keyboardType: keyboardType,
// //       maxLines: maxLines,
// //       decoration: InputDecoration(labelText: label, hintText: hint),
// //       validator: (value) {
// //         if (required && (value == null || value.trim().isEmpty)) {
// //           return '$label is required';
// //         }
// //         if (isNumeric &&
// //             value != null &&
// //             value.trim().isNotEmpty &&
// //             _toDouble(value) == null) {
// //           return 'Invalid number';
// //         }
// //         return null;
// //       },
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// //     return Padding(
// //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// //       child: SingleChildScrollView(
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text('Add Item',
// //                   style: Theme.of(context)
// //                       .textTheme
// //                       .headlineSmall
// //                       ?.copyWith(fontWeight: FontWeight.w900)),
// //               const SizedBox(height: 16),
// //               _field('Product Name', _productNameController, required: true),
// //               const SizedBox(height: 12),
// //               _field('Category (Arabic)', _categoryController, required: true),
// //               const SizedBox(height: 12),
// //               _field('Item Code', _itemCodeController),
// //               const SizedBox(height: 12),
// //               _field('Description', _descriptionController, maxLines: 3),
// //               const SizedBox(height: 12),
// //               Wrap(
// //                 runSpacing: 12,
// //                 spacing: 12,
// //                 children: [
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price EE', _priceEeController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price AA', _priceAaController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price A', _priceAController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price RR', _priceRrController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price R', _priceRController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Price ART', _priceArtController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Pot Price', _potPriceController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                   SizedBox(
// //                       width: 180,
// //                       child: _field('Total Price', _totalPriceController,
// //                           isNumeric: true,
// //                           keyboardType: const TextInputType.numberWithOptions(
// //                               decimal: true))),
// //                 ],
// //               ),
// //               const SizedBox(height: 12),
// //               _field('Pot Item No', _potItemNoController),
// //               const SizedBox(height: 12),
// //               _field('Additions', _additionsController, maxLines: 2),
// //               const SizedBox(height: 12),
// //               _field('Length', _lengthController),
// //               const SizedBox(height: 12),
// //               _field('Width', _widthController),
// //               const SizedBox(height: 12),
// //               _field('Production Time', _productionTimeController),
// //               const SizedBox(height: 12),
// //               _field('Display Price', _displayPriceController),
// //               const SizedBox(height: 12),
// //               _field('Image Path', _imagePathController,
// //                   hint: 'Bucket path, e.g. flowers/item-1.jpg'),
// //               const SizedBox(height: 12),
// //               SwitchListTile(
// //                 contentPadding: EdgeInsets.zero,
// //                 value: _isActive,
// //                 onChanged: _isSaving
// //                     ? null
// //                     : (value) => setState(() => _isActive = value),
// //                 title: const Text('Active'),
// //               ),
// //               const SizedBox(height: 16),
// //               SizedBox(
// //                 width: double.infinity,
// //                 child: FilledButton.icon(
// //                   onPressed: _isSaving ? null : _submit,
// //                   icon: _isSaving
// //                       ? const SizedBox(
// //                       width: 18,
// //                       height: 18,
// //                       child: CircularProgressIndicator(strokeWidth: 2))
// //                       : const Icon(Icons.save_outlined),
// //                   label: Text(_isSaving ? 'Saving...' : 'Create Item'),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _BulkAddItemsSheet  (unchanged)
// // // ===========================================================================
// //
// // class _BulkAddItemsSheet extends StatefulWidget {
// //   const _BulkAddItemsSheet();
// //
// //   @override
// //   State<_BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
// // }
// //
// // class _BulkAddItemsSheetState extends State<_BulkAddItemsSheet> {
// //   final _inputController = TextEditingController();
// //   bool _isSaving = false;
// //   int _previewCount = 0;
// //   String? _previewError;
// //
// //   @override
// //   void dispose() {
// //     _inputController.dispose();
// //     super.dispose();
// //   }
// //
// //   List<Map<String, dynamic>> _parseRows(String raw) {
// //     final input = raw.trim();
// //     if (input.isEmpty) throw const FormatException('Paste at least one row.');
// //
// //     if (input.startsWith('[')) {
// //       final decoded = jsonDecode(input);
// //       if (decoded is! List) {
// //         throw const FormatException('JSON input must be an array of objects.');
// //       }
// //       final rows = decoded
// //           .map((e) =>
// //           _buildPriceListItemPayload(Map<String, dynamic>.from(e as Map)))
// //           .where((e) => e.isNotEmpty)
// //           .toList();
// //       for (final row in rows) {
// //         if ((row['product_name'] ?? '').toString().trim().isEmpty) {
// //           throw const FormatException('Each row must include product_name.');
// //         }
// //         if ((row['category_ar'] ?? '').toString().trim().isEmpty) {
// //           throw const FormatException('Each row must include category_ar.');
// //         }
// //       }
// //       return rows;
// //     }
// //
// //     List<List<dynamic>> table;
// //     try {
// //       table =
// //           const CsvDecoder(dynamicTyping: false).convert(input);
// //     } catch (_) {
// //       try {
// //         table = const CsvDecoder(fieldDelimiter: '\t', dynamicTyping: false)
// //             .convert(input);
// //       } catch (e) {
// //         throw FormatException('Invalid CSV/TSV format: $e');
// //       }
// //     }
// //
// //     if (table.length < 2) {
// //       throw const FormatException(
// //           'Provide a header row and at least one data row.');
// //     }
// //
// //     final headers = table.first
// //         .map((e) => e?.toString().trim() ?? '')
// //         .where((e) => e.isNotEmpty)
// //         .toList();
// //     if (headers.isEmpty) throw const FormatException('Header row is empty.');
// //
// //     final rows = <Map<String, dynamic>>[];
// //     for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
// //       final values = table[rowIndex];
// //       final rawRow = <String, dynamic>{};
// //       for (var col = 0; col < headers.length; col++) {
// //         rawRow[headers[col]] = col < values.length ? values[col] : null;
// //       }
// //       final payload = _buildPriceListItemPayload(rawRow);
// //       if ((payload['product_name'] ?? '').toString().trim().isEmpty) {
// //         throw FormatException('Row ${rowIndex + 1}: product_name is required.');
// //       }
// //       if ((payload['category_ar'] ?? '').toString().trim().isEmpty) {
// //         throw FormatException('Row ${rowIndex + 1}: category_ar is required.');
// //       }
// //       rows.add(payload);
// //     }
// //
// //     if (rows.isEmpty) throw const FormatException('No valid rows found.');
// //     return rows;
// //   }
// //
// //   void _updatePreview() {
// //     final raw = _inputController.text;
// //     if (raw.trim().isEmpty) {
// //       setState(() {
// //         _previewCount = 0;
// //         _previewError = null;
// //       });
// //       return;
// //     }
// //     try {
// //       final rows = _parseRows(raw);
// //       setState(() {
// //         _previewCount = rows.length;
// //         _previewError = null;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _previewCount = 0;
// //         _previewError = e.toString();
// //       });
// //     }
// //   }
// //
// //   Future<void> _submit() async {
// //     if (_isSaving) return;
// //     List<Map<String, dynamic>> rows;
// //     try {
// //       rows = _parseRows(_inputController.text);
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Invalid bulk input: $e')));
// //       return;
// //     }
// //     setState(() => _isSaving = true);
// //     try {
// //       await Supabase.instance.client.from('price_list_items').insert(rows);
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('${rows.length} items added successfully.')));
// //       Navigator.of(context).pop(true);
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(SnackBar(content: Text('Bulk insert failed: $e')));
// //     } finally {
// //       if (mounted) setState(() => _isSaving = false);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// //     return Padding(
// //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// //       child: SingleChildScrollView(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text('Add Bulk Items',
// //                 style: Theme.of(context)
// //                     .textTheme
// //                     .headlineSmall
// //                     ?.copyWith(fontWeight: FontWeight.w900)),
// //             const SizedBox(height: 8),
// //             const Text(
// //                 'Paste CSV, TSV, or JSON rows. Required columns: product_name, category_ar.'),
// //             const SizedBox(height: 12),
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF171717),
// //                 borderRadius: BorderRadius.circular(16),
// //                 border: Border.all(color: const Color(0xFF3A2F0B)),
// //               ),
// //               child: const SelectableText(
// //                 'Example CSV\n'
// //                     'product_name,category_ar,item_code,total_price,is_active\n'
// //                     '"Rose Box, Large",ورد,RB-100,125,true\n\n'
// //                     'Example JSON\n'
// //                     '[{"product_name":"Rose Box","category_ar":"ورد","item_code":"RB-100","total_price":125}]',
// //               ),
// //             ),
// //             const SizedBox(height: 12),
// //             TextField(
// //               controller: _inputController,
// //               onChanged: (_) => _updatePreview(),
// //               minLines: 10,
// //               maxLines: 18,
// //               decoration: const InputDecoration(
// //                 labelText: 'Bulk rows',
// //                 alignLabelWithHint: true,
// //                 hintText: 'Paste CSV / TSV / JSON here',
// //               ),
// //             ),
// //             const SizedBox(height: 12),
// //             if (_previewError != null)
// //               Text(_previewError!,
// //                   style: const TextStyle(color: Color(0xFFFFC7CE)))
// //             else if (_previewCount > 0)
// //               Text('Ready to insert $_previewCount item(s).',
// //                   style: const TextStyle(
// //                       color: AppConstants.primaryColor,
// //                       fontWeight: FontWeight.w700)),
// //             const SizedBox(height: 16),
// //             SizedBox(
// //               width: double.infinity,
// //               child: FilledButton.icon(
// //                 onPressed:
// //                 (_isSaving || _previewCount == 0 || _previewError != null)
// //                     ? null
// //                     : _submit,
// //                 icon: _isSaving
// //                     ? const SizedBox(
// //                     width: 18,
// //                     height: 18,
// //                     child: CircularProgressIndicator(strokeWidth: 2))
// //                     : const Icon(Icons.playlist_add_check_circle_outlined),
// //                 label:
// //                 Text(_isSaving ? 'Importing...' : 'Insert Bulk Items'),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // _CreateQuotationSheet  (unchanged)
// // // ===========================================================================
// //
// // class _CreateQuotationSheet extends StatefulWidget {
// //   final double subtotal;
// //   final String Function(dynamic value) formatPrice;
// //   final Map<String, dynamic> profile;
// //
// //   const _CreateQuotationSheet({
// //     required this.subtotal,
// //     required this.formatPrice,
// //     required this.profile,
// //   });
// //
// //   @override
// //   State<_CreateQuotationSheet> createState() =>
// //       _CreateQuotationSheetState();
// // }
// //
// // class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
// //   final _formKey = GlobalKey<FormState>();
// //
// //   final _customerNameController = TextEditingController();
// //   final _companyNameController = TextEditingController();
// //   final _customerTrnController = TextEditingController();
// //   final _customerPhoneController = TextEditingController();
// //   final _salespersonNameController = TextEditingController();
// //   final _salespersonContactController = TextEditingController();
// //   final _notesController = TextEditingController();
// //
// //   final _deliveryFeeController = TextEditingController(text: '0');
// //   final _installationFeeController = TextEditingController(text: '0');
// //   final _additionalDetailsFeeController = TextEditingController(text: '0');
// //   final _vatPercentController = TextEditingController(text: '5');
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     final fullName = (widget.profile['full_name'] ?? '').toString().trim();
// //     final email = (widget.profile['email'] ?? '').toString().trim();
// //     _salespersonNameController.text = fullName;
// //     _salespersonContactController.text = email;
// //   }
// //
// //   @override
// //   void dispose() {
// //     _customerNameController.dispose();
// //     _companyNameController.dispose();
// //     _customerTrnController.dispose();
// //     _customerPhoneController.dispose();
// //     _salespersonNameController.dispose();
// //     _salespersonContactController.dispose();
// //     _notesController.dispose();
// //     _deliveryFeeController.dispose();
// //     _installationFeeController.dispose();
// //     _additionalDetailsFeeController.dispose();
// //     _vatPercentController.dispose();
// //     super.dispose();
// //   }
// //
// //   double _parseNumber(String value) =>
// //       double.tryParse(value.trim()) ?? 0;
// //
// //   double get _deliveryFee => _parseNumber(_deliveryFeeController.text);
// //   double get _installationFee =>
// //       _parseNumber(_installationFeeController.text);
// //   double get _additionalDetailsFee =>
// //       _parseNumber(_additionalDetailsFeeController.text);
// //   double get _vatPercent => _parseNumber(_vatPercentController.text);
// //
// //   double get _taxableTotal =>
// //       widget.subtotal + _deliveryFee + _installationFee + _additionalDetailsFee;
// //   double get _vatAmount => _taxableTotal * (_vatPercent / 100);
// //   double get _netTotal => _taxableTotal + _vatAmount;
// //
// //   String? _validateNumber(String? value) {
// //     if (value == null || value.trim().isEmpty) return null;
// //     if (double.tryParse(value.trim()) == null) return 'Invalid number';
// //     return null;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
// //     return Padding(
// //       padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
// //       child: SingleChildScrollView(
// //         child: Form(
// //           key: _formKey,
// //           child: StatefulBuilder(
// //             builder: (context, setLocalState) {
// //               return Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text('Create Quotation',
// //                       style: Theme.of(context)
// //                           .textTheme
// //                           .headlineSmall
// //                           ?.copyWith(fontWeight: FontWeight.w900)),
// //                   const SizedBox(height: 16),
// //                   TextFormField(
// //                     controller: _customerNameController,
// //                     decoration:
// //                     const InputDecoration(labelText: 'Customer Name'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _companyNameController,
// //                     decoration:
// //                     const InputDecoration(labelText: 'Company Name'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _customerTrnController,
// //                     decoration:
// //                     const InputDecoration(labelText: 'Customer TRN'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _customerPhoneController,
// //                     keyboardType: TextInputType.phone,
// //                     decoration:
// //                     const InputDecoration(labelText: 'Customer Phone'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     enabled: false,
// //                     controller: _salespersonNameController,
// //                     decoration:
// //                     const InputDecoration(labelText: 'Salesperson Name'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     enabled: false,
// //                     controller: _salespersonContactController,
// //                     decoration: const InputDecoration(
// //                         labelText: 'Salesperson Contact'),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _deliveryFeeController,
// //                     keyboardType:
// //                     const TextInputType.numberWithOptions(decimal: true),
// //                     decoration:
// //                     const InputDecoration(labelText: 'Delivery Fee'),
// //                     validator: _validateNumber,
// //                     onChanged: (_) => setLocalState(() {}),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _installationFeeController,
// //                     keyboardType:
// //                     const TextInputType.numberWithOptions(decimal: true),
// //                     decoration:
// //                     const InputDecoration(labelText: 'Installation Fee'),
// //                     validator: _validateNumber,
// //                     onChanged: (_) => setLocalState(() {}),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _additionalDetailsFeeController,
// //                     keyboardType:
// //                     const TextInputType.numberWithOptions(decimal: true),
// //                     decoration: const InputDecoration(
// //                         labelText: 'Additional Details Fee'),
// //                     validator: _validateNumber,
// //                     onChanged: (_) => setLocalState(() {}),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _vatPercentController,
// //                     keyboardType:
// //                     const TextInputType.numberWithOptions(decimal: true),
// //                     decoration:
// //                     const InputDecoration(labelText: 'VAT Percent'),
// //                     validator: _validateNumber,
// //                     onChanged: (_) => setLocalState(() {}),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextFormField(
// //                     controller: _notesController,
// //                     maxLines: 4,
// //                     decoration: const InputDecoration(labelText: 'Notes'),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   Container(
// //                     width: double.infinity,
// //                     padding: const EdgeInsets.all(16),
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFF171717),
// //                       borderRadius: BorderRadius.circular(16),
// //                       border: Border.all(color: const Color(0xFF3A2F0B)),
// //                     ),
// //                     child: Column(
// //                       children: [
// //                         Row(children: [
// //                           const Expanded(child: Text('Subtotal')),
// //                           Text(widget.formatPrice(widget.subtotal)),
// //                         ]),
// //                         const SizedBox(height: 8),
// //                         Row(children: [
// //                           const Expanded(child: Text('Taxable Total')),
// //                           Text(widget.formatPrice(_taxableTotal)),
// //                         ]),
// //                         const SizedBox(height: 8),
// //                         Row(children: [
// //                           Expanded(
// //                               child: Text(
// //                                   'VAT (${widget.formatPrice(_vatPercent)}%)')),
// //                           Text(widget.formatPrice(_vatAmount)),
// //                         ]),
// //                         const SizedBox(height: 8),
// //                         Row(children: [
// //                           const Expanded(
// //                               child: Text('Net Total',
// //                                   style: TextStyle(
// //                                       fontWeight: FontWeight.w900))),
// //                           Text(
// //                             widget.formatPrice(_netTotal),
// //                             style: const TextStyle(
// //                               color: Color(0xFFFFD95E),
// //                               fontWeight: FontWeight.w900,
// //                               fontSize: 18,
// //                             ),
// //                           ),
// //                         ]),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: FilledButton.icon(
// //                       onPressed: () {
// //                         if (!_formKey.currentState!.validate()) return;
// //                         Navigator.pop(
// //                           context,
// //                           _QuotationDraft(
// //                             customerName:
// //                             _customerNameController.text.trim(),
// //                             companyName: _companyNameController.text.trim(),
// //                             customerTrn: _customerTrnController.text.trim(),
// //                             customerPhone:
// //                             _customerPhoneController.text.trim(),
// //                             salespersonName:
// //                             _salespersonNameController.text.trim(),
// //                             salespersonContact:
// //                             _salespersonContactController.text.trim(),
// //                             notes: _notesController.text.trim(),
// //                             deliveryFee: _deliveryFee,
// //                             installationFee: _installationFee,
// //                             additionalDetailsFee: _additionalDetailsFee,
// //                             vatPercent: _vatPercent,
// //                             salespersonPhone: widget.profile['phone'],
// //                           ),
// //                         );
// //                       },
// //                       icon: const Icon(Icons.save_outlined),
// //                       label: const Text('Save Quotation'),
// //                     ),
// //                   ),
// //                 ],
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // Detail UI helpers (unchanged)
// // // ===========================================================================
// //
// // class _DetailsSection extends StatelessWidget {
// //   final String title;
// //   final List<Widget> children;
// //
// //   const _DetailsSection({required this.title, required this.children});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF151515),
// //         borderRadius: BorderRadius.circular(22),
// //         border: Border.all(color: const Color(0xFF3A2F0B)),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             title,
// //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //                 color: AppConstants.primaryColor,
// //                 fontWeight: FontWeight.w900),
// //           ),
// //           const SizedBox(height: 12),
// //           ...children,
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _InfoRow extends StatelessWidget {
// //   final String label;
// //   final String value;
// //   final bool rtl;
// //
// //   const _InfoRow({required this.label, required this.value, this.rtl = false});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (value.trim().isEmpty) return const SizedBox.shrink();
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 7),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           SizedBox(
// //             width: 110,
// //             child: Text(label,
// //                 style: const TextStyle(
// //                     color: AppConstants.primaryColor,
// //                     fontWeight: FontWeight.w700)),
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               value,
// //               textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
// //               style: const TextStyle(
// //                   color: Color(0xFFF5E7B2), height: 1.35),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _PriceRow extends StatelessWidget {
// //   final String label;
// //   final String value;
// //
// //   const _PriceRow({required this.label, required this.value});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (value == '-' || value.trim().isEmpty) return const SizedBox.shrink();
// //     return Container(
// //       margin: const EdgeInsets.symmetric(vertical: 5),
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF1A1A1A),
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(color: const Color(0xFF2F2A18)),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Text(label,
// //                 style: const TextStyle(
// //                     color: AppConstants.primaryColor,
// //                     fontWeight: FontWeight.w800)),
// //           ),
// //           Text(value,
// //               style: const TextStyle(
// //                   color: Color(0xFFF5E7B2), fontWeight: FontWeight.w700)),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // ===========================================================================
// // // PricePermissionsScreen  (unchanged)
// // // ===========================================================================
// //
// // class PricePermissionsScreen extends StatefulWidget {
// //   const PricePermissionsScreen({super.key});
// //
// //   @override
// //   State<PricePermissionsScreen> createState() =>
// //       _PricePermissionsScreenState();
// // }
// //
// // class _PricePermissionsScreenState extends State<PricePermissionsScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //
// //   bool _isLoading = true;
// //   bool _isSavingGlobal = false;
// //   String? _error;
// //
// //   bool _globalBlockAll = false;
// //   final Set<String> _globalBlockedKeys = {};
// //
// //   List<Map<String, dynamic>> _users = [];
// //   Map<String, bool> _userBlockAll = {};
// //   Map<String, Set<String>> _userBlockedKeys = {};
// //
// //   final TextEditingController _userSearchController = TextEditingController();
// //   final Set<String> _savingUserIds = {};
// //   bool _isSavingAllUsers = false;
// //   String _userSearchQuery = '';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _userSearchController.addListener(() {
// //       if (!mounted) return;
// //       setState(() =>
// //       _userSearchQuery = _userSearchController.text.trim().toLowerCase());
// //     });
// //     _loadData();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _userSearchController.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> _loadData() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final settingsResponse = await _supabase
// //           .from('price_permission_settings')
// //           .select('id, block_all_prices')
// //           .eq('id', 1)
// //           .maybeSingle();
// //
// //       final globalBlockedResponse =
// //       await _supabase.from('global_blocked_price_keys').select('price_key');
// //
// //       final usersResponse = await _supabase
// //           .from('profiles')
// //           .select('id, email, full_name, role, is_active')
// //           .order('full_name', ascending: true);
// //
// //       final profileAccessResponse = await _supabase
// //           .from('profile_price_access')
// //           .select('profile_id, block_all_prices');
// //
// //       final profileBlockedResponse = await _supabase
// //           .from('profile_blocked_price_keys')
// //           .select('profile_id, price_key');
// //
// //       final users = (usersResponse as List)
// //           .map((e) => Map<String, dynamic>.from(e as Map))
// //           .where((e) => (e['role'] ?? '').toString() == 'sales')
// //           .toList();
// //
// //       final globalBlocked = <String>{};
// //       for (final row in (globalBlockedResponse as List)) {
// //         final map = Map<String, dynamic>.from(row as Map);
// //         final key = (map['price_key'] ?? '').toString();
// //         if (key.isNotEmpty) globalBlocked.add(key);
// //       }
// //
// //       final userBlockAll = <String, bool>{};
// //       for (final row in (profileAccessResponse as List)) {
// //         final map = Map<String, dynamic>.from(row as Map);
// //         final profileId = (map['profile_id'] ?? '').toString();
// //         if (profileId.isEmpty) continue;
// //         userBlockAll[profileId] = map['block_all_prices'] == true;
// //       }
// //
// //       final userBlockedKeys = <String, Set<String>>{};
// //       for (final row in (profileBlockedResponse as List)) {
// //         final map = Map<String, dynamic>.from(row as Map);
// //         final profileId = (map['profile_id'] ?? '').toString();
// //         final key = (map['price_key'] ?? '').toString();
// //         if (profileId.isEmpty || key.isEmpty) continue;
// //         userBlockedKeys.putIfAbsent(profileId, () => <String>{}).add(key);
// //       }
// //
// //       for (final user in users) {
// //         final id = (user['id'] ?? '').toString();
// //         userBlockAll.putIfAbsent(id, () => false);
// //         userBlockedKeys.putIfAbsent(id, () => <String>{});
// //       }
// //
// //       if (!mounted) return;
// //       setState(() {
// //         _globalBlockAll = settingsResponse?['block_all_prices'] == true;
// //         _globalBlockedKeys..clear()..addAll(globalBlocked);
// //         _users = users;
// //         _userBlockAll = userBlockAll;
// //         _userBlockedKeys = userBlockedKeys;
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() {
// //         _error = e.toString();
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _saveGlobalSettings() async {
// //     if (_isSavingGlobal) return;
// //     setState(() => _isSavingGlobal = true);
// //     try {
// //       await _supabase.from('price_permission_settings').upsert({
// //         'id': 1,
// //         'block_all_prices': _globalBlockAll,
// //       });
// //       await _supabase.from('global_blocked_price_keys').delete().neq('id', 0);
// //       if (_globalBlockedKeys.isNotEmpty) {
// //         await _supabase.from('global_blocked_price_keys').insert(
// //             _globalBlockedKeys.map((key) => {'price_key': key}).toList());
// //       }
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Global price permissions saved.')));
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to save global settings: $e')));
// //     } finally {
// //       if (mounted) setState(() => _isSavingGlobal = false);
// //     }
// //   }
// //
// //   Future<void> _saveUserPermissions(String profileId) async {
// //     if (_savingUserIds.contains(profileId)) return;
// //     setState(() => _savingUserIds.add(profileId));
// //     try {
// //       await _supabase.from('profile_price_access').upsert({
// //         'profile_id': profileId,
// //         'block_all_prices': _userBlockAll[profileId] ?? false,
// //       });
// //       await _supabase
// //           .from('profile_blocked_price_keys')
// //           .delete()
// //           .eq('profile_id', profileId);
// //       final blocked = _userBlockedKeys[profileId] ?? <String>{};
// //       if (blocked.isNotEmpty) {
// //         await _supabase.from('profile_blocked_price_keys').insert(
// //             blocked.map((key) => {'profile_id': profileId, 'price_key': key}).toList());
// //       }
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('User price permissions saved.')));
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to save user permissions: $e')));
// //     } finally {
// //       if (mounted) setState(() => _savingUserIds.remove(profileId));
// //     }
// //   }
// //
// //   String _userDisplayName(Map<String, dynamic> user) {
// //     final fullName = (user['full_name'] ?? '').toString().trim();
// //     final email = (user['email'] ?? '').toString().trim();
// //     if (fullName.isNotEmpty) return fullName;
// //     if (email.isNotEmpty) return email;
// //     return 'Unknown User';
// //   }
// //
// //   List<Map<String, dynamic>> get _filteredUsers {
// //     if (_userSearchQuery.isEmpty) return _users;
// //     return _users.where((user) {
// //       final name = _userDisplayName(user).toLowerCase();
// //       final email = (user['email'] ?? '').toString().trim().toLowerCase();
// //       return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
// //     }).toList();
// //   }
// //
// //   Future<void> _saveAllUserPermissions() async {
// //     if (_isSavingAllUsers) return;
// //     setState(() => _isSavingAllUsers = true);
// //     try {
// //       for (final user in _filteredUsers) {
// //         final profileId = (user['id'] ?? '').toString();
// //         if (profileId.isEmpty) continue;
// //         setState(() => _savingUserIds.add(profileId));
// //         await _supabase.from('profile_price_access').upsert({
// //           'profile_id': profileId,
// //           'block_all_prices': _userBlockAll[profileId] ?? false,
// //         });
// //         await _supabase
// //             .from('profile_blocked_price_keys')
// //             .delete()
// //             .eq('profile_id', profileId);
// //         final blocked = _userBlockedKeys[profileId] ?? <String>{};
// //         if (blocked.isNotEmpty) {
// //           await _supabase.from('profile_blocked_price_keys').insert(blocked
// //               .map((key) => {'profile_id': profileId, 'price_key': key})
// //               .toList());
// //         }
// //         if (mounted) setState(() => _savingUserIds.remove(profileId));
// //       }
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text(
// //               'Saved ${_filteredUsers.length} user permission set(s).')));
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to save all user settings: $e')));
// //     } finally {
// //       if (mounted) setState(() { _isSavingAllUsers = false; _savingUserIds.clear(); });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF0A0A0A),
// //       appBar: AppBar(
// //         title: const Text('Price Permissions'),
// //         backgroundColor: const Color(0xFF111111),
// //       ),
// //       body: _isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : _error != null
// //           ? Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Text(_error!, textAlign: TextAlign.center),
// //               const SizedBox(height: 12),
// //               FilledButton(
// //                   onPressed: _loadData,
// //                   child: const Text('Retry')),
// //             ],
// //           ),
// //         ),
// //       )
// //           : RefreshIndicator(
// //         onRefresh: _loadData,
// //         child: ListView(
// //           padding: const EdgeInsets.all(16),
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF141414),
// //                 borderRadius: BorderRadius.circular(20),
// //                 border:
// //                 Border.all(color: const Color(0xFF3A2F0B)),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text('Global Controls',
// //                       style: theme.textTheme.titleLarge
// //                           ?.copyWith(fontWeight: FontWeight.w900)),
// //                   const SizedBox(height: 12),
// //                   SwitchListTile(
// //                     contentPadding: EdgeInsets.zero,
// //                     title: const Text(
// //                         'Block all prices for all users'),
// //                     value: _globalBlockAll,
// //                     onChanged: (value) =>
// //                         setState(() => _globalBlockAll = value),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text('Blocked price keys for all users',
// //                       style: theme.textTheme.titleMedium?.copyWith(
// //                           fontWeight: FontWeight.w800,
// //                           color: AppConstants.primaryColor)),
// //                   const SizedBox(height: 10),
// //                   Wrap(
// //                     spacing: 8,
// //                     runSpacing: 8,
// //                     children: _priceOptions.map((option) {
// //                       final blocked =
// //                       _globalBlockedKeys.contains(option.key);
// //                       return FilterChip(
// //                         label: Text(option.label),
// //                         selected: blocked,
// //                         onSelected: (selected) {
// //                           setState(() {
// //                             if (selected) {
// //                               _globalBlockedKeys.add(option.key);
// //                             } else {
// //                               _globalBlockedKeys.remove(option.key);
// //                             }
// //                           });
// //                         },
// //                         selectedColor: AppConstants.primaryColor,
// //                         backgroundColor: const Color(0xFF1A1A1A),
// //                         labelStyle: TextStyle(
// //                           color: blocked
// //                               ? const Color(0xFF0A0A0A)
// //                               : const Color(0xFFF5E7B2),
// //                           fontWeight: FontWeight.w800,
// //                         ),
// //                       );
// //                     }).toList(),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: FilledButton.icon(
// //                       onPressed: _isSavingGlobal
// //                           ? null
// //                           : _saveGlobalSettings,
// //                       icon: _isSavingGlobal
// //                           ? const SizedBox(
// //                           width: 18,
// //                           height: 18,
// //                           child: CircularProgressIndicator(
// //                               strokeWidth: 2))
// //                           : const Icon(Icons.save_outlined),
// //                       label: Text(_isSavingGlobal
// //                           ? 'Saving...'
// //                           : 'Save Global Settings'),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 18),
// //             Text('Per-User Controls',
// //                 style: theme.textTheme.titleLarge
// //                     ?.copyWith(fontWeight: FontWeight.w900)),
// //             const SizedBox(height: 12),
// //             TextField(
// //               controller: _userSearchController,
// //               decoration: const InputDecoration(
// //                 labelText: 'Search users',
// //                 hintText: 'Search by name or email',
// //                 prefixIcon: Icon(Icons.search_rounded),
// //               ),
// //             ),
// //             const SizedBox(height: 12),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: Text('${_filteredUsers.length} user(s)',
// //                       style: theme.textTheme.bodyMedium
// //                           ?.copyWith(fontWeight: FontWeight.w700)),
// //                 ),
// //                 FilledButton.icon(
// //                   onPressed:
// //                   (_isSavingAllUsers || _filteredUsers.isEmpty)
// //                       ? null
// //                       : _saveAllUserPermissions,
// //                   icon: _isSavingAllUsers
// //                       ? const SizedBox(
// //                       width: 18,
// //                       height: 18,
// //                       child: CircularProgressIndicator(
// //                           strokeWidth: 2))
// //                       : const Icon(Icons.save_outlined),
// //                   label: Text(_isSavingAllUsers
// //                       ? 'Saving...'
// //                       : 'Save All Visible Users'),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 12),
// //             ..._filteredUsers.map((user) {
// //               final profileId = (user['id'] ?? '').toString();
// //               final blockedKeys =
// //                   _userBlockedKeys[profileId] ?? <String>{};
// //               final blockAll = _userBlockAll[profileId] ?? false;
// //               final isActive = user['is_active'] == true;
// //
// //               return Container(
// //                 margin: const EdgeInsets.only(bottom: 14),
// //                 padding: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF141414),
// //                   borderRadius: BorderRadius.circular(20),
// //                   border: Border.all(
// //                       color: const Color(0xFF3A2F0B)),
// //                 ),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Row(
// //                       children: [
// //                         Expanded(
// //                           child: Column(
// //                             crossAxisAlignment:
// //                             CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 _userDisplayName(user),
// //                                 style: theme.textTheme.titleMedium
// //                                     ?.copyWith(
// //                                     fontWeight:
// //                                     FontWeight.w900),
// //                               ),
// //                               const SizedBox(height: 4),
// //                               Text(
// //                                   (user['email'] ?? '').toString(),
// //                                   style: theme.textTheme.bodySmall),
// //                             ],
// //                           ),
// //                         ),
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(
// //                               horizontal: 10, vertical: 6),
// //                           decoration: BoxDecoration(
// //                             color: isActive
// //                                 ? const Color(0xFF1F3A1F)
// //                                 : const Color(0xFF3A1F1F),
// //                             borderRadius:
// //                             BorderRadius.circular(999),
// //                           ),
// //                           child: Text(
// //                             isActive ? 'ACTIVE' : 'INACTIVE',
// //                             style: const TextStyle(
// //                                 fontWeight: FontWeight.w800,
// //                                 fontSize: 11),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 12),
// //                     SwitchListTile(
// //                       contentPadding: EdgeInsets.zero,
// //                       title: const Text(
// //                           'Block all prices for this user'),
// //                       value: blockAll,
// //                       onChanged: (value) => setState(
// //                               () => _userBlockAll[profileId] = value),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Text(
// //                       'Blocked price keys for this user',
// //                       style: theme.textTheme.titleSmall?.copyWith(
// //                           fontWeight: FontWeight.w800,
// //                           color: AppConstants.primaryColor),
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Wrap(
// //                       spacing: 8,
// //                       runSpacing: 8,
// //                       children: _priceOptions.map((option) {
// //                         final blocked =
// //                         blockedKeys.contains(option.key);
// //                         return FilterChip(
// //                           label: Text(option.label),
// //                           selected: blocked,
// //                           onSelected: (selected) {
// //                             setState(() {
// //                               final set =
// //                               _userBlockedKeys.putIfAbsent(
// //                                   profileId, () => <String>{});
// //                               if (selected) {
// //                                 set.add(option.key);
// //                               } else {
// //                                 set.remove(option.key);
// //                               }
// //                             });
// //                           },
// //                           selectedColor: AppConstants.primaryColor,
// //                           backgroundColor: const Color(0xFF1A1A1A),
// //                           labelStyle: TextStyle(
// //                             color: blocked
// //                                 ? const Color(0xFF0A0A0A)
// //                                 : const Color(0xFFF5E7B2),
// //                             fontWeight: FontWeight.w800,
// //                           ),
// //                         );
// //                       }).toList(),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     SizedBox(
// //                       width: double.infinity,
// //                       child: OutlinedButton.icon(
// //                         onPressed:
// //                         _savingUserIds.contains(profileId)
// //                             ? null
// //                             : () => _saveUserPermissions(
// //                             profileId),
// //                         icon: _savingUserIds.contains(profileId)
// //                             ? const SizedBox(
// //                             width: 18,
// //                             height: 18,
// //                             child: CircularProgressIndicator(
// //                                 strokeWidth: 2))
// //                             : const Icon(Icons.save_outlined),
// //                         label: Text(
// //                           _savingUserIds.contains(profileId)
// //                               ? 'Saving...'
// //                               : 'Save User Settings',
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'dart:async';
// import 'dart:convert';
//
// import 'package:FlowerCenterCrm/user_role_management_screen.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:csv/csv.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'container_processor_screen.dart';
// import 'core/constants/app_constants.dart';
// import 'quotation_details_screen.dart';
// import 'quotation_list_screen.dart';
// import 'scanner.dart';
//
// class _PriceOptionMeta {
//   final String key;
//   final String label;
//
//   const _PriceOptionMeta(this.key, this.label);
// }
//
// const List<_PriceOptionMeta> _priceOptions = [
//   _PriceOptionMeta('price_ee', 'EE'),
//   _PriceOptionMeta('price_aa', 'AA'),
//   _PriceOptionMeta('price_a', 'A'),
//   _PriceOptionMeta('price_rr', 'RR'),
//   _PriceOptionMeta('price_r', 'R'),
//   _PriceOptionMeta('price_art', 'ART'),
// ];
//
// enum _CatalogViewMode {
//   compactGrid,
//   comfortableGrid,
//   list,
// }
//
// class _SelectedQuoteItem {
//   final int itemId;
//   final String productName;
//   final String priceKey;
//   final String priceLabel;
//   final double unitPrice;
//   final int quantity;
//   final Map<String, dynamic> item;
//
//   const _SelectedQuoteItem({
//     required this.itemId,
//     required this.productName,
//     required this.priceKey,
//     required this.priceLabel,
//     required this.unitPrice,
//     required this.quantity,
//     required this.item,
//   });
//
//   _SelectedQuoteItem copyWith({
//     String? priceKey,
//     String? priceLabel,
//     double? unitPrice,
//     int? quantity,
//   }) {
//     return _SelectedQuoteItem(
//       itemId: itemId,
//       productName: productName,
//       priceKey: priceKey ?? this.priceKey,
//       priceLabel: priceLabel ?? this.priceLabel,
//       unitPrice: unitPrice ?? this.unitPrice,
//       quantity: quantity ?? this.quantity,
//       item: item,
//     );
//   }
//
//   double get lineTotal => unitPrice * quantity;
// }
//
// class _QuotationDraft {
//   final String customerName;
//   final String companyName;
//   final String customerTrn;
//   final String customerPhone;
//   final String salespersonName;
//   final String salespersonContact;
//   final String salespersonPhone;
//   final String notes;
//   final double deliveryFee;
//   final double installationFee;
//   final double additionalDetailsFee;
//   final double vatPercent;
//
//   const _QuotationDraft({
//     required this.customerName,
//     required this.companyName,
//     required this.customerTrn,
//     required this.customerPhone,
//     required this.salespersonName,
//     required this.salespersonContact,
//     required this.salespersonPhone,
//     required this.notes,
//     required this.deliveryFee,
//     required this.installationFee,
//     required this.additionalDetailsFee,
//     required this.vatPercent,
//   });
// }
//
// int? _safeInt(dynamic value) {
//   if (value == null) return null;
//   if (value is int) return value;
//   if (value is num) return value.toInt();
//   return int.tryParse(value.toString().trim());
// }
//
// double _safeDouble(dynamic value) {
//   if (value == null) return 0;
//   if (value is num) return value.toDouble();
//   return double.tryParse(value.toString().trim()) ?? 0;
// }
//
// Map<String, dynamic> _buildPriceListItemPayload(Map<String, dynamic> source) {
//   double? toDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is num) return value.toDouble();
//     final raw = value.toString().trim();
//     if (raw.isEmpty) return null;
//     return double.tryParse(raw);
//   }
//
//   String? toText(dynamic value) {
//     if (value == null) return null;
//     final raw = value.toString().trim();
//     return raw.isEmpty ? null : raw;
//   }
//
//   String? displayPrice = toText(source['display_price']);
//   final totalPrice = toDouble(source['total_price']);
//
//   if ((displayPrice == null || displayPrice.isEmpty) && totalPrice != null) {
//     displayPrice = totalPrice == totalPrice.roundToDouble()
//         ? totalPrice.toInt().toString()
//         : totalPrice.toStringAsFixed(2);
//   }
//
//   return {
//     'category_ar': toText(source['category_ar']),
//     'description': toText(source['description']),
//     'product_name': toText(source['product_name']),
//     'item_code': toText(source['item_code']),
//     'barcode': toText(source['barcode']),
//     'price_ee': toDouble(source['price_ee']),
//     'price_aa': toDouble(source['price_aa']),
//     'price_a': toDouble(source['price_a']),
//     'price_rr': toDouble(source['price_rr']),
//     'price_r': toDouble(source['price_r']),
//     'price_art': toDouble(source['price_art']),
//     'pot_item_no': toText(source['pot_item_no']),
//     'pot_price': toDouble(source['pot_price']),
//     'additions': toText(source['additions']),
//     'total_price': totalPrice,
//     'display_price': displayPrice,
//     'image_path': toText(source['image_path']),
//     'length': toText(source['length']),
//     'width': toText(source['width']),
//     'production_time': toText(source['production_time']),
//     'is_active': source['is_active'] == false ? false : true,
//   }..removeWhere((key, value) => value == null);
// }
//
// class PriceListScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//
//   const PriceListScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//   });
//
//   @override
//   State<PriceListScreen> createState() => _PriceListScreenState();
// }
//
// class _PriceListScreenState extends State<PriceListScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final TextEditingController _searchController = TextEditingController();
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   bool get _isAdmin => _role == 'admin';
//   bool get _isSales => _role == 'sales';
//   bool get _isAccountant => _role == 'accountant';
//   bool get _isViewer => _role == 'viewer';
//
//   bool get _canCreateQuotation => _isSales || _isAdmin;
//   bool get _canViewQuotations => _isSales || _isAdmin;
//   bool get _canManagePricePermissions => _isAdmin || _isAccountant;
//   bool get _canAddItems => _isAdmin || _isAccountant;
//   bool get _canManageUsers => _isAdmin;
//   bool get _canUseContainerProcessor => _isAdmin || _isAccountant;
//   bool get _canUsePriceChipsForQuotation => _isAdmin || _isSales;
//
//   Timer? _debounce;
//
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   List<Map<String, dynamic>> _allItems = [];
//   List<Map<String, dynamic>> _filteredItems = [];
//   List<String> _categories = [];
//
//   String _searchQuery = '';
//   String? _selectedCategory;
//
//   Map<String, bool> _pricePermissions = {
//     for (final option in _priceOptions) option.key: true,
//   };
//
//   final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};
//   bool _isLoadingPermissions = true;
//
//   _CatalogViewMode _catalogViewMode = _CatalogViewMode.compactGrid;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     Future.wait([
//       _loadItems(),
//       _loadPricePermissions(),
//     ]);
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _onSearchChanged() {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       if (!mounted) return;
//       setState(() {
//         _searchQuery = _searchController.text.trim();
//         _applyFilters();
//       });
//     });
//   }
//
//   Future<void> _loadItems() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final response = await _supabase
//           .from('price_list_api')
//           .select()
//           .order('category_ar', ascending: true)
//           .order('product_name', ascending: true);
//
//       final items = (response as List)
//           .map((item) => Map<String, dynamic>.from(item as Map))
//           .toList();
//
//       final categories = items
//           .map((e) => (e['category_ar'] ?? '').toString().trim())
//           .where((e) => e.isNotEmpty)
//           .toSet()
//           .toList()
//         ..sort();
//
//       setState(() {
//         _allItems = items;
//         _categories = categories;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final search = _searchQuery.toLowerCase();
//
//     _filteredItems = _allItems.where((item) {
//       final category = (item['category_ar'] ?? '').toString().trim();
//       final description = (item['description'] ?? '').toString().trim();
//       final productName = (item['product_name'] ?? '').toString().trim();
//       final itemCode = (item['item_code'] ?? '').toString().trim();
//       final displayPrice = (item['display_price'] ?? '').toString().trim();
//       final barcode = (item['barcode'] ?? '').toString().trim();
//
//       final matchesCategory =
//           _selectedCategory == null || category == _selectedCategory;
//
//       final haystack = [
//         category,
//         description,
//         productName,
//         itemCode,
//         displayPrice,
//         barcode,
//       ].join(' ').toLowerCase();
//
//       final matchesSearch = search.isEmpty || haystack.contains(search);
//
//       return matchesCategory && matchesSearch;
//     }).toList();
//   }
//
//   void _clearFilters() {
//     setState(() {
//       _selectedCategory = null;
//       _searchQuery = '';
//       _searchController.clear();
//       _applyFilters();
//     });
//   }
//
//   Future<void> _startBarcodeScan() async {
//     final code = await Navigator.of(context).push<String>(
//       MaterialPageRoute(
//         builder: (_) => const BarcodeScannerScreen(),
//       ),
//     );
//
//     if (!mounted || code == null || code.trim().isEmpty) return;
//
//     setState(() {
//       _searchController.text = code.trim();
//       _searchController.selection = TextSelection.fromPosition(
//         TextPosition(offset: _searchController.text.length),
//       );
//       _searchQuery = code.trim();
//       _applyFilters();
//     });
//   }
//
//   double? _toDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString());
//   }
//
//   String _formatPrice(dynamic value) {
//     final number = _toDouble(value);
//     if (number == null) return '-';
//     if (number == number.roundToDouble()) {
//       return number.toInt().toString();
//     }
//     return number.toStringAsFixed(2);
//   }
//
//   Future<void> _loadPricePermissions() async {
//     try {
//       final response = await _supabase.rpc('get_my_price_permissions');
//
//       final map = {
//         for (final option in _priceOptions) option.key: true,
//       };
//
//       if (response is List) {
//         for (final row in response) {
//           final data = Map<String, dynamic>.from(row as Map);
//           final key = (data['price_key'] ?? '').toString();
//           final allowed = data['is_allowed'] == true;
//           if (map.containsKey(key)) {
//             map[key] = allowed;
//           }
//         }
//       }
//
//       if (!mounted) return;
//       setState(() {
//         _pricePermissions = map;
//         _isLoadingPermissions = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _pricePermissions = {
//           for (final option in _priceOptions) option.key: true,
//         };
//         _isLoadingPermissions = false;
//       });
//     }
//   }
//
//   double? _priceValueForKey(Map<String, dynamic> item, String priceKey) {
//     return _toDouble(item[priceKey]);
//   }
//
//   bool _isPriceAllowedForItem(Map<String, dynamic> item, String priceKey) {
//     final globallyAllowed = _pricePermissions[priceKey] ?? true;
//     final value = _priceValueForKey(item, priceKey);
//     return globallyAllowed && value != null;
//   }
//
//   String? _selectedPriceKeyForItem(Map<String, dynamic> item) {
//     final itemId = _safeInt(item['id']);
//     if (itemId == null) return null;
//     return _selectedQuoteItems[itemId]?.priceKey;
//   }
//
//   void _toggleItemPriceSelection(
//       Map<String, dynamic> item,
//       String priceKey,
//       String priceLabel,
//       ) {
//     if (!_canUsePriceChipsForQuotation) return;
//     if (!_isPriceAllowedForItem(item, priceKey)) return;
//
//     final itemId = _safeInt(item['id']);
//     if (itemId == null) return;
//
//     final priceValue = _priceValueForKey(item, priceKey);
//     if (priceValue == null) return;
//
//     final current = _selectedQuoteItems[itemId];
//
//     setState(() {
//       if (current != null && current.priceKey == priceKey) {
//         _selectedQuoteItems.remove(itemId);
//         return;
//       }
//
//       _selectedQuoteItems[itemId] = _SelectedQuoteItem(
//         itemId: itemId,
//         productName: (item['product_name'] ?? '').toString().trim(),
//         priceKey: priceKey,
//         priceLabel: priceLabel,
//         unitPrice: priceValue,
//         quantity: current?.quantity ?? 1,
//         item: item,
//       );
//     });
//   }
//
//   void _changeSelectedItemQuantity(int itemId, int delta) {
//     final current = _selectedQuoteItems[itemId];
//     if (current == null) return;
//
//     final nextQty = current.quantity + delta;
//     setState(() {
//       if (nextQty <= 0) {
//         _selectedQuoteItems.remove(itemId);
//       } else {
//         _selectedQuoteItems[itemId] = current.copyWith(quantity: nextQty);
//       }
//     });
//   }
//
//   double get _selectedGrandTotal {
//     return _selectedQuoteItems.values.fold(
//       0,
//           (sum, item) => sum + item.lineTotal,
//     );
//   }
//
//   Future<void> _openCreateQuotationSheet() async {
//     if (_selectedQuoteItems.isEmpty) return;
//
//     final draft = await showModalBottomSheet<_QuotationDraft>(
//       context: context,
//       useSafeArea: true,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (_) => _CreateQuotationSheet(
//         subtotal: _selectedGrandTotal,
//         formatPrice: _formatPrice,
//         profile: widget.profile,
//       ),
//     );
//
//     if (!mounted || draft == null) return;
//     await _saveQuotation(draft);
//   }
//
//   Future<void> _saveQuotation(_QuotationDraft draft) async {
//     final user = _supabase.auth.currentUser;
//     if (user == null) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No logged in user found.')),
//       );
//       return;
//     }
//
//     final subtotal = _selectedGrandTotal;
//     final taxableTotal = subtotal +
//         draft.deliveryFee +
//         draft.installationFee +
//         draft.additionalDetailsFee;
//     final vatAmount = taxableTotal * (draft.vatPercent / 100);
//     final netTotal = taxableTotal + vatAmount;
//
//     final quoteNo = 'QT-${DateTime.now().microsecondsSinceEpoch}';
//
//     final quotationPayload = {
//       'quote_no': quoteNo,
//       'quote_date': DateTime.now().toIso8601String().split('T').first,
//       'customer_name': draft.customerName.isEmpty ? null : draft.customerName,
//       'company_name': draft.companyName.isEmpty ? null : draft.companyName,
//       'customer_trn': draft.customerTrn.isEmpty ? null : draft.customerTrn,
//       'customer_phone': draft.customerPhone.isEmpty ? null : draft.customerPhone,
//       'salesperson_name':
//       draft.salespersonName.isEmpty ? null : draft.salespersonName,
//       'salesperson_contact':
//       draft.salespersonContact.isEmpty ? null : draft.salespersonContact,
//       'salesperson_phone': widget.profile['phone'],
//       'notes': draft.notes.isEmpty ? null : draft.notes,
//       'status': 'draft',
//       'subtotal': subtotal,
//       'delivery_fee': draft.deliveryFee,
//       'installation_fee': draft.installationFee,
//       'additional_details_fee': draft.additionalDetailsFee,
//       'taxable_total': taxableTotal,
//       'vat_percent': draft.vatPercent,
//       'vat_amount': vatAmount,
//       'net_total': netTotal,
//       'created_by': user.id,
//       'updated_by': user.id,
//     };
//
//     try {
//       final insertedQuotation = await _supabase
//           .from('quotations')
//           .insert(quotationPayload)
//           .select('id, quote_no, created_by')
//           .single();
//
//       final quotationId = _safeInt(insertedQuotation['id']);
//       if (quotationId == null) {
//         throw Exception('Failed to resolve quotation id.');
//       }
//
//       final itemRows = _selectedQuoteItems.values.map((selected) {
//         final item = selected.item;
//         final itemCode = (item['item_code'] ?? '').toString().trim();
//         final description = (item['description'] ?? '').toString().trim();
//         final imagePath = (item['image_path'] ?? '').toString().trim();
//         final productName = selected.productName.trim().isEmpty
//             ? 'Unnamed Product'
//             : selected.productName.trim();
//
//         final rawLength = item['length']?.toString().trim();
//         final rawWidth = item['width']?.toString().trim();
//         final rawProductionTime = item['production_time']?.toString().trim();
//
//         return {
//           'quotation_id': quotationId,
//           'product_id': selected.itemId,
//           'item_code': itemCode.isEmpty ? null : itemCode,
//           'product_name': productName,
//           'description': description.isEmpty ? null : description,
//           'image_path': imagePath.isEmpty ? null : imagePath,
//           'length': (rawLength == null || rawLength.isEmpty)
//               ? null
//               : item['length'].toString().trim(),
//           'width': (rawWidth == null || rawWidth.isEmpty)
//               ? null
//               : item['width'].toString().trim(),
//           'production_time': (rawProductionTime == null || rawProductionTime.isEmpty)
//               ? null
//               : item['production_time'].toString().trim(),
//           'price_key': selected.priceKey,
//           'price_label': selected.priceLabel,
//           'unit_price': selected.unitPrice,
//           'quantity': selected.quantity,
//           'line_total': selected.lineTotal,
//           'snapshot': {
//             'category_ar': item['category_ar'],
//             'description': item['description'],
//             'product_name': item['product_name'],
//             'item_code': item['item_code'],
//             'barcode': item['barcode'],
//             'price_ee': item['price_ee'],
//             'price_aa': item['price_aa'],
//             'price_a': item['price_a'],
//             'price_rr': item['price_rr'],
//             'price_r': item['price_r'],
//             'price_art': item['price_art'],
//             'pot_item_no': item['pot_item_no'],
//             'pot_price': item['pot_price'],
//             'additions': item['additions'],
//             'total_price': item['total_price'],
//             'display_price': item['display_price'],
//             'image_path': item['image_path'],
//             'length': item['length'],
//             'width': item['width'],
//             'production_time': item['production_time'],
//           },
//         };
//       }).toList();
//
//       await _supabase.from('quotation_items').insert(itemRows);
//
//       if (!mounted) return;
//
//       setState(() {
//         _selectedQuoteItems.clear();
//       });
//
//       final quoteNumber = (insertedQuotation['quote_no'] ?? '').toString();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Quotation $quoteNumber created successfully.'),
//         ),
//       );
//
//       await Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => QuotationDetailsScreen(
//             quotationId: quotationId,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create quotation: $e')),
//       );
//     }
//   }
//
//   void _openSelectedItemsSheet() {
//     showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (_) {
//         return const Center(child: Text('Selected Items Sheet')); // truncated in canvas preview
//       },
//     );
//   }
//
//   bool _isPhoneWidth(double width) => width < 700;
//
//   int _gridCountFor(double width) {
//     switch (_catalogViewMode) {
//       case _CatalogViewMode.list:
//         return 1;
//       case _CatalogViewMode.compactGrid:
//         if (width >= 1800) return 6;
//         if (width >= 1450) return 5;
//         if (width >= 1100) return 4;
//         if (width >= 700) return 3;
//         return 2;
//       case _CatalogViewMode.comfortableGrid:
//         if (width >= 1800) return 5;
//         if (width >= 1450) return 4;
//         if (width >= 1100) return 3;
//         if (width >= 700) return 2;
//         return 2;
//     }
//   }
//
//   double _gridAspectRatioFor(double width) {
//     switch (_catalogViewMode) {
//       case _CatalogViewMode.list:
//         return 3.0;
//       case _CatalogViewMode.compactGrid:
//         if (width >= 1100) return 0.84;
//         if (width >= 700) return 0.80;
//         return 0.73;
//       case _CatalogViewMode.comfortableGrid:
//         if (width >= 1100) return 0.95;
//         if (width >= 700) return 0.88;
//         return 0.82;
//     }
//   }
//
//   double _contentMaxWidth(double width) {
//     if (width >= 1800) return 1680;
//     if (width >= 1450) return 1400;
//     if (width >= 1100) return 1180;
//     return width;
//   }
//
//   EdgeInsets _pagePaddingFor(double width) {
//     if (width >= 1100) {
//       return const EdgeInsets.fromLTRB(24, 18, 24, 24);
//     }
//     if (width >= 700) {
//       return const EdgeInsets.fromLTRB(18, 16, 18, 22);
//     }
//     return const EdgeInsets.fromLTRB(12, 12, 12, 18);
//   }
//
//   Future<void> _openCategoryPicker() async {
//     final selected = await showModalBottomSheet<String?>(
//       context: context,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (context) {
//         return const SizedBox.shrink();
//       },
//     );
//
//     if (!mounted) return;
//
//     if (selected != _selectedCategory) {
//       setState(() {
//         _selectedCategory = selected;
//         _applyFilters();
//       });
//     }
//   }
//
//   void _openDetails(Map<String, dynamic> item) {
//     showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (_) => _ProductDetailsSheet(
//         item: item,
//         formatPrice: _formatPrice,
//       ),
//     );
//   }
//
//   Future<void> _openAddItemSheet() async {}
//   Future<void> _openBulkAddItemsSheet() async {}
//   Future<void> _openFabActions() async {}
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(body: Center(child: Text('Canvas preview only. Use the downloadable file from chat.')));
//   }
// }
//
// class _ResponsiveCatalogHeader extends StatelessWidget {
//   const _ResponsiveCatalogHeader({
//     required Map<String, dynamic> profile,
//     required Future<void> Function() onLogout,
//     required TextEditingController searchController,
//     required String? selectedCategory,
//     required int visibleCount,
//     required int totalCount,
//     required bool hasFilters,
//     required _CatalogViewMode currentViewMode,
//     required VoidCallback onClearFilters,
//     required VoidCallback onOpenCategoryPicker,
//     required VoidCallback onScanBarcode,
//     required ValueChanged<_CatalogViewMode> onViewModeChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _HeaderChipButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//
//   const _HeaderChipButton({
//     required this.icon,
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _CatalogProductTile extends StatelessWidget {
//   const _CatalogProductTile({
//     required Map<String, dynamic> item,
//     required String Function(dynamic value) formatPrice,
//     required bool compact,
//     required String? selectedPriceKey,
//     required Map<String, bool> pricePermissions,
//     required bool isLoadingPermissions,
//     required bool canSelectPricesForQuotation,
//     required VoidCallback onTap,
//     required void Function(String priceKey, String priceLabel) onSelectPrice,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _CatalogListTile extends StatelessWidget {
//   const _CatalogListTile({
//     required Map<String, dynamic> item,
//     required String Function(dynamic value) formatPrice,
//     required String? selectedPriceKey,
//     required Map<String, bool> pricePermissions,
//     required bool isLoadingPermissions,
//     required bool canSelectPricesForQuotation,
//     required VoidCallback onTap,
//     required void Function(String priceKey, String priceLabel) onSelectPrice,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _ProductDetailsSheet extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final String Function(dynamic value) formatPrice;
//
//   const _ProductDetailsSheet({required this.item, required this.formatPrice});
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _InfoBox extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const _InfoBox({required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _AddItemSheet extends StatefulWidget {
//   const _AddItemSheet();
//
//   @override
//   State<_AddItemSheet> createState() => _AddItemSheetState();
// }
//
// class _AddItemSheetState extends State<_AddItemSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _BulkAddItemsSheet extends StatefulWidget {
//   const _BulkAddItemsSheet();
//
//   @override
//   State<_BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
// }
//
// class _BulkAddItemsSheetState extends State<_BulkAddItemsSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _CreateQuotationSheet extends StatefulWidget {
//   final double subtotal;
//   final String Function(dynamic value) formatPrice;
//   final Map<String, dynamic> profile;
//
//   const _CreateQuotationSheet({
//     required this.subtotal,
//     required this.formatPrice,
//     required this.profile,
//   });
//
//   @override
//   State<_CreateQuotationSheet> createState() => _CreateQuotationSheetState();
// }
//
// class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class _SummaryRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isHighlighted;
//
//   const _SummaryRow({
//     required this.label,
//     required this.value,
//     this.isHighlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
//
// class PricePermissionsScreen extends StatefulWidget {
//   const PricePermissionsScreen({super.key});
//
//   @override
//   State<PricePermissionsScreen> createState() =>
//       _PricePermissionsScreenState();
// }
//
// class _PricePermissionsScreenState extends State<PricePermissionsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(body: SizedBox.shrink());
//   }
// }


import 'dart:async';
import 'dart:convert';

import 'package:FlowerCenterCrm/user_role_management_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

double _safeDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0;
}

String? _safeTextOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
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
  final ScrollController _scrollController = ScrollController();

  _ViewMode _viewMode = _ViewMode.list;
  static const String _kViewModeKey = 'price_list_view_mode';

  Timer? _debounce;

  bool _isLoading = true;
  bool _isLoadingPermissions = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _categories = [];

  String _searchQuery = '';
  String? _selectedCategory;

  bool _showFiltersOnMobile = false;

  final Map<String, bool> _pricePermissions = {
    for (final option in _priceOptions) option.key: true,
  };

  final Map<int, _SelectedQuoteItem> _selectedQuoteItems = {};

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

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
      final response = await _supabase
          .from('price_list_api')
          .select()
          .order('category_ar', ascending: true)
          .order('product_name', ascending: true);

      final items = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final categories = items
          .map((e) => (e['category_ar'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _categories = categories;
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
      'customer_name': _safeTextOrNull(draft.customerName),
      'company_name': _safeTextOrNull(draft.companyName),
      'customer_trn': _safeTextOrNull(draft.customerTrn),
      'customer_phone': _safeTextOrNull(draft.customerPhone),
      'salesperson_name': _safeTextOrNull(draft.salespersonName),
      'salesperson_contact': _safeTextOrNull(draft.salespersonContact),
      'salesperson_phone':
      _safeTextOrNull(draft.salespersonPhone) ??
          _safeTextOrNull(widget.profile['phone']),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171717),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF2E2E2E),
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
                                        visualDensity:
                                        VisualDensity.compact,
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
                                        '${liveSelected?.quantity ?? selected.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity:
                                        VisualDensity.compact,
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedQuoteItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
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

  double _gridAspectRatio(double width, int count) {
    if (width < 700) {
      if (count >= 3) return 0.88;
      return 0.80;
    }
    if (width < 1000) return 0.84;
    if (width < 1400) return 0.86;
    return 0.90;
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                                currentUserId:
                                (widget.profile['id'] ?? '').toString(),
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
                              currentUserId:
                              (widget.profile['id'] ?? '').toString(),
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
        controller: _scrollController,
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
        controller: _scrollController,
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
        final width = constraints.maxWidth;
        final isNarrow = width < 700;

        final useList = isNarrow && _viewMode == _ViewMode.list;

        if (useList) {
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
        child: Column(
          children: [
            // _ResponsiveHeaderSection(
            //   searchController: _searchController,
            //   selectedCategory: _selectedCategory,
            //   categories: _categories,
            //   visibleCount: _filteredItems.length,
            //   totalCount: _allItems.length,
            //   onClearFilters: _clearFilters,
            //   onCategorySelected: (value) {
            //     setState(() {
            //       _selectedCategory = value;
            //       _applyFilters();
            //     });
            //   },
            //   profile: widget.profile,
            //   onLogout: widget.onLogout,
            //   onScanBarcode: _startBarcodeScan,
            //   showFiltersOnMobile: _showFiltersOnMobile,
            //   onToggleMobileFilters: () {
            //     setState(() {
            //       _showFiltersOnMobile = !_showFiltersOnMobile;
            //     });
            //   },
            // ),
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
              profile: widget.profile,
              onLogout: widget.onLogout,
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBody(theme),
              ),
            ),
          ],
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
  final Map<String, dynamic> profile;
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
    final name = (profile['full_name'] ?? 'User').toString().trim();
    final role = (profile['role'] ?? '').toString().trim();

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

  const _HeaderFilters({
    required this.isMobile,
    required this.selectedCategory,
    required this.categories,
    required this.visibleCount,
    required this.totalCount,
    required this.onClearFilters,
    required this.onCategorySelected,
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
              Expanded(
                child: _CountBadge(
                  label: 'Showing',
                  value: '$visibleCount / $totalCount',
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Clear'),
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
        const SizedBox(width: 12),
        _CountBadge(
          label: 'Showing',
          value: '$visibleCount / $totalCount',
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Clear'),
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

  const _CompactListTile({
    required this.item,
    required this.formatPrice,
    required this.onTap,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
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
                          if (category.isNotEmpty && itemCode.isNotEmpty)
                            const Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 10.5,
                              ),
                            ),
                          if (itemCode.isNotEmpty)
                            Text(
                              itemCode,
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
                        children: _priceOptions.map((option) {
                          final rawValue = item[option.key];
                          final numericValue = _toDouble(rawValue);
                          final exists = numericValue != null;
                          final allowed = canSelectPricesForQuotation &&
                              (pricePermissions[option.key] ?? true) &&
                              exists;
                          final selected = selectedPriceKey == option.key;

                          if (!exists) return const SizedBox.shrink();

                          return GestureDetector(
                            onTap: allowed
                                ? () => onSelectPrice(option.key, option.label)
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
                                option.label,
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
              _ProductImage(
                imagePath: imagePath,
                height: isDense ? 110 : 145,
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
                              if (itemCode.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  itemCode,
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

  const _PriceChipWrap({
    required this.item,
    required this.formatPrice,
    required this.pricePermissions,
    required this.selectedPriceKey,
    required this.onSelectPrice,
    required this.isLoadingPermissions,
    required this.canSelectPricesForQuotation,
    required this.compact,
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

    final chips = _priceOptions.map((option) {
      final priceValue = _toDouble(item[option.key]);
      final hasValue = priceValue != null;
      final isAllowed = (pricePermissions[option.key] ?? true) && hasValue;
      final isSelected = selectedPriceKey == option.key;

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
              ? '${option.label} ${formatPrice(priceValue)}'
              : '${option.label} -',
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
            : (_) => onSelectPrice(option.key, option.label),
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

class _ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatPrice;

  const _ProductDetailsSheet({
    required this.item,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final productName =
    (item['product_name'] ?? 'Unnamed Product').toString().trim();
    final description = (item['description'] ?? '').toString().trim();
    final itemCode = (item['item_code'] ?? '').toString().trim();
    final category = (item['category_ar'] ?? '').toString().trim();
    final width = (item['width'] ?? '').toString().trim();
    final length = (item['length'] ?? '').toString().trim();
    final productionTime = (item['production_time'] ?? '').toString().trim();

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                      imagePath: (item['image_path'] ?? '').toString().trim(),
                      height: 240,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        children: _priceOptions.map((option) {
                          return Chip(
                            backgroundColor: const Color(0xFF101010),
                            side: const BorderSide(color: Color(0xFF303030)),
                            label: Text(
                              '${option.label}: ${formatPrice(item[option.key])}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final _salespersonPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '0');
  final _installationFeeController = TextEditingController(text: '0');
  final _additionalDetailsFeeController = TextEditingController(text: '0');
  final _vatPercentController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _salespersonNameController.text =
        (widget.profile['full_name'] ?? '').toString().trim();
    _salespersonContactController.text =
        (widget.profile['email'] ?? '').toString().trim();
    _salespersonPhoneController.text =
        (widget.profile['phone'] ?? '').toString().trim();

    _deliveryFeeController.addListener(_rebuild);
    _installationFeeController.addListener(_rebuild);
    _additionalDetailsFeeController.addListener(_rebuild);
    _vatPercentController.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
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
                              controller: _salespersonNameController,
                              decoration: const InputDecoration(
                                labelText: 'Salesperson Name',
                              ),
                            ),
                          ),
                          _AdaptiveField(
                            isMobile: isMobile,
                            child: TextFormField(
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
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save Quotation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppConstants.primaryColor : Colors.white;

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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