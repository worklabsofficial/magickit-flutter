class ComponentInfo {
  final String name;
  final String category;
  final String useCase;
  final List<String> visualKeywords;
  final String? importPath;
  final String? filePath;
  final String? widgetType;
  final String? description;
  final List<String> tags;
  final List<ConstructorInfo> constructors;

  const ComponentInfo({
    required this.name,
    required this.category,
    required this.useCase,
    required this.visualKeywords,
    this.importPath,
    this.filePath,
    this.widgetType,
    this.description,
    this.tags = const [],
    this.constructors = const [],
  });
}

class ConstructorInfo {
  final String name;
  final List<ParamInfo> parameters;
  final String? description;
  final String? usageExample;

  const ConstructorInfo({
    required this.name,
    this.parameters = const [],
    this.description,
    this.usageExample,
  });
}

class ParamInfo {
  final String name;
  final String type;
  final bool required;
  final String? defaultValue;

  const ParamInfo({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
  });
}

class RegistryGenerator {
  static final _annotationPattern = RegExp(
    r'\{@magickit\}(.*?)\{@end\}',
    dotAll: true,
  );

  /// Parse Dart source file content dan extract semua komponen yang diannotasi.
  List<ComponentInfo> parseSource(String content, {String? filePath}) {
    final results = <ComponentInfo>[];

    for (final match in _annotationPattern.allMatches(content)) {
      final block = match.group(1) ?? '';
      final info = _parseAnnotationBlock(block, content, filePath: filePath);
      if (info != null) results.add(info);
    }

    return results;
  }

  ComponentInfo? _parseAnnotationBlock(
    String block,
    String fullContent, {
    String? filePath,
  }) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('///'))
        .map((l) => l.substring(3).trim())
        .where((l) => l.isNotEmpty);

    String? name, category, useCase;
    List<String> visualKeywords = [];

    for (final line in lines) {
      if (line.startsWith('name:')) {
        name = line.substring(5).trim();
      } else if (line.startsWith('category:')) {
        category = line.substring(9).trim();
      } else if (line.startsWith('use_case:')) {
        useCase = line.substring(9).trim();
      } else if (line.startsWith('visual_keywords:')) {
        final raw = line.substring(16).trim();
        visualKeywords = raw.split(',').map((k) => k.trim()).toList();
      }
    }

    if (name == null || category == null) return null;

    final widgetType = _extractWidgetType(fullContent, name);
    final description = _extractDescription(fullContent, name);
    final constructors = _extractConstructors(fullContent, name);
    final tags = _generateTags(category, constructors, fullContent);

    return ComponentInfo(
      name: name,
      category: category,
      useCase: useCase ?? '',
      visualKeywords: visualKeywords,
      filePath: filePath,
      widgetType: widgetType,
      description: description,
      constructors: constructors,
      tags: tags,
    );
  }

  String? _extractWidgetType(String content, String className) {
    final classPattern = RegExp(
      r'class\s+' + RegExp.escape(className) + r'\s+extends\s+(\w+)',
    );
    final match = classPattern.firstMatch(content);
    return match?.group(1);
  }

  String? _extractDescription(String content, String className) {
    final lines = content.split('\n');
    final classLineIdx = lines.indexWhere(
      (l) => l.contains('class $className'),
    );
    if (classLineIdx < 0) return null;

    var descLines = <String>[];
    for (var i = classLineIdx - 1; i >= 0; i--) {
      final line = lines[i].trim();
      if (line.startsWith('///') && !line.contains('{@')) {
        descLines.add(line.substring(3).trim());
      } else if (line.isEmpty) {
        continue;
      } else {
        break;
      }
    }

    if (descLines.isEmpty) return null;
    descLines = descLines.reversed.toList();
    return descLines.join(' ');
  }

  List<ConstructorInfo> _extractConstructors(
    String content,
    String className,
  ) {
    final constructors = <ConstructorInfo>[];

    final defaultConstructor = _extractDefaultConstructor(
      content,
      className,
    );
    if (defaultConstructor != null) {
      constructors.add(defaultConstructor);
    }

    final namedConstructors = _extractNamedConstructors(
      content,
      className,
    );
    constructors.addAll(namedConstructors);

    return constructors;
  }

  ConstructorInfo? _extractDefaultConstructor(
    String content,
    String className,
  ) {
    final pattern = RegExp(
      r'(?:const\s+)?' + RegExp.escape(className) + r'\s*\(\s*\{([^}]*)\}\s*\)',
      dotAll: true,
    );
    final match = pattern.firstMatch(content);
    if (match == null) return null;

    final params = match.group(1) ?? '';
    final paramInfos = _extractParamInfos(params, content, className);

    return ConstructorInfo(
      name: className,
      parameters: paramInfos,
    );
  }

  List<ConstructorInfo> _extractNamedConstructors(
    String content,
    String className,
  ) {
    final results = <ConstructorInfo>[];
    final pattern = RegExp(
      r'(?:const\s+)?' +
          RegExp.escape(className) +
          r'\.(\w+)\s*\(\s*\{([^}]*)\}\s*\)',
      dotAll: true,
    );

    for (final match in pattern.allMatches(content)) {
      final ctorName = match.group(1)!;
      final params = match.group(2) ?? '';
      final paramInfos = _extractParamInfos(params, content, className);

      results.add(
        ConstructorInfo(
          name: '$className.$ctorName',
          parameters: paramInfos,
        ),
      );
    }

    return results;
  }

  List<ParamInfo> _extractParamInfos(
      String paramsBlock, String fullContent, String className) {
    final results = <ParamInfo>[];
    final fieldTypes = _extractFieldTypes(fullContent, className);

    final lines = paramsBlock.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('//')) continue;

      final isRequired = line.startsWith('required ');
      var cleanLine =
          isRequired ? line.substring('required '.length).trim() : line;

      final thisMatch = RegExp(r'this\.(\w+)').firstMatch(cleanLine);
      if (thisMatch == null) continue;

      final paramName = thisMatch.group(1)!;
      final type = fieldTypes[paramName] ?? 'dynamic';

      String? defaultValue;
      final defaultMatch = RegExp(r'=\s*([^,]+)').firstMatch(cleanLine);
      if (defaultMatch != null) {
        defaultValue = defaultMatch.group(1)!.trim();
      }

      results.add(
        ParamInfo(
          name: paramName,
          type: type,
          required: isRequired,
          defaultValue: defaultValue,
        ),
      );
    }

    return results;
  }

  Map<String, String> _extractFieldTypes(String content, String className) {
    final types = <String, String>{};
    final lines = content.split('\n');
    var inClass = false;
    var braceDepth = 0;

    for (final line in lines) {
      if (line.contains('class $className')) {
        inClass = true;
      }
      if (!inClass) continue;

      braceDepth += line.split('').where((c) => c == '{').length;
      braceDepth -= line.split('').where((c) => c == '}').length;

      if (braceDepth <= 0 && line.contains('}')) {
        break;
      }

      final fieldMatch = RegExp(
        r'final\s+([\w<>?]+)\s+(\w+)\s*[;=]',
      ).firstMatch(line);
      if (fieldMatch != null) {
        types[fieldMatch.group(2)!] = fieldMatch.group(1)!;
      }
    }

    return types;
  }

  List<String> _generateTags(
    String category,
    List<ConstructorInfo> constructors,
    String content,
  ) {
    final tags = <String>[category];

    if (content.contains('TextEditingController') ||
        content.contains('ValueNotifier') ||
        content.contains('onChanged')) {
      tags.add('input');
    }
    if (content.contains('onPressed') ||
        content.contains('onTap') ||
        content.contains('VoidCallback')) {
      tags.add('action');
    }
    if (content.contains('ListView') ||
        content.contains('GridView') ||
        content.contains('ListTile')) {
      tags.add('list');
    }
    if (content.contains('Image') ||
        content.contains('NetworkImage') ||
        content.contains('AssetImage')) {
      tags.add('media');
    }
    if (content.contains('showDialog') ||
        content.contains('showModalBottomSheet') ||
        content.contains('Navigator')) {
      tags.add('modal');
    }
    if (content.contains('animation') ||
        content.contains('AnimationController') ||
        content.contains('TickerProvider')) {
      tags.add('animation');
    }
    if (content.contains('Form') ||
        content.contains('validator') ||
        content.contains('TextFormField')) {
      tags.add('form');
    }
    if (content.contains('Scroll') || content.contains('ScrollController')) {
      tags.add('scroll');
    }
    if (content.contains('StatefulWidget')) {
      tags.add('stateful');
    }
    if (content.contains('StatelessWidget')) {
      tags.add('stateless');
    }

    return tags.toSet().toList();
  }

  /// Generate component_registry.yaml dari list ComponentInfo.
  String generateYaml(
    List<ComponentInfo> components, {
    String importPath = 'package:magickit/magickit.dart',
  }) {
    final buffer = StringBuffer()
      ..writeln('# MagicKit Component Registry')
      ..writeln('# Generated by: magickit registry')
      ..writeln('# Do not edit — run `magickit registry` to regenerate.')
      ..writeln()
      ..writeln('components:');

    for (final c in components) {
      final keywords = c.visualKeywords.map((k) => '"$k"').join(', ');
      buffer
        ..writeln('  - name: ${c.name}')
        ..writeln('    category: ${c.category}')
        ..writeln("    import: '$importPath'")
        ..writeln("    use_case: '${c.useCase}'")
        ..writeln('    visual_keywords: [$keywords]');
    }

    return buffer.toString();
  }

  /// Generate AI context bundle in Format 2 markdown structure.
  /// Optimized for AI understanding with constructors, examples, and tags.
  String generateAiBundle(List<ComponentInfo> components) {
    final grouped = <String, List<ComponentInfo>>{};
    for (final c in components) {
      grouped.putIfAbsent(c.category, () => []).add(c);
    }

    final buffer = StringBuffer()
      ..writeln('## AVAILABLE GLOBAL COMPONENTS')
      ..writeln()
      ..writeln(
        'The project uses a shared component library called `magickit`. '
        'When generating Flutter code, ALWAYS prefer using these existing '
        'components over creating new widgets from scratch.',
      )
      ..writeln()
      ..writeln('### Import Statement:')
      ..writeln('```dart')
      ..writeln("import 'package:magickit/magickit.dart';")
      ..writeln('// This import gives access to all MagicKit components')
      ..writeln('```')
      ..writeln();

    final order = ['atom', 'molecule', 'organism'];
    final categoryLabels = {
      'atom': 'Atoms',
      'molecule': 'Molecules',
      'organism': 'Organisms',
    };

    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return ai == -1 && bi == -1
            ? a.compareTo(b)
            : ai == -1
                ? 1
                : bi == -1
                    ? -1
                    : ai.compareTo(bi);
      });

    for (final key in keys) {
      final categoryComponents = grouped[key]!;
      buffer.writeln(
          '### ${categoryLabels[key] ?? key} (${categoryComponents.length})');
      buffer.writeln();

      for (final c in categoryComponents) {
        buffer.writeln('#### `${c.name}`');
        buffer.writeln();

        if (c.description != null && c.description!.isNotEmpty) {
          buffer.writeln(c.description);
          buffer.writeln();
        } else if (c.useCase.isNotEmpty) {
          buffer.writeln(c.useCase);
          buffer.writeln();
        }

        buffer.writeln('- **Category**: ${c.category}');
        if (c.widgetType != null) {
          buffer.writeln('- **Type**: ${c.widgetType}');
        }
        buffer.writeln('- **Tags**: ${c.tags.join(', ')}');
        buffer.writeln();

        if (c.filePath != null && c.filePath!.isNotEmpty) {
          buffer.writeln('**File**: `${c.filePath}`');
          buffer.writeln();
        }

        if (c.constructors.isNotEmpty) {
          buffer.writeln('**Constructors:**');
          buffer.writeln();
          for (final ctor in c.constructors) {
            buffer.writeln('```dart');
            buffer.writeln('${ctor.name}(');
            for (var i = 0; i < ctor.parameters.length; i++) {
              final param = ctor.parameters[i];
              final req = param.required ? 'required ' : '';
              final type = param.type;
              final name = param.name;
              final def =
                  param.defaultValue != null ? ' = ${param.defaultValue}' : '';
              final comma = i < ctor.parameters.length - 1 ? ',' : '';
              buffer.writeln('  $req$type $name$def$comma');
            }
            buffer.writeln(')');
            buffer.writeln('```');
            buffer.writeln();
          }
        }

        buffer.writeln('**Keywords:** ${c.visualKeywords.join(', ')}');
        buffer.writeln();
      }
    }

    buffer
      ..writeln('## USAGE GUIDELINES')
      ..writeln()
      ..writeln(
          '1. **Always check this list first** before creating new widgets')
      ..writeln('2. **Use the exact class names** shown above')
      ..writeln(
          '3. **Use named constructors** when available (e.g., MagicButton.primary)')
      ..writeln(
          "4. **Import via `package:magickit/magickit.dart`** for all components")
      ..writeln(
          '5. **Use MagicTheme.of(context)** to access design tokens (colors, spacing, typography, radius, shadows)')
      ..writeln('6. **Never hardcode values** — always use theme tokens')
      ..writeln('7. **Follow the parameter patterns** shown in constructors');

    return buffer.toString();
  }
}
