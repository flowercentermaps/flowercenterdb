// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:excel/excel.dart' hide Border;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class QuotationDetailsScreen extends StatefulWidget {
//   final dynamic quotationId;
//
//   const QuotationDetailsScreen({
//     super.key,
//     required this.quotationId,
//   });
//
//   @override
//   State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
// }
//
// class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   bool _isLoading = true;
//   bool _isExportingXlsx = false;
//   bool _isExportingPdf = false;
//   String? _error;
//
//   Map<String, dynamic>? _quotation;
//   List<Map<String, dynamic>> _items = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadQuotation();
//   }
//
//   Future<void> _loadQuotation() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final quotationResponse = await _supabase
//           .from('quotations')
//           .select()
//           .eq('id', widget.quotationId)
//           .single();
//
//       final itemsResponse = await _supabase
//           .from('quotation_items')
//           .select()
//           .eq('quotation_id', widget.quotationId)
//           .order('id', ascending: true);
//
//       if (!mounted) return;
//
//       setState(() {
//         _quotation = Map<String, dynamic>.from(quotationResponse as Map);
//         _items = (itemsResponse as List)
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   double _toDouble(dynamic value) {
//     if (value == null) return 0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is num) return value.toInt();
//     return int.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _text(dynamic value) {
//     return (value ?? '').toString().trim();
//   }
//
//   String _formatMoney(dynamic value) {
//     final number = _toDouble(value);
//     if (number == number.roundToDouble()) {
//       return number.toInt().toString();
//     }
//     return number.toStringAsFixed(2);
//   }
//
//   String _formatDate(dynamic value) {
//     final raw = _text(value);
//     if (raw.isEmpty) return '';
//     final parsed = DateTime.tryParse(raw);
//     if (parsed == null) return raw;
//     final day = parsed.day.toString().padLeft(2, '0');
//     final month = parsed.month.toString().padLeft(2, '0');
//     final year = parsed.year.toString();
//     return '$day/$month/$year';
//   }
//
//   String _imageUrlFromPath(String imagePath) {
//     return _supabase.storage.from('product-images').getPublicUrl(imagePath);
//   }
//
//   Future<Uint8List?> _downloadImageBytes(String imagePath) async {
//     try {
//       return await _supabase.storage.from('product-images').download(imagePath);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<String> _exportToTemplateXlsx() async {
//     final quote = _quotation!;
//     final templateData =
//     await rootBundle.load('assets/templates/quotation_template.xlsx');
//
//     final excel = Excel.decodeBytes(
//       templateData.buffer.asUint8List(),
//     );
//
//     final sheetName = excel.tables.keys.contains('Trees & Arrangment')
//         ? 'Trees & Arrangment'
//         : excel.tables.keys.first;
//
//     final sheet = excel[sheetName];
//
//     void setText(String cell, String value) {
//       sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
//     }
//
//     void setNumber(String cell, double value) {
//       sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
//     }
//
//     setText('D7', _text(quote['customer_name']));
//     setText('D8', _text(quote['company_name']));
//     setText('D9', _text(quote['customer_trn']));
//     setText('D10', _text(quote['customer_phone']));
//
//     setText('K7', _formatDate(quote['quote_date']));
//     setText('K8', _text(quote['quote_no']));
//     setText('K9', _text(quote['salesperson_name']));
//     setText('K10', _text(quote['salesperson_contact']));
//
//     const int startRow = 12;
//     const int maxRows = 20;
//
//     for (var i = 0; i < maxRows; i++) {
//       final row = startRow + i;
//       setText('B$row', '');
//       setText('C$row', '');
//       setText('D$row', '');
//       setText('E$row', '');
//       setText('F$row', '');
//       setText('G$row', '');
//       setText('H$row', '');
//       setText('I$row', '');
//       setText('J$row', '');
//       setText('K$row', '');
//     }
//
//     for (var i = 0; i < _items.length && i < maxRows; i++) {
//       final item = _items[i];
//       final row = startRow + i;
//
//       setNumber('B$row', i + 1.0);
//       setText('D$row', _text(item['item_code']));
//       setText('E$row', _text(item['product_name']).isEmpty
//           ? _text(item['description'])
//           : _text(item['product_name']));
//       setText('F$row', _text(item['length']));
//       setText('G$row', _text(item['width']));
//       setText('H$row', _text(item['production_time']));
//       setNumber('I$row', _toInt(item['quantity']).toDouble());
//       setNumber('J$row', _toDouble(item['unit_price']));
//       setNumber('K$row', _toDouble(item['line_total']));
//     }
//
//     setNumber('K33', _toDouble(quote['delivery_fee']));
//     setNumber('K34', _toDouble(quote['installation_fee']));
//     setNumber('K35', _toDouble(quote['additional_details_fee']));
//
//     final dir = await getApplicationDocumentsDirectory();
//     final quoteNo = _text(quote['quote_no']).replaceAll('/', '-');
//     final filePath = '${dir.path}/$quoteNo.xlsx';
//
//     final bytes = excel.encode();
//     if (bytes == null) {
//       throw Exception('Failed to generate XLSX.');
//     }
//
//     final file = File(filePath)
//       ..createSync(recursive: true)
//       ..writeAsBytesSync(bytes, flush: true);
//
//     return file.path;
//   }
//
//   Future<String> _exportToPdf() async {
//     final quote = _quotation!;
//     final pdf = pw.Document();
//
//     final List<pw.Widget> itemRows = [];
//
//     for (var i = 0; i < _items.length; i++) {
//       final item = _items[i];
//       final imagePath = _text(item['image_path']);
//       pw.Widget imageWidget = pw.SizedBox(
//         width: 48,
//         height: 48,
//       );
//
//       if (imagePath.isNotEmpty) {
//         final bytes = await _downloadImageBytes(imagePath);
//         if (bytes != null) {
//           imageWidget = pw.Container(
//             width: 48,
//             height: 48,
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
//             ),
//             child: pw.Image(
//               pw.MemoryImage(bytes),
//               fit: pw.BoxFit.cover,
//             ),
//           );
//         }
//       }
//
//       itemRows.add(
//         pw.Container(
//           decoration: pw.BoxDecoration(
//             border: pw.Border(
//               left: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
//               right: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
//               bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
//             ),
//           ),
//           child: pw.Row(
//             crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//             children: [
//               _pdfCell('${i + 1}', width: 24),
//               _pdfCellWidget(imageWidget, width: 60),
//               _pdfCell(_text(item['item_code']), width: 52),
//               _pdfCell(
//                 _text(item['product_name']).isEmpty
//                     ? _text(item['description'])
//                     : _text(item['product_name']),
//                 width: 150,
//                 align: pw.TextAlign.left,
//               ),
//               _pdfCell(_text(item['length']), width: 40),
//               _pdfCell(_text(item['width']), width: 40),
//               _pdfCell(_text(item['production_time']), width: 58),
//               _pdfCell('${_toInt(item['quantity'])}', width: 32),
//               _pdfCell(_formatMoney(item['unit_price']), width: 52),
//               _pdfCell(_formatMoney(item['line_total']), width: 58),
//             ],
//           ),
//         ),
//       );
//     }
//
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4.landscape,
//         margin: const pw.EdgeInsets.all(18),
//         build: (context) => [
//           pw.Container(
//             padding: const pw.EdgeInsets.all(10),
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.teal700, width: 1),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 pw.Center(
//                   child: pw.Text(
//                     'QUOTATION',
//                     style: pw.TextStyle(
//                       fontSize: 18,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColors.teal700,
//                     ),
//                   ),
//                 ),
//                 pw.SizedBox(height: 10),
//                 pw.Row(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Expanded(
//                       child: pw.Container(
//                         padding: const pw.EdgeInsets.all(8),
//                         decoration: pw.BoxDecoration(
//                           border: pw.Border.all(
//                             color: PdfColors.grey600,
//                             width: 0.8,
//                           ),
//                         ),
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             pw.Text('To: ${_text(quote['customer_name'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('Company: ${_text(quote['company_name'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('TRN: ${_text(quote['customer_trn'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('Tel: ${_text(quote['customer_phone'])}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                     pw.SizedBox(width: 10),
//                     pw.Expanded(
//                       child: pw.Container(
//                         padding: const pw.EdgeInsets.all(8),
//                         decoration: pw.BoxDecoration(
//                           border: pw.Border.all(
//                             color: PdfColors.grey600,
//                             width: 0.8,
//                           ),
//                         ),
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             pw.Text('Quotation Date: ${_formatDate(quote['quote_date'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('Quotation Number: ${_text(quote['quote_no'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('Salesperson: ${_text(quote['salesperson_name'])}'),
//                             pw.SizedBox(height: 4),
//                             pw.Text('Contact: ${_text(quote['salesperson_contact'])}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 12),
//                 _pdfHeaderRow(),
//                 ...itemRows,
//                 pw.Container(
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
//                   ),
//                   padding: const pw.EdgeInsets.all(10),
//                   child: pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Expanded(
//                         flex: 3,
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             pw.Text(
//                               'Terms & Conditions',
//                               style: pw.TextStyle(
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                             pw.SizedBox(height: 4),
//                             pw.Text(
//                               _text(quote['notes']).isEmpty
//                                   ? 'Thank you for your business.'
//                                   : _text(quote['notes']),
//                             ),
//                           ],
//                         ),
//                       ),
//                       pw.SizedBox(width: 14),
//                       pw.Expanded(
//                         flex: 2,
//                         child: pw.Column(
//                           children: [
//                             _pdfSummaryRow('Subtotal', _formatMoney(quote['subtotal'])),
//                             _pdfSummaryRow('Delivery', _formatMoney(quote['delivery_fee'])),
//                             _pdfSummaryRow('Installation Work', _formatMoney(quote['installation_fee'])),
//                             _pdfSummaryRow('Additional Details', _formatMoney(quote['additional_details_fee'])),
//                             _pdfSummaryRow('Total Taxable', _formatMoney(quote['taxable_total'])),
//                             _pdfSummaryRow(
//                               'VAT (${_formatMoney(quote['vat_percent'])}%)',
//                               _formatMoney(quote['vat_amount']),
//                             ),
//                             _pdfSummaryRow(
//                               'Net Total',
//                               _formatMoney(quote['net_total']),
//                               bold: true,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//
//     final dir = await getApplicationDocumentsDirectory();
//     final quoteNo = _text(quote['quote_no']).replaceAll('/', '-');
//     final filePath = '${dir.path}/$quoteNo.pdf';
//
//     final file = File(filePath);
//     await file.writeAsBytes(await pdf.save(), flush: true);
//
//     return file.path;
//   }
//
//   pw.Widget _pdfHeaderRow() {
//     return pw.Container(
//       decoration: pw.BoxDecoration(
//         color: PdfColors.teal700,
//         border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
//       ),
//       child: pw.Row(
//         children: [
//           _pdfHeaderCell('S.No', width: 24),
//           _pdfHeaderCell('Picture', width: 60),
//           _pdfHeaderCell('Item.No', width: 52),
//           _pdfHeaderCell('Description', width: 150),
//           _pdfHeaderCell('Length', width: 40),
//           _pdfHeaderCell('Width', width: 40),
//           _pdfHeaderCell('Production Time', width: 58),
//           _pdfHeaderCell('QTY', width: 32),
//           _pdfHeaderCell('Unit Price', width: 52),
//           _pdfHeaderCell('Total (AED)', width: 58),
//         ],
//       ),
//     );
//   }
//
//   pw.Widget _pdfHeaderCell(String text, {required double width}) {
//     return pw.Container(
//       width: width,
//       padding: const pw.EdgeInsets.all(6),
//       alignment: pw.Alignment.center,
//       child: pw.Text(
//         text,
//         textAlign: pw.TextAlign.center,
//         style: pw.TextStyle(
//           color: PdfColors.white,
//           fontSize: 8,
//           fontWeight: pw.FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   pw.Widget _pdfCell(
//       String text, {
//         required double width,
//         pw.TextAlign align = pw.TextAlign.center,
//       }) {
//     return pw.Container(
//       width: width,
//       padding: const pw.EdgeInsets.all(4),
//       alignment: align == pw.TextAlign.left
//           ? pw.Alignment.centerLeft
//           : pw.Alignment.center,
//       child: pw.Text(
//         text,
//         textAlign: align,
//         style: const pw.TextStyle(fontSize: 8),
//       ),
//     );
//   }
//
//   pw.Widget _pdfCellWidget(
//       pw.Widget child, {
//         required double width,
//       }) {
//     return pw.Container(
//       width: width,
//       padding: const pw.EdgeInsets.all(4),
//       alignment: pw.Alignment.center,
//       child: child,
//     );
//   }
//
//   pw.Widget _pdfSummaryRow(String label, String value, {bool bold = false}) {
//     return pw.Container(
//       decoration: pw.BoxDecoration(
//         border: pw.Border(
//           bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
//         ),
//       ),
//       padding: const pw.EdgeInsets.symmetric(vertical: 4),
//       child: pw.Row(
//         children: [
//           pw.Expanded(
//             child: pw.Text(
//               label,
//               style: pw.TextStyle(
//                 fontSize: 9,
//                 fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//               ),
//             ),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(
//               fontSize: 9,
//               fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _handleExportXlsx() async {
//     if (_quotation == null || _isExportingXlsx) return;
//
//     setState(() {
//       _isExportingXlsx = true;
//     });
//
//     try {
//       final path = await _exportToTemplateXlsx();
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Saved: $path')),
//       );
//
//       await OpenFilex.open(path);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('XLSX export failed: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isExportingXlsx = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _handleExportPdf() async {
//     if (_quotation == null || _isExportingPdf) return;
//
//     setState(() {
//       _isExportingPdf = true;
//     });
//
//     try {
//       final path = await _exportToPdf();
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Saved: $path')),
//       );
//
//       await OpenFilex.open(path);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF export failed: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isExportingPdf = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _sharePdf() async {
//     if (_quotation == null) return;
//     final path = await _exportToPdf();
//     await Share.shareXFiles([XFile(path)]);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final quote = _quotation;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       appBar: AppBar(
//         title: const Text('Quotation Details'),
//         backgroundColor: const Color(0xFF111111),
//         actions: [
//           IconButton(
//             onPressed: _isLoading ? null : _handleExportXlsx,
//             icon: _isExportingXlsx
//                 ? const SizedBox(
//               width: 18,
//               height: 18,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : const Icon(Icons.table_view_outlined),
//           ),
//           IconButton(
//             onPressed: _isLoading ? null : _handleExportPdf,
//             icon: _isExportingPdf
//                 ? const SizedBox(
//               width: 18,
//               height: 18,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : const Icon(Icons.picture_as_pdf_outlined),
//           ),
//           IconButton(
//             onPressed: _isLoading ? null : _sharePdf,
//             icon: const Icon(Icons.share_outlined),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Text(
//             _error!,
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : quote == null
//           ? const Center(child: Text('Quotation not found'))
//           : ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _text(quote['quote_no']),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w900,
//                     fontSize: 20,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Date: ${_formatDate(quote['quote_date'])}'),
//                 Text('Customer: ${_text(quote['customer_name'])}'),
//                 Text('Company: ${_text(quote['company_name'])}'),
//                 Text('TRN: ${_text(quote['customer_trn'])}'),
//                 Text('Phone: ${_text(quote['customer_phone'])}'),
//                 Text('Salesperson: ${_text(quote['salesperson_name'])}'),
//                 Text('Contact: ${_text(quote['salesperson_contact'])}'),
//                 if (_text(quote['notes']).isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Text('Notes: ${_text(quote['notes'])}'),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           ...List.generate(_items.length, (index) {
//             final item = _items[index];
//             final imagePath = _text(item['image_path']);
//
//             return Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF141414),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: const Color(0xFF3A2F0B)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (imagePath.isNotEmpty)
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.network(
//                         _imageUrlFromPath(imagePath),
//                         width: 72,
//                         height: 72,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) =>
//                         const SizedBox(
//                           width: 72,
//                           height: 72,
//                         ),
//                       ),
//                     ),
//                   if (imagePath.isNotEmpty) const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${index + 1}. ${_text(item['product_name'])}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         if (_text(item['item_code']).isNotEmpty)
//                           Text('Item No: ${_text(item['item_code'])}'),
//                         if (_text(item['description']).isNotEmpty)
//                           Text(_text(item['description'])),
//                         if (_text(item['length']).isNotEmpty)
//                           Text('Length: ${_text(item['length'])}'),
//                         if (_text(item['width']).isNotEmpty)
//                           Text('Width: ${_text(item['width'])}'),
//                         if (_text(item['production_time']).isNotEmpty)
//                           Text(
//                             'Production Time: ${_text(item['production_time'])}',
//                           ),
//                         const SizedBox(height: 6),
//                         Text(
//                           'Qty: ${_toInt(item['quantity'])} • Unit: ${_formatMoney(item['unit_price'])} • Total: ${_formatMoney(item['line_total'])}',
//                           style: const TextStyle(
//                             color: Color(0xFFD4AF37),
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: Column(
//               children: [
//                 _summaryRow('Subtotal', quote['subtotal']),
//                 _summaryRow('Delivery', quote['delivery_fee']),
//                 _summaryRow('Installation', quote['installation_fee']),
//                 _summaryRow(
//                   'Additional Details',
//                   quote['additional_details_fee'],
//                 ),
//                 _summaryRow('Taxable Total', quote['taxable_total']),
//                 _summaryRow(
//                   'VAT (${_formatMoney(quote['vat_percent'])}%)',
//                   quote['vat_amount'],
//                 ),
//                 _summaryRow(
//                   'Net Total',
//                   quote['net_total'],
//                   bold: true,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: FilledButton.icon(
//                   onPressed:
//                   _isExportingXlsx ? null : _handleExportXlsx,
//                   icon: const Icon(Icons.table_view_outlined),
//                   label: const Text('Export XLSX'),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: FilledButton.icon(
//                   onPressed:
//                   _isExportingPdf ? null : _handleExportPdf,
//                   icon: const Icon(Icons.picture_as_pdf_outlined),
//                   label: const Text('Export PDF'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryRow(String label, dynamic value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
//               ),
//             ),
//           ),
//           Text(
//             '${_formatMoney(value)} AED',
//             style: TextStyle(
//               fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
//               color: bold ? const Color(0xFFD4AF37) : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuotationDetailsScreen extends StatefulWidget {
  final dynamic quotationId;

  const QuotationDetailsScreen({
    super.key,
    required this.quotationId,
  });

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExportingXlsx = false;
  bool _isExportingPdf = false;
  String? _error;

  Map<String, dynamic>? _quotation;
  List<Map<String, dynamic>> _items = [];

  pw.Font? _pdfFont;
  pw.Font? _pdfFontBold;

  @override
  void initState() {
    super.initState();
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
          .select()
          .eq('id', widget.quotationId)
          .single();

      final itemsResponse = await _supabase
          .from('quotation_items')
          .select()
          .eq('quotation_id', widget.quotationId)
          .order('id', ascending: true);

      if (!mounted) return;

      setState(() {
        _quotation = Map<String, dynamic>.from(quotationResponse as Map);
        _items = (itemsResponse as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _ensurePdfFonts() async {
    if (_pdfFont != null && _pdfFontBold != null) return;

    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    _pdfFont = pw.Font.ttf(regular);
    _pdfFontBold = pw.Font.ttf(bold);
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

  Future<Uint8List?> _downloadImageBytes(String imagePath) async {
    try {
      return await _supabase.storage.from('product-images').download(imagePath);
    } catch (_) {
      return null;
    }
  }

  Future<String> _exportToTemplateXlsx() async {
    final quote = _quotation!;
    final templateData =
    await rootBundle.load('assets/templates/quotation_template.xlsx');

    final excel = Excel.decodeBytes(
      templateData.buffer.asUint8List(),
    );

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

  Future<String> _exportToPdf() async {
    final quote = _quotation!;

    await _ensurePdfFonts();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _pdfFont!,
        bold: _pdfFontBold!,
      ),
    );

    final List<List<String>> tableData = [
      [
        'S.No',
        'Item.No',
        'Description',
        'Length',
        'Width',
        'Production Time',
        'QTY',
        'Unit Price',
        'Total (AED)',
      ],
      ...List.generate(_items.length, (index) {
        final item = _items[index];
        return [
          '${index + 1}',
          _text(item['item_code']),
          _text(item['product_name']).isEmpty
              ? _text(item['description'])
              : _text(item['product_name']),
          _text(item['length']),
          _text(item['width']),
          _text(item['production_time']),
          '${_toInt(item['quantity'])}',
          _formatMoney(item['unit_price']),
          _formatMoney(item['line_total']),
        ];
      }),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal700, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'QUOTATION',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey600,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('To: ${_text(quote['customer_name'])}'),
                            pw.SizedBox(height: 4),
                            pw.Text('Company: ${_text(quote['company_name'])}'),
                            pw.SizedBox(height: 4),
                            pw.Text('TRN: ${_text(quote['customer_trn'])}'),
                            pw.SizedBox(height: 4),
                            pw.Text('Tel: ${_text(quote['customer_phone'])}'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey600,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Quotation Date: ${_formatDate(quote['quote_date'])}',
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Quotation Number: ${_text(quote['quote_no'])}',
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Salesperson: ${_text(quote['salesperson_name'])}',
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Contact: ${_text(quote['salesperson_contact'])}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: tableData.first,
                  data: tableData.sublist(1),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
                  cellStyle: const pw.TextStyle(
                    fontSize: 8,
                  ),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.all(4),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey500,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(26),
                    1: const pw.FixedColumnWidth(52),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FixedColumnWidth(42),
                    4: const pw.FixedColumnWidth(42),
                    5: const pw.FixedColumnWidth(62),
                    6: const pw.FixedColumnWidth(34),
                    7: const pw.FixedColumnWidth(56),
                    8: const pw.FixedColumnWidth(60),
                  },
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey600,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Terms & Conditions',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              _text(quote['notes']).isEmpty
                                  ? 'Thank you for your business.'
                                  : _text(quote['notes']),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey600,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            _pdfSummaryRow(
                              'Subtotal',
                              _formatMoney(quote['subtotal']),
                            ),
                            _pdfSummaryRow(
                              'Delivery',
                              _formatMoney(quote['delivery_fee']),
                            ),
                            _pdfSummaryRow(
                              'Installation Work',
                              _formatMoney(quote['installation_fee']),
                            ),
                            _pdfSummaryRow(
                              'Additional Details',
                              _formatMoney(quote['additional_details_fee']),
                            ),
                            _pdfSummaryRow(
                              'Total Taxable',
                              _formatMoney(quote['taxable_total']),
                            ),
                            _pdfSummaryRow(
                              'VAT (${_formatMoney(quote['vat_percent'])}%)',
                              _formatMoney(quote['vat_amount']),
                            ),
                            _pdfSummaryRow(
                              'Net Total',
                              _formatMoney(quote['net_total']),
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final quoteNo = _text(quote['quote_no']).replaceAll('/', '-');
    final filePath = '${dir.path}/$quoteNo.pdf';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save(), flush: true);

    return file.path;
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
    if (_quotation == null || _isExportingPdf) return;

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final path = await _exportToPdf();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $path')),
      );

      await OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      if (_quotation == null) return;
      final path = await _exportToPdf();
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share PDF failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Quotation Details'),
        backgroundColor: const Color(0xFF111111),
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
            icon: _isExportingPdf
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
              border: Border.all(color: const Color(0xFF3A2F0B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(quote['quote_no']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3A2F0B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrlFromPath(imagePath),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const SizedBox(
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                  if (imagePath.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${_text(item['product_name'])}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
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
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
              border: Border.all(color: const Color(0xFF3A2F0B)),
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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                  _isExportingXlsx ? null : _handleExportXlsx,
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('Export XLSX'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                  _isExportingPdf ? null : _handleExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            '${_formatMoney(value)} AED',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold ? const Color(0xFFD4AF37) : null,
            ),
          ),
        ],
      ),
    );
  }
}