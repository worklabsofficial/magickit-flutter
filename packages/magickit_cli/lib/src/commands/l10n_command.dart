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
      'Scan assets/l10n/ dan generate AppLocalizations class dengan grouped getters.';

  @override
  Future<void> run() async {
    final config = _readConfig();
    final inputDir = config['input'] as String? ?? 'assets/l10n/';
    final outputDir = config['output'] as String? ?? 'lib/core/l10n/';
    final defaultLocale = config['default_locale'] as String? ?? 'id';

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      logger.err('Folder "$inputDir" tidak ditemukan.');
      logger.info('Jalankan `magickit init` untuk membuat struktur folder.');
      exit(1);
    }

    logger.info('');
    logger.info('🧙 MagicKit L10n Generator');
    logger.info('');
    logger.info('Scanning $inputDir...');

    final localeFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) {
        final aLocale = _extractLocale(a.path);
        final bLocale = _extractLocale(b.path);
        if (aLocale == defaultLocale) return -1;
        if (bLocale == defaultLocale) return 1;
        return aLocale.compareTo(bLocale);
      });

    if (localeFiles.isEmpty) {
      logger.err('Tidak ada file JSON ditemukan di "$inputDir"');
      logger.info('Contoh: ${inputDir}id.json, ${inputDir}en.json');
      exit(1);
    }

    // Parse all locale files
    final localeGroups = <String, Map<String?, Map<String, String>>>{};

    for (final file in localeFiles) {
      final locale = _extractLocale(file.path);
      final isDefault = locale == defaultLocale;
      logger.info('  → $locale.json${isDefault ? ' (default locale)' : ''}');

      try {
        final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        localeGroups[locale] = _parseAndGroup(raw);
      } catch (e) {
        logger.warn('Gagal parse ${file.path}: $e');
      }
    }

    if (localeGroups.isEmpty) {
      logger.err('Tidak ada locale yang berhasil di-parse.');
      exit(1);
    }

    final defaultGroups =
        localeGroups[defaultLocale] ?? localeGroups.values.first;
    final defaultFlat = _flattenGroups(defaultGroups);

    logger.info('');
    logger.info('Keys found: ${defaultFlat.length}');
    logger.info('');

    // Validate missing/extra keys
    for (final entry in localeGroups.entries) {
      if (entry.key == defaultLocale) continue;
      final flat = _flattenGroups(entry.value);
      final missing =
          defaultFlat.keys.where((k) => !flat.containsKey(k)).toList();
      final extra =
          flat.keys.where((k) => !defaultFlat.containsKey(k)).toList();

      if (missing.isNotEmpty) {
        logger.warn('Missing keys in ${entry.key}.json:');
        for (final k in missing) {
          logger.info('  - $k');
        }
      }
      if (extra.isNotEmpty) {
        logger.warn('Extra keys in ${entry.key}.json:');
        for (final k in extra) {
          logger.info('  - $k');
        }
      }
    }

    // Prepare output directories
    Directory(outputDir).createSync(recursive: true);
    Directory('${outputDir}getters').createSync(recursive: true);

    final generator = L10nGenerator();
    final generated = <String>[];

    // 1. l10n_keys.dart
    _writeFile(
        '${outputDir}l10n_keys.dart', generator.generateKeys(defaultGroups));
    generated.add('  → ${outputDir}l10n_keys.dart');

    // 2. per-locale maps
    final resolvedLocales = localeGroups.keys.toList();
    for (final locale in resolvedLocales) {
      final flatMap =
          Map<String, String>.from(_flattenGroups(localeGroups[locale]!));
      // Fill missing keys with default locale values as fallback
      for (final key in defaultFlat.keys) {
        flatMap.putIfAbsent(key, () => defaultFlat[key]!);
      }
      _writeFile('${outputDir}l10n_$locale.dart',
          generator.generateLocaleMap(locale, flatMap));
      generated.add('  → ${outputDir}l10n_$locale.dart');
    }

    // 3. getters per group
    final getterGroups = <String>[];

    final generalEntries = defaultGroups[null];
    if (generalEntries != null && generalEntries.isNotEmpty) {
      _writeFile(
        '${outputDir}getters/general_getters.dart',
        generator.generateGetters('general', generalEntries),
      );
      generated.add('  → ${outputDir}getters/general_getters.dart');
      getterGroups.add('general');
    }

    for (final groupEntry in defaultGroups.entries) {
      if (groupEntry.key == null) continue;
      _writeFile(
        '${outputDir}getters/${groupEntry.key}_getters.dart',
        generator.generateGetters(groupEntry.key!, groupEntry.value),
      );
      generated.add('  → ${outputDir}getters/${groupEntry.key}_getters.dart');
      getterGroups.add(groupEntry.key!);
    }

    // 4. app_localizations.dart
    _writeFile(
      '${outputDir}app_localizations.dart',
      generator.generateAppLocalizations(
        defaultLocale: defaultLocale,
        supportedLocales: resolvedLocales,
        getterGroups: getterGroups,
      ),
    );
    generated.add('  → ${outputDir}app_localizations.dart');

    logger.info('Generated:');
    for (final f in generated) {
      logger.info(f);
    }
    logger.info('');

    // 5. Inject to main.dart
    _injectMainDart(defaultLocale, outputDir);

    logger.info('');
    logger.info('Usage: context.lang.appName');
    logger.info('');
    logger.success('Done!');
  }

  void _injectMainDart(String defaultLocale, String outputDir) {
    final mainFile = File('lib/main.dart');
    final relativeOutputDirForLog = outputDir.startsWith('lib/')
        ? outputDir.substring('lib/'.length)
        : outputDir;

    if (!mainFile.existsSync()) {
      logger.warn('lib/main.dart tidak ditemukan. Setup l10n secara manual:');
      logger.info(
        "  import 'package:flutter_localizations/flutter_localizations.dart';",
      );
      logger.info("  import '${relativeOutputDirForLog}app_localizations.dart';");
      logger.info('  // Tambahkan ke MaterialApp:');
      logger.info("  locale: const Locale('$defaultLocale'),");
      logger.info('  supportedLocales: AppLocalizations.supportedLocales,');
      logger.info(
        '  localizationsDelegates: [AppLocalizations.delegate, ...GlobalXxxLocalizations.delegate],',
      );
      return;
    }

    var content = mainFile.readAsStringSync();
    var modified = false;

    const localizationsImport =
        "import 'package:flutter_localizations/flutter_localizations.dart';";

    // Compute import path relative to lib/ (e.g. 'lib/core/l10n/' → 'core/l10n/')
    final relativeOutputDir = outputDir.startsWith('lib/')
        ? outputDir.substring('lib/'.length)
        : outputDir;
    final appLocImport =
        "import '${relativeOutputDir}app_localizations.dart';";

    // Inject flutter_localizations import
    if (!content.contains(localizationsImport)) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n$localizationsImport",
      );
      modified = true;
    }

    // Inject app_localizations import
    if (!content.contains('app_localizations.dart')) {
      content = content.replaceFirst(
        localizationsImport,
        "$localizationsImport\n$appLocImport",
      );
      modified = true;
    }

    // Inject MaterialApp l10n properties
    if (!content.contains('AppLocalizations.delegate')) {
      final insertion = "      locale: const Locale('$defaultLocale'),\n"
          '      supportedLocales: AppLocalizations.supportedLocales,\n'
          '      localizationsDelegates: const [\n'
          '        AppLocalizations.delegate,\n'
          '        GlobalMaterialLocalizations.delegate,\n'
          '        GlobalWidgetsLocalizations.delegate,\n'
          '        GlobalCupertinoLocalizations.delegate,\n'
          '      ],\n';

      final materialAppIdx = content.indexOf('MaterialApp(');
      if (materialAppIdx != -1) {
        final insertIdx = content.indexOf('\n', materialAppIdx) + 1;
        content = content.substring(0, insertIdx) +
            insertion +
            content.substring(insertIdx);
        modified = true;
      }
    }

    if (modified) {
      mainFile.writeAsStringSync(content);
      logger.info('Injected to main.dart:');
      logger.info("  → import '${relativeOutputDir}app_localizations.dart'");
      logger.info('  → AppLocalizations.delegate');
      logger.info('  → AppLocalizations.supportedLocales');
      logger.info("  → locale: Locale('$defaultLocale')");
    } else {
      logger.info('main.dart: sudah ter-setup (skipped)');
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Parse JSON dan group berdasarkan top-level structure.
  /// null key = top-level strings (general), named key = nested group.
  Map<String?, Map<String, String>> _parseAndGroup(Map<String, dynamic> json) {
    final result = <String?, Map<String, String>>{};
    for (final entry in json.entries) {
      if (entry.value is Map) {
        result[entry.key] = _flattenToMap(
          entry.value as Map<String, dynamic>,
          entry.key,
        );
      } else {
        (result[null] ??= {})[entry.key] = entry.value?.toString() ?? '';
      }
    }
    return result;
  }

  Map<String, String> _flattenToMap(Map<String, dynamic> map, String prefix) {
    final result = <String, String>{};
    for (final entry in map.entries) {
      final key = '${prefix}_${entry.key}';
      if (entry.value is Map) {
        result.addAll(_flattenToMap(entry.value as Map<String, dynamic>, key));
      } else {
        result[key] = entry.value?.toString() ?? '';
      }
    }
    return result;
  }

  Map<String, String> _flattenGroups(
    Map<String?, Map<String, String>> groups,
  ) {
    final result = <String, String>{};
    for (final g in groups.values) {
      result.addAll(g);
    }
    return result;
  }

  void _writeFile(String path, String content) {
    File(path).writeAsStringSync(content);
  }

  String _extractLocale(String filePath) {
    return filePath
        .replaceAll(r'\', '/')
        .split('/')
        .last
        .replaceAll('.json', '');
  }

  Map<String, dynamic> _readConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final l10n = yaml?['magickit']?['l10n'];
      if (l10n is YamlMap) return Map<String, dynamic>.from(l10n);
    } catch (_) {}
    return {};
  }
}
