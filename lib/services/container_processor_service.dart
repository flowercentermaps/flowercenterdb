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

class ContainerProcessorService {
  static Future<String> resolveProcessorPath() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidate = p.join(exeDir, 'tools', 'container_processor.exe');

    if (await File(candidate).exists()) {
      return candidate;
    }

    throw Exception('Processor executable not found: $candidate');
  }

  static Future<ProcessorRunResult> run({
    required String masterPath,
    required String priceListPath,
    required List<String> containerPaths,
    required String outputPath,
    String sheetName = 'Container Prices',
  }) async {
    if (!Platform.isWindows) {
      throw Exception('This processor currently supports Windows desktop only.');
    }

    final processorPath = await resolveProcessorPath();

    final args = <String>[
      '--master', masterPath,
      '--price-list', priceListPath,
      '--containers',
      ...containerPaths,
      '--output', outputPath,
      '--sheet-name', sheetName,
    ];

    final result = await Process.run(
      processorPath,
      args,
      runInShell: false,
    );

    return ProcessorRunResult(
      exitCode: result.exitCode,
      stdoutText: (result.stdout ?? '').toString(),
      stderrText: (result.stderr ?? '').toString(),
    );
  }
}