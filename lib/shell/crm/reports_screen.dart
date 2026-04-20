import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;

  bool     _allTime = false;
  DateTime _from    = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to      = DateTime.now();

  bool         _loading = false;
  _ReportData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primaryColor,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _allTime = false;
      _from    = picked.start;
      _to      = picked.end;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _data = null; });
    try {
      final fromStr = _from.toIso8601String().split('T').first;
      final toStr   = DateTime(_to.year, _to.month, _to.day, 23, 59, 59)
          .toIso8601String();

      // Invoices
      var invQ = _supabase
          .from('invoices')
          .select('id, invoice_number, customer_name, total_amount, amount_paid, status, issue_date, due_date, created_by, quotation_id');
      if (!_allTime) {
        invQ = invQ
            .gte('issue_date', fromStr)
            .lte('issue_date', toStr.split('T').first);
      }
      final invoicesRaw = await invQ.order('issue_date', ascending: false);

      // Quotations
      var quotQ = _supabase
          .from('quotations')
          .select('id, quote_no, salesperson_name, net_total, status, created_at, created_by');
      if (!_allTime) {
        quotQ = quotQ
            .gte('created_at', '${fromStr}T00:00:00')
            .lte('created_at', toStr);
      }
      final quotationsRaw = await quotQ.order('created_at', ascending: false);

      final commissionsRaw = await _supabase
          .from('commission_rates')
          .select('profile_id, price_key, rate');

      final profilesRaw = await _supabase
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('role', ['admin', 'sales']);

      // Commission: use quotation_ids from the already date-filtered invoices
      final commissionQuotIds = (invoicesRaw as List)
          .map((i) => i['quotation_id'])
          .where((id) => id != null)
          .map((id) => (id as num).toInt())
          .toSet()
          .toList();

      // owner map: quotation_id → profile id (invoice created_by = quote owner)
      final approvedOwner = <int, String>{
        for (final inv in (invoicesRaw as List))
          if (inv['quotation_id'] != null)
            (inv['quotation_id'] as num).toInt():
                (inv['created_by'] ?? '').toString(),
      };

      List<Map<String, dynamic>> quotationItems = [];
      if (commissionQuotIds.isNotEmpty) {
        final itemsRaw = await _supabase
            .from('quotation_items')
            .select('quotation_id, price_key, line_total')
            .inFilter('quotation_id', commissionQuotIds);
        quotationItems = List<Map<String, dynamic>>.from(itemsRaw as List);
      }

      if (!mounted) return;

      setState(() {
        _data = _ReportData.build(
          invoices:       List<Map<String, dynamic>>.from(invoicesRaw as List),
          quotations:     List<Map<String, dynamic>>.from(quotationsRaw as List),
          commissions:    List<Map<String, dynamic>>.from(commissionsRaw as List),
          profiles:       List<Map<String, dynamic>>.from(profilesRaw as List),
          quotationItems: quotationItems,
          approvedOwner:  approvedOwner,
          from: _from,
          to:   _to,
          allTime: _allTime,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: AppConstants.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Reports',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
                // All time toggle
                _FilterChip(
                  label: 'All time',
                  selected: _allTime,
                  onTap: () {
                    setState(() => _allTime = !_allTime);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                // Date range picker (disabled when all time)
                OutlinedButton.icon(
                  onPressed: _allTime ? null : _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    '${fmt.format(_from)} – ${fmt.format(_to)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _allTime
                        ? Colors.white24
                        : AppConstants.primaryColor,
                    side: BorderSide(
                        color: _allTime
                            ? Colors.white12
                            : AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A220A)),
          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.primaryColor))
                : _data == null
                    ? const SizedBox()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        children: [
                          _RevenueSummaryCard(data: _data!),
                          const SizedBox(height: 16),
                          _OutstandingInvoicesCard(data: _data!),
                          const SizedBox(height: 16),
                          _SalesByAgentCard(data: _data!),
                          const SizedBox(height: 16),
                          _CommissionSummaryCard(data: _data!),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip widget
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String   label;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppConstants.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppConstants.primaryColor : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppConstants.primaryColor : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _AgentStat {
  final String name;
  final int    quoteCount;
  final int    invoiceCount;
  final double revenue;
  final double commission;

  const _AgentStat({
    required this.name,
    required this.quoteCount,
    required this.invoiceCount,
    required this.revenue,
    required this.commission,
  });
}

class _ReportData {
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> quotations;
  final Map<String, String>        profileNames; // id → name

  // Revenue summary
  final double totalRevenue;
  final double paidRevenue;
  final double partialRevenue;
  final double unpaidRevenue;
  final double totalVat;
  final int    invoiceCount;

  // Outstanding
  final List<Map<String, dynamic>> outstanding;
  final double outstandingTotal;

  // Sales by agent
  final List<_AgentStat> agentStats;

  // Commission
  final List<_AgentStat> commissionStats;

  final DateTime from;
  final DateTime to;
  final bool allTime;

  const _ReportData({
    required this.invoices,
    required this.quotations,
    required this.profileNames,
    required this.totalRevenue,
    required this.paidRevenue,
    required this.partialRevenue,
    required this.unpaidRevenue,
    required this.totalVat,
    required this.invoiceCount,
    required this.outstanding,
    required this.outstandingTotal,
    required this.agentStats,
    required this.commissionStats,
    required this.from,
    required this.to,
    required this.allTime,
  });

  static _ReportData build({
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> quotations,
    required List<Map<String, dynamic>> commissions,
    required List<Map<String, dynamic>> profiles,
    required List<Map<String, dynamic>> quotationItems,
    required Map<int, String> approvedOwner,
    required DateTime from,
    required DateTime to,
    required bool allTime,
  }) {
    final profileNames = <String, String>{
      for (final p in profiles)
        (p['id'] ?? '').toString(): (p['full_name'] ?? p['email'] ?? '').toString(),
    };

    // Revenue summary
    double paid = 0, partial = 0, unpaid = 0;
    for (final inv in invoices) {
      final total = _d(inv['total_amount']);
      switch ((inv['status'] ?? '').toString()) {
        case 'paid':    paid    += total; break;
        case 'partial': partial += total; break;
        default:        unpaid  += total; break;
      }
    }
    final totalRev = paid + partial + unpaid;
    final totalVat = totalRev * 5 / 105;

    // Outstanding
    final outstanding = invoices
        .where((i) => (i['status'] ?? '') != 'paid')
        .toList();
    final outstandingTotal = outstanding.fold<double>(
        0, (s, i) => s + _d(i['total_amount']) - _d(i['amount_paid']));

    // Sales by agent
    final agentQuotes    = <String, int>{};
    final agentInvoices  = <String, int>{};
    final agentRevenue   = <String, double>{};

    for (final q in quotations) {
      final name = (q['salesperson_name'] ?? '').toString();
      if (name.isEmpty) continue;
      agentQuotes[name] = (agentQuotes[name] ?? 0) + 1;
    }

    for (final inv in invoices) {
      final ownerId = (inv['created_by'] ?? '').toString();
      final name = profileNames[ownerId] ?? ownerId;
      agentInvoices[name] = (agentInvoices[name] ?? 0) + 1;
      agentRevenue[name]  = (agentRevenue[name]  ?? 0) + _d(inv['total_amount']);
    }

    final allAgentNames = {...agentQuotes.keys, ...agentInvoices.keys};
    final agentStats = allAgentNames.map((name) => _AgentStat(
      name:         name,
      quoteCount:   agentQuotes[name]   ?? 0,
      invoiceCount: agentInvoices[name] ?? 0,
      revenue:      agentRevenue[name]  ?? 0,
      commission:   0,
    )).toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Commission — per item × price_key rate (same logic as agent performance)
    final commissionRates = <String, Map<String, double>>{};
    for (final c in commissions) {
      final pid  = (c['profile_id'] ?? '').toString();
      final key  = (c['price_key']  ?? '').toString();
      final rate = _d(c['rate']);
      if (!commissionRates.containsKey(pid)) commissionRates[pid] = {};
      commissionRates[pid]![key] = rate;
    }

    final commissionByPid = <String, double>{};
    for (final item in quotationItems) {
      final qid      = item['quotation_id'] is num
          ? (item['quotation_id'] as num).toInt() : null;
      if (qid == null) continue;
      final pid      = approvedOwner[qid] ?? '';
      if (pid.isEmpty) continue;
      final priceKey = (item['price_key'] ?? '').toString();
      final lineTotal = _d(item['line_total']);
      final rate     = (commissionRates[pid] ?? {})[priceKey] ?? 0;
      commissionByPid[pid] = (commissionByPid[pid] ?? 0) + lineTotal * rate / 100;
    }

    final commissionStats = profiles.map((p) {
      final pid  = (p['id']        ?? '').toString();
      final name = (p['full_name'] ?? p['email'] ?? '').toString();
      final comm = commissionByPid[pid] ?? 0;
      return _AgentStat(
        name: name, quoteCount: 0, invoiceCount: 0,
        revenue: agentRevenue[name] ?? 0, commission: comm,
      );
    }).where((s) => s.commission > 0 || s.revenue > 0)
      .toList()
      ..sort((a, b) => b.commission.compareTo(a.commission));

    return _ReportData(
      invoices: invoices, quotations: quotations, profileNames: profileNames,
      totalRevenue: totalRev, paidRevenue: paid, partialRevenue: partial,
      unpaidRevenue: unpaid, totalVat: totalVat, invoiceCount: invoices.length,
      outstanding: outstanding, outstandingTotal: outstandingTotal,
      agentStats: agentStats, commissionStats: commissionStats,
      from: from, to: to, allTime: allTime,
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

final _moneyFmt = NumberFormat('#,##0.00');
final _dateFmt  = DateFormat('dd MMM yyyy');

String _fmtMoney(double v) => 'AED ${_moneyFmt.format(v)}';

Widget _reportCard({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget child,
  required VoidCallback onPdf,
  required VoidCallback onCsv,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF2A220A)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                tooltip: 'Export PDF',
                onPressed: onPdf,
                color: Colors.white54,
              ),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, size: 20),
                tooltip: 'Export CSV',
                onPressed: onCsv,
                color: Colors.white54,
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF2A220A), height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: child,
        ),
      ],
    ),
  );
}

Widget _statRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: valueColor ?? Colors.white)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Revenue Summary
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.data});
  final _ReportData data;

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Revenue Summary',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '${_dateFmt.format(data.from)} – ${_dateFmt.format(data.to)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 20),
          _pdfRow('Total Invoices', data.invoiceCount.toString()),
          _pdfRow('Total Revenue', _fmtMoney(data.totalRevenue)),
          _pdfRow('Paid', _fmtMoney(data.paidRevenue)),
          _pdfRow('Partial', _fmtMoney(data.partialRevenue)),
          _pdfRow('Unpaid', _fmtMoney(data.unpaidRevenue)),
          _pdfRow('VAT Collected (~5%)', _fmtMoney(data.totalVat)),
        ],
      ),
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'revenue_summary.pdf');
  }

  void _exportCsv(BuildContext context) {
    final rows = [
      ['Metric', 'Value'],
      ['Total Invoices', data.invoiceCount.toString()],
      ['Total Revenue (AED)', data.totalRevenue.toStringAsFixed(2)],
      ['Paid (AED)', data.paidRevenue.toStringAsFixed(2)],
      ['Partial (AED)', data.partialRevenue.toStringAsFixed(2)],
      ['Unpaid (AED)', data.unpaidRevenue.toStringAsFixed(2)],
      ['VAT Collected ~5% (AED)', data.totalVat.toStringAsFixed(2)],
    ];
    _shareCsv(context, _toCsv(rows),
        'revenue_summary.csv');
  }

  @override
  Widget build(BuildContext context) {
    return _reportCard(
      context: context,
      title: 'Revenue Summary',
      icon: Icons.attach_money_rounded,
      onPdf: () => _exportPdf(context),
      onCsv: () => _exportCsv(context),
      child: Column(
        children: [
          _statRow('Total Invoices', data.invoiceCount.toString()),
          _statRow('Total Revenue', _fmtMoney(data.totalRevenue),
              valueColor: AppConstants.primaryColor),
          const Divider(color: Color(0xFF2B2B2B), height: 16),
          _statRow('Paid', _fmtMoney(data.paidRevenue),
              valueColor: Colors.green),
          _statRow('Partial', _fmtMoney(data.partialRevenue),
              valueColor: Colors.orange),
          _statRow('Unpaid', _fmtMoney(data.unpaidRevenue),
              valueColor: Colors.redAccent),
          const Divider(color: Color(0xFF2B2B2B), height: 16),
          _statRow('VAT Collected (~5%)', _fmtMoney(data.totalVat),
              valueColor: Colors.white38),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Outstanding Invoices
// ─────────────────────────────────────────────────────────────────────────────

class _OutstandingInvoicesCard extends StatelessWidget {
  const _OutstandingInvoicesCard({required this.data});
  final _ReportData data;

  int _ageDays(Map<String, dynamic> inv) {
    try {
      final due = DateTime.parse(inv['due_date'].toString());
      final diff = DateTime.now().difference(due).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Outstanding Invoices',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '${_dateFmt.format(data.from)} – ${_dateFmt.format(data.to)}',
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Invoice #', 'Customer', 'Total', 'Paid', 'Balance', 'Days Overdue'],
            data: data.outstanding.map((inv) {
              final total   = _ReportData._d(inv['total_amount']);
              final paid    = _ReportData._d(inv['amount_paid']);
              return [
                inv['invoice_number'] ?? '',
                inv['customer_name']  ?? '',
                _fmtMoney(total),
                _fmtMoney(paid),
                _fmtMoney(total - paid),
                _ageDays(inv).toString(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
              'Total Outstanding: ${_fmtMoney(data.outstandingTotal)}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'outstanding_invoices.pdf');
  }

  void _exportCsv(BuildContext context) {
    final rows = [
      ['Invoice #', 'Customer', 'Total (AED)', 'Paid (AED)', 'Balance (AED)', 'Due Date', 'Days Overdue'],
      ...data.outstanding.map((inv) {
        final total = _ReportData._d(inv['total_amount']);
        final paid  = _ReportData._d(inv['amount_paid']);
        return [
          inv['invoice_number'] ?? '',
          inv['customer_name']  ?? '',
          total.toStringAsFixed(2),
          paid.toStringAsFixed(2),
          (total - paid).toStringAsFixed(2),
          inv['due_date']       ?? '',
          _ageDays(inv).toString(),
        ];
      }),
    ];
    _shareCsv(context, _toCsv(rows),
        'outstanding_invoices.csv');
  }

  @override
  Widget build(BuildContext context) {
    final buckets = [0, 0, 0]; // 0-30, 31-60, 60+
    for (final inv in data.outstanding) {
      final d = _ageDays(inv);
      if (d <= 30)       buckets[0]++;
      else if (d <= 60)  buckets[1]++;
      else               buckets[2]++;
    }

    return _reportCard(
      context: context,
      title: 'Outstanding Invoices',
      icon: Icons.receipt_long_outlined,
      onPdf: () => _exportPdf(context),
      onCsv: () => _exportCsv(context),
      child: Column(
        children: [
          _statRow('Total Outstanding',
              _fmtMoney(data.outstandingTotal),
              valueColor: Colors.redAccent),
          _statRow('Count', data.outstanding.length.toString()),
          const Divider(color: Color(0xFF2B2B2B), height: 16),
          _statRow('0–30 days overdue', '${buckets[0]} invoices'),
          _statRow('31–60 days overdue', '${buckets[1]} invoices',
              valueColor: Colors.orange),
          _statRow('60+ days overdue', '${buckets[2]} invoices',
              valueColor: Colors.redAccent),
          if (data.outstanding.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...data.outstanding.take(5).map((inv) {
              final total   = _ReportData._d(inv['total_amount']);
              final paid    = _ReportData._d(inv['amount_paid']);
              final balance = total - paid;
              final age     = _ageDays(inv);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv['invoice_number'] ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            inv['customer_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_fmtMoney(balance),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent)),
                        Text(
                          age > 0 ? '$age days overdue' : 'due soon',
                          style: TextStyle(
                              fontSize: 10,
                              color: age > 60
                                  ? Colors.red
                                  : age > 30
                                      ? Colors.orange
                                      : Colors.white38),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (data.outstanding.length > 5)
              Text(
                '+ ${data.outstanding.length - 5} more — export for full list',
                style: const TextStyle(
                    fontSize: 11, color: Colors.white38),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Sales by Agent
// ─────────────────────────────────────────────────────────────────────────────

class _SalesByAgentCard extends StatelessWidget {
  const _SalesByAgentCard({required this.data});
  final _ReportData data;

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Sales by Agent',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '${_dateFmt.format(data.from)} – ${_dateFmt.format(data.to)}',
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Agent', 'Quotes', 'Invoices', 'Revenue'],
            data: data.agentStats.map((s) => [
              s.name,
              s.quoteCount.toString(),
              s.invoiceCount.toString(),
              _fmtMoney(s.revenue),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'sales_by_agent.pdf');
  }

  void _exportCsv(BuildContext context) {
    final rows = [
      ['Agent', 'Quotes', 'Invoices', 'Revenue (AED)'],
      ...data.agentStats.map((s) => [
        s.name,
        s.quoteCount.toString(),
        s.invoiceCount.toString(),
        s.revenue.toStringAsFixed(2),
      ]),
    ];
    _shareCsv(context, _toCsv(rows),
        'sales_by_agent.csv');
  }

  @override
  Widget build(BuildContext context) {
    return _reportCard(
      context: context,
      title: 'Sales by Agent',
      icon: Icons.people_outline_rounded,
      onPdf: () => _exportPdf(context),
      onCsv: () => _exportCsv(context),
      child: data.agentStats.isEmpty
          ? const Text('No data for this period.',
              style: TextStyle(color: Colors.white38))
          : Column(
              children: data.agentStats.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          Text(_fmtMoney(s.revenue),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.primaryColor,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text('${s.quoteCount} quotes',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54)),
                          const Text('  ·  ',
                              style:
                                  TextStyle(color: Colors.white24)),
                          Text('${s.invoiceCount} invoices',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Commission Summary
// ─────────────────────────────────────────────────────────────────────────────

class _CommissionSummaryCard extends StatelessWidget {
  const _CommissionSummaryCard({required this.data});
  final _ReportData data;

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Commission Summary',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '${_dateFmt.format(data.from)} – ${_dateFmt.format(data.to)}',
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Agent', 'Revenue', 'Commission'],
            data: data.commissionStats.map((s) => [
              s.name,
              _fmtMoney(s.revenue),
              _fmtMoney(s.commission),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total Commission: ${_fmtMoney(data.commissionStats.fold(0.0, (s, a) => s + a.commission))}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'commission_summary.pdf');
  }

  void _exportCsv(BuildContext context) {
    final rows = [
      ['Agent', 'Revenue (AED)', 'Commission (AED)'],
      ...data.commissionStats.map((s) => [
        s.name,
        s.revenue.toStringAsFixed(2),
        s.commission.toStringAsFixed(2),
      ]),
    ];
    _shareCsv(context, _toCsv(rows),
        'commission_summary.csv');
  }

  @override
  Widget build(BuildContext context) {
    final totalComm = data.commissionStats
        .fold<double>(0, (s, a) => s + a.commission);

    return _reportCard(
      context: context,
      title: 'Commission Summary',
      icon: Icons.percent_rounded,
      onPdf: () => _exportPdf(context),
      onCsv: () => _exportCsv(context),
      child: data.commissionStats.isEmpty
          ? const Text('No commission data for this period.',
              style: TextStyle(color: Colors.white38))
          : Column(
              children: [
                ...data.commissionStats.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmtMoney(s.commission),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppConstants.primaryColor,
                                      fontSize: 13)),
                              Text(
                                'on ${_fmtMoney(s.revenue)}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const Divider(color: Color(0xFF2B2B2B), height: 16),
                _statRow('Total Commission', _fmtMoney(totalComm),
                    valueColor: AppConstants.primaryColor),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF helper
// ─────────────────────────────────────────────────────────────────────────────

pw.Widget _pdfRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// CSV share
// ─────────────────────────────────────────────────────────────────────────────

String _toCsv(List<List<dynamic>> rows) {
  return rows.map((row) => row
      .map((cell) {
        final s = cell.toString();
        return s.contains(',') || s.contains('"') || s.contains('\n')
            ? '"${s.replaceAll('"', '""')}"'
            : s;
      })
      .join(',')).join('\n');
}

void _shareCsv(BuildContext context, String csv, String filename) {
  Printing.sharePdf(
    bytes: Uint8List.fromList(csv.codeUnits),
    filename: filename,
  );
}
