import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../generators/page_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class PageCommand extends Command<void> {
  @override
  String get name => 'page';

  @override
  String get description =>
      'Generate page dengan clean architecture boilerplate.';

  @override
  String get invocation => 'magickit page <name>';

  PageCommand() {
    argParser
      ..addOption(
        'architecture',
        abbr: 'a',
        help: 'Arsitektur yang digunakan.',
        allowed: ['clean', 'mvvm'],
        defaultsTo: 'clean',
      )
      ..addOption(
        'state',
        abbr: 's',
        help: 'State management yang digunakan.',
        allowed: ['bloc', 'cubit', 'riverpod'],
        defaultsTo: 'bloc',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory untuk fitur.',
        defaultsTo: null,
      );
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      usageException(
        'Feature name wajib diisi.\nContoh: magickit page login',
      );
    }

    final name = argResults!.rest.first;
    final config = _readConfig();
    final arch = argResults!['architecture'] as String? ??
        config['architecture'] as String? ??
        'clean';
    final state = argResults!['state'] as String? ??
        config['state_management'] as String? ??
        'bloc';
    final outputDir = argResults!['output'] as String? ??
        config['output'] as String? ??
        'lib/features';

    logger.info('');
    logger.info('Generating ${toPascalCase(name)} feature...');
    logger.info('Architecture : $arch');
    logger.info('State       : $state');
    logger.info('Output      : $outputDir');
    logger.info('');

    final generator = PageGenerator();
    final progress = logger.progress('Generating files');

    final files = await generator.generate(
      name: name,
      outputDir: outputDir,
      stateManagement: state,
    );

    progress.complete('Generated ${files.length} files');

    logger.info('');
    for (final file in files) {
      logger.success('  + $file');
    }
    logger.info('');
    logger.success('Feature "${toPascalCase(name)}" berhasil di-generate!');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final page = yaml?['magickit']?['page'];
      if (page is YamlMap) return page.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }
}
