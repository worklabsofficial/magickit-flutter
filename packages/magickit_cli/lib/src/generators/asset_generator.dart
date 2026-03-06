import '../utils/string_utils.dart';

class AssetGenerator {
  /// Generate Assets class dari list file paths.
  ///
  /// [filePaths] — absolute atau relative paths ke file asset.
  /// [baseDir] — direktori base untuk menghitung relative path.
  String generate(List<String> filePaths, String baseDir) {
    final normalizedBase =
        baseDir.replaceAll(r'\', '/').trimRight().replaceAll(RegExp(r'/$'), '');

    final entries = <(String varName, String assetPath)>[];

    for (var path in filePaths) {
      final normalized = path.replaceAll(r'\', '/');

      // Get path relative to base dir for the asset reference
      final assetPath = normalized.startsWith('$normalizedBase/')
          ? normalized.substring(normalizedBase.length + 1)
          : normalized;

      // Skip hidden files / system files
      if (assetPath.split('/').any((p) => p.startsWith('.'))) continue;

      final varName = _pathToVarName(assetPath);
      entries.add((varName, assetPath));
    }

    // Sort alphabetically
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    // Deduplicate var names (in case of collision)
    final seen = <String>{};
    final deduped = <(String, String)>[];
    for (final entry in entries) {
      var name = entry.$1;
      var counter = 1;
      while (seen.contains(name)) {
        name = '${entry.$1}$counter';
        counter++;
      }
      seen.add(name);
      deduped.add((name, entry.$2));
    }

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit assets` to regenerate.')
      ..writeln(
        '// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names',
      )
      ..writeln()
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class Assets {')
      ..writeln('  Assets._();')
      ..writeln();

    for (final (varName, assetPath) in deduped) {
      buffer.writeln("  static const String $varName = '$assetPath';");
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _pathToVarName(String relativePath) {
    // Remove extension
    final withoutExt = relativePath.contains('.')
        ? relativePath.substring(0, relativePath.lastIndexOf('.'))
        : relativePath;

    // Split by separators
    final parts = withoutExt
        .split(RegExp(r'[/\\_\-\s.]+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'unknown';

    // camelCase: first part lowercase, rest capitalized
    return parts.first.toLowerCase() + parts.skip(1).map(capitalize).join('');
  }
}
