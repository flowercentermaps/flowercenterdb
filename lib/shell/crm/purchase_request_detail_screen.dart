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

// ─────────────────────────────────────────────────────────────────────────────
// Detail screen — read a submitted request; admin can approve / reject
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseRequestDetailScreen extends StatefulWidget {
  const PurchaseRequestDetailScreen({
    super.key,
    required this.requestId,
    required this.refNumber,
    required this.isAdmin,
    required this.pdfRenderer,
  });

  final int                      requestId;
  final String                   refNumber;
  final bool                     isAdmin;
  final PurchaseRequestPdfRenderer pdfRenderer;

  @override
  State<PurchaseRequestDetailScreen> createState() =>
      _PurchaseRequestDetailScreenState();
}

class _PurchaseRequestDetailScreenState
    extends State<PurchaseRequestDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>?       _request;
  List<Map<String, dynamic>>  _items   = [];
  bool                        _loading = true;
  String?                     _error;

  final TextEditingController _adminNotesCtrl = TextEditingController();
  bool _saving = false;

  static const Color _approved = Color(0xFF4CAF50);
  static const Color _rejected = Color(0xFFF44336);
  static const Color _pending  = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _adminNotesCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final req = await _supabase
          .from('purchase_requests')
          .select()
          .eq('id', widget.requestId)
          .single();

      final items = await _supabase
          .from('purchase_request_items')
          .select()
          .eq('request_id', widget.requestId)
          .order('id');

      if (!mounted) return;
      _adminNotesCtrl.text = (req['admin_notes'] as String? ?? '');
      setState(() {
        _request = req;
        _items   = List<Map<String, dynamic>>.from(items as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Approve / Reject ───────────────────────────────────────────────────────

  Future<void> _updateStatus(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(newStatus == 'approved' ? 'Approve Request' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newStatus == 'approved'
                  ? 'Approve and add items to the running order?'
                  : 'Mark this request as rejected?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminNotesCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin notes (optional)',
                isDense: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  newStatus == 'approved' ? _approved : _rejected,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      await _supabase.from('purchase_requests').update({
        'status':      newStatus,
        'admin_notes': _adminNotesCtrl.text.trim(),
        'reviewed_by': uid,
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.requestId);

      await _load();

      // Pop back and return the approved items so the parent screen can
      // accumulate them into the running order automatically.
      if (newStatus == 'approved' && mounted) {
        Navigator.of(context).pop(_items);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  String get _dateString {
    final r = _request;
    if (r == null) return '';
    try {
      final dt = DateTime.parse(r['created_at'] as String).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openExportSheet() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ExportSheet(
        items:       _items,
        refNumber:   widget.refNumber,
        dateString:  _dateString,
        pdfRenderer: widget.pdfRenderer,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _t(dynamic v) => (v ?? '').toString().trim();

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = (_request?['status'] as String? ?? 'pending');

    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = _approved;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = _rejected;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = _pending;
        statusLabel = 'Pending';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.refNumber,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          // Export sheet — admin always, user only once approved
          if ((widget.isAdmin || status == 'approved') && !_loading)
            IconButton(
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: _openExportSheet,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _buildContent(status, statusColor, statusLabel),
      bottomNavigationBar: widget.isAdmin && status == 'pending' && !_loading
          ? _buildAdminActions()
          : null,
    );
  }

  Widget _buildContent(
      String status, Color statusColor, String statusLabel) {
    final req          = _request!;
    final creatorName  = _t(req['created_by_name']);
    final createdRaw   = req['created_at'] as String?;
    final createdAt    = createdRaw != null ? _formatDate(createdRaw) : '';
    final adminNotes   = _t(req['admin_notes']);
    final reviewedRaw  = req['reviewed_at'] as String?;
    final reviewedAt   = reviewedRaw != null ? _formatDate(reviewedRaw) : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Header card ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2B2B2B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.refNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16,
                            color: AppConstants.primaryColor)),
                  ),
                  _StatusChip(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 10),
              if (creatorName.isNotEmpty)
                _InfoRow(icon: Icons.person_outline, text: creatorName),
              _InfoRow(icon: Icons.calendar_today_outlined, text: createdAt),
              if (adminNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF2B2B2B), height: 1),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: status == 'rejected'
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  text: adminNotes,
                  color: statusColor,
                ),
                if (reviewedAt.isNotEmpty)
                  _InfoRow(
                    icon: Icons.history_outlined,
                    text: 'Reviewed $reviewedAt',
                    color: Colors.white38,
                    fontSize: 11,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Items ────────────────────────────────────────────────────────────
        Text(
          '${_items.length} item${_items.length == 1 ? '' : 's'}',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white54),
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemCard(
                  index: e.key + 1, item: e.value, supabase: _supabase),
            )),
      ],
    );
  }

  Widget _buildAdminActions() {
    return Container(
      color: const Color(0xFF121212),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => _updateStatus('rejected'),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _rejected,
                side: BorderSide(color: _rejected.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _updateStatus('approved'),
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54))
                  : const Icon(Icons.check_rounded),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: _approved,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item card
// ─────────────────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard(
      {required this.index, required this.item, required this.supabase});
  final int                  index;
  final Map<String, dynamic> item;
  final SupabaseClient       supabase;

  static String _t(dynamic v) => (v ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name         = _t(item['product_name']);
    final code         = _t(item['item_code']);
    final supplier     = _t(item['supplier_code']);
    final desc         = _t(item['description']);
    final length       = _t(item['length']);
    final width        = _t(item['width']);
    final prodTime     = _t(item['production_time']);
    final notes        = _t(item['notes']);
    final qty          = (item['quantity'] as num? ?? 1).toInt();
    final imagePath    = _t(item['image_path']);

    final imageUrl = imagePath.isNotEmpty
        ? supabase.storage.from('product-images').getPublicUrl(imagePath)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryColor)),
          ),
          const SizedBox(width: 10),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 58,
              height: 58,
              child: imageUrl != null
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _noImage())
                  : _noImage(),
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                if (code.isNotEmpty || supplier.isNotEmpty)
                  Text(
                    [
                      if (code.isNotEmpty) code,
                      if (supplier.isNotEmpty) supplier,
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54),
                  ),
                if (desc.isNotEmpty)
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
                if (length.isNotEmpty || width.isNotEmpty)
                  Text('L: $length  W: $width',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38)),
                if (prodTime.isNotEmpty)
                  Text('Production: $prodTime',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38)),
                if (notes.isNotEmpty)
                  Text('Notes: $notes',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.primaryColor,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.35)),
            ),
            child: Text('×$qty',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _noImage() => Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white24, size: 20),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.color,
    this.fontSize = 13,
  });
  final IconData icon;
  final String   text;
  final Color?   color;
  final double   fontSize;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 14,
                color: color ?? Colors.white38),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: fontSize,
                      color: color ?? Colors.white60)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Export sheet — shown immediately after approval, or via AppBar button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({
    required this.items,
    required this.refNumber,
    required this.dateString,
    required this.pdfRenderer,
  });
  final List<Map<String, dynamic>> items;
  final String                     refNumber;
  final String                     dateString;
  final PurchaseRequestPdfRenderer pdfRenderer;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _exportingPdf  = false;
  bool _exportingXlsx = false;

  static String _t(dynamic v) => (v ?? '').toString().trim();

  // ── PDF ─────────────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final exportItems = widget.items.map((item) => {
        ...item,
        'quantity': item['quantity'] ?? 1,
        'notes':    item['notes']    ?? '',
      }).toList();

      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuotationPdfPreviewScreen(
          quoteNo: widget.refNumber,
          buildPdf: (fmt) => widget.pdfRenderer.build(
            items:      exportItems,
            refNumber:  widget.refNumber,
            date:       widget.dateString,
            pageFormat: fmt,
          ),
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

  // ── Excel ────────────────────────────────────────────────────────────────────

  Future<void> _exportXlsx() async {
    setState(() => _exportingXlsx = true);
    try {
      final path = await _buildXlsx();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved: $path'),
        action: SnackBarAction(
            label: 'Open', onPressed: () => OpenFilex.open(path)),
      ));
      await Share.shareXFiles([XFile(path)],
          subject: 'Purchase Request ${widget.refNumber}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Excel failed: $e')));
    } finally {
      if (mounted) setState(() => _exportingXlsx = false);
    }
  }

  Future<String> _buildXlsx() async {
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
    setText('A2', 'Ref: ${widget.refNumber}');
    setText('D2', 'Date: ${widget.dateString}');

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
      final item = widget.items[i];
      final row  = 4 + i;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(i + 1);
      setText('${cols[1]}${row + 1}', _t(item['item_code']));
      setText('${cols[2]}${row + 1}', _t(item['supplier_code']));
      setText('${cols[3]}${row + 1}', _t(item['product_name']));
      setText('${cols[4]}${row + 1}', _t(item['description']));
      setText('${cols[5]}${row + 1}', _t(item['length']));
      setText('${cols[6]}${row + 1}', _t(item['width']));
      setText('${cols[7]}${row + 1}', _t(item['production_time']));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = IntCellValue((item['quantity'] as num? ?? 1).toInt());
      setText('${cols[9]}${row + 1}', _t(item['notes']));
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel encoding failed');
    final dir  = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/${widget.refNumber.replaceAll('/', '-')}.xlsx';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _exportingPdf || _exportingXlsx;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 56, height: 5,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Export Request',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppConstants.primaryColor)),
                ),
                Text(
                  '${widget.items.length} item${widget.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(widget.refNumber,
                style: const TextStyle(fontSize: 12, color: Colors.white38)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    sublabel: 'Print / share',
                    loading: _exportingPdf,
                    disabled: busy,
                    onTap: _exportPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExportButton(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    sublabel: 'Spreadsheet',
                    loading: _exportingXlsx,
                    disabled: busy,
                    onTap: _exportXlsx,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close',
                  style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });
  final IconData  icon;
  final String    label;
  final String    sublabel;
  final bool      loading;
  final bool      disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFF1A1A1A)
              : AppConstants.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? const Color(0xFF2B2B2B)
                : AppConstants.primaryColor.withOpacity(0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : Icon(icon,
                    size: 28,
                    color: disabled
                        ? Colors.white24
                        : AppConstants.primaryColor),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: disabled ? Colors.white24 : Colors.white)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
