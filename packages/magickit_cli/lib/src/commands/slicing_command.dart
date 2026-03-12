import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import '../services/anthropic_service.dart';
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
      ..addOption(
        'bundle',
        abbr: 'b',
        help: 'Path ke ai_context_bundle.txt.',
        defaultsTo: null,
      );
  }

  @override
  Future<void> run() async {
    final imagePath = argResults?['image'] as String?;
    final figmaUrl = argResults?['figma'] as String?;
    final outputPath = argResults?['output'] as String? ?? 'lib/generated/sliced_ui.dart';
    final model = argResults?['model'] as String? ?? 'claude-sonnet-4-6';
    final bundlePath = argResults?['bundle'] as String?;

    if (imagePath == null && figmaUrl == null) {
      usageException('Gunakan --image <path> atau --figma <url>.');
    }

    // Validate API key
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.err('ANTHROPIC_API_KEY tidak ditemukan di environment.');
      logger.info('Set environment variable:');
      logger.info('  export ANTHROPIC_API_KEY=sk-ant-...');
      exit(1);
    }

    // Read AI bundle
    final bundle = _readAiBundle(bundlePath);
    if (bundle == null) {
      logger.warn(
        'ai_context_bundle.txt tidak ditemukan. '
        'Jalankan `magickit registry` terlebih dahulu untuk hasil terbaik.',
      );
    }

    final service = AnthropicService(apiKey: apiKey, model: model);
    final systemPrompt = _buildSystemPrompt(bundle);

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

    // Extract file key from URL
    // Format: https://www.figma.com/file/{fileKey}/...
    //         https://www.figma.com/design/{fileKey}/...
    final fileKeyMatch = RegExp(r'figma\.com/(?:file|design)/([^/]+)').firstMatch(figmaUrl);
    if (fileKeyMatch == null) {
      logger.err('Format Figma URL tidak valid: $figmaUrl');
      logger.info('Format yang valid: https://www.figma.com/file/XXXXXX/nama-file');
      exit(1);
    }

    final fileKey = fileKeyMatch.group(1)!;
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
    final pageName = (figmaData['document'] as Map<String, dynamic>?)?['name'] ?? 'Figma Design';
    final components = _extractFigmaComponents(figmaData);

    progress.update('Mengirim ke Claude...');

    final widgetName = _outputPathToWidgetName(outputPath);
    final figmaContext = '''
Figma File: $pageName
Components ditemukan:
${components.map((c) => '- $c').join('\n')}

Figma data (JSON excerpt):
${jsonEncode(figmaData).substring(0, (jsonEncode(figmaData).length).clamp(0, 3000))}...
''';

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
    final paths = [
      if (customPath != null) customPath,
      'lib/src/registry/ai_context_bundle.txt',
      'packages/magickit/lib/src/registry/ai_context_bundle.txt',
    ];

    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) return file.readAsStringSync();
    }

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
