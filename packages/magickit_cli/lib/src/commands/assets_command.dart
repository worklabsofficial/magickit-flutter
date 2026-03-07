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
      'Scan folder assets/ dan generate Dart class MagicAssets dengan grouped references.';

  @override
  Future<void> run() async {
    final config = _readConfig();

    final inputDir = config['input'] as String? ?? 'assets/';
    final outputFile =
        config['output'] as String? ?? 'lib/core/assets/assets.gen.dart';

    final exclude = _parseStringList(config['exclude']);
    final groups = _parseGroups(config['group']);
    final stripPrefix =
        config.containsKey('strip_prefix')
            ? _parseStringList(config['strip_prefix'])
            : ['ic_', 'img_'];

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      logger.err('Folder "$inputDir" tidak ditemukan.');
      logger.info(
        'Jalankan `magickit init` untuk membuat struktur folder, atau buat folder tersebut secara manual.',
      );
      exit(1);
    }

    logger.info('');
    logger.info('🧙 MagicKit Assets Generator');
    logger.info('');
    logger.info('Scanning $inputDir...');

    // Collect first-level subfolders
    final subfolders =
        dir
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path.replaceAll(r'\', '/').split('/').last)
            .toList()
          ..sort();

    // Count files per subfolder
    final folderCounts = <String, int>{};
    final allFiles = <String>[];

    for (final folder in subfolders) {
      final subDir = Directory(
        '${inputDir.endsWith('/') ? inputDir : '$inputDir/'}$folder',
      );
      final files =
          subDir
              .listSync(recursive: true)
              .whereType<File>()
              .map((f) => f.path.replaceAll(r'\', '/'))
              .where((p) => !p.split('/').any((s) => s.startsWith('.')))
              .toList();

      folderCounts[folder] = files.length;

      if (!exclude.contains(folder)) {
        allFiles.addAll(files);
      }
    }

    // Also collect root-level files (directly in inputDir)
    final rootFiles =
        dir
            .listSync()
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/'))
            .where((p) => !p.split('/').any((s) => s.startsWith('.')))
            .toList();
    allFiles.addAll(rootFiles);
    allFiles.sort();

    // Print folder scan summary
    for (final folder in subfolders) {
      final count = folderCounts[folder] ?? 0;
      if (exclude.contains(folder)) {
        logger.info('  ⏭️  $folder/ → excluded');
      } else {
        logger.info('  ✅ $folder/ → $count file${count == 1 ? '' : 's'}');
      }
    }

    if (allFiles.isEmpty) {
      logger.err('Tidak ada file ditemukan di "$inputDir"');
      exit(1);
    }

    logger.info('');

    final generator = AssetGenerator();
    final code = generator.generate(
      inputDir: inputDir,
      allFiles: allFiles,
      exclude: exclude,
      groups: groups,
      stripPrefix: stripPrefix,
    );

    final output = File(outputFile);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(code);

    // Print generation summary
    logger.info('Generated: $outputFile');
    if (groups.isNotEmpty) {
      var total = 0;
      for (final groupEntry in groups.entries) {
        final folder = groupEntry.value.replaceAll('/', '');
        final count = folderCounts[folder] ?? 0;
        total += count;
        logger.info(
          '  → MagicAssets.${groupEntry.key.padRight(16)} ($count asset${count == 1 ? '' : 's'})',
        );
      }
      logger.info('  → Total: $total assets');
    } else {
      logger.info('  → Total: ${allFiles.length} assets');
    }
    logger.info('');
    logger.success('Done!');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final assets = yaml?['magickit']?['assets'];
      if (assets is YamlMap) return Map<String, dynamic>.from(assets);
    } catch (_) {}
    return {};
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) return value.map((e) => e.toString()).toList();
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, String> _parseGroups(dynamic value) {
    if (value == null) return {};
    if (value is YamlMap) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): entry.value.toString(),
      };
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): entry.value.toString(),
      };
    }
    return {};
  }
}
