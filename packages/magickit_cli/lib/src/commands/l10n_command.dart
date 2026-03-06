import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../generators/l10n_generator.dart';
import '../utils/logger.dart';

class L10nCommand extends Command<void> {
  @override
  String get name => 'l10n';

  @override
  String get description =>
      'Scan folder assets/lang/ dan generate localization classes.';

  @override
  Future<void> run() async {
    final config = _readConfig();
    final inputDir = config['input'] as String? ?? 'assets/lang/';
    final outputDir = config['output'] as String? ?? 'lib/generated/l10n/';
    final defaultLocale = config['default_locale'] as String? ?? 'id';

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      logger.err('Folder "$inputDir" tidak ditemukan.');
      logger.info('Buat folder dan tambahkan file JSON/ARB locale di dalamnya.');
      exit(1);
    }

    final progress = logger.progress('Scanning $inputDir');

    final localeFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') || f.path.endsWith('.arb'))
        .toList();

    if (localeFiles.isEmpty) {
      progress.fail('Tidak ada file JSON/ARB ditemukan di "$inputDir"');
      logger.info('Contoh: $inputDir/id.json, $inputDir/en.json');
      return;
    }

    progress.complete('Ditemukan ${localeFiles.length} locale file(s)');

    final generator = L10nGenerator();
    final allKeys = <String>{};
    final localeData = <String, Map<String, dynamic>>{};

    // Parse semua locale files
    for (final file in localeFiles) {
      final locale = _extractLocale(file.path);
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data;
        if (file.path.endsWith('.arb')) {
          // ARB files have metadata keys starting with @
          final raw = jsonDecode(content) as Map<String, dynamic>;
          data = Map.fromEntries(
            raw.entries.where((e) => !e.key.startsWith('@')),
          );
        } else {
          data = jsonDecode(content) as Map<String, dynamic>;
        }
        localeData[locale] = _flattenKeys(data);
        allKeys.addAll(localeData[locale]!.keys);
        logger.detail('  Parsed $locale: ${localeData[locale]!.length} keys');
      } catch (e) {
        logger.warn('Gagal parse ${file.path}: $e');
      }
    }

    if (allKeys.isEmpty) {
      logger.err('Tidak ada key yang ditemukan di file locale.');
      exit(1);
    }

    final outputDirectory = Directory(outputDir);
    outputDirectory.createSync(recursive: true);

    // Generate L10nKeys
    final keysCode = generator.generateKeys(allKeys);
    File('${outputDir}l10n_keys.dart').writeAsStringSync(keysCode);

    // Generate per-locale maps
    final supportedLocales = localeData.keys.toList();
    for (final entry in localeData.entries) {
      final mapCode = generator.generateLocaleMap(entry.key, entry.value);
      File('${outputDir}l10n_${entry.key.toLowerCase()}.dart')
          .writeAsStringSync(mapCode);
    }

    // Generate AppLocalizations
    final appLocCode = generator.generateAppLocalizations(
      defaultLocale,
      supportedLocales,
      allKeys,
    );
    File('${outputDir}app_localizations.dart').writeAsStringSync(appLocCode);

    logger.success(
      'Generated ${allKeys.length} keys, ${localeData.length} locale(s) → $outputDir',
    );
    logger.info('Files: l10n_keys.dart, app_localizations.dart, ${supportedLocales.map((l) => 'l10n_$l.dart').join(', ')}');
  }

  /// Flatten nested JSON ke dot-notation keys.
  /// {"app": {"title": "MagicKit"}} -> {"app.title": "MagicKit"}
  Map<String, dynamic> _flattenKeys(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map<String, dynamic>) {
        result.addAll(_flattenKeys(entry.value as Map<String, dynamic>, key));
      } else {
        result[key] = entry.value;
      }
    }
    return result;
  }

  String _extractLocale(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    return fileName.replaceAll(RegExp(r'\.(json|arb)$'), '');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final l10n = yaml?['magickit']?['l10n'];
      if (l10n is YamlMap) return l10n.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }
}
