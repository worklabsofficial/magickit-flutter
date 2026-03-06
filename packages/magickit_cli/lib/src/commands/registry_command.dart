import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/registry_generator.dart';
import '../utils/logger.dart';

class RegistryCommand extends Command<void> {
  @override
  String get name => 'registry';

  @override
  String get description =>
      'Scan source code annotations dan generate component_registry.yaml + AI bundle.';

  RegistryCommand() {
    argParser
      ..addOption(
        'source',
        abbr: 's',
        help: 'Direktori source code yang di-scan.',
        defaultsTo: 'lib/',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory untuk registry files.',
        defaultsTo: 'lib/src/registry/',
      )
      ..addFlag(
        'ai-bundle',
        help: 'Generate ai_context_bundle.txt untuk magickit slicing.',
        defaultsTo: true,
      );
  }

  @override
  Future<void> run() async {
    final sourceDir = argResults?['source'] as String? ?? 'lib/';
    final outputDir = argResults?['output'] as String? ?? 'lib/src/registry/';
    final generateAiBundle = argResults?['ai-bundle'] as bool? ?? true;

    final dir = Directory(sourceDir);
    if (!dir.existsSync()) {
      logger.err('Source directory "$sourceDir" tidak ditemukan.');
      exit(1);
    }

    final progress = logger.progress('Scanning $sourceDir untuk @magickit annotations');

    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    final generator = RegistryGenerator();
    final allComponents = <ComponentInfo>[];

    for (final file in dartFiles) {
      try {
        final content = file.readAsStringSync();
        if (!content.contains('{@magickit}')) continue;

        final components = generator.parseSource(content);
        if (components.isNotEmpty) {
          allComponents.addAll(components);
          logger.detail(
            '  Found ${components.length} component(s) in ${file.path}',
          );
        }
      } catch (e) {
        logger.warn('Gagal parse ${file.path}: $e');
      }
    }

    if (allComponents.isEmpty) {
      progress.fail('Tidak ada @magickit annotations ditemukan di $sourceDir');
      logger.info(
        'Pastikan widget menggunakan annotation:\n'
        '/// {\\@magickit}\n'
        '/// name: MyWidget\n'
        '/// category: atom\n'
        '/// {\\@end}',
      );
      return;
    }

    progress.complete(
      'Ditemukan ${allComponents.length} komponen dari ${dartFiles.length} file',
    );

    // Write output files
    final outputDirectory = Directory(outputDir);
    outputDirectory.createSync(recursive: true);

    // Generate registry YAML
    final yamlContent = generator.generateYaml(allComponents);
    final yamlFile = File('${outputDir}component_registry.yaml');
    yamlFile.writeAsStringSync(yamlContent);
    logger.success('component_registry.yaml → $outputDir');

    // Generate AI bundle
    if (generateAiBundle) {
      final bundleContent = generator.generateAiBundle(allComponents);
      final bundleFile = File('${outputDir}ai_context_bundle.txt');
      bundleFile.writeAsStringSync(bundleContent);
      logger.success('ai_context_bundle.txt → $outputDir');
    }

    // Summary
    logger.info('');
    logger.info('Registry Summary:');
    final grouped = <String, int>{};
    for (final c in allComponents) {
      grouped[c.category] = (grouped[c.category] ?? 0) + 1;
    }
    for (final entry in grouped.entries) {
      logger.info('  ${entry.key}: ${entry.value} komponen');
    }
  }
}
