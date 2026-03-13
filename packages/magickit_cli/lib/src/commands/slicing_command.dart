import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
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

class SlicingCommand extends Command<void> {
  @override
  String get name => 'slicing';

  @override
  String get description =>
      'AI-powered: konversi gambar atau Figma design menjadi Flutter code menggunakan MagicKit.';

  SlicingCommand() {
    argParser
      ..addOption(
        'provider',
        help: 'AI provider (anthropic atau gemini).',
        allowed: ['anthropic', 'gemini'],
      )
      ..addOption(
        'image',
        abbr: 'i',
        help: 'Path ke screenshot atau gambar UI (PNG/JPG/WEBP).',
      )
      ..addOption(
        'figma',
        abbr: 'f',
        help: 'Figma file URL. Memerlukan FIGMA_API_KEY atau config di magickit.yaml.',
      )
      ..addOption(
        'figma-selection',
        help: 'Path ke file JSON selection dari Figma MCP (opsional).',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Path output Dart file.',
        defaultsTo: 'lib/generated/sliced_ui.dart',
      )
      ..addFlag(
        'print-prompt',
        help: 'Tampilkan prompt lengkap (system + user) untuk LLM manual.',
        defaultsTo: false,
      )
      ..addFlag(
        'export-prompt',
        help: 'Simpan prompt lengkap ke file.',
        defaultsTo: false,
      )
      ..addFlag(
        'package-components',
        help: 'Gunakan bundle komponen dari package magickit.',
        defaultsTo: true,
        negatable: true,
      );
  }

  @override
  Future<void> run() async {
    requireMagickitInit();

    final config = _readSlicingConfig();
    final useLocalComponents = _readBoolConfig(
      config,
      'use_local_components',
      defaultValue: true,
    );
    final usePackageComponents = _resolveBoolOption(
      'package-components',
      configValue: _readOptionalBoolConfig(config, 'use_package_components'),
      defaultValue: true,
    );
    final imagePath = argResults?['image'] as String?;
    final figmaUrl = argResults?['figma'] as String?;
    final figmaSelectionPath = argResults?['figma-selection'] as String?;
    final figmaSelectionContext =
        _readFigmaSelectionContext(figmaSelectionPath);
    final outputPath = _resolveStringOption(
      'output',
      configValue: _readStringConfig(config, 'output'),
      defaultValue: 'lib/generated/sliced_ui.dart',
    );
    final providerInput = _resolveStringOption(
      'provider',
      configValue: _readStringConfig(config, 'ai_provider'),
      defaultValue: 'anthropic',
    );
    final provider = _resolveProvider(providerInput);
    _warnIfUnknownProvider(providerInput);
    final model = _resolveModel(provider, config);
    _warnIfProviderModelMismatch(provider, model);
    final printPrompt = argResults?['print-prompt'] as bool? ?? false;
    final exportPrompt = argResults?['export-prompt'] as bool? ?? false;
    final promptOut =
        _readStringConfig(config, 'prompt_output') ??
        'lib/generated/slicing_prompt.txt';
    final figmaApiKey = _resolveFigmaApiKey(config);

    if (imagePath == null &&
        figmaUrl == null &&
        figmaSelectionContext == null) {
      usageException(
        'Gunakan --image <path>, --figma <url>, atau --figma-selection <path>.',
      );
    }

    // Read AI bundle
    final bundle = _readAiBundle(
      config: config,
      includeLocal: useLocalComponents,
      includePackage: usePackageComponents,
    );
    if (bundle == null) {
      logger.warn(
        'ai_context_bundle.txt tidak ditemukan. '
        'Jalankan `magickit registry` terlebih dahulu untuk hasil terbaik.',
      );
    }

    final systemPrompt = _buildSystemPrompt(bundle);

    final promptOnly = printPrompt || exportPrompt;
    if (promptOnly) {
      final userPrompt = await _buildUserPrompt(
        imagePath: imagePath,
        figmaUrl: figmaUrl,
        figmaSelectionContext: figmaSelectionContext,
        figmaApiKey: figmaApiKey,
        outputPath: outputPath,
      );
      final fullPrompt = _buildFullPrompt(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        imagePath: imagePath,
        figmaUrl: figmaUrl,
        figmaSelectionPath: figmaSelectionPath,
      );

      if (printPrompt) {
        stdout.writeln(fullPrompt);
      }

      if (exportPrompt) {
        final promptFile = File(promptOut);
        promptFile.parent.createSync(recursive: true);
        promptFile.writeAsStringSync(fullPrompt);
        logger.success('Prompt berhasil disimpan → $promptOut');
      }

      return;
    }

    final SendMessageFn sendMessage;
    if (provider == 'gemini') {
      final apiKey = _resolveAiApiKey(provider, config);
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
      final apiKey = _resolveAiApiKey(provider, config);
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
      String generatedCode;

      if (imagePath != null) {
        generatedCode = await _sliceFromImage(
          imagePath,
          sendMessage,
          systemPrompt,
          outputPath,
        );
      } else if (figmaSelectionContext != null) {
        generatedCode = await _sliceFromFigmaSelection(
          figmaSelectionContext,
          sendMessage,
          systemPrompt,
          outputPath,
        );
      } else {
        generatedCode = await _sliceFromFigma(
          figmaUrl!,
          figmaApiKey,
          sendMessage,
          systemPrompt,
          outputPath,
        );
      }

      // Write output
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

    final widgetName = _outputPathToWidgetName(outputPath);
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
    return _cleanCode(response);
  }

  Future<String> _sliceFromFigma(
    String figmaUrl,
    String? figmaApiKey,
    SendMessageFn sendMessage,
    String systemPrompt,
    String outputPath,
  ) async {
    final figmaKey = figmaApiKey;
    if (figmaKey == null || figmaKey.isEmpty) {
      logger.err('FIGMA_API_KEY tidak ditemukan di magickit.yaml atau environment.');
      logger.info('Set environment variable: export FIGMA_API_KEY=figd_...');
      exit(1);
    }

    final fileKey = _extractFigmaFileKey(figmaUrl);
    if (fileKey == null) {
      logger.err('Format Figma URL tidak valid: $figmaUrl');
      logger.info('Format yang valid: https://www.figma.com/file/XXXXXX/nama-file');
      exit(1);
    }
    final nodeId = _extractFigmaNodeId(figmaUrl);
    final progress = logger.magicProgress('Mengambil data dari Figma...');

    final figmaData = nodeId != null
        ? await _fetchFigmaNode(
            fileKey: fileKey,
            nodeId: nodeId,
            apiKey: figmaKey,
            progress: progress,
          )
        : await _fetchFigmaFile(
            fileKey: fileKey,
            apiKey: figmaKey,
            progress: progress,
          );

    final widgetName = _outputPathToWidgetName(outputPath);
    final figmaContext = nodeId != null
        ? _formatFigmaNodeContext(nodeId, figmaData)
        : _formatFigmaContext(figmaData);

    progress.update('Mengirim ke AI...');

    final response = await sendMessage(
      systemPrompt: systemPrompt,
      userMessage:
          'Convert Figma design ini menjadi Flutter widget bernama "$widgetName" '
          'menggunakan MagicKit components:\n\n$figmaContext\n\n'
          'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.',
    );

    progress.complete('Code berhasil di-generate!');
    return _cleanCode(response);
  }

  Future<String> _sliceFromFigmaSelection(
    String figmaSelectionContext,
    SendMessageFn sendMessage,
    String systemPrompt,
    String outputPath,
  ) async {
    final progress =
        logger.magicProgress('Mengirim Figma selection ke AI...');

    final widgetName = _outputPathToWidgetName(outputPath);
    final response = await sendMessage(
      systemPrompt: systemPrompt,
      userMessage:
          'Convert Figma selection ini menjadi Flutter widget bernama "$widgetName" '
          'menggunakan MagicKit components:\n\n$figmaSelectionContext\n\n'
          'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.',
    );

    progress.complete('Code berhasil di-generate!');
    return _cleanCode(response);
  }

  Map<String, dynamic> _readSlicingConfig() {
    final configFile = File('magickit.yaml');
    if (!configFile.existsSync()) return {};
    try {
      final yaml = loadYaml(configFile.readAsStringSync()) as YamlMap?;
      final slicing = yaml?['magickit']?['slicing'];
      if (slicing is YamlMap) return Map<String, dynamic>.from(slicing);
    } catch (_) {}
    return {};
  }

  String _resolveStringOption(
    String key, {
    required String? configValue,
    required String defaultValue,
  }) {
    if (argResults?.wasParsed(key) == true) {
      return (argResults?[key] as String?) ?? defaultValue;
    }
    if (configValue != null && configValue.isNotEmpty) return configValue;
    return defaultValue;
  }

  bool _resolveBoolOption(
    String key, {
    required bool? configValue,
    required bool defaultValue,
  }) {
    if (argResults?.wasParsed(key) == true) {
      return (argResults?[key] as bool?) ?? defaultValue;
    }
    if (configValue != null) return configValue;
    return defaultValue;
  }

  String _resolveProvider(String provider) {
    final normalized = provider.trim().toLowerCase();
    return normalized == 'gemini' ? 'gemini' : 'anthropic';
  }

  void _warnIfUnknownProvider(String providerInput) {
    final normalized = providerInput.trim().toLowerCase();
    if (normalized == 'anthropic' || normalized == 'gemini') return;
    logger.warn(
      'Provider "$providerInput" tidak dikenal. Default ke "anthropic".',
    );
  }

  void _warnIfProviderModelMismatch(String provider, String model) {
    final normalizedModel = model.toLowerCase();
    if (provider == 'anthropic' &&
        (normalizedModel.contains('gemini') ||
            normalizedModel.contains('google'))) {
      logger.warn(
        'Model "$model" terlihat milik Gemini, tapi provider = anthropic.',
      );
    }
    if (provider == 'gemini' &&
        (normalizedModel.contains('claude') ||
            normalizedModel.contains('anthropic'))) {
      logger.warn(
        'Model "$model" terlihat milik Anthropic, tapi provider = gemini.',
      );
    }
  }

  String _resolveModel(String provider, Map<String, dynamic> config) {
    final providerWasExplicit =
        argResults?.wasParsed('provider') == true;
    if (providerWasExplicit) return _defaultModelFor(provider);

    final configModel = _readStringConfig(config, 'model');
    if (configModel is String && configModel.isNotEmpty) {
      return configModel;
    }

    return _defaultModelFor(provider);
  }

  String _defaultModelFor(String provider) {
    if (provider == 'gemini') return 'gemini-2.5-flash';
    return 'claude-sonnet-4-6';
  }

  bool _readBoolConfig(
    Map<String, dynamic> config,
    String key, {
    required bool defaultValue,
  }) {
    final value = config[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return defaultValue;
  }

  bool? _readOptionalBoolConfig(Map<String, dynamic> config, String key) {
    final value = config[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  String? _readStringConfig(Map<String, dynamic> config, String key) {
    final value = config[key];
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Future<String> _buildUserPrompt({
    required String? imagePath,
    required String? figmaUrl,
    required String? figmaSelectionContext,
    required String? figmaApiKey,
    required String outputPath,
  }) async {
    final widgetName = _outputPathToWidgetName(outputPath);
    final baseInstruction =
        'Convert UI design ini menjadi Flutter widget bernama "$widgetName" '
        'menggunakan MagicKit components. '
        'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.';

    if (imagePath != null) {
      return '''
$baseInstruction

Image Path: $imagePath
Catatan: Upload gambar ini ke LLM yang kamu pakai.
'''.trim();
    }

    if (figmaSelectionContext != null) {
      return '''
$baseInstruction

$figmaSelectionContext
'''.trim();
    }

    if (figmaUrl != null) {
      final figmaContext =
          await _tryBuildFigmaContext(figmaUrl, figmaApiKey);
      if (figmaContext != null) {
        return '''
$baseInstruction

$figmaContext
'''.trim();
      }

      return '''
$baseInstruction

Figma URL: $figmaUrl
Catatan: Jika perlu, ambil detail dari Figma secara manual.
'''.trim();
    }

    return baseInstruction;
  }

  String _buildFullPrompt({
    required String systemPrompt,
    required String userPrompt,
    required String? imagePath,
    required String? figmaUrl,
    required String? figmaSelectionPath,
  }) {
    final notes = _buildManualNotes(
      imagePath: imagePath,
      figmaUrl: figmaUrl,
      figmaSelectionPath: figmaSelectionPath,
    );
    return '''
=== MANUAL MODE NOTES ===
$notes

=== SYSTEM PROMPT ===
$systemPrompt

=== USER PROMPT ===
$userPrompt
'''.trim();
  }

  String _buildManualNotes({
    required String? imagePath,
    required String? figmaUrl,
    required String? figmaSelectionPath,
  }) {
    final buffer = StringBuffer()
      ..writeln('1. Buka Claude/Codex desktop kamu.')
      ..writeln('2. Upload gambar atau gunakan Figma sesuai sumber.')
      ..writeln('3. Paste USER PROMPT di bawah ini, lalu jalankan.');

    if (imagePath != null) {
      buffer.writeln('Image path: $imagePath');
    }
    if (figmaUrl != null) {
      buffer.writeln('Figma URL: $figmaUrl');
    }
    if (figmaSelectionPath != null) {
      buffer.writeln('Figma selection file: $figmaSelectionPath');
    }

    return buffer.toString().trim();
  }

  Future<String?> _tryBuildFigmaContext(
    String figmaUrl,
    String? figmaApiKey,
  ) async {
    final figmaKey = figmaApiKey;
    if (figmaKey == null || figmaKey.isEmpty) return null;

    final fileKey = _extractFigmaFileKey(figmaUrl);
    if (fileKey == null) return null;
    final nodeId = _extractFigmaNodeId(figmaUrl);

    try {
      final response = nodeId != null
          ? await http.get(
              Uri.parse(
                'https://api.figma.com/v1/files/$fileKey/nodes?ids=$nodeId',
              ),
              headers: {'X-Figma-Token': figmaKey},
            )
          : await http.get(
              Uri.parse(
                'https://api.figma.com/v1/files/$fileKey?depth=3',
              ),
              headers: {'X-Figma-Token': figmaKey},
            );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (nodeId != null) {
        final nodeData = _extractNodePayload(nodeId, data);
        if (nodeData == null) return null;
        return _formatFigmaNodeContext(nodeId, nodeData);
      }
      return _formatFigmaContext(data);
    } catch (_) {
      return null;
    }
  }

  String? _extractFigmaFileKey(String figmaUrl) {
    // Format: https://www.figma.com/file/{fileKey}/...
    //         https://www.figma.com/design/{fileKey}/...
    final match =
        RegExp(r'figma\.com/(?:file|design)/([^/]+)').firstMatch(figmaUrl);
    return match?.group(1);
  }

  String? _extractFigmaNodeId(String figmaUrl) {
    try {
      final uri = Uri.parse(figmaUrl);
      final nodeId = uri.queryParameters['node-id'];
      if (nodeId == null || nodeId.trim().isEmpty) return null;
      return _normalizeNodeId(nodeId);
    } catch (_) {
      return null;
    }
  }

  String _normalizeNodeId(String nodeId) {
    final trimmed = nodeId.trim();
    if (trimmed.contains(':')) return trimmed;
    if (trimmed.contains('-')) return trimmed.replaceAll('-', ':');
    return trimmed;
  }

  String _formatFigmaContext(Map<String, dynamic> figmaData) {
    final pageName =
        (figmaData['document'] as Map<String, dynamic>?)?['name'] ??
            'Figma Design';
    final components = _extractFigmaComponents(figmaData);
    final dataJson = jsonEncode(figmaData);
    final excerpt = dataJson.substring(
      0,
      dataJson.length.clamp(0, 3000),
    );

    return '''
Figma File: $pageName
Components ditemukan:
${components.map((c) => '- $c').join('\n')}

Figma data (JSON excerpt):
$excerpt...
'''.trim();
  }

  String _formatFigmaNodeContext(
    String nodeId,
    Map<String, dynamic> nodeData,
  ) {
    final document = nodeData['document'] as Map<String, dynamic>?;
    final name = document?['name'] as String? ?? 'Figma Node';
    final type = document?['type'] as String? ?? 'NODE';
    final components =
        document == null ? <String>[] : _extractFigmaComponents(document);
    final dataJson = jsonEncode(nodeData);
    final excerpt = dataJson.substring(
      0,
      dataJson.length.clamp(0, 3000),
    );

    return '''
Figma Node: $name
Node ID: $nodeId
Type: $type
Components ditemukan:
${components.map((c) => '- $c').join('\n')}

Figma node data (JSON excerpt):
$excerpt...
'''.trim();
  }

  String _buildSystemPrompt(String? bundle) {
    final bundleSection = bundle != null
        ? '\n\n$bundle'
        : '\n\nGunakan MagicKit widgets (MagicButton, MagicText, MagicInput, MagicCard, dll) untuk semua UI elements.';

    return '''
Kamu adalah Flutter developer expert yang mengkonversi UI design menjadi Flutter/Dart code menggunakan MagicKit UI Kit.
$bundleSection

Rules yang WAJIB diikuti:
1. Return HANYA Dart code — tidak ada penjelasan, markdown, atau teks lain
2. Selalu gunakan MagicKit components yang tersedia
3. Selalu gunakan MagicTheme.of(context) untuk warna, spacing, typography
4. JANGAN hardcode nilai warna, ukuran, atau font — gunakan theme tokens
5. Code harus complete dan bisa langsung dijalankan
6. Gunakan StatelessWidget kecuali ada state yang jelas perlu dikelola
7. Import hanya package:magickit/magickit.dart dan package:flutter/material.dart
''';
  }

  String? _readAiBundle({
    required Map<String, dynamic> config,
    required bool includeLocal,
    required bool includePackage,
  }) {
    final localBundle =
        includeLocal ? _readLocalBundle(config: config) : null;
    final packageBundle = includePackage
        ? (_readPackageBundle() ??
            _readBundleFile(
              'packages/magickit/lib/src/registry/ai_context_bundle.txt',
            ))
        : null;

    if (localBundle == null && packageBundle == null) return null;
    if (localBundle == null) return packageBundle;
    if (packageBundle == null) return localBundle;

    logger.info('Menggabungkan AI bundle (package + local)...');
    return _mergeBundles(packageBundle, localBundle);
  }

  String? _readLocalBundle({
    required Map<String, dynamic> config,
  }) {
    final customPath = _resolveLocalBundlePath(config);
    final paths = [
      if (customPath != null) customPath,
      'lib/src/registry/ai_context_bundle.txt',
    ];

    for (final path in paths) {
      final content = _readBundleFile(path);
      if (content != null) {
        logger.info('AI bundle (local) ditemukan: $path');
        return content;
      }
    }

    return null;
  }

  String? _resolveLocalBundlePath(Map<String, dynamic> config) {
    final bundlePath = _readStringConfig(config, 'bundle');
    if (bundlePath != null && bundlePath.isNotEmpty) {
      return _normalizeBundlePath(bundlePath);
    }

    final registryOutput = _readStringConfig(config, 'registry_output');
    if (registryOutput != null && registryOutput.isNotEmpty) {
      return _normalizeBundlePath(registryOutput);
    }

    final defaultOutput = _defaultRegistryOutput();
    return _normalizeBundlePath(defaultOutput);
  }

  String _normalizeBundlePath(String value) {
    if (value.endsWith('.txt')) return value;
    return _joinPath(value, 'ai_context_bundle.txt');
  }

  String _defaultRegistryOutput() {
    if (Directory('lib/core/components').existsSync()) {
      return 'lib/core/components/src/registry/';
    }
    if (Directory('lib/components').existsSync()) {
      return 'lib/components/src/registry/';
    }
    return 'lib/src/registry/';
  }

  String _joinPath(String dir, String file) {
    if (dir.endsWith('/')) return '$dir$file';
    return '$dir/$file';
  }

  String? _readPackageBundle() {
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

        final rootUri = configFile.uri.resolve(rootUriStr);
        final bundleUri =
            rootUri.resolve('lib/src/registry/ai_context_bundle.txt');
        final bundleFile = File.fromUri(bundleUri);
        if (bundleFile.existsSync()) {
          logger.info(
            'AI bundle (package) ditemukan: ${bundleFile.path}',
          );
          return bundleFile.readAsStringSync();
        }
        return null;
      }
    } catch (_) {
      // Fall back silently if package_config.json is not parseable.
      return null;
    }

    return null;
  }

  String? _readBundleFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  String _mergeBundles(String packageBundle, String localBundle) {
    final packageParts = _splitBundle(packageBundle);
    final localParts = _splitBundle(localBundle);

    final buffer = StringBuffer();

    final packageComponents = _stripBundleHeader(packageParts.components);
    if (packageComponents.isNotEmpty) {
      buffer.writeln('Available MagicKit Components (package):');
      buffer.writeln();
      buffer.writeln(packageComponents);
      buffer.writeln();
    }

    final localComponents = _stripBundleHeader(localParts.components);
    if (localComponents.isNotEmpty) {
      buffer.writeln('Available MagicKit Components (local):');
      buffer.writeln();
      buffer.writeln(localComponents);
      buffer.writeln();
    }

    final rules = _pickRules(packageParts.rules, localParts.rules);
    if (rules != null && rules.isNotEmpty) {
      buffer.writeln(rules.trim());
    }

    return buffer.toString().trim();
  }

  _BundleParts _splitBundle(String bundle) {
    final marker = 'Rules untuk AI:';
    final index = bundle.indexOf(marker);
    if (index == -1) {
      return _BundleParts(bundle, null);
    }

    final components = bundle.substring(0, index).trim();
    final rules = bundle.substring(index).trim();
    return _BundleParts(components, rules);
  }

  String _stripBundleHeader(String components) {
    final lines = components.split('\n');
    if (lines.isEmpty) return '';

    var startIndex = 0;
    if (lines.first.trim() == 'Available MagicKit Components:') {
      startIndex = 1;
      if (lines.length > 1 && lines[1].trim().isEmpty) {
        startIndex = 2;
      }
    }

    return lines.sublist(startIndex).join('\n').trim();
  }

  String? _pickRules(String? packageRules, String? localRules) {
    final local = localRules?.trim();
    if (local != null && local.isNotEmpty) return local;
    final pkg = packageRules?.trim();
    if (pkg != null && pkg.isNotEmpty) return pkg;
    return null;
  }

  String _outputPathToWidgetName(String outputPath) {
    final fileName = outputPath.split('/').last.replaceAll('.dart', '');
    return fileName
        .split('_')
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join();
  }

  List<String> _extractFigmaComponents(Map<String, dynamic> data) {
    final components = <String>[];
    void traverse(dynamic node) {
      if (node is Map<String, dynamic>) {
        final name = node['name'] as String?;
        final type = node['type'] as String?;
        if (name != null && type != null && type != 'DOCUMENT' && type != 'PAGE') {
          components.add('$type: $name');
        }
        final children = node['children'];
        if (children is List) {
          for (final child in children.take(20)) {
            traverse(child);
          }
        }
      }
    }

    traverse(data['document']);
    return components.take(30).toList();
  }

  Future<Map<String, dynamic>> _fetchFigmaFile({
    required String fileKey,
    required String apiKey,
    required Progress progress,
  }) async {
    final response = await http.get(
      Uri.parse('https://api.figma.com/v1/files/$fileKey?depth=3'),
      headers: {'X-Figma-Token': apiKey},
    );

    if (response.statusCode != 200) {
      progress.fail('Gagal mengambil Figma data: ${response.statusCode}');
      exit(1);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchFigmaNode({
    required String fileKey,
    required String nodeId,
    required String apiKey,
    required Progress progress,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://api.figma.com/v1/files/$fileKey/nodes?ids=$nodeId',
      ),
      headers: {'X-Figma-Token': apiKey},
    );

    if (response.statusCode != 200) {
      progress.fail('Gagal mengambil Figma node: ${response.statusCode}');
      exit(1);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final nodeData = _extractNodePayload(nodeId, data);
    if (nodeData == null) {
      progress.fail('Node "$nodeId" tidak ditemukan di file Figma.');
      exit(1);
    }
    return nodeData;
  }

  Map<String, dynamic>? _extractNodePayload(
    String nodeId,
    Map<String, dynamic> data,
  ) {
    final nodes = data['nodes'];
    if (nodes is! Map<String, dynamic>) return null;
    final payload = nodes[nodeId];
    if (payload is! Map<String, dynamic>) return null;
    return payload;
  }

  String _cleanCode(String response) {
    // Strip markdown code blocks if Claude adds them
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

  String? _resolveAiApiKey(String provider, Map<String, dynamic> config) {
    final providerKey = provider == 'gemini'
        ? _readStringConfig(config, 'gemini_api_key')
        : _readStringConfig(config, 'anthropic_api_key');
    final genericKey =
        _readStringConfig(config, 'ai_api_key') ??
        _readStringConfig(config, 'api_key');
    final envKey = provider == 'gemini'
        ? Platform.environment['GEMINI_API_KEY']
        : Platform.environment['ANTHROPIC_API_KEY'];

    return _firstNonEmpty([providerKey, genericKey, envKey]);
  }

  String? _resolveFigmaApiKey(Map<String, dynamic> config) {
    final configKey =
        _readStringConfig(config, 'figma_api_key') ??
        _readStringConfig(config, 'figma_key');
    final envKey = Platform.environment['FIGMA_API_KEY'];
    return _firstNonEmpty([configKey, envKey]);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String? _readFigmaSelectionContext(String? selectionPath) {
    if (selectionPath == null || selectionPath.trim().isEmpty) return null;
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
'''.trim();
  }

}

class _BundleParts {
  final String components;
  final String? rules;

  const _BundleParts(this.components, this.rules);
}
