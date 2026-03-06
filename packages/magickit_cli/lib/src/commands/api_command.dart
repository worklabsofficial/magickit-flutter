import 'dart:convert';
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
      'Scan JSON schema files di api_schemas/ dan generate Dart models.';

  ApiCommand() {
    argParser
      ..addOption(
        'input',
        abbr: 'i',
        help: 'Direktori input JSON schema files.',
        defaultsTo: null,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Direktori output model files.',
        defaultsTo: null,
      )
      ..addFlag(
        'repository',
        abbr: 'r',
        help: 'Generate repository stub untuk setiap model.',
        defaultsTo: false,
      );
  }

  @override
  Future<void> run() async {
    final config = _readConfig();
    final inputDir =
        argResults?['input'] as String? ?? config['input'] as String? ?? 'api_schemas/';
    final outputDir =
        argResults?['output'] as String? ?? config['output'] as String? ?? 'lib/data/models/';
    final generateRepo = argResults?['repository'] as bool? ??
        (config['generate_repository'] as bool? ?? false);

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      logger.err('Direktori "$inputDir" tidak ditemukan.');
      logger.info(
        'Buat folder tersebut dan tambahkan JSON schema files.\n'
        'Contoh: $inputDir/user.json',
      );
      exit(1);
    }

    final jsonFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    if (jsonFiles.isEmpty) {
      logger.err('Tidak ada file .json ditemukan di "$inputDir"');
      exit(1);
    }

    logger.info('Ditemukan ${jsonFiles.length} schema file(s)');

    final generator = ApiGenerator();
    final outputDirectory = Directory(outputDir);
    outputDirectory.createSync(recursive: true);

    var successCount = 0;

    for (final file in jsonFiles) {
      final modelName = file.uri.pathSegments.last.replaceAll('.json', '');
      final progress = logger.progress('Generating ${toPascalCase(modelName)}Model');

      try {
        final content = file.readAsStringSync();
        final json = jsonDecode(content);

        // Handle both object and array root
        final Map<String, dynamic> sample;
        if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
          sample = json.first as Map<String, dynamic>;
        } else if (json is Map<String, dynamic>) {
          sample = json;
        } else {
          progress.fail('Format JSON tidak valid untuk ${file.path}');
          continue;
        }

        final code = generator.generateModel(
          modelName,
          sample,
          generateRepository: generateRepo,
        );

        final outputFile = File('$outputDir${toSnakeCase(toPascalCase(modelName))}_model.dart');
        outputFile.writeAsStringSync(code);

        progress.complete(
          'Generated ${toPascalCase(modelName)}Model → ${outputFile.path}',
        );
        successCount++;
      } catch (e) {
        progress.fail('Gagal generate ${file.path}: $e');
      }
    }

    logger.info('');
    logger.success('$successCount/${jsonFiles.length} model(s) berhasil di-generate.');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final api = yaml?['magickit']?['api'];
      if (api is YamlMap) return api.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }
}
