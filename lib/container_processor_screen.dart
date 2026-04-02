import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'services/container_processor_service.dart';

class ContainerProcessorScreen extends StatefulWidget {
  const ContainerProcessorScreen({super.key});

  @override
  State<ContainerProcessorScreen> createState() => _ContainerProcessorScreenState();
}

class _ContainerProcessorScreenState extends State<ContainerProcessorScreen> {
  String? _masterPath;
  String? _priceListPath;
  List<String> _containerPaths = [];
  String? _outputPath;

  bool _isRunning = false;
  String _log = 'Ready.';

  Future<void> _pickMaster() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _masterPath = result.files.single.path!);
    }
  }

  Future<void> _pickPriceList() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _priceListPath = result.files.single.path!);
    }
  }

  Future<void> _pickContainers() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      setState(() {
        _containerPaths = result.paths.whereType<String>().toList();
      });
    }
  }

  Future<void> _pickOutput() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save output workbook',
      fileName: 'combined_container_prices.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (path != null) {
      setState(() => _outputPath = path);
    }
  }

  Future<void> _runProcessor() async {
    if (_masterPath == null ||
        _priceListPath == null ||
        _containerPaths.isEmpty ||
        _outputPath == null) {
      setState(() {
        _log = 'Please choose master, price list, container files, and output path.';
      });
      return;
    }

    setState(() {
      _isRunning = true;
      _log = 'Running processor...';
    });

    try {
      final result = await ContainerProcessorService.run(
        masterPath: _masterPath!,
        priceListPath: _priceListPath!,
        containerPaths: _containerPaths,
        outputPath: _outputPath!,
      );

      setState(() {
        _log = '''
Exit code: ${result.exitCode}

STDOUT:
${result.stdoutText}

STDERR:
${result.stderrText}
''';
      });

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workbook created: $_outputPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processor failed. Check the log.')),
        );
      }
    } catch (e) {
      setState(() {
        _log = 'Error:\n$e';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Widget _pathTile(String title, String? path) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(path ?? 'Not selected'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return Scaffold(
        appBar: AppBar(title: const Text('Container Processor')),
        body: const Center(
          child: Text('This tool is available only on Windows desktop.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Container Processor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _pathTile('Master workbook', _masterPath),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _pickMaster,
                child: const Text('Choose Master'),
              ),
            ),
            const SizedBox(height: 8),

            _pathTile('Price list workbook', _priceListPath),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _pickPriceList,
                child: const Text('Choose Price List'),
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: ListTile(
                title: const Text('Container workbooks'),
                subtitle: Text(
                  _containerPaths.isEmpty ? 'Not selected' : _containerPaths.join('\n'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _pickContainers,
                child: const Text('Choose Containers'),
              ),
            ),
            const SizedBox(height: 8),

            _pathTile('Output workbook', _outputPath),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _pickOutput,
                child: const Text('Choose Output'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRunning ? null : _runProcessor,
                icon: _isRunning
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_isRunning ? 'Running...' : 'Generate Workbook'),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: SelectableText(_log),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}