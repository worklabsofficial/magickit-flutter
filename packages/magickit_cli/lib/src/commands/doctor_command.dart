import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class DoctorCommand extends Command<void> {
  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Periksa environment, dependencies, dan konfigurasi MagicKit.';

  @override
  Future<void> run() async {
    logger.info('');
    logger.info('MagicKit Doctor');
    logger.info('━' * 40);

    var allGood = true;

    // 1. Check Flutter
    allGood &= await _checkFlutter();

    // 2. Check Dart
    allGood &= await _checkDart();

    // 3. Check magickit dependency
    allGood &= _checkMagickitDependency();

    // 4. Check magickit.yaml
    allGood &= _checkMagickitConfig();

    logger.info('');
    if (allGood) {
      logger.success('Semua checks passed! MagicKit siap digunakan.');
    } else {
      logger.err('Beberapa issues ditemukan. Perbaiki masalah di atas.');
      exit(1);
    }
    logger.info('');
  }

  Future<bool> _checkFlutter() async {
    final progress = logger.magicProgress('Checking Flutter');
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final versionLine = (result.stdout as String)
            .split('\n')
            .firstWhere((l) => l.startsWith('Flutter'), orElse: () => '');
        progress.complete(_pass('Flutter — ${versionLine.trim()}'));
        return true;
      } else {
        progress.fail(_fail('Flutter tidak ditemukan'));
        logger.detail('  Install Flutter: https://flutter.dev/docs/get-started/install');
        return false;
      }
    } catch (_) {
      progress.fail(_fail('Flutter tidak ditemukan di PATH'));
      return false;
    }
  }

  Future<bool> _checkDart() async {
    final progress = logger.magicProgress('Checking Dart');
    try {
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode == 0) {
        final version = (result.stdout as String).trim().isNotEmpty
            ? (result.stdout as String).trim()
            : (result.stderr as String).trim();
        progress.complete(_pass('Dart — $version'));
        return true;
      } else {
        progress.fail(_fail('Dart tidak ditemukan'));
        return false;
      }
    } catch (_) {
      progress.fail(_fail('Dart tidak ditemukan di PATH'));
      return false;
    }
  }

  bool _checkMagickitDependency() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      logger.warn(_warn('pubspec.yaml tidak ditemukan di direktori ini'));
      logger.detail('  Pastikan kamu menjalankan magickit di root project Flutter.');
      return true; // tidak fatal di luar project
    }

    final content = pubspecFile.readAsStringSync();
    if (content.contains('magickit:')) {
      logger.success(_pass('magickit ditemukan di pubspec.yaml'));
      return true;
    } else {
      logger.warn(_warn('magickit belum ditambahkan ke pubspec.yaml'));
      logger.detail('  Tambahkan ke dependencies:');
      logger.detail('    dependencies:');
      logger.detail('      magickit: ^0.1.0');
      return false;
    }
  }

  bool _checkMagickitConfig() {
    final configFile = File('magickit.yaml');
    if (configFile.existsSync()) {
      logger.success(_pass('magickit.yaml ditemukan'));
      return true;
    } else {
      logger.warn(_warn('magickit.yaml tidak ditemukan'));
      logger.detail('  Jalankan: magickit init');
      return false;
    }
  }

  String _pass(String msg) => '[✓] $msg';
  String _fail(String msg) => '[✗] $msg';
  String _warn(String msg) => '[!] $msg';
}
