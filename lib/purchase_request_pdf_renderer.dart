import 'dart:typed_data';

import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseRequestPdfRenderer {
  PurchaseRequestPdfRenderer({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  pw.Font? _fontArabicRegular;
  pw.Font? _fontArabicBold;
  pw.MemoryImage? _logoImage;

  static const PdfColor _brandGold = PdfColor.fromInt(0xFFba8c50);
  static const PdfColor _brandDark = PdfColor.fromInt(0xFF111111);
  static const PdfColor _lineGray  = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor _softGray  = PdfColor.fromInt(0xFFf1e8dc);

  Future<void> _ensureAssets() async {
    _fontRegular ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    _fontBold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    _fontArabicRegular ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    _fontArabicBold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));
    if (_logoImage == null) {
      final logo = await rootBundle.load('assets/icons/logo.png');
      _logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    }
  }

  /// [items] each map must contain all product fields plus:
  ///   'quantity' (int) and 'notes' (String).
  Future<Uint8List> build({
    required List<Map<String, dynamic>> items,
    required String refNumber,
    required String date,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    await _ensureAssets();

    // Load images from Supabase storage
    final prepared = <_PreparedItem>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final imagePath = _t(item['image_path']);
      Uint8List? imageBytes;
      if (imagePath.isNotEmpty) {
        try {
          imageBytes = await _supabase.storage
              .from('product-images')
              .download(imagePath);
        } catch (_) {}
      }
      prepared.add(_PreparedItem(index: i + 1, raw: item, imageBytes: imageBytes));
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _fontRegular!,
        bold: _fontBold!,
        fontFallback: [_fontArabicRegular!, _fontArabicBold!],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
        header: (ctx) => _buildHeader(refNumber, date),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [_buildTable(prepared)],
      ),
    );

    return pdf.save();
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(String ref, String date) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left — company details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FLOWER CENTER L.L.C',
                        style: pw.TextStyle(
                            font: _fontBold,
                            color: _brandGold,
                            fontSize: 10.5)),
                    pw.SizedBox(height: 4),
                    _headerLine('Phone: +97141234567'),
                    _headerLine('Email: info@flowercenter.ae'),
                    _headerLine('Dubai, United Arab Emirates'),
                    _headerLine('TRN: 100393229800003'),
                  ],
                ),
              ),
              // Centre — logo
              pw.SizedBox(width: 10),
              pw.Container(
                width: 90,
                height: 65,
                child: pw.Image(_logoImage!, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
              // Right — document info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('PURCHASE REQUEST',
                        style: pw.TextStyle(
                            font: _fontBold,
                            color: _brandGold,
                            fontSize: 13)),
                    pw.SizedBox(height: 8),
                    pw.Text('Ref No: $ref',
                        style: pw.TextStyle(font: _fontBold, fontSize: 8.5)),
                    pw.SizedBox(height: 3),
                    pw.Text('Date: $date',
                        style:
                            pw.TextStyle(font: _fontRegular, fontSize: 8.5)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 1.2, color: _brandGold),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  pw.Widget _headerLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text,
            style: pw.TextStyle(font: _fontRegular, fontSize: 7.0)),
      );

  // ── Items table ────────────────────────────────────────────────────────────

  pw.Widget _buildTable(List<_PreparedItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lineGray, width: 0.7),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),  // #
        1: pw.FixedColumnWidth(64),  // Image
        2: pw.FixedColumnWidth(56),  // Item Code
        3: pw.FlexColumnWidth(3.0),  // Description
        4: pw.FixedColumnWidth(30),  // Qty
        5: pw.FlexColumnWidth(1.6),  // Notes
      },
      children: [
        // Table header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _softGray),
          children: [
            _th('#'),
            _th('Image'),
            _th('Item No.'),
            _th('Description'),
            _th('Qty'),
            _th('Notes'),
          ],
        ),
        // Data rows
        ...items.map((prep) {
          final d = prep.raw;

          final descLines = <String>[
            if (_t(d['product_name']).isNotEmpty) _t(d['product_name']),
            if (_t(d['description']).isNotEmpty) _t(d['description']),
            if (_t(d['length']).isNotEmpty || _t(d['width']).isNotEmpty)
              'L: ${_t(d['length'])}   W: ${_t(d['width'])}',
            if (_t(d['production_time']).isNotEmpty)
              'Production: ${_t(d['production_time'])}',
          ];

          pw.Widget imageCell;
          if (prep.imageBytes != null) {
            imageCell = pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Image(pw.MemoryImage(prep.imageBytes!),
                  fit: pw.BoxFit.cover, height: 58),
            );
          } else {
            imageCell = pw.Center(
              child: pw.Text('—',
                  style: pw.TextStyle(font: _fontRegular, fontSize: 8)),
            );
          }

          final itemCode = _t(d['item_code']).isNotEmpty
              ? _t(d['item_code'])
              : _t(d['supplier_code']);

          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _td('${prep.index}', align: pw.TextAlign.center),
              imageCell,
              _td(itemCode, align: pw.TextAlign.center),
              // Description cell — name bold, rest regular
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: descLines.asMap().entries.map((e) {
                    final line = e.value;
                    final isFirst = e.key == 0;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        _shape(line),
                        textDirection: _dir(line),
                        style: pw.TextStyle(
                          font: isFirst ? _boldFont(line) : _regFont(line),
                          fontSize: isFirst ? 8.6 : 8.0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              _td('${d['quantity'] ?? 1}', align: pw.TextAlign.center),
              _td(_t(d['notes'])),
            ],
          );
        }),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        children: [
          pw.Container(height: 0.8, color: _lineGray),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Flower Center L.L.C — Internal Purchase Request',
                style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 7.5,
                    color: const PdfColor.fromInt(0xFF888888)),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(font: _fontRegular, fontSize: 7.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                font: _fontBold, fontSize: 8, color: _brandDark)),
      );

  pw.Widget _td(String text,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          _shape(text),
          textDirection: _dir(text),
          textAlign: align,
          style: pw.TextStyle(font: _regFont(text), fontSize: 8.2),
        ),
      );

  bool _isArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  String _shape(String text) {
    if (text.trim().isEmpty) return text;
    return _isArabic(text) ? ArabicReshaper.instance.reshape(text) : text;
  }

  pw.TextDirection _dir(String text) =>
      _isArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  pw.Font _regFont(String text) =>
      _isArabic(text) ? _fontArabicRegular! : _fontRegular!;

  pw.Font _boldFont(String text) =>
      _isArabic(text) ? _fontArabicBold! : _fontBold!;

  String _t(dynamic v) => (v ?? '').toString().trim();
}

class _PreparedItem {
  const _PreparedItem(
      {required this.index, required this.raw, this.imageBytes});
  final int index;
  final Map<String, dynamic> raw;
  final Uint8List? imageBytes;
}
