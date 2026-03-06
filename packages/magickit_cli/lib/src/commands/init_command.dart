import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description => 'Generate magickit.yaml di root project.';

  @override
  Future<void> run() async {
    final configFile = File('magickit.yaml');

    if (configFile.existsSync()) {
      logger.warn('magickit.yaml sudah ada. Gunakan --force untuk overwrite.');
      return;
    }

    logger.info('Membuat magickit.yaml...');
    configFile.writeAsStringSync(_defaultConfig);
    logger.success('magickit.yaml berhasil dibuat!');
    logger.info('');
    logger.info('Edit file tersebut sesuai kebutuhan project kamu.');
  }

  static const _defaultConfig = '''
magickit:
  # Assets generation
  assets:
    input: assets/
    output: lib/generated/assets.gen.dart
    types:
      - images
      - icons
      - fonts

  # Localization
  l10n:
    input: assets/lang/
    output: lib/generated/l10n/
    default_locale: id
    supported_locales:
      - id
      - en

  # Page generation
  page:
    architecture: clean       # clean | mvvm
    output: lib/features/
    state_management: bloc    # bloc | riverpod | cubit

  # API / Model generation
  api:
    input: api_schemas/
    output: lib/data/models/
    generate_repository: true
    serialization: json_serializable

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
}
