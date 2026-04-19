import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  final _supabase = Supabase.instance.client;

  bool    _loading = true;
  String? _error;

  // KPI
  double _totalRevenue     = 0;
  double _totalOutstanding = 0;
  double _thisMonth        = 0;
  int    _totalInvoices    = 0;
  int    _paidInvoices     = 0;

  // Monthly revenue (last 6 months)
  List<_MonthData> _monthlyRevenue = [];

  // Top products
  List<_ProductStat> _topProducts = [];

  // Top customers
  List<_CustomerStat> _topCustomers = [];

  // Top salespersons
  List<_AgentStat> _topAgents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Future.wait([
        _loadKpis(),
        _loadMonthlyRevenue(),
        _loadTopProducts(),
        _loadTopCustomers(),
        _loadTopAgents(),
      ]);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── KPIs ──────────────────────────────────────────────────────────────────

  Future<void> _loadKpis() async {
    // Invoices: revenue collected vs outstanding
    final invData = await _supabase
        .from('invoices')
        .select('status, total_amount, amount_paid');

    final invoices = List<Map<String, dynamic>>.from(invData as List);
    _totalInvoices = invoices.length;
    _paidInvoices  = invoices.where((i) => i['status'] == 'paid').length;
    _totalRevenue  = invoices.fold(0,
        (s, i) => s + _n(i['amount_paid']));
    _totalOutstanding = invoices.fold(0,
        (s, i) => s + (_n(i['total_amount']) - _n(i['amount_paid'])).clamp(0, double.infinity));

    // This month from approved quotations
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final monthData = await _supabase
        .from('quotations')
        .select('net_total')
        .eq('status', 'approved')
        .gte('created_at', start);
    _thisMonth = (monthData as List)
        .fold(0, (s, q) => s + _n(q['net_total']));
  }

  // ── Monthly revenue ────────────────────────────────────────────────────────

  Future<void> _loadMonthlyRevenue() async {
    final now    = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 5, 1);

    final data = await _supabase
        .from('quotations')
        .select('net_total, created_at')
        .eq('status', 'approved')
        .gte('created_at', cutoff.toIso8601String())
        .order('created_at');

    // Build month buckets for the last 6 months
    final buckets = <String, double>{};
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      buckets[_monthKey(m)] = 0;
    }

    for (final row in (data as List)) {
      try {
        final dt  = DateTime.parse(row['created_at'] as String);
        final key = _monthKey(dt);
        if (buckets.containsKey(key)) {
          buckets[key] = (buckets[key] ?? 0) + _n(row['net_total']);
        }
      } catch (_) {}
    }

    _monthlyRevenue = buckets.entries
        .map((e) => _MonthData(label: e.key, amount: e.value))
        .toList();
  }

  static String _monthKey(DateTime dt) =>
      DateFormat('MMM yy').format(dt);

  // ── Top products ───────────────────────────────────────────────────────────

  Future<void> _loadTopProducts() async {
    // Fetch approved quotation IDs first
    final quotData = await _supabase
        .from('quotations')
        .select('id')
        .eq('status', 'approved');
    final ids = (quotData as List)
        .map((q) => (q['id'] as num).toInt())
        .toList();

    if (ids.isEmpty) { _topProducts = []; return; }

    final itemsData = await _supabase
        .from('quotation_items')
        .select('product_name, quantity, line_total')
        .inFilter('quotation_id', ids);

    // Aggregate by product name
    final map = <String, _ProductStat>{};
    for (final row in (itemsData as List)) {
      final name = (row['product_name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final qty   = _n(row['quantity']).toInt();
      final total = _n(row['line_total']);
      if (map.containsKey(name)) {
        map[name]!.qty     += qty;
        map[name]!.revenue += total;
      } else {
        map[name] = _ProductStat(name: name, qty: qty, revenue: total);
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    _topProducts = sorted.take(10).toList();
  }

  // ── Top customers ──────────────────────────────────────────────────────────

  Future<void> _loadTopCustomers() async {
    final data = await _supabase
        .from('quotations')
        .select('customer_name, net_total')
        .eq('status', 'approved');

    final map = <String, _CustomerStat>{};
    for (final row in (data as List)) {
      final name = (row['customer_name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final total = _n(row['net_total']);
      if (map.containsKey(name)) {
        map[name]!.revenue += total;
        map[name]!.count   += 1;
      } else {
        map[name] = _CustomerStat(name: name, revenue: total, count: 1);
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    _topCustomers = sorted.take(8).toList();
  }

  // ── Top agents ─────────────────────────────────────────────────────────────

  Future<void> _loadTopAgents() async {
    final data = await _supabase
        .from('quotations')
        .select('salesperson_name, net_total')
        .eq('status', 'approved');

    final map = <String, _AgentStat>{};
    for (final row in (data as List)) {
      final name = (row['salesperson_name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final total = _n(row['net_total']);
      if (map.containsKey(name)) {
        map[name]!.revenue += total;
        map[name]!.count   += 1;
      } else {
        map[name] = _AgentStat(name: name, revenue: total, count: 1);
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    _topAgents = sorted.take(8).toList();
  }

  static double _n(dynamic v) =>
      double.tryParse((v ?? '0').toString()) ?? 0;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppConstants.primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildKpiCards(),
          const SizedBox(height: 20),
          _buildMonthlyChart(),
          const SizedBox(height: 20),
          _buildTopProducts(),
          const SizedBox(height: 20),
          _buildTopCustomers(),
          const SizedBox(height: 20),
          _buildTopAgents(),
        ],
      ),
    );
  }

  // ── KPI cards ──────────────────────────────────────────────────────────────

  Widget _buildKpiCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Collected',
                value: _fmtMoney(_totalRevenue),
                icon: Icons.payments_outlined,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Outstanding',
                value: _fmtMoney(_totalOutstanding),
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFFFFB300),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'This Month',
                value: _fmtMoney(_thisMonth),
                icon: Icons.calendar_month_outlined,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Invoices',
                value: '$_paidInvoices / $_totalInvoices paid',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF42A5F5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Monthly revenue line chart ─────────────────────────────────────────────

  Widget _buildMonthlyChart() {
    if (_monthlyRevenue.isEmpty) return const SizedBox.shrink();

    final maxY = _monthlyRevenue.map((m) => m.amount).fold(0.0, (a, b) => a > b ? a : b);
    final spots = _monthlyRevenue.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.amount)).toList();

    return _Card(
      title: 'Monthly Revenue (Approved Quotations)',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white12, strokeWidth: 0.8),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (v, _) => Text(
                    _shortMoney(v),
                    style: const TextStyle(
                        fontSize: 9, color: Colors.white38),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= _monthlyRevenue.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_monthlyRevenue[i].label,
                          style: const TextStyle(
                              fontSize: 9, color: Colors.white54)),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppConstants.primaryColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: AppConstants.primaryColor,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF1A1A1A),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppConstants.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
            minY: 0,
          ),
        ),
      ),
    );
  }

  // ── Top products ───────────────────────────────────────────────────────────

  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) return const SizedBox.shrink();
    final maxQty = _topProducts.first.qty.toDouble();

    return _Card(
      title: 'Top Products by Quantity Sold',
      child: Column(
        children: _topProducts.asMap().entries.map((e) {
          final p     = e.value;
          final ratio = maxQty > 0 ? p.qty / maxQty : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text('${p.qty} units',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(builder: (_, c) => Stack(
                  children: [
                    Container(
                        height: 6,
                        width: c.maxWidth,
                        decoration: BoxDecoration(
                            color: const Color(0xFF2B2B2B),
                            borderRadius: BorderRadius.circular(3))),
                    Container(
                        height: 6,
                        width: c.maxWidth * ratio,
                        decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(3))),
                  ],
                )),
                const SizedBox(height: 2),
                Text(_fmtMoney(p.revenue),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white38)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Top customers ──────────────────────────────────────────────────────────

  Widget _buildTopCustomers() {
    if (_topCustomers.isEmpty) return const SizedBox.shrink();
    final maxRev = _topCustomers.first.revenue;

    return _Card(
      title: 'Top Customers by Revenue',
      child: Column(
        children: _topCustomers.asMap().entries.map((e) {
          final rank = e.key + 1;
          final c    = e.value;
          final ratio = maxRev > 0 ? c.revenue / maxRev : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: rank <= 3
                              ? AppConstants.primaryColor
                              : Colors.white38)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      LayoutBuilder(builder: (_, box) => Stack(
                        children: [
                          Container(
                              height: 5,
                              width: box.maxWidth,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2B2B2B),
                                  borderRadius:
                                      BorderRadius.circular(3))),
                          Container(
                              height: 5,
                              width: box.maxWidth * ratio,
                              decoration: BoxDecoration(
                                  color: AppConstants.primaryColor
                                      .withOpacity(0.7),
                                  borderRadius:
                                      BorderRadius.circular(3))),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtMoney(c.revenue),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor)),
                    Text('${c.count} order${c.count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Top agents ─────────────────────────────────────────────────────────────

  Widget _buildTopAgents() {
    if (_topAgents.isEmpty) return const SizedBox.shrink();
    final maxRev = _topAgents.first.revenue;

    return _Card(
      title: 'Top Sales Agents',
      child: Column(
        children: _topAgents.asMap().entries.map((e) {
          final rank = e.key + 1;
          final a    = e.value;
          final ratio = maxRev > 0 ? a.revenue / maxRev : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: rank <= 3
                              ? AppConstants.primaryColor
                              : Colors.white38)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      LayoutBuilder(builder: (_, box) => Stack(
                        children: [
                          Container(
                              height: 5,
                              width: box.maxWidth,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2B2B2B),
                                  borderRadius:
                                      BorderRadius.circular(3))),
                          Container(
                              height: 5,
                              width: box.maxWidth * ratio,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF42A5F5)
                                      .withOpacity(0.8),
                                  borderRadius:
                                      BorderRadius.circular(3))),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtMoney(a.revenue),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF42A5F5))),
                    Text('${a.count} quote${a.count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Format helpers ─────────────────────────────────────────────────────────

  static String _fmtMoney(double v) =>
      'AED ${NumberFormat('#,##0').format(v)}';

  static String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white54)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white38)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _MonthData {
  _MonthData({required this.label, required this.amount});
  final String label;
  final double amount;
}

class _ProductStat {
  _ProductStat({required this.name, required this.qty, required this.revenue});
  final String name;
  int    qty;
  double revenue;
}

class _CustomerStat {
  _CustomerStat(
      {required this.name, required this.revenue, required this.count});
  final String name;
  double revenue;
  int    count;
}

class _AgentStat {
  _AgentStat(
      {required this.name, required this.revenue, required this.count});
  final String name;
  double revenue;
  int    count;
}
