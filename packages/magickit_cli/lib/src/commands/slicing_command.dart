import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../services/anthropic_service.dart';
import '../services/gemini_service.dart';
import '../utils/init_guard.dart';
import '../utils/logger.dart';

typedef SendMessageFn = Future<String> Function({
  required String systemPrompt,
  required String userMessage,
  String? base64Image,
  String? imageMediaType,
});

class SlicingContext {
  final Map<String, dynamic> config;
  final String? bundle;
  final String systemPrompt;

  SlicingContext({
    required this.config,
    required this.bundle,
    required this.systemPrompt,
  });
}

class SlicingCommand extends Command<void> {
  @override
  String get name => 'slicing';

  @override
  String get description =>
      'AI-powered: konversi gambar atau Figma design menjadi Flutter code menggunakan MagicKit.';

  SlicingCommand() {
    addSubcommand(SlicingPromptCommand(this));
    addSubcommand(SlicingImageCommand(this));
    addSubcommand(SlicingFigmaCommand(this));
  }

  @override
  Future<void> run() async {
    usageException(
      'Gunakan subcommand:\n'
      '  magickit slicing prompt   → Generate prompt untuk upload manual ke AI\n'
      '  magickit slicing image    → Direct ke AI dari gambar\n'
      '  magickit slicing figma    → Direct ke AI dari Figma MCP selection',
    );
  }

  Map<String, dynamic> readSlicingConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final slicing = yaml?['magickit']?['slicing'];
      if (slicing is YamlMap) return Map<String, dynamic>.from(slicing);
    } catch (_) {}
    return {};
  }

  String? readStringConfig(Map<String, dynamic> config, String key) {
    final value = config[key];
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  String? readAiBundle({
    required Map<String, dynamic> config,
    required bool includeLocal,
    required bool includePackage,
  }) {
    final localBundle = includeLocal ? _readLocalBundle() : null;
    final packageBundle = includePackage
        ? (_readPackageBundle() ??
            _readBundleFile(
              'packages/magickit/lib/src/registry/ai_context_bundle.md',
            ))
        : null;
    if (localBundle == null && packageBundle == null) return null;
    if (localBundle == null) return packageBundle;
    if (packageBundle == null) return localBundle;

    logger.info('Menggabungkan AI bundle (package + local)...');
    return _mergeBundles(packageBundle, localBundle);
  }

  String? _readLocalBundle() {
    final paths = _autoDetectRegistryPaths();

    for (final path in paths) {
      final content = _readBundleFile(path);
      if (content != null) {
        logger.info('AI bundle (local) ditemukan: $path');
        return content;
      }
    }

    return null;
  }

  List<String> _autoDetectRegistryPaths() {
    return [
      'lib/core/components/src/registry/ai_context_bundle.md',
      'lib/components/src/registry/ai_context_bundle.md',
      'lib/src/registry/ai_context_bundle.md',
      // Also check root-level registry (some projects use this)
      'registry/ai_context_bundle.md',
    ];
  }

  String? _readPackageBundle() {
    // Strategy 1: Use package_config.json (works for version, path, git deps)
    final bundle = _readBundleFromPackageConfig();
    if (bundle != null) return bundle;

    // Strategy 2: Use pubspec.lock to find resolved version, then check pub cache
    final pubspecLockBundle = _readBundleFromPubspecLock();
    if (pubspecLockBundle != null) return pubspecLockBundle;

    // Strategy 3: Check pubspec.yaml for path/git dependency and resolve
    final pubspecYamlBundle = _readBundleFromPubspecYaml();
    if (pubspecYamlBundle != null) return pubspecYamlBundle;

    return null;
  }

  /// Reads bundle via .dart_tool/package_config.json.
  /// Works for all dependency types: version (pub), path, git.
  String? _readBundleFromPackageConfig() {
    final configFile = File('.dart_tool/package_config.json');
    if (!configFile.existsSync()) return null;

    try {
      final configJson =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      final packages = configJson['packages'];
      if (packages is! List) return null;

      for (final entry in packages) {
        if (entry is! Map<String, dynamic>) continue;
        if (entry['name'] != 'magickit') continue;
        final rootUriStr = entry['rootUri'] as String?;
        if (rootUriStr == null) return null;

        var rootUri = configFile.uri.resolve(rootUriStr);
        if (!rootUri.path.endsWith('/')) {
          rootUri = rootUri.replace(path: '${rootUri.path}/');
        }
        final bundleUri =
            rootUri.resolve('lib/src/registry/ai_context_bundle.md');
        final bundleFile = File.fromUri(bundleUri);
        if (bundleFile.existsSync()) {
          logger.info(
            'AI bundle (package_config) ditemukan: ${bundleFile.path}',
          );
          return bundleFile.readAsStringSync();
        }
      }
    } catch (_) {}

    return null;
  }

  /// Reads bundle by checking pubspec.lock for resolved version,
  /// then searching in Dart/Flutter pub cache.
  String? _readBundleFromPubspecLock() {
    final lockFile = File('pubspec.lock');
    if (!lockFile.existsSync()) return null;

    try {
      final yaml = loadYaml(lockFile.readAsStringSync()) as YamlMap?;
      final packages = yaml?['packages'] as YamlMap?;
      if (packages == null) return null;

      final magickitEntry = packages['magickit'] as YamlMap?;
      if (magickitEntry == null) return null;

      final description = magickitEntry['description'] as YamlMap?;
      final version = description?['version']?.toString() ??
          magickitEntry['version']?.toString();
      if (version == null) return null;

      // Search in pub cache directories
      final home = Platform.environment['HOME'] ?? '';
      final pubCachePaths = [
        '$home/.pub-cache/hosted/pub.dev/magickit-$version',
        '$home/.pub-cache/hosted/dartlang.org/magickit-$version',
        '${Platform.environment['PUB_CACHE'] ?? ''}/hosted/pub.dev/magickit-$version',
      ];

      for (final cachePath in pubCachePaths) {
        final bundlePath = '$cachePath/lib/src/registry/ai_context_bundle.md';
        final bundleFile = File(bundlePath);
        if (bundleFile.existsSync()) {
          logger.info('AI bundle (pub cache) ditemukan: $bundlePath');
          return bundleFile.readAsStringSync();
        }
      }
    } catch (_) {}

    return null;
  }

  /// Reads bundle by checking pubspec.yaml for path or git dependency,
  /// then resolving the bundle location.
  String? _readBundleFromPubspecYaml() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return null;

    try {
      final yaml = loadYaml(pubspecFile.readAsStringSync()) as YamlMap?;
      final deps = yaml?['dependencies'] as YamlMap?;
      if (deps == null) return null;

      final magickitDep = deps['magickit'];
      if (magickitDep == null) return null;

      // Handle path dependency
      if (magickitDep is YamlMap && magickitDep.containsKey('path')) {
        final depPath = magickitDep['path'].toString();
        final bundlePath = '$depPath/lib/src/registry/ai_context_bundle.md';
        final bundleFile = File(bundlePath);
        if (bundleFile.existsSync()) {
          logger.info('AI bundle (path dep) ditemukan: $bundlePath');
          return bundleFile.readAsStringSync();
        }
      }

      // Handle git dependency — the package will be in package_config.json
      // which is already checked by _readBundleFromPackageConfig()
    } catch (_) {}

    return null;
  }

  String? _readBundleFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  String _mergeBundles(String packageBundle, String localBundle) {
    final buffer = StringBuffer();

    // ── Header: Available Global Components ──
    buffer.writeln('## AVAILABLE GLOBAL COMPONENTS');
    buffer.writeln();
    buffer.writeln(
      'The project uses a shared component library called `magickit` '
      'for base components, plus local project-specific components. '
      'When generating Flutter code, ALWAYS prefer using these existing '
      'components over creating new widgets from scratch.',
    );
    buffer.writeln();
    buffer.writeln('### Import Statements:');
    buffer.writeln('```dart');
    buffer.writeln("import 'package:magickit/magickit.dart';");
    buffer.writeln(
        "import 'package:core/core.dart'; // local project components");
    buffer.writeln('```');
    buffer.writeln();

    // ── Package Components ──
    final packageSections = _extractMarkdownSections(packageBundle);
    for (final section in packageSections) {
      if (section.title.toLowerCase().contains('available') ||
          section.title.toLowerCase().contains('import') ||
          section.title.toLowerCase().contains('usage') ||
          section.title.toLowerCase().contains('guideline')) {
        continue;
      }
      buffer.writeln(section.content);
      buffer.writeln();
    }

    // ── Local Components ──
    final localSections = _extractMarkdownSections(localBundle);
    if (localSections.isNotEmpty) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## LOCAL PROJECT COMPONENTS');
      buffer.writeln();
      buffer.writeln(
        'Components below are specific to this project and extend MagicKit.',
      );
      buffer.writeln();

      for (final section in localSections) {
        if (section.title.toLowerCase().contains('available') ||
            section.title.toLowerCase().contains('import') ||
            section.title.toLowerCase().contains('usage') ||
            section.title.toLowerCase().contains('guideline')) {
          continue;
        }
        buffer.writeln(section.content);
        buffer.writeln();
      }
    }

    // ── Usage Guidelines (merged) ──
    buffer.writeln('## USAGE GUIDELINES');
    buffer.writeln();
    buffer.writeln(
        '1. **Always check this list first** before creating new widgets');
    buffer.writeln('2. **Use the exact class names** shown above');
    buffer.writeln(
        '3. **Use named constructors** when available (e.g., MagicButton.primary)');
    buffer.writeln(
        "4. **Import via `package:magickit/magickit.dart`** for MagicKit components");
    if (localSections.isNotEmpty) {
      buffer.writeln(
          "5. **Import via `package:core/core.dart`** for local project components");
    }
    buffer.writeln(
        '${localSections.isNotEmpty ? "6" : "5"}. **Use MagicTheme.of(context)** to access design tokens (colors, spacing, typography, radius, shadows)');
    buffer.writeln(
        '${localSections.isNotEmpty ? "7" : "6"}. **Never hardcode values** — always use theme tokens');
    buffer.writeln(
        '${localSections.isNotEmpty ? "8" : "7"}. **Follow the parameter patterns** shown in constructors');

    return buffer.toString();
  }

  List<({String title, String content})> _extractMarkdownSections(
    String content,
  ) {
    final sections = <({String title, String content})>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#### ')) {
        sections.add(_extractSection(content, i));
      }
    }

    return sections;
  }

  ({String title, String content}) _extractSection(
    String content,
    int startIdx,
  ) {
    final lines = content.split('\n');
    final titleLine = lines[startIdx];
    final contentLines = <String>[];

    for (var i = startIdx + 1; i < lines.length; i++) {
      if (lines[i].startsWith('#### ') ||
          lines[i].startsWith('### ') ||
          lines[i].startsWith('## ')) {
        break;
      }
      contentLines.add(lines[i]);
    }

    return (
      title: titleLine,
      content: '$titleLine\n${contentLines.join('\n')}'.trim(),
    );
  }

  String buildSystemPrompt(String? bundle) {
    final bundleSection = bundle != null
        ? '\n\n## COMPONENT CONTEXT\n\n$bundle'
        : '\n\n## COMPONENT CONTEXT\n\nGunakan MagicKit widgets (MagicButton, MagicText, MagicInput, MagicCard, dll) untuk semua UI elements. Jalankan `magickit registry` dulu untuk mendapatkan context komponen lengkap.';

    return '''
Kamu adalah Flutter developer expert yang mengkonversi UI design menjadi Flutter/Dart code menggunakan MagicKit UI Kit.
$bundleSection

## DESIGN TOKENS (MagicTheme)

Akses design tokens via `MagicTheme.of(context)` — JANGAN hardcode values.

### Colors: `MagicTheme.of(context).colors`
```
primary, onPrimary, secondary, onSecondary, surface, onSurface,
background, onBackground, error, onError, success, warning, info,
grey50..grey900, white, black, transparent
```

### Typography: `MagicTheme.of(context).typography`
```
heading1..heading6, bodyLarge, bodyMedium, bodySmall,
labelLarge, labelMedium, labelSmall, caption
```

### Spacing: `MagicTheme.of(context).spacing`
```
xs(4), sm(8), md(16), lg(24), xl(32), xxl(48)
```

### Radius: `MagicTheme.of(context).radius`
```
none(0), sm(4), md(8), lg(12), xl(16), xxl(24), full(9999)
```

### Shadows: `MagicTheme.of(context).shadows`
```
none, sm, md, lg, xl
```

## ATOMIC DESIGN STRUCTURE

MagicKit follows atomic design:
- **Atoms** (16): Basic building blocks — MagicButton, MagicText, MagicInput, MagicAvatar, etc.
- **Molecules** (13): Compositions — MagicCard, MagicFormField, MagicSearchBar, MagicDialog, etc.
- **Organisms** (10): Complex — MagicAppBar, MagicNavBar, MagicDrawer, MagicForm, MagicListView, etc.

## RULES YANG WAJIB DIKUTI

1. Return HANYA Dart code — tidak ada penjelasan, markdown, atau teks lain
2. Selalu gunakan komponen yang tersedia di COMPONENT CONTEXT jika cocok
3. Selalu gunakan `MagicTheme.of(context).colors` untuk warna — JANGAN hardcode
4. Selalu gunakan `MagicTheme.of(context).typography` untuk text styles
5. Selalu gunakan `MagicTheme.of(context).spacing` untuk jarak/padding
6. Selalu gunakan `MagicTheme.of(context).radius` untuk border radius
7. JANGAN hardcode nilai warna, ukuran, atau font — gunakan theme tokens
8. Code harus complete dan bisa langsung dijalankan
9. Gunakan StatelessWidget kecuali ada state yang jelas perlu dikelola
10. Import: `package:magickit/magickit.dart` + `package:flutter/material.dart`
11. Gunakan constructor signatures yang tertera di COMPONENT CONTEXT — jangan nebak parameter
12. Gunakan named constructors jika tersedia (e.g., MagicEmptyState.noData, MagicCarousel.banner)
''';
  }

  String outputPathToWidgetName(String outputPath) {
    final fileName = outputPath.split('/').last.replaceAll('.dart', '');
    return fileName
        .split('_')
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join();
  }

  String cleanCode(String response) {
    var cleaned = response.trim();
    if (cleaned.startsWith('```dart')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  String? resolveAiApiKey(String provider, Map<String, dynamic> config) {
    final providerKey = provider == 'gemini'
        ? readStringConfig(config, 'gemini_api_key')
        : readStringConfig(config, 'anthropic_api_key');
    final genericKey = readStringConfig(config, 'ai_api_key') ??
        readStringConfig(config, 'api_key');
    final envKey = provider == 'gemini'
        ? Platform.environment['GEMINI_API_KEY']
        : Platform.environment['ANTHROPIC_API_KEY'];

    return _firstNonEmpty([providerKey, genericKey, envKey]);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String resolveProvider(String provider) {
    final normalized = provider.trim().toLowerCase();
    return normalized == 'gemini' ? 'gemini' : 'anthropic';
  }

  String defaultModelFor(String provider) {
    if (provider == 'gemini') return 'gemini-2.5-flash';
    return 'claude-sonnet-4-6';
  }
}

class SlicingPromptCommand extends Command<void> {
  final SlicingCommand _ctx;

  SlicingPromptCommand(this._ctx) {
    argParser.addFlag(
      'package-components',
      help: 'Gunakan bundle komponen dari package magickit.',
      defaultsTo: true,
      negatable: true,
    );
  }

  @override
  String get name => 'prompt';

  @override
  String get description =>
      'Generate prompt file untuk upload manual ke AI (Claude, Codex, dll).';

  @override
  Future<void> run() async {
    requireMagickitInit();

    final config = _ctx.readSlicingConfig();
    final usePackageComponents =
        argResults?['package-components'] as bool? ?? true;
    const promptOut = 'lib/generated/slicing_prompt.md';

    final task = argResults?.rest.join(' ') ?? 'slicing ui';

    final bundle = _ctx.readAiBundle(
      config: config,
      includeLocal: true,
      includePackage: usePackageComponents,
    );
    if (bundle == null) {
      logger.warn(
        'ai_context_bundle.md tidak ditemukan di package maupun local.\n'
        '   Slicing prompt akan dibuat tanpa component context.\n'
        '   Untuk hasil terbaik:\n'
        '     1. Pastikan `magickit` ada di dependencies pubspec.yaml\n'
        '     2. Jalankan `flutter pub get` agar package_config.json ter-update\n'
        '     3. Jalankan `magickit registry` jika ada local components',
      );
    }

    final fullPrompt = _buildFullPrompt(bundle, task);

    final promptFile = File(promptOut);
    promptFile.parent.createSync(recursive: true);
    promptFile.writeAsStringSync(fullPrompt);

    logger.success('Prompt berhasil disimpan → $promptOut');
    logger.info('');
    logger.info('Cara pakai:');
    logger.info('1. Buka Claude/Codex desktop');
    logger.info('2. Upload gambar atau Figma selection ke AI');
    logger.info('3. Copy-paste isi file $promptOut ke AI');
    logger.info('4. AI akan generate Flutter code');
  }

  String _buildFullPrompt(String? bundle, String task) {
    final buffer = StringBuffer()
      ..writeln('# System Instructions')
      ..writeln()
      ..writeln(
        'You are a Flutter developer assistant. '
        'Generate code using the project\'s existing component library.',
      )
      ..writeln();

    if (bundle != null) {
      buffer.writeln(bundle);
      buffer.writeln();
    }

    // Design tokens section (always include for self-containment)
    buffer
      ..writeln('## DESIGN TOKENS (MagicTheme)')
      ..writeln()
      ..writeln('Access via `MagicTheme.of(context)` — NEVER hardcode values.')
      ..writeln()
      ..writeln('### Colors: `MagicTheme.of(context).colors`')
      ..writeln('```')
      ..writeln(
          'primary, onPrimary, secondary, onSecondary, surface, onSurface,')
      ..writeln(
          'background, onBackground, error, onError, success, warning, info,')
      ..writeln('grey50..grey900, white, black, transparent')
      ..writeln('```')
      ..writeln()
      ..writeln('### Typography: `MagicTheme.of(context).typography`')
      ..writeln('```')
      ..writeln('heading1..heading6, bodyLarge, bodyMedium, bodySmall,')
      ..writeln('labelLarge, labelMedium, labelSmall, caption')
      ..writeln('```')
      ..writeln()
      ..writeln('### Spacing: `MagicTheme.of(context).spacing`')
      ..writeln('```')
      ..writeln('xs(4), sm(8), md(16), lg(24), xl(32), xxl(48)')
      ..writeln('```')
      ..writeln()
      ..writeln('### Radius: `MagicTheme.of(context).radius`')
      ..writeln('```')
      ..writeln('none(0), sm(4), md(8), lg(12), xl(16), xxl(24), full(9999)')
      ..writeln('```')
      ..writeln()
      ..writeln('### Shadows: `MagicTheme.of(context).shadows`')
      ..writeln('```')
      ..writeln('none, sm, md, lg, xl')
      ..writeln('```')
      ..writeln();

    // Usage guidelines
    buffer
      ..writeln('## USAGE GUIDELINES')
      ..writeln()
      ..writeln(
          '1. **Always check the component list first** before creating new widgets')
      ..writeln('2. **Use the exact class names** shown above')
      ..writeln(
          '3. **Use named constructors** when available (e.g., MagicButton.primary, MagicEmptyState.noData)')
      ..writeln(
          "4. **Import via `package:magickit/magickit.dart`** for MagicKit components")
      ..writeln(
          "5. **Import via `package:core/core.dart`** for local project components (if any)")
      ..writeln(
          '6. **Use MagicTheme.of(context)** to access design tokens — NEVER hardcode')
      ..writeln('7. **Follow the parameter patterns** shown in constructors')
      ..writeln('8. **Follow atomic design**: atoms → molecules → organisms')
      ..writeln()
      ..writeln('# Task')
      ..writeln()
      ..writeln('Generate Flutter code for the following UI:')
      ..writeln()
      ..writeln(task)
      ..writeln()
      ..writeln('## Requirements:')
      ..writeln('1. Use existing components whenever possible')
      ..writeln("2. Import via: import 'package:magickit/magickit.dart';")
      ..writeln(
          "3. Import via: import 'package:core/core.dart'; (only if local components exist)")
      ..writeln('4. Follow the project\'s atomic design pattern')
      ..writeln('5. Generate complete, runnable code')
      ..writeln('6. Include proper comments and documentation')
      ..writeln(
          '7. Use MagicTheme.of(context) for ALL colors, spacing, typography');

    return buffer.toString();
  }
}

class SlicingImageCommand extends Command<void> {
  final SlicingCommand _ctx;

  SlicingImageCommand(this._ctx) {
    argParser
      ..addOption(
        'source',
        abbr: 's',
        help: 'Path ke file gambar UI (PNG/JPG/WEBP).',
      )
      ..addOption(
        'provider',
        help: 'AI provider (anthropic atau gemini).',
        allowed: ['anthropic', 'gemini'],
      )
      ..addFlag(
        'package-components',
        help: 'Gunakan bundle komponen dari package magickit.',
        defaultsTo: true,
        negatable: true,
      );
  }

  @override
  String get name => 'image';

  @override
  String get description =>
      'Direct ke AI: konversi gambar UI menjadi Flutter code.';

  @override
  Future<void> run() async {
    requireMagickitInit();

    final config = _ctx.readSlicingConfig();
    final usePackageComponents =
        argResults?['package-components'] as bool? ?? true;
    final imagePath = argResults?['source'] as String?;
    const outputPath = 'lib/generated/sliced_ui.dart';
    final providerInput = argResults?['provider'] as String? ??
        _ctx.readStringConfig(config, 'ai_provider') ??
        'anthropic';
    final provider = _ctx.resolveProvider(providerInput);
    final model = _resolveModel(provider, config);

    if (imagePath == null) {
      usageException('Gunakan --source <path> untuk file gambar.');
    }

    final bundle = _ctx.readAiBundle(
      config: config,
      includeLocal: true,
      includePackage: usePackageComponents,
    );
    if (bundle == null) {
      logger.warn(
        'ai_context_bundle.md tidak ditemukan.\n'
        '   Slicing akan dilanjutkan tanpa component context.\n'
        '   Untuk hasil terbaik:\n'
        '     1. Pastikan `magickit` ada di dependencies pubspec.yaml\n'
        '     2. Jalankan `flutter pub get` agar package_config.json ter-update\n'
        '     3. Jalankan `magickit registry` jika ada local components',
      );
    }

    final systemPrompt = _ctx.buildSystemPrompt(bundle);

    final SendMessageFn sendMessage;
    if (provider == 'gemini') {
      final apiKey = _ctx.resolveAiApiKey(provider, config);
      if (apiKey == null || apiKey.isEmpty) {
        logger.err(
          'API key Gemini tidak ditemukan di magickit.yaml atau environment.',
        );
        logger.info('Set environment variable:');
        logger.info('  export GEMINI_API_KEY=...');
        exit(1);
      }
      final service = GeminiService(apiKey: apiKey, model: model);
      sendMessage = service.sendMessage;
    } else {
      final apiKey = _ctx.resolveAiApiKey(provider, config);
      if (apiKey == null || apiKey.isEmpty) {
        logger.err(
          'API key Anthropic tidak ditemukan di magickit.yaml atau environment.',
        );
        logger.info('Set environment variable:');
        logger.info('  export ANTHROPIC_API_KEY=sk-ant-...');
        exit(1);
      }
      final service = AnthropicService(apiKey: apiKey, model: model);
      sendMessage = service.sendMessage;
    }

    try {
      final generatedCode = await _sliceFromImage(
        imagePath,
        sendMessage,
        systemPrompt,
        outputPath,
      );

      final outputFile = File(outputPath);
      outputFile.parent.createSync(recursive: true);
      outputFile.writeAsStringSync(generatedCode);

      logger.success('Flutter code berhasil di-generate → $outputPath');
      logger.info('');
      logger.info('Preview (50 baris pertama):');
      final lines = generatedCode.split('\n').take(50).join('\n');
      logger.info(lines);
      if (generatedCode.split('\n').length > 50) {
        logger.info('... (lihat $outputPath untuk full code)');
      }
    } on AnthropicException catch (e) {
      logger.err('API error (${e.statusCode}): ${e.message}');
      exit(1);
    } on GeminiException catch (e) {
      logger.err('API error (${e.statusCode}): ${e.message}');
      exit(1);
    } catch (e) {
      logger.err('Error: $e');
      exit(1);
    }
  }

  Future<String> _sliceFromImage(
    String imagePath,
    SendMessageFn sendMessage,
    String systemPrompt,
    String outputPath,
  ) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      logger.err('File "$imagePath" tidak ditemukan.');
      exit(1);
    }

    final ext = imagePath.split('.').last.toLowerCase();
    final mediaType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };

    final progress =
        logger.magicProgress('Membaca dan mengirim gambar ke AI...');
    final bytes = file.readAsBytesSync();
    final base64Image = base64Encode(bytes);

    progress.update('Menunggu response dari AI...');

    final widgetName = _ctx.outputPathToWidgetName(outputPath);
    final response = await sendMessage(
      systemPrompt: systemPrompt,
      userMessage:
          'Convert UI design ini menjadi Flutter widget bernama "$widgetName" '
          'menggunakan MagicKit components. '
          'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.',
      base64Image: base64Image,
      imageMediaType: mediaType,
    );

    progress.complete('Code berhasil di-generate!');
    return _ctx.cleanCode(response);
  }

  String _resolveModel(String provider, Map<String, dynamic> config) {
    final providerWasExplicit = argResults?.wasParsed('provider') == true;
    if (providerWasExplicit) return _ctx.defaultModelFor(provider);

    final configModel = _ctx.readStringConfig(config, 'model');
    if (configModel is String && configModel.isNotEmpty) {
      return configModel;
    }

    return _ctx.defaultModelFor(provider);
  }
}

class SlicingFigmaCommand extends Command<void> {
  final SlicingCommand _ctx;

  SlicingFigmaCommand(this._ctx) {
    argParser
      ..addOption(
        'selection',
        abbr: 's',
        help: 'Path ke file JSON selection dari Figma MCP.',
      )
      ..addOption(
        'provider',
        help: 'AI provider (anthropic atau gemini).',
        allowed: ['anthropic', 'gemini'],
      )
      ..addFlag(
        'package-components',
        help: 'Gunakan bundle komponen dari package magickit.',
        defaultsTo: true,
        negatable: true,
      );
  }

  @override
  String get name => 'figma';

  @override
  String get description =>
      'Direct ke AI: konversi Figma selection (via MCP) menjadi Flutter code.';

  @override
  Future<void> run() async {
    requireMagickitInit();

    final config = _ctx.readSlicingConfig();
    final usePackageComponents =
        argResults?['package-components'] as bool? ?? true;
    final selectionPath = argResults?['selection'] as String?;
    const outputPath = 'lib/generated/sliced_ui.dart';
    final providerInput = argResults?['provider'] as String? ??
        _ctx.readStringConfig(config, 'ai_provider') ??
        'anthropic';
    final provider = _ctx.resolveProvider(providerInput);
    final model = _resolveModel(provider, config);

    if (selectionPath == null) {
      usageException(
          'Gunakan --selection <path> untuk file Figma selection JSON.');
    }

    final figmaSelectionContext = _readFigmaSelectionContext(selectionPath);

    final bundle = _ctx.readAiBundle(
      config: config,
      includeLocal: true,
      includePackage: usePackageComponents,
    );
    if (bundle == null) {
      logger.warn(
        'ai_context_bundle.md tidak ditemukan.\n'
        '   Slicing akan dilanjutkan tanpa component context.\n'
        '   Untuk hasil terbaik:\n'
        '     1. Pastikan `magickit` ada di dependencies pubspec.yaml\n'
        '     2. Jalankan `flutter pub get` agar package_config.json ter-update\n'
        '     3. Jalankan `magickit registry` jika ada local components',
      );
    }

    final systemPrompt = _ctx.buildSystemPrompt(bundle);

    final SendMessageFn sendMessage;
    if (provider == 'gemini') {
      final apiKey = _ctx.resolveAiApiKey(provider, config);
      if (apiKey == null || apiKey.isEmpty) {
        logger.err(
          'API key Gemini tidak ditemukan di magickit.yaml atau environment.',
        );
        logger.info('Set environment variable:');
        logger.info('  export GEMINI_API_KEY=...');
        exit(1);
      }
      final service = GeminiService(apiKey: apiKey, model: model);
      sendMessage = service.sendMessage;
    } else {
      final apiKey = _ctx.resolveAiApiKey(provider, config);
      if (apiKey == null || apiKey.isEmpty) {
        logger.err(
          'API key Anthropic tidak ditemukan di magickit.yaml atau environment.',
        );
        logger.info('Set environment variable:');
        logger.info('  export ANTHROPIC_API_KEY=sk-ant-...');
        exit(1);
      }
      final service = AnthropicService(apiKey: apiKey, model: model);
      sendMessage = service.sendMessage;
    }

    try {
      final generatedCode = await _sliceFromFigmaSelection(
        figmaSelectionContext,
        sendMessage,
        systemPrompt,
        outputPath,
      );

      final outputFile = File(outputPath);
      outputFile.parent.createSync(recursive: true);
      outputFile.writeAsStringSync(generatedCode);

      logger.success('Flutter code berhasil di-generate → $outputPath');
      logger.info('');
      logger.info('Preview (50 baris pertama):');
      final lines = generatedCode.split('\n').take(50).join('\n');
      logger.info(lines);
      if (generatedCode.split('\n').length > 50) {
        logger.info('... (lihat $outputPath untuk full code)');
      }
    } on AnthropicException catch (e) {
      logger.err('API error (${e.statusCode}): ${e.message}');
      exit(1);
    } on GeminiException catch (e) {
      logger.err('API error (${e.statusCode}): ${e.message}');
      exit(1);
    } catch (e) {
      logger.err('Error: $e');
      exit(1);
    }
  }

  String _readFigmaSelectionContext(String selectionPath) {
    final file = File(selectionPath);
    if (!file.existsSync()) {
      logger.err('Figma selection file tidak ditemukan: $selectionPath');
      exit(1);
    }
    final content = file.readAsStringSync();
    if (content.trim().isEmpty) {
      logger.err('Figma selection file kosong: $selectionPath');
      exit(1);
    }
    return _formatFigmaSelectionContext(content);
  }

  String _formatFigmaSelectionContext(String rawJson) {
    final trimmed = rawJson.trim();
    final excerpt = trimmed.substring(
      0,
      trimmed.length.clamp(0, 3000),
    );
    final suffix = trimmed.length > 3000 ? '...' : '';

    return '''
Figma selection (MCP JSON):
$excerpt$suffix
'''
        .trim();
  }

  Future<String> _sliceFromFigmaSelection(
    String figmaSelectionContext,
    SendMessageFn sendMessage,
    String systemPrompt,
    String outputPath,
  ) async {
    final progress = logger.magicProgress('Mengirim Figma selection ke AI...');

    final widgetName = _ctx.outputPathToWidgetName(outputPath);
    final response = await sendMessage(
      systemPrompt: systemPrompt,
      userMessage:
          'Convert Figma selection ini menjadi Flutter widget bernama "$widgetName" '
          'menggunakan MagicKit components:\n\n$figmaSelectionContext\n\n'
          'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.',
    );

    progress.complete('Code berhasil di-generate!');
    return _ctx.cleanCode(response);
  }

  String _resolveModel(String provider, Map<String, dynamic> config) {
    final providerWasExplicit = argResults?.wasParsed('provider') == true;
    if (providerWasExplicit) return _ctx.defaultModelFor(provider);

    final configModel = _ctx.readStringConfig(config, 'model');
    if (configModel is String && configModel.isNotEmpty) {
      return configModel;
    }

    return _ctx.defaultModelFor(provider);
  }
}
