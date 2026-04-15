import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class QuotationPdfPreviewScreen extends StatelessWidget {
  const QuotationPdfPreviewScreen({
    super.key,
    required this.quoteNo,
    required this.buildPdf,
    this.isHamasat = false,
  });

  final String quoteNo;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final bool isHamasat;

  static const Color _hamPrimary   = Color(0xFF9B77BA);
  static const Color _hamSecondary = Color(0xFFDED2E8);

  ThemeData _hamTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _hamPrimary,
        onPrimary: const Color(0xFF1A0A2E),
        onSurface: _hamSecondary,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: _hamPrimary,
      ),
      iconTheme: const IconThemeData(color: _hamPrimary),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: _hamPrimary),
    );
  }

  Future<String> _savePdf(BuildContext context) async {
    final bytes = await buildPdf(PdfPageFormat.a4);
    final dir = await getApplicationDocumentsDirectory();
    final safeName = quoteNo.replaceAll('/', '-').trim();
    final path = '${dir.path}/$safeName.pdf';

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title:  Text('Quotation Preview'.tr()),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: () async {
              try {
                final path = await _savePdf(context);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: $path')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Save failed: $e')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Open Saved File',
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () async {
              try {
                final path = await _savePdf(context);
                await OpenFilex.open(path);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Open failed: $e')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              try {
                final path = await _savePdf(context);
                await Share.shareXFiles([XFile(path)]);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share failed: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: buildPdf,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: false,
        pdfFileName: '${quoteNo.replaceAll('/', '-')}.pdf',
      ),
    );
    return isHamasat
        ? Theme(data: _hamTheme(context), child: scaffold)
        : scaffold;
  }
}