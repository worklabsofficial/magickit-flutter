import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/page_generator.dart';
import '../generators/route_generator.dart';
import '../utils/di_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class PageCommand extends Command<void> {
  @override
  String get name => 'page';

  @override
  String get description =>
      'Generate empty page structure + routing di dalam feature.';

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

    final routeGenerator = RouteGenerator();
    _ensureFeatureRouting(feature, routeGenerator);

    logger.info('');
    logger.magicInfo('Generating page');
    logger.info('Feature : $feature');
    logger.info('Output  : $outputDir/$snake');
    if (pathParams.isNotEmpty) {
      logger.info('Path    : ${pathParams.join(', ')}');
    }
    if (queryParams.isNotEmpty) {
      logger.info('Query   : ${queryParams.join(', ')}');
    }
    logger.info('');

    final generator = PageGenerator();
    final files = await generator.generate(
      name: page,
      outputDir: outputDir,
      pathParams: pathParams,
      queryParams: queryParams,
    );

    logger.info('Created ${files.length} file(s).');

    // Auto-update route files
    routeGenerator.updateRouteFilesForPage(
      feature,
      page,
      pathParams,
      queryParams,
    );
    logger.info('Routes updated for feature: $feature');
    if (queryParams.isNotEmpty) {
      logger.info('Query keys updated: ${queryParams.join(', ')}');
    }
    logger.info('');

    _ensureDependencyInjection(feature, page);

    logger.success('Page "$pascal" berhasil di-generate!');
  }

  List<String> _parseCommaList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _ensureFeatureRouting(String feature, RouteGenerator generator) {
    final files = generator.generateFeatureRouteFiles(feature);
    final created = <String>[];

    for (final entry in files.entries) {
      final file = File(entry.key);
      if (file.existsSync()) continue;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
      created.add(entry.key);
    }

    logger.info('');
    logger.magicInfo('Ensuring routing for feature: $feature');
    if (created.isEmpty) {
      logger.info('  ~ Feature route files already exist');
    } else {
      logger.info('  + Created ${created.length} route file(s)');
    }

    generator.updateCoreForFeature(feature);
    logger.info('  + Core routes ensured');
    logger.info('');
  }

  void _ensureDependencyInjection(String feature, String page) {
    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (!injectorFile.existsSync()) {
      logger.warn(
        'injector.dart tidak ditemukan. Jalankan `magickit init` terlebih dahulu.',
      );
      return;
    }

    final injectorContent = injectorFile.readAsStringSync();
    if (!injectorContent.contains('// MAGICKIT:INJECTOR') ||
        !injectorContent.contains('// MAGICKIT:IMPORT')) {
      logger.warn(
        'injector.dart tidak memiliki marker MAGICKIT. Skip auto DI update.',
      );
      return;
    }

    final appName = DiUtils.readAppName();
    if (appName == null) {
      logger.warn('pubspec.yaml tidak ditemukan atau gagal dibaca.');
      return;
    }

    final featureUpdated =
        DiUtils.updateFeatureInjector(feature: feature, page: page);
    final globalUpdated =
        DiUtils.updateGlobalInjector(appName: appName, feature: feature);

    if (featureUpdated || globalUpdated) {
      logger.info('DI updated for feature: $feature');
    }
  }

}
