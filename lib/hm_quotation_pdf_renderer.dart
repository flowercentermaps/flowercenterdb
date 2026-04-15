

import 'dart:typed_data';

import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class HMQuotationPdfRenderer {
  HMQuotationPdfRenderer({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;

  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  pw.Font? _fontArabicRegular;
  pw.Font? _fontArabicBold;
  pw.MemoryImage? _logoImage;

  static const PdfColor brandPurple = PdfColor.fromInt(0xFF581c8c); //gold - purple
  static const PdfColor brandDark = PdfColor.fromInt(0xFF111111); //black
  static const PdfColor lineGray = PdfColor.fromInt(0xFFBDBDBD); //grey
  // static const PdfColor softGray = PdfColor.fromInt(0xFFF6F6F6); //lgrey
  static const PdfColor softGray = PdfColor.fromInt(0xFFded2e8); //lgrey

  Future<void> _ensureAssets() async {
    if (_fontRegular == null) {
      final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      _fontRegular = pw.Font.ttf(regular);
    }

    if (_fontBold == null) {
      final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      _fontBold = pw.Font.ttf(bold);
    }

    if (_fontArabicRegular == null) {
      final arabicRegular =
      await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      _fontArabicRegular = pw.Font.ttf(arabicRegular);
    }

    if (_fontArabicBold == null) {
      final arabicBold =
      await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
      _fontArabicBold = pw.Font.ttf(arabicBold);
    }

    if (_logoImage == null) {
      final logo = await rootBundle.load('assets/icons/hamasat_logo.png');
      _logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    }
  }

  Future<Uint8List> build({
    required Map<String, dynamic> quotation,
    required List<Map<String, dynamic>> items,
    required Map<dynamic, Uint8List> temporaryItemImages,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    await _ensureAssets();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _fontRegular!,
        bold: _fontBold!,
        fontFallback: [
          _fontArabicRegular!,
          _fontArabicBold!,
        ],
      ),
    );

    final preparedItems = await _prepareItems(items, temporaryItemImages);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
        header: (context) => _buildPageHeader(quotation),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          _buildMetaSection(quotation),
          pw.SizedBox(height: 10),
          _buildItemsTable(preparedItems),
          pw.SizedBox(height: 12),
          _buildBottomSection(quotation),
          pw.SizedBox(height: 14),
          _buildBankDetailsSection(),
          pw.NewPage(),
          _buildTermsSection(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<List<_PreparedQuotationItem>> _prepareItems(
      List<Map<String, dynamic>> items,
      Map<dynamic, Uint8List> temporaryItemImages,
      ) async {
    final prepared = <_PreparedQuotationItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final itemId = item['id'];
      final originalPath = _text(item['image_path']);
      final customPath   = _text(item['custom_image_path']);

      // ── Load original image (catalog image, never changes) ──────────────
      Uint8List? originalBytes;
      if (originalPath.isNotEmpty) {
        try {
          originalBytes = await _supabase.storage
              .from('product-images')
              .download(originalPath);
        } catch (_) {
          originalBytes = null;
        }
      }

      // ── Load custom image: session cache first, then DB-persisted path ──
      Uint8List? customBytes = temporaryItemImages[itemId];
      if (customBytes == null && customPath.isNotEmpty) {
        try {
          customBytes = await _supabase.storage
              .from('product-images')
              .download(customPath);
        } catch (_) {
          customBytes = null;
        }
      }

      prepared.add(
        _PreparedQuotationItem(
          index: i + 1,
          raw: item,
          originalImageBytes: originalBytes,
          customImageBytes: customBytes,
        ),
      );
    }

    return prepared;
  }

  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  String _shapeArabic(String text) {
    if (text.trim().isEmpty) return text;
    return ArabicReshaper.instance.reshape(text);
  }

  String _pdfText(String text) {
    if (_containsArabic(text)) {
      return _shapeArabic(text);
    }
    return text;
  }

  pw.TextDirection _pdfDirection(String text) {
    return _containsArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  }

  pw.Font _pickRegularFont(String text) {
    return _containsArabic(text) ? _fontArabicRegular! : _fontRegular!;
  }

  pw.Font _pickBoldFont(String text) {
    return _containsArabic(text) ? _fontArabicBold! : _fontBold!;
  }

  pw.Widget _buildPageHeader(Map<String, dynamic> quote) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HAMASAT FLOWERS TR.',
                      style: pw.TextStyle(
                        color: brandPurple,
                        font: _fontBold,
                        fontSize: 10.5,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Phone: +97141234567',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Email: info@hamasatflowers.com',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Dubai, United Arab Emirates',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'TRN: 100425270400003',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Management: maheraktaa2000@gmail.com',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),

                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: 95,
                height: 70,
                alignment: pw.Alignment.center,
                child: pw.Image(
                  _logoImage!,
                  width: 90,
                  height: 65,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _pdfText('همسات لتجارة الزهور'),
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        color: brandPurple,
                        font: _fontArabicBold,
                        fontSize: 10.0,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 0.5),
                    pw.Row(
                      mainAxisAlignment: .end,
                      children: [
                        pw.Text(
                          _pdfText(' +97141234567'),
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: _fontArabicRegular,
                            fontSize: 7.0,
                          ),
                          textAlign: pw.TextAlign.end
                        ),
                        pw.Text(
                          _pdfText('الهاتف: '),
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: _fontArabicRegular,
                            fontSize: 7.0,
                          ),
                          textAlign: pw.TextAlign.end,
                        ),
                      ]
                    ),

                    pw.SizedBox(height: 0.5),
                    pw.Text(
                      _pdfText('البريد: info@hamasatflowers.com'),
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: _fontArabicRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 0.5),
                    pw.Text(
                      _pdfText('دبي، الإمارات العربية المتحدة'),
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: _fontArabicRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 0.5),
                    pw.Text(
                      _pdfText('الرقم الضريبي: 100425270400003'),
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: _fontArabicRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 0.5),
                    pw.Text(
                      _pdfText('الإدارة: maheraktaa2000@gmail.com'),
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: _fontArabicRegular,
                        fontSize: 7.0,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 1.2,
            color: brandPurple,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetaSection(Map<String, dynamic> quote) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _boxedSection(
            title: 'Customer Details',
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _labelValueRow('To Mr/s', _text(quote['customer_name'])),
                _labelValueRow('Company', _text(quote['company_name'])),
                _labelValueRow('TRN', _text(quote['customer_trn'])),
                _labelValueRow('Tel', _text(quote['customer_phone'])),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _boxedSection(
            title: 'Quotation Info',
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _labelValueRow('Quotation Date', _formatDate(quote['quote_date'])),
                _labelValueRow('Quotation No', _text(quote['quote_no'])),
                _labelValueRow('Salesperson', _text(quote['salesperson_name'])),
                _labelValueRow('Email', _text(quote['salesperson_contact'])),
                _labelValueRow('Phone', _text(quote['salesperson_phone'])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<_PreparedQuotationItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: lineGray, width: 0.7),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FixedColumnWidth(64),
        2: pw.FixedColumnWidth(54),
        3: pw.FlexColumnWidth(3.6),
        4: pw.FixedColumnWidth(34),
        5: pw.FixedColumnWidth(62),
        6: pw.FixedColumnWidth(68),
        7: pw.FixedColumnWidth(72),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: softGray),
          children: [
            _tableHeader('S.No'),
            _tableHeader('Picture'),
            _tableHeader('Item.No'),
            _tableHeader('Description'),
            _tableHeader('QTY'),
            _tableHeader('Unit Price'),
            _tableHeader('Total (AED)'),
            _tableHeader('Remarks'),
          ],
        ),
        ...items.map(_buildItemRow),
      ],
    );
  }

  pw.TableRow _buildItemRow(_PreparedQuotationItem item) {
    final data = item.raw;
    final descriptionLines = <String>[
      if (_text(data['product_name']).isNotEmpty) _text(data['product_name']),
      if (_text(data['description']).isNotEmpty) _text(data['description']),
      if (_text(data['length']).isNotEmpty) 'Length: ${_text(data['length'])}',
      if (_text(data['width']).isNotEmpty) 'Width: ${_text(data['width'])}',
      if (_text(data['depth']).isNotEmpty) 'Depth: ${_text(data['depth'])}',
      if (_text(data['production_time']).isNotEmpty)
        'Production Time: ${_text(data['production_time'])}',
    ];

    // ── Image cell: stacked Original + Custom when both present ────────────
    pw.Widget _singleImage(Uint8List bytes, {double height = 52}) =>
        pw.Container(
          height: height,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: lineGray, width: 0.5),
          ),
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
        );

    pw.Widget _labelledImage(Uint8List bytes, String label,
        {PdfColor labelColor = const PdfColor.fromInt(0xFF888888),
        double height = 44}) =>
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _singleImage(bytes, height: height),
            pw.Container(
              color: const PdfColor.fromInt(0xFF1A1A1A),
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Text(
                label,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ),
          ],
        );

    pw.Widget imageCell = pw.Container(
      height: 48,
      alignment: pw.Alignment.center,
      child: pw.Text('-', style: pw.TextStyle(fontSize: 8)),
    );

    final orig   = item.originalImageBytes;
    final custom = item.customImageBytes;

    if (orig != null && custom != null) {
      // Both present — stack Original on top, Custom below, with labels
      imageCell = pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _labelledImage(orig, 'ORIGINAL',
                labelColor: const PdfColor.fromInt(0xFF888888), height: 40),
             pw.SizedBox(height: 3),
            _labelledImage(custom, 'CUSTOM',
                labelColor: const PdfColor.fromInt(0xFFFFBF00), height: 40),
          ],
        ),
      );
    } else if (custom != null) {
      imageCell = pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: _singleImage(custom),
      );
    } else if (orig != null) {
      imageCell = pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: _singleImage(orig),
      );
    }

    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        _tableCell('${item.index}', align: pw.TextAlign.center),
        imageCell,
        _tableCell(_text(data['item_code']), align: pw.TextAlign.center),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: descriptionLines
                .map(
                  (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _pdfText(line),
                  textDirection: _pdfDirection(line),
                  style: pw.TextStyle(
                    fontSize: 8.4,
                    font: descriptionLines.first == line
                        ? _pickBoldFont(line)
                        : _pickRegularFont(line),
                  ),
                  textAlign: _containsArabic(line)
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                ),
              ),
            )
                .toList(),
          ),
        ),
        _tableCell('${_toInt(data['quantity'])}', align: pw.TextAlign.center),
        _tableCell(_formatMoney(data['unit_price']), align: pw.TextAlign.right),
        _tableCell(_formatMoney(data['line_total']), align: pw.TextAlign.right),
        _tableCell('', align: pw.TextAlign.center),
      ],
    );
  }

  pw.Widget _buildBottomSection(Map<String, dynamic> quote) {
    final notes = _text(quote['notes']).isEmpty
        ? 'Thank you for your inquiry. Please review the quotation details.'
        : _text(quote['notes']);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: _boxedSection(
            title: 'Notes',
            child: pw.Text(
              _pdfText(notes),
              textDirection: _pdfDirection(notes),
              textAlign:
              _containsArabic(notes) ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(
                font: _pickRegularFont(notes),
                fontSize: 8.7,
                lineSpacing: 2,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 2,
          child: _boxedSection(
            title: 'Summary',
            child: pw.Column(
              children: [
                _summaryRow('Subtotal', _formatMoney(quote['subtotal'])),
                _summaryRow('Delivery', _formatMoney(quote['delivery_fee'])),
                _summaryRow('Installation Work', _formatMoney(quote['installation_fee'])),
                _summaryRow('Additional Details', _formatMoney(quote['additional_details_fee'])),
                _summaryRow('Total Taxable', _formatMoney(quote['taxable_total'])),
                _summaryRow(
                  'VAT (${_formatMoney(quote['vat_percent'])}%)',
                  _formatMoney(quote['vat_amount']),
                ),
                _summaryRow(
                  'Net Total',
                  _formatMoney(quote['net_total']),
                  bold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBankDetailsSection() {
    return _boxedSection(
      title: 'Bank Details',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _labelValueRow('Beneficiary', 'HAMASAT FLOWERS TR LLC'),
          _labelValueRow('Account No', '18865788'),
          _labelValueRow('IBAN', 'AE920500000000018865788'),
          _labelValueRow('Currency', 'AED'),
          _labelValueRow('Bank', 'Abu Dhabi Islamic Bank ( ADIB )'),
          _labelValueRow('Branch', 'Dafza, dubai airport free zone'),
          _labelValueRow('SWIFT', 'ABDIAEAD'),
        ],
      ),
    );
  }

  pw.Widget _buildTermsSection() {
    final terms = <String>[
      '50% of the order value must be paid in advance. This amount is non-refundable, and order processing begins only after the amount is received in our bank account.',
      'Payment of the first installment constitutes full acceptance of these terms and conditions.',
      'The remaining 50% must be paid once the order is ready, and before delivery to the client, courier, or delivery representative.',
      'A penalty of 1% of the total order value per day will be charged for each day the client delays receiving the order.',
      'If the accumulated penalty equals the advance payment, the client forfeits their right to the order, and the company reserves the right to cancel it without refund.',
      'All sales are final. No returns or exchanges are accepted.',
      'The company is not responsible for any damage that occurs to the product after it leaves our premises.',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            color: softGray,
            border: pw.Border.all(color: lineGray, width: 0.8),
          ),
          child: pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 9,
              color: brandDark,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: lineGray, width: 0.8),
            right: pw.BorderSide(color: lineGray, width: 0.8),
            bottom: pw.BorderSide(color: lineGray, width: 0.8),
            horizontalInside: pw.BorderSide(color: lineGray, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(14),
            1: pw.FlexColumnWidth(),
          },
          children: terms.map((term) {
            return pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.top,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(8, 6, 4, 6),
                  child: pw.Text(
                    '•',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 8.4,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(0, 6, 8, 6),
                  child: pw.Text(
                    term,
                    style: pw.TextStyle(
                      font: _fontRegular,
                      fontSize: 8.2,
                      lineSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        children: [
          pw.Container(height: 0.8, color: lineGray),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for your business',
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: 8,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _boxedSection({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lineGray, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: softGray,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: 9,
                color: brandDark,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );
  }

  pw.Widget _labelValueRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 74,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: 8.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _pdfText(value),
              textDirection: _pdfDirection(value),
              textAlign:
              _containsArabic(value) ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(
                font: _pickRegularFont(value),
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: lineGray, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: bold ? _fontBold : _fontRegular,
                fontSize: 8.6,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold ? _fontBold : _fontRegular,
              fontSize: 8.6,
              color: bold ? brandDark : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: 8,
          color: brandDark,
        ),
      ),
    );
  }

  pw.Widget _tableCell(
      String text, {
        pw.TextAlign align = pw.TextAlign.left,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        _pdfText(text),
        textDirection: _pdfDirection(text),
        textAlign: align,
        style: pw.TextStyle(
          font: _pickRegularFont(text),
          fontSize: 8.2,
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0;
  }

  String _formatMoney(dynamic value) {
    final number = _toDouble(value);
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
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

  String _text(dynamic value) {
    return (value ?? '').toString().trim();
  }
}

class _PreparedQuotationItem {
  _PreparedQuotationItem({
    required this.index,
    required this.raw,
    required this.originalImageBytes,
    required this.customImageBytes,
  });

  final int index;
  final Map<String, dynamic> raw;
  /// Bytes loaded from item['image_path'] — the catalog original, never changed.
  final Uint8List? originalImageBytes;
  /// Bytes loaded from item['custom_image_path'] (or session cache) — agent override.
  final Uint8List? customImageBytes;

  /// Convenience: whichever image the PDF should use when only one slot is available.
  Uint8List? get imageBytes => customImageBytes ?? originalImageBytes;
}