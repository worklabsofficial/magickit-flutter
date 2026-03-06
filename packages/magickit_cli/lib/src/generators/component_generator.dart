import '../utils/string_utils.dart';

class ComponentGenerator {
  /// Generate widget scaffold file sesuai MagicKit convention.
  ///
  /// [name] — nama komponen (e.g. "rating_star" → MagicRatingStar)
  /// [type] — "atom" | "molecule" | "organism"
  String generate({
    required String name,
    required String type,
    String? packageName,
  }) {
    final pascal = toPascalCase(name);
    final className = 'Magic$pascal';
    final pkg = packageName ?? 'magickit';

    return '''
import 'package:flutter/material.dart';
import 'package:$pkg/$pkg.dart';

/// {@magickit}
/// name: $className
/// category: $type
/// use_case: TODO: describe use case
/// visual_keywords: TODO: tambahkan keywords
/// {@end}
class $className extends StatelessWidget {
  // TODO: tambahkan properties

  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    // TODO: implement widget
    return const SizedBox.shrink();
  }
}
''';
  }

  /// Tentukan direktori output berdasarkan tipe komponen.
  String outputDir(String type, String baseDir) {
    final dir = switch (type) {
      'atom' || 'atoms' => 'atoms',
      'molecule' || 'molecules' => 'molecules',
      'organism' || 'organisms' => 'organisms',
      _ => type,
    };
    return '$baseDir/$dir';
  }
}
