import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../generators/api_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class ApiCommand extends Command<void> {
  @override
  String get name => 'api';

  @override
  String get description =>
      'Generate full-stack feature code from remote/ folder structure.\n\n'
      'Usage:\n'
      '  magickit api                       # generate all features\n'
      '  magickit api <feature>             # generate all pages in a feature\n'
      '  magickit api <feature> <page>      # generate a specific page\n\n'
      'The remote/ folder must contain page definition JSON files.\n'
      'Run `magickit init` first to set up the project structure.';

  ApiCommand() {
    argParser
      ..addFlag(
        'force',
        help: 'Overwrite existing generated files.',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Print what would be generated without writing files.',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Print resolution details (\$ref, type inference, etc.).',
        defaultsTo: false,
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final force = argResults?['force'] as bool? ?? false;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final verbose = argResults?['verbose'] as bool? ?? false;
    final rest = argResults?.rest ?? [];

    // ------------------------------------------------------------------
    // 1. Check magickit init prerequisite
    // ------------------------------------------------------------------
    _validatePrerequisites();
    final appName = _readAppName();
    _warnMissingDeps();

    // ------------------------------------------------------------------
    // 2. Resolve remote/ directory
    // ------------------------------------------------------------------
    const remoteDir = 'remote';
    if (!Directory(remoteDir).existsSync()) {
      logger.err(
        'Folder "remote/" tidak ditemukan di direktori saat ini.\n'
        'Buat folder tersebut dengan struktur:\n'
        '  remote/\n'
        '    shared/\n'
        '      <service>.json\n'
        '    <feature>/\n'
        '      <page>_page.json\n'
        '\n'
        'Base URL bisa diambil dari magickit.yaml (api.base_urls) '
        'atau remote/shared/base_urls.json.',
      );
      exit(1);
    }

    // ------------------------------------------------------------------
    // 3. Find page JSON files to process
    // ------------------------------------------------------------------
    final pageFiles = _findPageFiles(remoteDir, rest);

    if (pageFiles.isEmpty) {
      logger.warn('Tidak ada page definition file (.json) ditemukan.');
      if (rest.isNotEmpty) {
        logger.info('Filter: ${rest.join(' / ')}');
      }
      return;
    }

    logger.info('Ditemukan ${pageFiles.length} page definition file(s).');
    if (verbose) {
      for (final f in pageFiles) {
        logger.info('  • $f');
      }
    }

    // ------------------------------------------------------------------
    // 4. Generate base_urls.dart if config exists
    // ------------------------------------------------------------------
    final generator = ApiGenerator(appName: appName);
    final baseUrlsFile = File('$remoteDir/shared/base_urls.json');
    final baseUrlsFromConfig = _readBaseUrlsFromConfig();

    if (baseUrlsFile.existsSync()) {
      final progress =
          logger.magicProgress('Generating lib/core/network/base_urls.dart');
      try {
        final path = generator.generateBaseUrls(
          remoteDir,
          force: force,
          dryRun: dryRun,
        );
        if (dryRun) {
          progress.complete('[dry-run] Would generate: $path');
        } else {
          progress.complete('Generated: $path');
        }
      } catch (e) {
        progress.fail('Gagal generate base_urls.dart: $e');
      }
    } else if (baseUrlsFromConfig != null && baseUrlsFromConfig.isNotEmpty) {
      final progress =
          logger.magicProgress('Generating lib/core/network/base_urls.dart');
      try {
        final path = generator.generateBaseUrlsFromConfig(
          baseUrlsFromConfig,
          force: force,
          dryRun: dryRun,
        );
        if (dryRun) {
          progress.complete('[dry-run] Would generate: $path');
        } else {
          progress.complete('Generated: $path');
        }
      } catch (e) {
        progress.fail('Gagal generate base_urls.dart: $e');
      }
    } else {
      logger.warn(
        'base_urls tidak ditemukan. Tambahkan di magickit.yaml (api.base_urls) '
        'atau buat remote/shared/base_urls.json.',
      );
    }

    // ------------------------------------------------------------------
    // 5. Process each page file
    // ------------------------------------------------------------------
    var totalGenerated = 0;
    var totalFailed = 0;
    final pagesByFeature = <String, List<PageDef>>{};

    for (final pageFilePath in pageFiles) {
      final shortPath = pageFilePath.replaceFirst('$remoteDir/', '');
      final progress = logger.magicProgress('Processing $shortPath');

      try {
        final pageDef = generator.parsePageDef(pageFilePath, remoteDir);
        pagesByFeature.putIfAbsent(pageDef.feature, () => []).add(pageDef);

        if (verbose) {
          progress.complete('Parsed ${pageDef.page} (${pageDef.endpoints.length} endpoints)');
          for (final ep in pageDef.endpoints) {
            logger.info(
                '    • ${ep.method} ${ep.path} → ${toPascalCase(ep.name)}');
          }
        }

        final generated = generator.generateForPage(
          pageDef,
          remoteDir,
          force: force,
          dryRun: dryRun,
          verbose: verbose,
        );
        _deleteStaleGeneratedFiles(pageDef, generated, dryRun: dryRun);

        totalGenerated += generated.length;

        final label = dryRun ? '[dry-run] Would generate' : 'Generated';
        progress.complete(
          '$label ${generated.length} file(s) for ${pageDef.feature}/${pageDef.page}',
        );

        if (verbose && !dryRun) {
          for (final f in generated) {
            logger.info('    ✓ $f');
          }
        }
      } catch (e) {
        progress.fail('Gagal memproses $shortPath: $e');
        totalFailed++;
      }
    }

    // ------------------------------------------------------------------
    // 5.5 Generate feature injector + update global injector
    // ------------------------------------------------------------------
    for (final entry in pagesByFeature.entries) {
      final feature = entry.key;
      final pages = entry.value;
      final featureSnake = toSnakeCase(feature);
      final injectorPath = 'lib/features/$feature/${featureSnake}_injector.dart';
      final injectorProgress =
          logger.magicProgress('Generating ${featureSnake}_injector.dart');

      try {
        final code = generator.generateFeatureInjector(feature, pages);
        if (dryRun) {
          injectorProgress.complete('[dry-run] Would generate: $injectorPath');
        } else {
          File(injectorPath).parent.createSync(recursive: true);
          File(injectorPath).writeAsStringSync(code);
          injectorProgress.complete('Generated: $injectorPath');
        }
        totalGenerated += 1;
      } catch (e) {
        injectorProgress.fail('Gagal generate injector: $e');
        totalFailed++;
      }

      if (!dryRun) {
        _updateGlobalInjector(appName, feature, featureSnake);
      }
    }

    // ------------------------------------------------------------------
    // 6. Summary
    // ------------------------------------------------------------------
    logger.info('');
    if (dryRun) {
      logger.info(
          '[dry-run] Would generate files for ${pageFiles.length} page(s). No files written.');
    } else {
      logger.success(
        '$totalGenerated file(s) generated, '
        '$totalFailed failed.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: find page JSON files
  // ---------------------------------------------------------------------------

  List<String> _findPageFiles(String remoteDir, List<String> filter) {
    final remoteDirectory = Directory(remoteDir);
    final allFiles = remoteDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
          final path = f.path.replaceAll('\\', '/');
          // Exclude shared/ folder — those are service/base-url definitions
          if (path.contains('/$remoteDir/shared/') ||
              path.contains('$remoteDir/shared/')) {
            return false;
          }
          return f.path.endsWith('.json');
        })
        .map((f) => f.path)
        .toList()
      ..sort();

    if (filter.isEmpty) return allFiles;

    final featureFilter = filter.isNotEmpty ? filter[0] : null;
    final pageFilter = filter.length > 1 ? filter[1] : null;

    return allFiles.where((path) {
      // path: remote/<feature>/<page>.json
      final segments = path.replaceAll('\\', '/').split('/');
      // Find index of remoteDir
      final remoteIdx = segments.indexOf(remoteDir);
      if (remoteIdx < 0) return false;

      final featureSegment =
          remoteIdx + 1 < segments.length ? segments[remoteIdx + 1] : null;
      final fileSegment =
          remoteIdx + 2 < segments.length ? segments[remoteIdx + 2] : null;

      if (featureFilter != null && featureSegment != featureFilter) {
        return false;
      }

      if (pageFilter != null && fileSegment != null) {
        final pageFileName =
            fileSegment.replaceAll('.json', '').replaceAll('_page', '');
        if (pageFileName != pageFilter && fileSegment != '$pageFilter.json') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _deleteStaleGeneratedFiles(
    PageDef pageDef,
    List<String> generated, {
    required bool dryRun,
  }) {
    final pageSnake = toSnakeCase(pageDef.page);
    final featureBase = 'lib/features/${pageDef.feature}/$pageSnake';
    final dir = Directory(featureBase);
    if (!dir.existsSync()) return;

    final generatedSet = generated.toSet();
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (generatedSet.contains(path)) continue;

      final content = entity.readAsStringSync();
      final isGenerated = content.startsWith('// GENERATED CODE') ||
          content.startsWith('// GENERATED BY MAGICKIT CLI');

      if (!isGenerated) continue;

      if (dryRun) {
        logger.info('[dry-run] Would delete: $path');
      } else {
        entity.deleteSync();
        logger.info('Deleted: $path');
      }
    }
  }

  void _validatePrerequisites() {
    final requiredFiles = <String>[
      'lib/core/base/either.dart',
      'lib/core/base/failure.dart',
      'lib/core/base/server_exception.dart',
      'lib/core/network/token_manager.dart',
      'lib/core/dependency_injection/injector.dart',
    ];

    for (final path in requiredFiles) {
      if (!File(path).existsSync()) {
        logger.err(
          '$path tidak ditemukan.\n'
          'Jalankan `magickit init` terlebih dahulu untuk setup project structure.',
        );
        exit(1);
      }
    }

    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    final injectorContent = injectorFile.readAsStringSync();
    if (!injectorContent.contains('// MAGICKIT:INJECTOR') ||
        !injectorContent.contains('// MAGICKIT:IMPORT')) {
      logger.err(
        'lib/core/dependency_injection/injector.dart tidak memiliki marker MAGICKIT.\n'
        'Pastikan file berisi "// MAGICKIT:IMPORT" dan "// MAGICKIT:INJECTOR".',
      );
      exit(1);
    }
  }

  String _readAppName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      logger.err('pubspec.yaml tidak ditemukan.');
      exit(1);
    }
    try {
      final yaml = loadYaml(pubspec.readAsStringSync());
      final name = yaml is YamlMap ? yaml['name']?.toString() : null;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}
    logger.err('Gagal membaca nama app dari pubspec.yaml.');
    exit(1);
  }

  Map<String, dynamic>? _readBaseUrlsFromConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return null;
    try {
      final yaml = loadYaml(configFile.readAsStringSync());
      if (yaml is! YamlMap) return null;
      final magickit = yaml['magickit'];
      if (magickit is! YamlMap) return null;
      final api = magickit['api'];
      if (api is! YamlMap) return null;
      final baseUrls = api['base_urls'];
      if (baseUrls is! YamlMap) return null;
      return baseUrls.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  void _warnMissingDeps() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return;
    final content = pubspec.readAsStringSync();
    final existingDeps = <String>{};
    try {
      final yaml = loadYaml(content) as YamlMap?;
      final deps = yaml?['dependencies'];
      if (deps is YamlMap) {
        existingDeps.addAll(deps.keys.map((k) => k.toString()));
      }
    } catch (_) {}

    final missing = <String>[];
    for (final dep in ['http', 'flutter_bloc', 'get_it']) {
      if (!existingDeps.contains(dep)) missing.add(dep);
    }

    for (final dep in missing) {
      logger.warn(
          "Package '$dep' tidak ditemukan di pubspec.yaml. Tambahkan dengan: flutter pub add $dep");
    }
  }

  void _updateGlobalInjector(
    String appName,
    String feature,
    String featureSnake,
  ) {
    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (!injectorFile.existsSync()) return;

    var content = injectorFile.readAsStringSync();
    final importLine =
        "import 'package:$appName/features/$feature/${featureSnake}_injector.dart';";
    final markerImport = '// MAGICKIT:IMPORT';
    final markerInjector = '// MAGICKIT:INJECTOR';
    final callLine = '${toCamelCase(feature)}Injector();';

    var modified = false;

    if (!content.contains(importLine)) {
      if (content.contains(markerImport)) {
        content = content.replaceFirst(
          markerImport,
          '$importLine\n$markerImport',
        );
        modified = true;
      }
    }

    if (!content.contains(callLine)) {
      if (content.contains(markerInjector)) {
        content = content.replaceFirst(
          markerInjector,
          '  $callLine\n  $markerInjector',
        );
        modified = true;
      }
    }

    if (modified) {
      injectorFile.writeAsStringSync(content);
      logger.info(
          'Updated injector.dart → register ${toCamelCase(feature)}Injector()');
    }
  }
}
