import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Generate magickit.yaml dan struktur folder project.';

  @override
  Future<void> run() async {
    final configFile = File('magickit.yaml');

    if (configFile.existsSync()) {
      logger.warn('magickit.yaml sudah ada. Hapus file tersebut untuk generate ulang.');
      return;
    }

    logger.info('Initializing MagicKit project...');
    logger.info('');

    // 1. Create magickit.yaml
    configFile.writeAsStringSync(_defaultConfig);
    logger.success('magickit.yaml berhasil dibuat');

    // 2. Create asset folders
    _createDir('assets/icons');
    _createDir('assets/illustrations');
    _createDir('assets/images');
    _createDir('assets/l10n');
    logger.success('Folder assets/ berhasil dibuat (icons, illustrations, images, l10n)');

    // 3. Create l10n template files
    _createFile('assets/l10n/en.json', _enJson);
    _createFile('assets/l10n/id.json', _idJson);
    logger.success('Template l10n berhasil dibuat (en.json, id.json)');

    // 4. Create lib/core/assets/ directory
    _createDir('lib/core/assets');
    logger.success('Folder lib/core/assets/ berhasil dibuat');

    logger.info('');
    logger.info('Struktur project:');
    logger.info('  assets/');
    logger.info('  ├── icons/');
    logger.info('  ├── illustrations/');
    logger.info('  ├── images/');
    logger.info('  └── l10n/');
    logger.info('      ├── en.json');
    logger.info('      └── id.json');
    logger.info('  lib/');
    logger.info('  └── core/');
    logger.info('      └── assets/     ← output `magickit assets`');
    logger.info('');
    logger.info('Edit magickit.yaml sesuai kebutuhan project kamu.');
    logger.info('Lalu jalankan `magickit assets` dan `magickit l10n` untuk generate code.');
  }

  void _createDir(String path) {
    Directory(path).createSync(recursive: true);
  }

  void _createFile(String path, String content) {
    final file = File(path);
    if (!file.existsSync()) {
      file.writeAsStringSync(content);
    }
  }

  static const _defaultConfig = '''
magickit:
  # Assets generation
  assets:
    input: assets/
    output: lib/core/assets/assets.gen.dart
    exclude:
      - l10n                         # skip, ditangani magickit l10n
    group:
      icons: icons/                  # MagicAssets.icons.xxx
      illustrations: illustrations/  # MagicAssets.illustrations.xxx
      images: images/                # MagicAssets.images.xxx
    strip_prefix:
      - ic_
      - img_

  # Localization
  l10n:
    input: assets/l10n/
    output: lib/core/l10n/
    default_locale: id
    supported_locales:
      - id
      - en

  # Page generation
  page:
    architecture: clean           # clean | mvvm
    output: lib/features/
    state_management: bloc        # bloc | riverpod | cubit

  # API / Model generation
  api:
    input: api_schemas/
    output: lib/data/models/
    generate_repository: true

  # Theme
  theme:
    primary: "#2d4af5"
    secondary: "#1a1a2e"
    background: "#f5f4f0"
    font_family: "DM Sans"
    mono_font_family: "DM Mono"

  # Slicing
  slicing:
    ai_provider: anthropic
    output: lib/features/
    use_local_components: true
''';

  static const _enJson = '''{
  "app_name": "My App",
  "common": {
    "ok": "OK",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "loading": "Loading..."
  }
}
''';

  static const _idJson = '''{
  "app_name": "My App",
  "common": {
    "ok": "OK",
    "cancel": "Batal",
    "save": "Simpan",
    "delete": "Hapus",
    "loading": "Memuat..."
  }
}
''';
}
