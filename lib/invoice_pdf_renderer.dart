import 'dart:typed_data';

import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfRenderer {
  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  pw.Font? _fontArabicRegular;
  pw.Font? _fontArabicBold;
  pw.MemoryImage? _logoImage;

  static const PdfColor _brandGold  = PdfColor.fromInt(0xFFba8c50);
  static const PdfColor _brandDark  = PdfColor.fromInt(0xFF111111);
  static const PdfColor _lineGray   = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor _softGray   = PdfColor.fromInt(0xFFf1e8dc);
  static const PdfColor _paidGreen  = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _redColor   = PdfColor.fromInt(0xFFC62828);

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
      final logo = await rootBundle.load('assets/icons/logo_full.png');
      _logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    }
  }

  /// [invoice]   — row from the `invoices` table
  /// [quotation] — row from the `quotations` table (customer info + financials)
  /// [items]     — rows from `quotation_items` (must include unit_price, quantity, line_total)
  Future<Uint8List> build({
    required Map<String, dynamic> invoice,
    required Map<String, dynamic> quotation,
    required List<Map<String, dynamic>> items,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    await _ensureAssets();

    final isPaid   = _t(invoice['status']) == 'paid';
    final isPartial = _t(invoice['status']) == 'partial';
    final totalAmount = _num(invoice['total_amount']);
    final amountPaid  = _num(invoice['amount_paid']);
    final balance     = totalAmount - amountPaid;

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
        header: (ctx) => _buildHeader(invoice),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildCustomerAndMeta(invoice, quotation),
          pw.SizedBox(height: 14),
          _buildItemsTable(items),
          pw.SizedBox(height: 14),
          _buildSummary(quotation, invoice, totalAmount, amountPaid, balance),
          if (isPaid) ...[
            pw.SizedBox(height: 16),
            _buildPaidStamp(),
          ] else if (isPartial) ...[
            pw.SizedBox(height: 16),
            _buildPartialNote(amountPaid, balance),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(Map<String, dynamic> invoice) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
                    _hLine('Phone: +97141234567'),
                    _hLine('Email: info@flowercenter.ae'),
                    _hLine('Dubai, United Arab Emirates'),
                    _hLine('TRN: 100393229800003'),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 90,
                height: 65,
                child: pw.Image(_logoImage!, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: pw.TextStyle(
                            font: _fontBold,
                            color: _brandGold,
                            fontSize: 16)),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice No: ${_t(invoice['invoice_number'])}',
                        style:
                            pw.TextStyle(font: _fontBold, fontSize: 8.5)),
                    pw.SizedBox(height: 3),
                    pw.Text('Date: ${_t(invoice['issue_date'])}',
                        style: pw.TextStyle(
                            font: _fontRegular, fontSize: 8.5)),
                    if (_t(invoice['due_date']).isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text('Due: ${_t(invoice['due_date'])}',
                          style: pw.TextStyle(
                              font: _fontBold,
                              fontSize: 8.5,
                              color: _redColor)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 1.2, color: _brandGold),
        ],
      ),
    );
  }

  // ── Customer + Quotation ref ─────────────────────────────────────────────────

  pw.Widget _buildCustomerAndMeta(
      Map<String, dynamic> invoice, Map<String, dynamic> quotation) {
    final customerName    = _t(quotation['customer_name']);
    final companyName     = _t(quotation['company_name']);
    final customerPhone   = _t(quotation['customer_phone']);
    final customerTrn     = _t(quotation['customer_trn']);
    final quoteNo         = _t(quotation['quote_no']);
    final salesperson     = _t(quotation['salesperson_name']);
    final invoiceNotes    = _t(invoice['notes']);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _softGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO',
                    style: pw.TextStyle(
                        font: _fontBold,
                        fontSize: 7.5,
                        color: _brandGold)),
                pw.SizedBox(height: 4),
                if (customerName.isNotEmpty)
                  pw.Text(customerName,
                      style:
                          pw.TextStyle(font: _fontBold, fontSize: 9.5)),
                if (companyName.isNotEmpty)
                  pw.Text(companyName,
                      style: pw.TextStyle(
                          font: _fontRegular, fontSize: 8.5)),
                if (customerPhone.isNotEmpty)
                  pw.Text(customerPhone,
                      style: pw.TextStyle(
                          font: _fontRegular, fontSize: 8.5)),
                if (customerTrn.isNotEmpty)
                  pw.Text('TRN: $customerTrn',
                      style: pw.TextStyle(
                          font: _fontRegular, fontSize: 8)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (quoteNo.isNotEmpty)
                  _metaLine('Ref. Quotation:', quoteNo),
                if (salesperson.isNotEmpty)
                  _metaLine('Sales by:', salesperson),
                if (invoiceNotes.isNotEmpty)
                  _metaLine('Notes:', invoiceNotes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('$label ',
                style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 8,
                    color: _brandDark)),
            pw.Text(value,
                style:
                    pw.TextStyle(font: _fontBold, fontSize: 8)),
          ],
        ),
      );

  // ── Items table ──────────────────────────────────────────────────────────────

  pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lineGray, width: 0.7),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),   // #
        1: pw.FixedColumnWidth(56),   // Item Code
        2: pw.FlexColumnWidth(3.0),   // Description
        3: pw.FixedColumnWidth(30),   // Qty
        4: pw.FixedColumnWidth(58),   // Unit Price
        5: pw.FixedColumnWidth(62),   // Total
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _softGray),
          children: [
            _th('#'),
            _th('Item No.'),
            _th('Description'),
            _th('Qty'),
            _th('Unit Price'),
            _th('Total'),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          final name = _t(item['product_name']);
          final desc = _t(item['description']);

          final descLines = <String>[
            if (name.isNotEmpty) name,
            if (desc.isNotEmpty) desc,
            if (_t(item['length']).isNotEmpty || _t(item['width']).isNotEmpty)
              'L: ${_t(item['length'])}  W: ${_t(item['width'])}',
          ];

          final code = _t(item['item_code']).isNotEmpty
              ? _t(item['item_code'])
              : _t(item['supplier_code'] ?? '');

          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _td('${i + 1}', align: pw.TextAlign.center),
              _td(code, align: pw.TextAlign.center),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: descLines.asMap().entries.map((e2) {
                    final line    = e2.value;
                    final isFirst = e2.key == 0;
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
              _td(_t(item['quantity']), align: pw.TextAlign.center),
              _td('AED ${_fmtNum(item['unit_price'])}',
                  align: pw.TextAlign.right),
              _td('AED ${_fmtNum(item['line_total'])}',
                  align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  // ── Financial summary ────────────────────────────────────────────────────────

  pw.Widget _buildSummary(
    Map<String, dynamic> quotation,
    Map<String, dynamic> invoice,
    double totalAmount,
    double amountPaid,
    double balance,
  ) {
    final deliveryFee    = _num(quotation['delivery_fee']);
    final installFee     = _num(quotation['installation_fee']);
    final additionalFee  = _num(quotation['additional_details_fee']);
    final discountAmount = _num(quotation['discount_amount']);
    final vatPercent     = _num(quotation['vat_percent']);
    final vatAmount      = _num(quotation['vat_amount']);
    final subtotal       = _num(quotation['subtotal']);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Spacer(),
        pw.Container(
          width: 220,
          child: pw.Column(
            children: [
              _summaryRow('Subtotal', subtotal),
              if (deliveryFee > 0) _summaryRow('Delivery', deliveryFee),
              if (installFee > 0) _summaryRow('Installation', installFee),
              if (additionalFee > 0) _summaryRow('Additional', additionalFee),
              if (discountAmount > 0)
                _summaryRow('Discount', discountAmount, isDiscount: true),
              _summaryRow('VAT (${vatPercent.toStringAsFixed(0)}%)', vatAmount),
              pw.Container(height: 0.8, color: _brandGold),
              _summaryRow('Total', totalAmount, bold: true),
              if (amountPaid > 0) ...[
                _summaryRow('Amount Paid', amountPaid, color: _paidGreen),
                _summaryRow('Balance Due', balance,
                    bold: true,
                    color: balance <= 0 ? _paidGreen : _redColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryRow(String label, double value,
      {bool bold = false, PdfColor? color, bool isDiscount = false}) {
    final effectiveColor =
        isDiscount ? const PdfColor.fromInt(0xFF2E7D32) : color;
    final style = pw.TextStyle(
      font: bold ? _fontBold : _fontRegular,
      fontSize: bold ? 9.5 : 8.5,
      color: effectiveColor,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(
            '${isDiscount ? '- ' : ''}AED ${_fmtNum(value)}',
            style: style,
          ),
        ],
      ),
    );
  }

  // ── Paid stamp / partial note ────────────────────────────────────────────────

  pw.Widget _buildPaidStamp() {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _paidGreen, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text('PAID IN FULL',
            style: pw.TextStyle(
                font: _fontBold, fontSize: 14, color: _paidGreen)),
      ),
    );
  }

  pw.Widget _buildPartialNote(double amountPaid, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1),
        border: pw.Border.all(color: _brandGold, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Partial payment of AED ${_fmtNum(amountPaid)} received. '
              'Balance due: AED ${_fmtNum(balance)}.',
              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

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
              pw.Text('Flower Center L.L.C — Invoice',
                  style: pw.TextStyle(
                      font: _fontRegular,
                      fontSize: 7.5,
                      color: const PdfColor.fromInt(0xFF888888))),
              pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                  style:
                      pw.TextStyle(font: _fontRegular, fontSize: 7.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────────────────

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                font: _fontBold, fontSize: 8, color: _brandDark)),
      );

  pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          _shape(text),
          textDirection: _dir(text),
          textAlign: align,
          style: pw.TextStyle(font: _regFont(text), fontSize: 8.2),
        ),
      );

  pw.Widget _hLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text,
            style: pw.TextStyle(font: _fontRegular, fontSize: 7.0)),
      );

  // ── Text / number helpers ────────────────────────────────────────────────────

  bool _isArabic(String t) => RegExp(r'[\u0600-\u06FF]').hasMatch(t);

  String _shape(String text) => text.trim().isEmpty
      ? text
      : _isArabic(text)
          ? ArabicReshaper.instance.reshape(text)
          : text;

  pw.TextDirection _dir(String t) =>
      _isArabic(t) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  pw.Font _regFont(String t) =>
      _isArabic(t) ? _fontArabicRegular! : _fontRegular!;

  pw.Font _boldFont(String t) =>
      _isArabic(t) ? _fontArabicBold! : _fontBold!;

  String _t(dynamic v) => (v ?? '').toString().trim();

  double _num(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  String _fmtNum(dynamic v) {
    final d = _num(v);
    return d.toStringAsFixed(2);
  }
}
