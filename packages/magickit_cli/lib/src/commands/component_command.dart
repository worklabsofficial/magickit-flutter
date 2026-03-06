import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/component_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class ComponentCommand extends Command<void> {
  @override
  String get name => 'component';

  @override
  String get description =>
      'Scaffold widget baru mengikuti MagicKit convention.';

  @override
  String get invocation => 'magickit component <name> --type <atom|molecule|organism>';

  ComponentCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Tipe komponen.',
        allowed: ['atom', 'molecule', 'organism'],
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Base output direktori.',
        defaultsTo: 'lib/src',
      )
      ..addOption(
        'package',
        abbr: 'p',
        help: 'Nama package yang di-import (untuk ThemeExtension).',
        defaultsTo: 'magickit',
      );
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      usageException(
        'Nama komponen wajib diisi.\nContoh: magickit component rating_star --type atom',
      );
    }

    final name = argResults!.rest.first;
    final type = argResults!['type'] as String;
    final baseOutput = argResults!['output'] as String;
    final packageName = argResults!['package'] as String;

    final generator = ComponentGenerator();
    final pascal = toPascalCase(name);
    final snake = toSnakeCase(pascal);
    final className = 'Magic$pascal';
    final outputDir = generator.outputDir(type, baseOutput);
    final outputPath = '$outputDir/magic_$snake.dart';

    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      logger.err('File $outputPath sudah ada.');
      logger.info('Gunakan nama lain atau hapus file yang ada terlebih dahulu.');
      exit(1);
    }

    final code = generator.generate(
      name: name,
      type: type,
      packageName: packageName,
    );

    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(code);

    logger.info('');
    logger.success('$className scaffold berhasil dibuat!');
    logger.info('');
    logger.info('File   : $outputPath');
    logger.info('Class  : $className');
    logger.info('Type   : $type');
    logger.info('');
    logger.info('Langkah selanjutnya:');
    logger.info('  1. Buka $outputPath');
    logger.info('  2. Tambahkan properties dan implementasi widget');
    logger.info('  3. Export dari barrel file');
    logger.info('  4. Jalankan `magickit registry` untuk update registry');
  }
}
