import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/route_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class FeatureCommand extends Command<void> {
  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate feature route group (route_names, routes, route_extensions).';

  @override
  String get invocation => 'magickit feature <feature_name>';

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      usageException(
        'Feature name wajib diisi.\nContoh: magickit feature auth',
      );
    }

    final feature = argResults!.rest.first;
    final pascal = toPascalCase(feature);

    logger.info('');
    logger.info('Generating feature route group: $pascal...');
    logger.info('');

    final generator = RouteGenerator();

    // 1. Create feature route files
    final files = generator.generateFeatureRouteFiles(feature);
    for (final entry in files.entries) {
      final file = File(entry.key);
      if (file.existsSync()) {
        logger.warn('  ~ ${entry.key} (sudah ada, skipped)');
        continue;
      }
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
      logger.info('  + ${entry.key}');
    }

    logger.info('');

    // 2. Update core route files
    generator.updateCoreForFeature(feature);
    logger.info('  Updated route_config.dart → ...${feature}Routes');
    logger.info('  Updated route_names.dart → export $feature');
    logger.info('  Updated route_extensions.dart → export $feature');

    logger.info('');
    logger.success('Feature "$pascal" route group berhasil di-generate!');
  }
}
