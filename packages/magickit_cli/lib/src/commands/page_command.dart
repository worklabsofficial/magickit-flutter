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
      'Generate page dengan MagicCubit architecture boilerplate.';

  @override
  String get invocation => 'magickit page <name> [--with-bloc]';

  PageCommand() {
    argParser
      ..addFlag(
        'with-bloc',
        help:
            'Tambah Bloc layer untuk complex case (event-driven, debounce, stream).',
        negatable: false,
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
        'Feature name wajib diisi.\nContoh: magickit page login\n        magickit page order --with-bloc',
      );
    }

    final name = argResults!.rest.first;
    final config = _readConfig();
    final withBloc = argResults!['with-bloc'] as bool;
    final rawOutput = argResults!['output'] as String? ??
        config['output'] as String? ??
        'lib/features';
    final outputDir = rawOutput.endsWith('/')
        ? rawOutput.substring(0, rawOutput.length - 1)
        : rawOutput;

    final pascal = toPascalCase(name);
    final snake = toSnakeCase(pascal);

    logger.info('');
    logger.info('Generating $pascal feature...');
    logger.info('Architecture : MagicCubit${withBloc ? ' + Bloc' : ''}');
    logger.info('Output       : $outputDir/$snake');
    logger.info('');

    final generator = PageGenerator();
    final files = await generator.generate(
      name: name,
      outputDir: outputDir,
      withBloc: withBloc,
    );

    for (final file in files) {
      logger.info('  + $file');
    }
    logger.info('');

    // Auto-register ke injection.dart
    _updateInjection(pascal, snake, outputDir);

    logger.success('Feature "$pascal" berhasil di-generate!');
  }

  void _updateInjection(String pascal, String snake, String outputDir) {
    final injectionFile =
        File('lib/core/dependency_injection/injection.dart');
    if (!injectionFile.existsSync()) {
      logger.warn(
          'injection.dart tidak ditemukan. Register manual di lib/core/dependency_injection/injection.dart');
      return;
    }

    var content = injectionFile.readAsStringSync();

    // Relative import path dari injection.dart ke feature DI
    final featureRelPath =
        outputDir.startsWith('lib/') ? outputDir.substring(4) : outputDir;
    final importPath =
        '../../$featureRelPath/$snake/dependency_injection/${snake}_dependency_injection.dart';
    final importLine = "import '$importPath';";
    final registerLine = '  register$pascal(sl);';

    var modified = false;

    // Inject import jika belum ada
    if (!content.contains('${snake}_dependency_injection')) {
      final lastImportEnd = content.lastIndexOf("';") + 2;
      if (lastImportEnd > 1) {
        content = '${content.substring(0, lastImportEnd)}\n$importLine${content.substring(lastImportEnd)}';
        modified = true;
      }
    }

    // Inject register call jika belum ada
    if (!content.contains('register$pascal(sl)')) {
      // Cari closing } dari initDependencies()
      final initIdx = content.indexOf('void initDependencies()');
      if (initIdx != -1) {
        final openBrace = content.indexOf('{', initIdx);
        final closeBrace = content.indexOf('\n}', openBrace);
        content = '${content.substring(0, closeBrace)}\n$registerLine${content.substring(closeBrace)}';
        modified = true;
      }
    }

    if (modified) {
      injectionFile.writeAsStringSync(content);
      logger.info(
          '  Updated lib/core/dependency_injection/injection.dart → register$pascal(sl)');
    } else {
      logger.info('  injection.dart: $pascal sudah ter-register (skipped)');
    }
    logger.info('');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final page = yaml?['magickit']?['page'];
      if (page is YamlMap) return Map<String, dynamic>.from(page);
    } catch (_) {}
    return {};
  }
}
