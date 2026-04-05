// // import 'dart:io';
// // import 'package:path/path.dart' as p;
// //
// // class ProcessorRunResult {
// //   final int exitCode;
// //   final String stdoutText;
// //   final String stderrText;
// //
// //   const ProcessorRunResult({
// //     required this.exitCode,
// //     required this.stdoutText,
// //     required this.stderrText,
// //   });
// //
// //   bool get isSuccess => exitCode == 0;
// // }
// //
// // class ContainerProcessorService {
// //   static Future<String> resolveProcessorPath() async {
// //     final exeDir = File(Platform.resolvedExecutable).parent.path;
// //     final candidate = p.join(exeDir, 'tools', 'container_processor.exe');
// //
// //     if (await File(candidate).exists()) {
// //       return candidate;
// //     }
// //
// //     throw Exception('Processor executable not found: $candidate');
// //   }
// //
// //   static Future<ProcessorRunResult> run({
// //     required String masterPath,
// //     required String priceListPath,
// //     required List<String> containerPaths,
// //     required String outputPath,
// //     String sheetName = 'Container Prices',
// //   }) async {
// //     if (!Platform.isWindows) {
// //       throw Exception('This processor currently supports Windows desktop only.');
// //     }
// //
// //     final processorPath = await resolveProcessorPath();
// //
// //     final args = <String>[
// //       '--master', masterPath,
// //       '--price-list', priceListPath,
// //       '--containers',
// //       ...containerPaths,
// //       '--output', outputPath,
// //       '--sheet-name', sheetName,
// //     ];
// //
// //     final result = await Process.run(
// //       processorPath,
// //       args,
// //       runInShell: false,
// //     );
// //
// //     return ProcessorRunResult(
// //       exitCode: result.exitCode,
// //       stdoutText: (result.stdout ?? '').toString(),
// //       stderrText: (result.stderr ?? '').toString(),
// //     );
// //   }
// // }
//
//
// import 'dart:io';
// import 'package:path/path.dart' as p;
//
// class ProcessorRunResult {
//   final int exitCode;
//   final String stdoutText;
//   final String stderrText;
//
//   const ProcessorRunResult({
//     required this.exitCode,
//     required this.stdoutText,
//     required this.stderrText,
//   });
//
//   bool get isSuccess => exitCode == 0;
// }
//
// enum ProcessorMode {
//   container,
//   master,
//   reprice,
// }
//
// class ContainerProcessorService {
//   static Future<String> resolveProcessorPath() async {
//     final exeDir = File(Platform.resolvedExecutable).parent.path;
//     final candidate = p.join(exeDir, 'tools', 'container_processor.exe');
//
//     if (await File(candidate).exists()) {
//       return candidate;
//     }
//
//     throw Exception('Processor executable not found: $candidate');
//   }
//
//   static String _modeValue(ProcessorMode mode) {
//     switch (mode) {
//       case ProcessorMode.container:
//         return 'container';
//       case ProcessorMode.master:
//         return 'master';
//       case ProcessorMode.reprice:
//         return 'reprice';
//     }
//   }
//
//   static Future<ProcessorRunResult> run({
//     required ProcessorMode mode,
//     String? masterPath,
//     required String priceListPath,
//     List<String> containerPaths = const [],
//     String? existingOutputPath,
//     required String outputPath,
//     String sheetName = '',
//     bool containerOnly = false,
//     bool refreshNames = false,
//   }) async {
//     if (!Platform.isWindows) {
//       throw Exception('This processor currently supports Windows desktop only.');
//     }
//
//     final processorPath = await resolveProcessorPath();
//
//     final args = <String>[
//       '--mode',
//       _modeValue(mode),
//       '--price-list',
//       priceListPath,
//       '--output',
//       outputPath,
//     ];
//
//     if (sheetName.trim().isNotEmpty) {
//       args.addAll(['--sheet-name', sheetName.trim()]);
//     }
//
//     if (masterPath != null && masterPath.trim().isNotEmpty) {
//       args.addAll(['--master', masterPath]);
//     }
//
//     switch (mode) {
//       case ProcessorMode.container:
//         if (containerPaths.isEmpty) {
//           throw Exception('Container mode requires at least one container file.');
//         }
//         args.add('--containers');
//         args.addAll(containerPaths);
//         if (containerOnly) {
//           args.add('--container-only');
//         }
//         break;
//
//       case ProcessorMode.master:
//         if (masterPath == null || masterPath.trim().isEmpty) {
//           throw Exception('Master mode requires a master workbook.');
//         }
//         break;
//
//       case ProcessorMode.reprice:
//         if (existingOutputPath == null || existingOutputPath.trim().isEmpty) {
//           throw Exception('Reprice mode requires an existing output workbook.');
//         }
//         args.addAll(['--existing-output', existingOutputPath]);
//         if (refreshNames) {
//           args.add('--refresh-names');
//         }
//         break;
//     }
//
//     final result = await Process.run(
//       processorPath,
//       args,
//       runInShell: false,
//     );
//
//     return ProcessorRunResult(
//       exitCode: result.exitCode,
//       stdoutText: (result.stdout ?? '').toString(),
//       stderrText: (result.stderr ?? '').toString(),
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ProcessorRunResult {
  final int exitCode;
  final String stdoutText;
  final String stderrText;

  const ProcessorRunResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  bool get isSuccess => exitCode == 0;
}

enum ProcessorMode {
  container,
  master,
  reprice,
}

typedef ProcessorLogCallback = void Function(String line);

class ContainerProcessorService {
  static Future<String> resolveProcessorPath() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidate = p.join(exeDir, 'tools', 'container_processor.exe');

    if (await File(candidate).exists()) {
      return candidate;
    }

    throw Exception('Processor executable not found: $candidate');
  }

  static String _modeValue(ProcessorMode mode) {
    switch (mode) {
      case ProcessorMode.container:
        return 'container';
      case ProcessorMode.master:
        return 'master';
      case ProcessorMode.reprice:
        return 'reprice';
    }
  }

  static Future<ProcessorRunResult> run({
    required ProcessorMode mode,
    String? masterPath,
    required String priceListPath,
    List<String> containerPaths = const [],
    String? existingOutputPath,
    required String outputPath,
    bool containerOnly = false,
    bool refreshNames = false,
    ProcessorLogCallback? onStdoutLine,
    ProcessorLogCallback? onStderrLine,
  }) async {
    if (!Platform.isWindows) {
      throw Exception('This processor currently supports Windows desktop only.');
    }

    final processorPath = await resolveProcessorPath();

    final safeOutputPath = outputPath.toLowerCase().endsWith('.xlsx')
        ? outputPath
        : '$outputPath.xlsx';

    final args = <String>[
      '--mode',
      _modeValue(mode),
      '--price-list',
      priceListPath,
      '--output',
      safeOutputPath,
    ];

    if (masterPath != null && masterPath.trim().isNotEmpty) {
      args.addAll(['--master', masterPath]);
    }

    switch (mode) {
      case ProcessorMode.container:
        if (containerPaths.isEmpty) {
          throw Exception('Container mode requires at least one container file.');
        }
        args.add('--containers');
        args.addAll(containerPaths);
        if (containerOnly) {
          args.add('--container-only');
        }
        break;

      case ProcessorMode.master:
        if (masterPath == null || masterPath.trim().isEmpty) {
          throw Exception('Master mode requires a master workbook.');
        }
        break;

      case ProcessorMode.reprice:
        if (existingOutputPath == null || existingOutputPath.trim().isEmpty) {
          throw Exception('Reprice mode requires an existing output workbook.');
        }
        args.addAll(['--existing-output', existingOutputPath]);
        if (refreshNames) {
          args.add('--refresh-names');
        }
        break;
    }

    final process = await Process.start(
      processorPath,
      args,
      runInShell: false,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
        stdoutBuffer.writeln(line);
        onStdoutLine?.call(line);
      },
      onDone: () => stdoutCompleter.complete(),
      onError: (error, stackTrace) {
        stdoutBuffer.writeln('STDOUT stream error: $error');
        onStderrLine?.call('STDOUT stream error: $error');
        if (!stdoutCompleter.isCompleted) stdoutCompleter.complete();
      },
      cancelOnError: false,
    );

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
        stderrBuffer.writeln(line);
        onStderrLine?.call(line);
      },
      onDone: () => stderrCompleter.complete(),
      onError: (error, stackTrace) {
        stderrBuffer.writeln('STDERR stream error: $error');
        onStderrLine?.call('STDERR stream error: $error');
        if (!stderrCompleter.isCompleted) stderrCompleter.complete();
      },
      cancelOnError: false,
    );

    final exitCode = await process.exitCode;
    await Future.wait([
      stdoutCompleter.future,
      stderrCompleter.future,
    ]);

    return ProcessorRunResult(
      exitCode: exitCode,
      stdoutText: stdoutBuffer.toString(),
      stderrText: stderrBuffer.toString(),
    );
  }
}