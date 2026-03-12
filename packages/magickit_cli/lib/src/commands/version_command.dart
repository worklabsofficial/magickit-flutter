import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class VersionCommand extends Command<void> {
  static const cliVersion = '0.1.0';
  static const uiKitVersion = '0.1.0';

  @override
  String get name => 'version';

  @override
  String get description => 'Tampilkan versi MagicKit CLI dan UI Kit.';

  VersionCommand() {
    argParser.addFlag(
      'check',
      abbr: 'c',
      help: 'Cek versi terbaru di pub.dev.',
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    logger.info('');
    logger.info('  magickit_cli   v$cliVersion');
    logger.info('  magickit       v$uiKitVersion');
    logger.info('');
    logger.info('  Flutter  ${_flutterVersion()}');
    logger.info('  Dart     ${Platform.version.split(' ').first}');
    logger.info('');

    if (argResults?['check'] as bool? ?? false) {
      await _checkLatestVersion();
    }
  }

  String _flutterVersion() {
    try {
      final result = Process.runSync('flutter', ['--version', '--machine']);
      if (result.exitCode == 0) {
        final out = result.stdout as String;
        final match = RegExp(r'"frameworkVersion":"([^"]+)"').firstMatch(out);
        return match?.group(1) ?? 'unknown';
      }
    } catch (_) {}
    return 'unknown';
  }

  Future<void> _checkLatestVersion() async {
    final progress = logger.magicProgress('Memeriksa versi terbaru di pub.dev');
    try {
      await Process.run('dart', ['pub', 'global', 'list']);
      progress.complete('Selesai');

      // pub.dev check untuk magickit_cli
      logger.info('');
      logger.info('Jalankan untuk update:');
      logger.info(
        '  dart pub global activate --source path packages/magickit_cli',
      );
    } catch (e) {
      progress.fail('Gagal memeriksa: $e');
    }
  }
}
