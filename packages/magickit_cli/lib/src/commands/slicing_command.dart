import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import '../services/anthropic_service.dart';
import '../utils/init_guard.dart';
import '../utils/logger.dart';

class SlicingCommand extends Command<void> {
  @override
  String get name => 'slicing';

  @override
  String get description =>
      'AI-powered: konversi gambar atau Figma design menjadi Flutter code menggunakan MagicKit.';

  SlicingCommand() {
    argParser
      ..addOption(
        'image',
        abbr: 'i',
        help: 'Path ke screenshot atau gambar UI (PNG/JPG/WEBP).',
      )
      ..addOption(
        'figma',
        abbr: 'f',
        help: 'Figma file URL. Memerlukan FIGMA_API_KEY di environment.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Path output Dart file.',
        defaultsTo: 'lib/generated/sliced_ui.dart',
      )
      ..addOption(
        'model',
        abbr: 'm',
        help: 'Claude model yang digunakan.',
        defaultsTo: 'claude-sonnet-4-6',
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
      ..addOption(
        'prompt-out',
        help: 'Path output untuk file prompt.',
        defaultsTo: 'lib/generated/slicing_prompt.txt',
      )
      ..addOption(
        'bundle',
        abbr: 'b',
        help: 'Path ke ai_context_bundle.txt.',
        defaultsTo: null,
      );
  }

  @override
  Future<void> run() async {
    requireMagickitInit();

    final imagePath = argResults?['image'] as String?;
    final figmaUrl = argResults?['figma'] as String?;
    final outputPath = argResults?['output'] as String? ?? 'lib/generated/sliced_ui.dart';
    final model = argResults?['model'] as String? ?? 'claude-sonnet-4-6';
    final bundlePath = argResults?['bundle'] as String?;
    final printPrompt = argResults?['print-prompt'] as bool? ?? false;
    final exportPrompt = argResults?['export-prompt'] as bool? ?? false;
    final promptOut =
        argResults?['prompt-out'] as String? ?? 'lib/generated/slicing_prompt.txt';

    if (imagePath == null && figmaUrl == null) {
      usageException('Gunakan --image <path> atau --figma <url>.');
    }

    // Read AI bundle
    final bundle = _readAiBundle(bundlePath);
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
        outputPath: outputPath,
      );
      final fullPrompt = _buildFullPrompt(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
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

    // Validate API key
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.err('ANTHROPIC_API_KEY tidak ditemukan di environment.');
      logger.info('Set environment variable:');
      logger.info('  export ANTHROPIC_API_KEY=sk-ant-...');
      exit(1);
    }

    final service = AnthropicService(apiKey: apiKey, model: model);

    try {
      String generatedCode;

      if (imagePath != null) {
        generatedCode = await _sliceFromImage(
          imagePath,
          service,
          systemPrompt,
          outputPath,
        );
      } else {
        generatedCode = await _sliceFromFigma(
          figmaUrl!,
          service,
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
    } catch (e) {
      logger.err('Error: $e');
      exit(1);
    }
  }

  Future<String> _sliceFromImage(
    String imagePath,
    AnthropicService service,
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
        logger.magicProgress('Membaca dan mengirim gambar ke Claude...');
    final bytes = file.readAsBytesSync();
    final base64Image = base64Encode(bytes);

    progress.update('Menunggu response dari Claude...');

    final widgetName = _outputPathToWidgetName(outputPath);
    final response = await service.sendMessage(
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
    AnthropicService service,
    String systemPrompt,
    String outputPath,
  ) async {
    final figmaKey = Platform.environment['FIGMA_API_KEY'];
    if (figmaKey == null || figmaKey.isEmpty) {
      logger.err('FIGMA_API_KEY tidak ditemukan di environment.');
      logger.info('Set environment variable: export FIGMA_API_KEY=figd_...');
      exit(1);
    }

    final fileKey = _extractFigmaFileKey(figmaUrl);
    if (fileKey == null) {
      logger.err('Format Figma URL tidak valid: $figmaUrl');
      logger.info('Format yang valid: https://www.figma.com/file/XXXXXX/nama-file');
      exit(1);
    }
    final progress = logger.magicProgress('Mengambil data dari Figma...');

    final figmaResponse = await http.get(
      Uri.parse('https://api.figma.com/v1/files/$fileKey?depth=3'),
      headers: {'X-Figma-Token': figmaKey},
    );

    if (figmaResponse.statusCode != 200) {
      progress.fail('Gagal mengambil Figma data: ${figmaResponse.statusCode}');
      exit(1);
    }

    final figmaData = jsonDecode(figmaResponse.body) as Map<String, dynamic>;
    final widgetName = _outputPathToWidgetName(outputPath);
    final figmaContext = _formatFigmaContext(figmaData);

    progress.update('Mengirim ke Claude...');

    final response = await service.sendMessage(
      systemPrompt: systemPrompt,
      userMessage:
          'Convert Figma design ini menjadi Flutter widget bernama "$widgetName" '
          'menggunakan MagicKit components:\n\n$figmaContext\n\n'
          'Return HANYA Dart code yang bisa langsung dipakai, tanpa penjelasan.',
    );

    progress.complete('Code berhasil di-generate!');
    return _cleanCode(response);
  }

  Future<String> _buildUserPrompt({
    required String? imagePath,
    required String? figmaUrl,
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

    if (figmaUrl != null) {
      final figmaContext = await _tryBuildFigmaContext(figmaUrl);
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
  }) {
    return '''
=== SYSTEM PROMPT ===
$systemPrompt

=== USER PROMPT ===
$userPrompt
'''.trim();
  }

  Future<String?> _tryBuildFigmaContext(String figmaUrl) async {
    final figmaKey = Platform.environment['FIGMA_API_KEY'];
    if (figmaKey == null || figmaKey.isEmpty) return null;

    final fileKey = _extractFigmaFileKey(figmaUrl);
    if (fileKey == null) return null;

    try {
      final response = await http.get(
        Uri.parse('https://api.figma.com/v1/files/$fileKey?depth=3'),
        headers: {'X-Figma-Token': figmaKey},
      );

      if (response.statusCode != 200) return null;

      final figmaData =
          jsonDecode(response.body) as Map<String, dynamic>;
      return _formatFigmaContext(figmaData);
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

  String? _readAiBundle(String? customPath) {
    final localBundle = _readLocalBundle(customPath);
    final packageBundle =
        _readPackageBundle() ?? _readBundleFile('packages/magickit/lib/src/registry/ai_context_bundle.txt');

    if (localBundle == null && packageBundle == null) return null;
    if (localBundle == null) return packageBundle;
    if (packageBundle == null) return localBundle;

    logger.info('Menggabungkan AI bundle (package + local)...');
    return _mergeBundles(packageBundle, localBundle);
  }

  String? _readLocalBundle(String? customPath) {
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

}

class _BundleParts {
  final String components;
  final String? rules;

  const _BundleParts(this.components, this.rules);
}
