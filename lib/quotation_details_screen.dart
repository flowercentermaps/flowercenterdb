// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:excel/excel.dart' hide Border;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:image_picker/image_picker.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'quotation_pdf_preview_screen.dart';
// import 'quotation_pdf_renderer.dart';
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
//   final ImagePicker _imagePicker = ImagePicker();
//
//   late final QuotationPdfRenderer _quotationPdfRenderer;
//
//   bool _isLoading = true;
//   bool _isExportingXlsx = false;
//   bool _isPreparingPdf = false;
//   String? _error;
//
//   Map<String, dynamic>? _quotation;
//   List<Map<String, dynamic>> _items = [];
//
//   final Map<dynamic, Uint8List> _temporaryItemImages = {};
//   final Map<dynamic, String> _temporaryItemImageNames = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _quotationPdfRenderer = QuotationPdfRenderer(
//       supabase: _supabase,
//     );
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
//           .select('''
//       *,
//       created_by_profile:profiles!quotations_created_by_fkey (
//         id,
//         full_name,
//         email,
//         phone
//       )
//     ''')
//           .eq('id', widget.quotationId)
//           .single();
//
//       final userPhone = quotationResponse['created_by_profile']?['phone'];
//       print(userPhone);
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
//         print(_quotation);
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
//   String _formatMoneyWithAed(dynamic value) {
//     return '${_formatMoney(value)} AED';
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
//   bool _canUseCamera() {
//     if (kIsWeb) return false;
//     return Platform.isAndroid || Platform.isIOS;
//   }
//
//   Future<void> _pickReplacementImage(
//       Map<String, dynamic> item, {
//         required ImageSource source,
//       }) async {
//     try {
//       final picked = await _imagePicker.pickImage(
//         source: source,
//         imageQuality: 90,
//       );
//
//       if (picked == null) return;
//
//       final bytes = await picked.readAsBytes();
//       final itemId = item['id'];
//
//       if (!mounted) return;
//
//       setState(() {
//         _temporaryItemImages[itemId] = bytes;
//         _temporaryItemImageNames[itemId] = picked.name;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Temporary image applied to this quote item.'),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image pick failed: $e')),
//       );
//     }
//   }
//
//   void _removeReplacementImage(Map<String, dynamic> item) {
//     final itemId = item['id'];
//
//     setState(() {
//       _temporaryItemImages.remove(itemId);
//       _temporaryItemImageNames.remove(itemId);
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Temporary image removed.')),
//     );
//   }
//
//   Future<void> _showImageSourceSheet(Map<String, dynamic> item) async {
//     await showModalBottomSheet<void>(
//       context: context,
//       backgroundColor: const Color(0xFF161616),
//       builder: (context) {
//         final itemId = item['id'];
//         final hasReplacement = _temporaryItemImages.containsKey(itemId);
//
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.photo_library_outlined),
//                   title: const Text('Choose from gallery'),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _pickReplacementImage(
//                       item,
//                       source: ImageSource.gallery,
//                     );
//                   },
//                 ),
//                 if (_canUseCamera())
//                   ListTile(
//                     leading: const Icon(Icons.photo_camera_outlined),
//                     title: const Text('Take photo'),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _pickReplacementImage(
//                         item,
//                         source: ImageSource.camera,
//                       );
//                     },
//                   ),
//                 if (hasReplacement)
//                   ListTile(
//                     leading: const Icon(Icons.restore_outlined),
//                     title: const Text('Use original image'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _removeReplacementImage(item);
//                     },
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildItemPreviewImage(Map<String, dynamic> item, String imagePath) {
//     final itemId = item['id'];
//     final tempBytes = _temporaryItemImages[itemId];
//
//     Widget child;
//
//     if (tempBytes != null) {
//       child = Image.memory(
//         tempBytes,
//         width: 72,
//         height: 72,
//         fit: BoxFit.cover,
//       );
//     } else if (imagePath.isNotEmpty) {
//       child = Image.network(
//         _imageUrlFromPath(imagePath),
//         width: 72,
//         height: 72,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => Container(
//           width: 72,
//           height: 72,
//           color: const Color(0xFF222222),
//           alignment: Alignment.center,
//           child: const Icon(Icons.broken_image_outlined),
//         ),
//       );
//     } else {
//       child = Container(
//         width: 72,
//         height: 72,
//         color: const Color(0xFF222222),
//         alignment: Alignment.center,
//         child: const Icon(Icons.image_not_supported_outlined),
//       );
//     }
//
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: Stack(
//         children: [
//           child,
//           if (tempBytes != null)
//             Positioned(
//               right: 4,
//               top: 4,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 6,
//                   vertical: 2,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'TEMP',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<String> _exportToTemplateXlsx() async {
//     final quote = _quotation!;
//     final templateData =
//     await rootBundle.load('assets/templates/quotation_template.xlsx');
//
//     final excel = Excel.decodeBytes(templateData.buffer.asUint8List());
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
//       setText(
//         'E$row',
//         _text(item['product_name']).isEmpty
//             ? _text(item['description'])
//             : _text(item['product_name']),
//       );
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
//   Future<Uint8List> _buildQuotationPdfBytes([PdfPageFormat? format]) async {
//     if (_quotation == null) {
//       throw Exception('Quotation not loaded.');
//     }
//
//     return _quotationPdfRenderer.build(
//       quotation: _quotation!,
//       items: _items,
//       temporaryItemImages: _temporaryItemImages,
//       pageFormat: format ?? PdfPageFormat.a4,
//     );
//   }
//
//   Future<String> _savePdfToFile() async {
//     if (_quotation == null) {
//       throw Exception('Quotation not loaded.');
//     }
//
//     final bytes = await _buildQuotationPdfBytes(PdfPageFormat.a4);
//     final dir = await getApplicationDocumentsDirectory();
//     final quoteNo = _text(_quotation!['quote_no']).replaceAll('/', '-').trim();
//     final path = '${dir.path}/$quoteNo.pdf';
//
//     final file = File(path);
//     await file.writeAsBytes(bytes, flush: true);
//     return path;
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
//     if (_quotation == null || _isPreparingPdf) return;
//
//     setState(() {
//       _isPreparingPdf = true;
//     });
//
//     try {
//       final quoteNo = _text(_quotation!['quote_no']).isEmpty
//           ? 'quotation'
//           : _text(_quotation!['quote_no']);
//
//       if (!mounted) return;
//
//       await Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => QuotationPdfPreviewScreen(
//             quoteNo: quoteNo,
//             buildPdf: (format) => _buildQuotationPdfBytes(format),
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF preview failed: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isPreparingPdf = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _sharePdf() async {
//     try {
//       if (_quotation == null) return;
//       final path = await _savePdfToFile();
//       await Share.shareXFiles([XFile(path)]);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Share PDF failed: $e')),
//       );
//     }
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
//             icon: _isPreparingPdf
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
//                 Text(
//                   'Salesperson: ${_text(quote['salesperson_name'])}',
//                 ),
//                 Text(
//                   'Contact: ${_text(quote['salesperson_contact'])}',
//                 ),
//                 Text(
//                   'sales phone: ${_text(quote['salesperson_contact'])}',
//                 ),
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
//             final hasTempImage =
//             _temporaryItemImages.containsKey(item['id']);
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
//                   _buildItemPreviewImage(item, imagePath),
//                   const SizedBox(width: 12),
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
//                             color: AppConstants.primaryColor,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             OutlinedButton.icon(
//                               onPressed: () =>
//                                   _showImageSourceSheet(item),
//                               icon: const Icon(
//                                 Icons.image_outlined,
//                                 size: 18,
//                               ),
//                               label: Text(
//                                 hasTempImage
//                                     ? 'Replace temp image'
//                                     : 'Set temp image',
//                               ),
//                             ),
//                             if (hasTempImage)
//                               OutlinedButton.icon(
//                                 onPressed: () =>
//                                     _removeReplacementImage(item),
//                                 icon: const Icon(
//                                   Icons.restore_outlined,
//                                   size: 18,
//                                 ),
//                                 label: const Text('Use original'),
//                               ),
//                           ],
//                         ),
//                         if (hasTempImage) ...[
//                           const SizedBox(height: 6),
//                           Text(
//                             'PDF override: ${_temporaryItemImageNames[item['id']] ?? 'selected image'}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: AppConstants.primaryColor,
//                             ),
//                           ),
//                         ],
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
//           Expanded(
//             child: FilledButton.icon(
//               onPressed:
//               _isPreparingPdf ? null : _handleExportPdf,
//               icon: const Icon(Icons.picture_as_pdf_outlined),
//               label: const Text('Preview PDF'),
//             ),
//           ),
//           // Row(
//           //   children: [
//           //     Expanded(
//           //       child: FilledButton.icon(
//           //         onPressed:
//           //         _isExportingXlsx ? null : _handleExportXlsx,
//           //         icon: const Icon(Icons.table_view_outlined),
//           //         label: const Text('Export XLSX'),
//           //       ),
//           //     ),
//           //     const SizedBox(width: 12),
//           //     Expanded(
//           //       child: FilledButton.icon(
//           //         onPressed:
//           //         _isPreparingPdf ? null : _handleExportPdf,
//           //         icon: const Icon(Icons.picture_as_pdf_outlined),
//           //         label: const Text('Preview PDF'),
//           //       ),
//           //     ),
//           //   ],
//           // ),
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
//             _formatMoneyWithAed(value),
//             style: TextStyle(
//               fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
//               color: bold ? const AppConstants.primaryColor : null,
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
import 'quotation_pdf_preview_screen.dart';
import 'quotation_pdf_renderer.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  late final QuotationPdfRenderer _quotationPdfRenderer;

  bool _isLoading = true;
  bool _isExportingXlsx = false;
  bool _isPreparingPdf = false;
  String? _error;

  Map<String, dynamic>? _quotation;
  List<Map<String, dynamic>> _items = [];

  final Map<dynamic, Uint8List> _temporaryItemImages = {};
  final Map<dynamic, String> _temporaryItemImageNames = {};

  @override
  void initState() {
    super.initState();
    _quotationPdfRenderer = QuotationPdfRenderer(
      supabase: _supabase,
    );
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
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final itemId = item['id'];

      if (!mounted) return;

      setState(() {
        _temporaryItemImages[itemId] = bytes;
        _temporaryItemImageNames[itemId] = picked.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temporary image applied to this quote item.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image pick failed: $e')),
      );
    }
  }

  void _removeReplacementImage(Map<String, dynamic> item) {
    final itemId = item['id'];

    setState(() {
      _temporaryItemImages.remove(itemId);
      _temporaryItemImageNames.remove(itemId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Temporary image removed.')),
    );
  }

  Future<void> _showImageSourceSheet(Map<String, dynamic> item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      builder: (context) {
        final itemId = item['id'];
        final hasReplacement = _temporaryItemImages.containsKey(itemId);

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
                    onTap: () {
                      Navigator.pop(context);
                      _removeReplacementImage(item);
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
    final tempBytes = _temporaryItemImages[itemId];

    Widget child;

    if (tempBytes != null) {
      child = Image.memory(
        tempBytes,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      );
    } else if (imagePath.isNotEmpty) {
      child = Image.network(
        _imageUrlFromPath(imagePath),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: const Color(0xFF222222),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      child = Container(
        width: 72,
        height: 72,
        color: const Color(0xFF222222),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          child,
          if (tempBytes != null)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TEMP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
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

    return _quotationPdfRenderer.build(
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
                Text(
                  'Sales phone: ${_text(quote['salesperson_phone']).isNotEmpty ? _text(quote['salesperson_phone']) : _text(quote['creator_phone'])}',
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
            _temporaryItemImages.containsKey(item['id']);

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
                  _buildItemPreviewImage(item, imagePath),
                  const SizedBox(width: 12),
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
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showImageSourceSheet(item),
                              icon: const Icon(
                                Icons.image_outlined,
                                size: 18,
                              ),
                              label: Text(
                                hasTempImage
                                    ? 'Replace temp image'
                                    : 'Set temp image',
                              ),
                            ),
                            if (hasTempImage)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _removeReplacementImage(item),
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
                            'PDF override: ${_temporaryItemImageNames[item['id']] ?? 'selected image'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryColor,
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
          FilledButton.icon(
            onPressed: _isPreparingPdf ? null : _handleExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview PDF'),
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
            _formatMoneyWithAed(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold ?  AppConstants.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}