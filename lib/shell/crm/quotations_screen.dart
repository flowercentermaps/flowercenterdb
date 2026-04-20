import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../quotation_details_screen.dart';

class QuotationsScreen extends StatefulWidget {
  final bool isAdmin;

  const QuotationsScreen({super.key, this.isAdmin = false});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final TabController _tab;

  static const _tabs = ['All', 'Draft', 'Sent', 'Approved', 'Cancelled'];

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];
  Set<int> _invoicedIds = {}; // quotation IDs that already have an invoice
  Set<int> _unreadQuotationIds = {};

  final _searchCtrl = TextEditingController();
  String _query = '';

  RealtimeChannel? _channel;
  Timer?           _debounce;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) unawaited(_supabase.removeChannel(ch));
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    final id = DateTime.now().millisecondsSinceEpoch;
    _channel = _supabase
        .channel('quotations-screen-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quotations',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => _scheduleReload(),
        )
        .subscribe((status, error) {
          debugPrint('QuotationsScreen realtime: $status ${error != null ? "error=$error" : ""}');
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
      final quotFuture = _supabase
          .from('quotations')
          .select(
              'id, quote_no, customer_name, company_name, salesperson_name, net_total, quote_date, created_at, status, is_hamasat')
          .order('created_at', ascending: false);
      final invFuture = _supabase
          .from('invoices')
          .select('quotation_id')
          .not('quotation_id', 'is', null);
      final unreadFuture = _fetchUnreadQuotationIds();

      final quotRes = await quotFuture;
      final invRes = await invFuture;
      final unreadIds = await unreadFuture;

      if (!mounted) return;

      final invoicedIds = (invRes as List)
          .map((e) => (e as Map)['quotation_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();

      setState(() {
        _all = (quotRes as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _invoicedIds = invoicedIds;
        _unreadQuotationIds = unreadIds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (showError) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Set<int>> _fetchUnreadQuotationIds() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return {};
    try {
      final logsFuture = _supabase
          .from('activity_logs')
          .select('id, actor_id, meta')
          .eq('action_type', 'quotation_status_change')
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
    final tab = _tabs[_tab.index];
    var list = _all;

    if (tab != 'All') {
      list = list.where((q) => _t(q['status']) == tab.toLowerCase()).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((item) {
        return _t(item['customer_name']).toLowerCase().contains(q) ||
            _t(item['quote_no']).toLowerCase().contains(q) ||
            _t(item['company_name']).toLowerCase().contains(q) ||
            _t(item['salesperson_name']).toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  int _countForTab(String tab) {
    if (tab == 'All') return _all.length;
    return _all.where((q) => _t(q['status']) == tab.toLowerCase()).length;
  }

  String _t(dynamic v) => (v ?? '').toString().trim();

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    try {
      final dt = DateTime.parse(v.toString());
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return v.toString();
    }
  }

  String _formatMoney(dynamic v) {
    if (v == null) return '0.00';
    final d = double.tryParse(v.toString()) ?? 0.0;
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  Future<void> _openQuotation(Map<String, dynamic> q) async {
    final id = q['id'];
    final qId = (q['id'] as num?)?.toInt() ?? 0;
    final isHamasat = q['is_hamasat'] == true;

    // Optimistic: hide dot immediately
    if (_unreadQuotationIds.contains(qId)) {
      setState(() => _unreadQuotationIds.remove(qId));
      unawaited(_dismissNotificationsForQuotation(qId));
    }

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuotationDetailsScreen(
        quotationId: id,
        isHamasat: isHamasat,
        isAdmin: widget.isAdmin,
      ),
    ));
    _load();
  }

  Future<void> _dismissNotificationsForQuotation(int qId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final logs = await _supabase
          .from('activity_logs')
          .select('id, meta')
          .eq('action_type', 'quotation_status_change') as List;
      final matches = logs.where((log) {
        final meta = log['meta'];
        if (meta is! Map) return false;
        return meta['doc_id']?.toString() == qId.toString();
      }).toList();
      if (matches.isEmpty) return;
      await _supabase.from('notification_dismissals').upsert(
        matches.map((log) => {
          'user_id': uid,
          'category': 'doc_status_changes',
          'entity_type': 'activity_log',
          'entity_id': log['id'].toString(),
        }).toList(),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildTabBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search customer, quote no, salesperson…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A220A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A220A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppConstants.primaryColor, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tab,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppConstants.primaryColor,
      unselectedLabelColor: Colors.white54,
      indicatorColor: AppConstants.primaryColor,
      indicatorWeight: 2,
      labelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      tabs: _tabs.map((t) {
        final count = _countForTab(t);
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _tab.index == _tabs.indexOf(t)
                        ? AppConstants.primaryColor.withOpacity(0.2)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _tab.index == _tabs.indexOf(t)
                          ? AppConstants.primaryColor
                          : Colors.white54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'No results for "$_query"'
                  : 'No quotations yet',
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final q = items[i];
          final qId = (q['id'] as num?)?.toInt() ?? 0;
          final isInvoiced = _invoicedIds.contains(qId);
          final isUnread = _unreadQuotationIds.contains(qId);
          return _QuotationCard(
            quotation: q,
            isInvoiced: isInvoiced,
            isUnread: isUnread,
            onTap: () => _openQuotation(q),
            formatDate: _formatDate,
            formatMoney: _formatMoney,
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Quotation Card
// ──────────────────────────────────────────────────────────────────────────────

class _QuotationCard extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final bool isInvoiced;
  final bool isUnread;
  final VoidCallback onTap;
  final String Function(dynamic) formatDate;
  final String Function(dynamic) formatMoney;

  const _QuotationCard({
    required this.quotation,
    required this.isInvoiced,
    required this.onTap,
    required this.formatDate,
    required this.formatMoney,
    this.isUnread = false,
  });

  String _t(dynamic v) => (v ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final status = _t(quotation['status']);
    final isHamasat = quotation['is_hamasat'] == true;
    final statusColor = _statusColor(status);
    final accentColor =
        isHamasat ? const Color(0xFF9B77BA) : AppConstants.primaryColor;

    final quoteLabel = _t(quotation['quote_no']).isNotEmpty
        ? _t(quotation['quote_no'])
        : '#${quotation['id']}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Stack(
            children: [
              // ── Card body ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHamasat
                        ? const Color(0xFF3D2E52)
                        : const Color(0xFF2A220A),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Colored left bar
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          // Extra top padding so content clears the quote tag
                          padding: const EdgeInsets.fromLTRB(12, 12, 50, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: status + HAM chip + invoiced chip
                              Row(
                                children: [
                                  _StatusChip(status: status),
                                  if (isHamasat) ...[
                                    const SizedBox(width: 6),
                                    _HamChip(),
                                  ],
                                  const Spacer(),
                                  if (isInvoiced) _InvoicedChip(),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Row 2: customer name
                              Text(
                                _t(quotation['customer_name']).isNotEmpty
                                    ? _t(quotation['customer_name'])
                                    : 'Unknown Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_t(quotation['company_name']).isNotEmpty)
                                Text(
                                  _t(quotation['company_name']),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Row 3: total + date
                              Row(
                                children: [
                                  Text(
                                    'AED ${formatMoney(quotation['net_total'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatDate(quotation['quote_date'] ??
                                        quotation['created_at']),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (_t(quotation['salesperson_name'])
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded,
                                        size: 12, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      _t(quotation['salesperson_name']),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.chevron_right_rounded,
                            color: Colors.white24, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Unread indicator dot ─────────────────────────────────────
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
                      border: Border.all(
                          color: const Color(0xFF161616), width: 1.5),
                    ),
                  ),
                ),

              // ── Quote number corner tag ───────────────────────────────────
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    quoteLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Color(0xFF111111),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'sent':
        return const Color(0xFFFFA726);
      case 'cancelled':
        return const Color(0xFFEF5350);
      case 'draft':
        return const Color(0xFF78909C);
      default:
        return Colors.white24;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'approved':
        bg = const Color(0xFF1B3A1D);
        fg = const Color(0xFF66BB6A);
        label = 'Approved';
        break;
      case 'sent':
        bg = const Color(0xFF3A2C0A);
        fg = const Color(0xFFFFA726);
        label = 'Sent';
        break;
      case 'cancelled':
        bg = const Color(0xFF3A1212);
        fg = const Color(0xFFEF5350);
        label = 'Cancelled';
        break;
      case 'draft':
        bg = const Color(0xFF1E2428);
        fg = const Color(0xFF90A4AE);
        label = 'Draft';
        break;
      default:
        bg = Colors.white12;
        fg = Colors.white54;
        label = status.isEmpty ? 'Unknown' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HamChip extends StatelessWidget {
  const _HamChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1F42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF6A4A8A), width: 0.8),
      ),
      child: const Text(
        'HAM',
        style: TextStyle(
          color: Color(0xFFCDAEE8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InvoicedChip extends StatelessWidget {
  const _InvoicedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3320),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2E6E42), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.receipt_long_rounded,
              size: 11, color: Color(0xFF4CAF50)),
          SizedBox(width: 4),
          Text(
            'Invoiced',
            style: TextStyle(
              color: Color(0xFF66BB6A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
