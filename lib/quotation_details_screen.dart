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

class QuotationDetailsScreen extends StatefulWidget {
  final dynamic quotationId;
  final bool isHamasat;

  const QuotationDetailsScreen({
    super.key,
    required this.quotationId,
    required this.isHamasat,
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
          FilledButton.icon(
            onPressed: _isPreparingPdf ? null : _handleExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview PDF'),
          ),
        ],
      ),
    );
    return widget.isHamasat
        ? Theme(data: _hamTheme(context), child: scaffold)
        : scaffold;
  }

  Widget _summaryRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatMoneyWithAed(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold ? _accentColor : null,
            ),
          ),
        ],
      ),
    );
  }
}