import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../generators/asset_generator.dart';
import '../utils/logger.dart';

class AssetsCommand extends Command<void> {
  @override
  String get name => 'assets';

  @override
  String get description =>
      'Scan folder assets/ dan generate Dart class dengan static references.';

  @override
  Future<void> run() async {
    final config = _readConfig();
    final inputDir = config['input'] as String? ?? 'assets/';
    final outputFile =
        config['output'] as String? ?? 'lib/generated/assets.gen.dart';

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      logger.err('Folder "$inputDir" tidak ditemukan.');
      logger.info('Buat folder tersebut terlebih dahulu atau ubah config di magickit.yaml');
      exit(1);
    }

    final progress = logger.progress('Scanning $inputDir');

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .toList()
      ..sort();

    if (files.isEmpty) {
      progress.fail('Tidak ada file ditemukan di "$inputDir"');
      return;
    }

    progress.complete('Ditemukan ${files.length} file');

    final generator = AssetGenerator();
    final code = generator.generate(files, inputDir.replaceAll('/', ''));

    final output = File(outputFile);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(code);

    logger.success('Generated ${files.length} assets → $outputFile');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final assets = yaml?['magickit']?['assets'];
      if (assets is YamlMap) return assets.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }
}
