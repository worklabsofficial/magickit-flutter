import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/page_generator.dart';
import '../generators/route_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class PageCommand extends Command<void> {
  @override
  String get name => 'page';

  @override
  String get description =>
      'Generate page di dalam feature dengan MagicCubit architecture boilerplate.';

  @override
  String get invocation =>
      'magickit page <feature_name> <page_name> [--path-params x] [--query-params x,y]';

  PageCommand() {
    argParser
      ..addFlag(
        'with-bloc',
        help:
            'Tambah Bloc layer untuk complex case (event-driven, debounce, stream).',
        negatable: false,
      )
      ..addOption(
        'path-params',
        help: 'Path parameters (comma-separated). Contoh: --path-params id',
      )
      ..addOption(
        'query-params',
        help:
            'Query parameters (comma-separated). Contoh: --query-params sort,rating',
      );
  }

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      usageException(
        'Feature name dan page name wajib diisi.\n'
        'Contoh: magickit page auth login\n'
        '        magickit page product product_detail --path-params id',
      );
    }

    final feature = rest[0];
    final page = rest[1];
    final withBloc = argResults!['with-bloc'] as bool;

    final pathParams = _parseCommaList(argResults!['path-params'] as String?);
    final queryParams = _parseCommaList(argResults!['query-params'] as String?);

    final pascal = toPascalCase(page);
    final snake = toSnakeCase(pascal);

    final outputDir = 'lib/features/$feature';

    logger.info('');
    logger.info('Generating $pascal page in feature: $feature...');
    logger.info('Architecture : MagicCubit${withBloc ? ' + Bloc' : ''}');
    logger.info('Output       : $outputDir/$snake');
    if (pathParams.isNotEmpty) {
      logger.info('Path params  : ${pathParams.join(', ')}');
    }
    if (queryParams.isNotEmpty) {
      logger.info('Query params : ${queryParams.join(', ')}');
    }
    logger.info('');

    final generator = PageGenerator();
    final files = await generator.generate(
      name: page,
      outputDir: outputDir,
      withBloc: withBloc,
      pathParams: pathParams,
      queryParams: queryParams,
    );

    for (final file in files) {
      logger.info('  + $file');
    }
    logger.info('');

    // Auto-register ke injection.dart
    _updateInjection(pascal, snake, outputDir);

    // Auto-update route files
    final routeGenerator = RouteGenerator();
    routeGenerator.updateRouteFilesForPage(feature, page, pathParams, queryParams);
    logger.info('  Updated ${feature}_route_names.dart');
    logger.info('  Updated ${feature}_routes.dart');
    logger.info('  Updated ${feature}_route_extensions.dart');
    if (queryParams.isNotEmpty) {
      logger.info('  Updated route_query_keys.dart → ${queryParams.join(', ')}');
    }
    logger.info('');

    logger.success('Page "$pascal" berhasil di-generate!');
  }

  List<String> _parseCommaList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
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

    final featureRelPath =
        outputDir.startsWith('lib/') ? outputDir.substring(4) : outputDir;
    final importPath =
        '../../$featureRelPath/$snake/dependency_injection/${snake}_dependency_injection.dart';
    final importLine = "import '$importPath';";
    final registerLine = '  register$pascal(sl);';

    var modified = false;

    if (!content.contains('${snake}_dependency_injection')) {
      final lastImportEnd = content.lastIndexOf("';") + 2;
      if (lastImportEnd > 1) {
        content =
            '${content.substring(0, lastImportEnd)}\n$importLine${content.substring(lastImportEnd)}';
        modified = true;
      }
    }

    if (!content.contains('register$pascal(sl)')) {
      final initIdx = content.indexOf('void initDependencies()');
      if (initIdx != -1) {
        final openBrace = content.indexOf('{', initIdx);
        final closeBrace = content.indexOf('\n}', openBrace);
        content =
            '${content.substring(0, closeBrace)}\n$registerLine${content.substring(closeBrace)}';
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
  }
}
