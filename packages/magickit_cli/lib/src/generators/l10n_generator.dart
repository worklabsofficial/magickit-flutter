import '../utils/string_utils.dart';

class L10nGenerator {
  /// Generate L10nKeys class dengan static const string keys.
  String generateKeys(Set<String> keys) {
    final sortedKeys = keys.toList()..sort();

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit l10n` to regenerate.')
      ..writeln()
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class L10nKeys {')
      ..writeln('  L10nKeys._();')
      ..writeln();

    for (final key in sortedKeys) {
      final varName = _keyToVarName(key);
      buffer.writeln("  static const String $varName = '$key';");
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Generate per-locale Map constant.
  String generateLocaleMap(String locale, Map<String, dynamic> translations) {
    final localePascal = toPascalCase(locale);

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit l10n` to regenerate.')
      ..writeln()
      ..writeln('// ignore_for_file: lines_longer_than_80_chars')
      ..writeln("// Locale: $locale")
      ..writeln(
        "const Map<String, String> l10n$localePascal = {",
      );

    for (final entry in translations.entries) {
      final escaped = entry.value.toString().replaceAll("'", r"\'");
      buffer.writeln("  '${entry.key}': '$escaped',");
    }

    buffer.writeln('};');
    return buffer.toString();
  }

  /// Generate main AppLocalizations class that delegates to locale maps.
  String generateAppLocalizations(
    String defaultLocale,
    List<String> supportedLocales,
    Set<String> keys,
  ) {
    final sortedKeys = keys.toList()..sort();

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit l10n` to regenerate.')
      ..writeln()
      ..writeln("import 'l10n_keys.dart';");

    for (final locale in supportedLocales) {
      buffer.writeln("import 'l10n_${locale.toLowerCase()}.dart';");
    }

    buffer
      ..writeln()
      ..writeln('class AppLocalizations {')
      ..writeln('  AppLocalizations(this.locale);')
      ..writeln()
      ..writeln('  final String locale;')
      ..writeln()
      ..writeln('  static final Map<String, Map<String, String>> _maps = {');

    for (final locale in supportedLocales) {
      buffer.writeln("    '$locale': l10n${toPascalCase(locale)},");
    }

    buffer
      ..writeln('  };')
      ..writeln()
      ..writeln('  Map<String, String> get _map =>');
      buffer.writeln("      _maps[locale] ?? _maps['$defaultLocale'] ?? {};");
    buffer
      ..writeln()
      ..writeln('  String translate(String key) => _map[key] ?? key;')
      ..writeln();

    for (final key in sortedKeys) {
      final varName = _keyToVarName(key);
      buffer.writeln(
        "  String get $varName => translate(L10nKeys.$varName);",
      );
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _keyToVarName(String key) {
    // e.g. "app.title" -> "appTitle", "login_button" -> "loginButton"
    final parts = key.split(RegExp(r'[._\-\s]+'));
    if (parts.isEmpty) return key;
    return parts.first.toLowerCase() + parts.skip(1).map(capitalize).join('');
  }
}
