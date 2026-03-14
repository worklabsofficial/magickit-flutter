import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';
import '../utils/version_utils.dart';

class VersionCommand extends Command<void> {
  @override
  String get name => 'version';

  @override
  String get description => 'Tampilkan versi MagicKit CLI dan UI Kit.';

  VersionCommand() {
    argParser.addFlag(
      'update',
      abbr: 'u',
      help: 'Update magickit_cli ke versi terbaru dari pub.dev.',
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final cliVersion = VersionUtils.readCliVersion();
    final uiKitVersion = VersionUtils.readUiKitVersion();

    logger.info('');
    logger.info('  magickit_cli   v$cliVersion');
    logger.info('  magickit       v$uiKitVersion');
    logger.info('');
    if (argResults?['update'] as bool? ?? false) {
      await _updateToLatest();
    }
  }

  Future<void> _updateToLatest() async {
    final progress = logger.magicProgress('Update magickit_cli ke versi terbaru');
    try {
      final result = await Process.run(
        'dart',
        ['pub', 'global', 'activate', 'magickit_cli'],
      );
      if (result.exitCode == 0) {
        progress.complete('Selesai');
        logger.info('');
        logger.info('Update selesai. Jalankan ulang `magickit version`.');
      } else {
        progress.fail('Gagal update (exit code ${result.exitCode})');
        if ((result.stderr as String).trim().isNotEmpty) {
          logger.info((result.stderr as String).trim());
        }
      }
    } catch (e) {
      progress.fail('Gagal update: $e');
    }
  }
}
