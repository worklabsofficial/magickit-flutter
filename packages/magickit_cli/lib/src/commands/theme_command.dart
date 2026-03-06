import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class ThemeCommand extends Command<void> {
  @override
  String get name => 'theme';

  @override
  String get description =>
      'Generate atau update design tokens di magickit.yaml.';

  ThemeCommand() {
    argParser
      ..addOption('primary', help: 'Primary color (hex, e.g. #2d4af5).')
      ..addOption('secondary', help: 'Secondary color (hex).')
      ..addOption('background', help: 'Background color (hex).')
      ..addOption('font', help: 'Font family name (e.g. "DM Sans").')
      ..addOption('mono-font', help: 'Mono font family name (e.g. "DM Mono").');
  }

  @override
  Future<void> run() async {
    final primary = argResults?['primary'] as String?;
    final secondary = argResults?['secondary'] as String?;
    final background = argResults?['background'] as String?;
    final font = argResults?['font'] as String?;
    final monoFont = argResults?['mono-font'] as String?;

    if ([primary, secondary, background, font, monoFont]
        .every((v) => v == null)) {
      usageException(
        'Minimal satu opsi diperlukan.\n'
        'Contoh: magickit theme --primary "#2d4af5" --font "DM Sans"',
      );
    }

    // Validate hex colors
    for (final (name, value) in [
      ('primary', primary),
      ('secondary', secondary),
      ('background', background),
    ]) {
      if (value != null && !_isValidHex(value)) {
        logger.err('Warna $name "$value" tidak valid. Gunakan format hex (#RRGGBB).');
        exit(1);
      }
    }

    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) {
      logger.err('magickit.yaml tidak ditemukan.');
      logger.info('Jalankan `magickit init` terlebih dahulu.');
      exit(1);
    }

    final content = configFile.readAsStringSync();
    var updated = content;

    if (primary != null) {
      updated = _updateYamlValue(updated, 'primary', primary);
    }
    if (secondary != null) {
      updated = _updateYamlValue(updated, 'secondary', secondary);
    }
    if (background != null) {
      updated = _updateYamlValue(updated, 'background', background);
    }
    if (font != null) {
      updated = _updateYamlValue(updated, 'font_family', font);
    }
    if (monoFont != null) {
      updated = _updateYamlValue(updated, 'mono_font_family', monoFont);
    }

    configFile.writeAsStringSync(updated);

    logger.info('');
    logger.success('magickit.yaml berhasil diupdate!');
    logger.info('');
    logger.info('Perubahan:');
    if (primary != null) logger.info('  primary      : $primary');
    if (secondary != null) logger.info('  secondary    : $secondary');
    if (background != null) logger.info('  background   : $background');
    if (font != null) logger.info('  font_family  : $font');
    if (monoFont != null) logger.info('  mono_font    : $monoFont');
    logger.info('');
    logger.info(
      'Jalankan `magickit registry` untuk update component registry '
      'dan apply token ke kode.',
    );
  }

  bool _isValidHex(String value) {
    return RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$')
        .hasMatch(value);
  }

  /// Update nilai key di YAML content menggunakan regex.
  String _updateYamlValue(String content, String key, String value) {
    // Escape quotes untuk value yang mengandung spasi
    final yamlValue = value.contains(' ') ? '"$value"' : '"$value"';
    final pattern = RegExp('($key:\\s*).*');
    if (pattern.hasMatch(content)) {
      return content.replaceFirst(pattern, '$key: $yamlValue');
    }
    return content;
  }
}
