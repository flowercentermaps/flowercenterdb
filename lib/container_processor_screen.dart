// // import 'dart:io';
// //
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// //
// // import 'services/container_processor_service.dart';
// //
// // class ContainerProcessorScreen extends StatefulWidget {
// //   const ContainerProcessorScreen({super.key});
// //
// //   @override
// //   State<ContainerProcessorScreen> createState() => _ContainerProcessorScreenState();
// // }
// //
// // class _ContainerProcessorScreenState extends State<ContainerProcessorScreen> {
// //   String? _masterPath;
// //   String? _priceListPath;
// //   List<String> _containerPaths = [];
// //   String? _outputPath;
// //
// //   bool _isRunning = false;
// //   String _log = 'Ready.';
// //
// //   Future<void> _pickMaster() async {
// //     final result = await FilePicker.platform.pickFiles(
// //       type: FileType.custom,
// //       allowedExtensions: ['xlsx'],
// //     );
// //     if (result != null && result.files.single.path != null) {
// //       setState(() => _masterPath = result.files.single.path!);
// //     }
// //   }
// //
// //   Future<void> _pickPriceList() async {
// //     final result = await FilePicker.platform.pickFiles(
// //       type: FileType.custom,
// //       allowedExtensions: ['xlsx'],
// //     );
// //     if (result != null && result.files.single.path != null) {
// //       setState(() => _priceListPath = result.files.single.path!);
// //     }
// //   }
// //
// //   Future<void> _pickContainers() async {
// //     final result = await FilePicker.platform.pickFiles(
// //       allowMultiple: true,
// //       type: FileType.custom,
// //       allowedExtensions: ['xlsx'],
// //     );
// //     if (result != null) {
// //       setState(() {
// //         _containerPaths = result.paths.whereType<String>().toList();
// //       });
// //     }
// //   }
// //
// //   Future<void> _pickOutput() async {
// //     final path = await FilePicker.platform.saveFile(
// //       dialogTitle: 'Save output workbook',
// //       fileName: 'combined_container_prices.xlsx',
// //       type: FileType.custom,
// //       allowedExtensions: ['xlsx'],
// //     );
// //     if (path != null) {
// //       setState(() => _outputPath = path);
// //     }
// //   }
// //
// //   Future<void> _runProcessor() async {
// //     if (_masterPath == null ||
// //         _priceListPath == null ||
// //         _containerPaths.isEmpty ||
// //         _outputPath == null) {
// //       setState(() {
// //         _log = 'Please choose master, price list, container files, and output path.';
// //       });
// //       return;
// //     }
// //
// //     setState(() {
// //       _isRunning = true;
// //       _log = 'Running processor...';
// //     });
// //
// //     try {
// //       final result = await ContainerProcessorService.run(
// //         masterPath: _masterPath!,
// //         priceListPath: _priceListPath!,
// //         containerPaths: _containerPaths,
// //         outputPath: _outputPath!,
// //       );
// //
// //       setState(() {
// //         _log = '''
// // Exit code: ${result.exitCode}
// //
// // STDOUT:
// // ${result.stdoutText}
// //
// // STDERR:
// // ${result.stderrText}
// // ''';
// //       });
// //
// //       if (!mounted) return;
// //
// //       if (result.isSuccess) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Workbook created: $_outputPath')),
// //         );
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Processor failed. Check the log.')),
// //         );
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _log = 'Error:\n$e';
// //       });
// //
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           _isRunning = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   Widget _pathTile(String title, String? path) {
// //     return Card(
// //       child: ListTile(
// //         title: Text(title),
// //         subtitle: Text(path ?? 'Not selected'),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (!Platform.isWindows) {
// //       return Scaffold(
// //         appBar: AppBar(title: const Text('Container Processor')),
// //         body: const Center(
// //           child: Text('This tool is available only on Windows desktop.'),
// //         ),
// //       );
// //     }
// //
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Container Processor')),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           children: [
// //             _pathTile('Master workbook', _masterPath),
// //             Align(
// //               alignment: Alignment.centerLeft,
// //               child: ElevatedButton(
// //                 onPressed: _isRunning ? null : _pickMaster,
// //                 child: const Text('Choose Master'),
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //
// //             _pathTile('Price list workbook', _priceListPath),
// //             Align(
// //               alignment: Alignment.centerLeft,
// //               child: ElevatedButton(
// //                 onPressed: _isRunning ? null : _pickPriceList,
// //                 child: const Text('Choose Price List'),
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //
// //             Card(
// //               child: ListTile(
// //                 title: const Text('Container workbooks'),
// //                 subtitle: Text(
// //                   _containerPaths.isEmpty ? 'Not selected' : _containerPaths.join('\n'),
// //                 ),
// //               ),
// //             ),
// //             Align(
// //               alignment: Alignment.centerLeft,
// //               child: ElevatedButton(
// //                 onPressed: _isRunning ? null : _pickContainers,
// //                 child: const Text('Choose Containers'),
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //
// //             _pathTile('Output workbook', _outputPath),
// //             Align(
// //               alignment: Alignment.centerLeft,
// //               child: ElevatedButton(
// //                 onPressed: _isRunning ? null : _pickOutput,
// //                 child: const Text('Choose Output'),
// //               ),
// //             ),
// //
// //             const SizedBox(height: 16),
// //
// //             SizedBox(
// //               width: double.infinity,
// //               child: FilledButton.icon(
// //                 onPressed: _isRunning ? null : _runProcessor,
// //                 icon: _isRunning
// //                     ? const SizedBox(
// //                   width: 18,
// //                   height: 18,
// //                   child: CircularProgressIndicator(strokeWidth: 2),
// //                 )
// //                     : const Icon(Icons.play_arrow_rounded),
// //                 label: Text(_isRunning ? 'Running...' : 'Generate Workbook'),
// //               ),
// //             ),
// //
// //             const SizedBox(height: 16),
// //
// //             Expanded(
// //               child: Card(
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(12),
// //                   child: SingleChildScrollView(
// //                     child: SelectableText(_log),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'dart:io';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
//
// import 'services/container_processor_service.dart';
//
// enum ProcessorUiMode {
//   container,
//   master,
//   reprice,
// }
//
// class ContainerProcessorScreen extends StatefulWidget {
//   const ContainerProcessorScreen({super.key});
//
//   @override
//   State<ContainerProcessorScreen> createState() => _ContainerProcessorScreenState();
// }
//
// class _ContainerProcessorScreenState extends State<ContainerProcessorScreen> {
//   ProcessorUiMode _mode = ProcessorUiMode.container;
//
//   String? _masterPath;
//   String? _priceListPath;
//   List<String> _containerPaths = [];
//   String? _existingOutputPath;
//   String? _outputPath;
//
//   bool _containerOnly = false;
//   bool _refreshNames = false;
//
//   bool _isRunning = false;
//   String _log = 'Ready.';
//
//   String get _modeLabel {
//     switch (_mode) {
//       case ProcessorUiMode.container:
//         return 'New Containers';
//       case ProcessorUiMode.master:
//         return 'Build From Master';
//       case ProcessorUiMode.reprice:
//         return 'Reprice Existing Output';
//     }
//   }
//
//   Future<void> _pickMaster() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx'],
//     );
//     if (result != null && result.files.single.path != null) {
//       setState(() => _masterPath = result.files.single.path!);
//     }
//   }
//
//   Future<void> _pickPriceList() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx'],
//     );
//     if (result != null && result.files.single.path != null) {
//       setState(() => _priceListPath = result.files.single.path!);
//     }
//   }
//
//   Future<void> _pickContainers() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       type: FileType.custom,
//       allowedExtensions: ['xlsx'],
//     );
//     if (result != null) {
//       setState(() {
//         _containerPaths = result.paths.whereType<String>().toList();
//       });
//     }
//   }
//
//   Future<void> _pickExistingOutput() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx'],
//     );
//     if (result != null && result.files.single.path != null) {
//       setState(() => _existingOutputPath = result.files.single.path!);
//     }
//   }
//
//   Future<void> _pickOutput() async {
//     final defaultName = switch (_mode) {
//       ProcessorUiMode.container => 'combined_container_prices.xlsx',
//       ProcessorUiMode.master => 'master_priced_output.xlsx',
//       ProcessorUiMode.reprice => 'repriced_output.xlsx',
//     };
//
//     final path = await FilePicker.platform.saveFile(
//       dialogTitle: 'Save output workbook',
//       fileName: defaultName,
//       type: FileType.custom,
//       allowedExtensions: ['xlsx'],
//     );
//     if (path != null) {
//       setState(() => _outputPath = path);
//     }
//   }
//
//   bool _validateInputs() {
//     if (_priceListPath == null) {
//       _log = 'Please choose the price list workbook.';
//       return false;
//     }
//
//     switch (_mode) {
//       case ProcessorUiMode.container:
//         if (_masterPath == null || _containerPaths.isEmpty || _outputPath == null) {
//           _log = 'Please choose master, price list, container files, and output path.';
//           return false;
//         }
//         break;
//
//       case ProcessorUiMode.master:
//         if (_masterPath == null || _outputPath == null) {
//           _log = 'Please choose master, price list, and output path.';
//           return false;
//         }
//         break;
//
//       case ProcessorUiMode.reprice:
//         if (_existingOutputPath == null || _outputPath == null) {
//           _log = 'Please choose existing output, price list, and output path.';
//           return false;
//         }
//         break;
//     }
//
//     return true;
//   }
//
//   Future<void> _runProcessor() async {
//     if (!_validateInputs()) {
//       setState(() {});
//       return;
//     }
//
//     setState(() {
//       _isRunning = true;
//       _log = 'Running $_modeLabel processor...';
//     });
//
//     try {
//       final result = await ContainerProcessorService.run(
//         mode: switch (_mode) {
//           ProcessorUiMode.container => ProcessorMode.container,
//           ProcessorUiMode.master => ProcessorMode.master,
//           ProcessorUiMode.reprice => ProcessorMode.reprice,
//         },
//         masterPath: _masterPath,
//         priceListPath: _priceListPath!,
//         containerPaths: _containerPaths,
//         existingOutputPath: _existingOutputPath,
//         outputPath: _outputPath!,
//         containerOnly: _containerOnly,
//         refreshNames: _refreshNames,
//       );
//
//       setState(() {
//         _log = '''
// Mode: $_modeLabel
// Exit code: ${result.exitCode}
//
// STDOUT:
// ${result.stdoutText}
//
// STDERR:
// ${result.stderrText}
// ''';
//       });
//
//       if (!mounted) return;
//
//       if (result.isSuccess) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Workbook created: $_outputPath')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Processor failed. Check the log.')),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _log = 'Error:\n$e';
//       });
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRunning = false;
//         });
//       }
//     }
//   }
//
//   Widget _pathTile(String title, String? path) {
//     return Card(
//       child: ListTile(
//         title: Text(title),
//         subtitle: Text(path ?? 'Not selected'),
//       ),
//     );
//   }
//
//   Widget _sectionButton({
//     required String text,
//     required VoidCallback onPressed,
//   }) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: ElevatedButton(
//         onPressed: _isRunning ? null : onPressed,
//         child: Text(text),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!Platform.isWindows) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Container Processor')),
//         body: const Center(
//           child: Text('This tool is available only on Windows desktop.'),
//         ),
//       );
//     }
//
//     final isContainerMode = _mode == ProcessorUiMode.container;
//     final isMasterMode = _mode == ProcessorUiMode.master;
//     final isRepriceMode = _mode == ProcessorUiMode.reprice;
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Container Processor')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             DropdownButtonFormField<ProcessorUiMode>(
//               value: _mode,
//               decoration: const InputDecoration(
//                 labelText: 'Processing Mode',
//                 border: OutlineInputBorder(),
//               ),
//               items: const [
//                 DropdownMenuItem(
//                   value: ProcessorUiMode.container,
//                   child: Text('New Containers'),
//                 ),
//                 DropdownMenuItem(
//                   value: ProcessorUiMode.master,
//                   child: Text('Build From Master'),
//                 ),
//                 DropdownMenuItem(
//                   value: ProcessorUiMode.reprice,
//                   child: Text('Reprice Existing Output'),
//                 ),
//               ],
//               onChanged: _isRunning
//                   ? null
//                   : (value) {
//                 if (value == null) return;
//                 setState(() {
//                   _mode = value;
//                 });
//               },
//             ),
//
//             const SizedBox(height: 12),
//
//             if (isContainerMode || isMasterMode) ...[
//               _pathTile('Master workbook', _masterPath),
//               _sectionButton(
//                 text: 'Choose Master',
//                 onPressed: _pickMaster,
//               ),
//               const SizedBox(height: 8),
//             ],
//
//             _pathTile('Price list workbook', _priceListPath),
//             _sectionButton(
//               text: 'Choose Price List',
//               onPressed: _pickPriceList,
//             ),
//             const SizedBox(height: 8),
//
//             if (isContainerMode) ...[
//               Card(
//                 child: ListTile(
//                   title: const Text('Container workbooks'),
//                   subtitle: Text(
//                     _containerPaths.isEmpty ? 'Not selected' : _containerPaths.join('\n'),
//                   ),
//                 ),
//               ),
//               _sectionButton(
//                 text: 'Choose Containers',
//                 onPressed: _pickContainers,
//               ),
//               SwitchListTile(
//                 value: _containerOnly,
//                 onChanged: _isRunning
//                     ? null
//                     : (value) {
//                   setState(() => _containerOnly = value);
//                 },
//                 title: const Text('Only variants that appear in container sheets'),
//               ),
//               const SizedBox(height: 8),
//             ],
//
//             if (isRepriceMode) ...[
//               _pathTile('Existing output workbook', _existingOutputPath),
//               _sectionButton(
//                 text: 'Choose Existing Output',
//                 onPressed: _pickExistingOutput,
//               ),
//               SwitchListTile(
//                 value: _refreshNames,
//                 onChanged: _isRunning
//                     ? null
//                     : (value) {
//                   setState(() => _refreshNames = value);
//                 },
//                 title: const Text('Refresh Item No. names from price list/master'),
//               ),
//               const SizedBox(height: 8),
//             ],
//
//             _pathTile('Output workbook', _outputPath),
//             _sectionButton(
//               text: 'Choose Output',
//               onPressed: _pickOutput,
//             ),
//
//             const SizedBox(height: 16),
//
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton.icon(
//                 onPressed: _isRunning ? null : _runProcessor,
//                 icon: _isRunning
//                     ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : const Icon(Icons.play_arrow_rounded),
//                 label: Text(_isRunning ? 'Running...' : 'Generate Workbook'),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             Expanded(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: SingleChildScrollView(
//                     child: SelectableText(_log),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'services/container_processor_service.dart';

enum ProcessorUiMode {
  container,
  master,
  reprice,
}

class ContainerProcessorScreen extends StatefulWidget {
  const ContainerProcessorScreen({super.key});

  @override
  State<ContainerProcessorScreen> createState() => _ContainerProcessorScreenState();
}

class _ContainerProcessorScreenState extends State<ContainerProcessorScreen> {
  ProcessorUiMode _mode = ProcessorUiMode.container;

  String? _masterPath;
  String? _priceListPath;
  List<String> _containerPaths = [];
  String? _existingOutputPath;
  String? _outputPath;

  bool _containerOnly = false;
  bool _refreshNames = false;

  bool _isRunning = false;
  String _log = 'Ready.';

  String get _modeLabel {
    switch (_mode) {
      case ProcessorUiMode.container:
        return 'New Containers';
      case ProcessorUiMode.master:
        return 'Build From Master';
      case ProcessorUiMode.reprice:
        return 'Reprice Existing Output';
    }
  }

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

  Future<void> _pickExistingOutput() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _existingOutputPath = result.files.single.path!);
    }
  }

  Future<void> _pickOutput() async {
    final defaultName = switch (_mode) {
      ProcessorUiMode.container => 'combined_container_prices.xlsx',
      ProcessorUiMode.master => 'master_priced_output.xlsx',
      ProcessorUiMode.reprice => 'repriced_output.xlsx',
    };

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save output workbook',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path != null) {
      final normalized = path.toLowerCase().endsWith('.xlsx') ? path : '$path.xlsx';
      setState(() => _outputPath = normalized);
    }
  }

  bool _validateInputs() {
    if (_priceListPath == null) {
      _log = 'Please choose the price list workbook.';
      return false;
    }

    switch (_mode) {
      case ProcessorUiMode.container:
        if (_masterPath == null || _containerPaths.isEmpty || _outputPath == null) {
          _log = 'Please choose master, price list, container files, and output path.';
          return false;
        }
        break;

      case ProcessorUiMode.master:
        if (_masterPath == null || _outputPath == null) {
          _log = 'Please choose master, price list, and output path.';
          return false;
        }
        break;

      case ProcessorUiMode.reprice:
        if (_existingOutputPath == null || _outputPath == null) {
          _log = 'Please choose existing output, price list, and output path.';
          return false;
        }
        break;
    }

    return true;
  }

  Future<void> _runProcessor() async {
    if (!_validateInputs()) {
      setState(() {});
      return;
    }

    setState(() {
      _isRunning = true;
      _log = 'Running $_modeLabel processor...\n';
    });

    try {
      final result = await ContainerProcessorService.run(
        mode: switch (_mode) {
          ProcessorUiMode.container => ProcessorMode.container,
          ProcessorUiMode.master => ProcessorMode.master,
          ProcessorUiMode.reprice => ProcessorMode.reprice,
        },
        masterPath: _masterPath,
        priceListPath: _priceListPath!,
        containerPaths: _containerPaths,
        existingOutputPath: _existingOutputPath,
        outputPath: _outputPath!,
        containerOnly: _containerOnly,
        refreshNames: _refreshNames,
        onStdoutLine: (line) {
          if (!mounted) return;
          setState(() {
            _log += '$line\n';
          });
        },
        onStderrLine: (line) {
          if (!mounted) return;
          setState(() {
            _log += 'ERROR: $line\n';
          });
        },
      ).timeout(
        const Duration(minutes: 15),
        onTimeout: () {
          throw Exception('Processor timed out after 15 minutes.');
        },
      );

      if (!mounted) return;

      setState(() {
        _log += '\nFinished with exit code: ${result.exitCode}\n';
      });

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
      if (!mounted) return;

      setState(() {
        _log += '\nFatal error: $e\n';
      });

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

  Widget _sectionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: _isRunning ? null : onPressed,
        child: Text(text),
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

    final isContainerMode = _mode == ProcessorUiMode.container;
    final isMasterMode = _mode == ProcessorUiMode.master;
    final isRepriceMode = _mode == ProcessorUiMode.reprice;

    return Scaffold(
      appBar: AppBar(title: const Text('Container Processor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<ProcessorUiMode>(
              value: _mode,
              decoration: const InputDecoration(
                labelText: 'Processing Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProcessorUiMode.container,
                  child: Text('New Containers'),
                ),
                DropdownMenuItem(
                  value: ProcessorUiMode.master,
                  child: Text('Build From Master'),
                ),
                DropdownMenuItem(
                  value: ProcessorUiMode.reprice,
                  child: Text('Reprice Existing Output'),
                ),
              ],
              onChanged: _isRunning
                  ? null
                  : (value) {
                if (value == null) return;
                setState(() {
                  _mode = value;
                });
              },
            ),
            const SizedBox(height: 12),

            if (isContainerMode || isMasterMode) ...[
              _pathTile('Master workbook', _masterPath),
              _sectionButton(
                text: 'Choose Master',
                onPressed: _pickMaster,
              ),
              const SizedBox(height: 8),
            ],

            _pathTile('Price list workbook', _priceListPath),
            _sectionButton(
              text: 'Choose Price List',
              onPressed: _pickPriceList,
            ),
            const SizedBox(height: 8),

            if (isContainerMode) ...[
              Card(
                child: ListTile(
                  title: const Text('Container workbooks'),
                  subtitle: Text(
                    _containerPaths.isEmpty ? 'Not selected' : _containerPaths.join('\n'),
                  ),
                ),
              ),
              _sectionButton(
                text: 'Choose Containers',
                onPressed: _pickContainers,
              ),
              SwitchListTile(
                value: _containerOnly,
                onChanged: _isRunning
                    ? null
                    : (value) {
                  setState(() => _containerOnly = value);
                },
                title: const Text('Only variants that appear in container sheets'),
              ),
              const SizedBox(height: 8),
            ],

            if (isRepriceMode) ...[
              _pathTile('Existing output workbook', _existingOutputPath),
              _sectionButton(
                text: 'Choose Existing Output',
                onPressed: _pickExistingOutput,
              ),
              SwitchListTile(
                value: _refreshNames,
                onChanged: _isRunning
                    ? null
                    : (value) {
                  setState(() => _refreshNames = value);
                },
                title: const Text('Refresh Item No. names from price list/master'),
              ),
              const SizedBox(height: 8),
            ],

            _pathTile('Output workbook', _outputPath),
            _sectionButton(
              text: 'Choose Output',
              onPressed: _pickOutput,
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