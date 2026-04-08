import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'core/constants/app_constants.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
    formats: const [BarcodeFormat.all],
  );

  bool _isHandled = false;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isHandled) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _isHandled = true;
        Navigator.of(context).pop(rawValue.trim());
        return;
      }
    }
  }

  Future<void> _pickBarcodeFromImage() async {
    if (_isPickingImage || _isHandled) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        if (mounted) {
          setState(() {
            _isPickingImage = false;
          });
        }
        return;
      }

      final BarcodeCapture? capture = await _controller.analyzeImage(file.path);

      if (!mounted) return;

      String? code;
      final barcodes = capture?.barcodes ?? const <Barcode>[];

      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue != null && rawValue.trim().isNotEmpty) {
          code = rawValue.trim();
          break;
        }
      }

      if (code == null) {
        setState(() {
          _isPickingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('No barcode found in the selected image.'.tr()),
          ),
        );
        return;
      }

      _isHandled = true;
      Navigator.of(context).pop(code);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPickingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read image: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:  Text('Scan Barcode'.tr()),
        actions: [
          IconButton(
            tooltip: 'Pick image'.tr(),
            onPressed: _pickBarcodeFromImage,
            icon: _isPickingImage
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeCapture,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color:  AppConstants.primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Point the camera at the barcode or choose an image from the top right.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}