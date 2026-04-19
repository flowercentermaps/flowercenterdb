import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'hm_quotation_pdf_renderer.dart';
import 'quotation_pdf_preview_screen.dart';
import 'fc_quotation_pdf_renderer.dart';
import 'shell/crm/invoices_screen.dart';

class QuotationDetailsScreen extends StatefulWidget {
  final dynamic quotationId;
  final bool isHamasat;
  final bool isAdmin;

  const QuotationDetailsScreen({
    super.key,
    required this.quotationId,
    required this.isHamasat,
    this.isAdmin = false,
  });

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  static const Color _hamPrimary     = Color(0xFF9B77BA);
  static const Color _hamSecondary   = Color(0xFFDED2E8);
  static const Color _hamBorderColor = Color(0xFF3D2E52);

  Color get _accentColor =>
      widget.isHamasat ? _hamPrimary : AppConstants.primaryColor;
  Color get _borderColor =>
      widget.isHamasat ? _hamBorderColor : const Color(0xFF3A2F0B);

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  late final FCQuotationPdfRenderer _fCQuotationPdfRenderer;
  late final HMQuotationPdfRenderer _hMQuotationPdfRenderer;

  bool _isLoading = true;
  bool _isExportingXlsx = false;
  bool _isPreparingPdf = false;
  String? _error;

  Map<String, dynamic>? _quotation;
  List<Map<String, dynamic>> _items = [];

  final Map<dynamic, Uint8List> _temporaryItemImages = {};
  final Map<dynamic, String> _temporaryItemImageNames = {};
  bool _isSavingImage = false;

  // ── Invoice ────────────────────────────────────────────────────────────────
  int?  _existingInvoiceId;
  bool  _checkingInvoice  = false;
  bool  _creatingInvoice  = false;

  // ── Status management ──────────────────────────────────────────────────────
  bool  _updatingStatus   = false;

  @override
  void initState() {
    super.initState();
    // Always initialize both — they're lightweight (fonts loaded lazily on first build)
    _fCQuotationPdfRenderer = FCQuotationPdfRenderer(supabase: _supabase);
    _hMQuotationPdfRenderer = HMQuotationPdfRenderer(supabase: _supabase);
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quotationResponse = await _supabase
          .from('quotations')
          .select('''
            *,
            created_by_profile:profiles!quotations_created_by_fkey (
              id,
              full_name,
              email,
              phone
            )
          ''')
          .eq('id', widget.quotationId)
          .single();

      final quotationMap =
      Map<String, dynamic>.from(quotationResponse as Map);

      final creatorProfile =
      quotationMap['created_by_profile'] as Map<String, dynamic>?;
      final creatorPhone = (creatorProfile?['phone'] ?? '').toString().trim();

      quotationMap['creator_phone'] = creatorPhone;

      final itemsResponse = await _supabase
          .from('quotation_items')
          .select()
          .eq('quotation_id', widget.quotationId)
          .order('id', ascending: true);

      if (!mounted) return;

      setState(() {
        _quotation = quotationMap;
        _items = (itemsResponse as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });

      // Check whether an invoice already exists for this quotation
      _checkExistingInvoice();

      debugPrint('Creator phone: $creatorPhone');
      debugPrint('Quotation: $_quotation');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Invoice helpers ────────────────────────────────────────────────────────

  Future<void> _checkExistingInvoice() async {
    if (_quotation == null) return;
    setState(() => _checkingInvoice = true);
    try {
      final rows = await _supabase
          .from('invoices')
          .select('id')
          .eq('quotation_id', widget.quotationId)
          .limit(1);
      if (!mounted) return;
      setState(() {
        _existingInvoiceId = (rows as List).isNotEmpty
            ? ((rows.first as Map)['id'] as num).toInt()
            : null;
        _checkingInvoice = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checkingInvoice = false);
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────────

  Future<void> _openEditSheet() async {
    final quote = _quotation;
    if (quote == null) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuotationEditSheet(
        supabase: _supabase,
        quotation: quote,
        items: _items,
        isHamasat: widget.isHamasat,
        accentColor: _accentColor,
        borderColor: _borderColor,
      ),
    );

    if (updated == true && mounted) {
      _loadQuotation(); // full refresh
    }
  }

  Future<void> _updateQuotationStatus(String newStatus) async {
    // Confirm destructive actions
    if (newStatus == 'cancelled') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel Quotation?'),
          content: const Text(
              'This will mark the quotation as cancelled. You can revert it to draft later if needed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Back')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Quotation'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _updatingStatus = true);
    try {
      await _supabase
          .from('quotations')
          .update({'status': newStatus})
          .eq('id', widget.quotationId);

      if (!mounted) return;
      setState(() {
        _quotation = {...?_quotation, 'status': newStatus};
        _updatingStatus = false;
      });

      // If just approved, check for existing invoice
      if (newStatus == 'approved') _checkExistingInvoice();

      final msg = {
        'approved':  'Quotation approved ✓',
        'cancelled': 'Quotation cancelled',
        'sent':      'Submitted for review',
        'draft':     'Reverted to draft',
      }[newStatus] ?? 'Status updated';
      final color = newStatus == 'approved'
          ? Colors.green.shade700
          : newStatus == 'cancelled'
              ? Colors.red.shade700
              : Colors.blueGrey.shade700;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingStatus = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _createInvoice() async {
    final quot = _quotation;
    if (quot == null) return;

    // Ask for due date
    final today   = DateTime.now();
    final dueDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Select Invoice Due Date',
    );
    if (dueDate == null || !mounted) return;

    setState(() => _creatingInvoice = true);
    try {
      final invNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch}';
      final uid = _supabase.auth.currentUser?.id;

      final row = await _supabase.from('invoices').insert({
        'invoice_number': invNumber,
        'quotation_id':   widget.quotationId,
        'customer_name':  (quot['customer_name'] ?? '').toString(),
        'issue_date':     today.toIso8601String().split('T').first,
        'due_date': '${dueDate.year}-'
            '${dueDate.month.toString().padLeft(2, '0')}-'
            '${dueDate.day.toString().padLeft(2, '0')}',
        'status':        'unpaid',
        'total_amount':  quot['net_total'] ?? 0,
        'amount_paid':   0,
        'is_hamasat':    widget.isHamasat,
        'created_by':    uid,
      }).select().single();

      final invoiceId = (row['id'] as num).toInt();
      if (!mounted) return;

      setState(() {
        _existingInvoiceId = invoiceId;
        _creatingInvoice   = false;
      });

      // Navigate straight to invoice detail
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoiceId: invoiceId,
          isAdmin:   true,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingInvoice = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  String _text(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _formatMoney(dynamic value) {
    final number = _toDouble(value);
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  String _formatMoneyWithAed(dynamic value) {
    return '${_formatMoney(value)} AED';
  }

  String _formatDate(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String _imageUrlFromPath(String imagePath) {
    return _supabase.storage.from('product-images').getPublicUrl(imagePath);
  }

  bool _canUseCamera() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _pickReplacementImage(
      Map<String, dynamic> item, {
        required ImageSource source,
      }) async {
    try {
      Uint8List? bytes;
      String? fileName;

      final isDesktop = !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        // file_picker runs the native dialog off the main thread — no freeze
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          withData: true,
          allowMultiple: false,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        if (file.bytes == null) return;
        bytes = file.bytes!;
        fileName = file.name;
      } else {
        // image_picker for mobile / camera
        final picked = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (picked == null) return;
        bytes = await picked.readAsBytes();
        fileName = picked.name;
      }

      final itemId = item['id'];

      if (!mounted) return;
      setState(() => _isSavingImage = true);

      // Upload to Supabase Storage under quotation-items/ prefix
      final ext = (fileName ?? 'jpg').split('.').last.toLowerCase();
      final storagePath =
          'quotation-items/$itemId-${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage.from('product-images').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );

      // Persist to custom_image_path — original image_path is never modified
      await _supabase
          .from('quotation_items')
          .update({'custom_image_path': storagePath})
          .eq('id', itemId);

      if (!mounted) return;

      setState(() {
        // Write to custom_image_path only — original image_path is never touched
        final idx = _items.indexWhere((i) => i['id'] == itemId);
        if (idx != -1) {
          _items[idx] = Map<String, dynamic>.from(_items[idx])
            ..['custom_image_path'] = storagePath;
        }

        // Cache bytes for fast display without a network round-trip
        _temporaryItemImages[itemId] = bytes!;
        _temporaryItemImageNames[itemId] = fileName ?? storagePath;
        _isSavingImage = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to quotation.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image update failed: $e')),
        );
      }
    }
  }

  Future<void> _removeReplacementImage(Map<String, dynamic> item) async {
    final itemId = item['id'];
    try {
      setState(() => _isSavingImage = true);

      // Clear custom_image_path — the original image_path is untouched
      await _supabase
          .from('quotation_items')
          .update({'custom_image_path': null})
          .eq('id', itemId);

      if (!mounted) return;
      setState(() {
        _temporaryItemImages.remove(itemId);
        _temporaryItemImageNames.remove(itemId);
        final idx = _items.indexWhere((i) => i['id'] == itemId);
        if (idx != -1) {
          _items[idx] = Map<String, dynamic>.from(_items[idx])
            ..['custom_image_path'] = null;
        }
        _isSavingImage = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom image removed.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove image: $e')),
        );
      }
    }
  }

  Future<void> _showImageSourceSheet(Map<String, dynamic> item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      builder: (context) {
        final itemId = item['id'];
        final hasReplacement = _temporaryItemImages.containsKey(itemId) ||
            _text(item['custom_image_path']).isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickReplacementImage(
                      item,
                      source: ImageSource.gallery,
                    );
                  },
                ),
                if (_canUseCamera())
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Take photo'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickReplacementImage(
                        item,
                        source: ImageSource.camera,
                      );
                    },
                  ),
                if (hasReplacement)
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: const Text('Use original image'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _removeReplacementImage(item);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemPreviewImage(Map<String, dynamic> item, String imagePath) {
    final itemId = item['id'];
    final customBytes = _temporaryItemImages[itemId];
    final customDbPath = _text(item['custom_image_path']);
    final hasCustom = customBytes != null || customDbPath.isNotEmpty;

    // ── helper: build a single labelled thumbnail ──────────────────────────
    Widget _thumb({
      required Widget image,
      required String label,
      Color labelColor = Colors.white,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                image,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    const double sz = 72;

    // ── Original image widget ──────────────────────────────────────────────
    Widget originalWidget;
    if (imagePath.isNotEmpty) {
      originalWidget = Image.network(
        _imageUrlFromPath(imagePath),
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: sz,
          height: sz,
          color: const Color(0xFF222222),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 20),
        ),
      );
    } else {
      originalWidget = Container(
        width: sz,
        height: sz,
        color: const Color(0xFF222222),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      );
    }

    // ── If no custom image, just show original (no labels) ─────────────────
    if (!hasCustom) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: originalWidget,
      );
    }

    // ── Custom image widget ────────────────────────────────────────────────
    Widget customWidget;
    if (customBytes != null) {
      customWidget = Image.memory(
        customBytes,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
      );
    } else {
      // Loaded from DB path (after app restart)
      customWidget = Image.network(
        _imageUrlFromPath(customDbPath),
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: sz,
          height: sz,
          color: const Color(0xFF1A1A1A),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 20),
        ),
      );
    }

    // ── Side-by-side: Original (left) + Custom (right) ─────────────────────
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _thumb(
          image: originalWidget,
          label: 'ORIGINAL',
          labelColor: Colors.white70,
        ),
        const SizedBox(width: 6),
        _thumb(
          image: customWidget,
          label: 'CUSTOM',
          labelColor: Colors.amberAccent,
        ),
      ],
    );
  }

  Future<String> _exportToTemplateXlsx() async {
    final quote = _quotation!;
    final templateData =
    await rootBundle.load('assets/templates/quotation_template.xlsx');

    final excel = Excel.decodeBytes(templateData.buffer.asUint8List());

    final sheetName = excel.tables.keys.contains('Trees & Arrangment')
        ? 'Trees & Arrangment'
        : excel.tables.keys.first;

    final sheet = excel[sheetName];

    void setText(String cell, String value) {
      sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
    }

    void setNumber(String cell, double value) {
      sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
    }

    setText('D7', _text(quote['customer_name']));
    setText('D8', _text(quote['company_name']));
    setText('D9', _text(quote['customer_trn']));
    setText('D10', _text(quote['customer_phone']));

    setText('K7', _formatDate(quote['quote_date']));
    setText('K8', _text(quote['quote_no']));
    setText('K9', _text(quote['salesperson_name']));
    setText('K10', _text(quote['salesperson_contact']));

    const int startRow = 12;
    const int maxRows = 20;

    for (var i = 0; i < maxRows; i++) {
      final row = startRow + i;
      setText('B$row', '');
      setText('C$row', '');
      setText('D$row', '');
      setText('E$row', '');
      setText('F$row', '');
      setText('G$row', '');
      setText('H$row', '');
      setText('I$row', '');
      setText('J$row', '');
      setText('K$row', '');
    }

    for (var i = 0; i < _items.length && i < maxRows; i++) {
      final item = _items[i];
      final row = startRow + i;

      setNumber('B$row', i + 1.0);
      setText('D$row', _text(item['item_code']));
      setText(
        'E$row',
        _text(item['product_name']).isEmpty
            ? _text(item['description'])
            : _text(item['product_name']),
      );
      setText('F$row', _text(item['length']));
      setText('G$row', _text(item['width']));
      setText('H$row', _text(item['production_time']));
      setNumber('I$row', _toInt(item['quantity']).toDouble());
      setNumber('J$row', _toDouble(item['unit_price']));
      setNumber('K$row', _toDouble(item['line_total']));
    }

    setNumber('K33', _toDouble(quote['delivery_fee']));
    setNumber('K34', _toDouble(quote['installation_fee']));
    setNumber('K35', _toDouble(quote['additional_details_fee']));

    final dir = await getApplicationDocumentsDirectory();
    final quoteNo = _text(quote['quote_no']).replaceAll('/', '-');
    final filePath = '${dir.path}/$quoteNo.xlsx';

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate XLSX.');
    }

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes, flush: true);

    return file.path;
  }

  Future<Uint8List> _buildQuotationPdfBytes([PdfPageFormat? format]) async {
    if (_quotation == null) {
      throw Exception('Quotation not loaded.');
    }
    return widget.isHamasat?
    _hMQuotationPdfRenderer.build(
      quotation: _quotation!,
      items: _items,
      temporaryItemImages: _temporaryItemImages,
      pageFormat: format ?? PdfPageFormat.a4,
    ):
     _fCQuotationPdfRenderer.build(
      quotation: _quotation!,
      items: _items,
      temporaryItemImages: _temporaryItemImages,
      pageFormat: format ?? PdfPageFormat.a4,
    );
  }

  Future<String> _savePdfToFile() async {
    if (_quotation == null) {
      throw Exception('Quotation not loaded.');
    }

    final bytes = await _buildQuotationPdfBytes(PdfPageFormat.a4);
    final dir = await getApplicationDocumentsDirectory();
    final quoteNo = _text(_quotation!['quote_no']).replaceAll('/', '-').trim();
    final path = '${dir.path}/$quoteNo.pdf';

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _handleExportXlsx() async {
    if (_quotation == null || _isExportingXlsx) return;

    setState(() {
      _isExportingXlsx = true;
    });

    try {
      final path = await _exportToTemplateXlsx();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $path')),
      );

      await OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('XLSX export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingXlsx = false;
        });
      }
    }
  }

  Future<void> _handleExportPdf() async {
    if (_quotation == null || _isPreparingPdf) return;

    setState(() {
      _isPreparingPdf = true;
    });

    try {
      final quoteNo = _text(_quotation!['quote_no']).isEmpty
          ? 'quotation'
          : _text(_quotation!['quote_no']);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuotationPdfPreviewScreen(
            quoteNo: quoteNo,
            buildPdf: (format) => _buildQuotationPdfBytes(format),
            isHamasat: widget.isHamasat,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF preview failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingPdf = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      if (_quotation == null) return;
      final path = await _savePdfToFile();
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share PDF failed: $e')),
      );
    }
  }

  ThemeData _hamTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _hamPrimary,
        onPrimary: const Color(0xFF1A0A2E),
        onSurface: _hamSecondary,
        primaryContainer: _hamBorderColor,
        onPrimaryContainer: _hamSecondary,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: _hamPrimary,
      ),
      iconTheme: const IconThemeData(color: _hamPrimary),
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
          foregroundColor: const Color(0xFF1A0A2E),
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
        color: _hamBorderColor,
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotation;

    final scaffold = Scaffold( // wrapped below with Theme for Hamasat
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Quotation Details'),
        backgroundColor: const Color(0xFF111111),
        foregroundColor: _accentColor,
        actions: [
          // Edit — only for admin, only before approval
          if (widget.isAdmin &&
              (_quotation?['status'] as String? ?? '') != 'approved')
            IconButton(
              tooltip: 'Edit Quotation',
              onPressed: _isLoading ? null : _openEditSheet,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            onPressed: _isLoading ? null : _handleExportXlsx,
            icon: _isExportingXlsx
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.table_view_outlined),
          ),
          IconButton(
            onPressed: _isLoading ? null : _handleExportPdf,
            icon: _isPreparingPdf
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            onPressed: _isLoading ? null : _sharePdf,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : quote == null
          ? const Center(child: Text('Quotation not found'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(quote['quote_no']),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: ${_formatDate(quote['quote_date'])}'),
                Text('Customer: ${_text(quote['customer_name'])}'),
                Text('Company: ${_text(quote['company_name'])}'),
                Text('TRN: ${_text(quote['customer_trn'])}'),
                Text('Phone: ${_text(quote['customer_phone'])}'),
                Text('Salesperson: ${_text(quote['salesperson_name'])}'),
                Text('Contact: ${_text(quote['salesperson_contact'])}'),
                Text(
                  'Sales phone: ${_text(quote['salesperson_phone']).isNotEmpty
                      ? _text(quote['salesperson_phone'])
                      : _text(quote['creator_phone'])}',
                ),
                if (_text(quote['notes']).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${_text(quote['notes'])}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final imagePath = _text(item['image_path']);
            final hasTempImage =
                _temporaryItemImages.containsKey(item['id']) ||
                _text(item['custom_image_path']).isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemPreviewImage(item, imagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${_text(item['product_name'])}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _accentColor,
                          ),
                        ),
                        if (_text(item['item_code']).isNotEmpty)
                          Text('Item No: ${_text(item['item_code'])}'),
                        if (_text(item['description']).isNotEmpty)
                          Text(_text(item['description'])),
                        if (_text(item['length']).isNotEmpty)
                          Text('Length: ${_text(item['length'])}'),
                        if (_text(item['width']).isNotEmpty)
                          Text('Width: ${_text(item['width'])}'),
                        if (_text(item['production_time']).isNotEmpty)
                          Text(
                            'Production Time: ${_text(item['production_time'])}',
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Qty: ${_toInt(item['quantity'])} • Unit: ${_formatMoney(item['unit_price'])} • Total: ${_formatMoney(item['line_total'])}',
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSavingImage
                                  ? null
                                  : () => _showImageSourceSheet(item),
                              icon: _isSavingImage
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.image_outlined, size: 18),
                              label: Text(
                                hasTempImage ? 'Change image' : 'Set image',
                              ),
                            ),
                            if (hasTempImage)
                              OutlinedButton.icon(
                                onPressed: _isSavingImage
                                    ? null
                                    : () => _removeReplacementImage(item),
                                icon: const Icon(
                                  Icons.restore_outlined,
                                  size: 18,
                                ),
                                label: const Text('Use original'),
                              ),
                          ],
                        ),
                        if (hasTempImage) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Saved: ${_temporaryItemImageNames[item['id']] ?? 'custom image'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _accentColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', quote['subtotal']),
                _summaryRow('Delivery', quote['delivery_fee']),
                _summaryRow('Installation', quote['installation_fee']),
                _summaryRow(
                  'Additional Details',
                  quote['additional_details_fee'],
                ),
                _summaryRow('Taxable Total', quote['taxable_total']),
                if (_toDouble(quote['discount_amount']) > 0)
                  _summaryRow(
                    'Discount',
                    quote['discount_amount'],
                    isDiscount: true,
                  ),
                _summaryRow(
                  'VAT (${_formatMoney(quote['vat_percent'])}%)',
                  quote['vat_amount'],
                ),
                _summaryRow(
                  'Net Total',
                  quote['net_total'],
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status action buttons ──────────────────────────────────────────
          Builder(builder: (context) {
            final status = (_quotation?['status'] as String? ?? '').trim();
            final busy = _updatingStatus;

            // Admin sees Approve + Cancel on sent quotations
            if (widget.isAdmin && status == 'sent') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => _updateQuotationStatus('cancelled'),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => _updateQuotationStatus('approved'),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Admin can revert approved/cancelled back to draft
            if (widget.isAdmin &&
                (status == 'approved' || status == 'cancelled')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed:
                      busy ? null : () => _updateQuotationStatus('draft'),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Revert to Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              );
            }

            // Any user can submit a draft for review
            if (status == 'draft') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed:
                      busy ? null : () => _updateQuotationStatus('sent'),
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Submit for Review'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          }),

          FilledButton.icon(
            onPressed: _isPreparingPdf ? null : _handleExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview PDF'),
          ),
          // Invoice button — only for approved quotations
          if ((_quotation?['status'] as String? ?? '') == 'approved') ...[
            const SizedBox(height: 10),
            if (_checkingInvoice)
              const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_existingInvoiceId != null)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(
                      invoiceId: _existingInvoiceId!,
                      isAdmin: true,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor.withOpacity(0.5)),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _creatingInvoice ? null : _createInvoice,
                icon: _creatingInvoice
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_card_outlined),
                label: const Text('Create Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor.withOpacity(0.5)),
                ),
              ),
          ],
        ],
      ),
    );
    return widget.isHamasat
        ? Theme(data: _hamTheme(context), child: scaffold)
        : scaffold;
  }

  Widget _summaryRow(String label, dynamic value,
      {bool bold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: isDiscount ? Colors.green.shade400 : null,
              ),
            ),
          ),
          Text(
            isDiscount
                ? '− ${_formatMoneyWithAed(value)}'
                : _formatMoneyWithAed(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: isDiscount
                  ? Colors.green.shade400
                  : bold
                      ? _accentColor
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────────────────────
// Quotation Edit Sheet  — covers every editable field
// ──────────────────────────────────────────────────────────────────────────────

class _QuotationEditSheet extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic> quotation;
  final List<Map<String, dynamic>> items;
  final bool isHamasat;
  final Color accentColor;
  final Color borderColor;

  const _QuotationEditSheet({
    required this.supabase,
    required this.quotation,
    required this.items,
    required this.isHamasat,
    required this.accentColor,
    required this.borderColor,
  });

  @override
  State<_QuotationEditSheet> createState() => _QuotationEditSheetState();
}

class _QuotationEditSheetState extends State<_QuotationEditSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── Header controllers ────────────────────────────────────────────────────
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _customerTrnCtrl;
  late final TextEditingController _customerPhoneCtrl;
  late final TextEditingController _salespersonNameCtrl;
  late final TextEditingController _salespersonContactCtrl;
  late final TextEditingController _salespersonPhoneCtrl;
  late final TextEditingController _notesCtrl;

  // ── Fee controllers ───────────────────────────────────────────────────────
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _installationFeeCtrl;
  late final TextEditingController _additionalFeeCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _vatPercentCtrl;

  // ── Per-item controllers — keyed by item id ───────────────────────────────
  late final Map<dynamic, Map<String, TextEditingController>> _itemCtrls;

  // Items list (mutable so we can delete rows)
  late List<Map<String, dynamic>> _items;

  String _t(dynamic v) => (v ?? '').toString().trim();
  double _d(dynamic v) => double.tryParse(_t(v)) ?? 0.0;

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    _items = List<Map<String, dynamic>>.from(widget.items);

    // Header
    _customerNameCtrl       = TextEditingController(text: _t(q['customer_name']));
    _companyNameCtrl        = TextEditingController(text: _t(q['company_name']));
    _customerTrnCtrl        = TextEditingController(text: _t(q['customer_trn']));
    _customerPhoneCtrl      = TextEditingController(text: _t(q['customer_phone']));
    _salespersonNameCtrl    = TextEditingController(text: _t(q['salesperson_name']));
    _salespersonContactCtrl = TextEditingController(text: _t(q['salesperson_contact']));
    _salespersonPhoneCtrl   = TextEditingController(text: _t(q['salesperson_phone']));
    _notesCtrl              = TextEditingController(text: _t(q['notes']));

    // Fees
    _deliveryFeeCtrl     = TextEditingController(text: _t(q['delivery_fee']));
    _installationFeeCtrl = TextEditingController(text: _t(q['installation_fee']));
    _additionalFeeCtrl   = TextEditingController(text: _t(q['additional_details_fee']));
    _discountCtrl        = TextEditingController(
        text: _d(q['discount_amount']) > 0 ? _t(q['discount_amount']) : '');
    _vatPercentCtrl      = TextEditingController(text: _t(q['vat_percent']));

    // Per-item
    _itemCtrls = {};
    for (final item in _items) {
      _itemCtrls[item['id']] = {
        'qty':       TextEditingController(text: _t(item['quantity'])),
        'price':     TextEditingController(text: _d(item['unit_price']).toStringAsFixed(2)),
        'desc':      TextEditingController(text: _t(item['description'])),
        'length':    TextEditingController(text: _t(item['length'])),
        'width':     TextEditingController(text: _t(item['width'])),
        'prod_time': TextEditingController(text: _t(item['production_time'])),
      };
    }

    // Listeners for live total recalc
    for (final c in _feeControllers) c.addListener(_rebuild);
    for (final cmap in _itemCtrls.values) {
      cmap['qty']!.addListener(_rebuild);
      cmap['price']!.addListener(_rebuild);
    }
  }

  List<TextEditingController> get _feeControllers => [
        _deliveryFeeCtrl, _installationFeeCtrl,
        _additionalFeeCtrl, _discountCtrl, _vatPercentCtrl,
      ];

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    for (final c in [
      _customerNameCtrl, _companyNameCtrl, _customerTrnCtrl,
      _customerPhoneCtrl, _salespersonNameCtrl, _salespersonContactCtrl,
      _salespersonPhoneCtrl, _notesCtrl,
      _deliveryFeeCtrl, _installationFeeCtrl, _additionalFeeCtrl,
      _discountCtrl, _vatPercentCtrl,
    ]) c.dispose();
    for (final cmap in _itemCtrls.values) {
      for (final c in cmap.values) c.dispose();
    }
    super.dispose();
  }

  // ── Live totals ────────────────────────────────────────────────────────────

  double _itemLineTotal(dynamic id) {
    final cmap = _itemCtrls[id];
    if (cmap == null) return 0;
    return _d(cmap['qty']!.text) * _d(cmap['price']!.text);
  }

  double get _subtotal =>
      _items.fold(0.0, (s, i) => s + _itemLineTotal(i['id']));

  double get _deliveryFee     => _d(_deliveryFeeCtrl.text);
  double get _installationFee => _d(_installationFeeCtrl.text);
  double get _additionalFee   => _d(_additionalFeeCtrl.text);
  double get _discount        => _d(_discountCtrl.text);
  double get _vatPercent      => _d(_vatPercentCtrl.text);

  double get _taxableTotal  => _subtotal + _deliveryFee + _installationFee + _additionalFee;
  double get _afterDiscount => (_taxableTotal - _discount).clamp(0.0, double.infinity);
  double get _vatAmount     => _afterDiscount * (_vatPercent / 100);
  double get _netTotal      => _afterDiscount + _vatAmount;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // Update each item
      for (final item in _items) {
        final id    = item['id'];
        final cmap  = _itemCtrls[id]!;
        final qty   = _d(cmap['qty']!.text);
        final price = _d(cmap['price']!.text);
        await widget.supabase.from('quotation_items').update({
          'quantity':        qty.toInt(),
          'unit_price':      price,
          'line_total':      qty * price,
          'description':     cmap['desc']!.text.trim(),
          'length':          cmap['length']!.text.trim(),
          'width':           cmap['width']!.text.trim(),
          'production_time': cmap['prod_time']!.text.trim(),
        }).eq('id', id);
      }

      // Update quotation header + totals
      await widget.supabase.from('quotations').update({
        'customer_name':          _customerNameCtrl.text.trim(),
        'company_name':           _companyNameCtrl.text.trim(),
        'customer_trn':           _customerTrnCtrl.text.trim(),
        'customer_phone':         _customerPhoneCtrl.text.trim(),
        'salesperson_name':       _salespersonNameCtrl.text.trim(),
        'salesperson_contact':    _salespersonContactCtrl.text.trim(),
        'salesperson_phone':      _salespersonPhoneCtrl.text.trim(),
        'notes':                  _notesCtrl.text.trim(),
        'delivery_fee':           _deliveryFee,
        'installation_fee':       _installationFee,
        'additional_details_fee': _additionalFee,
        'discount_amount':        _discount,
        'vat_percent':            _vatPercent,
        'subtotal':               _subtotal,
        'taxable_total':          _taxableTotal,
        'vat_amount':             _vatAmount,
        'net_total':              _netTotal,
      }).eq('id', widget.quotation['id']);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item?'),
        content: Text('Remove "${_t(item['product_name'])}" from this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await widget.supabase.from('quotation_items').delete().eq('id', item['id']);
      final cmap = _itemCtrls.remove(item['id']);
      if (cmap != null) for (final c in cmap.values) c.dispose();
      setState(() => _items.remove(item));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.96,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: widget.borderColor),
          ),
          child: Column(
            children: [
              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Quotation',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: [

                      // ── Customer ──────────────────────────────────────────
                      _sectionHeader('Customer Info'),
                      _row([
                        _field(_customerNameCtrl, 'Customer Name', icon: Icons.person_outline),
                        _field(_companyNameCtrl,  'Company Name',  icon: Icons.business_outlined),
                      ]),
                      _row([
                        _field(_customerTrnCtrl,   'TRN',   icon: Icons.tag_outlined),
                        _field(_customerPhoneCtrl, 'Phone', icon: Icons.phone_outlined,
                            kb: TextInputType.phone),
                      ]),

                      // ── Salesperson ───────────────────────────────────────
                      _sectionHeader('Salesperson'),
                      _row([
                        _field(_salespersonNameCtrl,    'Name',            icon: Icons.badge_outlined),
                        _field(_salespersonContactCtrl, 'Email / Contact', icon: Icons.email_outlined),
                      ]),
                      _field(_salespersonPhoneCtrl, 'Salesperson Phone',
                          icon: Icons.phone_outlined, kb: TextInputType.phone),

                      // ── Items ─────────────────────────────────────────────
                      _sectionHeader('Items (${_items.length})'),
                      ..._items.asMap().entries.map((e) => _itemCard(e.key, e.value)),

                      // ── Fees & Discount ───────────────────────────────────
                      _sectionHeader('Fees & Discount'),
                      _row([
                        _field(_deliveryFeeCtrl,     'Delivery Fee',      kb: _numKb, isNum: true),
                        _field(_installationFeeCtrl, 'Installation Fee',  kb: _numKb, isNum: true),
                      ]),
                      _row([
                        _field(_additionalFeeCtrl, 'Additional Details Fee', kb: _numKb, isNum: true),
                        _field(_discountCtrl,      'Discount (AED)',
                            icon: Icons.local_offer_outlined, kb: _numKb, isNum: true),
                      ]),
                      _field(_vatPercentCtrl, 'VAT %', kb: _numKb, isNum: true),

                      // ── Notes ─────────────────────────────────────────────
                      _sectionHeader('Notes'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: _notesCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _dec('Notes', alignHint: true),
                        ),
                      ),

                      // ── Live totals ───────────────────────────────────────
                      _sectionHeader('Totals Preview'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Column(children: [
                          _totRow('Subtotal',      _subtotal),
                          _totRow('Taxable Total', _taxableTotal),
                          if (_discount > 0)
                            _totRow('Discount', _discount, isDiscount: true),
                          _totRow('VAT (${_fmt(_vatPercent)}%)', _vatAmount),
                          const Divider(height: 16),
                          _totRow('Net Total', _netTotal, bold: true),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_saving ? 'Saving…' : 'Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ── Item card ─────────────────────────────────────────────────────────────

  Widget _itemCard(int index, Map<String, dynamic> item) {
    final id        = item['id'];
    final cmap      = _itemCtrls[id]!;
    final lineTotal = _itemLineTotal(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: index + name + live total + delete
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: widget.accentColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t(item['product_name']),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                ),
              ),
            ),
            Text(
              'AED ${_fmt(lineTotal)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
              onPressed: () => _deleteItem(item),
              tooltip: 'Remove item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
          const SizedBox(height: 10),

          // Qty + Price
          _row([
            TextFormField(
              controller: cmap['qty'],
              keyboardType: TextInputType.number,
              decoration: _dec('Quantity'),
              validator: (v) =>
                  (int.tryParse(v?.trim() ?? '') ?? 0) <= 0 ? 'Required' : null,
            ),
            TextFormField(
              controller: cmap['price'],
              keyboardType: _numKb,
              decoration: _dec('Unit Price (AED)'),
              validator: (v) =>
                  (double.tryParse(v?.trim() ?? '') ?? -1) < 0 ? 'Required' : null,
            ),
          ]),
          const SizedBox(height: 8),

          // Description
          TextFormField(
            controller: cmap['desc'],
            minLines: 1, maxLines: 3,
            decoration: _dec('Description'),
          ),
          const SizedBox(height: 8),

          // Dimensions + production time
          _row([
            TextFormField(controller: cmap['length'], decoration: _dec('Length')),
            TextFormField(controller: cmap['width'],  decoration: _dec('Width')),
            TextFormField(controller: cmap['prod_time'], decoration: _dec('Prod. Time')),
          ]),
        ],
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  static const _numKb = TextInputType.numberWithOptions(decimal: true);

  InputDecoration _dec(String label,
      {IconData? icon, bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignHint,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFF222222),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.accentColor, width: 1.4),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    IconData? icon,
    TextInputType kb = TextInputType.text,
    bool isNum = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: kb,
        validator: isNum
            ? (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) return 'Invalid';
                return null;
              }
            : null,
        decoration: _dec(label, icon: icon),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(Expanded(child: children[i]));
      if (i < children.length - 1) spaced.add(const SizedBox(width: 10));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: spaced),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: widget.accentColor.withOpacity(0.7),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _totRow(String label, double value,
      {bool bold = false, bool isDiscount = false}) {
    final color = isDiscount
        ? Colors.green.shade400
        : bold ? widget.accentColor : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  color: color)),
        ),
        Text(
          isDiscount ? '− AED ${_fmt(value)}' : 'AED ${_fmt(value)}',
          style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: color),
        ),
      ]),
    );
  }
}
