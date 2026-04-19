import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../purchase_request_pdf_renderer.dart';
import '../../quotation_pdf_preview_screen.dart';
import 'purchase_request_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _PRItem {
  _PRItem({required this.id, required this.data, this.quantity = 1, this.notes = ''});

  final int id;
  final Map<String, dynamic> data;
  int quantity;
  String notes;

  String get productName    => _t(data['product_name']);
  String get itemCode       => _t(data['item_code']);
  String get supplierCode   => _t(data['supplier_code']);
  String get description    => _t(data['description']);
  String get length         => _t(data['length']);
  String get width          => _t(data['width']);
  String get productionTime => _t(data['production_time']);
  String get imagePath      => _t(data['image_path']);
  String get categoryAr     => _t(data['category_ar']);

  static String _t(dynamic v) => (v ?? '').toString().trim();

  Map<String, dynamic> toExportMap() => {...data, 'quantity': quantity, 'notes': notes};

  Map<String, dynamic> toDbMap(int requestId) => {
        'request_id': requestId,
        'product_id': id,
        'product_name': productName,
        'item_code': itemCode,
        'supplier_code': supplierCode,
        'description': description,
        'length': length,
        'width': width,
        'production_time': productionTime,
        'image_path': imagePath,
        'category_ar': categoryAr,
        'quantity': quantity,
        'notes': notes,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseRequestScreen extends StatefulWidget {
  const PurchaseRequestScreen({super.key, this.isAdmin = false});
  final bool isAdmin;

  @override
  State<PurchaseRequestScreen> createState() => _PurchaseRequestScreenState();
}

class _PurchaseRequestScreenState extends State<PurchaseRequestScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final TabController _tabController;
  late final PurchaseRequestPdfRenderer _pdfRenderer;

  // ── Product selection state ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems   = [];
  List<Map<String, dynamic>> _filtered   = [];
  final Map<int, _PRItem>    _selected   = {};
  bool    _loadingProducts = true;
  String? _productsError;

  // ── Requests list state ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _requests      = [];
  bool                       _loadingReqs   = true;
  int                        _pendingCount  = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _pdfRenderer = PurchaseRequestPdfRenderer(supabase: _supabase);
    _loadProducts();
    _loadRequests();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Products ───────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    try {
      final data = await _supabase
          .from('price_list_api')
          .select()
          .order('category_ar', ascending: true)
          .order('product_name', ascending: true);
      if (!mounted) return;
      setState(() {
        _allItems        = List<Map<String, dynamic>>.from(data as List);
        _filtered        = _allItems;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _productsError = e.toString(); _loadingProducts = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allItems
          : _allItems.where((item) {
              return _t(item['product_name']).toLowerCase().contains(q) ||
                     _t(item['item_code']).toLowerCase().contains(q) ||
                     _t(item['supplier_code']).toLowerCase().contains(q) ||
                     _t(item['category_ar']).toLowerCase().contains(q);
            }).toList();
    });
  }

  // ── Requests ───────────────────────────────────────────────────────────────

  Future<void> _loadRequests() async {
    setState(() => _loadingReqs = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      late List<dynamic> data;
      if (widget.isAdmin) {
        data = await _supabase
            .from('purchase_requests')
            .select('*, purchase_request_items(count)')
            .order('created_at', ascending: false);
      } else {
        if (uid == null) { setState(() => _loadingReqs = false); return; }
        data = await _supabase
            .from('purchase_requests')
            .select('*, purchase_request_items(count)')
            .eq('created_by', uid)
            .order('created_at', ascending: false);
      }
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data);
      setState(() {
        _requests     = list;
        _pendingCount = list.where((r) => r['status'] == 'pending').length;
        _loadingReqs  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReqs = false);
    }
  }

  // ── Selection helpers ──────────────────────────────────────────────────────

  // ── Draft order (admin: merge approved requests) ───────────────────────────

  /// Merges items returned from an approved purchase request into [_selected].
  /// If a product is already selected, quantities are added together.
  void _addToDraft(List<Map<String, dynamic>> dbItems) {
    for (final item in dbItems) {
      final productId = (item['product_id'] as num?)?.toInt() ?? 0;
      if (productId == 0) continue;
      final qty   = (item['quantity'] as num? ?? 1).toInt();
      final notes = _t(item['notes']);

      if (_selected.containsKey(productId)) {
        _selected[productId]!.quantity += qty;
        if (notes.isNotEmpty && _selected[productId]!.notes.isEmpty) {
          _selected[productId]!.notes = notes;
        }
      } else {
        // Prefer live product data; fall back to snapshot stored in the request
        final productData = _allItems.firstWhere(
          (p) => (p['id'] as num?)?.toInt() == productId,
          orElse: () => {
            'id':              productId,
            'product_name':    item['product_name']    ?? '',
            'item_code':       item['item_code']       ?? '',
            'supplier_code':   item['supplier_code']   ?? '',
            'description':     item['description']     ?? '',
            'length':          item['length']           ?? '',
            'width':           item['width']            ?? '',
            'production_time': item['production_time'] ?? '',
            'image_path':      item['image_path']      ?? '',
            'category_ar':     item['category_ar']     ?? '',
          },
        );
        _selected[productId] = _PRItem(
          id:       productId,
          data:     productData,
          quantity: qty,
          notes:    notes,
        );
      }
    }
    setState(() {});
  }

  void _toggle(Map<String, dynamic> item) {
    final id = item['id'] as int;
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = _PRItem(id: id, data: item);
      }
    });
  }

  void _setQty(int id, int qty) {
    if (!_selected.containsKey(id)) return;
    setState(() => _selected[id]!.quantity = qty.clamp(1, 9999));
  }

  static String _t(dynamic v) => (v ?? '').toString().trim();

  // ── Submit (user) ──────────────────────────────────────────────────────────

  Future<void> _handleUserSubmit(List<_PRItem> items) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String creatorName = '';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      creatorName = _t(profile['full_name']);
    } catch (_) {}

    final ref = 'PR-${DateTime.now().millisecondsSinceEpoch}';

    final row = await _supabase.from('purchase_requests').insert({
      'ref_number':      ref,
      'created_by':      user.id,
      'created_by_name': creatorName.isNotEmpty ? creatorName : (user.email ?? ''),
      'status':          'pending',
    }).select().single();

    final requestId = (row['id'] as num).toInt();

    await _supabase.from('purchase_request_items').insert(
      items.map((e) => e.toDbMap(requestId)).toList(),
    );

    if (!mounted) return;
    setState(() => _selected.clear());
    await _loadRequests();
    // Switch to "My Requests" tab
    _tabController.animateTo(1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $ref submitted successfully'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  // ── Open bottom sheet ──────────────────────────────────────────────────────

  void _openSheet() {
    if (_selected.isEmpty) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => widget.isAdmin
          ? _AdminExportSheet(
              items: _selected.values.toList(),
              pdfRenderer: _pdfRenderer,
            )
          : _UserSubmitSheet(
              items: _selected.values.toList(),
              onSubmit: _handleUserSubmit,
            ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Tab 0: admin = "Requests (N)" / user = "New Request"
    // Tab 1: admin = "Create"       / user = "My Requests"
    final tab0Label = widget.isAdmin
        ? (_pendingCount > 0 ? 'Requests ($_pendingCount)' : 'Requests')
        : 'New Request';
    final tab1Label = widget.isAdmin ? 'Create' : 'My Requests';

    // FAB only on the selection tab
    final selectionTabIndex = widget.isAdmin ? 1 : 0;
    final showFab = _tabController.index == selectionTabIndex && _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: tab0Label), Tab(text: tab1Label)],
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.isAdmin
            ? [_buildRequestsList(), _buildProductSelection()]
            : [_buildProductSelection(), _buildRequestsList()],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _openSheet,
              icon: const Icon(Icons.list_alt_rounded),
              label: Text(
                widget.isAdmin
                    ? 'Review (${_selected.length})'
                    : 'Submit (${_selected.length})',
              ),
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: const Color(0xFF111111),
            )
          : null,
    );
  }

  // ── Product selection tab ──────────────────────────────────────────────────

  Widget _buildProductSelection() {
    return Column(
      children: [
        // Banner: shown to admin when items from approved requests are queued
        if (widget.isAdmin && _selected.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: AppConstants.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_selected.length} item${_selected.length == 1 ? '' : 's'} in your running order',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.white38,
                      padding: EdgeInsets.zero),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () { _searchController.clear(); _applyFilter(); },
                    )
                  : null,
            ),
          ),
        ),
        if (_loadingProducts)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_productsError != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_productsError!, textAlign: TextAlign.center),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildItemCard(_filtered[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final id       = item['id'] as int;
    final sel      = _selected.containsKey(id);
    final pr       = _selected[id];
    final name     = _t(item['product_name']);
    final code     = _t(item['item_code']);
    final supplier = _t(item['supplier_code']);
    final cat      = _t(item['category_ar']);
    final imageUrl = _t(item['image_path']).isNotEmpty
        ? _supabase.storage.from('product-images').getPublicUrl(_t(item['image_path']))
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _toggle(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel
              ? AppConstants.primaryColor.withOpacity(0.07)
              : const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel
                ? AppConstants.primaryColor.withOpacity(0.55)
                : const Color(0xFF2B2B2B),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: sel,
                  onChanged: (_) => _toggle(item),
                  activeColor: AppConstants.primaryColor,
                  side: const BorderSide(color: Color(0xFF555555)),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _NoImage(),
                          )
                        : const _NoImage(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (cat.isNotEmpty)
                        Text(cat,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38)),
                      if (code.isNotEmpty || supplier.isNotEmpty)
                        Text(
                          [
                            if (code.isNotEmpty) code,
                            if (supplier.isNotEmpty) supplier,
                          ].join(' · '),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54),
                        ),
                    ],
                  ),
                ),
                if (sel && pr != null)
                  _QuantityStepper(
                      value: pr.quantity, onChanged: (v) => _setQty(id, v)),
              ],
            ),
            if (sel && pr != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Notes…',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => pr.notes = v,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Requests list tab ──────────────────────────────────────────────────────

  Widget _buildRequestsList() {
    if (_loadingReqs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              widget.isAdmin ? 'No requests yet' : 'No requests submitted yet',
              style: const TextStyle(color: Colors.white38, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppConstants.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildRequestCard(_requests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = (req['status'] as String? ?? 'pending');

    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = const Color(0xFFF44336);
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = const Color(0xFFFFB300);
        statusLabel = 'Pending';
    }

    final ref         = (req['ref_number'] as String? ?? '');
    final createdRaw  = req['created_at'] as String?;
    final createdAt   = createdRaw != null ? _formatDate(createdRaw) : '';
    final creatorName = widget.isAdmin ? (req['created_by_name'] as String? ?? '') : '';
    final countList   = req['purchase_request_items'] as List?;
    final itemCount   = countList != null && countList.isNotEmpty
        ? (countList.first['count'] ?? 0)
        : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final addedItems =
            await Navigator.of(context).push<List<Map<String, dynamic>>>(
          MaterialPageRoute(
            builder: (_) => PurchaseRequestDetailScreen(
              requestId: (req['id'] as num).toInt(),
              refNumber: ref,
              isAdmin: widget.isAdmin,
              pdfRenderer: _pdfRenderer,
            ),
          ),
        );
        _loadRequests(); // refresh badge / status on return
        if (addedItems != null && addedItems.isNotEmpty && mounted) {
          _addToDraft(addedItems);
          // Switch to Create tab and let the admin know
          _tabController.animateTo(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${addedItems.length} item${addedItems.length == 1 ? '' : 's'} added — '
                '${_selected.length} total in running order.',
              ),
              backgroundColor: AppConstants.primaryColor.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Row(
          children: [
            // Coloured status bar
            Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ref,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      _StatusBadge(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (widget.isAdmin && creatorName.isNotEmpty)
                    Text(creatorName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60)),
                  Text('$createdAt  ·  $itemCount item${itemCount == 1 ? '' : 's'}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d  = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h  = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  $h:$mi';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white24, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity stepper
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => onChanged(value - 1),
            visualDensity: VisualDensity.compact,
            color: AppConstants.primaryColor,
          ),
          Text('$value',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryColor)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => onChanged(value + 1),
            visualDensity: VisualDensity.compact,
            color: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User: submit-request sheet
// ─────────────────────────────────────────────────────────────────────────────

class _UserSubmitSheet extends StatefulWidget {
  const _UserSubmitSheet({required this.items, required this.onSubmit});
  final List<_PRItem> items;
  final Future<void> Function(List<_PRItem>) onSubmit;

  @override
  State<_UserSubmitSheet> createState() => _UserSubmitSheetState();
}

class _UserSubmitSheetState extends State<_UserSubmitSheet> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(widget.items);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // Handle
              Container(
                width: 56, height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99)),
              ),
              const SizedBox(height: 14),
              // Title
              Row(
                children: [
                  const Expanded(
                    child: Text('Submit Purchase Request',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppConstants.primaryColor)),
                  ),
                  Text('${widget.items.length} item${widget.items.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Your request will be sent to an admin for review.',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 12),
              // Items
              Expanded(
                child: ListView.separated(
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final pr = widget.items[i];
                    return _ReviewItemTile(pr: pr);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black54))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Submit Request'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: const Color(0xFF111111),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

// ─────────────────────────────────────────────────────────────────────────────
// Admin: export sheet (PDF / Excel)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminExportSheet extends StatefulWidget {
  const _AdminExportSheet({required this.items, required this.pdfRenderer});
  final List<_PRItem> items;
  final PurchaseRequestPdfRenderer pdfRenderer;

  @override
  State<_AdminExportSheet> createState() => _AdminExportSheetState();
}

class _AdminExportSheetState extends State<_AdminExportSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _exportingPdf  = false;
  bool _exportingXlsx = false;
  bool _submitting    = false;

  // Single ref shared across export + submit in this sheet session
  late final String _ref = 'PR-${DateTime.now().millisecondsSinceEpoch}';

  String get _refNumber => _ref;
  String get _dateString {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  // ── Submit as admin's own request (auto-approved) ──────────────────────────

  Future<void> _submitAsRequest() async {
    setState(() => _submitting = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Fetch admin's display name
      String adminName = '';
      try {
        final profile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        adminName = (profile['full_name'] as String? ?? '').trim();
      } catch (_) {}

      final now = DateTime.now().toUtc().toIso8601String();

      // Insert request — already approved (admin owns it)
      final row = await _supabase.from('purchase_requests').insert({
        'ref_number':      _ref,
        'created_by':      user.id,
        'created_by_name': adminName.isNotEmpty ? adminName : (user.email ?? ''),
        'status':          'approved',
        'reviewed_by':     user.id,
        'reviewed_at':     now,
        'admin_notes':     'Created directly by admin',
      }).select().single();

      final requestId = (row['id'] as num).toInt();

      // Insert items
      await _supabase.from('purchase_request_items').insert(
        widget.items.map((item) => item.toDbMap(requestId)).toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved as $_ref'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final ref  = _refNumber;
      final date = _dateString;
      final exportItems = widget.items.map((e) => e.toExportMap()).toList();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuotationPdfPreviewScreen(
          quoteNo: ref,
          buildPdf: (fmt) => widget.pdfRenderer.build(
              items: exportItems, refNumber: ref, date: date, pageFormat: fmt),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('PDF failed: $e')));
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportXlsx() async {
    setState(() => _exportingXlsx = true);
    try {
      final ref  = _refNumber;
      final date = _dateString;
      final path = await _buildXlsx(ref, date);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved: $path'),
        action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(path)),
      ));
      await Share.shareXFiles([XFile(path)], subject: 'Purchase Request $ref');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Excel failed: $e')));
    } finally {
      if (mounted) setState(() => _exportingXlsx = false);
    }
  }

  Future<String> _buildXlsx(String ref, String date) async {
    final excel     = Excel.createExcel();
    const sheetName = 'Purchase Request';
    final sheet     = excel[sheetName];
    excel.delete('Sheet1');

    void setText(String cell, String value) =>
        sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);

    CellStyle headerStyle() => CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#3A2F0B'),
          fontColorHex: ExcelColor.fromHexString('#F5E7B2'),
        );

    setText('A1', 'FLOWER CENTER L.L.C — PURCHASE REQUEST');
    setText('A2', 'Ref: $ref');
    setText('D2', 'Date: $date');

    const headers = [
      '#', 'Item Code', 'Supplier Code', 'Product Name', 'Description',
      'Length', 'Width', 'Production Time', 'Quantity', 'Notes',
    ];
    const cols = ['A','B','C','D','E','F','G','H','I','J'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByString('${cols[i]}4'));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle();
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 28);
    sheet.setColumnWidth(4, 32);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 20);
    sheet.setColumnWidth(8, 12);
    sheet.setColumnWidth(9, 30);

    for (var i = 0; i < widget.items.length; i++) {
      final pr  = widget.items[i];
      final row = 4 + i;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(i + 1);
      setText('${cols[1]}${row + 1}', pr.itemCode);
      setText('${cols[2]}${row + 1}', pr.supplierCode);
      setText('${cols[3]}${row + 1}', pr.productName);
      setText('${cols[4]}${row + 1}', pr.description);
      setText('${cols[5]}${row + 1}', pr.length);
      setText('${cols[6]}${row + 1}', pr.width);
      setText('${cols[7]}${row + 1}', pr.productionTime);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = IntCellValue(pr.quantity);
      setText('${cols[9]}${row + 1}', pr.notes);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel encoding failed');
    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$ref.xlsx';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _exportingPdf || _exportingXlsx || _submitting;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                width: 56, height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('Purchase Request',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppConstants.primaryColor)),
                  ),
                  Text(
                    '${widget.items.length} item${widget.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReviewItemTile(pr: widget.items[i]),
                ),
              ),
              const SizedBox(height: 16),
              // ── Export row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : _exportPdf,
                      icon: _exportingPdf
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black54))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Export PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : _exportXlsx,
                      icon: _exportingXlsx
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black54))
                          : const Icon(Icons.table_chart_outlined),
                      label: const Text('Export Excel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Save as tracked request ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _submitAsRequest,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppConstants.primaryColor))
                      : const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save as My Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(
                        color: AppConstants.primaryColor.withOpacity(0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Logs this order in your request history for tracking',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared review item tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({required this.pr});
  final _PRItem pr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pr.productName.isNotEmpty)
                  Text(pr.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                if (pr.itemCode.isNotEmpty || pr.supplierCode.isNotEmpty)
                  Text(
                    [
                      if (pr.itemCode.isNotEmpty) pr.itemCode,
                      if (pr.supplierCode.isNotEmpty) pr.supplierCode,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                if (pr.notes.isNotEmpty)
                  Text('Notes: ${pr.notes}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.4)),
            ),
            child: Text('Qty: ${pr.quantity}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryColor)),
          ),
        ],
      ),
    );
  }
}
