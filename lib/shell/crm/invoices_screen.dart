import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../hm_invoice_pdf_renderer.dart';
import '../../invoice_pdf_renderer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Invoice list screen
// ─────────────────────────────────────────────────────────────────────────────

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key, this.isAdmin = false});
  final bool isAdmin;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final TabController _tabController;

  List<Map<String, dynamic>> _all            = [];
  Set<int>                   _unreadInvoiceIds = {};
  bool                       _loading  = true;
  String?                    _error;

  RealtimeChannel? _channel;
  Timer?           _debounce;

  static const _tabs = ['All', 'Unpaid', 'Partial', 'Paid'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) unawaited(_supabase.removeChannel(ch));
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    final id = DateTime.now().millisecondsSinceEpoch;
    _channel = _supabase
        .channel('invoices-screen-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => _scheduleReload(),
        )
        .subscribe((status, error) {
          debugPrint('InvoicesScreen realtime: $status ${error != null ? "error=$error" : ""}');
        });
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _silentRefresh();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    await _fetchAndApply(showError: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _silentRefresh() async {
    await _fetchAndApply(showError: false);
  }

  Future<void> _fetchAndApply({required bool showError}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      var query = _supabase.from('invoices').select();
      if (!widget.isAdmin && uid != null) {
        query = query.eq('created_by', uid);
      }
      final invoicesFuture = query.order('created_at', ascending: false);
      final unreadFuture = _fetchUnreadInvoiceIds();
      final data = await invoicesFuture;
      final unreadIds = await unreadFuture;
      if (!mounted) return;
      setState(() {
        _all = List<Map<String, dynamic>>.from(data as List);
        _unreadInvoiceIds = unreadIds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (showError) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Set<int>> _fetchUnreadInvoiceIds() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return {};
    try {
      final logsFuture = _supabase
          .from('activity_logs')
          .select('id, actor_id, meta')
          .inFilter('action_type', ['invoice_status_change', 'invoice_created'])
          .order('created_at', ascending: false)
          .limit(100);
      final dismissalsFuture = _supabase
          .from('notification_dismissals')
          .select('entity_id')
          .eq('user_id', uid)
          .eq('category', 'doc_status_changes')
          .eq('entity_type', 'activity_log');

      final logs = await logsFuture as List;
      final dismissals = await dismissalsFuture as List;
      final dismissedIds =
          dismissals.map((e) => (e as Map)['entity_id']?.toString() ?? '').toSet();

      final unread = <int>{};
      for (final item in logs) {
        final log = Map<String, dynamic>.from(item as Map);
        if ((log['actor_id'] ?? '').toString() == uid) continue;
        final meta = log['meta'];
        final m = meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
        final ownerId = (m['owner_id'] ?? '').toString();
        if (!widget.isAdmin && ownerId != uid) continue;
        if (dismissedIds.contains((log['id'] ?? '').toString())) continue;
        final docId = int.tryParse((m['doc_id'] ?? '').toString());
        if (docId != null) unread.add(docId);
      }
      return unread;
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final tab = _tabs[_tabController.index].toLowerCase();
    if (tab == 'all') return _all;
    return _all.where((inv) => inv['status'] == tab).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final t in _tabs)
        t: t == 'All'
            ? _all.length
            : _all.where((inv) => inv['status'] == t.toLowerCase()).length,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.white54,
          tabs: _tabs.map((t) {
            final c = counts[t] ?? 0;
            return Tab(text: c > 0 ? '$t ($c)' : t);
          }).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((_) => _buildList()).toList(),
                ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text('No invoices', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppConstants.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final invId = (items[i]['id'] as num?)?.toInt() ?? 0;
          return _InvoiceCard(
            invoice: items[i],
            isAdmin: widget.isAdmin,
            isUnread: _unreadInvoiceIds.contains(invId),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => InvoiceDetailScreen(
                  invoiceId: invId,
                  isAdmin: widget.isAdmin,
                ),
              ));
              _load();
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice card
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard(
      {required this.invoice, required this.isAdmin, required this.onTap, this.isUnread = false});
  final Map<String, dynamic> invoice;
  final bool                 isAdmin;
  final VoidCallback         onTap;
  final bool                 isUnread;

  @override
  Widget build(BuildContext context) {
    final status    = invoice['status'] as String? ?? 'unpaid';
    final color     = _statusColor(status);
    final label     = _statusLabel(status);
    final invNo     = invoice['invoice_number'] as String? ?? '';
    final customer  = invoice['customer_name'] as String? ?? '';
    final total     = _num(invoice['total_amount']);
    final paid      = _num(invoice['amount_paid']);
    final balance   = total - paid;
    final dueRaw    = invoice['due_date'] as String?;
    final dueDate   = dueRaw != null ? _fmtDate(dueRaw) : '';

    return Stack(
      children: [
      InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Row(
          children: [
            Container(
              width: 4, height: 56,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(invNo,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      _StatusBadge(label: label, color: color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (customer.isNotEmpty)
                    Text(customer,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60)),
                  Row(
                    children: [
                      Text('AED ${_fmtMoney(total)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryColor)),
                      if (balance > 0 && status != 'paid') ...[
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.white24)),
                        Text('Due AED ${_fmtMoney(balance)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38)),
                      ],
                      if (dueDate.isNotEmpty) ...[
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.white24)),
                        Text(dueDate,
                            style: TextStyle(
                                fontSize: 11,
                                color: _isOverdue(dueRaw!, status)
                                    ? const Color(0xFFF44336)
                                    : Colors.white38)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    ),
      if (isUnread)
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'paid':    return const Color(0xFF4CAF50);
      case 'partial': return const Color(0xFFFFB300);
      case 'overdue': return const Color(0xFFF44336);
      default:        return const Color(0xFF90A4AE);
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'paid':    return 'Paid';
      case 'partial': return 'Partial';
      case 'overdue': return 'Overdue';
      default:        return 'Unpaid';
    }
  }

  static bool _isOverdue(String dueRaw, String status) {
    if (status == 'paid') return false;
    try {
      return DateTime.parse(dueRaw).isBefore(DateTime.now());
    } catch (_) { return false; }
  }

  static double _num(dynamic v) =>
      double.tryParse((v ?? '0').toString()) ?? 0;

  static String _fmtMoney(double v) =>
      NumberFormat('#,##0.00').format(v);

  static String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) { return iso; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice detail screen
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen(
      {super.key, required this.invoiceId, required this.isAdmin});
  final int  invoiceId;
  final bool isAdmin;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _supabase          = Supabase.instance.client;
  final _fcPdfRenderer     = InvoicePdfRenderer();
  final _hmPdfRenderer     = HmInvoicePdfRenderer();

  Map<String, dynamic>?      _invoice;
  Map<String, dynamic>?      _quotation;
  List<Map<String, dynamic>> _items    = [];
  List<Map<String, dynamic>> _payments = [];
  bool                       _loading  = true;
  String?                    _error;

  RealtimeChannel? _channel;
  Timer?           _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) unawaited(_supabase.removeChannel(ch));
    super.dispose();
  }

  void _setupRealtime() {
    _channel = _supabase
        .channel('invoice-detail-${widget.invoiceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoice_payments',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Invoice
      final inv = await _supabase
          .from('invoices')
          .select()
          .eq('id', widget.invoiceId)
          .single();

      // Quotation (for customer info + financials)
      final quot = await _supabase
          .from('quotations')
          .select()
          .eq('id', (inv['quotation_id'] as num).toInt())
          .single();

      // Items from quotation
      final items = await _supabase
          .from('quotation_items')
          .select()
          .eq('quotation_id', (inv['quotation_id'] as num).toInt())
          .order('id');

      // Payment records
      final pays = await _supabase
          .from('invoice_payments')
          .select()
          .eq('invoice_id', widget.invoiceId)
          .order('payment_date', ascending: false);

      if (!mounted) return;
      setState(() {
        _invoice   = inv;
        _quotation = quot;
        _items     = List<Map<String, dynamic>>.from(items as List);
        _payments  = List<Map<String, dynamic>>.from(pays as List);
        _loading   = false;
      });
      unawaited(_autoDismissStatusNotifications());
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Payment actions ────────────────────────────────────────────────────────

  void _openRecordPayment() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RecordPaymentSheet(
        invoiceId: widget.invoiceId,
        maxAmount: _balance,
        onSaved: () async {
          Navigator.of(context).pop();
          await _load();
          await _updateInvoiceStatus();
        },
      ),
    );
  }

  double get _total   => _num(_invoice?['total_amount']);
  double get _paid    => _num(_invoice?['amount_paid']);
  double get _balance => (_total - _paid).clamp(0, double.infinity);
  bool   get _isPaid  => (_invoice?['status'] as String? ?? '') == 'paid';

  Future<void> _updateInvoiceStatus() async {
    final newPaid = _payments.fold<double>(
        0, (sum, p) => sum + _num(p['amount']));
    final String newStatus;
    if (newPaid <= 0) {
      newStatus = 'unpaid';
    } else if (newPaid >= _total) {
      newStatus = 'paid';
    } else {
      newStatus = 'partial';
    }
    final oldStatus = (_invoice?['status'] ?? '').toString();
    await _supabase.from('invoices').update({
      'amount_paid': newPaid,
      'status':      newStatus,
    }).eq('id', widget.invoiceId);
    if (oldStatus != newStatus) {
      unawaited(_logInvoiceStatusChange(
        ownerId: (_invoice?['created_by'] ?? '').toString(),
        docNumber: (_invoice?['invoice_number'] ?? '').toString(),
        customerName: (_quotation?['customer_name'] ?? '').toString(),
        oldStatus: oldStatus,
        newStatus: newStatus,
      ));
    }
    await _load();
  }

  Future<void> _logInvoiceStatusChange({
    required String ownerId,
    required String docNumber,
    required String customerName,
    required String oldStatus,
    required String newStatus,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || ownerId.isEmpty) return;
    try {
      await _supabase.from('activity_logs').insert({
        'actor_id': uid,
        'action_type': 'invoice_status_change',
        'meta': {
          'doc_id': widget.invoiceId,
          'owner_id': ownerId,
          'doc_number': docNumber,
          'old_status': oldStatus,
          'new_status': newStatus,
          'customer_name': customerName,
        },
      });
    } catch (_) {}
  }

  Future<void> _autoDismissStatusNotifications() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('id, meta')
          .inFilter('action_type', ['invoice_status_change', 'invoice_created']);
      final docIdStr = widget.invoiceId.toString();
      final logs = (response as List).where((log) {
        final meta = log['meta'];
        if (meta is! Map) return false;
        return meta['doc_id']?.toString() == docIdStr;
      }).toList();
      if (logs.isEmpty) return;
      await _supabase.from('notification_dismissals').upsert(
        logs.map((log) => {
          'user_id': uid,
          'category': 'doc_status_changes',
          'entity_type': 'activity_log',
          'entity_id': log['id'].toString(),
        }).toList(),
      );
    } catch (_) {}
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  Future<void> _openPdf() async {
    if (_invoice == null || _quotation == null) return;
    final isHamasat = _quotation!['is_hamasat'] == true;
    final invNo     = _invoice!['invoice_number'] as String? ?? 'Invoice';

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(invNo),
          foregroundColor: isHamasat
              ? const Color(0xFF9B77BA)
              : AppConstants.primaryColor,
        ),
        body: PdfPreview(
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: '$invNo.pdf',
          build: (_) => isHamasat
              ? _hmPdfRenderer.build(
                  invoice:   _invoice!,
                  quotation: _quotation!,
                  items:     _items,
                )
              : _fcPdfRenderer.build(
                  invoice:   _invoice!,
                  quotation: _quotation!,
                  items:     _items,
                ),
        ),
      ),
    ));
  }

  static double _num(dynamic v) =>
      double.tryParse((v ?? '0').toString()) ?? 0;

  static String _fmtMoney(double v) =>
      'AED ${NumberFormat('#,##0.00').format(v)}';

  static String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso)); }
    catch (_) { return iso; }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status  = _invoice?['status'] as String? ?? 'unpaid';
    final color   = _statusColor(status);
    final label   = _statusLabel(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice?['invoice_number'] as String? ?? 'Invoice',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        foregroundColor: AppConstants.primaryColor,
        actions: [
          if (!_loading && _invoice != null)
            IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _openPdf,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(status, color, label),
      floatingActionButton: (!_loading && !_isPaid && widget.isAdmin)
          ? FloatingActionButton.extended(
              onPressed: _openRecordPayment,
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Record Payment'),
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: const Color(0xFF111111),
            )
          : null,
    );
  }

  Widget _buildBody(String status, Color color, String label) {
    final inv  = _invoice!;
    final quot = _quotation!;

    final subtotal      = _num(quot['subtotal']);
    final deliveryFee   = _num(quot['delivery_fee']);
    final installFee    = _num(quot['installation_fee']);
    final additionalFee = _num(quot['additional_details_fee']);
    final discountAmount = _num(quot['discount_amount']);
    final vatPercent    = _num(quot['vat_percent']);
    final vatAmount     = _num(quot['vat_amount']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── Invoice header card ──────────────────────────────────────────────
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(inv['invoice_number'] as String? ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppConstants.primaryColor)),
                  ),
                  _StatusBadge(label: label, color: color),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.person_outline,
                  text: inv['customer_name'] as String? ?? ''),
              if ((quot['company_name'] as String? ?? '').isNotEmpty)
                _InfoRow(icon: Icons.business_outlined,
                    text: quot['company_name'] as String),
              _InfoRow(icon: Icons.calendar_today_outlined,
                  text: 'Issued: ${_fmtDate(inv['issue_date'] as String?)}'),
              _InfoRow(icon: Icons.event_outlined,
                  text: 'Due: ${_fmtDate(inv['due_date'] as String?)}',
                  color: _balance > 0 && status != 'paid'
                      ? const Color(0xFFF44336)
                      : null),
              if ((inv['notes'] as String? ?? '').isNotEmpty)
                _InfoRow(icon: Icons.notes_outlined,
                    text: inv['notes'] as String),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Items ────────────────────────────────────────────────────────────
        _SectionTitle(
            icon: Icons.inventory_2_outlined,
            label: '${_items.length} item${_items.length == 1 ? '' : 's'}'),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ItemRow(index: e.key + 1, item: e.value),
            )),

        // ── Financial summary ────────────────────────────────────────────────
        const SizedBox(height: 6),
        _Section(
          child: Column(
            children: [
              _FinRow('Subtotal', subtotal),
              if (deliveryFee > 0) _FinRow('Delivery Fee', deliveryFee),
              if (installFee > 0) _FinRow('Installation Fee', installFee),
              if (additionalFee > 0)
                _FinRow('Additional Fee', additionalFee),
              if (discountAmount > 0)
                _FinRow('Discount', discountAmount, isDiscount: true),
              _FinRow('VAT (${vatPercent.toStringAsFixed(0)}%)', vatAmount),
              const Divider(color: Color(0xFF2B2B2B), height: 16),
              _FinRow('Total', _total, bold: true,
                  color: AppConstants.primaryColor),
              if (_paid > 0) ...[
                _FinRow('Paid', _paid,
                    color: const Color(0xFF4CAF50)),
                _FinRow('Balance Due', _balance, bold: true,
                    color: _balance <= 0
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336)),
              ],
            ],
          ),
        ),

        // ── Payment history ──────────────────────────────────────────────────
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionTitle(
              icon: Icons.payments_outlined,
              label: 'Payment History'),
          const SizedBox(height: 8),
          ..._payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentRow(payment: p),
              )),
        ],
      ],
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'paid':    return const Color(0xFF4CAF50);
      case 'partial': return const Color(0xFFFFB300);
      case 'overdue': return const Color(0xFFF44336);
      default:        return const Color(0xFF90A4AE);
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'paid':    return 'Paid';
      case 'partial': return 'Partial';
      case 'overdue': return 'Overdue';
      default:        return 'Unpaid';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Record Payment bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({
    required this.invoiceId,
    required this.maxAmount,
    required this.onSaved,
  });
  final int      invoiceId;
  final double   maxAmount;
  final VoidCallback onSaved;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _supabase    = Supabase.instance.client;
  final _amountCtrl  = TextEditingController();
  final _refCtrl     = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  String   _method   = 'cash';
  DateTime _date     = DateTime.now();
  bool     _saving   = false;

  static const _methods = ['cash', 'bank_transfer', 'card', 'cheque'];
  static const _methodLabels = {
    'cash':          'Cash',
    'bank_transfer': 'Bank Transfer',
    'card':          'Card',
    'cheque':        'Cheque',
  };

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.maxAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      await _supabase.from('invoice_payments').insert({
        'invoice_id':     widget.invoiceId,
        'amount':         double.parse(_amountCtrl.text.trim()),
        'payment_date':   DateFormat('yyyy-MM-dd').format(_date),
        'payment_method': _method,
        'reference':      _refCtrl.text.trim(),
        'recorded_by':    uid,
      });
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Record Payment',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppConstants.primaryColor)),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (AED)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              validator: (v) {
                final d = double.tryParse(v?.trim() ?? '');
                if (d == null || d <= 0) return 'Enter a valid amount';
                if (d > widget.maxAmount + 0.01) {
                  return 'Exceeds balance due '
                      '(${widget.maxAmount.toStringAsFixed(2)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Payment method
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment_outlined)),
              items: _methods
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(_methodLabels[m]!)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),

            // Reference
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                labelText: 'Reference / Cheque No. (optional)',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black54))
                    : const Icon(Icons.check_rounded),
                label: const Text('Save Payment'),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryColor),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white54)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.text, this.color});
  final IconData icon;
  final String   text;
  final Color?   color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white38),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: color ?? Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  const _FinRow(this.label, this.amount,
      {this.bold = false, this.color, this.isDiscount = false});
  final String  label;
  final double  amount;
  final bool    bold;
  final Color?  color;
  final bool    isDiscount;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDiscount
        ? const Color(0xFF4CAF50)
        : color ?? (bold ? Colors.white : Colors.white70);
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        fontSize: bold ? 14 : 13,
        color: effectiveColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '${isDiscount ? '− ' : ''}AED ${NumberFormat('#,##0.00').format(amount)}',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.index, required this.item});
  final int                  index;
  final Map<String, dynamic> item;

  static String _t(dynamic v) => (v ?? '').toString().trim();
  static double _num(dynamic v) =>
      double.tryParse((v ?? '0').toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final name  = _t(item['product_name']);
    final code  = _t(item['item_code']);
    final qty   = _t(item['quantity']);
    final price = _num(item['unit_price']);
    final total = _num(item['line_total']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                if (code.isNotEmpty)
                  Text(code,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('×$qty',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54)),
              Text('AED ${NumberFormat('#,##0.00').format(price)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white38)),
              Text('AED ${NumberFormat('#,##0.00').format(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final Map<String, dynamic> payment;

  static String _t(dynamic v) => (v ?? '').toString().trim();
  static double _num(dynamic v) =>
      double.tryParse((v ?? '0').toString()) ?? 0;

  static const _methodIcons = {
    'cash':          Icons.money_outlined,
    'bank_transfer': Icons.account_balance_outlined,
    'card':          Icons.credit_card_outlined,
    'cheque':        Icons.edit_note_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final method  = _t(payment['payment_method']);
    final amount  = _num(payment['amount']);
    final dateRaw = _t(payment['payment_date']);
    final ref     = _t(payment['reference']);
    String dateStr = dateRaw;
    try {
      dateStr =
          DateFormat('dd/MM/yyyy').format(DateTime.parse(dateRaw));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_methodIcons[method] ?? Icons.payment_outlined,
              size: 20, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        letterSpacing: 0.5)),
                if (ref.isNotEmpty)
                  Text('Ref: $ref',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('AED ${NumberFormat('#,##0.00').format(amount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4CAF50))),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}
