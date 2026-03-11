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
      'Generate empty page structure di dalam feature.';

  @override
  String get invocation =>
      'magickit page <feature_name> <page_name> [--path-params x] [--query-params x,y]';

  PageCommand() {
    argParser
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

    final pathParams = _parseCommaList(argResults!['path-params'] as String?);
    final queryParams = _parseCommaList(argResults!['query-params'] as String?);

    final pascal = toPascalCase(page);
    final snake = toSnakeCase(pascal);

    final outputDir = 'lib/features/$feature';

    logger.info('');
    logger.info('Generating $pascal page in feature: $feature...');
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
      pathParams: pathParams,
      queryParams: queryParams,
    );

    for (final file in files) {
      logger.info('  + $file');
    }
    logger.info('');

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

}
